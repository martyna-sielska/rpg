"use client";

import Image from "next/image";
import { Interactable } from "@/components/world/Interactable";
import { DayNightOverlay } from "@/components/world/DayNightOverlay";
import type { Interactable as InteractableType } from "@/lib/game/types";

// Hand-placed against assets/locations/lake.png — matches the map_x/map_y
// seeded for each row in supabase/seed.sql's interactables insert, same
// convention as ForestScene's INTERACTABLE_POSITIONS.
const INTERACTABLE_POSITIONS: Record<string, { x: number; y: number }> = {
  lake_dock: { x: 30, y: 68 },
  lake_strange_lights: { x: 62, y: 38 },
  lake_boat: { x: 48, y: 78 },
  lake_underwater_evidence: { x: 40, y: 52 },
  lake_submerged_structure: { x: 72, y: 40 },
};

export function LakeScene({
  backgroundImage,
  interactables,
}: {
  backgroundImage: string;
  interactables: InteractableType[];
}) {
  return (
    <div className="relative min-h-screen w-full overflow-hidden">
      <Image src={backgroundImage} alt="Magic Lake" fill priority unoptimized className="object-cover" />
      <div className="absolute inset-0 bg-black/10" />
      <DayNightOverlay />

      {interactables.map((obj) => {
        const pos = INTERACTABLE_POSITIONS[obj.id];
        if (!pos) return null;
        return <Interactable key={obj.id} id={obj.id} name={obj.name} mapX={pos.x} mapY={pos.y} />;
      })}
    </div>
  );
}
