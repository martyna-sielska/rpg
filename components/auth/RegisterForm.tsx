"use client";

import { useActionState, useState } from "react";
import Link from "next/link";
import { signUp, type AuthFormState } from "@/lib/actions/auth";
import { AvatarPicker } from "@/components/auth/AvatarPicker";
import { SubmitButton } from "@/components/ui/Button";
import type { AvatarId } from "@/lib/game/types";

const initialState: AuthFormState = {};

export function RegisterForm() {
  const [state, formAction] = useActionState(signUp, initialState);
  const [avatarId, setAvatarId] = useState<AvatarId>("kael");

  return (
    <form action={formAction} className="flex flex-col gap-4">
      <AvatarPicker value={avatarId} onChange={setAvatarId} />
      <input type="hidden" name="avatar_id" value={avatarId} />

      <label className="flex flex-col gap-1 text-sm">
        <span className="font-semibold text-parchment-dark">Username</span>
        <input
          name="username"
          type="text"
          required
          minLength={3}
          maxLength={20}
          placeholder="e.g. Wren"
          className="rounded-md border-2 border-wood-dark bg-wood-darkest/60 px-3 py-2 text-parchment placeholder:text-parchment-dark/50 focus:border-gold focus:outline-none"
        />
      </label>

      <label className="flex flex-col gap-1 text-sm">
        <span className="font-semibold text-parchment-dark">Email</span>
        <input
          name="email"
          type="email"
          required
          placeholder="you@example.com"
          className="rounded-md border-2 border-wood-dark bg-wood-darkest/60 px-3 py-2 text-parchment placeholder:text-parchment-dark/50 focus:border-gold focus:outline-none"
        />
      </label>

      <label className="flex flex-col gap-1 text-sm">
        <span className="font-semibold text-parchment-dark">Password</span>
        <input
          name="password"
          type="password"
          required
          minLength={6}
          placeholder="min. 6 characters"
          className="rounded-md border-2 border-wood-dark bg-wood-darkest/60 px-3 py-2 text-parchment placeholder:text-parchment-dark/50 focus:border-gold focus:outline-none"
        />
      </label>

      {state?.error && (
        <p className="rounded-md border-2 border-hp bg-hp/20 px-3 py-2 text-sm text-parchment">
          {state.error}
        </p>
      )}

      <SubmitButton pendingLabel="Creating character...">Begin Your Journey</SubmitButton>

      <p className="text-center text-sm text-parchment-dark">
        Already have an account?{" "}
        <Link href="/login" className="font-semibold text-gold hover:underline">
          Sign in
        </Link>
      </p>
    </form>
  );
}
