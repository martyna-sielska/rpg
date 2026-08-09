"use client";

import { useTransition } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";
import { Panel } from "@/components/ui/Panel";
import { Button } from "@/components/ui/Button";
import { equipItem, unequipItem, useItemFromInventory } from "@/lib/actions/inventory";
import type { EquipSlot, Item } from "@/lib/game/types";

export function ItemDetailPanel({
  item,
  quantity,
  equippedSlot,
}: {
  item: Item;
  quantity: number;
  equippedSlot: EquipSlot | null;
}) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();

  function handleEquip() {
    startTransition(async () => {
      await equipItem(item.id);
      router.refresh();
    });
  }

  function handleUnequip() {
    if (!item.equip_slot) return;
    startTransition(async () => {
      await unequipItem(item.equip_slot as EquipSlot);
      router.refresh();
    });
  }

  function handleUse() {
    startTransition(async () => {
      await useItemFromInventory(item.id);
      router.refresh();
    });
  }

  const isEquipped = equippedSlot === item.equip_slot && item.equip_slot != null;
  const canUse = item.item_type === "consumable" && Boolean((item.consumable_effect as { heal?: number })?.heal);

  return (
    <Panel className="p-4">
      <div className="flex items-center gap-3">
        <div className="relative h-14 w-14 shrink-0">
          <Image src={item.icon_image} alt={item.name} fill sizes="56px" unoptimized className="object-contain" />
        </div>
        <div>
          <p className="font-pixel text-sm text-gold">{item.name}</p>
          <p className="text-xs text-parchment-dark">Qty: {quantity}</p>
        </div>
      </div>
      <p className="mt-3 text-sm text-parchment">{item.description}</p>

      <div className="mt-4 flex gap-2">
        {item.equip_slot && !isEquipped && (
          <Button onClick={handleEquip} disabled={isPending}>
            Equip
          </Button>
        )}
        {item.equip_slot && isEquipped && (
          <Button variant="secondary" onClick={handleUnequip} disabled={isPending}>
            Unequip
          </Button>
        )}
        {canUse && (
          <Button onClick={handleUse} disabled={isPending}>
            Use
          </Button>
        )}
      </div>
    </Panel>
  );
}
