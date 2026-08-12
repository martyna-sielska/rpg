import type { Locale } from "@/lib/i18n/locale";
import { en, type Dictionary } from "@/lib/i18n/dictionaries/en";
import { pl } from "@/lib/i18n/dictionaries/pl";

export type { Dictionary };

export const dictionaries: Record<Locale, Dictionary> = { en, pl };
