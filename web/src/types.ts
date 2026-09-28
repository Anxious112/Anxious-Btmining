export interface RigSlotGpu {
  tier: string;
  durability: number;
}

export type RigSlotValue = RigSlotGpu | false;

export interface RigStatus {
  damaged?: boolean;
  onFire?: boolean;
  seized?: boolean;
}

export interface Rig {
  id: number;
  rig_model: string;
  maxSlots: number;
  coords: { x: number; y: number; z: number };
  heading: number;
  slots: RigSlotValue[];
  heat: number;
  power_state: boolean;
  banked_micro_btc: number;
  uptime_seconds: number;
  status: RigStatus;
  xp: number;
  level: number;
  isOwner: boolean; // false for a shared-access viewer -- gates the Access tab
}

export interface AccessEntry {
  citizenid: string;
  name: string;
}

export interface SkillProgress {
  level: number;
  xp: number;
  maxLevel: number;
  currentLevelXp: number;
  nextLevelXp: number;
}

export interface ShopEntry {
  key: string;
  label: string;
  price: number;
  requiredLevel: number;
  hashrate: number;
  powerDraw: number;
  heatPerSecond: number;
  unlocked: boolean;
}

export interface OwnedGpu {
  inventorySlot: number;
  tier: string;
  label: string;
  durability: number;
}

export interface GpuTierConfig {
  item: string;
  label: string;
  hashrate: number;
  powerDraw: number;
  heatPerSecond: number;
  price: number;
  maxCondition: number;
  requiredLevel: number;
}

export interface RigData {
  rig: Rig;
  skill: SkillProgress;
  shop: ShopEntry[];
  myGpus: OwnedGpu[];
  access: AccessEntry[]; // [] for a shared-access (non-owner) viewer
  btcPrice: number;
  gpuTiers: Record<string, GpuTierConfig>;
}

export type MinigameKind = 'extinguish' | 'install' | 'hack';

// "Coolant Purge" (fire) and "Socket Alignment" (GPU install) -- a marker
// sweeps a track, the player strikes when it's inside the target zone.
export interface SweepDifficulty {
  variant: 'linear' | 'radial';
  zoneWidthPct: number; // target zone width, as a % of the full track/circle
  speedMs: number; // time for the marker to sweep the full track one-way
  requiredHits: number;
  maxMisses: number;
  timeLimitMs: number;
}

// "Firewall Breach" (hack) -- a Simon-says sequence-recall grid.
export interface SequenceDifficulty {
  gridSize: number; // perfect square: 9 = 3x3, 16 = 4x4
  length: number;
  showDelayMs: number;
  inputTimeoutMs: number;
}

export interface MinigameRequest {
  requestId: number;
  kind: MinigameKind;
  difficulty: SweepDifficulty | SequenceDifficulty;
}
