import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { travelToLocation } from "@/lib/actions/world";
import { HollowScene } from "@/components/world/HollowScene";

export const metadata: Metadata = { title: "The Hollow — Wonderhill" };

export default async function HollowPage() {
  await travelToLocation("hollow");

  const supabase = await createClient();
  const [{ data: location }, { data: interactables }] = await Promise.all([
    supabase.from("locations").select("*").eq("id", "hollow").single(),
    supabase.from("interactables").select("*").eq("location_id", "hollow"),
  ]);

  return (
    <HollowScene
      backgroundImage={location?.background_image ?? "/assets/locations/hollow.png"}
      interactables={interactables ?? []}
    />
  );
}
