---@diagnostic disable: trailing-space
local QBCore = exports['qb-core']:GetCoreObject()

-- Example of showing progress bar
function StartProgressBar(duration, label)
    local playerPed = PlayerPedId()
    local progressBarData = {
        duration = duration,   -- How long the progress bar lasts (in ms)
        label = label,         -- The label displayed on the progress bar
        useWhileDead = false,  -- Whether to show progress while dead (optional)
        canCancel = true,      -- Whether the progress bar can be canceled by player (optional)
        controlDisables = {   -- What controls are disabled while the progress bar is active
            disableMovement = true, 
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = false
        },
        animation = {         -- Animation to play during the progress
            animDict = "amb@world_human_hammering@male@idle_a", 
            animName = "idle_c"
        }
    }

    -- Trigger the progress bar UI
    TriggerEvent('qb-core:progressbar', progressBarData)
    
    -- Optionally, play animation (if desired)
    RequestAnimDict(progressBarData.animation.animDict)
    while not HasAnimDictLoaded(progressBarData.animation.animDict) do
        Wait(100)
    end
    TaskPlayAnim(playerPed, progressBarData.animation.animDict, progressBarData.animation.animName, 8.0, -8.0, duration / 1000, 1, 0, false, false, false)

    -- Start the progress bar
    Citizen.Wait(duration)

    -- After the progress bar completes, you can add further logic here.
end

-- Command to start the progress bar (for testing purposes)
RegisterCommand("testprogress", function()
    StartProgressBar(5000, "Processing Item...") -- 5000 ms = 5 seconds
end, false)
