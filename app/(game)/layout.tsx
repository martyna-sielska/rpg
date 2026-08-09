import type { ReactNode } from "react";
import { getCurrentPlayer } from "@/lib/game/data";
import { GameHud } from "@/components/world/GameHud";

export default async function GameLayout({ children }: { children: ReactNode }) {
  const player = await getCurrentPlayer();

  return (
    <div className="relative min-h-screen bg-wood-darkest">
      <GameHud player={player} />
      <main className="min-h-screen">{children}</main>
    </div>
  );
}
