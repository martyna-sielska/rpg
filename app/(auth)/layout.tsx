import type { ReactNode } from "react";
import { LanguageSwitcher } from "@/components/ui/LanguageSwitcher";

export default function AuthLayout({ children }: { children: ReactNode }) {
  return (
    <div
      className="relative flex min-h-screen flex-col items-center justify-center gap-6 bg-cover bg-center px-4 py-10"
      style={{
        backgroundImage:
          "linear-gradient(rgba(28,19,12,0.75), rgba(28,19,12,0.9)), url('/assets/map.png')",
      }}
    >
      <div className="absolute right-4 top-4">
        <LanguageSwitcher />
      </div>
      <h1 className="font-pixel text-2xl text-gold drop-shadow-[0_2px_0_rgba(0,0,0,0.6)] sm:text-3xl">
        Magaly
      </h1>
      <div className="w-full max-w-md rounded-xl border-4 border-wood-dark bg-wood/95 p-6 shadow-[inset_0_1px_0_rgba(255,255,255,0.08),0_12px_32px_rgba(0,0,0,0.5)]">
        {children}
      </div>
    </div>
  );
}
