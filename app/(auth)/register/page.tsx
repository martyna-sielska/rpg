import type { Metadata } from "next";
import { RegisterForm } from "@/components/auth/RegisterForm";
import { getDictionary } from "@/lib/i18n/getDictionary";
import { dictionaries } from "@/lib/i18n/dictionaries";
import { getLocale } from "@/lib/i18n/locale";

export async function generateMetadata(): Promise<Metadata> {
  const locale = await getLocale();
  return { title: dictionaries[locale].meta.register };
}

export default async function RegisterPage() {
  const t = await getDictionary();

  return (
    <div>
      <h2 className="mb-5 text-center font-pixel text-lg text-parchment">{t.auth.createYourCharacter}</h2>
      <RegisterForm />
    </div>
  );
}
