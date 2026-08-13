-- patch-014: fading_shadow (the "Skazony Straznik" / Corrupted Guardian
-- boss in dungeon_ruins) was reachable and defeatable as soon as its
-- miniboss (bramble_warden, the objective of the very first quest,
-- whispers_of_the_forest) was down -- five quests before the_ancient_gate,
-- the quest whose 3rd objective is to defeat it, was even offered. Unlike
-- the mountains/volcano bosses (which already check a `questActive` prop --
-- see MountainsScene.tsx/VolcanoScene.tsx), DungeonScene.tsx never gated
-- the boss hotspot on the_ancient_gate being active. The app-code fix
-- (adding that same gate to app/(game)/dungeon/page.tsx and
-- DungeonScene.tsx) ships alongside this patch.
--
-- record_quest_event only progresses objectives of a player's currently
-- *active* quests, so anyone who beat fading_shadow before starting
-- the_ancient_gate got player_boss_state.defeated = true with no matching
-- objective progress -- and since a defeated boss's hotspot never comes
-- back, that objective (and the_ancient_gate, and everything chained after
-- it) was permanently unwinnable. This data-repair statement un-defeats
-- fading_shadow for any player who hasn't actually completed
-- the_ancient_gate yet, so the (now properly gated) hotspot reappears once
-- they reach it and the fight can register normally.
--
-- Safe to run more than once. Run in the Supabase SQL Editor, after
-- patch-013-mountains-map-position.sql.

update public.player_boss_state pbs
  set defeated = false, defeated_at = null
  where pbs.monster_id = 'fading_shadow'
    and pbs.defeated = true
    and not exists (
      select 1 from public.player_quests pq
      where pq.player_id = pbs.player_id
        and pq.quest_id = 'the_ancient_gate'
        and pq.status = 'completed'
    );
