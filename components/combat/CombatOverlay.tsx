"use client";

import { useCallback, useEffect, useRef, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Panel } from "@/components/ui/Panel";
import { Button } from "@/components/ui/Button";
import { LevelUpModal } from "@/components/level-up/LevelUpModal";
import { CombatSprite } from "@/components/combat/CombatSprite";
import { ActionBar } from "@/components/combat/ActionBar";
import { DamageNumber, type FloatingText } from "@/components/combat/DamageNumber";
import { COMBAT_TIMING, clampHp, pickMonsterAttack, playerAttackDamage, playerSkillDamage } from "@/lib/game/combat";
import { resolveCombat } from "@/lib/actions/combat";
import { useHealingPotion } from "@/lib/actions/inventory";
import { getCombatSizeClasses, getMonsterIdleAnimationClass, getMonsterScale } from "@/lib/game/monsterIdle";
import { useI18n } from "@/lib/i18n/I18nProvider";
import type { AttackPattern } from "@/lib/game/database.types";
import type { Monster, Player } from "@/lib/game/types";

type Phase = "fighting" | "resolving" | "victory" | "defeat";

let floatingTextId = 0;

export function CombatOverlay({
  monster,
  player,
  avatarImage,
  weaponBonus,
  initialPotionCount,
  onClose,
}: {
  monster: Monster;
  player: Player;
  avatarImage: string;
  weaponBonus: number;
  initialPotionCount: number;
  onClose: () => void;
}) {
  const router = useRouter();
  const { t } = useI18n();
  const [isPending, startTransition] = useTransition();

  const [playerHp, setPlayerHp] = useState(player.hp);
  const [monsterHp, setMonsterHp] = useState(monster.max_hp);
  const [phase, setPhase] = useState<Phase>("fighting");
  const [log, setLog] = useState<string[]>([t.combat.wildAppears(monster.name)]);
  const [telegraph, setTelegraph] = useState<AttackPattern | null>(null);
  const [potionCount, setPotionCount] = useState(initialPotionCount);
  const [floaters, setFloaters] = useState<FloatingText[]>([]);
  const [playerHitKey, setPlayerHitKey] = useState(0);
  const [monsterHitKey, setMonsterHitKey] = useState(0);
  const [rewards, setRewards] = useState<{ gold: number; leveledUp: boolean; newLevel: number; loot: { item_id: string; quantity: number }[] } | null>(null);

  const dodgedRef = useRef(false);
  const timers = useRef<ReturnType<typeof setTimeout>[]>([]);
  const [attackReadyAt, setAttackReadyAt] = useState(0);
  const [skillReadyAt, setSkillReadyAt] = useState(0);
  const [dodgeReadyAt, setDodgeReadyAt] = useState(0);
  const [now, setNow] = useState(Date.now());

  const addFloater = useCallback((f: Omit<FloatingText, "id">) => {
    const id = ++floatingTextId;
    setFloaters((prev) => [...prev, { ...f, id }]);
    const timeoutId = setTimeout(() => setFloaters((prev) => prev.filter((x) => x.id !== id)), 1100);
    timers.current.push(timeoutId);
  }, []);

  // tick for cooldown countdown display
  useEffect(() => {
    const i = setInterval(() => setNow(Date.now()), 100);
    return () => clearInterval(i);
  }, []);

  // Monster AI loop: pause -> telegraph an attack -> resolve -> repeat.
  useEffect(() => {
    if (phase !== "fighting") return;
    let cancelled = false;

    function loop() {
      const pauseTimer = setTimeout(() => {
        if (cancelled) return;
        const pattern = pickMonsterAttack(monster);
        dodgedRef.current = false;
        setTelegraph(pattern);

        const resolveTimer = setTimeout(() => {
          if (cancelled) return;
          setTelegraph(null);
          if (dodgedRef.current) {
            addFloater({ text: t.combat.dodgedFloater, target: "player", kind: "miss" });
            setLog((l) => [...l, t.combat.youDodge()]);
          } else {
            const dmg = Math.max(1, pattern.damage - Math.floor(player.vitality / 4));
            setPlayerHp((hp) => {
              const next = clampHp(hp - dmg, player.max_hp);
              if (next <= 0) setPhase("defeat");
              return next;
            });
            setPlayerHitKey((k) => k + 1);
            addFloater({ text: `-${dmg}`, target: "player", kind: "damage" });
            setLog((l) => [...l, t.combat.monsterHits(monster.name, pattern.name, dmg)]);
          }
          loop();
        }, pattern.telegraph_ms);
        timers.current.push(resolveTimer);
      }, COMBAT_TIMING.monsterActionPauseMs);
      timers.current.push(pauseTimer);
    }

    loop();
    return () => {
      cancelled = true;
      timers.current.forEach(clearTimeout);
      timers.current = [];
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [phase]);

  useEffect(() => {
    return () => {
      timers.current.forEach(clearTimeout);
    };
  }, []);

  const resolvedRef = useRef(false);

  function finishCombat(outcome: "victory" | "fled", finalHp: number) {
    if (resolvedRef.current) return;
    resolvedRef.current = true;
    setPhase("resolving");
    startTransition(async () => {
      try {
        const result = await resolveCombat(monster.id, outcome, finalHp);
        if (outcome === "victory") {
          setRewards({ gold: result.newGold - player.gold, leveledUp: result.leveledUp, newLevel: result.newLevel, loot: result.loot });
          setPhase("victory");
        } else {
          setPhase("defeat");
        }
      } catch {
        setPhase(outcome === "victory" ? "victory" : "defeat");
      }
    });
  }

  useEffect(() => {
    if (phase === "fighting" && monsterHp <= 0) {
      finishCombat("victory", playerHp);
    } else if (phase === "defeat") {
      finishCombat("fled", 1);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [monsterHp, phase]);

  function handleAttack() {
    if (phase !== "fighting" || now < attackReadyAt) return;
    const dmg = playerAttackDamage(player, weaponBonus);
    setMonsterHp((hp) => clampHp(hp - dmg, monster.max_hp));
    setMonsterHitKey((k) => k + 1);
    addFloater({ text: `-${dmg}`, target: "monster", kind: "damage" });
    setLog((l) => [...l, t.combat.youStrike(monster.name, dmg)]);
    setAttackReadyAt(Date.now() + COMBAT_TIMING.attackCooldownMs);
  }

  function handleSkill() {
    if (phase !== "fighting" || now < skillReadyAt) return;
    const dmg = playerSkillDamage(player, weaponBonus);
    setMonsterHp((hp) => clampHp(hp - dmg, monster.max_hp));
    setMonsterHitKey((k) => k + 1);
    addFloater({ text: `-${dmg}!`, target: "monster", kind: "damage" });
    setLog((l) => [...l, t.combat.skillLands(dmg)]);
    setSkillReadyAt(Date.now() + COMBAT_TIMING.skillCooldownMs);
  }

  function handleDodge() {
    if (phase !== "fighting" || now < dodgeReadyAt) return;
    dodgedRef.current = true;
    setDodgeReadyAt(Date.now() + COMBAT_TIMING.dodgeCooldownMs);
  }

  function handlePotion() {
    if (phase !== "fighting" || potionCount < 1 || isPending) return;
    startTransition(async () => {
      try {
        const { healed } = await useHealingPotion();
        setPotionCount((c) => c - 1);
        setPlayerHp((hp) => clampHp(hp + healed, player.max_hp));
        addFloater({ text: `+${healed}`, target: "player", kind: "heal" });
        setLog((l) => [...l, t.combat.drinkPotion(healed)]);
      } catch (e) {
        setLog((l) => [...l, e instanceof Error ? e.message : t.combat.potionFailed]);
      }
    });
  }

  function handleDone() {
    router.refresh();
    onClose();
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4">
      <div className="w-full max-w-2xl">
        <Panel className="p-5">
          {phase === "victory" || phase === "defeat" ? (
            <div className="flex flex-col items-center gap-3 text-center">
              <p className="font-pixel text-lg text-gold">{phase === "victory" ? t.combat.victory : t.combat.defeat}</p>
              {phase === "victory" && rewards && (
                <div className="text-sm text-parchment">
                  <p>{t.combat.goldGained(rewards.gold)}</p>
                  {rewards.loot.length > 0 && (
                    <p>
                      {t.combat.lootLabel}{" "}
                      {rewards.loot.map((l) => `${l.quantity}× ${l.item_id.replace(/_/g, " ")}`).join(", ")}
                    </p>
                  )}
                </div>
              )}
              {phase === "defeat" && (
                <p className="text-sm text-parchment-dark">{t.combat.defeatMessage}</p>
              )}
              <Button onClick={handleDone} disabled={isPending}>
                {t.common.continue}
              </Button>
            </div>
          ) : (
            <>
              <div className="relative flex items-start justify-between gap-4 px-2 pb-4">
                <div className="relative">
                  <CombatSprite
                    name={player.username}
                    image={avatarImage}
                    hp={playerHp}
                    maxHp={player.max_hp}
                    hitKey={playerHitKey}
                    telegraphing={false}
                    defeated={false}
                    align="left"
                  />
                  {floaters.filter((f) => f.target === "player").map((f) => (
                    <DamageNumber key={f.id} {...f} />
                  ))}
                </div>
                <div className="relative">
                  <CombatSprite
                    name={monster.name}
                    image={monster.sprite_image}
                    hp={monsterHp}
                    maxHp={monster.max_hp}
                    hitKey={monsterHitKey}
                    telegraphing={telegraph != null}
                    defeated={monsterHp <= 0}
                    align="right"
                    sizeClassName={getCombatSizeClasses(getMonsterScale(monster.id, monster.tier))}
                    idleAnimationClass={getMonsterIdleAnimationClass(monster.id, monster.tier)}
                  />
                  {floaters.filter((f) => f.target === "monster").map((f) => (
                    <DamageNumber key={f.id} {...f} />
                  ))}
                </div>
              </div>

              <div className="mb-3 h-16 overflow-y-auto rounded-md border-2 border-wood-dark bg-wood-darkest/50 p-2 text-xs text-parchment-dark">
                {log.slice(-4).map((entry, i) => (
                  <p key={i}>{entry}</p>
                ))}
                {telegraph && <p className="font-semibold text-gold">{t.combat.windUp(monster.name, telegraph.name)}</p>}
              </div>

              <ActionBar
                onAttack={handleAttack}
                onSkill={handleSkill}
                onDodge={handleDodge}
                onPotion={handlePotion}
                attackReady={now >= attackReadyAt}
                skillReady={now >= skillReadyAt}
                dodgeReady={now >= dodgeReadyAt}
                potionCount={potionCount}
                disabled={phase !== "fighting"}
              />
            </>
          )}
        </Panel>
      </div>

      {rewards?.leveledUp && <LevelUpModal level={rewards.newLevel} onClose={() => setRewards((r) => (r ? { ...r, leveledUp: false } : r))} />}
    </div>
  );
}
