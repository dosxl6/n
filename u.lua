local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

-- State Variables
local CurrentTarget = nil
local OriginalCameraSubject = nil
local IsCameraLocked = false
local SendPartActive = false
local SendPartLoopThread = nil
local NetworkConnection = nil
local FreezeConnection = nil
local OriginalWalkSpeed = 16
local OriginalJumpPower = 50
local IsRandomMode = false

-- Colors (Updated Modern Dark Theme)
local COLORS = {
    DARK_BG = Color3.fromRGB(18, 18, 18),
    MEDIUM_BG = Color3.fromRGB(28, 28, 30),
    STROKE_BLUE = Color3.fromRGB(70, 130, 255),
    TEXT_WHITE = Color3.fromRGB(255, 255, 255),
    TEXT_GRAY = Color3.fromRGB(150, 150, 155),
    BUTTON_INACTIVE = Color3.fromRGB(35, 35, 37),
    BUTTON_ACTIVE = Color3.fromRGB(70, 130, 255),
    BUTTON_HOVER = Color3.fromRGB(45, 45, 48),
    GREEN = Color3.fromRGB(0, 255, 128),
    RED = Color3.fromRGB(255, 70, 70),
    YELLOW = Color3.fromRGB(255, 200, 0)
}

-- Character refs
local humanoid, rootPart
local function refreshCharacterRefs()
    local char = LP.Character
    if char then
        humanoid = char:FindFirstChildOfClass("Humanoid")
        rootPart = char:FindFirstChild("HumanoidRootPart")
        if humanoid then
            OriginalWalkSpeed = humanoid.WalkSpeed
            OriginalJumpPower = humanoid.JumpPower
        end
    else
        humanoid = nil
        rootPart = nil
    end
end
refreshCharacterRefs()

LP.CharacterAdded:Connect(function(char)
    pcall(function()
        char:WaitForChild("Humanoid", 5)
        char:WaitForChild("HumanoidRootPart", 5)
    end)
    refreshCharacterRefs()
end)

-- Helper: Check if part belongs to any player character
local function isPlayerCharacterPart(part)
    local parent = part.Parent
    if parent and parent:FindFirstChildOfClass("Humanoid") then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character == parent then
                return true
            end
        end
    end
    return false
end

-- ========== FREEZE SYSTEM ==========
local function freezeCharacter()
    if FreezeConnection then FreezeConnection:Disconnect() end
    FreezeConnection = RunService.Heartbeat:Connect(function()
        if humanoid and rootPart then
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
            pcall(function()
                rootPart.AssemblyLinearVelocity = Vector3.zero
                rootPart.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end)
    if humanoid then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
    end
end

local function unfreezeCharacter()
    if FreezeConnection then
        FreezeConnection:Disconnect()
        FreezeConnection = nil
    end
    if humanoid then
        humanoid.WalkSpeed = OriginalWalkSpeed
        humanoid.JumpPower = OriginalJumpPower
    end
end

-- ========== NETWORK & SEND PART FUNCTIONS ==========
local function OneTimeUnanchor()
    if _G.__JSY_UnanchorCooldown then return end
    _G.__JSY_UnanchorCooldown = true
    task.spawn(function()
        local start = tick()
        while tick() - start < 1 do
            -- Destroy RopeConstraints
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("RopeConstraint") then
                    local p0 = obj.Attachment0 and obj.Attachment0.Parent
                    local p1 = obj.Attachment1 and obj.Attachment1.Parent
                    pcall(function() obj:Destroy() end)
                    if p0 and p0:IsA("BasePart") and not isPlayerCharacterPart(p0) then 
                        p0.Anchored = false 
                    end
                    if p1 and p1:IsA("BasePart") and not isPlayerCharacterPart(p1) then 
                        p1.Anchored = false 
                    end
                end
            end
            
            -- Apply velocity only to NON-CHARACTER parts
            for _, part in ipairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") and not part.Anchored and not isPlayerCharacterPart(part) then
                    pcall(function()
                        part.AssemblyLinearVelocity = Vector3.new(
                            math.random(-50,50), 
                            math.random(20,100), 
                            math.random(-50,50)
                        )
                    end)
                end
            end
            task.wait(0.2)
        end
        _G.__JSY_UnanchorCooldown = false
    end)
end

local function GetAllPartsRecursive(parent)
    local parts = {}
    for _, obj in ipairs(parent:GetChildren()) do
        if obj:IsA("BasePart") then
            table.insert(parts, obj)
        elseif obj:IsA("Model") or obj:IsA("Folder") then
            for _, p in ipairs(GetAllPartsRecursive(obj)) do
                table.insert(parts, p)
            end
        end
    end
    return parts
end

local function EnableNetworkStabilizer()
    if NetworkConnection then return end
    pcall(function()
        NetworkConnection = RunService.Heartbeat:Connect(function()
            pcall(function()
                if sethiddenproperty then
                    sethiddenproperty(LP, "SimulationRadius", math.huge)
                end
            end)
        end)
    end)
end

local function DisableNetworkStabilizer()
    if NetworkConnection then
        NetworkConnection:Disconnect()
        NetworkConnection = nil
    end
end

local function sendUnanchoredPartsToTarget(target)
    if not target or not target.Character then return end
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end

    EnableNetworkStabilizer()
    OneTimeUnanchor()

    local folder = Workspace:FindFirstChild("SIEXTHERCHAOS") or Instance.new("Folder", Workspace)
    folder.Name = "SIEXTHERCHAOS"

    local targetPart = folder:FindFirstChild("TargetPart") or Instance.new("Part", folder)
    targetPart.Name = "TargetPart"
    targetPart.Anchored = true
    targetPart.CanCollide = false
    targetPart.Transparency = 1
    targetPart.Size = Vector3.new(1,1,1)
    targetPart.CFrame = targetHRP.CFrame
    local attach1 = targetPart:FindFirstChild("Attachment") or Instance.new("Attachment", targetPart)

    local function ForcePart(v)
        if not v:IsA("BasePart") then return end
        if v.Anchored then return end
        if isPlayerCharacterPart(v) then return end -- SKIP PLAYER PARTS
        if v.Name == "Handle" then return end

        local originalCFrame = v.CFrame
        local originalAnchored = v.Anchored
        local originalCanCollide = v.CanCollide

        for _, x in ipairs(v:GetChildren()) do
            if x:IsA("BodyMover") or x:IsA("AlignPosition") or x:IsA("Torque") or x:IsA("RocketPropulsion") or x:IsA("AlignOrientation") then
                pcall(function() x:Destroy() end)
            end
        end

        v.CanCollide = false

        local torque = Instance.new("Torque")
        torque.Parent = v
        torque.Torque = Vector3.new(100000,100000,100000)

        local align = Instance.new("AlignPosition")
        align.Parent = v
        align.MaxForce = math.huge
        align.MaxVelocity = math.huge
        align.Responsiveness = 200

        local attach2 = Instance.new("Attachment", v)
        torque.Attachment0 = attach2
        align.Attachment0 = attach2
        align.Attachment1 = attach1

        task.spawn(function()
            local started = tick()
            while tick() - started < 2 do
                if not v or not v.Parent then break end
                task.wait(0.05)
            end
            pcall(function()
                if v and v:IsA("BasePart") then
                    v.AssemblyLinearVelocity = Vector3.zero
                    v.AssemblyAngularVelocity = Vector3.zero
                end
                if align and align.Parent then align:Destroy() end
                if torque and torque.Parent then torque:Destroy() end
                for _, child in ipairs(v:GetChildren()) do
                    if child:IsA("Attachment") then
                        if child ~= attach1 then
                            pcall(function() child:Destroy() end)
                        end
                    end
                end
                if v and v.Parent then
                    pcall(function()
                        v.CanCollide = originalCanCollide
                        v.Anchored = originalAnchored
                        task.wait(0.05)
                        v.CFrame = originalCFrame
                    end)
                end
            end)
        end)
    end

    local parts = GetAllPartsRecursive(Workspace)
    for _, p in ipairs(parts) do
        pcall(function()
            if not p.Anchored and not isPlayerCharacterPart(p) then
                ForcePart(p)
            end
        end)
    end

    task.spawn(function()
        local duration = 5
        local start = tick()
        while tick() - start < duration do
            if attach1 and targetHRP then
                pcall(function()
                    attach1.WorldCFrame = targetHRP.CFrame
                    targetPart.CFrame = targetHRP.CFrame
                end)
            end
            task.wait()
        end
        pcall(function() folder:Destroy() end)
        DisableNetworkStabilizer()
    end)
end

-- ========== DRAG FUNCTION (UNIVERSAL) ==========
local function makeDraggable(frame)
    local dragging = false
    local dragInput, dragStart, startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- ========== GUI CREATION (SMALLER SIZE) ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SIEXTHERCHAOSSX"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Floating Button (Minimized State)
local FloatingButton = Instance.new("TextButton")
FloatingButton.Size = UDim2.new(0, 41, 0, 41)
FloatingButton.Position = UDim2.new(0, 15, 0.5, -25)
FloatingButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
FloatingButton.BorderSizePixel = 0
FloatingButton.Text = "☠️"
FloatingButton.TextSize = 13
FloatingButton.TextColor3 = COLORS.TEXT_WHITE
FloatingButton.Visible = false
FloatingButton.Active = true
FloatingButton.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner", FloatingButton)
FloatCorner.CornerRadius = UDim.new(0, 12)

makeDraggable(FloatingButton)

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 320)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -185)
MainFrame.BackgroundColor3 = COLORS.DARK_BG
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 8)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = COLORS.STROKE_BLUE
MainStroke.Thickness = 2

makeDraggable(MainFrame)

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundColor3 = COLORS.MEDIUM_BG
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner", Header)
HeaderCorner.CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -65, 1, 0)
Title.Position = UDim2.new(0, 8, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SIEXTHER BRING"
Title.TextColor3 = COLORS.STROKE_BLUE
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Minimize Button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 22, 0, 22)
MinimizeBtn.Position = UDim2.new(1, -52, 0.5, -11)
MinimizeBtn.BackgroundColor3 = COLORS.BUTTON_INACTIVE
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Text = "–"
MinimizeBtn.TextSize = 16
MinimizeBtn.TextColor3 = COLORS.TEXT_WHITE
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = Header

local MinCorner = Instance.new("UICorner", MinimizeBtn)
MinCorner.CornerRadius = UDim.new(0, 4)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -26, 0.5, -11)
CloseBtn.BackgroundColor3 = COLORS.RED
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = COLORS.TEXT_WHITE
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner", CloseBtn)
CloseCorner.CornerRadius = UDim.new(0, 4)

-- Search Bar
local SearchFrame = Instance.new("Frame")
SearchFrame.Size = UDim2.new(1, -16, 0, 28)
SearchFrame.Position = UDim2.new(0, 8, 0, 38)
SearchFrame.BackgroundColor3 = COLORS.MEDIUM_BG
SearchFrame.BorderSizePixel = 0
SearchFrame.Parent = MainFrame

local SearchCorner = Instance.new("UICorner", SearchFrame)
SearchCorner.CornerRadius = UDim.new(0, 5)

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -12, 1, 0)
SearchBox.Position = UDim2.new(0, 6, 0, 0)
SearchBox.BackgroundTransparency = 1
SearchBox.PlaceholderText = "Cari player..."
SearchBox.PlaceholderColor3 = COLORS.TEXT_GRAY
SearchBox.Text = ""
SearchBox.TextColor3 = COLORS.TEXT_WHITE
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 11
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = SearchFrame

-- Player List Scroll
local PlayerListFrame = Instance.new("ScrollingFrame")
PlayerListFrame.Size = UDim2.new(1, -16, 1, -114)
PlayerListFrame.Position = UDim2.new(0, 8, 0, 72)
PlayerListFrame.BackgroundColor3 = COLORS.MEDIUM_BG
PlayerListFrame.BorderSizePixel = 0
PlayerListFrame.ScrollBarThickness = 3
PlayerListFrame.ScrollBarImageColor3 = COLORS.STROKE_BLUE
PlayerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerListFrame.Parent = MainFrame

local ListCorner = Instance.new("UICorner", PlayerListFrame)
ListCorner.CornerRadius = UDim.new(0, 5)

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 2)
ListLayout.SortOrder = Enum.SortOrder.Name
ListLayout.Parent = PlayerListFrame

-- Bottom Buttons Frame
local BottomFrame = Instance.new("Frame")
BottomFrame.Size = UDim2.new(1, -16, 0, 38)
BottomFrame.Position = UDim2.new(0, 8, 1, -46)
BottomFrame.BackgroundTransparency = 1
BottomFrame.Parent = MainFrame

local function createBottomButton(text, position, inactiveColor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.31, 0, 1, 0)
    btn.Position = position
    btn.BackgroundColor3 = inactiveColor
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = COLORS.TEXT_WHITE
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.AutoButtonColor = false
    btn.Parent = BottomFrame
    
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 5)
    
    btn.MouseEnter:Connect(function()
        if btn.BackgroundColor3 ~= COLORS.BUTTON_ACTIVE and btn.BackgroundColor3 ~= COLORS.RED then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.BUTTON_HOVER}):Play()
        end
    end)
    
    btn.MouseLeave:Connect(function()
        if btn.BackgroundColor3 ~= COLORS.BUTTON_ACTIVE and btn.BackgroundColor3 ~= COLORS.RED then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = inactiveColor}):Play()
        end
    end)
    
    return btn
end

local BringBtn = createBottomButton("EXECUTE", UDim2.new(0, 0, 0, 0), COLORS.BUTTON_INACTIVE)
local CancelBtn = createBottomButton("STOP", UDim2.new(0.345, 0, 0, 0), COLORS.RED)
local RandomBtn = createBottomButton("RANDOM", UDim2.new(0.69, 0, 0, 0), COLORS.BUTTON_INACTIVE)

CancelBtn.Visible = false

-- ========== CAMERA SYSTEM ==========
local function lockCamera(target)
    if not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if not IsCameraLocked then
        OriginalCameraSubject = Cam.CameraSubject
    end
    
    IsCameraLocked = true
    CurrentTarget = target
    Cam.CameraSubject = hrp
    CancelBtn.Visible = true
end

local function unlockCamera()
    IsCameraLocked = false
    CurrentTarget = nil
    
    if OriginalCameraSubject then
        Cam.CameraSubject = OriginalCameraSubject
    else
        if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
            Cam.CameraSubject = LP.Character:FindFirstChildOfClass("Humanoid")
        end
    end
    
    CancelBtn.Visible = false
end

-- ========== PLAYER LIST CREATION ==========
local PlayerButtons = {}

local function createPlayerButton(player)
    if PlayerButtons[player] then return end
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 36)
    btn.BackgroundColor3 = COLORS.DARK_BG
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.Name = player.Name
    btn.Parent = PlayerListFrame
    
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 4)
    
    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(0, 28, 0, 28)
    avatar.Position = UDim2.new(0, 4, 0.5, -14)
    avatar.BackgroundTransparency = 1
    avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=48&height=48&format=png"
    avatar.Parent = btn
    
    local avatarCorner = Instance.new("UICorner", avatar)
    avatarCorner.CornerRadius = UDim.new(0, 5)
    
    local displayName = player.DisplayName or player.Name
    local username = "@" .. player.Name
    local fullText = displayName .. " " .. username
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -38, 1, 0)
    nameLabel.Position = UDim2.new(0, 36, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = fullText
    nameLabel.TextColor3 = COLORS.TEXT_WHITE
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextSize = 10
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = btn
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.MEDIUM_BG}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.DARK_BG}):Play()
    end)
    
    btn.MouseButton1Click:Connect(function()
        lockCamera(player)
    end)
    
    PlayerButtons[player] = btn
end

local function updatePlayerList(searchTerm)
    searchTerm = searchTerm or ""
    searchTerm = searchTerm:lower()
    
    for player, btn in pairs(PlayerButtons) do
        if not player or not player.Parent then
            btn:Destroy()
            PlayerButtons[player] = nil
        else
            local name = player.Name:lower()
            local displayName = (player.DisplayName or ""):lower()
            
            if searchTerm == "" or name:find(searchTerm) or displayName:find(searchTerm) then
                btn.Visible = true
            else
                btn.Visible = false
            end
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            if not PlayerButtons[player] then
                createPlayerButton(player)
            end
        end
    end
    
    ListLayout:ApplyLayout()
    PlayerListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 6)
end

-- ========== BUTTON FUNCTIONS ==========
BringBtn.MouseButton1Click:Connect(function()
    if not CurrentTarget then return end
    if IsRandomMode then return end
    
    SendPartActive = not SendPartActive
    
    if SendPartActive then
        BringBtn.Text = "STOP"
        BringBtn.BackgroundColor3 = COLORS.RED
        freezeCharacter()
        
        if not SendPartLoopThread then
            SendPartLoopThread = task.spawn(function()
                while SendPartActive do
                    if CurrentTarget and CurrentTarget.Character then
                        pcall(function()
                            sendUnanchoredPartsToTarget(CurrentTarget)
                        end)
                    end
                    task.wait(2.2)
                end
                SendPartLoopThread = nil
            end)
        end
    else
        BringBtn.Text = "EXECUTE"
        BringBtn.BackgroundColor3 = COLORS.BUTTON_INACTIVE
        unfreezeCharacter()
    end
end)

CancelBtn.MouseButton1Click:Connect(function()
    SendPartActive = false
    IsRandomMode = false
    BringBtn.Text = "EXECUTE"
    BringBtn.BackgroundColor3 = COLORS.BUTTON_INACTIVE
    RandomBtn.BackgroundColor3 = COLORS.BUTTON_INACTIVE
    unfreezeCharacter()
    unlockCamera()
end)

RandomBtn.MouseButton1Click:Connect(function()
    IsRandomMode = not IsRandomMode
    
    if IsRandomMode then
        TweenService:Create(RandomBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BUTTON_ACTIVE}):Play()
        
        local players = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                if rootPart then
                    local distance = (hrp.Position - rootPart.Position).Magnitude
                    table.insert(players, {player = player, distance = distance})
                end
            end
        end
        
        table.sort(players, function(a, b) return a.distance < b.distance end)
        
        if #players > 0 then
            local closestPlayer = players[1].player
            
            lockCamera(closestPlayer)
            
            SendPartActive = true
            freezeCharacter()
            
            pcall(function()
                sendUnanchoredPartsToTarget(closestPlayer)
            end)
            
            if not SendPartLoopThread then
                SendPartLoopThread = task.spawn(function()
                    while SendPartActive and IsRandomMode do
                        if CurrentTarget and CurrentTarget.Character then
                            pcall(function()
                                sendUnanchoredPartsToTarget(CurrentTarget)
                            end)
                        end
                        task.wait(2.2)
                    end
                    SendPartLoopThread = nil
                end)
            end
        else
            IsRandomMode = false
            task.wait(0.3)
            TweenService:Create(RandomBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BUTTON_INACTIVE}):Play()
        end
    else
        SendPartActive = false
        unfreezeCharacter()
        unlockCamera()
        TweenService:Create(RandomBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BUTTON_INACTIVE}):Play()
    end
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    FloatingButton.Visible = true
end)

FloatingButton.MouseButton1Click:Connect(function()
    FloatingButton.Visible = false
    MainFrame.Visible = true
end)

CloseBtn.MouseButton1Click:Connect(function()
    SendPartActive = false
    IsRandomMode = false
    unfreezeCharacter()
    unlockCamera()
    DisableNetworkStabilizer()
    pcall(function() ScreenGui:Destroy() end)
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    updatePlayerList(SearchBox.Text)
end)

Players.PlayerAdded:Connect(function(player)
    task.wait(0.5)
    updatePlayerList(SearchBox.Text)
end)

Players.PlayerRemoving:Connect(function(player)
    if PlayerButtons[player] then
        PlayerButtons[player]:Destroy()
        PlayerButtons[player] = nil
    end
    
    if CurrentTarget == player then
        unlockCamera()
        SendPartActive = false
        IsRandomMode = false
        BringBtn.Text = "EXECUTE"
        BringBtn.BackgroundColor3 = COLORS.BUTTON_INACTIVE
        RandomBtn.BackgroundColor3 = COLORS.BUTTON_INACTIVE
        unfreezeCharacter()
    end
    
    task.wait(0.5)
    updatePlayerList(SearchBox.Text)
end)

-- Initial Update
task.defer(function()
    updatePlayerList()
end)