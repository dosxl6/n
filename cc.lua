local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

loadstring(game:HttpGet("https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/han.lua"))()

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SIEXTHERDOPE"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999 
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 200, 0, 115)
mainFrame.Position = UDim2.new(0.8, -100, 0.5, -57.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(70, 130, 255)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -30, 0, 20)
title.Position = UDim2.new(0, 8, 0, 5)
title.BackgroundTransparency = 1
title.Text = "SIEXTHER COPYHAT"
title.TextColor3 = Color3.fromRGB(200, 200, 200)
title.TextSize = 11
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

-- Button Close (X)
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 18, 0, 18)
closeButton.Position = UDim2.new(1, -23, 0, 6)
closeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 70, 70)
closeButton.TextSize = 11
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeButton

-- Fungsi Close
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Hover Effect Close Button
closeButton.MouseEnter:Connect(function()
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
end)

closeButton.MouseLeave:Connect(function()
    closeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    closeButton.TextColor3 = Color3.fromRGB(255, 70, 70)
end)

-- Container untuk Grid Compact
local gridContainer = Instance.new("Frame")
gridContainer.Name = "GridContainer"
gridContainer.Size = UDim2.new(1, -16, 1, -33)
gridContainer.Position = UDim2.new(0, 8, 0, 28)
gridContainer.BackgroundTransparency = 1
gridContainer.Parent = mainFrame

-- Data Button dengan Hat IDs
local buttonData = {
    {name = "COPYHAT 1", row = 1, col = 1, hatID = "hat 127226449989167"},
    {name = "COPYHAT 2", row = 1, col = 2, hatID = "hat 96655874457685"},
    {name = "COPYHAT 3", row = 1, col = 3, hatID = "hat 123402086843885"},
    {name = "COPYHAT 4", row = 2, col = 1, hatID = "hat 78300682916056"},
    {name = "COPYHAT 5", row = 2, col = 2, hatID = "hat 86276701020724"},
    {name = "COPYHAT 6", row = 2, col = 3, hatID = "hat 135683585167755"}
}

local cellWidth = 57
local cellHeight = 40
local spacing = 5

-- Membuat Button Papan
for i, data in ipairs(buttonData) do
    local button = Instance.new("TextButton")
    button.Name = "Button" .. i
    button.Size = UDim2.new(0, cellWidth, 0, cellHeight)
    button.Position = UDim2.new(0, (data.col - 1) * (cellWidth + spacing), 0, (data.row - 1) * (cellHeight + spacing))
    button.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
    button.Text = data.name
    button.TextColor3 = Color3.fromRGB(180, 180, 180)
    button.TextSize = 9
    button.Font = Enum.Font.GothamBold
    button.TextWrapped = true
    button.Parent = gridContainer
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = button
    
    -- Tambahkan UIStroke untuk setiap button
    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Color = Color3.fromRGB(40, 40, 45)
    buttonStroke.Thickness = 1
    buttonStroke.Transparency = 0.5
    buttonStroke.Parent = button
    
    -- Click Effect dengan Fungsi Copy Hat ID
    button.MouseButton1Click:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        buttonStroke.Color = Color3.fromRGB(70, 130, 255)
        buttonStroke.Thickness = 2
        buttonStroke.Transparency = 0
        
        -- Copy Hat ID to clipboard
        if setclipboard then
            setclipboard(data.hatID)
            getgenv().Notify({
                Title = "BERHASIL", 
                Content = data.name .. " TELAH DICOPY KE CLIPBOARD",
                Duration = 2
            })
        else
            getgenv().Notify({
                Title = "TERJADI KESALAHAN", 
                Content = "EXECUTOR TIDAK SUPPORT CLIPBOARD",
                Duration = 3
            })
        end
        
        wait(0.15)
        
        button.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        button.TextColor3 = Color3.fromRGB(180, 180, 180)
        buttonStroke.Color = Color3.fromRGB(40, 40, 45)
        buttonStroke.Thickness = 1
        buttonStroke.Transparency = 0.5
    end)
    
    -- Hover Effect
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        button.TextColor3 = Color3.fromRGB(70, 130, 255)
        buttonStroke.Transparency = 0
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        button.TextColor3 = Color3.fromRGB(180, 180, 180)
        buttonStroke.Color = Color3.fromRGB(40, 40, 45)
        buttonStroke.Transparency = 0.5
    end)
end