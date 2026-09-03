-- Simple GUI dengan 10 Button + Loadstring + Info Text
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Konfigurasi Warna
local CONFIG = {
    StrokeColor = Color3.fromRGB(70, 130, 255),
    BackgroundColor = Color3.fromRGB(15, 20, 35),
    SecondaryColor = Color3.fromRGB(25, 30, 45),
    TextColor = Color3.fromRGB(240, 245, 255),
    AccentColor = Color3.fromRGB(70, 130, 255)
}

-- Buat ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SIEXTHERTELEPORT"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 420, 0, 280)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -140)
MainFrame.BackgroundColor3 = CONFIG.BackgroundColor
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = CONFIG.StrokeColor
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- Header / Title Bar
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = CONFIG.SecondaryColor
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 12)
HeaderFix.Position = UDim2.new(0, 0, 1, -12)
HeaderFix.BackgroundColor3 = CONFIG.SecondaryColor
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

-- Title
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SIEXTHER TELEPORT"
Title.TextColor3 = CONFIG.StrokeColor
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Close Button (X)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
CloseBtn.BackgroundColor3 = CONFIG.BackgroundColor
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.TextSize = 22
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

-- Container untuk 10 Button
local ButtonContainer = Instance.new("Frame")
ButtonContainer.Name = "ButtonContainer"
ButtonContainer.Size = UDim2.new(1, -40, 0, 160)
ButtonContainer.Position = UDim2.new(0, 20, 0, 50)
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Parent = MainFrame

-- Buat 10 Button (5 kolom x 2 baris)
local buttonSize = 70
local buttonSpacing = 8
local startX = (ButtonContainer.AbsoluteSize.X - (5 * buttonSize + 4 * buttonSpacing)) / 2
local startY = 10

for i = 1, 10 do
    local row = math.floor((i - 1) / 5)
    local col = (i - 1) % 5
    
    local Button = Instance.new("TextButton")
    Button.Name = "Button" .. i
    Button.Size = UDim2.new(0, buttonSize, 0, buttonSize)
    Button.Position = UDim2.new(0, col * (buttonSize + buttonSpacing), 0, startY + row * (buttonSize + buttonSpacing))
    Button.AnchorPoint = Vector2.new(0, 0)
    Button.BackgroundColor3 = CONFIG.AccentColor
    Button.Text = tostring(i)
    Button.TextColor3 = CONFIG.TextColor
    Button.TextSize = 24
    Button.Font = Enum.Font.GothamBold
    Button.BorderSizePixel = 0
    Button.Parent = ButtonContainer
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 10)
    BtnCorner.Parent = Button
    
    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Color = CONFIG.StrokeColor
    BtnStroke.Thickness = 2
    BtnStroke.Parent = Button
    
    Button.MouseButton1Click:Connect(function()
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/8z/" .. i .. ".lua"))()
    end)
    
    if not success then
        warn("Failed to load script " .. i .. ": " .. tostring(err))
    end
end)
    
    -- Hover Effect
    Button.MouseEnter:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(90, 150, 255)
        }):Play()
    end)
    
    Button.MouseLeave:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.2), {
            BackgroundColor3 = CONFIG.AccentColor
        }):Play()
    end)
end

-- Info Text di bawah buttons
local InfoText = Instance.new("TextLabel")
InfoText.Name = "InfoText"
InfoText.Size = UDim2.new(1, -40, 0, 60)
InfoText.Position = UDim2.new(0, 20, 0, 215)
InfoText.BackgroundTransparency = 1
InfoText.Text = "INI ADALAH TELEPORT DENGAN BERBEDA-BEDA FILE, JADI KALIAN BISA SIMPAN FILE UNTUK MOUNT YANG BERBEDA ASAL DI INGET AJA YA TARO DI NOMOR BERAPA. KALO 10 MASIH KURANG BISA LAPOR AJA HEHE BIAR NANNTI DI TAMBAHIN. ENJOY!"
InfoText.TextColor3 = Color3.fromRGB(180, 190, 210)
InfoText.TextSize = 9
InfoText.Font = Enum.Font.Gotham
InfoText.TextXAlignment = Enum.TextXAlignment.Center
InfoText.TextYAlignment = Enum.TextYAlignment.Top
InfoText.TextWrapped = true
InfoText.Parent = MainFrame

-- Close Button Functionality
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Hover effect untuk Close Button
CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    }):Play()
end)

CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = CONFIG.BackgroundColor
    }):Play()
end)

-- Drag Functionality
local dragging = false
local dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(
        startPos.X.Scale, 
        startPos.X.Offset + delta.X, 
        startPos.Y.Scale, 
        startPos.Y.Offset + delta.Y
    )
end

Header.InputBegan:Connect(function(input)
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

Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Parent ke CoreGui
ScreenGui.Parent = game.CoreGui