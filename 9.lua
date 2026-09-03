local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LclPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- Fungsi helper dari script asli
local function cloneref(obj)
    return obj
end

-- Semua fungsi utility dari script asli
function isNumber(p235)
    if tonumber(p235) ~= nil or p235 == "inf" then
        return true
    end
end

function GetPlayer(p198, _)
    local v199 = Players.LocalPlayer
    if p198 == nil then
        return {v199.Name}
    end
    local results = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if string.find(string.lower(player.Name), string.lower(p198)) or 
           string.find(string.lower(player.DisplayName), string.lower(p198)) then
            table.insert(results, player.Name)
        end
    end
    return results
end

-- Fungsi blackhole dari script asli
local vu652 = true
function suckblackhole(pu653, pu654)
    vu652 = true
    local v655 = Instance.new("Folder", workspace)
    local v656 = Instance.new("Part", v655)
    local vu657 = Instance.new("Attachment", v656)
    v656.Anchored = true
    v656.CanCollide = false
    v656.Transparency = 1
    
    function ForcePart(p658)
        if p658:IsA("BasePart") and p658.Anchored == false and 
           not p658:IsDescendantOf(LclPlayer.Character) and
           p658.Name ~= "Torso" and p658.Name ~= "Head" and
           p658.Name ~= "HumanoidRootPart" then
            
            for _, v in ipairs(p658:GetChildren()) do
                if v:IsA("BodyAngularVelocity") or v:IsA("BodyForce") or 
                   v:IsA("BodyGyro") or v:IsA("BodyPosition") then
                    v:Destroy()
                end
            end
            
            if p658:FindFirstChild("Attachment") then
                p658:FindFirstChild("Attachment"):Destroy()
            end
            if p658:FindFirstChild("AlignPosition") then
                p658:FindFirstChild("AlignPosition"):Destroy()
            end
            if p658:FindFirstChild("Torque") then
                p658:FindFirstChild("Torque"):Destroy()
            end
            
            p658.CanCollide = false
            local v663 = Instance.new("Torque", p658)
            v663.Torque = Vector3.new(100000, 100000, 100000)
            local v664 = Instance.new("AlignPosition", p658)
            local v665 = Instance.new("Attachment", p658)
            v663.Attachment0 = v665
            v664.MaxForce = 9999999999999998
            v664.MaxVelocity = math.huge
            v664.Responsiveness = 200
            v664.Attachment0 = v665
            v664.Attachment1 = vu657
        end
    end
    
    if vu652 then
        for _, v in ipairs(workspace:GetDescendants()) do
            ForcePart(v)
        end
    end
    
    workspace.DescendantAdded:Connect(function(p670)
        if vu652 then
            ForcePart(p670)
        end
    end)
    
    if pu653 then
        LclPlayer:GetMouse().Button1Down:Connect(function()
            if vu652 then
                vu657.WorldCFrame = LclPlayer:GetMouse().Hit
            end
        end)
    else
        spawn(function()
            while vu652 and RunService.RenderStepped:Wait() do
                pcall(function()
                    vu657.WorldCFrame = pu654.Character:FindFirstChild("HumanoidRootPart").CFrame
                end)
            end
        end)
    end
end

-- Fungsi delete unanchored parts
local delpar = false
coroutine.wrap(function()
    while task.wait(0.1) do
        if delpar then
            local v601 = {}
            for _, v602 in ipairs(workspace:GetDescendants()) do
                if v602:IsA("BasePart") and v602.Anchored == false and 
                   not v602:IsDescendantOf(LclPlayer.Character) and
                   v602.Name ~= "Torso" and v602.Name ~= "Head" and
                   v602.Name ~= "HumanoidRootPart" then
                    
                    for _, v606 in ipairs(v602:GetChildren()) do
                        if v606:IsA("BodyPosition") or v606:IsA("BodyGyro") then
                            v606:Destroy()
                        end
                    end
                    
                    local v607 = Instance.new("BodyPosition")
                    v607.Parent = v602
                    v607.P = 1000000
                    v607.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    table.insert(v601, v607)
                end
            end
            
            for _, v611 in ipairs(v601) do
                v611.Position = Vector3.new(99999999999, 99999999999, 99999999999)
            end
        end
    end
end)()

-- Fungsi freeze parts (tetap ada untuk keperluan lain)
local frozen = false
local vu612 = nil
local frozenParts = {}

local function freezeParts()
    frozen = true
    local function freezePart(p614)
        if p614:IsA("BasePart") and p614.Anchored == false and
           not p614:IsDescendantOf(LclPlayer.Character) then
            
            for _, v620 in ipairs(p614:GetChildren()) do
                if v620:IsA("BodyPosition") or v620:IsA("BodyGyro") then
                    v620:Destroy()
                end
            end
            
            local v621 = Instance.new("BodyPosition")
            v621.Parent = p614
            v621.Position = p614.Position
            v621.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            
            local v622 = Instance.new("BodyGyro")
            v622.Parent = p614
            v622.CFrame = p614.CFrame
            v622.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            
            if not table.find(frozenParts, p614) then
                table.insert(frozenParts, p614)
            end
        end
    end
    
    for _, v627 in ipairs(workspace:GetDescendants()) do
        freezePart(v627)
    end
    
    vu612 = workspace.DescendantAdded:Connect(freezePart)
end

local function unfreezeParts()
    frozen = false
    if vu612 then
        vu612:Disconnect()
    end
    
    for _, v632 in ipairs(frozenParts) do
        for _, v636 in ipairs(v632:GetChildren()) do
            if v636:IsA("BodyPosition") or v636:IsA("BodyGyro") then
                v636:Destroy()
            end
        end
    end
    frozenParts = {}
end

-- FUNGSI UNANCHOR DARI SCRIPT KEDUA (SAMA PERSIS)
local player = game.Players.LocalPlayer
local aktif = false
local folder, attachment1, koneksi1
local RADIUS = 500

-- Scan part sekitar player
local function scanParts()
    local parts = {}
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return parts end

    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") 
        and not part.Anchored 
        and not part:IsDescendantOf(player.Character) then
            local dist = (part.Position - root.Position).Magnitude
            if dist <= RADIUS then
                table.insert(parts, part)
            end
        end
    end
    return parts
end

-- Apply force ke part
local function applyForce(part)
    if not part or not part.Parent then return end
    part.CanCollide = false

    for _, x in next, part:GetChildren() do
        if x:IsA("BodyAngularVelocity") or x:IsA("BodyForce") or x:IsA("BodyGyro") 
        or x:IsA("BodyPosition") or x:IsA("BodyThrust") or x:IsA("BodyVelocity")
        or x:IsA("RocketPropulsion") then
            x:Destroy()
        end
    end

    if not part:FindFirstChildOfClass("Torque") then
        local torque = Instance.new("Torque", part)
        torque.Torque = Vector3.new(100000,100000,100000)
        local align = Instance.new("AlignPosition", part)
        local at2 = Instance.new("Attachment", part)
        torque.Attachment0 = at2
        align.MaxForce = 9e15
        align.MaxVelocity = math.huge
        align.Responsiveness = 200
        align.Attachment0 = at2
        if attachment1 then
            align.Attachment1 = attachment1
        end
    end

    if attachment1 then
        local dist = (part.Position - attachment1.WorldPosition).Magnitude
        if dist <= RADIUS then
            local arah = (attachment1.WorldPosition - part.Position).Unit
            part.AssemblyLinearVelocity = arah * 200
        end
    end
end

-- === Network stabilizer (aktif hanya saat tombol ON) ===
if not getgenv().Network then
    getgenv().Network = {
        BaseParts = {},
        Velocity = Vector3.new(14.46, 14.46, 14.46)
    }

    function Network.RetainPart(part)
        if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
            table.insert(Network.BaseParts, part)
            part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            part.CanCollide = false
        end
    end
end

local NetworkConnection = nil

local function EnableNetwork()
    if NetworkConnection then return end
    NetworkConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            sethiddenproperty(LclPlayer, "SimulationRadius", math.huge)
        end)
    end)
end

local function DisableNetwork()
    if NetworkConnection then
        NetworkConnection:Disconnect()
        NetworkConnection = nil
    end
end

-- Mulai Unanchor
local function mulaiUnanchor()
    folder = Instance.new("Folder", workspace)
    local part = Instance.new("Part", folder)
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    attachment1 = Instance.new("Attachment", part)

    -- Enable Network saat unanchor aktif
    EnableNetwork()

    task.spawn(function()
        settings().Physics.AllowSleep = false
        while aktif and task.wait() do
            for _, pl in next, game.Players:GetPlayers() do
                if pl ~= player then
                    pl.MaximumSimulationRadius = 0
                    sethiddenproperty(pl, "SimulationRadius", 0)
                end
            end
            player.MaximumSimulationRadius = math.pow(math.huge, math.huge)
            setsimulationradius(math.huge)
        end
    end)

    koneksi1 = game:GetService("RunService").Stepped:Connect(function()
        local list = scanParts()
        for _, v in pairs(list) do
            applyForce(v)
        end
    end)
end

-- Stop Unanchor
local function stopUnanchor()
    -- Disable Network saat unanchor dimatikan
    DisableNetwork()
    
    if koneksi1 then koneksi1:Disconnect() end
    if folder then folder:Destroy() end
    folder, attachment1 = nil, nil
end

-- GUI Creation - Ultra Compact
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SiextherUnachor"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame (Lebih kecil dan compact)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -120)
MainFrame.Size = UDim2.new(0, 250, 0, 240)
MainFrame.ClipsDescendants = true

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = MainFrame
MainStroke.Color = Color3.fromRGB(70, 130, 255)
MainStroke.Thickness = 2
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local MainCorner = Instance.new("UICorner")
MainCorner.Parent = MainFrame
MainCorner.CornerRadius = UDim.new(0, 10)

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
TitleBar.BorderSizePixel = 0
TitleBar.Size = UDim2.new(1, 0, 0, 28)

local TitleCorner = Instance.new("UICorner")
TitleCorner.Parent = TitleBar
TitleCorner.CornerRadius = UDim.new(0, 10)

-- Title Text
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Parent = TitleBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 8, 0, 0)
Title.Size = UDim2.new(0.65, 0, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "SIEXTHER BROKEN"
Title.TextColor3 = Color3.fromRGB(70, 130, 255)
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left

local TitleGradient = Instance.new("UIGradient")
TitleGradient.Parent = Title
TitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), 
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)), 
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))  
})
TitleGradient.Offset = Vector2.new(-1, 0)
TitleGradient.Rotation = 0

task.spawn(function()
    while Title and Title.Parent do
        TweenService:Create(TitleGradient, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(1, 0)
        }):Play()
        task.wait(2)
        TweenService:Create(TitleGradient, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(-1, 0)
        }):Play()
        task.wait(2)
    end
end)

-- Minimize Button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Parent = TitleBar
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Position = UDim2.new(1, -48, 0.5, -8)
MinimizeBtn.Size = UDim2.new(0, 18, 0, 18)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Text = "–"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 14

local MinCorner = Instance.new("UICorner")
MinCorner.Parent = MinimizeBtn
MinCorner.CornerRadius = UDim.new(0, 4)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Parent = TitleBar
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.BorderSizePixel = 0
CloseBtn.Position = UDim2.new(1, -25, 0.5, -8)
CloseBtn.Size = UDim2.new(0, 18, 0, 18)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14

local CloseCorner = Instance.new("UICorner")
CloseCorner.Parent = CloseBtn
CloseCorner.CornerRadius = UDim.new(0, 4)

-- Warning Label (Lebih compact)
local WarningLabel = Instance.new("TextLabel")
WarningLabel.Parent = MainFrame
WarningLabel.BackgroundColor3 = Color3.fromRGB(40, 25, 20)
WarningLabel.BorderSizePixel = 0
WarningLabel.Position = UDim2.new(0, 6, 0, 34)
WarningLabel.Size = UDim2.new(1, -12, 0, 32)
WarningLabel.Font = Enum.Font.Gotham
WarningLabel.Text = "⚠️ JIKA KAMU MENGHILANGKAN PART!\nKAMU TIDAK BISA GUNAKAN SIEXTHER BRING"
WarningLabel.TextColor3 = Color3.fromRGB(255, 180, 100)
WarningLabel.TextSize = 8
WarningLabel.TextWrapped = true
WarningLabel.TextYAlignment = Enum.TextYAlignment.Center

local WarnCorner = Instance.new("UICorner")
WarnCorner.Parent = WarningLabel
WarnCorner.CornerRadius = UDim.new(0, 5)

-- Info Label
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Parent = MainFrame
InfoLabel.BackgroundColor3 = Color3.fromRGB(20, 30, 25)
InfoLabel.BorderSizePixel = 0
InfoLabel.Position = UDim2.new(0, 6, 0, 72)
InfoLabel.Size = UDim2.new(1, -12, 0, 22)
InfoLabel.Font = Enum.Font.GothamBold
InfoLabel.Text = "PARTS DITEMUKAN: 0 | DIHAPUS: 0"
InfoLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
InfoLabel.TextSize = 9

local InfoCorner = Instance.new("UICorner")
InfoCorner.Parent = InfoLabel
InfoCorner.CornerRadius = UDim.new(0, 5)

-- Footer Text
local FooterLabel = Instance.new("TextLabel")
FooterLabel.Parent = MainFrame
FooterLabel.BackgroundTransparency = 1
FooterLabel.Position = UDim2.new(0, 0, 1, -22)
FooterLabel.Size = UDim2.new(1, 0, 0, 18)
FooterLabel.Font = Enum.Font.GothamBold
FooterLabel.Text = "Made With 🤍 Siexther"
FooterLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FooterLabel.TextSize = 11
FooterLabel.TextXAlignment = Enum.TextXAlignment.Center

local FooterGradient = Instance.new("UIGradient")
FooterGradient.Parent = FooterLabel
FooterGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), 
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)), 
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))  
})
FooterGradient.Offset = Vector2.new(-1, 0)
FooterGradient.Rotation = 0

task.spawn(function()
    while FooterLabel and FooterLabel.Parent do
        TweenService:Create(FooterGradient, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(1, 0)
        }):Play()
        task.wait(2)
        TweenService:Create(FooterGradient, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(-1, 0)
        }):Play()
        task.wait(2)
    end
end)

-- Content Frame
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 6, 0, 100)
ContentFrame.Size = UDim2.new(1, -12, 1, -106)

-- Floating Button
local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Name = "FloatingBtn"
FloatingBtn.Parent = ScreenGui
FloatingBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
FloatingBtn.BorderSizePixel = 0
FloatingBtn.Position = UDim2.new(0, 15, 0, 60)
FloatingBtn.Size = UDim2.new(0, 41, 0, 41)
FloatingBtn.Font = Enum.Font.GothamBold
FloatingBtn.Text = "SX"
FloatingBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
FloatingBtn.TextSize = 25
FloatingBtn.Draggable = true
FloatingBtn.Visible = false

-- Gradient Animation untuk Minimized Button
local MinimizedGradient = Instance.new("UIGradient")
MinimizedGradient.Parent = FloatingBtn
MinimizedGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
MinimizedGradient.Offset = Vector2.new(-1, 0)

task.spawn(function()
    while FloatingBtn and FloatingBtn.Parent do
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

local FloatCorner = Instance.new("UICorner")
FloatCorner.Parent = FloatingBtn
FloatCorner.CornerRadius = UDim.new(0, 12)

-- Button Creation Function
local yPos = 0
local partsFound = 0
local partsDeleted = 0

local function createButton(text, callback)
    local Button = Instance.new("TextButton")
    Button.Parent = ContentFrame
    Button.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
    Button.BorderSizePixel = 0
    Button.Position = UDim2.new(0, 0, 0, yPos)
    Button.Size = UDim2.new(1, 0, 0, 26)
    Button.Font = Enum.Font.GothamBold
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 10
    Button.AutoButtonColor = false
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.Parent = Button
    BtnCorner.CornerRadius = UDim.new(0, 5)
    
    Button.MouseEnter:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 130, 255)}):Play()
    end)
    
    Button.MouseLeave:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 35, 45)}):Play()
    end)
    
    Button.MouseButton1Click:Connect(callback)
    
    yPos = yPos + 30
    
    return Button
end

-- Create Buttons (DENGAN FITUR UNANCHOR DI SCAN)
createButton("S C A N", function()
    partsFound = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Anchored == false and 
           not v:IsDescendantOf(LclPlayer.Character) and
           v.Name ~= "Torso" and v.Name ~= "Head" and
           v.Name ~= "HumanoidRootPart" then
            partsFound = partsFound + 1
        end
    end
    InfoLabel.Text = "PARTS DITEMUKAN: "..partsFound.." | DIHAPUS: "..partsDeleted
    
    -- TAMBAHAN FITUR UNANCHOR DARI SCRIPT KEDUA
    aktif = not aktif
    if aktif then
        mulaiUnanchor()
    else
        stopUnanchor()
    end
end)

createButton("EXECUTE", function()
    local v641 = {}
    local deleteCount = 0
    for _, v642 in ipairs(workspace:GetDescendants()) do
        if v642:IsA("BasePart") and v642.Anchored == false and 
           not v642:IsDescendantOf(LclPlayer.Character) and
           v642.Name ~= "Torso" and v642.Name ~= "Head" and
           v642.Name ~= "HumanoidRootPart" then
            
            local v647 = Instance.new("BodyPosition")
            v647.Parent = v642
            v647.P = 1000000
            v647.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            table.insert(v641, v647)
            deleteCount = deleteCount + 1
        end
    end
    
    for _, v651 in ipairs(v641) do
        v651.Position = Vector3.new(99999999999, 99999999999, 99999999999)
    end
    
    partsDeleted = partsDeleted + deleteCount
    InfoLabel.Text = "PARTS DITEMUKAN: "..partsFound.." | DIHAPUS: "..partsDeleted
end)

createButton("SIEXTHER DELETE PARTS", function()
    delpar = not delpar
    
    if delpar then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/han.lua"))()
        getgenv().Notify({Title = 'SIEXTHER DELETE PARTS', Content = 'BERHASIL MENGHAPUS PARTS UNACHOR', Duration = 4})
    end
end)

-- BUTTON REJOIN (PALING BAWAH)
createButton("REJOIN SERVER", function()
    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

-- Dragging
local dragging, dragInput, dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
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

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Minimize/Maximize
MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    FloatingBtn.Visible = true
end)

FloatingBtn.MouseButton1Click:Connect(function()
    FloatingBtn.Visible = false
    MainFrame.Visible = true
end)

-- Close
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)