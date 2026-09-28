import { useEffect, useRef, useState } from 'react';
import { color, font, scanlines } from '../../theme/tokens';
import type { MinigameRequest, SequenceDifficulty, SweepDifficulty } from '../../types';
import { SweepGame } from './SweepGame';
import { SequenceGame } from './SequenceGame';

const TITLES: Record<MinigameRequest['kind'], string> = {
  extinguish: 'Coolant Purge',
  install: 'Socket Alignment',
  hack: 'Firewall Breach',
};

const INSTRUCTIONS: Record<MinigameRequest['kind'], string> = {
  extinguish: 'Strike the marker inside the zone to vent pressure before time runs out.',
  install: 'Strike the marker inside the zone to seat the card without cracking a pin.',
  hack: 'Watch the sequence, then repeat it exactly. One wrong node ends the attempt.',
};

export function MinigameOverlay({ request, onResult }: { request: MinigameRequest; onResult: (success: boolean) => void }) {
  const [result, setResult] = useState<'success' | 'failure' | null>(null);
  const reportedRef = useRef(false);

  function handleResult(success: boolean) {
    if (reportedRef.current) return;
    reportedRef.current = true;
    setResult(success ? 'success' : 'failure');
    setTimeout(() => onResult(success), 700);
  }

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') handleResult(false);
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        background: 'rgba(0,0,0,0.72)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 50,
      }}
    >
      <div
        style={{
          ...scanlines,
          width: 440,
          maxWidth: '90vw',
          border: `1px solid ${result === 'success' ? color.good : result === 'failure' ? color.bad : color.borderBright}`,
          borderRadius: 4,
          background: color.bg,
          boxShadow: '0 24px 64px rgba(0,0,0,0.7)',
          padding: 24,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: 16,
        }}
      >
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontFamily: font.display, fontSize: 16, fontWeight: 700, letterSpacing: '0.06em', textTransform: 'uppercase' }}>
            {TITLES[request.kind]}
          </div>
          <div style={{ fontFamily: font.mono, fontSize: 11, color: color.textMuted, marginTop: 6, maxWidth: 340 }}>
            {INSTRUCTIONS[request.kind]}
          </div>
        </div>

        {result ? (
          <div
            style={{
              fontFamily: font.display,
              fontSize: 20,
              fontWeight: 700,
              letterSpacing: '0.08em',
              color: result === 'success' ? color.good : color.bad,
              padding: '24px 0',
            }}
          >
            {result === 'success' ? 'SUCCESS' : 'FAILURE'}
          </div>
        ) : request.kind === 'hack' ? (
          <SequenceGame difficulty={request.difficulty as SequenceDifficulty} onResult={handleResult} />
        ) : (
          <SweepGame difficulty={request.difficulty as SweepDifficulty} onResult={handleResult} />
        )}
      </div>
    </div>
  );
}
