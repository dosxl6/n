-- SIEXTHER
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Dancing = true

-- Network Bypass
settings().Physics.AllowSleep = false
settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)

-- Dance Animation System
local DanceSystem = {
    Parts = {},
    CurrentDance = 1,
    DanceTime = 0,
    GroupCenter = Vector3.new(0, 0, 0)
}

-- Enhanced Dance Moves
local DanceMoves = {
    {
        Name = "SHAKE ONE",
        Duration = 4,
        Steps = function(data, time, center)
            local t = time * 2
            return {
                Position = center + Vector3.new(
                    math.sin(t) * 3,
                    math.abs(math.sin(t * 2)) * 2,
                    math.cos(t) * 3
                ),
                Rotation = Vector3.new(
                    math.sin(t) * 30,
                    t * 180,
                    math.cos(t) * 20
                )
            }
        end
    },
    {
        Name = "SHAKE TWO",
        Duration = 2,
        Steps = function(data, time, center)
            local t = time * 3
            return {
                Position = center + Vector3.new(
                    math.floor(math.sin(t) * 2) * 2,
                    math.abs(math.sin(t * 4)) * 3,
                    math.floor(math.cos(t) * 2) * 2
                ),
                Rotation = Vector3.new(
                    math.floor(time * 90) % 90,
                    math.floor(time * 45) % 180,
                    math.floor(time * 60) % 60
                )
            }
        end
    },
    {
        Name = "SHAKE THREE",
        Duration = 3,
        Steps = function(data, time, center)
            local t = time * 4
            return {
                Position = center + Vector3.new(
                    math.sin(t) * 4 * math.cos(t),
                    math.abs(math.sin(t * 2)) * 4,
                    math.cos(t) * 4 * math.sin(t)
                ),
                Rotation = Vector3.new(
                    t * 360,
                    math.sin(t) * 180,
                    t * 180
                )
            }
        end
    },
    {
        Name = "SHAKE FOUR",
        Duration = 2.5,
        Steps = function(data, time, center)
            local wave = math.sin(time * 4) * 3
            local t = time * 2
            return {
                Position = center + Vector3.new(
                    math.sin(t + data.Offset) * 3,
                    wave + math.cos(t * 2) * 2,
                    math.cos(t + data.Offset) * 3
                ),
                Rotation = Vector3.new(
                    wave * 20,
                    t * 90,
                    math.cos(t) * 45
                )
            }
        end
    },
    {
        Name = "SHAKE FIVE",
        Duration = 2,
        Steps = function(data, time, center)
            local t = time * 3
            local shuffle = math.sin(t * 2) * math.cos(t)
            return {
                Position = center + Vector3.new(
                    shuffle * 4,
                    math.abs(math.sin(t * 3)) * 2,
                    math.cos(t * 2) * 3
                ),
                Rotation = Vector3.new(
                    0,
                    shuffle * 180,
                    math.sin(t) * 30
                )
            }
        end
    }
}

-- Part Setup
function DanceSystem:SetupPart(part)
    if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(LocalPlayer.Character) then
        part.CustomPhysicalProperties = PhysicalProperties.new(0.1, 0, 0, 0, 0)
        
        local attachment = Instance.new("Attachment")
        attachment.Parent = part
        
        local alignPosition = Instance.new("AlignPosition")
        alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
        alignPosition.Attachment0 = attachment
        alignPosition.MaxForce = math.huge
        alignPosition.MaxVelocity = math.huge
        alignPosition.Responsiveness = 200
        alignPosition.Parent = part
        
        local gyro = Instance.new("BodyGyro")
        gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        gyro.P = 100000
        gyro.Parent = part
        
        self.Parts[part] = {
            Attachment = attachment,
            AlignPosition = alignPosition,
            Gyro = gyro,
            StartPos = part.Position,
            Offset = #self.Parts * 0.2,
            BaseY = part.Position.Y
        }
        
        self.GroupCenter = self.GroupCenter + part.Position
    end
end

function DanceSystem:UpdateFormation()
    if next(self.Parts) then
        self.GroupCenter = Vector3.new(0, 0, 0)
        local count = 0
        
        for part, _ in pairs(self.Parts) do
            if part and part.Parent then
                self.GroupCenter = self.GroupCenter + part.Position
                count = count + 1
            end
        end
        
        if count > 0 then
            self.GroupCenter = self.GroupCenter / count
        end
    end
end

function DanceSystem:AnimateParts()
    self:UpdateFormation()
    local currentDance = DanceMoves[self.CurrentDance]
    local nextDance = DanceMoves[self.CurrentDance % #DanceMoves + 1]
    
    for part, data in pairs(self.Parts) do
        if part and part.Parent then
            local current = currentDance.Steps(data, self.DanceTime, self.GroupCenter)
            local next = nextDance.Steps(data, self.DanceTime, self.GroupCenter)
            
            local blend = math.clamp((self.DanceTime % currentDance.Duration) / currentDance.Duration, 0, 1)
            local finalPos = current.Position:Lerp(next.Position, blend)
            local finalRot = Vector3.new(
                current.Rotation.X + (next.Rotation.X - current.Rotation.X) * blend,
                current.Rotation.Y + (next.Rotation.Y - current.Rotation.Y) * blend,
                current.Rotation.Z + (next.Rotation.Z - current.Rotation.Z) * blend
            )
            
            data.AlignPosition.Position = finalPos
            data.Gyro.CFrame = CFrame.new(finalPos) * CFrame.Angles(
                math.rad(finalRot.X),
                math.rad(finalRot.Y),
                math.rad(finalRot.Z)
            )
            
            part.Velocity = (finalPos - part.Position) * 10
        else
            self.Parts[part] = nil
        end
    end
end

-- Random Mode Toggle
local RandomMode = false

-- Main Update Loop
RunService.Heartbeat:Connect(function()
    if Dancing then
        DanceSystem.DanceTime = DanceSystem.DanceTime + 0.03
        
        if RandomMode and DanceSystem.DanceTime >= DanceMoves[DanceSystem.CurrentDance].Duration then
            DanceSystem.CurrentDance = math.random(1, #DanceMoves)
            DanceSystem.DanceTime = 0
        elseif not RandomMode and DanceSystem.DanceTime >= DanceMoves[DanceSystem.CurrentDance].Duration then
            DanceSystem.DanceTime = 0
        end
        
        sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
        DanceSystem:AnimateParts()
    end
end)

-- Initialize Parts
for _, part in ipairs(workspace:GetDescendants()) do
    DanceSystem:SetupPart(part)
end

workspace.DescendantAdded:Connect(function(part)
    DanceSystem:SetupPart(part)
end)

-- ============================================
-- MODERN DARK GUI WITH BLUE SKY STROKE
-- ============================================

local gui = Instance.new("ScreenGui")
gui.Name = "SiextherDanceGUI"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 220, 0, 180)
mainFrame.Position = UDim2.new(0.5, -110, 0.5, -90)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = false
mainFrame.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Blue Sky Stroke (Outer Frame Only)
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(70, 130, 255)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 32)
header.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 10)
headerFix.Position = UDim2.new(0, 0, 1, -10)
headerFix.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -70, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "SIEXTHER SHAKE"
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextColor3 = Color3.fromRGB(70, 130, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, 24, 0, 24)
minimizeBtn.Position = UDim2.new(1, -58, 0.5, -12)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
minimizeBtn.Text = "─"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 14
minimizeBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = header

local minimizeBtnCorner = Instance.new("UICorner")
minimizeBtnCorner.CornerRadius = UDim.new(0, 5)
minimizeBtnCorner.Parent = minimizeBtn

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -28, 0.5, -12)
closeBtn.BackgroundColor3 = Color3.fromRGB(30, 25, 25)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
closeBtn.BorderSizePixel = 0
closeBtn.Parent = header

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 5)
closeBtnCorner.Parent = closeBtn

-- Content Frame
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -20, 1, -42)
content.Position = UDim2.new(0, 10, 0, 36)
content.BackgroundTransparency = 1
content.Parent = mainFrame

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Size = UDim2.new(1, 0, 0, 18)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "STATUS: ACTIVATED"
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 10
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = content

-- Current Dance Label
local danceLabel = Instance.new("TextLabel")
danceLabel.Name = "DanceLabel"
danceLabel.Size = UDim2.new(1, 0, 0, 16)
danceLabel.Position = UDim2.new(0, 0, 0, 20)
danceLabel.BackgroundTransparency = 1
danceLabel.Text = "SHAKE: " .. DanceMoves[1].Name
danceLabel.Font = Enum.Font.Gotham
danceLabel.TextSize = 9
danceLabel.TextColor3 = Color3.fromRGB(150, 180, 220)
danceLabel.TextXAlignment = Enum.TextXAlignment.Left
danceLabel.Parent = content

-- Toggle Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleBtn"
toggleBtn.Size = UDim2.new(1, 0, 0, 28)
toggleBtn.Position = UDim2.new(0, 0, 0, 42)
toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
toggleBtn.Text = "SHAKE PARTS"
toggleBtn.Font = Enum.Font.GothamSemibold
toggleBtn.TextSize = 11
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = content

local toggleBtnCorner = Instance.new("UICorner")
toggleBtnCorner.CornerRadius = UDim.new(0, 6)
toggleBtnCorner.Parent = toggleBtn

-- Next Dance Button
local nextDanceBtn = Instance.new("TextButton")
nextDanceBtn.Name = "NextDanceBtn"
nextDanceBtn.Size = UDim2.new(1, 0, 0, 28)
nextDanceBtn.Position = UDim2.new(0, 0, 0, 76)
nextDanceBtn.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
nextDanceBtn.Text = "NEXT SHAKE"
nextDanceBtn.Font = Enum.Font.GothamSemibold
nextDanceBtn.TextSize = 11
nextDanceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
nextDanceBtn.BorderSizePixel = 0
nextDanceBtn.Parent = content

local nextDanceBtnCorner = Instance.new("UICorner")
nextDanceBtnCorner.CornerRadius = UDim.new(0, 6)
nextDanceBtnCorner.Parent = nextDanceBtn

-- Random Mode Button
local randomBtn = Instance.new("TextButton")
randomBtn.Name = "RandomBtn"
randomBtn.Size = UDim2.new(1, 0, 0, 28)
randomBtn.Position = UDim2.new(0, 0, 0, 110)
randomBtn.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
randomBtn.Text = "RANDOM: OFF"
randomBtn.Font = Enum.Font.GothamSemibold
randomBtn.TextSize = 11
randomBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
randomBtn.BorderSizePixel = 0
randomBtn.Parent = content

local randomBtnCorner = Instance.new("UICorner")
randomBtnCorner.CornerRadius = UDim.new(0, 6)
randomBtnCorner.Parent = randomBtn

-- Minimized Button (Skull Icon)
local minimizedBtn = Instance.new("TextButton")
minimizedBtn.Name = "MinimizedBtn"
minimizedBtn.Size = UDim2.new(0, 41, 0, 41)
minimizedBtn.Position = UDim2.new(1, -60, 0, 15)
minimizedBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
minimizedBtn.Text = "☠️"
minimizedBtn.Font = Enum.Font.GothamBold
minimizedBtn.TextSize = 20
minimizedBtn.BorderSizePixel = 0
minimizedBtn.Visible = false
minimizedBtn.Active = true
minimizedBtn.Draggable = true
minimizedBtn.Parent = gui
minimizedBtn.ZIndex = 5

local minimizedBtnCorner = Instance.new("UICorner")
minimizedBtnCorner.CornerRadius = UDim.new(0, 12)
minimizedBtnCorner.Parent = minimizedBtn


-- ============================================
-- DRAG FUNCTIONALITY
-- ============================================

local dragging = false
local dragInput, mousePos, framePos

local function updateInput(input)
    local delta = input.Position - mousePos
    mainFrame.Position = UDim2.new(
        framePos.X.Scale,
        framePos.X.Offset + delta.X,
        framePos.Y.Scale,
        framePos.Y.Offset + delta.Y
    )
end

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        mousePos = input.Position
        framePos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateInput(input)
    end
end)

-- ============================================
-- BUTTON FUNCTIONS
-- ============================================

-- Toggle Dancing
toggleBtn.MouseButton1Click:Connect(function()
    Dancing = not Dancing
    if Dancing then
        statusLabel.Text = "STATUS: ACTIVATED"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(25, 35, 45)
    else
        statusLabel.Text = "STATUS: OFF"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(35, 20, 20)
    end
end)

-- Next Dance
nextDanceBtn.MouseButton1Click:Connect(function()
    if not RandomMode then
        DanceSystem.CurrentDance = DanceSystem.CurrentDance % #DanceMoves + 1
        DanceSystem.DanceTime = 0
        danceLabel.Text = "SHAKE: " .. DanceMoves[DanceSystem.CurrentDance].Name
    end
end)

-- Random Mode Toggle
randomBtn.MouseButton1Click:Connect(function()
    RandomMode = not RandomMode
    if RandomMode then
        randomBtn.Text = "RANDOM: ON"
        randomBtn.BackgroundColor3 = Color3.fromRGB(30, 25, 40)
        nextDanceBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
    else
        randomBtn.Text = "RANDOM: OFF"
        randomBtn.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
        nextDanceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end)

-- Minimize
minimizeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    minimizedBtn.Visible = true
end)

-- Restore from minimize
minimizedBtn.MouseButton1Click:Connect(function()
    minimizedBtn.Visible = false
    mainFrame.Visible = true
end)

-- Close
closeBtn.MouseButton1Click:Connect(function()
    Dancing = false
    gui:Destroy()
end)

-- Hover Effects
local function addHoverEffect(button)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(35, 45, 60)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(20, 25, 35)
        }):Play()
    end)
end

addHoverEffect(toggleBtn)
addHoverEffect(nextDanceBtn)
addHoverEffect(randomBtn)

-- Update dance label continuously
spawn(function()
    while wait(0.1) do
        if gui.Parent then
            danceLabel.Text = "SHAKE: " .. DanceMoves[DanceSystem.CurrentDance].Name
        else
            break
        end
    end
end)
