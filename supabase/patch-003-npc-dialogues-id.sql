-- Patch: npc_dialogues.id was uuid-with-random-default, which made seed.sql's
-- "on conflict (id) do nothing" never match on re-run (a fresh random uuid is
-- generated every time) — re-running the seed would just keep duplicating
-- dialogue rows instead of updating them in place. Switch to a stable text id
-- like every other content table. Safe: nothing references npc_dialogues.id
-- as a foreign key, so this table can just be dropped and recreated.

drop table if exists public.npc_dialogues cascade;

create table public.npc_dialogues (
  id text primary key,
  npc_id text not null references public.npcs (id) on delete cascade,
  quest_id text references public.quests (id),
  state text not null check (state in ('idle', 'quest_offer', 'quest_active', 'quest_ready', 'quest_done')),
  lines text[] not null,
  response_label text not null default 'Continue'
);

create index npc_dialogues_npc_id_idx on public.npc_dialogues (npc_id);

alter table public.npc_dialogues enable row level security;
create policy "npc_dialogues_select_all" on public.npc_dialogues for select using (true);
grant select on public.npc_dialogues to authenticated;
