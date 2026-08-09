"use server";

import { createClient } from "@/lib/supabase/server";

export interface CombatResolution {
  newHp: number;
  newXp: number;
  newLevel: number;
  newGold: number;
  leveledUp: boolean;
  loot: { item_id: string; quantity: number }[];
}

export async function resolveCombat(
  monsterId: string,
  outcome: "victory" | "fled",
  playerHpRemaining: number
): Promise<CombatResolution> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("resolve_combat", {
    p_monster_id: monsterId,
    p_outcome: outcome,
    p_player_hp_remaining: playerHpRemaining,
  });
  const row = data?.[0];
  if (error || !row) throw new Error(error?.message ?? "Combat couldn't be resolved.");

  return {
    newHp: row.new_hp,
    newXp: row.new_xp,
    newLevel: row.new_level,
    newGold: row.new_gold,
    leveledUp: row.leveled_up,
    loot: row.loot,
  };
}
