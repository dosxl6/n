-- SIEXTHER - Modern Dark Blue Design
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Pengaturan ESP
local ESPSettings = {
    Enabled = true,
    ShowName = false,
    ShowHealth = false,
    ShowLine = false,
    ShowGlow = false,
    ShowNPC = false,
    ShowNPCHealth = false,
    ShowNPCDistance = false,
    ShowNPCLine = false,
    ShowItems = false,
    ShowItemDistance = false,
    ShowItemLine = false
}

local ESPObjects = {}
local NPCObjects = {}
local ItemObjects = {}

-- Fungsi untuk membuat GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ESPPlayerGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

-- Frame utama dengan modern dark design
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 400)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- Stroke biru sky untuk frame utama (hanya luar)
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(70, 130, 255)
MainStroke.Thickness = 2
MainStroke.Transparency = 0
MainStroke.Parent = MainFrame

-- Header dengan gradient effect
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 12)
HeaderFix.Position = UDim2.new(0, 0, 1, -12)
HeaderFix.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

-- Title dengan glow effect
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SIEXTHER ESP PLAYER"
Title.TextColor3 = Color3.fromRGB(70, 130, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Button Minimize (modern style)
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -65, 0.5, -15)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
MinimizeBtn.Text = "─"
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinimizeBtn.TextSize = 16
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Parent = Header

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 8)
MinimizeCorner.Parent = MinimizeBtn

-- Button Close (modern style)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -32, 0.5, -15)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 60)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

-- ScrollingFrame dengan dark design
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "ScrollFrame"
ScrollFrame.Size = UDim2.new(1, -20, 1, -55)
ScrollFrame.Position = UDim2.new(0, 10, 0, 50)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 520)
ScrollFrame.Parent = MainFrame

-- Fungsi untuk membuat divider modern
local function createDivider(yPos, text)
    local Divider = Instance.new("Frame")
    Divider.Name = "Divider"
    Divider.Size = UDim2.new(1, 0, 0, 30)
    Divider.Position = UDim2.new(0, 0, 0, yPos)
    Divider.BackgroundTransparency = 1
    Divider.Parent = ScrollFrame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(70, 130, 255)
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamBold
    Label.Parent = Divider
    
    return Divider
end

-- Fungsi untuk membuat toggle button modern
local function createToggleButton(name, yPos, setting)
    local Button = Instance.new("TextButton")
    Button.Name = name
    Button.Size = UDim2.new(1, 0, 0, 36)
    Button.Position = UDim2.new(0, 0, 0, yPos)
    Button.BackgroundColor3 = ESPSettings[setting] and Color3.fromRGB(70, 130, 255) or Color3.fromRGB(28, 28, 35)
    Button.Text = ""
    Button.BorderSizePixel = 0
    Button.Parent = ScrollFrame
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 10)
    BtnCorner.Parent = Button
    
    -- Label text
    local ButtonLabel = Instance.new("TextLabel")
    ButtonLabel.Size = UDim2.new(1, -70, 1, 0)
    ButtonLabel.Position = UDim2.new(0, 12, 0, 0)
    ButtonLabel.BackgroundTransparency = 1
    ButtonLabel.Text = name
    ButtonLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    ButtonLabel.TextSize = 13
    ButtonLabel.Font = Enum.Font.Gotham
    ButtonLabel.TextXAlignment = Enum.TextXAlignment.Left
    ButtonLabel.Parent = Button
    
    -- Status indicator dengan background
    local StatusBg = Instance.new("Frame")
    StatusBg.Size = UDim2.new(0, 48, 0, 22)
    StatusBg.Position = UDim2.new(1, -56, 0.5, -11)
    StatusBg.BackgroundColor3 = ESPSettings[setting] and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(40, 40, 50)
    StatusBg.BorderSizePixel = 0
    StatusBg.Parent = Button
    
    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 11)
    StatusCorner.Parent = StatusBg
    
    local StatusText = Instance.new("TextLabel")
    StatusText.Name = "Status"
    StatusText.Size = UDim2.new(1, 0, 1, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = ESPSettings[setting] and "ON" or "OFF"
    StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatusText.TextSize = 11
    StatusText.Font = Enum.Font.GothamBold
    StatusText.Parent = StatusBg
    
    Button.MouseButton1Click:Connect(function()
        ESPSettings[setting] = not ESPSettings[setting]
        Button.BackgroundColor3 = ESPSettings[setting] and Color3.fromRGB(70, 130, 255) or Color3.fromRGB(28, 28, 35)
        StatusBg.BackgroundColor3 = ESPSettings[setting] and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(40, 40, 50)
        StatusText.Text = ESPSettings[setting] and "ON" or "OFF"
    end)
    
    return Button
end

-- === ESP PLAYER SECTION ===
createToggleButton("DISPLAY NAME", 0, "ShowName")
createToggleButton("HEALTH BAR", 41, "ShowHealth")
createToggleButton("LINE PLAYER", 82, "ShowLine")
createToggleButton("CHARACTER", 123, "ShowGlow")

-- === DIVIDER 1 ===
createDivider(169, "━━━━ ESP NPC ━━━━")

-- === ESP NPC SECTION ===
createToggleButton("SHOW NPC", 204, "ShowNPC")
createToggleButton("NPC HEALTH", 245, "ShowNPCHealth")
createToggleButton("NPC DISTANCE", 286, "ShowNPCDistance")
createToggleButton("NPC LINE", 327, "ShowNPCLine")

-- === DIVIDER 2 ===
createDivider(373, "━━━━ ESP ITEMS ━━━━")

-- === ESP ITEMS SECTION ===
createToggleButton("SHOW ITEMS", 408, "ShowItems")
createToggleButton("ITEM DISTANCE", 449, "ShowItemDistance")
createToggleButton("ITEM LINE", 490, "ShowItemLine")

-- Button Fire dengan modern design
local FireButton = Instance.new("TextButton")
FireButton.Name = "FireButton"
FireButton.Size = UDim2.new(0, 41, 0, 41)
FireButton.Position = UDim2.new(0, 15, 0.5, -22.5)
FireButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
FireButton.Text = "👁️"
FireButton.TextSize = 20
FireButton.Font = Enum.Font.GothamBold
FireButton.BorderSizePixel = 0
FireButton.Visible = false
FireButton.Active = true
FireButton.Draggable = true
FireButton.Parent = ScreenGui

local FireCorner = Instance.new("UICorner")
FireCorner.CornerRadius = UDim.new(0, 12)
FireCorner.Parent = FireButton


-- Fungsi minimize
local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    MainFrame.Visible = not isMinimized
    FireButton.Visible = isMinimized
end)

FireButton.MouseButton1Click:Connect(function()
    isMinimized = false
    MainFrame.Visible = true
    FireButton.Visible = false
end)

-- Variable untuk connection
local renderConnection = nil

-- Fungsi close
CloseBtn.MouseButton1Click:Connect(function()
    ESPSettings.Enabled = false
    
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
    
    for _, espObj in pairs(ESPObjects) do
        if espObj.DisplayName then espObj.DisplayName:Remove() end
        if espObj.Username then espObj.Username:Remove() end
        if espObj.Health then espObj.Health:Remove() end
        if espObj.Line then espObj.Line:Remove() end
        if espObj.Highlight then espObj.Highlight:Destroy() end
    end
    
    for _, npcObj in pairs(NPCObjects) do
        if npcObj.Name then npcObj.Name:Remove() end
        if npcObj.Health then npcObj.Health:Remove() end
        if npcObj.Distance then npcObj.Distance:Remove() end
        if npcObj.Line then npcObj.Line:Remove() end
        if npcObj.Highlight then npcObj.Highlight:Destroy() end
    end
    
    for _, itemObj in pairs(ItemObjects) do
        if itemObj.Name then itemObj.Name:Remove() end
        if itemObj.Distance then itemObj.Distance:Remove() end
        if itemObj.Line then itemObj.Line:Remove() end
        if itemObj.Highlight then itemObj.Highlight:Destroy() end
    end
    
    ESPObjects = {}
    NPCObjects = {}
    ItemObjects = {}
    
    ScreenGui:Destroy()
    
    print("ESP GUI closed successfully!")
end)

-- [SISANYA SAMA SEPERTI KODE ASLI - FUNGSI ESP TIDAK BERUBAH]
-- Saya sengaja tidak menyalin ulang fungsi ESP karena hanya GUI yang diubah

local function createESP(player)
    if player == LocalPlayer then return end
    
    local esp = {
        DisplayName = nil,
        Username = nil,
        Health = nil,
        Line = nil,
        Highlight = nil
    }
    
    local displayLabel = Drawing.new("Text")
    displayLabel.Visible = false
    displayLabel.Center = true
    displayLabel.Outline = true
    displayLabel.Font = 2
    displayLabel.Size = 14
    displayLabel.Color = Color3.new(1, 1, 1)
    esp.DisplayName = displayLabel
    
    local usernameLabel = Drawing.new("Text")
    usernameLabel.Visible = false
    usernameLabel.Center = true
    usernameLabel.Outline = true
    usernameLabel.Font = 2
    usernameLabel.Size = 13
    usernameLabel.Color = Color3.new(0.7, 0.7, 0.7)
    esp.Username = usernameLabel
    
    local healthLabel = Drawing.new("Text")
    healthLabel.Visible = false
    healthLabel.Center = true
    healthLabel.Outline = true
    healthLabel.Font = 2
    healthLabel.Size = 12
    healthLabel.Color = Color3.new(0, 1, 0)
    esp.Health = healthLabel
    
    local line = Drawing.new("Line")
    line.Visible = false
    line.Thickness = 1
    line.Color = Color3.new(1, 1, 1)
    esp.Line = line
    
    ESPObjects[player] = esp
end

local function createPlayerHighlight(character)
    if not character then return nil end
    
    local existingHighlight = character:FindFirstChild("PlayerESPHighlight")
    if existingHighlight then
        return existingHighlight
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "PlayerESPHighlight"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(135, 206, 250)
    highlight.OutlineColor = Color3.fromRGB(135, 206, 250)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    highlight.Parent = character
    
    return highlight
end

local function isNPC(model)
    if model:FindFirstChildOfClass("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character == model then
                return false
            end
        end
        return true
    end
    return false
end

local function createNPCESP(npcModel)
    if NPCObjects[npcModel] then return end
    
    local npcEsp = {
        Name = nil,
        Health = nil,
        Distance = nil,
        Line = nil,
        Highlight = nil
    }
    
    local nameLabel = Drawing.new("Text")
    nameLabel.Visible = false
    nameLabel.Center = true
    nameLabel.Outline = true
    nameLabel.Font = 2
    nameLabel.Size = 14
    nameLabel.Color = Color3.new(1, 0.3, 0.3)
    npcEsp.Name = nameLabel
    
    local healthLabel = Drawing.new("Text")
    healthLabel.Visible = false
    healthLabel.Center = true
    healthLabel.Outline = true
    healthLabel.Font = 2
    healthLabel.Size = 12
    healthLabel.Color = Color3.new(1, 0.5, 0)
    npcEsp.Health = healthLabel
    
    local distLabel = Drawing.new("Text")
    distLabel.Visible = false
    distLabel.Center = true
    distLabel.Outline = true
    distLabel.Font = 2
    distLabel.Size = 11
    distLabel.Color = Color3.new(0.8, 0.8, 0.8)
    npcEsp.Distance = distLabel
    
    local line = Drawing.new("Line")
    line.Visible = false
    line.Thickness = 1
    line.Color = Color3.new(1, 0.3, 0.3)
    npcEsp.Line = line
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "NPCHighlight"
    highlight.Adornee = npcModel
    highlight.FillColor = Color3.fromRGB(255, 80, 80)
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    highlight.Parent = npcModel
    npcEsp.Highlight = highlight
    
    NPCObjects[npcModel] = npcEsp
end

local function isPickupItem(obj)
    if obj:IsA("Tool") or obj:IsA("Model") then
        if obj:FindFirstChildOfClass("ClickDetector") or 
           obj:FindFirstChildOfClass("ProximityPrompt") or
           obj:FindFirstChild("Handle") then
            return true
        end
    elseif obj:IsA("Part") or obj:IsA("MeshPart") then
        if obj:FindFirstChildOfClass("ClickDetector") or 
           obj:FindFirstChildOfClass("ProximityPrompt") then
            return true
        end
    end
    return false
end

local function createItemESP(item)
    if ItemObjects[item] then return end
    
    local itemEsp = {
        Name = nil,
        Distance = nil,
        Line = nil,
        Highlight = nil
    }
    
    local nameLabel = Drawing.new("Text")
    nameLabel.Visible = false
    nameLabel.Center = true
    nameLabel.Outline = true
    nameLabel.Font = 2
    nameLabel.Size = 13
    nameLabel.Color = Color3.new(1, 1, 0)
    itemEsp.Name = nameLabel
    
    local distLabel = Drawing.new("Text")
    distLabel.Visible = false
    distLabel.Center = true
    distLabel.Outline = true
    distLabel.Font = 2
    distLabel.Size = 11
    distLabel.Color = Color3.new(0.9, 0.9, 0.9)
    itemEsp.Distance = distLabel
    
    local line = Drawing.new("Line")
    line.Visible = false
    line.Thickness = 1
    line.Color = Color3.new(1, 1, 0)
    itemEsp.Line = line
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ItemHighlight"
    highlight.Adornee = item
    highlight.FillColor = Color3.fromRGB(255, 255, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    highlight.Parent = item
    itemEsp.Highlight = highlight
    
    ItemObjects[item] = itemEsp
end

local function updatePlayerESP()
    if not ESPSettings.Enabled then return end
    
    for player, esp in pairs(ESPObjects) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local hrp = player.Character.HumanoidRootPart
            local humanoid = player.Character.Humanoid
            
            local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            
            if onScreen then
                if ESPSettings.ShowName and esp.DisplayName then
                    esp.DisplayName.Visible = true
                    esp.DisplayName.Position = Vector2.new(vector.X, vector.Y - 50)
                    esp.DisplayName.Text = player.DisplayName
                    
                    esp.Username.Visible = true
                    esp.Username.Position = Vector2.new(vector.X, vector.Y - 35)
                    esp.Username.Text = "@" .. player.Name
                else
                    esp.DisplayName.Visible = false
                    esp.Username.Visible = false
                end
                
                if ESPSettings.ShowHealth and esp.Health then
                    esp.Health.Visible = true
                    esp.Health.Position = Vector2.new(vector.X, vector.Y - 20)
                    esp.Health.Text = string.format("HP: %d/%d", math.floor(humanoid.Health), math.floor(humanoid.MaxHealth))
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    esp.Health.Color = Color3.new(1 - healthPercent, healthPercent, 0)
                else
                    esp.Health.Visible = false
                end
                
                if ESPSettings.ShowLine and esp.Line then
                    esp.Line.Visible = true
                    esp.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    esp.Line.To = Vector2.new(vector.X, vector.Y)
                else
                    esp.Line.Visible = false
                end
                
                if ESPSettings.ShowGlow then
                    local highlight = createPlayerHighlight(player.Character)
                    if highlight then
                        highlight.Enabled = true
                        esp.Highlight = highlight
                    end
                else
                    if esp.Highlight then
                        esp.Highlight.Enabled = false
                    end
                end
            else
                esp.DisplayName.Visible = false
                esp.Username.Visible = false
                esp.Health.Visible = false
                esp.Line.Visible = false
                if esp.Highlight then
                    esp.Highlight.Enabled = false
                end
            end
        else
            esp.DisplayName.Visible = false
            esp.Username.Visible = false
            esp.Health.Visible = false
            esp.Line.Visible = false
            if esp.Highlight then
                esp.Highlight.Enabled = false
            end
        end
    end
end

local function updateNPCESP()
    if not ESPSettings.ShowNPC then
        for _, npcEsp in pairs(NPCObjects) do
            npcEsp.Name.Visible = false
            if npcEsp.Health then npcEsp.Health.Visible = false end
            if npcEsp.Distance then npcEsp.Distance.Visible = false end
            if npcEsp.Line then npcEsp.Line.Visible = false end
            if npcEsp.Highlight then npcEsp.Highlight.Enabled = false end
        end
        return
    end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isNPC(obj) then
            createNPCESP(obj)
        end
    end
    
    for npcModel, npcEsp in pairs(NPCObjects) do
        if npcModel and npcModel.Parent and npcModel:FindFirstChild("HumanoidRootPart") then
            local hrp = npcModel.HumanoidRootPart
            local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
            
            local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            
            if onScreen then
                npcEsp.Name.Visible = true
                npcEsp.Name.Position = Vector2.new(vector.X, vector.Y - 40)
                npcEsp.Name.Text = npcModel.Name
                
                if ESPSettings.ShowNPCHealth and humanoid and npcEsp.Health then
                    npcEsp.Health.Visible = true
                    npcEsp.Health.Position = Vector2.new(vector.X, vector.Y - 25)
                    npcEsp.Health.Text = string.format("HP: %d", math.floor(humanoid.Health))
                else
                    npcEsp.Health.Visible = false
                end
                
                if ESPSettings.ShowNPCDistance and npcEsp.Distance and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                    npcEsp.Distance.Visible = true
                    npcEsp.Distance.Position = Vector2.new(vector.X, vector.Y - 10)
                    npcEsp.Distance.Text = string.format("[%.1fm]", distance)
                else
                    npcEsp.Distance.Visible = false
                end
                
                if ESPSettings.ShowNPCLine and npcEsp.Line then
                    npcEsp.Line.Visible = true
                    npcEsp.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    npcEsp.Line.To = Vector2.new(vector.X, vector.Y)
                else
                    npcEsp.Line.Visible = false
                end
                
                if npcEsp.Highlight then
                    npcEsp.Highlight.Enabled = true
                end
            else
                npcEsp.Name.Visible = false
                if npcEsp.Health then npcEsp.Health.Visible = false end
                if npcEsp.Distance then npcEsp.Distance.Visible = false end
                if npcEsp.Line then npcEsp.Line.Visible = false end
                if npcEsp.Highlight then npcEsp.Highlight.Enabled = false end
            end
        end
    end
end

local function updateItemESP()
    if not ESPSettings.ShowItems then
        for _, itemEsp in pairs(ItemObjects) do
            itemEsp.Name.Visible = false
            if itemEsp.Distance then itemEsp.Distance.Visible = false end
            if itemEsp.Line then itemEsp.Line.Visible = false end
            if itemEsp.Highlight then itemEsp.Highlight.Enabled = false end
        end
        return
    end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isPickupItem(obj) then
            createItemESP(obj)
        end
    end
    
    for item, itemEsp in pairs(ItemObjects) do
        if item and item.Parent and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local pos = item:IsA("Model") and item:GetPivot().Position or item.Position
            local vector, onScreen = Camera:WorldToViewportPoint(pos)
            
            if onScreen then
                itemEsp.Name.Visible = true
                itemEsp.Name.Position = Vector2.new(vector.X, vector.Y - 20)
                itemEsp.Name.Text = item.Name
                
                if ESPSettings.ShowItemDistance and itemEsp.Distance then
                    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - pos).Magnitude
                    itemEsp.Distance.Visible = true
                    itemEsp.Distance.Position = Vector2.new(vector.X, vector.Y - 5)
                    itemEsp.Distance.Text = string.format("[%.1fm]", distance)
                else
                    itemEsp.Distance.Visible = false
                end
                
                if ESPSettings.ShowItemLine and itemEsp.Line then
                    itemEsp.Line.Visible = true
                    itemEsp.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    itemEsp.Line.To = Vector2.new(vector.X, vector.Y)
                else
                    itemEsp.Line.Visible = false
                end
                
                if itemEsp.Highlight then
                    itemEsp.Highlight.Enabled = true
                end
            else
                itemEsp.Name.Visible = false
                if itemEsp.Distance then itemEsp.Distance.Visible = false end
                if itemEsp.Line then itemEsp.Line.Visible = false end
                if itemEsp.Highlight then itemEsp.Highlight.Enabled = false end
            end
        end
    end
end

-- Initialize ESP for existing players
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

-- Handle new players
Players.PlayerAdded:Connect(function(player)
    createESP(player)
end)

-- Handle player removing
Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        if ESPObjects[player].DisplayName then ESPObjects[player].DisplayName:Remove() end
        if ESPObjects[player].Username then ESPObjects[player].Username:Remove() end
        if ESPObjects[player].Health then ESPObjects[player].Health:Remove() end
        if ESPObjects[player].Line then ESPObjects[player].Line:Remove() end
        if ESPObjects[player].Highlight then ESPObjects[player].Highlight:Destroy() end
        ESPObjects[player] = nil
    end
end)

-- Main render loop
renderConnection = RunService.RenderStepped:Connect(function()
    if ESPSettings.Enabled then
        updatePlayerESP()
        updateNPCESP()
        updateItemESP()
    end
end)
