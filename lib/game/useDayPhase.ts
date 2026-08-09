"use client";

import { useEffect, useState } from "react";
import { getDayPhase, type DayPhase } from "@/lib/game/time";

// Starts null rather than calling getDayPhase() immediately: that call reads
// the real clock, and the server's "now" (at SSR render time) and the
// client's "now" (at hydration, a moment later) can straddle a 5-minute
// phase boundary — the server-rendered markup and the client's first render
// would then disagree, which is a hydration error. Staying null through the
// first render keeps server and client output identical; the real phase is
// only computed client-side, after mount, in the effect below.
export function useDayPhase(): DayPhase {
  const [phase, setPhase] = useState<DayPhase | null>(null);

  useEffect(() => {
    setPhase(getDayPhase());
    const i = setInterval(() => setPhase(getDayPhase()), 15000);
    return () => clearInterval(i);
  }, []);

  return phase ?? "day";
}
