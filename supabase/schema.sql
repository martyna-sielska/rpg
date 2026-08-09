-- Cozy Fantasy RPG — core schema
-- Run this once in the Supabase SQL Editor (Dashboard -> SQL Editor -> New query -> Run),
-- then run seed.sql immediately after (handle_new_user needs seeded locations/monsters
-- to exist before any real signup happens).
--
-- WARNING: this is a destructive rewrite of the old "Habit RPG" schema. It drops the
-- old quests/pets/bosses/players tables and everything in them. That is intentional —
-- the habit-tracker concept (arbitrary user quests, streaks) is being replaced with a
-- structured RPG content model. Do not run this against a schema with data you want to keep.

create extension if not exists "pgcrypto";

-- =========================================================
-- CLEANUP (drop the old Habit RPG objects, in dependency order)
-- =========================================================

drop trigger if exists on_auth_user_created on auth.users;

-- Tables first (cascade takes their triggers, e.g. quests_set_updated_at,
-- with them) — dropping the functions before the tables that still have
-- triggers pointing at them fails with a dependency error.
drop table if exists public.bosses cascade;
drop table if exists public.quests cascade;
drop table if exists public.pets cascade;
drop table if exists public.players cascade;

drop function if exists public.complete_quest(uuid);
drop function if exists public.uncomplete_quest(uuid);
drop function if exists public.handle_new_user();
drop function if exists public.xp_required(integer);
drop function if exists public.set_updated_at();

-- =========================================================
-- STATIC CONTENT TABLES
-- Same for every player, seeded once via seed.sql. Read-only from the
-- client (no insert/update/delete policy) — content changes happen by
-- re-running seed.sql, not through gameplay.
-- =========================================================

create table public.locations (
  id text primary key,
  name text not null,
  description text not null default '',
  background_image text not null,
  map_x numeric not null default 50,
  map_y numeric not null default 50,
  region_kind text not null default 'wilderness'
    check (region_kind in ('home', 'settlement', 'wilderness', 'dungeon', 'landmark')),
  is_implemented boolean not null default false,
  unlock_hint text,
  sort_order integer not null default 0
);

create table public.npcs (
  id text primary key,
  name text not null,
  location_id text not null references public.locations (id),
  portrait_image text not null,
  role text not null,
  sort_order integer not null default 0
);

create index npcs_location_id_idx on public.npcs (location_id);

create table public.items (
  id text primary key,
  name text not null,
  description text not null default '',
  item_type text not null check (item_type in ('material', 'weapon', 'armor', 'trinket', 'consumable', 'quest')),
  icon_image text not null,
  equip_slot text check (equip_slot in ('weapon', 'armor', 'trinket')),
  stack_max integer not null default 99 check (stack_max >= 1),
  sell_value integer not null default 0,
  stat_bonus jsonb not null default '{}'::jsonb,
  consumable_effect jsonb not null default '{}'::jsonb
);

create table public.monsters (
  id text primary key,
  name text not null,
  location_id text not null references public.locations (id),
  tier text not null check (tier in ('regular', 'miniboss', 'boss')),
  sprite_image text not null,
  max_hp integer not null,
  attack integer not null,
  defense integer not null default 0,
  xp_reward integer not null default 0,
  gold_reward integer not null default 0,
  -- array of {item_id, chance (0..1), min_qty, max_qty}
  loot_table jsonb not null default '[]'::jsonb,
  -- array of {name, telegraph_ms, damage}, used by miniboss/boss combat
  attack_patterns jsonb not null default '[]'::jsonb,
  weakness text,
  description text not null default ''
);

create index monsters_location_id_idx on public.monsters (location_id);

create table public.gathering_nodes (
  id text primary key,
  location_id text not null references public.locations (id),
  item_id text not null references public.items (id),
  name text not null,
  respawn_seconds integer not null default 300
);

create index gathering_nodes_location_id_idx on public.gathering_nodes (location_id);

create table public.crafting_recipes (
  id text primary key,
  output_item_id text not null references public.items (id),
  output_quantity integer not null default 1 check (output_quantity > 0),
  station text not null default 'anywhere' check (station in ('home_forge', 'anywhere')),
  required_level integer not null default 1
);

create table public.crafting_recipe_ingredients (
  recipe_id text not null references public.crafting_recipes (id) on delete cascade,
  item_id text not null references public.items (id),
  quantity integer not null check (quantity > 0),
  primary key (recipe_id, item_id)
);

create table public.quests (
  id text primary key,
  title text not null,
  description text not null default '',
  giver_npc_id text not null references public.npcs (id),
  location_id text not null references public.locations (id),
  min_level integer not null default 1,
  xp_reward integer not null default 0,
  gold_reward integer not null default 0,
  item_reward_id text references public.items (id),
  item_reward_qty integer not null default 0,
  is_main boolean not null default true,
  sort_order integer not null default 0,
  -- Chains this quest onto another: not offered until the prerequisite is
  -- completed. Lets one NPC hand out several quests in sequence (see
  -- talk_to_npc) instead of exactly one, and lets a quest be gated on a
  -- different NPC's quest (e.g. Dorran's fetch quest requiring Elira's
  -- gate quest to be done first).
  prerequisite_quest_id text references public.quests (id),
  -- Unlocks this location for the player the moment the quest is offered
  -- (see talk_to_npc) — used when a later quest's own objectives require
  -- traveling somewhere not reachable at signup (see patch-007).
  unlocks_location_id text references public.locations (id)
);

-- Deliberately no 'return_to_npc' objective row for the final turn-in step —
-- once every real objective below is completed, player_quests.status flips
-- to 'ready_to_turn_in' automatically (see record_quest_event) and the UI
-- derives "go tell <giver>" from quests.giver_npc_id. Avoids a chicken/egg
-- dependency between "all objectives done" and "the return objective is done".
create table public.quest_objectives (
  id uuid primary key default gen_random_uuid(),
  quest_id text not null references public.quests (id) on delete cascade,
  order_index integer not null,
  objective_type text not null check (objective_type in ('talk_to_npc', 'enter_location', 'defeat_monster', 'collect_item', 'interact')),
  target_id text not null,
  target_count integer not null default 1 check (target_count > 0),
  description text not null,
  unique (quest_id, order_index)
);

create index quest_objectives_quest_id_idx on public.quest_objectives (quest_id);

-- Static points of interest a player can investigate (magical traces,
-- ancient markings, the gate itself, ...) — the 'interact' objective_type's
-- target. Unlike gathering_nodes there's no respawn cooldown: investigating
-- always shows the flavor lines again, but grants_item_id (if set) is only
-- granted once per player, tracked in player_interactions below.
create table public.interactables (
  id text primary key,
  location_id text not null references public.locations (id),
  name text not null,
  map_x numeric not null,
  map_y numeric not null,
  lines text[] not null,
  grants_item_id text references public.items (id),
  grants_item_qty integer not null default 0
);

create index interactables_location_id_idx on public.interactables (location_id);

-- Dialogue state is derived per-player from player_quests.status at read
-- time (see talk_to_npc) rather than stored per player — deliberately kept
-- linear (no branching/choice tables yet) since the slice only needs one
-- quest-giver conversation; the shape (npc_id, quest_id, state, lines) is
-- easy to extend with a choices table later without a breaking migration.
create table public.npc_dialogues (
  id text primary key,
  npc_id text not null references public.npcs (id) on delete cascade,
  quest_id text references public.quests (id),
  state text not null check (state in ('idle', 'quest_offer', 'quest_active', 'quest_ready', 'quest_done')),
  lines text[] not null,
  response_label text not null default 'Continue'
);

create index npc_dialogues_npc_id_idx on public.npc_dialogues (npc_id);

-- =========================================================
-- PER-PLAYER STATE TABLES
-- =========================================================

create table public.players (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique,
  avatar_id text not null default 'kael' check (avatar_id in ('elara', 'kael', 'liora', 'rowan')),
  level integer not null default 1,
  xp integer not null default 0,
  hp integer not null default 50,
  max_hp integer not null default 50,
  gold integer not null default 0,
  strength integer not null default 5,
  intelligence integer not null default 5,
  dexterity integer not null default 5,
  vitality integer not null default 5,
  luck integer not null default 5,
  current_location_id text not null default 'home' references public.locations (id),
  created_at timestamptz not null default now()
);

-- Equipment pieces are plain item references, not unique item instances
-- (no per-item enchantments/durability in this slice) — equipping doesn't
-- consume the item from player_inventory, it just references it.
create table public.player_equipment (
  player_id uuid primary key references public.players (id) on delete cascade,
  weapon_item_id text references public.items (id),
  armor_item_id text references public.items (id),
  trinket_item_id text references public.items (id),
  updated_at timestamptz not null default now()
);

-- Every item stacks by item_id (no unique item instances in this slice),
-- hence the uniqueness constraint on (player_id, item_id) rather than a
-- free-standing row per pickup.
create table public.player_inventory (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references public.players (id) on delete cascade,
  item_id text not null references public.items (id),
  quantity integer not null default 1 check (quantity >= 0),
  acquired_at timestamptz not null default now(),
  unique (player_id, item_id)
);

create index player_inventory_player_id_idx on public.player_inventory (player_id);

-- Absence of a row for a given location_id = locked. Seeded for the
-- implemented locations at signup by handle_new_user.
create table public.player_locations (
  player_id uuid not null references public.players (id) on delete cascade,
  location_id text not null references public.locations (id),
  unlocked boolean not null default true,
  discovered boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (player_id, location_id)
);

create table public.player_quests (
  player_id uuid not null references public.players (id) on delete cascade,
  quest_id text not null references public.quests (id),
  status text not null default 'active' check (status in ('active', 'ready_to_turn_in', 'completed')),
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  primary key (player_id, quest_id)
);

create table public.player_quest_objective_progress (
  player_id uuid not null references public.players (id) on delete cascade,
  quest_id text not null,
  objective_id uuid not null references public.quest_objectives (id),
  progress_count integer not null default 0,
  completed boolean not null default false,
  primary key (player_id, objective_id),
  foreign key (player_id, quest_id) references public.player_quests (player_id, quest_id) on delete cascade
);

-- Only miniboss/boss tier monsters get a row here (seeded by handle_new_user)
-- — regular monsters respawn indefinitely and don't need "defeated" state.
create table public.player_boss_state (
  player_id uuid not null references public.players (id) on delete cascade,
  monster_id text not null references public.monsters (id),
  defeated boolean not null default false,
  defeated_at timestamptz,
  primary key (player_id, monster_id)
);

create table public.player_gathering_state (
  player_id uuid not null references public.players (id) on delete cascade,
  node_id text not null references public.gathering_nodes (id),
  last_gathered_at timestamptz,
  primary key (player_id, node_id)
);

-- Tracks whether an interactable's one-time item grant has already
-- happened for this player. Investigating again still shows the flavor
-- lines (see interact_with_object) — this table only gates the item.
create table public.player_interactions (
  player_id uuid not null references public.players (id) on delete cascade,
  interactable_id text not null references public.interactables (id),
  first_interacted_at timestamptz not null default now(),
  primary key (player_id, interactable_id)
);

create table public.pets (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null unique references public.players (id) on delete cascade,
  name text not null default 'Ember',
  species text not null default 'dragon',
  level integer not null default 1,
  mood text not null default 'happy',
  created_at timestamptz not null default now()
);

-- =========================================================
-- ROW LEVEL SECURITY
-- =========================================================

alter table public.locations enable row level security;
alter table public.npcs enable row level security;
alter table public.items enable row level security;
alter table public.monsters enable row level security;
alter table public.gathering_nodes enable row level security;
alter table public.crafting_recipes enable row level security;
alter table public.crafting_recipe_ingredients enable row level security;
alter table public.quests enable row level security;
alter table public.quest_objectives enable row level security;
alter table public.npc_dialogues enable row level security;
alter table public.interactables enable row level security;

alter table public.players enable row level security;
alter table public.player_equipment enable row level security;
alter table public.player_inventory enable row level security;
alter table public.player_locations enable row level security;
alter table public.player_quests enable row level security;
alter table public.player_quest_objective_progress enable row level security;
alter table public.player_boss_state enable row level security;
alter table public.player_gathering_state enable row level security;
alter table public.player_interactions enable row level security;
alter table public.pets enable row level security;

-- Static content: readable by any signed-in player, no client writes.
create policy "locations_select_all" on public.locations for select using (true);
create policy "npcs_select_all" on public.npcs for select using (true);
create policy "items_select_all" on public.items for select using (true);
create policy "monsters_select_all" on public.monsters for select using (true);
create policy "gathering_nodes_select_all" on public.gathering_nodes for select using (true);
create policy "crafting_recipes_select_all" on public.crafting_recipes for select using (true);
create policy "crafting_recipe_ingredients_select_all" on public.crafting_recipe_ingredients for select using (true);
create policy "quests_select_all" on public.quests for select using (true);
create policy "quest_objectives_select_all" on public.quest_objectives for select using (true);
create policy "npc_dialogues_select_all" on public.npc_dialogues for select using (true);
create policy "interactables_select_all" on public.interactables for select using (true);

-- Per-player: scoped to auth.uid(). Mutations happen through SECURITY INVOKER
-- RPCs below, which still run under the caller's own permissions — hence
-- "for all" policies (not just select) on every table an RPC writes to.
create policy "players_select_own" on public.players
  for select using (auth.uid() = id);
create policy "players_update_own" on public.players
  for update using (auth.uid() = id) with check (auth.uid() = id);

create policy "player_equipment_all_own" on public.player_equipment
  for all using (auth.uid() = player_id) with check (auth.uid() = player_id);
create policy "player_inventory_all_own" on public.player_inventory
  for all using (auth.uid() = player_id) with check (auth.uid() = player_id);
create policy "player_locations_all_own" on public.player_locations
  for all using (auth.uid() = player_id) with check (auth.uid() = player_id);
create policy "player_quests_all_own" on public.player_quests
  for all using (auth.uid() = player_id) with check (auth.uid() = player_id);
create policy "player_quest_objective_progress_all_own" on public.player_quest_objective_progress
  for all using (auth.uid() = player_id) with check (auth.uid() = player_id);
create policy "player_boss_state_all_own" on public.player_boss_state
  for all using (auth.uid() = player_id) with check (auth.uid() = player_id);
create policy "player_gathering_state_all_own" on public.player_gathering_state
  for all using (auth.uid() = player_id) with check (auth.uid() = player_id);
create policy "player_interactions_all_own" on public.player_interactions
  for all using (auth.uid() = player_id) with check (auth.uid() = player_id);
create policy "pets_select_own" on public.pets
  for select using (auth.uid() = player_id);

-- RLS policies only filter *rows* — Postgres still checks table-level GRANTs
-- first, and new tables have none by default (see patch-002 in the old
-- schema for how this bit the original project). Grant explicitly here
-- instead of as an afterthought patch.
grant select on public.locations, public.npcs, public.items, public.monsters,
  public.gathering_nodes, public.crafting_recipes, public.crafting_recipe_ingredients,
  public.quests, public.quest_objectives, public.npc_dialogues, public.interactables to authenticated;

grant select, update on public.players to authenticated;
grant select, insert, update, delete on public.player_equipment to authenticated;
grant select, insert, update, delete on public.player_inventory to authenticated;
grant select, insert, update, delete on public.player_locations to authenticated;
grant select, insert, update, delete on public.player_quests to authenticated;
grant select, insert, update, delete on public.player_quest_objective_progress to authenticated;
grant select, insert, update, delete on public.player_boss_state to authenticated;
grant select, insert, update, delete on public.player_gathering_state to authenticated;
grant select, insert, update, delete on public.player_interactions to authenticated;
grant select on public.pets to authenticated;

-- =========================================================
-- Level curve: xp needed to go from level p_level to p_level + 1
-- (unchanged from the original Habit RPG schema)
-- =========================================================

create or replace function public.xp_required(p_level integer)
returns integer
language sql
immutable
set search_path = public
as $$
  select 100 + (p_level - 1) * 50;
$$;

grant execute on function public.xp_required(integer) to authenticated, anon;

-- =========================================================
-- New user bootstrap: player + starter pet/equipment row + unlocked
-- slice locations + boss-state rows for the slice's miniboss/boss.
-- Requires locations/monsters to already be seeded (run seed.sql first).
-- =========================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.players (id, username, avatar_id)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'username', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data ->> 'avatar_id', 'kael')
  );

  insert into public.pets (player_id) values (new.id);
  insert into public.player_equipment (player_id) values (new.id);

  insert into public.player_locations (player_id, location_id, unlocked)
    select new.id, l.id, true
    from public.locations l
    where l.is_implemented = true;

  insert into public.player_boss_state (player_id, monster_id, defeated)
    select new.id, m.id, false
    from public.monsters m
    where m.tier in ('miniboss', 'boss');

  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Trigger invocation doesn't need an EXECUTE grant; revoke it so nobody can
-- call this SECURITY DEFINER function directly via /rest/v1/rpc.
revoke execute on function public.handle_new_user() from public, anon, authenticated;

-- =========================================================
-- record_quest_event: single generic entry point called after any
-- quest-relevant action (entering a location, defeating a monster,
-- collecting an item, talking to an NPC). Matches against the player's
-- active objectives and flips the quest to ready_to_turn_in once every
-- objective is complete.
-- =========================================================

create or replace function public.record_quest_event(p_event_type text, p_target_id text, p_amount integer default 1)
returns void
language plpgsql
set search_path = public
as $$
declare
  v_player_id uuid := auth.uid();
  v_obj record;
begin
  if v_player_id is null then
    raise exception 'Not authenticated';
  end if;

  for v_obj in
    select qo.id as objective_id, qo.quest_id, qo.target_count, pqop.progress_count
    from public.quest_objectives qo
    join public.player_quests pq
      on pq.quest_id = qo.quest_id and pq.player_id = v_player_id and pq.status = 'active'
    join public.player_quest_objective_progress pqop
      on pqop.objective_id = qo.id and pqop.player_id = v_player_id
    where qo.objective_type = p_event_type
      and qo.target_id = p_target_id
      and pqop.completed = false
  loop
    update public.player_quest_objective_progress
      set progress_count = least(v_obj.target_count, v_obj.progress_count + p_amount),
          completed = (v_obj.progress_count + p_amount) >= v_obj.target_count
      where player_id = v_player_id and objective_id = v_obj.objective_id;
  end loop;

  update public.player_quests pq
    set status = 'ready_to_turn_in'
    where pq.player_id = v_player_id
      and pq.status = 'active'
      and not exists (
        select 1 from public.quest_objectives qo2
        left join public.player_quest_objective_progress pqop2
          on pqop2.objective_id = qo2.id and pqop2.player_id = v_player_id
        where qo2.quest_id = pq.quest_id
          and coalesce(pqop2.completed, false) = false
      );
end;
$$;

revoke execute on function public.record_quest_event(text, text, integer) from public;
grant execute on function public.record_quest_event(text, text, integer) to authenticated;

-- =========================================================
-- travel_to_location: move the player, mark the location discovered,
-- fire the enter_location quest event.
-- =========================================================

create or replace function public.travel_to_location(p_location_id text)
returns void
language plpgsql
set search_path = public
as $$
declare
  v_player_id uuid := auth.uid();
  v_unlocked boolean;
begin
  if v_player_id is null then
    raise exception 'Not authenticated';
  end if;

  select unlocked into v_unlocked from public.player_locations
    where player_id = v_player_id and location_id = p_location_id;

  if not coalesce(v_unlocked, false) then
    raise exception 'Location is locked';
  end if;

  update public.players set current_location_id = p_location_id where id = v_player_id;

  update public.player_locations
    set discovered = true, updated_at = now()
    where player_id = v_player_id and location_id = p_location_id;

  perform public.record_quest_event('enter_location', p_location_id);
end;
$$;

revoke execute on function public.travel_to_location(text) from public;
grant execute on function public.travel_to_location(text) to authenticated;

-- =========================================================
-- talk_to_npc: resolves the current dialogue state for this player/NPC
-- pair (derived from player_quests, not stored), returns the matching
-- dialogue lines, and — on first contact — creates the player_quests +
-- objective-progress rows for the NPC's quest.
--
-- An NPC can own an ordered chain of quests (see quests.prerequisite_quest_id),
-- not just one, so each call re-derives which of the NPC's quests is
-- currently relevant:
--   1. a quest of theirs already active/ready_to_turn_in takes priority
--   2. otherwise the lowest-sort_order quest of theirs the player hasn't
--      started, whose prerequisite (if any) is completed and whose
--      min_level is met -> offered (auto-starts it, same as before)
--   3. otherwise the most recently completed quest of theirs -> closing
--      flavor for that specific quest, so an NPC can say "go see Dorran
--      about that" between two of their own quests instead of falling
--      back to generic idle chatter
--   4. otherwise idle (no quest of theirs has ever come up yet)
-- Dialogue lookup is now keyed on (npc_id, quest_id, state) rather than
-- just (npc_id, state), since one NPC can have several quests' worth of
-- dialogue rows.
-- =========================================================

-- Output columns are prefixed out_* because several of them (state, lines,
-- response_label, quest_id) share a name with a real column this function
-- queries (npc_dialogues.state/lines/response_label, player_quests.quest_id)
-- — PL/pgSQL raises "ambiguous... variable or column" if a RETURNS TABLE
-- name collides with a column name used anywhere in the function body, even
-- in places like INSERT target lists that would otherwise be unambiguous.
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

-- =========================================================
-- complete_quest_turn_in: awards xp/gold/item once a quest is
-- ready_to_turn_in, loops level-ups (same pattern as the old
-- complete_quest), and marks the quest completed.
-- =========================================================

create or replace function public.complete_quest_turn_in(p_quest_id text)
returns table (
  new_level integer,
  new_xp integer,
  new_gold integer,
  leveled_up boolean,
  reward_item_id text,
  reward_item_qty integer
)
language plpgsql
set search_path = public
as $$
declare
  v_player_id uuid := auth.uid();
  v_quest public.quests;
  v_player public.players;
  v_pq public.player_quests;
  v_xp integer;
  v_level integer;
  v_gold integer;
  v_leveled_up boolean := false;
begin
  if v_player_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_pq from public.player_quests
    where player_id = v_player_id and quest_id = p_quest_id
    for update;

  if not found or v_pq.status <> 'ready_to_turn_in' then
    raise exception 'Quest is not ready to turn in';
  end if;

  select * into v_quest from public.quests where id = p_quest_id;
  select * into v_player from public.players where id = v_player_id for update;

  v_xp := v_player.xp + v_quest.xp_reward;
  v_level := v_player.level;
  v_gold := v_player.gold + v_quest.gold_reward;

  while v_xp >= public.xp_required(v_level) loop
    v_xp := v_xp - public.xp_required(v_level);
    v_level := v_level + 1;
    v_leveled_up := true;
  end loop;

  update public.players set xp = v_xp, level = v_level, gold = v_gold where id = v_player_id;

  update public.player_quests
    set status = 'completed', completed_at = now()
    where player_id = v_player_id and quest_id = p_quest_id;

  if v_quest.item_reward_id is not null and v_quest.item_reward_qty > 0 then
    insert into public.player_inventory (player_id, item_id, quantity)
      values (v_player_id, v_quest.item_reward_id, v_quest.item_reward_qty)
      on conflict (player_id, item_id) do update
        set quantity = public.player_inventory.quantity + excluded.quantity;
  end if;

  return query select v_level, v_xp, v_gold, v_leveled_up, v_quest.item_reward_id, v_quest.item_reward_qty;
end;
$$;

revoke execute on function public.complete_quest_turn_in(text) from public;
grant execute on function public.complete_quest_turn_in(text) to authenticated;

-- =========================================================
-- resolve_combat: authoritative outcome of a client-simulated fight.
-- The client only reports the outcome + resulting HP; xp/gold/loot are
-- always computed server-side so the client can never dictate rewards.
-- =========================================================

create or replace function public.resolve_combat(p_monster_id text, p_outcome text, p_player_hp_remaining integer)
returns table (
  new_hp integer,
  new_xp integer,
  new_level integer,
  new_gold integer,
  leveled_up boolean,
  loot jsonb
)
language plpgsql
set search_path = public
as $$
declare
  v_player_id uuid := auth.uid();
  v_monster public.monsters;
  v_player public.players;
  v_xp integer;
  v_level integer;
  v_gold integer;
  v_leveled_up boolean := false;
  v_hp integer;
  v_loot jsonb := '[]'::jsonb;
  v_entry jsonb;
  v_min_qty integer;
  v_max_qty integer;
  v_qty integer;
begin
  if v_player_id is null then
    raise exception 'Not authenticated';
  end if;
  if p_outcome not in ('victory', 'fled') then
    raise exception 'Invalid outcome';
  end if;

  select * into v_monster from public.monsters where id = p_monster_id;
  if not found then
    raise exception 'Monster not found';
  end if;

  select * into v_player from public.players where id = v_player_id for update;

  v_hp := greatest(0, least(v_player.max_hp, p_player_hp_remaining));
  v_xp := v_player.xp;
  v_level := v_player.level;
  v_gold := v_player.gold;

  if p_outcome = 'victory' then
    v_xp := v_xp + v_monster.xp_reward;
    v_gold := v_gold + v_monster.gold_reward;

    while v_xp >= public.xp_required(v_level) loop
      v_xp := v_xp - public.xp_required(v_level);
      v_level := v_level + 1;
      v_leveled_up := true;
    end loop;

    for v_entry in select * from jsonb_array_elements(v_monster.loot_table)
    loop
      if random() <= coalesce((v_entry ->> 'chance')::numeric, 0) then
        v_min_qty := coalesce((v_entry ->> 'min_qty')::integer, 1);
        v_max_qty := coalesce((v_entry ->> 'max_qty')::integer, v_min_qty);
        v_qty := v_min_qty + floor(random() * (v_max_qty - v_min_qty + 1))::integer;

        insert into public.player_inventory (player_id, item_id, quantity)
          values (v_player_id, v_entry ->> 'item_id', v_qty)
          on conflict (player_id, item_id) do update
            set quantity = public.player_inventory.quantity + excluded.quantity;

        v_loot := v_loot || jsonb_build_object('item_id', v_entry ->> 'item_id', 'quantity', v_qty);
      end if;
    end loop;

    if v_monster.tier in ('miniboss', 'boss') then
      update public.player_boss_state
        set defeated = true, defeated_at = now()
        where player_id = v_player_id and monster_id = p_monster_id;
    end if;

    perform public.record_quest_event('defeat_monster', p_monster_id);
  end if;

  update public.players set hp = v_hp, xp = v_xp, level = v_level, gold = v_gold where id = v_player_id;

  return query select v_hp, v_xp, v_level, v_gold, v_leveled_up, v_loot;
end;
$$;

revoke execute on function public.resolve_combat(text, text, integer) from public;
grant execute on function public.resolve_combat(text, text, integer) to authenticated;

-- =========================================================
-- gather_node: grants the node's item, subject to a respawn cooldown.
-- =========================================================

-- Output columns prefixed out_* — item_id/quantity collide with real
-- player_inventory columns this function writes to (see talk_to_npc above
-- for why that's unsafe even in seemingly-structural positions like SET).
create or replace function public.gather_node(p_node_id text)
returns table (out_item_id text, out_quantity integer)
language plpgsql
set search_path = public
as $$
declare
  v_player_id uuid := auth.uid();
  v_node public.gathering_nodes;
  v_last timestamptz;
begin
  if v_player_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_node from public.gathering_nodes where id = p_node_id;
  if not found then
    raise exception 'Gathering node not found';
  end if;

  select pgs.last_gathered_at into v_last from public.player_gathering_state pgs
    where pgs.player_id = v_player_id and pgs.node_id = p_node_id;

  if v_last is not null and v_last > now() - (v_node.respawn_seconds || ' seconds')::interval then
    raise exception 'This node has not respawned yet';
  end if;

  insert into public.player_inventory (player_id, item_id, quantity)
    values (v_player_id, v_node.item_id, 1)
    on conflict (player_id, item_id) do update
      set quantity = public.player_inventory.quantity + 1;

  insert into public.player_gathering_state (player_id, node_id, last_gathered_at)
    values (v_player_id, p_node_id, now())
    on conflict (player_id, node_id) do update set last_gathered_at = now();

  perform public.record_quest_event('collect_item', v_node.item_id);

  return query select v_node.item_id, 1;
end;
$$;

revoke execute on function public.gather_node(text) from public;
grant execute on function public.gather_node(text) to authenticated;

-- =========================================================
-- interact_with_object: returns the interactable's flavor lines every
-- time, grants its item on first interaction only (repeat visits just
-- re-show the lines), and fires the 'interact' quest event.
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
-- craft_item: validates level + ingredients, deducts them, grants output.
-- =========================================================

-- Output columns prefixed out_* — same reasoning as gather_node above.
create or replace function public.craft_item(p_recipe_id text)
returns table (out_item_id text, out_quantity integer)
language plpgsql
set search_path = public
as $$
declare
  v_player_id uuid := auth.uid();
  v_recipe public.crafting_recipes;
  v_player public.players;
  v_ing record;
  v_have integer;
begin
  if v_player_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_recipe from public.crafting_recipes where id = p_recipe_id;
  if not found then
    raise exception 'Recipe not found';
  end if;

  select * into v_player from public.players where id = v_player_id;
  if v_player.level < v_recipe.required_level then
    raise exception 'Level too low to craft this';
  end if;

  for v_ing in
    select cri.item_id, cri.quantity
    from public.crafting_recipe_ingredients cri
    where cri.recipe_id = p_recipe_id
  loop
    select coalesce(pi.quantity, 0) into v_have from public.player_inventory pi
      where pi.player_id = v_player_id and pi.item_id = v_ing.item_id;

    if v_have < v_ing.quantity then
      raise exception 'Missing ingredient %', v_ing.item_id;
    end if;
  end loop;

  update public.player_inventory pi
    set quantity = pi.quantity - cri.quantity
    from public.crafting_recipe_ingredients cri
    where cri.recipe_id = p_recipe_id
      and pi.player_id = v_player_id
      and pi.item_id = cri.item_id;

  delete from public.player_inventory where player_id = v_player_id and quantity <= 0;

  insert into public.player_inventory (player_id, item_id, quantity)
    values (v_player_id, v_recipe.output_item_id, v_recipe.output_quantity)
    on conflict (player_id, item_id) do update
      set quantity = public.player_inventory.quantity + excluded.quantity;

  return query select v_recipe.output_item_id, v_recipe.output_quantity;
end;
$$;

revoke execute on function public.craft_item(text) from public;
grant execute on function public.craft_item(text) to authenticated;

-- =========================================================
-- equip_item / unequip_item
-- =========================================================

create or replace function public.equip_item(p_item_id text)
returns void
language plpgsql
set search_path = public
as $$
declare
  v_player_id uuid := auth.uid();
  v_item public.items;
  v_have integer;
begin
  if v_player_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_item from public.items where id = p_item_id;
  if not found or v_item.equip_slot is null then
    raise exception 'Item is not equippable';
  end if;

  select coalesce(quantity, 0) into v_have from public.player_inventory
    where player_id = v_player_id and item_id = p_item_id;
  if coalesce(v_have, 0) < 1 then
    raise exception 'Item not owned';
  end if;

  insert into public.player_equipment (player_id)
    values (v_player_id)
    on conflict (player_id) do nothing;

  update public.player_equipment
    set weapon_item_id = case when v_item.equip_slot = 'weapon' then p_item_id else weapon_item_id end,
        armor_item_id = case when v_item.equip_slot = 'armor' then p_item_id else armor_item_id end,
        trinket_item_id = case when v_item.equip_slot = 'trinket' then p_item_id else trinket_item_id end,
        updated_at = now()
    where player_id = v_player_id;
end;
$$;

create or replace function public.unequip_item(p_slot text)
returns void
language plpgsql
set search_path = public
as $$
declare
  v_player_id uuid := auth.uid();
begin
  if v_player_id is null then
    raise exception 'Not authenticated';
  end if;
  if p_slot not in ('weapon', 'armor', 'trinket') then
    raise exception 'Invalid slot';
  end if;

  update public.player_equipment
    set weapon_item_id = case when p_slot = 'weapon' then null else weapon_item_id end,
        armor_item_id = case when p_slot = 'armor' then null else armor_item_id end,
        trinket_item_id = case when p_slot = 'trinket' then null else trinket_item_id end,
        updated_at = now()
    where player_id = v_player_id;
end;
$$;

revoke execute on function public.equip_item(text) from public;
grant execute on function public.equip_item(text) to authenticated;
revoke execute on function public.unequip_item(text) from public;
grant execute on function public.unequip_item(text) to authenticated;

-- =========================================================
-- rest_at_home: full HP restore (the bed in the Home scene).
-- =========================================================

create or replace function public.rest_at_home()
returns integer
language plpgsql
set search_path = public
as $$
declare
  v_player_id uuid := auth.uid();
  v_max_hp integer;
begin
  if v_player_id is null then
    raise exception 'Not authenticated';
  end if;

  update public.players set hp = max_hp where id = v_player_id returning max_hp into v_max_hp;
  return v_max_hp;
end;
$$;

revoke execute on function public.rest_at_home() from public;
grant execute on function public.rest_at_home() to authenticated;
