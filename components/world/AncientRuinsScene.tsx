"use client";

import Image from "next/image";
import { Interactable } from "@/components/world/Interactable";
import { DayNightOverlay } from "@/components/world/DayNightOverlay";
import { SceneFrame } from "@/components/world/SceneFrame";
import { useI18n } from "@/lib/i18n/I18nProvider";
import type { Interactable as InteractableType } from "@/lib/game/types";

// Hand-placed against assets/locations/ancient_ruins.png — covers the
// interactables for The Forgotten City (Quest 10), Three Seals (Quest 11),
// The Forge Materials (Quest 15), and The Betrayal (Quest 17). All render
// whenever present; which ones matter is driven entirely by the player's
// active quest objectives, same as the Forest's reused interactables.
const INTERACTABLE_POSITIONS: Record<string, { x: number; y: number }> = {
  ruins_inscription_1: { x: 18, y: 32 },
  ruins_inscription_2: { x: 44, y: 22 },
  ruins_inscription_3: { x: 68, y: 30 },
  ruins_temple: { x: 50, y: 58 },
  ruins_elira_secret: { x: 45, y: 53 },
  ruins_veil_records: { x: 58, y: 68 },
  ruins_maintenance_evidence: { x: 32, y: 62 },
  ruins_sabotage_evidence: { x: 76, y: 52 },
  ruins_seal_lake_confirmation: { x: 24, y: 46 },
  ruins_seal_frost_hint: { x: 52, y: 40 },
  ruins_seal_volcanic_hint: { x: 66, y: 44 },
  ruins_resonant_fragment: { x: 38, y: 74 },
};

export function AncientRuinsScene({
  backgroundImage,
  interactables,
}: {
  backgroundImage: string;
  interactables: InteractableType[];
}) {
  const { t } = useI18n();
  return (
    <SceneFrame>
      <Image src={backgroundImage} alt={t.sceneAlt.ancientRuins} fill priority unoptimized className="object-cover" />
      <div className="absolute inset-0 bg-black/15" />
      <DayNightOverlay />

      {interactables.map((obj) => {
        const pos = INTERACTABLE_POSITIONS[obj.id];
        if (!pos) return null;
        return <Interactable key={obj.id} id={obj.id} name={obj.name} mapX={pos.x} mapY={pos.y} />;
      })}
    </SceneFrame>
  );
}
