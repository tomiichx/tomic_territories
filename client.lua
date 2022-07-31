
local ESX, PlayerData, territoriesClient, Blips, iBlips, progress, isTaking = nil, {}, {}, {}, {}, 0, false

CreateThread(function()
    while ESX == nil do TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end) Wait(250) end
    while ESX.GetPlayerData().job == nil do Wait(250) end
    PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

CreateThread(function()
    ESX.TriggerServerCallback('tomic_territories:getTerritories', function(territories) 
        territoriesClient = territories
    end)
    Wait(1000)
    createBlips()
end)

RegisterNetEvent('tomic_territories:updateTerritories')
AddEventHandler('tomic_territories:updateTerritories', function(territories)
    territoriesClient = territories
    for i, blipovi in pairs(iBlips) do
        RemoveBlip(blipovi)
    end
    iBlips = {}
    for i, blipovix in pairs(Blips) do
        RemoveBlip(blipovix)
    end
    Blips = {}
    Wait(1000)
    createBlips()
end)

RegisterNetEvent('tomic_territories:blipblink')
AddEventHandler('tomic_territories:blipblink', function(id, job, label)
    while true do
        Wait(1000)
        for i, v in pairs(territoriesClient) do
            if v.id == id then
                if v.isTaking then
                    for k, p in pairs(shared.gangs) do
                        if v.owner == k then
                            SetBlipColour(iBlips[i], p.blipboja)
                            Wait(1000)
                            SetBlipColour(iBlips[i], shared.gangs[job].blipboja)
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
    local player = PlayerPedId()
    local coords = GetEntityCoords(player)
    local input = lib.inputDialog('Create a new territory', {
        { type = 'input', label = 'Territory Name' },
        { type = 'input', label = 'Radius' },
        { type = 'select', label = 'Territory type', options = {
            { value = 'market', label = 'Market (Buying)' },
            { value = 'dealer', label = 'Market (Selling)' },
            { value = 'default', label = 'Default (Stash Only)' },
        }},
    })
    if input then
        if input[1] ~= nil and tonumber(input[2]) ~= nil and input[3] ~= nil then
            local name = input[1]
            local radius = input[2]
            local type = input[3]
            local territoryInfo = {
                id = #territoriesClient +1,
                name = name,
                type = type,
                owner = 'noone',
                label = 'NoOne',
                radius = radius,
                isTaking = false,
                progress = 0,
                cooldown = false,
                coords = coords,
            }
            TriggerServerEvent('tomic_territories:createTerritory', territoryInfo)
        else
            ESX.ShowNotification('You must fill all fields correctly!')
        end
    else
        ESX.ShowNotification('You cancelled the creation of a new territory.')
    end
end)

RegisterNetEvent('tomic_territories:deleteTerritory')
AddEventHandler('tomic_territories:deleteTerritory', function()
    local player = PlayerPedId()
    local coords = GetEntityCoords(player)
    local input = lib.inputDialog('Delete a territory', {
        { type = 'input', label = 'Territory name' },
    })
    if input then
        if input[1] ~= nil then
            local name = input[1]
            TriggerServerEvent('tomic_territories:deleteTerritory', name)
        else
            ESX.ShowNotification('You must fill all fields correctly!')
        end
    else
        ESX.ShowNotification('You cancelled the creation of a new territory.')
    end
end)

createBlips = function()
    for i = 1, #territoriesClient, 1 do
        local info = territoriesClient[i]
        vlasnik = info.owner
        label = info.label
        pocetnoslovo = string.upper(string.sub(vlasnik, 1, 1))
        ostatak = string.sub(vlasnik, 2)
        local blipovi = AddBlipForCoord(info.coords.x, info.coords.y, info.coords.z) -- T1
        SetBlipSprite(blipovi, 373)
        SetBlipDisplay(blipovi, 8)
        SetBlipScale(blipovi, 4.0)
        for k, v in pairs(shared.gangs) do
            if info.owner == k then
                SetBlipColour(blipovi, v.blipboja)
            end
        end
        SetBlipAlpha(blipovi, 100)
        SetBlipAsShortRange(blipovi, true)
        table.insert(iBlips, blipovi)
        -- Kostur Blipovi // Skull Blips
        local blipovix = AddBlipForCoord(info.coords.x, info.coords.y, info.coords.z + 15) -- T1
        SetBlipSprite(blipovix, 310)
        SetBlipDisplay(blipovix, 4)
        BeginTextCommandSetBlipName('STRING')
        if info.owner ~= 'noone' then
            AddTextComponentString('Territory: '..info.name..' | Owner: '..info.label..'')
        else
            AddTextComponentString('Territory: '..info.name..' | Free Territory!')
        end
        EndTextCommandSetBlipName(blipovix)
        SetBlipScale(blipovix, 0.75)
        SetBlipColour(blipovix, 0)
        SetBlipAlpha(blipovix, 250)
        SetBlipAsShortRange(blipovix, true)
        table.insert(Blips, blipovix)
    end
end

-- e.g | PomocniText('Press ~INPUT_CONTEXT~ to do something!')
-- Good way to replace the default ESX Show Help Notification...
PomocniText = function(tekst)
    SetTextComponentFormat('STRING')
    AddTextComponentString(tekst)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

CreateThread(function()
    Wait(1000)
    local showUI
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local spavaj = true
        local playerCoords = GetEntityCoords(playerPed)
        for k, v in pairs(territoriesClient) do
            local coords = vec3(v.coords.x, v.coords.y, v.coords.z)
            local coordsx = vec3(v.coords.x, v.coords.y, v.coords.z-17.0)
            local distance = #(playerCoords - coords)
            if PlayerData.job and shared.gangs[PlayerData.job.name] then
                if distance < tonumber(v.radius) then
                    spavaj = false
                    DrawMarker(2, coords, 0.0, 0.0, 0.0, 0.0, 0, 0.0, 0.15, 0.15, 0.15, 200, 0, 50, 230, true, true, 2, true, false, false, false)
                    DrawMarker(1, coords, 0.0, 0.0, 0.0, 0.0, 0, 0.0, 0.25, 0.25, 0.02, 255, 255, 255, 255, false, true, 1, true, false, false, false)
                    territorydata = {
                        id = v.id,
                        job = PlayerData.job.name,
                        label = PlayerData.job.label,
                        name = v.name,
                        currentOwner = v.owner,
                        crds = vec3(v.coords.x, v.coords.y, v.coords.z),
                        taking = v.isTaking,
                        cooldown = v.cooldown,
                        type = v.type,
                        spawnano = v.spawnano,
                        radi = v.radi
                    }
                    if distance < 1.5 then
                        if IsControlJustPressed(0, 38) then
                            TriggerEvent('tomic_territories:infoMeni', territorydata)
                        end
                        if showUI ~= 0 then
                            lib.showTextUI('[E] - Info | '..territorydata.name..'')
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
        end
        if spavaj then Wait(1337) end
    end
end)

RegisterNetEvent('tomic_territories:infoMeni')
AddEventHandler('tomic_territories:infoMeni', function(territorydata)
    if territorydata.type == 'dealer' then
        lib.registerContext({
            id = 'infoMeniDealer',
            title = 'Territory: '..territorydata.name..' | 🎲',
            options = {
                {
                    title = 'Capture the territory | 🚩',
                    event = 'tomic_territories:pokreni',
                    metadata = {
                        'Press the button to start capturing territory '..territorydata.name..'!',
                    },
                    args = {
                        x = territorydata
                    }
                },
                {
                    title = 'Territory stash | 📦',
                    event = 'tomic_territories:openStash',
                    metadata = {
                        'Open the stash from territory '..territorydata.name..'.',
                    },
                    args = {
                        x = territorydata
                    }
                },
                {
                    title = 'Sell Shop | 🌿',
                    event = 'tomic_territories:listaItema',
                    args = {
                        data = territorydata
                    }
                },
            }
        })
        lib.showContext('infoMeniDealer')
    elseif territorydata.type == 'market' then
        lib.registerContext({
            id = 'infoMeniMarket',
            title = 'Territory: '..territorydata.name..' | 🎲',
            options = {
                {
                    title = 'Capture the territory | 🚩',
                    event = 'tomic_territories:pokreni',
                    metadata = {
                        'Press the button to start capturing territory '..territorydata.name..'!',
                    },
                    args = {
                        x = territorydata
                    }
                },
                {
                    title = 'Territory stash | 📦',
                    event = 'tomic_territories:openStash',
                    metadata = {
                        'Open the stash from territory '..territorydata.name..'.',
                    },
                    args = {
                        x = territorydata
                    }
                },
                {
                    title = 'Buy Shop | 🛒',
                    event = 'tomic_territories:BuyList',
                    args = {
                        data = territorydata
                    }
                },
            }
        })
        lib.showContext('infoMeniMarket')
        -- Work in progress!
    -- elseif territorydata.type == 'drugs' then
    --     lib.registerContext({
    --         id = 'infoMeniDroga',
    --         title = 'Territory: '..territorydata.name..' | 🎲',
    --         options = {
    --             {
    --                 title = 'Capture the territory | 🚩',
    --                 event = 'tomic_territories:pokreni',
    --                 metadata = {
    --                     'Press the button to start capturing territory '..territorydata.name..'!',
    --                 },
    --                 args = {
    --                     x = territorydata
    --                 }
    --             },
    --             {
    --                 title = 'Territory stash | 📦',
    --                 event = 'tomic_territories:openStash',
    --                 metadata = {
    --                     'Open the stash from territory '..territorydata.name..'.',
    --                 },
    --                 args = {
    --                     x = territorydata
    --                 }
    --             },
    --             {
    --                 title = 'Burrito Meth | 🛒',
    --                 event = 'tomic_territories:burritoMeth',
    --                 args = {
    --                     data = territorydata
    --                 }
    --             },
    --         }
    --     })
    --     lib.showContext('infoMeniDroga')
    -- Work in progress!
    elseif territorydata.type == 'default' then
        lib.registerContext({
            id = 'infoMeni',
            title = 'Territory: '..territorydata.name..' | 🎲',
            options = {
                {
                    title = 'Capture the territory | 🚩',
                    event = 'tomic_territories:pokreni',
                    metadata = {
                        'Press the button to start capturing territory '..territorydata.name..'!',
                    },
                    args = {
                        x = territorydata
                    }
                },
                {
                    title = 'Territory stash | 📦',
                    event = 'tomic_territories:openStash',
                    metadata = {
                        'Open the stash from territory '..territorydata.name..'.',
                    },
                    args = {
                        x = territorydata
                    }
                },
            }
        })
        lib.showContext('infoMeni')
    end
end)

-- Work in progress!
RegisterNetEvent('tomic_territories:burritoMeth')
AddEventHandler('tomic_territories:burritoMeth', function(data)
    infoX = data
    if data.data.spawnano == false then
        local spawnpoint = ESX.Game.IsSpawnPointClear(data.data.crds, 5.0)
        local closestPlayer, closestPlayerDistance = ESX.Game.GetClosestPlayer()
        local vozilo
        if spawnpoint then
            if closestPlayer == -1 or closestPlayerDistance > 3.0 then
                ESX.ShowNotification('devTomic | There is no one close. You need one more person to start the mission!')
            else
                ESX.Game.SpawnVehicle('burrito', data.data.crds-4.0, 50.0, function(vehicle)
                    vozilo = vehicle
                    ESX.Game.SetVehicleProperties(vozilo, {
                        plate = 'METH',
                        dirtLevel = 0.0,
                        fuelLevel = 100.0,
                        color1 = 0,
                        color2 = 2,
                        modArmor = 4
                    })
                end)
                local radi = data.data.radi
                local showUIx
                while not radi do
                    Wait(0)
                    local closestVeh, distance = ESX.Game.GetClosestVehicle()
                    if distance < 7 then
                        if IsControlJustPressed(0, 38) then
                            TaskWarpPedIntoVehicle(PlayerPedId(), vozilo, 1)
                            TriggerServerEvent('tomic_territories:MethServer', infoX, vozilo)
                            break
                        end
                        if showUIx ~= 0 then
                            lib.showTextUI('[E] - To Enter!')
                        elseif showUIx ~= 0 and IsPedInAnyVehicle(PlayerPedId(), false) then
                            showUIx = nil
                            lib.hideTextUI()
                        end
                    elseif IsPedInAnyVehicle(PlayerPedId(), false) then
                        showUIx = nil
                        lib.hideTextUI()
                    end
                end
            end
        else
            ESX.ShowNotification('devTomic | Spawnpoint is not clear!')
        end
    else
        ESX.ShowNotification('devTomic | Mission has already been started!')
    end
end)

-- Work in progress!
RegisterNetEvent('tomic_territories:MethClient')
AddEventHandler('tomic_territories:MethClient', function(voziloInfo)
    -- local gas = 0
    -- while IsEntityInAir(voziloInfo) and gas < 60 do
    --     Wait(1000)
    --     gas = gas + 1
    --     print(gas)
    -- end

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
        Label = 'Cooking meth...',
        LabelPosition = 'left',
        Color = 'rgba(255, 255, 255, 1.0)',
        BGColor = 'rgba(0, 0, 0, 0.4)',
        ZoneColor = 'rgba(51, 105, 30, 1)',
        DisableControls = {
            Mouse = true,
            Player = true,
            Vehicle = true
        },
        onStart = function()

        end,
        onComplete = function(cancelled)
            while true do
                Wait(2000)
                local uvozilu = IsPedInAnyVehicle(PlayerPedId(), true)
                if cancelled then
                    exports.rprogress:Stop()
                else
                    exports.rprogress:Stop()
                end
            end
        end
    })
end)

RegisterNetEvent('tomic_territories:listaItema')
AddEventHandler('tomic_territories:listaItema', function(data)
    local itemList = {}
    if PlayerData.job.name == data.data.currentOwner then
        for k, v in pairs(shared.itemsToSell) do
            local currentItemInfo = shared.itemsToSell
            local item = k
            local label = v.label
            local price = v.worth
            local black = v.black
            itemList[item] = {
                title = v.label,
                description = '💸 | Worth: $'..v.worth,
                event = 'tomic_territories:letCount',
                args = {
                    selected = {
                        name = label,
                        key = item,
                        worth = price,
                        moneytype = black
                    },
                    datax = data
                }
            }
        end
        lib.registerContext({
            id = 'itemListaX',
            title = 'devTomic | Sellable items',
            options = itemList,
            menu = 'infoMeniDealer'
        })
        lib.showContext('itemListaX')
    else
        ESX.ShowNotification('devTomic | You do not own this territory!')
    end
end)

RegisterNetEvent('tomic_territories:letCount')
AddEventHandler('tomic_territories:letCount', function(selected, datax)
    local input = lib.inputDialog(selected.selected.name, {'Amount'})
    if input then
        local count = tonumber(input[1])
        if count < 1 then
            return ESX.ShowNotification('devTomic | Amount cannot be lower than 1!')
        else
            allInfo = {
                i = selected.selected.key,
                ime = selected.selected.name,
                xCount = count,
                xWorth = selected.selected.worth,
                xType = selected.selected.moneytype
            }
            TriggerServerEvent('tomic_territories:sellDealer', allInfo)
        end
    end
end)

RegisterNetEvent('tomic_territories:BuyList')
AddEventHandler('tomic_territories:BuyList', function(data)
    local buyList = {}
    if PlayerData.job.name == data.data.currentOwner then
        for k, v in pairs(shared.itemsToBuy) do
            local item = k
            local label = v.label
            local price = v.worth
            local black = v.black
            buyList[item] = {
                title = v.label,
                description = '💸 | Price: $'..v.worth,
                event = 'tomic_territories:buyCount',
                args = {
                    selected = {
                        name = label,
                        key = item,
                        worth = price,
                        moneytype = black
                    },
                    datax = data
                }
            }
        end
        lib.registerContext({
            id = 'buyList',
            title = 'devTomic | Buyable items',
            options = buyList,
            menu = 'infoMeniMarket'
        })
        lib.showContext('buyList')
    else
        ESX.ShowNotification('devTomic | You do not own this territory!')
    end
end)

RegisterNetEvent('tomic_territories:buyCount')
AddEventHandler('tomic_territories:buyCount', function(selected, datax)
    local input = lib.inputDialog(selected.selected.name, {'Amount'})
    if input then
        local count = tonumber(input[1])
        if count < 1 then
            return ESX.ShowNotification('devTomic | Amount cannot be lower than 1!')
        else
            allInfo = {
                i = selected.selected.key,
                ime = selected.selected.name,
                xCount = count,
                xWorth = selected.selected.worth,
                xType = selected.selected.moneytype
            }
            TriggerServerEvent('tomic_territories:buyMarket', allInfo)
        end
    end
end)

RegisterNetEvent('tomic_territories:pokreni')
AddEventHandler('tomic_territories:pokreni', function(x)
    if territorydata.job ~= territorydata.currentOwner then
        if territorydata.taking == false then
            if territorydata.cooldown == false then
                TriggerServerEvent('tomic_territories:capturestart', territorydata.id, territorydata.job, territorydata.label, territorydata.name, territorydata.currentOwner)
            else
                ESX.ShowNotification('devTomic | This territory was recently captured, or capture was attempted!')
            end
        else
            ESX.ShowNotification('devTomic | Someone is already taking the territory!')
        end
    else
        ESX.ShowNotification('devTomic | This territory already belongs to you!')
    end
end)

RegisterNetEvent('tomic_territories:openStash')
AddEventHandler('tomic_territories:openStash', function(x)
    local igrac = PlayerPedId()
    local kordinateigraca = GetEntityCoords(igrac)
    local distanca = #(territorydata.crds - kordinateigraca)
    if distanca < 5.0 then
        if PlayerData.job and PlayerData.job.name == territorydata.currentOwner then
            exports.ox_inventory:openInventory('stash', {id = 'devTomic-Ter['..territorydata.name..']['..territorydata.id..']'})
        else
            ESX.ShowNotification('devTomic | You do not own this territory!')
        end
    end
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
            onStart = function()
            end,
            onComplete = function(cancelled)
                exports.rprogress:Stop()
            end
        }
    )
    elseif type == 'stop' then
        exports.rprogress:Stop()
    end
end)

RegisterNetEvent('tomic_territories:captureprogress')
AddEventHandler('tomic_territories:captureprogress', function(datakey, data)
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local coords = vec3(data.coords.x, data.coords.y, data.coords.z)
        local distance = #(playerCoords - coords)
        local isDead = IsPedDeadOrDying(playerPed, true)
        lastTerritory = datakey
        prekidanje = data.radius + 1.0
        if distance < prekidanje then
            if not isDead then
                if data.isTaking == true then
                    if progress < 60 then
                        TriggerEvent('tomic_territories:progressBars', 'start')
                        Wait(shared.capturing * 60000 / 60)
                        progress = progress + 1
                    else
                        TriggerEvent('tomic_territories:progressBars', 'stop')
                        job = PlayerData.job.name
                        label = PlayerData.job.label
                        prvivlasnik = data.owner
                        TriggerServerEvent('tomic_territories:capturecomplete', data.id, job, label, prvivlasnik)
                        progress = 0
                        TriggerEvent('tomic_territories:progressBars', 'stop')
                        ESX.ShowNotification('devTomic | You have successfully captured '..data.name..'!')
                        TriggerEvent('tomic_territories:progressBars', 'stop')
                        break
                    end
                else
                    break
                end
            else
                TriggerEvent('tomic_territories:progressBars', 'stop')
                ESX.ShowNotification('devTomic | You died, the capturing progress has stopped!')
                progress = 0
                TriggerServerEvent('tomic_territories:captureend', lastTerritory)
                lastTerritory = nil
                break
            end
        else
            TriggerEvent('tomic_territories:progressBars', 'stop')
            ESX.ShowNotification('devTomic | You left the territory, capturing progress has stopped!')
            progress = 0
            TriggerServerEvent('tomic_territories:captureend', lastTerritory)
            lastTerritory = nil
            break
        end
    end
end)

RegisterCommand('territories', function()
    if shared.rankings then
        lib.registerContext({
            id = 'prvastrana',
            title = 'Teritorije Meni | 🎲',
            options = {
                {
                    title = 'Territory List | 🚩',
                    event = 'tomic_territories:drugastrana',
                    metadata = {
                        'List of territories.',
                    },
                },
                {
                    title = 'Rank List | 🏆',
                    event = 'tomic_territories:trecastrana',
                    metadata = {
                        'Show the list of every gang and their All-Time points...',
                    },
                },
                {
                    title = 'Info | ❓',
                    metadata = {
                        '| Made by Tomić ✅',
                    },
                },
            }
        })
    else
        lib.registerContext({
            id = 'prvastrana',
            title = 'Teritorije Meni | 🎲',
            options = {
                {
                    title = 'Territory List | 🚩',
                    event = 'tomic_territories:drugastrana',
                    metadata = {
                        'List of territories.',
                    },
                },
                {
                    title = 'Info | ❓',
                    metadata = {
                        '| Made by Tomić ✅',
                    },
                },
            }
        })
    end
    lib.showContext('prvastrana')
end)

RegisterNetEvent('tomic_territories:drugastrana')
AddEventHandler('tomic_territories:drugastrana', function(args)
    local libTer = {}
    if territoriesClient ~= nil then
        for i = 1, #territoriesClient, 1 do
            local info = territoriesClient[i]
            local ter = vec3(info.coords.x, info.coords.y, info.coords.z)
            local pr = nil
            local cd = nil
            local vl = info.owner
            local ps = string.upper(string.sub(vl, 1, 1))
            local os = string.sub(vl, 2)
            if info.isTaking == true then pr = 'Yes' else pr = 'No' end
            if info.cooldown == true then cd = 'Yes' else cd = 'No' end
            libTer[i] = {
                title = '💀 | Territory: '..info.name,
                description = '🚩 | Owner: '..info.label,
                metadata = {
                    'Capturing: '..pr,
                    'Cooldown: '..cd,
                },
            }
        end
        lib.registerContext({
            id = 'drugastrana',
            title = 'devTomic | Territory List',
            menu = 'prvastrana',
            options = libTer,
        })
        lib.showContext('drugastrana')
    end
end)

RegisterNetEvent('tomic_territories:trecastrana')
AddEventHandler('tomic_territories:trecastrana', function(args)
    ESX.TriggerServerCallback('tomic_territories:povucipoene', function(lista)
        local trTabela = {}
        if territoriesClient ~= nil then
            for i = 1, #lista, 1 do
                table.sort(lista, function(a, b) return a.poeni > b.poeni end)
                trTabela[i] = {
                    title = '💀 | Gang: '..lista[i].label,
                    description = '🏆 | Position: '..i,
                    metadata = {
                        '⭐ | All-Time Points: '..lista[i].poeni,
                        '⭐ | Monthly Points: '..lista[i].mespoeni,
                        '⭐ | Weekly Points: '..lista[i].nedpoeni
                    }
                }
            end
            lib.registerContext({
                id = 'trecastrana',
                menu = 'prvastrana',
                title = 'devTomic | Rank List',
                options = trTabela,
            })
            lib.showContext('trecastrana')
        end
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
	if resourceName == GetCurrentResourceName() then 
		TriggerEvent('tomic_territories:progressBars', 'stop')
	end
end)