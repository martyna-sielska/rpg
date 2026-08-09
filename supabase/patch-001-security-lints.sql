-- Patch: fixes the 3 categories of warnings from the Supabase database linter
-- after the initial schema.sql run. Safe to run once.

-- 1) Pin search_path on the two functions that were missing it.
alter function public.set_updated_at() set search_path = public;
alter function public.xp_required(integer) set search_path = public;

-- 2) complete_quest / uncomplete_quest never needed SECURITY DEFINER — the
--    RLS policies already allow exactly what these functions do (a caller
--    only ever touches their own player/quest rows). Switch to the default
--    SECURITY INVOKER and make sure only signed-in users can call them.
alter function public.complete_quest(uuid) security invoker;
alter function public.complete_quest(uuid) set search_path = public;
revoke execute on function public.complete_quest(uuid) from public;
grant execute on function public.complete_quest(uuid) to authenticated;

alter function public.uncomplete_quest(uuid) security invoker;
alter function public.uncomplete_quest(uuid) set search_path = public;
revoke execute on function public.uncomplete_quest(uuid) from public;
grant execute on function public.uncomplete_quest(uuid) to authenticated;

-- 3) handle_new_user must stay SECURITY DEFINER (it bootstraps a brand-new
--    user's rows before any session/RLS context exists), but it should only
--    ever run via the auth.users trigger — never as a direct RPC call.
alter function public.handle_new_user() set search_path = public;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
