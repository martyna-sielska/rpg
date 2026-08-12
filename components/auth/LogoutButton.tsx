"use client";

import { signOut } from "@/lib/actions/auth";
import { Button } from "@/components/ui/Button";
import { useI18n } from "@/lib/i18n/I18nProvider";

export function LogoutButton() {
  const { t } = useI18n();
  return (
    <form action={signOut}>
      <Button type="submit" variant="secondary" className="px-3 py-1.5 text-xs">
        {t.nav.logOut}
      </Button>
    </form>
  );
}
