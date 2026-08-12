import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { travelToLocation } from "@/lib/actions/world";
import { HomeScene } from "@/components/home/HomeScene";
import { dictionaries } from "@/lib/i18n/dictionaries";
import { getLocale } from "@/lib/i18n/locale";

export async function generateMetadata(): Promise<Metadata> {
  const locale = await getLocale();
  return { title: dictionaries[locale].meta.home };
}

export default async function HomePage() {
  await travelToLocation("home");

  const supabase = await createClient();
  const { data: location } = await supabase.from("locations").select("*").eq("id", "home").single();

  return <HomeScene backgroundImage={location?.background_image ?? "/assets/locations/home.png"} />;
}
