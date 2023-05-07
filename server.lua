local territories = {}
local queries = {
    SELECT_POINTS = 'SELECT * FROM factions WHERE name IN (?)',
    SELECT_PREPARE_POINTS = 'SELECT * FROM factions WHERE name IN (?, ?)',
    SELECT_TERRITORY = 'SELECT * FROM tomic_territories',
    INSERT_TERRITORY = 'INSERT INTO tomic_territories (id, name, owner, radius, label, type, coords) VALUES (?, ?, ?, ?, ?, ?, ?)',
    UPDATE_POINTS = 'UPDATE factions SET weeklyPoints = ?, monthlyPoints = ?, totalPoints = ? WHERE name = ?',
    UPDATE_RESET_POINTS = 'UPDATE factions SET weeklyPoints = 0',
    UPDATE_TERRITORY = 'UPDATE tomic_territories SET owner = ?, label = ? WHERE id = ?',
    DELETE_TERRITORY = 'DELETE FROM tomic_territories WHERE name = ?'
}
local alreadyUsed = {}

CreateThread(function()
    MySQL.query(queries.SELECT_TERRITORY, function(rowsReturned)
        if rowsReturned then
            territories = {}
            for i = 1, #rowsReturned, 1 do
                insert(territories, { id = rowsReturned[i].id, name = rowsReturned[i].name, owner = rowsReturned[i].owner, radius = rowsReturned[i].radius, label = rowsReturned[i].label, type = rowsReturned[i].type, coords = json.decode(rowsReturned[i].coords), isTaking = false, progress = 0, isCooldown = false, attenders = {} })
                exports.ox_inventory:RegisterStash('[' .. rowsReturned[i].name .. '][' .. rowsReturned[i].id .. ']', 'Territoire : ' .. rowsReturned[i].name, 50, 100000)
                debugPrint('Registered stash: ' .. rowsReturned[i].id .. ' | Territoire : ' .. rowsReturned[i].name .. '')
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
        MySQL.query(queries.SELECT_POINTS, { getAllowedJobs() }, function(rowsReturned)
            if not rowsReturned then return end
            cb(rowsReturned)
        end)
    end)
end

RegisterCommand(shared.adminCommand, function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)

    if source == 0 then
        return print('Command can only be used in-game!')
    end

    if not inArray(shared.groups, xPlayer.getGroup()) then
        return xPlayer.showNotification(translateMessage('no_permission'))
    end

    if args[1] == nil then
        return xPlayer.showNotification(translateMessage('no_args'))
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
            return xPlayer.showNotification(translateMessage('territory_already_exists'))
        end
    end

    local territory = {
        id = #territories + 1,
        name = territoryInfo.name,
        owner = 'noone',
        radius = territoryInfo.radius,
        label = 'Aucun',
        type = territoryInfo.type or 'default',
        coords = territoryInfo.coords,
        progress = 0,
        isTaking = false,
        isCooldown = false
    }

    MySQL.query(queries.INSERT_TERRITORY, { territory.id, territory.name, territory.owner, territory.radius, territory.label, territory.type, json.encode(territory.coords) }, function(rowsChanged)
        if rowsChanged.affectedRows == 0 then
            return xPlayer.showNotification(translateMessage('territory_creation_failed'))
        end

        insert(territories, territory)
        exports.ox_inventory:RegisterStash('[' .. territory.name .. '][' .. territory.id .. ']', 'Territoire : ' .. territory.name, 50, 100000)
        TriggerClientEvent('tomic_territories:updateTerritories', -1, territories)
        xPlayer.showNotification(translateMessage('territory_created'))
    end)
end)

RegisterNetEvent('tomic_territories:deleteTerritory')
AddEventHandler('tomic_territories:deleteTerritory', function(territoryName)
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.query(queries.DELETE_TERRITORY, { territoryName }, function(rowsChanged)
        if rowsChanged.affectedRows == 0 then
            return xPlayer.showNotification(translateMessage('territory_deletion_failed'))
        end

        for i = 1, #territories, 1 do
            if territories[i].name == territoryName then
                table.remove(territories, i)
                break
            end
        end

        Wait(500)
        TriggerClientEvent('tomic_territories:updateTerritories', -1, territories)
        xPlayer.showNotification(translateMessage('territory_deleted'))
    end)
end)

local function updateAttenders(id, identifier, faction, inTerritory, isDead)
    local territory = territories[id]
    if not territory or not identifier or not shared.gangs[faction] then return end
    local attenders, found, isDefender = territory.attenders, false, territory.owner == faction

    for i = 1, #attenders do
        if attenders[i].playerIdentifier == identifier then
            found = true
            if isDead or not inTerritory then
                table.remove(attenders, i)
                TriggerClientEvent('tomic_territories:updateUI', source, 'hideUI', attenders)
                break
            end
        end
    end

    local territoryStatusMessage = isDefender and translateMessage('defender_message') or translateMessage('attacker_message')
    if inTerritory and not found and not isDead then
        insert(attenders, {
            playerIdentifier = identifier, playerJob = faction, isPlayerDefender = isDefender,
            territoryName = territory.name, territoryStatus = territoryStatusMessage
        })
    end

    for i = 1, #attenders do
        local xPlayer = ESX.GetPlayerFromIdentifier(attenders[i].playerIdentifier)
        if xPlayer then TriggerClientEvent('tomic_territories:updateUI', xPlayer.source, 'showUI', attenders) end
    end
end
RegisterNetEvent('tomic_territories:updateAttenders')
AddEventHandler('tomic_territories:updateAttenders', updateAttenders)

RegisterNetEvent('tomic_territories:captureServer')
AddEventHandler('tomic_territories:captureServer', function(id, faction, name, currentOwner)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xPlayers = ESX.GetPlayers()
    for i = 1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])

        if xPlayer.faction.name == currentOwner then
            xPlayer.showNotification(string.format(translateMessage('territory_being_attacked'), name))
        end

        if xPlayer.faction.name == faction then
            xPlayer.showNotification(string.format(translateMessage('territory_started_attacking'), name))
        end
    end

    local currentTerritory = territories[id]
    currentTerritory.isTaking, currentTerritory.isCooldown = true, true
    TriggerClientEvent('tomic_territories:updateTerritories', -1, territories)
    TriggerClientEvent('tomic_territories:updateBlips', -1, id, faction)
    TriggerClientEvent('tomic_territories:captureProgress', source, id, currentTerritory)
    debugPrint(GetPlayerName(xPlayer.source) .. 'commence à capturer : ' .. name)
end)

RegisterNetEvent('tomic_territories:marketHandler')
AddEventHandler('tomic_territories:marketHandler', function(itemObject, handlerType)
    local xPlayer = ESX.GetPlayerFromId(source)
    local itemCurrency = itemObject.itemCurrency and 'black_money' or 'money'

    if handlerType == 'sell' then
        if xPlayer.getInventoryItem(itemObject.itemKey).count < itemObject.itemCount then
            return xPlayer.showNotification(translateMessage('invalid_amount'))
        end

        xPlayer.addAccountMoney(itemCurrency, itemObject.itemWorth * itemObject.itemCount)
        xPlayer.removeInventoryItem(itemObject.itemKey, itemObject.itemCount)
    end

    if handlerType == 'buy' then
        if xPlayer.getAccount(itemCurrency).money < itemObject.itemWorth * itemObject.itemCount then
            return xPlayer.showNotification(translateMessage('not_enough_money'))
        end

        if not xPlayer.canCarryItem(itemObject.itemKey, itemObject.itemCount) then
            return xPlayer.showNotification(translateMessage('not_enough_space'))
        end

        xPlayer.removeAccountMoney(itemCurrency, itemObject.itemWorth * itemObject.itemCount)
        xPlayer.addInventoryItem(itemObject.itemKey, itemObject.itemCount)
    end
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
        MySQL.query(queries.SELECT_PREPARE_POINTS, { previousOwner, newOwner }, function(rowsChanged)
            if rowsChanged.affectedRows == 0 then
                return debugPrint('Une erreur s\'est produite lors de la mise à jour des points !')
            end

            for i = 1, #rowsChanged do
                local result = rowsChanged[i]
                local name, weeklyPoints, monthlyPoints, totalPoints = result.name, result.weeklyPoints, result.monthlyPoints, result.totalPoints

                weeklyPoints = (name == previousOwner) and weeklyPoints - 2 or (name == newOwner) and weeklyPoints + 3 or weeklyPoints
                monthlyPoints = (name == previousOwner) and monthlyPoints - 2 or (name == newOwner) and monthlyPoints + 3 or monthlyPoints
                totalPoints = (name == previousOwner) and totalPoints - 2 or (name == newOwner) and totalPoints + 3 or totalPoints
                debugPrint({ name, weeklyPoints, monthlyPoints, totalPoints })

                MySQL.query(queries.UPDATE_POINTS, { weeklyPoints, monthlyPoints, totalPoints, name })
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
        if xPlayer.faction.name == terOwner then
            xPlayer.addInventoryItem(shared.rewards.item, shared.rewards.count)
            xPlayer.showNotification(string.format(translateMessage('territory_reward'), shared.rewards.count, terName))
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

function getAllowedJobs()
    local jobsArray = {}
    for k in pairs(shared.gangs) do
        insert(jobsArray, k)
    end

    return jobsArray
end

function checkForUpdates()
    local resourceName = GetCurrentResourceName()
    local currentVersion = GetResourceMetadata(resourceName, 'version', 0)
    PerformHttpRequest('https://api.github.com/repos/tomiichx/tomic_territories/releases/latest', function(code, response)
        if code ~= 200 then
            return print('Une erreur s\'est produite lors de la vérification des mises à jour.')
        end

        local returnedData = json.decode(response)
        local latestVersion, downloadLink = returnedData.tag_name, returnedData.html_url

        if currentVersion == latestVersion then
            return print('Vous utilisez la dernière version de' .. resourceName)
        end

        print('\n')
        print('devTomic | Une nouvelle mise à jour est disponible pour ' .. resourceName)
        print('devTomic | Ta version : ' .. currentVersion .. ' | Nouvelle version : ' .. latestVersion)
        print('devTomic | Téléchargez-le depuis : ' .. downloadLink)
        print('\n')

        debugPrint('Une nouvelle mise à jour est disponible pour ' .. resourceName .. '. Ta version : ' .. currentVersion .. ' | Nouvelle version : ' .. latestVersion .. '. Téléchargez-le depuis : ' .. downloadLink)
    end, 'GET')
end

function logAction(header, message, footer)
    local embed = {
        {
            ['color'] = 16711680,
            ['title'] = header or '',
            ['description'] = message or '',
            ['footer'] = {
                ['text'] = footer or ('' .. os.date('%Y-%m-%d %H:%M:%S'))
            }
        }
    }

    PerformHttpRequest('https://ptb.discord.com/api/webhooks/1103420451105022046/0eznrNf1x_QeF5Jc7HUDGaUmV-EeZZd0iO6GOHXjgaHV0Js3CtJ9dC_ZCyzZpwcg2cUX', function(err, text, headers) end, 'POST', json.encode({ username = 'Territoires', embeds = embed }), { ['Content-Type'] = 'application/json' })
end
RegisterNetEvent('tomic_territories:logAction')
AddEventHandler('tomic_territories:logAction', logAction)

RegisterCommand("terbug", function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)

    if source == 0 then
        return print('La commande ne peut être utilisée que dans le jeu !')
    end

    if not inArray(shared.groups, xPlayer.getGroup()) then
        return xPlayer.showNotification(translateMessage('no_permission'))
    end

    if alreadyUsed[xPlayer.identifier] then
        return xPlayer.showNotification(translateMessage('already_used'))
    end

    local sourceInfo = {
        ['name'] = xPlayer.getName() .. ' (' .. GetPlayerName(source) .. ')' or 'Unknown',
        ['steam'] = xPlayer.identifier or 'Unknown',
    }

    local header = 'Rapport de bogue de ' .. sourceInfo.name .. ' (' .. sourceInfo.steam .. ')'
    local message = GetCurrentResourceName() .. ' | ' .. table.concat(args, ' ')

    if message == nil or message == "" then
        return xPlayer.showNotification(translateMessage('no_message'))
    end

    alreadyUsed[xPlayer.identifier] = true
    logAction(header, message)
end, false)