"use client";

import { useSyncExternalStore } from "react";
import { Panel } from "@/components/ui/Panel";
import { Button } from "@/components/ui/Button";

// Bumping this key (rather than reusing an old one) is how we'd force the
// intro to show again for existing players if its content changes meaningfully.
const STORAGE_KEY = "wonderhill:intro-seen:v1";

const HOW_TO_PLAY = [
  "Travel the World Map (top-right, the globe icon) to reach the Forest, Lake, Dungeon and other locations as you unlock them.",
  "Return to the Village often — NPCs there hand out new quests and reward you when you bring finished ones back.",
  "Head Home to rest and heal, check your Chest, or use the Crafting Table.",
  "Your Quests, Inventory and Character screens are always one click away in the top-right icon bar.",
  "Fight monsters and gather resources out in the world for XP, gold, and crafting materials.",
];

// Module-level store (mirrors the useSyncExternalStore pattern in
// lib/game/useDayPhase.ts) rather than useState+useEffect, so opening the
// intro on first visit is a plain external-system sync — not a setState
// call inside an effect — and the same store lets the HUD's "?" button
// reopen it from a completely different component subtree.
let open = false;
let seenChecked = false;
const listeners = new Set<() => void>();

function notify() {
  for (const listener of listeners) listener();
}

function subscribe(callback: () => void) {
  if (!seenChecked) {
    seenChecked = true;
    if (!window.localStorage.getItem(STORAGE_KEY)) {
      open = true;
      window.localStorage.setItem(STORAGE_KEY, "1");
    }
  }
  listeners.add(callback);
  return () => listeners.delete(callback);
}

function getSnapshot() {
  return open;
}

function getServerSnapshot() {
  return false;
}

export function openIntro() {
  open = true;
  notify();
}

function closeIntro() {
  open = false;
  notify();
}

export function IntroModal() {
  const isOpen = useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot);

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-[70] flex items-center justify-center bg-black/70 p-4"
      onClick={closeIntro}
    >
      <div className="w-full max-w-lg" onClick={(e) => e.stopPropagation()}>
        <Panel className="max-h-[85vh] overflow-y-auto p-6">
          <h2 className="font-pixel text-lg text-gold drop-shadow-[0_2px_0_rgba(0,0,0,0.6)]">
            Welcome to Wonderhill
          </h2>

          <p className="mt-4 text-sm leading-relaxed text-parchment">
            Wonderhill is a small village on the edge of a mysterious forest. For as long as
            anyone can remember, an old magic has watched over it and kept it safe — but lately,
            that magic has begun to fade. Strange lights flicker among the trees at night, and
            the village elders fear something is stirring beyond them.
          </p>
          <p className="mt-3 text-sm leading-relaxed text-parchment">
            You&apos;ve just arrived. Elira, near the village fountain, has already noticed the
            signs — seek her out to learn more and take on your first quest.
          </p>

          <h3 className="mt-5 font-pixel text-sm text-gold">How to Play</h3>
          <ul className="mt-3 flex flex-col gap-2 text-sm leading-relaxed text-parchment">
            {HOW_TO_PLAY.map((line) => (
              <li key={line} className="flex gap-2">
                <span className="text-gold" aria-hidden>
                  ▸
                </span>
                <span>{line}</span>
              </li>
            ))}
          </ul>

          <p className="mt-4 text-xs text-parchment-dark">
            You can revisit this any time from the ? button next to your icon bar.
          </p>

          <Button className="mt-5 w-full" onClick={closeIntro}>
            Begin Your Journey
          </Button>
        </Panel>
      </div>
    </div>
  );
}
