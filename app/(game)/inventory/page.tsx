import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { getCurrentPlayer } from "@/lib/game/data";
import { InventoryScreen } from "@/components/inventory/InventoryScreen";
import type { RecipeView } from "@/components/crafting/CraftingPanel";
import type { Item } from "@/lib/game/types";

export const metadata: Metadata = { title: "Inventory — Wonderhill" };

export default async function InventoryPage() {
  const player = await getCurrentPlayer();
  const supabase = await createClient();

  const [
    { data: inventoryRows },
    { data: allItems },
    { data: equipment },
    { data: recipes },
    { data: recipeIngredients },
  ] = await Promise.all([
    supabase.from("player_inventory").select("*").eq("player_id", player.id),
    supabase.from("items").select("*"),
    supabase.from("player_equipment").select("*").eq("player_id", player.id).maybeSingle(),
    supabase.from("crafting_recipes").select("*"),
    supabase.from("crafting_recipe_ingredients").select("*"),
  ]);

  const itemsById = new Map<string, Item>((allItems ?? []).map((i) => [i.id, i]));
  const ownedQtyByItemId = new Map<string, number>((inventoryRows ?? []).map((r) => [r.item_id, r.quantity]));

  const entries = (inventoryRows ?? [])
    .map((row) => {
      const item = itemsById.get(row.item_id);
      return item ? { item, quantity: row.quantity } : null;
    })
    .filter((e): e is { item: Item; quantity: number } => e != null);

  const weapon = equipment?.weapon_item_id ? (itemsById.get(equipment.weapon_item_id) ?? null) : null;
  const armor = equipment?.armor_item_id ? (itemsById.get(equipment.armor_item_id) ?? null) : null;
  const trinket = equipment?.trinket_item_id ? (itemsById.get(equipment.trinket_item_id) ?? null) : null;

  const recipeViews: RecipeView[] = (recipes ?? [])
    .map((recipe) => {
      const outputItem = itemsById.get(recipe.output_item_id);
      if (!outputItem) return null;
      const ingredients = (recipeIngredients ?? [])
        .filter((ri) => ri.recipe_id === recipe.id)
        .map((ri) => {
          const ingredientItem = itemsById.get(ri.item_id);
          if (!ingredientItem) return null;
          return { item: ingredientItem, required: ri.quantity, owned: ownedQtyByItemId.get(ri.item_id) ?? 0 };
        })
        .filter((i): i is { item: Item; required: number; owned: number } => i != null);

      return {
        id: recipe.id,
        outputItem,
        outputQuantity: recipe.output_quantity,
        requiredLevel: recipe.required_level,
        ingredients,
      };
    })
    .filter((r): r is RecipeView => r != null);

  return (
    <div className="mx-auto min-h-screen max-w-4xl px-4 pb-10 pt-24">
      <InventoryScreen
        entries={entries}
        weapon={weapon}
        armor={armor}
        trinket={trinket}
        recipes={recipeViews}
        playerLevel={player.level}
      />
    </div>
  );
}
