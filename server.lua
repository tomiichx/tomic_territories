local territories = {}
local queries = {
    SELECT_POINTS = 'SELECT * FROM jobs',
    SELECT_PREPARE_POINTS = 'SELECT * FROM jobs WHERE name IN (?, ?)',
    SELECT_TERRITORY = 'SELECT * FROM tomic_territories',
    INSERT_TERRITORY = 'INSERT INTO tomic_territories (id, name, owner, radius, label, type, coords) VALUES (?, ?, ?, ?, ?, ?, ?)',
    UPDATE_POINTS = 'UPDATE jobs SET weeklyPoints = ?, monthlyPoints = ?, totalPoints = ? WHERE name = ?',
    UPDATE_RESET_POINTS = "UPDATE jobs SET weeklyPoints = 0",
    UPDATE_TERRITORY = 'UPDATE tomic_territories SET owner = ?, label = ? WHERE id = ?',
    DELETE_TERRITORY = 'DELETE FROM tomic_territories WHERE name = ?'
}

CreateThread(function()
    MySQL.query(queries.SELECT_TERRITORY, function(data)
        if data then
            territories = {}
            for i = 1, #data, 1 do
                table.insert(territories, { id = data[i].id, name = data[i].name, owner = data[i].owner, radius = data[i].radius, label = data[i].label, type = data[i].type, coords = json.decode(data[i].coords), isTaking = false, progress = 0, isCooldown = false })
                exports.ox_inventory:RegisterStash('devTomic-Ter[' .. data[i].name .. '][' .. data[i].id .. ']', 'devTomic | Territory: ' .. data[i].name, 50, 100000)
                print('devTomic | Registered stash: devTomic-' .. data[i].id .. ' | Territory: ' .. data[i].name .. '')
            end
        end
    end)
    checkForUpdates()
end)

ESX.RegisterServerCallback('tomic_territories:getTerritories', function(source, cb)
    cb(territories)
end)

if shared.rankings then
    ESX.RegisterServerCallback('tomic_territories:fetchPoints', function(source, cb)
        MySQL.query(queries.SELECT_POINTS, function(cbResults)
            if cbResults then
                cb(cbResults)
            end
        end)
    end)
end

RegisterCommand(shared.command, function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)

    if source == 0 then
        return print('devTomic | Command can only be used in-game!')
    end

    if not inArray(shared.groups, xPlayer.getGroup()) then
        return xPlayer.showNotification('devTomic | You do not have permission to use this command!')
    end

    if args[1] == nil then
        return xPlayer.showNotification('devTomic | Usage: /territory [create/delete]')
    end

    if args[1] == 'create' then
        TriggerClientEvent('tomic_territories:createTerritory', source)
    end

    if args[1] == 'delete' then
        TriggerClientEvent('tomic_territories:deleteTerritory', source)
    end
end, false)

RegisterNetEvent('tomic_territories:createTerritory')
AddEventHandler('tomic_territories:createTerritory', function(territoryInfo)
    local xPlayer = ESX.GetPlayerFromId(source)

    for i = 1, #territories, 1 do
        if territories[i].name == territoryInfo.name then
            return xPlayer.showNotification('devTomic | Territory with that name already exists!')
        end
    end

    local territory = {
        id = #territories + 1,
        name = territoryInfo.name,
        owner = 'noone',
        radius = territoryInfo.radius,
        label = 'NoOne',
        type = territoryInfo.type or 'default',
        coords = territoryInfo.coords,
        progress = 0,
        isTaking = false,
        isCooldown = false
    }

    MySQL.query(queries.INSERT_TERRITORY, { territory.id, territory.name, territory.owner, territory.radius, territory.label, territory.type, json.encode(territory.coords) }, function(rowsChanged)
        if rowsChanged.affectedRows == 0 then
            return xPlayer.showNotification('devTomic | Territory creation failed!')
        end

        table.insert(territories, territory)
        exports.ox_inventory:RegisterStash('devTomic-Ter[' .. territory.name .. '][' .. territory.id .. ']', 'devTomic | Territory: ' .. territory.name, 50, 100000)
        TriggerClientEvent('tomic_territories:updateTerritories', -1, territories)
        xPlayer.showNotification('devTomic | Territory created!')
    end)
end)

RegisterNetEvent('tomic_territories:deleteTerritory')
AddEventHandler('tomic_territories:deleteTerritory', function(territoryName)
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.query(queries.DELETE_TERRITORY, { territoryName }, function(rowsChanged)
        if rowsChanged.affectedRows == 0 then
            return xPlayer.showNotification('devTomic | Territory deletion failed!')
        end

        for i = 1, #territories, 1 do
            if territories[i].name == territoryName then
                table.remove(territories, i)
                break
            end
        end

        Wait(500)
        TriggerClientEvent('tomic_territories:updateTerritories', -1, territories)
        xPlayer.showNotification('devTomic | Territory deleted!')
    end)
end)

RegisterNetEvent('tomic_territories:captureServer')
AddEventHandler('tomic_territories:captureServer', function(id, job, label, name, currentOwner)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local xPlayers = ESX.GetPlayers()
    for i = 1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])

        if xPlayer.job.name == currentOwner then
            xPlayer.showNotification('devTomic | Territory: ' .. name .. ' is being attacked by another gang!')
        end

        if xPlayer.job.name == job then
            xPlayer.showNotification('devTomic | Your gang started attacking territory ' .. name .. '!')
        end
    end

    local currentTerritory = territories[id]
    currentTerritory.isTaking, currentTerritory.isCooldown = true, true
    TriggerClientEvent('tomic_territories:updateTerritories', -1, territories)
    TriggerClientEvent('tomic_territories:updateBlips', -1, id, job, label)
    TriggerClientEvent('tomic_territories:captureProgress', source, id, currentTerritory)
    print(GetPlayerName(xPlayer.source) .. ' started capturing: ' .. name)
end)

RegisterNetEvent('tomic_territories:sellDealer')
AddEventHandler('tomic_territories:sellDealer', function(itemObject)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getInventoryItem(itemObject.itemKey).count < itemObject.itemCount then
        return xPlayer.showNotification('devTomic | You do not have that amount!')
    end

    if itemObject.itemCurrency then
        xPlayer.addAccountMoney('black_money', itemObject.itemWorth * itemObject.itemCount)
    else
        xPlayer.addMoney(itemObject.itemWorth * itemObject.itemCount)
    end

    xPlayer.removeInventoryItem(itemObject.itemKey, itemObject.itemCount)
end)

RegisterNetEvent('tomic_territories:buyMarket')
AddEventHandler('tomic_territories:buyMarket', function(itemObject)
    local xPlayer = ESX.GetPlayerFromId(source)
    if itemObject.itemCurrency then
        if xPlayer.getAccount('black_money').money < itemObject.itemWorth * itemObject.itemCount then
            return xPlayer.showNotification('devTomic | You do not have enough black money!')
        end

        if not xPlayer.canCarryItem(itemObject.itemKey, itemObject.itemCount) then
            return xPlayer.showNotification('devTomic | You do not have any space in your inventory!')
        end

        xPlayer.removeAccountMoney('black_money', itemObject.itemWorth * itemObject.itemCount)
    else
        if xPlayer.getMoney() < itemObject.itemWorth * itemObject.itemCount then
            return xPlayer.showNotification('devTomic | You do not have enough money!')
        end

        if not xPlayer.canCarryItem(itemObject.itemKey, itemObject.itemCount) then
            return xPlayer.showNotification('devTomic | You do not have any space in your inventory!')
        end

        xPlayer.removeMoney(itemObject.itemWorth * itemObject.itemCount)
    end

    xPlayer.addInventoryItem(itemObject.itemKey, itemObject.itemCount)
end)

RegisterNetEvent('tomic_territories:captureComplete')
AddEventHandler('tomic_territories:captureComplete', function(terId, newOwner, newLabel, previousOwner)
    local currentTerritory = territories[terId]
    currentTerritory.isTaking, currentTerritory.owner, currentTerritory.label = false, newOwner, newLabel

    MySQL.query(queries.UPDATE_TERRITORY, { newOwner, newLabel, terId })

    if shared.rewards.on then
        TriggerEvent('tomic_territories:rewardPlayers', newOwner, currentTerritory.name)
    end

    if shared.rankings then
        MySQL.query(queries.SELECT_PREPARE_POINTS, { previousOwner, newOwner }, function(results)
            for i = 1, #results do
                local result = results[i]
                local name = result.name
                local points = result.totalPoints
            
                if name == previousOwner then
                    points = points - 2
                elseif name == newOwner then
                    points = points + 3
                end
            
                MySQL.query(queries.UPDATE_POINTS, { points, points, points, name })
            end
        end)
    end

    TriggerClientEvent('tomic_territories:updateTerritories', -1, territories)

    Wait(shared.cooldown * 60000)

    currentTerritory.isCooldown = false

    TriggerClientEvent('tomic_territories:updateTerritories', -1, territories)
end)

RegisterNetEvent('tomic_territories:rewardPlayers')
AddEventHandler('tomic_territories:rewardPlayers', function(terOwner, terName)
    local xPlayers = ESX.GetPlayers()
    for i = 1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer.job.name == terOwner then
            xPlayer.addInventoryItem(shared.rewards.item, shared.rewards.count)
            xPlayer.showNotification('devTomic | You got $' .. shared.rewards.count .. ' as a reward for capturing: ' .. terName .. '!')
        end
    end
end)

RegisterNetEvent('tomic_territories:endCapturing')
AddEventHandler('tomic_territories:endCapturing', function(id)
    local currentTerritory = territories[id]
    currentTerritory.isTaking = false
    TriggerClientEvent('tomic_territories:updateTerritories', -1, territories)

    Wait(shared.cooldown * 60000)

    currentTerritory.isCooldown = false
    TriggerClientEvent('tomic_territories:updateTerritories', -1, territories)
end)

if shared.rankings then
    function Reset(d, h, m)
        if d == 1 and h == 0 and m == 0 then
            MySQL.query(queries.UPDATE_RESET_POINTS)
        end
    end

    TriggerEvent('cron:runAt', 0, 0, Reset)
end

function inArray(array, value)
    for i, v in pairs(array) do
        if v == value then
            return true
        end
    end

    return false
end

function checkForUpdates()
    local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
    PerformHttpRequest('https://api.github.com/repos/tomiichx/tomic_territories/releases/latest', function(code, response)
        if code ~= 200 then
            return print('devTomic | There was an error while checking for updates.')
        end

        local returnedData = json.decode(response)
        local latestVersion, downloadLink = returnedData.tag_name, returnedData.html_url

        if currentVersion == latestVersion then
            return print('devTomic | You are using the latest version of ' .. GetCurrentResourceName())
        end

        print('\n')
        print('devTomic | There is a new update available for ' .. GetCurrentResourceName())
        print('devTomic | Your version: ' .. currentVersion .. ' | New version: ' .. latestVersion)
        print('devTomic | Download it from: ' .. downloadLink)
        print('\n')
    end, 'GET')
end
