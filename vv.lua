local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

-- External notification system
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/han.lua"))()
end)

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function notify(title, content, duration)
    pcall(function()
        local notifier = (getgenv and getgenv().Notify) or Notify
        if type(notifier) == "function" then
            notifier({
                Title = title,
                Content = content,
                Duration = duration or 3
            })
        end
    end)
end

--==================================================
-- COLORS
--==================================================

local COLORS = {
    Background = Color3.fromRGB(18, 18, 22),
    Surface = Color3.fromRGB(25, 25, 30),
    Surface2 = Color3.fromRGB(30, 30, 35),
    Hover = Color3.fromRGB(40, 40, 45),

    Primary = Color3.fromRGB(70, 130, 255),
    PrimaryHover = Color3.fromRGB(90, 150, 255),

    White = Color3.fromRGB(255, 255, 255),
    Gray = Color3.fromRGB(120, 120, 120),
    LightGray = Color3.fromRGB(180, 180, 180),

    Success = Color3.fromRGB(0, 255, 100),
    Warning = Color3.fromRGB(255, 200, 0),
    Error = Color3.fromRGB(255, 80, 80),
    Danger = Color3.fromRGB(255, 60, 70),

    OnFill = Color3.fromRGB(40, 123, 75),
    On = Color3.fromRGB(255, 255, 255),
    Faint = Color3.fromRGB(120, 120, 140),
    Active = Color3.fromRGB(31, 76, 164),
}

--==================================================
-- STATE
--==================================================

local State = {
    Open = false,
    SelectedPlayer = nil,
    Destroyed = false,
    SearchQuery = "",
    rig = "R15",
}

--==================================================
-- HELPERS
--==================================================

local function makeCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = object
    return corner
end

local function makeStroke(object, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness or 1
    stroke.Parent = object
    return stroke
end

local function makeDraggable(frame)
    local dragging = false
    local dragInput
    local dragStart
    local startPosition

    local function update(input)
        if not dragging then return end
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

local function createButton(parent, name, text, position, size, color)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = color or COLORS.Primary
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = COLORS.White
    button.Font = Enum.Font.GothamBold
    button.TextSize = 10
    button.AutoButtonColor = false
    button.Parent = parent
    makeCorner(button, 6)

    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {
            BackgroundColor3 = COLORS.PrimaryHover
        }):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {
            BackgroundColor3 = color or COLORS.Primary
        }):Play()
    end)
    return button
end

--==================================================
-- AVATAR CHANGER LOGIC (from avatar_changer.txt)
--==================================================

local tbl2 = {
    idle = "IdleAnimation",
    walk = "WalkAnimation",
    run = "RunAnimation",
    jump = "JumpAnimation",
    fall = "FallAnimation",
    climb = "ClimbAnimation",
    swim = "SwimAnimation",
}

local tbl8 = {}
local function fn10(arg)
    local str2 = tostring(arg)
    if tbl8[str2] ~= nil then
        return tbl8[str2] or nil
    end
    local ok, result = pcall(game.GetObjects, game, "rbxassetid://" .. str2)
    if not (ok and type(result) == "table") then
        tbl8[str2] = false
        return nil
    end
    for _, v2 in ipairs(result) do
        v2.Parent = nil
    end
    tbl8[str2] = result
    return result
end

local function fn11(arg)
    local n3 = 0
    for _, v2 in pairs(tbl2) do
        local v3 = arg[v2]
        if type(v3) == "number" and v3 > 0 and tbl8[tostring(v3)] == nil then
            n3 += 1
            task.spawn(function()
                fn10(v3)
                n3 -= 1
            end)
        end
    end
    local now = os.clock()
    while n3 > 0 and os.clock() - now < 15 do
        task.wait(0.05)
    end
end

local function fn12(arg)
    local tbl9 = {}
    fn11(arg)
    for k, v2 in pairs(tbl2) do
        local v3 = arg[v2]
        if type(v3) == "number" and v3 > 0 then
            local v4 = fn10(v3)
            for _, v6 in ipairs(v4 or {}) do
                for _, descendant in ipairs(v6:GetDescendants()) do
                    if descendant:IsA("Animation") and descendant.Parent and descendant.Parent ~= v6 then
                        local name = descendant.Parent.Name
                        tbl9[name] = tbl9[name] or {}
                        table.insert(tbl9[name], descendant)
                    elseif descendant:IsA("Animation") then
                        tbl9[k] = tbl9[k] or {}
                        table.insert(tbl9[k], descendant)
                    end
                end
            end
        end
    end
    return tbl9
end

-- HumanoidDescription fetching with cache
local tbl7 = {}
local function fn9(arg)
    if tbl7[arg] then return tbl7[arg] end
    local playerByUserId = Players:GetPlayerByUserId(arg)
    local humanoid = playerByUserId and playerByUserId.Character and playerByUserId.Character:FindFirstChildOfClass("Humanoid")
    local v2 = nil
    if humanoid then
        local ok, result = pcall(humanoid.GetAppliedDescription, humanoid)
        if ok and result then v2 = result end
    end
    if not v2 then
        local ok, result = pcall(Players.GetHumanoidDescriptionFromUserId, Players, arg)
        if ok and result then v2 = result end
    end
    if v2 then tbl7[arg] = v2 end
    return v2
end

-- Create model from userId + description
local function fn6(arg, arg2, arg3)
    local ok, result
    if arg3 == "R6" then
        if not arg2 then return nil end
        ok, result = pcall(Players.CreateHumanoidModelFromDescription, Players, arg2, Enum.HumanoidRigType.R6)
    else
        ok, result = pcall(Players.CreateHumanoidModelFromUserId, Players, arg)
        local humanoid = ok and result and result:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.RigType ~= Enum.HumanoidRigType.R15 and arg2 then
            result:Destroy()
            ok, result = pcall(Players.CreateHumanoidModelFromDescription, Players, arg2, Enum.HumanoidRigType.R15)
        end
    end
    if not (ok and result) then return nil end
    result.Parent = nil
    return result
end

-- Animate helpers
local obj = setmetatable({}, { __mode = "k" })

local function fn14(arg)
    if obj[arg] then return obj[arg] end
    local tbl9 = { anim = {} }
    local humanoid = arg:FindFirstChildOfClass("Humanoid")
    if humanoid then tbl9.hipHeight = humanoid.HipHeight end
    local animate = arg:FindFirstChild("Animate")
    if animate then
        for k in pairs(tbl2) do
            local v2 = animate:FindFirstChild(k)
            if v2 then
                tbl9.anim[k] = {}
                for _, child in ipairs(v2:GetChildren()) do
                    if child:IsA("Animation") then
                        local clone = child:Clone()
                        clone.Parent = nil
                        table.insert(tbl9.anim[k], clone)
                    end
                end
            end
        end
    end
    obj[arg] = tbl9
    return tbl9
end

local function fn15(arg, arg2)
    local humanoid = arg:FindFirstChildOfClass("Humanoid")
    if humanoid and arg2.hipHeight then
        pcall(function() humanoid.HipHeight = arg2.hipHeight end)
    end
end

local function fn16(arg)
    local animate = arg:FindFirstChild("Animate")
    local humanoid = arg:FindFirstChildOfClass("Humanoid")
    if not (animate and humanoid) then return end
    for _, v2 in ipairs(humanoid:GetPlayingAnimationTracks()) do
        if v2.Priority ~= Enum.AnimationPriority.Action then
            pcall(v2.Stop, v2, 0)
        end
    end
    animate.Disabled = true
    animate.Disabled = false
end

local function fn17(arg, arg2)
    local animate = arg:FindFirstChild("Animate")
    if not animate then return 0 end
    local n3 = 0
    for k, v2 in pairs(arg2) do
        local v3 = animate:FindFirstChild(k)
        if v3 and #v2 > 0 then
            for _, child in ipairs(v3:GetChildren()) do
                if child:IsA("Animation") then child:Destroy() end
            end
            for _, v4 in ipairs(v2) do
                v4:Clone().Parent = v3
                n3 += 1
            end
        end
    end
    if n3 > 0 then fn16(arg) end
    return n3
end

local function fn18(arg, arg2)
    local animate = arg:FindFirstChild("Animate")
    if not (animate and arg2 and arg2.anim) then return end
    local flag = false
    for k, v2 in pairs(arg2.anim) do
        local v3 = animate:FindFirstChild(k)
        if v3 then
            for _, child in ipairs(v3:GetChildren()) do
                if child:IsA("Animation") then child:Destroy() end
            end
            for _, v4 in ipairs(v2) do
                v4:Clone().Parent = v3
            end
            flag = true
        end
    end
    if flag then fn16(arg) end
end

-- Overlay model system
local tbl11 = { p0="HumanoidRootPart", p1="Torso", m0="HumanoidRootPart", m1="UpperTorso", r15={"Root","Waist"}, c0=CFrame.new(0,0,0,-1,0,0,0,0,1,0,1,0), c1=CFrame.new(0,0,0,-1,0,0,0,0,1,0,1,0) }
local tbl12 = { p0="Torso", p1="Head", m0="UpperTorso", m1="Head", r15={"Neck"}, c0=CFrame.new(0,1,0,-1,0,0,0,0,1,0,1,0), c1=CFrame.new(0,-0.5,0,-1,0,0,0,0,1,0,1,0) }
local tbl13 = { p0="Torso", p1="Right Arm", m0="UpperTorso", m1="RightUpperArm", r15={"RightShoulder"}, c0=CFrame.new(1,0.5,0,0,0,1,0,1,0,-1,0,0), c1=CFrame.new(-0.5,0.5,0,0,0,1,0,1,0,-1,0,0) }
local tbl14 = { p0="Torso", p1="Left Arm", m0="UpperTorso", m1="LeftUpperArm", r15={"LeftShoulder"}, c0=CFrame.new(-1,0.5,0,0,0,-1,0,1,0,1,0,0), c1=CFrame.new(0.5,0.5,0,0,0,-1,0,1,0,1,0,0) }
local tbl15 = { p0="Torso", p1="Right Leg", m0="UpperTorso", m1="RightUpperLeg", r15={"RightHip"}, c0=CFrame.new(1,-1,0,0,0,1,0,1,0,-1,0,0), c1=CFrame.new(0.5,1,0,0,0,1,0,1,0,-1,0,0) }
local tbl16 = { p0="Torso", p1="Left Leg", m0="UpperTorso", m1="LeftUpperLeg", r15={"LeftHip"}, c0=CFrame.new(-1,-1,0,0,0,-1,0,1,0,1,0,0), c1=CFrame.new(-0.5,1,0,0,0,-1,0,1,0,1,0,0) }
local jointDefs = { tbl11, tbl12, tbl13, tbl14, tbl15, tbl16 }

local tbl17 = { modelo=nil, char=nil, cadena={}, conn=nil, connFisica=nil }

local function fn23(arg)
    local tbl18 = {}
    for _, descendant in ipairs(arg:GetDescendants()) do
        if (descendant:IsA("Motor6D") or descendant:IsA("AnimationConstraint")) and not tbl18[descendant.Name] then
            tbl18[descendant.Name] = descendant
        end
    end
    return tbl18
end

local function fn24(arg)
    if arg:IsA("Motor6D") then return arg.C0.Rotation, arg.C1.Rotation end
    local a0 = arg.Attachment0
    local a1 = arg.Attachment1
    return a0 and a0.CFrame.Rotation or CFrame.identity, a1 and a1.CFrame.Rotation or CFrame.identity
end

local function fn25(arg, arg2, arg3, arg4, arg5)
    local cframe = CFrame.identity
    local cframe2 = CFrame.identity
    if #arg5 > 0 then
        local v2 = fn24(arg5[1])
        local v3, v4 = fn24(arg5[#arg5])
        cframe = arg3.Rotation:Inverse() * v2
        cframe2 = v4:Inverse() * arg4.Rotation
    end
    return { desde=arg, hacia=arg2, c0=arg3, c1=arg4, srcs=arg5, a=cframe, b=cframe2 }
end

local function fn26(arg, arg2, arg3, arg4)
    local v2 = fn23(arg)
    local tbl18 = {}
    local tbl19 = {}
    for _, child in ipairs(arg2:GetChildren()) do
        if child:IsA("BasePart") then table.insert(tbl19, child) end
    end
    if arg4 == "R6" then
        for _, v3 in ipairs(jointDefs) do
            local v4 = arg2:FindFirstChild(v3.p0)
            local v5 = arg2:FindFirstChild(v3.p1)
            if v4 and v5 then
                local tbl20 = {}
                for _, v6 in ipairs(v3.r15) do
                    if v2[v6] then table.insert(tbl20, v2[v6]) end
                end
                local v6 = fn25(v4, v5, v3.c0, v3.c1, tbl20)
                v6.m0 = arg:FindFirstChild(v3.m0)
                v6.m1 = arg:FindFirstChild(v3.m1)
                table.insert(tbl18, v6)
            end
        end
    else
        local tbl20 = { [arg3]=true }
        local tbl21 = { arg3 }
        while #tbl21 > 0 do
            local v3 = table.remove(tbl21, 1)
            for _, child in ipairs(v3:GetChildren()) do
                if child:IsA("Attachment") and child.Name:match("RigAttachment$") then
                    for _, v4 in ipairs(tbl19) do
                        if not tbl20[v4] then
                            local v5 = v4:FindFirstChild(child.Name)
                            if v5 and v5:IsA("Attachment") then
                                tbl20[v4] = true
                                local v6 = v2[child.Name:gsub("RigAttachment$","")]
                                table.insert(tbl18, fn25(v3, v4, child.CFrame, v5.CFrame, v6 and {v6} or {}))
                                table.insert(tbl21, v4)
                            end
                        end
                    end
                end
            end
        end
    end
    for _, child in ipairs(arg2:GetChildren()) do
        if child:IsA("Accessory") then
            local handle = child:FindFirstChild("Handle")
            local attachment = handle and handle:FindFirstChildOfClass("Attachment")
            if attachment then
                for _, v3 in ipairs(tbl19) do
                    local v4 = v3:FindFirstChild(attachment.Name)
                    if v4 and v4:IsA("Attachment") then
                        table.insert(tbl18, fn25(v3, handle, v4.CFrame, attachment.CFrame, {}))
                        break
                    end
                end
            end
        end
    end
    return tbl18
end

local function fn27()
    local currentCamera = workspace.CurrentCamera
    if not currentCamera then return nil end
    local rysCapa = currentCamera:FindFirstChild("SiextherCapa")
    if not rysCapa then
        local folder = Instance.new("Folder")
        folder.Name = "SiextherCapa"
        folder.Parent = currentCamera
        rysCapa = folder
    end
    return rysCapa
end

local function fn28(arg, arg2)
    for _, descendant in ipairs(arg:GetDescendants()) do
        if (descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" or descendant:IsA("Decal")) and not descendant:FindFirstAncestorOfClass("Tool") then
            if arg2 then
                if descendant:GetAttribute("SiextherTransp") == nil then
                    descendant:SetAttribute("SiextherTransp", descendant.Transparency)
                end
                if descendant.Transparency < 1 then
                    descendant.Transparency = 1
                end
            else
                local attribute = descendant:GetAttribute("SiextherTransp")
                if attribute ~= nil then
                    descendant.Transparency = attribute
                    descendant:SetAttribute("SiextherTransp", nil)
                end
            end
        end
    end
end

local function fn29()
    if tbl17.conn then tbl17.conn:Disconnect(); tbl17.conn = nil end
    if tbl17.connFisica then tbl17.connFisica:Disconnect(); tbl17.connFisica = nil end
    if tbl17.modelo then tbl17.modelo:Destroy(); tbl17.modelo = nil end
    tbl17.cadena = {}
    if tbl17.char then
        fn28(tbl17.char, false)
        tbl17.char = nil
    end
end

local function fn30(arg, arg2)
    local y = arg2.Position.Y
    for _, child in ipairs(arg:GetChildren()) do
        if child:IsA("BasePart") and child ~= arg2 then
            y = math.min(y, child.Position.Y - child.Size.Y / 2)
        end
    end
    return arg2.Position.Y - y
end

local function fn31(arg, arg2, arg3, arg4)
    arg2.CFrame = arg.CFrame * arg4
    for _, v2 in ipairs(arg3) do
        if v2.m0 and v2.m1 then
            local rotation = v2.m1.CFrame.Rotation
            local n3 = v2.m0.CFrame.Rotation:Inverse() * rotation
            v2.hacia.CFrame = v2.desde.CFrame * v2.c0 * v2.c0.Rotation:Inverse() * n3 * v2.c1.Rotation * v2.c1:Inverse()
        else
            local a = v2.a
            for _, src in ipairs(v2.srcs) do a *= src.Transform end
            v2.hacia.CFrame = v2.desde.CFrame * v2.c0 * a * v2.b * v2.c1:Inverse()
        end
    end
end

-- R15 overlay
local function applyR15Overlay(char, modelo)
    local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
    local humanoidRootPart2 = modelo:FindFirstChild("HumanoidRootPart")
    local v2 = fn27()
    if not (humanoidRootPart and humanoidRootPart2 and v2) then modelo:Destroy(); return false end
    local humanoid = modelo:FindFirstChildOfClass("Humanoid")
    local cframe = CFrame.new(0, (humanoid and humanoid.HipHeight > 0 and humanoid.HipHeight + humanoidRootPart2.Size.Y / 2 or fn30(modelo, humanoidRootPart2)) - fn30(char, humanoidRootPart), 0)
    local tbl18 = {}
    local function fn33(arg)
        arg.Anchored = arg == humanoidRootPart2
        arg.CanCollide = false
        arg.CanTouch = false
        arg.CanQuery = false
        arg.Massless = true
        table.insert(tbl18, arg)
    end
    for _, descendant in ipairs(modelo:GetDescendants()) do
        if descendant:IsA("BaseScript") then
            descendant.Disabled = true
        elseif descendant:IsA("BasePart") then
            fn33(descendant)
        end
    end
    if humanoid then
        humanoid.PlatformStand = true
        humanoid.AutoRotate = false
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        pcall(function() humanoid.EvaluateStateMachine = false end)
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then animator:Destroy() end
    end
    modelo.Name = "SiextherCapa_R15"
    modelo.PrimaryPart = humanoidRootPart2
    modelo:PivotTo(humanoidRootPart.CFrame * cframe)
    modelo.Parent = v2
    local now = os.clock()
    while os.clock() - now < 1.5 and not modelo:FindFirstChildWhichIsA("AnimationConstraint", true) and not modelo:FindFirstChildWhichIsA("Motor6D", true) do
        task.wait()
    end
    local v3 = fn23(char)
    local cadena = {}
    local function fn34(arg)
        if arg:IsA("BallSocketConstraint") then
            arg.Enabled = false
        elseif arg:IsA("AnimationConstraint") or arg:IsA("Motor6D") then
            pcall(function() arg.IsKinematic = true end)
            local v4 = v3[arg.Name]
            if v4 then table.insert(cadena, { src=v4, tgt=arg }) end
        end
    end
    for _, descendant in ipairs(modelo:GetDescendants()) do fn34(descendant) end
    modelo.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then fn33(descendant)
        else fn34(descendant) end
    end)
    tbl17.modelo = modelo
    tbl17.char = char
    tbl17.cadena = cadena
    fn28(char, true)
    local function fn35()
        humanoidRootPart2.CFrame = humanoidRootPart.CFrame * cframe
        for _, v6 in ipairs(cadena) do
            v6.tgt.Transform = v6.src.Transform
        end
    end
    tbl17.connFisica = RunService.Stepped:Connect(function()
        if tbl17.modelo ~= modelo then return end
        for _, v6 in ipairs(tbl18) do
            if v6.CanCollide then v6.CanCollide = false end
            if v6.CanTouch then v6.CanTouch = false end
        end
        fn35()
    end)
    local n3 = 0
    tbl17.conn = RunService.RenderStepped:Connect(function(deltaTime)
        if tbl17.modelo ~= modelo then return end
        fn35()
        n3 += deltaTime
        if n3 > 0.5 then
            n3 = 0
            fn28(char, true)
        end
    end)
    return true
end

-- R6 overlay
local function applyR6Overlay(char, modelo)
    local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
    local humanoidRootPart2 = modelo:FindFirstChild("HumanoidRootPart")
    local v2 = fn27()
    if not (humanoidRootPart and humanoidRootPart2 and v2) then modelo:Destroy(); return false end
    local humanoid2 = modelo:FindFirstChildOfClass("Humanoid")
    local flag = fn30(modelo, humanoidRootPart2)
    local n3 = flag or ((humanoid2 and humanoid2.HipHeight or 2) + humanoidRootPart2.Size.Y / 2)
    local cframe = CFrame.new(0, n3 - fn30(char, humanoidRootPart), 0)
    local tbl18 = {}
    for _, descendant in ipairs(modelo:GetDescendants()) do
        if descendant:IsA("BaseScript") then
            descendant.Disabled = true
        elseif descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
            descendant.Massless = true
            table.insert(tbl18, descendant)
        elseif descendant:IsA("JointInstance") or descendant:IsA("Constraint") then
            descendant:Destroy()
        end
    end
    if humanoid2 then
        humanoid2.PlatformStand = true
        humanoid2.AutoRotate = false
        humanoid2.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        pcall(function() humanoid2.EvaluateStateMachine = false end)
        local animator = humanoid2:FindFirstChildOfClass("Animator")
        if animator then animator:Destroy() end
    end
    modelo.Name = "SiextherCapa_R6"
    modelo.PrimaryPart = humanoidRootPart2
    local v3 = fn26(char, modelo, humanoidRootPart2, "R6")
    fn31(humanoidRootPart, humanoidRootPart2, v3, cframe)
    modelo.Parent = v2
    for _, descendant in ipairs(modelo:GetDescendants()) do
        if descendant:IsA("Constraint") or descendant:IsA("JointInstance") then
            descendant:Destroy()
        end
    end
    modelo.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("Constraint") or descendant:IsA("JointInstance") then
            task.defer(function() descendant:Destroy() end)
        elseif descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
            descendant.Massless = true
            table.insert(tbl18, descendant)
        end
    end)
    tbl17.modelo = modelo
    tbl17.char = char
    tbl17.cadena = v3
    fn28(char, true)
    tbl17.connFisica = RunService.Stepped:Connect(function()
        for _, v6 in ipairs(tbl18) do
            if v6.CanCollide then v6.CanCollide = false end
            if v6.CanTouch then v6.CanTouch = false end
        end
    end)
    local n4 = 0
    tbl17.conn = RunService.RenderStepped:Connect(function(deltaTime)
        if tbl17.modelo ~= modelo then return end
        fn31(humanoidRootPart, humanoidRootPart2, v3, cframe)
        n4 += deltaTime
        if n4 > 0.5 then
            n4 = 0
            fn28(char, true)
        end
    end)
    return true
end

-- Main overlay dispatcher
local function applyOverlay(char, modelo)
    fn29()
    local humanoid = modelo:FindFirstChildOfClass("Humanoid")
    local rigType = humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 and "R6" or "R15"
    if rigType == "R6" then
        return applyR6Overlay(char, modelo)
    else
        return applyR15Overlay(char, modelo)
    end
end

-- Restore original character appearance
local function restoreChar(arg)
    if not arg then return end
    fn29()
    local v2 = obj[arg]
    if not v2 then return end
    fn15(arg, v2)
    fn18(arg, v2)
end

-- Get local character (returns nil if invisible/special)
local function getMyChar()
    local character = LocalPlayer.Character
    if not character then return nil end
    if character.Name:find("d55076dde45f5d1c5267", 1, true) then return nil end
    return character
end

-- Apply avatar from userId with overlay (main copy logic)
local function applyAvatarOverlay(userId)
    local char = getMyChar()
    if not char then
        return false
    end

    local desc = fn9(userId)
    if desc then fn11(desc) end

    local modelo = fn6(userId, desc, State.rig)
    if not modelo then
        return false
    end

    if getMyChar() ~= char then
        modelo:Destroy()
        return false
    end

    local animCount = 0
    if desc then animCount = fn17(char, fn12(desc)) end

    local ok = applyOverlay(char, modelo)
    if not ok then
        return false
    end

    local pieces = #tbl17.cadena + 1 + animCount
    return true
end

-- Copy avatar from selected player
local function copyAvatar(player)
    if not player then return false, "Pilih pemain terlebih dahulu." end
    if player == LocalPlayer then return false, "Tidak dapat menyalin avatar sendiri." end
    if not player.Parent then return false, "Pemain sudah keluar." end

    local success = applyAvatarOverlay(player.UserId)
    if success then
        return true, "Avatar copied from " .. player.Name
    else
        return false, "Gagal menyalin avatar."
    end
end

-- Reset / remove overlay
local function resetAvatar()
    fn29()
    local char = getMyChar()
    if char then
        restoreChar(char)
    end
    return true, "Avatar reset."
end

-- Teleport
local function teleportToPlayer(player)
    if not player then return false, "Pilih pemain terlebih dahulu." end
    if player == LocalPlayer then return false, "Kamu sudah berada di pemain sendiri." end
    local targetCharacter = player.Character
    local myCharacter = LocalPlayer.Character
    if not targetCharacter or not myCharacter then return false, "Character tidak ditemukan." end
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return false, "HumanoidRootPart target tidak ditemukan." end
    local success, err = pcall(function()
        myCharacter:PivotTo(targetRoot.CFrame + Vector3.new(0, 3, 0))
    end)
    if not success then return false, "Teleport gagal: " .. tostring(err) end
    return true, "Teleported to " .. player.Name
end

--==================================================
-- PLAYER LIST HELPER
--==================================================

local function getPlayers()
    local result = {}
    local query = State.SearchQuery:lower()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if query == "" or player.Name:lower():find(query, 1, true) or player.DisplayName:lower():find(query, 1, true) then
                table.insert(result, player)
            end
        end
    end
    table.sort(result, function(a, b) return a.Name:lower() < b.Name:lower() end)
    return result
end

--==================================================
-- GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SiextherAvatar"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- TOGGLE / FLOATING BUTTON
--==================================================

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 38, 0, 38)
ToggleButton.Position = UDim2.new(0, 12, 0.5, -19)
ToggleButton.BackgroundColor3 = COLORS.Surface
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "🎮"
ToggleButton.TextColor3 = COLORS.White
ToggleButton.TextScaled = true
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.AutoButtonColor = false
ToggleButton.ZIndex = 20
ToggleButton.Visible = true
ToggleButton.Parent = ScreenGui
makeCorner(ToggleButton, 10)
makeStroke(ToggleButton, COLORS.Primary, 1)
makeDraggable(ToggleButton)

--==================================================
-- MAIN FRAME (taller for R15/R6 row)
--==================================================

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 270, 0, 302)
MainFrame.Position = UDim2.new(0.5, -135, 0.5, -151)
MainFrame.BackgroundColor3 = COLORS.Background
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
makeCorner(MainFrame, 10)
makeStroke(MainFrame, COLORS.Primary, 2)
makeDraggable(MainFrame)

--==================================================
-- TITLE BAR
--==================================================

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = COLORS.Surface
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
makeCorner(TitleBar, 10)

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -88, 1, 0)
TitleText.Position = UDim2.new(0, 10, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "SIEXTHER AVATAR"
TitleText.TextColor3 = COLORS.Primary
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 13
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 24, 0, 24)
MinimizeButton.Position = UDim2.new(1, -55, 0, 4)
MinimizeButton.BackgroundColor3 = COLORS.Surface2
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Text = "–"
MinimizeButton.TextColor3 = COLORS.White
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 16
MinimizeButton.AutoButtonColor = false
MinimizeButton.Parent = TitleBar
makeCorner(MinimizeButton, 6)

MinimizeButton.MouseEnter:Connect(function()
    TweenService:Create(MinimizeButton, TweenInfo.new(0.15), { BackgroundColor3 = COLORS.Hover }):Play()
end)
MinimizeButton.MouseLeave:Connect(function()
    TweenService:Create(MinimizeButton, TweenInfo.new(0.15), { BackgroundColor3 = COLORS.Surface2 }):Play()
end)

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 24, 0, 24)
CloseButton.Position = UDim2.new(1, -28, 0, 4)
CloseButton.BackgroundColor3 = COLORS.Danger
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = COLORS.White
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 12
CloseButton.AutoButtonColor = false
CloseButton.Parent = TitleBar
makeCorner(CloseButton, 6)

--==================================================
-- SELECT LABEL
--==================================================

local SelectLabel = Instance.new("TextLabel")
SelectLabel.Size = UDim2.new(1, -20, 0, 18)
SelectLabel.Position = UDim2.new(0, 10, 0, 39)
SelectLabel.BackgroundTransparency = 1
SelectLabel.Text = "SELECT PLAYER"
SelectLabel.TextColor3 = COLORS.Primary
SelectLabel.Font = Enum.Font.GothamBold
SelectLabel.TextSize = 10
SelectLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectLabel.Parent = MainFrame

--==================================================
-- SEARCH BAR
--==================================================

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -20, 0, 24)
SearchBox.Position = UDim2.new(0, 10, 0, 57)
SearchBox.BackgroundColor3 = COLORS.Surface
SearchBox.BorderSizePixel = 0
SearchBox.Text = ""
SearchBox.PlaceholderText = "Search player..."
SearchBox.PlaceholderColor3 = COLORS.Gray
SearchBox.TextColor3 = COLORS.White
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 9
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = MainFrame
makeCorner(SearchBox, 6)
makeStroke(SearchBox, COLORS.Surface2, 1)
local SearchPadding = Instance.new("UIPadding")
SearchPadding.PaddingLeft = UDim.new(0, 8)
SearchPadding.PaddingRight = UDim.new(0, 8)
SearchPadding.Parent = SearchBox

--==================================================
-- PLAYER LIST
--==================================================

local PlayerScrollFrame = Instance.new("ScrollingFrame")
PlayerScrollFrame.Size = UDim2.new(1, -20, 0, 103)
PlayerScrollFrame.Position = UDim2.new(0, 10, 0, 85)
PlayerScrollFrame.BackgroundColor3 = COLORS.Surface
PlayerScrollFrame.BorderSizePixel = 0
PlayerScrollFrame.ScrollBarThickness = 3
PlayerScrollFrame.ScrollBarImageColor3 = COLORS.Primary
PlayerScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerScrollFrame.Parent = MainFrame
makeCorner(PlayerScrollFrame, 7)

local PlayerLayout = Instance.new("UIListLayout")
PlayerLayout.SortOrder = Enum.SortOrder.Name
PlayerLayout.Padding = UDim.new(0, 3)
PlayerLayout.Parent = PlayerScrollFrame

local PlayerPadding = Instance.new("UIPadding")
PlayerPadding.PaddingTop = UDim.new(0, 3)
PlayerPadding.PaddingBottom = UDim.new(0, 3)
PlayerPadding.PaddingLeft = UDim.new(0, 3)
PlayerPadding.PaddingRight = UDim.new(0, 3)
PlayerPadding.Parent = PlayerScrollFrame

--==================================================
-- SELECTED LABEL
--==================================================

local SelectedLabel = Instance.new("TextLabel")
SelectedLabel.Size = UDim2.new(1, -20, 0, 18)
SelectedLabel.Position = UDim2.new(0, 10, 0, 191)
SelectedLabel.BackgroundTransparency = 1
SelectedLabel.Text = "Selected: None"
SelectedLabel.TextColor3 = COLORS.Primary
SelectedLabel.Font = Enum.Font.GothamBold
SelectedLabel.TextSize = 10
SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectedLabel.TextTruncate = Enum.TextTruncate.AtEnd
SelectedLabel.Parent = MainFrame

--==================================================
-- RIG BUTTONS (R15 / R6) - row sebelum action
--==================================================

local RigFrame = Instance.new("Frame")
RigFrame.Name = "RigFrame"
RigFrame.Size = UDim2.new(1, -20, 0, 24)
RigFrame.Position = UDim2.new(0, 10, 0, 213)
RigFrame.BackgroundTransparency = 1
RigFrame.Parent = MainFrame

local R15Button = Instance.new("TextButton")
R15Button.Name = "R15Button"
R15Button.Size = UDim2.new(0.5, -3, 1, 0)
R15Button.Position = UDim2.new(0, 0, 0, 0)
R15Button.BackgroundColor3 = COLORS.Active
R15Button.BorderSizePixel = 0
R15Button.Text = "R15"
R15Button.TextColor3 = COLORS.White
R15Button.Font = Enum.Font.GothamBold
R15Button.TextSize = 10
R15Button.AutoButtonColor = false
R15Button.Parent = RigFrame
makeCorner(R15Button, 6)

local R6Button = Instance.new("TextButton")
R6Button.Name = "R6Button"
R6Button.Size = UDim2.new(0.5, -3, 1, 0)
R6Button.Position = UDim2.new(0.5, 3, 0, 0)
R6Button.BackgroundColor3 = COLORS.Surface2
R6Button.BorderSizePixel = 0
R6Button.Text = "R6"
R6Button.TextColor3 = COLORS.Faint
R6Button.Font = Enum.Font.GothamBold
R6Button.TextSize = 10
R6Button.AutoButtonColor = false
R6Button.Parent = RigFrame
makeCorner(R6Button, 6)

local function updateRigButtons()
    if State.rig == "R15" then
        R15Button.BackgroundColor3 = COLORS.Active
        R15Button.TextColor3 = COLORS.White
        R6Button.BackgroundColor3 = COLORS.Surface2
        R6Button.TextColor3 = COLORS.Faint
    else
        -- R6 uses the exact same active color as R15
        R6Button.BackgroundColor3 = COLORS.Active
        R6Button.TextColor3 = COLORS.White
        R15Button.BackgroundColor3 = COLORS.Surface2
        R15Button.TextColor3 = COLORS.Faint
    end
end

R15Button.MouseButton1Click:Connect(function()
    if State.rig == "R15" then return end
    State.rig = "R15"
    updateRigButtons()
    notify("SIEXTHER AVATAR", "Rig diubah ke R15", 2)
end)

R6Button.MouseButton1Click:Connect(function()
    if State.rig == "R6" then return end
    State.rig = "R6"
    updateRigButtons()
    notify("SIEXTHER AVATAR", "Rig diubah ke R6", 2)
end)

--==================================================
-- ACTION BUTTONS
--==================================================

local ActionFrame = Instance.new("Frame")
ActionFrame.Name = "ActionFrame"
ActionFrame.Size = UDim2.new(1, -20, 0, 54)
ActionFrame.Position = UDim2.new(0, 10, 0, 243)
ActionFrame.BackgroundTransparency = 1
ActionFrame.Parent = MainFrame

local CopyButton = createButton(
    ActionFrame, "CopyButton", "COPY",
    UDim2.new(0, 0, 0, 0), UDim2.new(0.5, -3, 0, 25),
    COLORS.Primary
)

local ResetButton = createButton(
    ActionFrame, "ResetButton", "RESET",
    UDim2.new(0.5, 3, 0, 0), UDim2.new(0.5, -3, 0, 25),
    Color3.fromRGB(255, 80, 60)
)

local TeleportButton = createButton(
    ActionFrame, "TeleportButton", "TELEPORT",
    UDim2.new(0, 0, 0, 29), UDim2.new(0.5, -3, 0, 25),
    Color3.fromRGB(55, 115, 220)
)

local RefreshPlayerButton = createButton(
    ActionFrame, "RefreshPlayerButton", "REFRESH",
    UDim2.new(0.5, 3, 0, 29), UDim2.new(0.5, -3, 0, 25),
    Color3.fromRGB(55, 115, 220)
)

--==================================================
-- UPDATE CANVAS
--==================================================

local function updateCanvas()
    task.defer(function()
        if PlayerScrollFrame and PlayerScrollFrame.Parent then
            PlayerScrollFrame.CanvasSize = UDim2.new(0, 0, 0, PlayerLayout.AbsoluteContentSize.Y + 6)
        end
    end)
end

PlayerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

--==================================================
-- UPDATE PLAYER LIST
--==================================================

local function updatePlayerList()
    if State.Destroyed then return end
    for _, child in ipairs(PlayerScrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    local playerList = getPlayers()
    if #playerList == 0 then
        local EmptyFrame = Instance.new("Frame")
        EmptyFrame.Size = UDim2.new(1, -6, 0, 38)
        EmptyFrame.BackgroundColor3 = COLORS.Surface2
        EmptyFrame.BorderSizePixel = 0
        EmptyFrame.Parent = PlayerScrollFrame
        makeCorner(EmptyFrame, 6)
        local EmptyText = Instance.new("TextLabel")
        EmptyText.Size = UDim2.new(1, 0, 1, 0)
        EmptyText.BackgroundTransparency = 1
        EmptyText.Text = State.SearchQuery ~= "" and "No players found" or "No other players"
        EmptyText.TextColor3 = COLORS.Gray
        EmptyText.Font = Enum.Font.Gotham
        EmptyText.TextSize = 10
        EmptyText.Parent = EmptyFrame
        updateCanvas()
        return
    end
    for _, player in ipairs(playerList) do
        local PlayerContainer = Instance.new("Frame")
        PlayerContainer.Name = player.Name .. "_Container"
        PlayerContainer.Size = UDim2.new(1, -6, 0, 40)
        PlayerContainer.BackgroundColor3 = State.SelectedPlayer == player and COLORS.Primary or COLORS.Surface2
        PlayerContainer.BackgroundTransparency = State.SelectedPlayer == player and 0.78 or 0
        PlayerContainer.BorderSizePixel = 0
        PlayerContainer.Parent = PlayerScrollFrame
        makeCorner(PlayerContainer, 6)

        local AvatarImage = Instance.new("ImageLabel")
        AvatarImage.Size = UDim2.new(0, 32, 0, 32)
        AvatarImage.Position = UDim2.new(0, 4, 0, 4)
        AvatarImage.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        AvatarImage.BorderSizePixel = 0
        AvatarImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=48&h=48"
        AvatarImage.ScaleType = Enum.ScaleType.Fit
        AvatarImage.Parent = PlayerContainer
        makeCorner(AvatarImage, 6)

        local DisplayName = Instance.new("TextLabel")
        DisplayName.Size = UDim2.new(1, -46, 0, 17)
        DisplayName.Position = UDim2.new(0, 42, 0, 4)
        DisplayName.BackgroundTransparency = 1
        DisplayName.Text = player.DisplayName
        DisplayName.TextColor3 = COLORS.White
        DisplayName.Font = Enum.Font.GothamBold
        DisplayName.TextSize = 10
        DisplayName.TextXAlignment = Enum.TextXAlignment.Left
        DisplayName.TextTruncate = Enum.TextTruncate.AtEnd
        DisplayName.Parent = PlayerContainer

        local PlayerName = Instance.new("TextLabel")
        PlayerName.Size = UDim2.new(1, -46, 0, 13)
        PlayerName.Position = UDim2.new(0, 42, 0, 21)
        PlayerName.BackgroundTransparency = 1
        PlayerName.Text = "@" .. player.Name
        PlayerName.TextColor3 = COLORS.Gray
        PlayerName.Font = Enum.Font.Gotham
        PlayerName.TextSize = 8
        PlayerName.TextXAlignment = Enum.TextXAlignment.Left
        PlayerName.TextTruncate = Enum.TextTruncate.AtEnd
        PlayerName.Parent = PlayerContainer

        local SelectButton = Instance.new("TextButton")
        SelectButton.Size = UDim2.new(1, 0, 1, 0)
        SelectButton.BackgroundTransparency = 1
        SelectButton.BorderSizePixel = 0
        SelectButton.Text = ""
        SelectButton.AutoButtonColor = false
        SelectButton.Parent = PlayerContainer

        SelectButton.MouseButton1Click:Connect(function()
            State.SelectedPlayer = player
            SelectedLabel.Text = "Selected: " .. player.Name
            SelectedLabel.TextColor3 = COLORS.Primary
            for _, container in ipairs(PlayerScrollFrame:GetChildren()) do
                if container:IsA("Frame") then
                    if container.Name == player.Name .. "_Container" then
                        container.BackgroundColor3 = COLORS.Primary
                        container.BackgroundTransparency = 0.78
                    else
                        container.BackgroundColor3 = COLORS.Surface2
                        container.BackgroundTransparency = 0
                    end
                end
            end
        end)

        SelectButton.MouseEnter:Connect(function()
            TweenService:Create(PlayerContainer, TweenInfo.new(0.15), {
                BackgroundColor3 = State.SelectedPlayer == player and COLORS.Primary or COLORS.Hover,
                BackgroundTransparency = State.SelectedPlayer == player and 0.68 or 0
            }):Play()
        end)
        SelectButton.MouseLeave:Connect(function()
            TweenService:Create(PlayerContainer, TweenInfo.new(0.15), {
                BackgroundColor3 = State.SelectedPlayer == player and COLORS.Primary or COLORS.Surface2,
                BackgroundTransparency = State.SelectedPlayer == player and 0.78 or 0
            }):Play()
        end)
    end
    updateCanvas()
end

--==================================================
-- SEARCH
--==================================================

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    State.SearchQuery = SearchBox.Text or ""
    updatePlayerList()
end)

--==================================================
-- COPY BUTTON (fixed: debounce, check player.Parent)
--==================================================

local copyDebounce = false
CopyButton.MouseButton1Click:Connect(function()
    if copyDebounce then return end
    local player = State.SelectedPlayer
    if not player or not player.Parent then
        notify("SIEXTHER AVATAR", "Silakan pilih pemain terlebih dahulu.", 3)
        return
    end

    copyDebounce = true
    CopyButton.Text = "..."
    CopyButton.BackgroundColor3 = COLORS.Surface2

    local success, message = copyAvatar(player)

    if success then
        notify("SIEXTHER AVATAR", "Berhasil! " .. tostring(message), 3)
    else
        notify("SIEXTHER AVATAR", "Gagal! " .. tostring(message), 3)
    end

    task.delay(1.5, function()
        if CopyButton and CopyButton.Parent then
            CopyButton.Text = "COPY"
            CopyButton.BackgroundColor3 = COLORS.Primary
        end
        copyDebounce = false
    end)
end)

--==================================================
-- RESET BUTTON
--==================================================

ResetButton.MouseButton1Click:Connect(function()
    local success, message = resetAvatar()

    if success then
        notify("SIEXTHER AVATAR", "Berhasil! " .. tostring(message), 3)
    else
        notify("SIEXTHER AVATAR", "Gagal! " .. tostring(message), 3)
    end
end)

--==================================================
-- TELEPORT BUTTON
--==================================================

TeleportButton.MouseButton1Click:Connect(function()
    local player = State.SelectedPlayer
    if not player or not player.Parent then
        notify("SIEXTHER TELEPORT", "Silakan pilih pemain terlebih dahulu.", 3)
        return
    end

    local success, message = teleportToPlayer(player)

    if success then
        notify("SIEXTHER TELEPORT", "Berhasil! " .. tostring(message), 3)
    else
        notify("SIEXTHER TELEPORT", "Gagal! " .. tostring(message), 3)
    end
end)

--==================================================
-- REFRESH BUTTON
--==================================================

RefreshPlayerButton.MouseButton1Click:Connect(function()
    updatePlayerList()
    notify("SIEXTHER AVATAR", "Daftar pemain telah diperbarui.", 3)
end)

--==================================================
-- TOGGLE UI
--==================================================

local function toggleUI()
    if State.Destroyed then return end
    State.Open = not State.Open
    MainFrame.Visible = State.Open
    if State.Open then
        ToggleButton.Visible = false
        updatePlayerList()
    else
        ToggleButton.Visible = true
    end
end

ToggleButton.MouseButton1Click:Connect(toggleUI)
ToggleButton.MouseEnter:Connect(function() ToggleButton.BackgroundColor3 = COLORS.Hover end)
ToggleButton.MouseLeave:Connect(function() ToggleButton.BackgroundColor3 = COLORS.Surface end)

--==================================================
-- MINIMIZE
--==================================================

MinimizeButton.MouseButton1Click:Connect(function()
    if State.Destroyed then return end
    State.Open = false
    MainFrame.Visible = false
    ToggleButton.Visible = true
    ToggleButton.BackgroundColor3 = COLORS.Surface
end)

--==================================================
-- CLOSE
--==================================================

CloseButton.MouseButton1Click:Connect(function()
    if State.Destroyed then return end
    State.Destroyed = true
    fn29()
    ScreenGui:Destroy()
end)
CloseButton.MouseEnter:Connect(function() CloseButton.BackgroundColor3 = Color3.fromRGB(255, 80, 90) end)
CloseButton.MouseLeave:Connect(function() CloseButton.BackgroundColor3 = COLORS.Danger end)

--==================================================
-- F1 TOGGLE
--==================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or State.Destroyed then return end
    if input.KeyCode == Enum.KeyCode.F1 then toggleUI() end
end)

--==================================================
-- PLAYER EVENTS
--==================================================

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    if not State.Destroyed then updatePlayerList() end
end)

Players.PlayerRemoving:Connect(function(player)
    if State.SelectedPlayer == player then
        State.SelectedPlayer = nil
        SelectedLabel.Text = "Selected: None"
        SelectedLabel.TextColor3 = COLORS.Primary
    end
    if not State.Destroyed then
        task.wait(0.1)
        updatePlayerList()
    end
end)

--==================================================
-- CHARACTER RESPAWN
--==================================================

LocalPlayer.CharacterAdded:Connect(function(character)
    -- Clear overlay cache so next apply uses fresh data
    tbl17.modelo = nil
    tbl17.char = nil
    tbl17.cadena = {}
    task.wait(1)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then Camera.CameraSubject = humanoid end
end)

--==================================================
-- ANTI AFK
--==================================================

LocalPlayer.Idled:Connect(function()
    pcall(function()
        local VU = game:GetService("VirtualUser")
        VU:Button2Down(Vector2.new(0, 0))
        task.wait(0.1)
        VU:Button2Up(Vector2.new(0, 0))
    end)
end)

--==================================================
-- INITIALIZE
--==================================================

updateRigButtons()
updatePlayerList()
