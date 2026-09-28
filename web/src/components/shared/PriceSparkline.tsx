import { color } from '../../theme/tokens';

const WIDTH = 220;
const HEIGHT = 48;

export function PriceSparkline({ history }: { history: number[] }) {
  if (history.length < 2) {
    return <div style={{ width: WIDTH, height: HEIGHT }} />;
  }

  const min = Math.min(...history);
  const max = Math.max(...history);
  const range = max - min || 1;

  const points = history
    .map((price, i) => {
      const x = (i / (history.length - 1)) * WIDTH;
      const y = HEIGHT - ((price - min) / range) * HEIGHT;
      return `${x.toFixed(1)},${y.toFixed(1)}`;
    })
    .join(' ');

  const rising = history[history.length - 1] >= history[0];
  const lineColor = rising ? color.good : color.bad;

  return (
    <svg width={WIDTH} height={HEIGHT} viewBox={`0 0 ${WIDTH} ${HEIGHT}`} style={{ display: 'block' }}>
      <polyline points={points} fill="none" stroke={lineColor} strokeWidth={1.5} />
    </svg>
  );
}
