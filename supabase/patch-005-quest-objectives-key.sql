-- Patch: seed.sql re-seeds quest_objectives via "delete where quest_id = ...
-- then insert", the same unstable-identity mistake patch-003 already fixed
-- for npc_dialogues — except here it's worse: quest_objectives.id is a real
-- FK target (player_quest_objective_progress.objective_id references it),
-- so once a real player has progress on the quest, the delete now fails
-- outright with a foreign-key violation and aborts the whole seed script
-- (Supabase's SQL editor runs a pasted script as one implicit transaction,
-- so that one failure rolls back every other insert in the file too).
--
-- Fix: give quest_objectives a stable natural key (quest_id, order_index)
-- so seed.sql can upsert onto it instead of deleting, the same way every
-- other content table already does. This is additive — it doesn't touch
-- the uuid primary key, so existing player_quest_objective_progress rows
-- keep pointing at valid objectives.

alter table public.quest_objectives
  add constraint quest_objectives_quest_order_key unique (quest_id, order_index);
