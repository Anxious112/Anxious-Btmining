import { useEffect, useRef, useState } from 'react';
import { color, font } from '../../theme/tokens';
import type { SequenceDifficulty } from '../../types';

type Phase = 'watch' | 'input';

// "Firewall Breach" -- watch a flashing sequence of grid cells, then repeat
// it back in order. One wrong cell fails immediately, matching the
// no-second-chances feel of tripping a real intrusion-detection system.
export function SequenceGame({ difficulty, onResult }: { difficulty: SequenceDifficulty; onResult: (success: boolean) => void }) {
  const { gridSize, length, showDelayMs, inputTimeoutMs } = difficulty;
  const cols = Math.round(Math.sqrt(gridSize));

  const sequence = useRef<number[]>(buildSequence(gridSize, length));
  const [phase, setPhase] = useState<Phase>('watch');
  const [activeCell, setActiveCell] = useState<number | null>(null);
  const [progress, setProgress] = useState(0);
  const [msLeft, setMsLeft] = useState(inputTimeoutMs);
  const [flashCell, setFlashCell] = useState<{ index: number; ok: boolean } | null>(null);
  const doneRef = useRef(false);

  const finish = (success: boolean) => {
    if (doneRef.current) return;
    doneRef.current = true;
    onResult(success);
  };

  // Playback phase: flash each cell in the sequence in order, then hand off
  // to input.
  useEffect(() => {
    let cancelled = false;
    let i = 0;

    const step = () => {
      if (cancelled) return;
      if (i >= sequence.current.length) {
        setActiveCell(null);
        setPhase('input');
        return;
      }
      setActiveCell(sequence.current[i]);
      setTimeout(() => {
        if (cancelled) return;
        setActiveCell(null);
        setTimeout(() => {
          i += 1;
          step();
        }, showDelayMs * 0.35);
      }, showDelayMs * 0.65);
    };

    step();
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Input phase countdown.
  useEffect(() => {
    if (phase !== 'input') return;
    const start = performance.now();
    let raf: number;
    const tick = () => {
      const remaining = inputTimeoutMs - (performance.now() - start);
      if (remaining <= 0) {
        setMsLeft(0);
        finish(false);
        return;
      }
      setMsLeft(remaining);
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [phase]);

  function clickCell(index: number) {
    if (phase !== 'input' || doneRef.current) return;

    const expected = sequence.current[progress];
    const ok = index === expected;
    setFlashCell({ index, ok });
    setTimeout(() => setFlashCell(null), 120);

    if (!ok) {
      finish(false);
      return;
    }

    const next = progress + 1;
    setProgress(next);
    if (next >= sequence.current.length) {
      finish(true);
    }
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 16 }}>
      <div style={{ fontFamily: font.mono, fontSize: 12, color: color.textMuted, letterSpacing: '0.05em' }}>
        {phase === 'watch' ? 'MEMORIZE THE SEQUENCE' : `REPEAT IT -- ${(msLeft / 1000).toFixed(1)}s`}
      </div>

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: `repeat(${cols}, 56px)`,
          gap: 8,
        }}
      >
        {Array.from({ length: gridSize }, (_, i) => {
          const isActive = activeCell === i;
          const isFlash = flashCell?.index === i;

          let bg = color.panelAlt;
          let border = color.border;
          if (isActive) {
            bg = color.borderBright;
            border = color.borderBright;
          } else if (isFlash) {
            bg = flashCell!.ok ? color.good : color.bad;
            border = bg;
          }

          return (
            <button
              key={i}
              onClick={() => clickCell(i)}
              disabled={phase !== 'input'}
              style={{
                width: 56,
                height: 56,
                background: bg,
                border: `1px solid ${border}`,
                borderRadius: 2,
                cursor: phase === 'input' ? 'pointer' : 'default',
                transition: 'background 80ms ease, border-color 80ms ease',
              }}
            />
          );
        })}
      </div>

      <div style={{ fontFamily: font.mono, fontSize: 11, color: color.textDim }}>
        {phase === 'input' ? `${progress} / ${sequence.current.length}` : ` `}
      </div>
    </div>
  );
}

function buildSequence(gridSize: number, length: number): number[] {
  const out: number[] = [];
  let last = -1;
  for (let i = 0; i < length; i++) {
    let next = Math.floor(Math.random() * gridSize);
    while (next === last) {
      next = Math.floor(Math.random() * gridSize);
    }
    out.push(next);
    last = next;
  }
  return out;
}
