"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { getDictionary } from "@/lib/i18n/getDictionary";
import type { ConsumableEffect } from "@/lib/game/database.types";

export interface GatherResult {
  itemId: string;
  quantity: number;
}

export async function gatherNode(nodeId: string): Promise<GatherResult> {
  const supabase = await createClient();
  const t = await getDictionary();
  const { data, error } = await supabase.rpc("gather_node", { p_node_id: nodeId });
  const row = data?.[0];
  if (error || !row) {
    if (error?.message === "This node has not respawned yet") throw new Error(t.gather.notRespawnedYet);
    throw new Error(error?.message ?? t.gather.nothingToGather);
  }

  revalidatePath("/inventory");
  return { itemId: row.out_item_id, quantity: row.out_quantity };
}

export async function equipItem(itemId: string): Promise<void> {
  const supabase = await createClient();
  const { error } = await supabase.rpc("equip_item", { p_item_id: itemId });
  if (error) throw new Error(error.message);

  revalidatePath("/character");
  revalidatePath("/inventory");
}

export async function unequipItem(slot: "weapon" | "armor" | "trinket"): Promise<void> {
  const supabase = await createClient();
  const { error } = await supabase.rpc("unequip_item", { p_slot: slot });
  if (error) throw new Error(error.message);

  revalidatePath("/character");
  revalidatePath("/inventory");
}

export async function craftRecipe(recipeId: string): Promise<{ itemId: string; quantity: number }> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("craft_item", { p_recipe_id: recipeId });
  const row = data?.[0];
  if (error || !row) throw new Error(error?.message ?? "Couldn't craft that.");

  revalidatePath("/inventory");
  return { itemId: row.out_item_id, quantity: row.out_quantity };
}

/** Drinking a potion from the Inventory screen (outside combat) — unlike
 * useHealingPotion below, this applies the heal straight to players.hp
 * since there's no combat reducer state to reconcile it with afterward. */
export async function useItemFromInventory(itemId: string): Promise<{ healed: number }> {
  const supabase = await createClient();
  const t = await getDictionary();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) throw new Error(t.inventory.errors.notAuthenticated);

  const { data: item } = await supabase.from("items").select("consumable_effect").eq("id", itemId).single();
  const effect = (item?.consumable_effect ?? {}) as ConsumableEffect;
  if (!effect.heal) throw new Error(t.inventory.errors.cannotUseItem);

  const { data: inv } = await supabase
    .from("player_inventory")
    .select("*")
    .eq("player_id", user.id)
    .eq("item_id", itemId)
    .maybeSingle();
  if (!inv || inv.quantity < 1) throw new Error(t.inventory.errors.noneLeft);

  if (inv.quantity <= 1) {
    await supabase.from("player_inventory").delete().eq("id", inv.id);
  } else {
    await supabase.from("player_inventory").update({ quantity: inv.quantity - 1 }).eq("id", inv.id);
  }

  const { data: player } = await supabase.from("players").select("hp, max_hp").eq("id", user.id).single();
  if (player) {
    const newHp = Math.min(player.max_hp, player.hp + effect.heal);
    await supabase.from("players").update({ hp: newHp }).eq("id", user.id);
  }

  revalidatePath("/inventory");
  revalidatePath("/character");
  return { healed: effect.heal };
}

/**
 * Consumes one healing_potion from the player's inventory immediately
 * (not batched with the rest of a fight) so inventory state stays correct
 * even if the browser closes mid-combat. The HP gain itself is applied
 * client-side to the combat reducer's local hp, then flushed to the server
 * once via resolveCombat when the fight ends.
 */
export async function useHealingPotion(): Promise<{ healed: number }> {
  const supabase = await createClient();
  const t = await getDictionary();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) throw new Error(t.inventory.errors.notAuthenticated);

  const { data: inv } = await supabase
    .from("player_inventory")
    .select("*")
    .eq("player_id", user.id)
    .eq("item_id", "healing_potion")
    .maybeSingle();

  if (!inv || inv.quantity < 1) throw new Error(t.inventory.errors.noPotionsLeft);

  if (inv.quantity <= 1) {
    await supabase.from("player_inventory").delete().eq("id", inv.id);
  } else {
    await supabase.from("player_inventory").update({ quantity: inv.quantity - 1 }).eq("id", inv.id);
  }

  const { data: item } = await supabase.from("items").select("consumable_effect").eq("id", "healing_potion").single();
  const effect = (item?.consumable_effect ?? {}) as ConsumableEffect;

  revalidatePath("/inventory");
  return { healed: effect.heal ?? 0 };
}
