import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { getCurrentPlayer } from "@/lib/game/data";
import { PlayerCardWithEdit } from "@/components/player/PlayerCardWithEdit";
import { Panel } from "@/components/ui/Panel";

export const metadata: Metadata = { title: "Profile — Wonderhill" };

export default async function ProfilePage() {
  const player = await getCurrentPlayer();
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  return (
    <div className="mx-auto grid min-h-screen max-w-3xl gap-6 px-4 pb-10 pt-24 md:grid-cols-[320px_1fr]">
      <PlayerCardWithEdit player={player} />
      <Panel className="p-4 text-parchment">
        <h2 className="mb-3 font-pixel text-sm text-gold">Account</h2>
        <dl className="flex flex-col gap-2 text-sm">
          <div className="flex justify-between border-b border-wood-dark pb-2">
            <dt className="text-parchment-dark">Email</dt>
            <dd>{user?.email}</dd>
          </div>
          <div className="flex justify-between">
            <dt className="text-parchment-dark">Character joined</dt>
            <dd>{new Date(player.created_at).toLocaleDateString("en-US")}</dd>
          </div>
        </dl>
      </Panel>
    </div>
  );
}
