/** XP needed to advance from `level` to `level + 1`. Mirrors public.xp_required() in supabase/schema.sql. */
export function xpRequired(level: number): number {
  return 100 + (level - 1) * 50;
}

export function xpProgress(level: number, xp: number) {
  const required = xpRequired(level);
  return { xp, required, percent: Math.min(100, Math.round((xp / required) * 100)) };
}
