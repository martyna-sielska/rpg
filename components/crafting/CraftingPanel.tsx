"use client";

import { Panel } from "@/components/ui/Panel";
import { RecipeCard } from "@/components/crafting/RecipeCard";
import { useI18n } from "@/lib/i18n/I18nProvider";
import type { Item } from "@/lib/game/types";

export interface RecipeView {
  id: string;
  outputItem: Item;
  outputQuantity: number;
  requiredLevel: number;
  ingredients: { item: Item; required: number; owned: number }[];
}

export function CraftingPanel({ recipes, playerLevel }: { recipes: RecipeView[]; playerLevel: number }) {
  const { t } = useI18n();
  return (
    <Panel className="p-4">
      <h2 className="mb-3 font-pixel text-sm text-gold">{t.crafting.title}</h2>
      {recipes.length === 0 ? (
        <p className="text-sm text-parchment-dark">{t.crafting.none}</p>
      ) : (
        <div className="flex flex-col gap-2">
          {recipes.map((r) => (
            <RecipeCard
              key={r.id}
              recipeId={r.id}
              outputItem={r.outputItem}
              outputQuantity={r.outputQuantity}
              ingredients={r.ingredients}
              canAfford={playerLevel >= r.requiredLevel && r.ingredients.every((ing) => ing.owned >= ing.required)}
            />
          ))}
        </div>
      )}
    </Panel>
  );
}
