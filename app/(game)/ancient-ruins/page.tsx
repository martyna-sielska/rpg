import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { travelToLocation } from "@/lib/actions/world";
import { AncientRuinsScene } from "@/components/world/AncientRuinsScene";
import { dictionaries } from "@/lib/i18n/dictionaries";
import { getLocale } from "@/lib/i18n/locale";
import { localize } from "@/lib/i18n/localize";

export async function generateMetadata(): Promise<Metadata> {
  const locale = await getLocale();
  return { title: dictionaries[locale].meta.ancientRuins };
}

export default async function AncientRuinsPage() {
  await travelToLocation("ancient_ruins");

  const supabase = await createClient();
  const locale = await getLocale();
  const [{ data: location }, { data: interactables }] = await Promise.all([
    supabase.from("locations").select("*").eq("id", "ancient_ruins").single(),
    supabase.rpc("get_visible_interactables", { p_location_id: "ancient_ruins" }),
  ]);

  return (
    <AncientRuinsScene
      backgroundImage={location?.background_image ?? "/assets/locations/ancient_ruins.png"}
      interactables={(interactables ?? []).map((i) => localize(i, locale, ["name", "lines"]))}
    />
  );
}
