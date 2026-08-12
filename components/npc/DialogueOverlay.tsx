"use client";

import { useEffect, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";
import { talkToNpc, type TalkResult } from "@/lib/actions/npc";
import { completeQuestTurnIn, type QuestTurnInResult } from "@/lib/actions/quests";
import { Panel } from "@/components/ui/Panel";
import { Button } from "@/components/ui/Button";
import { LevelUpModal } from "@/components/level-up/LevelUpModal";

// Falls back to a single placeholder line if a dialogue row is ever missing
// server-side (talk_to_npc returns an empty array rather than an error) —
// keeps the overlay from ever rendering a blank window.
function lines(result: TalkResult): string[] {
  return result.lines.length > 0 ? result.lines : ["..."];
}

export function DialogueOverlay({
  npcId,
  portraitImage,
  onClose,
}: {
  npcId: string;
  portraitImage: string;
  onClose: () => void;
}) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [result, setResult] = useState<TalkResult | null>(null);
  const [lineIndex, setLineIndex] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [reward, setReward] = useState<QuestTurnInResult | null>(null);
  const [levelUpTo, setLevelUpTo] = useState<number | null>(null);

  useEffect(() => {
    startTransition(async () => {
      try {
        const res = await talkToNpc(npcId);
        setResult(res);
        setLineIndex(0);
      } catch (e) {
        setError(e instanceof Error ? e.message : "Something went wrong.");
      }
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [npcId]);

  function handleClose() {
    router.refresh();
    onClose();
  }

  function handleBack() {
    setLineIndex((i) => Math.max(0, i - 1));
  }

  function handleAdvance() {
    if (!result) return;

    if (lineIndex < lines(result).length - 1) {
      setLineIndex((i) => i + 1);
      return;
    }

    if (result.state === "quest_ready" && result.questId) {
      startTransition(async () => {
        try {
          const summary = await completeQuestTurnIn(result.questId!);
          setReward(summary);
        } catch (e) {
          setError(e instanceof Error ? e.message : "Couldn't turn in the quest.");
        }
      });
      return;
    }

    handleClose();
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/50 p-4 sm:items-center" onClick={handleClose}>
      <div onClick={(e) => e.stopPropagation()} className="w-full max-w-lg">
        <Panel className="p-5">
          {error && (
            <div className="flex flex-col gap-3">
              <p className="text-sm text-parchment">{error}</p>
              <Button onClick={handleClose}>Close</Button>
            </div>
          )}

          {!error && reward && (
            <div className="flex flex-col items-center gap-2 text-center">
              <p className="font-pixel text-base text-gold">Quest Complete!</p>
              <p className="text-sm text-parchment">
                You earned gold and experience.
                {reward.rewardItemId && (
                  <>
                    {" "}
                    You received <span className="font-semibold text-gold">{reward.rewardItemQty}× {reward.rewardItemId.replace(/_/g, " ")}</span>.
                  </>
                )}
              </p>
              {reward.rewardItemId && reward.rewardItemIcon && (
                <div className="relative h-14 w-14 shrink-0 drop-shadow-[0_4px_6px_rgba(0,0,0,0.6)]">
                  <Image src={reward.rewardItemIcon} alt="" fill sizes="56px" unoptimized className="object-contain" />
                </div>
              )}
              <Button
                onClick={() => {
                  if (reward.leveledUp) {
                    setLevelUpTo(reward.newLevel);
                  } else {
                    handleClose();
                  }
                }}
              >
                Nice!
              </Button>
            </div>
          )}

          {!error && !reward && !result && (
            <p className="text-sm text-parchment-dark">...</p>
          )}

          {!error && !reward && result && (
            <div className="flex flex-col gap-4">
              <div className="flex items-start gap-4">
                <div className="relative h-20 w-16 shrink-0 overflow-hidden rounded-md border-2 border-wood-dark sm:h-24 sm:w-20">
                  <Image src={portraitImage} alt={result.npcName} fill sizes="80px" unoptimized className="object-cover object-top" />
                </div>
                <div>
                  <p className="font-pixel text-sm text-gold">{result.npcName}</p>
                  <p className="mt-2 text-sm leading-relaxed text-parchment">{lines(result)[lineIndex]}</p>
                </div>
              </div>
              <div className="flex items-center justify-between gap-2">
                <button
                  type="button"
                  onClick={handleBack}
                  disabled={isPending || lineIndex === 0}
                  className="text-sm font-semibold text-parchment-dark underline-offset-2 hover:text-parchment hover:underline disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:no-underline"
                >
                  Back
                </button>
                <Button onClick={handleAdvance} disabled={isPending}>
                  {isPending
                    ? "..."
                    : lineIndex < lines(result).length - 1
                      ? "Next"
                      : result.responseLabel}
                </Button>
              </div>
            </div>
          )}
        </Panel>
      </div>

      {levelUpTo != null && <LevelUpModal level={levelUpTo} onClose={handleClose} />}
    </div>
  );
}
