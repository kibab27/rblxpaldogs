-- Passive Stat Extractor API Module
-- Usage: local getPetPassiveStats = loadstring(game:HttpGet("..."))()
--        local data = getPetPassiveStats(uuid [, playerName])

return function(uuid, playerName)
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local PetRegistry = require(ReplicatedStorage.Data.PetRegistry)
    local PetUtilities = require(ReplicatedStorage.Modules.PetServices.PetUtilities)
    local ActivePetsService = require(ReplicatedStorage.Modules.PetServices.ActivePetsService)

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
        warn("Player not found: " .. tostring(playerName))
        return nil
    end

    local success, equippedPets = pcall(function()
        return PetUtilities:GetPetsSortedByAge(targetPlayer, 0, false, true)
    end)

    if not success or not equippedPets then
        warn("Failed to retrieve equipped pets for " .. targetPlayer.Name)
        return nil
    end

    for _, petData in ipairs(equippedPets) do
        if petData.UUID == uuid then
            local petInfo = petData.PetData
            local petType = petData.PetType or petInfo.Name
            local petConfig = PetRegistry.PetList[petType]

            if not petConfig or not petConfig.Passives then
                warn("No passives found for pet: " .. tostring(petType))
                return nil
            end

            local currentWeight = PetUtilities:CalculateWeight(petInfo.BaseWeight or 1, petInfo.Level or 1)

            local output = {
                UUID = uuid,
                PetType = petType,
                Level = petInfo.Level or 1,
                Passives = {}
            }

            for _, passiveName in ipairs(petConfig.Passives) do
                local stats = PetUtilities:GetCurrentLevelState(currentWeight, passiveName)
                if stats then
                    output.Passives[passiveName] = {
                        Range = stats.Range,
                        Duration = stats.Duration,
                        Cooldown = stats.Cooldown
                    }
                end
            end

            return output
        end
    end

    warn("Pet UUID not found among equipped pets.")
    return nil
end
