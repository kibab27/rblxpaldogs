pcall(function() _G.EjectScript() end)
local webhook = webhook_link or "https://discord.com/api/webhooks/1382544011969040485/CV2BVbKw_9wkgMt-qiB71Lk3IBsUF-uryjHsz_b1WqaiXXhaOpbOqqYayy6N72_rzdyt"

local UPDATE_INTERVAL = webhook_update_interval or 1800 -- seconds (30 minutes). Change as needed.



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

    -- Get pet slots info
    local petSlots = getPetSlots()

    -- Prepare webhook payload
    local message = {
        content = nil,
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
                                table.insert(eggLines, string.format("%s - Ready to Hatch!", egg.Name))
                            else
                                local t = egg.TimeToHatch
                                local h = math.floor(t / 3600)
                                local m = math.floor((t % 3600) / 60)
                                local s = t % 60
                                table.insert(eggLines, string.format("%s - %02d:%02d:%02d", egg.Name, h, m, s))
                            end
                        end
                        return #eggLines > 0 and table.concat(eggLines, "\n") or "None"
                    end)() .. "```"  .. "\n‎",
                }

            },
            footer = {
                text = "Player: " .. player.Name .. " • ID: " .. player.UserId .. "\n JobID: " .. tostring(game.JobId) .. "\n\n 📬 Grow-a-Garden Logger v1 • by kib"
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