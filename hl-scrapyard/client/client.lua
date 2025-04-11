local QBCore = exports['qb-core']:GetCoreObject()
local currentJob = false
local vehicle = nil
local doorArray = {}
local count = 0
local demolishSuccess = 0
local activeMission = false
local deliveryBlip = nil
local carryingPart = false
local currentPart = nil
local salvageParts = {}
local missionStage = 0 -- 0: not started, 1: finding vehicle, 2: salvaging parts, 3: delivering parts
local sellPed = nil
local sellBlip = nil

-- Add outline functionality
local currentHighlight = nil

-- Function to highlight a part
function HighlightPart(entity, boneIndex)
    if currentHighlight then
        SetEntityDrawOutline(currentHighlight, false)
    end
    currentHighlight = entity
    SetEntityDrawOutline(entity, true)
    SetEntityDrawOutlineColor(255, 255, 255, 255) -- White outline
    SetEntityDrawOutlineShader(1) -- Thicker outline
end

-- Function to remove highlight
function RemoveHighlight()
    if currentHighlight then
        SetEntityDrawOutline(currentHighlight, false)
        currentHighlight = nil
    end
end

-- Prop objects for animations
local propList = {
    ['engine'] = 'prop_car_engine_01',
    ['transmission'] = 'imp_prop_impexp_gearbox_01',
    ['door'] = 'imp_prop_impexp_car_door_04a',
    ['hood'] = 'imp_prop_impexp_bonnet_02a',
    ['trunk'] = 'imp_prop_impexp_trunk_01a',
    ['wheel'] = 'prop_wheel_01',
    ['blowtorch'] = 'prop_ing_blowtorch',
    ['weldinggun'] = 'prop_weld_torch'
}

-- Blip Creation
CreateThread(function()
    -- Add default locations if Config.Locations is nil
    Config.Locations = Config.Locations or {
        {x = -458.0, y = -1718.0, z = 18.8} -- Default scrapyard location
    }

    for _, location in ipairs(Config.Locations) do
        local blip = AddBlipForCoord(location.x, location.y, location.z)
        SetBlipSprite(blip, Config.Blip.sprite or 467) -- Default sprite
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blip.scale or 0.8)
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, Config.Blip.color or 5)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.Blip.name or "Scrapyard")
        EndTextCommandSetBlipName(blip)
    end
end)

-- NPC Creation
CreateThread(function()
    local ped, pedSpawned = nil, false
    local animDict = 'mini@strip_club@idles@bouncer@base'
    local pedModel = 's_m_y_dockwork_01'

    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local npcCoords = vector3(Config.Npcspawn.x, Config.Npcspawn.y, Config.Npcspawn.z)
        local dist = #(coords - npcCoords)

        if dist <= 30 and not pedSpawned then
            sleep = 0
            RequestAnimDict(animDict)
            while not HasAnimDictLoaded(animDict) do
                Wait(100)
            end

            RequestModel(GetHashKey(pedModel))
            while not HasModelLoaded(GetHashKey(pedModel)) do
                Wait(100)
            end

            ped = CreatePed(4, GetHashKey(pedModel), npcCoords.x, npcCoords.y, npcCoords.z, Config.Npcheading, false, false)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetEntityAsMissionEntity(ped, true, true)
            TaskPlayAnim(ped, animDict, 'base', 8.0, 0.0, -1, 1, 0, false, false, false)

            if Config.UseTarget then
                exports['qb-target']:AddTargetEntity(ped, {
                    options = {
                        {
                            type = "client",
                            icon = Config.TargetIcon,
                            label = "Start Salvage Job",
                            action = function()
                                if not activeMission then
                                    TriggerServerEvent('hl-scrapyard:start')
                                else
                                    QBCore.Functions.Notify("You've already started a salvage mission.", "error")
                                end
                            end
                        },
                        {
                            type = "client",
                            icon = Config.TargetIcon,
                            label = "Cancel Salvage Job",
                            action = function()
                                CancelMission()
                            end,
                            canInteract = function()
                                return activeMission
                            end
                        },
                        {
                            type = "client",
                            icon = "fas fa-info-circle",
                            label = "Salvage Info",
                            action = function()
                                QBCore.Functions.Notify("Salvage and sell car parts for money!", "primary")
                                Wait(1000)
                                QBCore.Functions.Notify("Find cars, salvage parts and deliver them to the scrapyard.", "primary")
                            end
                        }
                    },
                    distance = 2.0
                })
            else
                -- For non-target systems, create a 3D text interaction
                CreateThread(function()
                    while pedSpawned do
                        sleep = 0
                        if dist <= 2.0 then
                            if not activeMission then
                                DrawText3D(npcCoords.x, npcCoords.y, npcCoords.z + 1.0, '[E] Start Salvage Job')
                                if IsControlJustPressed(0, 38) then -- E key
                                    TriggerServerEvent('hl-scrapyard:start')
                                end
                            else
                                DrawText3D(npcCoords.x, npcCoords.y, npcCoords.z + 1.0, '[E] Cancel Job | [G] Get Job Info')
                                if IsControlJustPressed(0, 38) then -- E key
                                    CancelMission()
                                elseif IsControlJustPressed(0, 47) then -- G key
                                    QBCore.Functions.Notify("Salvage and sell car parts for money!", "primary")
                                    Wait(1000)
                                    QBCore.Functions.Notify("Find cars, salvage parts and deliver them to the scrapyard.", "primary")
                                end
                            end
                        end
                        Wait(0)
                    end
                end)
            end
            pedSpawned = true
        elseif dist >= 31 and pedSpawned then
            sleep = 1000
            DeletePed(ped)
            SetModelAsNoLongerNeeded(GetHashKey(pedModel))
            RemoveAnimDict(animDict)
            pedSpawned = false

            if Config.UseTarget then
                exports['qb-target']:RemoveTargetEntity(ped)
            end
        end
        Wait(sleep)
    end
end)

-- Function to spawn the salvage vehicle
function SpawnSalvageVehicle(coords)
    -- Choose random vehicle
    local randomVehicle = Config.Vehicles[math.random(1, #Config.Vehicles)]

    -- Create the vehicle
    RequestModel(GetHashKey(randomVehicle))
    while not HasModelLoaded(GetHashKey(randomVehicle)) do
        Wait(100)
    end

    vehicle = CreateVehicle(GetHashKey(randomVehicle), coords.x, coords.y, coords.z, coords.w or 90.0, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleDoorsLocked(vehicle, 2)

    -- Create blip for the vehicle
    local vehicleBlip = AddBlipForEntity(vehicle)
    SetBlipSprite(vehicleBlip, Config.Blip.vehicle.sprite)
    SetBlipColour(vehicleBlip, Config.Blip.vehicle.color)
    SetBlipFlashes(vehicleBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Target Vehicle")
    EndTextCommandSetBlipName(vehicleBlip)

    QBCore.Functions.Notify("You found the vehicle! Salvage its parts using the interaction menu", "success")
    missionStage = 2

    -- Add target options
    SetupSalvageTargets()
    SetupNonTargetSalvage()
end

-- Setup salvage target options
function SetupSalvageTargets()
    if Config.UseTarget then
        -- Engine
        exports['qb-target']:AddTargetBone('engine', {
            options = {
                {
                    type = "client",
                    icon = "fas fa-oil-can",
                    label = "Remove Engine",
                    action = function()
                        SalvagePart('engine')
                    end,
                    canInteract = function()
                        return activeMission and missionStage == 2 and not salvageParts['engine']
                    end
                }
            },
            distance = 2.5
        })

        -- Doors (all 4 doors)
        for _, boneName in ipairs({'door_dside_f', 'door_pside_f', 'door_dside_r', 'door_pside_r'}) do
            exports['qb-target']:AddTargetBone(boneName, {
                options = {
                    {
                        type = "client",
                        icon = "fas fa-car-side",
                        label = "Remove Door",
                        action = function()
                            SalvagePart('door', boneName)
                        end,
                        canInteract = function()
                            return activeMission and missionStage == 2 and not salvageParts[boneName]
                        end
                    }
                },
                distance = 2.0
            })
        end

        -- Wheels (all 4 wheels)
        for _, boneName in ipairs({'wheel_lf', 'wheel_rf', 'wheel_lr', 'wheel_rr'}) do
            exports['qb-target']:AddTargetBone(boneName, {
                options = {
                    {
                        type = "client",
                        icon = "fas fa-circle",
                        label = "Remove Wheel",
                        action = function()
                            SalvagePart('wheel', boneName)
                        end,
                        canInteract = function()
                            return activeMission and missionStage == 2 and not salvageParts[boneName]
                        end
                    }
                },
                distance = 2.0
            })
        end

        -- Hood
        exports['qb-target']:AddTargetBone('bonnet', {
            options = {
                {
                    type = "client",
                    icon = "fas fa-car",
                    label = "Remove Hood",
                    action = function()
                        SalvagePart('hood')
                    end,
                    canInteract = function()
                        return activeMission and missionStage == 2 and not salvageParts['bonnet']
                    end
                }
            },
            distance = 2.0
        })

        -- Trunk
        exports['qb-target']:AddTargetBone('boot', {
            options = {
                {
                    type = "client",
                    icon = "fas fa-suitcase",
                    label = "Remove Trunk",
                    action = function()
                        SalvagePart('trunk')
                    end,
                    canInteract = function()
                        return activeMission and missionStage == 2 and not salvageParts['boot']
                    end
                }
            },
            distance = 2.0
        })
    end
end

-- Add this after the SetupSalvageTargets function if you want to support non-target interaction
function SetupNonTargetSalvage()
    if not Config.UseTarget and vehicle and missionStage == 2 then
        CreateThread(function()
            while DoesEntityExist(vehicle) and missionStage == 2 do
                local sleep = 1000
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local vehicleCoords = GetEntityCoords(vehicle)
                local engineCoords = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "engine"))

                if #(playerCoords - vehicleCoords) < 5.0 then
                    sleep = 0

                    -- Engine interaction
                    if not salvageParts['engine'] and #(playerCoords - engineCoords) < 2.0 then
                        DrawText3D(engineCoords.x, engineCoords.y, engineCoords.z, '[E] Salvage Engine')
                        if IsControlJustPressed(0, 38) then -- E key
                            SalvagePart('engine')
                        end
                    end

                    -- Add similar code for other parts (doors, hood, trunk, wheels)
                    -- ...
                end

                Wait(sleep)
            end
        end)
    end
end

-- Salvage a part
function SalvagePart(partType, specificBone)
    local boneName = specificBone or partType

    if carryingPart then
        QBCore.Functions.Notify("You're already carrying a part!", "error")
        return
    end

    if salvageParts[boneName] then
        QBCore.Functions.Notify("You've already removed this part", "error")
        return
    end

    -- Highlight the part
    local boneIndex = GetEntityBoneIndexByName(vehicle, boneName)
    if boneIndex ~= -1 then
        HighlightPart(vehicle, boneIndex)
    end

    QBCore.Functions.Progressbar("salvage_part", "Removing "..partType.."...", Config.DemolishTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        RemoveHighlight()
        -- Mark part as removed
        salvageParts[boneName] = true
        demolishSuccess = demolishSuccess + 1

        -- Handle vehicle damage
        HandleVehicleDamage(partType, boneName)

        QBCore.Functions.Notify("Part removed! Continue removing parts.", "success")

        -- Check if all parts are removed
        if CheckAllPartsRemoved() then
            QBCore.Functions.Notify("All parts removed! Return to the scrapyard for payment.", "success")
            CreateDeliveryBlip()
        end
    end, function() -- Cancel
        RemoveHighlight()
        QBCore.Functions.Notify("Removal canceled.", "error")
    end)
end

function HandleVehicleDamage(partType, boneName)
    if partType == 'engine' then
        SetVehicleDoorBroken(vehicle, 4, true) -- Engine compartment
        SetVehicleEngineHealth(vehicle, 0)
    elseif partType == 'door' then
        local doorIndex = GetDoorFromBoneName(boneName)
        if doorIndex then
            SetVehicleDoorBroken(vehicle, doorIndex, true)
        end
    elseif partType == 'hood' then
        SetVehicleDoorBroken(vehicle, 4, true)
    elseif partType == 'trunk' then
        SetVehicleDoorBroken(vehicle, 5, true)
    elseif partType == 'wheel' then
        local wheelIndex = GetWheelFromBoneName(boneName)
        if wheelIndex then
            SetVehicleTyreBurst(vehicle, wheelIndex, true, 1000.0)
        end
    end
end

-- Create delivery blip
function CreateDeliveryBlip()
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
    end

    deliveryBlip = AddBlipForCoord(Config.Npcspawn.x, Config.Npcspawn.y, Config.Npcspawn.z)
    SetBlipSprite(deliveryBlip, 501)
    SetBlipColour(deliveryBlip, 2)
    SetBlipRoute(deliveryBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Scrapyard Delivery")
    EndTextCommandSetBlipName(deliveryBlip)

    missionStage = 3
end

-- Cancel Mission
function CancelMission()
    if activeMission then
        -- Check if all parts are delivered
        if CheckAllPartsDelivered() then
            -- Reward the player
            TriggerServerEvent('hl-scrapyard:reward', demolishSuccess)
            QBCore.Functions.Notify("Mission completed! You received your payment.", "success")
        else
            QBCore.Functions.Notify("Mission canceled. You did not complete all objectives.", "error")
        end

        -- Reset mission state
        activeMission = false
        missionStage = 0
        salvageParts = {}
        carryingPart = false
        currentPart = nil

        -- Clean up blips and entities
        if deliveryBlip then
            RemoveBlip(deliveryBlip)
            deliveryBlip = nil
        end

        if vehicle then
            DeleteEntity(vehicle)
            vehicle = nil
        end
    else
        QBCore.Functions.Notify("No active mission to cancel.", "error")
    end
end

-- DeliverPart function
function DeliverPart()
    if carryingPart then
        local playerPed = PlayerPedId()

        -- Stop animation
        ClearPedTasks(playerPed)

        -- Delete the carried prop
        if currentPart and currentPart.propObj then
            DetachEntity(currentPart.propObj, true, true)
            DeleteEntity(currentPart.propObj)
        end

        -- Add item to inventory
        TriggerServerEvent('hl-scrapyard:deliverpart', currentPart.type)

        -- Reset state
        carryingPart = false
        currentPart = nil

        -- Check if all parts are delivered
        if CheckAllPartsDelivered() then
            QBCore.Functions.Notify("All parts delivered! Return to the scrapyard for payment.", "success")
        end
    else
        QBCore.Functions.Notify("You're not carrying any part!", "error")
    end
end

function CheckAllPartsDelivered()
    -- Add your logic here to check if all parts are delivered
    -- Return true if all parts are delivered, false otherwise
    return true -- Replace with actual logic
end

-- Create sell location
function CreateSellLocation()
    -- Create the sell ped
    local pedModel = Config.SellShop.ped.model
    local sellCoords = Config.SellShop.location

    RequestModel(GetHashKey(pedModel))
    while not HasModelLoaded(GetHashKey(pedModel)) do
        Wait(100)
    end

    sellPed = CreatePed(4, GetHashKey(pedModel), sellCoords.x, sellCoords.y, sellCoords.z, 180.0, false, false)
    FreezeEntityPosition(sellPed, true)
    SetEntityInvincible(sellPed, true)
    SetBlockingOfNonTemporaryEvents(sellPed, true)
    SetEntityAsMissionEntity(sellPed, true, true)

    -- Play animation or scenario
    if Config.SellShop.ped.animation then
        RequestAnimDict(Config.SellShop.ped.animation.dict)
        while not HasAnimDictLoaded(Config.SellShop.ped.animation.dict) do
            Wait(100)
        end
        TaskPlayAnim(sellPed, Config.SellShop.ped.animation.dict, Config.SellShop.ped.animation.anim, 8.0, 0.0, -1, 1, 0, false, false, false)
    elseif Config.SellShop.ped.scenario then
        TaskStartScenarioInPlace(sellPed, Config.SellShop.ped.scenario, 0, true)
    end

    -- Create the sell blip
    sellBlip = AddBlipForCoord(sellCoords.x, sellCoords.y, sellCoords.z)
    SetBlipSprite(sellBlip, Config.SellShop.blip.sprite)
    SetBlipColour(sellBlip, Config.SellShop.blip.color)
    SetBlipScale(sellBlip, Config.SellShop.blip.scale)
    SetBlipDisplay(sellBlip, Config.SellShop.blip.display)
    SetBlipAsShortRange(sellBlip, Config.SellShop.blip.shortRange)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Sell Parts")
    EndTextCommandSetBlipName(sellBlip)

    -- Add target interaction
    if Config.SellShop.ped.target.useTarget then
        exports['qb-target']:AddTargetEntity(sellPed, {
            options = {
                {
                    type = "client",
                    icon = Config.SellShop.ped.target.icon,
                    label = Config.SellShop.ped.target.label,
                    action = function()
                        print("Target interaction triggered")
                        SellParts()
                    end,
                    distance = Config.SellShop.ped.target.distance
                }
            },
        })
    else
        -- For non-target systems, create a 3D text interaction
        CreateThread(function()
            while true do
                local sleep = 1000
                local playerCoords = GetEntityCoords(PlayerPedId())
                local dist = #(playerCoords - sellCoords)

                if dist <= 2.0 then
                    sleep = 0
                    DrawText3D(sellCoords.x, sellCoords.y, sellCoords.z + 1.0, '[E] Sell Parts')
                    if IsControlJustPressed(0, 38) then -- E key
                        print("3D Text interaction triggered")
                        SellParts()
                    end
                end
                Wait(sleep)
            end
        end)
    end
end

-- Handle selling parts
function SellParts()
    print("SellParts function called")
    -- Add a loading notification to provide feedback to the user
    QBCore.Functions.Notify("Checking your inventory for parts...", "primary", 2000)

    QBCore.Functions.TriggerCallback('hl-scrapyard:server:getParts', function(parts) -- Make sure callback name matches server-side
        if parts and #parts > 0 then
            print("Parts found: " .. json.encode(parts))
            TriggerServerEvent('hl-scrapyard:server:sellParts', parts) -- Make sure event name matches server-side
            QBCore.Functions.Notify("You sold your parts!", "success")
        else
            print("No parts found to sell")
            QBCore.Functions.Notify("You don't have any parts to sell!", "error")
        end
    end)
end

-- 3D Text Draw Function
function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

-- Event handlers
RegisterNetEvent('hl-scrapyard:demolish')
AddEventHandler('hl-scrapyard:demolish', function()
    -- Existing code for demolish event
end)

RegisterNetEvent('hl-scrapyard:removeDoor')
AddEventHandler('hl-scrapyard:removeDoor', function(door)
    -- Existing code for removeDoor event
end)

RegisterNetEvent('hl-scrapyard:end')
AddEventHandler('hl-scrapyard:end', function(demolishSuccess)
    -- Existing code for end event
    TriggerServerEvent('hl-scrapyard:reward', demolishSuccess)
    currentJob = false
end)

-- Export the function
exports('CancelSalvage', CancelSalvage)

-- Initialize sell location
CreateThread(function()
    Wait(1000) -- Wait for everything to load
    CreateSellLocation()
end)
