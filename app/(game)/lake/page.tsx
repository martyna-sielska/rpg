import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { travelToLocation } from "@/lib/actions/world";
import { LakeScene } from "@/components/world/LakeScene";

export const metadata: Metadata = { title: "Magic Lake — Wonderhill" };

export default async function LakePage() {
  await travelToLocation("lake");

  const supabase = await createClient();
  const [{ data: location }, { data: interactables }] = await Promise.all([
    supabase.from("locations").select("*").eq("id", "lake").single(),
    supabase.from("interactables").select("*").eq("location_id", "lake"),
  ]);

  return (
    <LakeScene
      backgroundImage={location?.background_image ?? "/assets/locations/lake.png"}
      interactables={interactables ?? []}
    />
  );
}
