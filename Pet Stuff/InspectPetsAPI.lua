-- Equipped Pet Getter API
-- Usage: local getEquippedPets = loadstring(game:HttpGet("https://your-url.com/pets.lua"))()
--        local pets = getEquippedPets("SomePlayer") or getEquippedPets()

return function(playerName)
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local PetUtilities = require(ReplicatedStorage.Modules.PetServices.PetUtilities)

    -- Resolve the player
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

    -- Safely get equipped pets
    local success, pets = pcall(function()
        return PetUtilities:GetPetsSortedByAge(targetPlayer, 0, false, true)
    end)

    if not success or not pets or #pets == 0 then
        return nil
    end

    return pets
end
