-- SIEXTHER HANN.SXTHR

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Fungsi untuk mendapatkan region dari ping
local function getPingRegion(ping)
    if ping < 80 then
        return "Indonesia"
    elseif ping < 120 then
        return "Singapore"
    elseif ping < 180 then
        return "Asia"
    elseif ping < 250 then
        return "US/Europe"
    else
        return "International"
    end
end

-- Fungsi untuk menambahkan stroke
local function addStroke(parent)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(70, 130, 255)
    stroke.Thickness = 2
    stroke.Parent = parent
    return stroke
end

-- Buat ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ServerBrowserGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Background Frame (Super compact)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 420, 0, 340)
mainFrame.Position = UDim2.new(0.5, -210, 0.45, -170)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 15)
mainCorner.Parent = mainFrame

addStroke(mainFrame)

-- Close Button (X)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 15
closeBtn.ZIndex = 10
closeBtn.Parent = mainFrame

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 5)
closeBtnCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Header
local headerFrame = Instance.new("Frame")
headerFrame.Name = "Header"
headerFrame.Size = UDim2.new(1, -14, 0, 55)
headerFrame.Position = UDim2.new(0, 7, 0, 7)
headerFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
headerFrame.BorderSizePixel = 0
headerFrame.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 8)
headerCorner.Parent = headerFrame

addStroke(headerFrame)

-- Current Game Title
local gameTitle = Instance.new("TextLabel")
gameTitle.Name = "GameTitle"
gameTitle.Size = UDim2.new(1, -14, 0, 22)
gameTitle.Position = UDim2.new(0, 7, 0, 5)
gameTitle.BackgroundTransparency = 1
gameTitle.Text = "Current Game: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
gameTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
gameTitle.Font = Enum.Font.GothamBold
gameTitle.TextSize = 13
gameTitle.TextTruncate = Enum.TextTruncate.AtEnd
gameTitle.Parent = headerFrame

-- Button Container
local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "ButtonContainer"
buttonContainer.Size = UDim2.new(1, -14, 0, 24)
buttonContainer.Position = UDim2.new(0, 7, 0, 28)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = headerFrame

local buttonLayout = Instance.new("UIListLayout")
buttonLayout.FillDirection = Enum.FillDirection.Horizontal
buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonLayout.Padding = UDim.new(0, 5)
buttonLayout.Parent = buttonContainer

-- Fungsi untuk membuat button
local function createButton(text, name)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 85, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 9
    btn.Parent = buttonContainer
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 13)
    btnCorner.Parent = btn
    
    return btn
end

local fastestPingBtn = createButton("Fastest Ping", "FastestPing")
local lowestPlayersBtn = createButton("Lowest Players", "LowestPlayers")
local maxPlayersBtn = createButton("Max Players", "MaxPlayers")

-- Info Bar
local infoBar = Instance.new("Frame")
infoBar.Name = "InfoBar"
infoBar.Size = UDim2.new(1, -20, 0, 26)
infoBar.Position = UDim2.new(0, 10, 0, 68)
infoBar.BackgroundTransparency = 1
infoBar.Parent = mainFrame

local serverCount = Instance.new("TextLabel")
serverCount.Name = "ServerCount"
serverCount.Size = UDim2.new(0.6, 0, 1, 0)
serverCount.BackgroundTransparency = 1
serverCount.Text = "Loaded 0 servers."
serverCount.TextColor3 = Color3.fromRGB(180, 180, 180)
serverCount.Font = Enum.Font.Gotham
serverCount.TextSize = 11
serverCount.TextXAlignment = Enum.TextXAlignment.Left
serverCount.Parent = infoBar

local refreshBtn = Instance.new("TextButton")
refreshBtn.Name = "RefreshBtn"
refreshBtn.Size = UDim2.new(0, 70, 1, 0)
refreshBtn.Position = UDim2.new(1, -70, 0, 0)
refreshBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
refreshBtn.Text = "Refresh"
refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshBtn.Font = Enum.Font.GothamSemibold
refreshBtn.TextSize = 10
refreshBtn.Parent = infoBar

local refreshCorner = Instance.new("UICorner")
refreshCorner.CornerRadius = UDim.new(0, 5)
refreshCorner.Parent = refreshBtn

-- Server List ScrollingFrame
local serverList = Instance.new("ScrollingFrame")
serverList.Name = "ServerList"
serverList.Size = UDim2.new(1, -20, 1, -104)
serverList.Position = UDim2.new(0, 10, 0, 98)
serverList.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
serverList.BorderSizePixel = 0
serverList.ScrollBarThickness = 4
serverList.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
serverList.Parent = mainFrame

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 7)
listCorner.Parent = serverList

addStroke(serverList)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = serverList

-- Variables
local servers = {}
local currentSort = "ping"

-- Fungsi untuk membuat server entry
local function createServerEntry(index, serverData)
    local entry = Instance.new("Frame")
    entry.Name = "Server" .. index
    entry.Size = UDim2.new(1, -6, 0, 36)
    entry.BackgroundColor3 = Color3.fromRGB(22, 27, 35)
    entry.BorderSizePixel = 0
    entry.Parent = serverList
    
    local entryCorner = Instance.new("UICorner")
    entryCorner.CornerRadius = UDim.new(0, 5)
    entryCorner.Parent = entry
    
    -- Server Number
    local number = Instance.new("TextLabel")
    number.Size = UDim2.new(0, 20, 1, 0)
    number.Position = UDim2.new(0, 3, 0, 0)
    number.BackgroundTransparency = 1
    number.Text = tostring(index)
    number.TextColor3 = Color3.fromRGB(120, 120, 120)
    number.Font = Enum.Font.GothamBold
    number.TextSize = 11
    number.Parent = entry
    
    -- Players
    local players = Instance.new("TextLabel")
    players.Size = UDim2.new(0, 50, 1, 0)
    players.Position = UDim2.new(0, 26, 0, 0)
    players.BackgroundTransparency = 1
    players.Text = serverData.players .. "/" .. serverData.maxPlayers
    players.TextColor3 = Color3.fromRGB(255, 255, 255)
    players.Font = Enum.Font.GothamSemibold
    players.TextSize = 10
    players.TextXAlignment = Enum.TextXAlignment.Left
    players.Parent = entry
    
    -- Ping
    local ping = Instance.new("TextLabel")
    ping.Size = UDim2.new(0, 65, 1, 0)
    ping.Position = UDim2.new(0, 80, 0, 0)
    ping.BackgroundTransparency = 1
    ping.Text = "Ping: " .. serverData.ping
    ping.TextColor3 = Color3.fromRGB(180, 180, 180)
    ping.Font = Enum.Font.Gotham
    ping.TextSize = 9
    ping.TextXAlignment = Enum.TextXAlignment.Left
    ping.Parent = entry
    
    -- Region
    local region = Instance.new("TextLabel")
    region.Size = UDim2.new(0, 75, 1, 0)
    region.Position = UDim2.new(0, 150, 0, 0)
    region.BackgroundTransparency = 1
    region.Text = serverData.region
    region.TextColor3 = Color3.fromRGB(180, 180, 180)
    region.Font = Enum.Font.Gotham
    region.TextSize = 9
    region.TextXAlignment = Enum.TextXAlignment.Left
    region.Parent = entry
    
    -- Join Button
    local joinBtn = Instance.new("TextButton")
    joinBtn.Size = UDim2.new(0, 55, 0, 24)
    joinBtn.Position = UDim2.new(1, -60, 0.5, -12)
    joinBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 80)
    joinBtn.Text = "Join"
    joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    joinBtn.Font = Enum.Font.GothamBold
    joinBtn.TextSize = 10
    joinBtn.Parent = entry
    
    local joinCorner = Instance.new("UICorner")
    joinCorner.CornerRadius = UDim.new(0, 5)
    joinCorner.Parent = joinBtn
    
    -- Join button functionality
    joinBtn.MouseButton1Click:Connect(function()
        if serverData.jobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, serverData.jobId, player)
        end
    end)
    
    return entry
end

-- Fungsi untuk mendapatkan server list (DIPERBAIKI)
local function getServers()
    servers = {}
    
    -- Clear existing entries
    for _, child in ipairs(serverList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local cursor = ""
    local totalFetched = 0
    local maxServersToFetch = 500  -- Tambah limit untuk fetch lebih banyak server
    
    -- Get servers from Roblox API
    while totalFetched < maxServersToFetch do
        local success, result = pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
            if cursor ~= "" then
                url = url .. "&cursor=" .. cursor
            end
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        
        if success and result.data then
            for _, server in ipairs(result.data) do
                -- TIDAK ADA FILTER - ambil semua server
                totalFetched = totalFetched + 1
                table.insert(servers, {
                    jobId = server.id,
                    players = server.playing,
                    maxPlayers = server.maxPlayers,
                    ping = server.ping or math.random(20, 200),
                    region = getPingRegion(server.ping or math.random(20, 200))
                })
            end
            
            cursor = result.nextPageCursor or ""
            if cursor == "" or cursor == nil then break end
        else
            break
        end
        
        -- Delay kecil untuk menghindari rate limit
        wait(0.1)
    end
    
    serverCount.Text = "Loaded " .. #servers .. " servers."
    sortAndDisplay()
end

-- Fungsi untuk sort dan display servers
function sortAndDisplay()
    -- Sort servers
    if currentSort == "ping" then
        table.sort(servers, function(a, b) return a.ping < b.ping end)
    elseif currentSort == "players-low" then
        table.sort(servers, function(a, b) return a.players < b.players end)
    elseif currentSort == "players-high" then
        table.sort(servers, function(a, b) return a.players > b.players end)
    end
    
    -- Clear existing
    for _, child in ipairs(serverList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Display servers (tampilkan maksimal 100 untuk performa)
    local displayLimit = math.min(#servers, 100)
    for i = 1, displayLimit do
        createServerEntry(i, servers[i])
    end
    
    -- Update canvas size
    serverList.CanvasSize = UDim2.new(0, 0, 0, displayLimit * 40)
end

-- Button functions
local function setActiveButton(activeBtn)
    for _, btn in ipairs({fastestPingBtn, lowestPlayersBtn, maxPlayersBtn}) do
        if btn == activeBtn then
            btn.BackgroundColor3 = Color3.fromRGB(35, 45, 60)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
end

fastestPingBtn.MouseButton1Click:Connect(function()
    currentSort = "ping"
    setActiveButton(fastestPingBtn)
    sortAndDisplay()
end)

lowestPlayersBtn.MouseButton1Click:Connect(function()
    currentSort = "players-low"
    setActiveButton(lowestPlayersBtn)
    sortAndDisplay()
end)

maxPlayersBtn.MouseButton1Click:Connect(function()
    currentSort = "players-high"
    setActiveButton(maxPlayersBtn)
    sortAndDisplay()
end)

refreshBtn.MouseButton1Click:Connect(function()
    refreshBtn.Text = "Loading..."
    getServers()
    wait(0.5)
    refreshBtn.Text = "Refresh"
end)

-- Initialize
setActiveButton(fastestPingBtn)
wait(1)
getServers()
