-- NARS RBX IMPORTER
-- ImportCore: filesystem scanning + asset insertion
-- Handles Script / LocalScript / ModuleScript → StudioLite Codebox

local function getEnv()
    return rawget(_G, "NARS_RBX_ENV") or {}
end

local function executor()
    local env = getEnv()
    return env.Executor or {}
end

local function executorFunction(name)
    local fn = executor()[name]
    if type(fn) == "function" then return fn end
    fn = rawget(_G, name)
    return type(fn) == "function" and fn or nil
end

-- ============================================================
-- Script Source Handling (StudioLite Codebox)
-- ============================================================
function runProtected10(instance, sourceMap)
    if typeof(instance) ~= "Instance" or not instance:IsA("LuaSourceContainer") then
        return false
    end

    local key = instance.ClassName .. ":" .. instance.Name
    local source

    -- Parser source-map is primary
    if type(sourceMap) == "table"
        and type(sourceMap[key]) == "table"
        and #sourceMap[key] > 0 then
        source = table.remove(sourceMap[key], 1)
        if type(source) == "string" then
            source = source:gsub(string.char(0) .. "*$", "")
        end
    end

    -- Fallback to Instance.Source
    if type(source) ~= "string" then
        local ok, fallback = pcall(function()
            return instance.Source
        end)
        if ok and type(fallback) == "string" then
            source = fallback
        else
            source = ""
        end
    end

    -- Store raw source
    local rawSources = rawget(_G, "NARS_RAW_SOURCES")
    if type(rawSources) == "table" then
        local storeKey = instance.ClassName .. instance.Name
        rawSources[storeKey] = source
        rawSources[key] = source
    end

    -- Push into StudioLite Codebox via ServerFunctions if available
    local env = getEnv()
    local serverFn = env.StudioLiteServerFunctions or rawget(_G, "aw")

    if serverFn and typeof(serverFn) == "Instance" then
        local methodMap = {
            Script       = "InsertScriptScript",
            LocalScript  = "InsertLocalScriptLocalScript",
            ModuleScript = "InsertModuleScriptModuleScript",
        }
        local method = methodMap[instance.ClassName]
        if method then
            pcall(function()
                serverFn:InvokeServer(method, instance.Name, source)
            end)
        end
    end

    -- Also try to set Source if possible (some environments allow it)
    pcall(function()
        if instance:IsA("ModuleScript") or instance:IsA("Script") or instance:IsA("LocalScript") then
            -- Source is usually locked; the Codebox route above is the real path
        end
    end)

    return true
end

-- ============================================================
-- Helpers
-- ============================================================
function extractDigits(value)
    local aw = rawget(_G, "aw")
    if not aw or value == nil or value == "" then return nil end
    local id = tostring(value):match("%d+")
    if not id then return nil end
    pcall(function()
        aw:InvokeServer("LoadMeshToRuntimeMeshes", tonumber(id))
    end)
    return id
end

function checkCondition5(value)
    return typeof(value) == "Instance"
end

local function getFileName(path)
    path = tostring(path or "")
    return path:match("([^/\\]+)$") or path
end

function createFolder(asset)
    if type(asset) ~= "table" then return nil end
    local baseName = getFileName(asset.path):gsub("%.[^%.]+$", "")
    baseName = baseName:gsub("[^%w%-%_ ]", "_")
    if baseName == "" then baseName = "ImportedAsset" end

    local name, suffix = baseName, 1
    while workspace:FindFirstChild(name) do
        suffix += 1
        name = baseName .. "_" .. tostring(suffix)
    end

    local folder = Instance.new("Folder")
    folder.Name = name
    folder:SetAttribute("NARS_RBXL_IMPORT", true)
    folder:SetAttribute("SourceFile", tostring(asset.path))
    folder.Parent = workspace
    return folder
end

function runProtected12(instance, parent)
    if typeof(instance) ~= "Instance" or typeof(parent) ~= "Instance" then return false end
    local ok = pcall(function() instance.Parent = parent end)
    return ok and instance.Parent == parent
end

function runProtected13(container, parent, sourceMap)
    if typeof(container) ~= "Instance" or typeof(parent) ~= "Instance" then return 0 end
    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok then return 0 end
    local count = 0
    for _, child in ipairs(children) do
        if runProtected12(child, parent) then
            count += 1
            runProtected10(child, sourceMap)
            -- recurse
            count += runProtected13(child, child, sourceMap)
        end
    end
    return count
end

function runProtected14(instances, parent, sourceMap)
    if type(instances) ~= "table" or typeof(parent) ~= "Instance" then return 0 end
    local count = 0
    for _, instance in ipairs(instances) do
        if typeof(instance) == "Instance" then
            local isDataModel = false
            pcall(function() isDataModel = instance:IsA("DataModel") end)
            if isDataModel then
                count += runProtected13(instance, parent, sourceMap)
            elseif runProtected12(instance, parent) then
                count += 1
                runProtected10(instance, sourceMap)
                count += runProtected13(instance, instance, sourceMap)
            end
            if count > 0 and count % 40 == 0 then
                task.wait()
            end
        end
    end
    return count
end

function computeValue5(instances, isRBXL, sourceMap, asset)
    local folder = createFolder(asset)
    if not folder then return 0 end
    local count = runProtected14(instances, folder, sourceMap)
    if count <= 0 then
        pcall(function() folder:Destroy() end)
        return 0
    end
    return count
end

-- ============================================================
-- File System Scanning
-- ============================================================
local SEARCH_PATHS = {
    "",
    "workspace",
    "Delta/workspace",
    "delta/workspace",
    "Android/Delta/workspace",
    "Download",
    "Downloads",
    "../Download",
    "../../Download",
    "Android/Download",
    "/sdcard/Download",
    "/sdcard/Downloads",
    "/sdcard/Delta/workspace",
    "/sdcard/Android/Delta/workspace",
    "/storage/emulated/0/Download",
    "/storage/emulated/0/Downloads",
    "../workspace",
    ".",
}

local EXTENSIONS = {
    [".rbxm"] = true,
    [".rbxl"] = true,
    [".rbxlx"] = true,
}

local function isAssetFile(path)
    if type(path) ~= "string" then return false end
    local lower = path:lower()
    for ext in pairs(EXTENSIONS) do
        if lower:sub(-#ext) == ext then
            return true, ext
        end
    end
    return false
end

local function safeListFiles(path)
    local listfiles = executorFunction("listfiles")
    if not listfiles then return {} end
    local ok, result = pcall(listfiles, path)
    if ok and type(result) == "table" then
        return result
    end
    return {}
end

local function safeIsFolder(path)
    local isfolder = executorFunction("isfolder")
    if not isfolder then return false end
    local ok, result = pcall(isfolder, path)
    return ok and result == true
end

local function safeReadFile(path)
    local readfile = executorFunction("readfile")
    if not readfile then return nil end
    local ok, content = pcall(readfile, path)
    if ok and type(content) == "string" then
        return content
    end
    return nil
end

-- Recursive collect
local function collectAssets(basePath, results, depth)
    depth = depth or 0
    if depth > 6 then return end

    local files = safeListFiles(basePath)
    for _, entry in ipairs(files) do
        local full = entry
        if basePath ~= "" and not entry:find(basePath, 1, true) then
            full = basePath .. "/" .. entry
        end

        if safeIsFolder(full) then
            collectAssets(full, results, depth + 1)
        else
            local isAsset, ext = isAssetFile(full)
            if isAsset then
                local size = 0
                local content = safeReadFile(full)
                if content then
                    size = #content
                end
                table.insert(results, {
                    path = full,
                    name = getFileName(full),
                    ext = ext,
                    size = size,
                    content = content, -- may be nil if too large / failed
                })
            end
        end
    end
end

function processItems6()
    local results = {}
    local seen = {}

    for _, path in ipairs(SEARCH_PATHS) do
        collectAssets(path, results, 0)
    end

    -- Deduplicate by path
    local unique = {}
    for _, asset in ipairs(results) do
        if not seen[asset.path] then
            seen[asset.path] = true
            table.insert(unique, asset)
        end
    end

    -- Sort by name
    table.sort(unique, function(a, b)
        return (a.name or "") < (b.name or "")
    end)

    return unique
end

-- ============================================================
-- Import single asset
-- ============================================================
function runProtected16(asset)
    if type(asset) ~= "table" or type(asset.path) ~= "string" then
        return false, "Invalid asset"
    end

    local content = asset.content
    if type(content) ~= "string" or #content == 0 then
        content = safeReadFile(asset.path)
    end
    if type(content) ~= "string" or #content == 0 then
        return false, "Cannot read file"
    end

    -- Call Parser – primary entry is runProtected9 (original obfuscated parser)
    local parseFn = rawget(_G, "runProtected9") or rawget(_G, "bf") or rawget(_G, "au")
    if type(parseFn) ~= "function" then
        return false, "Parser not loaded (runProtected9 missing)"
    end

    local ok, result = pcall(parseFn, content)
    if not ok then
        return false, "Parse error: " .. tostring(result)
    end

    -- runProtected9 typically returns instances + sourceMap (or a single root)
    local instances, sourceMap
    if type(result) == "table" then
        if result[1] and typeof(result[1]) == "Instance" then
            instances = result
            sourceMap = {}
        else
            instances = result.instances or result[1] or result
            sourceMap = result.sources or result.sourceMap or {}
        end
    else
        instances = {result}
        sourceMap = {}
    end

    if type(instances) ~= "table" then
        instances = {instances}
    end

    local count = computeValue5(instances, asset.ext == ".rbxl" or asset.ext == ".rbxlx", sourceMap, asset)
    if count <= 0 then
        return false, "No instances imported"
    end

    return true, string.format("Imported %d objects", count)
end

-- Public aliases kept for UI compatibility
by = processItems6
bx = runProtected16

return {
    scanAssets = processItems6,
    importAsset = runProtected16,
    handleScriptSource = runProtected10,
}
