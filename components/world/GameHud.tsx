import Image from "next/image";
import Link from "next/link";
import { avatarById } from "@/lib/game/types";
import { xpProgress } from "@/lib/game/xp";
import { LogoutButton } from "@/components/auth/LogoutButton";
import { DayNightIndicator } from "@/components/world/DayNightIndicator";
import type { Player } from "@/lib/game/types";

// Bust-crop vertical anchor per avatar, tuned per portrait since headwear height
// (tall witch hat, plume, none) shifts each character's face to a different
// fraction of the source image.
const AVATAR_CROP_Y: Record<string, number> = {
  elara: 20,
  kael: 20,
  liora: 20,
  rowan: 20,
};

// Zoom level per avatar — same reasoning as AVATAR_CROP_Y, tuned per portrait.
const AVATAR_CROP_SCALE: Record<string, number> = {
  elara: 1.85,
  kael: 1.85,
  liora: 2.1,
  rowan: 1.85,
};

const NAV_LINKS = [
  { href: "/world-map", label: "World Map", icon: "/assets/icons/world_map.png" },
  { href: "/character", label: "Character", icon: "/assets/icons/character.png" },
  { href: "/inventory", label: "Inventory", icon: "/assets/icons/inventory.png" },
  { href: "/quests", label: "Quests", icon: "/assets/icons/quests.png" },
  { href: "/home", label: "Home", icon: "/assets/icons/home.png" },
] as const;

/**
 * Small, always-on corner HUD — deliberately not a full-width dashboard nav.
 * Scenes render full-bleed behind it; this only ever shows a glance of player
 * state plus a compact icon dock for the main game sections.
 */
export function GameHud({ player }: { player: Player }) {
  const avatar = avatarById(player.avatar_id);
  const { xp, required } = xpProgress(player.level, player.xp);
  const hpPercent = player.max_hp > 0 ? Math.min(100, Math.max(0, (player.hp / player.max_hp) * 100)) : 0;
  const xpPercent = required > 0 ? Math.min(100, Math.max(0, (xp / required) * 100)) : 0;

  return (
    <div className="pointer-events-none fixed inset-x-0 top-0 z-40 flex items-start justify-between gap-3 p-3 sm:p-4">
      <div className="pointer-events-auto relative flex items-center gap-3 rounded-xl border-4 border-wood-dark bg-wood/95 p-2 pr-4 shadow-[0_8px_24px_rgba(0,0,0,0.5)]">
        <div className="relative h-16 w-14 shrink-0 overflow-hidden rounded-md border-2 border-wood-darkest bg-wood-darkest/60">
          <Image
            src={avatar.image}
            alt={avatar.name}
            fill
            sizes="56px"
            unoptimized
            className="object-cover"
            style={{
              objectPosition: `50% ${AVATAR_CROP_Y[avatar.id] ?? 20}%`,
              transform: `scale(${AVATAR_CROP_SCALE[avatar.id] ?? 2.1})`,
              transformOrigin: "top",
            }}
          />
        </div>
        <div className="flex w-32 flex-col gap-1 sm:w-40">
          <div className="flex items-center justify-between text-sm font-semibold text-parchment">
            <span className="truncate">{player.username}</span>
            <span className="shrink-0 text-parchment-dark">Lv {player.level}</span>
          </div>
          <div className="h-2 w-full overflow-hidden rounded-full border border-wood-darkest bg-wood-darkest/80">
            <div className="h-full rounded-full bg-hp transition-all duration-500" style={{ width: `${hpPercent}%` }} />
          </div>
          <div className="h-1.5 w-full overflow-hidden rounded-full border border-wood-darkest bg-wood-darkest/80">
            <div className="h-full rounded-full bg-xp transition-all duration-500" style={{ width: `${xpPercent}%` }} />
          </div>
        </div>
        <div className="hidden items-center gap-1 text-xs font-semibold text-gold sm:flex">
          <span aria-hidden>🪙</span>
          <span>{player.gold}</span>
        </div>
        <DayNightIndicator />
      </div>

      <div className="pointer-events-auto flex items-center gap-1 rounded-xl border-4 border-wood-dark bg-wood/95 p-1.5 shadow-[0_8px_24px_rgba(0,0,0,0.5)]">
        {NAV_LINKS.map((link) => (
          <Link
            key={link.href}
            href={link.href}
            title={link.label}
            aria-label={link.label}
            className="relative flex h-10 w-10 items-center justify-center rounded-lg transition hover:scale-110 hover:brightness-110"
          >
            <Image src={link.icon} alt={link.label} fill sizes="40px" unoptimized className="object-contain" />
          </Link>
        ))}
        <div className="ml-1 scale-90">
          <LogoutButton />
        </div>
      </div>
    </div>
  );
}
