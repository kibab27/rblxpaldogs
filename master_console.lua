if not _G.MasterConsoleUpdateChecked then
    _G.MasterConsoleUpdateChecked = true
    if _G.checkForUpdate then
        print("🔄 Forcing update check via master_console.lua (run-once per session)...")
        _G.checkForUpdate()
    else
        print("❌ checkForUpdate function not found in _G.")
    end
end