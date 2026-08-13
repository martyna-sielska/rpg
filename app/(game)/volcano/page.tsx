import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { getCurrentPlayer } from "@/lib/game/data";
import { travelToLocation } from "@/lib/actions/world";
import { VolcanoScene } from "@/components/world/VolcanoScene";
import { avatarById } from "@/lib/game/types";
import { dictionaries } from "@/lib/i18n/dictionaries";
import { getLocale } from "@/lib/i18n/locale";
import { localize } from "@/lib/i18n/localize";
import type { StatBonus } from "@/lib/game/database.types";

export async function generateMetadata(): Promise<Metadata> {
  const locale = await getLocale();
  return { title: dictionaries[locale].meta.volcano };
}

export default async function VolcanoPage() {
  await travelToLocation("volcano");

  const player = await getCurrentPlayer();
  const supabase = await createClient();
  const locale = await getLocale();

  const [
    { data: location },
    { data: gatheringNodes },
    { data: items },
    { data: interactables },
    { data: monsters },
    { data: bossState },
    { data: interactions },
    { data: thirdSealQuest },
    { data: equipment },
    { data: potionRow },
  ] = await Promise.all([
    supabase.from("locations").select("*").eq("id", "volcano").single(),
    supabase.from("gathering_nodes").select("*").eq("location_id", "volcano"),
    supabase.from("items").select("id, icon_image"),
    supabase.rpc("get_visible_interactables", { p_location_id: "volcano" }),
    supabase.from("monsters").select("*").eq("location_id", "volcano").eq("tier", "boss"),
    supabase.from("player_boss_state").select("*").eq("player_id", player.id),
    supabase.from("player_interactions").select("interactable_id").eq("player_id", player.id).eq("interactable_id", "volcano_seal_chamber"),
    supabase.from("player_quests").select("status").eq("player_id", player.id).eq("quest_id", "the_third_seal").maybeSingle(),
    supabase.from("player_equipment").select("*").eq("player_id", player.id).maybeSingle(),
    supabase.from("player_inventory").select("quantity").eq("player_id", player.id).eq("item_id", "healing_potion").maybeSingle(),
  ]);

  let weaponBonus = 0;
  if (equipment?.weapon_item_id) {
    const { data: weapon } = await supabase.from("items").select("stat_bonus").eq("id", equipment.weapon_item_id).single();
    weaponBonus = (weapon?.stat_bonus as StatBonus | undefined)?.strength ?? 0;
  }

  const boss = monsters?.[0] ? localize(monsters[0], locale, ["name", "description"]) : null;
  const bossDefeated = bossState?.some((s) => s.monster_id === boss?.id && s.defeated) ?? false;
  const chamberReached = (interactions?.length ?? 0) > 0;
  const questActive = thirdSealQuest?.status === "active" || thirdSealQuest?.status === "ready_to_turn_in";
  const itemIcons = Object.fromEntries((items ?? []).map((item) => [item.id, item.icon_image]));

  return (
    <VolcanoScene
      backgroundImage={location?.background_image ?? "/assets/locations/volcano.png"}
      gatheringNodes={(gatheringNodes ?? []).map((n) => localize(n, locale, ["name"]))}
      itemIcons={itemIcons}
      interactables={(interactables ?? []).map((i) => localize(i, locale, ["name", "lines"]))}
      boss={boss}
      bossDefeated={bossDefeated}
      chamberReached={chamberReached}
      questActive={questActive}
      player={player}
      avatarImage={avatarById(player.avatar_id).image}
      weaponBonus={weaponBonus}
      potionCount={potionRow?.quantity ?? 0}
    />
  );
}
