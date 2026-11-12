local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Buat ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SiextherAntiStaff"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 220)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -110)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(70, 130, 255)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 8)
HeaderCorner.Parent = Header

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 8, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SIEXTHER ANTI-STAFF [BETA]"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextColor3 = Color3.fromRGB(70, 130, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Button Minimize
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 26, 0, 26)
MinimizeBtn.Position = UDim2.new(1, -56, 0, 2)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MinimizeBtn.Text = "–"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 16
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinimizeBtn.Parent = Header

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 5)
MinCorner.Parent = MinimizeBtn

-- Button Close
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -28, 0, 2)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 5)
CloseCorner.Parent = CloseBtn

-- Status Text
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -16, 0, 20)
StatusLabel.Position = UDim2.new(0, 8, 0, 38)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Scanning..."
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 10
StatusLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

-- ScrollingFrame untuk Log
local LogFrame = Instance.new("ScrollingFrame")
LogFrame.Name = "LogFrame"
LogFrame.Size = UDim2.new(1, -16, 1, -68)
LogFrame.Position = UDim2.new(0, 8, 0, 60)
LogFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
LogFrame.BorderSizePixel = 0
LogFrame.ScrollBarThickness = 3
LogFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
LogFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
LogFrame.Parent = MainFrame

local LogCorner = Instance.new("UICorner")
LogCorner.CornerRadius = UDim.new(0, 5)
LogCorner.Parent = LogFrame

local LogStroke = Instance.new("UIStroke")
LogStroke.Color = Color3.fromRGB(70, 130, 255)
LogStroke.Thickness = 1
LogStroke.Transparency = 0.5
LogStroke.Parent = LogFrame

local LogLayout = Instance.new("UIListLayout")
LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
LogLayout.Padding = UDim.new(0, 2)
LogLayout.Parent = LogFrame

-- Icon Minimized
local MinimizedIcon = Instance.new("TextButton")
MinimizedIcon.Name = "MinimizedIcon"
MinimizedIcon.Size = UDim2.new(0, 41, 0, 41)
MinimizedIcon.Position = UDim2.new(1, -65, 0, 15)
MinimizedIcon.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MinimizedIcon.Text = "⭐"
MinimizedIcon.Font = Enum.Font.GothamBold
MinimizedIcon.TextSize = 20
MinimizedIcon.Visible = false
MinimizedIcon.Draggable = true
MinimizedIcon.Parent = ScreenGui

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(0, 12)
IconCorner.Parent = MinimizedIcon

-- Variabel
local logCount = 0
local isRunning = true
local staffKeywords = {"admin", "mod", "moderator", "staff", "owner", "creator", "dev", "developer"}
local staffTitleKeywords = {
    "admin", "mod", "moderator", "staff", "owner", "creator", 
    "dev", "developer", "helper", "support", "manager", 
    "supervisor", "officer", "team", "employee"
}

-- Fungsi Log
local function addLog(text, color)
    logCount = logCount + 1
    
    local LogEntry = Instance.new("TextLabel")
    LogEntry.Size = UDim2.new(1, -8, 0, 18)
    LogEntry.BackgroundTransparency = 1
    LogEntry.Text = text
    LogEntry.Font = Enum.Font.Code
    LogEntry.TextSize = 9
    LogEntry.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    LogEntry.TextXAlignment = Enum.TextXAlignment.Left
    LogEntry.TextTruncate = Enum.TextTruncate.AtEnd
    LogEntry.LayoutOrder = logCount
    LogEntry.Parent = LogFrame
    
    LogFrame.CanvasSize = UDim2.new(0, 0, 0, LogLayout.AbsoluteContentSize.Y)
    LogFrame.CanvasPosition = Vector2.new(0, LogFrame.CanvasSize.Y.Offset)
end

-- Fungsi untuk mencari title di leaderstats
local function checkLeaderstatsTitle(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return false, nil end
    
    -- Cek semua child di leaderstats
    for _, stat in ipairs(leaderstats:GetChildren()) do
        if stat:IsA("StringValue") or stat:IsA("TextLabel") then
            local value = tostring(stat.Value):lower()
            
            for _, keyword in ipairs(staffTitleKeywords) do
                if value:find(keyword) then
                    return true, stat.Name .. ": " .. tostring(stat.Value)
                end
            end
        end
        
        -- Cek nama stat itu sendiri
        local statName = stat.Name:lower()
        if statName == "title" or statName == "rank" or statName == "role" then
            local value = tostring(stat.Value):lower()
            for _, keyword in ipairs(staffTitleKeywords) do
                if value:find(keyword) then
                    return true, stat.Name .. ": " .. tostring(stat.Value)
                end
            end
        end
    end
    
    return false, nil
end

-- Fungsi untuk mencari title di PlayerGui (overhead/nametag)
local function checkPlayerGuiTitle(player)
    local character = player.Character
    if not character then return false, nil end
    
    local head = character:FindFirstChild("Head")
    if not head then return false, nil end
    
    -- Cek BillboardGui atau TextLabel di atas kepala
    for _, obj in ipairs(head:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextBox") then
            local text = obj.Text:lower()
            
            for _, keyword in ipairs(staffTitleKeywords) do
                if text:find(keyword) then
                    return true, "Overhead: " .. obj.Text
                end
            end
        end
    end
    
    return false, nil
end

-- Fungsi Cek Staff (ENHANCED)
local function isStaff(player)
    local name = player.Name:lower()
    local displayName = player.DisplayName:lower()
    
    -- 1. Cek nama dan display name
    for _, keyword in ipairs(staffKeywords) do
        if name:find(keyword) or displayName:find(keyword) then
            addLog("🔍 Detected via name: " .. keyword, Color3.fromRGB(255, 150, 100))
            return true, "Name keyword: " .. keyword
        end
    end
    
    -- 2. Cek leaderstats title
    local hasStaffTitle, titleInfo = checkLeaderstatsTitle(player)
    if hasStaffTitle then
        addLog("🔍 Detected via leaderstats: " .. titleInfo, Color3.fromRGB(255, 150, 100))
        return true, titleInfo
    end
    
    -- 3. Cek overhead title (tunggu character load)
    task.wait(0.5)
    local hasOverheadTitle, overheadInfo = checkPlayerGuiTitle(player)
    if hasOverheadTitle then
        addLog("🔍 Detected via overhead: " .. overheadInfo, Color3.fromRGB(255, 150, 100))
        return true, overheadInfo
    end
    
    -- 4. Cek group rank (opsional)
    local success, rank = pcall(function()
        return player:GetRankInGroup(0) -- Ganti 0 dengan Group ID game
    end)
    
    if success and rank >= 250 then
        addLog("🔍 Detected via group rank: " .. rank, Color3.fromRGB(255, 150, 100))
        return true, "Group rank: " .. rank
    end
    
    return false, nil
end

-- Fungsi Server Hop
local function serverHop(reason)
    addLog("⚠️ STAFF DETECTED! Reason: " .. (reason or "Unknown"), Color3.fromRGB(255, 100, 100))
    StatusLabel.Text = "⚠️ Server Hopping!"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    
    wait(1)
    
    local success, errorMsg = pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
    
    if not success then
        addLog("❌ Hop failed: " .. tostring(errorMsg), Color3.fromRGB(255, 50, 50))
    end
end

-- Fungsi Scan Players
local function scanPlayers()
    while isRunning do
        local playerList = Players:GetPlayers()
        local totalPlayers = #playerList
        local scannedCount = 0
        
        for i, player in ipairs(playerList) do
            if not isRunning then break end
            
            if player ~= LocalPlayer then
                scannedCount = scannedCount + 1
                
                task.spawn(function()
                    addLog("[" .. scannedCount .. "/" .. totalPlayers .. "] Scan: " .. player.Name, Color3.fromRGB(150, 150, 150))
                end)
                
                local staffDetected, reason = isStaff(player)
                
                if staffDetected then
                    addLog("🚨 STAFF: " .. player.Name .. " (" .. (reason or "Unknown") .. ")", Color3.fromRGB(255, 80, 80))
                    
                    game.StarterGui:SetCore("SendNotification", {
                        Title = "⚠️ Staff Alert";
                        Text = player.Name .. " - " .. (reason or "Detected!");
                        Duration = 5;
                    })
                    
                    serverHop(reason)
                    return
                else
                    task.spawn(function()
                        addLog("✓ Safe: " .. player.Name, Color3.fromRGB(100, 200, 100))
                    end)
                end
                
                task.wait(0.3)
            end
        end
        
        StatusLabel.Text = "Semua Aman - Pemindaian Ulang..."
        StatusLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
        
        task.wait(3)
    end
end

-- Event Buttons
MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MinimizedIcon.Visible = true
end)

MinimizedIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MinimizedIcon.Visible = false
end)

CloseBtn.MouseButton1Click:Connect(function()
    isRunning = false
    ScreenGui:Destroy()
end)

-- Mulai Scanning
addLog("SIEXTHER ANTI STAFF", Color3.fromRGB(70, 130, 255))
addLog("FVCK YOU MODERATOR", Color3.fromRGB(70, 130, 255))
addLog("━━━━━━━━━━━━━━━━━━", Color3.fromRGB(70, 130, 255))


task.spawn(scanPlayers)

-- Monitor player join
Players.PlayerAdded:Connect(function(player)
    task.wait(1)
    addLog("👤 Joined: " .. player.Name, Color3.fromRGB(255, 200, 100))
    
    local staffDetected, reason = isStaff(player)
    if staffDetected then
        addLog("🚨 STAFF JOINED: " .. player.Name .. " (" .. (reason or "Unknown") .. ")", Color3.fromRGB(255, 80, 80))
        
        game.StarterGui:SetCore("SendNotification", {
            Title = "⚠️ Staff Joined!";
            Text = player.Name .. " - " .. (reason or "Detected!");
            Duration = 5;
        })
        
        serverHop(reason)
    end
end)

-- Monitor character added (untuk deteksi overhead title yang baru muncul)
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(2) -- Tunggu overhead title load
        
        local hasOverheadTitle, overheadInfo = checkPlayerGuiTitle(player)
        if hasOverheadTitle then
            addLog("🚨 STAFF OVERHEAD DETECTED: " .. player.Name, Color3.fromRGB(255, 80, 80))
            serverHop(overheadInfo)
        end
    end)
end)