---@class TerritoryRewardConfig
---@field enabled boolean
---@field item string
---@field count number

---@class TerritoryGangConfig
---@field blipColour number

---@class TerritoryMarketItem
---@field label string
---@field worth number
---@field black boolean true = black_money, false = cash

---@class TerritoryConfig
---@field adminCommand string
---@field playerCommand string
---@field groups table<string, boolean>
---@field rankings boolean
---@field captureDuration number Duration in minutes
---@field cooldown number Duration in minutes
---@field rewards TerritoryRewardConfig
---@field gangOnlyBlips boolean
---@field interactDistance number
---@field gangs table<string, TerritoryGangConfig>
---@field itemsToBuy table<string, TerritoryMarketItem>
---@field itemsToSell table<string, TerritoryMarketItem>

---@type TerritoryConfig
Config = {
    adminCommand = "territory",
    playerCommand = "territories",
    groups = { ["admin"] = true, ["superadmin"] = true },
    rankings = false,
    captureDuration = 5,
    cooldown = 30,
    interactDistance = 1.5,
    rewards = {
        enabled = true,
        item = "black_money",
        count = 1000,
    },
    gangOnlyBlips = true,
    gangs = {
        gsf = {
            blipColour = 69,
        },
        ballas = {
            blipColour = 58,
        },
        bloods = {
            blipColour = 59,
        },
    },
    itemsToBuy = {
        ["bread"] = {
            label = "Bread",
            worth = 30,
            black = true,
        },
        ["water"] = {
            label = "Water",
            worth = 20,
            black = true,
        },
    },
    itemsToSell = {
        ["marihuana"] = {
            label = "Marijuana",
            worth = 550,
            black = true,
        },
        ["heroin"] = {
            label = "Heroin",
            worth = 600,
            black = true,
        },
        ["amfetamin10g"] = {
            label = "Amphetamine",
            worth = 800,
            black = true,
        },
        ["coke_pooch"] = {
            label = "Cocaine",
            worth = 750,
            black = true,
        },
    },
}
