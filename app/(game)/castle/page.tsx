import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { travelToLocation } from "@/lib/actions/world";
import { CastleScene } from "@/components/world/CastleScene";
import { dictionaries } from "@/lib/i18n/dictionaries";
import { getLocale } from "@/lib/i18n/locale";
import { localize } from "@/lib/i18n/localize";

export async function generateMetadata(): Promise<Metadata> {
  const locale = await getLocale();
  return { title: dictionaries[locale].meta.castle };
}

export default async function CastlePage() {
  await travelToLocation("castle");

  const supabase = await createClient();
  const locale = await getLocale();
  const [{ data: location }, { data: interactables }] = await Promise.all([
    supabase.from("locations").select("*").eq("id", "castle").single(),
    supabase.from("interactables").select("*").eq("location_id", "castle"),
  ]);

  return (
    <CastleScene
      backgroundImage={location?.background_image ?? "/assets/locations/castle_archive.png"}
      interactables={(interactables ?? []).map((i) => localize(i, locale, ["name", "lines"]))}
    />
  );
}
