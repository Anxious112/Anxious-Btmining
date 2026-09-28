import { color, font, statusColor } from '../../theme/tokens';

// A segmented vertical bar-meter, not a circular gauge -- matches the
// terminal/rig-monitoring theme (think rackmount UPS/PDU load lights)
// instead of the glass-panel radial gauge used elsewhere in this codebase.
const SEGMENTS = 20;
const WARM_PCT = 60;
const CRITICAL_PCT = 80;
const MELTDOWN_PCT = 95;

export function HeatMeter({ heat }: { heat: number }) {
  const pct = Math.max(0, Math.min(100, heat));
  const litSegments = Math.round((pct / 100) * SEGMENTS);
  const activeColor = statusColor(pct, WARM_PCT, CRITICAL_PCT);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
      <div
        style={{
          display: 'flex',
          flexDirection: 'column-reverse',
          gap: 2,
          padding: 4,
          border: `1px solid ${color.border}`,
          borderRadius: 2,
          background: color.panelAlt,
        }}
      >
        {Array.from({ length: SEGMENTS }, (_, i) => {
          const lit = i < litSegments;
          return (
            <div
              key={i}
              style={{
                width: 22,
                height: 5,
                borderRadius: 1,
                background: lit ? activeColor : color.border,
                opacity: lit ? 1 : 0.5,
              }}
            />
          );
        })}
      </div>
      <div style={{ fontFamily: font.mono, fontSize: 11, color: color.textMuted, letterSpacing: '0.05em' }}>
        HEAT
      </div>
      <div style={{ fontFamily: font.mono, fontSize: 18, fontWeight: 700, color: activeColor, fontVariantNumeric: 'tabular-nums' }}>
        {pct.toFixed(0)}%
      </div>
      {pct >= MELTDOWN_PCT && (
        <div style={{ fontFamily: font.mono, fontSize: 10, color: color.bad, letterSpacing: '0.08em' }}>MELTDOWN RISK</div>
      )}
    </div>
  );
}
