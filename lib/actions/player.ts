"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { getDictionary } from "@/lib/i18n/getDictionary";
import { AVATAR_OPTIONS, type AvatarId } from "@/lib/game/types";

export interface UpdateAvatarResult {
  error?: string;
}

export async function updateAvatar(avatarId: AvatarId): Promise<UpdateAvatarResult> {
  const t = await getDictionary();
  if (!AVATAR_OPTIONS.some((a) => a.id === avatarId)) {
    return { error: t.changeHero.errors.invalidHero };
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: t.changeHero.errors.mustBeSignedIn };

  const { error } = await supabase
    .from("players")
    .update({ avatar_id: avatarId })
    .eq("id", user.id);
  if (error) return { error: t.changeHero.errors.saveFailed };

  revalidatePath("/profile");
  revalidatePath("/world-map");
  return {};
}
