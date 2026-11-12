local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Variables
local autoHeadsitEnabled = false
local autoHeadsitConnection = nil
local godModeConnection = nil
local movementConnection = nil
local currentTarget = nil
local selectedPlayer = nil
local currentAnimation = nil
local currentMode = 1 

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SIEXTHERHANN"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 240, 0, 345)
mainFrame.Position = UDim2.new(0.5, -120, 0.5, -203)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
mainFrame.BackgroundTransparency = 0
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Add rounded corners
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Add Blue Stroke to Main Frame
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(70, 130, 255)
mainStroke.Thickness = 2
mainStroke.Transparency = 0
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
mainStroke.Parent = mainFrame

-- Create Top Bar
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 38)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
topBar.BackgroundTransparency = 0
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 12)
topBarCorner.Parent = topBar

-- Fix bottom corners of topBar
local topBarFix = Instance.new("Frame")
topBarFix.Size = UDim2.new(1, 0, 0, 12)
topBarFix.Position = UDim2.new(0, 0, 1, -12)
topBarFix.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
topBarFix.BackgroundTransparency = 0
topBarFix.BorderSizePixel = 0
topBarFix.Parent = topBar

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -70, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "SIEXTHER KIMOCHI"
title.TextColor3 = Color3.fromRGB(70, 130, 255)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

-- Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, 26, 0, 26)
minimizeBtn.Position = UDim2.new(1, -58, 0.5, -13)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
minimizeBtn.Text = "–"
minimizeBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
minimizeBtn.TextSize = 18
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = topBar

local minimizeBtnCorner = Instance.new("UICorner")
minimizeBtnCorner.CornerRadius = UDim.new(0, 6)
minimizeBtnCorner.Parent = minimizeBtn

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -28, 0.5, -13)
closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 70, 90)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = topBar

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent = closeBtn

-- Content Frame
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -20, 1, -48)
contentFrame.Position = UDim2.new(0, 10, 0, 43)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "STATUS: TIDAK AKTIF"
statusLabel.TextColor3 = Color3.fromRGB(255, 70, 90)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Parent = contentFrame

-- Player List Label
local playerListLabel = Instance.new("TextLabel")
playerListLabel.Name = "PlayerListLabel"
playerListLabel.Size = UDim2.new(1, 0, 0, 16)
playerListLabel.Position = UDim2.new(0, 0, 0, 22)
playerListLabel.BackgroundTransparency = 1
playerListLabel.Text = "Pilih Player:"
playerListLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
playerListLabel.TextSize = 11
playerListLabel.Font = Enum.Font.Gotham
playerListLabel.TextXAlignment = Enum.TextXAlignment.Left
playerListLabel.Parent = contentFrame

-- Search Box
local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, 0, 0, 30)
searchBox.Position = UDim2.new(0, 0, 0, 40)
searchBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
searchBox.BackgroundTransparency = 0
searchBox.BorderSizePixel = 0
searchBox.PlaceholderText = "Cari Player..."
searchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
searchBox.Text = ""
searchBox.TextColor3 = Color3.fromRGB(200, 200, 210)
searchBox.TextSize = 11
searchBox.Font = Enum.Font.Gotham
searchBox.ClearTextOnFocus = false
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Parent = contentFrame

local searchBoxCorner = Instance.new("UICorner")
searchBoxCorner.CornerRadius = UDim.new(0, 6)
searchBoxCorner.Parent = searchBox

local searchBoxPadding = Instance.new("UIPadding")
searchBoxPadding.PaddingLeft = UDim.new(0, 8)
searchBoxPadding.PaddingRight = UDim.new(0, 8)
searchBoxPadding.Parent = searchBox

-- Player Count Label
local playerCountLabel = Instance.new("TextLabel")
playerCountLabel.Name = "PlayerCountLabel"
playerCountLabel.Size = UDim2.new(1, 0, 0, 14)
playerCountLabel.Position = UDim2.new(0, 0, 0, 74)
playerCountLabel.BackgroundTransparency = 1
playerCountLabel.Text = "PLAYERS: 0"
playerCountLabel.TextColor3 = Color3.fromRGB(120, 120, 130)
playerCountLabel.TextSize = 9
playerCountLabel.Font = Enum.Font.Gotham
playerCountLabel.TextXAlignment = Enum.TextXAlignment.Left
playerCountLabel.Parent = contentFrame

-- Player List ScrollFrame
local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Name = "PlayerListFrame"
playerListFrame.Size = UDim2.new(1, 0, 0, 95)
playerListFrame.Position = UDim2.new(0, 0, 0, 90)
playerListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
playerListFrame.BackgroundTransparency = 0
playerListFrame.BorderSizePixel = 0
playerListFrame.ScrollBarThickness = 3
playerListFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
playerListFrame.Parent = contentFrame

local playerListCorner = Instance.new("UICorner")
playerListCorner.CornerRadius = UDim.new(0, 6)
playerListCorner.Parent = playerListFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 3)
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Parent = playerListFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 3)
listPadding.PaddingBottom = UDim.new(0, 3)
listPadding.PaddingLeft = UDim.new(0, 3)
listPadding.PaddingRight = UDim.new(0, 3)
listPadding.Parent = playerListFrame

-- Mode Selection Frame
local modeFrame = Instance.new("Frame")
modeFrame.Name = "ModeFrame"
modeFrame.Size = UDim2.new(1, 0, 0, 34)
modeFrame.Position = UDim2.new(0, 0, 0, 193)
modeFrame.BackgroundTransparency = 1
modeFrame.Parent = contentFrame

-- Mode 1 Button (Sit)
local mode1Btn = Instance.new("TextButton")
mode1Btn.Name = "Mode1Btn"
mode1Btn.Size = UDim2.new(0.48, 0, 1, 0)
mode1Btn.Position = UDim2.new(0, 0, 0, 0)
mode1Btn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
mode1Btn.Text = "KIMOCHI"
mode1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
mode1Btn.TextSize = 11
mode1Btn.Font = Enum.Font.GothamBold
mode1Btn.BorderSizePixel = 0
mode1Btn.Parent = modeFrame

local mode1BtnCorner = Instance.new("UICorner")
mode1BtnCorner.CornerRadius = UDim.new(0, 6)
mode1BtnCorner.Parent = mode1Btn

-- Mode 2 Button (Stand)
local mode2Btn = Instance.new("TextButton")
mode2Btn.Name = "Mode2Btn"
mode2Btn.Size = UDim2.new(0.48, 0, 1, 0)
mode2Btn.Position = UDim2.new(0.52, 0, 0, 0)
mode2Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
mode2Btn.Text = "RODOK"
mode2Btn.TextColor3 = Color3.fromRGB(150, 150, 160)
mode2Btn.TextSize = 11
mode2Btn.Font = Enum.Font.GothamBold
mode2Btn.BorderSizePixel = 0
mode2Btn.Parent = modeFrame

local mode2BtnCorner = Instance.new("UICorner")
mode2BtnCorner.CornerRadius = UDim.new(0, 6)
mode2BtnCorner.Parent = mode2Btn

-- Toggle Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleBtn"
toggleBtn.Size = UDim2.new(1, 0, 0, 38)
toggleBtn.Position = UDim2.new(0, 0, 0, 235)
toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
toggleBtn.Text = "AKTIFKAN"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 13
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = contentFrame

local toggleBtnCorner = Instance.new("UICorner")
toggleBtnCorner.CornerRadius = UDim.new(0, 7)
toggleBtnCorner.Parent = toggleBtn

-- Info Label
local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "InfoLabel"
infoLabel.Size = UDim2.new(1, 0, 0, 16)
infoLabel.Position = UDim2.new(0, 0, 1, -16)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Pilih pemain yang ingin ditargetkan!"
infoLabel.TextColor3 = Color3.fromRGB(130, 130, 140)
infoLabel.TextSize = 10
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextWrapped = true
infoLabel.Parent = contentFrame

-- Minimized Button (Fire)
local fireBtn = Instance.new("TextButton")
fireBtn.Name = "FireBtn"
fireBtn.Size = UDim2.new(0, 41, 0, 41)
fireBtn.Position = UDim2.new(1, -70, 0.5, -22)
fireBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
fireBtn.Text = "SX"
fireBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
fireBtn.TextSize = 25
fireBtn.Font = Enum.Font.GothamBold
fireBtn.BorderSizePixel = 0
fireBtn.Visible = false
fireBtn.Active = true
fireBtn.Draggable = true
fireBtn.Parent = screenGui

-- Gradient Animation untuk Minimized Button
local MinimizedGradient = Instance.new("UIGradient")
MinimizedGradient.Parent = fireBtn
MinimizedGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
MinimizedGradient.Offset = Vector2.new(-1, 0)

task.spawn(function()
    while fireBtn and fireBtn.Parent do
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

local fireBtnCorner = Instance.new("UICorner")
fireBtnCorner.CornerRadius = UDim.new(0, 12)
fireBtnCorner.Parent = fireBtn

-- God Mode Function
local function enableGodMode()
    if godModeConnection then
        godModeConnection:Disconnect()
    end
    
    godModeConnection = RunService.Heartbeat:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            local humanoid = char.Humanoid
            
            if humanoid.Health < humanoid.MaxHealth then
                humanoid.Health = humanoid.MaxHealth
            end
            
            humanoid.MaxHealth = math.huge
            humanoid.Health = math.huge
        end
    end)
end

local function disableGodMode()
    if godModeConnection then
        godModeConnection:Disconnect()
        godModeConnection = nil
    end
    
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        local humanoid = char.Humanoid
        humanoid.MaxHealth = 100
        humanoid.Health = 100
    end
end

-- Load and play animation
local function loadAnimation()
    local char = player.Character
    if not char then return end
    
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    if currentAnimation then
        currentAnimation:Stop()
        currentAnimation = nil
    end
    
    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://698251653"
    
    currentAnimation = humanoid:LoadAnimation(animation)
    currentAnimation.Looped = false
    currentAnimation:Play()
    currentAnimation.TimePosition = 0.58
    currentAnimation:AdjustSpeed(0.4)
    
    task.spawn(function()
        while currentAnimation and currentAnimation.IsPlaying and autoHeadsitEnabled do
            if currentAnimation.TimePosition >= 0.63 then
                currentAnimation.TimePosition = 0.58
            end
            task.wait()
        end
    end)
end

-- Fungsi animasi maju mundur untuk Mode 1 (Sit)
local function startForwardBackwardMovement()
    if movementConnection then
        movementConnection:Disconnect()
    end
    
    local movementSpeed = 15
    local movementDistance = 0.3
    local time = 0
    
    movementConnection = RunService.Heartbeat:Connect(function(deltaTime)
        time = time + deltaTime * movementSpeed
        
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            return
        end
        
        if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("Head") then
            local targetHead = selectedPlayer.Character.Head
            local targetHRP = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if targetHRP then
                local targetLook = targetHRP.CFrame.LookVector
                local headPosition = targetHead.CFrame.Position
                
                -- Tambahkan offset maju mundur menggunakan sin wave
                local forwardBackwardOffset = math.sin(time) * movementDistance
                
                local offsetPosition = headPosition + Vector3.new(0, 0.4, 0) - (targetLook * (-1.8 + forwardBackwardOffset))
                local oppositeLook = -targetLook
                
                char.HumanoidRootPart.CFrame = CFrame.new(
                    offsetPosition,
                    offsetPosition + oppositeLook
                )
            end
        end
    end)
end

-- Fungsi untuk Mode 2 (Stand Behind) dengan speed 35
local function startStandBehindMovement()
    if movementConnection then
        movementConnection:Disconnect()
    end
    
    local movementSpeed = 25
    local movementDistance = 0.3
    local time = 0
    
    movementConnection = RunService.Heartbeat:Connect(function(deltaTime)
        time = time + deltaTime * movementSpeed
        
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            return
        end
        
        if selectedPlayer and selectedPlayer.Character then
            local targetHRP = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if targetHRP then
                local targetLook = targetHRP.CFrame.LookVector
                local targetPosition = targetHRP.CFrame.Position
                
                -- Tambahkan offset maju mundur menggunakan sin wave
                local forwardBackwardOffset = math.sin(time) * movementDistance
                
                -- Posisi di belakang target dengan jarak 2 studs + animasi maju mundur
                local offsetPosition = targetPosition - (targetLook * (1 + forwardBackwardOffset))
                
                -- Menghadap ke arah yang sama dengan target
                char.HumanoidRootPart.CFrame = CFrame.new(
                    offsetPosition,
                    offsetPosition + targetLook
                )
            end
        end
    end)
end

local function stopForwardBackwardMovement()
    if movementConnection then
        movementConnection:Disconnect()
        movementConnection = nil
    end
end

-- Functions
local function updatePlayerList(searchText)
    searchText = searchText or ""
    searchText = searchText:lower()
    
    for _, child in pairs(playerListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local playerCount = 0
    
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local displayName = otherPlayer.DisplayName:lower()
            local userName = otherPlayer.Name:lower()
            
            if searchText == "" or displayName:find(searchText, 1, true) or userName:find(searchText, 1, true) then
                playerCount = playerCount + 1
                
                local playerBtn = Instance.new("TextButton")
                playerBtn.Name = otherPlayer.Name
                playerBtn.Size = UDim2.new(1, -6, 0, 36)
                playerBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
                playerBtn.BackgroundTransparency = 0
                playerBtn.BorderSizePixel = 0
                playerBtn.Text = ""
                playerBtn.AutoButtonColor = false
                playerBtn.Parent = playerListFrame
                
                local playerBtnCorner = Instance.new("UICorner")
                playerBtnCorner.CornerRadius = UDim.new(0, 5)
                playerBtnCorner.Parent = playerBtn
                
                -- Avatar Image
                local avatarImg = Instance.new("ImageLabel")
                avatarImg.Name = "Avatar"
                avatarImg.Size = UDim2.new(0, 28, 0, 28)
                avatarImg.Position = UDim2.new(0, 4, 0.5, -14)
                avatarImg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                avatarImg.BorderSizePixel = 0
                avatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. otherPlayer.UserId .. "&w=48&h=48"
                avatarImg.Parent = playerBtn
                
                local avatarCorner = Instance.new("UICorner")
                avatarCorner.CornerRadius = UDim.new(0, 14)
                avatarCorner.Parent = avatarImg
                
                -- Display Name
                local displayNameLabel = Instance.new("TextLabel")
                displayNameLabel.Size = UDim2.new(1, -42, 0, 14)
                displayNameLabel.Position = UDim2.new(0, 36, 0, 4)
                displayNameLabel.BackgroundTransparency = 1
                displayNameLabel.Text = otherPlayer.DisplayName
                displayNameLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
                displayNameLabel.TextSize = 11
                displayNameLabel.Font = Enum.Font.GothamBold
                displayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
                displayNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                displayNameLabel.Parent = playerBtn
                
                -- Username
                local userNameLabel = Instance.new("TextLabel")
                userNameLabel.Size = UDim2.new(1, -42, 0, 11)
                userNameLabel.Position = UDim2.new(0, 36, 0, 18)
                userNameLabel.BackgroundTransparency = 1
                userNameLabel.Text = "@" .. otherPlayer.Name
                userNameLabel.TextColor3 = Color3.fromRGB(120, 120, 130)
                userNameLabel.TextSize = 9
                userNameLabel.Font = Enum.Font.Gotham
                userNameLabel.TextXAlignment = Enum.TextXAlignment.Left
                userNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                userNameLabel.Parent = playerBtn
                
                playerBtn.MouseButton1Click:Connect(function()
                    selectedPlayer = otherPlayer
                    
                    for _, btn in pairs(playerListFrame:GetChildren()) do
                        if btn:IsA("TextButton") then
                            btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
                        end
                    end
                    
                    playerBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
                    infoLabel.Text = "Selected: " .. otherPlayer.DisplayName
                end)
                
                playerBtn.MouseEnter:Connect(function()
                    if selectedPlayer ~= otherPlayer then
                        TweenService:Create(playerBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 45)}):Play()
                    end
                end)
                
                playerBtn.MouseLeave:Connect(function()
                    if selectedPlayer ~= otherPlayer then
                        TweenService:Create(playerBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(25, 25, 35)}):Play()
                    end
                end)
            end
        end
    end
    
    playerCountLabel.Text = "Players: " .. playerCount
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 6)
end

local function startHeadsit()
    if autoHeadsitConnection then
        autoHeadsitConnection:Disconnect()
    end
    
    if not selectedPlayer then
        infoLabel.Text = "Silahkan pilih target dulu!"
        return
    end
    
    enableGodMode()
    
    if currentMode == 1 then
        -- Mode 1: Sit
        loadAnimation()
        startForwardBackwardMovement()
        
        autoHeadsitConnection = RunService.Heartbeat:Connect(function()
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then
                return
            end
            
            if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("Head") then
                currentTarget = selectedPlayer.Name
                
                if char:FindFirstChild("Humanoid") then
                    char.Humanoid.Sit = true
                end
            else
                infoLabel.Text = "Pemain target tidak ditemukan!"
                infoLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
            end
        end)
    else
        -- Mode 2: Stand Behind dengan animasi
        loadAnimation()  -- Tetap pakai animasi
        startStandBehindMovement()  -- Pakai movement maju mundur dengan speed 35
        
        autoHeadsitConnection = RunService.Heartbeat:Connect(function()
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then
                return
            end
            
            if selectedPlayer and selectedPlayer.Character then
                currentTarget = selectedPlayer.Name
                
                -- Tidak set Sit = true, biarkan berdiri
                if char:FindFirstChild("Humanoid") then
                    char.Humanoid.Sit = false
                end
            else
                infoLabel.Text = "Pemain target tidak ditemukan!"
                infoLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
            end
        end)
    end
end

local function stopHeadsit()
    if autoHeadsitConnection then
        autoHeadsitConnection:Disconnect()
        autoHeadsitConnection = nil
    end
    
    stopForwardBackwardMovement()
    
    if currentAnimation then
        currentAnimation:Stop()
        currentAnimation = nil
    end
    
    disableGodMode()
    
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.Sit = false
        char.Humanoid.PlatformStand = false
    end
    
    currentTarget = nil
end

-- Fungsi untuk mengganti mode dengan restart otomatis jika sedang aktif
local function switchMode(newMode)
    if currentMode == newMode then
        return -- Sudah di mode yang sama
    end
    
    local wasEnabled = autoHeadsitEnabled
    
    -- Jika sedang aktif, stop dulu
    if wasEnabled then
        stopHeadsit()
    end
    
    -- Ganti mode
    currentMode = newMode
    
    -- Update tampilan button
    if currentMode == 1 then
        mode1Btn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        mode1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        mode2Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        mode2Btn.TextColor3 = Color3.fromRGB(150, 150, 160)
    else
        mode2Btn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        mode2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        mode1Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        mode1Btn.TextColor3 = Color3.fromRGB(150, 150, 160)
    end
    
    -- Jika sebelumnya aktif, start lagi dengan mode baru
    if wasEnabled then
        startHeadsit()
        
        -- Update info label
        if currentMode == 1 then
            infoLabel.Text = "KIMOCHI: " .. selectedPlayer.DisplayName
        else
            infoLabel.Text = "RODOK: " .. selectedPlayer.DisplayName
        end
        infoLabel.TextColor3 = Color3.fromRGB(70, 255, 130)
    else
        -- Update info label untuk mode yang dipilih
        if currentMode == 1 then
            infoLabel.Text = "Mode Kimochi"
        else
            infoLabel.Text = "Mode Rodok"
        end
        infoLabel.TextColor3 = Color3.fromRGB(70, 130, 255)
    end
end

-- Mode Selection - Sekarang bisa ganti kapan saja
mode1Btn.MouseButton1Click:Connect(function()
    switchMode(1)
end)

mode2Btn.MouseButton1Click:Connect(function()
    switchMode(2)
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    updatePlayerList(searchBox.Text)
end)

searchBox.Focused:Connect(function()
    searchBox.PlaceholderText = "Ketik untuk mencari..."
end)

searchBox.FocusLost:Connect(function()
    searchBox.PlaceholderText = "Cari player..."
end)

toggleBtn.MouseButton1Click:Connect(function()
    if not selectedPlayer then
        infoLabel.Text = "Silahkan pilih target dulu!"
        infoLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
        
        TweenService:Create(toggleBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(255, 150, 100)}):Play()
        wait(0.1)
        TweenService:Create(toggleBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(70, 130, 255)}):Play()
        
        wait(2)
        infoLabel.TextColor3 = Color3.fromRGB(130, 130, 140)
        infoLabel.Text = "Pilih pemain yang ingin ditargetkan!"
        return
    end
    
    autoHeadsitEnabled = not autoHeadsitEnabled
    
    if autoHeadsitEnabled then
        toggleBtn.Text = "MATIKAN"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 90)
        statusLabel.Text = "STATUS: AKTIF"
        statusLabel.TextColor3 = Color3.fromRGB(70, 255, 130)
        
        if currentMode == 1 then
            infoLabel.Text = "KIMOCHI: " .. selectedPlayer.DisplayName
        else
            infoLabel.Text = "FOLLOWING: " .. selectedPlayer.DisplayName
        end
        
        infoLabel.TextColor3 = Color3.fromRGB(70, 255, 130)
        startHeadsit()
    else
        toggleBtn.Text = "AKTIFKAN"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        statusLabel.Text = "STATUS: TIDAK AKTIF"
        statusLabel.TextColor3 = Color3.fromRGB(255, 70, 90)
        infoLabel.Text = "Pilih pemain yang ingin ditargetkan!"
        infoLabel.TextColor3 = Color3.fromRGB(130, 130, 140)
        stopHeadsit()
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(mainFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    TweenService:Create(mainStroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
    for _, child in pairs(mainFrame:GetDescendants()) do
        if child:IsA("GuiObject") then
            local props = {BackgroundTransparency = 1}
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                props.TextTransparency = 1
            end
            TweenService:Create(child, TweenInfo.new(0.3), props):Play()
        end
    end
    
    wait(0.3)
    stopHeadsit()
    screenGui:Destroy()
end)

minimizeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    fireBtn.Visible = true
end)

fireBtn.MouseButton1Click:Connect(function()
    fireBtn.Visible = false
    mainFrame.Visible = true
end)

local function addHoverEffect(btn, normalColor, hoverColor)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = normalColor}):Play()
    end)
end

addHoverEffect(closeBtn, Color3.fromRGB(30, 30, 40), Color3.fromRGB(255, 70, 90))
addHoverEffect(minimizeBtn, Color3.fromRGB(30, 30, 40), Color3.fromRGB(70, 130, 255))
addHoverEffect(fireBtn, Color3.fromRGB(15, 15, 20), Color3.fromRGB(70, 130, 255))

-- Hover effects untuk mode buttons
mode1Btn.MouseEnter:Connect(function()
    if currentMode ~= 1 then
        TweenService:Create(mode1Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
    end
end)

mode1Btn.MouseLeave:Connect(function()
    if currentMode ~= 1 then
        TweenService:Create(mode1Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
    end
end)

mode2Btn.MouseEnter:Connect(function()
    if currentMode ~= 2 then
        TweenService:Create(mode2Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
    end
end)

mode2Btn.MouseLeave:Connect(function()
    if currentMode ~= 2 then
        TweenService:Create(mode2Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
    end
end)

toggleBtn.MouseEnter:Connect(function()
    if autoHeadsitEnabled then
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 50, 70)}):Play()
    else
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(90, 150, 255)}):Play()
    end
end)

toggleBtn.MouseLeave:Connect(function()
    if autoHeadsitEnabled then
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 70, 90)}):Play()
    else
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 130, 255)}):Play()
    end
end)

updatePlayerList()

Players.PlayerAdded:Connect(function()
    wait(0.5)
    updatePlayerList(searchBox.Text)
end)

Players.PlayerRemoving:Connect(function(removingPlayer)
    updatePlayerList(searchBox.Text)
    
    if selectedPlayer == removingPlayer then
        selectedPlayer = nil
        if autoHeadsitEnabled then
            autoHeadsitEnabled = false
            toggleBtn.Text = "AKTIFKAN"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
            statusLabel.Text = "STATUS: TIDAK AKTIF"
            statusLabel.TextColor3 = Color3.fromRGB(255, 70, 90)
            infoLabel.Text = "Pemain yang menjadi target keluar dari permainan."
            infoLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
            stopHeadsit()
        end
    end
end)