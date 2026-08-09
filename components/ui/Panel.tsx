import type { ReactNode } from "react";

export function Panel({
  children,
  className = "",
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <div
      className={`rounded-xl border-4 border-wood-dark bg-wood/90 shadow-[inset_0_1px_0_rgba(255,255,255,0.08),0_8px_24px_rgba(0,0,0,0.4)] ${className}`}
    >
      {children}
    </div>
  );
}

export function ParchmentPanel({
  children,
  className = "",
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <div
      className={`rounded-lg border-4 border-wood-dark bg-parchment text-ink shadow-[inset_0_1px_0_rgba(255,255,255,0.4),0_8px_24px_rgba(0,0,0,0.35)] ${className}`}
    >
      {children}
    </div>
  );
}
