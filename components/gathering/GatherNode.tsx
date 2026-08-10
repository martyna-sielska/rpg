"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";
import { gatherNode } from "@/lib/actions/inventory";

export function GatherNode({
  nodeId,
  name,
  iconImage,
  mapX,
  mapY,
}: {
  nodeId: string;
  name: string;
  iconImage: string;
  mapX: number;
  mapY: number;
}) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [message, setMessage] = useState<string | null>(null);

  function handleClick() {
    startTransition(async () => {
      try {
        const result = await gatherNode(nodeId);
        setMessage(`+${result.quantity} ${result.itemId.replace(/_/g, " ")}`);
        router.refresh();
      } catch (e) {
        setMessage(e instanceof Error ? e.message : "Nothing to gather here right now.");
      }
      setTimeout(() => setMessage(null), 2500);
    });
  }

  return (
    <button
      type="button"
      onClick={handleClick}
      disabled={isPending}
      className="group absolute flex -translate-x-1/2 -translate-y-1/2 flex-col items-center gap-1"
      style={{ left: `${mapX}%`, top: `${mapY}%` }}
    >
      <div className="relative h-12 w-12 overflow-hidden rounded-full border-4 border-wood-dark bg-parchment/90 p-2 shadow-[0_6px_16px_rgba(0,0,0,0.5)] transition group-hover:scale-110">
        <Image src={iconImage} alt="" fill sizes="48px" unoptimized className="object-contain" />
      </div>
      <div className="pointer-events-none whitespace-nowrap rounded-md border-2 border-wood-dark bg-wood-darkest/90 px-2 py-0.5 text-[10px] font-semibold text-parchment opacity-0 shadow-lg transition group-hover:opacity-100">
        {message ?? name}
      </div>
    </button>
  );
}
