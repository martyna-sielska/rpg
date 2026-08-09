import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { getCurrentPlayer } from "@/lib/game/data";
import { travelToLocation } from "@/lib/actions/world";
import { DungeonScene } from "@/components/world/DungeonScene";
import { avatarById } from "@/lib/game/types";
import type { StatBonus } from "@/lib/game/database.types";

export const metadata: Metadata = { title: "Forest Dungeon — Wonderhill" };

export default async function DungeonPage() {
  await travelToLocation("dungeon_ruins");

  const player = await getCurrentPlayer();
  const supabase = await createClient();

  const [{ data: location }, { data: monsters }, { data: bossState }, { data: equipment }, { data: potionRow }] =
    await Promise.all([
      supabase.from("locations").select("*").eq("id", "dungeon_ruins").single(),
      supabase.from("monsters").select("*").eq("location_id", "dungeon_ruins").in("tier", ["miniboss", "boss"]),
      supabase.from("player_boss_state").select("*").eq("player_id", player.id),
      supabase.from("player_equipment").select("*").eq("player_id", player.id).maybeSingle(),
      supabase.from("player_inventory").select("quantity").eq("player_id", player.id).eq("item_id", "healing_potion").maybeSingle(),
    ]);

  let weaponBonus = 0;
  if (equipment?.weapon_item_id) {
    const { data: weapon } = await supabase.from("items").select("stat_bonus").eq("id", equipment.weapon_item_id).single();
    weaponBonus = (weapon?.stat_bonus as StatBonus | undefined)?.strength ?? 0;
  }

  const miniboss = monsters?.find((m) => m.tier === "miniboss") ?? null;
  const boss = monsters?.find((m) => m.tier === "boss") ?? null;
  const minibossDefeated = bossState?.some((s) => s.monster_id === miniboss?.id && s.defeated) ?? false;
  const bossDefeated = bossState?.some((s) => s.monster_id === boss?.id && s.defeated) ?? false;

  return (
    <DungeonScene
      backgroundImage={location?.background_image ?? "/assets/locations/dungeon.png"}
      miniboss={miniboss}
      boss={boss}
      minibossDefeated={minibossDefeated}
      bossDefeated={bossDefeated}
      player={player}
      avatarImage={avatarById(player.avatar_id).image}
      weaponBonus={weaponBonus}
      potionCount={potionRow?.quantity ?? 0}
    />
  );
}
