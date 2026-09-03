
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

--//===== EMOTE SYSTEM =====//
local CurrentTrack = nil
local EMOTE_IDS = {
    "97751567165693",
    "128582748149019",
    "133965316214893"
}

local function getRandomEmoteID()
    return EMOTE_IDS[math.random(1, #EMOTE_IDS)]
end

local function LoadTrack(id)
    if CurrentTrack then 
        CurrentTrack:Stop(0) 
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

    newTrack:Play(0.1, 1, 1)
    
    CurrentTrack = newTrack

    return newTrack
end

local function StopTrack()
    if CurrentTrack then
        CurrentTrack:Stop(0.1)
        CurrentTrack = nil
    end
end

--//===== VARIABEL FLY =====//
local flying = false
local flySpeed = 2
local pressed = {Up=false,Down=false,Left=false,Right=false}
local moving = false
local savedOrientation = nil
local oldGravity = Workspace.Gravity
local frozenPos = nil

--//===== SCREEN GUI =====//
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FlyModernGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

--//===== MAIN FRAME =====//
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 90)
MainFrame.Position = UDim2.new(0.5, -100, 0.5, -45)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BackgroundTransparency = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = MainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(70, 130, 255)
mainStroke.Thickness = 2
mainStroke.Parent = MainFrame

--//===== NAVBAR =====//
local Navbar = Instance.new("Frame")
Navbar.Size = UDim2.new(1, 0, 0, 30)
Navbar.Position = UDim2.new(0, 0, 0, 0)
Navbar.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
Navbar.BorderSizePixel = 0
Navbar.Parent = MainFrame

local navCorner = Instance.new("UICorner")
navCorner.CornerRadius = UDim.new(0, 12)
navCorner.Parent = Navbar

-- Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -70, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "SIEXTHER FLY"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 14
TitleLabel.TextColor3 = Color3.fromRGB(70, 130, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Navbar

-- Minimize Button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 25, 0, 25)
MinimizeBtn.Position = UDim2.new(1, -55, 0.5, -12.5)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
MinimizeBtn.Text = "–"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 16
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Parent = Navbar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = MinimizeBtn

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -28, 0.5, -12.5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Parent = Navbar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = CloseBtn

--//===== FLOATING BUTTON =====//
local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Size = UDim2.new(0, 41, 0, 41)
FloatingBtn.Position = UDim2.new(1, -70, 0, 80)
FloatingBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
FloatingBtn.Text = "🦸"
FloatingBtn.Font = Enum.Font.GothamBold
FloatingBtn.TextSize = 20
FloatingBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
FloatingBtn.Visible = false
FloatingBtn.Active = true
FloatingBtn.Draggable = true
FloatingBtn.Parent = ScreenGui

local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(0, 12)
floatCorner.Parent = FloatingBtn

--//===== CONTENT FRAME =====//
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -16, 1, -40)
ContentFrame.Position = UDim2.new(0, 8, 0, 35)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Fly Toggle Button
local FlyToggleBtn = Instance.new("TextButton")
FlyToggleBtn.Size = UDim2.new(1, 0, 0, 40)
FlyToggleBtn.Position = UDim2.new(0, 0, 0, 5)
FlyToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
FlyToggleBtn.Text = "FLY"
FlyToggleBtn.Font = Enum.Font.GothamBold
FlyToggleBtn.TextSize = 14
FlyToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyToggleBtn.Parent = ContentFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = FlyToggleBtn

--//===== NEW D-PAD CONTROLS (POJOK KIRI BAWAH) =====//
local DPadContainer = Instance.new("Frame")
DPadContainer.Name = "DPadContainer"
DPadContainer.Size = UDim2.new(0, 160, 0, 160)
DPadContainer.Position = UDim2.new(0, 30, 1, -190)
DPadContainer.BackgroundTransparency = 1
DPadContainer.Visible = false
DPadContainer.Parent = ScreenGui

local function createDPadButton(name, position, text)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(0, 50, 0, 50)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    button.BackgroundTransparency = 0.3
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 24
    button.Font = Enum.Font.GothamBold
    button.BorderSizePixel = 0
    button.Parent = DPadContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button
    
    return button
end

local UpBtn = createDPadButton("Up", UDim2.new(0.5, -25, 0, 0), "▲")
local DownBtn = createDPadButton("Down", UDim2.new(0.5, -25, 1, -50), "▼")
local LeftBtn = createDPadButton("Left", UDim2.new(0, 0, 0.5, -25), "◀")
local RightBtn = createDPadButton("Right", UDim2.new(1, -50, 0.5, -25), "▶")

local function buttonPressEffect(button)
    button.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
end

local function buttonReleaseEffect(button)
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
end

local function connectBtn(btn, key)
    btn.MouseButton1Down:Connect(function()
        pressed[key] = true
        buttonPressEffect(btn)
    end)
    btn.MouseButton1Up:Connect(function()
        pressed[key] = false
        buttonReleaseEffect(btn)
    end)
end

connectBtn(UpBtn, "Up")
connectBtn(DownBtn, "Down")
connectBtn(LeftBtn, "Left")
connectBtn(RightBtn, "Right")

--//===== HELPER FUNCTIONS =====//
local function noclip(state)
    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = not state
        end
    end
end

local function enableFly()
    flying = true
    DPadContainer.Visible = true
    humanoid.PlatformStand = true
    noclip(true)
    Workspace.Gravity = 0
    
    FlyToggleBtn.Text = "STOP FLY"
    FlyToggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    
    frozenPos = root.Position
    local _, y, _ = root.CFrame:ToOrientation()
    savedOrientation = CFrame.Angles(0, y, 0)
    
    -- Load random emote
    local randomEmoteID = getRandomEmoteID()
    LoadTrack(randomEmoteID)
end

local function disableFly()
    flying = false
    DPadContainer.Visible = false
    humanoid.PlatformStand = false
    noclip(false)
    Workspace.Gravity = oldGravity
    frozenPos = nil
    
    FlyToggleBtn.Text = "FLY"
    FlyToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    
    -- Stop emote
    StopTrack()
end

--//===== BUTTON EVENTS =====//
FlyToggleBtn.MouseButton1Click:Connect(function()
    if flying then
        disableFly()
    else
        enableFly()
    end
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    local tween = TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 0, 0)})
    tween:Play()
    tween.Completed:Connect(function()
        MainFrame.Visible = false
        FloatingBtn.Visible = true
    end)
end)

FloatingBtn.MouseButton1Click:Connect(function()
    FloatingBtn.Visible = false
    MainFrame.Visible = true
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    local tween = TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 200, 0, 90)})
    tween:Play()
end)

CloseBtn.MouseButton1Click:Connect(function()
    if flying then disableFly() end
    local tween = TweenService:Create(MainFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 0)})
    tween:Play()
    tween.Completed:Wait()
    ScreenGui:Destroy()
end)

--//===== KEYBOARD INPUT =====//
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not flying then return end
    if input.KeyCode == Enum.KeyCode.W then pressed.Up = true end
    if input.KeyCode == Enum.KeyCode.S then pressed.Down = true end
    if input.KeyCode == Enum.KeyCode.A then pressed.Left = true end
    if input.KeyCode == Enum.KeyCode.D then pressed.Right = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then pressed.Up = false end
    if input.KeyCode == Enum.KeyCode.S then pressed.Down = false end
    if input.KeyCode == Enum.KeyCode.A then pressed.Left = false end
    if input.KeyCode == Enum.KeyCode.D then pressed.Right = false end
end)

--//===== FLY LOOP =====//
RunService.Heartbeat:Connect(function(dt)
    if not flying or not root then return end
    
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    
    local cam = workspace.CurrentCamera
    local lookVec = cam.CFrame.LookVector
    local rightVec = cam.CFrame.RightVector
    local dir = Vector3.zero
    
    if pressed.Up then dir += lookVec end
    if pressed.Down then dir -= lookVec end
    if pressed.Left then dir -= rightVec end
    if pressed.Right then dir += rightVec end
    
    if dir.Magnitude > 0 then
        moving = true
        frozenPos = root.Position + dir.Unit * flySpeed * dt * 60
        root.CFrame = CFrame.new(frozenPos, frozenPos + lookVec)
    else
        moving = false
        if frozenPos and savedOrientation then
            root.CFrame = CFrame.new(frozenPos) * savedOrientation
        end
    end
end)

--//===== RESET HANDLING =====//
humanoid.Died:Connect(function()
    disableFly()
end)

player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    root = char:WaitForChild("HumanoidRootPart")
    
    humanoid.Died:Connect(function()
        disableFly()
    end)
end)