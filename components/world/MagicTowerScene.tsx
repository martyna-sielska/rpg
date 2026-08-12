"use client";

import { useState } from "react";
import Image from "next/image";
import { NpcSprite } from "@/components/npc/NpcSprite";
import { DialogueOverlay } from "@/components/npc/DialogueOverlay";
import { Interactable } from "@/components/world/Interactable";
import { DayNightOverlay } from "@/components/world/DayNightOverlay";
import { SceneFrame } from "@/components/world/SceneFrame";
import type { Interactable as InteractableType, Npc } from "@/lib/game/types";

// Hand-placed against assets/locations/magic_tower.png.
const INTERACTABLE_POSITIONS: Record<string, { x: number; y: number }> = {
  tower_ancient_records_1: { x: 28, y: 32 },
  tower_ancient_records_2: { x: 66, y: 50 },
};

const SCHOLAR_POSITION = { x: 50, y: 62 };

export function MagicTowerScene({
  backgroundImage,
  scholar,
  interactables,
}: {
  backgroundImage: string;
  scholar: Npc | null;
  interactables: InteractableType[];
}) {
  const [talkingToScholar, setTalkingToScholar] = useState(false);

  return (
    <SceneFrame>
      <Image src={backgroundImage} alt="Magic Tower" fill priority unoptimized className="object-cover" />
      <div className="absolute inset-0 bg-black/20" />
      <DayNightOverlay />

      {scholar && (
        <NpcSprite
          name={scholar.name}
          role={scholar.role}
          portraitImage={scholar.portrait_image}
          mapX={SCHOLAR_POSITION.x}
          mapY={SCHOLAR_POSITION.y}
          onClick={() => setTalkingToScholar(true)}
        />
      )}

      {interactables.map((obj) => {
        const pos = INTERACTABLE_POSITIONS[obj.id];
        if (!pos) return null;
        return <Interactable key={obj.id} id={obj.id} name={obj.name} mapX={pos.x} mapY={pos.y} />;
      })}

      {talkingToScholar && scholar && (
        <DialogueOverlay npcId={scholar.id} portraitImage={scholar.portrait_image} onClose={() => setTalkingToScholar(false)} />
      )}
    </SceneFrame>
  );
}
