local webhook = "https://discord.com/api/webhooks/1382134335238443090/XCkrCU6atsiZi4PecJDz0MbWyH_XN-sm1J-UDsh2h_4SNT4s1pJ4gsUqa5ptaXh2pEOx"

local player = game:GetService("Players").LocalPlayer
local HttpService = game:GetService("HttpService")

local function debug(msg)
    pcall(function()
        game.StarterGui:SetCore("ChatMakeSystemMessage", { Text = "[DEBUG] " .. msg })
    end)
end

debug("Started inventory classifier")

local inventory = {}
local seeds, eggs, gears, pets = {}, {}, {}, {}

-- Gather items from backpack and character
local function collectItems(container)
    for _, tool in ipairs(container:GetChildren()) do
        if tool:IsA("Tool") then
            local itemName = tool.Name
            table.insert(inventory, itemName)

            local lower = itemName:lower()

            if lower:match("seed$") then
                table.insert(seeds, itemName)
            elseif lower:match("egg$") then
                table.insert(eggs, itemName)
            elseif lower:match("sprinkler$") or lower:match("staff$") or lower:match("rod$") then
                table.insert(gears, itemName)
            elseif lower:find("age") then
                table.insert(pets, itemName)
            end
        end
    end
end

collectItems(player.Backpack)
collectItems(player.Character or player.CharacterAdded:Wait())

-- Format inventory sections
local function formatList(list)
    if #list == 0 then return "```\n   None\n```" end
    local counts = {}
    for _, item in ipairs(list) do
        counts[item] = (counts[item] or 0) + 1
    end

    local lines = {}
    for item, count in pairs(counts) do
        table.insert(lines, string.format("   [%dx] %s", count, item))
    end

    return "```\n" .. table.concat(lines, "\n") .. "\n```"
end

-- Final message formatting
local message = {
    content = nil,
    username = player.Name,
    embeds = {{
        title = "**" .. player.Name .. "**",
        description = "_ _\n**🪙 Sheckles  **: " .. tostring(player.leaderstats and player.leaderstats:FindFirstChild("Sheckles") and player.leaderstats.Sheckles.Value or "Unknown") .. "\n_ _\n_ _\n**🎒 | Inventory**\n_ _\n_ _",
        color = 2750290,
        fields = {
            {
                name = "> 🐶 | Pets & Ages",
                value = formatList(pets),
                inline = false
            },
            {
                name = "> 🥚 | Eggs",
                value = formatList(eggs),
                inline = false
            },
            {
                name = "> 🔧 | Gears",
                value = formatList(gears),
                inline = false
            },
            {
                name = "> 🌱 | Seeds",
                value = formatList(seeds),
                inline = false
            }
        }
    }}
}

-- Send to Discord
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
