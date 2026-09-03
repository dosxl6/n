if _G.SiextherVD then
    for _, v in pairs(_G.SiextherVD) do pcall(function() v:Disconnect() end) end
    _G.SiextherVD = nil
end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

_G.SiextherVD = {}
local Connections = _G.SiextherVD

-- NOTIFY
loadstring(game:HttpGet("https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/han.lua"))()

local function Notif(title, content, duration)
    pcall(function()
        getgenv().Notify({
            Title    = title or "SIEXTHER VD",
            Content  = content or "",
            Duration = duration or 3,
        })
    end)
end

-- THEME
local C = {
    bg      = Color3.fromRGB(25, 25, 35),
    surface = Color3.fromRGB(20, 20, 32),
    card    = Color3.fromRGB(26, 26, 40),
    stroke  = Color3.fromRGB(70, 130, 255),
    accent  = Color3.fromRGB(100, 180, 255),
    text    = Color3.fromRGB(230, 230, 240),
    subtext = Color3.fromRGB(120, 130, 155),
    onClr   = Color3.fromRGB(70, 130, 255),
    offClr  = Color3.fromRGB(38, 38, 52),
    red     = Color3.fromRGB(220, 60, 60),
    redHov  = Color3.fromRGB(255, 80, 80),
    minClr  = Color3.fromRGB(40, 90, 200),
    minHov  = Color3.fromRGB(70, 130, 255),
}

local TW = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- HELPERS
local function tween(obj, props) TweenService:Create(obj, TW, props):Play() end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thick)
    local s = Instance.new("UIStroke")
    s.Color = color or C.stroke
    s.Thickness = thick or 1.5
    s.Parent = parent
    return s
end

local function makeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
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
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))
end

-- IS KILLER DETECTION
local function IsKiller(player)
    if not player or player == LocalPlayer then return false end
    if player:GetAttribute("Role") == "Killer" or player:GetAttribute("Killerost") then return true end
    local char = player.Character
    if char then
        for _, n in ipairs({"Weapon","Knife","Axe","Sword","Gun","KillerTool","MurderTool"}) do
            if char:FindFirstChild(n) then return true end
        end
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") then
                local nm = child.Name:lower()
                if nm:find("weapon") or nm:find("knife") or nm:find("gun") then return true end
            end
        end
    end
    return false
end

local function isKiller()
    return LocalPlayer.Team and LocalPlayer.Team.Name == "Killer"
end

local function getCharacterRootPart()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then return nil end
    return result
end

-- CROSSHAIR
local function ToggleCrosshair(state)
    local nm = "SVD_CrosshairGui"
    local cg = game:GetService("CoreGui")
    local ex = cg:FindFirstChild(nm) or PlayerGui:FindFirstChild(nm)
    if ex then ex:Destroy() end
    if not state then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = nm; gui.DisplayOrder = 999
    gui.IgnoreGuiInset = true; gui.ResetOnSpawn = false

    

    local ring = Instance.new("Frame")
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Size = UDim2.fromOffset(14, 14)
    ring.Position = UDim2.fromScale(0.5, 0.5)
    ring.BackgroundTransparency = 1
    ring.Parent = gui
    stroke(ring, C.stroke, 1.5)
    corner(ring, 7)

    local dot = Instance.new("Frame")
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Size = UDim2.fromOffset(4, 4)
    dot.Position = UDim2.fromScale(0.5, 0.5)
    dot.BackgroundColor3 = C.accent
    dot.BorderSizePixel = 0
    dot.Parent = gui
    corner(dot, 2)

    gui.Parent = cg
end

-- NOCLIP
local function ToggleNoclip(state)
    if Connections.NoclipLoop then
        pcall(function() Connections.NoclipLoop:Disconnect() end)
        Connections.NoclipLoop = nil
    end

    if state then
        Connections.NoclipLoop = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
        Notif("SIEXTHER VD", "Noclip ON", 2)
    else
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
        Notif("SIEXTHER VD", "Noclip OFF", 2)
    end
end

-- SURVIVOR ESP
local SurvivorESPActive = false

local function ClearSurvivorESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            if char then
                local hl = char:FindFirstChild("SVD_SurvHL")
                if hl then hl:Destroy() end
                local bb = char:FindFirstChild("SVD_SurvBB")
                if bb then bb:Destroy() end
            end
        end
    end
end

local function ApplySurvivorESPToChar(char, player)
    if not char then return end
    if not char:FindFirstChild("SVD_SurvHL") then
        local hl = Instance.new("Highlight")
        hl.Name = "SVD_SurvHL"
        hl.FillColor = Color3.fromRGB(70, 130, 255)
        hl.OutlineColor = Color3.fromRGB(130, 180, 255)
        hl.FillTransparency = 0.4
        hl.OutlineTransparency = 0
        hl.Adornee = char
        hl.Parent = char
    end

    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if rootPart and not char:FindFirstChild("SVD_SurvBB") then
        local bb = Instance.new("BillboardGui")
        bb.Name = "SVD_SurvBB"
        bb.Size = UDim2.new(0, 90, 0, 34)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.AlwaysOnTop = true
        bb.Adornee = rootPart
        bb.Parent = char

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, 0, 0.55, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextColor3 = Color3.fromRGB(70, 130, 255)
        nameLbl.TextStrokeTransparency = 0
        nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLbl.TextSize = 11
        nameLbl.Text = player.Name
        nameLbl.Parent = bb

        local distLbl = Instance.new("TextLabel")
        distLbl.Size = UDim2.new(1, 0, 0.45, 0)
        distLbl.Position = UDim2.new(0, 0, 0.55, 0)
        distLbl.BackgroundTransparency = 1
        distLbl.Font = Enum.Font.Gotham
        distLbl.TextColor3 = Color3.fromRGB(160, 190, 255)
        distLbl.TextStrokeTransparency = 0
        distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        distLbl.TextSize = 9
        distLbl.Text = "..."
        distLbl.Parent = bb

        table.insert(Connections, RunService.RenderStepped:Connect(function()
            if not SurvivorESPActive then return end
            local lc = LocalPlayer.Character
            local hrp = lc and lc:FindFirstChild("HumanoidRootPart")
            if hrp and rootPart and rootPart.Parent then
                local dist = math.floor((hrp.Position - rootPart.Position).Magnitude)
                distLbl.Text = dist .. " studs"
            end
        end))
    end
end

local function ToggleSurvivorESP(state)
    SurvivorESPActive = state
    if Connections.SurvESPLoop then
        pcall(function() Connections.SurvESPLoop:Disconnect() end)
        Connections.SurvESPLoop = nil
    end
    if state then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not IsKiller(p) and p.Character then
                ApplySurvivorESPToChar(p.Character, p)
            end
        end
        Connections.SurvESPLoop = RunService.Heartbeat:Connect(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and not IsKiller(p) and p.Character then
                    if not p.Character:FindFirstChild("SVD_SurvHL") then
                        ApplySurvivorESPToChar(p.Character, p)
                    end
                end
            end
        end)
        Notif("SIEXTHER VD", "Survivor ESP ON", 2)
    else
        ClearSurvivorESP()
        Notif("SIEXTHER VD", "Survivor ESP OFF", 2)
    end
end

-- KILLER ESP
local KillerESPActive = false

local function ClearKillerESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            if char then
                local hl = char:FindFirstChild("SVD_KillerHL")
                if hl then hl:Destroy() end
                local bb = char:FindFirstChild("SVD_KillerBB")
                if bb then bb:Destroy() end
            end
        end
    end
end

local function ApplyKillerESPToChar(char, player)
    if not char then return end
    if not char:FindFirstChild("SVD_KillerHL") then
        local hl = Instance.new("Highlight")
        hl.Name = "SVD_KillerHL"
        hl.FillColor = Color3.fromRGB(220, 30, 30)
        hl.OutlineColor = Color3.fromRGB(255, 80, 80)
        hl.FillTransparency = 0.4
        hl.OutlineTransparency = 0
        hl.Adornee = char
        hl.Parent = char
    end

    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if rootPart and not char:FindFirstChild("SVD_KillerBB") then
        local bb = Instance.new("BillboardGui")
        bb.Name = "SVD_KillerBB"
        bb.Size = UDim2.new(0, 90, 0, 34)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.AlwaysOnTop = true
        bb.Adornee = rootPart
        bb.Parent = char

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, 0, 0.55, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
        nameLbl.TextStrokeTransparency = 0
        nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLbl.TextSize = 11
        nameLbl.Text = player.Name
        nameLbl.Parent = bb

        local distLbl = Instance.new("TextLabel")
        distLbl.Size = UDim2.new(1, 0, 0.45, 0)
        distLbl.Position = UDim2.new(0, 0, 0.55, 0)
        distLbl.BackgroundTransparency = 1
        distLbl.Font = Enum.Font.Gotham
        distLbl.TextColor3 = Color3.fromRGB(255, 180, 180)
        distLbl.TextStrokeTransparency = 0
        distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        distLbl.TextSize = 9
        distLbl.Text = "..."
        distLbl.Parent = bb

        table.insert(Connections, RunService.RenderStepped:Connect(function()
            if not KillerESPActive then return end
            local lc = LocalPlayer.Character
            local hrp = lc and lc:FindFirstChild("HumanoidRootPart")
            if hrp and rootPart and rootPart.Parent then
                local dist = math.floor((hrp.Position - rootPart.Position).Magnitude)
                distLbl.Text = dist .. " studs"
            end
        end))
    end
end

local function ToggleKillerESP(state)
    KillerESPActive = state
    if Connections.KillerESPLoop then
        pcall(function() Connections.KillerESPLoop:Disconnect() end)
        Connections.KillerESPLoop = nil
    end
    if state then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and IsKiller(p) and p.Character then
                ApplyKillerESPToChar(p.Character, p)
            end
        end
        Connections.KillerESPLoop = RunService.Heartbeat:Connect(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and IsKiller(p) and p.Character then
                    if not p.Character:FindFirstChild("SVD_KillerHL") then
                        ApplyKillerESPToChar(p.Character, p)
                    end
                end
            end
        end)
        Notif("SIEXTHER VD", "Killer ESP ON", 2)
    else
        ClearKillerESP()
        Notif("SIEXTHER VD", "Killer ESP OFF", 2)
    end
end

-- GENERATOR ESP
local GeneratorESPActive = false
local Highlights_Gen = {}
local BillboardGuis_Gen = {}

local function validateInstance(instance)
    return instance and typeof(instance) == "Instance" and instance.Parent ~= nil
end

local function isGeneratorComplete(obj)
    local val = obj:FindFirstChild("GeneratorValue") or obj:FindFirstChild("Progress") or obj:FindFirstChild("Repaired")
    if val then
        if val:IsA("BoolValue") and val.Value == true then return true end
        if (val:IsA("NumberValue") or val:IsA("IntValue")) and val.Value >= 100 then return true end
    end
    for _, child in ipairs(obj:GetChildren()) do
        local nm = child.Name:lower()
        if nm:find("complet") or nm:find("done") or nm:find("finish") then
            if child:IsA("BoolValue") and child.Value == true then return true end
        end
    end
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt")
    if prompt and not prompt.Enabled then return true end
    return false
end

local function createGeneratorHighlight(obj)
    if not validateInstance(obj) then return end
    if Highlights_Gen[obj] and validateInstance(Highlights_Gen[obj]) then return end
    if Highlights_Gen[obj] then Highlights_Gen[obj] = nil end
    local existingH = obj:FindFirstChild("SVD_GenHL2")
    if existingH then existingH:Destroy() end
    safeCall(function()
        local h = Instance.new("Highlight")
        h.Name = "SVD_GenHL2"
        h.Adornee = obj
        h.FillColor = Color3.fromRGB(255, 255, 0)
        h.OutlineColor = Color3.fromRGB(255, 255, 0)
        h.FillTransparency = 0.5
        h.OutlineTransparency = 0
        h.Parent = obj
        Highlights_Gen[obj] = h
    end)
end

local function removeGeneratorHighlight(obj)
    if Highlights_Gen[obj] then
        safeCall(function()
            if validateInstance(Highlights_Gen[obj]) then
                Highlights_Gen[obj]:Destroy()
            end
        end)
        Highlights_Gen[obj] = nil
    end
    local existingH = obj:FindFirstChild("SVD_GenHL2")
    if existingH then pcall(function() existingH:Destroy() end) end
end

local function createGeneratorLabel(obj)
    if not validateInstance(obj) then return end
    local playerRoot = getCharacterRootPart()
    if not playerRoot then return end
    local rootPart = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart")
        or (obj:IsA("BasePart") and obj or nil)
    if not rootPart then return end
    local distance = (playerRoot.Position - rootPart.Position).Magnitude
    if BillboardGuis_Gen[obj] and validateInstance(BillboardGuis_Gen[obj]) then
        local textLabel = BillboardGuis_Gen[obj]:FindFirstChild("TextLabel")
        if textLabel then
            textLabel.Text = string.format("Gen\n%.0fm", distance)
        end
        return
    end
    BillboardGuis_Gen[obj] = nil
    safeCall(function()
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 80, 0, 30)
        billboard.AlwaysOnTop = true
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Adornee = rootPart
        billboard.Parent = obj

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        textLabel.TextStrokeTransparency = 0
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 10
        textLabel.Text = string.format("Gen\n%.0fm", distance)
        textLabel.Parent = billboard

        BillboardGuis_Gen[obj] = billboard
    end)
end

local function removeGeneratorLabel(obj)
    if BillboardGuis_Gen[obj] then
        safeCall(function()
            if validateInstance(BillboardGuis_Gen[obj]) then
                BillboardGuis_Gen[obj]:Destroy()
            end
        end)
        BillboardGuis_Gen[obj] = nil
    end
end

local function clearAllGeneratorESP()
    for obj, _ in pairs(Highlights_Gen) do removeGeneratorHighlight(obj) end
    for obj, _ in pairs(BillboardGuis_Gen) do removeGeneratorLabel(obj) end
    Highlights_Gen = {}
    BillboardGuis_Gen = {}
end

local function updateGeneratorESP()
    if not GeneratorESPActive then return end
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Generator" then
            if isGeneratorComplete(obj) then
                removeGeneratorHighlight(obj)
                removeGeneratorLabel(obj)
            else
                createGeneratorHighlight(obj)
                createGeneratorLabel(obj)
            end
        end
    end
end

local function ToggleGeneratorESP(state)
    GeneratorESPActive = state
    if Connections.GenESPLoop then
        pcall(function() Connections.GenESPLoop:Disconnect() end)
        Connections.GenESPLoop = nil
    end
    if state then
        Connections.GenESPLoop = RunService.Heartbeat:Connect(function()
            updateGeneratorESP()
        end)
        Notif("SIEXTHER VD", "Generator ESP ON", 3)
    else
        clearAllGeneratorESP()
        Notif("SIEXTHER VD", "Generator ESP OFF", 2)
    end
end

-- TELEPORT
local function TeleportToSurvivor()
    local lc = LocalPlayer.Character
    if not lc or not lc:FindFirstChild("HumanoidRootPart") then return end
    local tgt, md = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not IsKiller(p) and p.Character
            and p.Character:FindFirstChild("HumanoidRootPart") then
            local d = (lc.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if d < md then md = d; tgt = p end
        end
    end
    if tgt then
        lc.HumanoidRootPart.CFrame = tgt.Character.HumanoidRootPart.CFrame
        Notif("SIEXTHER VD", "Teleported to " .. tgt.Name, 2)
    else
        Notif("SIEXTHER VD", "No survivor found", 2)
    end
end

local function TeleportToKiller()
    local lc = LocalPlayer.Character
    if not lc or not lc:FindFirstChild("HumanoidRootPart") then return end
    local tgt, md = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsKiller(p) and p.Character
            and p.Character:FindFirstChild("HumanoidRootPart") then
            local d = (lc.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if d < md then md = d; tgt = p end
        end
    end
    if tgt then
        lc.HumanoidRootPart.CFrame = tgt.Character.HumanoidRootPart.CFrame
        Notif("SIEXTHER VD", "Teleported to Killer: " .. tgt.Name, 2)
    else
        Notif("SIEXTHER VD", "No killer found", 2)
    end
end

-- AUTO COMPLETE GENERATORS
local AutoGeneratorActive = false

task.spawn(function()
    while true do
        task.wait(0.2)
        if AutoGeneratorActive then
            safeCall(function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if not remotes then return end
                local genRemotes = remotes:FindFirstChild("Generator")
                if not genRemotes then return end
                local repairEvent = genRemotes:FindFirstChild("RepairEvent")
                local skillCheckEvent = genRemotes:FindFirstChild("SkillCheckResultEvent")
                if not repairEvent or not skillCheckEvent then return end
                local map = workspace:FindFirstChild("Map")
                if not map then return end
                for _, obj in ipairs(map:GetDescendants()) do
                    if obj:IsA("Model") and obj.Name == "Generator" then
                        for _, point in ipairs(obj:GetChildren()) do
                            if point.Name:find("GeneratorPoint") then
                                pcall(function()
                                    repairEvent:FireServer(point, true)
                                    skillCheckEvent:FireServer("success", 1, obj, point)
                                end)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- AUTO ATTACK
local AutoAttackActive = false
local AutoAttackRange = 10
local AutoAttackConnection = nil
local lastAttackTime = 0
local ATTACK_COOLDOWN = 0.3

local function findClosestSurvivor()
    if not isKiller() then return nil, nil end
    local hrp = getCharacterRootPart()
    if not hrp then return nil, nil end
    local closestPlayer = nil
    local closestDist = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team and player.Team.Name == "Survivors" and player.Character then
            local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local dist = (targetHRP.Position - hrp.Position).Magnitude
                if dist < closestDist and dist <= AutoAttackRange then
                    closestDist = dist
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer, closestDist
end

local function performAutoAttack()
    if not isKiller() then return end
    local target, _ = findClosestSurvivor()
    if not target then return end
    safeCall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local attacks = remotes:FindFirstChild("Attacks")
        if not attacks then return end
        local basicAttack = attacks:FindFirstChild("BasicAttack")
        if basicAttack then basicAttack:FireServer(false) end
    end)
end

local function startAutoAttack()
    if AutoAttackConnection then return end
    if not isKiller() then
        Notif("SIEXTHER VD", "Must be Killer!", 3)
        return
    end
    AutoAttackConnection = RunService.Heartbeat:Connect(function()
        if not AutoAttackActive then return end
        local now = tick()
        if now - lastAttackTime < ATTACK_COOLDOWN then return end
        lastAttackTime = now
        performAutoAttack()
    end)
    table.insert(Connections, AutoAttackConnection)
    Notif("SIEXTHER VD", "Auto Attack ON | Range: " .. AutoAttackRange, 3)
end

local function stopAutoAttack()
    if AutoAttackConnection then
        AutoAttackConnection:Disconnect()
        AutoAttackConnection = nil
    end
    Notif("SIEXTHER VD", "Auto Attack OFF", 2)
end

-- MAIN SCREEN GUI
local Root = Instance.new("ScreenGui")
Root.Name = "SiextherVD_GUI"
Root.DisplayOrder = 999
Root.ResetOnSpawn = false
Root.IgnoreGuiInset = true
Root.Parent = PlayerGui

local FULL_W    = 190
local FULL_H    = 360
local FULL_SIZE = UDim2.new(0, FULL_W, 0, FULL_H)

-- FLOATING SX BUTTON
local floatBtn = Instance.new("TextButton")
floatBtn.Name = "FloatSX"
floatBtn.Size = UDim2.new(0, 41, 0, 41)
floatBtn.Position = UDim2.new(0, 18, 0.5, -18)
floatBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
floatBtn.Text = "SX"
floatBtn.Font = Enum.Font.GothamBold
floatBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
floatBtn.TextSize = 25
floatBtn.BorderSizePixel = 0
floatBtn.Visible = true
floatBtn.ZIndex = 200
floatBtn.Parent = Root
corner(floatBtn, 10)
makeDraggable(floatBtn, floatBtn)

-- Animasi teks ganti-ganti SX / VD
local floatTexts = {"SX", "VD"}
local floatTextIndex = 1

task.spawn(function()
    while floatBtn and floatBtn.Parent do
        task.wait(3)
        floatTextIndex = (floatTextIndex % #floatTexts) + 1
        -- Fade out
        TweenService:Create(floatBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 1
        }):Play()
        task.wait(0.35)
        -- Ganti teks
        floatBtn.Text = floatTexts[floatTextIndex]
        -- Fade in
        TweenService:Create(floatBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 0
        }):Play()
    end
end)

-- Gradient animasi
local MinimizedGradient = Instance.new("UIGradient")
MinimizedGradient.Parent = floatBtn
MinimizedGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
MinimizedGradient.Offset = Vector2.new(-1, 0)

task.spawn(function()
    while floatBtn and floatBtn.Parent do
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

-- MAIN FRAME
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = FULL_SIZE
Main.Position = UDim2.new(0.5, -(FULL_W/2), 0.15, 0)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = Root
corner(Main, 10)
stroke(Main, C.stroke, 1.5)

local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 38)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 18)),
})
grad.Rotation = 135
grad.Parent = Main

-- TITLE BAR
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 28)
TitleBar.BackgroundColor3 = C.surface
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 10
TitleBar.Parent = Main
corner(TitleBar, 10)

local tbFix = Instance.new("Frame")
tbFix.Size = UDim2.new(1, 0, 0, 12)
tbFix.Position = UDim2.new(0, 0, 1, -12)
tbFix.BackgroundColor3 = C.surface
tbFix.BorderSizePixel = 0
tbFix.ZIndex = 10
tbFix.Parent = TitleBar

local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(0, 3, 0.6, 0)
accentBar.Position = UDim2.new(0, 6, 0.2, 0)
accentBar.BackgroundColor3 = C.stroke
accentBar.BorderSizePixel = 0
accentBar.ZIndex = 12
accentBar.Parent = TitleBar
corner(accentBar, 2)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -90, 1, 0)
titleLbl.Position = UDim2.new(0, 14, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "SIEXTHER VD"
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextColor3 = Color3.fromRGB(70, 130, 255)
titleLbl.TextSize = 12
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.ZIndex = 12
titleLbl.Parent = TitleBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 20, 0, 16)
minBtn.Position = UDim2.new(1, -44, 0.5, -8)
minBtn.BackgroundColor3 = C.minClr
minBtn.BorderSizePixel = 0
minBtn.Text = "–"
minBtn.Font = Enum.Font.GothamBold
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.TextSize = 9
minBtn.ZIndex = 13
minBtn.Parent = TitleBar
corner(minBtn, 4)

minBtn.MouseEnter:Connect(function() tween(minBtn, {BackgroundColor3 = C.minHov}) end)
minBtn.MouseLeave:Connect(function() tween(minBtn, {BackgroundColor3 = C.minClr}) end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 20, 0, 16)
closeBtn.Position = UDim2.new(1, -22, 0.5, -8)
closeBtn.BackgroundColor3 = C.red
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 9
closeBtn.ZIndex = 13
closeBtn.Parent = TitleBar
corner(closeBtn, 4)

closeBtn.MouseEnter:Connect(function() tween(closeBtn, {BackgroundColor3 = C.redHov}) end)
closeBtn.MouseLeave:Connect(function() tween(closeBtn, {BackgroundColor3 = C.red}) end)

closeBtn.MouseButton1Click:Connect(function()
    ToggleCrosshair(false)
    ToggleNoclip(false)
    ToggleSurvivorESP(false)
    ToggleKillerESP(false)
    ToggleGeneratorESP(false)
    AutoGeneratorActive = false
    AutoAttackActive = false
    stopAutoAttack()
    for k, v in pairs(Connections) do
        pcall(function()
            if typeof(v) == "RBXScriptConnection" then v:Disconnect() end
        end)
        Connections[k] = nil
    end
    _G.SiextherVD = nil
    Root:Destroy()
end)

minBtn.MouseButton1Click:Connect(function()
    tween(Main, {Size = UDim2.new(0, FULL_W, 0, 0)})
    task.wait(0.18)
    Main.Visible = false
    floatBtn.Visible = true
end)

floatBtn.MouseButton1Click:Connect(function()
    floatBtn.Visible = false
    Main.Visible = true
    Main.Size = UDim2.new(0, FULL_W, 0, 0)
    tween(Main, {Size = FULL_SIZE})
end)

-- DRAG
makeDraggable(Main, TitleBar)

-- SCROLL CONTENT
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -8, 1, -34)
Scroll.Position = UDim2.new(0, 4, 0, 30)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = C.stroke
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.ClipsDescendants = true
Scroll.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 3)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Scroll

local Pad = Instance.new("UIPadding")
Pad.PaddingBottom = UDim.new(0, 4)
Pad.PaddingTop = UDim.new(0, 2)
Pad.Parent = Scroll

Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 8)
end)

local order = 0
local function nextO() order = order + 1; return order end

-- DIVIDER
local function Divider(txt)
    local f = Instance.new("Frame")
    f.LayoutOrder = nextO()
    f.Size = UDim2.new(1, 0, 0, 18)
    f.BackgroundTransparency = 1
    f.Parent = Scroll

    local line1 = Instance.new("Frame")
    line1.Size = UDim2.new(0.5, -45, 0, 1)
    line1.Position = UDim2.new(0, 0, 0.5, 0)
    line1.BackgroundColor3 = Color3.fromRGB(40, 50, 72)
    line1.BorderSizePixel = 0
    line1.Parent = f

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 84, 1, 0)
    lbl.Position = UDim2.new(0.5, -42, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.Font = Enum.Font.GothamBold
    lbl.TextColor3 = C.stroke
    lbl.TextSize = 8
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.Parent = f

    local line2 = Instance.new("Frame")
    line2.Size = UDim2.new(0.5, -45, 0, 1)
    line2.Position = UDim2.new(0.5, 45, 0.5, 0)
    line2.BackgroundColor3 = Color3.fromRGB(40, 50, 72)
    line2.BorderSizePixel = 0
    line2.Parent = f
end

-- TOGGLE
local function Toggle(txt, default, cb)
    local f = Instance.new("Frame")
    f.LayoutOrder = nextO()
    f.Size = UDim2.new(1, 0, 0, 26)
    f.BackgroundColor3 = C.card
    f.BorderSizePixel = 0
    f.Parent = Scroll
    corner(f, 6)
    stroke(f, Color3.fromRGB(35, 35, 55), 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -52, 1, 0)
    lbl.Position = UDim2.new(0, 7, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.Font = Enum.Font.GothamBold
    lbl.TextColor3 = C.text
    lbl.TextSize = 8
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f

    local pill = Instance.new("TextButton")
    pill.Size = UDim2.new(0, 36, 0, 16)
    pill.Position = UDim2.new(1, -42, 0.5, -8)
    pill.BackgroundColor3 = default and C.onClr or C.offClr
    pill.BorderSizePixel = 0
    pill.Text = default and "ON" or "OFF"
    pill.Font = Enum.Font.GothamBold
    pill.TextColor3 = Color3.fromRGB(255, 255, 255)
    pill.TextSize = 7
    pill.ZIndex = 5
    pill.Parent = f
    corner(pill, 4)

    local state = default
    pill.MouseButton1Click:Connect(function()
        state = not state
        pill.Text = state and "ON" or "OFF"
        tween(pill, {BackgroundColor3 = state and C.onClr or C.offClr})
        cb(state)
    end)

    return f
end

-- SLIDER
local function Slider(txt, min, max, default, cb)
    local f = Instance.new("Frame")
    f.LayoutOrder = nextO()
    f.Size = UDim2.new(1, 0, 0, 40)
    f.BackgroundColor3 = C.card
    f.BorderSizePixel = 0
    f.Parent = Scroll
    corner(f, 6)
    stroke(f, Color3.fromRGB(35, 35, 55), 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 0, 16)
    lbl.Position = UDim2.new(0, 7, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextColor3 = C.text
    lbl.TextSize = 8
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = txt .. ": " .. default
    lbl.Parent = f

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -14, 0, 5)
    track.Position = UDim2.new(0, 7, 0, 26)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    track.BorderSizePixel = 0
    track.Parent = f
    corner(track, 3)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = C.stroke
    fill.BorderSizePixel = 0
    fill.Parent = track
    corner(fill, 3)

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0)
    knob.BackgroundColor3 = C.accent
    knob.BorderSizePixel = 0
    knob.Text = ""
    knob.ZIndex = 5
    knob.Parent = track
    corner(knob, 6)

    local dragging = false
    knob.MouseButton1Down:Connect(function() dragging = true end)
    table.insert(Connections, UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end))
    table.insert(Connections, UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            local trackAbs = track.AbsolutePosition
            local trackSize = track.AbsoluteSize
            local rel = math.clamp((i.Position.X - trackAbs.X) / trackSize.X, 0, 1)
            local val = math.floor(min + (max - min) * rel)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, 0, 0.5, 0)
            lbl.Text = txt .. ": " .. val
            cb(val)
        end
    end))
end

-- BUTTON
local function Button(txt, cb)
    local btn = Instance.new("TextButton")
    btn.LayoutOrder = nextO()
    btn.Size = UDim2.new(1, 0, 0, 26)
    btn.BackgroundColor3 = C.card
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.ZIndex = 2
    btn.Parent = Scroll
    corner(btn, 6)
    stroke(btn, Color3.fromRGB(35, 35, 55), 1)

    local arw = Instance.new("TextLabel")
    arw.Size = UDim2.new(0, 12, 1, 0)
    arw.Position = UDim2.new(0, 7, 0, 0)
    arw.BackgroundTransparency = 1
    arw.Text = "›"
    arw.Font = Enum.Font.GothamBold
    arw.TextColor3 = C.stroke
    arw.TextSize = 13
    arw.TextXAlignment = Enum.TextXAlignment.Left
    arw.ZIndex = 3
    arw.Parent = btn

    local lbl2 = Instance.new("TextLabel")
    lbl2.Size = UDim2.new(1, -22, 1, 0)
    lbl2.Position = UDim2.new(0, 20, 0, 0)
    lbl2.BackgroundTransparency = 1
    lbl2.Text = txt
    lbl2.Font = Enum.Font.GothamBold
    lbl2.TextColor3 = C.text
    lbl2.TextSize = 8
    lbl2.TextXAlignment = Enum.TextXAlignment.Left
    lbl2.ZIndex = 3
    lbl2.Parent = btn

    btn.MouseEnter:Connect(function()
        tween(btn, {BackgroundColor3 = Color3.fromRGB(32, 32, 50)})
        tween(arw, {TextColor3 = C.accent})
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, {BackgroundColor3 = C.card})
        tween(arw, {TextColor3 = C.stroke})
    end)
    btn.MouseButton1Click:Connect(function()
        tween(btn, {BackgroundColor3 = Color3.fromRGB(40, 60, 100)})
        task.wait(0.12)
        tween(btn, {BackgroundColor3 = C.card})
        task.spawn(cb)
    end)
end

-- BUILD UI
Divider("S I E X T H E R")
Toggle("Auto Complete Generators", false, function(v)
    AutoGeneratorActive = v
    Notif("SIEXTHER VD", "Auto Generator " .. (v and "ON" or "OFF"), 2)
end)
Toggle("Crosshair Center", false, function(v)
    ToggleCrosshair(v)
    Notif("SIEXTHER VD", "Crosshair " .. (v and "ON" or "OFF"), 2)
end)
Toggle("Noclip", false, function(v)
    ToggleNoclip(v)
end)

Divider("TELEPORT")
Button("Teleport to Survivors", TeleportToSurvivor)
Button("Teleport to Killer", TeleportToKiller)

Divider("ESP")
Toggle("Survivor ESP", false, function(v)
    ToggleSurvivorESP(v)
end)
Toggle("Killer ESP", false, function(v)
    ToggleKillerESP(v)
end)
Toggle("Generator ESP", false, function(v)
    ToggleGeneratorESP(v)
end)

Divider("KILLER ONLY")
Toggle("Auto Attack Survivors", false, function(v)
    AutoAttackActive = v
    if v then
        startAutoAttack()
    else
        stopAutoAttack()
    end
end)
Slider("Attack Range", 5, 20, 10, function(v)
    AutoAttackRange = v
end)
Button("Activate Killer Power", function()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then Notif("SIEXTHER VD", "Remotes not found", 2) return end
    local killerRemotes = remotes:FindFirstChild("Killers")
    if not killerRemotes then Notif("SIEXTHER VD", "Killers remote not found", 2) return end
    local killerFolder = killerRemotes:FindFirstChild("Killer")
    if not killerFolder then Notif("SIEXTHER VD", "Killer folder not found", 2) return end
    local activatePower = killerFolder:FindFirstChild("ActivatePower")
    if activatePower then
        activatePower:FireServer()
        Notif("SIEXTHER VD", "Killer power triggered", 2)
    else
        Notif("SIEXTHER VD", "ActivatePower not found", 2)
    end
end)
Button("Basic Attack", function()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then Notif("SIEXTHER VD", "Remotes not found", 2) return end
    local attacks = remotes:FindFirstChild("Attacks")
    if not attacks then Notif("SIEXTHER VD", "Attacks remote not found", 2) return end
    local basicAttack = attacks:FindFirstChild("BasicAttack")
    if basicAttack then
        basicAttack:FireServer(false)
        Notif("SIEXTHER VD", "Basic attack executed", 2)
    else
        Notif("SIEXTHER VD", "BasicAttack not found", 2)
    end
end)

-- startup notify
Notif("SIEXTHER VD", "HANN.SIEXTHER", 3)