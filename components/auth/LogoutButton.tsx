"use client";

import { signOut } from "@/lib/actions/auth";
import { Button } from "@/components/ui/Button";

export function LogoutButton() {
  return (
    <form action={signOut}>
      <Button type="submit" variant="secondary" className="px-3 py-1.5 text-xs">
        Log Out
      </Button>
    </form>
  );
}
