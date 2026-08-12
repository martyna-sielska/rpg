"use client";

import { useActionState } from "react";
import Link from "next/link";
import { signIn, forceClearSession, type AuthFormState } from "@/lib/actions/auth";
import { SubmitButton } from "@/components/ui/Button";
import { useI18n } from "@/lib/i18n/I18nProvider";

const initialState: AuthFormState = {};

export function LoginForm() {
  const [state, formAction] = useActionState(signIn, initialState);
  const { t } = useI18n();

  return (
    <form action={formAction} className="flex flex-col gap-4">
      <label className="flex flex-col gap-1 text-sm">
        <span className="font-semibold text-parchment-dark">{t.auth.emailLabel}</span>
        <input
          name="email"
          type="email"
          required
          placeholder={t.auth.emailPlaceholder}
          className="rounded-md border-2 border-wood-dark bg-wood-darkest/60 px-3 py-2 text-parchment placeholder:text-parchment-dark/50 focus:border-gold focus:outline-none"
        />
      </label>

      <label className="flex flex-col gap-1 text-sm">
        <span className="font-semibold text-parchment-dark">{t.auth.passwordLabel}</span>
        <input
          name="password"
          type="password"
          required
          placeholder={t.auth.passwordPlaceholder}
          className="rounded-md border-2 border-wood-dark bg-wood-darkest/60 px-3 py-2 text-parchment placeholder:text-parchment-dark/50 focus:border-gold focus:outline-none"
        />
      </label>

      {state?.error && (
        <p className="rounded-md border-2 border-hp bg-hp/20 px-3 py-2 text-sm text-parchment">
          {state.error}
        </p>
      )}

      <SubmitButton pendingLabel={t.auth.signingIn}>{t.auth.signIn}</SubmitButton>

      <p className="text-center text-sm text-parchment-dark">
        {t.auth.dontHaveAccount}{" "}
        <Link href="/register" className="font-semibold text-gold hover:underline">
          {t.auth.createCharacterLink}
        </Link>
      </p>
    </form>
  );
}

export function ClearSessionLink() {
  const { t } = useI18n();
  return (
    <form action={forceClearSession} className="text-center">
      <button type="submit" className="text-xs text-parchment-dark/70 underline hover:text-parchment-dark">
        {t.auth.stuckRedirect}
      </button>
    </form>
  );
}
