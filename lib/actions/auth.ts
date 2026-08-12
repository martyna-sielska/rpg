"use server";

import { redirect } from "next/navigation";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { getDictionary } from "@/lib/i18n/getDictionary";
import type { Dictionary } from "@/lib/i18n/dictionaries";
import type { AvatarId } from "@/lib/game/types";

export interface AuthFormState {
  error?: string;
}

function translateAuthError(message: string, t: Dictionary): string {
  if (message.includes("Invalid login credentials")) {
    return t.auth.errors.invalidCredentials;
  }
  if (message.toLowerCase().includes("already registered")) {
    return t.auth.errors.alreadyRegistered;
  }
  if (message.toLowerCase().includes("password")) {
    return t.auth.errors.passwordMinLength;
  }
  if (message.toLowerCase().includes("database error saving new user")) {
    return t.auth.errors.accountCreateFailed;
  }
  return message;
}

export async function signUp(
  _prevState: AuthFormState,
  formData: FormData
): Promise<AuthFormState> {
  const t = await getDictionary();
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");
  const username = String(formData.get("username") ?? "").trim();
  const avatarId = String(formData.get("avatar_id") ?? "") as AvatarId;

  if (!email || !password || !username || !avatarId) {
    return { error: t.auth.errors.fillFields };
  }
  if (password.length < 6) {
    return { error: t.auth.errors.passwordMinLength };
  }
  if (username.length < 3 || username.length > 20) {
    return { error: t.auth.errors.usernameLength };
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { username, avatar_id: avatarId } },
  });

  if (error) {
    return { error: translateAuthError(error.message, t) };
  }

  redirect("/world-map");
}

export async function signIn(
  _prevState: AuthFormState,
  formData: FormData
): Promise<AuthFormState> {
  const t = await getDictionary();
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");

  if (!email || !password) {
    return { error: t.auth.errors.enterEmailPassword };
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });

  if (error) {
    return { error: translateAuthError(error.message, t) };
  }

  redirect("/world-map");
}

export async function signOut() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}

/**
 * Wipes every Supabase auth cookie regardless of whether it's valid, expired,
 * or corrupted. Escape hatch for a browser stuck with a broken session (e.g.
 * a stale/partial cookie causing a redirect loop) — signOut() above needs a
 * working session to call the Supabase API, this doesn't.
 */
export async function forceClearSession() {
  const cookieStore = await cookies();
  for (const cookie of cookieStore.getAll()) {
    if (cookie.name.startsWith("sb-")) {
      cookieStore.delete(cookie.name);
    }
  }
  redirect("/login");
}
