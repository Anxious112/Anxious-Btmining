// Must match Config.MicroBtcPerItem in config.lua -- the server never sends
// this constant to the NUI, so it's mirrored here for display purposes only.
export const MICRO_BTC_PER_ITEM = 1000000;

export function formatCash(amount: number): string {
  return '$' + Math.round(amount).toLocaleString('en-US');
}

export function formatMicroBtc(microBtc: number): string {
  return (microBtc / MICRO_BTC_PER_ITEM).toFixed(4) + ' BTC';
}

export function formatUptime(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  return `${h}h ${m}m`;
}
