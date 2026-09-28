import { useEffect, useState } from 'react';
import { useNuiEvent } from '../hooks/useNuiEvent';
import { fetchNui } from '../utils/fetchNui';
import { isEnvBrowser } from '../utils/misc';
import { mockRigData } from '../data/mockData';
import { color, font } from '../theme/tokens';
import type { MinigameRequest, RigData } from '../types';
import { Dashboard } from './Dashboard';
import { MinigameOverlay } from './minigames/MinigameOverlay';

export function App() {
  const [visible, setVisible] = useState(isEnvBrowser());
  const [data, setData] = useState<RigData | null>(isEnvBrowser() ? mockRigData : null);
  const [minigame, setMinigame] = useState<MinigameRequest | null>(null);

  useNuiEvent<boolean>('setVisible', setVisible);
  useNuiEvent<RigData>('setRigData', setData);
  useNuiEvent<number>('setBtcPrice', (price) => {
    setData((prev) => (prev ? { ...prev, btcPrice: price } : prev));
  });
  // Fired by client/minigame.lua's RunMinigame for the two world-triggered
  // minigames (fighting a fire, hacking someone else's rig) -- these have no
  // dashboard open, so this is the only NUI visible while they run.
  useNuiEvent<MinigameRequest>('openMinigame', setMinigame);

  function close() {
    setVisible(false);
    fetchNui('closeDashboard');
  }

  function update(patch: Partial<RigData>) {
    setData((prev) => (prev ? { ...prev, ...patch } : prev));
  }

  function resolveMinigame(success: boolean) {
    if (!minigame) return;
    fetchNui('minigameResult', { requestId: minigame.requestId, success });
    setMinigame(null);
  }

  useEffect(() => {
    if (!visible) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [visible]);

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontFamily: font.mono,
        color: color.text,
        pointerEvents: 'none',
      }}
    >
      {visible && data && (
        <div style={{ pointerEvents: 'auto' }}>
          <Dashboard data={data} onClose={close} onUpdate={update} />
        </div>
      )}
      {minigame && (
        <div style={{ pointerEvents: 'auto' }}>
          <MinigameOverlay request={minigame} onResult={resolveMinigame} />
        </div>
      )}
    </div>
  );
}
