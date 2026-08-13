import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { travelToLocation } from "@/lib/actions/world";
import { VillageScene } from "@/components/world/VillageScene";
import { dictionaries } from "@/lib/i18n/dictionaries";
import { getLocale } from "@/lib/i18n/locale";
import { localize } from "@/lib/i18n/localize";

export async function generateMetadata(): Promise<Metadata> {
  const locale = await getLocale();
  return { title: dictionaries[locale].meta.village };
}

export default async function VillagePage() {
  await travelToLocation("village");

  const supabase = await createClient();
  const locale = await getLocale();
  const [{ data: location }, { data: npcs }, { data: interactables }] = await Promise.all([
    supabase.from("locations").select("*").eq("id", "village").single(),
    supabase.from("npcs").select("*").eq("location_id", "village").order("sort_order"),
    supabase.rpc("get_visible_interactables", { p_location_id: "village" }),
  ]);

  return (
    <VillageScene
      backgroundImage={location?.background_image ?? "/assets/locations/village.png"}
      npcs={(npcs ?? []).map((n) => localize(n, locale, ["role"]))}
      interactables={(interactables ?? []).map((i) => localize(i, locale, ["name", "lines"]))}
    />
  );
}
