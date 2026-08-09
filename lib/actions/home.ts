"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

/** Full HP restore via the bed hotspot in the Home scene. Returns the player's max HP. */
export async function restAtHome(): Promise<number> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("rest_at_home");
  if (error) throw new Error(error.message);

  revalidatePath("/home");
  return data as number;
}
