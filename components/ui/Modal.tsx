"use client";

import type { ReactNode } from "react";
import { useI18n } from "@/lib/i18n/I18nProvider";

export function Modal({
  open,
  onClose,
  title,
  children,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
}) {
  const { t } = useI18n();
  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      onClick={onClose}
    >
      <div
        className="max-h-[90vh] w-full max-w-md overflow-y-auto rounded-xl border-4 border-wood-dark bg-wood p-5 shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="mb-4 flex items-center justify-between">
          <h2 className="font-pixel text-sm text-gold">{title}</h2>
          <button
            type="button"
            onClick={onClose}
            aria-label={t.common.close}
            className="text-lg leading-none text-parchment-dark hover:text-parchment"
          >
            ✕
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}
