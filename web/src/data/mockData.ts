import type { GpuTierConfig, RigData } from '../types';

// Mirrors config.lua's Config.GpuTiers exactly (20 tiers on the ANX line) --
// kept as one source array here so the mock gpuTiers/shop below can't drift
// out of sync with each other the way two hand-typed literals would.
const TIER_SOURCE: (GpuTierConfig & { key: string })[] = [
  { key: 'tier01', item: 'gpu_tier01', label: 'ANX-100', hashrate: 8, powerDraw: 90, heatPerSecond: 0.6, price: 1800, maxCondition: 100, requiredLevel: 1 },
  { key: 'tier02', item: 'gpu_tier02', label: 'ANX-150', hashrate: 10, powerDraw: 100, heatPerSecond: 0.7, price: 2200, maxCondition: 100, requiredLevel: 1 },
  { key: 'tier03', item: 'gpu_tier03', label: 'ANX-200', hashrate: 12, powerDraw: 115, heatPerSecond: 0.8, price: 2700, maxCondition: 100, requiredLevel: 2 },
  { key: 'tier04', item: 'gpu_tier04', label: 'ANX-250', hashrate: 14, powerDraw: 130, heatPerSecond: 0.85, price: 3300, maxCondition: 100, requiredLevel: 3 },
  { key: 'tier05', item: 'gpu_tier05', label: 'ANX-300', hashrate: 17, powerDraw: 150, heatPerSecond: 0.95, price: 4000, maxCondition: 100, requiredLevel: 4 },
  { key: 'tier06', item: 'gpu_tier06', label: 'ANX-400', hashrate: 20, powerDraw: 170, heatPerSecond: 1.05, price: 5000, maxCondition: 100, requiredLevel: 5 },
  { key: 'tier07', item: 'gpu_tier07', label: 'ANX-500', hashrate: 24, powerDraw: 190, heatPerSecond: 1.2, price: 6100, maxCondition: 100, requiredLevel: 6 },
  { key: 'tier08', item: 'gpu_tier08', label: 'ANX-600', hashrate: 29, powerDraw: 215, heatPerSecond: 1.3, price: 7500, maxCondition: 100, requiredLevel: 7 },
  { key: 'tier09', item: 'gpu_tier09', label: 'ANX-700', hashrate: 35, powerDraw: 245, heatPerSecond: 1.45, price: 9100, maxCondition: 100, requiredLevel: 8 },
  { key: 'tier10', item: 'gpu_tier10', label: 'ANX-800', hashrate: 41, powerDraw: 275, heatPerSecond: 1.6, price: 11200, maxCondition: 100, requiredLevel: 9 },
  { key: 'tier11', item: 'gpu_tier11', label: 'ANX-900', hashrate: 50, powerDraw: 310, heatPerSecond: 1.8, price: 13700, maxCondition: 100, requiredLevel: 10 },
  { key: 'tier12', item: 'gpu_tier12', label: 'ANX-1000', hashrate: 60, powerDraw: 350, heatPerSecond: 2.0, price: 16800, maxCondition: 100, requiredLevel: 11 },
  { key: 'tier13', item: 'gpu_tier13', label: 'ANX-1200', hashrate: 72, powerDraw: 400, heatPerSecond: 2.25, price: 20500, maxCondition: 100, requiredLevel: 13 },
  { key: 'tier14', item: 'gpu_tier14', label: 'ANX-1400', hashrate: 86, powerDraw: 450, heatPerSecond: 2.5, price: 25200, maxCondition: 100, requiredLevel: 15 },
  { key: 'tier15', item: 'gpu_tier15', label: 'ANX-1600', hashrate: 103, powerDraw: 510, heatPerSecond: 2.8, price: 30800, maxCondition: 100, requiredLevel: 16 },
  { key: 'tier16', item: 'gpu_tier16', label: 'ANX-1800', hashrate: 124, powerDraw: 580, heatPerSecond: 3.1, price: 37700, maxCondition: 100, requiredLevel: 18 },
  { key: 'tier17', item: 'gpu_tier17', label: 'ANX-2000', hashrate: 148, powerDraw: 650, heatPerSecond: 3.5, price: 46200, maxCondition: 100, requiredLevel: 19 },
  { key: 'tier18', item: 'gpu_tier18', label: 'ANX-2200', hashrate: 178, powerDraw: 740, heatPerSecond: 3.9, price: 56600, maxCondition: 100, requiredLevel: 21 },
  { key: 'tier19', item: 'gpu_tier19', label: 'ANX-2400', hashrate: 214, powerDraw: 840, heatPerSecond: 4.3, price: 69400, maxCondition: 100, requiredLevel: 23 },
  { key: 'tier20', item: 'gpu_tier20', label: 'ANX-2600 Ti', hashrate: 256, powerDraw: 950, heatPerSecond: 4.8, price: 85000, maxCondition: 100, requiredLevel: 25 },
];

const MOCK_LEVEL = 9;

const gpuTiers: Record<string, GpuTierConfig> = {};
for (const { key, ...tier } of TIER_SOURCE) gpuTiers[key] = tier;

const shop = TIER_SOURCE.map(({ key, item: _item, maxCondition: _maxCondition, ...rest }) => ({
  key,
  ...rest,
  unlocked: MOCK_LEVEL >= rest.requiredLevel,
}));

// Only used when running in a plain browser (isEnvBrowser()) for local dev
// preview -- these numbers follow the real formulas in config.lua/skill.lua
// (baseXp=200, growth=1.6) so the preview looks like a plausible mid-game
// rig rather than arbitrary placeholder values.
export const mockRigData: RigData = {
  rig: {
    id: 1,
    rig_model: 'standard',
    maxSlots: 4,
    coords: { x: 120.4, y: -890.2, z: 29.3 },
    heading: 180.0,
    slots: [
      { tier: 'tier01', durability: 82 },
      { tier: 'tier06', durability: 96 },
      false,
      false,
    ],
    heat: 47,
    power_state: true,
    banked_micro_btc: 342000,
    uptime_seconds: 5430,
    status: { damaged: false, onFire: false, seized: false },
    xp: 5400,
    level: MOCK_LEVEL,
    isOwner: true,
  },
  skill: {
    level: MOCK_LEVEL,
    xp: 5400,
    maxLevel: 25,
    currentLevelXp: 5115,
    nextLevelXp: 6493,
  },
  shop,
  myGpus: [{ inventorySlot: 7, tier: 'tier02', label: 'ANX-150', durability: 100 }],
  access: [{ citizenid: 'ABC12345', name: 'Jane Doe' }],
  btcPrice: 47200,
  gpuTiers,
};

// A short synthetic price trail so the Sell tab's sparkline has something to
// draw in browser preview -- a freshly-opened real dashboard legitimately
// starts with just one known price point, this is preview-only polish.
export const mockPriceHistory = [45800, 46100, 45600, 46700, 47500, 46900, 47200];

const actionEvents = new Set([
  'installGpu',
  'removeGpu',
  'collectBtc',
  'togglePower',
  'buyGpu',
  'sellBtc',
  'closeDashboard',
  'minigameResult',
  'grantAccess',
  'revokeAccess',
]);

const mockNearbyPlayers = [
  { citizenid: 'XYZ98765', name: 'John Smith' },
  { citizenid: 'QWE45612', name: 'Alex Reyes' },
];

// Auto-responds to the client->NUI action callbacks with a plausible {ok:
// true} so buttons don't error out in a plain browser -- browser preview
// doesn't get live game-state round trips back, only the real Lua side
// pushes fresh setRigData after an action actually lands.
export function getMockResponse<T>(eventName: string, _data?: unknown): T | undefined {
  if (eventName === 'getNearbyPlayers') {
    return mockNearbyPlayers as unknown as T;
  }
  if (actionEvents.has(eventName)) {
    return { ok: true } as unknown as T;
  }
  return undefined;
}
