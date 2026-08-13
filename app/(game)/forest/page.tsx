import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { getCurrentPlayer } from "@/lib/game/data";
import { travelToLocation } from "@/lib/actions/world";
import { ForestScene } from "@/components/world/ForestScene";
import { avatarById } from "@/lib/game/types";
import { dictionaries } from "@/lib/i18n/dictionaries";
import { getLocale } from "@/lib/i18n/locale";
import { localize } from "@/lib/i18n/localize";
import type { StatBonus } from "@/lib/game/database.types";

export async function generateMetadata(): Promise<Metadata> {
  const locale = await getLocale();
  return { title: dictionaries[locale].meta.forest };
}

export default async function ForestPage() {
  await travelToLocation("forest");

  const player = await getCurrentPlayer();
  const supabase = await createClient();
  const locale = await getLocale();

  const [{ data: location }, { data: gatheringNodes }, { data: items }, { data: monsters }, { data: interactables }, { data: equipment }, { data: potionRow }] =
    await Promise.all([
      supabase.from("locations").select("*").eq("id", "forest").single(),
      supabase.from("gathering_nodes").select("*").eq("location_id", "forest"),
      supabase.from("items").select("id, icon_image"),
      supabase.from("monsters").select("*").eq("location_id", "forest").eq("tier", "regular"),
      supabase.rpc("get_visible_interactables", { p_location_id: "forest" }),
      supabase.from("player_equipment").select("*").eq("player_id", player.id).maybeSingle(),
      supabase.from("player_inventory").select("quantity").eq("player_id", player.id).eq("item_id", "healing_potion").maybeSingle(),
    ]);

  let weaponBonus = 0;
  if (equipment?.weapon_item_id) {
    const { data: weapon } = await supabase.from("items").select("stat_bonus").eq("id", equipment.weapon_item_id).single();
    weaponBonus = (weapon?.stat_bonus as StatBonus | undefined)?.strength ?? 0;
  }

  const itemIcons = Object.fromEntries((items ?? []).map((item) => [item.id, item.icon_image]));

  return (
    <ForestScene
      backgroundImage={location?.background_image ?? "/assets/locations/forest.png"}
      gatheringNodes={(gatheringNodes ?? []).map((n) => localize(n, locale, ["name"]))}
      itemIcons={itemIcons}
      monsters={(monsters ?? []).map((m) => localize(m, locale, ["name", "description"]))}
      interactables={(interactables ?? []).map((i) => localize(i, locale, ["name", "lines"]))}
      player={player}
      avatarImage={avatarById(player.avatar_id).image}
      weaponBonus={weaponBonus}
      potionCount={potionRow?.quantity ?? 0}
    />
  );
}
