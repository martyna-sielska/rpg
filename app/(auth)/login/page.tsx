import type { Metadata } from "next";
import { LoginForm, ClearSessionLink } from "@/components/auth/LoginForm";
import { getDictionary } from "@/lib/i18n/getDictionary";
import { dictionaries } from "@/lib/i18n/dictionaries";
import { getLocale } from "@/lib/i18n/locale";

export async function generateMetadata(): Promise<Metadata> {
  const locale = await getLocale();
  return { title: dictionaries[locale].meta.signIn };
}

export default async function LoginPage() {
  const t = await getDictionary();

  return (
    <div className="flex flex-col gap-4">
      <h2 className="text-center font-pixel text-lg text-parchment">{t.auth.welcomeBack}</h2>
      <LoginForm />
      <ClearSessionLink />
    </div>
  );
}
