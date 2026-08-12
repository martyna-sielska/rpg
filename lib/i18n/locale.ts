import { cookies } from "next/headers";

export type Locale = "en" | "pl";

export const LOCALES: Locale[] = ["en", "pl"];
export const DEFAULT_LOCALE: Locale = "en";
export const LOCALE_COOKIE = "locale";

function isLocale(value: string | undefined): value is Locale {
  return value === "en" || value === "pl";
}

/** Server-only: reads the visitor's chosen language from a cookie, defaulting to English. */
export async function getLocale(): Promise<Locale> {
  const cookieStore = await cookies();
  const value = cookieStore.get(LOCALE_COOKIE)?.value;
  return isLocale(value) ? value : DEFAULT_LOCALE;
}
