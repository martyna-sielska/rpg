"use client";

import { createContext, useContext, type ReactNode } from "react";
import type { Locale } from "@/lib/i18n/locale";
import { dictionaries, type Dictionary } from "@/lib/i18n/dictionaries";

const I18nContext = createContext<{ locale: Locale; t: Dictionary } | null>(null);

// Only `locale` (a plain string) crosses the Server -> Client Component
// boundary as a prop. The dictionary itself is looked up from this client
// module's own import — dictionary values include functions (for
// interpolated strings), and functions can't be passed as props from a
// Server Component.
export function I18nProvider({ locale, children }: { locale: Locale; children: ReactNode }) {
  return <I18nContext.Provider value={{ locale, t: dictionaries[locale] }}>{children}</I18nContext.Provider>;
}

/** Client-only: the current visitor's locale + dictionary, from the I18nProvider mounted in the root layout. */
export function useI18n() {
  const ctx = useContext(I18nContext);
  if (!ctx) throw new Error("useI18n must be used within an I18nProvider");
  return ctx;
}
