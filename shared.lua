shared = {
    language = 'en', -- jezik / language (WIP)
    command = 'ter', -- komanda / command (Admin Only) // /ter (create/delete)
    groups = {'admin', 'superadmin'}, -- grupa ili permisija / group required
    rankings = false, -- rang lista za mafije / rank list and points for gangs? (true/false) (not user-friendly, yet.. but it's translated tho)
    capturing = 5, -- in minutes / u minutama
    cooldown = 30, -- in minutes / u minutama
    rewards = { -- reward is given only after successfully capturing the territory
        on = true, -- off (false) / on (true)
        item = 'black_money', -- item name
        count = 1000 -- amount
    },
    itemsToBuy = { -- buyable items if territory type is 'market'
        ['bread'] = {
            label = '🍞 | Bread',
            worth = 30,
            black = true, -- true = black money, false = cash
        },
        ['water'] = {
            label = '💧 | Water',
            worth = 20,
            black = true, -- true = black money, false = cash
        }
    },
    itemsToSell = { -- sellable items if territory type is 'dealer'
        ['marihuana'] = {
            label = '🌿 | Marijuana',
            worth = 550,
            black = true, -- true = black money, false = cash
        },
        ['heroin'] = {
            label = '💉 | Heroin',
            worth = 600,
            black = true, -- true = black money, false = cash
        },
        ['amfetamin10g'] = {
            label = '💊 | Amphetamine',
            worth = 800,
            black = true, -- true = black money, false = cash
        },
        ['coke_pooch'] = {
            label = '🏔️ | Cocaine',
            worth = 750,
            black = true, -- true = black money, false = cash
        }
    },
    gangs = { -- https://docs.fivem.net/docs/game-references/blips/ || gangs allowed to territories, aswell as their label (label not in use yet, but planned in future) and blip color
        gsf = { -- posao / job
            blipColour = 69, -- boja blipa / blip color
        },
        ballas = { -- posao / job
            blipColour = 58, -- boja blipa / blip color
        },
        bloods = { -- posao / job
            blipColour = 59, -- boja blipa / blip color
        }
    },
    translations = { -- WIP
        ['en'] = {},
        ['hr'] = {}
    }
}