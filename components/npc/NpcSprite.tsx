"use client";

import Image from "next/image";

export function NpcSprite({
  name,
  role,
  portraitImage,
  mapX,
  mapY,
  onClick,
}: {
  name: string;
  role: string;
  portraitImage: string;
  mapX: number;
  mapY: number;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="group absolute flex -translate-x-1/2 -translate-y-1/2 flex-col items-center gap-1"
      style={{ left: `${mapX}%`, top: `${mapY}%` }}
    >
      <div className="relative h-14 w-14 overflow-hidden rounded-full border-4 border-wood-dark bg-parchment shadow-[0_6px_16px_rgba(0,0,0,0.5)] transition group-hover:scale-110">
        <Image src={portraitImage} alt={name} fill sizes="56px" unoptimized className="object-cover object-top" />
      </div>
      <div className="pointer-events-none whitespace-nowrap rounded-md border-2 border-wood-dark bg-wood-darkest/90 px-2 py-0.5 text-[10px] font-semibold text-parchment opacity-0 shadow-lg transition group-hover:opacity-100">
        {name} · {role}
      </div>
    </button>
  );
}
