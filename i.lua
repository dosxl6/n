local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local lp = Players.LocalPlayer
local mouse = lp:GetMouse()

-- Avatar Persistence System
local AvatarData = {
    currentUsername = nil,
    currentUserId = nil,
    currentDescription = nil,
    isEnabled = false
}

-- Save/Load Functions
local function saveAvatarData()
    if not AvatarData.isEnabled then return end
    
    local data = {
        username = AvatarData.currentUsername,
        userId = AvatarData.currentUserId,
        enabled = AvatarData.isEnabled
    }
    
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    
    if success then
        writefile("ilhanava.json", encoded)
        print("✅ Avatar data saved to ilhanava.json")
    else
        warn("❌ Failed to save avatar data")
    end
end

local function loadAvatarData()
    if not isfile or not readfile then
        warn("⚠️ File functions not available")
        return false
    end
    
    if not isfile("ilhanava.json") then
        print("ℹ️ No saved avatar data found")
        return false
    end
    
    local success, content = pcall(function()
        return readfile("ilhanava.json")
    end)
    
    if not success then
        warn("❌ Failed to read avatar data")
        return false
    end
    
    local success2, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    
    if success2 and data.username and data.enabled then
        AvatarData.currentUsername = data.username
        AvatarData.currentUserId = data.userId
        AvatarData.isEnabled = data.enabled
        print("✅ Loaded saved avatar: " .. data.username)
        return true
    end
    
    return false
end

local function clearAvatarData()
    AvatarData.currentUsername = nil
    AvatarData.currentUserId = nil
    AvatarData.currentDescription = nil
    AvatarData.isEnabled = false
    
    if writefile then
        local success = pcall(function()
            writefile("ilhanava.json", HttpService:JSONEncode({enabled = false}))
        end)
        if success then
            print("🗑️ Avatar data cleared")
        end
    end
end

-- UI State Management
local UIState = {
    isOpen = false,
    isAnimating = false
}

-- Drag Function
local function makeDraggable(frame)
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
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

-- Toggle Button Creation
local function createToggleButton()
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(0, 41, 0, 41)
    ToggleButton.Position = UDim2.new(0, 15, 0.5, -22.5)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Text = "🎮"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextScaled = true
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.ZIndex = 5
    
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 12)
    ToggleCorner.Parent = ToggleButton
    
    
    makeDraggable(ToggleButton)
    
    return ToggleButton
end

-- Modern UI Creation
local function createUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "RobloxAccountLoader"
    ScreenGui.Parent = lp.PlayerGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local ToggleButton = createToggleButton()
    ToggleButton.Parent = ScreenGui
    
    -- Main Frame - Ukuran lebih kecil
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 280, 0, 340)
    MainFrame.Position = UDim2.new(0.5, -140, 0.5, -170)
    MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    MainFrame.Visible = false
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = MainFrame
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(70, 130, 255)
    MainStroke.Thickness = 2
    MainStroke.Parent = MainFrame
    
    makeDraggable(MainFrame)
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 32)
    TitleBar.Position = UDim2.new(0, 0, 0, 0)
    TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 12)
    TitleCorner.Parent = TitleBar
    
    -- Title Text
    local TitleText = Instance.new("TextLabel")
    TitleText.Name = "TitleText"
    TitleText.Size = UDim2.new(1, -40, 1, 0)
    TitleText.Position = UDim2.new(0, 10, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "SIEXTHER AVATAR CHANGER"
    TitleText.TextColor3 = Color3.fromRGB(70, 130, 255)
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextSize = 14
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar
    
    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 26, 0, 26)
    CloseButton.Position = UDim2.new(1, -29, 0, 3)
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 60, 70)
    CloseButton.BorderSizePixel = 0
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 14
    CloseButton.Parent = TitleBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 8)
    CloseCorner.Parent = CloseButton
    
    -- Input Frame
    local InputFrame = Instance.new("Frame")
    InputFrame.Name = "InputFrame"
    InputFrame.Size = UDim2.new(1, -20, 0, 28)
    InputFrame.Position = UDim2.new(0, 10, 0, 42)
    InputFrame.BackgroundTransparency = 1
    InputFrame.Parent = MainFrame
    
    -- Username Input
    local UsernameInput = Instance.new("TextBox")
    UsernameInput.Name = "UsernameInput"
    UsernameInput.Size = UDim2.new(0.65, -2, 1, 0)
    UsernameInput.Position = UDim2.new(0, 0, 0, 0)
    UsernameInput.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    UsernameInput.BorderSizePixel = 0
    UsernameInput.Text = ""
    UsernameInput.PlaceholderText = "Enter username..."
    UsernameInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    UsernameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    UsernameInput.Font = Enum.Font.Gotham
    UsernameInput.TextSize = 13
    UsernameInput.Parent = InputFrame
    
    local UsernameCorner = Instance.new("UICorner")
    UsernameCorner.CornerRadius = UDim.new(0, 6)
    UsernameCorner.Parent = UsernameInput
    
    -- Submit Button
    local SubmitButton = Instance.new("TextButton")
    SubmitButton.Name = "SubmitButton"
    SubmitButton.Size = UDim2.new(0.35, -2, 1, 0)
    SubmitButton.Position = UDim2.new(0.65, 0, 0, 0)
    SubmitButton.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    SubmitButton.BorderSizePixel = 0
    SubmitButton.Text = "SAVE"
    SubmitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubmitButton.Font = Enum.Font.GothamBold
    SubmitButton.TextSize = 12
    SubmitButton.Parent = InputFrame
    
    local SubmitCorner = Instance.new("UICorner")
    SubmitCorner.CornerRadius = UDim.new(0, 6)
    SubmitCorner.Parent = SubmitButton
    
    -- Persistence Frame
    local PersistenceFrame = Instance.new("Frame")
    PersistenceFrame.Name = "PersistenceFrame"
    PersistenceFrame.Size = UDim2.new(1, -20, 0, 28)
    PersistenceFrame.Position = UDim2.new(0, 10, 0, 78)
    PersistenceFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    PersistenceFrame.BorderSizePixel = 0
    PersistenceFrame.Parent = MainFrame
    
    local PersistenceCorner = Instance.new("UICorner")
    PersistenceCorner.CornerRadius = UDim.new(0, 6)
    PersistenceCorner.Parent = PersistenceFrame
    
    -- Persistence Label
    local PersistenceLabel = Instance.new("TextLabel")
    PersistenceLabel.Name = "PersistenceLabel"
    PersistenceLabel.Size = UDim2.new(0.68, 0, 1, 0)
    PersistenceLabel.Position = UDim2.new(0, 8, 0, 0)
    PersistenceLabel.BackgroundTransparency = 1
    PersistenceLabel.Text = "Keep After Death"
    PersistenceLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    PersistenceLabel.Font = Enum.Font.GothamBold
    PersistenceLabel.TextSize = 11
    PersistenceLabel.TextXAlignment = Enum.TextXAlignment.Left
    PersistenceLabel.Parent = PersistenceFrame
    
    -- Reset Button
    local ResetButton = Instance.new("TextButton")
    ResetButton.Name = "ResetButton"
    ResetButton.Size = UDim2.new(0.30, -4, 0, 22)
    ResetButton.Position = UDim2.new(0.70, 0, 0, 3)
    ResetButton.BackgroundColor3 = Color3.fromRGB(255, 80, 60)
    ResetButton.BorderSizePixel = 0
    ResetButton.Text = "RESET"
    ResetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ResetButton.Font = Enum.Font.GothamBold
    ResetButton.TextSize = 10
    ResetButton.Parent = PersistenceFrame
    
    local ResetCorner = Instance.new("UICorner")
    ResetCorner.CornerRadius = UDim.new(0, 5)
    ResetCorner.Parent = ResetButton
    
    -- Player List Label
    local PlayerListLabel = Instance.new("TextLabel")
    PlayerListLabel.Name = "PlayerListLabel"
    PlayerListLabel.Size = UDim2.new(1, -20, 0, 22)
    PlayerListLabel.Position = UDim2.new(0, 10, 0, 114)
    PlayerListLabel.BackgroundTransparency = 1
    PlayerListLabel.Text = "SELECT PLAYER"
    PlayerListLabel.TextColor3 = Color3.fromRGB(70, 130, 255)
    PlayerListLabel.Font = Enum.Font.GothamBold
    PlayerListLabel.TextSize = 12
    PlayerListLabel.TextXAlignment = Enum.TextXAlignment.Left
    PlayerListLabel.Parent = MainFrame
    
    -- Scrolling Frame
    local PlayerScrollFrame = Instance.new("ScrollingFrame")
    PlayerScrollFrame.Name = "PlayerScrollFrame"
    PlayerScrollFrame.Size = UDim2.new(1, -20, 0, 175)
    PlayerScrollFrame.Position = UDim2.new(0, 10, 0, 140)
    PlayerScrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    PlayerScrollFrame.BorderSizePixel = 0
    PlayerScrollFrame.ScrollBarThickness = 4
    PlayerScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
    PlayerScrollFrame.Parent = MainFrame
    
    local PlayerScrollCorner = Instance.new("UICorner")
    PlayerScrollCorner.CornerRadius = UDim.new(0, 6)
    PlayerScrollCorner.Parent = PlayerScrollFrame
    
    local PlayerListLayout = Instance.new("UIListLayout")
    PlayerListLayout.Name = "PlayerListLayout"
    PlayerListLayout.SortOrder = Enum.SortOrder.Name
    PlayerListLayout.Padding = UDim.new(0, 4)
    PlayerListLayout.Parent = PlayerScrollFrame
    
    local PlayerScrollPadding = Instance.new("UIPadding")
    PlayerScrollPadding.PaddingTop = UDim.new(0, 4)
    PlayerScrollPadding.PaddingBottom = UDim.new(0, 4)
    PlayerScrollPadding.PaddingLeft = UDim.new(0, 4)
    PlayerScrollPadding.PaddingRight = UDim.new(0, 4)
    PlayerScrollPadding.Parent = PlayerScrollFrame
    
    -- Status Text
    local StatusText = Instance.new("TextLabel")
    StatusText.Name = "StatusText"
    StatusText.Size = UDim2.new(1, -20, 0, 14)
    StatusText.Position = UDim2.new(0, 10, 0, 320)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "HANN.SIEXTHER"
    StatusText.TextColor3 = Color3.fromRGB(120, 120, 120)
    StatusText.Font = Enum.Font.Gotham
    StatusText.TextSize = 10
    StatusText.TextXAlignment = Enum.TextXAlignment.Center
    StatusText.Parent = MainFrame
    
    return ScreenGui, MainFrame, UsernameInput, StatusText, ToggleButton, SubmitButton, CloseButton, PlayerScrollFrame, PersistenceLabel, ResetButton
end

-- Advanced Avatar Loading Function
local function loadAvatar(username, enablePersistence)
    if not username or username == "" then
        return false, "Username tidak boleh kosong!"
    end
    
    local success, userId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)
    
    if not success then
        return false, "Username tidak ditemukan"
    end
    
    if not lp.Character then
        return false, "Character tidak ada!"
    end
    
    local success2, humanoidDesc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(userId)
    end)
    
    if not success2 then
        return false, "Gagal mendapatkan avatar"
    end
    
    if enablePersistence then
        AvatarData.currentUsername = username
        AvatarData.currentUserId = userId
        AvatarData.currentDescription = humanoidDesc
        AvatarData.isEnabled = true
        saveAvatarData()
    end
    
    local success_clear = pcall(function()
        for _, accessory in pairs(lp.Character:GetChildren()) do
            if accessory:IsA("Accessory") then
                accessory:Destroy()
            end
        end
        
        for _, clothing in pairs(lp.Character:GetChildren()) do
            if clothing:IsA("Shirt") or clothing:IsA("Pants") or clothing:IsA("ShirtGraphic") then
                clothing:Destroy()
            end
        end
        
        wait(0.1)
    end)
    
    if not success_clear then
        return false, "Gagal membersihkan avatar lama"
    end
    
    local success3 = pcall(function()
        lp.Character.Humanoid:ApplyDescriptionClientServer(humanoidDesc)
        wait(0.5)
    end)
    
    if not success3 then
        return false, "Gagal mengubah avatar"
    end
    
    return true, "Avatar changed to: " .. username
end

-- Apply saved avatar
local function applySavedAvatar()
    if not AvatarData.isEnabled or not AvatarData.currentUsername then
        return false
    end
    
    if not lp.Character or not lp.Character:FindFirstChild("Humanoid") then
        return false
    end
    
    print("🔄 Reapplying saved avatar: " .. AvatarData.currentUsername)
    
    local success, humanoidDesc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(AvatarData.currentUserId)
    end)
    
    if not success then
        warn("❌ Failed to get saved avatar description")
        return false
    end
    
    pcall(function()
        for _, accessory in pairs(lp.Character:GetChildren()) do
            if accessory:IsA("Accessory") then
                accessory:Destroy()
            end
        end
        
        for _, clothing in pairs(lp.Character:GetChildren()) do
            if clothing:IsA("Shirt") or clothing:IsA("Pants") or clothing:IsA("ShirtGraphic") then
                clothing:Destroy()
            end
        end
    end)
    
    wait(0.2)
    
    local success2 = pcall(function()
        lp.Character.Humanoid:ApplyDescriptionClientServer(humanoidDesc)
    end)
    
    if success2 then
        print("✅ Saved avatar reapplied successfully")
        return true
    else
        warn("❌ Failed to reapply saved avatar")
        return false
    end
end

-- Update Player List
local function updatePlayerList(scrollFrame, usernameInput, statusText, persistenceLabel)
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local players = Players:GetPlayers()
    
    for i, player in ipairs(players) do
        local PlayerContainer = Instance.new("Frame")
        PlayerContainer.Name = player.Name .. "Container"
        PlayerContainer.Size = UDim2.new(1, -8, 0, 44)
        PlayerContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        PlayerContainer.BorderSizePixel = 0
        PlayerContainer.Parent = scrollFrame
        
        local ContainerCorner = Instance.new("UICorner")
        ContainerCorner.CornerRadius = UDim.new(0, 6)
        ContainerCorner.Parent = PlayerContainer
        
        local PlayerButton = Instance.new("TextButton")
        PlayerButton.Name = player.Name
        PlayerButton.Size = UDim2.new(1, 0, 1, 0)
        PlayerButton.Position = UDim2.new(0, 0, 0, 0)
        PlayerButton.BackgroundTransparency = 1
        PlayerButton.Text = ""
        PlayerButton.Parent = PlayerContainer
        
        local AvatarImage = Instance.new("ImageLabel")
        AvatarImage.Name = "AvatarImage"
        AvatarImage.Size = UDim2.new(0, 36, 0, 36)
        AvatarImage.Position = UDim2.new(0, 4, 0, 4)
        AvatarImage.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        AvatarImage.BorderSizePixel = 0
        AvatarImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=48&h=48"
        AvatarImage.ScaleType = Enum.ScaleType.Fit
        AvatarImage.Parent = PlayerContainer
        
        local AvatarCorner = Instance.new("UICorner")
        AvatarCorner.CornerRadius = UDim.new(0, 5)
        AvatarCorner.Parent = AvatarImage
        
        local PlayerNameLabel = Instance.new("TextLabel")
        PlayerNameLabel.Name = "PlayerNameLabel"
        PlayerNameLabel.Size = UDim2.new(1, -48, 0, 18)
        PlayerNameLabel.Position = UDim2.new(0, 44, 0, 6)
        PlayerNameLabel.BackgroundTransparency = 1
        PlayerNameLabel.Text = player.Name .. (player == lp and " (You)" or "")
        PlayerNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        PlayerNameLabel.Font = Enum.Font.GothamBold
        PlayerNameLabel.TextSize = 12
        PlayerNameLabel.TextXAlignment = Enum.TextXAlignment.Left
        PlayerNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        PlayerNameLabel.Parent = PlayerContainer
        
        local DisplayNameLabel = Instance.new("TextLabel")
        DisplayNameLabel.Name = "DisplayNameLabel"
        DisplayNameLabel.Size = UDim2.new(1, -48, 0, 14)
        DisplayNameLabel.Position = UDim2.new(0, 44, 0, 24)
        DisplayNameLabel.BackgroundTransparency = 1
        DisplayNameLabel.Text = "@" .. player.Name
        DisplayNameLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
        DisplayNameLabel.Font = Enum.Font.Gotham
        DisplayNameLabel.TextSize = 10
        DisplayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
        DisplayNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        DisplayNameLabel.Parent = PlayerContainer
        
        PlayerButton.MouseButton1Click:Connect(function()
            usernameInput.Text = player.Name
            
            statusText.Text = "⏳ Loading " .. player.Name .. "'s avatar..."
            statusText.TextColor3 = Color3.fromRGB(255, 200, 0)
            
            local success, message = loadAvatar(player.Name, true)
            
            if success then
                statusText.Text = "✅ " .. message .. " (Persistent)"
                statusText.TextColor3 = Color3.fromRGB(0, 255, 100)
                persistenceLabel.Text = "Saved: " .. player.Name
                persistenceLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
                
                wait(3)
                statusText.Text = "HANN.SIEXTHER"
                statusText.TextColor3 = Color3.fromRGB(120, 120, 120)
            else
                statusText.Text = "❌ " .. message
                statusText.TextColor3 = Color3.fromRGB(255, 80, 80)
                
                wait(3)
                statusText.Text = "HANN.SIEXTHER"
                statusText.TextColor3 = Color3.fromRGB(120, 120, 120)
            end
        end)
        
        PlayerButton.MouseEnter:Connect(function()
            TweenService:Create(PlayerContainer, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 45)}):Play()
        end)
        
        PlayerButton.MouseLeave:Connect(function()
            TweenService:Create(PlayerContainer, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 35)}):Play()
        end)
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #players * 48 + 8)
end

-- Toggle UI (Tanpa animasi close)
local function toggleUI(mainFrame, toggleButton)
    if UIState.isAnimating then return end
    
    UIState.isOpen = not UIState.isOpen
    mainFrame.Visible = UIState.isOpen
    
    if UIState.isOpen then
        toggleButton.Text = "❌"
        toggleButton.BackgroundColor3 = Color3.fromRGB(255, 60, 70)
    else
        toggleButton.Text = "🎮"
        toggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    end
end

-- Destroy Script
local function destroyScript(screenGui)
    screenGui:Destroy()
    print("🔴 Avatar Changer Script Destroyed!")
end

-- Main Script
local ScreenGui, MainFrame, UsernameInput, StatusText, ToggleButton, SubmitButton, CloseButton, PlayerScrollFrame, PersistenceLabel, ResetButton = createUI()

local hasSavedData = loadAvatarData()
if hasSavedData and AvatarData.currentUsername then
    PersistenceLabel.Text = "Saved: " .. AvatarData.currentUsername
    PersistenceLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    
    task.wait(2)
    if lp.Character and lp.Character:FindFirstChild("Humanoid") then
        applySavedAvatar()
    end
end

updatePlayerList(PlayerScrollFrame, UsernameInput, StatusText, PersistenceLabel)

lp.CharacterAdded:Connect(function(character)
    print("🔄 Character respawned, checking for saved avatar...")
    character:WaitForChild("Humanoid")
    task.wait(1)
    
    if AvatarData.isEnabled and AvatarData.currentUsername then
        print("🔄 Reapplying avatar: " .. AvatarData.currentUsername)
        applySavedAvatar()
    else
        print("ℹ️ No saved avatar to apply")
    end
end)

ToggleButton.MouseButton1Click:Connect(function()
    toggleUI(MainFrame, ToggleButton)
end)

CloseButton.MouseButton1Click:Connect(function()
    StatusText.Text = "⚠️ Destroying script..."
    StatusText.TextColor3 = Color3.fromRGB(255, 100, 0)
    wait(0.3)
    destroyScript(ScreenGui)
end)

SubmitButton.MouseButton1Click:Connect(function()
    local username = UsernameInput.Text
    if username and username ~= "" then
        UsernameInput.Text = ""
        StatusText.Text = "⏳ Loading avatar..."
        StatusText.TextColor3 = Color3.fromRGB(255, 200, 0)
        
        local success, message = loadAvatar(username, true)
        
        if success then
            StatusText.Text = "✅ " .. message .. " (Persistent)"
            StatusText.TextColor3 = Color3.fromRGB(0, 255, 100)
            PersistenceLabel.Text = "Saved: " .. username
            PersistenceLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
            
            wait(3)
            StatusText.Text = "HANN.SIEXTHER"
            StatusText.TextColor3 = Color3.fromRGB(120, 120, 120)
        else
            StatusText.Text = "❌ " .. message
            StatusText.TextColor3 = Color3.fromRGB(255, 80, 80)
            
            wait(3)
            StatusText.Text = "HANN.SIEXTHER"
            StatusText.TextColor3 = Color3.fromRGB(120, 120, 120)
        end
    end
end)

ResetButton.MouseButton1Click:Connect(function()
    clearAvatarData()
    
    PersistenceLabel.Text = "Keep After Death"
    PersistenceLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    
    StatusText.Text = "🗑️ Avatar persistence disabled"
    StatusText.TextColor3 = Color3.fromRGB(255, 150, 0)
    
    if lp.Character and lp.Character:FindFirstChild("Humanoid") then
        local success = pcall(function()
            for _, accessory in pairs(lp.Character:GetChildren()) do
                if accessory:IsA("Accessory") then
                    accessory:Destroy()
                end
            end
            
            for _, clothing in pairs(lp.Character:GetChildren()) do
                if clothing:IsA("Shirt") or clothing:IsA("Pants") or clothing:IsA("ShirtGraphic") then
                    clothing:Destroy()
                end
            end
            
            wait(0.2)
            
            local defaultDesc = Players:GetHumanoidDescriptionFromUserId(lp.UserId)
            lp.Character.Humanoid:ApplyDescriptionClientServer(defaultDesc)
        end)
        
        if success then
            StatusText.Text = "✅ Reset to default avatar"
            StatusText.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            StatusText.Text = "⚠️ Persistence disabled (respawn to reset)"
            StatusText.TextColor3 = Color3.fromRGB(255, 200, 0)
        end
    end
    
    wait(3)
    StatusText.Text = "HANN.SIEXTHER"
    StatusText.TextColor3 = Color3.fromRGB(120, 120, 120)
end)

-- Hover Effects
ToggleButton.MouseEnter:Connect(function()
    if not UIState.isOpen then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    end
end)

ToggleButton.MouseLeave:Connect(function()
    if not UIState.isOpen then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    end
end)

SubmitButton.MouseEnter:Connect(function()
    SubmitButton.BackgroundColor3 = Color3.fromRGB(90, 150, 255)
end)

SubmitButton.MouseLeave:Connect(function()
    SubmitButton.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
end)

CloseButton.MouseEnter:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 80, 90)
end)

CloseButton.MouseLeave:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 60, 70)
end)

ResetButton.MouseEnter:Connect(function()
    ResetButton.BackgroundColor3 = Color3.fromRGB(255, 100, 80)
end)

ResetButton.MouseLeave:Connect(function()
    ResetButton.BackgroundColor3 = Color3.fromRGB(255, 80, 60)
end)

-- Enter key functionality
UsernameInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local username = UsernameInput.Text
        if username and username ~= "" then
            UsernameInput.Text = ""
            StatusText.Text = "⏳ Loading avatar..."
            StatusText.TextColor3 = Color3.fromRGB(255, 200, 0)
            
            local success, message = loadAvatar(username, true)
            
            if success then
                StatusText.Text = "✅ " .. message .. " (Persistent)"
                StatusText.TextColor3 = Color3.fromRGB(0, 255, 100)
                PersistenceLabel.Text = "Saved: " .. username
                PersistenceLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
                
                wait(3)
                StatusText.Text = "HANN.SIEXTHER"
                StatusText.TextColor3 = Color3.fromRGB(120, 120, 120)
            else
                StatusText.Text = "❌ " .. message
                StatusText.TextColor3 = Color3.fromRGB(255, 80, 80)
                
                wait(3)
                StatusText.Text = "HANN.SIEXTHER"
                StatusText.TextColor3 = Color3.fromRGB(120, 120, 120)
            end
        end
    end
end)

-- Keyboard Shortcut (F1)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F1 then
        toggleUI(MainFrame, ToggleButton)
    end
end)

-- Update player list when players join/leave
Players.PlayerAdded:Connect(function()
    wait(0.5)
    updatePlayerList(PlayerScrollFrame, UsernameInput, StatusText, PersistenceLabel)
end)

Players.PlayerRemoving:Connect(function()
    wait(0.1)
    updatePlayerList(PlayerScrollFrame, UsernameInput, StatusText, PersistenceLabel)
end)

-- Periodic check for avatar persistence
task.spawn(function()
    while wait(5) do
        if AvatarData.isEnabled and lp.Character and lp.Character:FindFirstChild("Humanoid") then
            local currentAccessories = 0
            for _, child in pairs(lp.Character:GetChildren()) do
                if child:IsA("Accessory") then
                    currentAccessories = currentAccessories + 1
                end
            end
            
            if currentAccessories == 0 and AvatarData.currentDescription then
                print("⚠️ Avatar detected as reset, reapplying...")
                applySavedAvatar()
            end
        end
    end
end)
