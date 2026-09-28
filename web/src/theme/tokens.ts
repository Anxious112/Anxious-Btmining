// Deliberately NOT the black-glass/soft-glow look used elsewhere in this
// codebase's other redesigns -- this is its own identity: a flat, hard-edged
// rig-monitoring/terminal aesthetic (think GPU monitoring software crossed
// with an SSH session), so a Bitcoin mining product reads as its own thing
// rather than a reskin of ox_lib.
import type { CSSProperties } from 'react';

export const color = {
  bg: '#050505',
  panel: '#0d0d0d',
  panelAlt: '#111111',
  border: '#2a2a2a',
  borderBright: '#ffffff',
  text: '#f2f2f2',
  textMuted: '#7a7a7a',
  textDim: '#4a4a4a',

  // The only non-monochrome colors in the whole UI -- reserved strictly for
  // rig health/status, nothing decorative ever uses these.
  good: '#4ade80',
  warn: '#fbbf24',
  bad: '#f87171',
};

export const font = {
  mono: '"JetBrains Mono", ui-monospace, "SFMono-Regular", monospace',
  display: '"Chakra Petch", "JetBrains Mono", sans-serif',
};

// A thin-bordered, sharp-cornered panel with a terminal-window title bar --
// the base building block every screen composes from.
export const panel: CSSProperties = {
  background: color.panel,
  border: `1px solid ${color.border}`,
  borderRadius: 3,
};

export const panelHeader: CSSProperties = {
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'space-between',
  padding: '8px 12px',
  borderBottom: `1px solid ${color.border}`,
  fontFamily: font.display,
  fontSize: 11,
  fontWeight: 600,
  letterSpacing: '0.08em',
  textTransform: 'uppercase',
  color: color.textMuted,
};

export const monoValue: CSSProperties = {
  fontFamily: font.mono,
  fontVariantNumeric: 'tabular-nums',
  color: color.text,
};

export const button: CSSProperties = {
  fontFamily: font.mono,
  fontSize: 12,
  fontWeight: 600,
  letterSpacing: '0.04em',
  textTransform: 'uppercase',
  background: 'transparent',
  color: color.text,
  border: `1px solid ${color.border}`,
  borderRadius: 2,
  padding: '8px 14px',
  cursor: 'pointer',
  transition: 'background 100ms ease, color 100ms ease, border-color 100ms ease',
};

export const buttonPrimary: CSSProperties = {
  ...button,
  background: color.text,
  color: color.bg,
  borderColor: color.text,
};

export const buttonDisabled: CSSProperties = {
  ...button,
  color: color.textDim,
  borderColor: color.border,
  cursor: 'not-allowed',
};

export function statusColor(pct: number, warmPct: number, criticalPct: number): string {
  if (pct >= criticalPct) return color.bad;
  if (pct >= warmPct) return color.warn;
  return color.good;
}

// Subtle repeating scanline texture applied as a background-image, evoking a
// CRT/monitor surface without needing an image asset.
export const scanlines: CSSProperties = {
  backgroundImage:
    'repeating-linear-gradient(0deg, rgba(255,255,255,0.015) 0px, rgba(255,255,255,0.015) 1px, transparent 1px, transparent 3px)',
};
