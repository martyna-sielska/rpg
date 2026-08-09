"use client";

import Image from "next/image";
import type { Item } from "@/lib/game/types";

export function ItemSlot({
  item,
  quantity,
  equipped,
  selected,
  onClick,
}: {
  item: Item;
  quantity: number;
  equipped?: boolean;
  selected?: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`relative flex h-16 w-16 items-center justify-center rounded-lg border-2 bg-wood-darkest/60 p-1.5 transition hover:border-gold ${
        selected ? "border-gold" : "border-wood-dark"
      }`}
      title={item.name}
    >
      <div className="relative h-full w-full">
        <Image src={item.icon_image} alt={item.name} fill sizes="56px" unoptimized className="object-contain" />
      </div>
      {quantity > 1 && (
        <span className="absolute bottom-0.5 right-1 font-pixel text-[10px] text-gold drop-shadow-[0_1px_0_rgba(0,0,0,0.9)]">
          {quantity}
        </span>
      )}
      {equipped && (
        <span className="absolute -top-1.5 -right-1.5 rounded-full border border-wood-darkest bg-gold px-1 text-[8px] font-bold text-ink">
          E
        </span>
      )}
    </button>
  );
}
