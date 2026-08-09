import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { travelToLocation } from "@/lib/actions/world";
import { MagicTowerScene } from "@/components/world/MagicTowerScene";

export const metadata: Metadata = { title: "Magic Tower — Wonderhill" };

export default async function MagicTowerPage() {
  await travelToLocation("magic_tower");

  const supabase = await createClient();
  const [{ data: location }, { data: scholar }, { data: interactables }] = await Promise.all([
    supabase.from("locations").select("*").eq("id", "magic_tower").single(),
    supabase.from("npcs").select("*").eq("id", "scholar_alden").maybeSingle(),
    supabase.from("interactables").select("*").eq("location_id", "magic_tower"),
  ]);

  return (
    <MagicTowerScene
      backgroundImage={location?.background_image ?? "/assets/locations/magic_tower.png"}
      scholar={scholar ?? null}
      interactables={interactables ?? []}
    />
  );
}
