import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { travelToLocation } from "@/lib/actions/world";
import { CastleScene } from "@/components/world/CastleScene";

export const metadata: Metadata = { title: "Castle — Wonderhill" };

export default async function CastlePage() {
  await travelToLocation("castle");

  const supabase = await createClient();
  const [{ data: location }, { data: interactables }] = await Promise.all([
    supabase.from("locations").select("*").eq("id", "castle").single(),
    supabase.from("interactables").select("*").eq("location_id", "castle"),
  ]);

  return (
    <CastleScene
      backgroundImage={location?.background_image ?? "/assets/locations/castle_archive.png"}
      interactables={interactables ?? []}
    />
  );
}
