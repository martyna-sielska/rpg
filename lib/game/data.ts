import { cache } from "react";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import type { Location, Player, PlayerLocation } from "@/lib/game/types";

/** Cached per request: fetches the signed-in player's row, redirecting to /login if there is none. */
export const getCurrentPlayer = cache(async (): Promise<Player> => {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: player, error } = await supabase
    .from("players")
    .select("*")
    .eq("id", user.id)
    .single();

  if (error || !player) {
    // A valid Supabase auth session with no matching players row (e.g. the
    // database was reset while this browser still had a session cookie)
    // would otherwise redirect-loop forever: this page sends them to
    // /login, but proxy.ts sends an authenticated user straight back here.
    // Signing out first means the next request is genuinely unauthenticated.
    await supabase.auth.signOut();
    redirect("/login");
  }
  return player;
});

/** Every location in the game, ordered for the World Map (locked ones included). */
export const getAllLocations = cache(async (): Promise<Location[]> => {
  const supabase = await createClient();
  const { data } = await supabase.from("locations").select("*").order("sort_order");
  return data ?? [];
});

/** The signed-in player's per-location unlock/discovery state. */
export const getPlayerLocations = cache(async (): Promise<PlayerLocation[]> => {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data } = await supabase.from("player_locations").select("*").eq("player_id", user.id);
  return data ?? [];
});
