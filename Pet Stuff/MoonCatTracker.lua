repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
repeat task.wait() until LocalPlayer:FindFirstChild("PlayerGui")



-- 🌙 Moon Cat Passive Tracker by kib
-- Make sure these APIs are loaded:
local getEquippedPets = loadstring(game:HttpGet("https://raw.githubusercontent.com/kibab27/rblxpaldogs/refs/heads/main/Pet%20Stuff/InspectPetsAPI.lua"))()
local PetInspector = loadstring(game:HttpGet("https://raw.githubusercontent.com/kibab27/rblxpaldogs/main/Pet%20Stuff/TrackPetStateAPI.lua"))()
local PetPositionAPI = loadstring(game:HttpGet("https://raw.githubusercontent.com/kibab27/rblxpaldogs/main/Pet%20Stuff/PetPositionAPI.lua"))()
local getPassiveStats = loadstring(game:HttpGet("https://raw.githubusercontent.com/kibab27/rblxpaldogs/main/Pet%20Stuff/PassiveStatExtractorAPI.lua"))()

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MoonCatUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 250, 0, 150)
Frame.Position = UDim2.new(0, 20, 0, 80)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Name = "MoonCatUI"

local StatusLabel = Instance.new("TextLabel", Frame)
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.new(1, 1, 1)
StatusLabel.Text = "🌙 Finding Moon Cats..."

local Toggle = Instance.new("TextButton", Frame)
Toggle.Position = UDim2.new(0, 0, 0, 40)
Toggle.Size = UDim2.new(1, 0, 0, 30)
Toggle.Text = "🔄 Toggle Visuals"
Toggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
Toggle.TextColor3 = Color3.new(1, 1, 1)
Toggle.AutoButtonColor = false
Toggle.Active = false
Toggle.BackgroundTransparency = 0.5

local MoonCats = {}
local visualsEnabled = true

local function updateStatus(text)
    StatusLabel.Text = text
end

local function createBeamAttachment(part)
    local attachment = Instance.new("Attachment", part)
    local beam = Instance.new("Beam", part)
    beam.Attachment0 = attachment
    beam.Attachment1 = attachment
    beam.FaceCamera = true
    beam.Width0, beam.Width1 = 0.5, 0.5
    beam.LightEmission = 1
    beam.Enabled = false
    return beam
end

local function visualizeCooldown(petUUID, passiveInfo, petName)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "MoonCatTracker_" .. petUUID
    billboard.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    billboard.Name = "MoonCatTracker_" .. petUUID
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = true

    local text = Instance.new("TextLabel", billboard)
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.new(1, 1, 1)
    text.TextScaled = true
    text.Text = "Tracking " .. petName

    local beam = nil

    PetInspector.trackPetState(petUUID, function(data)
        local now = os.clock()
        if data.newState == "Nap" then
            local duration = passiveInfo.Duration
            local cooldown = passiveInfo.Cooldown
            local startTime = now

            if not beam and data.position then
                local part = Instance.new("Part")
                part.Anchored = true
                part.CanCollide = false
                part.Size = Vector3.new(0.1, 0.1, 0.1)
                part.Position = data.position
                part.Transparency = 1
                part.Parent = workspace
                beam = createBeamAttachment(part)
            end

            coroutine.wrap(function()
                while os.clock() - startTime < cooldown do
                    local elapsed = os.clock() - startTime
                    local remaining = math.max(cooldown - elapsed, 0)
                    text.Text = string.format("🌙 %s - %.1fs", petName, remaining)

                    if remaining <= 5 and visualsEnabled then
                        if beam then
                            beam.Enabled = true
                            beam.Color = ColorSequence.new(Color3.new(1, 1, 0)) -- Yellow
                        end
                    else
                        if beam then beam.Enabled = false end
                    end

                    if elapsed >= duration and beam then
                        beam.Enabled = false
                    end

                    RunService.Heartbeat:Wait()
                end
                text.Text = "🌙 Ready"
                if beam then beam.Enabled = false end
            end)()
        end
    end)
end

-- INIT FUNCTION
local function init()
    updateStatus("🔍 Finding Moon Cats...")
    local totalMoonCats = 0

    for _, player in ipairs(Players:GetPlayers()) do
        local pets = getEquippedPets(player.Name)
        if pets then
            for _, pet in ipairs(pets) do
                if pet and pet.PetType == "Moon Cat" then
                    totalMoonCats = totalMoonCats + 1
                    local passiveData = getPassiveStats(pet.UUID, player.Name)
                    local stats = passiveData and passiveData.Passives and passiveData.Passives["Moonlight Pulse"]
                    if stats then
                        MoonCats[pet.UUID] = true
                        PetPositionAPI.track(pet.UUID)
                        visualizeCooldown(pet.UUID, stats, pet.PetData.Name or "Moon Cat")
                    end
                end
            end
        end
    end

    if totalMoonCats > 0 then
        updateStatus("✅ Ready! Moon Cats: " .. totalMoonCats)
        Toggle.Active = true
        Toggle.BackgroundColor3 = Color3.fromRGB(60, 150, 60)
    else
        updateStatus("⚠️ No Moon Cats found.")
        Toggle.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end
end

Toggle.MouseButton1Click:Connect(function()
    if not Toggle.Active then return end
    visualsEnabled = not visualsEnabled
    Toggle.Text = visualsEnabled and "✅ Visuals On" or "❌ Visuals Off"
end)

-- Start
init()
