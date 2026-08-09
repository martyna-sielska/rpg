import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { travelToLocation } from "@/lib/actions/world";
import { HomeScene } from "@/components/home/HomeScene";

export const metadata: Metadata = { title: "Home — Wonderhill" };

export default async function HomePage() {
  await travelToLocation("home");

  const supabase = await createClient();
  const { data: location } = await supabase.from("locations").select("*").eq("id", "home").single();

  return <HomeScene backgroundImage={location?.background_image ?? "/assets/locations/home.png"} />;
}
