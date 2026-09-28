import { useState } from 'react';
import { fetchNui } from '../../utils/fetchNui';
import { formatMicroBtc, formatUptime, MICRO_BTC_PER_ITEM } from '../../utils/format';
import { button, buttonDisabled, buttonPrimary, color, font, monoValue, panel, panelHeader } from '../../theme/tokens';
import { HeatMeter } from '../shared/HeatMeter';
import type { RigData } from '../../types';

export function OverviewTab({ data, onUpdate }: { data: RigData; onUpdate: (patch: Partial<RigData>) => void }) {
  const { rig } = data;
  const [busy, setBusy] = useState(false);

  const wholeCollectable = Math.floor(rig.banked_micro_btc / MICRO_BTC_PER_ITEM);
  const installedGpus = rig.slots.filter((s) => s !== false).length;
  const onFire = !!rig.status.onFire;

  async function collect() {
    setBusy(true);
    const res = await fetchNui<{ ok: boolean }>('collectBtc');
    if (res.ok) onUpdate({ rig: { ...rig, banked_micro_btc: rig.banked_micro_btc % MICRO_BTC_PER_ITEM } });
    setBusy(false);
  }

  async function togglePower() {
    setBusy(true);
    const res = await fetchNui<{ ok: boolean }>('togglePower');
    if (res.ok) onUpdate({ rig: { ...rig, power_state: !rig.power_state } });
    setBusy(false);
  }

  return (
    <div style={{ display: 'flex', gap: 16 }}>
      <div style={{ ...panel, flex: '0 0 160px', padding: '20px 12px', display: 'flex', justifyContent: 'center' }}>
        <HeatMeter heat={rig.heat} />
      </div>

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 12 }}>
        <div style={panel}>
          <div style={panelHeader}>
            <span>Rig Status</span>
            <span style={{ color: onFire ? color.bad : rig.power_state ? color.good : color.textDim }}>
              {onFire ? 'ON FIRE' : rig.power_state ? 'RUNNING' : 'OFFLINE'}
            </span>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, padding: 12 }}>
            <Stat label="GPUs Installed" value={`${installedGpus} / ${rig.maxSlots}`} />
            <Stat label="Uptime" value={formatUptime(rig.uptime_seconds)} />
            <Stat label="Level" value={`${rig.level}`} />
            <Stat label="XP" value={`${rig.xp}`} />
          </div>
        </div>

        <div style={panel}>
          <div style={panelHeader}>
            <span>Banked Balance</span>
          </div>
          <div style={{ padding: 12, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ ...monoValue, fontSize: 24, fontWeight: 700 }}>{formatMicroBtc(rig.banked_micro_btc)}</div>
            <button
              onClick={collect}
              disabled={busy || wholeCollectable < 1}
              style={busy || wholeCollectable < 1 ? buttonDisabled : buttonPrimary}
            >
              Collect {wholeCollectable > 0 ? `(${wholeCollectable})` : ''}
            </button>
          </div>
        </div>

        <button onClick={togglePower} disabled={busy || onFire} style={busy || onFire ? buttonDisabled : button}>
          {rig.power_state ? 'Shut Down' : 'Power On'}
        </button>
      </div>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <div style={{ fontFamily: font.display, fontSize: 10, letterSpacing: '0.08em', textTransform: 'uppercase', color: color.textMuted }}>
        {label}
      </div>
      <div style={{ ...monoValue, fontSize: 16 }}>{value}</div>
    </div>
  );
}
