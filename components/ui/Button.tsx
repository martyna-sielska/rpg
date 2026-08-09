"use client";

import { useFormStatus } from "react-dom";
import type { ButtonHTMLAttributes, ReactNode } from "react";

const VARIANTS = {
  primary:
    "bg-gold text-ink border-gold-light hover:bg-gold-light active:translate-y-px",
  secondary:
    "bg-wood-light text-parchment border-wood-dark hover:bg-wood active:translate-y-px",
  danger:
    "bg-hp text-parchment border-red-900 hover:brightness-110 active:translate-y-px",
} as const;

type Variant = keyof typeof VARIANTS;

export function Button({
  children,
  variant = "primary",
  className = "",
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & { variant?: Variant; children: ReactNode }) {
  return (
    <button
      className={`inline-flex items-center justify-center gap-2 rounded-lg border-b-4 px-5 py-2.5 font-pixel text-sm font-semibold tracking-wide shadow-md transition disabled:cursor-not-allowed disabled:opacity-60 ${VARIANTS[variant]} ${className}`}
      {...props}
    >
      {children}
    </button>
  );
}

export function SubmitButton({
  children,
  pendingLabel,
  variant = "primary",
  className = "",
}: {
  children: ReactNode;
  pendingLabel?: string;
  variant?: Variant;
  className?: string;
}) {
  const { pending } = useFormStatus();
  return (
    <Button type="submit" variant={variant} disabled={pending} className={`w-full ${className}`}>
      {pending ? pendingLabel ?? "..." : children}
    </Button>
  );
}
