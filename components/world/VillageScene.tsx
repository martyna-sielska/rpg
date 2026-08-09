"use client";

import { useState } from "react";
import Image from "next/image";
import { NpcSprite } from "@/components/npc/NpcSprite";
import { DialogueOverlay } from "@/components/npc/DialogueOverlay";
import { DayNightOverlay } from "@/components/world/DayNightOverlay";
import { useDayPhase } from "@/lib/game/useDayPhase";
import type { Npc } from "@/lib/game/types";

// Hand-placed against assets/village.png (fountain square, bakery top-left,
// blacksmith forge top-right, tavern far right) — same "hardcoded hotspot"
// approach as the Home scene, not a general placement system.
const NPC_POSITIONS: Record<string, { x: number; y: number }> = {
  elira: { x: 72, y: 62 },
  dorran: { x: 68, y: 24 },
  mira: { x: 38, y: 30 },
};

// Dorran and Mira keep shopkeeper hours; Elira (the quest giver) is always
// reachable so nothing here can block quest progress.
const NIGHT_CLOSED_NPCS = new Set(["dorran", "mira"]);

export function VillageScene({ backgroundImage, npcs }: { backgroundImage: string; npcs: Npc[] }) {
  const [activeNpcId, setActiveNpcId] = useState<string | null>(null);
  const [closedMessage, setClosedMessage] = useState<string | null>(null);
  const phase = useDayPhase();

  function handleNpcClick(npc: Npc) {
    if (phase === "night" && NIGHT_CLOSED_NPCS.has(npc.id)) {
      setClosedMessage(`${npc.name} has gone home for the night.`);
      setTimeout(() => setClosedMessage(null), 2200);
      return;
    }
    setActiveNpcId(npc.id);
  }

  const activeNpc = npcs.find((npc) => npc.id === activeNpcId) ?? null;

  return (
    <div className="relative min-h-screen w-full overflow-hidden">
      <Image src={backgroundImage} alt="Village" fill priority unoptimized className="object-cover" />
      <div className="absolute inset-0 bg-black/10" />
      <DayNightOverlay />

      {npcs.map((npc) => {
        const pos = NPC_POSITIONS[npc.id];
        if (!pos) return null;
        const closed = phase === "night" && NIGHT_CLOSED_NPCS.has(npc.id);
        return (
          <div key={npc.id} className={closed ? "opacity-40 grayscale" : ""}>
            <NpcSprite
              name={npc.name}
              role={npc.role}
              portraitImage={npc.portrait_image}
              mapX={pos.x}
              mapY={pos.y}
              onClick={() => handleNpcClick(npc)}
            />
          </div>
        );
      })}

      {closedMessage && (
        <div className="pointer-events-none fixed inset-x-0 bottom-8 flex justify-center">
          <div className="rounded-lg border-2 border-wood-dark bg-wood-darkest/95 px-4 py-2 text-sm text-parchment shadow-lg">
            {closedMessage}
          </div>
        </div>
      )}

      {activeNpc && (
        <DialogueOverlay npcId={activeNpc.id} portraitImage={activeNpc.portrait_image} onClose={() => setActiveNpcId(null)} />
      )}
    </div>
  );
}
