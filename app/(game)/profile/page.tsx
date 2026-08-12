import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { getCurrentPlayer } from "@/lib/game/data";
import { PlayerCardWithEdit } from "@/components/player/PlayerCardWithEdit";
import { Panel } from "@/components/ui/Panel";
import { getDictionary } from "@/lib/i18n/getDictionary";
import { dictionaries } from "@/lib/i18n/dictionaries";
import { getLocale } from "@/lib/i18n/locale";

const DATE_LOCALE: Record<string, string> = { en: "en-US", pl: "pl-PL" };

export async function generateMetadata(): Promise<Metadata> {
  const locale = await getLocale();
  return { title: dictionaries[locale].meta.profile };
}

export default async function ProfilePage() {
  const player = await getCurrentPlayer();
  const supabase = await createClient();
  const t = await getDictionary();
  const locale = await getLocale();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  return (
    <div className="mx-auto grid min-h-screen max-w-3xl gap-6 px-4 pb-10 pt-24 md:grid-cols-[320px_1fr]">
      <PlayerCardWithEdit player={player} />
      <Panel className="p-4 text-parchment">
        <h2 className="mb-3 font-pixel text-sm text-gold">{t.profile.account}</h2>
        <dl className="flex flex-col gap-2 text-sm">
          <div className="flex justify-between border-b border-wood-dark pb-2">
            <dt className="text-parchment-dark">{t.profile.email}</dt>
            <dd>{user?.email}</dd>
          </div>
          <div className="flex justify-between">
            <dt className="text-parchment-dark">{t.profile.characterJoined}</dt>
            <dd>{new Date(player.created_at).toLocaleDateString(DATE_LOCALE[locale])}</dd>
          </div>
        </dl>
      </Panel>
    </div>
  );
}
