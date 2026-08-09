"use server";

import { redirect } from "next/navigation";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import type { AvatarId } from "@/lib/game/types";

export interface AuthFormState {
  error?: string;
}

function translateAuthError(message: string): string {
  if (message.includes("Invalid login credentials")) {
    return "Incorrect email or password.";
  }
  if (message.toLowerCase().includes("already registered")) {
    return "That email is already registered.";
  }
  if (message.toLowerCase().includes("password")) {
    return "Password must be at least 6 characters.";
  }
  if (message.toLowerCase().includes("database error saving new user")) {
    return "Couldn't create your account — that username may already be taken. Try another.";
  }
  return message;
}

export async function signUp(
  _prevState: AuthFormState,
  formData: FormData
): Promise<AuthFormState> {
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");
  const username = String(formData.get("username") ?? "").trim();
  const avatarId = String(formData.get("avatar_id") ?? "") as AvatarId;

  if (!email || !password || !username || !avatarId) {
    return { error: "Fill in every field and choose a hero." };
  }
  if (password.length < 6) {
    return { error: "Password must be at least 6 characters." };
  }
  if (username.length < 3 || username.length > 20) {
    return { error: "Username must be 3–20 characters." };
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { username, avatar_id: avatarId } },
  });

  if (error) {
    return { error: translateAuthError(error.message) };
  }

  redirect("/world-map");
}

export async function signIn(
  _prevState: AuthFormState,
  formData: FormData
): Promise<AuthFormState> {
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");

  if (!email || !password) {
    return { error: "Enter your email and password." };
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });

  if (error) {
    return { error: translateAuthError(error.message) };
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
