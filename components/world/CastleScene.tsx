"use client";

import Image from "next/image";
import { Interactable } from "@/components/world/Interactable";
import type { Interactable as InteractableType } from "@/lib/game/types";

// Hand-placed against assets/locations/castle_archive.png (cropped from the
// castle's library/archive room) — covers The King's Archive (Quest 12) and
// The Betrayal (Quest 17). No day/night tint here — an indoor archive stays
// lit regardless of the hour.
const INTERACTABLE_POSITIONS: Record<string, { x: number; y: number }> = {
  castle_archive_doors: { x: 50, y: 82 },
  castle_old_records: { x: 22, y: 32 },
  castle_missing_pages: { x: 56, y: 24 },
  castle_frost_reference: { x: 30, y: 58 },
  castle_volcanic_reference: { x: 64, y: 58 },
  castle_hidden_documents_1: { x: 40, y: 42 },
  castle_hidden_documents_2: { x: 70, y: 44 },
  castle_antagonist_plan: { x: 52, y: 18 },
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
