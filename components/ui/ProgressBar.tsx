const COLORS = {
  xp: "bg-xp",
  hp: "bg-hp",
  gold: "bg-gold",
} as const;

export function ProgressBar({
  value,
  max,
  color = "xp",
  label,
  showNumbers = true,
}: {
  value: number;
  max: number;
  color?: keyof typeof COLORS;
  label?: string;
  showNumbers?: boolean;
}) {
  const percent = max > 0 ? Math.min(100, Math.max(0, (value / max) * 100)) : 0;

  return (
    <div className="w-full">
      {(label || showNumbers) && (
        <div className="mb-1 flex items-center justify-between text-[11px] font-semibold text-parchment-dark">
          {label && <span>{label}</span>}
          {showNumbers && (
            <span>
              {value} / {max}
            </span>
          )}
        </div>
      )}
      <div className="h-3 w-full overflow-hidden rounded-full border-2 border-wood-darkest bg-wood-darkest/80">
        <div
          className={`h-full rounded-full transition-all duration-500 ease-out ${COLORS[color]}`}
          style={{ width: `${percent}%` }}
        />
      </div>
    </div>
  );
}
