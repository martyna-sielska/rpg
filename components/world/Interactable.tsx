"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { interactWithObject, type InteractResult } from "@/lib/actions/interactables";
import { InteractOverlay } from "@/components/world/InteractOverlay";

export function Interactable({ id, name, mapX, mapY }: { id: string; name: string; mapX: number; mapY: number }) {
  const router = useRouter();
  const [isPending, setIsPending] = useState(false);
  const [result, setResult] = useState<InteractResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function handleClick() {
    setIsPending(true);
    try {
      const res = await interactWithObject(id);
      setResult(res);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Nothing happens.");
    } finally {
      setIsPending(false);
    }
  }

  function handleClose() {
    setResult(null);
    setError(null);
    router.refresh();
  }

  return (
    <>
      <button
        type="button"
        onClick={handleClick}
        disabled={isPending}
        className="group absolute flex -translate-x-1/2 -translate-y-1/2 flex-col items-center gap-1"
        style={{ left: `${mapX}%`, top: `${mapY}%` }}
      >
        <div className="flex h-12 w-12 items-center justify-center rounded-full border-4 border-wood-dark bg-parchment/90 text-xl shadow-[0_6px_16px_rgba(0,0,0,0.5)] transition group-hover:scale-110">
          <span aria-hidden>🔍</span>
        </div>
        <div className="pointer-events-none whitespace-nowrap rounded-md border-2 border-wood-dark bg-wood-darkest/90 px-2 py-0.5 text-[10px] font-semibold text-parchment opacity-0 shadow-lg transition group-hover:opacity-100">
          {name}
        </div>
      </button>

      {(result || error) && <InteractOverlay name={name} result={result} error={error} onClose={handleClose} />}
    </>
  );
}
