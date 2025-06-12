local webhook = webhook_link or "https://discord.com/api/webhooks/123456789012345678/abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"

local UPDATE_INTERVAL = update_interval or 1800 -- seconds (30 minutes). Change as needed.

local player = game:GetService("Players").LocalPlayer
local HttpService = game:GetService("HttpService")

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

-- Gather inventory
local allItems = {}
local function gatherItems(container)
    for _, tool in ipairs(container:GetChildren()) do
        if tool:IsA("Tool") then
            table.insert(allItems, tool.Name)
        end
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

local function codeBlock(list)
    if #list == 0 then return "```\nNone\n```" end
    return "```\n   " .. table.concat(list, "\n‎ ‎ ‎ ‎") .. "\n```"
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
    local gears = filterItems({ "sprinkler", "staff", "rod" })

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
                local nameLabel = petFrame:FindFirstChild("PET_NAME")
                local typeLabel = petFrame:FindFirstChild("PET_TYPE")
                local ageLabel = petFrame:FindFirstChild("PET_AGE")

                if nameLabel and typeLabel and ageLabel then
                    local name = nameLabel.Text
                    local petType = typeLabel.Text
                    local age = ageLabel.Text:gsub("Age: ", "")
                    table.insert(petsEquipped, string.format("%s (%s) — Age: %s", name, petType, age))
                    debug("🟢 Found pet: " .. name)
                else
                    debug("⚠️ Skipped pet UI frame: " .. petFrame.Name)
                end
            end
        end
    end)

    if not success then
        debug("❌ Failed to scan equipped pets: " .. tostring(err))
    end

    -- Prepare webhook payload
    local message = {
        content = nil,
        username = player.Name,
        avatar_url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=100&height=100&format=png",
        embeds = { {
            title = "**" .. player.Name .. "**",
            description = "_ _\n> **🪙 Sheckles  **: " ..
                (player.leaderstats and player.leaderstats:FindFirstChild("Sheckles") and formatNumberWithCommas(player.leaderstats.Sheckles.Value) or "Unknown") ..
                "\n_ _\n_ _\n**> 🎒 | Inventory**\n_ _\n_ _",
            color = 2750290,
            fields = {
                {
                    name = "> 🐶 | Pets Equipped",
                    value = codeBlock(petsEquipped),
                    inline = false
                },
                {
                    name = "> 🥚 | Eggs & Pets",
                    value = codeBlock(eggs)  .. "\n" .. codeBlock(pets),
                    inline = false
                },
                {
                    name = "> 🔧 | Gears",
                    value = codeBlock(gears),
                    inline = false
                },
                {
                    name = "> 🌱 | Seeds",
                    value = codeBlock(seeds),
                    inline = false
                }
            },
            footer = {
                text = "User: " .. player.Name .. " | ID: " .. player.UserId
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

-- Initial send
gatherAndSend()

-- Loop for periodic updates
spawn(function()
    while true do
        wait(UPDATE_INTERVAL)
        gatherAndSend()
    end
end)