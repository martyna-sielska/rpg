"use client";

import { useActionState } from "react";
import Link from "next/link";
import { signIn, forceClearSession, type AuthFormState } from "@/lib/actions/auth";
import { SubmitButton } from "@/components/ui/Button";

const initialState: AuthFormState = {};

export function LoginForm() {
  const [state, formAction] = useActionState(signIn, initialState);

  return (
    <form action={formAction} className="flex flex-col gap-4">
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
          placeholder="••••••••"
          className="rounded-md border-2 border-wood-dark bg-wood-darkest/60 px-3 py-2 text-parchment placeholder:text-parchment-dark/50 focus:border-gold focus:outline-none"
        />
      </label>

      {state?.error && (
        <p className="rounded-md border-2 border-hp bg-hp/20 px-3 py-2 text-sm text-parchment">
          {state.error}
        </p>
      )}

      <SubmitButton pendingLabel="Signing in...">Sign In</SubmitButton>

      <p className="text-center text-sm text-parchment-dark">
        Don&apos;t have an account yet?{" "}
        <Link href="/register" className="font-semibold text-gold hover:underline">
          Create a character
        </Link>
      </p>
    </form>
  );
}

export function ClearSessionLink() {
  return (
    <form action={forceClearSession} className="text-center">
      <button type="submit" className="text-xs text-parchment-dark/70 underline hover:text-parchment-dark">
        Stuck in a redirect loop? Clear your session
      </button>
    </form>
  );
}
