"use client";

import { useActionState, useState } from "react";
import Link from "next/link";
import { signUp, type AuthFormState } from "@/lib/actions/auth";
import { AvatarPicker } from "@/components/auth/AvatarPicker";
import { SubmitButton } from "@/components/ui/Button";
import { useI18n } from "@/lib/i18n/I18nProvider";
import type { AvatarId } from "@/lib/game/types";

const initialState: AuthFormState = {};

export function RegisterForm() {
  const [state, formAction] = useActionState(signUp, initialState);
  const [avatarId, setAvatarId] = useState<AvatarId>("kael");
  const { t } = useI18n();

  return (
    <form action={formAction} className="flex flex-col gap-4">
      <AvatarPicker value={avatarId} onChange={setAvatarId} />
      <input type="hidden" name="avatar_id" value={avatarId} />

      <label className="flex flex-col gap-1 text-sm">
        <span className="font-semibold text-parchment-dark">{t.auth.usernameLabel}</span>
        <input
          name="username"
          type="text"
          required
          minLength={3}
          maxLength={20}
          placeholder={t.auth.usernamePlaceholder}
          className="rounded-md border-2 border-wood-dark bg-wood-darkest/60 px-3 py-2 text-parchment placeholder:text-parchment-dark/50 focus:border-gold focus:outline-none"
        />
      </label>

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
          minLength={6}
          placeholder={t.auth.passwordHintPlaceholder}
          className="rounded-md border-2 border-wood-dark bg-wood-darkest/60 px-3 py-2 text-parchment placeholder:text-parchment-dark/50 focus:border-gold focus:outline-none"
        />
      </label>

      {state?.error && (
        <p className="rounded-md border-2 border-hp bg-hp/20 px-3 py-2 text-sm text-parchment">
          {state.error}
        </p>
      )}

      <SubmitButton pendingLabel={t.auth.creatingCharacter}>{t.auth.beginJourney}</SubmitButton>

      <p className="text-center text-sm text-parchment-dark">
        {t.auth.alreadyHaveAccount}{" "}
        <Link href="/login" className="font-semibold text-gold hover:underline">
          {t.auth.signInLink}
        </Link>
      </p>
    </form>
  );
}
