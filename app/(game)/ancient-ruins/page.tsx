import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { travelToLocation } from "@/lib/actions/world";
import { AncientRuinsScene } from "@/components/world/AncientRuinsScene";

export const metadata: Metadata = { title: "Ancient Ruins — Wonderhill" };

export default async function AncientRuinsPage() {
  await travelToLocation("ancient_ruins");

  const supabase = await createClient();
  const [{ data: location }, { data: interactables }] = await Promise.all([
    supabase.from("locations").select("*").eq("id", "ancient_ruins").single(),
    supabase.from("interactables").select("*").eq("location_id", "ancient_ruins"),
  ]);

  return (
    <AncientRuinsScene
      backgroundImage={location?.background_image ?? "/assets/locations/ancient_ruins.png"}
      interactables={interactables ?? []}
    />
  );
}
