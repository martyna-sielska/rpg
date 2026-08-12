"use client";

import { useI18n } from "@/lib/i18n/I18nProvider";

export function LevelUpModal({
  level,
  onClose,
}: {
  level: number | null;
  onClose: () => void;
}) {
  const { t } = useI18n();
  if (level == null) return null;

  return (
    <div
      className="fixed inset-0 z-[60] flex items-center justify-center bg-black/70 p-4"
      onClick={onClose}
    >
      <div
        className="animate-level-up flex flex-col items-center gap-3 rounded-2xl border-4 border-gold bg-wood p-8 text-center shadow-[0_0_60px_rgba(232,185,35,0.5)]"
        onClick={(e) => e.stopPropagation()}
      >
        <p className="font-pixel text-3xl text-gold drop-shadow-[0_2px_0_rgba(0,0,0,0.6)] sm:text-4xl">
          {t.levelUp.title}
        </p>
        <p className="text-parchment">{t.levelUp.reached(level)}</p>
        <button
          type="button"
          onClick={onClose}
          className="mt-2 rounded-lg border-b-4 border-gold-light bg-gold px-5 py-2 font-pixel text-sm text-ink hover:bg-gold-light"
        >
          {t.common.nice}
        </button>
      </div>
    </div>
  );
}
