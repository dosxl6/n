local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

-- State
local Active = true
local TargetList = {}
local CurrentIndex = 0
local CurrentTarget = nil
local FlingActive = false
local FlingThread = nil
local OriginalCFrame = nil
local FollowActive = false
local FollowConnection = nil
local FollowAnim = nil
local SendPartActive = false
local SendPartLoopThread = nil
local FreezeConnection = nil
local OriginalWalkSpeed = 16
local OriginalJumpPower = 50
local NetworkConnection = nil

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
    else humanoid = nil rootPart = nil end
end
refreshCharacterRefs()

LP.CharacterAdded:Connect(function(char)
    pcall(function() char:WaitForChild("Humanoid",5) char:WaitForChild("HumanoidRootPart",5) end)
    refreshCharacterRefs()
    if FollowActive then
        if FollowConnection then FollowConnection:Disconnect() FollowConnection = nil end
        if FollowAnim then pcall(function() FollowAnim:Stop() end) FollowAnim = nil end
        FollowActive = false
    end
end)

-- ========== FREEZE ==========
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
    if humanoid then humanoid.WalkSpeed = 0 humanoid.JumpPower = 0 end
end

local function unfreezeCharacter()
    if FreezeConnection then FreezeConnection:Disconnect() FreezeConnection = nil end
    if humanoid then
        humanoid.WalkSpeed = OriginalWalkSpeed
        humanoid.JumpPower = OriginalJumpPower
    end
end

-- ========== WARNA ==========
local BG_MAIN    = Color3.fromRGB(25, 25, 35)
local BG_CARD    = Color3.fromRGB(35, 35, 48)
local BG_BTN     = Color3.fromRGB(45, 45, 60)
local BG_BTN_HOV = Color3.fromRGB(60, 60, 78)
local COL_WHITE  = Color3.fromRGB(255, 255, 255)
local COL_GRAY   = Color3.fromRGB(155, 155, 175)
local COL_GREEN  = Color3.fromRGB(80, 220, 100)
local COL_RED    = Color3.fromRGB(220, 70, 70)
local COL_BORDER = Color3.fromRGB(70, 130, 255)

-- ========== SCREEN GUI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SiextheR_Spectator"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ========== FLOATING ICON (saat minimize) ==========
-- Ukuran frame:
-- TitleBar: 32px
-- ProfileCard: 68px
-- 3 baris tombol: 3 * 38px = 114px
-- gap atas/bawah + antar: 8+8+5+5+5 = 31px
-- Total: 32 + 8 + 68 + 8 + 114 + 10 = 240px
local FULL_H = 250
local FULL_W = 300

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, FULL_W, 0, FULL_H)
MainFrame.Position = UDim2.new(0.5, -150, 0.12, 0)
MainFrame.BackgroundColor3 = BG_MAIN
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Active = true
MainFrame.Draggable = false -- manual drag via TitleBar

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = COL_BORDER
MainStroke.Thickness = 1.5

-- ========== TITLE BAR (32px) ==========
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = BG_MAIN
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner", TitleBar)
TitleCorner.CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "SIEXTHER SPECTATOR"
TitleLabel.TextColor3 = COL_WHITE
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar
local TitleTextStroke = Instance.new("UIStroke", TitleLabel)
TitleTextStroke.Color = Color3.fromRGB(0, 0, 0)
TitleTextStroke.Thickness = 1.5
TitleTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

-- Minimize (—)
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 24, 0, 24)
MinimizeBtn.Position = UDim2.new(1, -54, 0.5, -12)
MinimizeBtn.BackgroundColor3 = BG_BTN
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Text = "–"
MinimizeBtn.TextColor3 = COL_WHITE
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 12
MinimizeBtn.Parent = TitleBar
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 5)

-- Close (□)
local CloseNavBtn = Instance.new("TextButton")
CloseNavBtn.Size = UDim2.new(0, 24, 0, 24)
CloseNavBtn.Position = UDim2.new(1, -28, 0.5, -12)
CloseNavBtn.BackgroundColor3 = BG_BTN
CloseNavBtn.BorderSizePixel = 0
CloseNavBtn.Text = "x"
CloseNavBtn.TextColor3 = COL_WHITE
CloseNavBtn.Font = Enum.Font.GothamBold
CloseNavBtn.TextSize = 12
CloseNavBtn.Parent = TitleBar
Instance.new("UICorner", CloseNavBtn).CornerRadius = UDim.new(0, 5)

-- (Separator/divider dihapus)

-- ========== CONTENT FRAME ==========
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, 0, 1, -32)
ContentFrame.Position = UDim2.new(0, 0, 0, 32)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0
ContentFrame.Parent = MainFrame

-- ========== PROFILE CARD (68px, posisi Y=6) ==========
local ProfileCard = Instance.new("Frame")
ProfileCard.Size = UDim2.new(1, -16, 0, 68)
ProfileCard.Position = UDim2.new(0, 8, 0, 8)
ProfileCard.BackgroundColor3 = BG_CARD
ProfileCard.BorderSizePixel = 0
ProfileCard.Parent = ContentFrame
Instance.new("UICorner", ProfileCard).CornerRadius = UDim.new(0, 7)
local PS = Instance.new("UIStroke", ProfileCard)
PS.Color = COL_BORDER PS.Thickness = 1

-- Avatar (48x48)
local Avatar = Instance.new("ImageLabel")
Avatar.Size = UDim2.new(0, 48, 0, 48)
Avatar.Position = UDim2.new(0, 10, 0.5, -24)
Avatar.BackgroundColor3 = BG_BTN
Avatar.BorderSizePixel = 0
Avatar.Image = ""
Avatar.Parent = ProfileCard
Instance.new("UICorner", Avatar).CornerRadius = UDim.new(0, 7)

-- Status dot
local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 9, 0, 9)
StatusDot.Position = UDim2.new(0, 10 + 48 - 10, 0.5, 24 - 10)
StatusDot.BackgroundColor3 = COL_RED
StatusDot.BorderSizePixel = 0
StatusDot.ZIndex = 2
StatusDot.Parent = ProfileCard
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)

-- Username
local UsernameLabel = Instance.new("TextLabel")
UsernameLabel.Size = UDim2.new(1, -70, 0, 22)
UsernameLabel.Position = UDim2.new(0, 66, 0, 10)
UsernameLabel.BackgroundTransparency = 1
UsernameLabel.Text = "Nama"
UsernameLabel.TextColor3 = COL_WHITE
UsernameLabel.Font = Enum.Font.GothamBold
UsernameLabel.TextSize = 13
UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left
UsernameLabel.Parent = ProfileCard

-- Age
local AgeLabel = Instance.new("TextLabel")
AgeLabel.Size = UDim2.new(1, -70, 0, 16)
AgeLabel.Position = UDim2.new(0, 66, 0, 32)
AgeLabel.BackgroundTransparency = 1
AgeLabel.Text = "Age: 0 days"
AgeLabel.TextColor3 = COL_GRAY
AgeLabel.Font = Enum.Font.Gotham
AgeLabel.TextSize = 11
AgeLabel.TextXAlignment = Enum.TextXAlignment.Left
AgeLabel.Parent = ProfileCard

-- ID
local IdLabel = Instance.new("TextLabel")
IdLabel.Size = UDim2.new(1, -70, 0, 14)
IdLabel.Position = UDim2.new(0, 66, 0, 48)
IdLabel.BackgroundTransparency = 1
IdLabel.Text = "ID: 0"
IdLabel.TextColor3 = COL_GRAY
IdLabel.Font = Enum.Font.Gotham
IdLabel.TextSize = 10
IdLabel.TextXAlignment = Enum.TextXAlignment.Left
IdLabel.Parent = ProfileCard

-- ========== TOMBOL GRID ==========
-- Mulai Y = 6 (top pad) + 68 (profile) + 6 (gap) = 80
-- Tiap baris: 38px tinggi, gap 4px
-- Lebar tiap tombol: (290 - 12 - 12 - 6) / 2 = 130px
local function makeBtn(parent, text, col, row)
    local padL = 8
    local gap = 6
    local btnW = 139  -- (300 - 16 - 6) / 2 = 139
    local btnH = 36
    local startY = 84  -- 8 (top pad) + 68 (profile) + 8 (gap)
    local xPos = padL + (col - 1) * (btnW + gap)
    local yPos = startY + (row - 1) * (btnH + gap)

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, btnW, 0, btnH)
    Btn.Position = UDim2.new(0, xPos, 0, yPos)
    Btn.BackgroundColor3 = BG_BTN
    Btn.BorderSizePixel = 0
    Btn.Text = text
    Btn.TextColor3 = COL_WHITE
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 12
    Btn.AutoButtonColor = false
    Btn.Parent = parent

    local bc = Instance.new("UICorner", Btn)
    bc.CornerRadius = UDim.new(0, 7)

    local bs = Instance.new("UIStroke", Btn)
    bs.Color = COL_BORDER
    bs.Thickness = 1
    bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.12), {BackgroundColor3 = BG_BTN_HOV}):Play()
    end)
    Btn.MouseLeave:Connect(function()
        if Btn.BackgroundColor3 ~= COL_GREEN and Btn.BackgroundColor3 ~= COL_RED then
            TweenService:Create(Btn, TweenInfo.new(0.12), {BackgroundColor3 = BG_BTN}):Play()
        end
    end)
    return Btn
end

-- Row 1: PREV | NEXT
local PrevBtn     = makeBtn(ContentFrame, "PREV",     1, 1)
local NextBtn     = makeBtn(ContentFrame, "NEXT",     2, 1)
-- Row 2: TELEPORT | KICK
local TeleBtn     = makeBtn(ContentFrame, "TELEPORT", 1, 2)
local KickBtn     = makeBtn(ContentFrame, "KICK",     2, 2)
-- Row 3: FOLLOW | SEND PART
local FollowBtn   = makeBtn(ContentFrame, "FOLLOW",   1, 3)
local SendPartBtn = makeBtn(ContentFrame, "SEND PART",2, 3)

-- ========== EYE BUTTON ==========
local EyeBtn = Instance.new("TextButton")
EyeBtn.Name = "EyeIcon"
EyeBtn.Size = UDim2.new(0, 41, 0, 41)
EyeBtn.Position = UDim2.new(0, 14, 0.5, -19) -- posisi default awal
EyeBtn.BackgroundColor3 = BG_MAIN
EyeBtn.BorderSizePixel = 0
EyeBtn.Text = "👁️"
EyeBtn.TextSize = 20
EyeBtn.Font = Enum.Font.GothamBold
EyeBtn.Visible = false
EyeBtn.Active = true
EyeBtn.Draggable = false -- kita handle manual biar smooth
EyeBtn.ZIndex = 5
EyeBtn.Parent = ScreenGui
Instance.new("UICorner", EyeBtn).CornerRadius = UDim.new(0, 12)
local EyeStroke = Instance.new("UIStroke", EyeBtn)
EyeStroke.Color = COL_BORDER
EyeStroke.Thickness = 1.5

-- ========== DRAG LOGIC UNTUK MAINFRAME (via TitleBar) ==========
local draggingMain = false
local dragInputMain, dragStartMain, startPosMain

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        draggingMain = true
        dragStartMain = input.Position
        startPosMain = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingMain = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or
       input.UserInputType == Enum.UserInputType.Touch then
        dragInputMain = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if draggingMain and input == dragInputMain then
        local delta = input.Position - dragStartMain
        MainFrame.Position = UDim2.new(
            startPosMain.X.Scale,
            startPosMain.X.Offset + delta.X,
            startPosMain.Y.Scale,
            startPosMain.Y.Offset + delta.Y
        )
    end
end)

-- ========== DRAG LOGIC UNTUK EYE BUTTON ==========
local dragging = false
local dragInput, dragStart, startPos
local dragMoved = false

EyeBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragMoved = false
        dragStart = input.Position
        startPos = EyeBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

EyeBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or
       input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        if delta.Magnitude > 4 then dragMoved = true end
        EyeBtn.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ========== MINIMIZE LOGIC ==========
local minimized = false

MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = true
    -- EyeBtn tetap di posisi terakhirnya, tidak ikut MainFrame
    MainFrame.Visible = false
    EyeBtn.Visible = true
end)

EyeBtn.MouseButton1Click:Connect(function()
    if dragMoved then dragMoved = false return end -- jangan trigger klik kalau habis drag
    minimized = false
    EyeBtn.Visible = false
    -- MainFrame muncul di posisi terakhirnya (tidak berubah saat minimize)
    MainFrame.Size = UDim2.new(0, FULL_W, 0, FULL_H)
    MainFrame.Visible = true
end)

-- ========== CLOSE ==========
CloseNavBtn.MouseButton1Click:Connect(function()
    Active = false
    FlingActive = false
    SendPartActive = false
    unfreezeCharacter()
    if FollowConnection then FollowConnection:Disconnect() FollowConnection = nil end
    if FollowAnim then pcall(function() FollowAnim:Stop() end) FollowAnim = nil end
    if LP.Character and LP.Character:FindFirstChild("Humanoid") then
        Cam.CameraSubject = LP.Character:FindFirstChild("Humanoid")
    end
    pcall(function() ScreenGui:Destroy() end)
end)

-- ========== UPDATE PROFILE ==========
local function updateProfile(plr)
    if plr and plr:IsA("Player") then
        UsernameLabel.Text = plr.Name
        AgeLabel.Text = "Age: " .. tostring(plr.AccountAge or 0) .. " days"
        IdLabel.Text = "ID: " .. tostring(plr.UserId)
        StatusDot.BackgroundColor3 = COL_GREEN
        pcall(function()
            Avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. plr.UserId .. "&width=150&height=150&format=png"
        end)
    else
        UsernameLabel.Text = "Nama"
        AgeLabel.Text = "Age: 0 days"
        IdLabel.Text = "ID: 0"
        Avatar.Image = ""
        StatusDot.BackgroundColor3 = COL_RED
    end
end

-- ========== SEND PART HELPERS ==========
local function OneTimeUnanchor()
    if _G.__JSY_UnanchorCooldown then return end
    _G.__JSY_UnanchorCooldown = true
    task.spawn(function()
        local start = tick()
        while tick() - start < 1 do
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("RopeConstraint") then
                    local p0 = obj.Attachment0 and obj.Attachment0.Parent
                    local p1 = obj.Attachment1 and obj.Attachment1.Parent
                    pcall(function() obj:Destroy() end)
                    if p0 and p0:IsA("BasePart") then p0.Anchored = false end
                    if p1 and p1:IsA("BasePart") then p1.Anchored = false end
                end
            end
            for _, part in ipairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") and not part.Anchored then
                    part.AssemblyLinearVelocity = Vector3.new(math.random(-50,50), math.random(20,100), math.random(-50,50))
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
        if obj:IsA("BasePart") then table.insert(parts, obj)
        elseif obj:IsA("Model") or obj:IsA("Folder") then
            for _, p in ipairs(GetAllPartsRecursive(obj)) do table.insert(parts, p) end
        end
    end
    return parts
end

local function EnableNetworkStabilizer()
    if NetworkConnection then return end
    pcall(function()
        NetworkConnection = RunService.Heartbeat:Connect(function()
            pcall(function()
                if sethiddenproperty then sethiddenproperty(LP, "SimulationRadius", math.huge) end
            end)
        end)
    end)
end

local function DisableNetworkStabilizer()
    if NetworkConnection then NetworkConnection:Disconnect() NetworkConnection = nil end
end

local function sendUnanchoredPartsToTarget(target)
    if not target or not target.Character then return end
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end

    EnableNetworkStabilizer()
    OneTimeUnanchor()

    local folder = Workspace:FindFirstChild("JSY_SendPartFolder") or Instance.new("Folder", Workspace)
    folder.Name = "JSY_SendPartFolder"

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
        if v.Parent and v.Parent:FindFirstChildOfClass("Humanoid") then return end
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
                    if child:IsA("Attachment") and child ~= attach1 then
                        pcall(function() child:Destroy() end)
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
        pcall(function() if not p.Anchored then ForcePart(p) end end)
    end

    task.spawn(function()
        local start = tick()
        while tick() - start < 5 do
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

local function turnOffSendPart()
    if SendPartActive then
        SendPartActive = false
        SendPartBtn.Text = "SEND PART"
        TweenService:Create(SendPartBtn, TweenInfo.new(0.3), {BackgroundColor3 = BG_BTN}):Play()
        unfreezeCharacter()
    end
end

-- ========== TARGETING ==========
local function getTargetablePlayers()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(list, p)
        end
    end
    return list
end

local function refreshTargetList()
    local oldTarget = CurrentTarget
    TargetList = getTargetablePlayers()
    if #TargetList == 0 then
        CurrentIndex = 0; CurrentTarget = nil; updateProfile(nil); return
    end
    if oldTarget and table.find(TargetList, oldTarget) then
        CurrentIndex = table.find(TargetList, oldTarget)
        CurrentTarget = oldTarget; updateProfile(CurrentTarget); return
    end
    if oldTarget then
        for i, player in ipairs(TargetList) do
            if player.UserId == oldTarget.UserId then
                CurrentIndex = i; CurrentTarget = player; updateProfile(CurrentTarget); return
            end
        end
    end
    if CurrentIndex < 1 or CurrentIndex > #TargetList then CurrentIndex = 1 end
    CurrentTarget = TargetList[CurrentIndex]
    updateProfile(CurrentTarget)
end

local refreshDebounce = false
local function safeRefreshTargetList()
    if refreshDebounce then return end
    refreshDebounce = true
    refreshTargetList()
    task.wait(0.5)
    refreshDebounce = false
end

refreshTargetList()

Players.PlayerAdded:Connect(function() task.wait(0.1) safeRefreshTargetList() end)
Players.PlayerRemoving:Connect(function(plr)
    task.wait(0.1)
    safeRefreshTargetList()
    if CurrentTarget and plr == CurrentTarget then
        CurrentTarget = nil; updateProfile(nil)
        if FollowActive then
            FollowActive = false
            if FollowConnection then FollowConnection:Disconnect() FollowConnection = nil end
            if FollowAnim then pcall(function() FollowAnim:Stop() end) FollowAnim = nil end
            FollowBtn.Text = "FOLLOW"
            TweenService:Create(FollowBtn, TweenInfo.new(0.3), {BackgroundColor3 = BG_BTN}):Play()
        end
        if FlingActive then
            FlingActive = false; KickBtn.Text = "KICK"
            TweenService:Create(KickBtn, TweenInfo.new(0.3), {BackgroundColor3 = BG_BTN}):Play()
        end
        if SendPartActive then turnOffSendPart() end
    end
end)

-- ========== NAVIGATION ==========
PrevBtn.MouseButton1Click:Connect(function()
    if #TargetList == 0 then safeRefreshTargetList() end
    if #TargetList == 0 then return end
    local idx = CurrentIndex - 1
    if idx < 1 then idx = #TargetList end
    CurrentIndex = idx; CurrentTarget = TargetList[CurrentIndex]
    updateProfile(CurrentTarget); turnOffSendPart()
end)

NextBtn.MouseButton1Click:Connect(function()
    if #TargetList == 0 then safeRefreshTargetList() end
    if #TargetList == 0 then return end
    local idx = CurrentIndex + 1
    if idx > #TargetList then idx = 1 end
    CurrentIndex = idx; CurrentTarget = TargetList[CurrentIndex]
    updateProfile(CurrentTarget); turnOffSendPart()
end)

-- ========== CAMERA ==========
RunService.RenderStepped:Connect(function()
    if not Active then return end
    if CurrentTarget and CurrentTarget.Character then
        local hrp = CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
        if hrp then Cam.CameraSubject = hrp end
    end
end)

-- ========== TELEPORT ==========
TeleBtn.MouseButton1Click:Connect(function()
    if not CurrentTarget then return end
    local lpHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local targetHRP = CurrentTarget.Character and CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
    if lpHRP and targetHRP then
        lpHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
        TweenService:Create(TeleBtn, TweenInfo.new(0.3), {BackgroundColor3 = COL_GREEN}):Play()
        task.wait(0.5)
        TweenService:Create(TeleBtn, TweenInfo.new(0.3), {BackgroundColor3 = BG_BTN}):Play()
    end
end)

-- ========== KICK / FLING ==========
local function flingLoop()
    while FlingActive do
        RunService.Heartbeat:Wait()
        local lpHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local targetHRP = CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
        if lpHRP and targetHRP then
            local dir = (targetHRP.Position - lpHRP.Position)
            if dir.Magnitude > 0 then lpHRP.AssemblyLinearVelocity = dir.Unit * 500 end
            lpHRP.CFrame = targetHRP.CFrame
        end
    end
end

KickBtn.MouseButton1Click:Connect(function()
    if not CurrentTarget then return end
    local lpHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not lpHRP then return end
    FlingActive = not FlingActive
    if FlingActive then
        OriginalCFrame = lpHRP.CFrame
        KickBtn.Text = "KICKING..."
        TweenService:Create(KickBtn, TweenInfo.new(0.3), {BackgroundColor3 = COL_RED}):Play()
        if not FlingThread then FlingThread = task.spawn(flingLoop) end
    else
        FlingActive = false; KickBtn.Text = "KICK"
        TweenService:Create(KickBtn, TweenInfo.new(0.3), {BackgroundColor3 = BG_BTN}):Play()
        FlingThread = nil
        task.defer(function()
            pcall(function()
                if lpHRP and OriginalCFrame then
                    lpHRP.AssemblyLinearVelocity = Vector3.zero
                    lpHRP.AssemblyAngularVelocity = Vector3.zero
                    task.wait(0.1)
                    lpHRP.CFrame = OriginalCFrame
                end
            end)
        end)
    end
end)

-- ========== FOLLOW ==========
local function stopFollow()
    FollowActive = false
    if FollowConnection then FollowConnection:Disconnect() FollowConnection = nil end
    if FollowAnim then pcall(function() FollowAnim:Stop() end) FollowAnim = nil end
    FollowBtn.Text = "FOLLOW"
    TweenService:Create(FollowBtn, TweenInfo.new(0.3), {BackgroundColor3 = BG_BTN}):Play()
end

local function startFollowToTarget(target)
    if not target or not rootPart or not humanoid then return end
    FollowActive = true
    FollowBtn.Text = "FOLLOWING..."
    TweenService:Create(FollowBtn, TweenInfo.new(0.3), {BackgroundColor3 = COL_GREEN}):Play()
    pcall(function()
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://100681208320300"
        FollowAnim = humanoid:LoadAnimation(anim)
        FollowAnim.Looped = true
        FollowAnim:Play()
    end)
    FollowConnection = RunService.Heartbeat:Connect(function()
        if not FollowActive then return end
        if not target.Character then stopFollow() return end
        local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
        if not targetHRP then stopFollow() return end
        rootPart.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
    end)
end

FollowBtn.MouseButton1Click:Connect(function()
    if FollowActive then stopFollow() return end
    if not CurrentTarget then return end
    refreshCharacterRefs()
    startFollowToTarget(CurrentTarget)
end)

-- ========== SEND PART ==========
SendPartBtn.MouseButton1Click:Connect(function()
    SendPartActive = not SendPartActive
    if SendPartActive then
        SendPartBtn.Text = "SENDING..."
        TweenService:Create(SendPartBtn, TweenInfo.new(0.3), {BackgroundColor3 = COL_GREEN}):Play()
        freezeCharacter()
        if not SendPartLoopThread then
            SendPartLoopThread = task.spawn(function()
                while SendPartActive do
                    if CurrentTarget and CurrentTarget.Character then
                        pcall(function() sendUnanchoredPartsToTarget(CurrentTarget) end)
                    end
                    task.wait(2.2)
                end
                SendPartLoopThread = nil
            end)
        end
    else
        SendPartBtn.Text = "SEND PART"
        TweenService:Create(SendPartBtn, TweenInfo.new(0.3), {BackgroundColor3 = BG_BTN}):Play()
        unfreezeCharacter()
    end
end)

-- ========== INIT ==========
task.defer(function()
    refreshTargetList()
    if #TargetList > 0 then
        CurrentIndex = 1
        CurrentTarget = TargetList[1]
        updateProfile(CurrentTarget)
    end
end)
