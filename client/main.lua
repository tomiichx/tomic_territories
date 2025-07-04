local ESX = {}
local PlayerData = {}
local territoryCollection = {}
local headerBlips, circleBlips = {}, {}
local progress = 0
local lastTerritory = nil
local showUI = false

CreateThread(function()
    ESX = exports["es_extended"]:getSharedObject()
    PlayerData = ESX.GetPlayerData()

    territoryCollection = lib.callback.await("tomic_territories:getTerritories", 5000)

    if not territoryCollection then
        lib.print.error(Translate("something_went_wrong"))
        return
    end

    CreateBlips()
end)

RegisterNetEvent("esx:playerLoaded", function(playerInfo)
    PlayerData = playerInfo
end)

local monitoringThread = nil
RegisterNetEvent("esx:setJob", function(newJob)
    PlayerData.job = newJob

    if monitoringThread then
        monitoringThread = nil
    end

    if PlayerData.job and shared.gangs[PlayerData.job.name] then
        monitoringThread = CreateThread(function()
            while monitoringThread do
                Wait(5000)
                MonitorAttendance()
            end
        end)
    end
end)

local TYPE_ERROR <const> = "error"
local TYPE_SUCCESS <const> = "success"
local TYPE_INFO <const> = "info"

local validTypes <const> = {
    [TYPE_SUCCESS] = true,
    [TYPE_ERROR] = true,
    [TYPE_INFO] = true
}

function ShowNotification(message, nType)
    if not message or message:match("^%s*$") then return end

    if not validTypes[nType] then nType = TYPE_INFO end

    lib.notify({
        title = Translate("territory_menu_title"),
        description = message,
        type = nType,
        position = "top",
        duration = 5000
    })
end

function CreateBlips()
    local renderBlips = (shared.gangOnlyBlips and PlayerData.job and shared.gangs[PlayerData.job.name]) or
        not shared.gangOnlyBlips
    if not renderBlips then return end

    for i = 1, #territoryCollection do
        local currentTerritory = territoryCollection[i]
        local circleBlip = AddBlipForCoord(currentTerritory.coords.x, currentTerritory.coords.y,
            currentTerritory.coords.z)
        SetBlipSprite(circleBlip, 373)
        SetBlipDisplay(circleBlip, 8)
        SetBlipScale(circleBlip, 4.0)
        SetBlipAlpha(circleBlip, 100)
        SetBlipAsShortRange(circleBlip, true)
        for k, v in pairs(shared.gangs) do
            if currentTerritory.owner == k then
                SetBlipColour(circleBlip, v.blipColour)
                break
            end
        end

        local headerBlip = AddBlipForCoord(
            currentTerritory.coords.x,
            currentTerritory.coords.y,
            currentTerritory.coords.z + 15
        )

        SetBlipSprite(headerBlip, 310)
        SetBlipDisplay(headerBlip, 4)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(
            Translate("territory_blip_occupied"):format(
                currentTerritory.name,
                currentTerritory.owner ~= "noone" and currentTerritory.label or Translate("territory_blip_unoccupied")
            )
        )
        EndTextCommandSetBlipName(headerBlip)
        SetBlipScale(headerBlip, 0.75)
        SetBlipColour(headerBlip, 0)
        SetBlipAlpha(headerBlip, 250)
        SetBlipAsShortRange(headerBlip, true)

        table.insert(circleBlips, circleBlip)
        table.insert(headerBlips, headerBlip)
    end
end

RegisterNetEvent("tomic_territories:updateTerritories", function(serverData)
    territoryCollection = serverData

    for _, blip in pairs(circleBlips) do RemoveBlip(blip) end
    for _, blip in pairs(headerBlips) do RemoveBlip(blip) end

    circleBlips, headerBlips = {}, {}

    Wait(500)

    CreateBlips()
end)

RegisterNetEvent("tomic_territories:updateBlips", function(id, job)
    while true do
        Wait(1000)
        if not territoryCollection[id].isTaking then break end
        for k, p in pairs(shared.gangs) do
            if territoryCollection[id].owner == k then
                SetBlipColour(circleBlips[id], p.blipColour)
                Wait(1000)
                SetBlipColour(circleBlips[id], shared.gangs[job].blipColour)
            end
        end
    end
end)

RegisterNetEvent("tomic_territories:createTerritory", function()
    local input = lib.inputDialog(Translate("territory_create_input"), {
        { type = "input", label = Translate("territory_create_name") },
        { type = "input", label = Translate("territory_create_radius") },
        {
            type = "select",
            label = Translate("territory_create_type"),
            options = {
                { value = "market",  label = Translate("territory_create_type_market") },
                { value = "dealer",  label = Translate("territory_create_type_dealer") },
                { value = "default", label = Translate("territory_create_type_default") },
            }
        },
    })

    if not input then
        ShowNotification(Translate("something_went_wrong"), TYPE_ERROR)
        return
    end

    local name = tostring(input[1])
    local radius = tonumber(input[2]) or 0
    local territoryType = tostring(input[3])

    if not name or name:match("^%s*$") then
        lib.print.error(Translate("fill_all_fields_out"))
        return
    end

    if not radius or radius <= 0 then
        lib.print.error(Translate("fill_all_fields_out"))
        return
    end

    if not territoryType or territoryType:match("^%s*$") then
        lib.print.error(Translate("fill_all_fields_out"))
        return
    end

    TriggerServerEvent("tomic_territories:createTerritory", {
        id = #territoryCollection + 1,
        name = name,
        type = territoryType,
        owner = "noone",
        label = "NoOne",
        radius = radius,
        isTaking = false,
        progress = 0,
        isCooldown = false,
        coords = GetEntityCoords(cache.ped),
    })
end)

RegisterNetEvent("tomic_territories:deleteTerritory", function()
    local input = lib.inputDialog(Translate("territory_delete_input"), {
        { type = "input", label = Translate("territory_delete_input_name") },
    })

    if not input then
        ShowNotification(Translate("something_went_wrong"), TYPE_ERROR)
        return
    end

    local name = tostring(input[1])

    if not name or name:match("^%s*$") then
        lib.print.error(Translate("fill_all_fields_out"))
        return
    end

    TriggerServerEvent("tomic_territories:deleteTerritory", name)
end)

RegisterNetEvent("tomic_territories:updateUI", function(action, data)
    SendNUIMessage({ action = action, data = data })
end)

function MonitorAttendance()
    local playerPed = cache.ped
    local playerCoords = GetEntityCoords(playerPed)

    for _, v in pairs(territoryCollection) do
        local territoryCoords = vec3(v.coords.x, v.coords.y, v.coords.z)
        local playerTerritoryDistance = #(playerCoords - territoryCoords)
        if playerTerritoryDistance < tonumber(v.radius) and v.isTaking then
            lastTerritory = v.id
            TriggerServerEvent(
                "tomic_territories:updateAttenders",
                lastTerritory,
                PlayerData.identifier,
                PlayerData.job.name,
                true,
                LocalPlayer.state.isDead or LocalPlayer.state.dead
            )
            return true
        end
    end

    if lastTerritory then
        TriggerServerEvent(
            "tomic_territories:updateAttenders",
            lastTerritory,
            PlayerData.identifier,
            PlayerData.job.name,
            false,
            false
        )
        lastTerritory = nil
    end

    return false
end

CreateThread(function()
    Wait(1000)

    while true do
        local playerCoords = GetEntityCoords(cache.ped)
        local sleepThread = 2000

        if not (PlayerData.job and shared.gangs[PlayerData.job.name]) then
            Wait(sleepThread)
            goto continue
        end

        for _, v in pairs(territoryCollection) do
            local territoryCoords = vec3(v.coords.x, v.coords.y, v.coords.z)
            local playerTerritoryDistance = #(playerCoords - territoryCoords)

            if playerTerritoryDistance >= tonumber(v.radius) then
                goto inner_continue
            end

            sleepThread = 0

            DrawMarker(2, territoryCoords.x, territoryCoords.y, territoryCoords.z, 0.0, 0.0, 0.0, 0.0, 0, 0.0,
                0.15, 0.15, 0.15, 200, 0, 50, 230, false, false, 0, true, nil, nil, false)
            DrawMarker(1, territoryCoords.x, territoryCoords.y, territoryCoords.z, 0.0, 0.0, 0.0, 0.0, 0, 0.0,
                0.25, 0.25, 0.02, 255, 255, 255, 255, false, false, 0, true, nil, nil, false)

            if playerTerritoryDistance < 1.5 then
                if IsControlJustPressed(0, 38) then
                    DisplayMenu({
                        id = v.id,
                        job = PlayerData.job.name,
                        label = PlayerData.job.label,
                        name = v.name,
                        currentOwner = v.owner,
                        terCoords = vec3(v.coords.x, v.coords.y, v.coords.z),
                        isTaking = v.isTaking,
                        isCooldown = v.isCooldown,
                        type = v.type
                    })
                end

                if not showUI then
                    showUI = true
                    lib.showTextUI(Translate("territory_show_text"):format(v.name))
                end

                goto inner_continue
            end

            if playerTerritoryDistance > 2.0 and showUI then
                showUI = false
                lib.hideTextUI()
            end

            ::inner_continue::
        end

        ::continue::
        Wait(sleepThread)
    end
end)

function DisplayMenu(terData)
    local defaultContext = {
        id = "infoMenu" .. terData.id,
        title = Translate("territory_info_menu"):format(terData.name),
        options = {
            {
                title = Translate("territory_info_menu_capture"),
                event = "tomic_territories:captureClient",
                args = {
                    currentTerritory = terData
                }
            },
            {
                title = Translate("territory_info_menu_stash"),
                event = "tomic_territories:openStash",
                args = {
                    currentTerritory = terData
                }
            }
        }
    }

    local terType = {
        ["dealer"] = {
            title = Translate("territory_info_menu_sell"),
            event = "tomic_territories:sellList",
            args = {
                data = terData
            }
        },
        ["market"] = {
            title = Translate("territory_info_menu_buy"),
            event = "tomic_territories:buyList",
            args = {
                data = terData
            }
        }
    }

    table.insert(defaultContext.options, terType[terData.type])

    lib.registerContext(defaultContext)
    lib.showContext(defaultContext.id)
end

RegisterNetEvent("tomic_territories:letCount", function(data)
    local input = lib.inputDialog(data.selected.name, { Translate("amount") })

    if not input or #input == 0 then
        ShowNotification(Translate("something_went_wrong"), TYPE_ERROR)
        return
    end

    local count = tonumber(input[1]) or 0

    if count <= 0 then
        ShowNotification(Translate("fill_all_fields_out"), TYPE_ERROR)
        return
    end

    local itemObject = {
        itemKey = data.selected.key,
        itemName = data.selected.name,
        itemCount = count,
        itemWorth = data.selected.worth,
        itemCurrency = data.selected.currency
    }

    TriggerServerEvent("tomic_territories:marketHandler", itemObject, data.selected.type)
end)

RegisterNetEvent("tomic_territories:sellList", function(args)
    if PlayerData.job.name ~= args.data.currentOwner then
        ShowNotification(Translate("territory_not_owned"), TYPE_ERROR)
        return
    end

    local itemList = {}
    for k, v in pairs(shared.itemsToSell) do
        local item, label, price, black = k, v.label, v.worth, v.black
        itemList[item] = {
            title = v.label,
            description = Translate("territory_info_menu_buy_sell_price"):format(v.worth),
            event = "tomic_territories:letCount",
            args = {
                selected = {
                    name = label,
                    key = item,
                    worth = price,
                    currency = black,
                    type = "sell"
                },
            }
        }
    end

    lib.registerContext({
        id = "territorySellList",
        title = Translate("territory_info_menu_sell_title"),
        options = itemList,
        menu = "infoMenu" .. args.data.id,
    })
    lib.showContext("territorySellList")
end)

RegisterNetEvent("tomic_territories:buyList", function(terData)
    local buyList, territoryData = {}, terData.data
    if PlayerData.job.name ~= territoryData.currentOwner then
        ShowNotification(Translate("territory_not_owned"), TYPE_ERROR)
        return
    end

    for k, v in pairs(shared.itemsToBuy) do
        local item = k
        local label = v.label
        local price = v.worth
        local black = v.black
        buyList[item] = {
            title = v.label,
            description = Translate("territory_info_menu_buy_sell_price"):format(v.worth),
            event = "tomic_territories:letCount",
            args = {
                selected = {
                    name = label,
                    key = item,
                    worth = price,
                    currency = black,
                    type = "buy"
                },
            }
        }
    end

    lib.registerContext({
        id = "territoryBuyList",
        title = Translate("territory_info_menu_buy_title"),
        options = buyList,
        menu = "infoMenu" .. territoryData.id,
    })
    lib.showContext("territoryBuyList")
end)

RegisterNetEvent("tomic_territories:captureClient", function(terData)
    local currentTerritory = nil
    for _, v in pairs(territoryCollection) do
        if v.id == terData.currentTerritory.id then
            currentTerritory = v
        end
    end

    if not currentTerritory then
        ShowNotification(Translate("something_went_wrong"), TYPE_ERROR)
        return
    end

    if PlayerData.job.name == currentTerritory.owner then
        ShowNotification(Translate("territory_already_owned"), TYPE_INFO)
        return
    end

    if currentTerritory.isTaking then
        ShowNotification(Translate("capture_in_progress"), TYPE_INFO)
        return
    end

    if currentTerritory.isCooldown then
        ShowNotification(Translate("territory_on_cooldown"), TYPE_INFO)
        return
    end

    TriggerServerEvent(
        "tomic_territories:captureServer",
        currentTerritory.id,
        PlayerData.job.name,
        currentTerritory.name,
        currentTerritory.owner
    )
end)

RegisterNetEvent("tomic_territories:openStash", function(terData)
    terData = terData.currentTerritory
    local playerTerritoryDistance = #(terData.terCoords - GetEntityCoords(cache.ped))

    if PlayerData.job and PlayerData.job.name ~= terData.currentOwner then
        ShowNotification(Translate("territory_not_owned"), TYPE_ERROR)
        return
    end

    if playerTerritoryDistance > 3.0 then
        ShowNotification(Translate("too_far_away"), TYPE_ERROR)
        return
    end

    exports.ox_inventory:openInventory(
        "stash",
        { id = "devTomic-Ter[" .. terData.name .. "][" .. terData.id .. "]" }
    )
end)

RegisterNetEvent("tomic_territories:captureProgress", function(terKey, terData)
    local lastTerritory = terKey
    while true do
        Wait(0)
        local playerPed = cache.ped
        local playerCoords = GetEntityCoords(playerPed)
        local territoryCoords = vec3(terData.coords.x, terData.coords.y, terData.coords.z)
        local playerTerritoryDistance = #(playerCoords - territoryCoords)

        if not terData.isTaking then
            return
        end

        if playerTerritoryDistance > terData.radius then
            lib.cancelProgress()
            ShowNotification(Translate("territory_cause_distance"), TYPE_ERROR)
            progress = 0
            TriggerServerEvent("tomic_territories:endCapturing", lastTerritory)
            lastTerritory = nil
            return
        end

        if LocalPlayer.state.isDead or LocalPlayer.state.dead then
            lib.cancelProgress()
            ShowNotification(Translate("territory_cause_death"), TYPE_ERROR)
            progress = 0
            TriggerServerEvent("tomic_territories:endCapturing", lastTerritory)
            lastTerritory = nil
            return
        end

        if progress >= 60 then
            lib.cancelProgress()
            TriggerServerEvent("tomic_territories:captureComplete", terData.id, PlayerData.job.name, PlayerData.job
                .label, terData.owner)
            progress = 0
            ShowNotification(Translate("territory_captured"):format(terData.name), TYPE_SUCCESS)
            return
        end

        if not lib.progressActive() then
            lib.progressCircle({
                duration = shared.capturing * 60000,
                label = Translate("territory_capture_progress_bar"),
                position = "bottom",
                useWhileDead = false,
                allowSwimming = false,
                allowCuffed = false,
                canCancel = true
            })
        end

        Wait(shared.capturing * 60000 / 60)
        progress = progress + 1
    end
end)

RegisterCommand(shared.playerCommand, function(source, args, rawCommand)
    local homePage = {
        id = "homePage",
        title = Translate("territory_menu_title"),
        options = {
            {
                title = Translate("territory_list_title"),
                event = "tomic_territories:listTerritories",
                metadata = {
                    Translate("territory_list_metadata")
                }
            },
            {
                title = "Info | ❓",
                metadata = {
                    "| Made by Tomić ✅"
                }
            }
        }
    }

    if shared.rankings then
        table.insert(homePage.options, {
            title = Translate("territory_rankings_title"),
            event = "tomic_territories:listRankings",
            metadata = {
                Translate("territory_rankings_metadata")
            }
        })
    end

    lib.registerContext(homePage)
    lib.showContext(homePage.id)
end, false)

RegisterNetEvent("tomic_territories:listTerritories", function()
    local terListCollection = {}
    local territoryStatuses = {
        ["isCooldown"] = nil,
        ["isTaking"] = nil
    }

    if territoryCollection == nil then return end

    for i = 1, #territoryCollection, 1 do
        local currentTerritory = territoryCollection[i]
        territoryStatuses.isTaking = currentTerritory.isTaking and Translate("context_yes") or
            Translate("context_no")
        territoryStatuses.isCooldown = currentTerritory.isCooldown and Translate("context_yes") or
            Translate("context_no")
        terListCollection[i] = {
            title = Translate("territory_list_territory_name"):format(currentTerritory.name),
            description = Translate("territory_list_territory_owner"):format(currentTerritory.label),
            metadata = {
                Translate("territory_list_territory_capturing"):format(territoryStatuses.isTaking),
                Translate("territory_list_territory_cooldown"):format(territoryStatuses.isCooldown)
            },
        }
    end

    lib.registerContext({
        id = "listTerritories",
        title = Translate("territory_menu_context_title"),
        menu = "homePage",
        options = terListCollection,
    })
    lib.showContext("listTerritories")
end)

if shared.rankings then
    RegisterNetEvent("tomic_territories:listRankings", function()
        if not territoryCollection or #territoryCollection == 0 then return end

        local pointsCollection = lib.callback.await("tomic_territories:fetchPoints", 5000)
        if not pointsCollection or #pointsCollection == 0 then
            lib.print.error(Translate("something_went_wrong"))
            return
        end

        table.sort(pointsCollection, function(a, b)
            return a.totalPoints > b.totalPoints
        end)

        local rankCollection = {}
        for i = 1, #pointsCollection do
            local currentEntry = pointsCollection[i]
            rankCollection[i] = {
                title = Translate("territory_rankings_gang"):format(currentEntry.label),
                description = Translate("territory_rankings_position"):format(i),
                metadata = {
                    Translate("territory_rankings_all_time"):format(currentEntry.totalPoints),
                    Translate("territory_rankings_monthly"):format(currentEntry.monthlyPoints),
                    Translate("territory_rankings_weekly"):format(currentEntry.weeklyPoints)
                }
            }
        end

        lib.registerContext({
            id = "listRankings",
            menu = "homePage",
            title = Translate("territory_rankings_menu_context_title"),
            options = rankCollection,
        })

        lib.showContext("listRankings")
    end)
end

RegisterNetEvent("onResourceStop", function(resourceName)
    if resourceName ~= cache.resource then return end

    lib.cancelProgress()
    lib.hideTextUI()
    progress = 0
end)
