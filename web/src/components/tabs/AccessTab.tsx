import { useState } from 'react';
import { fetchNui } from '../../utils/fetchNui';
import { button, buttonDisabled, buttonPrimary, color, font, monoValue, panel, panelHeader } from '../../theme/tokens';
import type { AccessEntry, RigData } from '../../types';

export function AccessTab({ data, onUpdate }: { data: RigData; onUpdate: (patch: Partial<RigData>) => void }) {
  const { access } = data;
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [nearby, setNearby] = useState<AccessEntry[] | null>(null);
  const [manualId, setManualId] = useState('');

  async function findNearby() {
    setBusy(true);
    setMessage(null);
    const players = await fetchNui<AccessEntry[]>('getNearbyPlayers');
    setNearby(players);
    setBusy(false);
  }

  async function grant(citizenid: string) {
    setBusy(true);
    const res = await fetchNui<{ ok: boolean; message?: string }>('grantAccess', { citizenid });
    if (res.ok) {
      setNearby((prev) => prev?.filter((p) => p.citizenid !== citizenid) ?? null);
      setManualId('');
      setMessage(null);
    } else {
      setMessage(res.message ?? 'Failed to grant access');
    }
    setBusy(false);
  }

  async function revoke(citizenid: string) {
    setBusy(true);
    const res = await fetchNui<{ ok: boolean; message?: string }>('revokeAccess', { citizenid });
    if (res.ok) {
      onUpdate({ access: access.filter((a) => a.citizenid !== citizenid) });
    } else {
      setMessage(res.message ?? 'Failed to revoke access');
    }
    setBusy(false);
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <div style={panel}>
        <div style={panelHeader}>
          <span>Authorized Users</span>
          <span style={{ fontFamily: font.mono, fontSize: 11 }}>{access.length} / 8</span>
        </div>
        {access.length === 0 ? (
          <div style={{ padding: 12, fontFamily: font.mono, fontSize: 12, color: color.textDim }}>
            Nobody else has access to this rig yet.
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            {access.map((entry) => (
              <div
                key={entry.citizenid}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '10px 12px',
                  borderTop: `1px solid ${color.border}`,
                }}
              >
                <div>
                  <div style={{ fontFamily: font.display, fontSize: 13, fontWeight: 600 }}>{entry.name}</div>
                  <div style={{ ...monoValue, fontSize: 10, color: color.textMuted }}>{entry.citizenid}</div>
                </div>
                <button style={{ ...button, fontSize: 10, padding: '4px 8px' }} disabled={busy} onClick={() => revoke(entry.citizenid)}>
                  Revoke
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      <div style={panel}>
        <div style={panelHeader}>
          <span>Grant Access</span>
        </div>
        <div style={{ padding: 12, display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div>
            <button style={busy ? buttonDisabled : button} disabled={busy} onClick={findNearby}>
              Find Nearby Players
            </button>
            {nearby && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginTop: 10 }}>
                {nearby.length === 0 ? (
                  <div style={{ fontFamily: font.mono, fontSize: 12, color: color.textDim }}>Nobody nearby.</div>
                ) : (
                  nearby.map((p) => (
                    <div key={p.citizenid} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                      <div style={{ fontFamily: font.mono, fontSize: 12 }}>{p.name}</div>
                      <button
                        style={{ ...buttonPrimary, fontSize: 10, padding: '4px 10px' }}
                        disabled={busy}
                        onClick={() => grant(p.citizenid)}
                      >
                        Grant
                      </button>
                    </div>
                  ))
                )}
              </div>
            )}
          </div>

          <div style={{ borderTop: `1px solid ${color.border}`, paddingTop: 12 }}>
            <div style={{ fontFamily: font.display, fontSize: 10, textTransform: 'uppercase', color: color.textMuted, marginBottom: 8 }}>
              Or enter a citizen ID directly
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <input
                value={manualId}
                onChange={(e) => setManualId(e.target.value)}
                placeholder="ABC12345"
                style={{
                  ...monoValue,
                  fontSize: 12,
                  background: color.panelAlt,
                  border: `1px solid ${color.border}`,
                  borderRadius: 2,
                  padding: '6px 10px',
                  flex: 1,
                }}
              />
              <button
                style={busy || !manualId ? buttonDisabled : buttonPrimary}
                disabled={busy || !manualId}
                onClick={() => grant(manualId)}
              >
                Grant
              </button>
            </div>
          </div>

          {message && <div style={{ fontFamily: font.mono, fontSize: 11, color: color.bad }}>{message}</div>}
        </div>
      </div>
    </div>
  );
}
