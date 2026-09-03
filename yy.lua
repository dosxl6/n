local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local Players          = game:GetService("Players")
local LP               = Players.LocalPlayer


local BG     = Color3.fromRGB(25, 25, 35)
local DARK   = Color3.fromRGB(18, 18, 28)
local ACCENT = Color3.fromRGB(70, 130, 255)
local BTN    = Color3.fromRGB(35, 35, 52)
local BTN_ON = Color3.fromRGB(26, 45, 85)
local TEXT   = Color3.fromRGB(210, 215, 255)
local MUTED  = Color3.fromRGB(110, 115, 165)

-- ── Lighting helpers ─────────────────────────
local origLight = {
    Ambient    = Lighting.Ambient,
    Brightness = Lighting.Brightness,
    ClockTime  = Lighting.ClockTime,
    FogColor   = Lighting.FogColor,
    FogEnd     = Lighting.FogEnd,
}

local function getEff(cls, name)
    local e = Lighting:FindFirstChild(name)
    if e then return e end
    e = Instance.new(cls)
    e.Name = name
    e.Parent = Lighting
    return e
end

local function remEff(list)
    for _, n in pairs(list) do
        local e = Lighting:FindFirstChild(n)
        if e then e:Destroy() end
    end
end

-- ── Shader definitions ───────────────────────
local SHADERS = {
    {
        name  = "RTX SHADER",
        color = Color3.fromRGB(100, 180, 255),
        on = function()
            local b = getEff("BloomEffect","SX_B1")
            b.Intensity = 1.5; b.Size = 24; b.Threshold = 0.85
            local c = getEff("ColorCorrectionEffect","SX_C1")
            c.Brightness = 0.05; c.Contrast = 0.2; c.Saturation = 0.3
            c.TintColor = Color3.fromRGB(240,248,255)
            local s = getEff("SunRaysEffect","SX_S1")
            s.Intensity = 0.25; s.Spread = 0.5
            Lighting.Ambient = Color3.fromRGB(80,90,120)
            Lighting.Brightness = 3
        end,
        off = function() remEff({"SX_B1","SX_C1","SX_S1"}) end,
    },
    {
        name  = "SHADER FULL MAX FPS",
        color = Color3.fromRGB(80, 255, 150),
        on = function()
            local c = getEff("ColorCorrectionEffect","SX_C2")
            c.Brightness = 0.08; c.Contrast = 0.15; c.Saturation = -0.1
            c.TintColor = Color3.fromRGB(255,255,255)
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.fromRGB(120,120,120)
        end,
        off = function() remEff({"SX_C2"}) end,
    },
    {
        name  = "REALISTIC SHADER",
        color = Color3.fromRGB(255, 200, 100),
        on = function()
            local b = getEff("BloomEffect","SX_B3")
            b.Intensity = 0.8; b.Size = 16; b.Threshold = 0.9
            local c = getEff("ColorCorrectionEffect","SX_C3")
            c.Brightness = 0.02; c.Contrast = 0.25; c.Saturation = 0.4
            c.TintColor = Color3.fromRGB(255,248,235)
            local s = getEff("SunRaysEffect","SX_S3")
            s.Intensity = 0.2; s.Spread = 0.4
            Lighting.Ambient = Color3.fromRGB(90,85,75)
            Lighting.Brightness = 2.5; Lighting.ClockTime = 14
        end,
        off = function() remEff({"SX_B3","SX_C3","SX_S3"}) end,
    },
    {
        name  = "ULTRA GRAPHICS SHADER",
        color = Color3.fromRGB(200, 100, 255),
        on = function()
            local b = getEff("BloomEffect","SX_B4")
            b.Intensity = 2.5; b.Size = 28; b.Threshold = 0.75
            local c = getEff("ColorCorrectionEffect","SX_C4")
            c.Brightness = 0.1; c.Contrast = 0.35; c.Saturation = 0.5
            c.TintColor = Color3.fromRGB(235,245,255)
            local s = getEff("SunRaysEffect","SX_S4")
            s.Intensity = 0.35; s.Spread = 0.7
            local d = getEff("DepthOfFieldEffect","SX_D4")
            d.FocusDistance = 50; d.InFocusRadius = 30
            d.NearIntensity = 0.05; d.FarIntensity = 0.3
            Lighting.Ambient = Color3.fromRGB(60,65,90); Lighting.Brightness = 3.5
        end,
        off = function() remEff({"SX_B4","SX_C4","SX_S4","SX_D4"}) end,
    },
    {
        name  = "CINEMATIC SHADER",
        color = Color3.fromRGB(255, 140, 100),
        on = function()
            local b = getEff("BloomEffect","SX_B5")
            b.Intensity = 1.2; b.Size = 20; b.Threshold = 0.88
            local c = getEff("ColorCorrectionEffect","SX_C5")
            c.Brightness = -0.05; c.Contrast = 0.4; c.Saturation = 0.2
            c.TintColor = Color3.fromRGB(255,235,210)
            local d = getEff("DepthOfFieldEffect","SX_D5")
            d.FocusDistance = 40; d.InFocusRadius = 20
            d.NearIntensity = 0.2; d.FarIntensity = 0.6
            local s = getEff("SunRaysEffect","SX_S5")
            s.Intensity = 0.15; s.Spread = 0.3
            Lighting.Ambient = Color3.fromRGB(70,55,45); Lighting.Brightness = 2.8
        end,
        off = function() remEff({"SX_B5","SX_C5","SX_D5","SX_S5"}) end,
    },
    {
        name  = "NIGHT SHADERS",
        color = Color3.fromRGB(80, 100, 220),
        on = function()
            local c = getEff("ColorCorrectionEffect","SX_C6")
            c.Brightness = -0.2; c.Contrast = 0.3; c.Saturation = -0.15
            c.TintColor = Color3.fromRGB(180,190,255)
            local b = getEff("BloomEffect","SX_B6")
            b.Intensity = 2.0; b.Size = 22; b.Threshold = 0.7
            Lighting.Ambient    = Color3.fromRGB(20,25,60)
            Lighting.Brightness = 0.5
            Lighting.ClockTime  = 0
            Lighting.FogColor   = Color3.fromRGB(10,15,40)
            Lighting.FogEnd     = 500
        end,
        off = function()
            remEff({"SX_C6","SX_B6"})
            Lighting.ClockTime = origLight.ClockTime
            Lighting.FogColor  = origLight.FogColor
            Lighting.FogEnd    = origLight.FogEnd
        end,
    },
    {
        name  = "8 BIT SHADERS",
        color = Color3.fromRGB(255, 100, 150),
        on = function()
            local c = getEff("ColorCorrectionEffect","SX_C7")
            c.Brightness = 0.15; c.Contrast = 0.6; c.Saturation = 0.8
            c.TintColor = Color3.fromRGB(255,240,255)
            Lighting.Brightness = 2
            Lighting.Ambient    = Color3.fromRGB(80,80,80)
        end,
        off = function() remEff({"SX_C7"}) end,
    },
    {
        name  = "SUNRISE SHADERS",
        color = Color3.fromRGB(255, 175, 80),
        on = function()
            local c = getEff("ColorCorrectionEffect","SX_C8")
            c.Brightness = 0.14; c.Contrast = 0.22; c.Saturation = 0.45
            c.TintColor = Color3.fromRGB(255, 235, 180)
            local b = getEff("BloomEffect","SX_B8")
            b.Intensity = 1.4; b.Size = 22; b.Threshold = 0.82
            local s = getEff("SunRaysEffect","SX_S8")
            s.Intensity = 0.45; s.Spread = 0.75
            Lighting.Ambient    = Color3.fromRGB(130, 90, 55)
            Lighting.Brightness = 3.2
            Lighting.ClockTime  = 6.5
        end,
        off = function()
            remEff({"SX_C8","SX_B8","SX_S8"})
            Lighting.ClockTime = origLight.ClockTime
        end,
    },
    {
        name  = "SUNSET SHADERS",
        color = Color3.fromRGB(255, 110, 70),
        on = function()
            local c = getEff("ColorCorrectionEffect","SX_C10")
            c.Brightness = 0.06; c.Contrast = 0.3; c.Saturation = 0.55
            c.TintColor = Color3.fromRGB(255, 190, 150)
            local b = getEff("BloomEffect","SX_B10")
            b.Intensity = 1.6; b.Size = 26; b.Threshold = 0.78
            local s = getEff("SunRaysEffect","SX_S10")
            s.Intensity = 0.5; s.Spread = 0.85
            Lighting.Ambient    = Color3.fromRGB(140, 70, 60)
            Lighting.Brightness = 2.4
            Lighting.ClockTime  = 18.5
        end,
        off = function()
            remEff({"SX_C10","SX_B10","SX_S10"})
            Lighting.ClockTime = origLight.ClockTime
        end,
    },
    {
        name  = "SNOW SHADERS",
        color = Color3.fromRGB(200, 225, 255),
        on = function()
            local c = getEff("ColorCorrectionEffect","SX_C11")
            c.Brightness = 0.18; c.Contrast = 0.1; c.Saturation = -0.35
            c.TintColor = Color3.fromRGB(225, 240, 255)
            local b = getEff("BloomEffect","SX_B11")
            b.Intensity = 1.0; b.Size = 20; b.Threshold = 0.85
            Lighting.Ambient    = Color3.fromRGB(160, 175, 195)
            Lighting.Brightness = 3.4
            Lighting.FogColor   = Color3.fromRGB(210, 225, 240)
            Lighting.FogEnd     = 700
        end,
        off = function()
            remEff({"SX_C11","SX_B11"})
            Lighting.FogColor = origLight.FogColor
            Lighting.FogEnd   = origLight.FogEnd
        end,
    },
    {
        name  = "THUNDER SHADERS",
        color = Color3.fromRGB(120, 130, 160),
        on = function()
            local c = getEff("ColorCorrectionEffect","SX_C12")
            c.Brightness = -0.15; c.Contrast = 0.5; c.Saturation = -0.4
            c.TintColor = Color3.fromRGB(190, 200, 220)
            local b = getEff("BloomEffect","SX_B12")
            b.Intensity = 0.6; b.Size = 14; b.Threshold = 0.95
            Lighting.Ambient    = Color3.fromRGB(45, 48, 60)
            Lighting.Brightness = 1.1
            Lighting.FogColor   = Color3.fromRGB(60, 63, 75)
            Lighting.FogEnd     = 350
        end,
        off = function()
            remEff({"SX_C12","SX_B12"})
            Lighting.FogColor = origLight.FogColor
            Lighting.FogEnd   = origLight.FogEnd
        end,
    },
    {
        name  = "VERY ULTRA HIGH GRAPHICS",
        color = Color3.fromRGB(255, 60, 180),
        on = function()
            local b = getEff("BloomEffect","SX_B13")
            b.Intensity = 3.2; b.Size = 32; b.Threshold = 0.6
            local c = getEff("ColorCorrectionEffect","SX_C13")
            c.Brightness = 0.12; c.Contrast = 0.5; c.Saturation = 0.55
            c.TintColor = Color3.fromRGB(250,250,255)
            local s = getEff("SunRaysEffect","SX_S13")
            s.Intensity = 0.5; s.Spread = 0.9
            local d = getEff("DepthOfFieldEffect","SX_D13")
            d.FocusDistance = 55; d.InFocusRadius = 35
            d.NearIntensity = 0.1; d.FarIntensity = 0.35
            Lighting.Ambient    = Color3.fromRGB(90,95,130)
            Lighting.Brightness = 4.2
        end,
        off = function() remEff({"SX_B13","SX_C13","SX_S13","SX_D13"}) end,
    },
    {
        name  = "ROBLOX 4K GRAPHIC SHADER",
        color = Color3.fromRGB(60, 220, 255),
        on = function()
            local b = getEff("BloomEffect","SX_B14")
            b.Intensity = 1.1; b.Size = 12; b.Threshold = 0.92
            local c = getEff("ColorCorrectionEffect","SX_C14")
            c.Brightness = 0.05; c.Contrast = 0.42; c.Saturation = 0.35
            c.TintColor = Color3.fromRGB(245,250,255)
            local s = getEff("SunRaysEffect","SX_S14")
            s.Intensity = 0.2; s.Spread = 0.35
            Lighting.Ambient    = Color3.fromRGB(100,105,120)
            Lighting.Brightness = 3
        end,
        off = function() remEff({"SX_B14","SX_C14","SX_S14"}) end,
    },
    {
        name  = "HDR GRAPHICS SHADERS",
        color = Color3.fromRGB(255, 220, 50),
        on = function()
            local b = getEff("BloomEffect","SX_B9")
            b.Intensity = 3.0; b.Size = 30; b.Threshold = 0.65
            local c = getEff("ColorCorrectionEffect","SX_C9")
            c.Brightness = 0.12; c.Contrast = 0.45; c.Saturation = 0.6
            c.TintColor = Color3.fromRGB(255,250,240)
            local s = getEff("SunRaysEffect","SX_S9")
            s.Intensity = 0.4; s.Spread = 0.8
            local d = getEff("DepthOfFieldEffect","SX_D9")
            d.FocusDistance = 60; d.InFocusRadius = 40
            d.NearIntensity = 0.08; d.FarIntensity = 0.25
            Lighting.Ambient    = Color3.fromRGB(85,90,115)
            Lighting.Brightness = 4.0
        end,
        off = function() remEff({"SX_B9","SX_C9","SX_S9","SX_D9"}) end,
    },
}

-- ── GUI parent (executor safe) ────────────────
local guiParent = (gethui and gethui()) or LP:WaitForChild("PlayerGui")

-- ── ScreenGui ─────────────────────────────────
local SG = Instance.new("ScreenGui")
SG.Name           = "SIEXTHERShaders"
SG.ResetOnSpawn   = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset = true
SG.DisplayOrder   = 999
SG.Parent         = guiParent

-- ── Tiny helpers ──────────────────────────────
local function mk(cls, props, par)
    local o = Instance.new(cls)
    for k, v in pairs(props) do o[k] = v end
    if par then o.Parent = par end
    return o
end
local function rnd(r, p)
    mk("UICorner", {CornerRadius = UDim.new(0, r)}, p)
end
local function strk(col, thk, tr, p)
    mk("UIStroke", {Color = col, Thickness = thk, Transparency = tr}, p)
end
local TI = function(t, s, d)
    return TweenInfo.new(t, s or Enum.EasingStyle.Quad, d or Enum.EasingDirection.Out)
end


local Main = mk("Frame", {
    Name             = "Main",
    Size             = UDim2.new(0, 188, 0, 316),
    Position         = UDim2.new(0.5, -94, 0.5, -158),
    BackgroundColor3 = BG,
    BorderSizePixel  = 0,
    ClipsDescendants = true,
    ZIndex           = 2,
}, SG)
rnd(10, Main)
strk(ACCENT, 1.5, 0.25, Main)

-- subtle inner gradient
mk("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 45)),
        ColorSequenceKeypoint.new(1, BG),
    }),
    Rotation = 135,
}, Main)

-- ══════════════════════════════════════════════
--   TITLE BAR
-- ══════════════════════════════════════════════
local TBar = mk("Frame", {
    Size             = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = DARK,
    BorderSizePixel  = 0,
    ZIndex           = 3,
}, Main)
rnd(10, TBar)

-- fill bottom corners of titlebar
mk("Frame", {
    Size             = UDim2.new(1, 0, 0, 12),
    Position         = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = DARK,
    BorderSizePixel  = 0,
    ZIndex           = 3,
}, TBar)

-- bottom border line
mk("Frame", {
    Size             = UDim2.new(1, 0, 0, 1),
    Position         = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = ACCENT,
    BorderSizePixel  = 0,
    ZIndex           = 4,
    BackgroundTransparency = 0.65,
}, TBar)

-- icon + title
mk("TextLabel", {
    Size                 = UDim2.new(1, -78, 1, 0),
    Position             = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text                 = "SIEXTHER SHADER",
    TextColor3           = ACCENT,
    TextSize             = 11,
    Font                 = Enum.Font.GothamBold,
    TextXAlignment       = Enum.TextXAlignment.Left,
    ZIndex               = 5,
}, TBar)

mk("TextLabel", {
    Size                 = UDim2.new(0, 60, 0, 10),
    Position             = UDim2.new(0, 10, 0, 23),
    BackgroundTransparency = 1,
    Text                 = "Made By Hann.Siexther",
    TextColor3           = MUTED,
    TextSize             = 6,
    Font                 = Enum.Font.GothamBold,
    TextXAlignment       = Enum.TextXAlignment.Left,
    ZIndex               = 5,
}, TBar)

-- ── Minimize button ───────────────────────────
local MinBtn = mk("TextButton", {
    Size             = UDim2.new(0, 23, 0, 23),
    Position         = UDim2.new(1, -50, 0.5, -11),
    BackgroundColor3 = Color3.fromRGB(42, 42, 62),
    BorderSizePixel  = 0,
    Text             = "–",
    TextColor3       = Color3.fromRGB(180, 185, 255),
    TextSize         = 14,
    Font             = Enum.Font.GothamBold,
    ZIndex           = 6,
    AutoButtonColor  = false,
}, TBar)
rnd(6, MinBtn)

-- ── Close button ──────────────────────────────
local CloseBtn = mk("TextButton", {
    Size             = UDim2.new(0, 23, 0, 23),
    Position         = UDim2.new(1, -25, 0.5, -11),
    BackgroundColor3 = Color3.fromRGB(42, 42, 62),
    BorderSizePixel  = 0,
    Text             = "X",
    TextColor3       = Color3.fromRGB(255, 85, 85),
    TextSize         = 10,
    Font             = Enum.Font.GothamBold,
    ZIndex           = 6,
    AutoButtonColor  = false,
}, TBar)
rnd(6, CloseBtn)

-- button hover effects
for _, b in pairs({MinBtn, CloseBtn}) do
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TI(0.12), {BackgroundColor3 = Color3.fromRGB(55, 55, 78)}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TI(0.12), {BackgroundColor3 = Color3.fromRGB(42, 42, 62)}):Play()
    end)
end

-- ── Section label ─────────────────────────────
mk("TextLabel", {
    Size                 = UDim2.new(1, -14, 0, 13),
    Position             = UDim2.new(0, 8, 0, 41),
    BackgroundTransparency = 1,
    Text                 = "——— PILIH SHADER ———",
    TextColor3           = MUTED,
    TextSize             = 7,
    Font                 = Enum.Font.GothamBold,
    TextXAlignment       = Enum.TextXAlignment.Left,
    ZIndex               = 3,
}, Main)

-- divider
mk("Frame", {
    Size             = UDim2.new(1, -16, 0, 1),
    Position         = UDim2.new(0, 8, 0, 54),
    BackgroundColor3 = ACCENT,
    BackgroundTransparency = 0.8,
    BorderSizePixel  = 0,
    ZIndex           = 3,
}, Main)

-- ══════════════════════════════════════════════
--   SCROLL FRAME
-- ══════════════════════════════════════════════
local Scroll = mk("ScrollingFrame", {
    Size                 = UDim2.new(1, -10, 1, -62),
    Position             = UDim2.new(0, 5, 0, 58),
    BackgroundTransparency = 1,
    BorderSizePixel      = 0,
    ScrollBarThickness   = 2,
    ScrollBarImageColor3 = ACCENT,
    ScrollBarImageTransparency = 0.45,
    CanvasSize           = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize  = Enum.AutomaticSize.Y,
    ZIndex               = 3,
}, Main)

mk("UIListLayout", {
    Padding                  = UDim.new(0, 4),
    SortOrder                = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment      = Enum.HorizontalAlignment.Center,
}, Scroll)

mk("UIPadding", {
    PaddingTop    = UDim.new(0, 2),
    PaddingBottom = UDim.new(0, 5),
    PaddingLeft   = UDim.new(0, 2),
    PaddingRight  = UDim.new(0, 2),
}, Scroll)

-- ══════════════════════════════════════════════
--   SHADER BUTTONS  (icon dihapus, hanya teks)
-- ══════════════════════════════════════════════
local activeState = {}
local btnRefs     = {}

local function refreshBtn(data)
    local isOn = activeState[data.name]
    local btn  = btnRefs[data.name]
    if not btn then return end

    local pill = btn:FindFirstChild("Pill")
    local ind  = pill and pill:FindFirstChild("Ind")
    local plbl = pill and pill:FindFirstChild("Lbl")
    local pst  = pill and pill:FindFirstChildOfClass("UIStroke")
    local bst  = btn:FindFirstChildOfClass("UIStroke")
    local glow = btn:FindFirstChild("Glow")
    local tw   = TI(0.18)

    TweenService:Create(btn, tw, {
        BackgroundColor3 = isOn and BTN_ON or BTN
    }):Play()

    if bst then
        TweenService:Create(bst, tw, {
            Color        = isOn and ACCENT or Color3.fromRGB(52, 52, 72),
            Transparency = isOn and 0.05 or 0.72,
        }):Play()
    end
    if glow then
        TweenService:Create(glow, tw, {
            BackgroundTransparency = isOn and 0.82 or 1,
        }):Play()
    end
    if pill then
        TweenService:Create(pill, tw, {
            BackgroundColor3 = isOn and Color3.fromRGB(18, 35, 68) or Color3.fromRGB(38, 38, 58)
        }):Play()
    end
    if pst then
        TweenService:Create(pst, tw, {
            Color        = isOn and ACCENT or Color3.fromRGB(52, 52, 72),
            Transparency = isOn and 0.1 or 0.72,
        }):Play()
    end
    if ind then
        TweenService:Create(ind, tw, {
            Position         = isOn and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
            BackgroundColor3 = isOn and ACCENT or Color3.fromRGB(62, 62, 88),
        }):Play()
    end
    if plbl then
        plbl.Text      = isOn and "ON" or "OFF"
        plbl.TextColor3 = isOn and ACCENT or MUTED
    end
end

for i, data in ipairs(SHADERS) do
    -- main button
    local Btn = mk("TextButton", {
        Name             = data.name,
        Size             = UDim2.new(1, -4, 0, 32),
        BackgroundColor3 = BTN,
        BorderSizePixel  = 0,
        Text             = "",
        LayoutOrder      = i,
        AutoButtonColor  = false,
        ZIndex           = 4,
    }, Scroll)
    rnd(8, Btn)
    strk(Color3.fromRGB(52, 52, 72), 1, 0.72, Btn)

    -- accent glow (visible when ON)
    local Glow = mk("Frame", {
        Name                 = "Glow",
        Size                 = UDim2.new(1, 0, 1, 0),
        BackgroundColor3     = data.color,
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        ZIndex               = 4,
    }, Btn)
    rnd(8, Glow)

    -- left color stripe (menggantikan ikon)
    local stripe = mk("Frame", {
        Size             = UDim2.new(0, 3, 0.52, 0),
        Position         = UDim2.new(0, 8, 0.24, 0),
        BackgroundColor3 = data.color,
        BorderSizePixel  = 0,
        ZIndex           = 5,
    }, Btn)
    rnd(3, stripe)

    -- shader name (mulai lebih ke kiri karena tidak ada ikon)
    mk("TextLabel", {
        Size                 = UDim2.new(1, -68, 1, 0),
        Position             = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Text                 = data.name,
        TextColor3           = TEXT,
        TextSize             = 9,
        Font                 = Enum.Font.GothamBold,
        TextXAlignment       = Enum.TextXAlignment.Left,
        TextTruncate         = Enum.TextTruncate.AtEnd,
        ZIndex               = 5,
    }, Btn)

    -- toggle pill background
    local Pill = mk("Frame", {
        Name             = "Pill",
        Size             = UDim2.new(0, 40, 0, 20),
        Position         = UDim2.new(1, -46, 0.5, -10),
        BackgroundColor3 = Color3.fromRGB(38, 38, 58),
        BorderSizePixel  = 0,
        ZIndex           = 5,
    }, Btn)
    rnd(10, Pill)
    strk(Color3.fromRGB(52, 52, 72), 1, 0.72, Pill)

    -- sliding circle
    local Ind = mk("Frame", {
        Name             = "Ind",
        Size             = UDim2.new(0, 12, 0, 12),
        Position         = UDim2.new(0, 3, 0.5, -6),
        BackgroundColor3 = Color3.fromRGB(62, 62, 88),
        BorderSizePixel  = 0,
        ZIndex           = 6,
    }, Pill)
    rnd(6, Ind)

    -- ON/OFF label
    mk("TextLabel", {
        Name                 = "Lbl",
        Size                 = UDim2.new(1, -14, 1, 0),
        Position             = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text                 = "OFF",
        TextColor3           = MUTED,
        TextSize             = 6,
        Font                 = Enum.Font.GothamBold,
        ZIndex               = 6,
    }, Pill)

    btnRefs[data.name] = Btn

    -- hover
    Btn.MouseEnter:Connect(function()
        if not activeState[data.name] then
            TweenService:Create(Btn, TI(0.12), {BackgroundColor3 = Color3.fromRGB(40, 40, 58)}):Play()
        end
    end)
    Btn.MouseLeave:Connect(function()
        if not activeState[data.name] then
            TweenService:Create(Btn, TI(0.12), {BackgroundColor3 = BTN}):Play()
        end
    end)

    -- click toggle
    Btn.MouseButton1Click:Connect(function()
        activeState[data.name] = not activeState[data.name]
        if activeState[data.name] then data.on() else data.off() end
        refreshBtn(data)
    end)
end

-- ══════════════════════════════════════════════
--   FLOATING BUTTON (minimized state)
-- ══════════════════════════════════════════════
local FloatBtn = mk("TextButton", {
    Name             = "FloatBtn",
    Size             = UDim2.new(0, 40, 0, 40),
    Position         = UDim2.new(0, 18, 0.5, -22),
    BackgroundColor3 = Color3.fromRGB(25, 25, 35),
    BorderSizePixel  = 0,
    Text             = "🪐",
    TextSize         = 20,
    Visible          = false,
    ZIndex           = 10,
    AutoButtonColor  = false,
}, SG)
rnd(12, FloatBtn)

do
    local drag, ds, sp = false, nil, nil
    TBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = i.Position; sp = Main.Position
        end
    end)
    TBar.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
                  or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X,
                                      sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

-- Float button drag (with click detection)
local fbDrag, fbDS, fbSP, fbMoved = false, nil, nil, false
FloatBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        fbDrag = true; fbMoved = false
        fbDS = i.Position; fbSP = FloatBtn.Position
    end
end)
FloatBtn.InputChanged:Connect(function(i)
    if fbDrag and (i.UserInputType == Enum.UserInputType.MouseMovement
               or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - fbDS
        if math.abs(d.X) > 5 or math.abs(d.Y) > 5 then fbMoved = true end
        FloatBtn.Position = UDim2.new(fbSP.X.Scale, fbSP.X.Offset + d.X,
                                      fbSP.Y.Scale,  fbSP.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then fbDrag = false end
end)

-- ══════════════════════════════════════════════
--   MINIMIZE  →  floating 🩷
-- ══════════════════════════════════════════════
MinBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TI(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 188, 0, 0),
    }):Play()
    task.wait(0.22)
    Main.Visible    = false
    FloatBtn.Visible = true
    FloatBtn.Size   = UDim2.new(0, 0, 0, 0)
    TweenService:Create(FloatBtn, TI(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 44, 0, 44),
    }):Play()
end)

-- ══════════════════════════════════════════════
--   RESTORE from floating
-- ══════════════════════════════════════════════
FloatBtn.MouseButton1Click:Connect(function()
    if fbMoved then return end
    FloatBtn.Visible = false
    Main.Visible     = true
    Main.Size        = UDim2.new(0, 188, 0, 0)
    TweenService:Create(Main, TI(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 188, 0, 316),
    }):Play()
end)

-- ══════════════════════════════════════════════
--   CLOSE  →  destroy script
-- ══════════════════════════════════════════════
CloseBtn.MouseButton1Click:Connect(function()
    -- disable all active shaders first
    for _, d in ipairs(SHADERS) do
        if activeState[d.name] then
            pcall(d.off)
        end
    end
    -- restore original lighting
    Lighting.Ambient    = origLight.Ambient
    Lighting.Brightness = origLight.Brightness
    Lighting.ClockTime  = origLight.ClockTime
    Lighting.FogColor   = origLight.FogColor
    Lighting.FogEnd     = origLight.FogEnd

    TweenService:Create(Main, TI(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size                 = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
    }):Play()
    task.wait(0.22)
    SG:Destroy()
end)
