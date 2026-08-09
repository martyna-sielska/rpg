import type { AttackPattern } from "@/lib/game/database.types";
import type { Monster, Player } from "@/lib/game/types";

/**
 * Pure combat math — no Supabase calls, safe to run inside a client
 * component's useReducer. The server (resolve_combat RPC) is still the
 * authority on rewards/loot; this only drives the real-time fight itself.
 */

const BASE_PLAYER_ATTACK = 6;
const STRENGTH_DAMAGE_FACTOR = 1.4;
const SKILL_MULTIPLIER = 1.8;
const SKILL_COOLDOWN_MS = 3200;
const ATTACK_COOLDOWN_MS = 650;
const DODGE_COOLDOWN_MS = 900;
const DODGE_WINDOW_MS = 500;
const DEFAULT_TELEGRAPH_MS = 900;
const MONSTER_ACTION_PAUSE_MS = 1600;

export const COMBAT_TIMING = {
  attackCooldownMs: ATTACK_COOLDOWN_MS,
  skillCooldownMs: SKILL_COOLDOWN_MS,
  dodgeCooldownMs: DODGE_COOLDOWN_MS,
  dodgeWindowMs: DODGE_WINDOW_MS,
  monsterActionPauseMs: MONSTER_ACTION_PAUSE_MS,
};

export function playerAttackDamage(player: Player, weaponBonus: number): number {
  return Math.max(1, Math.round(BASE_PLAYER_ATTACK + player.strength * STRENGTH_DAMAGE_FACTOR + weaponBonus));
}

export function playerSkillDamage(player: Player, weaponBonus: number): number {
  return Math.round(playerAttackDamage(player, weaponBonus) * SKILL_MULTIPLIER);
}

/** Regular monsters have no attack_patterns — fall back to a plain hit using monster.attack. */
export function pickMonsterAttack(monster: Monster): AttackPattern {
  if (monster.attack_patterns.length === 0) {
    return { name: "Strike", telegraph_ms: DEFAULT_TELEGRAPH_MS, damage: monster.attack };
  }
  const i = Math.floor(Math.random() * monster.attack_patterns.length);
  return monster.attack_patterns[i];
}

export function clampHp(hp: number, maxHp: number): number {
  return Math.max(0, Math.min(maxHp, hp));
}
