import { useState } from 'react';
import { fetchNui } from '../../utils/fetchNui';
import { formatCash } from '../../utils/format';
import { button, buttonDisabled, buttonPrimary, color, font, monoValue, panel, panelHeader } from '../../theme/tokens';
import { PriceSparkline } from '../shared/PriceSparkline';

export function SellTab({ btcPrice, priceHistory }: { btcPrice: number; priceHistory: number[] }) {
  const [amount, setAmount] = useState('1');
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState<string | null>(null);

  const parsedAmount = Math.max(0, Math.floor(Number(amount) || 0));
  const preview = parsedAmount * btcPrice;

  async function sell() {
    if (parsedAmount < 1) return;
    setBusy(true);
    setResult(null);
    const res = await fetchNui<{ ok: boolean; message?: string; result?: number }>('sellBtc', { amount: parsedAmount });
    setResult(res.ok ? `Sold for ${formatCash(preview)}` : res.message ?? 'Sale failed');
    setBusy(false);
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <div style={panel}>
        <div style={panelHeader}>
          <span>Market Price</span>
          <span style={monoValue}>{formatCash(btcPrice)} / BTC</span>
        </div>
        <div style={{ padding: 12, display: 'flex', justifyContent: 'center' }}>
          <PriceSparkline history={priceHistory} />
        </div>
      </div>

      <div style={panel}>
        <div style={panelHeader}>
          <span>Sell Bitcoin</span>
        </div>
        <div style={{ padding: 12, display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <label style={{ fontFamily: font.display, fontSize: 11, textTransform: 'uppercase', color: color.textMuted }}>
              Amount
            </label>
            <input
              value={amount}
              onChange={(e) => setAmount(e.target.value.replace(/[^0-9]/g, ''))}
              style={{
                ...monoValue,
                fontSize: 14,
                background: color.panelAlt,
                border: `1px solid ${color.border}`,
                borderRadius: 2,
                padding: '6px 10px',
                width: 100,
              }}
            />
            <span style={{ fontFamily: font.mono, fontSize: 12, color: color.textMuted }}>BTC</span>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div>
              <div style={{ fontFamily: font.display, fontSize: 10, textTransform: 'uppercase', color: color.textMuted }}>
                Payout Preview
              </div>
              <div style={{ ...monoValue, fontSize: 20, fontWeight: 700 }}>{formatCash(preview)}</div>
            </div>
            <button style={busy || parsedAmount < 1 ? buttonDisabled : buttonPrimary} disabled={busy || parsedAmount < 1} onClick={sell}>
              Sell
            </button>
          </div>

          {result && (
            <div style={{ fontFamily: font.mono, fontSize: 12, color: color.textMuted }}>{result}</div>
          )}
        </div>
      </div>
    </div>
  );
}
