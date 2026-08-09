import type { Metadata } from "next";
import { LoginForm, ClearSessionLink } from "@/components/auth/LoginForm";

export const metadata: Metadata = { title: "Sign In — Wonderhill" };

export default function LoginPage() {
  return (
    <div className="flex flex-col gap-4">
      <h2 className="text-center font-pixel text-lg text-parchment">Welcome Back</h2>
      <LoginForm />
      <ClearSessionLink />
    </div>
  );
}
