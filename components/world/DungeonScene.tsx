"use client";

import { useState } from "react";
import Image from "next/image";
import { Interactable } from "@/components/world/Interactable";
import { MonsterHotspot } from "@/components/combat/MonsterHotspot";
import { CombatOverlay } from "@/components/combat/CombatOverlay";
import { Panel } from "@/components/ui/Panel";
import { SceneFrame } from "@/components/world/SceneFrame";
import type { Interactable as InteractableType, Monster, Player } from "@/lib/game/types";

// Hand-placed against assets/locations/dungeon.png — the miniboss guards
// the locked door area, the boss waits in the rune-circle room deeper in.
const MONSTER_POSITIONS: Record<string, { x: number; y: number }> = {
  bramble_warden: { x: 48, y: 18 },
  fading_shadow: { x: 88, y: 78 },
};

const INTERACTABLE_POSITIONS: Record<string, { x: number; y: number }> = {
  dungeon_mira_connection: { x: 30, y: 55 },
};

export function DungeonScene({
  backgroundImage,
  interactables,
  miniboss,
  boss,
  minibossDefeated,
  bossDefeated,
  player,
  avatarImage,
  weaponBonus,
  potionCount,
}: {
  backgroundImage: string;
  interactables: InteractableType[];
  miniboss: Monster | null;
  boss: Monster | null;
  minibossDefeated: boolean;
  bossDefeated: boolean;
  player: Player;
  avatarImage: string;
  weaponBonus: number;
  potionCount: number;
}) {
  const [activeMonster, setActiveMonster] = useState<Monster | null>(null);

  return (
    <SceneFrame>
      <Image src={backgroundImage} alt="Forest Dungeon" fill priority unoptimized className="object-cover" />
      <div className="absolute inset-0 bg-black/25" />

      {interactables.map((obj) => {
        const pos = INTERACTABLE_POSITIONS[obj.id];
        if (!pos) return null;
        return <Interactable key={obj.id} id={obj.id} name={obj.name} mapX={pos.x} mapY={pos.y} />;
      })}

      {miniboss && !minibossDefeated && (
        <MonsterHotspot
          id={miniboss.id}
          name={miniboss.name}
          image={miniboss.sprite_image}
          mapX={MONSTER_POSITIONS.bramble_warden.x}
          mapY={MONSTER_POSITIONS.bramble_warden.y}
          tier={miniboss.tier}
          onClick={() => setActiveMonster(miniboss)}
        />
      )}

      {boss && !bossDefeated && minibossDefeated && (
        <MonsterHotspot
          id={boss.id}
          name={boss.name}
          image={boss.sprite_image}
          mapX={MONSTER_POSITIONS.fading_shadow.x}
          mapY={MONSTER_POSITIONS.fading_shadow.y}
          tier={boss.tier}
          onClick={() => setActiveMonster(boss)}
        />
      )}

      {boss && !bossDefeated && !minibossDefeated && (
        <div className="absolute bottom-6 left-1/2 -translate-x-1/2">
          <Panel className="px-4 py-2 text-center text-xs text-parchment-dark">
            Something deeper in the ruins stirs — but the Bramble Warden blocks the way.
          </Panel>
        </div>
      )}

      {minibossDefeated && bossDefeated && (
        <div className="absolute bottom-6 left-1/2 -translate-x-1/2">
          <Panel className="px-4 py-2 text-center text-xs text-parchment-dark">
            The ruins have gone quiet. You've cleared this place — for now.
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
    </SceneFrame>
  );
}
