"use client";

import { Button } from "@/components/ui/Button";
import { useI18n } from "@/lib/i18n/I18nProvider";

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
  const { t } = useI18n();
  return (
    <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
      <Button variant="primary" onClick={onAttack} disabled={disabled || !attackReady}>
        ⚔️ {t.combat.attack}
      </Button>
      <Button variant="primary" onClick={onSkill} disabled={disabled || !skillReady}>
        ✨ {t.combat.skill}
      </Button>
      <Button variant="secondary" onClick={onDodge} disabled={disabled || !dodgeReady}>
        💨 {t.combat.dodge}
      </Button>
      <Button variant="secondary" onClick={onPotion} disabled={disabled || potionCount < 1}>
        🧪 {t.combat.potion(potionCount)}
      </Button>
    </div>
  );
}
