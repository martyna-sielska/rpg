"use client";

import { useState } from "react";
import Image from "next/image";
import { GatherNode } from "@/components/gathering/GatherNode";
import { Interactable } from "@/components/world/Interactable";
import { MonsterHotspot } from "@/components/combat/MonsterHotspot";
import { CombatOverlay } from "@/components/combat/CombatOverlay";
import { Panel } from "@/components/ui/Panel";
import type { GatheringNode, Interactable as InteractableType, Monster, Player } from "@/lib/game/types";

// Hand-placed against assets/locations/mountains.png.
const GATHER_POSITIONS: Record<string, { x: number; y: number }> = {
  mountains_frost_iron_vein: { x: 35, y: 65 },
  mountains_glacier_moss: { x: 15, y: 40 },
};

const INTERACTABLE_POSITIONS: Record<string, { x: number; y: number }> = {
  mountains_mine_entrance: { x: 24, y: 52 },
  mountains_chamber_entrance: { x: 58, y: 34 },
  mountains_puzzle_rune_1: { x: 50, y: 42 },
  mountains_puzzle_rune_2: { x: 66, y: 42 },
  mountains_recover_second_seal: { x: 74, y: 22 },
};

const BOSS_POSITION = { x: 70, y: 25 };

export function MountainsScene({
  backgroundImage,
  gatheringNodes,
  interactables,
  boss,
  bossDefeated,
  puzzleSolved,
  player,
  avatarImage,
  weaponBonus,
  potionCount,
}: {
  backgroundImage: string;
  gatheringNodes: GatheringNode[];
  interactables: InteractableType[];
  boss: Monster | null;
  bossDefeated: boolean;
  puzzleSolved: boolean;
  player: Player;
  avatarImage: string;
  weaponBonus: number;
  potionCount: number;
}) {
  const [activeMonster, setActiveMonster] = useState<Monster | null>(null);

  return (
    <div className="relative min-h-screen w-full overflow-hidden">
      <Image src={backgroundImage} alt="Frost Mountains" fill priority unoptimized className="object-cover" />
      <div className="absolute inset-0 bg-blue-950/20" />

      {gatheringNodes.map((node) => {
        const pos = GATHER_POSITIONS[node.id];
        if (!pos) return null;
        return <GatherNode key={node.id} nodeId={node.id} name={node.name} mapX={pos.x} mapY={pos.y} />;
      })}

      {interactables.map((obj) => {
        if (obj.id === "mountains_recover_second_seal" && !bossDefeated) return null;
        const pos = INTERACTABLE_POSITIONS[obj.id];
        if (!pos) return null;
        return <Interactable key={obj.id} id={obj.id} name={obj.name} mapX={pos.x} mapY={pos.y} />;
      })}

      {boss && !bossDefeated && puzzleSolved && (
        <MonsterHotspot
          id={boss.id}
          name={boss.name}
          image={boss.sprite_image}
          mapX={BOSS_POSITION.x}
          mapY={BOSS_POSITION.y}
          tier={boss.tier}
          onClick={() => setActiveMonster(boss)}
        />
      )}

      {boss && !bossDefeated && !puzzleSolved && (
        <div className="absolute bottom-6 left-1/2 -translate-x-1/2">
          <Panel className="px-4 py-2 text-center text-xs text-parchment-dark">
            The chamber&apos;s inner door stays shut. Something in this room still wants activating.
          </Panel>
        </div>
      )}

      {activeMonster && (
        <CombatOverlay
          monster={activeMonster}
          player={player}
          avatarImage={avatarImage}
          weaponBonus={weaponBonus}
          initialPotionCount={potionCount}
          onClose={() => setActiveMonster(null)}
        />
      )}
    </div>
  );
}
