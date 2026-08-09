"use client";

import { useState } from "react";
import { EquipmentSlots } from "@/components/inventory/EquipmentSlots";
import { InventoryGrid } from "@/components/inventory/InventoryGrid";
import { ItemDetailPanel } from "@/components/inventory/ItemDetailPanel";
import { CraftingPanel, type RecipeView } from "@/components/crafting/CraftingPanel";
import type { EquipSlot, Item } from "@/lib/game/types";

export function InventoryScreen({
  entries,
  weapon,
  armor,
  trinket,
  recipes,
  playerLevel,
}: {
  entries: { item: Item; quantity: number }[];
  weapon: Item | null;
  armor: Item | null;
  trinket: Item | null;
  recipes: RecipeView[];
  playerLevel: number;
}) {
  const [selectedItemId, setSelectedItemId] = useState<string | null>(null);
  const selected = entries.find((e) => e.item.id === selectedItemId) ?? null;

  const equippedIds = new Set([weapon?.id, armor?.id, trinket?.id].filter(Boolean) as string[]);
  const equippedSlotByItemId: Record<string, EquipSlot> = {};
  if (weapon) equippedSlotByItemId[weapon.id] = "weapon";
  if (armor) equippedSlotByItemId[armor.id] = "armor";
  if (trinket) equippedSlotByItemId[trinket.id] = "trinket";

  return (
    <div className="grid gap-4 md:grid-cols-[280px_1fr]">
      <div className="flex flex-col gap-4">
        <EquipmentSlots weapon={weapon} armor={armor} trinket={trinket} />
        {selected && (
          <ItemDetailPanel
            item={selected.item}
            quantity={selected.quantity}
            equippedSlot={equippedSlotByItemId[selected.item.id] ?? null}
          />
        )}
      </div>
      <div className="flex flex-col gap-4">
        <InventoryGrid entries={entries} equippedIds={equippedIds} selectedItemId={selectedItemId} onSelect={setSelectedItemId} />
        <CraftingPanel recipes={recipes} playerLevel={playerLevel} />
      </div>
    </div>
  );
}
