"use client";

import { Button } from "@/components/ui/Button";

export function ActionBar({
  onAttack,
  onSkill,
  onDodge,
  onPotion,
  attackReady,
  skillReady,
  dodgeReady,
  potionCount,
  disabled,
}: {
  onAttack: () => void;
  onSkill: () => void;
  onDodge: () => void;
  onPotion: () => void;
  attackReady: boolean;
  skillReady: boolean;
  dodgeReady: boolean;
  potionCount: number;
  disabled: boolean;
}) {
  return (
    <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
      <Button variant="primary" onClick={onAttack} disabled={disabled || !attackReady}>
        ⚔️ Attack
      </Button>
      <Button variant="primary" onClick={onSkill} disabled={disabled || !skillReady}>
        ✨ Skill
      </Button>
      <Button variant="secondary" onClick={onDodge} disabled={disabled || !dodgeReady}>
        💨 Dodge
      </Button>
      <Button variant="secondary" onClick={onPotion} disabled={disabled || potionCount < 1}>
        🧪 Potion ({potionCount})
      </Button>
    </div>
  );
}
