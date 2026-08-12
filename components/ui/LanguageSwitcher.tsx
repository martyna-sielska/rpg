"use client";

import { useTransition } from "react";
import { setLocale } from "@/lib/actions/locale";
import { useI18n } from "@/lib/i18n/I18nProvider";
import type { Locale } from "@/lib/i18n/locale";

const OPTIONS: { id: Locale; label: string }[] = [
  { id: "en", label: "EN" },
  { id: "pl", label: "PL" },
];

export function LanguageSwitcher() {
  const { locale } = useI18n();
  const [isPending, startTransition] = useTransition();

  function handleChange(next: Locale) {
    if (next === locale || isPending) return;
    startTransition(async () => {
      await setLocale(next);
    });
  }

  return (
    <div className="flex items-center gap-0.5 rounded-lg border-2 border-wood-dark bg-wood-darkest/60 p-0.5">
      {OPTIONS.map((opt) => (
        <button
          key={opt.id}
          type="button"
          onClick={() => handleChange(opt.id)}
          disabled={isPending}
          aria-pressed={locale === opt.id}
          className={`rounded-md px-2 py-1 font-pixel text-[10px] font-semibold transition disabled:cursor-not-allowed ${
            locale === opt.id
              ? "bg-gold text-ink"
              : "text-parchment-dark hover:text-parchment"
          }`}
        >
          {opt.label}
        </button>
      ))}
    </div>
  );
}
