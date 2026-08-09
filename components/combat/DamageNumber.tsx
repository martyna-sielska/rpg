"use client";

const KIND_COLOR = {
  damage: "text-hp",
  heal: "text-xp",
  miss: "text-parchment-dark",
} as const;

export interface FloatingText {
  id: number;
  text: string;
  target: "player" | "monster";
  kind: keyof typeof KIND_COLOR;
}

export function DamageNumber({ text, kind, target }: FloatingText) {
  return (
    <div
      className={`animate-float-up pointer-events-none absolute top-0 font-pixel text-sm font-bold drop-shadow-[0_2px_0_rgba(0,0,0,0.7)] ${KIND_COLOR[kind]} ${
        target === "player" ? "left-1/4" : "left-3/4"
      }`}
    >
      {text}
    </div>
  );
}
