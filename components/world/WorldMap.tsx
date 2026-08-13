"use client";

import Image from "next/image";
import Link from "next/link";
import { useDayPhase } from "@/lib/game/useDayPhase";
import { SceneFrame } from "@/components/world/SceneFrame";
import { useI18n } from "@/lib/i18n/I18nProvider";
import type { Location, PlayerLocation } from "@/lib/game/types";

const LOCATION_ROUTE: Record<string, string> = {
  home: "/home",
  village: "/village",
  forest: "/forest",
  dungeon_ruins: "/dungeon",
  lake: "/lake",
  castle: "/castle",
  mountains: "/mountains",
  volcano: "/volcano",
  magic_tower: "/magic-tower",
  ancient_ruins: "/ancient-ruins",
  // Deliberately no "hollow" route here: the Hollow is never a World Map
  // destination, even once unlocked (needed so travel_to_location succeeds
  // when the passage sends you there) — the only way in is the temporary
  // passage interactable at the village altar.
};

// Locations that never appear on the map at all, regardless of unlocked
// state — not even as a locked pin.
const HIDDEN_FROM_MAP = new Set(["hollow"]);

// Clickable regions hand-placed directly over the matching art in
// assets/map2.png (percent of the 1536x1024 image) — the leftmost cottage
// for Home, the fountain-square cluster for Village, the wooded clearing
// for Forest, the ruin archway for the Dungeon, and so on for every other
// landmark. No visible pin/badge for these; the art itself is the hit
// target (see the hover highlight below). Rects are trimmed to avoid
// overlapping their neighbors' art (e.g. the lake's left/top edges are
// pulled back from the village forge and the castle cliff).
const HOTSPOT_RECTS: Record<string, { left: number; top: number; width: number; height: number }> = {
  home: { left: 2.0, top: 47.4, width: 19.5, height: 22.5 },
  village: { left: 22.8, top: 48.3, width: 39.7, height: 36.6 },
  forest: { left: 19.5, top: 9.8, width: 29.3, height: 29.3 },
  dungeon_ruins: { left: 49.5, top: 2.9, width: 15.0, height: 18.6 },
  lake: { left: 45.6, top: 45.4, width: 20.2, height: 18.6 },
  castle: { left: 50.8, top: 22.0, width: 26.0, height: 23.0 },
  mountains: { left: 85.0, top: 6.0, width: 15.0, height: 18.0 },
  volcano: { left: 82.7, top: 28.3, width: 17.3, height: 30.3 },
  magic_tower: { left: 2.6, top: 0, width: 11.1, height: 29.3 },
  ancient_ruins: { left: 77.5, top: 14.2, width: 15.0, height: 13.7 },
};

export function WorldMap({
  locations,
  playerLocations,
  currentLocationId,
}: {
  locations: Location[];
  playerLocations: PlayerLocation[];
  currentLocationId: string;
}) {
  const phase = useDayPhase();
  const { t } = useI18n();

  return (
    <SceneFrame>
      <Image
        src="/assets/map2.png"
        alt={t.sceneAlt.worldMap}
        fill
        priority
        unoptimized
        className={`object-cover transition-[filter] duration-1000 ${phase === "day" ? "brightness-150 saturate-125" : ""}`}
      />
      <div className="absolute inset-0 bg-black/10" />

      {locations.map((location) => {
        if (HIDDEN_FROM_MAP.has(location.id)) return null;
        const unlocked = playerLocations.some((pl) => pl.location_id === location.id && pl.unlocked);
        const route = LOCATION_ROUTE[location.id];
        const rect = HOTSPOT_RECTS[location.id];
        const isCurrent = location.id === currentLocationId;

        if (unlocked && route && rect) {
          return (
            <Link
              key={location.id}
              href={route}
              aria-label={location.name}
              title={location.name}
              className="group absolute"
              style={{
                left: `${rect.left}%`,
                top: `${rect.top}%`,
                width: `${rect.width}%`,
                height: `${rect.height}%`,
              }}
            >
              <span className="pointer-events-none absolute left-1/2 top-2 -translate-x-1/2 whitespace-nowrap rounded-md border-2 border-wood-dark bg-wood-darkest/90 px-2 py-0.5 text-[10px] font-semibold text-parchment opacity-0 shadow-lg transition group-hover:opacity-100">
                {location.name}
                {isCurrent ? ` ${t.worldMap.here}` : ""}
              </span>
            </Link>
          );
        }

        // Fallback for any unlocked, routed location that doesn't (yet) have
        // a hand-placed hotspot rect above — still a clickable point pin.
        if (unlocked && route) {
          return (
            <Link
              key={location.id}
              href={route}
              aria-label={location.name}
              title={location.name}
              className="group absolute -translate-x-1/2 -translate-y-1/2"
              style={{ left: `${location.map_x}%`, top: `${location.map_y}%` }}
            >
              <div className="flex flex-col items-center gap-1 rounded-full border-4 border-gold bg-wood-darkest/80 p-2 text-2xl text-parchment shadow-[0_6px_16px_rgba(0,0,0,0.5)] transition group-hover:scale-110">
                <span aria-hidden>📍</span>
              </div>
              <div className="pointer-events-none absolute left-1/2 top-full mt-1 -translate-x-1/2 whitespace-nowrap rounded-md border-2 border-wood-dark bg-wood-darkest/90 px-2 py-0.5 text-[10px] font-semibold text-parchment opacity-0 shadow-lg transition group-hover:opacity-100">
                {location.name}
                {isCurrent ? ` ${t.worldMap.here}` : ""}
              </div>
            </Link>
          );
        }

        // Locked (or not-yet-routed) locations use a simple point pin — real
        // lock/region art to replace this is coming later.
        return (
          <div
            key={location.id}
            className="group absolute -translate-x-1/2 -translate-y-1/2"
            style={{ left: `${location.map_x}%`, top: `${location.map_y}%` }}
          >
            <div
              className="flex h-10 w-10 cursor-not-allowed items-center justify-center rounded-full border-4 border-wood-dark bg-wood-darkest/80 p-1 opacity-60 shadow-[0_6px_16px_rgba(0,0,0,0.5)]"
              title={location.unlock_hint ?? t.worldMap.locked}
            >
              <Image src="/assets/items/locked_location_padlock.png" alt="" aria-hidden width={32} height={32} unoptimized className="h-full w-full object-contain" />
            </div>
            <div className="pointer-events-none absolute left-1/2 top-full mt-1 -translate-x-1/2 whitespace-nowrap rounded-md border-2 border-wood-dark bg-wood-darkest/90 px-2 py-0.5 text-[10px] font-semibold text-parchment opacity-0 shadow-lg transition group-hover:opacity-100">
              {location.name}
            </div>
          </div>
        );
      })}
    </SceneFrame>
  );
}
