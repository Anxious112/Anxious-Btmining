CREATE TABLE IF NOT EXISTS `mining_rigs` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `rig_model` VARCHAR(50) NOT NULL,
  `coords` JSON NOT NULL,
  `heading` FLOAT NOT NULL DEFAULT 0,
  `slots` JSON NOT NULL,
  `heat` FLOAT NOT NULL DEFAULT 0,
  `power_state` TINYINT(1) NOT NULL DEFAULT 1,
  `banked_micro_btc` BIGINT NOT NULL DEFAULT 0,
  `uptime_seconds` INT NOT NULL DEFAULT 0,
  `last_tick` INT NOT NULL DEFAULT 0,
  `status` JSON NOT NULL,
  -- Mining skill is per-rig, not per-player -- a player who owns several
  -- rigs levels each one up independently by collecting BTC from it.
  `xp` INT NOT NULL DEFAULT 0,
  `level` INT NOT NULL DEFAULT 1,
  -- JSON array of citizenids the owner has granted rig access to -- everyone
  -- listed here gets the same dashboard access as the owner (install/remove
  -- GPUs, collect, toggle power, buy GPUs), but only the owner can grant or
  -- revoke it. See server/access.lua.
  `shared_access` JSON NOT NULL DEFAULT ('[]'),
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_owner` (`citizenid`),
  FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
