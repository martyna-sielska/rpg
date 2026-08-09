"use client";

import { useDayPhase } from "@/lib/game/useDayPhase";

/** Full-bleed tint over a scene background — day is untouched, night dims and cools it. */
export function DayNightOverlay() {
  const phase = useDayPhase();
  if (phase === "day") return null;

  return (
    <>
      <div className="pointer-events-none absolute inset-0 bg-[#0a1030]/45 mix-blend-multiply transition-opacity duration-1000" />
      <div className="pointer-events-none absolute inset-0 bg-[#1a1440]/20" />
      <div className="pointer-events-none absolute right-4 top-20 text-2xl opacity-80" aria-hidden>
        🌙
      </div>
    </>
  );
}
