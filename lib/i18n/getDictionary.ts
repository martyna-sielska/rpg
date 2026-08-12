import { getLocale } from "@/lib/i18n/locale";
import { dictionaries, type Dictionary } from "@/lib/i18n/dictionaries";

/** Server-only: the current visitor's dictionary, resolved from their locale cookie. */
export async function getDictionary(): Promise<Dictionary> {
  const locale = await getLocale();
  return dictionaries[locale];
}
