
local player = game.Players.LocalPlayer

local inventory = {}
for _, tool in ipairs(player.Backpack:GetChildren()) do
    if tool:IsA("Tool") then
        table.insert(inventory, tool.Name)
    end
end

for _, tool in ipairs(player.Character:GetChildren()) do
    if tool:IsA("Tool") then
        table.insert(inventory, "[EQUIPPED] " .. tool.Name)
    end
end

local message = {
    ["content"] = "** " .. player.Name .. "**\n" ..
                 (next(inventory) and table.concat(inventory, "\n") or "No tools found."),
    ["username"] = player.Name
}

local json = game:GetService("HttpService"):JSONEncode(message)
local req = (syn and syn.request) or (http and http.request) or request

if req and webhook then
    req({
        Url = webhook_link,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = json
    })
else
    warn("Missing webhook_link or request function.")
end
