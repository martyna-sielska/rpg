"use client";

import { useState } from "react";
import Image from "next/image";
import { GatherNode } from "@/components/gathering/GatherNode";
import { MonsterHotspot } from "@/components/combat/MonsterHotspot";
import { CombatOverlay } from "@/components/combat/CombatOverlay";
import { DayNightOverlay } from "@/components/world/DayNightOverlay";
import { Interactable } from "@/components/world/Interactable";
import type { GatheringNode, Interactable as InteractableType, Monster, Player } from "@/lib/game/types";

// Hand-placed against assets/forest.png (crystal cluster + treasure chest
// top-left, glowing mushrooms bottom-left, mossy rocks center for the slime,
// guardian statue on the right for the ember) — same hardcoded hotspot
// approach used everywhere else in the vertical slice.
const GATHER_POSITIONS: Record<string, { x: number; y: number }> = {
  forest_crystal_cluster: { x: 13, y: 24 },
  forest_glowing_mushrooms: { x: 9, y: 70 },
  forest_deadwood: { x: 45, y: 40 },
  forest_iron_vein: { x: 60, y: 30 },
};

const MONSTER_POSITIONS: Record<string, { x: number; y: number }> = {
  bog_slime: { x: 30, y: 64 },
  wild_ember: { x: 80, y: 62 },
};

// Positions match the map_x/map_y seeded for each row in supabase/seed.sql's
// interactables insert — kept in sync by hand, same as GATHER_POSITIONS above.
const INTERACTABLE_POSITIONS: Record<string, { x: number; y: number }> = {
  forest_strange_traces: { x: 25, y: 45 },
  forest_corrupted_plants: { x: 50, y: 75 },
  forest_strange_crystals: { x: 65, y: 55 },
  forest_ancient_markings: { x: 75, y: 35 },
  ancient_gate: { x: 90, y: 20 },
};

export function ForestScene({
  backgroundImage,
  gatheringNodes,
  monsters,
  interactables,
  player,
  avatarImage,
  weaponBonus,
  potionCount,
}: {
  backgroundImage: string;
  gatheringNodes: GatheringNode[];
  monsters: Monster[];
  interactables: InteractableType[];
  player: Player;
  avatarImage: string;
  weaponBonus: number;
  potionCount: number;
}) {
  const [activeMonster, setActiveMonster] = useState<Monster | null>(null);

  return (
    <div className="relative min-h-screen w-full overflow-hidden">
      <Image src={backgroundImage} alt="Enchanted Forest" fill priority unoptimized className="object-cover" />
      <div className="absolute inset-0 bg-black/10" />
      <DayNightOverlay />

      {gatheringNodes.map((node) => {
        const pos = GATHER_POSITIONS[node.id];
        if (!pos) return null;
        return <GatherNode key={node.id} nodeId={node.id} name={node.name} mapX={pos.x} mapY={pos.y} />;
      })}

      {monsters.map((monster) => {
        const pos = MONSTER_POSITIONS[monster.id];
        if (!pos) return null;
        return (
          <MonsterHotspot
            key={monster.id}
            id={monster.id}
            name={monster.name}
            image={monster.sprite_image}
            mapX={pos.x}
            mapY={pos.y}
            tier={monster.tier}
            onClick={() => setActiveMonster(monster)}
          />
        );
      })}

      {interactables.map((obj) => {
        const pos = INTERACTABLE_POSITIONS[obj.id];
        if (!pos) return null;
        return <Interactable key={obj.id} id={obj.id} name={obj.name} mapX={pos.x} mapY={pos.y} />;
      })}

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
