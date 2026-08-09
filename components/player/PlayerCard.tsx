import Image from "next/image";
import { Panel } from "@/components/ui/Panel";
import { ProgressBar } from "@/components/ui/ProgressBar";
import { avatarById } from "@/lib/game/types";
import { xpProgress } from "@/lib/game/xp";
import type { Player } from "@/lib/game/types";

const STATS: { key: keyof Player; label: string }[] = [
  { key: "strength", label: "Strength" },
  { key: "intelligence", label: "Intelligence" },
  { key: "dexterity", label: "Dexterity" },
  { key: "vitality", label: "Vitality" },
  { key: "luck", label: "Luck" },
];

export function PlayerCard({ player }: { player: Player }) {
  const avatar = avatarById(player.avatar_id);
  const { xp, required } = xpProgress(player.level, player.xp);

  return (
    <Panel className="px-4 py-3">
      <div className="flex items-center gap-4">
        <div className="relative h-32 w-36 shrink-0 overflow-hidden sm:h-44 sm:w-44">
          <Image
            src={avatar.image}
            alt={avatar.name}
            fill
            sizes="176px"
            unoptimized
            className="object-contain object-top"
            style={{ transform: "scale(1.25)" }}
          />
        </div>
        <div className="min-w-0">
          <p className="truncate font-pixel text-base text-gold sm:text-lg">{player.username}</p>
          <p className="text-sm text-parchment-dark">
            {avatar.className} · Level {player.level}
          </p>
        </div>
      </div>

      <div className="mt-3 flex flex-col gap-2">
        <ProgressBar value={xp} max={required} color="xp" label="XP" />
        <ProgressBar value={player.hp} max={player.max_hp} color="hp" label="HP" />
        <div className="flex items-center gap-1.5 text-sm font-semibold text-gold">
          <span aria-hidden>🪙</span>
          <span>{player.gold} gold</span>
        </div>
      </div>

      <dl className="mt-3 grid grid-cols-2 gap-x-4 gap-y-1.5 border-t-2 border-wood-dark pt-2 text-sm">
        {STATS.map(({ key, label }) => (
          <div key={key} className="flex items-center justify-between">
            <dt className="text-parchment-dark">{label}</dt>
            <dd className="font-semibold text-parchment">{String(player[key])}</dd>
          </div>
        ))}
      </dl>
    </Panel>
  );
}
