"use client";

import { useSyncExternalStore } from "react";
import { getDayPhase, type DayPhase } from "@/lib/game/time";

function subscribe(callback: () => void): () => void {
  const id = setInterval(callback, 15000);
  return () => clearInterval(id);
}

function getSnapshot(): DayPhase {
  return getDayPhase();
}

// The server and the client's first render can't agree on the real clock
// (SSR render time vs. hydration time can straddle a 5-minute phase
// boundary), so useSyncExternalStore's server snapshot stays fixed at "day"
// — identical on both sides, avoiding a hydration mismatch. The real,
// live-updating phase only takes over once the client subscribes below.
function getServerSnapshot(): DayPhase {
  return "day";
}

/** Re-checks the shared day/night clock periodically so a scene left open updates on its own. */
export function useDayPhase(): DayPhase {
  return useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot);
}
