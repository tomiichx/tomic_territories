---@diagnostic disable: undefined-global
lib.versionCheck("tomic_territories")
lib.locale()

---@class Territory
---@field id number
---@field name string
---@field owner string
---@field label string
---@field radius number
---@field type string
---@field coords { x: number, y: number, z: number }?
---@field isTaking boolean
---@field isCooldown boolean
---@field attackerJob string?
---@field attenders TerritoryAttender[]

---@class TerritoryAttender
---@field identifier string
---@field playerJob string
---@field isPlayerDefender boolean
---@field territoryName string
---@field territoryStatus string

---@type Territory[]
local territories = {}

---@type table<number, { initiator: number, startTime: number, job: string }>
local activeCaptures = {}

local queries = {
    SELECT_TERRITORY = "SELECT * FROM tomic_territories",
    SELECT_POINTS = "SELECT * FROM jobs WHERE name IN (?)",
    SELECT_PREPARE_POINTS = "SELECT * FROM jobs WHERE name IN (?, ?)",
    INSERT_TERRITORY = "INSERT INTO tomic_territories (name, owner, radius, label, type, coords) VALUES (?, ?, ?, ?, ?, ?)",
    UPDATE_TERRITORY = "UPDATE tomic_territories SET owner = ?, label = ? WHERE id = ?",
    UPDATE_POINTS = "UPDATE jobs SET weeklyPoints = ?, monthlyPoints = ?, totalPoints = ? WHERE name = ?",
    UPDATE_RESET_POINTS = "UPDATE jobs SET weeklyPoints = 0",
    DELETE_TERRITORY = "DELETE FROM tomic_territories WHERE name = ?",
}

---@param src number
---@param message string
---@param nType string
local function notify(src, message, nType)
    TriggerClientEvent("ox_lib:notify", src, {
        description = message,
        type = nType,
        position = "top",
        duration = 5000,
    })
end

---@param src number
---@param reason string
local function logCheat(src, reason)
    lib.print.error(("[CHEAT] %s (ID: %s | License: %s) - %s"):format(
        GetPlayerName(src),
        src,
        GetPlayerIdentifierByType(src, "license"),
        reason
    ))

    lib.logger(src, "CheatDetected", json.encode({
        reason = reason,
    }), "cheat", "security")
end

---@param territoryID number
---@return Territory?
local function getTerritoryByID(territoryID)
    for i = 1, #territories do
        if territories[i].id == territoryID then
            return territories[i]
        end
    end

    return nil
end

CreateThread(function()
    local rows = MySQL.query.await(queries.SELECT_TERRITORY)
    if not rows then return end

    for i = 1, #rows do
        local row = rows[i]

        local success, coords = pcall(json.decode, row.coords)
        if not success or not coords then
            lib.print.error(("Territory '%s' (ID: %d) has invalid coords in database, skipping."):format(row.name, row.id))
            goto continue
        end

        territories[#territories + 1] = {
            id = row.id,
            name = row.name,
            owner = row.owner,
            radius = row.radius,
            label = row.label,
            type = row.type,
            coords = coords,
            isTaking = false,
            isCooldown = false,
            attenders = {},
        }

        exports.ox_inventory:RegisterStash(
            "devTomic-Ter[" .. row.name .. "][" .. row.id .. "]",
            "Territory: " .. row.name, 50, 100000
        )

        ::continue::
    end

    lib.print.info(("Registered %d territories."):format(#territories))
end)

lib.callback.register("tomic_territories:getTerritories", function()
    return territories
end)

if Config.rankings then
    local jobsArray = {}
    for k in pairs(Config.gangs) do
        jobsArray[#jobsArray + 1] = k
    end

    lib.callback.register("tomic_territories:fetchPoints", function()
        return MySQL.query.await(queries.SELECT_POINTS, { jobsArray }) or {}
    end)
end

RegisterCommand(Config.adminCommand, function(source, args)
    local src = source

    if src == 0 then
        lib.print.error("This command can only be used in-game.")
        return
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not Config.groups[xPlayer.getGroup()] then
        notify(src, locale("no_permission"), "error")
        return
    end

    if not args[1] then
        notify(src, locale("no_args"), "error")
        return
    end

    if args[1] == "create" then
        TriggerClientEvent("tomic_territories:createTerritory", src)
    elseif args[1] == "delete" then
        TriggerClientEvent("tomic_territories:deleteTerritory", src)
    end
end, false)

RegisterNetEvent("tomic_territories:createTerritory", function(territoryInfo)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer or not Config.groups[xPlayer.getGroup()] then
        logCheat(src, "Tried creating territory without admin.")
        return
    end

    for i = 1, #territories do
        if territories[i].name == territoryInfo.name then
            notify(src, locale("territory_already_exists"), "error")
            return
        end
    end

    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local coordsJSON = json.encode({ x = playerCoords.x, y = playerCoords.y, z = playerCoords.z })

    local insertID = MySQL.insert.await(queries.INSERT_TERRITORY, {
        territoryInfo.name, "noone",
        territoryInfo.radius, "NoOne",
        territoryInfo.type or "default", coordsJSON,
    })

    if not insertID or insertID == 0 then
        notify(src, locale("territory_creation_failed"), "error")
        return
    end

    local territory = {
        id = insertID,
        name = territoryInfo.name,
        owner = "noone",
        radius = territoryInfo.radius,
        label = "NoOne",
        type = territoryInfo.type or "default",
        coords = { x = playerCoords.x, y = playerCoords.y, z = playerCoords.z },
        isTaking = false,
        isCooldown = false,
        attenders = {},
    }

    territories[#territories + 1] = territory

    exports.ox_inventory:RegisterStash(
        "devTomic-Ter[" .. territory.name .. "][" .. territory.id .. "]",
        "Territory: " .. territory.name, 50, 100000
    )

    TriggerClientEvent("tomic_territories:updateTerritories", -1, territories)
    notify(src, locale("territory_created"), "success")

    lib.logger(src, "TerritoryCreated", json.encode({
        name = territory.name,
        type = territory.type,
        radius = territory.radius,
    }), "admin", "territory")
end)

RegisterNetEvent("tomic_territories:deleteTerritory", function(territoryName)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer or not Config.groups[xPlayer.getGroup()] then
        logCheat(src, "Tried deleting territory without admin.")
        return
    end

    local result = MySQL.query.await(queries.DELETE_TERRITORY, { territoryName })

    if not result or result.affectedRows == 0 then
        notify(src, locale("territory_deletion_failed"), "error")
        return
    end

    for i = 1, #territories do
        if territories[i].name == territoryName then
            table.remove(territories, i)
            break
        end
    end

    TriggerClientEvent("tomic_territories:updateTerritories", -1, territories)
    notify(src, locale("territory_deleted"), "success")

    lib.logger(src, "TerritoryDeleted", json.encode({
        name = territoryName,
    }), "admin", "territory")
end)

RegisterNetEvent("tomic_territories:updateAttenders", function(territoryID, inTerritory, isDead)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    local job = xPlayer.getJob()
    if not Config.gangs[job.name] then return end

    local territory = getTerritoryByID(territoryID)
    if not territory then return end

    local attenders = territory.attenders
    local isDefender = territory.owner == job.name
    local statusMessage = isDefender and locale("defender_message") or locale("attacker_message")

    for i = #attenders, 1, -1 do
        if attenders[i].identifier == identifier then
            if isDead or not inTerritory then
                table.remove(attenders, i)
                TriggerClientEvent("tomic_territories:updateUI", src, "hideUI", attenders)
            end
            goto found
        end
    end

    if inTerritory and not isDead then
        attenders[#attenders + 1] = {
            identifier = identifier,
            playerJob = job.name,
            isPlayerDefender = isDefender,
            territoryName = territory.name,
            territoryStatus = statusMessage,
        }
    end

    ::found::
    for i = 1, #attenders do
        local attendPlayer = ESX.GetPlayerFromIdentifier(attenders[i].identifier)
        if attendPlayer then
            TriggerClientEvent("tomic_territories:updateUI", attendPlayer.source, "showUI", attenders)
        end
    end
end)

---@param gangName string
---@param territoryName string
local function rewardPlayers(gangName, territoryName)
    local jobMembers = ESX.GetExtendedPlayers("job", gangName)

    for _, xPlayer in pairs(jobMembers) do
        exports.ox_inventory:AddItem(xPlayer.source, Config.rewards.item, Config.rewards.count)
        notify(xPlayer.source, locale("territory_reward"):format(Config.rewards.count, territoryName), "success")

        lib.logger(xPlayer.source, "CaptureReward", json.encode({
            item = Config.rewards.item,
            count = Config.rewards.count,
            territory = territoryName,
        }), "economy", "reward")
    end
end

lib.callback.register("tomic_territories:startCapture", function(source, territoryID)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end

    local job = xPlayer.getJob()
    if not Config.gangs[job.name] then return false end

    local territory = getTerritoryByID(territoryID)
    if not territory then return false end

    if territory.owner == job.name then return false end
    if territory.isTaking then return false end
    if territory.isCooldown then return false end

    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local terCoords = vec3(territory.coords.x, territory.coords.y, territory.coords.z)

    if #(playerCoords - terCoords) > territory.radius then
        logCheat(src, ("Tried starting capture of '%s' from invalid distance."):format(territory.name))
        return false
    end

    territory.isTaking = true
    territory.isCooldown = true
    territory.attackerJob = job.name

    activeCaptures[territory.id] = {
        initiator = src,
        startTime = os.time(),
        job = job.name,
    }

    local defendingPlayers = ESX.GetExtendedPlayers("job", territory.owner)
    for _, defender in pairs(defendingPlayers) do
        notify(defender.source, locale("territory_being_attacked"):format(territory.name), "info")
    end

    local attackingPlayers = ESX.GetExtendedPlayers("job", job.name)
    for _, attacker in pairs(attackingPlayers) do
        notify(attacker.source, locale("territory_started_attacking"):format(territory.name), "info")
    end

    TriggerClientEvent("tomic_territories:updateTerritories", -1, territories)
    TriggerClientEvent("tomic_territories:updateBlips", -1, territory.id, job.name)

    lib.print.info(("%s started capturing: %s"):format(GetPlayerName(src), territory.name))

    lib.logger(src, "CaptureStarted", json.encode({
        territory = territory.name,
        territoryID = territory.id,
        attackerJob = job.name,
        defenderJob = territory.owner,
    }), "territory", "combat")

    return true, territory
end)

lib.callback.register("tomic_territories:captureComplete", function(source, territoryID)
    local src = source
    local capture = activeCaptures[territoryID]

    if not capture then return false end

    if capture.initiator ~= src then
        logCheat(src, "Tried completing a capture they did not start.")
        return false
    end

    local elapsed = os.time() - capture.startTime
    if elapsed < (Config.captureDuration * 60 - 10) then
        logCheat(src, ("Capture completed too fast (%ds vs %ds)."):format(elapsed, Config.captureDuration * 60))
        return false
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end

    local job = xPlayer.getJob()
    local territory = getTerritoryByID(territoryID)
    if not territory then return false end

    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local terCoords = vec3(territory.coords.x, territory.coords.y, territory.coords.z)

    if #(playerCoords - terCoords) > territory.radius then
        logCheat(src, ("Completed capture of '%s' from invalid distance."):format(territory.name))
        return false
    end

    local previousOwner = territory.owner
    territory.isTaking = false
    territory.attackerJob = nil
    territory.owner = job.name
    territory.label = job.label
    activeCaptures[territoryID] = nil

    MySQL.query.await(queries.UPDATE_TERRITORY, { job.name, job.label, territory.id })

    if Config.rewards.enabled then
        rewardPlayers(job.name, territory.name)
    end

    if Config.rankings then
        local rows = MySQL.query.await(queries.SELECT_PREPARE_POINTS, { previousOwner, job.name })
        if rows then
            for i = 1, #rows do
                local result = rows[i]
                local weekly = result.weeklyPoints
                local monthly = result.monthlyPoints
                local total = result.totalPoints

                if result.name == previousOwner then
                    weekly = weekly - 2
                    monthly = monthly - 2
                    total = total - 2
                elseif result.name == job.name then
                    weekly = weekly + 3
                    monthly = monthly + 3
                    total = total + 3
                end

                MySQL.query.await(queries.UPDATE_POINTS, { weekly, monthly, total, result.name })
            end
        end
    end

    TriggerClientEvent("tomic_territories:updateTerritories", -1, territories)

    lib.logger(src, "CaptureCompleted", json.encode({
        territory = territory.name,
        territoryID = territory.id,
        newOwner = job.name,
        previousOwner = previousOwner,
    }), "territory", "combat")

    CreateThread(function()
        Wait(Config.cooldown * 60000)
        territory.isCooldown = false
        TriggerClientEvent("tomic_territories:updateTerritories", -1, territories)
    end)

    return true
end)

lib.callback.register("tomic_territories:endCapturing", function(source, territoryID)
    local src = source
    local capture = activeCaptures[territoryID]
    if not capture or capture.initiator ~= src then return false end

    local territory = getTerritoryByID(territoryID)
    if not territory then return false end

    territory.isTaking = false
    territory.attackerJob = nil
    activeCaptures[territoryID] = nil

    TriggerClientEvent("tomic_territories:updateTerritories", -1, territories)

    lib.logger(src, "CaptureFailed", json.encode({
        territory = territory.name,
        territoryID = territory.id,
    }), "territory")

    CreateThread(function()
        Wait(Config.cooldown * 60000)
        territory.isCooldown = false
        TriggerClientEvent("tomic_territories:updateTerritories", -1, territories)
    end)

    return true
end)

RegisterNetEvent("tomic_territories:marketHandler", function(itemKey, count, handlerType)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local job = xPlayer.getJob()
    if not Config.gangs[job.name] then return end

    if not count or count < 1 or count ~= math.floor(count) then
        notify(src, locale("invalid_amount"), "error")
        return
    end

    local itemConfig
    if handlerType == "sell" then
        itemConfig = Config.itemsToSell[itemKey]
    elseif handlerType == "buy" then
        itemConfig = Config.itemsToBuy[itemKey]
    end

    if not itemConfig then return end

    local price = itemConfig.worth * count
    local currency = itemConfig.black and "black_money" or "money"

    if handlerType == "sell" then
        if exports.ox_inventory:GetItemCount(src, itemKey) < count then
            notify(src, locale("invalid_amount"), "error")
            return
        end

        exports.ox_inventory:RemoveItem(src, itemKey, count)
        exports.ox_inventory:AddItem(src, currency, price)

    elseif handlerType == "buy" then
        if exports.ox_inventory:GetItemCount(src, currency) < price then
            notify(src, locale("not_enough_money"), "error")
            return
        end

        if not exports.ox_inventory:CanCarryItem(src, itemKey, count) then
            notify(src, locale("not_enough_space"), "error")
            return
        end

        exports.ox_inventory:RemoveItem(src, currency, price)
        exports.ox_inventory:AddItem(src, itemKey, count)
    end

    lib.logger(src, "MarketTransaction", json.encode({
        type = handlerType,
        item = itemKey,
        count = count,
        totalPrice = price,
        currency = currency,
    }), "economy", "market")
end)

AddEventHandler("playerDropped", function()
    local src = source

    for territoryID, capture in pairs(activeCaptures) do
        if capture.initiator ~= src then goto continue end

        local territory = getTerritoryByID(territoryID)
        if territory then
            territory.isTaking = false
            territory.attackerJob = nil
            TriggerClientEvent("tomic_territories:updateTerritories", -1, territories)

            CreateThread(function()
                Wait(Config.cooldown * 60000)
                territory.isCooldown = false
                TriggerClientEvent("tomic_territories:updateTerritories", -1, territories)
            end)
        end

        activeCaptures[territoryID] = nil
        ::continue::
    end
end)

if Config.rankings then
    lib.cron.new("0 0 * * 1", function()
        local result = MySQL.query.await(queries.UPDATE_RESET_POINTS)

        if not result then
            lib.print.error("Weekly points reset failed.")
            return
        end

        lib.print.info("Weekly points reset completed.")
    end)
end
