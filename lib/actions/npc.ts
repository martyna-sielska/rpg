"use server";

import { createClient } from "@/lib/supabase/server";
import { getLocale } from "@/lib/i18n/locale";
import { getDictionary } from "@/lib/i18n/getDictionary";
import { localize } from "@/lib/i18n/localize";
import type { DialogueState } from "@/lib/game/types";

export interface TalkResult {
  npcName: string;
  state: DialogueState;
  lines: string[];
  responseLabel: string;
  questId: string | null;
  questTitle: string | null;
  questDescription: string | null;
}

export async function talkToNpc(npcId: string): Promise<TalkResult> {
  const supabase = await createClient();
  const locale = await getLocale();
  const { data, error } = await supabase.rpc("talk_to_npc", { p_npc_id: npcId });
  const row = data?.[0];
  if (error || !row) {
    const t = await getDictionary();
    throw new Error(error?.message ?? t.dialogue.loadError);
  }

  const isPl = locale === "pl";

  // A brand-new quest was just inserted into player_quests by talk_to_npc —
  // fetch its title/description so the overlay can announce it once the
  // player has read through the offer dialogue, instead of the quest
  // silently appearing in the quest log.
  let questTitle: string | null = null;
  let questDescription: string | null = null;
  if (row.out_state === "quest_offer" && row.out_quest_id) {
    const { data: quest } = await supabase
      .from("quests")
      .select("title, title_pl, description, description_pl")
      .eq("id", row.out_quest_id)
      .single();
    if (quest) {
      const localized = localize(quest, locale, ["title", "description"]);
      questTitle = localized.title;
      questDescription = localized.description;
    }
  }

  return {
    npcName: row.out_npc_name,
    state: row.out_state,
    lines: (isPl && row.out_lines_pl?.length ? row.out_lines_pl : row.out_lines) ?? [],
    responseLabel: (isPl && row.out_response_label_pl) || row.out_response_label,
    questId: row.out_quest_id,
    questTitle,
    questDescription,
  };
}
