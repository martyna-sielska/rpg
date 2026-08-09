export type DayPhase = "day" | "night";

// A full day/night cycle every 10 minutes of real time (5 min day, 5 min
// night) — deterministic and shared by every player, no persistence needed.
const PHASE_LENGTH_MS = 5 * 60 * 1000;

export function getDayPhase(now: Date = new Date()): DayPhase {
  const bucket = Math.floor(now.getTime() / PHASE_LENGTH_MS);
  return bucket % 2 === 0 ? "day" : "night";
}
