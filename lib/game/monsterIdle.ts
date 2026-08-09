import type { MonsterTier } from "@/lib/game/types";

// Idle motion matched to what each notable creature actually is:
// bramble_warden is a treant rooted in the ground (sways like a tree),
// fading_shadow is an untethered wraith (floats and pulses),
// bog_slime squats on its mossy throne-rock (squishes in place),
// wild_ember is a crackling anomaly (jitters erratically). Unmapped
// boss-tier monsters fall back to a sway — most things stand on the ground.
type Motion = "sway" | "float" | "pulse" | "jitter";

const MONSTER_MOTION: Record<string, Motion> = {
  bramble_warden: "sway",
  fading_shadow: "float",
  bog_slime: "pulse",
  wild_ember: "jitter",
};

// Monsters that aren't boss-tier but still get a small size bump + idle motion.
const FEATURED_MONSTER_IDS = new Set(["bog_slime", "wild_ember"]);

export type MonsterScale = "regular" | "featured" | "boss";

export function getMonsterScale(monsterId: string, tier?: MonsterTier): MonsterScale {
  if (tier === "boss" || tier === "miniboss") return "boss";
  if (FEATURED_MONSTER_IDS.has(monsterId)) return "featured";
  return "regular";
}

export function getMonsterIdleAnimationClass(monsterId: string, tier?: MonsterTier): string {
  if (getMonsterScale(monsterId, tier) === "regular") return "";
  switch (MONSTER_MOTION[monsterId] ?? "sway") {
    case "float":
      return "animate-idle-float";
    case "pulse":
      return "animate-idle-pulse";
    case "jitter":
      return "animate-idle-jitter";
    default:
      return "animate-idle-sway";
  }
}

export function getHotspotSizeClasses(scale: MonsterScale): string {
  if (scale === "boss") return "h-24 w-24";
  if (scale === "featured") return "h-20 w-20";
  return "h-16 w-16";
}

export function getCombatSizeClasses(scale: MonsterScale): string {
  if (scale === "boss") return "h-40 w-36 sm:h-48 sm:w-40";
  if (scale === "featured") return "h-36 w-32 sm:h-44 sm:w-36";
  return "h-32 w-28 sm:h-40 sm:w-32";
}
