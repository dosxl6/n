
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Settings = {
    BringPartRadius = 100,
    BringPartSpeed = 200,
    UnanchorRadius = 500,
    PositionMode = "torso"
}


local aktif = false
local character, humanoidRootPart, torso, head

local folder, attachment1, koneksi1

local blackHoleActive = false
local DescendantAddedConnection
local NetworkConnection
local BringFolder, TargetPart, Attachment1

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SiextherChoticHan"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 200)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -100)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = MainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(70, 130, 255)
mainStroke.Thickness = 2
mainStroke.Parent = MainFrame

-- Navbar
local Navbar = Instance.new("Frame")
Navbar.Size = UDim2.new(1, 0, 0, 30)
Navbar.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
Navbar.Parent = MainFrame

local navCorner = Instance.new("UICorner")
navCorner.CornerRadius = UDim.new(0, 10)
navCorner.Parent = Navbar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -65, 1, 0)
TitleLabel.Position = UDim2.new(0, 8, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "SIEXTHER CHAOTIC"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.TextColor3 = Color3.fromRGB(70, 130, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Navbar

local TitleGradient = Instance.new("UIGradient")
TitleGradient.Parent = TitleLabel
TitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
TitleGradient.Offset = Vector2.new(-1, 0)

task.spawn(function()
    while TitleLabel and TitleLabel.Parent do
        TweenService:Create(TitleGradient, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(1, 0)
        }):Play()
        task.wait(2)
        
        TweenService:Create(TitleGradient, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(-1, 0)
        }):Play()
        task.wait(2)
    end
end)

-- Minimize Button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 24, 0, 24)
MinimizeBtn.Position = UDim2.new(1, -56, 0.5, -12)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MinimizeBtn.Text = "–"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 16
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Parent = Navbar

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 5)
minimizeCorner.Parent = MinimizeBtn

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -28, 0.5, -12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Parent = Navbar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = CloseBtn

-- Mini Frame
local MiniFrame = Instance.new("TextButton")
MiniFrame.Size = UDim2.new(0, 41, 0, 41)
MiniFrame.Position = UDim2.new(0, 15, 0.5, -22)
MiniFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MiniFrame.Text = "SX"
MiniFrame.Font = Enum.Font.GothamBold
MiniFrame.TextSize = 25
MiniFrame.TextColor3 = Color3.fromRGB(70, 130, 255)
MiniFrame.Visible = false
MiniFrame.Active = true
MiniFrame.Draggable = true
MiniFrame.Parent = ScreenGui

local MinimizedGradient = Instance.new("UIGradient")
MinimizedGradient.Parent = MiniFrame
MinimizedGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
MinimizedGradient.Offset = Vector2.new(-1, 0)

task.spawn(function()
    while MiniFrame and MiniFrame.Parent do
        TweenService:Create(MinimizedGradient, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(1, 0)
        }):Play()
        task.wait(2)
        
        TweenService:Create(MinimizedGradient, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(-1, 0)
        }):Play()
        task.wait(2)
    end
end)

local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(0, 12)
miniCorner.Parent = MiniFrame

-- Content Container
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -16, 1, -40)
Content.Position = UDim2.new(0, 8, 0, 35)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- Toggle Button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, 0, 0, 38)
ToggleBtn.Position = UDim2.new(0, 0, 0, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
ToggleBtn.Text = "SIEXTHER | OFF"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Parent = Content

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 7)
toggleCorner.Parent = ToggleBtn

-- Mode Label
local ModeLabel = Instance.new("TextLabel")
ModeLabel.Size = UDim2.new(1, 0, 0, 18)
ModeLabel.Position = UDim2.new(0, 0, 0, 48)
ModeLabel.BackgroundTransparency = 1
ModeLabel.Text = "MODE POSISI: BADAN"
ModeLabel.Font = Enum.Font.GothamBold
ModeLabel.TextSize = 11
ModeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
ModeLabel.TextXAlignment = Enum.TextXAlignment.Left
ModeLabel.Parent = Content

-- Mode Buttons Container
local ModeContainer = Instance.new("Frame")
ModeContainer.Size = UDim2.new(1, 0, 0, 70)
ModeContainer.Position = UDim2.new(0, 0, 0, 68)
ModeContainer.BackgroundTransparency = 1
ModeContainer.Parent = Content

-- Function to create mode button
local function createModeButton(text, position, mode)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.48, 0, 0, 32)
    btn.Position = position
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Parent = ModeContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        Settings.PositionMode = mode
        
        -- Update all buttons
        for _, child in pairs(ModeContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            end
        end
        
        -- Highlight selected
        btn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        
        -- Update label
        local modeText = {
            torso = "BADAN",
            head = "KEPALA",
            feet = "KAKI",
            front = "DEPAN"
        }
        ModeLabel.Text = "MODE POSISI: " .. modeText[mode]
    end)
    
    return btn
end

-- Create 4 mode buttons
local TorsoBtn = createModeButton("BADAN", UDim2.new(0, 0, 0, 0), "torso")
local HeadBtn = createModeButton("KEPALA", UDim2.new(0.52, 0, 0, 0), "head")
local FeetBtn = createModeButton("KAKI", UDim2.new(0, 0, 0, 38), "feet")
local FrontBtn = createModeButton("DEPAN", UDim2.new(0.52, 0, 0, 38), "front")

-- Set default selected
TorsoBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)

local FooterText1 = Instance.new("TextLabel")
FooterText1.Size = UDim2.new(1, 0, 0, 16)
FooterText1.Position = UDim2.new(0, 0, 1, -16)
FooterText1.BackgroundTransparency = 1
FooterText1.Text = "SIEXTHER"
FooterText1.Font = Enum.Font.GothamBold
FooterText1.TextSize = 12
FooterText1.TextColor3 = Color3.fromRGB(255, 255, 255)
FooterText1.TextTransparency = 0
FooterText1.Parent = Content

local FooterGradient1 = Instance.new("UIGradient")
FooterGradient1.Parent = FooterText1
FooterGradient1.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
FooterGradient1.Offset = Vector2.new(-1, 0)

local FooterText2 = Instance.new("TextLabel")
FooterText2.Size = UDim2.new(1, 0, 0, 16)
FooterText2.Position = UDim2.new(0, 0, 1, -16)
FooterText2.BackgroundTransparency = 1
FooterText2.Text = "PILIH MODE SESUKA KALIAN"
FooterText2.Font = Enum.Font.GothamBold
FooterText2.TextSize = 12
FooterText2.TextColor3 = Color3.fromRGB(255, 255, 255)
FooterText2.TextTransparency = 1
FooterText2.Parent = Content

local FooterGradient2 = Instance.new("UIGradient")
FooterGradient2.Parent = FooterText2
FooterGradient2.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
FooterGradient2.Offset = Vector2.new(-1, 0)

-- Footer Animation
task.spawn(function()
    while FooterText1 and FooterText1.Parent do
        TweenService:Create(FooterText1, TweenInfo.new(1, Enum.EasingStyle.Sine), {TextTransparency = 0}):Play()
        TweenService:Create(FooterText2, TweenInfo.new(1, Enum.EasingStyle.Sine), {TextTransparency = 1}):Play()
        
        TweenService:Create(FooterGradient1, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(1, 0)
        }):Play()
        task.wait(3)
        
        TweenService:Create(FooterGradient1, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(-1, 0)
        }):Play()
        task.wait(2)
        
        TweenService:Create(FooterText1, TweenInfo.new(1, Enum.EasingStyle.Sine), {TextTransparency = 1}):Play()
        task.wait(1)
        
        TweenService:Create(FooterText2, TweenInfo.new(1, Enum.EasingStyle.Sine), {TextTransparency = 0}):Play()
        
        TweenService:Create(FooterGradient2, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(1, 0)
        }):Play()
        task.wait(3)
        
        TweenService:Create(FooterGradient2, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(-1, 0)
        }):Play()
        task.wait(2)
        
        TweenService:Create(FooterText2, TweenInfo.new(1, Enum.EasingStyle.Sine), {TextTransparency = 1}):Play()
        task.wait(1)
    end
end)

local function getTargetPosition()
    if not character then return nil end
    
    if Settings.PositionMode == "torso" then
        return torso and torso.CFrame
    elseif Settings.PositionMode == "head" then
        return head and head.CFrame
    elseif Settings.PositionMode == "feet" then
        if humanoidRootPart then
            return humanoidRootPart.CFrame * CFrame.new(0, -3, 0)
        end
    elseif Settings.PositionMode == "front" then
        if humanoidRootPart then
            return humanoidRootPart.CFrame * CFrame.new(0, 0, -5)
        end
    end
    
    return torso and torso.CFrame
end

local function scanParts()
    local parts = {}
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return parts end

    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") 
        and not part.Anchored 
        and not part:IsDescendantOf(character) then
            local dist = (part.Position - root.Position).Magnitude
            if dist <= Settings.UnanchorRadius then
                table.insert(parts, part)
            end
        end
    end
    return parts
end

local function applyForce(part)
    if not part or not part.Parent then return end
    part.CanCollide = false

    for _, x in next, part:GetChildren() do
        if x:IsA("BodyAngularVelocity") or x:IsA("BodyForce") or x:IsA("BodyGyro") 
        or x:IsA("BodyPosition") or x:IsA("BodyThrust") or x:IsA("BodyVelocity")
        or x:IsA("RocketPropulsion") then
            x:Destroy()
        end
    end

    if not part:FindFirstChildOfClass("Torque") then
        local torque = Instance.new("Torque", part)
        torque.Torque = Vector3.new(100000,100000,100000)
        local align = Instance.new("AlignPosition", part)
        local at2 = Instance.new("Attachment", part)
        torque.Attachment0 = at2
        align.MaxForce = 9e15
        align.MaxVelocity = math.huge
        align.Responsiveness = 200
        align.Attachment0 = at2
        if attachment1 then
            align.Attachment1 = attachment1
        end
    end

    if attachment1 then
        local dist = (part.Position - attachment1.WorldPosition).Magnitude
        if dist <= Settings.UnanchorRadius then
            local arah = (attachment1.WorldPosition - part.Position).Unit
            part.AssemblyLinearVelocity = arah * 200
        end
    end
end

local function mulaiUnanchor()
    folder = Instance.new("Folder", workspace)
    local part = Instance.new("Part", folder)
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    attachment1 = Instance.new("Attachment", part)

    task.spawn(function()
        settings().Physics.AllowSleep = false
        while aktif and task.wait() do
            for _, pl in next, game.Players:GetPlayers() do
                if pl ~= LocalPlayer then
                    pl.MaximumSimulationRadius = 0
                    sethiddenproperty(pl, "SimulationRadius", 0)
                end
            end
            LocalPlayer.MaximumSimulationRadius = math.pow(math.huge, math.huge)
            setsimulationradius(math.huge)
        end
    end)

    koneksi1 = RunService.Stepped:Connect(function()
        local list = scanParts()
        for _, v in pairs(list) do
            applyForce(v)
        end
    end)
end

local function stopUnanchor()
    if koneksi1 then koneksi1:Disconnect() end
    if folder then folder:Destroy() end
    folder, attachment1 = nil, nil
end

-- ========== BRINGPART FUNCTIONS ==========
if not getgenv().Network then
    getgenv().Network = {
        BaseParts = {},
        Velocity = Vector3.new(14.46, 14.46, 14.46)
    }

    function Network.RetainPart(part)
        if part:IsA("BasePart") and part:IsDescendantOf(Workspace) then
            table.insert(Network.BaseParts, part)
            part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            part.CanCollide = false
        end
    end
end

local function EnableNetwork()
    if NetworkConnection then return end
    NetworkConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
        end)
    end)
end

local function DisableNetwork()
    if NetworkConnection then
        NetworkConnection:Disconnect()
        NetworkConnection = nil
    end
end

local function ForcePart(v)
    if v:IsA("BasePart") 
    and not v.Anchored 
    and not v.Parent:FindFirstChildOfClass("Humanoid") 
    and not v.Parent:FindFirstChild("Head") 
    and v.Name ~= "Handle" then

        for _, x in ipairs(v:GetChildren()) do
            if x:IsA("BodyMover") or x:IsA("RocketPropulsion") then
                x:Destroy()
            end
        end

        if v:FindFirstChild("Attachment") then v:FindFirstChild("Attachment"):Destroy() end
        if v:FindFirstChild("AlignPosition") then v:FindFirstChild("AlignPosition"):Destroy() end
        if v:FindFirstChild("Torque") then v:FindFirstChild("Torque"):Destroy() end

        v.CanCollide = false
        local Torque = Instance.new("Torque", v)
        Torque.Torque = Vector3.new(100000, 100000, 100000)
        local AlignPosition = Instance.new("AlignPosition", v)
        local Attachment2 = Instance.new("Attachment", v)
        Torque.Attachment0 = Attachment2
        AlignPosition.MaxForce = math.huge
        AlignPosition.MaxVelocity = math.huge
        AlignPosition.Responsiveness = Settings.BringPartSpeed
        AlignPosition.Attachment0 = Attachment2
        AlignPosition.Attachment1 = Attachment1
    end
end

local function OneTimeUnanchor()
    if getgenv().UnanchorCooldown then return end
    getgenv().UnanchorCooldown = true

    task.spawn(function()
        local startTime = tick()
        
        -- Simpan posisi awal player
        local originalCFrame = humanoidRootPart.CFrame
        local wasAnchored = humanoidRootPart.Anchored

        while tick() - startTime < 1 do
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("RopeConstraint") then
                    local part0 = obj.Attachment0 and obj.Attachment0.Parent
                    local part1 = obj.Attachment1 and obj.Attachment1.Parent
                    pcall(function() obj:Destroy() end)
                    if part0 and part0:IsA("BasePart") and not part0:IsDescendantOf(character) then 
                        part0.Anchored = false 
                    end
                    if part1 and part1:IsA("BasePart") and not part1:IsDescendantOf(character) then 
                        part1.Anchored = false 
                    end
                end
            end

            for _, part in pairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") 
                and not part.Anchored 
                and not part:IsDescendantOf(character) then
                    part.AssemblyLinearVelocity = Vector3.new(
                        math.random(-50, 50),
                        math.random(20, 100),
                        math.random(-50, 50)
                    )
                end
            end
            
            -- Kunci posisi player agar tidak terbang
            if humanoidRootPart and humanoidRootPart.Parent then
                humanoidRootPart.CFrame = originalCFrame
                humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end

            task.wait(0.1)
        end
        
        -- Kembalikan ke state normal
        if humanoidRootPart and humanoidRootPart.Parent then
            humanoidRootPart.Anchored = wasAnchored
        end

        getgenv().UnanchorCooldown = false
    end)
end

local function GetAllPartsRecursive(parent)
    local parts = {}
    for _, obj in ipairs(parent:GetChildren()) do
        if obj:IsA("BasePart") then
            table.insert(parts, obj)
        elseif obj:IsA("Folder") or obj:IsA("Model") then
            for _, childPart in ipairs(GetAllPartsRecursive(obj)) do
                table.insert(parts, childPart)
            end
        end
    end
    return parts
end

local playerStabilizer

local function mulaBringPart()
    BringFolder = Instance.new("Folder", Workspace)
    BringFolder.Name = "BringPartFolder"
    TargetPart = Instance.new("Part", BringFolder)
    TargetPart.Anchored = true
    TargetPart.CanCollide = false
    TargetPart.Transparency = 1
    Attachment1 = Instance.new("Attachment", TargetPart)

    EnableNetwork()
    OneTimeUnanchor()

    for _, v in ipairs(GetAllPartsRecursive(Workspace)) do
        if not v:IsDescendantOf(character) then
            local dist = (v.Position - humanoidRootPart.Position).Magnitude
            if dist <= Settings.BringPartRadius then
                ForcePart(v)
            end
        end
    end

    DescendantAddedConnection = Workspace.DescendantAdded:Connect(function(v)
        if blackHoleActive and v:IsA("BasePart") and not v:IsDescendantOf(character) then
            local dist = (v.Position - humanoidRootPart.Position).Magnitude
            if dist <= Settings.BringPartRadius then
                ForcePart(v)
            end
        end
    end)

    -- Stabilizer untuk mencegah player terbang
    playerStabilizer = RunService.Heartbeat:Connect(function()
        if humanoidRootPart and humanoidRootPart.Parent and character then
            -- Reset velocity yang tidak wajar
            local velocity = humanoidRootPart.AssemblyLinearVelocity
            if velocity.Y > 50 or velocity.Magnitude > 100 then
                humanoidRootPart.AssemblyLinearVelocity = Vector3.new(
                    velocity.X * 0.5,
                    math.min(velocity.Y, 20),
                    velocity.Z * 0.5
                )
            end
            
            -- Reset angular velocity
            if humanoidRootPart.AssemblyAngularVelocity.Magnitude > 10 then
                humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end
    end)

    task.spawn(function()
        while blackHoleActive and RunService.RenderStepped:Wait() do
            local targetCF = getTargetPosition()
            if targetCF then
                Attachment1.WorldCFrame = targetCF
            end
        end
    end)
end

local function stopBringPart()
    DisableNetwork()
    if DescendantAddedConnection then
        DescendantAddedConnection:Disconnect()
        DescendantAddedConnection = nil
    end
    if playerStabilizer then
        playerStabilizer:Disconnect()
        playerStabilizer = nil
    end
    if BringFolder then
        BringFolder:Destroy()
        BringFolder = nil
    end
end

-- ========== TOGGLE BUTTON ==========
ToggleBtn.MouseButton1Click:Connect(function()
    aktif = not aktif
    blackHoleActive = aktif

    character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    head = character:FindFirstChild("Head")

    if aktif then
        ToggleBtn.Text = "SIEXTHER | AKTIF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        
        mulaiUnanchor()
        mulaBringPart()
    else
        ToggleBtn.Text = "SIEXTHER | OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        
        stopUnanchor()
        stopBringPart()
    end
end)

-- ========== WINDOW CONTROLS ==========
CloseBtn.MouseButton1Click:Connect(function()
    local tween = TweenService:Create(MainFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 0)})
    tween:Play()
    tween.Completed:Wait()
    ScreenGui:Destroy()
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    local tween = TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 0, 0)})
    tween:Play()
    tween.Completed:Connect(function()
        MainFrame.Visible = false
        MiniFrame.Visible = true
    end)
end)

MiniFrame.MouseButton1Click:Connect(function()
    MiniFrame.Visible = false
    MainFrame.Visible = true
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    local tween = TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 280, 0, 200)})
    tween:Play()
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    if aktif then
        aktif = false
        blackHoleActive = false
        stopUnanchor()
        stopBringPart()
        ToggleBtn.Text = "SIEXTHER | OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    end
end)


