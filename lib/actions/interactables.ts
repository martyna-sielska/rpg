"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { getLocale } from "@/lib/i18n/locale";
import { getDictionary } from "@/lib/i18n/getDictionary";

export interface InteractResult {
  lines: string[];
  grantedItemId: string | null;
  grantedItemQty: number;
  grantedItemIcon: string | null;
}

/**
 * Investigates a point of interest: fires the 'interact' quest event,
 * grants its item on first interaction only, and returns the flavor lines
 * every time. Mirrors gatherNode in lib/actions/inventory.ts.
 */
export async function interactWithObject(id: string): Promise<InteractResult> {
  const supabase = await createClient();
  const locale = await getLocale();
  const { data, error } = await supabase.rpc("interact_with_object", { p_id: id });
  const row = data?.[0];
  if (error || !row) {
    const t = await getDictionary();
    throw new Error(error?.message ?? t.interact.nothingHappens);
  }

  revalidatePath("/quests");
  revalidatePath("/inventory");

  let grantedItemIcon: string | null = null;
  if (row.out_granted_item_id) {
    const { data: item } = await supabase.from("items").select("icon_image").eq("id", row.out_granted_item_id).single();
    grantedItemIcon = item?.icon_image ?? null;
  }

  const isPl = locale === "pl";
  return {
    lines: (isPl && row.out_lines_pl?.length ? row.out_lines_pl : row.out_lines) ?? [],
    grantedItemId: row.out_granted_item_id,
    grantedItemQty: row.out_granted_item_qty,
    grantedItemIcon,
  };
}
