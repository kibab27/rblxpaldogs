if  _G.MasterConsoleUpdateChecked then
    _G.MasterConsoleUpdateChecked = nil
    if _G.checkForUpdate then
        print("🔄 Forcing update check via master_console.lua (run-once per session)...")
        _G.checkForUpdate()
    else
        print("❌ checkForUpdate function not found in _G.")
    end
end