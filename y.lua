
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local Folder = Instance.new("Folder", Workspace)
local Part = Instance.new("Part", Folder)
local Attachment1 = Instance.new("Attachment", Part)
Part.Anchored = true
Part.CanCollide = false
Part.Transparency = 1

-- Network setup from second script (orbit script)
local getpart = 300
local currentMode = 2
local orbitRadius = 50
local orbitSpeed = 2
local isActive = true
local lastValidPosition = Vector3.new(0, 0, 0)
local UPDATE_INTERVAL = 0
local lastUpdate = tick()
local ringParts = {}

if not getgenv().Network then
    getgenv().Network = {
        BaseParts = {},
        FPS = 20,
        Velocity = Vector3.new(25.1, 0, 0)
    }
    
    local function EnableNetwork()
        local function UpdateNetwork()
            if not isActive then return end
            pcall(function()
                sethiddenproperty(LocalPlayer, "MaxSimulationRadius", getpart)
                sethiddenproperty(LocalPlayer, "SimulationRadius", getpart)
            end)
            local partsToProcess = {}
            for part in pairs(Network.BaseParts) do
                table.insert(partsToProcess, part)
            end
            for _, part in ipairs(partsToProcess) do
                if not part or not part.Parent then
                    Network.BaseParts[part] = nil
                    continue
                end
                pcall(function()
                    sethiddenproperty(part, "NetworkOwnership", Enum.NetworkOwnership.Manual)
                    sethiddenproperty(part, "CustomPhysicalProperties", PhysicalProperties.new(0.7, 0.3, 0.5))
                    part.Velocity = Network.Velocity
                end)
            end
        end
        RunService.Heartbeat:Connect(UpdateNetwork)
    end
    EnableNetwork()
end

-- PartOrbit Functions
local function processPart(part)
    if part:IsA("Part") and not part.Anchored and 
       not part.Parent:FindFirstChild("Humanoid") and 
       not part.Parent:FindFirstChild("Head") and 
       part.Name ~= "Handle" then
        
        if not pcall(function() return part.Parent end) then
            return nil
        end
        
        for _, child in pairs(part:GetChildren()) do
            if child:IsA("BodyAngularVelocity") or child:IsA("BodyForce") or 
               child:IsA("BodyGyro") or child:IsA("BodyPosition") or 
               child:IsA("BodyThrust") or child:IsA("BodyVelocity") or 
               child:IsA("RocketPropulsion") or child:IsA("Attachment") or 
               child:IsA("AlignPosition") or child:IsA("AlignOrientation") or 
               child:IsA("LinearVelocity") or child:IsA("BodyMover") then
                child:Destroy()
            end
        end
        
        part.CanCollide = false
        part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        
        local attachment = Instance.new("Attachment", part)
        local alignPos = Instance.new("AlignPosition", part)
        alignPos.Attachment0 = attachment
        alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
        alignPos.Responsiveness = 200
        
        return {
            part = part,
            align = alignPos,
            index = 0
        }
    end
    return nil
end

local function calculateRingPosition(index, totalParts, center)
    local angle = (index / totalParts) * (2 * math.pi) + tick() * orbitSpeed
    local offsetX, offsetY, offsetZ = 0, 0, 0
    
    if currentMode == 2 then
        offsetX = math.cos(angle) * orbitRadius
        offsetZ = math.sin(angle) * orbitRadius
    end
    
    return center + Vector3.new(offsetX, offsetY, offsetZ)
end

local function updateRingPositions()
    if not isActive then return end
    local currentTime = tick()
    if currentTime - lastUpdate < UPDATE_INTERVAL then return end
    lastUpdate = currentTime
    local position = (humanoidRootPart and humanoidRootPart.Position) or lastValidPosition
    if position then
        lastValidPosition = position
        local totalParts = #ringParts
        for i = #ringParts, 1, -1 do
            local data = ringParts[i]
            local validPart = pcall(function() return data.part.Parent ~= nil end)
            if validPart then
                local targetPos = calculateRingPosition(i, totalParts, position)
                data.align.Position = targetPos
            else
                Network.BaseParts[data.part] = nil
                table.remove(ringParts, i)
            end
        end
    end
end



-- COMPACT MODERN DARK GUI WITH BLUE STROKE (SMALLER)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SuperRingPartsGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame (Even smaller size)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 180, 0, 130)
MainFrame.Position = UDim2.new(0.5, -90, 0.5, -65)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BackgroundTransparency = 0
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Blue Stroke
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(70, 130, 255)
UIStroke.Thickness = 2
UIStroke.Parent = MainFrame

-- Title bar
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.6, 0, 0, 32)
Title.Position = UDim2.new(0, 8, 0, 0)
Title.Text = "SIEXTHER RING"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BorderSizePixel = 0
Title.Parent = MainFrame

-- Close button (X)
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 22, 0, 22)
CloseButton.Position = UDim2.new(1, -27, 0, 5)
CloseButton.Text = "X"
CloseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
CloseButton.BackgroundTransparency = 0
CloseButton.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 12
CloseButton.BorderSizePixel = 0
CloseButton.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(1, 0)
CloseCorner.Parent = CloseButton

-- Minimize button (-)
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 22, 0, 22)
MinimizeButton.Position = UDim2.new(1, -54, 0, 5)
MinimizeButton.Text = "–"
MinimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
MinimizeButton.BackgroundTransparency = 0
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 14
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Parent = MainFrame

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(1, 0)
MinimizeCorner.Parent = MinimizeButton

-- Floating Button (top right corner)
local FloatingButton = Instance.new("TextButton")
FloatingButton.Size = UDim2.new(0, 38, 0, 38)
FloatingButton.Position = UDim2.new(1, -55, 0, 15)
FloatingButton.Text = "💫"
FloatingButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
FloatingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingButton.Font = Enum.Font.GothamBold
FloatingButton.TextSize = 18
FloatingButton.BorderSizePixel = 0
FloatingButton.Visible = false
FloatingButton.Parent = ScreenGui
FloatingButton.ZIndex = 5

local FloatingCorner = Instance.new("UICorner")
FloatingCorner.CornerRadius = UDim.new(0, 10)
FloatingCorner.Parent = FloatingButton

-- Toggle button
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0.85, 0, 0, 30)
ToggleButton.Position = UDim2.new(0.075, 0, 0.29, 0)
ToggleButton.Text = "RING | OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(238, 0, 0)
ToggleButton.BackgroundTransparency = 0
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 12
ToggleButton.BorderSizePixel = 0
ToggleButton.Parent = MainFrame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleButton

-- Radius Controls
local DecreaseRadius = Instance.new("TextButton")
DecreaseRadius.Size = UDim2.new(0.22, 0, 0, 30)
DecreaseRadius.Position = UDim2.new(0.075, 0, 0.65, 0)
DecreaseRadius.Text = "<"
DecreaseRadius.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
DecreaseRadius.BackgroundTransparency = 0
DecreaseRadius.TextColor3 = Color3.fromRGB(70, 130, 255)
DecreaseRadius.Font = Enum.Font.GothamBold
DecreaseRadius.TextSize = 16
DecreaseRadius.BorderSizePixel = 0
DecreaseRadius.Parent = MainFrame

local DecreaseCorner = Instance.new("UICorner")
DecreaseCorner.CornerRadius = UDim.new(0, 8)
DecreaseCorner.Parent = DecreaseRadius

local IncreaseRadius = Instance.new("TextButton")
IncreaseRadius.Size = UDim2.new(0.22, 0, 0, 30)
IncreaseRadius.Position = UDim2.new(0.705, 0, 0.65, 0)
IncreaseRadius.Text = ">"
IncreaseRadius.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
IncreaseRadius.BackgroundTransparency = 0
IncreaseRadius.TextColor3 = Color3.fromRGB(70, 130, 255)
IncreaseRadius.Font = Enum.Font.GothamBold
IncreaseRadius.TextSize = 16
IncreaseRadius.BorderSizePixel = 0
IncreaseRadius.Parent = MainFrame

local IncreaseCorner = Instance.new("UICorner")
IncreaseCorner.CornerRadius = UDim.new(0, 8)
IncreaseCorner.Parent = IncreaseRadius

local RadiusDisplay = Instance.new("TextLabel")
RadiusDisplay.Size = UDim2.new(0.42, 0, 0, 30)
RadiusDisplay.Position = UDim2.new(0.29, 0, 0.65, 0)
RadiusDisplay.Text = "Radius: 8"
RadiusDisplay.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
RadiusDisplay.BackgroundTransparency = 0
RadiusDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
RadiusDisplay.Font = Enum.Font.GothamBold
RadiusDisplay.TextSize = 11
RadiusDisplay.BorderSizePixel = 0
RadiusDisplay.Parent = MainFrame

local RadiusCorner = Instance.new("UICorner")
RadiusCorner.CornerRadius = UDim.new(0, 8)
RadiusCorner.Parent = RadiusDisplay

-- Close button functionality
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    ringPartsEnabled = false
    parts = {}
    isActive = false
    
end)

-- Minimize Functionality
local minimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame.Visible = false
        FloatingButton.Visible = true
    else
        MainFrame.Visible = true
        FloatingButton.Visible = false
    end
end)

-- Floating button restore
FloatingButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    FloatingButton.Visible = false
    minimized = false
end)

-- Draggable GUI (MainFrame)
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Draggable Floating Button
local floatingDragging, floatingDragInput, floatingDragStart, floatingStartPos
local function updateFloating(input)
    local delta = input.Position - floatingDragStart
    FloatingButton.Position = UDim2.new(floatingStartPos.X.Scale, floatingStartPos.X.Offset + delta.X, floatingStartPos.Y.Scale, floatingStartPos.Y.Offset + delta.Y)
end
FloatingButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        floatingDragging = true
        floatingDragStart = input.Position
        floatingStartPos = FloatingButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                floatingDragging = false
            end
        end)
    end
end)
FloatingButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        floatingDragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == floatingDragInput and floatingDragging then
        updateFloating(input)
    end
end)

-- Ring Parts Logic
local radius = 8
local height = 100
local rotationSpeed = 1
local attractionStrength = 1000
local ringPartsEnabled = false

local function RetainPart(Part)
    if Part:IsA("BasePart") and not Part.Anchored and Part:IsDescendantOf(workspace) then
        if Part.Parent == LocalPlayer.Character or Part:IsDescendantOf(LocalPlayer.Character) then
            return false
        end

        Part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        Part.CanCollide = false
        return true
    end
    return false
end

local parts = {}
local function addPart(part)
    if RetainPart(part) then
        if not table.find(parts, part) then
            table.insert(parts, part)
        end
    end
end

local function removePart(part)
    local index = table.find(parts, part)
    if index then
        table.remove(parts, index)
    end
end

for _, part in pairs(workspace:GetDescendants()) do
    addPart(part)
end

workspace.DescendantAdded:Connect(addPart)
workspace.DescendantRemoving:Connect(removePart)

RunService.Heartbeat:Connect(function()
    if not ringPartsEnabled then return end
    
    local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local tornadoCenter = humanoidRootPart.Position
        for _, part in pairs(parts) do
            if part.Parent and not part.Anchored then
                local pos = part.Position
                local distance = (Vector3.new(pos.X, tornadoCenter.Y, pos.Z) - tornadoCenter).Magnitude
                local angle = math.atan2(pos.Z - tornadoCenter.Z, pos.X - tornadoCenter.X)
                local newAngle = angle + math.rad(rotationSpeed)
                local targetPos = Vector3.new(
                    tornadoCenter.X + math.cos(newAngle) * math.min(radius, distance),
                    tornadoCenter.Y + (height * (math.abs(math.sin((pos.Y - tornadoCenter.Y) / height)))),
                    tornadoCenter.Z + math.sin(newAngle) * math.min(radius, distance)
                )
                local directionToTarget = (targetPos - part.Position).unit
                part.Velocity = directionToTarget * attractionStrength
            end
        end
    end
end)

-- Button functionality
ToggleButton.MouseButton1Click:Connect(function()
    ringPartsEnabled = not ringPartsEnabled
    ToggleButton.Text = ringPartsEnabled and "RING | ON" or "RING | OFF"
    ToggleButton.BackgroundColor3 = ringPartsEnabled and Color3.fromRGB(70, 130, 255)or Color3.fromRGB(238, 0, 0)
end)

DecreaseRadius.MouseButton1Click:Connect(function()
    radius = math.max(1, radius - 2)
    RadiusDisplay.Text = "Radius: " .. radius
end)

IncreaseRadius.MouseButton1Click:Connect(function()
    radius = math.min(1000, radius + 2)
    RadiusDisplay.Text = "Radius: " .. radius
end)

-- Update humanoidRootPart on character respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    wait(1)
    humanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)
