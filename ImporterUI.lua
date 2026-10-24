-- NARS RBX IMPORTER
-- ImporterUI – Monochrome UI matching provided design
-- Panel size: UDim2.new(0, 270, 0, 340)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local function getEnv()
    return rawget(_G, "NARS_RBX_ENV") or {}
end

local function getIcons()
    local env = getEnv()
    return env.Icons or {}
end

local function getIcon(name)
    local icons = getIcons()
    return icons[name] or ""
end

-- ============================================================
-- Theme (Monochrome dark)
-- ============================================================
local Theme = {
    Bg          = Color3.fromRGB(18, 18, 20),
    Surface     = Color3.fromRGB(28, 28, 32),
    Surface2    = Color3.fromRGB(36, 36, 42),
    Border      = Color3.fromRGB(48, 48, 56),
    Text        = Color3.fromRGB(235, 235, 240),
    TextDim     = Color3.fromRGB(140, 140, 150),
    Accent      = Color3.fromRGB(255, 255, 255),
    Success     = Color3.fromRGB(80, 200, 120),
    Danger      = Color3.fromRGB(220, 80, 80),
    Button      = Color3.fromRGB(42, 42, 50),
    ButtonHover = Color3.fromRGB(55, 55, 65),
}

local uiState = {
    Screen = nil,
    Main = nil,
    Scroll = nil,
    Selected = {},
    Assets = {},
    Scanning = false,
    Importing = false,
    Connections = {},
    Minimized = false,
}

-- ============================================================
-- Utility
-- ============================================================
local function connect(signal, callback)
    if not signal then return nil end
    local ok, connection = pcall(function()
        return signal:Connect(callback)
    end)
    if ok and connection then
        table.insert(uiState.Connections, connection)
        return connection
    end
    return nil
end

local function tween(obj, props, duration, style, dir)
    duration = duration or 0.18
    style = style or Enum.EasingStyle.Quint
    dir = dir or Enum.EasingDirection.Out
    local t = TweenService:Create(obj, TweenInfo.new(duration, style, dir), props)
    t:Play()
    return t
end

local function create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = inst
        end
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function padding(parent, t, r, b, l)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft = UDim.new(0, l or 0)
    p.Parent = parent
    return p
end

local function formatSize(bytes)
    if not bytes or bytes <= 0 then return "--" end
    if bytes < 1024 then return string.format("%d B", bytes) end
    if bytes < 1024 * 1024 then return string.format("%.1f KB", bytes / 1024) end
    return string.format("%.1f MB", bytes / (1024 * 1024))
end

-- ============================================================
-- Notification
-- ============================================================
local function notify(title, message, isError)
    local env = getEnv()
    local parent = env.GuiParent or game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if not parent then return end

    local existing = parent:FindFirstChild("NARS_Notify")
    if existing then existing:Destroy() end

    local frame = create("Frame", {
        Name = "NARS_Notify",
        Size = UDim2.fromOffset(240, 52),
        Position = UDim2.new(0.5, -120, 0, -60),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = parent,
        ZIndex = 100,
    })
    corner(frame, 8)
    stroke(frame, isError and Theme.Danger or Theme.Border, 1)

    create("TextLabel", {
        Size = UDim2.new(1, -16, 0, 18),
        Position = UDim2.fromOffset(8, 6),
        BackgroundTransparency = 1,
        Text = title or "Info",
        TextColor3 = isError and Theme.Danger or Theme.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
        ZIndex = 101,
    })

    create("TextLabel", {
        Size = UDim2.new(1, -16, 0, 20),
        Position = UDim2.fromOffset(8, 26),
        BackgroundTransparency = 1,
        Text = message or "",
        TextColor3 = Theme.TextDim,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = frame,
        ZIndex = 101,
    })

    tween(frame, {Position = UDim2.new(0.5, -120, 0, 16)}, 0.25)
    task.delay(2.4, function()
        if frame and frame.Parent then
            tween(frame, {Position = UDim2.new(0.5, -120, 0, -70)}, 0.2)
            task.wait(0.22)
            frame:Destroy()
        end
    end)
end

-- ============================================================
-- Build UI
-- ============================================================
local function buildUI()
    local env = getEnv()
    local parent = env.GuiParent or game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")

    -- Destroy previous
    local old = parent:FindFirstChild("NARS_RBX_ImporterUI")
    if old then old:Destroy() end

    local screen = create("ScreenGui", {
        Name = "NARS_RBX_ImporterUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        Parent = parent,
    })
    uiState.Screen = screen

    -- Main Panel 270 x 340
    local main = create("Frame", {
        Name = "Main",
        Size = UDim2.fromOffset(270, 340),
        Position = UDim2.new(0.5, -135, 0.5, -170),
        BackgroundColor3 = Theme.Bg,
        BorderSizePixel = 0,
        Parent = screen,
        ClipsDescendants = true,
    })
    uiState.Main = main
    corner(main, 10)
    stroke(main, Theme.Border, 1)

    -- ========== HEADER ==========
    local header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = main,
    })

    -- Logo
    local logo = create("ImageLabel", {
        Name = "Logo",
        Size = UDim2.fromOffset(22, 22),
        Position = UDim2.fromOffset(12, 10),
        BackgroundTransparency = 1,
        Image = getIcon("Logo"),
        Parent = header,
    })

    local title = create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -90, 0, 16),
        Position = UDim2.fromOffset(40, 7),
        BackgroundTransparency = 1,
        Text = "NARS RBX IMPORTER",
        TextColor3 = Theme.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })

    local subtitle = create("TextLabel", {
        Name = "Subtitle",
        Size = UDim2.new(1, -90, 0, 12),
        Position = UDim2.fromOffset(40, 23),
        BackgroundTransparency = 1,
        Text = "RBXM · RBXL · RBXLX",
        TextColor3 = Theme.TextDim,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })

    -- Window controls
    local btnClose = create("ImageButton", {
        Name = "Close",
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.new(1, -28, 0, 12),
        BackgroundTransparency = 1,
        Image = getIcon("Close"),
        ImageColor3 = Theme.TextDim,
        Parent = header,
    })
    connect(btnClose.MouseButton1Click, function()
        tween(main, {Size = UDim2.fromOffset(270, 0)}, 0.2)
        task.wait(0.22)
        screen:Destroy()
    end)
    connect(btnClose.MouseEnter, function() btnClose.ImageColor3 = Theme.Danger end)
    connect(btnClose.MouseLeave, function() btnClose.ImageColor3 = Theme.TextDim end)

    local btnMin = create("ImageButton", {
        Name = "Minimize",
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.new(1, -50, 0, 12),
        BackgroundTransparency = 1,
        Image = getIcon("Minimal"),
        ImageColor3 = Theme.TextDim,
        Parent = header,
    })
    connect(btnMin.MouseButton1Click, function()
        uiState.Minimized = not uiState.Minimized
        if uiState.Minimized then
            tween(main, {Size = UDim2.fromOffset(270, 42)}, 0.22)
        else
            tween(main, {Size = UDim2.fromOffset(270, 340)}, 0.22)
        end
    end)

    -- ========== STATS BAR ==========
    local stats = create("Frame", {
        Name = "Stats",
        Size = UDim2.new(1, -20, 0, 48),
        Position = UDim2.fromOffset(10, 50),
        BackgroundTransparency = 1,
        Parent = main,
    })

    local function makeStat(name, value, iconId, x)
        local box = create("Frame", {
            Name = name,
            Size = UDim2.fromOffset(78, 44),
            Position = UDim2.fromOffset(x, 0),
            BackgroundColor3 = Theme.Surface,
            BorderSizePixel = 0,
            Parent = stats,
        })
        corner(box, 6)

        create("ImageLabel", {
            Size = UDim2.fromOffset(12, 12),
            Position = UDim2.fromOffset(8, 8),
            BackgroundTransparency = 1,
            Image = iconId,
            ImageColor3 = Theme.TextDim,
            Parent = box,
        })

        local val = create("TextLabel", {
            Name = "Value",
            Size = UDim2.new(1, -10, 0, 16),
            Position = UDim2.fromOffset(8, 22),
            BackgroundTransparency = 1,
            Text = value,
            TextColor3 = Theme.Text,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = box,
        })
        return val
    end

    local statFiles = makeStat("Files", "00", getIcon("List"), 0)
    local statSelected = makeStat("Selected", "00", getIcon("Checklis"), 86)
    local statSize = makeStat("Size", "--", getIcon("FileCode"), 172)

    uiState.StatFiles = statFiles
    uiState.StatSelected = statSelected
    uiState.StatSize = statSize

    -- ========== SECTION: Asset Files ==========
    local sectionLabel = create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 16),
        Position = UDim2.fromOffset(12, 106),
        BackgroundTransparency = 1,
        Text = "Asset Files",
        TextColor3 = Theme.TextDim,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = main,
    })

    local clearBtn = create("TextButton", {
        Name = "Clear",
        Size = UDim2.fromOffset(70, 16),
        Position = UDim2.new(1, -80, 0, 106),
        BackgroundTransparency = 1,
        Text = "Clear selection",
        TextColor3 = Theme.TextDim,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        Parent = main,
    })

    -- Scroll list
    local listFrame = create("Frame", {
        Name = "ListFrame",
        Size = UDim2.new(1, -20, 0, 140),
        Position = UDim2.fromOffset(10, 124),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = main,
        ClipsDescendants = true,
    })
    corner(listFrame, 6)

    local scroll = create("ScrollingFrame", {
        Name = "Scroll",
        Size = UDim2.new(1, -4, 1, -4),
        Position = UDim2.fromOffset(2, 2),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Border,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = listFrame,
    })
    uiState.Scroll = scroll

    local listLayout = create("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = scroll,
    })
    padding(scroll, 4, 4, 4, 4)

    -- ========== BOTTOM BUTTONS ==========
    local btnRow = create("Frame", {
        Name = "BtnRow",
        Size = UDim2.new(1, -20, 0, 32),
        Position = UDim2.fromOffset(10, 274),
        BackgroundTransparency = 1,
        Parent = main,
    })

    local btnScan = create("TextButton", {
        Name = "Scan",
        Size = UDim2.new(0.48, -3, 1, 0),
        BackgroundColor3 = Theme.Button,
        BorderSizePixel = 0,
        Text = "  Scan Assets",
        TextColor3 = Theme.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        Parent = btnRow,
    })
    corner(btnScan, 6)

    local scanIcon = create("ImageLabel", {
        Size = UDim2.fromOffset(13, 13),
        Position = UDim2.fromOffset(10, 9),
        BackgroundTransparency = 1,
        Image = getIcon("Refresh"),
        ImageColor3 = Theme.Text,
        Parent = btnScan,
    })

    local btnImport = create("TextButton", {
        Name = "Import",
        Size = UDim2.new(0.48, -3, 1, 0),
        Position = UDim2.new(0.52, 3, 0, 0),
        BackgroundColor3 = Theme.Button,
        BorderSizePixel = 0,
        Text = "  Import (0)",
        TextColor3 = Theme.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        Parent = btnRow,
    })
    corner(btnImport, 6)

    local importIcon = create("ImageLabel", {
        Size = UDim2.fromOffset(13, 13),
        Position = UDim2.fromOffset(10, 9),
        BackgroundTransparency = 1,
        Image = getIcon("Import"),
        ImageColor3 = Theme.Text,
        Parent = btnImport,
    })

    uiState.BtnScan = btnScan
    uiState.BtnImport = btnImport

    -- Footer
    create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 14),
        Position = UDim2.fromOffset(10, 318),
        BackgroundTransparency = 1,
        Text = "NARS RBX IMPORTER  ·  Monochrome UI",
        TextColor3 = Theme.TextDim,
        TextSize = 8,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = main,
    })

    -- ========== Drag ==========
    local dragging, dragStart, startPos
    connect(header.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- ========== Card Template Factory ==========
    local function createCard(asset, index)
        local selected = uiState.Selected[asset.path] == true

        local card = create("Frame", {
            Name = "Card_" .. index,
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = selected and Theme.Surface2 or Theme.Bg,
            BorderSizePixel = 0,
            LayoutOrder = index,
            Parent = scroll,
        })
        corner(card, 5)
        if selected then
            stroke(card, Theme.Accent, 1)
        end

        -- Checkbox
        local check = create("Frame", {
            Size = UDim2.fromOffset(14, 14),
            Position = UDim2.fromOffset(8, 8),
            BackgroundColor3 = selected and Theme.Accent or Theme.Surface2,
            BorderSizePixel = 0,
            Parent = card,
        })
        corner(check, 3)
        stroke(check, Theme.Border, 1)

        if selected then
            create("ImageLabel", {
                Size = UDim2.fromOffset(10, 10),
                Position = UDim2.fromOffset(2, 2),
                BackgroundTransparency = 1,
                Image = getIcon("Checklis"),
                ImageColor3 = Theme.Bg,
                Parent = check,
            })
        end

        -- Icon
        create("ImageLabel", {
            Size = UDim2.fromOffset(14, 14),
            Position = UDim2.fromOffset(28, 8),
            BackgroundTransparency = 1,
            Image = getIcon("FileCode"),
            ImageColor3 = Theme.TextDim,
            Parent = card,
        })

        -- Name
        create("TextLabel", {
            Size = UDim2.new(1, -110, 0, 14),
            Position = UDim2.fromOffset(48, 3),
            BackgroundTransparency = 1,
            Text = asset.name or "Unknown",
            TextColor3 = Theme.Text,
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = card,
        })

        -- Meta
        local meta = string.format("%s · %s", formatSize(asset.size), (asset.ext or ""):upper():gsub("%.", ""))
        create("TextLabel", {
            Size = UDim2.new(1, -110, 0, 12),
            Position = UDim2.fromOffset(48, 16),
            BackgroundTransparency = 1,
            Text = meta,
            TextColor3 = Theme.TextDim,
            TextSize = 9,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = card,
        })

        -- Click to toggle select
        local btn = create("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            Parent = card,
        })
        connect(btn.MouseButton1Click, function()
            if uiState.Selected[asset.path] then
                uiState.Selected[asset.path] = nil
            else
                uiState.Selected[asset.path] = true
            end
            refreshList()
            updateStats()
        end)

        return card
    end

    function refreshList()
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        for i, asset in ipairs(uiState.Assets) do
            createCard(asset, i)
        end
    end

    function updateStats()
        local total = #uiState.Assets
        local selectedCount = 0
        local totalSize = 0
        for path, _ in pairs(uiState.Selected) do
            selectedCount += 1
            for _, a in ipairs(uiState.Assets) do
                if a.path == path then
                    totalSize += (a.size or 0)
                    break
                end
            end
        end

        uiState.StatFiles.Text = string.format("%02d", total)
        uiState.StatSelected.Text = string.format("%02d", selectedCount)
        uiState.StatSize.Text = formatSize(totalSize)
        uiState.BtnImport.Text = string.format("  Import (%d)", selectedCount)
    end

    -- Clear selection
    connect(clearBtn.MouseButton1Click, function()
        uiState.Selected = {}
        refreshList()
        updateStats()
    end)

    -- Scan
    connect(btnScan.MouseButton1Click, function()
        if uiState.Scanning then return end
        uiState.Scanning = true
        btnScan.Text = "  Scanning..."
        uiState.Assets = {}
        uiState.Selected = {}
        refreshList()
        updateStats()

        task.spawn(function()
            local scanFn = rawget(_G, "by") or (getEnv().scanAssets)
            local files = {}
            if type(scanFn) == "function" then
                local ok, result = pcall(scanFn)
                if ok and type(result) == "table" then
                    files = result
                end
            end

            uiState.Assets = files
            refreshList()
            updateStats()
            uiState.Scanning = false
            btnScan.Text = "  Scan Assets"
            notify("Scan Complete", string.format("Found %d asset files", #files), false)
        end)
    end)

    -- Import
    connect(btnImport.MouseButton1Click, function()
        if uiState.Importing then return end
        local toImport = {}
        for _, asset in ipairs(uiState.Assets) do
            if uiState.Selected[asset.path] then
                table.insert(toImport, asset)
            end
        end
        if #toImport == 0 then
            notify("Nothing Selected", "Select at least one file", true)
            return
        end

        uiState.Importing = true
        btnImport.Text = "  Importing..."

        task.spawn(function()
            local importFn = rawget(_G, "bx")
            local successCount = 0
            for _, asset in ipairs(toImport) do
                if type(importFn) == "function" then
                    local ok, success, msg = pcall(function()
                        return importFn(asset)
                    end)
                    if ok and success then
                        successCount += 1
                    end
                end
                task.wait(0.05)
            end

            uiState.Importing = false
            btnImport.Text = string.format("  Import (%d)", #toImport)
            notify("Import Finished", string.format("%d / %d assets imported", successCount, #toImport), successCount == 0)
        end)
    end)

    -- Hover effects
    local function setupHover(btn)
        connect(btn.MouseEnter, function()
            tween(btn, {BackgroundColor3 = Theme.ButtonHover}, 0.12)
        end)
        connect(btn.MouseLeave, function()
            tween(btn, {BackgroundColor3 = Theme.Button}, 0.12)
        end)
    end
    setupHover(btnScan)
    setupHover(btnImport)

    -- Entrance animation
    main.Size = UDim2.fromOffset(270, 0)
    tween(main, {Size = UDim2.fromOffset(270, 340)}, 0.28, Enum.EasingStyle.Back)

    return screen
end

-- ============================================================
-- Public entry
-- ============================================================
function initializeImporter()
    local env = getEnv()
    if not env or not env.GuiParent then
        warn("[NARS] Environment not ready")
    end
    buildUI()
    return uiState.Screen
end

return {
    initialize = initializeImporter,
    notify = notify,
}
