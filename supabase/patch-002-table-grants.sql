-- Patch: RLS policies alone are not enough — Postgres checks table-level
-- GRANTs first, and this project never had them for these tables. Every
-- query was failing with "permission denied for table players" regardless
-- of browser/session, because the authenticated role had no baseline access
-- to touch the tables at all (independent of what RLS would have allowed).

grant select, update on public.players to authenticated;
grant select, insert, update, delete on public.quests to authenticated;
grant select on public.pets to authenticated;
grant select on public.bosses to authenticated;
