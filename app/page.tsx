import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { Button } from "@/components/ui/Button";

export default async function Home() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (user) redirect("/world-map");

  return (
    <div
      className="flex min-h-screen flex-col items-center justify-center gap-8 bg-cover bg-center px-4 text-center"
      style={{
        backgroundImage:
          "linear-gradient(rgba(28,19,12,0.55), rgba(28,19,12,0.85)), url('/assets/map.png')",
      }}
    >
      <div className="flex flex-col items-center gap-4">
        <h1 className="font-pixel text-3xl text-gold drop-shadow-[0_2px_0_rgba(0,0,0,0.6)] sm:text-5xl">
          Wonderhill
        </h1>
        <p className="max-w-md text-balance text-parchment">
          A small village on the edge of a mysterious forest. The old magic is fading — explore,
          quest, and uncover why before it&apos;s gone for good.
        </p>
      </div>
      <div className="flex gap-4">
        <Link href="/register">
          <Button variant="primary">Begin Your Journey</Button>
        </Link>
        <Link href="/login">
          <Button variant="secondary">Sign In</Button>
        </Link>
      </div>
    </div>
  );
}
