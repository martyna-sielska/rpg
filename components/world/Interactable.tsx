"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";
import { interactWithObject, type InteractResult } from "@/lib/actions/interactables";
import { InteractOverlay } from "@/components/world/InteractOverlay";
import { useI18n } from "@/lib/i18n/I18nProvider";

// Per-interactable icon overrides, cropped from assets/items2.png (see
// scripts/crop-items2-icons.py). Anything not listed here — the large
// majority of interactables, which are plain "investigate this" story
// beats — falls back to the generic investigation_spot.png icon.
const ICON_OVERRIDES: Record<string, string> = {
  ruins_inscription_1: "ancient_stone_inscription",
  ruins_inscription_2: "ancient_stone_tablet",
  ruins_veil_records: "veil_inscription",
  ruins_resonant_fragment: "ancient_forge_fragment",
  village_three_seals_altar: "ancient_altar",
  castle_old_records: "ancient_archive_document",
  castle_hidden_documents_1: "hidden_archive_book",
  castle_hidden_documents_2: "ancient_archive_document",
  castle_missing_pages: "torn_archive_page",
  castle_antagonist_plan: "torn_archive_page",
  ancient_gate: "locked_ancient_gate",
  mountains_chamber_entrance: "ancient_seal_socket",
  mountains_recover_second_seal: "second_seal",
  volcano_seal_chamber: "ancient_seal_socket",
  volcano_recover_third_seal: "third_seal",
};

export function Interactable({
  id,
  name,
  mapX,
  mapY,
  navigateTo,
}: {
  id: string;
  name: string;
  mapX: number;
  mapY: number;
  /** If set, navigate here once the player closes the overlay after a successful interaction (e.g. a portal/passage). */
  navigateTo?: string;
}) {
  const router = useRouter();
  const { t } = useI18n();
  const [isPending, setIsPending] = useState(false);
  const [result, setResult] = useState<InteractResult | null>(null);
  const [error, setError] = useState<string | null>(null);
  const icon = ICON_OVERRIDES[id] ?? "investigation_spot";

  async function handleClick() {
    setIsPending(true);
    try {
      const res = await interactWithObject(id);
      setResult(res);
    } catch (e) {
      setError(e instanceof Error ? e.message : t.interact.nothingHappens);
    } finally {
      setIsPending(false);
    }
  }

  function handleClose() {
    const shouldNavigate = navigateTo && result && !error;
    setResult(null);
    setError(null);
    if (shouldNavigate) {
      router.push(navigateTo);
    } else {
      router.refresh();
    }
  }

  return (
    <>
      <button
        type="button"
        onClick={handleClick}
        disabled={isPending}
        className="group absolute flex -translate-x-1/2 -translate-y-1/2 flex-col items-center gap-1"
        style={{ left: `${mapX}%`, top: `${mapY}%` }}
      >
        <div className="relative h-12 w-12 drop-shadow-[0_4px_6px_rgba(0,0,0,0.6)] transition group-hover:scale-110">
          <Image src={`/assets/items/${icon}.png`} alt="" fill sizes="48px" unoptimized className="object-contain" />
        </div>
        <div className="pointer-events-none whitespace-nowrap rounded-md border-2 border-wood-dark bg-wood-darkest/90 px-2 py-0.5 text-[10px] font-semibold text-parchment opacity-0 shadow-lg transition group-hover:opacity-100">
          {name}
        </div>
      </button>

      {(result || error) && <InteractOverlay name={name} result={result} error={error} onClose={handleClose} />}
    </>
  );
}
