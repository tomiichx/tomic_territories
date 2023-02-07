local ESX, PlayerData, territories, headerBlips, circleBlips, progress = nil, {}, {}, {}, {}, 0

CreateThread(function()
    ESX = exports['es_extended']:getSharedObject()
    PlayerData = ESX.GetPlayerData()

    ESX.TriggerServerCallback('tomic_territories:getTerritories', function(cb)
        territories = cb
    end)

    Wait(1000) -- Wait for the territories to load (in case you have a lot of them, this would be clever to keep here)...

    createBlips()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

local function checkInput(input, typeRequired, checkEmpty)
    checkEmpty = checkEmpty or false
    if input == nil then return false end
    if typeRequired == nil then return false end

    if typeRequired == 'any' then return true end
    if typeRequired == 'number' then input = tonumber(input) end
    if typeRequired == 'string' then input = tostring(input) end

    if type(input) == 'table' then
        for k, v in pairs(input) do
            if type(v) ~= typeRequired or (checkEmpty and (v == '' or v == nil)) then return false end
        end
    else
        if type(input) ~= typeRequired or (checkEmpty and (input == '' or input == nil)) then return false end
    end

    return true
end

function createBlips()
    for i = 1, #territories do
        local territory = territories[i]
        local circleBlip = AddBlipForCoord(territory.coords.x, territory.coords.y, territory.coords.z)
        SetBlipSprite(circleBlip, 373)
        SetBlipDisplay(circleBlip, 8)
        SetBlipScale(circleBlip, 4.0)
        SetBlipAlpha(circleBlip, 100)
        SetBlipAsShortRange(circleBlip, true)
        for k, v in pairs(shared.gangs) do
            if territory.owner == k then
                SetBlipColour(circleBlip, v.blipColour)
                break
            end
        end
        table.insert(circleBlips, circleBlip)

        -- ////////////////////////////////////////// --

        local headerBlip = AddBlipForCoord(territory.coords.x, territory.coords.y, territory.coords.z + 15)
        SetBlipSprite(headerBlip, 310)
        SetBlipDisplay(headerBlip, 4)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(string.format('Territory: %s | Owner: %s', territory.name, territory.owner ~= 'noone' and territory.label or 'Free Territory!'))
        EndTextCommandSetBlipName(headerBlip)
        SetBlipScale(headerBlip, 0.75)
        SetBlipColour(headerBlip, 0)
        SetBlipAlpha(headerBlip, 250)
        SetBlipAsShortRange(headerBlip, true)
        table.insert(headerBlips, headerBlip)
    end
end

RegisterNetEvent('tomic_territories:updateTerritories')
AddEventHandler('tomic_territories:updateTerritories', function(cb)
    territories = cb
    for _, blip in pairs(circleBlips) do RemoveBlip(blip) end
    for _, blip in pairs(headerBlips) do RemoveBlip(blip) end
    circleBlips, headerBlips = {}, {}
    Wait(1000) -- Wait for blips to disappear...
    createBlips()
end)

RegisterNetEvent('tomic_territories:updateBlips')
AddEventHandler('tomic_territories:updateBlips', function(id, job, label)
    while true do
        Wait(1000)
        for i, v in pairs(territories) do
            if v.id == id then
                if v.isTaking then
                    for k, p in pairs(shared.gangs) do
                        if v.owner == k then
                            SetBlipColour(circleBlips[i], p.blipColour)
                            Wait(1000)
                            SetBlipColour(circleBlips[i], shared.gangs[job].blipColour)
                        end
                    end
                else
                    break
                end
            end
        end
    end
end)

RegisterNetEvent('tomic_territories:createTerritory')
AddEventHandler('tomic_territories:createTerritory', function()
    local input = lib.inputDialog('Create a new territory', {
        { type = 'input', label = 'Territory Name' },
        { type = 'input', label = 'Radius' },
        { type = 'select', label = 'Territory type', options = {
            { value = 'market', label = 'Market (Buying)' },
            { value = 'dealer', label = 'Market (Selling)' },
            { value = 'default', label = 'Default (Stash Only)' },
        } },
    })

    if not input then
        return ESX.ShowNotification('Something went wrong!')
    end

    if not checkInput({ input[1], input[3] }, 'any', true) or not checkInput(input[2], 'number') then
        return ESX.ShowNotification('You must fill all fields correctly!')
    end

    TriggerServerEvent('tomic_territories:createTerritory', {
        id = #territories + 1,
        name = input[1],
        type = input[3],
        owner = 'noone',
        label = 'NoOne',
        radius = input[2],
        isTaking = false,
        progress = 0,
        isCooldown = false,
        coords = GetEntityCoords(PlayerPedId()),
    })
end)

RegisterNetEvent('tomic_territories:deleteTerritory')
AddEventHandler('tomic_territories:deleteTerritory', function()
    local input = lib.inputDialog('Delete a territory', {
        { type = 'input', label = 'Territory name' },
    })

    if not input then
        return ESX.ShowNotification('Something went wrong!')
    end

    if not checkInput(input[1], 'any', true) then
        return ESX.ShowNotification('You must fill all fields correctly!')
    end

    TriggerServerEvent('tomic_territories:deleteTerritory', input[1])
end)

CreateThread(function()
    Wait(1000) -- Wait for everything to load before displaying the markers...
    local showUI
    while true do
        Wait(0)
        local sleepThread = true
        local playerCoords = GetEntityCoords(PlayerPedId())
        for k, v in pairs(territories) do
            local coords = vec3(v.coords.x, v.coords.y, v.coords.z)
            local distance = #(playerCoords - coords)
            if PlayerData.job and shared.gangs[PlayerData.job.name] and distance <= tonumber(v.radius) then
                sleepThread = false
                DrawMarker(2, coords, 0.0, 0.0, 0.0, 0.0, 0, 0.0, 0.15, 0.15, 0.15, 200, 0, 50, 230, true, true, 2, true, false, false, false)
                DrawMarker(1, coords, 0.0, 0.0, 0.0, 0.0, 0, 0.0, 0.25, 0.25, 0.02, 255, 255, 255, 255, false, true, 1, true, false, false, false)
                if distance < 1.5 then
                    if IsControlJustPressed(0, 38) then
                        TriggerEvent('tomic_territories:infoMenu', {
                            id = v.id,
                            job = PlayerData.job.name,
                            label = PlayerData.job.label,
                            name = v.name,
                            currentOwner = v.owner,
                            terCoords = vec3(v.coords.x, v.coords.y, v.coords.z),
                            taking = v.isTaking,
                            cooldown = v.isCooldown,
                            type = v.type
                        })
                    end
                    if showUI ~= 0 then
                        lib.showTextUI('[E] - Info | ' .. v.name .. '')
                    elseif showUI ~= 0 and distance > 2.0 then
                        showUI = nil
                        lib.hideTextUI()
                    end
                elseif distance > 2.0 then
                    showUI = nil
                    lib.hideTextUI()
                end
            end
        end
        if sleepThread then Wait(2000) end
    end
end)

RegisterNetEvent('tomic_territories:infoMenu')
AddEventHandler('tomic_territories:infoMenu', function(terData)
    local defaultContext = {
        id = 'infoMenu' .. terData.id,
        title = 'Territory: ' .. terData.name .. ' | 🎲',
        options = {
            {
                title = 'Capture the territory | 🚩',
                event = 'tomic_territories:captureClient',
                metadata = {
                    'Press the button to start capturing territory ' .. terData.name .. '!',
                },
                args = {
                    currentTerritory = terData
                }
            },
            {
                title = 'Territory stash | 📦',
                event = 'tomic_territories:openStash',
                metadata = {
                    'Open the stash from territory ' .. terData.name .. '.',
                },
                args = {
                    currentTerritory = terData
                }
            }
        }
    }

    if terData.type == 'dealer' then
        defaultContext.options[#defaultContext.options + 1] = {
            title = 'Sell Shop | 🌿',
            event = 'tomic_territories:sellList',
            args = {
                data = terData
            }
        }
    elseif terData.type == 'market' then
        defaultContext.options[#defaultContext.options + 1] = {
            title = 'Buy Shop | 🛒',
            event = 'tomic_territories:buyList',
            args = {
                data = terData
            }
        }
    end

    lib.registerContext(defaultContext)
    lib.showContext(defaultContext.id)
end)

RegisterNetEvent('tomic_territories:letCount')
AddEventHandler('tomic_territories:letCount', function(data)
    local input = lib.inputDialog(data.selected.name, { 'Amount' })
    local count = input[1]

    if not input then
        return ESX.ShowNotification('Something went wrong!')
    end

    if not checkInput(count, 'number', true) then
        return ESX.ShowNotification('You must fill all fields correctly!')
    end

    if count < 1 then
        return ESX.ShowNotification('devTomic | Amount cannot be lower than 1!')
    end

    local itemObject = {
        itemKey = data.selected.key,
        itemName = data.selected.name,
        itemCount = count,
        itemWorth = data.selected.worth,
        itemCurrency = data.selected.currency
    }

    if data.selected.type == 'buy' then
        TriggerServerEvent('tomic_territories:buyMarket', itemObject)
    elseif data.selected.type == 'sell' then
        TriggerServerEvent('tomic_territories:sellDealer', itemObject)
    end
end)

RegisterNetEvent('tomic_territories:sellList')
AddEventHandler('tomic_territories:sellList', function(args)
    if PlayerData.job.name ~= args.data.currentOwner then
        return ESX.ShowNotification('devTomic | You do not own this territory!')
    end

    local itemList = {}
    for k, v in pairs(shared.itemsToSell) do
        local item, label, price, black = k, v.label, v.worth, v.black
        itemList[item] = {
            title = v.label,
            description = '💸 | Worth: $' .. v.worth,
            event = 'tomic_territories:letCount',
            args = {
                selected = {
                    name = label,
                    key = item,
                    worth = price,
                    currency = black,
                    type = 'sell'
                },
            }
        }
    end

    lib.registerContext({
        id = 'territorySellList',
        title = 'devTomic | Sellable items',
        options = itemList,
        menu = 'TerritoryDealer'
    })
    lib.showContext('territorySellList')
end)

RegisterNetEvent('tomic_territories:buyList')
AddEventHandler('tomic_territories:buyList', function(terData)
    local buyList = {}
    terData = terData.data
    if PlayerData.job.name ~= terData.currentOwner then
        return ESX.ShowNotification('devTomic | You do not own this territory!')
    end

    for k, v in pairs(shared.itemsToBuy) do
        local item = k
        local label = v.label
        local price = v.worth
        local black = v.black
        buyList[item] = {
            title = v.label,
            description = '💸 | Price: $' .. v.worth,
            event = 'tomic_territories:letCount',
            args = {
                selected = {
                    name = label,
                    key = item,
                    worth = price,
                    currency = black,
                    type = 'buy'
                },
            }
        }
    end

    lib.registerContext({
        id = 'territoryBuyList',
        title = 'devTomic | Buyable items',
        options = buyList,
        menu = 'TerritoryMarket'
    })
    lib.showContext('territoryBuyList')
end)

RegisterNetEvent('tomic_territories:captureClient')
AddEventHandler('tomic_territories:captureClient', function(terData)
    terData = terData.currentTerritory
    if terData.job == terData.currentOwner then
        return ESX.ShowNotification('devTomic | This territory already belongs to you!')
    end

    if terData.taking == true then
        return ESX.ShowNotification('devTomic | Someone is already taking the territory!')
    end

    if terData.cooldown == true then
        return ESX.ShowNotification('devTomic | This territory was recently captured, or capture was attempted!')
    end

    TriggerServerEvent('tomic_territories:captureServer', terData.id, terData.job, terData.label, terData.name, terData.currentOwner)
end)

RegisterNetEvent('tomic_territories:openStash')
AddEventHandler('tomic_territories:openStash', function(terData)
    terData = terData.currentTerritory
    local distance = #(terData.terCoords - GetEntityCoords(PlayerPedId()))

    if PlayerData.job and PlayerData.job.name ~= terData.currentOwner then
        return ESX.ShowNotification('devTomic | You do not own this territory!')
    end

    if distance > 3.0 then
        return ESX.ShowNotification('devTomic | You are too far away from the territory!')
    end

    exports.ox_inventory:openInventory('stash', { id = 'devTomic-Ter[' .. terData.name .. '][' .. terData.id .. ']' })
end)

RegisterNetEvent('tomic_territories:progressBars')
AddEventHandler('tomic_territories:progressBars', function(type)
    if type == 'start' then
        exports.rprogress:Custom({
            Async = false,
            canCancel = false,
            cancelKey = 178,
            x = 0.5,
            y = 0.9,
            From = 0,
            To = 100,
            Duration = shared.capturing * 60000 + 500,
            Radius = 40,
            Stroke = 3,
            Cap = 'round',
            Padding = 0,
            MaxAngle = 360,
            Rotation = 0,
            Width = 300,
            Height = 40,
            ShowTimer = false,
            ShowProgress = true,
            Easing = 'easeLinear',
            Label = 'Capturing...',
            LabelPosition = 'right',
            Color = 'rgba(255, 0, 0, 1.0)',
            BGColor = 'rgba(0, 0, 0, 0.4)',
            ZoneColor = 'rgba(51, 105, 30, 1)',
            DisableControls = {
                Mouse = false,
                Player = false,
                Vehicle = false
            },
            onComplete = function(cancelled)
                exports.rprogress:Stop()
            end
        })
    elseif type == 'stop' then
        exports.rprogress:Stop()
    end
end)

RegisterNetEvent('tomic_territories:captureProgress')
AddEventHandler('tomic_territories:captureProgress', function(terKey, terData)
    local lastTerritory = terKey
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local coords = vec3(terData.coords.x, terData.coords.y, terData.coords.z)
        local distance = #(playerCoords - coords)
        local isDead = IsPedDeadOrDying(playerPed, true)

        if distance < terData.radius then
            if not isDead then
                if terData.isTaking then
                    if progress < 60 then
                        TriggerEvent('tomic_territories:progressBars', 'start')
                        Wait(shared.capturing * 60000 / 60)
                        progress = progress + 1
                    else
                        TriggerEvent('tomic_territories:progressBars', 'stop')
                        TriggerServerEvent('tomic_territories:captureComplete', terData.id, PlayerData.job.name, PlayerData.job.label, terData.owner)
                        progress = 0
                        ESX.ShowNotification('devTomic | You have successfully captured ' .. terData.name .. '!')
                        break
                    end
                else
                    break
                end
            else
                TriggerEvent('tomic_territories:progressBars', 'stop')
                ESX.ShowNotification('devTomic | You died, the capturing progress has stopped!')
                progress = 0
                TriggerServerEvent('tomic_territories:endCapturing', lastTerritory)
                lastTerritory = nil
                break
            end
        else
            TriggerEvent('tomic_territories:progressBars', 'stop')
            ESX.ShowNotification('devTomic | You left the territory, capturing progress has stopped!')
            progress = 0
            TriggerServerEvent('tomic_territories:endCapturing', lastTerritory)
            lastTerritory = nil
            break
        end
    end
end)

RegisterCommand('territories', function(source, args, rawCommand)
    local homePage = {
        id = 'homePage',
        title = 'Territories | 🎲',
        options = {
            {
                title = 'Territory List | 🚩',
                event = 'tomic_territories:listTerritories',
                metadata = {
                    'List of territories.'
                }
            },
            {
                title = 'Info | ❓',
                metadata = {
                    '| Made by Tomić ✅'
                }
            }
        }
    }

    if shared.rankings then
        homePage.options[#homePage.options + 1] = {
            title = 'Rank List | 🏆',
            event = 'tomic_territories:listRankings',
            metadata = {
                'Show the list of every gang and their All-Time points...'
            }
        }
    end

    lib.registerContext(homePage)
    lib.showContext(homePage.id)
end, false)

RegisterNetEvent('tomic_territories:listTerritories')
AddEventHandler('tomic_territories:listTerritories', function()
    local terCollection = {}
    local territoryStatuses = {
        ['isCooldown'] = nil,
        ['isTaking'] = nil
    }

    if territories ~= nil then
        for i = 1, #territories, 1 do
            local info = territories[i]
            if info.isTaking == true then territoryStatuses.isTaking = 'Yes' else territoryStatuses.isTaking = 'No' end
            if info.isCooldown == true then territoryStatuses.isCooldown = 'Yes' else territoryStatuses.isCooldown = 'No' end
            terCollection[i] = {
                title = '💀 | Territory: ' .. info.name,
                description = '🚩 | Owner: ' .. info.label,
                metadata = {
                    'Capturing: ' .. territoryStatuses.isTaking,
                    'Cooldown: ' .. territoryStatuses.isCooldown,
                },
            }
        end

        lib.registerContext({
            id = 'listTerritories',
            title = 'devTomic | Territory List',
            menu = 'homePage',
            options = terCollection,
        })
        lib.showContext('listTerritories')
    end
end)

if shared.rankings then
    RegisterNetEvent('tomic_territories:listRankings')
    AddEventHandler('tomic_territories:listRankings', function()
        ESX.TriggerServerCallback('tomic_territories:fetchPoints', function(pointsCollection)
            local rankCollection = {}
            if territories ~= nil then
                for i = 1, #pointsCollection, 1 do
                    table.sort(pointsCollection, function(a, b) return a.totalPoints > b.totalPoints end)
                    rankCollection[i] = {
                        title = '💀 | Gang: ' .. pointsCollection[i].label,
                        description = '🏆 | Position: ' .. i,
                        metadata = {
                            '⭐ | All-Time Points: ' .. pointsCollection[i].totalPoints,
                            '⭐ | Monthly Points: ' .. pointsCollection[i].monthlyPoints,
                            '⭐ | Weekly Points: ' .. pointsCollection[i].weeklyPoints
                        }
                    }
                end

                lib.registerContext({
                    id = 'listRankings',
                    menu = 'homePage',
                    title = 'devTomic | Rank List',
                    options = rankCollection,
                })
                lib.showContext('listRankings')
            end
        end)
    end)
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        TriggerEvent('tomic_territories:progressBars', 'stop')
        progress = 0
    end
end)
