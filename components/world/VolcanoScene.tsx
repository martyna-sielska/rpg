"use client";

import { useState } from "react";
import Image from "next/image";
import { GatherNode } from "@/components/gathering/GatherNode";
import { Interactable } from "@/components/world/Interactable";
import { MonsterHotspot } from "@/components/combat/MonsterHotspot";
import { CombatOverlay } from "@/components/combat/CombatOverlay";
import { Panel } from "@/components/ui/Panel";
import type { GatheringNode, Interactable as InteractableType, Monster, Player } from "@/lib/game/types";

// Hand-placed against assets/locations/volcano.png. Interactables here span
// The Ancient Forge (Quest 14) and The Third Seal (Quest 16) — all render
// flatly, same convention as the Ancient Ruins scene.
const GATHER_POSITIONS: Record<string, { x: number; y: number }> = {
  volcano_glass_deposit: { x: 45, y: 70 },
};

const INTERACTABLE_POSITIONS: Record<string, { x: number; y: number }> = {
  volcano_entrance: { x: 28, y: 58 },
  volcano_forge: { x: 52, y: 44 },
  volcano_forge_tablet: { x: 62, y: 40 },
  volcano_deep_ruins: { x: 72, y: 26 },
  volcano_recent_visitor: { x: 40, y: 22 },
  volcano_interference: { x: 56, y: 18 },
  volcano_seal_chamber: { x: 80, y: 16 },
  volcano_recover_third_seal: { x: 86, y: 12 },
};

const BOSS_POSITION = { x: 82, y: 14 };

export function VolcanoScene({
  backgroundImage,
  gatheringNodes,
  itemIcons,
  interactables,
  boss,
  bossDefeated,
  chamberReached,
  player,
  avatarImage,
  weaponBonus,
  potionCount,
}: {
  backgroundImage: string;
  gatheringNodes: GatheringNode[];
  itemIcons: Record<string, string>;
  interactables: InteractableType[];
  boss: Monster | null;
  bossDefeated: boolean;
  chamberReached: boolean;
  player: Player;
  avatarImage: string;
  weaponBonus: number;
  potionCount: number;
}) {
  const [activeMonster, setActiveMonster] = useState<Monster | null>(null);

  return (
    <div className="relative min-h-screen w-full overflow-hidden">
      <Image src={backgroundImage} alt="Volcano" fill priority unoptimized className="object-cover" />
      <div className="absolute inset-0 bg-orange-950/20" />

      {gatheringNodes.map((node) => {
        const pos = GATHER_POSITIONS[node.id];
        if (!pos) return null;
        return (
          <GatherNode
            key={node.id}
            nodeId={node.id}
            name={node.name}
            iconImage={itemIcons[node.item_id] ?? "/assets/items/crystal_shard.png"}
            mapX={pos.x}
            mapY={pos.y}
          />
        );
      })}

      {interactables.map((obj) => {
        if (obj.id === "volcano_recover_third_seal" && !bossDefeated) return null;
        const pos = INTERACTABLE_POSITIONS[obj.id];
        if (!pos) return null;
        return <Interactable key={obj.id} id={obj.id} name={obj.name} mapX={pos.x} mapY={pos.y} />;
      })}

      {boss && !bossDefeated && chamberReached && (
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

      {boss && !bossDefeated && !chamberReached && (
        <div className="absolute bottom-6 left-1/2 -translate-x-1/2">
          <Panel className="px-4 py-2 text-center text-xs text-parchment-dark">
            Heat rolls up from deeper in the volcano. Whatever guards the seal chamber is still out of reach.
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
