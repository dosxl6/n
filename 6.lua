local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DayCycleChanger"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

-- Main Frame (Dark Modern)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 320)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(70, 130, 255)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 12)
HeaderFix.Position = UDim2.new(0, 0, 1, -12)
HeaderFix.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

-- Title
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SIEXTHER SKY"
Title.TextColor3 = Color3.fromRGB(70, 130, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Minimize Button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 28, 0, 28)
MinimizeBtn.Position = UDim2.new(1, -64, 0.5, -14)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MinimizeBtn.Text = "–"
MinimizeBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
MinimizeBtn.TextSize = 16
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.AutoButtonColor = false
MinimizeBtn.Parent = Header

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 7)
MinimizeCorner.Parent = MinimizeBtn

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -32, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 70, 70)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 7)
CloseCorner.Parent = CloseBtn

-- Minimized Button
local MinimizedBtn = Instance.new("TextButton")
MinimizedBtn.Name = "MinimizedBtn"
MinimizedBtn.Size = UDim2.new(0, 41, 0, 41)
MinimizedBtn.Position = UDim2.new(1, -70, 0.5, -22)
MinimizedBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MinimizedBtn.Text = "🌤️"
MinimizedBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
MinimizedBtn.TextSize = 20
MinimizedBtn.Font = Enum.Font.GothamBold
MinimizedBtn.BorderSizePixel = 0
MinimizedBtn.Visible = false
MinimizedBtn.Active = true
MinimizedBtn.Draggable = true
MinimizedBtn.AutoButtonColor = false
MinimizedBtn.Parent = ScreenGui


local MinimizedCorner = Instance.new("UICorner")
MinimizedCorner.CornerRadius = UDim.new(0, 12)
MinimizedCorner.Parent = MinimizedBtn


-- Content Frame
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -24, 1, -52)
ContentFrame.Position = UDim2.new(0, 12, 0, 46)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Info Label
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Name = "InfoLabel"
InfoLabel.Size = UDim2.new(1, 0, 0, 18)
InfoLabel.Position = UDim2.new(0, 0, 0, 0)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "SAAT INI: Default"
InfoLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
InfoLabel.TextSize = 12
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.Parent = ContentFrame

-- Scroll Frame for Options (Grid Layout)
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "ScrollFrame"
ScrollFrame.Size = UDim2.new(1, 0, 1, -25)
ScrollFrame.Position = UDim2.new(0, 0, 0, 22)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent = ContentFrame

local ScrollCorner = Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(0, 8)
ScrollCorner.Parent = ScrollFrame

-- Grid Layout (2 kolom, compact)
local GridLayout = Instance.new("UIGridLayout")
GridLayout.CellSize = UDim2.new(0.5, -6, 0, 55)
GridLayout.CellPadding = UDim2.new(0, 4, 0, 4)
GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
GridLayout.Parent = ScrollFrame

local ScrollPadding = Instance.new("UIPadding")
ScrollPadding.PaddingTop = UDim.new(0, 8)
ScrollPadding.PaddingBottom = UDim.new(0, 8)
ScrollPadding.PaddingLeft = UDim.new(0, 8)
ScrollPadding.PaddingRight = UDim.new(0, 8)
ScrollPadding.Parent = ScrollFrame

-- Day Cycle Presets
local presets = {
    {
        name = "☀️ Pagi",
        shortName = "Pagi",
        emoji = "☀️",
        timeOfDay = 7,
        settings = {
            Brightness = 2,
            ColorShift_Top = Color3.fromRGB(255, 200, 150),
            ColorShift_Bottom = Color3.fromRGB(255, 230, 200),
            OutdoorAmbient = Color3.fromRGB(180, 180, 180),
            Ambient = Color3.fromRGB(150, 150, 150),
            FogColor = Color3.fromRGB(200, 220, 255),
            FogEnd = 100000,
            FogStart = 0,
            ClockTime = 7
        }
    },
    {
        name = "🌞 Siang",
        shortName = "Siang",
        emoji = "🌞",
        timeOfDay = 12,
        settings = {
            Brightness = 3,
            ColorShift_Top = Color3.fromRGB(0, 0, 0),
            ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
            OutdoorAmbient = Color3.fromRGB(127, 127, 127),
            Ambient = Color3.fromRGB(100, 100, 100),
            FogColor = Color3.fromRGB(191, 191, 191),
            FogEnd = 100000,
            FogStart = 0,
            ClockTime = 12
        }
    },
    {
        name = "🌅 Sore",
        shortName = "Sore",
        emoji = "🌅",
        timeOfDay = 18,
        settings = {
            Brightness = 1.5,
            ColorShift_Top = Color3.fromRGB(255, 100, 50),
            ColorShift_Bottom = Color3.fromRGB(255, 150, 100),
            OutdoorAmbient = Color3.fromRGB(150, 100, 80),
            Ambient = Color3.fromRGB(120, 80, 60),
            FogColor = Color3.fromRGB(255, 150, 100),
            FogEnd = 80000,
            FogStart = 0,
            ClockTime = 18
        }
    },
    {
        name = "🌙 Malam",
        shortName = "Malam",
        emoji = "🌙",
        timeOfDay = 0,
        settings = {
            Brightness = 0.5,
            ColorShift_Top = Color3.fromRGB(0, 0, 50),
            ColorShift_Bottom = Color3.fromRGB(0, 0, 30),
            OutdoorAmbient = Color3.fromRGB(50, 50, 80),
            Ambient = Color3.fromRGB(30, 30, 50),
            FogColor = Color3.fromRGB(20, 20, 40),
            FogEnd = 50000,
            FogStart = 0,
            ClockTime = 0
        }
    },
    {
        name = "🌧️ Hujan",
        shortName = "Hujan",
        emoji = "🌧️",
        timeOfDay = 14,
        settings = {
            Brightness = 1,
            ColorShift_Top = Color3.fromRGB(100, 100, 120),
            ColorShift_Bottom = Color3.fromRGB(80, 80, 100),
            OutdoorAmbient = Color3.fromRGB(100, 100, 110),
            Ambient = Color3.fromRGB(80, 80, 90),
            FogColor = Color3.fromRGB(150, 150, 160),
            FogEnd = 40000,
            FogStart = 0,
            ClockTime = 14
        },
        effects = {"rain"}
    },
    {
        name = "❄️ Salju",
        shortName = "Salju",
        emoji = "❄️",
        timeOfDay = 10,
        settings = {
            Brightness = 2.5,
            ColorShift_Top = Color3.fromRGB(200, 220, 255),
            ColorShift_Bottom = Color3.fromRGB(220, 230, 255),
            OutdoorAmbient = Color3.fromRGB(180, 200, 220),
            Ambient = Color3.fromRGB(160, 180, 200),
            FogColor = Color3.fromRGB(230, 240, 255),
            FogEnd = 50000,
            FogStart = 0,
            ClockTime = 10
        },
        effects = {"snow"}
    },
    {
        name = "🌫️ Kabut",
        shortName = "Kabut",
        emoji = "🌫️",
        timeOfDay = 6,
        settings = {
            Brightness = 0.8,
            ColorShift_Top = Color3.fromRGB(180, 180, 190),
            ColorShift_Bottom = Color3.fromRGB(160, 160, 170),
            OutdoorAmbient = Color3.fromRGB(120, 120, 130),
            Ambient = Color3.fromRGB(100, 100, 110),
            FogColor = Color3.fromRGB(200, 200, 210),
            FogEnd = 200,
            FogStart = 0,
            ClockTime = 6
        },
        effects = {"fog"}
    },
    {
        name = "⛈️ Badai",
        shortName = "Badai",
        emoji = "⛈️",
        timeOfDay = 15,
        settings = {
            Brightness = 0.5,
            ColorShift_Top = Color3.fromRGB(50, 50, 70),
            ColorShift_Bottom = Color3.fromRGB(30, 30, 50),
            OutdoorAmbient = Color3.fromRGB(60, 60, 80),
            Ambient = Color3.fromRGB(40, 40, 60),
            FogColor = Color3.fromRGB(80, 80, 100),
            FogEnd = 25000,
            FogStart = 0,
            ClockTime = 15
        },
        effects = {"rain", "wind"}
    },
    {
        name = "🌆 Sunset",
        shortName = "Sunset",
        emoji = "🌆",
        timeOfDay = 19,
        settings = {
            Brightness = 1,
            ColorShift_Top = Color3.fromRGB(255, 80, 0),
            ColorShift_Bottom = Color3.fromRGB(255, 120, 50),
            OutdoorAmbient = Color3.fromRGB(130, 70, 50),
            Ambient = Color3.fromRGB(100, 60, 40),
            FogColor = Color3.fromRGB(255, 100, 50),
            FogEnd = 70000,
            FogStart = 0,
            ClockTime = 19
        }
    },
    {
        name = "🔄 Random",
        shortName = "Random",
        emoji = "🔄",
        timeOfDay = 12,
        settings = {
            Brightness = 2,
            ColorShift_Top = Color3.fromRGB(0, 0, 0),
            ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
            OutdoorAmbient = Color3.fromRGB(127, 127, 127),
            Ambient = Color3.fromRGB(100, 100, 100),
            FogColor = Color3.fromRGB(191, 191, 191),
            FogEnd = 100000,
            FogStart = 0,
            ClockTime = 12
        },
        effects = {"random_cycle"}
    }
}

-- Variables
local currentPreset = nil
local activeEffects = {}
local auroraConnection = nil
local randomCycleRunning = false
local randomCycleConnection = nil
local activeButton = nil

-- Random cycle presets
local cyclePresets = {
    {
        name = "Pagi",
        settings = {
            Brightness = 2,
            ColorShift_Top = Color3.fromRGB(255, 200, 150),
            ColorShift_Bottom = Color3.fromRGB(255, 230, 200),
            OutdoorAmbient = Color3.fromRGB(180, 180, 180),
            Ambient = Color3.fromRGB(150, 150, 150),
            FogColor = Color3.fromRGB(200, 220, 255),
            FogEnd = 100000,
            FogStart = 0,
            ClockTime = 7
        }
    },
    {
        name = "Siang",
        settings = {
            Brightness = 3,
            ColorShift_Top = Color3.fromRGB(0, 0, 0),
            ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
            OutdoorAmbient = Color3.fromRGB(127, 127, 127),
            Ambient = Color3.fromRGB(100, 100, 100),
            FogColor = Color3.fromRGB(191, 191, 191),
            FogEnd = 100000,
            FogStart = 0,
            ClockTime = 12
        }
    },
    {
        name = "Sore",
        settings = {
            Brightness = 1.5,
            ColorShift_Top = Color3.fromRGB(255, 100, 50),
            ColorShift_Bottom = Color3.fromRGB(255, 150, 100),
            OutdoorAmbient = Color3.fromRGB(150, 100, 80),
            Ambient = Color3.fromRGB(120, 80, 60),
            FogColor = Color3.fromRGB(255, 150, 100),
            FogEnd = 80000,
            FogStart = 0,
            ClockTime = 18
        }
    },
    {
        name = "Malam",
        settings = {
            Brightness = 0.5,
            ColorShift_Top = Color3.fromRGB(0, 0, 50),
            ColorShift_Bottom = Color3.fromRGB(0, 0, 30),
            OutdoorAmbient = Color3.fromRGB(50, 50, 80),
            Ambient = Color3.fromRGB(30, 30, 50),
            FogColor = Color3.fromRGB(20, 20, 40),
            FogEnd = 50000,
            FogStart = 0,
            ClockTime = 0
        }
    }
}

-- Function to clear effects
local function clearEffects()
    for _, effect in ipairs(activeEffects) do
        if effect and effect.Parent then
            effect:Destroy()
        end
    end
    activeEffects = {}
    
    if auroraConnection then
        auroraConnection:Disconnect()
        auroraConnection = nil
    end
    
    if randomCycleConnection then
        randomCycleConnection:Disconnect()
        randomCycleConnection = nil
        randomCycleRunning = false
    end
end

-- Function to create rain effect
local function createRainEffect()
    local rain = Instance.new("ParticleEmitter")
    rain.Name = "RainEffect"
    rain.Texture = "rbxasset://textures/particles/smoke_main.dds"
    rain.Color = ColorSequence.new(Color3.fromRGB(150, 180, 200))
    rain.Size = NumberSequence.new(0.3)
    rain.Transparency = NumberSequence.new(0.5)
    rain.Lifetime = NumberRange.new(1, 2)
    rain.Rate = 300
    rain.Speed = NumberRange.new(50, 80)
    rain.SpreadAngle = Vector2.new(10, 10)
    rain.VelocityInheritance = -0.5
    rain.Acceleration = Vector3.new(0, -100, 0)
    rain.Parent = workspace.CurrentCamera
    
    table.insert(activeEffects, rain)
    return rain
end

-- Function to create snow effect
local function createSnowEffect()
    local snow = Instance.new("ParticleEmitter")
    snow.Name = "SnowEffect"
    snow.Texture = "rbxasset://textures/particles/smoke_main.dds"
    snow.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    snow.Size = NumberSequence.new(0.2, 0.4)
    snow.Transparency = NumberSequence.new(0)
    snow.Lifetime = NumberRange.new(5, 8)
    snow.Rate = 100
    snow.Speed = NumberRange.new(5, 10)
    snow.SpreadAngle = Vector2.new(20, 20)
    snow.Rotation = NumberRange.new(0, 360)
    snow.RotSpeed = NumberRange.new(-50, 50)
    snow.VelocityInheritance = -0.3
    snow.Acceleration = Vector3.new(0, -5, 0)
    snow.Parent = workspace.CurrentCamera
    
    table.insert(activeEffects, snow)
    return snow
end

-- Function to create fog effect
local function createFogEffect()
    for i = 1, 3 do
        local fog = Instance.new("ParticleEmitter")
        fog.Name = "FogEffect_" .. i
        fog.Texture = "rbxasset://textures/particles/smoke_main.dds"
        fog.Color = ColorSequence.new(Color3.fromRGB(200, 200, 210))
        fog.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 20),
            NumberSequenceKeypoint.new(0.5, 30),
            NumberSequenceKeypoint.new(1, 40)
        }
        fog.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(0.5, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        }
        fog.Lifetime = NumberRange.new(8, 12)
        fog.Rate = 15
        fog.Speed = NumberRange.new(2, 5)
        fog.SpreadAngle = Vector2.new(180, 180)
        fog.Rotation = NumberRange.new(0, 360)
        fog.RotSpeed = NumberRange.new(-10, 10)
        fog.VelocityInheritance = -0.2
        fog.Acceleration = Vector3.new(0, 0.5, 0)
        fog.Parent = workspace.CurrentCamera
        
        table.insert(activeEffects, fog)
    end
end

-- Function to start random cycle
local function startRandomCycle()
    randomCycleRunning = true
    
    local function applyCyclePreset(cyclePreset)
        local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        
        for property, value in pairs(cyclePreset.settings) do
            if Lighting:FindFirstChild(property) or property == "ClockTime" or property == "Brightness" or property == "Ambient" or property == "OutdoorAmbient" or property == "FogEnd" or property == "FogStart" or property == "FogColor" or property == "ColorShift_Top" or property == "ColorShift_Bottom" then
                local tween = TweenService:Create(Lighting, tweenInfo, {[property] = value})
                tween:Play()
            end
        end
        
        InfoLabel.Text = "Random Cycle: " .. cyclePreset.name
    end
    
    spawn(function()
        local currentIndex = 1
        
        while randomCycleRunning do
            applyCyclePreset(cyclePresets[currentIndex])
            wait(300)
            
            currentIndex = currentIndex + 1
            if currentIndex > #cyclePresets then
                currentIndex = 1
            end
        end
    end)
end

-- Function to apply preset
local function applyPreset(preset)
    clearEffects()
    
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    
    for property, value in pairs(preset.settings) do
        if Lighting:FindFirstChild(property) or property == "ClockTime" or property == "Brightness" or property == "Ambient" or property == "OutdoorAmbient" or property == "FogEnd" or property == "FogStart" or property == "FogColor" or property == "ColorShift_Top" or property == "ColorShift_Bottom" then
            local tween = TweenService:Create(Lighting, tweenInfo, {[property] = value})
            tween:Play()
        end
    end
    
    if preset.effects then
        task.wait(0.5)
        
        for _, effect in ipairs(preset.effects) do
            if effect == "rain" then
                createRainEffect()
            elseif effect == "snow" then
                createSnowEffect()
            elseif effect == "fog" then
                createFogEffect()
            elseif effect == "random_cycle" then
                startRandomCycle()
            end
        end
    end
    
    currentPreset = preset.name
    if not randomCycleRunning then
        InfoLabel.Text = "SAAT INI: " .. preset.shortName
    end
end

-- Function to create preset button (Dark Modern)
local function createPresetButton(preset, index)
    local PresetBtn = Instance.new("TextButton")
    PresetBtn.Name = "Preset_" .. index
    PresetBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    PresetBtn.BorderSizePixel = 0
    PresetBtn.Text = ""
    PresetBtn.AutoButtonColor = false
    PresetBtn.LayoutOrder = index
    PresetBtn.Parent = ScrollFrame
    
    local PresetCorner = Instance.new("UICorner")
    PresetCorner.CornerRadius = UDim.new(0, 8)
    PresetCorner.Parent = PresetBtn
    
    -- Emoji
    local EmojiLabel = Instance.new("TextLabel")
    EmojiLabel.Size = UDim2.new(1, 0, 0, 24)
    EmojiLabel.Position = UDim2.new(0, 0, 0, 4)
    EmojiLabel.BackgroundTransparency = 1
    EmojiLabel.Text = preset.emoji
    EmojiLabel.TextSize = 20
    EmojiLabel.Font = Enum.Font.GothamBold
    EmojiLabel.Parent = PresetBtn
    
    -- Name
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -8, 0, 18)
    NameLabel.Position = UDim2.new(0, 4, 0, 30)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = preset.shortName
    NameLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    NameLabel.TextSize = 10
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Center
    NameLabel.Parent = PresetBtn
    
    -- Click event
    PresetBtn.MouseButton1Click:Connect(function()
        -- Reset previous active button
        if activeButton and activeButton ~= PresetBtn then
            activeButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        end
        
        -- Set new active button
        activeButton = PresetBtn
        PresetBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        
        applyPreset(preset)
    end)
    
    -- Hover effect
    PresetBtn.MouseEnter:Connect(function()
        if activeButton ~= PresetBtn then
            PresetBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        end
    end)
    
    PresetBtn.MouseLeave:Connect(function()
        if activeButton ~= PresetBtn then
            PresetBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        end
    end)
    
    return PresetBtn
end

-- Create all preset buttons
for i, preset in ipairs(presets) do
    createPresetButton(preset, i)
end

-- Update canvas size
task.wait(0.1)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#presets / 2) * 59 + 16)

-- Minimize/Maximize
local function minimizeGUI()
    MainFrame.Visible = false
    MinimizedBtn.Visible = true
end

local function maximizeGUI()
    MinimizedBtn.Visible = false
    MainFrame.Visible = true
end

MinimizeBtn.MouseButton1Click:Connect(function()
    minimizeGUI()
end)

MinimizedBtn.MouseButton1Click:Connect(function()
    maximizeGUI()
end)

-- Close Button
CloseBtn.MouseButton1Click:Connect(function()
    clearEffects()
    ScreenGui:Destroy()
end)

-- Cleanup on player leaving
LocalPlayer.AncestryChanged:Connect(function()
    if not LocalPlayer:IsDescendantOf(game) then
        clearEffects()
    end
end)
