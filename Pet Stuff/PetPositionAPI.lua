
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStream = ReplicatedStorage.GameEvents.DataStream

local PetPositionAPI = {}
local trackedPets = {}

-- Internal function to handle data updates
local function processDataUpdate(petUUID, path, value)
    if path:find("PositionalData$") then
        trackedPets[petUUID].startPos = value.StartPosition
        trackedPets[petUUID].goalPos = value.GoalPosition
        trackedPets[petUUID].startTime = value.StartTime
    elseif path:find("CurrentCFrame$") then
        trackedPets[petUUID].currentPos = value.Position
    end
    trackedPets[petUUID].lastUpdate = os.clock()
end

-- Connect to data stream
DataStream.OnClientEvent:Connect(function(action, serviceName, data)
    if action == "UpdateData" and serviceName == "ActivePetsService_Replicator" then
        for _, entry in ipairs(data) do
            local path, value = entry[1], entry[2]
            local _, petUUID = path:match("ROOT/ActivePetStates/([^/]+)/({[^}]+})")
            if petUUID and trackedPets[petUUID] then
                processDataUpdate(petUUID, path, value)
            end
        end
    end
end)

-- API Functions
function PetPositionAPI.track(petUUID)
    if not trackedPets[petUUID] then
        trackedPets[petUUID] = {
            currentPos = nil,
            startPos = nil,
            goalPos = nil,
            startTime = 0,
            lastUpdate = 0
        }
    end
    return true
end

function PetPositionAPI.stop(petUUID)
    trackedPets[petUUID] = nil
    return true
end

function PetPositionAPI.get(petUUID)
    local data = trackedPets[petUUID]
    if not data then return nil end
    
    return {
        current = data.currentPos,
        start = data.startPos,
        goal = data.goalPos,
        startTime = data.startTime,
        lastUpdate = data.lastUpdate
    }
end

function PetPositionAPI.predict(petUUID)
    local data = trackedPets[petUUID]
    if not data or not data.currentPos then return nil end
    
    -- If no movement data, return current position
    if not data.startPos or not data.goalPos then
        return data.currentPos
    end
    
    -- Calculate prediction
    local direction = (data.goalPos - data.startPos).Unit
    local totalDist = (data.goalPos - data.startPos).Magnitude
    local traveled = (data.currentPos - data.startPos).Magnitude
    local progress = math.clamp(traveled / totalDist, 0, 1)
    
    return {
        position = data.startPos + (direction * (totalDist * progress)),
        progress = progress,
        remaining = totalDist - traveled
    }
end

return PetPositionAPI



--[[ 
            Usage Example:
            -- In any client script where you need pet positions
            local PetPositionAPI = loadstring(game:HttpGet("https://raw.githubusercontent.com/your-username/your-repo/main/PetPositionAPI.lua"))()

            -- Example usage:
            local myPetUUID = "{12345678-1234-5678-1234-567812345678}"

            -- Start tracking
            PetPositionAPI.track(myPetUUID)

            -- Get current data
            local positionData = PetPositionAPI.get(myPetUUID)
            if positionData then
                print("Current position:", positionData.current)
                print("Movement path:", positionData.start, "→", positionData.goal)
            end

            -- Get prediction
            local prediction = PetPositionAPI.predict(myPetUUID)
            if prediction then
                print(string.format(
                    "Predicted position: %s (%.1f%% complete, %.2f studs remaining)",
                    prediction.position,
                    prediction.progress * 100,
                    prediction.remaining
                ))
            end

            -- Stop tracking when done
            PetPositionAPI.stop(myPetUUID)
]]--