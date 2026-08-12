import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { travelToLocation } from "@/lib/actions/world";
import { LakeScene } from "@/components/world/LakeScene";
import { dictionaries } from "@/lib/i18n/dictionaries";
import { getLocale } from "@/lib/i18n/locale";
import { localize } from "@/lib/i18n/localize";

export async function generateMetadata(): Promise<Metadata> {
  const locale = await getLocale();
  return { title: dictionaries[locale].meta.lake };
}

export default async function LakePage() {
  await travelToLocation("lake");

  const supabase = await createClient();
  const locale = await getLocale();
  const [{ data: location }, { data: interactables }] = await Promise.all([
    supabase.from("locations").select("*").eq("id", "lake").single(),
    supabase.from("interactables").select("*").eq("location_id", "lake"),
  ]);

  return (
    <LakeScene
      backgroundImage={location?.background_image ?? "/assets/locations/lake.png"}
      interactables={(interactables ?? []).map((i) => localize(i, locale, ["name", "lines"]))}
    />
  );
}
