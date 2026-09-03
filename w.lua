-- Heavy Winds 2 GUI Script
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Variables from original script
local claimedParts = {}
local connection = nil
local heartbeatConnection = nil
local lastCleanupTime = 0
local cleanupInterval = 5
local partCheckCooldown = {}
local getpart = 300

-- Heavy Winds 2 Variables
local networkown = {}
local ohb = nil
local ts = 100  -- Wind Size
local ss = 100  -- Wind Speed
local cb = nil
local heavyWinds2Enabled = false

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HeavyWinds2GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = playerGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 260, 0, 215)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -107.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- UICorner for MainFrame
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- UIStroke for MainFrame (Blue Stroke)
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(70, 130, 255)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

-- Title Label
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Size = UDim2.new(1, -75, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "SIEXTHER TORNADO"
TitleLabel.TextColor3 = Color3.fromRGB(70, 130, 255)
TitleLabel.TextSize = 15
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Minimize Button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 30, 0, 26)
MinimizeBtn.Position = UDim2.new(1, -63, 0, 5)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Text = "–"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 13
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = TitleBar

local MinBtnCorner = Instance.new("UICorner")
MinBtnCorner.CornerRadius = UDim.new(0, 6)
MinBtnCorner.Parent = MinimizeBtn

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 30, 0, 26)
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar

local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 6)
CloseBtnCorner.Parent = CloseBtn

-- Content Frame
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -18, 1, -52)
ContentFrame.Position = UDim2.new(0, 9, 0, 43)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Toggle Button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(1, 0, 0, 36)
ToggleBtn.Position = UDim2.new(0, 0, 0, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "AKTIFKAN"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 13
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = ContentFrame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleBtn

-- Wind Size Section
local SizeLabel = Instance.new("TextLabel")
SizeLabel.Name = "SizeLabel"
SizeLabel.Size = UDim2.new(1, 0, 0, 20)
SizeLabel.Position = UDim2.new(0, 0, 0, 46)
SizeLabel.BackgroundTransparency = 1
SizeLabel.Text = "Radius: " .. ts
SizeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SizeLabel.TextSize = 12
SizeLabel.Font = Enum.Font.GothamSemibold
SizeLabel.TextXAlignment = Enum.TextXAlignment.Left
SizeLabel.Parent = ContentFrame

-- Wind Size Slider (Thicker and wider)
local SizeSliderBg = Instance.new("Frame")
SizeSliderBg.Name = "SizeSliderBg"
SizeSliderBg.Size = UDim2.new(0.6, 0, 0, 8)  -- Increased from 4 to 8
SizeSliderBg.Position = UDim2.new(0, 0, 0, 70)
SizeSliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
SizeSliderBg.BorderSizePixel = 0
SizeSliderBg.Parent = ContentFrame

local SizeSliderBgCorner = Instance.new("UICorner")
SizeSliderBgCorner.CornerRadius = UDim.new(0, 4)  -- Adjusted for board-like appearance
SizeSliderBgCorner.Parent = SizeSliderBg

local SizeSliderFill = Instance.new("Frame")
SizeSliderFill.Name = "Fill"
SizeSliderFill.Size = UDim2.new(ts / 500, 0, 1, 0)
SizeSliderFill.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
SizeSliderFill.BorderSizePixel = 0
SizeSliderFill.Parent = SizeSliderBg

local SizeSliderFillCorner = Instance.new("UICorner")
SizeSliderFillCorner.CornerRadius = UDim.new(1, 0)
SizeSliderFillCorner.Parent = SizeSliderFill

-- Wind Size TextBox
local SizeTextBox = Instance.new("TextBox")
SizeTextBox.Name = "SizeTextBox"
SizeTextBox.Size = UDim2.new(0.35, 0, 0, 26)
SizeTextBox.Position = UDim2.new(0.63, 0, 0, 64)
SizeTextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
SizeTextBox.BorderSizePixel = 0
SizeTextBox.Text = tostring(ts)
SizeTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SizeTextBox.TextSize = 12
SizeTextBox.Font = Enum.Font.GothamSemibold
SizeTextBox.PlaceholderText = "5-500"
SizeTextBox.ClearTextOnFocus = false
SizeTextBox.Parent = ContentFrame

local SizeTextBoxCorner = Instance.new("UICorner")
SizeTextBoxCorner.CornerRadius = UDim.new(0, 6)
SizeTextBoxCorner.Parent = SizeTextBox

-- Wind Speed Section
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Name = "SpeedLabel"
SpeedLabel.Size = UDim2.new(1, 0, 0, 20)
SpeedLabel.Position = UDim2.new(0, 0, 0, 100)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Speed: " .. ss
SpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SpeedLabel.TextSize = 12
SpeedLabel.Font = Enum.Font.GothamSemibold
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent = ContentFrame

-- Wind Speed Slider (Thicker and wider)
local SpeedSliderBg = Instance.new("Frame")
SpeedSliderBg.Name = "SpeedSliderBg"
SpeedSliderBg.Size = UDim2.new(0.6, 0, 0, 8)  -- Increased from 4 to 8
SpeedSliderBg.Position = UDim2.new(0, 0, 0, 124)
SpeedSliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
SpeedSliderBg.BorderSizePixel = 0
SpeedSliderBg.Parent = ContentFrame

local SpeedSliderBgCorner = Instance.new("UICorner")
SpeedSliderBgCorner.CornerRadius = UDim.new(0, 4)  -- Adjusted for board-like appearance
SpeedSliderBgCorner.Parent = SpeedSliderBg

local SpeedSliderFill = Instance.new("Frame")
SpeedSliderFill.Name = "Fill"
SpeedSliderFill.Size = UDim2.new(ss / 1000, 0, 1, 0)
SpeedSliderFill.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
SpeedSliderFill.BorderSizePixel = 0
SpeedSliderFill.Parent = SpeedSliderBg

local SpeedSliderFillCorner = Instance.new("UICorner")
SpeedSliderFillCorner.CornerRadius = UDim.new(1, 0)
SpeedSliderFillCorner.Parent = SpeedSliderFill

-- Wind Speed TextBox
local SpeedTextBox = Instance.new("TextBox")
SpeedTextBox.Name = "SpeedTextBox"
SpeedTextBox.Size = UDim2.new(0.35, 0, 0, 26)
SpeedTextBox.Position = UDim2.new(0.63, 0, 0, 118)
SpeedTextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
SpeedTextBox.BorderSizePixel = 0
SpeedTextBox.Text = tostring(ss)
SpeedTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedTextBox.TextSize = 12
SpeedTextBox.Font = Enum.Font.GothamSemibold
SpeedTextBox.PlaceholderText = "1-1000"
SpeedTextBox.ClearTextOnFocus = false
SpeedTextBox.Parent = ContentFrame

local SpeedTextBoxCorner = Instance.new("UICorner")
SpeedTextBoxCorner.CornerRadius = UDim.new(0, 6)
SpeedTextBoxCorner.Parent = SpeedTextBox

-- Floating Button (Hidden initially)
local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Name = "FloatingBtn"
FloatingBtn.Size = UDim2.new(0, 41, 0, 41)
FloatingBtn.Position = UDim2.new(0, 15, 0, 60)
FloatingBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
FloatingBtn.BorderSizePixel = 0
FloatingBtn.Text = "🌪️"
FloatingBtn.TextSize = 20
FloatingBtn.Font = Enum.Font.GothamBold
FloatingBtn.Visible = false
FloatingBtn.Active = true
FloatingBtn.Draggable = true
FloatingBtn.Parent = ScreenGui
FloatingBtn.ZIndex = 5

local FloatingCorner = Instance.new("UICorner")
FloatingCorner.CornerRadius = UDim.new(0, 12)
FloatingCorner.Parent = FloatingBtn


-- PartClaim Function (from original script)
function pcz()
    pcall(function()
        sethiddenproperty(player, "SimulationRadius", getpart)
        sethiddenproperty(player, "MaxSimulationRadius", getpart)
        sethiddenproperty(player, "MaximumSimulationRadius", getpart)
        if game:GetService("NetworkClient") then
            game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.huge)
        end
    end)
    
    if heartbeatConnection then 
        heartbeatConnection:Disconnect() 
        heartbeatConnection = nil
    end
    
    if connection then 
        connection:Disconnect() 
        connection = nil
    end

    local MAX_PARTS_PER_FRAME = 10
    local NETWORK_UPDATE_INTERVAL = 3.0
    local FRAME_TIME = 1 / 60
    local lastFrameTime = tick()
    local lastNetworkUpdate = 0
    local CLEANUP_INTERVAL = 3
    local processedPartsCount = 0
    
    local function scanInitialParts()
        local character = player.Character
        local center = character and character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart.Position or Vector3.new(0, 0, 0)
        
        local parts = workspace:GetPartBoundsInRadius(center, getpart)
        local partsProcessed = 0
        local maxInitialParts = 40
        
        for i, part in ipairs(parts) do
            if partsProcessed >= maxInitialParts then break end
            
            if part and part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(player.Character) then
                if not claimedParts[part] then
                    claimedParts[part] = {
                        CanCollide = part.CanCollide,
                        claimed = true,
                        OriginalMassless = part.Massless,
                        lastNetworkCheck = 0
                    }
                    
                    pcall(function()
                        part.CanCollide = false
                        part.Massless = true
                        part.CustomPhysicalProperties = PhysicalProperties.new(0.001, 0.001, 0.001)
                        
                        if (part.Position - center).Magnitude < 100 then
                            pcall(function()
                                part:SetNetworkOwner(player)
                            end)
                        end
                        
                        for _, child in ipairs(part:GetChildren()) do
                            if child:IsA("Constraint") or child:IsA("BodyMover") then
                                child:Destroy()
                            end
                        end
                    end)
                    
                    partsProcessed = partsProcessed + 1
                end
            end
            
            if partsProcessed % 15 == 0 then
                RunService.Heartbeat:Wait()
            end
        end
    end
    
    scanInitialParts()
    
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        
        if currentTime - lastFrameTime < FRAME_TIME then return end
        lastFrameTime = currentTime
        
        if currentTime - lastNetworkUpdate >= NETWORK_UPDATE_INTERVAL then
            pcall(function()
                sethiddenproperty(player, "SimulationRadius", getpart)
                sethiddenproperty(player, "MaxSimulationRadius", getpart)
            end)
            lastNetworkUpdate = currentTime
        end
        
        if currentTime - lastCleanupTime >= cleanupInterval then
            local partsToRemove = {}
            for part, data in pairs(claimedParts) do
                if not part or not part.Parent then
                    table.insert(partsToRemove, part)
                end
            end
            for _, part in ipairs(partsToRemove) do
                claimedParts[part] = nil
            end
            lastCleanupTime = currentTime
        end
        
        local processed = 0
        local partsToRemove = {}
        
        for part, data in pairs(claimedParts) do
            if processed >= MAX_PARTS_PER_FRAME then break end
            
            if part and part.Parent then
                pcall(function()
                    local shouldCheckNetwork = (currentTime - data.lastNetworkCheck) > 5
                    
                    if shouldCheckNetwork then
                        local owner = part:GetNetworkOwner()
                        if owner ~= player then
                            pcall(function()
                                part:SetNetworkOwner(player)
                            end)
                        end
                        data.lastNetworkCheck = currentTime
                    end
                    
                    if part.CanCollide ~= false then part.CanCollide = false end
                    if part.Massless ~= true then part.Massless = true end
                    if part.Velocity.Magnitude > 5 then part.Velocity = part.Velocity * 0.9 end
                    if part.RotVelocity.Magnitude > 5 then part.RotVelocity = part.RotVelocity * 0.9 end
                    
                    processed = processed + 1
                end)
            else
                table.insert(partsToRemove, part)
            end
        end
        for _, part in ipairs(partsToRemove) do
            claimedParts[part] = nil
        end
    end)
    
    connection = workspace.DescendantAdded:Connect(function(part)
        if part and part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(player.Character) then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local distance = (part.Position - character.HumanoidRootPart.Position).Magnitude
                if distance > 200 then return end
            end
            task.wait(0.2)
            if not claimedParts[part] then
                claimedParts[part] = {
                    CanCollide = part.CanCollide,
                    claimed = true,
                    OriginalMassless = part.Massless,
                    lastNetworkCheck = 0
                }
                
                pcall(function()
                    part.CanCollide = false
                    part.Massless = true
                    part.CustomPhysicalProperties = PhysicalProperties.new(0.001, 0.001, 0.001)
                    task.spawn(function()
                        task.wait(0.5)
                        if part and part.Parent and claimedParts[part] then
                            pcall(function()
                                part:SetNetworkOwner(player)
                            end)
                        end
                    end)
                end)
            end
        end
    end)
end

-- Heavy Winds 2 Functions
local function retain(part)
    if part and part:IsA("BasePart") and not part.Anchored then
        local rt = {part.CanCollide, part.CanTouch, part.CustomPhysicalProperties}
        part.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 0, 0)
        part.CanCollide = false
        part.CanTouch = false
        return rt
    end
    return nil
end

local function dopart2(v)
    if v:IsA("BasePart") and not v.Anchored and not v:IsDescendantOf(player.Character) then
        local stuff = retain(v)
        if stuff then
            networkown[v] = {math.random(1,10000000)/100000, stuff[1], stuff[2], stuff[3]}
            
            if not v:FindFirstChild("bp") then
                local m = v:GetMass()
                local bp = Instance.new("BodyPosition")
                bp.Name = "bp"
                bp.P = m/0.64e-5
                bp.D = m/0.64e-3
                bp.MaxForce = Vector3.new(m/0.64e-6, m/0.64e-6, m/0.64e-6)
                bp.Parent = v
            end
        end
    end
end

local function scanParts()
    for i, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v.Anchored and not v:IsDescendantOf(player.Character) then
            dopart2(v)
        end
    end
end

local function startPartControl()
    if ohb then ohb:Disconnect() end
    
    ohb = RunService.Heartbeat:Connect(function(dt)
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local mpos = character.HumanoidRootPart.Position
            
            for part, data in pairs(networkown) do
                if part and part.Parent then
                    data[1] = data[1] + (dt * ss)
                    local bp = part:FindFirstChild("bp")
                    
                    if bp then
                        bp.Position = ((CFrame.new(mpos) * CFrame.Angles(0, data[1] * ss, 0)) * CFrame.new(0, data[1] % (ts) - 6, -ts + math.random(ts))).Position
                    end
                else
                    networkown[part] = nil
                end
            end
        end
    end)
end

local function stopPartControl()
    if ohb then
        ohb:Disconnect()
        ohb = nil
    end
    
    for part, data in pairs(networkown) do
        if part and part:FindFirstChild("bp") then
            part.bp:Destroy()
        end
    end
    networkown = {}
end

-- Initialize PartClaim
pcz()

-- Slider Functions
local function updateSizeSlider(value)
    ts = math.clamp(value, 5, 500)
    SizeLabel.Text = "Radius: " .. ts
    SizeTextBox.Text = tostring(ts)
    SizeSliderFill.Size = UDim2.new(ts / 500, 0, 1, 0)
end

local function updateSpeedSlider(value)
    ss = math.clamp(value, 1, 1000)
    SpeedLabel.Text = "Speed: " .. ss
    SpeedTextBox.Text = tostring(ss)
    SpeedSliderFill.Size = UDim2.new(ss / 1000, 0, 1, 0)
end

-- Slider Input
SizeSliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local function update()
            local mousePos = UserInputService:GetMouseLocation()
            local relativePos = mousePos.X - SizeSliderBg.AbsolutePosition.X
            local percentage = math.clamp(relativePos / SizeSliderBg.AbsoluteSize.X, 0, 1)
            updateSizeSlider(math.floor(percentage * 495) + 5)
        end
        
        update()
        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                connection:Disconnect()
            else
                update()
            end
        end)
    end
end)

SpeedSliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local function update()
            local mousePos = UserInputService:GetMouseLocation()
            local relativePos = mousePos.X - SpeedSliderBg.AbsolutePosition.X
            local percentage = math.clamp(relativePos / SpeedSliderBg.AbsoluteSize.X, 0, 1)
            updateSpeedSlider(math.floor(percentage * 999) + 1)
        end
        
        update()
        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                connection:Disconnect()
            else
                update()
            end
        end)
    end
end)

-- TextBox Input
SizeTextBox.FocusLost:Connect(function(enterPressed)
    local value = tonumber(SizeTextBox.Text)
    if value then
        updateSizeSlider(value)
    else
        SizeTextBox.Text = tostring(ts)
    end
end)

SpeedTextBox.FocusLost:Connect(function(enterPressed)
    local value = tonumber(SpeedTextBox.Text)
    if value then
        updateSpeedSlider(value)
    else
        SpeedTextBox.Text = tostring(ss)
    end
end)

-- Toggle Button
ToggleBtn.MouseButton1Click:Connect(function()
    heavyWinds2Enabled = not heavyWinds2Enabled
    
    if heavyWinds2Enabled then
        cb = "tornado"
        scanParts()
        startPartControl()
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        ToggleBtn.Text = "TORNADO : ON"
    else
        cb = nil
        stopPartControl()
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        ToggleBtn.Text = "TORNADO : OFF"
    end
end)

-- Minimize Button
MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    FloatingBtn.Visible = true
end)

-- Floating Button
FloatingBtn.MouseButton1Click:Connect(function()
    FloatingBtn.Visible = false
    MainFrame.Visible = true
end)

-- Close Button
CloseBtn.MouseButton1Click:Connect(function()
    if heavyWinds2Enabled then
        stopPartControl()
    end
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
    end
    if connection then
        connection:Disconnect()
    end
    ScreenGui:Destroy()
end)