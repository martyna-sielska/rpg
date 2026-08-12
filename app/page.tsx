import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { Button } from "@/components/ui/Button";
import { LanguageSwitcher } from "@/components/ui/LanguageSwitcher";
import { getDictionary } from "@/lib/i18n/getDictionary";

export default async function Home() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (user) redirect("/world-map");

  const t = await getDictionary();

  return (
    <div
      className="relative flex min-h-screen flex-col items-center justify-center gap-8 bg-cover bg-center px-4 text-center"
      style={{
        backgroundImage:
          "linear-gradient(rgba(28,19,12,0.55), rgba(28,19,12,0.85)), url('/assets/map.png')",
      }}
    >
      <div className="absolute right-4 top-4">
        <LanguageSwitcher />
      </div>
      <div className="flex flex-col items-center gap-4">
        <h1 className="font-pixel text-3xl text-gold drop-shadow-[0_2px_0_rgba(0,0,0,0.6)] sm:text-5xl">
          {t.landing.title}
        </h1>
        <p className="max-w-md text-balance text-parchment">{t.landing.tagline}</p>
      </div>
      <div className="flex gap-4">
        <Link href="/register">
          <Button variant="primary">{t.landing.beginJourney}</Button>
        </Link>
        <Link href="/login">
          <Button variant="secondary">{t.landing.signIn}</Button>
        </Link>
      </div>
    </div>
  );
}
