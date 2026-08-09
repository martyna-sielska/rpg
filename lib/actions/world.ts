import { createClient } from "@/lib/supabase/server";

/**
 * Marks the player as having arrived at a location: updates
 * players.current_location_id, flags it discovered, and fires any
 * enter_location quest objectives (see travel_to_location in schema.sql).
 * Called server-side from each scene page's render path — not a form
 * action, since arriving somewhere is a side effect of navigating there.
 */
export async function travelToLocation(locationId: string): Promise<void> {
  const supabase = await createClient();
  await supabase.rpc("travel_to_location", { p_location_id: locationId });
}
