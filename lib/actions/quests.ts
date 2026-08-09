"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface QuestTurnInResult {
  newLevel: number;
  newXp: number;
  newGold: number;
  leveledUp: boolean;
  rewardItemId: string | null;
  rewardItemQty: number;
}

export async function completeQuestTurnIn(questId: string): Promise<QuestTurnInResult> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("complete_quest_turn_in", { p_quest_id: questId });
  const row = data?.[0];
  if (error || !row) throw new Error(error?.message ?? "Couldn't turn in this quest.");

  revalidatePath("/quests");
  revalidatePath("/character");

  return {
    newLevel: row.new_level,
    newXp: row.new_xp,
    newGold: row.new_gold,
    leveledUp: row.leveled_up,
    rewardItemId: row.reward_item_id,
    rewardItemQty: row.reward_item_qty,
  };
}
