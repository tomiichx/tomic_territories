lib.versionCheck("tomic_territories")

local territories = {}
local queries = {
    SELECT_POINTS = "SELECT * FROM jobs WHERE name IN (?)",
    SELECT_PREPARE_POINTS = "SELECT * FROM jobs WHERE name IN (?, ?)",
    SELECT_TERRITORY = "SELECT * FROM tomic_territories",
    INSERT_TERRITORY =
    "INSERT INTO tomic_territories (id, name, owner, radius, label, type, coords) VALUES (?, ?, ?, ?, ?, ?, ?)",
    UPDATE_POINTS = "UPDATE jobs SET weeklyPoints = ?, monthlyPoints = ?, totalPoints = ? WHERE name = ?",
    UPDATE_RESET_POINTS = "UPDATE jobs SET weeklyPoints = 0",
    UPDATE_TERRITORY = "UPDATE tomic_territories SET owner = ?, label = ? WHERE id = ?",
    DELETE_TERRITORY = "DELETE FROM tomic_territories WHERE name = ?"
}

local TYPE_ERROR <const> = "error"
local TYPE_SUCCESS <const> = "success"
local TYPE_INFO <const> = "info"

local validTypes <const> = {
    [TYPE_SUCCESS] = true,
    [TYPE_ERROR] = true,
    [TYPE_INFO] = true
}

function ShowNotification(source, message, nType)
    if not message or message:match("^%s*$") then return end

    if not validTypes[nType] then nType = TYPE_INFO end

    TriggerClientEvent("ox_lib:notify", source, {
        title = Translate("territory_menu_title"),
        description = message,
        type = nType,
        position = "top",
        duration = 5000
    })
end

CreateThread(function()
    MySQL.query(queries.SELECT_TERRITORY, function(rowsReturned)
        if rowsReturned then
            territories = {}

            for i = 1, #rowsReturned, 1 do
                table.insert(
                    territories,
                    {
                        id = rowsReturned[i].id,
                        name = rowsReturned[i].name,
                        owner = rowsReturned[i].owner,
                        radius =
                            rowsReturned[i].radius,
                        label = rowsReturned[i].label,
                        type = rowsReturned[i].type,
                        coords = json
                            .decode(rowsReturned[i].coords),
                        isTaking = false,
                        progress = 0,
                        isCooldown = false,
                        attenders = {}
                    }
                )

                exports.ox_inventory:RegisterStash(
                    "devTomic-Ter[" .. rowsReturned[i].name .. "][" .. rowsReturned[i].id .. "]",
                    "Territory: " .. rowsReturned[i].name, 50, 100000
                )
            end

            lib.print.info("Registered " .. #rowsReturned .. " territories!")
        end
    end)
end)

lib.callback.register("tomic_territories:getTerritories", function()
    return territories
end)

if shared.rankings then
    local jobsArray = {}

    for k in pairs(shared.gangs) do
        table.insert(jobsArray, k)
    end

    lib.callback.register("tomic_territories:fetchPoints", function()
        return MySQL.query.await(queries.SELECT_POINTS, { jobsArray }) or {}
    end)
end

RegisterCommand(shared.adminCommand, function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)

    if source == 0 then
        lib.print.error("The command you entered can be used in-game only!")
        return
    end

    if not shared.groups[xPlayer.getGroup()] then
        ShowNotification(source, Translate("no_permission"), TYPE_ERROR)
        return
    end

    if args[1] == nil then
        ShowNotification(source, Translate("no_args"), TYPE_ERROR)
        return
    end

    if args[1] == "create" then
        TriggerClientEvent("tomic_territories:createTerritory", source)
    end

    if args[1] == "delete" then
        TriggerClientEvent("tomic_territories:deleteTerritory", source)
    end
end, false)

RegisterNetEvent("tomic_territories:createTerritory", function(territoryInfo)
    for i = 1, #territories, 1 do
        if territories[i].name == territoryInfo.name then
            ShowNotification(source, Translate("territory_already_exists"), TYPE_ERROR)
            return
        end
    end

    local territory = {
        id = #territories + 1,
        name = territoryInfo.name,
        owner = "noone",
        radius = territoryInfo.radius,
        label = "NoOne",
        type = territoryInfo.type or "default",
        coords = territoryInfo.coords,
        progress = 0,
        isTaking = false,
        isCooldown = false
    }

    MySQL.query(queries.INSERT_TERRITORY,
        { territory.id, territory.name, territory.owner, territory.radius, territory.label, territory.type, json.encode(
            territory.coords) }, function(rowsChanged)
            if rowsChanged.affectedRows == 0 then
                ShowNotification(source, Translate("territory_creation_failed"), TYPE_ERROR)
                return
            end

            table.insert(territories, territory)

            exports.ox_inventory:RegisterStash(
                "devTomic-Ter[" .. territory.name .. "][" .. territory.id .. "]",
                "Territory: " .. territory.name, 50, 100000
            )

            TriggerClientEvent("tomic_territories:updateTerritories", -1, territories)
            ShowNotification(source, Translate("territory_created"), TYPE_SUCCESS)
        end)
end)

RegisterNetEvent("tomic_territories:deleteTerritory", function(territoryName)
    MySQL.query(queries.DELETE_TERRITORY, { territoryName }, function(rowsChanged)
        if rowsChanged.affectedRows == 0 then
            ShowNotification(source, Translate("territory_deletion_failed"), TYPE_ERROR)
            return
        end

        for i = 1, #territories, 1 do
            if territories[i].name == territoryName then
                table.remove(territories, i)
                break
            end
        end

        Wait(500)
        TriggerClientEvent("tomic_territories:updateTerritories", -1, territories)
        ShowNotification(source, Translate("territory_deleted"), TYPE_SUCCESS)
    end)
end)

RegisterNetEvent("tomic_territories:updateAttenders", function(id, identifier, job, inTerritory, isDead)
    local territory = territories[id]
    if not territory or not identifier or not shared.gangs[job] then return end
    local attenders, found, isDefender = territory.attenders, false, territory.owner == job

    for i = 1, #attenders do
        if attenders[i].playerIdentifier == identifier then
            found = true
            if isDead or not inTerritory then
                table.remove(attenders, i)
                TriggerClientEvent("tomic_territories:updateUI", source, "hideUI", attenders)
                break
            end
        end
    end

    local territoryStatusMessage = isDefender and
        Translate("defender_message") or
        Translate("attacker_message")

    if inTerritory and not found and not isDead then
        table.insert(attenders, {
            playerIdentifier = identifier,
            playerJob = job,
            isPlayerDefender = isDefender,
            territoryName = territory.name,
            territoryStatus = territoryStatusMessage
        })
    end

    for i = 1, #attenders do
        local xPlayer = ESX.GetPlayerFromIdentifier(attenders[i].playerIdentifier)
        if xPlayer then TriggerClientEvent("tomic_territories:updateUI", xPlayer.source, "showUI", attenders) end
    end
end)

RegisterNetEvent("tomic_territories:captureServer", function(id, job, name, currentOwner)
    local defendingPlayers = ESX.GetExtendedPlayers("job", currentOwner)
    for _, defender in pairs(defendingPlayers) do
        ShowNotification(defender.source, Translate("territory_being_attacked"):format(name), TYPE_INFO)
    end

    local attackingPlayers = ESX.GetExtendedPlayers("job", job)
    for _, attacker in pairs(attackingPlayers) do
        ShowNotification(attacker.source, Translate("territory_started_attacking"):format(name), TYPE_INFO)
    end

    local currentTerritory = territories[id]
    currentTerritory.isTaking, currentTerritory.isCooldown = true, true

    TriggerClientEvent("tomic_territories:updateTerritories", -1, territories)
    TriggerClientEvent("tomic_territories:updateBlips", -1, id, job)
    TriggerClientEvent("tomic_territories:captureProgress", source, id, currentTerritory)

    lib.print.info(("%s started capturing: %s"):format(GetPlayerName(source), name))
end)

RegisterNetEvent("tomic_territories:marketHandler", function(itemObject, handlerType)
    local itemCurrency = itemObject.itemCurrency and "black_money" or "money"

    if handlerType == "sell" then
        if exports.ox_inventory:GetItemCount(source, itemObject.itemKey) < itemObject.itemCount then
            ShowNotification(source, Translate("invalid_amount"), TYPE_ERROR)
            return
        end

        exports.ox_inventory:AddItem(source, itemCurrency, itemObject.itemWorth * itemObject.itemCount)
        exports.ox_inventory:RemoveItem(source, itemObject.itemKey, itemObject.itemCount)
    end

    if handlerType == "buy" then
        if exports.ox_inventory:GetItemCount(source, itemCurrency) < itemObject.itemWorth * itemObject.itemCount then
            ShowNotification(source, Translate("not_enough_money"), TYPE_ERROR)
            return
        end

        if not exports.ox_inventory:CanCarryItem(source, itemObject.itemKey, itemObject.itemCount) then
            ShowNotification(source, Translate("not_enough_space"), TYPE_ERROR)
            return
        end

        exports.ox_inventory:RemoveItem(source, itemCurrency, itemObject.itemWorth * itemObject.itemCount)
        exports.ox_inventory:AddItem(source, itemObject.itemKey, itemObject.itemCount)
    end
end)

RegisterNetEvent("tomic_territories:captureComplete", function(terId, newOwner, newLabel, previousOwner)
    local currentTerritory = territories[terId]
    currentTerritory.isTaking, currentTerritory.owner, currentTerritory.label = false, newOwner, newLabel

    MySQL.query(queries.UPDATE_TERRITORY, { newOwner, newLabel, terId })

    if shared.rewards.on then
        RewardPlayers(newOwner, currentTerritory.name)
    end

    if shared.rankings then
        MySQL.query(queries.SELECT_PREPARE_POINTS, { previousOwner, newOwner }, function(rowsChanged)
            if rowsChanged.affectedRows == 0 then
                lib.print.error("An error has occured while updating the points!")
                return
            end

            for i = 1, #rowsChanged do
                local result = rowsChanged[i]
                local name, weeklyPoints, monthlyPoints, totalPoints = result.name, result.weeklyPoints,
                    result.monthlyPoints, result.totalPoints

                weeklyPoints = (name == previousOwner) and weeklyPoints - 2 or (name == newOwner) and weeklyPoints + 3 or
                    weeklyPoints
                monthlyPoints = (name == previousOwner) and monthlyPoints - 2 or (name == newOwner) and monthlyPoints + 3 or
                    monthlyPoints
                totalPoints = (name == previousOwner) and totalPoints - 2 or (name == newOwner) and totalPoints + 3 or
                    totalPoints

                MySQL.query(queries.UPDATE_POINTS, { weeklyPoints, monthlyPoints, totalPoints, name })
            end
        end)
    end

    TriggerClientEvent("tomic_territories:updateTerritories", -1, territories)

    Wait(shared.cooldown * 60000)

    currentTerritory.isCooldown = false

    TriggerClientEvent("tomic_territories:updateTerritories", -1, territories)
end)

function RewardPlayers(terOwner, terName)
    local jobMembers = ESX.GetExtendedPlayers("job", terOwner)

    for _, xPlayer in pairs(jobMembers) do
        exports.ox_inventory:AddItem(xPlayer.source, shared.rewards.item, shared.rewards.count)
        ShowNotification(xPlayer.source, Translate("territory_reward"):format(shared.rewards.count, terName), TYPE_INFO)
    end
end

RegisterNetEvent("tomic_territories:endCapturing", function(id)
    local currentTerritory = territories[id]
    currentTerritory.isTaking = false
    TriggerClientEvent("tomic_territories:updateTerritories", -1, territories)

    Wait(shared.cooldown * 60000)

    currentTerritory.isCooldown = false
    TriggerClientEvent("tomic_territories:updateTerritories", -1, territories)
end)

if shared.rankings then
    lib.cron.new("0 0 * * 1", function()
        local affectedRows = MySQL.query.await(queries.UPDATE_RESET_POINTS)

        if not affectedRows then
            lib.print.error("An error has occurred during the weekly reset of points!")
            return
        end

        lib.print.info("Weekly points reset completed successfully")
    end)
end
