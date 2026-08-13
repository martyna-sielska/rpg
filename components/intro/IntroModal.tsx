"use client";

import { useEffect, useSyncExternalStore } from "react";
import { Panel } from "@/components/ui/Panel";
import { Button } from "@/components/ui/Button";
import { useI18n } from "@/lib/i18n/I18nProvider";
import { markIntroSeen } from "@/lib/actions/player";

// Module-level store (mirrors the useSyncExternalStore pattern in
// lib/game/useDayPhase.ts) rather than useState+useEffect, so the "?" HUD
// button (a completely different component subtree) can reopen the modal
// just by calling openIntro().
let open = false;
const listeners = new Set<() => void>();

function notify() {
  for (const listener of listeners) listener();
}

function subscribe(callback: () => void) {
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
  void markIntroSeen();
}

// "Seen" lives on the player row (players.intro_seen), not localStorage, so
// a brand-new account is shown the intro exactly once no matter which
// browser/device they first log in from, and it never resurfaces for that
// account once dismissed.
export function IntroModal({ autoOpen }: { autoOpen: boolean }) {
  const isOpen = useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot);
  const { t } = useI18n();

  useEffect(() => {
    if (autoOpen) openIntro();
    // Only the mount-time value matters — this fires once per GameLayout
    // mount, i.e. once per login session, not on every player prop refresh.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

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
