"use server";

import { createClient } from "@/lib/supabase/server";
import { getLocale } from "@/lib/i18n/locale";
import { getDictionary } from "@/lib/i18n/getDictionary";
import type { DialogueState } from "@/lib/game/types";

export interface TalkResult {
  npcName: string;
  state: DialogueState;
  lines: string[];
  responseLabel: string;
  questId: string | null;
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
  return {
    npcName: row.out_npc_name,
    state: row.out_state,
    lines: (isPl && row.out_lines_pl?.length ? row.out_lines_pl : row.out_lines) ?? [],
    responseLabel: (isPl && row.out_response_label_pl) || row.out_response_label,
    questId: row.out_quest_id,
  };
}
