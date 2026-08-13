-- patch-012: track "has this player dismissed the welcome/how-to-play
-- screen" on the account itself instead of in browser localStorage. Run
-- once in the Supabase SQL Editor, after patch-011-interactable-quest-gating.sql.
--
-- The intro modal used to remember "seen" per-browser (localStorage key
-- wonderhill:intro-seen:v1), so a brand-new account on a browser that had
-- already dismissed it for a previous character never saw it, while the
-- same account re-shown on a different browser/device saw it again every
-- time. Moving the flag onto players ties it to the account: new rows
-- default to false (so every newly created character sees it once, right
-- after signup) and the client flips it to true the first time they close
-- the modal, from any device.

alter table public.players
  add column if not exists intro_seen boolean not null default false;
