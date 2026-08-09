"use client";

import { useDayPhase } from "@/lib/game/useDayPhase";

export function DayNightIndicator() {
  const phase = useDayPhase();
  return (
    <span className="text-lg" title={phase === "day" ? "Daytime" : "Nighttime"} aria-label={phase}>
      {phase === "day" ? "☀️" : "🌙"}
    </span>
  );
}
