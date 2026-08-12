"use client";

import { openIntro } from "@/components/intro/IntroModal";
import { useI18n } from "@/lib/i18n/I18nProvider";

export function IntroHelpButton() {
  const { t } = useI18n();
  return (
    <button
      type="button"
      onClick={openIntro}
      title={t.nav.howToPlay}
      aria-label={t.nav.howToPlay}
      className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg font-pixel text-base text-gold transition hover:scale-110 hover:brightness-110"
    >
      ?
    </button>
  );
}
