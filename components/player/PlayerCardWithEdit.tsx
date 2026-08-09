"use client";

import { useState } from "react";
import { PlayerCard } from "@/components/player/PlayerCard";
import { ChangeAvatarModal } from "@/components/player/ChangeAvatarModal";
import type { Player } from "@/lib/game/types";

export function PlayerCardWithEdit({ player }: { player: Player }) {
  const [open, setOpen] = useState(false);

  return (
    <div className="relative">
      <PlayerCard player={player} />
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="absolute right-4 top-4 rounded-md border-2 border-wood-dark bg-wood-darkest/70 px-2 py-1 text-xs text-parchment hover:border-gold hover:text-gold"
      >
        Change Hero
      </button>
      <ChangeAvatarModal
        open={open}
        onClose={() => setOpen(false)}
        currentAvatarId={player.avatar_id}
      />
    </div>
  );
}
