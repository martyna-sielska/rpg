import type { Metadata } from "next";
import { RegisterForm } from "@/components/auth/RegisterForm";

export const metadata: Metadata = { title: "Create Your Character — Wonderhill" };

export default function RegisterPage() {
  return (
    <div>
      <h2 className="mb-5 text-center font-pixel text-lg text-parchment">Create Your Character</h2>
      <RegisterForm />
    </div>
  );
}
