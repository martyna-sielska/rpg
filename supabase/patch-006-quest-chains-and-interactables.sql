-- Patch: quest chains + interactables (story expansion beyond the vertical
-- slice's single quest). Two gaps blocked the new content:
--
-- 1. talk_to_npc only ever looked up ONE quest per NPC ("giver_npc_id = ...
--    limit 1"), with dialogue keyed only by (npc_id, state). The new story
--    has Elira handing out five quests in sequence and Dorran one, so NPCs
--    need an ordered chain of quests, not a single fixed one.
-- 2. There was no primitive for "investigate this thing" — the new quests
--    lean on inspecting magical traces, corrupted plants, ancient markings,
--    and the gate itself, none of which are monsters, locations, or
--    gathering nodes.
--
-- Purely additive: no existing rows are deleted or renumbered, so existing
-- players' player_quests / player_quest_objective_progress stay valid.
-- Run this once in the Supabase SQL Editor, after schema.sql + patch-001..005.

-- =========================================================
-- 1. Quest chaining
-- =========================================================

alter table public.quests
  add column if not exists prerequisite_quest_id text references public.quests (id);

-- =========================================================
-- 2. New objective type: 'interact' (investigating a point of interest)
-- =========================================================

alter table public.quest_objectives
  drop constraint if exists quest_objectives_objective_type_check;
alter table public.quest_objectives
  add constraint quest_objectives_objective_type_check
  check (objective_type in ('talk_to_npc', 'enter_location', 'defeat_monster', 'collect_item', 'interact'));

-- =========================================================
-- 3. Interactables — static points of interest a player can investigate.
-- Same two-tier shape as gathering_nodes / player_gathering_state, but
-- without a respawn cooldown: investigating always shows the flavor lines,
-- and grants its item (if any) only once per player, tracked in
-- player_interactions.
-- =========================================================

create table if not exists public.interactables (
  id text primary key,
  location_id text not null references public.locations (id),
  name text not null,
  map_x numeric not null,
  map_y numeric not null,
  lines text[] not null,
  grants_item_id text references public.items (id),
  grants_item_qty integer not null default 0
);

create index if not exists interactables_location_id_idx on public.interactables (location_id);

create table if not exists public.player_interactions (
  player_id uuid not null references public.players (id) on delete cascade,
  interactable_id text not null references public.interactables (id),
  first_interacted_at timestamptz not null default now(),
  primary key (player_id, interactable_id)
);

alter table public.interactables enable row level security;
alter table public.player_interactions enable row level security;

drop policy if exists "interactables_select_all" on public.interactables;
create policy "interactables_select_all" on public.interactables for select using (true);

drop policy if exists "player_interactions_all_own" on public.player_interactions;
create policy "player_interactions_all_own" on public.player_interactions
  for all using (auth.uid() = player_id) with check (auth.uid() = player_id);

grant select on public.interactables to authenticated;
grant select, insert, update, delete on public.player_interactions to authenticated;

-- =========================================================
-- interact_with_object: returns the interactable's flavor lines every time,
-- grants its item on first interaction only (repeat visits just re-show the
-- lines), and fires the 'interact' quest event.
-- =========================================================

create or replace function public.interact_with_object(p_id text)
returns table (out_lines text[], out_granted_item_id text, out_granted_item_qty integer)
language plpgsql
set search_path = public
as $$
declare
  v_player_id uuid := auth.uid();
  v_obj public.interactables;
  v_already boolean;
  v_granted_item text := null;
  v_granted_qty integer := 0;
begin
  if v_player_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_obj from public.interactables where id = p_id;
  if not found then
    raise exception 'Nothing to investigate here';
  end if;

  select exists (
    select 1 from public.player_interactions
    where player_id = v_player_id and interactable_id = p_id
  ) into v_already;

  if not v_already then
    insert into public.player_interactions (player_id, interactable_id)
      values (v_player_id, p_id);

    if v_obj.grants_item_id is not null and v_obj.grants_item_qty > 0 then
      insert into public.player_inventory (player_id, item_id, quantity)
        values (v_player_id, v_obj.grants_item_id, v_obj.grants_item_qty)
        on conflict (player_id, item_id) do update
          set quantity = public.player_inventory.quantity + excluded.quantity;

      v_granted_item := v_obj.grants_item_id;
      v_granted_qty := v_obj.grants_item_qty;
    end if;
  end if;

  perform public.record_quest_event('interact', p_id);

  return query select v_obj.lines, v_granted_item, v_granted_qty;
end;
$$;

revoke execute on function public.interact_with_object(text) from public;
grant execute on function public.interact_with_object(text) to authenticated;

-- =========================================================
-- 4. talk_to_npc rewrite: supports an ordered chain of quests per NPC
-- instead of one fixed quest. Priority per NPC, each time the player talks
-- to them:
--   1. a quest of theirs the player already has active/ready_to_turn_in
--   2. otherwise the lowest-sort_order quest of theirs the player hasn't
--      started yet, whose prerequisite_quest_id (if any) is completed and
--      whose min_level is met -> offered
--   3. otherwise the most recently completed quest of theirs -> closing
--      flavor for that specific quest (lets an NPC say "go see Dorran
--      about that" between two of their own quests, instead of falling
--      back to generic idle chatter)
--   4. otherwise idle (never had a quest to offer yet, or genuinely just
--      flavor-text NPCs like Mira)
-- Dialogue lookup now keys on (npc_id, quest_id, state) instead of just
-- (npc_id, state), since one NPC can own several quests' worth of dialogue.
-- Output columns keep the same out_* names/shapes as before, so no calling
-- code (lib/actions/npc.ts, database.types.ts) needs to change.
-- =========================================================

create or replace function public.talk_to_npc(p_npc_id text)
returns table (
  out_npc_name text,
  out_state text,
  out_lines text[],
  out_response_label text,
  out_quest_id text
)
language plpgsql
set search_path = public
as $$
declare
  v_player_id uuid := auth.uid();
  v_player public.players;
  v_npc public.npcs;
  v_quest_id text;
  v_state text;
  v_pq_status text;
  v_dialogue public.npc_dialogues;
begin
  if v_player_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_npc from public.npcs where id = p_npc_id;
  if not found then
    raise exception 'NPC not found';
  end if;

  select * into v_player from public.players where id = v_player_id;

  -- 1. a quest of theirs already in progress takes priority
  select pq.quest_id, pq.status into v_quest_id, v_pq_status
    from public.player_quests pq
    join public.quests q on q.id = pq.quest_id
    where pq.player_id = v_player_id
      and q.giver_npc_id = p_npc_id
      and pq.status in ('active', 'ready_to_turn_in')
    order by q.sort_order
    limit 1;

  if v_quest_id is not null then
    v_state := case v_pq_status when 'active' then 'quest_active' else 'quest_ready' end;
  else
    -- 2. next not-yet-started quest of theirs whose prerequisite is met
    select q.id into v_quest_id
      from public.quests q
      where q.giver_npc_id = p_npc_id
        and q.min_level <= v_player.level
        and not exists (
          select 1 from public.player_quests pq2
          where pq2.player_id = v_player_id and pq2.quest_id = q.id
        )
        and (
          q.prerequisite_quest_id is null
          or exists (
            select 1 from public.player_quests pq3
            where pq3.player_id = v_player_id
              and pq3.quest_id = q.prerequisite_quest_id
              and pq3.status = 'completed'
          )
        )
      order by q.sort_order
      limit 1;

    if v_quest_id is not null then
      v_state := 'quest_offer';
    else
      -- 3. most recently completed quest of theirs, for closing flavor
      select pq4.quest_id into v_quest_id
        from public.player_quests pq4
        join public.quests q4 on q4.id = pq4.quest_id
        where pq4.player_id = v_player_id
          and q4.giver_npc_id = p_npc_id
          and pq4.status = 'completed'
        order by pq4.completed_at desc
        limit 1;

      v_state := case when v_quest_id is not null then 'quest_done' else 'idle' end;
    end if;
  end if;

  if v_state = 'quest_offer' then
    insert into public.player_quests (player_id, quest_id, status)
      values (v_player_id, v_quest_id, 'active')
      on conflict (player_id, quest_id) do nothing;

    insert into public.player_quest_objective_progress (player_id, quest_id, objective_id)
      select v_player_id, v_quest_id, qo.id
      from public.quest_objectives qo
      where qo.quest_id = v_quest_id
      on conflict (player_id, objective_id) do nothing;
  end if;

  select * into v_dialogue from public.npc_dialogues nd
    where nd.npc_id = p_npc_id
      and nd.state = v_state
      and ((v_quest_id is null and nd.quest_id is null) or nd.quest_id = v_quest_id)
    limit 1;

  perform public.record_quest_event('talk_to_npc', p_npc_id);

  return query select
    v_npc.name,
    v_state,
    coalesce(v_dialogue.lines, array[]::text[]),
    coalesce(v_dialogue.response_label, 'Continue'),
    v_quest_id;
end;
$$;

revoke execute on function public.talk_to_npc(text) from public;
grant execute on function public.talk_to_npc(text) to authenticated;
