"use client";

import { useEffect, useRef, useState, useSyncExternalStore, type ReactNode } from "react";
import { useI18n } from "@/lib/i18n/I18nProvider";

// Fullscreen requires vendor-prefixed fallbacks on some browsers (notably
// Safari, which still ships only the webkit-prefixed Fullscreen API).
type FullscreenDocument = Document & {
  webkitFullscreenElement?: Element;
  webkitExitFullscreen?: () => Promise<void>;
  webkitFullscreenEnabled?: boolean;
};
type FullscreenElement = HTMLElement & {
  webkitRequestFullscreen?: () => Promise<void>;
};
type NavigatorStandalone = Navigator & { standalone?: boolean };

function getFullscreenElement() {
  const doc = document as FullscreenDocument;
  return doc.fullscreenElement ?? doc.webkitFullscreenElement ?? null;
}

// `fullscreenEnabled` (unlike checking for the method's mere presence) is
// what actually reflects whether the browser will honor a request — this is
// how iOS Safari is correctly detected as unsupported: it defines
// `Element.requestFullscreen` in its DOM interfaces but always rejects it for
// anything other than <video>, and never sets `fullscreenEnabled` to true.
function isNativeFullscreenSupported() {
  const doc = document as FullscreenDocument;
  return Boolean(doc.fullscreenEnabled ?? doc.webkitFullscreenEnabled);
}

// True when already launched from an iOS/Android home-screen icon — there's
// no browser chrome left to toggle, so the button would have nothing to do.
function isStandalone() {
  return (
    window.matchMedia("(display-mode: standalone)").matches || (window.navigator as NavigatorStandalone).standalone === true
  );
}

// Neither fact changes during a session, so there's nothing to subscribe to
// — this only exists to give useSyncExternalStore a way to read a
// browser-only value once, on the client, without the SSR/hydration
// mismatch a plain useState+useEffect would risk.
function subscribeNever() {
  return () => {};
}

// Every location background is 1264x843 (or map2.png's equivalent 1536x1024)
// — a fixed ~3:2 aspect ratio. This wrapper locks the scene box to that same
// ratio and fits it entirely inside the viewport (letterboxed/pillarboxed as
// needed) instead of letting `object-cover` crop it to whatever the screen's
// aspect happens to be. The min()-based sizing is the standard CSS-only
// "fit a fixed-ratio box inside a variable viewport" formula: 150vh = 100vh
// scaled by the 3/2 ratio, 66.667vw = 100vw divided by it. Because it's
// viewport-unit driven, it keeps fitting correctly when the page goes
// fullscreen (the browser fullscreen viewport is what vh/vw resolve
// against), so the fullscreen toggle below needs no extra sizing logic.
export function SceneFrame({ children }: { children: ReactNode }) {
  const { t } = useI18n();
  const wrapperRef = useRef<HTMLDivElement>(null);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [showUnsupportedHint, setShowUnsupportedHint] = useState(false);
  const supportsNativeFullscreen = useSyncExternalStore(subscribeNever, isNativeFullscreenSupported, () => true);
  const hideToggle = useSyncExternalStore(subscribeNever, isStandalone, () => false);

  useEffect(() => {
    function handleChange() {
      setIsFullscreen(getFullscreenElement() === document.documentElement);
    }
    document.addEventListener("fullscreenchange", handleChange);
    document.addEventListener("webkitfullscreenchange", handleChange);
    return () => {
      document.removeEventListener("fullscreenchange", handleChange);
      document.removeEventListener("webkitfullscreenchange", handleChange);
    };
  }, []);

  async function toggleFullscreen() {
    if (!supportsNativeFullscreen) {
      setShowUnsupportedHint(true);
      setTimeout(() => setShowUnsupportedHint(false), 4000);
      return;
    }
    const doc = document as FullscreenDocument;
    if (getFullscreenElement()) {
      if (doc.exitFullscreen) await doc.exitFullscreen();
      else if (doc.webkitExitFullscreen) await doc.webkitExitFullscreen();
      return;
    }
    // Fullscreen the whole page (not just this wrapper) so the HUD — which
    // lives outside this component, as a sibling in the game layout — stays
    // visible instead of vanishing along with everything else the browser
    // excludes from a narrower fullscreen target.
    const el = document.documentElement as FullscreenElement;
    if (el.requestFullscreen) await el.requestFullscreen();
    else if (el.webkitRequestFullscreen) await el.webkitRequestFullscreen();
  }

  return (
    <div ref={wrapperRef} className="flex min-h-screen w-full items-center justify-center bg-wood-darkest">
      <div className="relative aspect-[3/2] h-[min(100vh,66.667vw)] w-[min(100vw,150vh)] overflow-hidden border-4 border-wood-dark shadow-[inset_0_1px_0_rgba(255,255,255,0.08),0_8px_24px_rgba(0,0,0,0.5)]">
        {children}
      </div>

      {!hideToggle && (
        <>
          {showUnsupportedHint && (
            <div className="pointer-events-none fixed bottom-14 right-3 z-50 max-w-[240px] rounded-lg border-2 border-wood-dark bg-wood-darkest/95 px-3 py-2 text-xs text-parchment shadow-lg">
              {t.fullscreen.unsupportedHint}
            </div>
          )}

          {/* Fixed to the real screen edge (not the letterboxed frame above)
              so it stays reachable even when the 3:2 frame is pillarboxed/
              letterboxed inside a differently-shaped viewport or fullscreen
              display. */}
          <button
            type="button"
            onClick={toggleFullscreen}
            aria-label={isFullscreen ? t.fullscreen.exit : t.fullscreen.enter}
            title={isFullscreen ? t.fullscreen.exit : t.fullscreen.enter}
            className="fixed bottom-3 right-3 z-50 flex h-8 w-8 items-center justify-center rounded-md border-2 border-wood-dark bg-wood-darkest/80 text-parchment shadow-[0_2px_8px_rgba(0,0,0,0.5)] transition hover:bg-wood-darkest"
          >
            {isFullscreen ? (
              <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth={2}>
                <path d="M9 3v4a2 2 0 0 1-2 2H3M21 9h-4a2 2 0 0 1-2-2V3M3 15h4a2 2 0 0 1 2 2v4M15 21v-4a2 2 0 0 1 2-2h4" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            ) : (
              <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth={2}>
                <path d="M3 9V5a2 2 0 0 1 2-2h4M21 9V5a2 2 0 0 1-2-2h-4M3 15v4a2 2 0 0 0 2 2h4M21 15v4a2 2 0 0 1-2 2h-4" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            )}
          </button>
        </>
      )}
    </div>
  );
}
