import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { travelToLocation } from "@/lib/actions/world";
import { Panel } from "@/components/ui/Panel";
import { SceneFrame } from "@/components/world/SceneFrame";

/**
 * Placeholder scene for a location that's unlocked but not yet built out
 * (Home/Village get their real hotspot-driven scenes in Phase 2, Forest in
 * Phase 3, Dungeon in Phase 4). Still records arrival so quest objectives
 * and "current location" tracking work end-to-end before the real scene
 * exists.
 */
export async function LocationSceneStub({ locationId }: { locationId: string }) {
  await travelToLocation(locationId);

  const supabase = await createClient();
  const { data: location } = await supabase.from("locations").select("*").eq("id", locationId).single();
  if (!location) notFound();

  return (
    <SceneFrame>
      <Image src={location.background_image} alt={location.name} fill priority unoptimized className="object-cover" />
      <div className="absolute inset-0 bg-black/40" />
      <div className="absolute inset-0 flex flex-col items-center justify-center gap-4 p-6 text-center">
        <Panel className="max-w-md p-5">
          <h1 className="font-pixel text-lg text-gold">{location.name}</h1>
          <p className="mt-2 text-sm text-parchment">{location.description}</p>
          <p className="mt-4 text-xs italic text-parchment-dark">
            This location is still being built out. Check back soon.
          </p>
          <Link href="/world-map" className="mt-4 inline-block text-sm font-semibold text-gold hover:underline">
            ← Back to World Map
          </Link>
        </Panel>
      </div>
    </SceneFrame>
  );
}
