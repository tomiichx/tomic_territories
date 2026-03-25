---@diagnostic disable: undefined-global
lib.locale()

local ESX = exports["es_extended"]:getSharedObject()

---@type table
local PlayerData = ESX.GetPlayerData() or {}

---@type Territory[]
local territoryCollection = {}

---@type number[]
local headerBlips = {}

---@type number[]
local circleBlips = {}

---@type table<number, CPoint>
local territoryPoints = {}

---@type boolean
local showUI = false

---@type boolean
local capturing = false

---@type number?
local lastTerritory = nil

local createBlips, removeBlips, createPoints, removePoints
local displayMenu, startCapture, monitorAttendance


CreateThread(function()
    territoryCollection = lib.callback.await("tomic_territories:getTerritories", false)

    if not territoryCollection then
        lib.print.error(locale("something_went_wrong"))
        return
    end

    createBlips()
    createPoints()
end)

RegisterNetEvent("esx:playerLoaded", function(playerInfo)
    PlayerData = playerInfo
end)

---@type number?
local monitoringThread = nil

RegisterNetEvent("esx:setJob", function(newJob)
    PlayerData.job = newJob

    if monitoringThread then
        monitoringThread = nil
    end

    removePoints()
    createPoints()

    if PlayerData.job and Config.gangs[PlayerData.job.name] then
        monitoringThread = CreateThread(function()
            while monitoringThread do
                Wait(5000)
                monitorAttendance()
            end
        end)
    end
end)

function removeBlips()
    for i = 1, #circleBlips do
        RemoveBlip(circleBlips[i])
    end

    for i = 1, #headerBlips do
        RemoveBlip(headerBlips[i])
    end

    circleBlips = {}
    headerBlips = {}
end

function createBlips()
    local canSeeBlips = (Config.gangOnlyBlips and PlayerData.job and Config.gangs[PlayerData.job.name])
        or not Config.gangOnlyBlips

    if not canSeeBlips then return end

    for i = 1, #territoryCollection do
        local territory = territoryCollection[i]

        if not territory.coords then
            lib.print.error(("Territory '%s' has no coordinates, skipping blip."):format(territory.name))
            goto continue
        end

        local circleBlip = AddBlipForCoord(territory.coords.x, territory.coords.y, territory.coords.z)
        SetBlipSprite(circleBlip, 373)
        SetBlipDisplay(circleBlip, 8)
        SetBlipScale(circleBlip, 4.0)
        SetBlipAlpha(circleBlip, 100)
        SetBlipAsShortRange(circleBlip, true)

        for gangName, gangData in pairs(Config.gangs) do
            if territory.owner == gangName then
                SetBlipColour(circleBlip, gangData.blipColour)
                break
            end
        end

        local headerBlip = AddBlipForCoord(territory.coords.x, territory.coords.y, territory.coords.z + 15)
        SetBlipSprite(headerBlip, 310)
        SetBlipDisplay(headerBlip, 4)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(
            locale("territory_blip_occupied"):format(
                territory.name,
                territory.owner ~= "noone" and territory.label or locale("territory_blip_unoccupied")
            )
        )
        EndTextCommandSetBlipName(headerBlip)

        SetBlipScale(headerBlip, 0.75)
        SetBlipColour(headerBlip, 0)
        SetBlipAlpha(headerBlip, 250)
        SetBlipAsShortRange(headerBlip, true)

        circleBlips[#circleBlips + 1] = circleBlip
        headerBlips[#headerBlips + 1] = headerBlip

        ::continue::
    end
end

function removePoints()
    for _, point in pairs(territoryPoints) do
        point:remove()
    end

    territoryPoints = {}
end

---@param territory Territory
---@return number index
local function getTerritoryIndex(territory)
    for i = 1, #territoryCollection do
        if territoryCollection[i].id == territory.id then
            return i
        end
    end

    return -1
end

function createPoints()
    removePoints()

    if not (PlayerData.job and Config.gangs[PlayerData.job.name]) then return end

    for i = 1, #territoryCollection do
        local territory = territoryCollection[i]
        if not territory.coords then goto continue end

        local terCoords = vec3(territory.coords.x, territory.coords.y, territory.coords.z)

        local point = lib.points.new({
            coords = terCoords,
            distance = territory.radius,
            territory = territory,
        })

        function point:onExit()
            if showUI then
                showUI = false
                lib.hideTextUI()
            end
        end

        function point:nearby()
            local terData = self.territory

            DrawMarker(2, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0, 0.0,
                0.15, 0.15, 0.15, 200, 0, 50, 230, false, false, 0, true, nil, nil, false)
            DrawMarker(1, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0, 0.0,
                0.25, 0.25, 0.02, 255, 255, 255, 255, false, false, 0, true, nil, nil, false)

            if self.currentDistance < Config.interactDistance then
                if not showUI then
                    showUI = true
                    lib.showTextUI(locale("territory_show_text"):format(terData.name))
                end

                if IsControlJustPressed(0, 38) then
                    displayMenu(terData)
                end
            elseif showUI then
                showUI = false
                lib.hideTextUI()
            end
        end

        territoryPoints[territory.id] = point

        ::continue::
    end
end

RegisterNetEvent("tomic_territories:updateTerritories", function(serverData)
    territoryCollection = serverData

    removeBlips()
    removePoints()

    Wait(500)

    createBlips()
    createPoints()

    for i = 1, #territoryCollection do
        local territory = territoryCollection[i]
        if territory.isTaking and territory.attackerJob then
            TriggerEvent("tomic_territories:updateBlips", territory.id, territory.attackerJob)
        end
    end
end)

RegisterNetEvent("tomic_territories:updateBlips", function(territoryID, attackerJob)
    CreateThread(function()
        while true do
            local territory
            for i = 1, #territoryCollection do
                if territoryCollection[i].id == territoryID then
                    territory = territoryCollection[i]
                    break
                end
            end

            if not territory or not territory.isTaking then break end

            local blipIndex = getTerritoryIndex(territory)
            local blip = circleBlips[blipIndex]
            if not blip then break end

            local ownerGang = Config.gangs[territory.owner]
            if ownerGang then
                SetBlipColour(blip, ownerGang.blipColour)
            end
            Wait(1000)

            local attackerGang = Config.gangs[attackerJob]
            if attackerGang and circleBlips[blipIndex] then
                SetBlipColour(circleBlips[blipIndex], attackerGang.blipColour)
            end
            Wait(1000)
        end
    end)
end)

RegisterNetEvent("tomic_territories:updateUI", function(action, data)
    SendNUIMessage({ action = action, data = data })
end)

---@param terData Territory
function displayMenu(terData)
    local menuID = "infoMenu" .. terData.id

    ---@type table[]
    local options = {
        {
            title = locale("territory_info_menu_capture"),
            event = "tomic_territories:captureClient",
            args = { territoryID = terData.id },
        },
        {
            title = locale("territory_info_menu_stash"),
            event = "tomic_territories:openStash",
            args = { territoryID = terData.id, name = terData.name, owner = terData.owner },
        },
    }

    if terData.type == "dealer" then
        options[#options + 1] = {
            title = locale("territory_info_menu_sell"),
            event = "tomic_territories:sellList",
            args = { territoryID = terData.id, owner = terData.owner, menuID = menuID },
        }
    elseif terData.type == "market" then
        options[#options + 1] = {
            title = locale("territory_info_menu_buy"),
            event = "tomic_territories:buyList",
            args = { territoryID = terData.id, owner = terData.owner, menuID = menuID },
        }
    end

    lib.registerContext({
        id = menuID,
        title = locale("territory_info_menu"):format(terData.name),
        options = options,
    })
    lib.showContext(menuID)
end

RegisterNetEvent("tomic_territories:captureClient", function(args)
    local territoryID = args.territoryID

    local territory
    for i = 1, #territoryCollection do
        if territoryCollection[i].id == territoryID then
            territory = territoryCollection[i]
            break
        end
    end

    if not territory then
        lib.notify({ description = locale("something_went_wrong"), type = "error" })
        return
    end

    if PlayerData.job.name == territory.owner then
        lib.notify({ description = locale("territory_already_owned"), type = "info" })
        return
    end

    if territory.isTaking then
        lib.notify({ description = locale("capture_in_progress"), type = "info" })
        return
    end

    if territory.isCooldown then
        lib.notify({ description = locale("territory_on_cooldown"), type = "info" })
        return
    end

    local success, serverTerritory = lib.callback.await("tomic_territories:startCapture", false, territory.id)
    if not success then return end

    startCapture(territory.id, serverTerritory)
end)

---@param territoryID number
---@param territory Territory
function startCapture(territoryID, territory)
    capturing = true
    local territoryCoords = vec3(territory.coords.x, territory.coords.y, territory.coords.z)

    CreateThread(function()
        while capturing do
            Wait(500)
            if not capturing then return end

            local playerCoords = GetEntityCoords(cache.ped)
            if #(playerCoords - territoryCoords) > territory.radius then
                capturing = false
                lib.cancelProgress()
                lib.notify({ description = locale("territory_cause_distance"), type = "error" })
                lib.callback.await("tomic_territories:endCapturing", false, territoryID)
                return
            end

            if LocalPlayer.state.isDead or LocalPlayer.state.dead then
                capturing = false
                lib.cancelProgress()
                lib.notify({ description = locale("territory_cause_death"), type = "error" })
                lib.callback.await("tomic_territories:endCapturing", false, territoryID)
                return
            end
        end
    end)

    local completed = lib.progressCircle({
        duration = Config.captureDuration * 60000,
        label = locale("territory_capture_progress_bar"),
        position = "bottom",
        useWhileDead = false,
        canCancel = true,
    })

    capturing = false

    if not completed then
        lib.callback.await("tomic_territories:endCapturing", false, territoryID)
        return
    end

    local captureSuccess = lib.callback.await("tomic_territories:captureComplete", false, territoryID)

    if captureSuccess then
        lib.notify({ description = locale("territory_captured"):format(territory.name), type = "success" })
    end
end

RegisterNetEvent("tomic_territories:openStash", function(args)
    if not PlayerData.job or PlayerData.job.name ~= args.owner then
        lib.notify({ description = locale("territory_not_owned"), type = "error" })
        return
    end

    local nearPoint = false

    for _, point in pairs(territoryPoints) do
        if point.currentDistance and point.currentDistance < 3.0 then
            nearPoint = true
            break
        end
    end

    if not nearPoint then
        lib.notify({ description = locale("too_far_away"), type = "error" })
        return
    end

    exports.ox_inventory:openInventory("stash", {
        id = "devTomic-Ter[" .. args.name .. "][" .. args.territoryID .. "]",
    })
end)

RegisterNetEvent("tomic_territories:sellList", function(args)
    if PlayerData.job.name ~= args.owner then
        lib.notify({ description = locale("territory_not_owned"), type = "error" })
        return
    end

    ---@type table
    local options = {}
    for itemKey, itemData in pairs(Config.itemsToSell) do
        options[#options + 1] = {
            title = itemData.label,
            description = locale("territory_info_menu_buy_sell_price"):format(itemData.worth),
            event = "tomic_territories:letCount",
            args = { key = itemKey, name = itemData.label, type = "sell" },
        }
    end

    lib.registerContext({
        id = "territorySellList",
        title = locale("territory_info_menu_sell_title"),
        menu = args.menuID,
        options = options,
    })
    lib.showContext("territorySellList")
end)

RegisterNetEvent("tomic_territories:buyList", function(args)
    if PlayerData.job.name ~= args.owner then
        lib.notify({ description = locale("territory_not_owned"), type = "error" })
        return
    end

    ---@type table
    local options = {}
    for itemKey, itemData in pairs(Config.itemsToBuy) do
        options[#options + 1] = {
            title = itemData.label,
            description = locale("territory_info_menu_buy_sell_price"):format(itemData.worth),
            event = "tomic_territories:letCount",
            args = { key = itemKey, name = itemData.label, type = "buy" },
        }
    end

    lib.registerContext({
        id = "territoryBuyList",
        title = locale("territory_info_menu_buy_title"),
        menu = args.menuID,
        options = options,
    })
    lib.showContext("territoryBuyList")
end)

RegisterNetEvent("tomic_territories:letCount", function(data)
    local input = lib.inputDialog(data.name, { locale("amount") })

    if not input or #input == 0 then return end

    local count = tonumber(input[1]) or 0
    if count <= 0 then
        lib.notify({ description = locale("fill_all_fields_out"), type = "error" })
        return
    end

    TriggerServerEvent("tomic_territories:marketHandler", data.key, count, data.type)
end)

RegisterNetEvent("tomic_territories:createTerritory", function()
    local input = lib.inputDialog(locale("territory_create_input"), {
        { type = "input", label = locale("territory_create_name") },
        { type = "input", label = locale("territory_create_radius") },
        {
            type = "select",
            label = locale("territory_create_type"),
            options = {
                { value = "market", label = locale("territory_create_type_market") },
                { value = "dealer", label = locale("territory_create_type_dealer") },
                { value = "default", label = locale("territory_create_type_default") },
            },
        },
    })

    if not input then return end

    local name = tostring(input[1])
    local radius = tonumber(input[2]) or 0
    local territoryType = tostring(input[3])

    if not name or name:match("^%s*$") then
        lib.notify({ description = locale("fill_all_fields_out"), type = "error" })
        return
    end

    if radius <= 0 then
        lib.notify({ description = locale("fill_all_fields_out"), type = "error" })
        return
    end

    if not territoryType or territoryType:match("^%s*$") then
        lib.notify({ description = locale("fill_all_fields_out"), type = "error" })
        return
    end

    TriggerServerEvent("tomic_territories:createTerritory", {
        name = name,
        type = territoryType,
        radius = radius,
    })
end)

RegisterNetEvent("tomic_territories:deleteTerritory", function()
    local input = lib.inputDialog(locale("territory_delete_input"), {
        { type = "input", label = locale("territory_delete_input_name") },
    })

    if not input then return end

    local name = tostring(input[1])

    if not name or name:match("^%s*$") then
        lib.notify({ description = locale("fill_all_fields_out"), type = "error" })
        return
    end

    TriggerServerEvent("tomic_territories:deleteTerritory", name)
end)

function monitorAttendance()
    local playerCoords = GetEntityCoords(cache.ped)

    for i = 1, #territoryCollection do
        local territory = territoryCollection[i]
        if not territory.coords or not territory.isTaking then goto continue end

        local terCoords = vec3(territory.coords.x, territory.coords.y, territory.coords.z)

        if #(playerCoords - terCoords) < territory.radius then
            lastTerritory = territory.id
            TriggerServerEvent("tomic_territories:updateAttenders",
                territory.id,
                true,
                LocalPlayer.state.isDead or LocalPlayer.state.dead
            )
            return
        end

        ::continue::
    end

    if lastTerritory then
        TriggerServerEvent("tomic_territories:updateAttenders",
            lastTerritory,
            false,
            false
        )
        lastTerritory = nil
    end
end

RegisterCommand(Config.playerCommand, function()
    local options = {
        {
            title = locale("territory_list_title"),
            event = "tomic_territories:listTerritories",
            metadata = { locale("territory_list_metadata") },
        },
    }

    if Config.rankings then
        options[#options + 1] = {
            title = locale("territory_rankings_title"),
            event = "tomic_territories:listRankings",
            metadata = { locale("territory_rankings_metadata") },
        }
    end

    lib.registerContext({
        id = "homePage",
        title = locale("territory_menu_title"),
        options = options,
    })
    lib.showContext("homePage")
end, false)

RegisterNetEvent("tomic_territories:listTerritories", function()
    if not territoryCollection then return end

    ---@type table[]
    local options = {}

    for i = 1, #territoryCollection do
        local territory = territoryCollection[i]
        local takingText = territory.isTaking and locale("context_yes") or locale("context_no")
        local cooldownText = territory.isCooldown and locale("context_yes") or locale("context_no")

        options[#options + 1] = {
            title = locale("territory_list_territory_name"):format(territory.name),
            description = locale("territory_list_territory_owner"):format(territory.label),
            metadata = {
                locale("territory_list_territory_capturing"):format(takingText),
                locale("territory_list_territory_cooldown"):format(cooldownText),
            },
        }
    end

    lib.registerContext({
        id = "listTerritories",
        title = locale("territory_menu_context_title"),
        menu = "homePage",
        options = options,
    })
    lib.showContext("listTerritories")
end)

if Config.rankings then
    RegisterNetEvent("tomic_territories:listRankings", function()
        if not territoryCollection or #territoryCollection == 0 then return end

        local pointsCollection = lib.callback.await("tomic_territories:fetchPoints", false)
        if not pointsCollection or #pointsCollection == 0 then
            lib.print.error(locale("something_went_wrong"))
            return
        end

        table.sort(pointsCollection, function(a, b)
            return a.totalPoints > b.totalPoints
        end)

        ---@type table[]
        local options = {}

        for i = 1, #pointsCollection do
            local entry = pointsCollection[i]
            options[#options + 1] = {
                title = locale("territory_rankings_gang"):format(entry.label),
                description = locale("territory_rankings_position"):format(i),
                metadata = {
                    locale("territory_rankings_all_time"):format(entry.totalPoints),
                    locale("territory_rankings_monthly"):format(entry.monthlyPoints),
                    locale("territory_rankings_weekly"):format(entry.weeklyPoints),
                },
            }
        end

        lib.registerContext({
            id = "listRankings",
            menu = "homePage",
            title = locale("territory_rankings_menu_context_title"),
            options = options,
        })
        lib.showContext("listRankings")
    end)
end

AddEventHandler("onResourceStop", function(resource)
    if resource ~= cache.resource then return end

    lib.cancelProgress()
    lib.hideTextUI()
    capturing = false

    removeBlips()
    removePoints()
end)
