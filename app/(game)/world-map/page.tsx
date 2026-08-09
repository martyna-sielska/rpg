import type { Metadata } from "next";
import { getAllLocations, getCurrentPlayer, getPlayerLocations } from "@/lib/game/data";
import { WorldMap } from "@/components/world/WorldMap";

export const metadata: Metadata = { title: "World Map — Wonderhill" };

export default async function WorldMapPage() {
  const [player, locations, playerLocations] = await Promise.all([
    getCurrentPlayer(),
    getAllLocations(),
    getPlayerLocations(),
  ]);

  return (
    <WorldMap
      locations={locations}
      playerLocations={playerLocations}
      currentLocationId={player.current_location_id}
    />
  );
}
