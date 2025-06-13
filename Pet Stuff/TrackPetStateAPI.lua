-- PetInspector API v2.0 - Focused Tracking
-- Load with: local PetInspector = loadstring(game:HttpGet("URL_TO_THIS_SCRIPT"))()

local PetInspector = {}
local serviceCache = {}
local activeTrackers = {}

-- Service initialization
local function getService(serviceName)
    if not serviceCache[serviceName] then
        serviceCache[serviceName] = game:GetService(serviceName)
    end
    return serviceCache[serviceName]
end

local Players = getService("Players")
local ReplicatedStorage = getService("ReplicatedStorage")
local RunService = getService("RunService")

-- Module initialization
local function requireModule(path)
    if not serviceCache[path] then
        serviceCache[path] = require(path)
    end
    return serviceCache[path]
end

local ActivePetsService = requireModule(ReplicatedStorage.Modules.PetServices.ActivePetsService)
local PetUtilities = requireModule(ReplicatedStorage.Modules.PetServices.PetUtilities)
local PetRegistry = requireModule(ReplicatedStorage.Data.PetRegistry)

--[[
    Core Pet Functions
]]

--- Gets pet data by UUID
-- @param uuid string The pet's UUID
-- @param playerName string|nil Optional player name (defaults to local player)
-- @return table|nil Pet data or nil if not found
function PetInspector.getPetData(uuid, playerName)
    local targetPlayer
    if playerName then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Name:lower() == playerName:lower() then
                targetPlayer = player
                break
            end
        end
    else
        targetPlayer = Players.LocalPlayer
    end

    if not targetPlayer then return nil end

    local success, petData = pcall(function()
        return ActivePetsService:GetPetData(targetPlayer.Name, uuid)
    end)

    if not success or not petData then return nil end

    local petType = petData.PetType
    local petConfig = PetRegistry.PetList[petType]
    if not petConfig then return nil end

    local currentWeight = PetUtilities:CalculateWeight(petData.PetData.BaseWeight or 1, petData.PetData.Level or 1)

    -- Process passives
    local passives = {}
    if petConfig.Passives then
        for _, passiveName in ipairs(petConfig.Passives) do
            local success, passiveString = pcall(function()
                return PetUtilities:GetPassiveString(currentWeight, passiveName)
            end)

            passives[passiveName] = {
                description = success and passiveString or "Error loading passive",
                stats = success and PetUtilities:GetCurrentLevelState(currentWeight, passiveName) or {}
            }
        end
    end

    return {
        uuid = uuid,
        name = petData.PetData.Name or petType,
        type = petType,
        level = petData.PetData.Level or 1,
        weight = currentWeight,
        passives = passives,
        rawData = petData.PetData
    }
end

--[[
    State Tracking System
]]

--- Tracks state changes for a specific pet
-- @param uuid string The pet's UUID to track
-- @param callback function Callback when state changes (params: newState, oldState, petData)
-- @param playerName string|nil Optional player name (defaults to local player)
-- @return function Cleanup function to stop tracking
function PetInspector.trackPetState(uuid, callback, playerName)
    -- Stop existing tracker if one exists
    if activeTrackers[uuid] then
        activeTrackers[uuid].cleanup()
    end

    local targetPlayer
    if playerName then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Name:lower() == playerName:lower() then
                targetPlayer = player
                break
            end
        end
    else
        targetPlayer = Players.LocalPlayer
    end

    if not targetPlayer then
        warn("Player not found")
        return function() end
    end

    -- Get initial pet data
    local petData = PetInspector.getPetData(uuid, targetPlayer.Name)
    if not petData then
        warn("Pet not found:", uuid)
        return function() end
    end

    -- Get client state
    local success, clientState = pcall(function()
        return ActivePetsService:GetClientPetStateUUID(targetPlayer.Name, uuid)
    end)

    if not success or not clientState then
        warn("Could not get client state for pet")
        return function() end
    end

    -- Create tracker
    local tracker = {
        lastState = "Unknown",
        connection = nil,
        cleanup = function()
            if tracker.connection then
                tracker.connection:Disconnect()
            end
            activeTrackers[uuid] = nil
        end
    }
    activeTrackers[uuid] = tracker

    -- Setup heartbeat connection
    tracker.connection = RunService.Heartbeat:Connect(function()
        local currentState = clientState.LastAnimationState or 
                           (clientState.CurrentAnimation and clientState.CurrentAnimation.Name) or
                           "Unknown"

        if currentState ~= tracker.lastState then
            local oldState = tracker.lastState
            tracker.lastState = currentState

            -- Refresh pet data in case it changed
            local updatedPetData = PetInspector.getPetData(uuid, targetPlayer.Name) or petData

            -- Call callback with state info
            pcall(callback, {
                newState = currentState,
                oldState = oldState,
                petData = updatedPetData,
                position = clientState.CurrentCFrame and clientState.CurrentCFrame.Position,
                speed = clientState.MovementSpeed,
                timestamp = os.time()
            })
        end
    end)

    return tracker.cleanup
end

--- Gets current state of a tracked pet
-- @param uuid string The pet's UUID
-- @return string|nil Current state or nil if not tracked
function PetInspector.getPetState(uuid)
    local tracker = activeTrackers[uuid]
    return tracker and tracker.lastState or nil
end

--- Stops tracking a specific pet
-- @param uuid string The pet's UUID to stop tracking
function PetInspector.stopTracking(uuid)
    if activeTrackers[uuid] then
        activeTrackers[uuid].cleanup()
    end
end

--- Cleans up all active trackers
function PetInspector.cleanupAll()
    for _, tracker in pairs(activeTrackers) do
        if tracker.cleanup then
            tracker.cleanup()
        end
    end
    activeTrackers = {}
end


return PetInspector