-- Mean-reverting random walk -- written to GlobalState so every client's
-- dashboard gets live price updates for free via statebag replication,
-- no polling callback needed.

local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

local function stepPrice(price)
    local swing = (math.random() * 2 - 1) * Config.Market.volatility
    local reversion = (Config.Market.basePrice - price) * Config.Market.meanReversion

    return clamp(price + swing + reversion, Config.Market.minPrice, Config.Market.maxPrice)
end

CreateThread(function()
    GlobalState.btc_price = Config.Market.basePrice

    while true do
        Wait(Config.Market.updateIntervalMs)
        GlobalState.btc_price = stepPrice(GlobalState.btc_price)
    end
end)
