"use client";

import { useState, useTransition } from "react";
import { Modal } from "@/components/ui/Modal";
import { AvatarPicker } from "@/components/auth/AvatarPicker";
import { Button } from "@/components/ui/Button";
import { updateAvatar } from "@/lib/actions/player";
import type { AvatarId } from "@/lib/game/types";

export function ChangeAvatarModal({
  open,
  onClose,
  currentAvatarId,
}: {
  open: boolean;
  onClose: () => void;
  currentAvatarId: AvatarId;
}) {
  const [avatarId, setAvatarId] = useState<AvatarId>(currentAvatarId);
  const [error, setError] = useState<string>();
  const [isPending, startTransition] = useTransition();

  function handleSave() {
    setError(undefined);
    startTransition(async () => {
      const result = await updateAvatar(avatarId);
      if (result.error) {
        setError(result.error);
      } else {
        onClose();
      }
    });
  }

  return (
    <Modal open={open} onClose={onClose} title="Change Hero">
      <div className="flex flex-col gap-4">
        <AvatarPicker value={avatarId} onChange={setAvatarId} />
        {error && (
          <p className="rounded-md border-2 border-hp bg-hp/20 px-3 py-2 text-sm text-parchment">
            {error}
          </p>
        )}
        <Button onClick={handleSave} disabled={isPending}>
          {isPending ? "Saving..." : "Save"}
        </Button>
      </div>
    </Modal>
  );
}
