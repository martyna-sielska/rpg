"use client";

import { useState, useTransition } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { restAtHome } from "@/lib/actions/home";
import { DayNightOverlay } from "@/components/world/DayNightOverlay";
import { SceneFrame } from "@/components/world/SceneFrame";
import { useI18n } from "@/lib/i18n/I18nProvider";

// Hand-placed against assets/house.png (bed bottom-left, chest at its foot,
// crafting table center, world-map painting on the wall) — same hardcoded
// hotspot approach as the Village scene, not a furniture-placement system.
const HOTSPOT_POSITIONS = [
  { id: "bed", x: 15, y: 70, icon: "🛏️" },
  { id: "chest", x: 28, y: 80, icon: "📦" },
  { id: "table", x: 62, y: 32, icon: "🔨" },
  { id: "map", x: 62, y: 17, icon: "🗺️" },
] as const;

export function HomeScene({ backgroundImage }: { backgroundImage: string }) {
  const router = useRouter();
  const { t } = useI18n();
  const [isPending, startTransition] = useTransition();
  const [message, setMessage] = useState<string | null>(null);

  const hotspotLabels: Record<(typeof HOTSPOT_POSITIONS)[number]["id"], string> = {
    bed: t.home.rest,
    chest: t.home.storage,
    table: t.home.crafting,
    map: t.home.worldMap,
  };

  function handleRest() {
    startTransition(async () => {
      try {
        await restAtHome();
        setMessage(t.home.fullyRested);
        router.refresh();
      } catch (e) {
        setMessage(e instanceof Error ? e.message : t.home.cantRest);
      }
    });
  }

  return (
    <SceneFrame>
      <Image src={backgroundImage} alt={t.sceneAlt.home} fill priority unoptimized className="object-cover" />
      <div className="absolute inset-0 bg-black/10" />
      <DayNightOverlay />

      {HOTSPOT_POSITIONS.map((spot) => {
        const labelText = hotspotLabels[spot.id];
        const inner = (
          <div className="flex h-14 w-14 items-center justify-center rounded-full border-4 border-wood-dark bg-parchment text-2xl shadow-[0_6px_16px_rgba(0,0,0,0.5)] transition group-hover:scale-110">
            <span aria-hidden>{spot.icon}</span>
          </div>
        );
        const label = (
          <div className="pointer-events-none whitespace-nowrap rounded-md border-2 border-wood-dark bg-wood-darkest/90 px-2 py-0.5 text-[10px] font-semibold text-parchment opacity-0 shadow-lg transition group-hover:opacity-100">
            {labelText}
          </div>
        );

        if (spot.id === "bed") {
          return (
            <button
              key={spot.id}
              type="button"
              onClick={handleRest}
              disabled={isPending}
              className="group absolute flex -translate-x-1/2 -translate-y-1/2 flex-col items-center gap-1"
              style={{ left: `${spot.x}%`, top: `${spot.y}%` }}
            >
              {inner}
              {label}
            </button>
          );
        }

        const href = spot.id === "map" ? "/world-map" : "/inventory";
        return (
          <Link
            key={spot.id}
            href={href}
            className="group absolute flex -translate-x-1/2 -translate-y-1/2 flex-col items-center gap-1"
            style={{ left: `${spot.x}%`, top: `${spot.y}%` }}
          >
            {inner}
            {label}
          </Link>
        );
      })}

      {message && (
        <div className="pointer-events-none fixed inset-x-0 bottom-8 flex justify-center">
          <div className="rounded-lg border-2 border-wood-dark bg-wood-darkest/95 px-4 py-2 text-sm text-parchment shadow-lg">
            {message}
          </div>
        </div>
      )}
    </SceneFrame>
  );
}
