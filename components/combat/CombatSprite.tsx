"use client";

import Image from "next/image";
import { ProgressBar } from "@/components/ui/ProgressBar";

export function CombatSprite({
  name,
  image,
  hp,
  maxHp,
  hitKey,
  telegraphing,
  defeated,
  align,
  sizeClassName,
  idleAnimationClass,
}: {
  name: string;
  image: string;
  hp: number;
  maxHp: number;
  hitKey: number;
  telegraphing: boolean;
  defeated: boolean;
  align: "left" | "right";
  sizeClassName?: string;
  idleAnimationClass?: string;
}) {
  return (
    <div className={`flex flex-col items-center gap-2 ${align === "right" ? "items-end" : "items-start"}`}>
      <div className="w-36 sm:w-44">
        <ProgressBar value={hp} max={maxHp} color="hp" label={name} />
      </div>
      <div className={defeated ? "" : idleAnimationClass}>
        <div
          key={hitKey}
          className={`relative ${sizeClassName ?? "h-32 w-28 sm:h-40 sm:w-32"} ${
            hitKey > 0 ? "animate-hit-flash" : ""
          } ${telegraphing ? "animate-telegraph rounded-full" : ""} ${
            defeated ? "opacity-0 transition-opacity duration-700" : "opacity-100"
          }`}
        >
          <Image src={image} alt={name} fill sizes="192px" unoptimized className="object-contain" />
        </div>
      </div>
    </div>
  );
}
