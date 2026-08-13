"use client";

import Image from "next/image";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";

type NavLink = { href: string; label: string; icon: string };

/**
 * The map icon always just navigates to the map. Every other icon acts as a
 * toggle: clicking the icon for the section you're already viewing sends you
 * back to wherever you came from (e.g. quests -> ancient ruins) instead of
 * re-navigating to itself.
 */
export function HudNavLinks({ links }: { links: readonly NavLink[] }) {
  const pathname = usePathname();
  const router = useRouter();

  return (
    <>
      {links.map((link) => {
        const isCurrentAndToggleable = link.href !== "/world-map" && pathname === link.href;

        return (
          <Link
            key={link.href}
            href={link.href}
            title={link.label}
            aria-label={link.label}
            className="relative flex h-10 w-10 items-center justify-center rounded-lg transition hover:scale-110 hover:brightness-110"
            onClick={(event) => {
              if (isCurrentAndToggleable) {
                event.preventDefault();
                router.back();
              }
            }}
          >
            <Image src={link.icon} alt={link.label} fill sizes="40px" unoptimized className="object-contain" />
          </Link>
        );
      })}
    </>
  );
}
