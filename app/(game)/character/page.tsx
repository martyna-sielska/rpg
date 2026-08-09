import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { getCurrentPlayer } from "@/lib/game/data";
import { PlayerCardWithEdit } from "@/components/player/PlayerCardWithEdit";
import { EquipmentSlots } from "@/components/inventory/EquipmentSlots";
import type { Item } from "@/lib/game/types";

export const metadata: Metadata = { title: "Character — Wonderhill" };

export default async function CharacterPage() {
  const player = await getCurrentPlayer();
  const supabase = await createClient();

  const { data: equipment } = await supabase.from("player_equipment").select("*").eq("player_id", player.id).maybeSingle();

  let weapon: Item | null = null;
  let armor: Item | null = null;
  let trinket: Item | null = null;

  const equippedIds = [equipment?.weapon_item_id, equipment?.armor_item_id, equipment?.trinket_item_id].filter(
    (id): id is string => Boolean(id)
  );
  if (equippedIds.length > 0) {
    const { data: items } = await supabase.from("items").select("*").in("id", equippedIds);
    const byId = new Map((items ?? []).map((i) => [i.id, i]));
    weapon = equipment?.weapon_item_id ? (byId.get(equipment.weapon_item_id) ?? null) : null;
    armor = equipment?.armor_item_id ? (byId.get(equipment.armor_item_id) ?? null) : null;
    trinket = equipment?.trinket_item_id ? (byId.get(equipment.trinket_item_id) ?? null) : null;
  }

  return (
    <div className="mx-auto flex min-h-screen max-w-3xl flex-col gap-4 px-4 pb-10 pt-24">
      <PlayerCardWithEdit player={player} />
      <EquipmentSlots weapon={weapon} armor={armor} trinket={trinket} />
    </div>
  );
}
