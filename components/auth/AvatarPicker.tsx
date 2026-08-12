"use client";

import Image from "next/image";
import { AVATAR_OPTIONS, type AvatarId } from "@/lib/game/types";
import { useI18n } from "@/lib/i18n/I18nProvider";

export function AvatarPicker({
  value,
  onChange,
}: {
  value: AvatarId;
  onChange: (id: AvatarId) => void;
}) {
  const { t } = useI18n();
  return (
    <div>
      <span className="mb-2 block font-pixel text-xs uppercase tracking-wide text-parchment-dark">
        {t.auth.chooseHero}
      </span>
      <div className="grid grid-cols-4 gap-2">
        {AVATAR_OPTIONS.map((avatar) => {
          const selected = avatar.id === value;
          return (
            <button
              key={avatar.id}
              type="button"
              onClick={() => onChange(avatar.id)}
              aria-pressed={selected}
              className={`flex flex-col items-center gap-1 rounded-lg border-2 p-2 transition ${
                selected
                  ? "border-gold bg-wood-light/60"
                  : "border-wood-dark bg-wood-dark/40 hover:border-wood-light"
              }`}
            >
              <div className="relative h-28 w-20 sm:h-32 sm:w-24">
                <Image
                  src={avatar.image}
                  alt={avatar.name}
                  fill
                  sizes="120px"
                  unoptimized
                  className="object-contain object-top"
                />
              </div>
              <span className="text-[10px] font-semibold text-parchment sm:text-xs">
                {avatar.name}
              </span>
              <span className="text-[9px] text-parchment-dark">{t.heroClass[avatar.id]}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
