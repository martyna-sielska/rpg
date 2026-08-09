"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { AVATAR_OPTIONS, type AvatarId } from "@/lib/game/types";

export interface UpdateAvatarResult {
  error?: string;
}

export async function updateAvatar(avatarId: AvatarId): Promise<UpdateAvatarResult> {
  if (!AVATAR_OPTIONS.some((a) => a.id === avatarId)) {
    return { error: "Invalid hero." };
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: "You must be signed in." };

  const { error } = await supabase
    .from("players")
    .update({ avatar_id: avatarId })
    .eq("id", user.id);
  if (error) return { error: "Couldn't save the change." };

  revalidatePath("/profile");
  revalidatePath("/world-map");
  return {};
}
