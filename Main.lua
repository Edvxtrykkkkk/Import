-- NARS RBX IMPORTER
-- Main entry point (modular)
-- Load order: Environment -> Parser -> ImportCore -> ImporterUI

local BASE_URL = "https://raw.githubusercontent.com/Edvxtrykkkkk/Import/refs/heads/main/"

local function loadService(filename)
    local okFetch, source = pcall(function()
        return game:HttpGet(BASE_URL .. filename)
    end)

    if not okFetch or type(source) ~= "string" or source == "" then
        error("[NARS RBX IMPORTER] Failed to load " .. filename, 0)
    end

    local chunk, compileError = loadstring(source, "@" .. filename)
    if not chunk then
        error("[NARS RBX IMPORTER] Compile failed for " .. filename .. ": " .. tostring(compileError), 0)
    end

    local okRun, result = pcall(chunk)
    if not okRun then
        error("[NARS RBX IMPORTER] Execute failed for " .. filename .. ": " .. tostring(result), 0)
    end

    return result
end

-- Dependency order is intentional
loadService("Environment.lua")
loadService("Parser.lua")
loadService("ImportCore.lua")
loadService("ImporterUI.lua")

if type(initializeImporter) ~= "function" then
    error("[NARS RBX IMPORTER] initializeImporter() is missing.", 0)
end

local ok, result = pcall(initializeImporter)
if not ok then
    error("[NARS RBX IMPORTER] Initialization failed: " .. tostring(result), 0)
end

return result
