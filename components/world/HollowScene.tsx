"use client";

import Image from "next/image";
import { Interactable } from "@/components/world/Interactable";
import { SceneFrame } from "@/components/world/SceneFrame";
import type { Interactable as InteractableType } from "@/lib/game/types";

// The Hollow reuses the Forest Dungeon's background art (the only moody
// underground-temple asset available) — a heavy hue/contrast shift makes it
// read as a genuinely different, otherworldly place rather than a literal
// revisit of dungeon_ruins.
const INTERACTABLE_POSITIONS: Record<string, { x: number; y: number }> = {
  hollow_ancient_evidence: { x: 38, y: 48 },
  hollow_origin_of_magic: { x: 62, y: 58 },
};

export function HollowScene({
  backgroundImage,
  interactables,
}: {
  backgroundImage: string;
  interactables: InteractableType[];
}) {
  return (
    <SceneFrame>
      <Image
        src={backgroundImage}
        alt="The Hollow"
        fill
        priority
        unoptimized
        className="object-cover [filter:hue-rotate(200deg)_saturate(1.7)_brightness(0.75)_contrast(1.15)]"
      />
      <div className="absolute inset-0 bg-fuchsia-950/30" />
      <div className="pointer-events-none absolute inset-0 animate-pulse bg-violet-500/5" />

      {interactables.map((obj) => {
        const pos = INTERACTABLE_POSITIONS[obj.id];
        if (!pos) return null;
        return <Interactable key={obj.id} id={obj.id} name={obj.name} mapX={pos.x} mapY={pos.y} />;
      })}
    </SceneFrame>
  );
}
