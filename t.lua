local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Variables dari script asli
local getpart = 300
local currentMode = 2
local radius = 50
local speed = 2
local isActive = false
local lastValidPosition = Vector3.new(0, 0, 0)
local UPDATE_INTERVAL = 0
local lastUpdate = tick()
local ringParts = {}
local humanoidRootPart
local blackHoleActive = false
local bhradius = 8
local angleSpeed = 10
local angle = 1
local currentTargetPlayer = LocalPlayer
local Folder, Attachment1
local controlledParts = {}
local descendantConnection = nil
local renderLoop = nil

local modes = {
    "VERTICAL", "HORIZONTAL", "VERTICAL & HORIZONTAL",
    "Left Tilt", "Right Tilt", "Left & Right Tilt", "Spiral", "Figure 8",
    "HELIX", "Flower Pattern", "Galaxy Spiral", "Infinity", "Wave Pattern",
    "Atomic Orbit", "Butterfly", "Tornado", "Heart", "Vortex", "Pendulum",
    "Lemniscate 3D", "Star Pattern", "Trefoil Knot", "Double Spiral",
    "Mobius Strip", "Hypocycloid", "Sphere Spiral", "Asteroid Belt",
    "Rose Curve", "Lissajous", "Polygonal Orbit"
}

-- Network setup
if not getgenv().Network then
    getgenv().Network = {
        BaseParts = {},
        FPS = 20,
        Velocity = Vector3.new(25.1, 0, 0)
    }
    
    local function EnableNetwork()
        local function UpdateNetwork()
            if not isActive then return end
            pcall(function()
                sethiddenproperty(LocalPlayer, "MaxSimulationRadius", getpart)
                sethiddenproperty(LocalPlayer, "SimulationRadius", getpart)
            end)
            local partsToProcess = {}
            for part in pairs(Network.BaseParts) do
                table.insert(partsToProcess, part)
            end
            for _, part in ipairs(partsToProcess) do
                if not part or not part.Parent then
                    Network.BaseParts[part] = nil
                    continue
                end
                pcall(function()
                    sethiddenproperty(part, "NetworkOwnership", Enum.NetworkOwnership.Manual)
                    sethiddenproperty(part, "CustomPhysicalProperties", PhysicalProperties.new(0.7, 0.3, 0.5))
                    part.Velocity = Network.Velocity
                end)
            end
        end
        RunService.Heartbeat:Connect(UpdateNetwork)
    end
    EnableNetwork()
end

-- Fungsi helper
local function GetPlayer(name)
    if not name or name == "" then return LocalPlayer end
    if string.lower(name) == "You" then return LocalPlayer end
    name = string.lower(name)
    for _, plr in pairs(Players:GetPlayers()) do
        if string.find(string.lower(plr.Name), name) or string.find(string.lower(plr.DisplayName), name) then
            return plr
        end
    end
    return LocalPlayer
end

local function GetPlayerList()
    local playerList = {{
        name = "You", 
        display = LocalPlayer.DisplayName .. " (You)", 
        username = "You"
    }}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerList, {
                name = player.Name,
                display = player.DisplayName .. " (@" .. player.Name .. ")",
                username = player.Name
            })
        end
    end
    return playerList
end

local function setupPlayer(targetPlayer)
    local character = targetPlayer.Character
    if not character then
        character = targetPlayer.CharacterAdded:Wait()
    end
    local rootPart = character:WaitForChild("HumanoidRootPart")
    if Folder then
        Folder:Destroy()
        Folder = nil
    end
    Folder = Instance.new("Folder", Workspace)
    Folder.Name = "BlackHoleAttachments"
    local Part = Instance.new("Part", Folder)
    Part.Name = "BlackHoleCenter"
    Attachment1 = Instance.new("Attachment", Part)
    Part.Anchored = true
    Part.CanCollide = false
    Part.Transparency = 1
    return rootPart, Attachment1
end

humanoidRootPart, Attachment1 = setupPlayer(LocalPlayer)

local function processPart(part)
    if part:IsA("Part") and not part.Anchored and 
       not part.Parent:FindFirstChild("Humanoid") and 
       not part.Parent:FindFirstChild("Head") and 
       part.Name ~= "Handle" then
        
        if not pcall(function() return part.Parent end) then
            return nil
        end
        
        for _, child in pairs(part:GetChildren()) do
            if child:IsA("BodyAngularVelocity") or child:IsA("BodyForce") or 
               child:IsA("BodyGyro") or child:IsA("BodyPosition") or 
               child:IsA("BodyThrust") or child:IsA("BodyVelocity") or 
               child:IsA("RocketPropulsion") or child:IsA("Attachment") or 
               child:IsA("AlignPosition") or child:IsA("AlignOrientation") or 
               child:IsA("LinearVelocity") or child:IsA("BodyMover") then
                child:Destroy()
            end
        end
        
        part.CanCollide = false
        part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        
        local attachment = Instance.new("Attachment", part)
        local alignPos = Instance.new("AlignPosition", part)
        alignPos.Attachment0 = attachment
        alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
        alignPos.Responsiveness = 200
        
        return {
            part = part,
            align = alignPos,
            index = 0
        }
    end
    return nil
end

local function calculateRingPosition(index, totalParts, center)
    local angle = (index / totalParts) * (2 * math.pi) + tick() * speed
    local offsetX, offsetY, offsetZ = 0, 0, 0
    
    if currentMode == 1 then
        offsetX = math.cos(angle) * radius
        offsetY = math.sin(angle) * radius
    elseif currentMode == 2 then
        offsetX = math.cos(angle) * radius
        offsetZ = math.sin(angle) * radius
    elseif currentMode == 3 then
        local angle2 = angle + math.pi/2
        offsetX = math.cos(angle) * radius
        offsetY = math.sin(angle2) * radius
        offsetZ = math.sin(angle) * radius
    elseif currentMode == 4 then
        offsetX = math.cos(angle) * radius
        offsetY = math.sin(angle) * radius * 0.5
        offsetZ = math.sin(angle) * radius * 0.866
    elseif currentMode == 5 then
        offsetX = math.cos(angle) * radius
        offsetY = math.sin(angle) * radius * 0.5
        offsetZ = -math.sin(angle) * radius * 0.866
    elseif currentMode == 6 then
        local tiltAngle = math.sin(tick() * speed * 0.5) * math.pi/3
        offsetX = math.cos(angle) * radius
        offsetY = math.sin(angle) * radius * math.cos(tiltAngle)
        offsetZ = math.sin(angle) * radius * math.sin(tiltAngle)
    elseif currentMode == 7 then
        local heightOffset = ((index / totalParts) * 2 - 1) * radius
        offsetX = math.cos(angle) * radius
        offsetY = heightOffset
        offsetZ = math.sin(angle) * radius
    elseif currentMode == 8 then
        local scale = 1.5
        offsetX = math.cos(angle) * radius
        offsetY = math.sin(2 * angle) * radius * 0.5
        offsetZ = math.sin(angle) * radius * scale
    elseif currentMode == 9 then
        local heightOffset = math.sin(tick() * speed) * radius
        offsetX = math.cos(angle) * radius
        offsetY = math.cos(angle * 2) * radius + heightOffset
        offsetZ = math.sin(angle) * radius
    elseif currentMode == 10 then
        local petalCount = 5
        local r = math.cos(petalCount * angle) * radius
        offsetX = math.cos(angle) * r
        offsetY = math.sin(angle) * r
        offsetZ = math.sin(petalCount * angle) * radius * 0.5
    elseif currentMode == 11 then
        local spiralTightness = 0.2
        local r = (1 + angle * spiralTightness) * radius
        offsetX = math.cos(angle) * r
        offsetY = math.sin(tick() * speed) * radius * 0.2
        offsetZ = math.sin(angle) * r
    elseif currentMode == 12 then
        local scale = 1.5
        offsetX = math.cos(angle) * radius * scale
        offsetY = math.sin(2 * angle) * radius * 0.5
        offsetZ = math.sin(angle) * radius
    elseif currentMode == 13 then
        offsetX = angle * radius * 0.1
        offsetY = math.sin(angle * 2) * radius
        offsetZ = math.cos(angle * 2) * radius
    elseif currentMode == 14 then
        local subOrbitRadius = radius * 0.3
        local mainAngle = tick() * speed
        local subAngle = angle * 3
        offsetX = math.cos(mainAngle) * radius + math.cos(subAngle) * subOrbitRadius
        offsetY = math.sin(mainAngle) * radius + math.sin(subAngle) * subOrbitRadius
        offsetZ = math.cos(subAngle) * subOrbitRadius
    elseif currentMode == 15 then
        local t = angle
        offsetX = math.sin(t) * (math.exp(math.cos(t)) - 2 * math.cos(4*t) - math.pow(math.sin(t/12), 5)) * radius * 0.5
        offsetY = math.cos(t) * (math.exp(math.cos(t)) - 2 * math.cos(4*t) - math.pow(math.sin(t/12), 5)) * radius * 0.5
        offsetZ = math.sin(t * 3) * radius * 0.3
    elseif currentMode == 16 then
        local heightScale = 2
        local r = radius * (1 - (index / totalParts))
        offsetX = math.cos(angle) * r
        offsetY = (index / totalParts) * radius * heightScale
        offsetZ = math.sin(angle) * r
    elseif currentMode == 17 then
        local t = angle
        offsetX = 16 * math.sin(t) ^ 3 * (radius * 0.1)
        offsetY = (13 * math.cos(t) - 5 * math.cos(2*t) - 2 * math.cos(3*t) - math.cos(4*t)) * (radius * 0.1)
        offsetZ = math.sin(t * 2) * radius * 0.3
    elseif currentMode == 18 then
        local spiral = angle * 0.1
        local height = math.sin(tick() * speed) * radius
        offsetX = (radius + spiral) * math.cos(angle)
        offsetY = height + (index / totalParts) * radius
        offsetZ = (radius + spiral) * math.sin(angle)
    elseif currentMode == 19 then
        local swingAngle = math.sin(tick() * speed) * math.pi/2
        offsetX = math.sin(swingAngle) * radius
        offsetY = -math.cos(swingAngle) * radius
        offsetZ = math.sin(angle) * radius * 0.3
    elseif currentMode == 20 then
        local t = angle
        local scale = radius * 0.8
        offsetX = scale * math.cos(t) / (1 + math.sin(t)^2)
        offsetY = scale * math.sin(t) * math.cos(t) / (1 + math.sin(t)^2)
        offsetZ = math.sin(t * 2) * radius * 0.5
    elseif currentMode == 21 then
        local points = 5
        local innerRadius = radius * 0.4
        local t = angle * points
        local r = innerRadius + (radius - innerRadius) * math.abs(math.sin(t))
        offsetX = r * math.cos(angle)
        offsetY = r * math.sin(angle)
        offsetZ = math.sin(angle * points) * radius * 0.3
    elseif currentMode == 22 then
        local t = angle
        offsetX = (2 + math.cos(3*t)) * math.cos(2*t) * radius * 0.2
        offsetY = (2 + math.cos(3*t)) * math.sin(2*t) * radius * 0.2
        offsetZ = math.sin(3*t) * radius * 0.2
    elseif currentMode == 23 then
        local t = angle
        local r1 = radius * (0.5 + 0.5 * math.cos(t * 5))
        local r2 = radius * (0.5 + 0.5 * math.sin(t * 5))
        offsetX = math.cos(t) * r1
        offsetY = math.sin(t) * r1
        offsetZ = math.cos(t) * r2
    elseif currentMode == 24 then
        local t = angle
        local s = (index / totalParts) * 2 - 1
        offsetX = (radius + s * math.cos(t/2)) * math.cos(t)
        offsetY = (radius + s * math.cos(t/2)) * math.sin(t)
        offsetZ = s * math.sin(t/2)
    elseif currentMode == 25 then
        local a = radius
        local b = radius * 0.2
        local t = angle * 4
        offsetX = (a - b) * math.cos(t) + b * math.cos((a-b)/b * t)
        offsetY = (a - b) * math.sin(t) - b * math.sin((a-b)/b * t)
        offsetZ = math.sin(t * 2) * radius * 0.3
    elseif currentMode == 26 then
        local phi = angle
        local theta = (index / totalParts) * math.pi
        offsetX = radius * math.sin(theta) * math.cos(phi)
        offsetY = radius * math.sin(theta) * math.sin(phi)
        offsetZ = radius * math.cos(theta)
    elseif currentMode == 27 then
        local baseAngle = (index / totalParts) * (2 * math.pi)
        local wobble = math.sin(tick() * speed + baseAngle * 3) * (radius * 0.2)
        local r = radius + wobble
        offsetX = math.cos(angle) * r
        offsetY = math.sin(baseAngle * 2) * (radius * 0.1)
        offsetZ = math.sin(angle) * r
    elseif currentMode == 28 then
        local n = 3
        local d = 2
        local k = n/d
        local r = radius * math.cos(k * angle)
        offsetX = r * math.cos(angle)
        offsetY = r * math.sin(angle)
        offsetZ = math.sin(angle * k) * radius * 0.3
    elseif currentMode == 29 then
        local a = 3
        local b = 2
        offsetX = radius * math.sin(a * angle)
        offsetY = radius * math.cos(b * angle)
        offsetZ = radius * math.sin((a+b) * angle) * 0.3
    elseif currentMode == 30 then
        local sides = 6
        local angleSnap = math.floor(angle * sides / (2 * math.pi)) * (2 * math.pi / sides)
        local transition = (angle * sides / (2 * math.pi)) % 1
        local nextAngleSnap = angleSnap + (2 * math.pi / sides)
        local currentX = math.cos(angleSnap) * radius
        local currentZ = math.sin(angleSnap) * radius
        local nextX = math.cos(nextAngleSnap) * radius
        local nextZ = math.sin(nextAngleSnap) * radius
        offsetX = currentX + (nextX - currentX) * transition
        offsetY = math.sin(angle * 2) * radius * 0.2
        offsetZ = currentZ + (nextZ - currentZ) * transition
    end
    
    return center + Vector3.new(offsetX, offsetY, offsetZ)
end

local function updateRingPositions()
    if not isActive then return end
    local currentTime = tick()
    if currentTime - lastUpdate < UPDATE_INTERVAL then return end
    lastUpdate = currentTime
    local position = (humanoidRootPart and humanoidRootPart.Position) or lastValidPosition
    if position then
        lastValidPosition = position
        local totalParts = #ringParts
        for i = #ringParts, 1, -1 do
            local data = ringParts[i]
            local validPart = pcall(function() return data.part.Parent ~= nil end)
            if validPart then
                local targetPos = calculateRingPosition(i, totalParts, position)
                data.align.Position = targetPos
            else
                Network.BaseParts[data.part] = nil
                table.remove(ringParts, i)
            end
        end
    end
end

local function orbite()
    isActive = not isActive
    if isActive then
        ringParts = {}
        for _, v in ipairs(Workspace:GetDescendants()) do
            local partData = processPart(v)
            if partData then
                table.insert(ringParts, partData)
                Network.BaseParts[partData.part] = true
            end
        end
        local connection
        connection = Workspace.DescendantAdded:Connect(function(v)
            if not isActive then
                connection:Disconnect()
                return
            end
            local partData = processPart(v)
            if partData then
                table.insert(ringParts, partData)
                Network.BaseParts[partData.part] = true
            end
        end)
        RunService.Heartbeat:Connect(updateRingPositions)
    else
        for i = #ringParts, 1, -1 do
            local data = ringParts[i]
            if data.part and data.part.Parent then
                Network.BaseParts[data.part] = nil
                if data.align then 
                    pcall(function() data.align:Destroy() end)
                end
            end
        end
        ringParts = {}
    end
end

local function ForcePart(v)
    if v:IsA("Part") and not v.Anchored and not v.Parent:FindFirstChild("Humanoid") and not v.Parent:FindFirstChild("Head") and v.Name ~= "Handle" then
        for _, x in next, v:GetChildren() do
            if x:IsA("BodyAngularVelocity") or x:IsA("BodyForce") or x:IsA("BodyGyro") or x:IsA("BodyPosition") or x:IsA("BodyThrust") or x:IsA("BodyVelocity") or x:IsA("RocketPropulsion") then
                x:Destroy()
            end
        end
        if v:FindFirstChild("Attachment") then v:FindFirstChild("Attachment"):Destroy() end
        if v:FindFirstChild("AlignPosition") then v:FindFirstChild("AlignPosition"):Destroy() end
        if v:FindFirstChild("Torque") then v:FindFirstChild("Torque"):Destroy() end
        v.CanCollide = false
        local Torque = Instance.new("Torque", v)
        Torque.Torque = Vector3.new(1000000, 1000000, 1000000)
        local AlignPosition = Instance.new("AlignPosition", v)
        local Attachment2 = Instance.new("Attachment", v)
        Torque.Attachment0 = Attachment2
        AlignPosition.MaxForce = math.huge
        AlignPosition.MaxVelocity = math.huge
        AlignPosition.Responsiveness = 500
        AlignPosition.Attachment0 = Attachment2
        AlignPosition.Attachment1 = Attachment1
        controlledParts[v] = {
            Torque = Torque,
            AlignPosition = AlignPosition,
            Attachment = Attachment2
        }
    end
end

local function releaseAllParts()
    for part, constraints in pairs(controlledParts) do
        if part and part.Parent then
            for _, constraint in pairs(constraints) do
                if constraint and constraint.Parent then
                    constraint:Destroy()
                end
            end
        end
    end
    controlledParts = {}
end

local function togglebh()
    blackHoleActive = not blackHoleActive
    if blackHoleActive then
        humanoidRootPart, Attachment1 = setupPlayer(currentTargetPlayer)
        for _, v in next, Workspace:GetDescendants() do
            ForcePart(v)
        end
        descendantConnection = Workspace.DescendantAdded:Connect(function(v)
            if blackHoleActive then
                ForcePart(v)
            end
        end)
        renderLoop = RunService.RenderStepped:Connect(function()
            if not blackHoleActive then
                if renderLoop then
                    renderLoop:Disconnect()
                    renderLoop = nil
                end
                return
            end
            if humanoidRootPart and humanoidRootPart.Parent then
                angle = angle + math.rad(angleSpeed)
                local offsetX = math.cos(angle) * bhradius
                local offsetZ = math.sin(angle) * bhradius
                Attachment1.WorldCFrame = humanoidRootPart.CFrame * CFrame.new(offsetX, 0, offsetZ)
            else
                humanoidRootPart, Attachment1 = setupPlayer(currentTargetPlayer)
            end
        end)
    else
        if descendantConnection then
            descendantConnection:Disconnect()
            descendantConnection = nil
        end
        if renderLoop then
            renderLoop:Disconnect()
            renderLoop = nil
        end
        releaseAllParts()
        if Attachment1 then
            Attachment1.WorldCFrame = CFrame.new(0, -10000, 0)
        end
        if Folder then
            Folder:Destroy()
            Folder = nil
        end
    end
end

-- GUI Creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PartOrbitBlackHoleGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- Main Frame (Ukuran disesuaikan tanpa space kosong)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -135, 0.5, -100)
MainFrame.Size = UDim2.new(0, 270, 0, 200)
MainFrame.Parent = ScreenGui

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(70, 130, 255)
UIStroke.Thickness = 2
UIStroke.Parent = MainFrame

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Floating Button (Hidden by default)
local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Name = "FloatingBtn"
FloatingBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
FloatingBtn.BorderSizePixel = 0
FloatingBtn.Position = UDim2.new(0, 15, 0.5, -22.5)
FloatingBtn.Size = UDim2.new(0, 41, 0, 41)
FloatingBtn.Font = Enum.Font.GothamBold
FloatingBtn.Text = "☠️"
FloatingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingBtn.TextSize = 20
FloatingBtn.Visible = false
FloatingBtn.Parent = ScreenGui
FloatingBtn.ZIndex = 5

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(0, 12)
FloatCorner.Parent = FloatingBtn

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
TitleBar.BorderSizePixel = 0
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 8, 0, 0)
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "SIEXTHER PART-CONTROLLER"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Minimize Button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Position = UDim2.new(1, -53, 0, 4)
MinimizeBtn.Size = UDim2.new(0, 22, 0, 22)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Text = "–"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 16
MinimizeBtn.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 4)
MinCorner.Parent = MinimizeBtn

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
CloseBtn.BorderSizePixel = 0
CloseBtn.Position = UDim2.new(1, -27, 0, 4)
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 12
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseBtn

-- Tab Buttons Container
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.BackgroundTransparency = 1
TabContainer.Position = UDim2.new(0, 0, 0, 30)
TabContainer.Size = UDim2.new(1, 0, 0, 32)
TabContainer.Parent = MainFrame

local Tab1Btn = Instance.new("TextButton")
Tab1Btn.Name = "Tab1Btn"
Tab1Btn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
Tab1Btn.BorderSizePixel = 0
Tab1Btn.Position = UDim2.new(0, 8, 0, 4)
Tab1Btn.Size = UDim2.new(0.48, -10, 0, 24)
Tab1Btn.Font = Enum.Font.GothamBold
Tab1Btn.Text = "SIEXTHER"
Tab1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
Tab1Btn.TextSize = 12
Tab1Btn.Parent = TabContainer

local Tab1Corner = Instance.new("UICorner")
Tab1Corner.CornerRadius = UDim.new(0, 5)
Tab1Corner.Parent = Tab1Btn

local Tab2Btn = Instance.new("TextButton")
Tab2Btn.Name = "Tab2Btn"
Tab2Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Tab2Btn.BorderSizePixel = 0
Tab2Btn.Position = UDim2.new(0.52, 2, 0, 4)
Tab2Btn.Size = UDim2.new(0.48, -10, 0, 24)
Tab2Btn.Font = Enum.Font.GothamBold
Tab2Btn.Text = "MORBVEIL"
Tab2Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
Tab2Btn.TextSize = 12
Tab2Btn.Parent = TabContainer

local Tab2Corner = Instance.new("UICorner")
Tab2Corner.CornerRadius = UDim.new(0, 5)
Tab2Corner.Parent = Tab2Btn

-- Content Frame
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 8, 0, 66)
ContentFrame.Size = UDim2.new(1, -16, 1, -72)
ContentFrame.Parent = MainFrame

-- PartOrbit Tab Content
local PartOrbitTab = Instance.new("Frame")
PartOrbitTab.Name = "PartOrbitTab"
PartOrbitTab.BackgroundTransparency = 1
PartOrbitTab.Size = UDim2.new(1, 0, 1, 0)
PartOrbitTab.Visible = true
PartOrbitTab.Parent = ContentFrame

-- Toggle Button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Position = UDim2.new(0, 0, 0, 0)
ToggleBtn.Size = UDim2.new(1, 0, 0, 28)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Text = "AKTIFKAN"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 11
ToggleBtn.Parent = PartOrbitTab

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 5)
ToggleCorner.Parent = ToggleBtn

-- Radius Controls
local RadiusLabel = Instance.new("TextLabel")
RadiusLabel.Name = "RadiusLabel"
RadiusLabel.BackgroundTransparency = 1
RadiusLabel.Position = UDim2.new(0, 0, 0, 34)
RadiusLabel.Size = UDim2.new(1, 0, 0, 14)
RadiusLabel.Font = Enum.Font.GothamSemibold
RadiusLabel.Text = "Radius: 50"
RadiusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
RadiusLabel.TextSize = 10
RadiusLabel.TextXAlignment = Enum.TextXAlignment.Left
RadiusLabel.Parent = PartOrbitTab

local RadiusSlider = Instance.new("Frame")
RadiusSlider.Name = "RadiusSlider"
RadiusSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
RadiusSlider.BorderSizePixel = 0
RadiusSlider.Position = UDim2.new(0, 0, 0, 50)
RadiusSlider.Size = UDim2.new(0.68, 0, 0, 18)
RadiusSlider.Parent = PartOrbitTab

local RadSliderCorner = Instance.new("UICorner")
RadSliderCorner.CornerRadius = UDim.new(0, 4)
RadSliderCorner.Parent = RadiusSlider

local RadiusFill = Instance.new("Frame")
RadiusFill.Name = "Fill"
RadiusFill.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
RadiusFill.BorderSizePixel = 0
RadiusFill.Size = UDim2.new(0.5, 0, 1, 0)
RadiusFill.Parent = RadiusSlider

local RadFillCorner = Instance.new("UICorner")
RadFillCorner.CornerRadius = UDim.new(0, 4)
RadFillCorner.Parent = RadiusFill

local RadiusInput = Instance.new("TextBox")
RadiusInput.Name = "RadiusInput"
RadiusInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
RadiusInput.BorderSizePixel = 0
RadiusInput.Position = UDim2.new(0.72, 0, 0, 50)
RadiusInput.Size = UDim2.new(0.28, 0, 0, 18)
RadiusInput.Font = Enum.Font.GothamSemibold
RadiusInput.PlaceholderText = "50"
RadiusInput.Text = "50"
RadiusInput.TextColor3 = Color3.fromRGB(255, 255, 255)
RadiusInput.TextSize = 10
RadiusInput.Parent = PartOrbitTab

local RadInputCorner = Instance.new("UICorner")
RadInputCorner.CornerRadius = UDim.new(0, 4)
RadInputCorner.Parent = RadiusInput

-- Speed Controls
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Name = "SpeedLabel"
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Position = UDim2.new(0, 0, 0, 74)
SpeedLabel.Size = UDim2.new(1, 0, 0, 14)
SpeedLabel.Font = Enum.Font.GothamSemibold
SpeedLabel.Text = "Speed: 2"
SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedLabel.TextSize = 10
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent = PartOrbitTab

local SpeedSlider = Instance.new("Frame")
SpeedSlider.Name = "SpeedSlider"
SpeedSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
SpeedSlider.BorderSizePixel = 0
SpeedSlider.Position = UDim2.new(0, 0, 0, 90)
SpeedSlider.Size = UDim2.new(0.68, 0, 0, 18)
SpeedSlider.Parent = PartOrbitTab

local SpdSliderCorner = Instance.new("UICorner")
SpdSliderCorner.CornerRadius = UDim.new(0, 4)
SpdSliderCorner.Parent = SpeedSlider

local SpeedFill = Instance.new("Frame")
SpeedFill.Name = "Fill"
SpeedFill.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
SpeedFill.BorderSizePixel = 0
SpeedFill.Size = UDim2.new(0.2, 0, 1, 0)
SpeedFill.Parent = SpeedSlider

local SpdFillCorner = Instance.new("UICorner")
SpdFillCorner.CornerRadius = UDim.new(0, 4)
SpdFillCorner.Parent = SpeedFill

local SpeedInput = Instance.new("TextBox")
SpeedInput.Name = "SpeedInput"
SpeedInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
SpeedInput.BorderSizePixel = 0
SpeedInput.Position = UDim2.new(0.72, 0, 0, 90)
SpeedInput.Size = UDim2.new(0.28, 0, 0, 18)
SpeedInput.Font = Enum.Font.GothamSemibold
SpeedInput.PlaceholderText = "2"
SpeedInput.Text = "2"
SpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedInput.TextSize = 10
SpeedInput.Parent = PartOrbitTab

local SpdInputCorner = Instance.new("UICorner")
SpdInputCorner.CornerRadius = UDim.new(0, 4)
SpdInputCorner.Parent = SpeedInput

-- Black Hole Tab Content
local BlackHoleTab = Instance.new("Frame")
BlackHoleTab.Name = "BlackHoleTab"
BlackHoleTab.BackgroundTransparency = 1
BlackHoleTab.Size = UDim2.new(1, 0, 1, 0)
BlackHoleTab.Visible = false
BlackHoleTab.Parent = ContentFrame

-- BH Toggle Button
local BHToggleBtn = Instance.new("TextButton")
BHToggleBtn.Name = "BHToggleBtn"
BHToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
BHToggleBtn.BorderSizePixel = 0
BHToggleBtn.Position = UDim2.new(0, 0, 0, 0)
BHToggleBtn.Size = UDim2.new(1, 0, 0, 28)
BHToggleBtn.Font = Enum.Font.GothamBold
BHToggleBtn.Text = "AKTIFKAN"
BHToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BHToggleBtn.TextSize = 11
BHToggleBtn.Parent = BlackHoleTab

local BHToggleCorner = Instance.new("UICorner")
BHToggleCorner.CornerRadius = UDim.new(0, 5)
BHToggleCorner.Parent = BHToggleBtn

-- BH Radius Controls
local BHRadiusLabel = Instance.new("TextLabel")
BHRadiusLabel.Name = "BHRadiusLabel"
BHRadiusLabel.BackgroundTransparency = 1
BHRadiusLabel.Position = UDim2.new(0, 0, 0, 34)
BHRadiusLabel.Size = UDim2.new(1, 0, 0, 14)
BHRadiusLabel.Font = Enum.Font.GothamSemibold
BHRadiusLabel.Text = "Radius: 8"
BHRadiusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
BHRadiusLabel.TextSize = 10
BHRadiusLabel.TextXAlignment = Enum.TextXAlignment.Left
BHRadiusLabel.Parent = BlackHoleTab

local BHRadiusSlider = Instance.new("Frame")
BHRadiusSlider.Name = "BHRadiusSlider"
BHRadiusSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
BHRadiusSlider.BorderSizePixel = 0
BHRadiusSlider.Position = UDim2.new(0, 0, 0, 50)
BHRadiusSlider.Size = UDim2.new(0.68, 0, 0, 18)
BHRadiusSlider.Parent = BlackHoleTab

local BHRadSliderCorner = Instance.new("UICorner")
BHRadSliderCorner.CornerRadius = UDim.new(0, 4)
BHRadSliderCorner.Parent = BHRadiusSlider

local BHRadiusFill = Instance.new("Frame")
BHRadiusFill.Name = "Fill"
BHRadiusFill.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
BHRadiusFill.BorderSizePixel = 0
BHRadiusFill.Size = UDim2.new(0.08, 0, 1, 0)
BHRadiusFill.Parent = BHRadiusSlider

local BHRadFillCorner = Instance.new("UICorner")
BHRadFillCorner.CornerRadius = UDim.new(0, 4)
BHRadFillCorner.Parent = BHRadiusFill

local BHRadiusInput = Instance.new("TextBox")
BHRadiusInput.Name = "BHRadiusInput"
BHRadiusInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
BHRadiusInput.BorderSizePixel = 0
BHRadiusInput.Position = UDim2.new(0.72, 0, 0, 50)
BHRadiusInput.Size = UDim2.new(0.28, 0, 0, 18)
BHRadiusInput.Font = Enum.Font.GothamSemibold
BHRadiusInput.PlaceholderText = "8"
BHRadiusInput.Text = "8"
BHRadiusInput.TextColor3 = Color3.fromRGB(255, 255, 255)
BHRadiusInput.TextSize = 10
BHRadiusInput.Parent = BlackHoleTab

local BHRadInputCorner = Instance.new("UICorner")
BHRadInputCorner.CornerRadius = UDim.new(0, 4)
BHRadInputCorner.Parent = BHRadiusInput

-- Rotation Speed Controls
local RotSpeedLabel = Instance.new("TextLabel")
RotSpeedLabel.Name = "RotSpeedLabel"
RotSpeedLabel.BackgroundTransparency = 1
RotSpeedLabel.Position = UDim2.new(0, 0, 0, 74)
RotSpeedLabel.Size = UDim2.new(1, 0, 0, 14)
RotSpeedLabel.Font = Enum.Font.GothamSemibold
RotSpeedLabel.Text = "Rotation Speed: 10"
RotSpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
RotSpeedLabel.TextSize = 10
RotSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
RotSpeedLabel.Parent = BlackHoleTab

local RotSpeedSlider = Instance.new("Frame")
RotSpeedSlider.Name = "RotSpeedSlider"
RotSpeedSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
RotSpeedSlider.BorderSizePixel = 0
RotSpeedSlider.Position = UDim2.new(0, 0, 0, 90)
RotSpeedSlider.Size = UDim2.new(0.68, 0, 0, 18)
RotSpeedSlider.Parent = BlackHoleTab

local RotSliderCorner = Instance.new("UICorner")
RotSliderCorner.CornerRadius = UDim.new(0, 4)
RotSliderCorner.Parent = RotSpeedSlider

local RotSpeedFill = Instance.new("Frame")
RotSpeedFill.Name = "Fill"
RotSpeedFill.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
RotSpeedFill.BorderSizePixel = 0
RotSpeedFill.Size = UDim2.new(0.1, 0, 1, 0)
RotSpeedFill.Parent = RotSpeedSlider

local RotFillCorner = Instance.new("UICorner")
RotFillCorner.CornerRadius = UDim.new(0, 4)
RotFillCorner.Parent = RotSpeedFill

local RotSpeedInput = Instance.new("TextBox")
RotSpeedInput.Name = "RotSpeedInput"
RotSpeedInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
RotSpeedInput.BorderSizePixel = 0
RotSpeedInput.Position = UDim2.new(0.72, 0, 0, 90)
RotSpeedInput.Size = UDim2.new(0.28, 0, 0, 18)
RotSpeedInput.Font = Enum.Font.GothamSemibold
RotSpeedInput.PlaceholderText = "10"
RotSpeedInput.Text = "10"
RotSpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
RotSpeedInput.TextSize = 10
RotSpeedInput.Parent = BlackHoleTab

local RotInputCorner = Instance.new("UICorner")
RotInputCorner.CornerRadius = UDim.new(0, 4)
RotInputCorner.Parent = RotSpeedInput

-- Functionality
local minimized = false
local dragging = false
local dragInput, dragStart, startPos

-- Dragging Main Frame
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
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Dragging Floating Button
local floatDragging = false
local floatDragInput, floatDragStart, floatStartPos

FloatingBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        floatDragging = true
        floatDragStart = input.Position
        floatStartPos = FloatingBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                floatDragging = false
            end
        end)
    end
end)

FloatingBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        floatDragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == floatDragInput and floatDragging then
        local delta = input.Position - floatDragStart
        FloatingBtn.Position = UDim2.new(floatStartPos.X.Scale, floatStartPos.X.Offset + delta.X, floatStartPos.Y.Scale, floatStartPos.Y.Offset + delta.Y)
    end
end)

-- Minimize with Floating Button
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame.Visible = false
        FloatingBtn.Visible = true
    else
        FloatingBtn.Visible = false
        MainFrame.Visible = true
    end
end)

-- Floating Button Click to Restore
FloatingBtn.MouseButton1Click:Connect(function()
    minimized = false
    FloatingBtn.Visible = false
    MainFrame.Visible = true
end)

-- Close
CloseBtn.MouseButton1Click:Connect(function()
    if isActive then orbite() end
    if blackHoleActive then togglebh() end
    ScreenGui:Destroy()
end)

-- Tab Switching
Tab1Btn.MouseButton1Click:Connect(function()
    Tab1Btn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    Tab1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tab2Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    Tab2Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    PartOrbitTab.Visible = true
    BlackHoleTab.Visible = false
end)

Tab2Btn.MouseButton1Click:Connect(function()
    Tab2Btn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    Tab2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tab1Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    Tab1Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    BlackHoleTab.Visible = true
    PartOrbitTab.Visible = false
end)

-- PartOrbit Toggle
ToggleBtn.MouseButton1Click:Connect(function()
    orbite()
    ToggleBtn.Text = isActive and "SIEXTHER : AKTIF" or "SIEXTHER : OFF"
    ToggleBtn.BackgroundColor3 = isActive and Color3.fromRGB(70, 130, 255) or Color3.fromRGB(40, 40, 45)
end)

-- Radius Slider
local radiusDragging = false
RadiusSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        radiusDragging = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        radiusDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if radiusDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = input.Position.X
        local sliderPos = RadiusSlider.AbsolutePosition.X
        local sliderSize = RadiusSlider.AbsoluteSize.X
        local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
        radius = math.floor(percent * 100)
        RadiusFill.Size = UDim2.new(percent, 0, 1, 0)
        RadiusLabel.Text = "Radius: " .. radius
        RadiusInput.Text = tostring(radius)
    end
end)

RadiusInput.FocusLost:Connect(function()
    local val = tonumber(RadiusInput.Text)
    if val and val >= 0 and val <= 100 then
        radius = val
        RadiusFill.Size = UDim2.new(val / 100, 0, 1, 0)
        RadiusLabel.Text = "Radius: " .. radius
    else
        RadiusInput.Text = tostring(radius)
    end
end)

-- Speed Slider
local speedDragging = false
SpeedSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        speedDragging = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        speedDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if speedDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = input.Position.X
        local sliderPos = SpeedSlider.AbsolutePosition.X
        local sliderSize = SpeedSlider.AbsoluteSize.X
        local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
        speed = math.floor(percent * 10)
        SpeedFill.Size = UDim2.new(percent, 0, 1, 0)
        SpeedLabel.Text = "Speed: " .. speed
        SpeedInput.Text = tostring(speed)
    end
end)

SpeedInput.FocusLost:Connect(function()
    local val = tonumber(SpeedInput.Text)
    if val and val >= 0 and val <= 10 then
        speed = val
        SpeedFill.Size = UDim2.new(val / 10, 0, 1, 0)
        SpeedLabel.Text = "Speed: " .. speed
    else
        SpeedInput.Text = tostring(speed)
    end
end)

-- Black Hole Toggle
BHToggleBtn.MouseButton1Click:Connect(function()
    togglebh()
    BHToggleBtn.Text = blackHoleActive and "MORBVEIL : AKTIF" or "MORBVEIL : OFF"
    BHToggleBtn.BackgroundColor3 = blackHoleActive and Color3.fromRGB(70, 130, 255) or Color3.fromRGB(40, 40, 45)
end)

-- BH Radius Slider
local bhRadiusDragging = false
BHRadiusSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        bhRadiusDragging = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        bhRadiusDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if bhRadiusDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = input.Position.X
        local sliderPos = BHRadiusSlider.AbsolutePosition.X
        local sliderSize = BHRadiusSlider.AbsoluteSize.X
        local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
        bhradius = math.floor(percent * 100)
        BHRadiusFill.Size = UDim2.new(percent, 0, 1, 0)
        BHRadiusLabel.Text = "Radius: " .. bhradius
        BHRadiusInput.Text = tostring(bhradius)
    end
end)

BHRadiusInput.FocusLost:Connect(function()
    local val = tonumber(BHRadiusInput.Text)
    if val and val >= 0 and val <= 100 then
        bhradius = val
        BHRadiusFill.Size = UDim2.new(val / 100, 0, 1, 0)
        BHRadiusLabel.Text = "Radius: " .. bhradius
    else
        BHRadiusInput.Text = tostring(bhradius)
    end
end)

-- Rotation Speed Slider
local rotSpeedDragging = false
RotSpeedSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        rotSpeedDragging = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        rotSpeedDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if rotSpeedDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = input.Position.X
        local sliderPos = RotSpeedSlider.AbsolutePosition.X
        local sliderSize = RotSpeedSlider.AbsoluteSize.X
        local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
        angleSpeed = math.floor(percent * 100)
        RotSpeedFill.Size = UDim2.new(percent, 0, 1, 0)
        RotSpeedLabel.Text = "Rotation Speed: " .. angleSpeed
        RotSpeedInput.Text = tostring(angleSpeed)
    end
end)

RotSpeedInput.FocusLost:Connect(function()
    local val = tonumber(RotSpeedInput.Text)
    if val and val >= 0 and val <= 100 then
        angleSpeed = val
        RotSpeedFill.Size = UDim2.new(val / 100, 0, 1, 0)
        RotSpeedLabel.Text = "Rotation Speed: " .. angleSpeed
    else
        RotSpeedInput.Text = tostring(angleSpeed)
    end
end)

-- Character respawn handler
LocalPlayer.CharacterAdded:Connect(function(character)
    wait(1)
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    if currentTargetPlayer == LocalPlayer then
        humanoidRootPart, Attachment1 = setupPlayer(LocalPlayer)
        if blackHoleActive then
            togglebh()
            wait(0.1)
            togglebh()
        end
    end
end)