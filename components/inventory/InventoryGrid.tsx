"use client";

import { Panel } from "@/components/ui/Panel";
import { ItemSlot } from "@/components/inventory/ItemSlot";
import { useI18n } from "@/lib/i18n/I18nProvider";
import type { Item } from "@/lib/game/types";

export function InventoryGrid({
  entries,
  equippedIds,
  selectedItemId,
  onSelect,
}: {
  entries: { item: Item; quantity: number }[];
  equippedIds: Set<string>;
  selectedItemId: string | null;
  onSelect: (itemId: string) => void;
}) {
  const { t } = useI18n();
  return (
    <Panel className="p-4">
      <h2 className="mb-3 font-pixel text-sm text-gold">{t.inventory.title}</h2>
      {entries.length === 0 ? (
        <p className="text-sm text-parchment-dark">{t.inventory.empty}</p>
      ) : (
        <div className="grid grid-cols-5 gap-2 sm:grid-cols-6">
          {entries.map(({ item, quantity }) => (
            <ItemSlot
              key={item.id}
              item={item}
              quantity={quantity}
              equipped={equippedIds.has(item.id)}
              selected={selectedItemId === item.id}
              onClick={() => onSelect(item.id)}
            />
          ))}
        </div>
      )}
    </Panel>
  );
}
