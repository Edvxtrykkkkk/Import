-- NARS RBX IMPORTER
-- Environment
-- Shared runtime bridge for Main.lua, Parser.lua, ImportCore.lua and ImporterUI.lua.

local executorEnv = (type(getfenv) == "function" and getfenv()) or _G

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local InsertService = game:GetService("InsertService")
local HttpService = game:GetService("HttpService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    LocalPlayer = Players.PlayerAdded:Wait()
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)

-- ============================================================
-- Icon Module (hardcoded asset ids as requested)
-- Usage: Image = Icon.Close  (or Icons.Close)
-- ============================================================
local Icon = {
    Maximize = 73085922906397,
    Close    = 110786993356448,
    Minimal  = 118026365011536,
    FileCode = 77253337986109,
    Refresh  = 138133190015277,
    Import   = 93307473217005,
    List     = 96385120752336,
    Search   = 80009010551347,
    Checklis = 93898873302694,
    Logo     = 122926744824622,
}

-- Also expose as Icons with rbxassetid prefix for convenience
local Icons = {}
for name, id in pairs(Icon) do
    Icons[name] = "rbxassetid://" .. tostring(id)
end

-- Resolve best parent for ScreenGui
local function resolveHost()
    local getHiddenUi = rawget(executorEnv, "gethui") or rawget(executorEnv, "get_hidden_gui")
    if type(getHiddenUi) == "function" then
        local ok, gui = pcall(getHiddenUi)
        if ok and typeof(gui) == "Instance" then
            return gui
        end
    end

    local ok, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok and typeof(coreGui) == "Instance" then
        return coreGui
    end

    return PlayerGui
end

local GuiParent = resolveHost()

local function getRequest()
    local requestFn = rawget(executorEnv, "request") or rawget(executorEnv, "http_request")
    if type(requestFn) == "function" then
        return requestFn
    end
    local httpTable = rawget(executorEnv, "http")
    if type(httpTable) == "table" and type(httpTable.request) == "function" then
        return httpTable.request
    end
    return nil
end

local function httpGet(url)
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(result) == "string" then
        return result
    end

    local req = getRequest()
    if req then
        local requestOk, response = pcall(function()
            return req({
                Url = url,
                Method = "GET",
            })
        end)
        if requestOk and type(response) == "table" and type(response.Body) == "string" then
            return response.Body
        end
    end
    return nil
end

local function setClipboard(value)
    local clipboard = rawget(executorEnv, "setclipboard") or rawget(executorEnv, "toclipboard")
    if type(clipboard) == "function" then
        pcall(clipboard, tostring(value))
    end
end

local function getExecutorEnvironment()
    local identify = rawget(executorEnv, "identifyexecutor") or rawget(executorEnv, "getexecutorname")
    if type(identify) == "function" then
        local ok, name = pcall(identify)
        if ok then return tostring(name) end
    end
    return "Unknown"
end

local function optionalGlobal(name)
    local value = rawget(executorEnv, name)
    if type(value) == "function" then
        return value
    end
    return nil
end

local function createRawSourceStore()
    local existing = rawget(_G, "NARS_RAW_SOURCES")
    if type(existing) ~= "table" then
        existing = rawget(_G, "NARS_RBX_RAW_SOURCES")
    end
    if type(existing) ~= "table" then
        existing = {}
    end
    rawset(_G, "NARS_RAW_SOURCES", existing)
    rawset(_G, "NARS_RBX_RAW_SOURCES", existing)
    return existing
end

local Executor = {
    request = getRequest(),
    httpget = httpGet,
    setclipboard = setClipboard,

    listfiles = optionalGlobal("listfiles"),
    makefolder = optionalGlobal("makefolder"),
    isfolder = optionalGlobal("isfolder"),
    isfile = optionalGlobal("isfile"),
    readfile = optionalGlobal("readfile"),
    writefile = optionalGlobal("writefile"),
    getcustomasset = optionalGlobal("getcustomasset"),

    -- sUNC Encoding library (preferred) + fallbacks
    base64encode = optionalGlobal("base64encode") or (rawget(executorEnv, "crypt") and rawget(executorEnv, "crypt").base64encode),
    base64decode = optionalGlobal("base64decode") or (rawget(executorEnv, "crypt") and rawget(executorEnv, "crypt").base64decode),
    lz4compress = optionalGlobal("lz4compress") or (rawget(executorEnv, "crypt") and rawget(executorEnv, "crypt").lz4compress),
    lz4decompress = optionalGlobal("lz4decompress") or (rawget(executorEnv, "crypt") and rawget(executorEnv, "crypt").lz4decompress),
    zstdcompress = optionalGlobal("zstdcompress"),
    zstddecompress = optionalGlobal("zstddecompress"),

    getfunctionbytecode = optionalGlobal("getfunctionbytecode"),
    dumpbytecode = optionalGlobal("dumpbytecode"),
    decompile = optionalGlobal("decompile"),
    getscriptbytecode = optionalGlobal("getscriptbytecode"),
}

local Services = {
    Players = Players,
    LocalPlayer = LocalPlayer,
    PlayerGui = PlayerGui,
    ReplicatedStorage = ReplicatedStorage,
    RunService = RunService,
    TweenService = TweenService,
    UserInputService = UserInputService,
    InsertService = InsertService,
    HttpService = HttpService,
    ReplicatedFirst = ReplicatedFirst,
    StarterGui = StarterGui,
    StarterPack = StarterPack,
    StarterPlayer = StarterPlayer,
    Workspace = workspace,
}

local StudioLiteFolder = ReplicatedStorage:FindFirstChild("StudioLiteFolder")
local StudioLiteServerFunctions = StudioLiteFolder
    and StudioLiteFolder:FindFirstChild("ServerFunctions")
    or nil

local Environment = {
    Services = Services,
    Executor = Executor,
    LocalPlayer = LocalPlayer,
    PlayerGui = PlayerGui,
    GuiParent = GuiParent,
    TweenService = TweenService,
    RunService = RunService,
    ReplicatedStorage = ReplicatedStorage,
    StudioLiteFolder = StudioLiteFolder,
    StudioLiteServerFunctions = StudioLiteServerFunctions,
    Icon = Icon,          -- numeric ids
    Icons = Icons,        -- rbxassetid:// strings
    RawSources = createRawSourceStore(),
    ExecutorInfo = getExecutorEnvironment(),
    HttpGet = httpGet,
    Request = getRequest(),
    SetClipboard = setClipboard,
}

-- Public bridge
_G.NARS_RBX_ENV = Environment
_G.NARS_RAW_SOURCES = Environment.RawSources
_G.NARS_RBX_RAW_SOURCES = Environment.RawSources

-- Legacy short names kept for Parser compatibility
_G.aa = InsertService
_G.ab = Executor
_G.ae = TweenService
_G.af = GuiParent
_G.ag = Icons
_G.ah = Executor.request
_G.al = LocalPlayer
_G.am = Executor
_G.at = RunService
_G.aw = StudioLiteServerFunctions

return Environment
