-- BY @muhmdilhan_
function missing(t, f, fallback)
    if type(f) == t then return f end
    return fallback 
end

cloneref = missing("function", cloneref, function(...) return ... end)

local Services = setmetatable({}, {
    __index = function(_, name)
        return cloneref(game:GetService(name))
    end
})

local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService
local StarterGui = Services.StarterGui

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
end)

--// Settings
local Settings = {}
Settings["Speed"] = 1

-- Mode configurations
local GlitchModes = {
    {name = "SIEXTHER GLITCH V1 ⭐", id1 = "93224413172183", id2 = "93195109588878"},
    {name = "SIEXTHER GLITCH V2 ⭐", id1 = "70883871260184", id2 = nil},
    {name = "SIEXTHER GLITCH V3 ⭐", id1 = "93224413172183", id2 = "109501168073514"},
    {name = "SIEXTHER GLITCH V4 ⭐", id1 = "93224413172183", id2 = "75924260262717"},    
    {name = "SIEXTHER GLITCH V5 ⭐", id1 = "93224413172183", id2 = "123821472330376"},
    {name = "SIEXTHER GLITCH V6 ⭐", id1 = "93224413172183", id2 = "84662057365559"},
    {name = "SIEXTHER GLITCH V7 ⭐", id1 = "93224413172183", id2 = "78760916873658"},
   {name = "SIEXTHER GLITCH V8 ⭐", id1 = "93224413172183", id2 = "110172609245744"}, 
    {name = "SIEXTHER GLITCH V9", id1 = "93224413172183", id2 = "140356607168824"},
    {name = "SIEXTHER GLITCH v10", id1 = "93224413172183", id2 = "137822800022978"},
    {name = "SIEXTHER GLITCH V11", id1 = "93224413172183", id2 = "95337497384937"},
    {name = "SIEXTHER GLITCH V12", id1 = "93224413172183", id2 = "131029312743794"},
    {name = "SIEXTHER GLITCH V13", id1 = "93224413172183", id2 = "137869087140582"},
    {name = "SIEXTHER GLITCH V14", id1 = "93224413172183", id2 = "82743213236172"},
    {name = "SIEXTHER GLITCH V15", id1 = "93224413172183", id2 = "94438242882874"},
    {name = "SIEXTHER GLITCH V16", id1 = "93224413172183", id2 = "107199542682215"}
}

local selectedMode = nil
local isGlitchActive = false

local CurrentTrack1
local CurrentTrack2
local lastPosition = character.PrimaryPart and character.PrimaryPart.Position or Vector3.new()

-- FreeCam Variables
local freeCamEnabled = false
local freeCamConnection
local keysDown = {}
local rotating = false
local touchPos
local onMobile = not UserInputService.KeyboardEnabled
local freeCamSpeed = 25
local freeCamSens = 0.3
local originalWalkSpeed = 16
local originalJumpPower = 50
local originalJumpHeight = 7.2
local originalCamera = workspace.CurrentCamera.CameraType

freeCamSpeed = freeCamSpeed / 25

if onMobile then
    freeCamSens = freeCamSens * 2
end

-- Function to check if in correct map
local function isInCorrectMap()
    return game.PlaceId == 6358567974
end

local function extractIdFromInput(input)
    local num = tonumber(input)
    if num then
        return num
    end
    local assetIdMatch = string.match(input, "rbxassetid://(%d+)")
    if assetIdMatch then
        return tonumber(assetIdMatch)
    end
    local catalogMatch = string.match(input, "roblox%.com/catalog/(%d+)")
    if catalogMatch then
        return tonumber(catalogMatch)
    end
    local libraryMatch = string.match(input, "roblox%.com/library/(%d+)")
    if libraryMatch then
        return tonumber(libraryMatch)
    end
    local assetMatch = string.match(input, "roblox%.com/asset/%?id=(%d+)")
    if assetMatch then
        return tonumber(assetMatch)
    end
    return tonumber(input)
end

local function LoadTrack(id)
    if CurrentTrack1 then 
        CurrentTrack1:Stop(0) 
    end

    local animId
    local ok, result = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(id))
    end)

    if ok and result and #result > 0 then
        local anim = result[1]
        if anim:IsA("Animation") then
            animId = anim.AnimationId
        else
            animId = "rbxassetid://" .. tostring(id)
        end
    else
        animId = "rbxassetid://" .. tostring(id)
    end

    local newAnim = Instance.new("Animation")
    newAnim.AnimationId = animId
    local newTrack = humanoid:LoadAnimation(newAnim)
    newTrack.Priority = Enum.AnimationPriority.Action4

    newTrack:Play(0.1, 1, Settings["Speed"])
    
    CurrentTrack1 = newTrack

    return newTrack
end

local function LoadTrack2(id)
    if CurrentTrack2 then 
        CurrentTrack2:Stop(0) 
    end

    local animId
    local ok, result = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(id))
    end)

    if ok and result and #result > 0 then
        local anim = result[1]
        if anim:IsA("Animation") then
            animId = anim.AnimationId
        else
            animId = "rbxassetid://" .. tostring(id)
        end
    else
        animId = "rbxassetid://" .. tostring(id)
    end

    local newAnim = Instance.new("Animation")
    newAnim.AnimationId = animId
    local newTrack = humanoid:LoadAnimation(newAnim)
    newTrack.Priority = Enum.AnimationPriority.Action3

    newTrack:Play(0.1, 1, Settings["Speed"])
    
    CurrentTrack2 = newTrack

    return newTrack
end

local function StopTrack()
    if CurrentTrack1 then
        CurrentTrack1:Stop(0.1)
        CurrentTrack1 = nil
    end
    if CurrentTrack2 then
        CurrentTrack2:Stop(0.1)
        CurrentTrack2 = nil
    end
end

local function SmoothTween(obj, time, properties)
    local tween = TweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    tween:Play()
    return tween
end

-- FreeCam Functions
local function freeCamRenderStep()
    local cam = workspace.CurrentCamera
    
    if rotating then
        local delta = UserInputService:GetMouseDelta()
        local cf = cam.CFrame
        local yAngle = cf:ToEulerAngles(Enum.RotationOrder.YZX)
        local newAmount = math.deg(yAngle) + delta.Y
        
        if newAmount > 65 or newAmount < -65 then
            if not (yAngle < 0 and delta.Y < 0) and not (yAngle > 0 and delta.Y > 0) then
                delta = Vector2.new(delta.X, 0)
            end
        end
        
        cf = cf * CFrame.Angles(-math.rad(delta.Y), 0, 0)
        cf = CFrame.Angles(0, -math.rad(delta.X), 0) * (cf - cf.Position) + cf.Position
        cf = CFrame.lookAt(cf.Position, cf.Position + cf.LookVector)
        
        if delta ~= Vector2.new(0, 0) then
            cam.CFrame = cam.CFrame:Lerp(cf, freeCamSens)
        end
        
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
    
    if keysDown["Enum.KeyCode.W"] then
        cam.CFrame = cam.CFrame * CFrame.new(Vector3.new(0, 0, -freeCamSpeed))
    end
    if keysDown["Enum.KeyCode.A"] then
        cam.CFrame = cam.CFrame * CFrame.new(Vector3.new(-freeCamSpeed, 0, 0))
    end
    if keysDown["Enum.KeyCode.S"] then
        cam.CFrame = cam.CFrame * CFrame.new(Vector3.new(0, 0, freeCamSpeed))
    end
    if keysDown["Enum.KeyCode.D"] then
        cam.CFrame = cam.CFrame * CFrame.new(Vector3.new(freeCamSpeed, 0, 0))
    end
end

local function enableFreeCam()
    if freeCamEnabled then return end
    freeCamEnabled = true
    
    if player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            originalWalkSpeed = hum.WalkSpeed
            originalJumpPower = hum.JumpPower
            originalJumpHeight = hum.JumpHeight
            
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum.JumpHeight = 0
        end
    end
    
    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
    freeCamConnection = RunService.RenderStepped:Connect(freeCamRenderStep)
end

local function disableFreeCam()
    if not freeCamEnabled then return end
    freeCamEnabled = false
    
    if freeCamConnection then
        freeCamConnection:Disconnect()
        freeCamConnection = nil
    end
    
    if player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = originalWalkSpeed
            hum.JumpPower = originalJumpPower
            hum.JumpHeight = originalJumpHeight
        end
    end
    
    workspace.CurrentCamera.CameraSubject = player.Character.Humanoid
    workspace.CurrentCamera.CameraType = originalCamera
    
    keysDown = {}
    rotating = false
end

-- Input handling for FreeCam
local validKeys = {"Enum.KeyCode.W", "Enum.KeyCode.A", "Enum.KeyCode.S", "Enum.KeyCode.D"}

UserInputService.InputBegan:Connect(function(Input)
    if not freeCamEnabled then return end
    
    for i, key in pairs(validKeys) do
        if key == tostring(Input.KeyCode) then
            keysDown[key] = true
        end
    end
    
    if Input.UserInputType == Enum.UserInputType.MouseButton2 or 
       (Input.UserInputType == Enum.UserInputType.Touch and UserInputService:GetMouseLocation().X > (workspace.CurrentCamera.ViewportSize.X / 2)) then
        rotating = true
    end
    
    if Input.UserInputType == Enum.UserInputType.Touch then
        if Input.Position.X < workspace.CurrentCamera.ViewportSize.X / 2 then
            touchPos = Input.Position
        end
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if not freeCamEnabled then return end
    
    for key, v in pairs(keysDown) do
        if key == tostring(Input.KeyCode) then
            keysDown[key] = false
        end
    end
    
    if Input.UserInputType == Enum.UserInputType.MouseButton2 or 
       (Input.UserInputType == Enum.UserInputType.Touch and UserInputService:GetMouseLocation().X > (workspace.CurrentCamera.ViewportSize.X / 2)) then
        rotating = false
    end
    
    if Input.UserInputType == Enum.UserInputType.Touch and touchPos then
        if Input.Position.X < workspace.CurrentCamera.ViewportSize.X / 2 then
            touchPos = nil
            keysDown["Enum.KeyCode.W"] = false
            keysDown["Enum.KeyCode.A"] = false
            keysDown["Enum.KeyCode.S"] = false
            keysDown["Enum.KeyCode.D"] = false
        end
    end
end)

UserInputService.TouchMoved:Connect(function(input)
    if not freeCamEnabled then return end
    
    if touchPos then
        if input.Position.X < workspace.CurrentCamera.ViewportSize.X / 2 then
            if input.Position.Y < touchPos.Y then
                keysDown["Enum.KeyCode.W"] = true
                keysDown["Enum.KeyCode.S"] = false
            else
                keysDown["Enum.KeyCode.W"] = false
                keysDown["Enum.KeyCode.S"] = true
            end
            
            if input.Position.X < (touchPos.X - 15) then
                keysDown["Enum.KeyCode.A"] = true
                keysDown["Enum.KeyCode.D"] = false
            elseif input.Position.X > (touchPos.X + 15) then
                keysDown["Enum.KeyCode.A"] = false
                keysDown["Enum.KeyCode.D"] = true
            else
                keysDown["Enum.KeyCode.A"] = false
                keysDown["Enum.KeyCode.D"] = false
            end
        end
    end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SiextherByHann.Sxthr"
screenGui.ResetOnSpawn = false
screenGui.Parent = Services.CoreGui

-- MAIN FRAME
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 250)
mainFrame.Position = UDim2.new(0.5, -120, 0.5, -125)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 10)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(70, 130, 255)
mainStroke.Thickness = 2

-- Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 26, 0, 26)
minimizeBtn.Position = UDim2.new(1, -60, 0, 6)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
minimizeBtn.Text = "–"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 18
minimizeBtn.ZIndex = 10
minimizeBtn.Parent = mainFrame

local minimizeCorner = Instance.new("UICorner", minimizeBtn)
minimizeCorner.CornerRadius = UDim.new(0, 6)

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -30, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.ZIndex = 10
closeBtn.Parent = mainFrame

local closeCorner = Instance.new("UICorner", closeBtn)
closeCorner.CornerRadius = UDim.new(0, 6)

-- Minimized Button
local minimizedBtn = Instance.new("TextButton")
minimizedBtn.Size = UDim2.new(0, 41, 0, 41)
minimizedBtn.Position = UDim2.new(0, 15, 0, 60)
minimizedBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
minimizedBtn.Text = "SX"
minimizedBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
minimizedBtn.Font = Enum.Font.GothamBold
minimizedBtn.TextSize = 25
minimizedBtn.Visible = false
minimizedBtn.Active = true
minimizedBtn.Draggable = true
minimizedBtn.Parent = screenGui
minimizedBtn.ZIndex = 5

-- Gradient Animation untuk Minimized Button
local MinimizedGradient = Instance.new("UIGradient")
MinimizedGradient.Parent = minimizedBtn
MinimizedGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
MinimizedGradient.Offset = Vector2.new(-1, 0)

task.spawn(function()
    while minimizedBtn and minimizedBtn.Parent do
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

local minimizedCorner = Instance.new("UICorner", minimizedBtn)
minimizedCorner.CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -95, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "SIEXTHER GLITCHER"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(70, 130, 255)
title.Parent = mainFrame

local TitleGradient = Instance.new("UIGradient")
TitleGradient.Parent = title
TitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
TitleGradient.Offset = Vector2.new(-1, 0)

task.spawn(function()
    while title and title.Parent do
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

-- Load notification system
loadstring(game:HttpGet("https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/han.lua"))()

-- Dropdown Button untuk Mode Selection
local dropdownBtn = Instance.new("TextButton")
dropdownBtn.Size = UDim2.new(1, -20, 0, 30)
dropdownBtn.Position = UDim2.new(0, 10, 0, 38)
dropdownBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
dropdownBtn.BorderSizePixel = 0
dropdownBtn.Text = "PILIH MODE ▼"
dropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dropdownBtn.Font = Enum.Font.GothamBold
dropdownBtn.TextSize = 12
dropdownBtn.ZIndex = 5
dropdownBtn.Parent = mainFrame

local dropdownCorner = Instance.new("UICorner", dropdownBtn)
dropdownCorner.CornerRadius = UDim.new(0, 7)

-- Dropdown Frame (akan muncul di luar mainFrame)
local dropdownFrame = Instance.new("ScrollingFrame")
dropdownFrame.Size = UDim2.new(0, 220, 0, 200)
dropdownFrame.Position = UDim2.new(0, 10, 0, 70)
dropdownFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
dropdownFrame.BorderSizePixel = 0
dropdownFrame.Visible = false
dropdownFrame.ScrollBarThickness = 6
dropdownFrame.CanvasSize = UDim2.new(0, 0, 0, #GlitchModes * 32 + 10)
dropdownFrame.ZIndex = 100
dropdownFrame.Parent = mainFrame

local dropdownFrameCorner = Instance.new("UICorner", dropdownFrame)
dropdownFrameCorner.CornerRadius = UDim.new(0, 7)

local dropdownStroke = Instance.new("UIStroke", dropdownFrame)
dropdownStroke.Color = Color3.fromRGB(70, 130, 255)
dropdownStroke.Thickness = 2

-- Create mode buttons in dropdown
for i, mode in ipairs(GlitchModes) do
    local modeBtn = Instance.new("TextButton")
    modeBtn.Size = UDim2.new(1, -10, 0, 28)
    modeBtn.Position = UDim2.new(0, 5, 0, (i - 1) * 32 + 5)
    modeBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
    modeBtn.BorderSizePixel = 0
    modeBtn.Text = mode.name
    modeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    modeBtn.Font = Enum.Font.GothamMedium
    modeBtn.TextSize = 11
    modeBtn.ZIndex = 101
    modeBtn.Parent = dropdownFrame
    
    local modeBtnCorner = Instance.new("UICorner", modeBtn)
    modeBtnCorner.CornerRadius = UDim.new(0, 5)
    
    modeBtn.MouseButton1Click:Connect(function()
        selectedMode = i
        dropdownBtn.Text = mode.name .. " ▼"
        dropdownFrame.Visible = false      
        
        -- If glitch already active, change mode directly
        if isGlitchActive then
            StopTrack()
            
            local id1 = extractIdFromInput(mode.id1)
            if id1 then
                LoadTrack(id1)
            end
            
            if mode.id2 then
                local id2 = extractIdFromInput(mode.id2)
                if id2 then
                    LoadTrack2(id2)
                end
            end
            
            getgenv().Notify({Title = "MODE BERUBAH", Content = "GLITCH BERGANTI KE " .. mode.name, Duration = 2})
            
        end
    end)
    
    modeBtn.MouseEnter:Connect(function()
        TweenService:Create(modeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 130, 255)}):Play()
        modeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    
    modeBtn.MouseLeave:Connect(function()
        TweenService:Create(modeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 40, 50)}):Play()
        modeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    end)
end

-- Toggle dropdown visibility
dropdownBtn.MouseButton1Click:Connect(function()
    dropdownFrame.Visible = not dropdownFrame.Visible
end)

-- Activate/Deactivate Button
local activateBtn = Instance.new("TextButton")
activateBtn.Size = UDim2.new(1, -20, 0, 30)
activateBtn.Position = UDim2.new(0, 10, 0, 72)
activateBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
activateBtn.BorderSizePixel = 0
activateBtn.Text = "AKTIFKAN GLITCH"
activateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
activateBtn.Font = Enum.Font.GothamBold
activateBtn.TextSize = 12
activateBtn.Parent = mainFrame

local activateCorner = Instance.new("UICorner", activateBtn)
activateCorner.CornerRadius = UDim.new(0, 7)

activateBtn.MouseButton1Click:Connect(function()
    if not isGlitchActive then
        if not selectedMode then
        getgenv().Notify({Title = "TERJADI KESALAHAN", Content = "PILIH MODE DULU SAYANG!", Duration = 2})            
            return
        end
        
        local mode = GlitchModes[selectedMode]
        local id1 = extractIdFromInput(mode.id1)
        
        if id1 then
            LoadTrack(id1)
        end
        
        if mode.id2 then
            local id2 = extractIdFromInput(mode.id2)
            if id2 then
                LoadTrack2(id2)
            end
        end
        
        activateBtn.Text = "MATIKAN GLITCH"
        activateBtn.TextColor3 = Color3.fromRGB(255, 59, 48)
        isGlitchActive = true
        
        getgenv().Notify({Title = "SIEXTHER GLITCH", Content = mode.name .. " TELAH DIAKTIFKAN!", Duration = 2})
        

    else
        StopTrack()
        activateBtn.Text = "AKTIFKAN GLITCH"
        activateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        isGlitchActive = false
        
                getgenv().Notify({Title = "SIEXTHER GLITCH", Content = "GLITCH TELAH DIMATIKAN!", Duration = 2})
        

    end
end)

-- Speed Slider Container
local speedContainer = Instance.new("Frame")
speedContainer.Size = UDim2.new(1, -20, 0, 48)
speedContainer.Position = UDim2.new(0, 10, 0, 107)
speedContainer.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
speedContainer.BorderSizePixel = 0
speedContainer.Parent = mainFrame

local speedCorner = Instance.new("UICorner", speedContainer)
speedCorner.CornerRadius = UDim.new(0, 7)

local speedStroke = Instance.new("UIStroke", speedContainer)
speedStroke.Color = Color3.fromRGB(70, 130, 255)
speedStroke.Thickness = 1
speedStroke.Transparency = 0.5

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -16, 0, 16)
speedLabel.Position = UDim2.new(0, 8, 0, 4)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = string.format("SPEED GLITCH: X%.1f", Settings["Speed"]) 
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.Font = Enum.Font.GothamMedium
speedLabel.TextSize = 11
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedContainer

local sliderBar = Instance.new("Frame")
sliderBar.Size = UDim2.new(1, -16, 0, 7)
sliderBar.Position = UDim2.new(0, 8, 0, 28)
sliderBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
sliderBar.BorderSizePixel = 0
sliderBar.Parent = speedContainer

local sliderCorner = Instance.new("UICorner", sliderBar)
sliderCorner.CornerRadius = UDim.new(1, 0)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.2, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBar

local fillCorner = Instance.new("UICorner", sliderFill)
fillCorner.CornerRadius = UDim.new(1, 0)

local thumb = Instance.new("Frame")
thumb.Size = UDim2.new(0, 14, 0, 14)
thumb.AnchorPoint = Vector2.new(0.5, 0.5)
thumb.Position = UDim2.new(0.2, 0, 0.5, 0)
thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
thumb.BorderSizePixel = 0
thumb.Parent = sliderBar

local thumbCorner = Instance.new("UICorner", thumb)
thumbCorner.CornerRadius = UDim.new(1, 0)

local thumbStroke = Instance.new("UIStroke", thumb)
thumbStroke.Color = Color3.fromRGB(70, 130, 255)
thumbStroke.Thickness = 2

-- TOOLS Divider dengan garis kiri kanan
local toolsDividerContainer = Instance.new("Frame")
toolsDividerContainer.Size = UDim2.new(1, -20, 0, 18)
toolsDividerContainer.Position = UDim2.new(0, 10, 0, 161)
toolsDividerContainer.BackgroundTransparency = 1
toolsDividerContainer.Parent = mainFrame

local leftLine = Instance.new("Frame")
leftLine.Size = UDim2.new(0.25, 0, 0, 1)
leftLine.Position = UDim2.new(0, 0, 0.5, 0)
leftLine.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
leftLine.BorderSizePixel = 0
leftLine.Parent = toolsDividerContainer

local toolsDivider = Instance.new("TextLabel")
toolsDivider.Size = UDim2.new(0.5, 0, 1, 0)
toolsDivider.Position = UDim2.new(0.25, 0, 0, 0)
toolsDivider.BackgroundTransparency = 1
toolsDivider.Text = "TOOLS"
toolsDivider.TextColor3 = Color3.fromRGB(70, 130, 255)
toolsDivider.Font = Enum.Font.GothamBold
toolsDivider.TextSize = 11
toolsDivider.Parent = toolsDividerContainer

local rightLine = Instance.new("Frame")
rightLine.Size = UDim2.new(0.25, 0, 0, 1)
rightLine.Position = UDim2.new(0.75, 0, 0.5, 0)
rightLine.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
rightLine.BorderSizePixel = 0
rightLine.Parent = toolsDividerContainer

-- Spin Button
local spinBtn = Instance.new("TextButton")
spinBtn.Size = UDim2.new(0.48, -5, 0, 28)
spinBtn.Position = UDim2.new(0, 10, 0, 184)
spinBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
spinBtn.BorderSizePixel = 0
spinBtn.Text = "SPIN"
spinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
spinBtn.Font = Enum.Font.GothamBold
spinBtn.TextSize = 11
spinBtn.Parent = mainFrame

local spinCorner = Instance.new("UICorner", spinBtn)
spinCorner.CornerRadius = UDim.new(0, 7)

-- Swimming Button
local swimBtn = Instance.new("TextButton")
swimBtn.Size = UDim2.new(0.48, -5, 0, 28)
swimBtn.Position = UDim2.new(0.52, 0, 0, 184)
swimBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
swimBtn.BorderSizePixel = 0
swimBtn.Text = "SWIM"
swimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
swimBtn.Font = Enum.Font.GothamBold
swimBtn.TextSize = 11
swimBtn.Parent = mainFrame

local swimCorner = Instance.new("UICorner", swimBtn)
swimCorner.CornerRadius = UDim.new(0, 7)

-- Copy Hat IDs Button
local copyHatBtn = Instance.new("TextButton")
copyHatBtn.Size = UDim2.new(1, -20, 0, 28)
copyHatBtn.Position = UDim2.new(0, 10, 0, 217)
copyHatBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
copyHatBtn.BorderSizePixel = 0
copyHatBtn.Text = "COPY HAT"
copyHatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyHatBtn.Font = Enum.Font.GothamBold
copyHatBtn.TextSize = 11
copyHatBtn.Parent = mainFrame

local copyHatCorner = Instance.new("UICorner", copyHatBtn)
copyHatCorner.CornerRadius = UDim.new(0, 7)

-- Update button state based on map
local function updateCopyHatButton()
    if isInCorrectMap() then
        copyHatBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
        copyHatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        copyHatBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
        copyHatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        
    end
end

-- Initial button state check
updateCopyHatButton()

-- Speed Slider
local function updateSpeedSlider(value)
    Settings["Speed"] = value
    speedLabel.Text = string.format("SPEED GLITCH: X%.1f", value)
    local rel = math.clamp((value - 0) / (10 - 0), 0, 1)
    TweenService:Create(sliderFill, TweenInfo.new(0.15), {Size = UDim2.new(rel, 0, 1, 0)}):Play()
    TweenService:Create(thumb, TweenInfo.new(0.15), {Position = UDim2.new(rel, 0, 0.5, 0)}):Play()

    if CurrentTrack1 and CurrentTrack1.IsPlaying then
        CurrentTrack1:AdjustSpeed(Settings["Speed"])
    end
    if CurrentTrack2 and CurrentTrack2.IsPlaying then
        CurrentTrack2:AdjustSpeed(Settings["Speed"])
    end
end

local dragging = false
local function updateFromInput(input)
    local relX = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
    local value = math.floor((0 + (10 - 0) * relX) * 10) / 10
    updateSpeedSlider(value)
end

sliderBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        updateFromInput(input)
    end
end)

thumb.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        updateFromInput(input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateFromInput(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        dragging = false
    end
end)

-- Spin Button Logic
local isSpinning = false
local spinConnection

spinBtn.MouseButton1Click:Connect(function()
    if not isSpinning then
        isSpinning = true
        spinBtn.Text = "SPIN"
        spinBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        
        spinConnection = RunService.RenderStepped:Connect(function(dt)
            if character.PrimaryPart then
                character.PrimaryPart.CFrame = character.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(40), 0)
            end
        end)
    else
        isSpinning = false
        spinBtn.Text = "SPIN"
        spinBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
        
        if spinConnection then
            spinConnection:Disconnect()
            spinConnection = nil
        end
    end
end)

-- Swimming Logic
local swimming = false
local oldgrav = nil
local gravReset = nil
local swimbeat = nil

local function startSwimming()
    if player and character and humanoid then
        oldgrav = workspace.Gravity
        workspace.Gravity = 0
        
        local function swimDied()
            workspace.Gravity = oldgrav
            swimming = false
            if gravReset then
                gravReset:Disconnect()
            end
            if swimbeat then
                swimbeat:Disconnect()
                swimbeat = nil
            end
            local enums = Enum.HumanoidStateType:GetEnumItems()
            table.remove(enums, table.find(enums, Enum.HumanoidStateType.None))
            for _, v in pairs(enums) do
                humanoid:SetStateEnabled(v, true)
            end
        end
        
        gravReset = humanoid.Died:Connect(swimDied)
        local enums = Enum.HumanoidStateType:GetEnumItems()
        table.remove(enums, table.find(enums, Enum.HumanoidStateType.None))
        for _, v in pairs(enums) do
            humanoid:SetStateEnabled(v, false)
        end
        humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
        
        swimbeat = RunService.Heartbeat:Connect(function()
            pcall(function()
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local rootPart = character.HumanoidRootPart
                    if humanoid.MoveDirection ~= Vector3.new() then
                        rootPart.Velocity = Vector3.new(0, 10, 0)
                    else
                        rootPart.Velocity = Vector3.new()
                    end
                end
            end)
        end)
        
        swimming = true
    end
end

local function stopSwimming()
    if swimming then
        workspace.Gravity = oldgrav
        swimming = false
        if gravReset then
            gravReset:Disconnect()
            gravReset = nil
        end
        if swimbeat then
            swimbeat:Disconnect()
            swimbeat = nil
        end
        local enums = Enum.HumanoidStateType:GetEnumItems()
        table.remove(enums, table.find(enums, Enum.HumanoidStateType.None))
        for _, v in pairs(enums) do
            humanoid:SetStateEnabled(v, true)
        end
    end
end

swimBtn.MouseButton1Click:Connect(function()
    if swimming then
        stopSwimming()
        swimBtn.Text = "SWIM"
        swimBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
    else
        startSwimming()
        swimBtn.Text = "SWIM"
        swimBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    end
end)

-- Copy Hat IDs Button Logic
copyHatBtn.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet("https://app.buddy.works/ilhamfleast123/kyzn/repository/raw/branch/master/cc"))()
end)

-- Variable untuk menyimpan posisi frame
local savedFramePosition = mainFrame.Position

-- Minimize/Maximize Logic dengan Animasi
minimizeBtn.MouseButton1Click:Connect(function()
    savedFramePosition = mainFrame.Position
    
    mainFrame.Visible = false
    minimizedBtn.Visible = true
end)

minimizedBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    minimizedBtn.Visible = false
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = savedFramePosition
    mainFrame.BackgroundTransparency = 1
    
    SmoothTween(mainFrame, 0.5, {
        Size = UDim2.new(0, 240, 0, 250),
        Position = savedFramePosition,
        BackgroundTransparency = 0
    })
end)

-- Close Button Logic dengan Animasi
closeBtn.MouseButton1Click:Connect(function()
    StopTrack()
    if spinConnection then
        spinConnection:Disconnect()
    end
    stopSwimming()
    if freeCamEnabled then
        disableFreeCam()
    end
    screenGui:Destroy()
end)

RunService.RenderStepped:Connect(function()
    if character.PrimaryPart then
        lastPosition = character.PrimaryPart.Position
    end
end)

-- Handle character respawn for FreeCam
player.CharacterAdded:Connect(function(newChar)
    if freeCamEnabled then
        task.wait(0.1)
        local hum = newChar:WaitForChild("Humanoid")
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        hum.JumpHeight = 0
    end
end)