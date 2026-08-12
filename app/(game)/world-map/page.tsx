import type { Metadata } from "next";
import { getAllLocations, getCurrentPlayer, getPlayerLocations } from "@/lib/game/data";
import { WorldMap } from "@/components/world/WorldMap";
import { dictionaries } from "@/lib/i18n/dictionaries";
import { getLocale } from "@/lib/i18n/locale";

export async function generateMetadata(): Promise<Metadata> {
  const locale = await getLocale();
  return { title: dictionaries[locale].meta.worldMap };
}

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
