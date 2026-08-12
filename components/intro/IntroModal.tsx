"use client";

import { useSyncExternalStore } from "react";
import { Panel } from "@/components/ui/Panel";
import { Button } from "@/components/ui/Button";
import { useI18n } from "@/lib/i18n/I18nProvider";

// Bumping this key (rather than reusing an old one) is how we'd force the
// intro to show again for existing players if its content changes meaningfully.
const STORAGE_KEY = "wonderhill:intro-seen:v1";

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
  const { t } = useI18n();

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-[70] flex items-center justify-center bg-black/70 p-4"
      onClick={closeIntro}
    >
      <div className="w-full max-w-lg" onClick={(e) => e.stopPropagation()}>
        <Panel className="max-h-[85vh] overflow-y-auto p-6">
          <h2 className="font-pixel text-lg text-gold drop-shadow-[0_2px_0_rgba(0,0,0,0.6)]">
            {t.intro.title}
          </h2>

          <p className="mt-4 text-sm leading-relaxed text-parchment">{t.intro.p1}</p>
          <p className="mt-3 text-sm leading-relaxed text-parchment">{t.intro.p2}</p>

          <h3 className="mt-5 font-pixel text-sm text-gold">{t.intro.howToPlayTitle}</h3>
          <ul className="mt-3 flex flex-col gap-2 text-sm leading-relaxed text-parchment">
            {t.intro.steps.map((line) => (
              <li key={line} className="flex gap-2">
                <span className="text-gold" aria-hidden>
                  ▸
                </span>
                <span>{line}</span>
              </li>
            ))}
          </ul>

          <p className="mt-4 text-xs text-parchment-dark">{t.intro.footer}</p>

          <Button className="mt-5 w-full" onClick={closeIntro}>
            {t.intro.cta}
          </Button>
        </Panel>
      </div>
    </div>
  );
}
