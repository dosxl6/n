-- Modern Teleport GUI by Siexther (Enhanced with Clone Mode + Reorder)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Clone character untuk background mode
local cloneCharacter = nil
local cloneHRP = nil

-- Konfigurasi
local CONFIG = {
    SaveFile = "./SiextherTeleport10.json",
    StrokeColor = Color3.fromRGB(70, 130, 255),
    BackgroundColor = Color3.fromRGB(15, 20, 35),
    SecondaryColor = Color3.fromRGB(25, 30, 45),
    TextColor = Color3.fromRGB(240, 245, 255),
    AccentColor = Color3.fromRGB(70, 130, 255)
}

-- Data teleport dengan array untuk menjaga urutan
local teleportData = {}
local teleportOrder = {}
local autoPlayEnabled = false
local autoPlayConnection = nil
local currentAutoPlayIndex = 1
local teleportDelay = 3
local teleportMode = "default"

-- Variable untuk tracking reorder frame yang aktif
local activeReorderFrame = nil

-- Fungsi untuk membuat clone character
local function createCloneCharacter()
    if cloneCharacter then
        cloneCharacter:Destroy()
    end
    
    if not character then return end
    
    cloneCharacter = character:Clone()
    cloneCharacter.Name = "CloneCharacter_" .. player.Name
    
    for _, part in ipairs(cloneCharacter:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = 0.5
            part.CanCollide = false
            part.Anchored = false
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 0.5
        end
    end
    
    for _, obj in ipairs(cloneCharacter:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") then
            obj:Destroy()
        end
    end
    
    if cloneCharacter:FindFirstChild("HumanoidRootPart") then
        cloneHRP = cloneCharacter.HumanoidRootPart
        cloneHRP.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(5, 0, 0)
    end
    
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(70, 130, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(100, 160, 255)
    highlight.OutlineTransparency = 0
    highlight.Parent = cloneCharacter
    
    cloneCharacter.Parent = workspace
    
    return cloneCharacter
end

local function destroyClone()
    if cloneCharacter then
        cloneCharacter:Destroy()
        cloneCharacter = nil
        cloneHRP = nil
    end
end

-- Fungsi untuk load data
local function loadTeleportData()
    if isfile and readfile and isfile(CONFIG.SaveFile) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG.SaveFile))
        end)
        if success and data then
            teleportData = data.locations or {}
            teleportOrder = data.order or {}
            
            local tempOrder = {}
            for _, name in ipairs(teleportOrder) do
                if teleportData[name] then
                    table.insert(tempOrder, name)
                end
            end
            for name, _ in pairs(teleportData) do
                local found = false
                for _, orderedName in ipairs(tempOrder) do
                    if orderedName == name then
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(tempOrder, name)
                end
            end
            teleportOrder = tempOrder
        end
    end
end

-- Fungsi untuk save data
local function saveTeleportData()
    if writefile then
        local success = pcall(function()
            local saveData = {
                locations = teleportData,
                order = teleportOrder
            }
            writefile(CONFIG.SaveFile, HttpService:JSONEncode(saveData))
        end)
    end
end

loadTeleportData()

-- Buat ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SiextherTeleport"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 320)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -170)
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

-- Header
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

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SIEXTHER TELEPORT"
Title.TextColor3 = CONFIG.StrokeColor
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -70, 0.5, -15)
MinimizeBtn.BackgroundColor3 = CONFIG.BackgroundColor
MinimizeBtn.Text = "−"
MinimizeBtn.TextColor3 = CONFIG.TextColor
MinimizeBtn.TextSize = 20
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Parent = Header

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinimizeBtn

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

-- Left Side (Teleport List)
local LeftFrame = Instance.new("Frame")
LeftFrame.Name = "LeftFrame"
LeftFrame.Size = UDim2.new(0, 280, 1, -100)
LeftFrame.Position = UDim2.new(0, 10, 0, 50)
LeftFrame.BackgroundTransparency = 1
LeftFrame.Parent = MainFrame

local TeleportList = Instance.new("ScrollingFrame")
TeleportList.Name = "TeleportList"
TeleportList.Size = UDim2.new(1, 0, 1, 0)
TeleportList.Position = UDim2.new(0, 0, 0, 0)
TeleportList.BackgroundTransparency = 1
TeleportList.BorderSizePixel = 0
TeleportList.ScrollBarThickness = 4
TeleportList.ScrollBarImageColor3 = CONFIG.StrokeColor
TeleportList.CanvasSize = UDim2.new(0, 0, 0, 0)
TeleportList.Parent = LeftFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 8)
ListLayout.Parent = TeleportList

-- Right Side (Controls)
local RightFrame = Instance.new("Frame")
RightFrame.Name = "RightFrame"
RightFrame.Size = UDim2.new(0, 190, 1, -100)
RightFrame.Position = UDim2.new(0, 300, 0, 50)
RightFrame.BackgroundTransparency = 1
RightFrame.Parent = MainFrame

-- Auto Play Section
local AutoPlaySection = Instance.new("Frame")
AutoPlaySection.Name = "AutoPlaySection"
AutoPlaySection.Size = UDim2.new(1, 0, 0, 100)
AutoPlaySection.BackgroundColor3 = CONFIG.SecondaryColor
AutoPlaySection.BorderSizePixel = 0
AutoPlaySection.Parent = RightFrame

local AutoSectionCorner = Instance.new("UICorner")
AutoSectionCorner.CornerRadius = UDim.new(0, 8)
AutoSectionCorner.Parent = AutoPlaySection

local AutoSectionStroke = Instance.new("UIStroke")
AutoSectionStroke.Color = CONFIG.StrokeColor
AutoSectionStroke.Thickness = 1.5
AutoSectionStroke.Parent = AutoPlaySection

local AutoPlayBtn = Instance.new("TextButton")
AutoPlayBtn.Name = "AutoPlayBtn"
AutoPlayBtn.Size = UDim2.new(1, -20, 0, 30)
AutoPlayBtn.Position = UDim2.new(0, 10, 0, 10)
AutoPlayBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
AutoPlayBtn.Text = "START AUTO LOOP"
AutoPlayBtn.TextColor3 = CONFIG.TextColor
AutoPlayBtn.TextSize = 13
AutoPlayBtn.Font = Enum.Font.GothamBold
AutoPlayBtn.BorderSizePixel = 0
AutoPlayBtn.Parent = AutoPlaySection

local AutoPlayBtnCorner = Instance.new("UICorner")
AutoPlayBtnCorner.CornerRadius = UDim.new(0, 6)
AutoPlayBtnCorner.Parent = AutoPlayBtn

local DelayLabel = Instance.new("TextLabel")
DelayLabel.Size = UDim2.new(1, -20, 0, 15)
DelayLabel.Position = UDim2.new(0, 10, 0, 45)
DelayLabel.BackgroundTransparency = 1
DelayLabel.Text = "Delay (seconds):"
DelayLabel.TextColor3 = CONFIG.TextColor
DelayLabel.TextSize = 11
DelayLabel.Font = Enum.Font.GothamMedium
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DelayLabel.Parent = AutoPlaySection

local DelayFrame = Instance.new("Frame")
DelayFrame.Size = UDim2.new(1, -20, 0, 30)
DelayFrame.Position = UDim2.new(0, 10, 0, 62)
DelayFrame.BackgroundTransparency = 1
DelayFrame.Parent = AutoPlaySection

local DecreaseBtn = Instance.new("TextButton")
DecreaseBtn.Size = UDim2.new(0, 35, 0, 30)
DecreaseBtn.Position = UDim2.new(0, 0, 0, 0)
DecreaseBtn.BackgroundColor3 = CONFIG.AccentColor
DecreaseBtn.Text = "−"
DecreaseBtn.TextColor3 = CONFIG.TextColor
DecreaseBtn.TextSize = 18
DecreaseBtn.Font = Enum.Font.GothamBold
DecreaseBtn.BorderSizePixel = 0
DecreaseBtn.Parent = DelayFrame

local DecreaseCorner = Instance.new("UICorner")
DecreaseCorner.CornerRadius = UDim.new(0, 6)
DecreaseCorner.Parent = DecreaseBtn

local DelayDisplay = Instance.new("TextBox")
DelayDisplay.Size = UDim2.new(1, -80, 0, 30)
DelayDisplay.Position = UDim2.new(0, 40, 0, 0)
DelayDisplay.BackgroundColor3 = CONFIG.BackgroundColor
DelayDisplay.Text = tostring(teleportDelay)
DelayDisplay.TextColor3 = CONFIG.TextColor
DelayDisplay.TextSize = 14
DelayDisplay.Font = Enum.Font.GothamBold
DelayDisplay.BorderSizePixel = 0
DelayDisplay.TextXAlignment = Enum.TextXAlignment.Center
DelayDisplay.Parent = DelayFrame

local DelayDisplayCorner = Instance.new("UICorner")
DelayDisplayCorner.CornerRadius = UDim.new(0, 6)
DelayDisplayCorner.Parent = DelayDisplay

local IncreaseBtn = Instance.new("TextButton")
IncreaseBtn.Size = UDim2.new(0, 35, 0, 30)
IncreaseBtn.Position = UDim2.new(1, -35, 0, 0)
IncreaseBtn.BackgroundColor3 = CONFIG.AccentColor
IncreaseBtn.Text = "+"
IncreaseBtn.TextColor3 = CONFIG.TextColor
IncreaseBtn.TextSize = 18
IncreaseBtn.Font = Enum.Font.GothamBold
IncreaseBtn.BorderSizePixel = 0
IncreaseBtn.Parent = DelayFrame

local IncreaseCorner = Instance.new("UICorner")
IncreaseCorner.CornerRadius = UDim.new(0, 6)
IncreaseCorner.Parent = IncreaseBtn

-- Teleport Mode Section
local ModeSection = Instance.new("Frame")
ModeSection.Name = "ModeSection"
ModeSection.Size = UDim2.new(1, 0, 0, 100)
ModeSection.Position = UDim2.new(0, 0, 0, 110)
ModeSection.BackgroundColor3 = CONFIG.SecondaryColor
ModeSection.BorderSizePixel = 0
ModeSection.Parent = RightFrame

local ModeSectionCorner = Instance.new("UICorner")
ModeSectionCorner.CornerRadius = UDim.new(0, 8)
ModeSectionCorner.Parent = ModeSection

local ModeSectionStroke = Instance.new("UIStroke")
ModeSectionStroke.Color = CONFIG.StrokeColor
ModeSectionStroke.Thickness = 1.5
ModeSectionStroke.Parent = ModeSection

local ModeLabel = Instance.new("TextLabel")
ModeLabel.Size = UDim2.new(1, -20, 0, 20)
ModeLabel.Position = UDim2.new(0, 10, 0, 10)
ModeLabel.BackgroundTransparency = 1
ModeLabel.Text = "Teleport Mode:"
ModeLabel.TextColor3 = CONFIG.TextColor
ModeLabel.TextSize = 12
ModeLabel.Font = Enum.Font.GothamBold
ModeLabel.TextXAlignment = Enum.TextXAlignment.Left
ModeLabel.Parent = ModeSection

local DefaultModeBtn = Instance.new("TextButton")
DefaultModeBtn.Size = UDim2.new(1, -20, 0, 30)
DefaultModeBtn.Position = UDim2.new(0, 10, 0, 35)
DefaultModeBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
DefaultModeBtn.Text = "SMOOTH MODE ✅"
DefaultModeBtn.TextColor3 = CONFIG.TextColor
DefaultModeBtn.TextSize = 12
DefaultModeBtn.Font = Enum.Font.GothamBold
DefaultModeBtn.BorderSizePixel = 0
DefaultModeBtn.Parent = ModeSection

local DefaultModeCorner = Instance.new("UICorner")
DefaultModeCorner.CornerRadius = UDim.new(0, 6)
DefaultModeCorner.Parent = DefaultModeBtn

local BackgroundModeBtn = Instance.new("TextButton")
BackgroundModeBtn.Size = UDim2.new(1, -20, 0, 30)
BackgroundModeBtn.Position = UDim2.new(0, 10, 0, 68)
BackgroundModeBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
BackgroundModeBtn.Text = "INSTANT MODE"
BackgroundModeBtn.TextColor3 = CONFIG.TextColor
BackgroundModeBtn.TextSize = 12
BackgroundModeBtn.Font = Enum.Font.GothamBold
BackgroundModeBtn.BorderSizePixel = 0
BackgroundModeBtn.Parent = ModeSection

local BackgroundModeCorner = Instance.new("UICorner")
BackgroundModeCorner.CornerRadius = UDim.new(0, 6)
BackgroundModeCorner.Parent = BackgroundModeBtn

-- Bottom Frame
local BottomFrame = Instance.new("Frame")
BottomFrame.Name = "BottomFrame"
BottomFrame.Size = UDim2.new(1, -20, 0, 40)
BottomFrame.Position = UDim2.new(0, 10, 1, -45)
BottomFrame.BackgroundColor3 = CONFIG.SecondaryColor
BottomFrame.BorderSizePixel = 0
BottomFrame.Parent = MainFrame

local BottomCorner = Instance.new("UICorner")
BottomCorner.CornerRadius = UDim.new(0, 8)
BottomCorner.Parent = BottomFrame

local BottomStroke = Instance.new("UIStroke")
BottomStroke.Color = CONFIG.StrokeColor
BottomStroke.Thickness = 1.5
BottomStroke.Parent = BottomFrame

local NameInput = Instance.new("TextBox")
NameInput.Name = "NameInput"
NameInput.Size = UDim2.new(1, -90, 1, -10)
NameInput.Position = UDim2.new(0, 10, 0, 5)
NameInput.BackgroundTransparency = 1
NameInput.Text = ""
NameInput.PlaceholderText = "Masukan text..."
NameInput.TextColor3 = CONFIG.TextColor
NameInput.PlaceholderColor3 = Color3.fromRGB(150, 160, 180)
NameInput.TextSize = 14
NameInput.Font = Enum.Font.Gotham
NameInput.TextXAlignment = Enum.TextXAlignment.Left
NameInput.ClearTextOnFocus = false
NameInput.Parent = BottomFrame

local SaveBtn = Instance.new("TextButton")
SaveBtn.Name = "SaveBtn"
SaveBtn.Size = UDim2.new(0, 70, 1, -10)
SaveBtn.Position = UDim2.new(1, -75, 0, 5)
SaveBtn.BackgroundColor3 = CONFIG.AccentColor
SaveBtn.Text = "SAVE"
SaveBtn.TextColor3 = CONFIG.TextColor
SaveBtn.TextSize = 13
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.BorderSizePixel = 0
SaveBtn.Parent = BottomFrame

local SaveCorner = Instance.new("UICorner")
SaveCorner.CornerRadius = UDim.new(0, 6)
SaveCorner.Parent = SaveBtn

-- Floating Button
local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Name = "FloatingBtn"
FloatingBtn.Size = UDim2.new(0, 41, 0, 41)
FloatingBtn.Position = UDim2.new(1, -70, 0, 20)
FloatingBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
FloatingBtn.Text = "🕳️"
FloatingBtn.TextSize = 20
FloatingBtn.Font = Enum.Font.GothamBold
FloatingBtn.BorderSizePixel = 0
FloatingBtn.Visible = false
FloatingBtn.Draggable = true
FloatingBtn.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(0, 12)
FloatCorner.Parent = FloatingBtn

-- Delay Control Functions
DecreaseBtn.MouseButton1Click:Connect(function()
    teleportDelay = math.max(0.5, teleportDelay - 0.5)
    DelayDisplay.Text = tostring(teleportDelay)
end)

IncreaseBtn.MouseButton1Click:Connect(function()
    teleportDelay = math.min(30, teleportDelay + 0.5)
    DelayDisplay.Text = tostring(teleportDelay)
end)

DelayDisplay.FocusLost:Connect(function()
    local value = tonumber(DelayDisplay.Text)
    if value then
        teleportDelay = math.clamp(value, 0.5, 30)
        DelayDisplay.Text = tostring(teleportDelay)
    else
        DelayDisplay.Text = tostring(teleportDelay)
    end
end)

-- Mode Switch Functions
DefaultModeBtn.MouseButton1Click:Connect(function()
    teleportMode = "default"
    DefaultModeBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    DefaultModeBtn.Text = "SMOOTH MODE ✅"
    BackgroundModeBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    BackgroundModeBtn.Text = "INSTANT MODE"
    destroyClone()
end)

BackgroundModeBtn.MouseButton1Click:Connect(function()
    teleportMode = "background"
    BackgroundModeBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    BackgroundModeBtn.Text = "INSTANT MODE ✅"
    DefaultModeBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    DefaultModeBtn.Text = "SMOOTH MODE"
    createCloneCharacter()
end)

-- Fungsi teleport dengan mode
local function performTeleport(targetPos)
    if teleportMode == "default" then
        -- Mode default: teleport dengan tween smooth
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = character.HumanoidRootPart
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos)})
        tween:Play()
    else
        -- Mode instant: teleport instant tanpa animasi
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = character.HumanoidRootPart
        hrp.CFrame = CFrame.new(targetPos)
        
        -- Update posisi clone jika ada
        if cloneCharacter and cloneHRP then
            cloneHRP.CFrame = CFrame.new(targetPos)
        end
    end
end

-- Fungsi untuk menggeser item dalam order
local function moveItemInOrder(name, direction)
    local currentIndex = nil
    for i, n in ipairs(teleportOrder) do
        if n == name then
            currentIndex = i
            break
        end
    end
    
    if not currentIndex then return end
    
    local newIndex = currentIndex + direction
    if newIndex < 1 or newIndex > #teleportOrder then return end
    
    teleportOrder[currentIndex], teleportOrder[newIndex] = teleportOrder[newIndex], teleportOrder[currentIndex]
    
    saveTeleportData()
    updateTeleportList()
end

-- Fungsi Auto Play Loop
local function stopAutoPlay()
    if autoPlayConnection then
        autoPlayConnection:Disconnect()
        autoPlayConnection = nil
    end
    autoPlayEnabled = false
    AutoPlayBtn.Text = "START AUTO LOOP"
    AutoPlayBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
end

local function startAutoPlay()
    if #teleportOrder == 0 then return end
    
    autoPlayEnabled = true
    AutoPlayBtn.Text = "STOP"
    AutoPlayBtn.BackgroundColor3 = Color3.fromRGB(70, 200, 100)
    
    local lastTeleportTime = 0
    
    autoPlayConnection = RunService.Heartbeat:Connect(function()
        if not autoPlayEnabled then return end
        
        local currentTime = tick()
        if currentTime - lastTeleportTime >= teleportDelay then
            local currentName = teleportOrder[currentAutoPlayIndex]
            
            if currentName and teleportData[currentName] then
                local data = teleportData[currentName]
                local targetPos = Vector3.new(data.x, data.y, data.z)
                
                performTeleport(targetPos)
                
                currentAutoPlayIndex = currentAutoPlayIndex + 1
                if currentAutoPlayIndex > #teleportOrder then
                    currentAutoPlayIndex = 1
                end
                
                lastTeleportTime = currentTime
            end
        end
    end)
end

AutoPlayBtn.MouseButton1Click:Connect(function()
    if autoPlayEnabled then
        stopAutoPlay()
    else
        startAutoPlay()
    end
end)

-- Fungsi untuk update list
function updateTeleportList()
    for _, child in ipairs(TeleportList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    activeReorderFrame = nil
    
    local ySize = 0
    for index, name in ipairs(teleportOrder) do
        local data = teleportData[name]
        if not data then continue end
        
        local ItemFrame = Instance.new("Frame")
        ItemFrame.Name = name
        ItemFrame.Size = UDim2.new(1, 0, 0, 45)
        ItemFrame.BackgroundColor3 = CONFIG.SecondaryColor
        ItemFrame.BorderSizePixel = 0
        ItemFrame.LayoutOrder = index
        ItemFrame.Parent = TeleportList
        
        local ItemCorner = Instance.new("UICorner")
        ItemCorner.CornerRadius = UDim.new(0, 8)
        ItemCorner.Parent = ItemFrame
        
        local ItemLabel = Instance.new("TextLabel")
        ItemLabel.Size = UDim2.new(1, -115, 1, 0)
        ItemLabel.Position = UDim2.new(0, 15, 0, 0)
        ItemLabel.BackgroundTransparency = 1
        ItemLabel.Text = "📍 " .. name
        ItemLabel.TextColor3 = CONFIG.TextColor
        ItemLabel.TextSize = 14
        ItemLabel.Font = Enum.Font.GothamMedium
        ItemLabel.TextXAlignment = Enum.TextXAlignment.Left
        ItemLabel.Parent = ItemFrame
        
        -- Order Button (↕) - di samping kiri roket
        local OrderBtn = Instance.new("TextButton")
        OrderBtn.Size = UDim2.new(0, 25, 0, 30)
        OrderBtn.Position = UDim2.new(1, -105, 0.5, -15)
        OrderBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        OrderBtn.BackgroundColor3 = CONFIG.AccentColor
        OrderBtn.Text = "↕"
        OrderBtn.TextSize = 14
        OrderBtn.Font = Enum.Font.GothamBold
        OrderBtn.BorderSizePixel = 0
        OrderBtn.Parent = ItemFrame
        
        local OrderCorner = Instance.new("UICorner")
        OrderCorner.CornerRadius = UDim.new(0, 6)
        OrderCorner.Parent = OrderBtn
        
        -- Reorder Frame (hidden by default) - di luar button
        local ReorderFrame = Instance.new("Frame")
        ReorderFrame.Name = "ReorderFrame"
        ReorderFrame.Size = UDim2.new(0, 50, 0, 30)
        ReorderFrame.Position = UDim2.new(1, -160, 0.5, -15)
        ReorderFrame.BackgroundColor3 = CONFIG.SecondaryColor
        ReorderFrame.BorderSizePixel = 0
        ReorderFrame.Visible = false
        ReorderFrame.ZIndex = 10
        ReorderFrame.Parent = ItemFrame
        
        local ReorderCorner = Instance.new("UICorner")
        ReorderCorner.CornerRadius = UDim.new(0, 6)
        ReorderCorner.Parent = ReorderFrame
        
        local ReorderStroke = Instance.new("UIStroke")
        ReorderStroke.Color = CONFIG.StrokeColor
        ReorderStroke.Thickness = 1.5
        ReorderStroke.Parent = ReorderFrame
        
        -- Up Button
        local UpBtn = Instance.new("TextButton")
        UpBtn.Size = UDim2.new(0, 22, 1, -4)
        UpBtn.Position = UDim2.new(0, 2, 0, 2)
        UpBtn.BackgroundColor3 = CONFIG.AccentColor
        UpBtn.Text = "↑"
        UpBtn.TextSize = 16
        UpBtn.Font = Enum.Font.GothamBold
        UpBtn.TextColor3 = CONFIG.TextColor
        UpBtn.BorderSizePixel = 0
        UpBtn.Parent = ReorderFrame
        
        local UpCorner = Instance.new("UICorner")
        UpCorner.CornerRadius = UDim.new(0, 4)
        UpCorner.Parent = UpBtn
        
        -- Down Button
        local DownBtn = Instance.new("TextButton")
        DownBtn.Size = UDim2.new(0, 22, 1, -4)
        DownBtn.Position = UDim2.new(0, 26, 0, 2)
        DownBtn.BackgroundColor3 = CONFIG.AccentColor
        DownBtn.Text = "↓"
        DownBtn.TextSize = 16
        DownBtn.Font = Enum.Font.GothamBold
        DownBtn.TextColor3 = CONFIG.TextColor
        DownBtn.BorderSizePixel = 0
        DownBtn.Parent = ReorderFrame
        
        local DownCorner = Instance.new("UICorner")
        DownCorner.CornerRadius = UDim.new(0, 4)
        DownCorner.Parent = DownBtn
        
        -- Toggle Reorder Frame - hanya 1 yang bisa aktif
        OrderBtn.MouseButton1Click:Connect(function()
            if activeReorderFrame and activeReorderFrame ~= ReorderFrame then
                activeReorderFrame.Visible = false
            end
            
            ReorderFrame.Visible = not ReorderFrame.Visible
            
            if ReorderFrame.Visible then
                activeReorderFrame = ReorderFrame
            else
                activeReorderFrame = nil
            end
        end)
        
        -- Up Button Action
        UpBtn.MouseButton1Click:Connect(function()
            moveItemInOrder(name, -1)
            ReorderFrame.Visible = false
            activeReorderFrame = nil
        end)
        
        -- Down Button Action
        DownBtn.MouseButton1Click:Connect(function()
            moveItemInOrder(name, 1)
            ReorderFrame.Visible = false
            activeReorderFrame = nil
        end)
        
        local TeleportBtn = Instance.new("TextButton")
        TeleportBtn.Size = UDim2.new(0, 35, 0, 30)
        TeleportBtn.Position = UDim2.new(1, -75, 0.5, -15)
        TeleportBtn.BackgroundColor3 = CONFIG.AccentColor
        TeleportBtn.Text = "🚀"
        TeleportBtn.TextSize = 16
        TeleportBtn.Font = Enum.Font.GothamBold
        TeleportBtn.BorderSizePixel = 0
        TeleportBtn.Parent = ItemFrame
        
        local TpCorner = Instance.new("UICorner")
        TpCorner.CornerRadius = UDim.new(0, 6)
        TpCorner.Parent = TeleportBtn
        
        local DeleteBtn = Instance.new("TextButton")
        DeleteBtn.Size = UDim2.new(0, 35, 0, 30)
        DeleteBtn.Position = UDim2.new(1, -35, 0.5, -15)
        DeleteBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
        DeleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        DeleteBtn.Text = "X"
        DeleteBtn.TextSize = 14
        DeleteBtn.Font = Enum.Font.GothamBold
        DeleteBtn.BorderSizePixel = 0
        DeleteBtn.Parent = ItemFrame
        
        local DelCorner = Instance.new("UICorner")
        DelCorner.CornerRadius = UDim.new(0, 6)
        DelCorner.Parent = DeleteBtn
        
        TeleportBtn.MouseButton1Click:Connect(function()
            local targetPos = Vector3.new(data.x, data.y, data.z)
            performTeleport(targetPos)
        end)
        
        DeleteBtn.MouseButton1Click:Connect(function()
            teleportData[name] = nil
            
            for i, n in ipairs(teleportOrder) do
                if n == name then
                    table.remove(teleportOrder, i)
                    break
                end
            end
            
            saveTeleportData()
            updateTeleportList()
        end)
        
        ySize = ySize + 53
    end
    
    TeleportList.CanvasSize = UDim2.new(0, 0, 0, math.max(ySize, 0))
end

-- Save button functionality
SaveBtn.MouseButton1Click:Connect(function()
    local name = NameInput.Text
    if name ~= "" and character and character:FindFirstChild("HumanoidRootPart") then
        local pos = character.HumanoidRootPart.Position
        teleportData[name] = {
            x = pos.X,
            y = pos.Y,
            z = pos.Z
        }
        
        local exists = false
        for _, n in ipairs(teleportOrder) do
            if n == name then
                exists = true
                break
            end
        end
        if not exists then
            table.insert(teleportOrder, name)
        end
        
        saveTeleportData()
        updateTeleportList()
        NameInput.Text = ""
    end
end)

-- Minimize functionality
local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = true
    MainFrame.Visible = false
    FloatingBtn.Visible = true
end)

FloatingBtn.MouseButton1Click:Connect(function()
    isMinimized = false
    FloatingBtn.Visible = false
    MainFrame.Visible = true
end)

CloseBtn.MouseButton1Click:Connect(function()
    stopAutoPlay()
    destroyClone()
    ScreenGui:Destroy()
end)

-- Drag functionality
local dragging = false
local dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

MainFrame.InputBegan:Connect(function(input)
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

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Hover effects
local function addHoverEffect(button, hoverColor)
    local originalColor = button.BackgroundColor3
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = originalColor}):Play()
    end)
end

addHoverEffect(SaveBtn, Color3.fromRGB(90, 150, 255))
addHoverEffect(MinimizeBtn, CONFIG.SecondaryColor)
addHoverEffect(CloseBtn, Color3.fromRGB(255, 100, 100))
addHoverEffect(FloatingBtn, CONFIG.SecondaryColor)
addHoverEffect(AutoPlayBtn, Color3.fromRGB(100, 100, 110))
addHoverEffect(DecreaseBtn, Color3.fromRGB(90, 150, 255))
addHoverEffect(IncreaseBtn, Color3.fromRGB(90, 150, 255))
addHoverEffect(DefaultModeBtn, Color3.fromRGB(90, 150, 255))
addHoverEffect(BackgroundModeBtn, Color3.fromRGB(80, 90, 100))

-- Update character reference saat respawn
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    if teleportMode == "background" then
        task.wait(0.5)
        createCloneCharacter()
    end
end)

-- Initial update
updateTeleportList()

-- Parent ke game
ScreenGui.Parent = game.CoreGui
