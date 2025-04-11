Config = {}

-- Sell Shop Configuration
Config.SellShop = {
    location = vector3(-428.63, -1728.35, 19.78), -- Example location, adjust as needed
    blip = {
        sprite = 500, -- Blip sprite for the sell shop
        color = 2, -- Blip color
        scale = 0.8, -- Blip scale
        display = 4, -- Blip display
        shortRange = true -- Blip short range
    },
    sellMultiplier = 0.8, -- Multiplier for selling parts (e.g., 80% of the part's value)
    ped = {
        model = 's_m_y_dockwork_01', -- Model of the ped
        coords = vector3(-428.63, -1728.35, 19.78), -- Coordinates and heading of the ped
        animation = {
            dict = 'mini@strip_club@idles@bouncer@base', -- Animation dictionary
            anim = 'base' -- Animation name
        },
        scenario = nil, -- Optional: You can use a scenario instead of an animation
        target = {
            useTarget = true, -- Whether to use a target system for interaction
            icon = 'fa-solid fa-car', -- Icon for the target
            label = 'Sell Parts', -- Label for the target interaction
            distance = 2.5 -- Distance at which the target is interactable
        }
    }
}

-- NPC Configuration
Config.Npcspawn = vector4(-440.64, -1694.15, 19.15, 144.0)
Config.NpcModel = 's_m_y_dockwork_01'
Config.NpcAnimation = {
    dict = 'mini@strip_club@idles@bouncer@base',
    anim = 'base'
}

-- Car Spawn Locations
Config.CarSpawnLocations = {
    vector4(-427.0, -1718.0, 19.0, 90.0),
    vector4(-428.0, -1696.0, 19.0, 90.0),
    vector4(-464.0, -1709.0, 19.0, 90.0),
    vector4(-454.0, -1721.0, 19.0, 90.0),
    vector4(-440.0, -1694.0, 19.0, 144.0),
    vector4(-450.0, -1700.0, 19.0, 120.0),
    vector4(-460.0, -1710.0, 19.0, 100.0),
    vector4(-470.0, -1720.0, 19.0, 80.0)
}

-- Pickup Locations Configuration
Config.PickupLocations = {
    vector4(-455.12, -1701.09, 18.85, 241.52)
}

-- Mission Settings
Config.Mission = {
    minParts = 3,  -- Minimum parts to salvage per mission
    maxParts = 6,  -- Maximum parts to salvage per mission
    timeLimit = 600, -- Time limit in seconds (10 minutes)
    timeBonus = {
        max = 1000, -- Maximum time bonus
        perSecond = 2 -- $ per second under time limit
    },
    completionBonus = 1000 -- Bonus per part completed
}

-- Vehicle Configuration
Config.Vehicles = {
    'stanier',
    'washington',
    'fq2',
    'landstalker',
    'seminole',
    'rocoto'
}

-- Part Configuration
Config.Parts = {
    ['engine'] = {
        prop = 'prop_car_engine_01',
        value = { min = 1000, max = 1500 },
        animation = {
            dict = 'anim@heists@box_carry@',
            anim = 'idle',
            bone = 60309,
            offset = vector3(0.25, 0.08, 0.255),
            rotation = vector3(-145.0, 290.0, 0.0)
        }
    },
    ['transmission'] = {
        prop = 'imp_prop_impexp_gearbox_01',
        value = { min = 800, max = 1200 },
        animation = {
            dict = 'anim@heists@box_carry@',
            anim = 'idle',
            bone = 60309,
            offset = vector3(0.25, 0.08, 0.255),
            rotation = vector3(-145.0, 290.0, 0.0)
        }
    },
    ['hood'] = {
        prop = 'imp_prop_impexp_bonnet_02a',
        value = { min = 400, max = 600 },
        animation = {
            dict = 'anim@heists@box_carry@',
            anim = 'idle',
            bone = 60309,
            offset = vector3(0.25, 0.08, 0.255),
            rotation = vector3(-145.0, 290.0, 0.0)
        }
    },
    ['trunk'] = {
        prop = 'imp_prop_impexp_trunk_01a',
        value = { min = 350, max = 550 },
        animation = {
            dict = 'anim@heists@box_carry@',
            anim = 'idle',
            bone = 60309,
            offset = vector3(0.25, 0.08, 0.255),
            rotation = vector3(-145.0, 290.0, 0.0)
        }
    },
    ['wheel'] = {
        prop = 'prop_wheel_01',
        value = { min = 250, max = 400 },
        animation = {
            dict = 'anim@heists@box_carry@',
            anim = 'idle',
            bone = 60309,
            offset = vector3(0.25, 0.08, 0.255),
            rotation = vector3(-145.0, 290.0, 0.0)
        }
    },
    ['door'] = {
        prop = 'imp_prop_impexp_car_door_04a',
        value = { min = 300, max = 500 },
        animation = {
            dict = 'anim@heists@box_carry@',
            anim = 'idle',
            bone = 60309,
            offset = vector3(0.25, 0.08, 0.255),
            rotation = vector3(-145.0, 290.0, 0.0)
        }
    }
}

-- Part Prices
Config.PartPrices = {
    ['engine'] = 1200,
    ['transmission'] = 800,
    ['hood'] = 400,
    ['trunk'] = 350,
    ['wheel'] = 250,
    ['door'] = 300,
    ['salvaged_part'] = 200
}

-- Delivery Locations
Config.DeliveryPoints = {
    vector3(-427.1, -1691.85, 19.03)
}

-- Add Locations Configuration
Config.Locations = {
    vector3(-440.23, -1694.71, 19.15)
}

-- Blip Configuration
Config.Blip = {
    name = 'Scrapyard',
    sprite = 467,
    color = 5,
    scale = 0.8,
    vehicle = {
        sprite = 225,
        color = 1
    },
    delivery = {
        sprite = 478,
        color = 2
    },
    pickup = {
        sprite = 380,
        color = 5,
        scale = 1.0,
        display = 2,
        shortRange = false
    }
}

-- Target System Configuration
Config.UseTarget = true
Config.TargetIcon = 'fa-solid fa-car'
Config.TargetDistance = 2.5

-- Skill Check Configuration
Config.SkillCheck = {
    difficulty = { 'easy', 'easy', 'easy', 'easy' },
    keys = { 'w', 'a', 's', 'd' }
}

-- Progress Bar Configuration
Config.Progress = {
    duration = 5000, -- Base duration for actions
    label = 'Working...',
    useWhileDead = false,
    disable = {
        move = true,
        carMove = true,
        mouse = false,
        combat = true
    },
    anim = {
        dict = 'mini@repair',
        anim = 'fixing_a_ped',
        flags = 16
    }
}

-- Add Demolish Time Configuration
Config.DemolishTime = 10000 -- Time in milliseconds (10 seconds) to salvage a part

-- Payment Configuration
Config.PaymentType = 'cash' -- 'cash' or 'bank'
Config.MaxPerDay = 3
Config.MinReward = 2600
Config.MaxReward = 7500

-- Notification Configuration
Config.Notify = {
    success = {
        title = 'Success',
        duration = 5000,
        type = 'success'
    },
    error = {
        title = 'Error',
        duration = 5000,
        type = 'error'
    },
    info = {
        title = 'Information',
        duration = 5000,
        type = 'primary'
    }
}

-- Anti-Cheat Configuration
Config.AntiCheat = {
    maxPartsPerMission = 12,
    maxTimePerMission = 1200, -- 20 minutes
    maxDistanceFromVehicle = 50.0
}

-- Part Configuration
Config.Parts = {
    ['engine'] = {
        prop = 'prop_car_engine_01',
        value = { min = 1000, max = 1500 },
        sellValue = function(min, max) return math.floor((min + max) / 2 * Config.SellShop.sellMultiplier) end,
        animation = {
            dict = 'anim@heists@box_carry@',
            anim = 'idle',
            bone = 60309,
            offset = vector3(0.25, 0.08, 0.255),
            rotation = vector3(-145.0, 290.0, 0.0)
        }
    },
    ['transmission'] = {
        prop = 'imp_prop_impexp_gearbox_01',
        value = { min = 800, max = 1200 },
        sellValue = function(min, max) return math.floor((min + max) / 2 * Config.SellShop.sellMultiplier) end,
        animation = {
            dict = 'anim@heists@box_carry@',
            anim = 'idle',
            bone = 60309,
            offset = vector3(0.25, 0.08, 0.255),
            rotation = vector3(-145.0, 290.0, 0.0)
        }
    },
    -- Add similar sellValue functions for other parts...
}
