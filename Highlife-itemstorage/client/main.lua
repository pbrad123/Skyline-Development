local QBCore = exports['qb-core']:GetCoreObject()
Config = {Qbcore = nil, openstorage = nil}

-- Open Item Storage Event
RegisterNetEvent('itemstorage:client:OpenItemStorage', function(item, weight, slots, label, stashitems)
    QBCore.Functions.TriggerCallback('itemstorage:GenerateUniqueName', function(result)
        if result then
            -- Set the current stash using the generated unique name
            TriggerEvent("inventory:client:SetCurrentStash", result)

            -- After setting the stash, optionally create the inventory
            TriggerEvent('itemstorage:client:CreateInventory', result, weight, slots)
        else
            -- Handle error if result is nil (in case the unique name generation failed)
            QBCore.Functions.Notify("Failed to generate stash name.", "error")
        end
    end, label, item, stashitems, weight, slots)
end)

-- Create Inventory Event
RegisterNetEvent('itemstorage:client:CreateInventory', function(result, weight, slots)
    if result then
        -- Open inventory with the specified weight and slots
        TriggerServerEvent("inventory:server:OpenInventory", "stash", result, {
            maxweight = weight,
            slots = slots,
        })
    else
        -- If result is invalid, notify the player
        QBCore.Functions.Notify("Invalid stash name.", "error")
    end
end)

-- Optional: Move item to stash
RegisterNetEvent('itemstorage:client:MoveItemToStash', function(item, quantity)
    if item and quantity then
        -- Trigger the server to move the item to the stash
        TriggerServerEvent('itemstorage:server:MoveItemToStash', item, quantity)
    else
        QBCore.Functions.Notify("Invalid item or quantity.", "error")
    end
end)

-- Optional: Move item from stash
RegisterNetEvent('itemstorage:client:MoveItemFromStash', function(item, quantity)
    if item and quantity then
        -- Trigger the server to move the item from the stash
        TriggerServerEvent('itemstorage:server:MoveItemFromStash', item, quantity)
    else
        QBCore.Functions.Notify("Invalid item or quantity.", "error")
    end
end)
