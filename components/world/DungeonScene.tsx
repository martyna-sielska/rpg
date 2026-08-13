"use client";

import { useState } from "react";
import Image from "next/image";
import { Interactable } from "@/components/world/Interactable";
import { MonsterHotspot } from "@/components/combat/MonsterHotspot";
import { CombatOverlay } from "@/components/combat/CombatOverlay";
import { Panel } from "@/components/ui/Panel";
import { SceneFrame } from "@/components/world/SceneFrame";
import { useI18n } from "@/lib/i18n/I18nProvider";
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
  bossQuestActive,
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
  // Whether "The Ancient Gate" (the quest that introduces fading_shadow) is
  // currently the player's active/ready-to-turn-in quest — see the matching
  // note in VolcanoScene/MountainsScene for why this gate exists:
  // defeat_monster only progresses objectives of the player's currently
  // *active* quests, and a defeated boss's hotspot never comes back, so
  // beating it before the quest is active would permanently unwinnable that
  // objective.
  bossQuestActive: boolean;
  player: Player;
  avatarImage: string;
  weaponBonus: number;
  potionCount: number;
}) {
  const [activeMonster, setActiveMonster] = useState<Monster | null>(null);
  const { t } = useI18n();

  return (
    <SceneFrame>
      <Image src={backgroundImage} alt={t.sceneAlt.dungeon} fill priority unoptimized className="object-cover" />
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

      {boss && !bossDefeated && minibossDefeated && bossQuestActive && (
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
          <Panel className="px-4 py-2 text-center text-xs text-parchment-dark">{t.dungeon.minibossBlocking}</Panel>
        </div>
      )}

      {boss && !bossDefeated && minibossDefeated && !bossQuestActive && (
        <div className="absolute bottom-6 left-1/2 -translate-x-1/2">
          <Panel className="px-4 py-2 text-center text-xs text-parchment-dark">{t.dungeon.bossLocked}</Panel>
        </div>
      )}

      {minibossDefeated && bossDefeated && (
        <div className="absolute bottom-6 left-1/2 -translate-x-1/2">
          <Panel className="px-4 py-2 text-center text-xs text-parchment-dark">{t.dungeon.cleared}</Panel>
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
