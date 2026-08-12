import type { Locale } from "@/lib/i18n/locale";

/**
 * Overwrites each listed field with its `${field}_pl` counterpart when the
 * visitor's locale is Polish and a translation is present, falling back to
 * the original (English) value otherwise — e.g. proper names deliberately
 * left untranslated in the database.
 */
export function localize<T extends Record<string, unknown>>(row: T, locale: Locale, fields: (keyof T & string)[]): T {
  if (locale !== "pl") return row;

  const out = { ...row };
  for (const field of fields) {
    const plKey = `${field}_pl` as keyof T & string;
    const plValue = row[plKey];
    if (plValue != null) {
      out[field] = plValue as T[typeof field];
    }
  }
  return out;
}
