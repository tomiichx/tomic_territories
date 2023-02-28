local ESX, PlayerData, territories, headerBlips, circleBlips, progress, lastTerritory = nil, {}, {}, {}, {}, 0, nil

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

        table.insert(circleBlips, circleBlip)
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
                if not v.isTaking then
                    break
                end
                for k, p in pairs(shared.gangs) do
                    if v.owner == k then
                        SetBlipColour(circleBlips[i], p.blipColour)
                        Wait(1000)
                        SetBlipColour(circleBlips[i], shared.gangs[job].blipColour)
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('tomic_territories:createTerritory')
AddEventHandler('tomic_territories:createTerritory', function()
    local input = lib.inputDialog(translateMessage('territory_create_input'), {
        { type = 'input', label = translateMessage('territory_create_name') },
        { type = 'input', label = translateMessage('territory_create_radius') },
        { type = 'select', label = translateMessage('territory_create_type'), options = {
            { value = 'market', label = translateMessage('territory_create_type_market') },
            { value = 'dealer', label = translateMessage('territory_create_type_dealer') },
            { value = 'default', label = translateMessage('territory_create_type_default') },
        } },
    })

    if not input then
        return ESX.ShowNotification(translateMessage('something_went_wrong'))
    end

    if not checkInput({ input[1], input[3] }, 'any', true) or not checkInput(input[2], 'number') then
        return ESX.ShowNotification(translateMessage('fill_all_fields_out'))
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
    local input = lib.inputDialog(translateMessage('territory_delete_input'), {
        { type = 'input', label = translateMessage('territory_delete_input_name') },
    })

    if not input then
        return ESX.ShowNotification(translateMessage('something_went_wrong'))
    end

    if not checkInput(input[1], 'any', true) then
        return ESX.ShowNotification(translateMessage('fill_all_fields_out'))
    end

    TriggerServerEvent('tomic_territories:deleteTerritory', input[1])
end)

RegisterNetEvent('tomic_territories:updateUI')
AddEventHandler('tomic_territories:updateUI', function(action, data)
    SendNUIMessage({action = action, data = data })
end)

local function isInTerritory(isDead)
    local playerPed = PlayerPedId()
    local playerCoords, checkDead = GetEntityCoords(playerPed), isDead and true or false
    for k, v in pairs(territories) do
        local coords = vec3(v.coords.x, v.coords.y, v.coords.z)
        local distance = #(playerCoords - coords)
        if distance < tonumber(v.radius) and v.isTaking then
            lastTerritory = v.id
            TriggerServerEvent('tomic_territories:updateAttenders', lastTerritory, PlayerData.identifier, PlayerData.job.name, true, checkDead)
            return true, k
        end
    end
    if lastTerritory then
        TriggerServerEvent('tomic_territories:updateAttenders', lastTerritory, PlayerData.identifier, PlayerData.job.name, false, false)
        lastTerritory = nil
    end
    return false
end

CreateThread(function()
    Wait(2000)
    if PlayerData.job and shared.gangs[PlayerData.job.name] then
        while true do
            Wait(6000)
            isInTerritory(IsEntityDead(PlayerPedId()))
        end
    end
end)

CreateThread(function()
    Wait(1000) -- Wait for everything to load before displaying the markers...
    local showUI = false
    while true do
        local playerCoords, sleepThread = GetEntityCoords(PlayerPedId()), 2000
        for k, v in pairs(territories) do
            local coords = vec3(v.coords.x, v.coords.y, v.coords.z)
            local distance = #(playerCoords - coords)
            if PlayerData.job and shared.gangs[PlayerData.job.name] then
                if distance < tonumber(v.radius) then
                    sleepThread = 0
                    DrawMarker(2, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0, 0.0, 0.15, 0.15, 0.15, 200, 0, 50, 230, false, false, 0, true, nil, nil, false)
                    DrawMarker(1, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0, 0.0, 0.25, 0.25, 0.02, 255, 255, 255, 255, false, false, 0, true, nil, nil, false)
                    if distance < 1.5 then
                        if IsControlJustPressed(0, 38) then
                            TriggerEvent('tomic_territories:infoMenu', { id = v.id, job = PlayerData.job.name, label = PlayerData.job.label, name = v.name, currentOwner = v.owner, terCoords = vec3(v.coords.x, v.coords.y, v.coords.z), isTaking = v.isTaking, isCooldown = v.isCooldown, type = v.type })
                        end
                        if not showUI then
                            showUI = true
                            lib.showTextUI(string.format(translateMessage('territory_show_text'), v.name))
                        end
                    elseif distance > 2.0 and showUI then
                        showUI = false
                        lib.hideTextUI()
                    end
                end
            end
        end
        Wait(sleepThread)
    end
end)

RegisterNetEvent('tomic_territories:infoMenu')
AddEventHandler('tomic_territories:infoMenu', function(terData)
    local defaultContext = {
        id = 'infoMenu' .. terData.id,
        title = string.format(translateMessage('territory_info_menu'), terData.name),
        options = {
            {
                title = translateMessage('territory_info_menu_capture'),
                event = 'tomic_territories:captureClient',
                args = {
                    currentTerritory = terData
                }
            },
            {
                title = translateMessage('territory_info_menu_stash'),
                event = 'tomic_territories:openStash',
                args = {
                    currentTerritory = terData
                }
            }
        }
    }

    if terData.type == 'dealer' then
        defaultContext.options[#defaultContext.options + 1] = {
            title = translateMessage('territory_info_menu_sell'),
            event = 'tomic_territories:sellList',
            args = {
                data = terData
            }
        }
    elseif terData.type == 'market' then
        defaultContext.options[#defaultContext.options + 1] = {
            title = translateMessage('territory_info_menu_buy'),
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
    local input = lib.inputDialog(data.selected.name, { translateMessage('amount') })
    local count = tonumber(input[1])

    if not input then
        return ESX.ShowNotification(translateMessage('something_went_wrong'))
    end

    if not checkInput(count, 'number', true) then
        return ESX.ShowNotification(translateMessage('fill_all_fields_out'))
    end

    if count < 1 then
        return ESX.ShowNotification(translateMessage('incorrect_amount'))
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
        return ESX.ShowNotification(translateMessage('territory_not_owned'))
    end

    local itemList = {}
    for k, v in pairs(shared.itemsToSell) do
        local item, label, price, black = k, v.label, v.worth, v.black
        itemList[item] = {
            title = v.label,
            description = string.format(translateMessage('territory_info_menu_buy_sell_price'), v.worth),
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
        title = translateMessage('territory_info_menu_sell_title'),
        options = itemList,
        menu = 'infoMenu' .. args.data.id,
    })
    lib.showContext('territorySellList')
end)

RegisterNetEvent('tomic_territories:buyList')
AddEventHandler('tomic_territories:buyList', function(terData)
    local buyList, terData = {}, terData.data
    if PlayerData.job.name ~= terData.currentOwner then
        return ESX.ShowNotification(translateMessage('territory_not_owned'))
    end

    for k, v in pairs(shared.itemsToBuy) do
        local item = k
        local label = v.label
        local price = v.worth
        local black = v.black
        buyList[item] = {
            title = v.label,
            description = string.format(translateMessage('territory_info_menu_buy_sell_price'), v.worth),
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
        title = translateMessage('territory_info_menu_buy_title'),
        options = buyList,
        menu = 'infoMenu' .. terData.id,
    })
    lib.showContext('territoryBuyList')
end)

RegisterNetEvent('tomic_territories:captureClient')
AddEventHandler('tomic_territories:captureClient', function(terData)
    local currentTerritory = nil
    for k, v in pairs(territories) do
        if v.id == terData.currentTerritory.id then
            currentTerritory = v
        end
    end

    if PlayerData.job.name == currentTerritory.owner then
        return ESX.ShowNotification(translateMessage('territory_already_owned'))
    end

    if currentTerritory.isTaking then
        return ESX.ShowNotification(translateMessage('capture_in_progress'))
    end

    if currentTerritory.isCooldown then
        return ESX.ShowNotification(translateMessage('territory_on_cooldown'))
    end

    TriggerServerEvent('tomic_territories:captureServer', currentTerritory.id, PlayerData.job.name, PlayerData.job.label, currentTerritory.name, currentTerritory.owner)
end)

RegisterNetEvent('tomic_territories:openStash')
AddEventHandler('tomic_territories:openStash', function(terData)
    terData = terData.currentTerritory
    local distance = #(terData.terCoords - GetEntityCoords(PlayerPedId()))

    if PlayerData.job and PlayerData.job.name ~= terData.currentOwner then
        return ESX.ShowNotification(translateMessage('territory_not_owned'))
    end

    if distance > 3.0 then
        return ESX.ShowNotification(translateMessage('too_far_away'))
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
            Label = translateMessage('territory_capture_progress_bar'),
            LabelPosition = 'right',
            Color = 'rgba(255, 0, 0, 1.0)',
            BGColor = 'rgba(0, 0, 0, 0.4)',
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
                        ESX.ShowNotification(string.format(translateMessage('territory_captured'), terData.name))
                        break
                    end
                else
                    break
                end
            else
                TriggerEvent('tomic_territories:progressBars', 'stop')
                ESX.ShowNotification(translateMessage('territory_cause_death'))
                progress = 0
                TriggerServerEvent('tomic_territories:endCapturing', lastTerritory)
                lastTerritory = nil
                break
            end
        else
            TriggerEvent('tomic_territories:progressBars', 'stop')
            ESX.ShowNotification(translateMessage('territory_cause_distance'))
            progress = 0
            TriggerServerEvent('tomic_territories:endCapturing', lastTerritory)
            lastTerritory = nil
            break
        end
    end
end)

RegisterCommand(shared.playerCommand, function(source, args, rawCommand)
    local homePage = {
        id = 'homePage',
        title = translateMessage('territory_menu_title'),
        options = {
            {
                title = translateMessage('territory_list_title'),
                event = 'tomic_territories:listTerritories',
                metadata = {
                    translateMessage('territory_list_metadata')
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
            title = translateMessage('territory_rankings_title'),
            event = 'tomic_territories:listRankings',
            metadata = {
                translateMessage('territory_rankings_metadata')
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
            territoryStatuses.isTaking = info.isTaking and translateMessage('context_yes') or translateMessage('context_no')
            territoryStatuses.isCooldown = info.isCooldown and translateMessage('context_yes') or translateMessage('context_no')
            terCollection[i] = {
                title = string.format(translateMessage('territory_list_territory_name'), info.name),
                description = string.format(translateMessage('territory_list_territory_owner'), info.label),
                metadata = {
                    string.format(translateMessage('territory_list_territory_capturing'), territoryStatuses.isTaking),
                    string.format(translateMessage('territory_list_territory_cooldown'), territoryStatuses.isCooldown)
                },
            }
        end

        lib.registerContext({
            id = 'listTerritories',
            title = translateMessage('territory_menu_context_title'),
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
                        title = string.format(translateMessage('territory_rankings_gang'), pointsCollection[i].label),
                        description = string.format(translateMessage('territory_rankings_position'), i),
                        metadata = {
                            string.format(translateMessage('territory_rankings_all_time'), pointsCollection[i].totalPoints),
                            string.format(translateMessage('territory_rankings_monthly'), pointsCollection[i].monthlyPoints),
                            string.format(translateMessage('territory_rankings_weekly'), pointsCollection[i].weeklyPoints)
                        }
                    }
                end

                lib.registerContext({
                    id = 'listRankings',
                    menu = 'homePage',
                    title = translateMessage('territory_rankings_menu_context_title'),
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