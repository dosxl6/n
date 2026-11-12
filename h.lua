local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local BLACKLIST = {
    "rejoin",
    "resetcheckpoint",
    "resetcp",
    "backtobasecamp",
    "backbc",
    "basecamp",
    "respawn",
    "teleport",
    "afk",
    "afkglobal"
}

-- Function untuk cek apakah remote di-blacklist
local function isBlacklisted(remoteName)
    local lowerName = remoteName:lower()
    for _, keyword in ipairs(BLACKLIST) do
        if lowerName:find(keyword:lower()) then
            return true
        end
    end
    return false
end

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RemoteFirer"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame (UKURAN DIPERKECIL)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "SIEXTHERDOMB"
mainFrame.Size = UDim2.new(0, 260, 0, 300)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -180)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(70, 130, 255)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -90, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SIEXTHER INJECTION"
titleLabel.TextColor3 = Color3.fromRGB(70, 130, 255)
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 27, 0, 27)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 18
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Floating Button
local floatingButton = Instance.new("TextButton")
floatingButton.Name = "FloatingButton"
floatingButton.Size = UDim2.new(0, 55, 0, 55)
floatingButton.Position = UDim2.new(1, -75, 1, -75)
floatingButton.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
floatingButton.BorderSizePixel = 0
floatingButton.Text = "⭐"
floatingButton.TextSize = 28
floatingButton.Font = Enum.Font.GothamBold
floatingButton.Visible = false
floatingButton.Active = true
floatingButton.Draggable = true
floatingButton.Parent = screenGui

local floatingCorner = Instance.new("UICorner")
floatingCorner.CornerRadius = UDim.new(1, 0)
floatingCorner.Parent = floatingButton

local floatingStroke = Instance.new("UIStroke")
floatingStroke.Color = Color3.fromRGB(255, 255, 255)
floatingStroke.Thickness = 2
floatingStroke.Parent = floatingButton

-- Log Display Frame
local logFrame = Instance.new("Frame")
logFrame.Name = "LogFrame"
logFrame.Size = UDim2.new(1, -16, 1, -100)
logFrame.Position = UDim2.new(0, 8, 0, 48)
logFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
logFrame.BorderSizePixel = 0
logFrame.Parent = mainFrame

local logCorner = Instance.new("UICorner")
logCorner.CornerRadius = UDim.new(0, 8)
logCorner.Parent = logFrame

local logScroll = Instance.new("ScrollingFrame")
logScroll.Name = "LogScroll"
logScroll.Size = UDim2.new(1, -10, 1, -10)
logScroll.Position = UDim2.new(0, 5, 0, 5)
logScroll.BackgroundTransparency = 1
logScroll.BorderSizePixel = 0
logScroll.ScrollBarThickness = 4
logScroll.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
logScroll.Parent = logFrame

local logLayout = Instance.new("UIListLayout")
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
logLayout.Padding = UDim.new(0, 3)
logLayout.Parent = logScroll

-- Action Button (WARNA AWAL SKY BLUE)
local actionButton = Instance.new("TextButton")
actionButton.Name = "ActionButton"
actionButton.Size = UDim2.new(1, -16, 0, 40)
actionButton.Position = UDim2.new(0, 8, 1, -48)
actionButton.BackgroundColor3 = Color3.fromRGB(70, 130, 255)  -- SKY BLUE untuk SCAN
actionButton.BorderSizePixel = 0
actionButton.Text = "SCAN"
actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
actionButton.TextSize = 15
actionButton.Font = Enum.Font.GothamBold
actionButton.Parent = mainFrame

local actionCorner = Instance.new("UICorner")
actionCorner.CornerRadius = UDim.new(0, 8)
actionCorner.Parent = actionButton

-- Variables
local isSpamming = false
local isDone = false
local remoteButtons = {}

-- Function to add log
local function addLog(message, color)
    local logEntry = Instance.new("TextLabel")
    logEntry.Size = UDim2.new(1, -5, 0, 18)
    logEntry.BackgroundTransparency = 1
    logEntry.Text = "[" .. os.date("%H:%M:%S") .. "] " .. message
    logEntry.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    logEntry.TextSize = 10
    logEntry.Font = Enum.Font.Code
    logEntry.TextXAlignment = Enum.TextXAlignment.Left
    logEntry.TextWrapped = true
    logEntry.TextYAlignment = Enum.TextYAlignment.Top
    logEntry.LayoutOrder = #logScroll:GetChildren()
    logEntry.Parent = logScroll
    
    task.wait()
    logScroll.CanvasSize = UDim2.new(0, 0, 0, logLayout.AbsoluteContentSize.Y + 10)
    logScroll.CanvasPosition = Vector2.new(0, logScroll.CanvasSize.Y.Offset)
end

-- Fire remote function
function fireRemote(remote)
    local args = {remote.Name, 42, true}
    
    if remote:IsA("RemoteEvent") then
        remote:FireServer(unpack(args))
        addLog("✓ Injection: " .. remote.Name, Color3.fromRGB(100, 255, 100))
        print("Injection RemoteEvent: " .. remote:GetFullName() .. " dengan argumen: " .. table.concat(args, ", "))
    elseif remote:IsA("RemoteFunction") then
        local success, result = pcall(function()
            return remote:InvokeServer(unpack(args))
        end)
        if success then
            addLog("✓ Dipanggil: " .. remote.Name, Color3.fromRGB(100, 200, 255))
            print("Fungsi Jarak Jauh yang Dipanggil: " .. remote:GetFullName() .. " dengan argumen: " .. table.concat(args, ", ") .. " | Hasil: " .. tostring(result))
        else
            addLog("x Gagal: " .. remote.Name, Color3.fromRGB(255, 100, 100))
            warn("Gagal memanggil RemoteFunction: " .. remote:GetFullName() .. " | Kesalahan: " .. tostring(result))
        end
    end
end

-- Populate remotes dengan FILTER BLACKLIST
local function populateRemotes()
    for _, button in ipairs(remoteButtons) do
        button:Destroy()
    end
    remoteButtons = {}
    
    local remotes = {}
    local ignoredCount = 0
    
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            if isBlacklisted(obj.Name) then
                -- SKIP remote yang di-blacklist
                ignoredCount = ignoredCount + 1
                addLog("⊘ Skip: " .. obj.Name, Color3.fromRGB(150, 150, 150))
            else
                table.insert(remotes, obj)
            end
        end
    end
    
    -- Create invisible buttons
    for _, remote in ipairs(remotes) do
        local button = Instance.new("TextButton")
        button.Name = remote.Name .. "_" .. remote:GetFullName()
        button.Visible = false
        button.Parent = screenGui
        
        button.MouseButton1Click:Connect(function()
            fireRemote(remote)
        end)
        
        table.insert(remoteButtons, button)
    end
    
    addLog("Ditemukan " .. #remotes .. " remotes (" .. ignoredCount .. " skip)", Color3.fromRGB(255, 200, 100))
    print("Ditemukan " .. #remotes .. " remotes, skip " .. ignoredCount .. " masuk daftar hitam remotes")
    
    return #remotes
end

-- Start spam
local function startSpam()
    if isSpamming or isDone then return end
    
    isSpamming = true
    actionButton.Text = "BERHENTI"
    actionButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)  -- RED untuk BERHENTI
    
    addLog("—— SCAN DIMULAI ——", Color3.fromRGB(70, 130, 255))
    
    local totalRemotes = populateRemotes()
    
    if totalRemotes == 0 then
        addLog("⚠ Tidak ada remote yang ditemukan!", Color3.fromRGB(255, 150, 50))
        stopSpam()
        return
    end
    
    spawn(function()
        addLog(">>> Siklus spam dimulai <<<", Color3.fromRGB(150, 150, 255))
        
        for i, button in ipairs(remoteButtons) do
            if not isSpamming then break end
            
            addLog("Injection [" .. i .. "/" .. #remoteButtons .. "] " .. button.Name:match("(.-)_"), Color3.fromRGB(200, 200, 255))
            
            for _, connection in pairs(getconnections(button.MouseButton1Click)) do
                connection:Fire()
            end
            
            wait(0.05)
        end
        
        if isSpamming then
            addLog(">>> Penyelesaian Injection! <<<", Color3.fromRGB(100, 255, 150))
            isSpamming = false
            isDone = true
            actionButton.Text = "SELESAI"
            actionButton.BackgroundColor3 = Color3.fromRGB(70, 130, 255)  -- Kembali SKY BLUE
        end
    end)
end

local function stopSpam()
    isSpamming = false
    if not isDone then
        actionButton.Text = "SCAN"
        actionButton.BackgroundColor3 = Color3.fromRGB(70, 130, 255)  -- Kembali SKY BLUE
        addLog("—— SCAN DIBERHENTIKAN ——", Color3.fromRGB(220, 50, 50))
    end
end

-- Button Events
actionButton.MouseButton1Click:Connect(function()
    if isDone then
        screenGui:Destroy()
    elseif isSpamming then
        stopSpam()
    else
        startSpam()
    end
end)

floatingButton.MouseButton1Click:Connect(function()
    floatingButton.Visible = false
    mainFrame.Visible = true
end)

closeButton.MouseButton1Click:Connect(function()
    isSpamming = false
    screenGui:Destroy()
end)

-- Hover effects
local function addHoverEffect(button, hoverColor, normalColor)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = normalColor}):Play()
    end)
end

addHoverEffect(actionButton, Color3.fromRGB(90, 150, 255), Color3.fromRGB(70, 130, 255))
addHoverEffect(closeButton, Color3.fromRGB(255, 70, 70), Color3.fromRGB(220, 50, 50))
addHoverEffect(floatingButton, Color3.fromRGB(90, 150, 255), Color3.fromRGB(70, 130, 255))

-- Initial log
addLog("—————————————————————————", Color3.fromRGB(70, 130, 255))
addLog("        S I E X T H E R     ", Color3.fromRGB(70, 130, 255))
addLog("—————————————————————————", Color3.fromRGB(70, 130, 255))
addLog("Klik SCAN untuk memulai scanning backdoor...", Color3.fromRGB(150, 150, 150))