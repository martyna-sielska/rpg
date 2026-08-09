"use client";

import Image from "next/image";
import type { MonsterTier } from "@/lib/game/types";
import { getHotspotSizeClasses, getMonsterIdleAnimationClass, getMonsterScale } from "@/lib/game/monsterIdle";

export function MonsterHotspot({
  id,
  name,
  image,
  mapX,
  mapY,
  tier,
  defeated,
  onClick,
}: {
  id: string;
  name: string;
  image: string;
  mapX: number;
  mapY: number;
  tier?: MonsterTier;
  defeated?: boolean;
  onClick: () => void;
}) {
  if (defeated) return null;

  const scale = getMonsterScale(id, tier);
  const idleAnimationClass = getMonsterIdleAnimationClass(id, tier);

  return (
    <button
      type="button"
      onClick={onClick}
      className="group absolute flex -translate-x-1/2 -translate-y-1/2 flex-col items-center gap-1"
      style={{ left: `${mapX}%`, top: `${mapY}%` }}
    >
      <div className={idleAnimationClass}>
        <div
          className={`relative drop-shadow-[0_4px_10px_rgba(0,0,0,0.6)] transition group-hover:scale-110 ${getHotspotSizeClasses(scale)}`}
        >
          <Image src={image} alt={name} fill sizes="96px" unoptimized className="object-contain" />
        </div>
      </div>
      <div className="pointer-events-none whitespace-nowrap rounded-md border-2 border-wood-dark bg-wood-darkest/90 px-2 py-0.5 text-[10px] font-semibold text-parchment opacity-0 shadow-lg transition group-hover:opacity-100">
        {name}
      </div>
    </button>
  );
}
