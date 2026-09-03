-- Player Teleport GUI Script - Modern Dark Theme
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TeleportGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame (ukuran diperkecil)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 320)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BackgroundTransparency = 0
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- Blue Stroke untuk Main Frame
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(70, 130, 255)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
TopBar.BackgroundTransparency = 0
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 12)
TopCorner.Parent = TopBar

local TopBarBottom = Instance.new("Frame")
TopBarBottom.Size = UDim2.new(1, 0, 0, 12)
TopBarBottom.Position = UDim2.new(0, 0, 1, -12)
TopBarBottom.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
TopBarBottom.BackgroundTransparency = 0
TopBarBottom.BorderSizePixel = 0
TopBarBottom.Parent = TopBar

-- Title
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SIEXTHER TELEPORT"
Title.TextColor3 = Color3.fromRGB(70, 130, 255)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Minimize Button
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.new(0, 24, 0, 24)
MinimizeButton.Position = UDim2.new(1, -56, 0.5, -12)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
MinimizeButton.Text = "–"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.TextSize = 18
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Parent = TopBar

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 6)
MinimizeCorner.Parent = MinimizeButton

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 24, 0, 24)
CloseButton.Position = UDim2.new(1, -28, 0.5, -12)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 60, 80)
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 20
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

-- Search Box
local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.Size = UDim2.new(1, -20, 0, 32)
SearchBox.Position = UDim2.new(0, 10, 0, 50)
SearchBox.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
SearchBox.BackgroundTransparency = 0
SearchBox.BorderSizePixel = 0
SearchBox.PlaceholderText = "Cari player..."
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(220, 220, 220)
SearchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
SearchBox.TextSize = 13
SearchBox.Font = Enum.Font.Gotham
SearchBox.Parent = MainFrame

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 8)
SearchCorner.Parent = SearchBox

-- Player List Frame
local ListFrame = Instance.new("ScrollingFrame")
ListFrame.Name = "ListFrame"
ListFrame.Size = UDim2.new(1, -20, 1, -95)
ListFrame.Position = UDim2.new(0, 10, 0, 87)
ListFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
ListFrame.BackgroundTransparency = 0
ListFrame.BorderSizePixel = 0
ListFrame.ScrollBarThickness = 4
ListFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
ListFrame.Parent = MainFrame

local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 8)
ListCorner.Parent = ListFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 6)
ListLayout.SortOrder = Enum.SortOrder.Name
ListLayout.Parent = ListFrame

-- Minimized Button
local MinimizedButton = Instance.new("TextButton")
MinimizedButton.Name = "MinimizedButton"
MinimizedButton.Size = UDim2.new(0, 41, 0, 41)
MinimizedButton.Position = UDim2.new(1, -60, 0.5, -19)
MinimizedButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MinimizedButton.Text = "⚡"
MinimizedButton.TextColor3 = Color3.fromRGB(70, 130, 255)
MinimizedButton.TextSize = 20
MinimizedButton.Font = Enum.Font.GothamBold
MinimizedButton.Visible = false
MinimizedButton.Parent = ScreenGui

local MinimizedCorner = Instance.new("UICorner")
MinimizedCorner.CornerRadius = UDim.new(0, 12)
MinimizedCorner.Parent = MinimizedButton

-- Dragging functionality
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

TopBar.InputBegan:Connect(function(input)
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

TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Teleport Function
local function teleportToPlayer(targetPlayer)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
        end
    end
end

-- Update Player List dengan Avatar
local function updatePlayerList()
    for _, child in pairs(ListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local searchText = SearchBox.Text:lower()
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if searchText == "" or player.Name:lower():find(searchText) or player.DisplayName:lower():find(searchText) then
                local PlayerButton = Instance.new("TextButton")
                PlayerButton.Name = player.Name
                PlayerButton.Size = UDim2.new(1, -10, 0, 40)
                PlayerButton.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
                PlayerButton.BackgroundTransparency = 0
                PlayerButton.Text = ""
                PlayerButton.Parent = ListFrame
                
                local ButtonCorner = Instance.new("UICorner")
                ButtonCorner.CornerRadius = UDim.new(0, 8)
                ButtonCorner.Parent = PlayerButton
                
                -- Avatar Image (reduced quality untuk load cepat)
                local Avatar = Instance.new("ImageLabel")
                Avatar.Name = "Avatar"
                Avatar.Size = UDim2.new(0, 30, 0, 30)
                Avatar.Position = UDim2.new(0, 5, 0.5, -15)
                Avatar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                Avatar.BorderSizePixel = 0
                Avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..player.UserId.."&width=48&height=48&format=png"
                Avatar.Parent = PlayerButton
                
                local AvatarCorner = Instance.new("UICorner")
                AvatarCorner.CornerRadius = UDim.new(1, 0)
                AvatarCorner.Parent = Avatar
                
                -- Player Name Label
                local NameLabel = Instance.new("TextLabel")
                NameLabel.Size = UDim2.new(1, -45, 1, 0)
                NameLabel.Position = UDim2.new(0, 40, 0, 0)
                NameLabel.BackgroundTransparency = 1
                NameLabel.Text = player.DisplayName .. " (@" .. player.Name .. ")"
                NameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
                NameLabel.TextSize = 12
                NameLabel.Font = Enum.Font.Gotham
                NameLabel.TextXAlignment = Enum.TextXAlignment.Left
                NameLabel.Parent = PlayerButton
                
                PlayerButton.MouseButton1Click:Connect(function()
                    teleportToPlayer(player)
                    PlayerButton.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
                    wait(0.3)
                    PlayerButton.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
                end)
                
                PlayerButton.MouseEnter:Connect(function()
                    PlayerButton.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
                end)
                
                PlayerButton.MouseLeave:Connect(function()
                    PlayerButton.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
                end)
            end
        end
    end
    
    ListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 8)
end

-- Search functionality
SearchBox:GetPropertyChangedSignal("Text"):Connect(updatePlayerList)

-- Close Button
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Minimize/Maximize functionality
local isMinimized = false

MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = true
    MainFrame.Visible = false
    MinimizedButton.Visible = true
end)

MinimizedButton.MouseButton1Click:Connect(function()
    isMinimized = false
    MainFrame.Visible = true
    MinimizedButton.Visible = false
end)

-- Button hover effects
CloseButton.MouseEnter:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 80, 100)
end)

CloseButton.MouseLeave:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 60, 80)
end)

MinimizeButton.MouseEnter:Connect(function()
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(90, 150, 255)
end)

MinimizeButton.MouseLeave:Connect(function()
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
end)

-- Update player list on player join/leave
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)

-- Initial update
updatePlayerList()