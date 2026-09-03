

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- // State
local senterEnabled    = false
local senterBrightness = 5
local senterRange      = 40
local senterColor      = Color3.fromRGB(255, 255, 255)
local senterLight      = nil
local effectConn       = nil
local senterMode       = "Normal" 

-- // Palette GUI
local BG     = Color3.fromRGB(25, 25, 35)
local BGCARD = Color3.fromRGB(32, 32, 48)
local BGITEM = Color3.fromRGB(40, 40, 58)
local ACCENT = Color3.fromRGB(70, 130, 255)
local ACCENT2= Color3.fromRGB(100, 180, 255)
local WHITE  = Color3.fromRGB(220, 225, 255)
local SUBTEXT= Color3.fromRGB(120, 125, 160)
local DANGER = Color3.fromRGB(255, 70, 80)
local TOGON  = Color3.fromRGB(60, 200, 120)
local TOGOFF = Color3.fromRGB(70, 70, 95)


local function stopEffect()
    if effectConn then effectConn:Disconnect(); effectConn = nil end
    if senterLight then
        senterLight.Brightness = senterBrightness
        senterLight.Color      = senterColor
    end
end

local function removeLight()
    stopEffect()
    if senterLight then senterLight:Destroy(); senterLight = nil end
end

local function attachLight()
    removeLight()
    Character = LocalPlayer.Character
    if not Character then return end
    local part = Character:FindFirstChild("Head")
    if not part then return end

    local light      = Instance.new("SpotLight")
    light.Brightness = senterBrightness
    light.Color      = senterColor
    light.Range      = senterRange
    light.Angle      = 70
    light.Face       = Enum.NormalId.Front
    light.Parent     = part
    senterLight      = light
end

-- Start effect loop based on senterMode
local function startEffect()
    stopEffect()
    if not senterLight then return end

    if senterMode == "Normal" then
        senterLight.Color      = senterColor
        senterLight.Brightness = senterBrightness

    elseif senterMode == "Strobo" then
        local tick = false
        local timer = 0
        local STROBO_INTERVAL = 0.15 -- detik antar kedip (lebih besar = lebih lambat)
        effectConn = RunService.Heartbeat:Connect(function(dt)
            if not senterLight then return end
            timer = timer + dt
            if timer >= STROBO_INTERVAL then
                timer = 0
                tick = not tick
                senterLight.Brightness = tick and senterBrightness or 0
            end
        end)

    elseif senterMode == "RGB" then
        local t = 0
        effectConn = RunService.Heartbeat:Connect(function(dt)
            if not senterLight then return end
            t = (t + dt * 0.8) % 1
            senterLight.Color = Color3.fromHSV(t, 1, 1)
        end)

    elseif senterMode == "Belang" then
        -- Cycle melalui beberapa warna dengan tween smooth
        local colors = {
            Color3.fromRGB(255, 80, 80),
            Color3.fromRGB(255, 180, 0),
            Color3.fromRGB(80, 255, 120),
            Color3.fromRGB(80, 180, 255),
            Color3.fromRGB(200, 80, 255),
            Color3.fromRGB(255, 80, 180),
        }
        local idx = 1
        local timer = 0
        local INTERVAL = 0.35
        effectConn = RunService.Heartbeat:Connect(function(dt)
            if not senterLight then return end
            timer = timer + dt
            if timer >= INTERVAL then
                timer = 0
                idx = (idx % #colors) + 1
                TweenService:Create(senterLight, TweenInfo.new(INTERVAL * 0.7, Enum.EasingStyle.Sine), {
                    Color = colors[idx]
                }):Play()
            end
        end)
    end
end

local function applyMode()
    if senterEnabled and senterLight then
        startEffect()
    end
end

-- ==================== HELPERS ====================

local function corner(r, p)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p
end

local function mkStroke(col, thick, p)
    local s = Instance.new("UIStroke")
    s.Color = col; s.Thickness = thick
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p; return s
end

-- ==================== ROOT ====================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SIEXTHER_Senter"; ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; ScreenGui.Parent = PlayerGui

local GUI_W, GUI_H = 230, 310

local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Size = UDim2.new(0, GUI_W, 0, GUI_H)
MainFrame.Position = UDim2.new(0.5, -GUI_W/2, 0.5, -GUI_H/2)
MainFrame.BackgroundColor3 = BG; MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true; MainFrame.Parent = ScreenGui
corner(12, MainFrame); mkStroke(ACCENT, 1.5, MainFrame)

local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0,41,0,41); FloatBtn.Position = UDim2.new(0,20,0.5,-22)
FloatBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35) FloatBtn.Text = "🔦"; FloatBtn.TextSize = 20
FloatBtn.Font = Enum.Font.GothamBold; FloatBtn.TextColor3 = WHITE
FloatBtn.Visible = false; FloatBtn.ZIndex = 10; FloatBtn.Parent = ScreenGui
corner(12, FloatBtn);


-- ==================== TITLEBAR ====================

local TITLE_H = 36

local Titlebar = Instance.new("Frame")
Titlebar.Size = UDim2.new(1,0,0,TITLE_H); Titlebar.BackgroundColor3 = BGCARD
Titlebar.BorderSizePixel = 0; Titlebar.ZIndex = 3; Titlebar.Parent = MainFrame
corner(12, Titlebar)

local TBPatch = Instance.new("Frame")
TBPatch.Size = UDim2.new(1,0,0,12); TBPatch.Position = UDim2.new(0,0,1,-12)
TBPatch.BackgroundColor3 = BGCARD; TBPatch.BorderSizePixel = 0; TBPatch.Parent = Titlebar



local TitleLbl = Instance.new("TextLabel")
TitleLbl.Text = "SIEXTHER FLASHLIGHT"; TitleLbl.TextSize = 12
TitleLbl.Size = UDim2.new(1,-90,1,0); TitleLbl.Position = UDim2.new(0,8,0,0)
TitleLbl.BackgroundTransparency = 1; TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextColor3 = WHITE; TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Parent = Titlebar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0,22,0,18); MinBtn.Position = UDim2.new(1,-50,0.5,-9)
MinBtn.BackgroundColor3 = BGITEM; MinBtn.Text = "–"; MinBtn.TextSize = 10
MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextColor3 = SUBTEXT; MinBtn.Parent = Titlebar
corner(5, MinBtn)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0,22,0,18); CloseBtn.Position = UDim2.new(1,-24,0.5,-9)
CloseBtn.BackgroundColor3 = DANGER; CloseBtn.Text = "X"; CloseBtn.TextSize = 10
CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextColor3 = Color3.new(1,1,1); CloseBtn.Parent = Titlebar
corner(5, CloseBtn)

-- ==================== SCROLL ====================

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1,0,1,-TITLE_H)
ScrollFrame.Position = UDim2.new(0,0,0,TITLE_H)
ScrollFrame.BackgroundTransparency = 1; ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 3; ScrollFrame.ScrollBarImageColor3 = ACCENT
ScrollFrame.CanvasSize = UDim2.new(0,0,0,0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
ScrollFrame.ClipsDescendants = true; ScrollFrame.Parent = MainFrame

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,0,0,0); Content.AutomaticSize = Enum.AutomaticSize.Y
Content.BackgroundTransparency = 1; Content.Parent = ScrollFrame

local UIPad = Instance.new("UIPadding")
UIPad.PaddingLeft = UDim.new(0,10); UIPad.PaddingRight  = UDim.new(0,10)
UIPad.PaddingTop  = UDim.new(0,8);  UIPad.PaddingBottom = UDim.new(0,8)
UIPad.Parent = Content

local UIList = Instance.new("UIListLayout")
UIList.SortOrder = Enum.SortOrder.LayoutOrder; UIList.Padding = UDim.new(0,7)
UIList.Parent = Content

-- ==================== HELPERS SECTION ====================

local function makeSection(title, h, order)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,h); f.BackgroundColor3 = BGCARD
    f.LayoutOrder = order; f.Parent = Content; corner(8, f)
    local lbl = Instance.new("TextLabel")
    lbl.Text = title; lbl.TextSize = 9; lbl.Font = Enum.Font.GothamSemibold
    lbl.TextColor3 = SUBTEXT; lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1,-16,0,16); lbl.Position = UDim2.new(0,8,0,4)
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    return f
end

-- ==================== SLIDER SYSTEM ====================

local activeSlider = nil

UserInputService.InputChanged:Connect(function(inp)
    if activeSlider and (inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch) then
        activeSlider(inp.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        activeSlider = nil
    end
end)

local function buildSlider(parent, yPos, initRel, fillColor, onChanged)
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1,-16,0,7); track.Position = UDim2.new(0,8,0,yPos)
    track.BackgroundColor3 = BGITEM; track.BorderSizePixel = 0; track.Parent = parent
    corner(4, track)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(initRel,0,1,0); fill.BackgroundColor3 = fillColor
    fill.BorderSizePixel = 0; fill.Parent = track; corner(4, fill)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0,16,0,16); thumb.AnchorPoint = Vector2.new(0.5,0.5)
    thumb.Position = UDim2.new(initRel,0,0.5,0)
    thumb.BackgroundColor3 = WHITE; thumb.BorderSizePixel = 0; thumb.Parent = track
    corner(8, thumb); mkStroke(fillColor, 2, thumb)

    local function doSlide(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(rel,0,1,0); thumb.Position = UDim2.new(rel,0,0.5,0)
        onChanged(rel)
    end

    local function startSlide(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            activeSlider = doSlide; doSlide(inp.Position.X)
        end
    end

    track.InputBegan:Connect(startSlide)
    thumb.InputBegan:Connect(startSlide)
end

-- ==================== SECTION 1: TOGGLE ====================

local ToggleRow = Instance.new("Frame")
ToggleRow.Size = UDim2.new(1,0,0,34); ToggleRow.BackgroundColor3 = BGCARD
ToggleRow.LayoutOrder = 1; ToggleRow.Parent = Content
corner(8, ToggleRow)

local ToggleLbl = Instance.new("TextLabel")
ToggleLbl.Text = "AKTIFKAN SENTER"; ToggleLbl.TextSize = 11
ToggleLbl.Font = Enum.Font.GothamSemibold; ToggleLbl.TextColor3 = WHITE
ToggleLbl.BackgroundTransparency = 1
ToggleLbl.Size = UDim2.new(1,-68,1,0); ToggleLbl.Position = UDim2.new(0,10,0,0)
ToggleLbl.TextXAlignment = Enum.TextXAlignment.Left; ToggleLbl.Parent = ToggleRow

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0,48,0,22); ToggleBtn.Position = UDim2.new(1,-56,0.5,-11)
ToggleBtn.BackgroundColor3 = TOGOFF; ToggleBtn.Text = "OFF"; ToggleBtn.TextSize = 10
ToggleBtn.Font = Enum.Font.GothamBold; ToggleBtn.TextColor3 = WHITE; ToggleBtn.Parent = ToggleRow
corner(11, ToggleBtn)

-- ==================== SECTION 2: MODE EFEK ====================

-- 4 tombol 2x2 grid
local ModeSection = makeSection("MODE EFEK", 92, 2)

local modeList = {
    { id = "Normal", label = "NORMAL",  desc = "Cahaya diam" },
    { id = "Strobo", label = "STROBO",  desc = "Kedip-kedip" },
    { id = "RGB",    label = "RGB",     desc = "Warna berputar" },
    { id = "Belang", label = "BELANG",  desc = "Warna berganti" },
}

local modeBtns = {}
local BTN_W = 0.5
local BTN_H = 26
local BTN_PAD = 6  -- padding kiri
local BTN_GAP = 5  -- gap antar baris/kolom
local BTN_START_Y = 22

for i, m in ipairs(modeList) do
    local col = ((i-1) % 2)       -- 0 atau 1
    local row = math.floor((i-1) / 2) -- 0 atau 1

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.5, -(BTN_PAD + BTN_GAP/2), 0, BTN_H)
    btn.Position = UDim2.new(col * 0.5, col == 0 and BTN_PAD or BTN_GAP/2, 0,
        BTN_START_Y + row * (BTN_H + BTN_GAP))
    btn.BackgroundColor3 = m.id == senterMode and ACCENT or BGITEM
    btn.Text = m.label; btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = m.id == senterMode and WHITE or SUBTEXT
    btn.Parent = ModeSection
    corner(6, btn)
    modeBtns[m.id] = btn

    btn.MouseButton1Click:Connect(function()
        senterMode = m.id
        -- reset semua tombol
        for _, mb in pairs(modeBtns) do
            mb.BackgroundColor3 = BGITEM; mb.TextColor3 = SUBTEXT
        end
        btn.BackgroundColor3 = ACCENT; btn.TextColor3 = WHITE
        applyMode()
    end)
end

-- ==================== SECTION 3: WARNA ====================

local ColorSection = makeSection("WARNA CAHAYA", 64, 3)

local colorPresets = {
    { Color3.fromRGB(255,255,255), "Putih"  },
    { Color3.fromRGB(255,220,120), "Hangat" },
    { Color3.fromRGB(120,200,255), "Biru"   },
    { Color3.fromRGB(120,255,160), "Hijau"  },
    { Color3.fromRGB(255,100,100), "Merah"  },
    { Color3.fromRGB(200,120,255), "Ungu"   },
}

local SW, SW_GAP = 26, 5
-- inner width = 230 - 10*2 pad = 210
local startX = math.floor((210 - (#colorPresets * SW + (#colorPresets-1) * SW_GAP)) / 2)
local selectedDot = nil

for i, preset in ipairs(colorPresets) do
    local col = preset[1]
    local sw  = Instance.new("TextButton")
    sw.Size             = UDim2.new(0, SW, 0, SW)
    sw.Position         = UDim2.new(0, startX + (i-1)*(SW+SW_GAP), 0, 22)
    sw.BackgroundColor3 = col
    sw.Text = ""; sw.BorderSizePixel = 0; sw.Parent = ColorSection
    corner(6, sw)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0,5,0,5); dot.AnchorPoint = Vector2.new(0.5, 0)
    dot.Position = UDim2.new(0.5,0,1,3); dot.BackgroundColor3 = WHITE
    dot.BorderSizePixel = 0; dot.ZIndex = 2; dot.Visible = (i == 1)
    dot.Parent = sw; corner(3, dot)

    if i == 1 then selectedDot = dot end

    sw.MouseButton1Click:Connect(function()
        senterColor = col
        if selectedDot then selectedDot.Visible = false end
        dot.Visible = true; selectedDot = dot
        -- hanya update warna kalau mode Normal (mode lain handle warna sendiri)
        if senterLight and senterMode == "Normal" then
            senterLight.Color = senterColor
        end
    end)
end

-- ==================== SECTION 4: KECERAHAN ====================

local BrightSection = makeSection("KECERAHAN", 56, 4)

local BrightValLbl = Instance.new("TextLabel")
BrightValLbl.Text = tostring(senterBrightness); BrightValLbl.TextSize = 11
BrightValLbl.Font = Enum.Font.GothamBold; BrightValLbl.TextColor3 = ACCENT
BrightValLbl.BackgroundTransparency = 1
BrightValLbl.Size = UDim2.new(0,28,0,16); BrightValLbl.Position = UDim2.new(1,-34,0,4)
BrightValLbl.TextXAlignment = Enum.TextXAlignment.Right; BrightValLbl.Parent = BrightSection

buildSlider(BrightSection, 26, senterBrightness / 10, ACCENT, function(rel)
    senterBrightness = math.max(1, math.floor(rel * 10 + 0.5))
    BrightValLbl.Text = tostring(senterBrightness)
    if senterLight and senterMode == "Normal" then
        senterLight.Brightness = senterBrightness
    end
end)

-- ==================== SECTION 5: JANGKAUAN ====================

local RANGE_MIN, RANGE_MAX = 0, 100

local RangeSection = makeSection("JANGKAUAN", 56, 5)

local RangeValLbl = Instance.new("TextLabel")
RangeValLbl.Text = tostring(senterRange); RangeValLbl.TextSize = 11
RangeValLbl.Font = Enum.Font.GothamBold; RangeValLbl.TextColor3 = ACCENT2
RangeValLbl.BackgroundTransparency = 1
RangeValLbl.Size = UDim2.new(0,28,0,16); RangeValLbl.Position = UDim2.new(1,-34,0,4)
RangeValLbl.TextXAlignment = Enum.TextXAlignment.Right; RangeValLbl.Parent = RangeSection

buildSlider(RangeSection, 26, (senterRange - RANGE_MIN) / (RANGE_MAX - RANGE_MIN), ACCENT2, function(rel)
    senterRange = math.floor(RANGE_MIN + rel * (RANGE_MAX - RANGE_MIN) + 0.5)
    RangeValLbl.Text = tostring(senterRange)
    if senterLight then senterLight.Range = senterRange end
end)

-- ==================== BUTTON LOGIC ====================

ToggleBtn.MouseButton1Click:Connect(function()
    senterEnabled = not senterEnabled
    if senterEnabled then
        ToggleBtn.BackgroundColor3 = TOGON;  ToggleBtn.Text = "ON"
        attachLight(); startEffect()
    else
        ToggleBtn.BackgroundColor3 = TOGOFF; ToggleBtn.Text = "OFF"
        removeLight()
    end
end)

MinBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame, TweenInfo.new(0.18), {Size = UDim2.new(0,GUI_W,0,0)}):Play()
    task.wait(0.19); MainFrame.Visible = false; FloatBtn.Visible = true
end)

FloatBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true; MainFrame.Size = UDim2.new(0,GUI_W,0,0)
    TweenService:Create(MainFrame, TweenInfo.new(0.18), {Size = UDim2.new(0,GUI_W,0,GUI_H)}):Play()
    FloatBtn.Visible = false
end)

CloseBtn.MouseButton1Click:Connect(function()
    removeLight(); ScreenGui:Destroy()
end)

-- ==================== DRAG ====================

local function makeDraggable(frame, handle)
    local drag, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = i.Position; sp = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

local function makeFloatDraggable(btn)
    local drag, ds, sp = false, nil, nil
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = i.Position; sp = btn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            btn.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

makeDraggable(MainFrame, Titlebar)
makeFloatDraggable(FloatBtn)

-- Respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char; task.wait(1)
    if senterEnabled then attachLight(); startEffect() end
end)

