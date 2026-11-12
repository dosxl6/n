
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

-- FPS Counter
local FPSCounter = {
    lastTime = tick(),
    frames = 0,
    currentFPS = 0
}

-- Settings
local BoostEnabled = false

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AntiLagFPSBooster"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 220)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -110)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(70, 130, 255)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 16)
HeaderCorner.Parent = Header

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 16)
HeaderFix.Position = UDim2.new(0, 0, 1, -16)
HeaderFix.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

-- Title
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -50, 0.5, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SIEXTHER ANTI-LAG"
Title.TextColor3 = Color3.fromRGB(70, 130, 255)
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- FPS Display
local FPSLabel = Instance.new("TextLabel")
FPSLabel.Name = "FPSLabel"
FPSLabel.Size = UDim2.new(1, -50, 0.5, 0)
FPSLabel.Position = UDim2.new(0, 16, 0.5, 0)
FPSLabel.BackgroundTransparency = 1
FPSLabel.Text = "FPS: 0"
FPSLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
FPSLabel.TextSize = 14
FPSLabel.Font = Enum.Font.Gotham
FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
FPSLabel.Parent = Header

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 80)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

-- Content Frame
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -32, 1, -66)
Content.Position = UDim2.new(0, 16, 0, 58)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- Info Card
local InfoCard = Instance.new("Frame")
InfoCard.Name = "InfoCard"
InfoCard.Size = UDim2.new(1, 0, 0, 50)
InfoCard.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
InfoCard.BorderSizePixel = 0
InfoCard.Parent = Content

local InfoCorner = Instance.new("UICorner")
InfoCorner.CornerRadius = UDim.new(0, 10)
InfoCorner.Parent = InfoCard

local InfoText = Instance.new("TextLabel")
InfoText.Size = UDim2.new(1, -20, 1, -10)
InfoText.Position = UDim2.new(0, 10, 0, 5)
InfoText.BackgroundTransparency = 1
InfoText.Text = "UNTUK MEMBALIKKAN GRAPHICS\nSILAHKAN UNTUK KLIK RE-JOIN\nMade By Siexther"
InfoText.TextColor3 = Color3.fromRGB(170, 180, 200)
InfoText.TextSize = 11
InfoText.Font = Enum.Font.Gotham
InfoText.TextWrapped = true
InfoText.TextYAlignment = Enum.TextYAlignment.Top
InfoText.Parent = InfoCard

-- Apply Boost Button
local ApplyBtn = Instance.new("TextButton")
ApplyBtn.Name = "ApplyBtn"
ApplyBtn.Size = UDim2.new(1, 0, 0, 48)
ApplyBtn.Position = UDim2.new(0, 0, 0, 60)
ApplyBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
ApplyBtn.Text = "APPLY BOOST"
ApplyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyBtn.TextSize = 15
ApplyBtn.Font = Enum.Font.GothamBold
ApplyBtn.BorderSizePixel = 0
ApplyBtn.Parent = Content

local ApplyCorner = Instance.new("UICorner")
ApplyCorner.CornerRadius = UDim.new(0, 12)
ApplyCorner.Parent = ApplyBtn

-- Status Indicator
local StatusIndicator = Instance.new("Frame")
StatusIndicator.Name = "StatusIndicator"
StatusIndicator.Size = UDim2.new(0, 10, 0, 10)
StatusIndicator.Position = UDim2.new(0, 12, 0.5, -5)
StatusIndicator.BackgroundColor3 = Color3.fromRGB(150, 150, 160)
StatusIndicator.BorderSizePixel = 0
StatusIndicator.Parent = ApplyBtn

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(1, 0)
StatusCorner.Parent = StatusIndicator

-- Rejoin Server Button
local RejoinBtn = Instance.new("TextButton")
RejoinBtn.Name = "RejoinBtn"
RejoinBtn.Size = UDim2.new(1, 0, 0, 40)
RejoinBtn.Position = UDim2.new(0, 0, 0, 116)
RejoinBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
RejoinBtn.Text = "REJOIN SERVER"
RejoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RejoinBtn.TextSize = 13
RejoinBtn.Font = Enum.Font.GothamBold
RejoinBtn.BorderSizePixel = 0
RejoinBtn.Parent = Content

local RejoinCorner = Instance.new("UICorner")
RejoinCorner.CornerRadius = UDim.new(0, 12)
RejoinCorner.Parent = RejoinBtn

-- ========================================
-- OPTIMIZATION FUNCTIONS
-- ========================================

local function removeTextures()
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            elseif obj:IsA("MeshPart") or obj:IsA("Part") then
                if obj.Material ~= Enum.Material.SmoothPlastic then
                    obj.Material = Enum.Material.SmoothPlastic
                end
            end
        end)
    end
end

local function removeEffects()
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or 
               obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                obj.Enabled = false
            end
        end)
    end
    
    for _, obj in pairs(Lighting:GetChildren()) do
        pcall(function()
            if obj:IsA("BloomEffect") or obj:IsA("BlurEffect") or obj:IsA("ColorCorrectionEffect") or
               obj:IsA("SunRaysEffect") or obj:IsA("DepthOfFieldEffect") then
                obj.Enabled = false
            end
        end)
    end
end

local function applyLowGraphics()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
    
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 2
    
    pcall(function()
        Lighting.Technology = Enum.Technology.Legacy
    end)
end

local function optimizeTerrain()
    local terrain = Workspace.Terrain
    
    terrain.WaterWaveSize = 0
    terrain.WaterWaveSpeed = 0
    terrain.WaterReflectance = 0
    terrain.WaterTransparency = 0
    terrain.Decoration = false
end

local function applyAllOptimizations()
    if BoostEnabled then
        ApplyBtn.Text = "ALREADY ACTIVE"
        task.wait(1)
        ApplyBtn.Text = "BOOST ACTIVE"
        return
    end
    
    ApplyBtn.Text = "BOOST ACTIVE"
    ApplyBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
    StatusIndicator.BackgroundColor3 = Color3.fromRGB(100, 255, 150)
    task.wait(0.1)
    
    removeTextures()
    removeEffects()
    applyLowGraphics()
    optimizeTerrain()
    
    BoostEnabled = true
    
    ApplyBtn.Text = "BOOST ACTIVE"
    ApplyBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
    StatusIndicator.BackgroundColor3 = Color3.fromRGB(100, 255, 150)
end

local function rejoinServer()
    RejoinBtn.Text = "REJOINING..."
    RejoinBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    
    task.wait(0.5)
    
    local success, errorMsg = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
    
    if not success then
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end

-- ========================================
-- BUTTON HANDLERS
-- ========================================

ApplyBtn.MouseButton1Click:Connect(function()
    applyAllOptimizations()
end)

RejoinBtn.MouseButton1Click:Connect(function()
    rejoinServer()
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- ========================================
-- FPS COUNTER
-- ========================================

RunService.RenderStepped:Connect(function()
    FPSCounter.frames = FPSCounter.frames + 1
    
    local currentTime = tick()
    if currentTime - FPSCounter.lastTime >= 1 then
        FPSCounter.currentFPS = FPSCounter.frames
        FPSCounter.frames = 0
        FPSCounter.lastTime = currentTime
        
        FPSLabel.Text = string.format("FPS: %d", FPSCounter.currentFPS)
        
        if FPSCounter.currentFPS >= 60 then
            FPSLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
        elseif FPSCounter.currentFPS >= 30 then
            FPSLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        else
            FPSLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end
end)

-- ========================================
-- HOVER EFFECTS
-- ========================================

local function addHoverEffect(button, normalColor)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(
                math.min(normalColor.R * 255 + 25, 255),
                math.min(normalColor.G * 255 + 25, 255),
                math.min(normalColor.B * 255 + 25, 255)
            )
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        if not BoostEnabled or button ~= ApplyBtn then
            TweenService:Create(button, TweenInfo.new(0.2), {
                BackgroundColor3 = normalColor
            }):Play()
        end
    end)
end

addHoverEffect(ApplyBtn, Color3.fromRGB(70, 130, 255))
addHoverEffect(RejoinBtn, Color3.fromRGB(28, 28, 40))
addHoverEffect(CloseBtn, Color3.fromRGB(255, 70, 80))