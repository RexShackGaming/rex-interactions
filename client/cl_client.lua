local AvailableInteractions = {}
local CanStartInteraction = true
local CurrentInteraction = nil
local InMenu = false
local MaxRadius = 0.0
local StartingCoords = nil
local LastInteractionChange = 0
local ActiveTargets = {}
local StopPrompt = nil

local function Debug(...)
    if Config.DevMode then
        print(...)
    end
end

local function IsRanchStaff()
    -- Check if player has ranch staff job
    -- This function should be customized based on your framework
    -- Example for QBCore: return QBCore.Functions.GetPlayerData().job.name == 'ranchstaff'
    -- Example for RSG: return exports['rsg-core']:GetPlayerData().job.name == 'ranchstaff'
    -- For now, returns true to allow all interactions unless you have animals configured
    return true
end

local function IsAnimalModel(model)
    -- Check if the model is an animal (starts with a_c_)
    if type(model) == 'string' then
        return model:lower():find('^a_c_') ~= nil
    end
    return false
end

local function ShowNotification(notifType)
    if Config.EnableNotifications and Config.Notifications[notifType] then
        local notif = Config.Notifications[notifType]
        lib.notify({
            title = 'Interactions',
            description = notif.message,
            type = notif.type,
            position = 'top'
        })
    end
end

local function IsOnCooldown()
    return (GetGameTimer() - LastInteractionChange) < Config.InteractionCooldown
end

local function EnumerateEntities(firstFunc, nextFunc, endFunc)
    return coroutine.wrap(function()
        local iter, id = firstFunc()

        if not id or id == 0 then
            endFunc(iter)
            return
        end

        local enum = { handle = iter, destructor = endFunc }
        setmetatable(enum, entityEnumerator)

        local next = true
        repeat
            coroutine.yield(id)
            next, id = nextFunc(iter)
        until not next

        enum.destructor, enum.handle = nil, nil
        endFunc(iter)
    end)
end

local function EnumerateObjects()
    return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end

local function HasCompatibleModel(entity, models)
    local entityModel = GetEntityModel(entity)
    for _, model in ipairs(models) do
        if entityModel == GetHashKey(model) then
            return model
        end
    end
    return nil
end

local function CanStartInteractionAtObject(interaction, object, playerCoords, objectCoords)
    local distance = #(playerCoords - objectCoords)
    if distance > interaction.radius then
        return nil
    end
    return HasCompatibleModel(object, interaction.objects)
end

local function PlayAnimation(ped, anim)
    if not DoesAnimDictExist(anim.dict) then
        return
    end
    RequestAnimDict(anim.dict)
    while not HasAnimDictLoaded(anim.dict) do
        Wait(0)
    end
    TaskPlayAnim(ped, anim.dict, anim.name, 0.0, 0.0, -1, 1, 1.0, false, false, false, "", false)
    RemoveAnimDict(anim.dict)
end

local function StartInteractionAtCoords(interaction)
    if IsOnCooldown() then
        ShowNotification('Cooldown')
        return
    end
    
    local x, y, z, h = interaction.x, interaction.y, interaction.z, interaction.heading
    if not StartingCoords then
        StartingCoords = GetEntityCoords(PlayerPedId())
    end
    
    -- Smooth transition
    if CurrentInteraction then
        ClearPedTasksImmediately(PlayerPedId())
        Wait(100)
    end
    
    ClearPedTasksImmediately(PlayerPedId())
    FreezeEntityPosition(PlayerPedId(), true)
    Debug('ClearPedTasksImmediately: ^2ON^0 \n FreezeEntityPosition: ^2ON^0')
    
    if interaction.scenario then
        TaskStartScenarioAtPosition(PlayerPedId(), GetHashKey(interaction.scenario), x, y, z, h, -1, false, true)
    elseif interaction.animation then
        SetEntityCoordsNoOffset(PlayerPedId(), x, y, z)
        SetEntityHeading(PlayerPedId(), h)
        PlayAnimation(PlayerPedId(), interaction.animation)
    end
    
    if interaction.effect then
        Config.Effects[interaction.effect]()
    end
    
    CurrentInteraction = interaction
    LastInteractionChange = GetGameTimer()
    ShowNotification('InteractionStarted')
end

local function StartInteractionAtObject(interaction)
    local objectHeading = GetEntityHeading(interaction.object)
    local objectCoords = GetEntityCoords(interaction.object)
    local r = math.rad(objectHeading)
    local cosr = math.cos(r)
    local sinr = math.sin(r)
    local x = interaction.x * cosr - interaction.y * sinr + objectCoords.x
    local y = interaction.y * cosr + interaction.x * sinr + objectCoords.y
    local z = interaction.z + objectCoords.z
    local h = interaction.heading + objectHeading
    interaction.x, interaction.y, interaction.z, interaction.heading = x, y, z, h
    StartInteractionAtCoords(interaction)
end

local function IsCompatible(t, ped)
    return not t.isCompatible or t.isCompatible(ped)
end

local function SortInteractions(a, b)
    if a.distance == b.distance then
        if a.object == b.object then
            local aLabel = a.scenario or a.animation.label
            local bLabel = b.scenario or b.animation.label
            return aLabel < bLabel
        else
            return a.object < b.object
        end
    else
        return a.distance < b.distance
    end
end

local function AddInteractions(availableInteractions, interaction, playerCoords, targetCoords, modelName, object)
    local distance = #(playerCoords - targetCoords)
    if interaction.scenarios then
        for _, scenario in ipairs(interaction.scenarios) do
            if IsCompatible(scenario, PlayerPedId()) then
                table.insert(availableInteractions, {
                    x = interaction.x,
                    y = interaction.y,
                    z = interaction.z,
                    heading = interaction.heading,
                    scenario = scenario.name,
                    object = object,
                    modelName = modelName,
                    distance = distance,
                    label = interaction.label,
                    effect = interaction.effect,
                    labelText = scenario.label,
                    labelText2 = interaction.labelText,
                    targetCoords = targetCoords
                })
            end
        end
    end
    if interaction.animations then
        for _, animation in ipairs(interaction.animations) do
            if IsCompatible(animation, PlayerPedId()) then
                table.insert(availableInteractions, {
                    x = interaction.x,
                    y = interaction.y,
                    z = interaction.z,
                    heading = interaction.heading,
                    animation = animation,
                    object = object,
                    modelName = modelName,
                    distance = distance,
                    label = interaction.label,
                    effect = interaction.effect,
                    labelText = animation.label,
                    labelText2 = interaction.labelText,
                    targetCoords = targetCoords
                })
            end
        end
    end
end

local function GetAvailableInteractions()
    local playerCoords = GetEntityCoords(PlayerPedId())
    AvailableInteractions = {}
    for _, interaction in ipairs(Config.Interactions) do
        if IsCompatible(interaction, PlayerPedId()) then
            if interaction.objects then
                for object in EnumerateObjects() do
                    local objectCoords = GetEntityCoords(object)
                    local modelName = CanStartInteractionAtObject(interaction, object, playerCoords, objectCoords)
                    if modelName then
                        AddInteractions(AvailableInteractions, interaction, playerCoords, objectCoords, modelName, object)
                    end
                end
            else
                local targetCoords = vector3(interaction.x, interaction.y, interaction.z)
                if #(playerCoords - targetCoords) <= interaction.radius then
                    AddInteractions(AvailableInteractions, interaction, playerCoords, targetCoords)
                end
            end
        end
        Wait(0)
    end
    table.sort(AvailableInteractions, SortInteractions)
    return AvailableInteractions
end

local function menuStartInteraktion(data)
    if data.object then
        StartInteractionAtObject(data)
    else
        StartInteractionAtCoords(data)
    end
end

local function StopInteraction()
    CurrentInteraction = nil
    ClearPedTasksImmediately(PlayerPedId())
    FreezeEntityPosition(PlayerPedId(), false)
    Debug('ClearPedTasksImmediately: ^1OFF^0 \n FreezeEntityPosition: ^1OFF^0')
    if StartingCoords then
        SetEntityCoordsNoOffset(PlayerPedId(), StartingCoords.x, StartingCoords.y, StartingCoords.z)
        StartingCoords = nil
    end
    LastInteractionChange = GetGameTimer()
    ShowNotification('InteractionStopped')
end

local function GetInteractionIcon(scenario, animation)
    -- Enhanced icon detection for ox_target
    if scenario then
        local scenarioLower = scenario:lower()
        -- Sleeping
        if scenarioLower:find('sleep') or scenarioLower:find('bed') then
            return 'fa-bed'
        -- Music instruments
        elseif scenarioLower:find('piano') then
            return 'fa-music'
        elseif scenarioLower:find('guitar') then
            return 'fa-guitar'
        elseif scenarioLower:find('banjo') or scenarioLower:find('mandolin') then
            return 'fa-guitar'
        elseif scenarioLower:find('harmonica') or scenarioLower:find('concertina') then
            return 'fa-music'
        -- Drinking & Eating
        elseif scenarioLower:find('drink') or scenarioLower:find('beer') then
            return 'fa-wine-glass'
        -- Smoking
        elseif scenarioLower:find('smoke') or scenarioLower:find('cigar') then
            return 'fa-smoking'
        -- Reading
        elseif scenarioLower:find('read') or scenarioLower:find('book') then
            return 'fa-book'
        -- Fishing
        elseif scenarioLower:find('fish') then
            return 'fa-fish'
        -- Grooming
        elseif scenarioLower:find('groom') or scenarioLower:find('knitting') or scenarioLower:find('whittle') then
            return 'fa-scissors'
        -- Knife/Weapon
        elseif scenarioLower:find('knife') then
            return 'fa-knife'
        -- Generic sitting
        elseif scenarioLower:find('seat') or scenarioLower:find('chair') or scenarioLower:find('bench') then
            return 'fa-chair'
        end
    end
    
    if animation then
        local animName = animation.name:lower()
        if animName:find('bath') then
            return 'fa-shower'
        elseif animName:find('dance') then
            return 'fa-person-walking'
        elseif animName:find('scrub') then
            return 'fa-hand-sparkles'
        end
    end
    
    return 'fa-hand-paper' -- default icon
end

local function GetInteractionCategory(scenario, animation)
    if scenario then
        local scenarioLower = scenario:lower()
        if scenarioLower:find('sleep') or scenarioLower:find('bed') then
            return 'sleeping'
        elseif scenarioLower:find('piano') or scenarioLower:find('guitar') or scenarioLower:find('banjo') or scenarioLower:find('mandolin') or scenarioLower:find('harmonica') or scenarioLower:find('concertina') then
            return 'music'
        elseif scenarioLower:find('drink') or scenarioLower:find('beer') then
            return 'drinking'
        elseif scenarioLower:find('smoke') or scenarioLower:find('cigar') then
            return 'smoking'
        elseif scenarioLower:find('read') or scenarioLower:find('groom') or scenarioLower:find('whittle') or scenarioLower:find('knitting') or scenarioLower:find('knife') then
            return 'activities'
        end
    end
    
    if animation then
        local animName = animation.name:lower()
        if animName:find('bath') or animName:find('scrub') then
            return 'bathing'
        elseif animName:find('dance') then
            return 'dancing'
        end
    end
    
    return 'sitting' -- default category
end

local function GetInteractionLabel(scenario, animation, label)
    local baseLabel = ''
    
    if scenario then
        baseLabel = scenario.label
    elseif animation then
        baseLabel = animation.label
    end
    
    -- Add position suffix if specified and enabled in config
    if Config.ShowPositionInLabel and label then
        if label == 'left' then
            return baseLabel .. ' (Left)'
        elseif label == 'right' then
            return baseLabel .. ' (Right)'
        elseif label == 'middle' then
            return baseLabel .. ' (Middle)'
        elseif label == 'up' then
            return baseLabel .. ' (Upper)'
        end
    end
    
    return baseLabel
end

local function openInteractionMenu(availableInteractions)
    InMenu = true
    lib.hideContext(false)

    -- Categorize interactions
    local categories = {
        sitting = {},
        sleeping = {},
        music = {},
        drinking = {},
        smoking = {},
        bathing = {},
        dancing = {}
    }

    for k, v in pairs(availableInteractions) do
        local category = GetInteractionCategory(v)
        if not categories[category] then
            categories[category] = {}
        end
        table.insert(categories[category], {data = v, index = k})
    end

    local options = {}

    table.insert(options, {
        title = Translation[Config.Locale]["menu_cancel"],
        description = 'Exit interaction menu',
        icon = 'circle-xmark',
        iconColor = 'red',
        onSelect = function()
            StopInteraction()
            InMenu = false
        end
    })

    -- Category headers with icons
    local categoryOrder = {'sitting', 'sleeping', 'music', 'drinking', 'smoking', 'bathing', 'dancing'}
    local categoryIcons = {
        sitting = 'chair',
        sleeping = 'bed',
        music = 'music',
        drinking = 'wine-glass',
        smoking = 'smoking',
        bathing = 'shower',
        dancing = 'person-walking'
    }
    local categoryLabels = {
        sitting = 'Sitting',
        sleeping = 'Sleeping',
        music = 'Music',
        drinking = 'Drinking',
        smoking = 'Smoking',
        bathing = 'Bathing',
        dancing = 'Dancing'
    }

    for _, category in ipairs(categoryOrder) do
        if #categories[category] > 0 then
            -- Add category header
            table.insert(options, {
                title = '─── ' .. categoryLabels[category] .. ' ───',
                icon = categoryIcons[category],
                disabled = true
            })

            -- Add category items
            for _, item in ipairs(categories[category]) do
                local v = item.data
                local k = item.index
                local label

                if v.labelText then
                    if v.label == "left" then
                        label = tostring(v.labelText .. Translation[Config.Locale]["menu_left"])
                    elseif v.label == "right" then
                        label = tostring(v.labelText .. Translation[Config.Locale]["menu_right"])
                    elseif v.label == "middle" then
                        label = tostring(v.labelText .. Translation[Config.Locale]["menu_middle"])
                    elseif v.label == "up" then
                        label = tostring(v.labelText .. Translation[Config.Locale]["menu_up"])
                    else
                        label = tostring(v.labelText)
                    end
                else
                    label = v.labelText2
                end

                table.insert(options, {
                    title = '  ' .. label,
                    icon = GetInteractionIcon(v),
                    onSelect = function()
                        menuStartInteraktion(availableInteractions[k])
                        InMenu = false
                    end
                })
            end
        end
    end

    lib.registerContext({
        id = 'interaction_menu',
        title = Translation[Config.Locale]["menu_title"],
        options = options
    })

    lib.showContext('interaction_menu')
end


-- Initialize ox_target zones and entity targets
CreateThread(function()
    Wait(1000) -- Wait for resource to fully load
    
    -- Setup entity targets for objects
    for interactionIdx, interaction in ipairs(Config.Interactions) do
        if interaction.objects then
            local options = {}
            
            if interaction.scenarios then
                for scenarioIdx, scenario in ipairs(interaction.scenarios) do
                    -- Create unique name based on interaction index, scenario, and position label
                    local uniqueName = string.format('interaction_%d_%s_%s', 
                        interactionIdx, 
                        scenario.name, 
                        interaction.label or 'default'
                    )
                    
                    table.insert(options, {
                        name = uniqueName,
                        label = GetInteractionLabel(scenario, nil, interaction.label),
                        icon = GetInteractionIcon(scenario.name, nil),
                        distance = interaction.radius,
                        canInteract = function(entity, distance, coords, name, bone)
                            if not CanStartInteraction or isAreaBanned(coords) then
                                return false
                            end
                            -- Check if any of the models are animals and require ranch staff
                            if interaction.objects then
                                for _, modelName in ipairs(interaction.objects) do
                                    if IsAnimalModel(modelName) and not IsRanchStaff() then
                                        return false
                                    end
                                end
                            end
                            if scenario.isCompatible then
                                return scenario.isCompatible(PlayerPedId())
                            end
                            if interaction.isCompatible then
                                return interaction.isCompatible(PlayerPedId())
                            end
                            return true
                        end,
                        onSelect = function(data)
                            local interactionData = {
                                x = interaction.x,
                                y = interaction.y,
                                z = interaction.z,
                                heading = interaction.heading,
                                scenario = scenario.name,
                                object = data.entity,
                                effect = interaction.effect
                            }
                            StartInteractionAtObject(interactionData)
                        end
                    })
                end
            end
            
            if interaction.animations then
                for animIdx, animation in ipairs(interaction.animations) do
                    -- Create unique name based on interaction index, animation, and position label
                    local uniqueName = string.format('interaction_%d_%s_%s', 
                        interactionIdx, 
                        animation.name, 
                        interaction.label or 'default'
                    )
                    
                    table.insert(options, {
                        name = uniqueName,
                        label = GetInteractionLabel(nil, animation, interaction.label),
                        icon = GetInteractionIcon(nil, animation),
                        distance = interaction.radius,
                        canInteract = function(entity, distance, coords, name, bone)
                            if not CanStartInteraction or isAreaBanned(coords) then
                                return false
                            end
                            -- Check if any of the models are animals and require ranch staff
                            if interaction.objects then
                                for _, modelName in ipairs(interaction.objects) do
                                    if IsAnimalModel(modelName) and not IsRanchStaff() then
                                        return false
                                    end
                                end
                            end
                            if animation.isCompatible then
                                return animation.isCompatible(PlayerPedId())
                            end
                            if interaction.isCompatible then
                                return interaction.isCompatible(PlayerPedId())
                            end
                            return true
                        end,
                        onSelect = function(data)
                            local interactionData = {
                                x = interaction.x,
                                y = interaction.y,
                                z = interaction.z,
                                heading = interaction.heading,
                                animation = animation,
                                object = data.entity,
                                effect = interaction.effect
                            }
                            StartInteractionAtObject(interactionData)
                        end
                    })
                end
            end
            
            if #options > 0 then
                exports.ox_target:addModel(interaction.objects, options)
            end
        end
    end
    
    -- Setup zone targets for fixed coordinates
    for i, interaction in ipairs(Config.Interactions) do
        if not interaction.objects and interaction.x and interaction.y and interaction.z then
            local options = {}
            
            if interaction.scenarios then
                for _, scenario in ipairs(interaction.scenarios) do
                    table.insert(options, {
                        name = 'interaction_zone_' .. i .. '_' .. scenario.name,
                        label = GetInteractionLabel(scenario, nil, interaction.label),
                        icon = GetInteractionIcon(scenario.name, nil),
                        canInteract = function(entity, distance, coords, name, bone)
                            if not CanStartInteraction or isAreaBanned(coords) then
                                return false
                            end
                            if scenario.isCompatible then
                                return scenario.isCompatible(PlayerPedId())
                            end
                            if interaction.isCompatible then
                                return interaction.isCompatible(PlayerPedId())
                            end
                            return true
                        end,
                        onSelect = function()
                            local interactionData = {
                                x = interaction.x,
                                y = interaction.y,
                                z = interaction.z,
                                heading = interaction.heading,
                                scenario = scenario.name,
                                effect = interaction.effect
                            }
                            StartInteractionAtCoords(interactionData)
                        end
                    })
                end
            end
            
            if interaction.animations then
                for _, animation in ipairs(interaction.animations) do
                    table.insert(options, {
                        name = 'interaction_zone_' .. i .. '_' .. animation.name,
                        label = GetInteractionLabel(nil, animation, interaction.label),
                        icon = GetInteractionIcon(nil, animation),
                        canInteract = function(entity, distance, coords, name, bone)
                            if not CanStartInteraction or isAreaBanned(coords) then
                                return false
                            end
                            if animation.isCompatible then
                                return animation.isCompatible(PlayerPedId())
                            end
                            if interaction.isCompatible then
                                return interaction.isCompatible(PlayerPedId())
                            end
                            return true
                        end,
                        onSelect = function()
                            local interactionData = {
                                x = interaction.x,
                                y = interaction.y,
                                z = interaction.z,
                                heading = interaction.heading,
                                animation = animation,
                                effect = interaction.effect
                            }
                            StartInteractionAtCoords(interactionData)
                        end
                    })
                end
            end
            
            if #options > 0 then
                local zoneId = exports.ox_target:addSphereZone({
                    coords = vector3(interaction.x, interaction.y, interaction.z),
                    radius = interaction.radius,
                    options = options
                })
                table.insert(ActiveTargets, zoneId)
            end
        end
    end
end)

-- Initialize stop interaction prompt
CreateThread(function()
    Wait(1000)
    
    local str = 'Stop Interaction'
    StopPrompt = PromptRegisterBegin()
    PromptSetControlAction(StopPrompt, Config.Key) -- 0xF3830D8E [J]
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(StopPrompt, str)
    PromptSetEnabled(StopPrompt, false)
    PromptSetVisible(StopPrompt, false)
    PromptSetStandardMode(StopPrompt, true)
    PromptSetHoldMode(StopPrompt, false)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C, StopPrompt, true)
    PromptRegisterEnd(StopPrompt)
end)

CreateThread(function()
    while true do
        CanStartInteraction = not IsPedDeadOrDying(PlayerPedId()) and not IsPedInCombat(PlayerPedId())
        Wait(1000)
    end
end)

-- Handle stop interaction prompt
CreateThread(function()
    while true do
        Wait(0)
        
        if CurrentInteraction then
            PromptSetEnabled(StopPrompt, true)
            PromptSetVisible(StopPrompt, true)
            PromptSetActiveGroupThisFrame(StopPrompt, CreateVarString(10, 'LITERAL_STRING', 'Interaction'))
            
            if PromptHasStandardModeCompleted(StopPrompt) then
                StopInteraction()
            end
        else
            PromptSetEnabled(StopPrompt, false)
            PromptSetVisible(StopPrompt, false)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    
    -- Clean up ox_target zones
    for _, targetId in ipairs(ActiveTargets) do
        exports.ox_target:removeZone(targetId)
    end
    
    if InMenu then
        lib.hideContext(false)
    end
    StopInteraction()
end)

isAreaBanned = function (coords)
	for k,v in pairs(Config.BannedAreas) do
        local dist = GetDistanceBetweenCoords(coords.x,coords.y,coords.z,v.x,v.y,v.z,true)
		if dist < v.r then
			return true
		end
	end
	return false
end
