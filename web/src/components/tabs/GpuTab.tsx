import { useState } from 'react';
import { fetchNui } from '../../utils/fetchNui';
import { formatCash } from '../../utils/format';
import { button, buttonDisabled, buttonPrimary, color, font, monoValue, panel, panelHeader } from '../../theme/tokens';
import type { GpuTierConfig, RigData, RigSlotValue, SweepDifficulty } from '../../types';
import { MinigameOverlay } from '../minigames/MinigameOverlay';

// Harder tiers demand a tighter, faster-moving Socket Alignment window --
// derived from requiredLevel (1-25) rather than a second hand-tuned curve,
// so difficulty naturally tracks the same progression the GPU shop uses.
function installDifficultyFor(tier: GpuTierConfig | undefined): SweepDifficulty {
  const t = tier ? Math.min(1, Math.max(0, (tier.requiredLevel - 1) / 24)) : 0;
  return {
    variant: 'radial',
    zoneWidthPct: 22 - t * 13, // 22% down to 9%
    speedMs: Math.round(1000 - t * 500), // 1000ms down to 500ms per sweep
    requiredHits: 3,
    maxMisses: 1,
    timeLimitMs: 9000,
  };
}

export function GpuTab({ data, onUpdate }: { data: RigData; onUpdate: (patch: Partial<RigData>) => void }) {
  const { rig, shop, myGpus, skill } = data;
  const [pickerSlot, setPickerSlot] = useState<number | null>(null);
  const [busy, setBusy] = useState(false);
  const [installAttempt, setInstallAttempt] = useState<{ rigSlot: number; inventorySlot: number; difficulty: SweepDifficulty } | null>(
    null,
  );
  const [installMessage, setInstallMessage] = useState<string | null>(null);

  function beginInstall(rigSlot: number, inventorySlot: number) {
    const picked = myGpus.find((g) => g.inventorySlot === inventorySlot);
    setInstallMessage(null);
    setInstallAttempt({ rigSlot, inventorySlot, difficulty: installDifficultyFor(picked ? data.gpuTiers[picked.tier] : undefined) });
    setPickerSlot(null);
  }

  async function onInstallMinigameResult(success: boolean) {
    const attempt = installAttempt;
    setInstallAttempt(null);
    if (!attempt || !success) {
      if (attempt) setInstallMessage('Installation failed -- the card didn\'t seat right.');
      return;
    }
    await install(attempt.rigSlot, attempt.inventorySlot);
  }

  async function install(rigSlot: number, inventorySlot: number) {
    setBusy(true);
    // rig.slots is 0-indexed here (a plain JS array) but Lua's rig.slots
    // table is 1-indexed -- convert only at the network boundary so every
    // local array access in this file can stay natural 0-based JS indexing.
    const res = await fetchNui<{ ok: boolean; message?: string }>('installGpu', { rigSlot: rigSlot + 1, inventorySlot });
    if (res.ok) {
      const picked = myGpus.find((g) => g.inventorySlot === inventorySlot);
      const nextSlots: RigSlotValue[] = rig.slots.slice();
      if (picked) nextSlots[rigSlot] = { tier: picked.tier, durability: picked.durability };
      onUpdate({
        rig: { ...rig, slots: nextSlots },
        myGpus: myGpus.filter((g) => g.inventorySlot !== inventorySlot),
      });
    } else {
      setInstallMessage(res.message ?? 'Installation failed');
    }
    setBusy(false);
  }

  async function remove(rigSlot: number) {
    setBusy(true);
    const res = await fetchNui<{ ok: boolean; message?: string }>('removeGpu', { rigSlot: rigSlot + 1 });
    if (res.ok) {
      const nextSlots: RigSlotValue[] = rig.slots.slice();
      nextSlots[rigSlot] = false;
      onUpdate({ rig: { ...rig, slots: nextSlots } });
    }
    setBusy(false);
  }

  async function buy(tierKey: string) {
    setBusy(true);
    const res = await fetchNui<{ ok: boolean; message?: string }>('buyGpu', { tierKey });
    if (res.ok) {
      const tier = data.gpuTiers[tierKey];
      const label = shop.find((s) => s.key === tierKey)?.label ?? tierKey;
      onUpdate({ myGpus: [...myGpus, { inventorySlot: -1, tier: tierKey, label, durability: tier?.maxCondition ?? 100 }] });
    }
    setBusy(false);
  }

  const progressPct =
    skill.nextLevelXp > 0
      ? Math.min(100, ((skill.xp - skill.currentLevelXp) / (skill.nextLevelXp - skill.currentLevelXp)) * 100)
      : 100;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <div style={panel}>
        <div style={panelHeader}>
          <span>Rig Level {skill.level}</span>
          <span style={{ fontFamily: font.mono, fontSize: 11 }}>
            {skill.nextLevelXp > 0 ? `${skill.xp} / ${skill.nextLevelXp} XP` : 'MAX LEVEL'}
          </span>
        </div>
        <div style={{ padding: 12 }}>
          <div style={{ height: 6, background: color.panelAlt, border: `1px solid ${color.border}`, borderRadius: 2 }}>
            <div style={{ height: '100%', width: `${progressPct}%`, background: color.text, borderRadius: 1 }} />
          </div>
        </div>
      </div>

      <div style={panel}>
        <div style={panelHeader}>
          <span>Chassis Slots</span>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))', gap: 10, padding: 12 }}>
          {rig.slots.map((slot, i) => (
            <SlotBox
              key={i}
              slot={slot}
              gpuTiers={data.gpuTiers}
              busy={busy}
              onInstallClick={() => setPickerSlot(i)}
              onRemove={() => remove(i)}
            />
          ))}
        </div>
        {pickerSlot !== null && (
          <div style={{ borderTop: `1px solid ${color.border}`, padding: 12 }}>
            <div style={{ fontFamily: font.display, fontSize: 11, color: color.textMuted, marginBottom: 8, textTransform: 'uppercase' }}>
              Install into slot {pickerSlot + 1}
            </div>
            {myGpus.length === 0 ? (
              <div style={{ fontFamily: font.mono, fontSize: 12, color: color.textDim }}>No spare GPUs in your inventory.</div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                {myGpus.map((g) => (
                  <button
                    key={g.inventorySlot}
                    style={button}
                    disabled={busy}
                    onClick={() => beginInstall(pickerSlot, g.inventorySlot)}
                  >
                    {g.label} -- {g.durability}%
                  </button>
                ))}
              </div>
            )}
            <button style={{ ...button, marginTop: 8 }} onClick={() => setPickerSlot(null)}>
              Cancel
            </button>
          </div>
        )}
        {installMessage && (
          <div style={{ padding: '0 12px 12px', fontFamily: font.mono, fontSize: 11, color: color.textMuted }}>{installMessage}</div>
        )}
      </div>

      <div style={panel}>
        <div style={panelHeader}>
          <span>GPU Shop</span>
          <span style={{ fontFamily: font.mono, fontSize: 11 }}>{shop.length} tiers</span>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', maxHeight: 320, overflowY: 'auto' }}>
          {shop.map((entry) => (
            <div
              key={entry.key}
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                padding: '10px 12px',
                borderTop: `1px solid ${color.border}`,
                opacity: entry.unlocked ? 1 : 0.55,
              }}
            >
              <div>
                <div style={{ fontFamily: font.display, fontSize: 13, fontWeight: 600 }}>{entry.label}</div>
                <div style={{ fontFamily: font.mono, fontSize: 11, color: color.textMuted }}>
                  {entry.hashrate} H/s -- {entry.powerDraw}W -- {entry.heatPerSecond}/s heat
                </div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <div style={monoValue}>{formatCash(entry.price)}</div>
                <button
                  style={!entry.unlocked || busy ? buttonDisabled : buttonPrimary}
                  disabled={!entry.unlocked || busy}
                  onClick={() => buy(entry.key)}
                >
                  {entry.unlocked ? 'Buy' : `Lvl ${entry.requiredLevel}`}
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {installAttempt && (
        <MinigameOverlay
          request={{ requestId: 0, kind: 'install', difficulty: installAttempt.difficulty }}
          onResult={onInstallMinigameResult}
        />
      )}
    </div>
  );
}

function SlotBox({
  slot,
  gpuTiers,
  busy,
  onInstallClick,
  onRemove,
}: {
  slot: RigSlotValue;
  gpuTiers: RigData['gpuTiers'];
  busy: boolean;
  onInstallClick: () => void;
  onRemove: () => void;
}) {
  if (slot === false) {
    return (
      <button
        onClick={onInstallClick}
        disabled={busy}
        style={{
          ...button,
          minHeight: 72,
          borderStyle: 'dashed',
          color: color.textDim,
        }}
      >
        + Install GPU
      </button>
    );
  }

  const label = gpuTiers[slot.tier]?.label ?? slot.tier;

  return (
    <div style={{ border: `1px solid ${color.border}`, borderRadius: 2, padding: 10, background: color.panelAlt }}>
      <div style={{ fontFamily: font.display, fontSize: 12, fontWeight: 600 }}>{label}</div>
      <div style={{ height: 4, background: color.border, borderRadius: 2, margin: '8px 0' }}>
        <div style={{ height: '100%', width: `${slot.durability}%`, background: color.text, borderRadius: 2 }} />
      </div>
      <div style={{ fontFamily: font.mono, fontSize: 10, color: color.textMuted, marginBottom: 8 }}>{slot.durability}% condition</div>
      <button style={{ ...button, fontSize: 10, padding: '4px 8px' }} disabled={busy} onClick={onRemove}>
        Remove
      </button>
    </div>
  );
}
