if not _G.MasterConsoleRan then
    _G.MasterConsoleRan = true

    local url = webhook_link or _G.webhook_link
    if url then
        local req = (syn and syn.request) or (http and http.request) or request
        if req then
            req({
                Url = url,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = game:GetService("HttpService"):JSONEncode({
                    content = "[MASTER CONSOLE] Test message fired successfully!"
                })
            })
        end
    end
end