"use server";

import { createClient } from "@/lib/supabase/server";
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
  const { data, error } = await supabase.rpc("talk_to_npc", { p_npc_id: npcId });
  const row = data?.[0];
  if (error || !row) throw new Error(error?.message ?? "Couldn't talk to them right now.");

  return {
    npcName: row.out_npc_name,
    state: row.out_state,
    lines: row.out_lines,
    responseLabel: row.out_response_label,
    questId: row.out_quest_id,
  };
}
