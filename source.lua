-- Replace with your actual Discord webhook
local webhook = webhook_link

local player = game:GetService("Players").LocalPlayer
local inventory = {}

-- Backpack tools
for _, tool in ipairs(player.Backpack:GetChildren()) do
    if tool:IsA("Tool") then
        table.insert(inventory, tool.Name)
    end
end

-- Equipped tools
local character = player.Character or player.CharacterAdded:Wait()
for _, tool in ipairs(character:GetChildren()) do
    if tool:IsA("Tool") then
        table.insert(inventory, "[EQUIPPED] " .. tool.Name)
    end
end

-- Message format
local message = {
    ["content"] = "**Inventory for " .. player.Name .. "**\n" ..
                 (next(inventory) and table.concat(inventory, "\n") or "No tools found."),
    ["username"] = player.Name,
    ["avatar_url"] = "https://www.roblox.com/Thumbs/Avatar.ashx?x=100&y=100&Format=Png&userid=" .. player.UserId
}

-- Send it using executor-provided HTTP function
local json = game:GetService("HttpService"):JSONEncode(message)

-- Most executors use `syn.request`, `http_request`, or `request`
local req = (syn and syn.request) or (http and http.request) or request

if req then
    req({
        Url = webhook,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = json
    })
    print("Inventory sent to Discord.")
else
    warn("Your executor does not support HTTP requests.")
end
