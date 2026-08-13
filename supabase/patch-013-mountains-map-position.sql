-- patch-013: nudge the Frost Mountains world-map pin/hotspot down and to
-- the right so it sits on the distinct snow peak on the right edge of
-- map2.png instead of the empty sky above the ancient ruins wall. Run once
-- in the Supabase SQL Editor, after patch-012-intro-seen.sql.
--
-- Only moves the point (locations.map_x/map_y, used for the locked padlock
-- pin and as a fallback pin once unlocked) — the matching hand-placed
-- hotspot rect for the unlocked click area lives in WorldMap.tsx, not the
-- database, and was updated alongside this patch.

update public.locations
  set map_x = 92, map_y = 14
  where id = 'mountains';
