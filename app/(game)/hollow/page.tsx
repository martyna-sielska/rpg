import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { travelToLocation } from "@/lib/actions/world";
import { HollowScene } from "@/components/world/HollowScene";
import { dictionaries } from "@/lib/i18n/dictionaries";
import { getLocale } from "@/lib/i18n/locale";
import { localize } from "@/lib/i18n/localize";

export async function generateMetadata(): Promise<Metadata> {
  const locale = await getLocale();
  return { title: dictionaries[locale].meta.hollow };
}

export default async function HollowPage() {
  await travelToLocation("hollow");

  const supabase = await createClient();
  const locale = await getLocale();
  const [{ data: location }, { data: interactables }] = await Promise.all([
    supabase.from("locations").select("*").eq("id", "hollow").single(),
    supabase.rpc("get_visible_interactables", { p_location_id: "hollow" }),
  ]);

  return (
    <HollowScene
      backgroundImage={location?.background_image ?? "/assets/locations/hollow.png"}
      interactables={(interactables ?? []).map((i) => localize(i, locale, ["name", "lines"]))}
    />
  );
}
