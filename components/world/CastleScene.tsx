"use client";

import Image from "next/image";
import { Interactable } from "@/components/world/Interactable";
import type { Interactable as InteractableType } from "@/lib/game/types";

// Hand-placed against assets/locations/castle_archive.png (a landscape
// (844x560, same ~1.5 aspect as every other location background) crop of
// castleinside.png spanning the dining hall on the left and the full
// library/archive on the right) — covers The King's Archive (Quest 12) and
// The Betrayal (Quest 17). No day/night tint here — an indoor archive stays
// lit regardless of the hour.
const INTERACTABLE_POSITIONS: Record<string, { x: number; y: number }> = {
  castle_archive_doors: { x: 15, y: 15 },
  castle_old_records: { x: 55, y: 15 },
  castle_missing_pages: { x: 90, y: 15 },
  castle_frost_reference: { x: 65, y: 65 },
  castle_volcanic_reference: { x: 85, y: 65 },
  castle_hidden_documents_1: { x: 25, y: 70 },
  castle_hidden_documents_2: { x: 45, y: 78 },
  castle_antagonist_plan: { x: 62, y: 35 },
  castle_confrontation: { x: 12, y: 40 },
};

export function CastleScene({
  backgroundImage,
  interactables,
}: {
  backgroundImage: string;
  interactables: InteractableType[];
}) {
  return (
    <div className="relative min-h-screen w-full overflow-hidden">
      <Image src={backgroundImage} alt="The Castle Archive" fill priority unoptimized className="object-cover" />
      <div className="absolute inset-0 bg-black/10" />

      {interactables.map((obj) => {
        const pos = INTERACTABLE_POSITIONS[obj.id];
        if (!pos) return null;
        return <Interactable key={obj.id} id={obj.id} name={obj.name} mapX={pos.x} mapY={pos.y} />;
      })}
    </div>
  );
}
