"use client";

import { useState } from "react";
import { Panel } from "@/components/ui/Panel";
import { Button } from "@/components/ui/Button";
import type { InteractResult } from "@/lib/actions/interactables";

export function InteractOverlay({
  name,
  result,
  error,
  onClose,
}: {
  name: string;
  result: InteractResult | null;
  error: string | null;
  onClose: () => void;
}) {
  const [lineIndex, setLineIndex] = useState(0);

  function handleAdvance() {
    if (result && lineIndex < result.lines.length - 1) {
      setLineIndex((i) => i + 1);
      return;
    }
    onClose();
  }

  function handleBack() {
    setLineIndex((i) => Math.max(0, i - 1));
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/50 p-4 sm:items-center" onClick={onClose}>
      <div onClick={(e) => e.stopPropagation()} className="w-full max-w-lg">
        <Panel className="p-5">
          {error && (
            <div className="flex flex-col gap-3">
              <p className="text-sm text-parchment">{error}</p>
              <Button onClick={onClose}>Close</Button>
            </div>
          )}

          {!error && result && (
            <div className="flex flex-col gap-4">
              <div>
                <p className="font-pixel text-sm text-gold">{name}</p>
                <p className="mt-2 text-sm leading-relaxed text-parchment">{result.lines[lineIndex]}</p>
                {result.grantedItemId && lineIndex === result.lines.length - 1 && (
                  <p className="mt-2 text-xs font-semibold text-gold">
                    +{result.grantedItemQty} {result.grantedItemId.replace(/_/g, " ")}
                  </p>
                )}
              </div>
              <div className="flex items-center justify-end gap-2">
                {lineIndex > 0 && (
                  <Button onClick={handleBack} variant="secondary">
                    Back
                  </Button>
                )}
                <Button onClick={handleAdvance}>{lineIndex < result.lines.length - 1 ? "Next" : "Close"}</Button>
              </div>
            </div>
          )}
        </Panel>
      </div>
    </div>
  );
}
