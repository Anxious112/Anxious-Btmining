-- Auto-creates the `mining_rigs` table on first start, so a buyer can drop
-- this resource in and go -- no manual SQL import required. Reads
-- mining_rigs.sql directly (single source of truth, nothing duplicated into
-- Lua) and runs it as-is; `CREATE TABLE IF NOT EXISTS` makes this a no-op on
-- every subsequent restart, and it's still safe to import the .sql file by
-- hand first if a buyer prefers that -- whichever happens first wins, the
-- other is just a no-op. Written against MariaDB (the FOREIGN KEY needs the
-- `players` table -- i.e. qbx_core/oxmysql -- to already exist, which the
-- caller in server/main.lua guarantees by waiting on oxmysql first).
function RunMigrations()
    local sql = LoadResourceFile(GetCurrentResourceName(), 'mining_rigs.sql')
    if not sql then
        print('^1[anxious_btcmining] Could not read mining_rigs.sql from the resource -- table was not created^7')
        return
    end

    local ok, err = pcall(function()
        MySQL.query.await(sql)
    end)

    if not ok then
        print(('^1[anxious_btcmining] Failed to auto-create `mining_rigs` -- import mining_rigs.sql manually. Error: %s^7'):format(err))
    end
end
