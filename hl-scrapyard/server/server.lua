local QBCore = exports['qb-core']:GetCoreObject()
local triggerCounts = {} -- Tracks how many missions a player has started today
local activeMissions = {} -- Tracks active missions for each player

-- Start Mission
RegisterNetEvent('hl-scrapyard:start')
AddEventHandler('hl-scrapyard:start', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid

    -- Initialize trigger count if not already set
    if not triggerCounts[citizenid] then
        triggerCounts[citizenid] = 0
    end

    -- Check if player has reached the daily mission limit
    if triggerCounts[citizenid] >= Config.MaxPerDay then
        QBCore.Functions.Notify(src, 'You have reached the maximum number of missions for today.', 'error')
        return
    end

    -- Increment mission count
    triggerCounts[citizenid] = triggerCounts[citizenid] + 1

    -- Generate mission data
    local missionData = {
        citizenid = citizenid,
        vehicleModel = Config.Vehicles[math.random(1, #Config.Vehicles)],
        partsToSalvage = GeneratePartsList(),
        partsSalvaged = {},
        startTime = os.time(),
        status = 'active',
        pickupLocation = Config.PickupLocations[math.random(1, #Config.PickupLocations)] -- Random pickup location
    }

    -- Store mission data
    activeMissions[citizenid] = missionData

    -- Notify player and send mission data to client
    TriggerClientEvent('hl-scrapyard:startquest', src, missionData.pickupLocation)
    QBCore.Functions.Notify(src, "Mission started! Find the marked vehicle and salvage its parts.", "success")
end)

-- Generate random parts list
function GeneratePartsList()
    local parts = {
        'engine', 'transmission', 'hood', 'trunk',
        'wheel_lf', 'wheel_rf', 'wheel_lr', 'wheel_rr',
        'door_dside_f', 'door_pside_f', 'door_dside_r', 'door_pside_r'
    }

    local selectedParts = {}
    local numParts = math.random(3, 6) -- Random number of parts to salvage

    for i = 1, numParts do
        local part = parts[math.random(1, #parts)]
        if not selectedParts[part] then
            selectedParts[part] = true
        end
    end

    return selectedParts
end

-- Register part delivery
RegisterNetEvent('hl-scrapyard:deliverpart')
AddEventHandler('hl-scrapyard:deliverpart', function(partType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid

    -- Check if player has an active mission
    if not activeMissions[citizenid] then
        QBCore.Functions.Notify(src, "No active mission found.", "error")
        return
    end

    -- Add part to salvaged list
    activeMissions[citizenid].partsSalvaged[partType] = true

    -- Add item to inventory
    if Player.Functions.AddItem('salvaged_part', 1) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['salvaged_part'], "add")
        QBCore.Functions.Notify(src, "You received a salvaged part.", "success")
    else
        QBCore.Functions.Notify(src, "Inventory full, cannot receive the part.", "error")
        return
    end

    -- Calculate reward and add money
    local partValue = CalculatePartValue(partType)
    Player.Functions.AddMoney(Config.PaymentType, partValue, 'scrapyard-part-delivery')
    QBCore.Functions.Notify(src, ("You received $%s for delivering the %s."):format(partValue, partType), "success")

    -- Check if mission is complete
    if CheckMissionComplete(citizenid) then
        CompleteMission(citizenid, src)
    end
end)

-- Calculate part value
function CalculatePartValue(partType)
    local baseValues = {
        ['engine'] = 1200,
        ['transmission'] = 800,
        ['hood'] = 400,
        ['trunk'] = 350,
        ['wheel_lf'] = 250,
        ['wheel_rf'] = 250,
        ['wheel_lr'] = 250,
        ['wheel_rr'] = 250,
        ['door_dside_f'] = 300,
        ['door_pside_f'] = 300,
        ['door_dside_r'] = 300,
        ['door_pside_r'] = 300
    }

    local value = baseValues[partType] or 0
    return math.random(value * 0.8, value * 1.2) -- Randomize value within 80-120% range
end

-- Check if mission is complete
function CheckMissionComplete(citizenid)
    local mission = activeMissions[citizenid]
    if not mission then return false end

    for part, _ in pairs(mission.partsToSalvage) do
        if not mission.partsSalvaged[part] then
            return false
        end
    end
    return true
end

-- Complete mission
function CompleteMission(citizenid, src)
    local mission = activeMissions[citizenid]
    if not mission then return end

    -- Calculate bonus reward
    local timeTaken = os.time() - mission.startTime
    local timeBonus = math.max(0, 1000 - (timeTaken * 2)) -- $1 per second under 500 seconds
    local completionBonus = 1000 * tablelength(mission.partsToSalvage)
    local totalReward = timeBonus + completionBonus

    -- Add reward to player
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.AddMoney(Config.PaymentType, totalReward, 'scrapyard-mission-completion')
    QBCore.Functions.Notify(src, ("Mission complete! You received $%s bonus for completing the mission quickly."):format(totalReward), "success")

    -- Clean up mission data
    activeMissions[citizenid] = nil
    TriggerClientEvent('hl-scrapyard:missioncomplete', src)
end

-- Cancel mission
RegisterNetEvent('hl-scrapyard:cancelmission')
AddEventHandler('hl-scrapyard:cancelmission', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid

    if activeMissions[citizenid] then
        activeMissions[citizenid] = nil
        QBCore.Functions.Notify(src, "Mission cancelled.", "error")
        TriggerClientEvent('hl-scrapyard:missioncancelled', src)
    end
end)

-- Helper function to get table length
function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

-- Get mission status
QBCore.Functions.CreateCallback('hl-scrapyard:getmissionstatus', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local citizenid = Player.PlayerData.citizenid
    cb(activeMissions[citizenid] or false)
end)

-- Register callback to get parts
QBCore.Functions.CreateCallback('hl-scrapyard:server:getParts', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return cb({}) end
    
    local parts = {}
    
    -- Check inventory for salvaged parts
    local items = Player.PlayerData.items
    if items then
        for k, item in pairs(items) do
            if item and item.name and item.name:find("salvaged_") then
                table.insert(parts, {
                    name = item.name,
                    amount = item.amount,
                    slot = item.slot
                })
            end
        end
    end
    
    -- Debug info
    print("Player " .. src .. " has " .. #parts .. " salvaged parts")
    cb(parts)
end)

-- Register event to sell parts
RegisterNetEvent('hl-scrapyard:server:sellParts', function(parts)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local totalPrice = 0
    local partsSold = 0
    
    print("Player " .. src .. " attempting to sell " .. #parts .. " parts")
    
    for _, part in pairs(parts) do
        -- Check if the player still has the item
        local hasItem = Player.Functions.GetItemByName(part.name)
        
        if hasItem and hasItem.amount >= part.amount then
            -- Get price from config or use default value
            local price = (Config.PartPrices and Config.PartPrices[part.name]) or 500 -- Default 500 if no config found
            local payAmount = price * part.amount
            
            totalPrice = totalPrice + payAmount
            partsSold = partsSold + part.amount
            
            -- Remove item from inventory
            Player.Functions.RemoveItem(part.name, part.amount, part.slot)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[part.name], "remove", part.amount)
            
            print("Removed " .. part.amount .. "x " .. part.name .. " from player " .. src .. " at $" .. price .. " each")
        else
            print("Player " .. src .. " does not have " .. part.name .. " in inventory or insufficient amount")
        end
    end
    
    -- Add money to player
    if totalPrice > 0 then
        Player.Functions.AddMoney("cash", totalPrice)
        TriggerClientEvent('QBCore:Notify', src, "You received $" .. totalPrice .. " for selling " .. partsSold .. " parts", "success")
        print("Player " .. src .. " received $" .. totalPrice .. " for selling " .. partsSold .. " parts")
    else
        TriggerClientEvent('QBCore:Notify', src, "No valid parts to sell", "error")
    end
end)

-- Admin command to reset daily limits
QBCore.Commands.Add("resetscrapyard", "Reset scrapyard daily limits (Admin Only)", {}, false, function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == 'admin' then
        triggerCounts = {}
        QBCore.Functions.Notify(source, "Scrapyard daily limits reset.", "success")
    else
        QBCore.Functions.Notify(source, "You don't have permission to do this.", "error")
    end
end, "admin")

-- Event to give vehicle details item
RegisterNetEvent('hl-scrapyard:giveVehicleDetails', function(vehicleModel, vehicleLabel)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        Player.Functions.AddItem('vehicle_details', 1, false, {
            model = vehicleModel,
            label = vehicleLabel
        })
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['vehicle_details'], "add")
    end
end)
