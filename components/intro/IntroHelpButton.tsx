"use client";

import { openIntro } from "@/components/intro/IntroModal";

export function IntroHelpButton() {
  return (
    <button
      type="button"
      onClick={openIntro}
      title="How to Play"
      aria-label="How to Play"
      className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg font-pixel text-base text-gold transition hover:scale-110 hover:brightness-110"
    >
      ?
    </button>
  );
}
