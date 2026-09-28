import { useEffect, useRef, useState } from 'react';
import { button, color, font, scanlines } from '../theme/tokens';
import { isEnvBrowser } from '../utils/misc';
import { mockPriceHistory } from '../data/mockData';
import type { RigData } from '../types';
import { OverviewTab } from './tabs/OverviewTab';
import { GpuTab } from './tabs/GpuTab';
import { SellTab } from './tabs/SellTab';
import { AccessTab } from './tabs/AccessTab';

const BASE_TABS = ['Overview', 'GPUs & Shop', 'Sell BTC'] as const;
type Tab = (typeof BASE_TABS)[number] | 'Access';

export function Dashboard({
  data,
  onClose,
  onUpdate,
}: {
  data: RigData;
  onClose: () => void;
  onUpdate: (patch: Partial<RigData>) => void;
}) {
  const [tab, setTab] = useState<Tab>('Overview');
  const priceHistory = useRef<number[]>([data.btcPrice]);
  const [, forceRender] = useState(0);

  useEffect(() => {
    const last = priceHistory.current[priceHistory.current.length - 1];
    if (last !== data.btcPrice) {
      priceHistory.current = [...priceHistory.current, data.btcPrice].slice(-30);
      forceRender((n) => n + 1);
    }
  }, [data.btcPrice]);

  const onFire = !!data.rig.status.onFire;
  // Only the true owner can manage who else has access -- a shared-access
  // viewer never sees this tab at all, not just a disabled version of it.
  const tabs: Tab[] = data.rig.isOwner ? [...BASE_TABS, 'Access'] : [...BASE_TABS];

  return (
    <div
      style={{
        width: 620,
        maxWidth: '90vw',
        border: `1px solid ${onFire ? color.bad : color.borderBright}`,
        borderRadius: 4,
        background: color.bg,
        boxShadow: '0 24px 64px rgba(0,0,0,0.6)',
        overflow: 'hidden',
      }}
    >
      <div
        style={{
          ...scanlines,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '10px 14px',
          borderBottom: `1px solid ${color.border}`,
          background: color.panel,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <span
            style={{
              width: 8,
              height: 8,
              borderRadius: '50%',
              background: onFire ? color.bad : data.rig.power_state ? color.good : color.textDim,
            }}
          />
          <span style={{ fontFamily: font.display, fontSize: 13, fontWeight: 700, letterSpacing: '0.06em' }}>
            RIG #{data.rig.id.toString().padStart(3, '0')} -- {data.rig.rig_model.toUpperCase()}
          </span>
        </div>
        <button onClick={onClose} style={{ ...button, padding: '4px 10px', fontSize: 12 }}>
          Close [ESC]
        </button>
      </div>

      <div style={{ display: 'flex', borderBottom: `1px solid ${color.border}` }}>
        {tabs.map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            style={{
              flex: 1,
              padding: '10px 0',
              background: tab === t ? color.panelAlt : 'transparent',
              color: tab === t ? color.text : color.textMuted,
              border: 'none',
              borderBottom: tab === t ? `2px solid ${color.text}` : '2px solid transparent',
              fontFamily: font.display,
              fontSize: 12,
              fontWeight: 600,
              letterSpacing: '0.06em',
              textTransform: 'uppercase',
              cursor: 'pointer',
            }}
          >
            {t}
          </button>
        ))}
      </div>

      <div style={{ padding: 16, maxHeight: '70vh', overflowY: 'auto' }}>
        {tab === 'Overview' && <OverviewTab data={data} onUpdate={onUpdate} />}
        {tab === 'GPUs & Shop' && <GpuTab data={data} onUpdate={onUpdate} />}
        {tab === 'Sell BTC' && <SellTab btcPrice={data.btcPrice} priceHistory={priceHistory.current} />}
        {tab === 'Access' && data.rig.isOwner && <AccessTab data={data} onUpdate={onUpdate} />}
      </div>
    </div>
  );
}
