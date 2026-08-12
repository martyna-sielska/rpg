"use client";

import Image from "next/image";
import { Panel } from "@/components/ui/Panel";
import { useI18n } from "@/lib/i18n/I18nProvider";
import type { Item } from "@/lib/game/types";

export function EquipmentSlots({
  weapon,
  armor,
  trinket,
}: {
  weapon: Item | null;
  armor: Item | null;
  trinket: Item | null;
}) {
  const { t } = useI18n();
  const slots = [
    { key: "weapon", label: t.inventory.slotWeapon, item: weapon },
    { key: "armor", label: t.inventory.slotArmor, item: armor },
    { key: "trinket", label: t.inventory.slotTrinket, item: trinket },
  ];

  return (
    <Panel className="p-4">
      <h2 className="mb-3 font-pixel text-sm text-gold">{t.inventory.equipmentTitle}</h2>
      <div className="grid grid-cols-3 gap-3">
        {slots.map((slot) => (
          <div key={slot.key} className="flex flex-col items-center gap-1">
            <div className="flex h-16 w-16 items-center justify-center rounded-lg border-2 border-wood-dark bg-wood-darkest/60 p-1.5">
              {slot.item ? (
                <div className="relative h-full w-full">
                  <Image src={slot.item.icon_image} alt={slot.item.name} fill sizes="56px" unoptimized className="object-contain" />
                </div>
              ) : (
                <span className="text-xs text-parchment-dark/50">{t.inventory.emptySlot}</span>
              )}
            </div>
            <span className="text-[10px] text-parchment-dark">{slot.label}</span>
          </div>
        ))}
      </div>
    </Panel>
  );
}
