import { useEffect, useRef, useState } from 'react';
import { color, font } from '../../theme/tokens';
import type { SweepDifficulty } from '../../types';

// Shared "hit the marker inside the moving zone" engine behind both Coolant
// Purge (fire, linear) and Socket Alignment (GPU install, radial) -- same
// timing mechanic, two different tracks, so the two features play alike
// under the hood but read as distinct minigames on screen.
export function SweepGame({ difficulty, onResult }: { difficulty: SweepDifficulty; onResult: (success: boolean) => void }) {
  const { variant, zoneWidthPct, speedMs, requiredHits, maxMisses, timeLimitMs } = difficulty;

  const startRef = useRef(performance.now());
  const [pos, setPos] = useState(0); // 0-100 along the track
  const [zoneStart, setZoneStart] = useState(() => randomZoneStart(zoneWidthPct));
  const [hits, setHits] = useState(0);
  const [misses, setMisses] = useState(0);
  const [flash, setFlash] = useState<'hit' | 'miss' | null>(null);
  const [msLeft, setMsLeft] = useState(timeLimitMs);
  const doneRef = useRef(false);
  const flashTimeout = useRef<ReturnType<typeof setTimeout>>();

  const finish = (success: boolean) => {
    if (doneRef.current) return;
    doneRef.current = true;
    onResult(success);
  };

  useEffect(() => {
    let raf: number;
    const tick = () => {
      const elapsed = performance.now() - startRef.current;
      const remaining = timeLimitMs - elapsed;
      if (remaining <= 0) {
        setMsLeft(0);
        finish(false);
        return;
      }
      setMsLeft(remaining);

      const cycle = speedMs * 2;
      const phase = elapsed % cycle;
      const p = phase <= speedMs ? (phase / speedMs) * 100 : (1 - (phase - speedMs) / speedMs) * 100;
      setPos(p);

      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.code === 'Space') {
        e.preventDefault();
        strike();
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [zoneStart]);

  function strike() {
    if (doneRef.current) return;

    const elapsed = performance.now() - startRef.current;
    const cycle = speedMs * 2;
    const phase = elapsed % cycle;
    const current = phase <= speedMs ? (phase / speedMs) * 100 : (1 - (phase - speedMs) / speedMs) * 100;

    const hit = current >= zoneStart && current <= zoneStart + zoneWidthPct;
    clearTimeout(flashTimeout.current);
    setFlash(hit ? 'hit' : 'miss');
    flashTimeout.current = setTimeout(() => setFlash(null), 150);

    if (hit) {
      const nextHits = hits + 1;
      setHits(nextHits);
      if (nextHits >= requiredHits) {
        finish(true);
        return;
      }
    } else {
      const nextMisses = misses + 1;
      setMisses(nextMisses);
      if (nextMisses > maxMisses) {
        finish(false);
        return;
      }
    }
    setZoneStart(randomZoneStart(zoneWidthPct));
  }

  const flashColor = flash === 'hit' ? color.good : flash === 'miss' ? color.bad : color.text;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 18 }}>
      {variant === 'linear' ? (
        <LinearTrack pos={pos} zoneStart={zoneStart} zoneWidthPct={zoneWidthPct} flash={flash} />
      ) : (
        <RadialTrack pos={pos} zoneStart={zoneStart} zoneWidthPct={zoneWidthPct} flash={flash} />
      )}

      <div style={{ display: 'flex', gap: 24, fontFamily: font.mono, fontSize: 12, color: color.textMuted }}>
        <span>
          HITS <b style={{ color: color.good }}>{hits}</b>/{requiredHits}
        </span>
        <span>
          MISSES <b style={{ color: color.bad }}>{misses}</b>/{maxMisses}
        </span>
        <span>TIME {(msLeft / 1000).toFixed(1)}s</span>
      </div>

      <button
        onClick={strike}
        style={{
          fontFamily: font.display,
          fontSize: 13,
          fontWeight: 700,
          letterSpacing: '0.08em',
          textTransform: 'uppercase',
          background: flashColor,
          color: color.bg,
          border: 'none',
          borderRadius: 2,
          padding: '12px 40px',
          cursor: 'pointer',
        }}
      >
        Strike [Space]
      </button>
    </div>
  );
}

function randomZoneStart(zoneWidthPct: number): number {
  return Math.random() * (100 - zoneWidthPct);
}

function LinearTrack({
  pos,
  zoneStart,
  zoneWidthPct,
  flash,
}: {
  pos: number;
  zoneStart: number;
  zoneWidthPct: number;
  flash: 'hit' | 'miss' | null;
}) {
  return (
    <div
      style={{
        position: 'relative',
        width: 340,
        height: 28,
        background: color.panelAlt,
        border: `1px solid ${flash === 'hit' ? color.good : flash === 'miss' ? color.bad : color.border}`,
        borderRadius: 2,
      }}
    >
      <div
        style={{
          position: 'absolute',
          top: 0,
          bottom: 0,
          left: `${zoneStart}%`,
          width: `${zoneWidthPct}%`,
          background: 'rgba(255,255,255,0.15)',
          borderLeft: `1px solid ${color.borderBright}`,
          borderRight: `1px solid ${color.borderBright}`,
        }}
      />
      <div
        style={{
          position: 'absolute',
          top: -4,
          bottom: -4,
          left: `${pos}%`,
          width: 2,
          background: color.borderBright,
          transform: 'translateX(-1px)',
        }}
      />
    </div>
  );
}

function RadialTrack({
  pos,
  zoneStart,
  zoneWidthPct,
  flash,
}: {
  pos: number;
  zoneStart: number;
  zoneWidthPct: number;
  flash: 'hit' | 'miss' | null;
}) {
  const size = 220;
  const r = 90;
  const cx = size / 2;
  const cy = size / 2;

  const toXY = (pct: number) => {
    const angle = (pct / 100) * 360 - 90;
    const rad = (angle * Math.PI) / 180;
    return { x: cx + r * Math.cos(rad), y: cy + r * Math.sin(rad) };
  };

  const markerXY = toXY(pos);
  const ringColor = flash === 'hit' ? color.good : flash === 'miss' ? color.bad : color.border;

  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      <circle cx={cx} cy={cy} r={r} fill="none" stroke={ringColor} strokeWidth={2} />
      <path
        d={arcPath(cx, cy, r, zoneStart, zoneStart + zoneWidthPct)}
        fill="none"
        stroke={color.borderBright}
        strokeWidth={6}
        strokeLinecap="round"
      />
      <circle cx={markerXY.x} cy={markerXY.y} r={5} fill={color.borderBright} />
      <circle cx={cx} cy={cy} r={4} fill={color.textDim} />
    </svg>
  );
}

function arcPath(cx: number, cy: number, r: number, fromPct: number, toPct: number): string {
  const toXY = (pct: number) => {
    const angle = (pct / 100) * 360 - 90;
    const rad = (angle * Math.PI) / 180;
    return { x: cx + r * Math.cos(rad), y: cy + r * Math.sin(rad) };
  };
  const start = toXY(fromPct);
  const end = toXY(toPct);
  const largeArc = toPct - fromPct > 50 ? 1 : 0;
  return `M ${start.x} ${start.y} A ${r} ${r} 0 ${largeArc} 1 ${end.x} ${end.y}`;
}
