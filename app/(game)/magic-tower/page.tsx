import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { travelToLocation } from "@/lib/actions/world";
import { MagicTowerScene } from "@/components/world/MagicTowerScene";
import { dictionaries } from "@/lib/i18n/dictionaries";
import { getLocale } from "@/lib/i18n/locale";
import { localize } from "@/lib/i18n/localize";

export async function generateMetadata(): Promise<Metadata> {
  const locale = await getLocale();
  return { title: dictionaries[locale].meta.magicTower };
}

export default async function MagicTowerPage() {
  await travelToLocation("magic_tower");

  const supabase = await createClient();
  const locale = await getLocale();
  const [{ data: location }, { data: scholar }, { data: interactables }] = await Promise.all([
    supabase.from("locations").select("*").eq("id", "magic_tower").single(),
    supabase.from("npcs").select("*").eq("id", "scholar_alden").maybeSingle(),
    supabase.from("interactables").select("*").eq("location_id", "magic_tower"),
  ]);

  return (
    <MagicTowerScene
      backgroundImage={location?.background_image ?? "/assets/locations/magic_tower.png"}
      scholar={scholar ? localize(scholar, locale, ["role"]) : null}
      interactables={(interactables ?? []).map((i) => localize(i, locale, ["name", "lines"]))}
    />
  );
}
