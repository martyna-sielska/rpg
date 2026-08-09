"use client";

import Image from "next/image";
import { Interactable } from "@/components/world/Interactable";
import type { Interactable as InteractableType } from "@/lib/game/types";

// Hand-placed against assets/locations/castle_archive.png — the full,
// uncropped castleinside.png (1264x843, the same size as every other
// location background): throne room top-left, dining hall center, library/
// archive on the right (upper shelves + rune circles, curving down into a
// lower gallery with the world map), armory bottom-center. Covers The
// King's Archive (Quest 12) and The Betrayal (Quest 17). No day/night tint
// here — an indoor archive stays lit regardless of the hour.
const INTERACTABLE_POSITIONS: Record<string, { x: number; y: number }> = {
  castle_archive_doors: { x: 43, y: 13 },
  castle_old_records: { x: 75, y: 12 },
  castle_missing_pages: { x: 95, y: 10 },
  castle_frost_reference: { x: 78, y: 68 },
  castle_volcanic_reference: { x: 95, y: 62 },
  castle_hidden_documents_1: { x: 48, y: 45 },
  castle_hidden_documents_2: { x: 58, y: 52 },
  castle_antagonist_plan: { x: 85, y: 25 },
  castle_confrontation: { x: 12, y: 20 },
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
