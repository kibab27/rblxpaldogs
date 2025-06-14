-- Moon Cat Passive Tracker
-- Tracks all Moon Cat pets in server and visualizes their passive cooldowns/durations

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Load APIs
local getEquippedPets = loadstring(game:HttpGet("https://raw.githubusercontent.com/kibab27/rblxpaldogs/refs/heads/main/Pet%20Stuff/InspectPetsAPI.lua"))()
local PetInspector = loadstring(game:HttpGet("https://raw.githubusercontent.com/kibab27/rblxpaldogs/main/Pet%20Stuff/TrackPetStateAPI.lua"))()
local PetPositionAPI = loadstring(game:HttpGet("https://raw.githubusercontent.com/kibab27/rblxpaldogs/main/Pet%20Stuff/PetPositionAPI.lua"))()
local getPetPassiveStats = loadstring(game:HttpGet("https://raw.githubusercontent.com/kibab27/rblxpaldogs/main/Pet%20Stuff/PassiveStatExtractorAPI.lua"))()


-- Main tracker class
local MoonCatTracker = {}
MoonCatTracker.__index = MoonCatTracker

function MoonCatTracker.new()
    local self = setmetatable({}, MoonCatTracker)
    
    self.trackedCats = {}
    self.visualElements = {}
    self.enabled = false
    self.ready = false
    self.status = "Initializing..."
    self.moonCatCount = 0
    
    self:createGUI()
    self:initialize()
    
    return self
end

function MoonCatTracker:createGUI()
    -- Create main GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MoonCatTracker"
    screenGui.Parent = PlayerGui
    screenGui.ResetOnSpawn = false
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 150)
    mainFrame.Position = UDim2.new(0, 50, 0, 50)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Make draggable
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    local function updateInput(input)
        if dragging and dragStart then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end
    
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    mainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            updateInput(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            dragStart = nil
            startPos = nil
        end
    end)
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(50, 50, 150)
    title.BorderSizePixel = 0
    title.Text = "🌙 Moon Cat Tracker"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    -- Status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -10, 0, 25)
    statusLabel.Position = UDim2.new(0, 5, 0, 35)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Initializing..."
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = mainFrame
    
    -- Cat count label
    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "CountLabel"
    countLabel.Size = UDim2.new(1, -10, 0, 25)
    countLabel.Position = UDim2.new(0, 5, 0, 60)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "Moon Cats Found: 0"
    countLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
    countLabel.TextScaled = true
    countLabel.Font = Enum.Font.Gotham
    countLabel.TextXAlignment = Enum.TextXAlignment.Left
    countLabel.Parent = mainFrame
    
    -- Toggle button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 100, 0, 35)
    toggleButton.Position = UDim2.new(0, 5, 0, 90)
    toggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = "OFF"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextScaled = true
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.Active = false
    toggleButton.Parent = mainFrame
    
    -- Corner radius for better look
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = toggleButton
    
    -- Store GUI elements
    self.gui = {
        main = mainFrame,
        status = statusLabel,
        count = countLabel,
        toggle = toggleButton
    }
    
    -- Toggle button functionality
    toggleButton.MouseButton1Click:Connect(function()
        if self.ready and self.moonCatCount > 0 then
            self:toggle()
        end
    end)
end

function MoonCatTracker:updateStatus(status)
    self.status = status
    self.gui.status.Text = "Status: " .. status
    print("[Moon Cat Tracker] " .. status)
end

function MoonCatTracker:updateCount(count)
    self.moonCatCount = count
    self.gui.count.Text = "Moon Cats Found: " .. count
    
    -- Update toggle button state
    if count > 0 and self.ready then
        self.gui.toggle.Active = true
        self.gui.toggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    else
        self.gui.toggle.Active = false
        self.gui.toggle.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end
end

function MoonCatTracker:initialize()
    self:updateStatus("Finding Moon Cats...")
    
    spawn(function()
        wait(1) -- Give time for services to load
        
        local foundCats = {}
        
        -- Search through all players
        for _, player in ipairs(Players:GetPlayers()) do
            local pets = getEquippedPets(player.Name)
            if pets then
                for _, petData in ipairs(pets) do
                    if petData.PetType == "Moon Cat" then
                        table.insert(foundCats, {
                            uuid = petData.UUID,
                            owner = player.Name,
                            petData = petData
                        })
                    end
                end
            end
        end
        
        self:updateCount(#foundCats)
        
        if #foundCats == 0 then
            self:updateStatus("No Moon Cats found")
            return
        end
        
        self:updateStatus("Calibrating Moon Cats...")
        
        -- Get passive stats and setup tracking for each cat
        for i, catInfo in ipairs(foundCats) do
            local passiveStats = getPetPassiveStats(catInfo.uuid, catInfo.owner)
            if passiveStats and passiveStats.Passives then
                -- Find the nap passive (Moon Cats typically have "Nap" passive)
                for passiveName, stats in pairs(passiveStats.Passives) do
                    if passiveName:lower():find("nap") then
                        catInfo.napPassive = {
                            name = passiveName,
                            duration = stats.Duration or 10,
                            cooldown = stats.Cooldown or 60
                        }
                        break
                    end
                end
                
                -- If no nap passive found, use first available
                if not catInfo.napPassive then
                    local firstPassive = next(passiveStats.Passives)
                    if firstPassive then
                        local stats = passiveStats.Passives[firstPassive]
                        catInfo.napPassive = {
                            name = firstPassive,
                            duration = stats.Duration or 10,
                            cooldown = stats.Cooldown or 60
                        }
                    end
                end
                
                self.trackedCats[catInfo.uuid] = catInfo
            end
            
            self:updateStatus(string.format("Calibrating... (%d/%d)", i, #foundCats))
            wait(0.1)
        end
        
        self:updateStatus("Ready!")
        self.ready = true
        self:updateCount(#foundCats)
    end)
end

function MoonCatTracker:toggle()
    self.enabled = not self.enabled
    
    if self.enabled then
        self.gui.toggle.Text = "ON"
        self.gui.toggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        self:startTracking()
    else
        self.gui.toggle.Text = "OFF"
        self.gui.toggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        self:stopTracking()
    end
end

function MoonCatTracker:startTracking()
    self:updateStatus("Tracking Active")
    
    for uuid, catInfo in pairs(self.trackedCats) do
        -- Initialize tracking state
        catInfo.state = "Unknown"
        catInfo.cooldownStartTime = nil -- When cooldown started (after nap ends)
        catInfo.napStartTime = 0
        catInfo.isNapping = false
        
        -- Start state tracking
        catInfo.cleanup = PetInspector.trackPetState(uuid, function(stateData)
            self:handleStateChange(uuid, stateData)
        end, catInfo.owner)
        
        -- Create visual elements
        self:createVisualElements(uuid, catInfo)
    end
    
    -- Start update loop
    self.updateConnection = RunService.Heartbeat:Connect(function()
        self:updateVisuals()
    end)
end

function MoonCatTracker:stopTracking()
    self:updateStatus("Ready!")
    
    -- Clean up state tracking
    for uuid, catInfo in pairs(self.trackedCats) do
        if catInfo.cleanup then
            catInfo.cleanup()
        end
    end
    
    -- Clean up visuals
    self:clearVisuals()
    
    -- Stop update loop
    if self.updateConnection then
        self.updateConnection:Disconnect()
        self.updateConnection = nil
    end
end

function MoonCatTracker:handleStateChange(uuid, stateData)
    local catInfo = self.trackedCats[uuid]
    if not catInfo then return end
    
    local newState = stateData.newState:lower()
    local currentTime = tick()
    
    if newState:find("nap") and not catInfo.isNapping then
        -- Nap started - this means cooldown just finished
        catInfo.isNapping = true
        catInfo.napStartTime = currentTime
        catInfo.cooldownStartTime = nil -- Clear cooldown timer
        print(string.format("[%s] Started napping (passive fired)", catInfo.owner))
        
    elseif catInfo.isNapping and not newState:find("nap") then
        -- Nap ended - start cooldown timer
        catInfo.isNapping = false
        catInfo.cooldownStartTime = currentTime
        print(string.format("[%s] Stopped napping (cooldown started)", catInfo.owner))
    end
    
    catInfo.state = stateData.newState
end

function MoonCatTracker:createVisualElements(uuid, catInfo)
    local petMover = self:findPetMover(uuid)
    if not petMover then return end
    
    -- Create billboard GUI with always-on-top and visibility through walls
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "MoonCatTracker_" .. uuid
    billboardGui.Size = UDim2.new(0, 300, 0, 80) -- Larger size
    billboardGui.StudsOffset = Vector3.new(0, 4, 0) -- Higher above pet
    billboardGui.AlwaysOnTop = true
    billboardGui.MaxDistance = 200
    billboardGui.Parent = petMover
    
    -- Owner label
    local ownerLabel = Instance.new("TextLabel")
    ownerLabel.Name = "OwnerLabel"
    ownerLabel.Size = UDim2.new(1, 0, 0, 20)
    ownerLabel.Position = UDim2.new(0, 0, 0, 0)
    ownerLabel.BackgroundTransparency = 1
    ownerLabel.Text = catInfo.owner
    ownerLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    ownerLabel.TextScaled = true
    ownerLabel.Font = Enum.Font.GothamBold
    ownerLabel.TextXAlignment = Enum.TextXAlignment.Center
    ownerLabel.Parent = billboardGui
    
    -- Cooldown label
    local cooldownLabel = Instance.new("TextLabel")
    cooldownLabel.Name = "CooldownLabel"
    cooldownLabel.Size = UDim2.new(0.5, 0, 0, 15)
    cooldownLabel.Position = UDim2.new(0, 0, 0, 20)
    cooldownLabel.BackgroundTransparency = 1
    cooldownLabel.Text = "Cooldown"
    cooldownLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    cooldownLabel.TextScaled = true
    cooldownLabel.Font = Enum.Font.Gotham
    cooldownLabel.TextXAlignment = Enum.TextXAlignment.Left
    cooldownLabel.Parent = billboardGui
    
    -- Cooldown bar background
    local cooldownBg = Instance.new("Frame")
    cooldownBg.Name = "CooldownBg"
    cooldownBg.Size = UDim2.new(1, -10, 0, 12) -- Larger bar
    cooldownBg.Position = UDim2.new(0, 5, 0, 35)
    cooldownBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    cooldownBg.BorderSizePixel = 0
    cooldownBg.ZIndex = 2
    cooldownBg.Parent = billboardGui
    
    -- Cooldown bar
    local cooldownBar = Instance.new("Frame")
    cooldownBar.Name = "CooldownBar"
    cooldownBar.Size = UDim2.new(0, 0, 1, 0)
    cooldownBar.Position = UDim2.new(0, 0, 0, 0)
    cooldownBar.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    cooldownBar.BorderSizePixel = 0
    cooldownBar.ZIndex = 3
    cooldownBar.Parent = cooldownBg
    
    -- Duration label
    local durationLabel = Instance.new("TextLabel")
    durationLabel.Name = "DurationLabel"
    durationLabel.Size = UDim2.new(0.5, 0, 0, 15)
    durationLabel.Position = UDim2.new(0, 0, 0, 50)
    durationLabel.BackgroundTransparency = 1
    durationLabel.Text = "Duration"
    durationLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    durationLabel.TextScaled = true
    durationLabel.Font = Enum.Font.Gotham
    durationLabel.TextXAlignment = Enum.TextXAlignment.Left
    durationLabel.Parent = billboardGui
    
    -- Duration bar background
    local durationBg = Instance.new("Frame")
    durationBg.Name = "DurationBg"
    durationBg.Size = UDim2.new(1, -10, 0, 12) -- Larger bar
    durationBg.Position = UDim2.new(0, 5, 0, 65)
    durationBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    durationBg.BorderSizePixel = 0
    durationBg.ZIndex = 2
    durationBg.Parent = billboardGui
    
    -- Duration bar
    local durationBar = Instance.new("Frame")
    durationBar.Name = "DurationBar"
    durationBar.Size = UDim2.new(0, 0, 1, 0)
    durationBar.Position = UDim2.new(0, 0, 0, 0)
    durationBar.BackgroundColor3 = Color3.fromRGB(255, 150, 100)
    durationBar.BorderSizePixel = 0
    durationBar.ZIndex = 3
    durationBar.Parent = durationBg
    
    -- Create much more visible beam
    local beam = Instance.new("Beam")
    beam.Name = "WarningBeam"
    beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
    beam.Width0 = 3 -- Wider beam
    beam.Width1 = 3
    beam.LightEmission = 1 -- Brighter
    beam.LightInfluence = 0 -- Not affected by lighting
    beam.Transparency = NumberSequence.new(0.2) -- More opaque
    beam.Enabled = false
    
    -- Create attachment points for beam (higher and more visible)
    local att0 = Instance.new("Attachment")
    att0.Name = "BeamStart"
    att0.Position = Vector3.new(0, 1, 0) -- Start from base of pet
    att0.Parent = petMover
    
    local att1 = Instance.new("Attachment")
    att1.Name = "BeamEnd"
    att1.Position = Vector3.new(0, 12, 0) -- Higher end point
    att1.Parent = petMover
    
    beam.Attachment0 = att0
    beam.Attachment1 = att1
    beam.Parent = petMover
    
    -- Add pulsing effect to beam
    local pulseTween = TweenService:Create(beam, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Width0 = 5,
        Width1 = 5
    })
    pulseTween:Play()
    
    -- Store visual elements
    self.visualElements[uuid] = {
        billboard = billboardGui,
        cooldownBar = cooldownBar,
        durationBar = durationBar,
        beam = beam,
        pulseTween = pulseTween,
        petMover = petMover
    }
end

function MoonCatTracker:findPetMover(uuid)
    local petsPhysical = workspace:FindFirstChild("PetsPhysical")
    if not petsPhysical then return nil end
    
    for _, petMover in ipairs(petsPhysical:GetChildren()) do
        if petMover.Name == "PetMover" and petMover:GetAttribute("UUID") == uuid then
            return petMover
        end
    end
    return nil
end

function MoonCatTracker:updateVisuals()
    local currentTime = tick()
    
    for uuid, catInfo in pairs(self.trackedCats) do
        local visuals = self.visualElements[uuid]
        if not visuals then continue end
        
        local napPassive = catInfo.napPassive
        if not napPassive then continue end
        
        -- Calculate cooldown progress
        local cooldownProgress = 0
        if catInfo.cooldownStartTime then
            local timeSinceCooldownStart = currentTime - catInfo.cooldownStartTime
            cooldownProgress = math.min(timeSinceCooldownStart / napPassive.cooldown, 1)
        elseif catInfo.isNapping then
            cooldownProgress = 0
        else
            cooldownProgress = 1
        end
        
        -- Update cooldown bar
        TweenService:Create(visuals.cooldownBar, TweenInfo.new(0.1), {
            Size = UDim2.new(cooldownProgress, 0, 1, 0)
        }):Play()
        
        -- Update duration bar (only if napping)
        if catInfo.isNapping then
            local napDuration = currentTime - catInfo.napStartTime
            local durationProgress = math.min(napDuration / napPassive.duration, 1)
            
            TweenService:Create(visuals.durationBar, TweenInfo.new(0.1), {
                Size = UDim2.new(durationProgress, 0, 1, 0)
            }):Play()
        else
            visuals.durationBar.Size = UDim2.new(0, 0, 1, 0)
        end
        
        -- Handle beam visibility and color
        if catInfo.isNapping then
            -- Show bright green beam during nap
            visuals.beam.Enabled = true
            visuals.beam.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0))
            visuals.beam.Width0 = 5
            visuals.beam.Width1 = 5
        elseif catInfo.cooldownStartTime and not catInfo.isNapping then
            -- Calculate time remaining in cooldown
            local timeSinceCooldownStart = currentTime - catInfo.cooldownStartTime
            local timeUntilReady = napPassive.cooldown - timeSinceCooldownStart
            
            if timeUntilReady <= 5 and timeUntilReady > 0 then
                -- Show pulsing yellow beam 5 seconds before ready
                visuals.beam.Enabled = true
                visuals.beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
                visuals.beam.Width0 = 5
                visuals.beam.Width1 = 5
            elseif timeUntilReady <= 0 then
                -- Cooldown finished, ready to nap - keep yellow beam
                visuals.beam.Enabled = true
                visuals.beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
                visuals.beam.Width0 = 5
                visuals.beam.Width1 = 5
            else
                -- Still cooling down, hide beam
                visuals.beam.Enabled = false
            end
        elseif not catInfo.cooldownStartTime and not catInfo.isNapping then
            -- Initial state - assume ready (show yellow beam)
            visuals.beam.Enabled = true
            visuals.beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
            visuals.beam.Width0 = 5
            visuals.beam.Width1 = 5
        else
            -- Hide beam
            visuals.beam.Enabled = false
        end
    end
end

function MoonCatTracker:clearVisuals()
    for uuid, visuals in pairs(self.visualElements) do
        if visuals.billboard then
            visuals.billboard:Destroy()
        end
        if visuals.beam then
            visuals.beam:Destroy()
        end
        if visuals.pulseTween then
            visuals.pulseTween:Cancel()
        end
        if visuals.petMover then
            local att0 = visuals.petMover:FindFirstChild("BeamStart")
            local att1 = visuals.petMover:FindFirstChild("BeamEnd")
            if att0 then att0:Destroy() end
            if att1 then att1:Destroy() end
        end
    end
    self.visualElements = {}
end

-- Initialize tracker
local tracker = MoonCatTracker.new()

-- Cleanup on script end
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        tracker:stopTracking()
        PetInspector.cleanupAll()
    end
end)