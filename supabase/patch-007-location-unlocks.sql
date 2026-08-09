-- Patch: quest-driven location unlocking (story expansion beyond Quest 7).
--
-- Gap: handle_new_user only ever unlocks is_implemented = true locations, at
-- signup. There was no way to unlock a location for an already-registered
-- player mid-game. Quests 8-19 need six new locations (lake, magic_tower,
-- ancient_ruins, castle, mountains, volcano) plus a new "hollow" location to
-- become reachable the moment the quest that sends the player there is
-- offered, since traveling there is one of that same quest's own objectives.
--
-- Fix: a new quests.unlocks_location_id column, unlocked in talk_to_npc()
-- at the exact moment a quest transitions to 'quest_offer' (same block that
-- already inserts the player_quests / player_quest_objective_progress rows
-- for it) — mirrors the unlock-insert shape already used by handle_new_user.
--
-- Purely additive: no existing rows are deleted or renumbered, so existing
-- players' player_quests / player_quest_objective_progress stay valid.
-- Run this once in the Supabase SQL Editor, after schema.sql + patch-001..006.

alter table public.quests
  add column if not exists unlocks_location_id text references public.locations (id);

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
  v_unlocks_location_id text;
begin
  if v_player_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_npc from public.npcs where id = p_npc_id;
  if not found then
    raise exception 'NPC not found';
  end if;

  select * into v_player from public.players where id = v_player_id;

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

    select q.unlocks_location_id into v_unlocks_location_id
      from public.quests q where q.id = v_quest_id;

    if v_unlocks_location_id is not null then
      insert into public.player_locations (player_id, location_id, unlocked)
        values (v_player_id, v_unlocks_location_id, true)
        on conflict (player_id, location_id) do update set unlocked = true, updated_at = now();
    end if;
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
