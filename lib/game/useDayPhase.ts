"use client";

import { useEffect, useState } from "react";
import { getDayPhase, type DayPhase } from "@/lib/game/time";

/** Re-checks the shared day/night clock periodically so a scene left open updates on its own. */
export function useDayPhase(): DayPhase {
  const [phase, setPhase] = useState<DayPhase>(() => getDayPhase());

  useEffect(() => {
    const i = setInterval(() => setPhase(getDayPhase()), 15000);
    return () => clearInterval(i);
  }, []);

  return phase;
}
