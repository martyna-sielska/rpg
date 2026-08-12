"use client";

import Image from "next/image";
import { Interactable } from "@/components/world/Interactable";
import { SceneFrame } from "@/components/world/SceneFrame";
import { useI18n } from "@/lib/i18n/I18nProvider";
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
  castle_old_records: { x: 75, y: 19 },
  castle_missing_pages: { x: 95, y: 17 },
  castle_frost_reference: { x: 82, y: 63 },
  castle_volcanic_reference: { x: 88, y: 42 },
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
  const { t } = useI18n();
  return (
    <SceneFrame>
      <Image src={backgroundImage} alt={t.sceneAlt.castle} fill priority unoptimized className="object-cover" />
      <div className="absolute inset-0 bg-black/10" />

      {interactables.map((obj) => {
        const pos = INTERACTABLE_POSITIONS[obj.id];
        if (!pos) return null;
        return <Interactable key={obj.id} id={obj.id} name={obj.name} mapX={pos.x} mapY={pos.y} />;
      })}
    </SceneFrame>
  );
}
