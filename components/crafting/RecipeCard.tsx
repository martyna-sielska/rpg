"use client";

import { useTransition } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";
import { Button } from "@/components/ui/Button";
import { craftRecipe } from "@/lib/actions/inventory";
import type { Item } from "@/lib/game/types";

export function RecipeCard({
  recipeId,
  outputItem,
  outputQuantity,
  ingredients,
  canAfford,
}: {
  recipeId: string;
  outputItem: Item;
  outputQuantity: number;
  ingredients: { item: Item; required: number; owned: number }[];
  canAfford: boolean;
}) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();

  function handleCraft() {
    startTransition(async () => {
      try {
        await craftRecipe(recipeId);
        router.refresh();
      } catch {
        // ingredient/level race — the disabled state normally prevents this
      }
    });
  }

  return (
    <div className="flex items-center gap-3 rounded-lg border-2 border-wood-dark bg-wood-darkest/40 p-3">
      <div className="relative h-12 w-12 shrink-0">
        <Image src={outputItem.icon_image} alt={outputItem.name} fill sizes="48px" unoptimized className="object-contain" />
      </div>
      <div className="min-w-0 flex-1">
        <p className="text-sm font-semibold text-parchment">
          {outputItem.name} {outputQuantity > 1 ? `×${outputQuantity}` : ""}
        </p>
        <p className="text-xs text-parchment-dark">
          {ingredients.map((ing, i) => (
            <span key={ing.item.id} className={ing.owned >= ing.required ? "" : "text-hp"}>
              {i > 0 ? ", " : ""}
              {ing.required}× {ing.item.name} ({ing.owned}/{ing.required})
            </span>
          ))}
        </p>
      </div>
      <Button onClick={handleCraft} disabled={!canAfford || isPending} className="shrink-0 px-3 py-1.5 text-xs">
        Craft
      </Button>
    </div>
  );
}
