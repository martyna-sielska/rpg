import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { travelToLocation } from "@/lib/actions/world";
import { VillageScene } from "@/components/world/VillageScene";

export const metadata: Metadata = { title: "Magic Hill — Wonderhill" };

export default async function VillagePage() {
  await travelToLocation("village");

  const supabase = await createClient();
  const [{ data: location }, { data: npcs }, { data: interactables }] = await Promise.all([
    supabase.from("locations").select("*").eq("id", "village").single(),
    supabase.from("npcs").select("*").eq("location_id", "village").order("sort_order"),
    supabase.from("interactables").select("*").eq("location_id", "village"),
  ]);

  return (
    <VillageScene
      backgroundImage={location?.background_image ?? "/assets/locations/village.png"}
      npcs={npcs ?? []}
      interactables={interactables ?? []}
    />
  );
}
