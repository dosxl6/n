function missing(t, f, fallback)
    if type(f) == t then
        return f
    end
    return fallback
end

cloneref = missing("function", cloneref, function(...)
    return ...
end)

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

--// Settings
local Settings = {
    ["Fade In"] = 0.1,
    ["Fade Out"] = 0.1,
    ["Weight"] = 1,
    ["Speed"] = 1,
    ["Allow Invisible"] = true,
    ["Time Position"] = 0.99
}

--// Emote ID
local EMOTE_ID = "70883871260184"

--// Main Variables
local isGlitchActive = false
local CurrentTrack
local lastPosition =
    character.PrimaryPart and character.PrimaryPart.Position
    or Vector3.new()

--// FreeCam Variables
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

--// Shunshin Variables
local shunshinActive = false
local shunshinLoop = false

freeCamSpeed = freeCamSpeed / 25

if onMobile then
    freeCamSens = freeCamSens * 2
end

--// Correct Map
local function isInCorrectMap()
    return game.PlaceId == 6358567974
end

--// Character Update
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")

    task.wait(0.1)

    if freeCamEnabled then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.JumpHeight = 0
    end
end)

--// Load Track
local function LoadTrack(id)
    if CurrentTrack then
        CurrentTrack:Stop(Settings["Fade Out"])
    end

    local animId = "rbxassetid://" .. tostring(id)

    local newAnim = Instance.new("Animation")
    newAnim.AnimationId = animId

    local animator = humanoid:FindFirstChildOfClass("Animator")

    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    local newTrack = animator:LoadAnimation(newAnim)
    newTrack.Priority = Enum.AnimationPriority.Action4

    local weight = Settings["Weight"]

    if weight == 0 then
        weight = 0.001
    end

    newTrack:Play(
        Settings["Fade In"],
        weight,
        Settings["Speed"]
    )

    CurrentTrack = newTrack

    if newTrack.Length > 0 then
        newTrack.TimePosition =
            math.clamp(
                Settings["Time Position"],
                0,
                1
            ) * newTrack.Length
    end

    task.delay(1, function()
        if CurrentTrack
            and CurrentTrack == newTrack
            and CurrentTrack.IsPlaying then

            CurrentTrack:AdjustSpeed(0)
        end
    end)

    return newTrack
end

--// Stop Track
local function StopTrack()
    if CurrentTrack then
        CurrentTrack:Stop(Settings["Fade Out"])
        CurrentTrack = nil
    end
end

--// Smooth Tween
local function SmoothTween(obj, time, properties)
    local tween = TweenService:Create(
        obj,
        TweenInfo.new(
            time,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        properties
    )

    tween:Play()

    return tween
end

--// FreeCam Render
local function freeCamRenderStep()
    local cam = workspace.CurrentCamera

    if rotating then
        local delta = UserInputService:GetMouseDelta()
        local cf = cam.CFrame

        local yAngle =
            cf:ToEulerAngles(Enum.RotationOrder.YZX)

        local newAmount =
            math.deg(yAngle) + delta.Y

        if newAmount > 65 or newAmount < -65 then
            if not (
                yAngle < 0 and delta.Y < 0
            ) and not (
                yAngle > 0 and delta.Y > 0
            ) then

                delta = Vector2.new(delta.X, 0)
            end
        end

        cf =
            cf *
            CFrame.Angles(
                -math.rad(delta.Y),
                0,
                0
            )

        cf =
            CFrame.Angles(
                0,
                -math.rad(delta.X),
                0
            ) *
            (cf - cf.Position)
            + cf.Position

        cf =
            CFrame.lookAt(
                cf.Position,
                cf.Position + cf.LookVector
            )

        if delta ~= Vector2.new(0, 0) then
            cam.CFrame =
                cam.CFrame:Lerp(
                    cf,
                    freeCamSens
                )
        end

        UserInputService.MouseBehavior =
            Enum.MouseBehavior.LockCurrentPosition
    else
        UserInputService.MouseBehavior =
            Enum.MouseBehavior.Default
    end

    if keysDown["Enum.KeyCode.W"] then
        cam.CFrame =
            cam.CFrame *
            CFrame.new(
                Vector3.new(
                    0,
                    0,
                    -freeCamSpeed
                )
            )
    end

    if keysDown["Enum.KeyCode.A"] then
        cam.CFrame =
            cam.CFrame *
            CFrame.new(
                Vector3.new(
                    -freeCamSpeed,
                    0,
                    0
                )
            )
    end

    if keysDown["Enum.KeyCode.S"] then
        cam.CFrame =
            cam.CFrame *
            CFrame.new(
                Vector3.new(
                    0,
                    0,
                    freeCamSpeed
                )
            )
    end

    if keysDown["Enum.KeyCode.D"] then
        cam.CFrame =
            cam.CFrame *
            CFrame.new(
                Vector3.new(
                    freeCamSpeed,
                    0,
                    0
                )
            )
    end
end

--// Enable FreeCam
local function enableFreeCam()
    if freeCamEnabled then
        return
    end

    freeCamEnabled = true

    if player.Character then
        local hum =
            player.Character:FindFirstChildOfClass("Humanoid")

        if hum then
            originalWalkSpeed = hum.WalkSpeed
            originalJumpPower = hum.JumpPower
            originalJumpHeight = hum.JumpHeight

            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum.JumpHeight = 0
        end
    end

    workspace.CurrentCamera.CameraType =
        Enum.CameraType.Scriptable

    freeCamConnection =
        RunService.RenderStepped:Connect(
            freeCamRenderStep
        )
end

--// Disable FreeCam
local function disableFreeCam()
    if not freeCamEnabled then
        return
    end

    freeCamEnabled = false

    if freeCamConnection then
        freeCamConnection:Disconnect()
        freeCamConnection = nil
    end

    if player.Character then
        local hum =
            player.Character:FindFirstChildOfClass("Humanoid")

        if hum then
            hum.WalkSpeed = originalWalkSpeed
            hum.JumpPower = originalJumpPower
            hum.JumpHeight = originalJumpHeight
        end
    end

    if player.Character then
        workspace.CurrentCamera.CameraSubject =
            player.Character:FindFirstChildOfClass("Humanoid")
    end

    workspace.CurrentCamera.CameraType =
        originalCamera

    keysDown = {}
    rotating = false
end

--// FreeCam Input
local validKeys = {
    "Enum.KeyCode.W",
    "Enum.KeyCode.A",
    "Enum.KeyCode.S",
    "Enum.KeyCode.D"
}

UserInputService.InputBegan:Connect(function(Input)
    if not freeCamEnabled then
        return
    end

    for _, key in pairs(validKeys) do
        if key == tostring(Input.KeyCode) then
            keysDown[key] = true
        end
    end

    if Input.UserInputType ==
        Enum.UserInputType.MouseButton2
        or (
            Input.UserInputType ==
            Enum.UserInputType.Touch
            and
            UserInputService:GetMouseLocation().X >
            (
                workspace.CurrentCamera.ViewportSize.X / 2
            )
        ) then

        rotating = true
    end

    if Input.UserInputType ==
        Enum.UserInputType.Touch then

        if Input.Position.X <
            workspace.CurrentCamera.ViewportSize.X / 2 then

            touchPos = Input.Position
        end
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if not freeCamEnabled then
        return
    end

    for key in pairs(keysDown) do
        if key == tostring(Input.KeyCode) then
            keysDown[key] = false
        end
    end

    if Input.UserInputType ==
        Enum.UserInputType.MouseButton2
        or (
            Input.UserInputType ==
            Enum.UserInputType.Touch
            and
            UserInputService:GetMouseLocation().X >
            (
                workspace.CurrentCamera.ViewportSize.X / 2
            )
        ) then

        rotating = false
    end

    if Input.UserInputType ==
        Enum.UserInputType.Touch
        and touchPos then

        if Input.Position.X <
            workspace.CurrentCamera.ViewportSize.X / 2 then

            touchPos = nil

            keysDown["Enum.KeyCode.W"] = false
            keysDown["Enum.KeyCode.A"] = false
            keysDown["Enum.KeyCode.S"] = false
            keysDown["Enum.KeyCode.D"] = false
        end
    end
end)

UserInputService.TouchMoved:Connect(function(input)
    if not freeCamEnabled then
        return
    end

    if touchPos then
        if input.Position.X <
            workspace.CurrentCamera.ViewportSize.X / 2 then

            if input.Position.Y < touchPos.Y then
                keysDown["Enum.KeyCode.W"] = true
                keysDown["Enum.KeyCode.S"] = false
            else
                keysDown["Enum.KeyCode.W"] = false
                keysDown["Enum.KeyCode.S"] = true
            end

            if input.Position.X <
                (touchPos.X - 15) then

                keysDown["Enum.KeyCode.A"] = true
                keysDown["Enum.KeyCode.D"] = false

            elseif input.Position.X >
                (touchPos.X + 15) then

                keysDown["Enum.KeyCode.A"] = false
                keysDown["Enum.KeyCode.D"] = true

            else
                keysDown["Enum.KeyCode.A"] = false
                keysDown["Enum.KeyCode.D"] = false
            end
        end
    end
end)

--// GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SiextherByHann.Sxthr"
screenGui.ResetOnSpawn = false
screenGui.Parent = Services.CoreGui

--// MAIN FRAME
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 253)
mainFrame.Position =
    UDim2.new(0.5, -120, 0.5, -143)

mainFrame.BackgroundColor3 =
    Color3.fromRGB(15, 18, 25)

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

--// Minimize
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 26, 0, 26)
minimizeBtn.Position = UDim2.new(1, -60, 0, 6)
minimizeBtn.BackgroundColor3 =
    Color3.fromRGB(60, 120, 200)
minimizeBtn.Text = "–"
minimizeBtn.TextColor3 =
    Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 18
minimizeBtn.ZIndex = 10
minimizeBtn.Parent = mainFrame

local minimizeCorner =
    Instance.new("UICorner", minimizeBtn)

minimizeCorner.CornerRadius = UDim.new(0, 6)

--// Close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -30, 0, 6)
closeBtn.BackgroundColor3 =
    Color3.fromRGB(180, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 =
    Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.ZIndex = 10
closeBtn.Parent = mainFrame

local closeCorner =
    Instance.new("UICorner", closeBtn)

closeCorner.CornerRadius = UDim.new(0, 6)

--// Minimized Button
local minimizedBtn = Instance.new("TextButton")
minimizedBtn.Size = UDim2.new(0, 41, 0, 41)
minimizedBtn.Position = UDim2.new(0, 15, 0, 60)
minimizedBtn.BackgroundColor3 =
    Color3.fromRGB(25, 25, 35)
minimizedBtn.Text = "SX"
minimizedBtn.TextColor3 =
    Color3.fromRGB(70, 130, 255)
minimizedBtn.Font = Enum.Font.GothamBold
minimizedBtn.TextSize = 25
minimizedBtn.Visible = false
minimizedBtn.Active = true
minimizedBtn.Draggable = true
minimizedBtn.Parent = screenGui
minimizedBtn.ZIndex = 5

local MinimizedGradient =
    Instance.new("UIGradient")

MinimizedGradient.Parent = minimizedBtn

MinimizedGradient.Color =
    ColorSequence.new({
        ColorSequenceKeypoint.new(
            0,
            Color3.fromRGB(255, 255, 255)
        ),
        ColorSequenceKeypoint.new(
            0.3,
            Color3.fromRGB(70, 130, 255)
        ),
        ColorSequenceKeypoint.new(
            0.6,
            Color3.fromRGB(70, 130, 255)
        ),
        ColorSequenceKeypoint.new(
            1,
            Color3.fromRGB(255, 255, 255)
        )
    })

MinimizedGradient.Offset =
    Vector2.new(-1, 0)

task.spawn(function()
    while minimizedBtn
        and minimizedBtn.Parent do

        TweenService:Create(
            MinimizedGradient,
            TweenInfo.new(
                2,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut
            ),
            {
                Offset = Vector2.new(1, 0)
            }
        ):Play()

        task.wait(2)

        TweenService:Create(
            MinimizedGradient,
            TweenInfo.new(
                2,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut
            ),
            {
                Offset = Vector2.new(-1, 0)
            }
        ):Play()

        task.wait(2)
    end
end)

local minimizedCorner =
    Instance.new("UICorner", minimizedBtn)

minimizedCorner.CornerRadius = UDim.new(0, 12)

--// Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -95, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "SIEXTHER GLITCH"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 =
    Color3.fromRGB(70, 130, 255)
title.Parent = mainFrame

local TitleGradient =
    Instance.new("UIGradient")

TitleGradient.Parent = title

TitleGradient.Color =
    ColorSequence.new({
        ColorSequenceKeypoint.new(
            0,
            Color3.fromRGB(255, 255, 255)
        ),
        ColorSequenceKeypoint.new(
            0.3,
            Color3.fromRGB(70, 130, 255)
        ),
        ColorSequenceKeypoint.new(
            0.6,
            Color3.fromRGB(70, 130, 255)
        ),
        ColorSequenceKeypoint.new(
            1,
            Color3.fromRGB(255, 255, 255)
        )
    })

TitleGradient.Offset =
    Vector2.new(-1, 0)

task.spawn(function()
    while title and title.Parent do
        TweenService:Create(
            TitleGradient,
            TweenInfo.new(
                2,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut
            ),
            {
                Offset = Vector2.new(1, 0)
            }
        ):Play()

        task.wait(2)

        TweenService:Create(
            TitleGradient,
            TweenInfo.new(
                2,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut
            ),
            {
                Offset = Vector2.new(-1, 0)
            }
        ):Play()

        task.wait(2)
    end
end)

--// Notification
loadstring(
    game:HttpGet(
        "https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/han.lua"
    )
)()

--// Activate / Deactivate
local activateBtn = Instance.new("TextButton")
activateBtn.Size = UDim2.new(1, -20, 0, 35)
activateBtn.Position = UDim2.new(0, 10, 0, 40)
activateBtn.BackgroundColor3 =
    Color3.fromRGB(25, 30, 40)
activateBtn.BorderSizePixel = 0
activateBtn.Text = "AKTIFKAN GLITCH"
activateBtn.TextColor3 =
    Color3.fromRGB(255, 255, 255)
activateBtn.Font = Enum.Font.GothamBold
activateBtn.TextSize = 13
activateBtn.Parent = mainFrame

local activateCorner =
    Instance.new("UICorner", activateBtn)

activateCorner.CornerRadius = UDim.new(0, 7)

--// Speed Container
local speedContainer = Instance.new("Frame")
speedContainer.Size =
    UDim2.new(1, -20, 0, 48)
speedContainer.Position =
    UDim2.new(0, 10, 0, 80)
speedContainer.BackgroundColor3 =
    Color3.fromRGB(25, 30, 40)
speedContainer.BorderSizePixel = 0
speedContainer.Parent = mainFrame

local speedCorner =
    Instance.new("UICorner", speedContainer)

speedCorner.CornerRadius = UDim.new(0, 7)

local speedStroke =
    Instance.new("UIStroke", speedContainer)

speedStroke.Color =
    Color3.fromRGB(70, 130, 255)

speedStroke.Thickness = 1
speedStroke.Transparency = 0.5

local speedLabel = Instance.new("TextLabel")
speedLabel.Size =
    UDim2.new(1, -16, 0, 16)
speedLabel.Position =
    UDim2.new(0, 8, 0, 4)
speedLabel.BackgroundTransparency = 1
speedLabel.Text =
    string.format(
        "SPEED GLITCH: X%.1f",
        Settings["Speed"]
    )
speedLabel.TextColor3 =
    Color3.fromRGB(200, 200, 200)
speedLabel.Font =
    Enum.Font.GothamMedium
speedLabel.TextSize = 11
speedLabel.TextXAlignment =
    Enum.TextXAlignment.Left
speedLabel.Parent = speedContainer

local sliderBar = Instance.new("Frame")
sliderBar.Size =
    UDim2.new(1, -16, 0, 7)
sliderBar.Position =
    UDim2.new(0, 8, 0, 28)
sliderBar.BackgroundColor3 =
    Color3.fromRGB(40, 40, 45)
sliderBar.BorderSizePixel = 0
sliderBar.Parent = speedContainer

local sliderCorner =
    Instance.new("UICorner", sliderBar)

sliderCorner.CornerRadius = UDim.new(1, 0)

local sliderFill = Instance.new("Frame")
sliderFill.Size =
    UDim2.new(0.2, 0, 1, 0)
sliderFill.BackgroundColor3 =
    Color3.fromRGB(70, 130, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBar

local fillCorner =
    Instance.new("UICorner", sliderFill)

fillCorner.CornerRadius = UDim.new(1, 0)

local thumb = Instance.new("Frame")
thumb.Size =
    UDim2.new(0, 14, 0, 14)
thumb.AnchorPoint =
    Vector2.new(0.5, 0.5)
thumb.Position =
    UDim2.new(0.2, 0, 0.5, 0)
thumb.BackgroundColor3 =
    Color3.fromRGB(255, 255, 255)
thumb.BorderSizePixel = 0
thumb.Parent = sliderBar

local thumbCorner =
    Instance.new("UICorner", thumb)

thumbCorner.CornerRadius = UDim.new(1, 0)

local thumbStroke =
    Instance.new("UIStroke", thumb)

thumbStroke.Color =
    Color3.fromRGB(70, 130, 255)

thumbStroke.Thickness = 2

--// TOOLS Divider
local toolsDividerContainer =
    Instance.new("Frame")

toolsDividerContainer.Size =
    UDim2.new(1, -20, 0, 18)

toolsDividerContainer.Position =
    UDim2.new(0, 10, 0, 134)

toolsDividerContainer.BackgroundTransparency = 1
toolsDividerContainer.Parent = mainFrame

local leftLine = Instance.new("Frame")
leftLine.Size =
    UDim2.new(0.25, 0, 0, 1)
leftLine.Position =
    UDim2.new(0, 0, 0.5, 0)
leftLine.BackgroundColor3 =
    Color3.fromRGB(70, 130, 255)
leftLine.BorderSizePixel = 0
leftLine.Parent =
    toolsDividerContainer

local toolsDivider =
    Instance.new("TextLabel")

toolsDivider.Size =
    UDim2.new(0.5, 0, 1, 0)
toolsDivider.Position =
    UDim2.new(0.25, 0, 0, 0)
toolsDivider.BackgroundTransparency = 1
toolsDivider.Text = "TOOLS"
toolsDivider.TextColor3 =
    Color3.fromRGB(70, 130, 255)
toolsDivider.Font =
    Enum.Font.GothamBold
toolsDivider.TextSize = 11
toolsDivider.Parent =
    toolsDividerContainer

local rightLine = Instance.new("Frame")
rightLine.Size =
    UDim2.new(0.25, 0, 0, 1)
rightLine.Position =
    UDim2.new(0.75, 0, 0.5, 0)
rightLine.BackgroundColor3 =
    Color3.fromRGB(70, 130, 255)
rightLine.BorderSizePixel = 0
rightLine.Parent =
    toolsDividerContainer

--// Spin
local spinBtn = Instance.new("TextButton")
spinBtn.Size =
    UDim2.new(0.48, -5, 0, 28)
spinBtn.Position =
    UDim2.new(0, 10, 0, 157)
spinBtn.BackgroundColor3 =
    Color3.fromRGB(25, 30, 40)
spinBtn.BorderSizePixel = 0
spinBtn.Text = "SPIN"
spinBtn.TextColor3 =
    Color3.fromRGB(255, 255, 255)
spinBtn.Font =
    Enum.Font.GothamBold
spinBtn.TextSize = 11
spinBtn.Parent = mainFrame

local spinCorner =
    Instance.new("UICorner", spinBtn)

spinCorner.CornerRadius = UDim.new(0, 7)

--// Swim
local swimBtn = Instance.new("TextButton")
swimBtn.Size =
    UDim2.new(0.48, -5, 0, 28)
swimBtn.Position =
    UDim2.new(0.52, 0, 0, 157)
swimBtn.BackgroundColor3 =
    Color3.fromRGB(25, 30, 40)
swimBtn.BorderSizePixel = 0
swimBtn.Text = "SWIM"
swimBtn.TextColor3 =
    Color3.fromRGB(255, 255, 255)
swimBtn.Font =
    Enum.Font.GothamBold
swimBtn.TextSize = 11
swimBtn.Parent = mainFrame

local swimCorner =
    Instance.new("UICorner", swimBtn)

swimCorner.CornerRadius = UDim.new(0, 7)

--// XNXX
local xnxxBtn = Instance.new("TextButton")
xnxxBtn.Size =
    UDim2.new(0.48, -5, 0, 28)
xnxxBtn.Position =
    UDim2.new(0, 10, 0, 190)
xnxxBtn.BackgroundColor3 =
    Color3.fromRGB(25, 30, 40)
xnxxBtn.BorderSizePixel = 0
xnxxBtn.Text = "XNXX"
xnxxBtn.TextColor3 =
    Color3.fromRGB(255, 255, 255)
xnxxBtn.Font =
    Enum.Font.GothamBold
xnxxBtn.TextSize = 11
xnxxBtn.Parent = mainFrame

local xnxxCorner =
    Instance.new("UICorner", xnxxBtn)

xnxxCorner.CornerRadius = UDim.new(0, 7)

--// Copy Hat
local copyHatBtn = Instance.new("TextButton")
copyHatBtn.Size =
    UDim2.new(0.48, -5, 0, 28)
copyHatBtn.Position =
    UDim2.new(0.52, 0, 0, 190)
copyHatBtn.BackgroundColor3 =
    Color3.fromRGB(25, 30, 40)
copyHatBtn.BorderSizePixel = 0
copyHatBtn.Text = "COPY HAT"
copyHatBtn.TextColor3 =
    Color3.fromRGB(255, 255, 255)
copyHatBtn.Font =
    Enum.Font.GothamBold
copyHatBtn.TextSize = 11
copyHatBtn.Parent = mainFrame

local copyHatCorner =
    Instance.new("UICorner", copyHatBtn)

copyHatCorner.CornerRadius = UDim.new(0, 7)

--// SHUNSHIN
local shunshinBtn = Instance.new("TextButton")
shunshinBtn.Size =
    UDim2.new(0.48, -5, 0, 28)
shunshinBtn.Position =
    UDim2.new(0, 10, 0, 223)
shunshinBtn.BackgroundColor3 =
    Color3.fromRGB(25, 30, 40)
shunshinBtn.BorderSizePixel = 0
shunshinBtn.Text = "SHUNSHIN"
shunshinBtn.TextColor3 =
    Color3.fromRGB(255, 255, 255)
shunshinBtn.Font =
    Enum.Font.GothamBold
shunshinBtn.TextSize = 11
shunshinBtn.Parent = mainFrame

local shunshinCorner =
    Instance.new("UICorner", shunshinBtn)

shunshinCorner.CornerRadius = UDim.new(0, 7)

--// FreeCam
local freeCamBtn = Instance.new("TextButton")
freeCamBtn.Size =
    UDim2.new(0.48, -5, 0, 28)
freeCamBtn.Position =
    UDim2.new(0.52, 0, 0, 223)
freeCamBtn.BackgroundColor3 =
    Color3.fromRGB(25, 30, 40)
freeCamBtn.BorderSizePixel = 0
freeCamBtn.Text = "FREECAM"
freeCamBtn.TextColor3 =
    Color3.fromRGB(255, 255, 255)
freeCamBtn.Font =
    Enum.Font.GothamBold
freeCamBtn.TextSize = 11
freeCamBtn.Parent = mainFrame

local freeCamCorner =
    Instance.new("UICorner", freeCamBtn)

freeCamCorner.CornerRadius = UDim.new(0, 7)

--// Shunshin Helper
local function stopJumpAnimations(hum)
    if not hum then
        return
    end

    for _, track in ipairs(
        hum:GetPlayingAnimationTracks()
    ) do

        local name =
            string.lower(track.Name)

        if string.find(name, "jump")
            or string.find(name, "fall")
            or string.find(name, "freefall") then

            track:Stop(0)
        end
    end
end

--// Stop Shunshin
local function stopShunshin()
    shunshinActive = false
    shunshinLoop = false

    if shunshinBtn
        and shunshinBtn.Parent then

        shunshinBtn.Text = "SHUNSHIN"
        shunshinBtn.BackgroundColor3 =
            Color3.fromRGB(25, 30, 40)
    end
end

--// Start Shunshin
local function startShunshin()
    if shunshinActive then
        return
    end

    if not isGlitchActive then
        if getgenv().Notify then
            getgenv().Notify({
                Title = "TERJADI KESALAHAN",
                Content =
                    "AKTIFKAN GLITCH TERLEBIH DAHULU!",
                Duration = 2
            })
        end

        return
    end

    shunshinActive = true
    shunshinLoop = true

    shunshinBtn.Text = "SHUNSHIN"
    shunshinBtn.BackgroundColor3 =
        Color3.fromRGB(70, 130, 255)

    task.spawn(function()
        while shunshinLoop
            and shunshinActive
            and isGlitchActive do

            task.wait(0.1)

            if not (
                shunshinLoop
                and shunshinActive
                and isGlitchActive
            ) then
                break
            end

            local currentCharacter =
                player.Character

            local currentHumanoid =
                currentCharacter
                and
                currentCharacter:FindFirstChildOfClass(
                    "Humanoid"
                )

            local root =
                currentCharacter
                and
                currentCharacter:FindFirstChild(
                    "HumanoidRootPart"
                )

            if currentHumanoid
                and root
                and currentHumanoid.Health > 0 then

                stopJumpAnimations(currentHumanoid)

                local targets = {}

                for _, targetPlayer in ipairs(
                    Players:GetPlayers()
                ) do

                    if targetPlayer ~= player then
                        local targetCharacter =
                            targetPlayer.Character

                        local targetRoot =
                            targetCharacter
                            and
                            targetCharacter:FindFirstChild(
                                "HumanoidRootPart"
                            )

                        local targetHumanoid =
                            targetCharacter
                            and
                            targetCharacter:FindFirstChildOfClass(
                                "Humanoid"
                            )

                        if targetRoot
                            and targetHumanoid
                            and targetHumanoid.Health > 0 then

                            table.insert(
                                targets,
                                targetPlayer
                            )
                        end
                    end
                end

                if #targets > 0 then
                    local target =
                        targets[
                            math.random(
                                1,
                                #targets
                            )
                        ]

                    local targetCharacter =
                        target.Character

                    local targetRoot =
                        targetCharacter
                        and
                        targetCharacter:FindFirstChild(
                            "HumanoidRootPart"
                        )

                    if targetRoot then

                        root.AssemblyLinearVelocity =
                            Vector3.zero

                        root.AssemblyAngularVelocity =
                            Vector3.zero

                        currentHumanoid:ChangeState(
                            Enum.HumanoidStateType.Running
                        )

                        root.CFrame =
                            targetRoot.CFrame *
                            CFrame.new(0, 2.5, 0)

                        root.AssemblyLinearVelocity =
                            Vector3.zero

                        root.AssemblyAngularVelocity =
                            Vector3.zero

                        stopJumpAnimations(
                            currentHumanoid
                        )

                        currentHumanoid:ChangeState(
                            Enum.HumanoidStateType.Running
                        )
                    end
                end
            end
        end

        shunshinActive = false
        shunshinLoop = false

        if shunshinBtn
            and shunshinBtn.Parent then

            shunshinBtn.Text = "SHUNSHIN"
            shunshinBtn.BackgroundColor3 =
                Color3.fromRGB(25, 30, 40)
        end
    end)
end

--// Shunshin Button
shunshinBtn.MouseButton1Click:Connect(function()
    if not isGlitchActive then
        if getgenv().Notify then
            getgenv().Notify({
                Title = "TERJADI KESALAHAN",
                Content =
                    "AKTIFKAN GLITCH TERLEBIH DAHULU!",
                Duration = 2
            })
        end

        return
    end

    if shunshinActive then
        stopShunshin()

        if getgenv().Notify then
            getgenv().Notify({
                Title = "SHUNSHIN NO JUTSU",
                Content =
                    "SHUNSHIN TELAH DIMATIKAN!",
                Duration = 2
            })
        end
    else
        startShunshin()

        if getgenv().Notify then
            getgenv().Notify({
                Title = "SHUNSHIN NO JUTSU",
                Content =
                    "SHUNSHIN TELAH DIAKTIFKAN!",
                Duration = 2
            })
        end
    end
end)

--// Glitch Button
activateBtn.MouseButton1Click:Connect(function()

    if not isGlitchActive then

        LoadTrack(EMOTE_ID)

        activateBtn.Text =
            "MATIKAN GLITCH"

        activateBtn.BackgroundColor3 =
            Color3.fromRGB(70, 130, 255)

        isGlitchActive = true

        if getgenv().Notify then
            getgenv().Notify({
                Title = "SIEXTHER GLITCH",
                Content =
                    "GLITCH TELAH DIAKTIFKAN!",
                Duration = 2
            })
        end

    else

        StopTrack()

        -- Shunshin otomatis mati
        stopShunshin()

        activateBtn.Text =
            "AKTIFKAN GLITCH"

        activateBtn.BackgroundColor3 =
            Color3.fromRGB(25, 30, 40)

        isGlitchActive = false

        if getgenv().Notify then
            getgenv().Notify({
                Title = "SIEXTHER GLITCH",
                Content =
                    "GLITCH TELAH DIMATIKAN!",
                Duration = 2
            })
        end
    end
end)

--// Speed Slider
local function updateSpeedSlider(value)
    Settings["Speed"] = value

    speedLabel.Text =
        string.format(
            "SPEED GLITCH: X%.1f",
            value
        )

    local rel =
        math.clamp(
            value / 10,
            0,
            1
        )

    TweenService:Create(
        sliderFill,
        TweenInfo.new(0.15),
        {
            Size =
                UDim2.new(
                    rel,
                    0,
                    1,
                    0
                )
        }
    ):Play()

    TweenService:Create(
        thumb,
        TweenInfo.new(0.15),
        {
            Position =
                UDim2.new(
                    rel,
                    0,
                    0.5,
                    0
                )
        }
    ):Play()

    if CurrentTrack
        and CurrentTrack.IsPlaying then

        CurrentTrack:AdjustSpeed(
            Settings["Speed"]
        )
    end
end

local dragging = false

local function updateFromInput(input)
    local relX =
        math.clamp(
            (
                input.Position.X -
                sliderBar.AbsolutePosition.X
            ) /
            sliderBar.AbsoluteSize.X,
            0,
            1
        )

    local value =
        math.floor(
            (10 * relX) * 10
        ) / 10

    updateSpeedSlider(value)
end

sliderBar.InputBegan:Connect(function(input)
    if input.UserInputType ==
        Enum.UserInputType.MouseButton1
        or
        input.UserInputType ==
        Enum.UserInputType.Touch then

        dragging = true
        updateFromInput(input)
    end
end)

thumb.InputBegan:Connect(function(input)
    if input.UserInputType ==
        Enum.UserInputType.MouseButton1
        or
        input.UserInputType ==
        Enum.UserInputType.Touch then

        dragging = true
        updateFromInput(input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging
        and (
            input.UserInputType ==
                Enum.UserInputType.MouseMovement
            or
            input.UserInputType ==
                Enum.UserInputType.Touch
        ) then

        updateFromInput(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if dragging
        and (
            input.UserInputType ==
                Enum.UserInputType.MouseButton1
            or
            input.UserInputType ==
                Enum.UserInputType.Touch
        ) then

        dragging = false
    end
end)

--// Spin
local isSpinning = false
local spinConnection

spinBtn.MouseButton1Click:Connect(function()

    if not isSpinning then

        isSpinning = true

        spinBtn.BackgroundColor3 =
            Color3.fromRGB(70, 130, 255)

        spinConnection =
            RunService.RenderStepped:Connect(
                function()
                    if character
                        and character.PrimaryPart then

                        character.PrimaryPart.CFrame =
                            character.PrimaryPart.CFrame *
                            CFrame.Angles(
                                0,
                                math.rad(40),
                                0
                            )
                    end
                end
            )

    else

        isSpinning = false

        spinBtn.BackgroundColor3 =
            Color3.fromRGB(25, 30, 40)

        if spinConnection then
            spinConnection:Disconnect()
            spinConnection = nil
        end
    end
end)

--// Swimming
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
                gravReset = nil
            end

            if swimbeat then
                swimbeat:Disconnect()
                swimbeat = nil
            end

            local enums =
                Enum.HumanoidStateType:GetEnumItems()

            local none =
                table.find(
                    enums,
                    Enum.HumanoidStateType.None
                )

            if none then
                table.remove(enums, none)
            end

            for _, v in pairs(enums) do
                humanoid:SetStateEnabled(
                    v,
                    true
                )
            end
        end

        gravReset =
            humanoid.Died:Connect(
                swimDied
            )

        local enums =
            Enum.HumanoidStateType:GetEnumItems()

        local none =
            table.find(
                enums,
                Enum.HumanoidStateType.None
            )

        if none then
            table.remove(enums, none)
        end

        for _, v in pairs(enums) do
            humanoid:SetStateEnabled(
                v,
                false
            )
        end

        humanoid:ChangeState(
            Enum.HumanoidStateType.Swimming
        )

        swimbeat =
            RunService.Heartbeat:Connect(
                function()
                    pcall(function()

                        if character
                            and character:FindFirstChild(
                                "HumanoidRootPart"
                            ) then

                            local rootPart =
                                character.HumanoidRootPart

                            if humanoid.MoveDirection
                                ~= Vector3.new() then

                                rootPart.Velocity =
                                    Vector3.new(
                                        0,
                                        10,
                                        0
                                    )
                            else

                                rootPart.Velocity =
                                    Vector3.zero
                            end
                        end
                    end)
                end
            )

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

        local enums =
            Enum.HumanoidStateType:GetEnumItems()

        local none =
            table.find(
                enums,
                Enum.HumanoidStateType.None
            )

        if none then
            table.remove(enums, none)
        end

        for _, v in pairs(enums) do
            humanoid:SetStateEnabled(
                v,
                true
            )
        end
    end
end

swimBtn.MouseButton1Click:Connect(function()

    if swimming then

        stopSwimming()

        swimBtn.BackgroundColor3 =
            Color3.fromRGB(25, 30, 40)

    else

        startSwimming()

        swimBtn.BackgroundColor3 =
            Color3.fromRGB(70, 130, 255)
    end
end)

--// FreeCam Button
freeCamBtn.MouseButton1Click:Connect(function()
    loadstring(
        game:HttpGet(
            "https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/2.lua"
        )
    )()
end)

--// Copy Hat
copyHatBtn.MouseButton1Click:Connect(function()
    loadstring(
        game:HttpGet(
            "https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/cc.lua"
        )
    )()
end)

--// XNXX
local xnxxActive = false
local xnxxTrack = nil
local xnxxCollisionConnection = nil
local xnxxOriginalCollisionStates = {}

local XnxxSettings = {}

XnxxSettings["Stop On Move"] = false
XnxxSettings["Fade In"] = 0.1
XnxxSettings["Fade Out"] = 0.1
XnxxSettings["Weight"] = 1
XnxxSettings["Speed"] = 1
XnxxSettings["Allow Invisible"] = true
XnxxSettings["Time Position"] = 0

local function LoadXnxxTrack(id)

    if xnxxTrack then
        xnxxTrack:Stop(0)
    end

    local animId

    local ok, result =
        pcall(function()
            return game:GetObjects(
                "rbxassetid://" ..
                tostring(id)
            )
        end)

    if ok
        and result
        and #result > 0 then

        local anim = result[1]

        if anim:IsA("Animation") then
            animId = anim.AnimationId
        else
            animId =
                "rbxassetid://" ..
                tostring(id)
        end

    else

        animId =
            "rbxassetid://" ..
            tostring(id)
    end

    local newAnim =
        Instance.new("Animation")

    newAnim.AnimationId = animId

    local newTrack =
        humanoid:LoadAnimation(
            newAnim
        )

    newTrack.Priority =
        Enum.AnimationPriority.Action4

    local weight =
        XnxxSettings["Weight"]

    if weight == 0 then
        weight = 0.001
    end

    newTrack:Play(
        XnxxSettings["Fade In"],
        weight,
        XnxxSettings["Speed"]
    )

    xnxxTrack = newTrack

    xnxxTrack.TimePosition =
        math.clamp(
            XnxxSettings["Time Position"],
            0,
            1
        ) *
        xnxxTrack.Length

    return newTrack
end

local function saveXnxxCollisionStates()

    xnxxOriginalCollisionStates = {}

    local humanoidRootPart =
        character:FindFirstChild(
            "HumanoidRootPart"
        )

    for _, part in ipairs(
        character:GetDescendants()
    ) do

        if part:IsA("BasePart")
            and part ~= humanoidRootPart then

            xnxxOriginalCollisionStates[part] =
                part.CanCollide
        end
    end
end

local function disableXnxxCollisionsExceptRootPart()

    if not XnxxSettings["Allow Invisible"] then
        return
    end

    local humanoidRootPart =
        character:FindFirstChild(
            "HumanoidRootPart"
        )

    for _, part in ipairs(
        character:GetDescendants()
    ) do

        if part:IsA("BasePart")
            and part ~= humanoidRootPart then

            part.CanCollide = false
        end
    end
end

local function restoreXnxxCollisions()

    for part, state in pairs(
        xnxxOriginalCollisionStates
    ) do

        if part and part.Parent then
            part.CanCollide = state
        end
    end
end

local function startXnxx()

    saveXnxxCollisionStates()

    task.wait(1)

    if not isGlitchActive then
        return
    end

    xnxxTrack =
        LoadXnxxTrack(
            116241168989348
        )

    xnxxCollisionConnection =
        RunService.Stepped:Connect(
            function()

                if character
                    and character.Parent
                    and XnxxSettings[
                        "Allow Invisible"
                    ] then

                    disableXnxxCollisionsExceptRootPart()
                end
            end
        )

    xnxxActive = true
end

local function stopXnxx()

    if xnxxTrack then
        xnxxTrack:Stop(0)
        xnxxTrack = nil
    end

    if xnxxCollisionConnection then
        xnxxCollisionConnection:Disconnect()
        xnxxCollisionConnection = nil
    end

    restoreXnxxCollisions()

    xnxxActive = false
end

xnxxBtn.MouseButton1Click:Connect(function()

    if not isGlitchActive then

        if getgenv().Notify then
            getgenv().Notify({
                Title =
                    "TERJADI KESALAHAN",
                Content =
                    "AKTIFKAN GLITCH TERLEBIH DAHULU!",
                Duration = 2
            })
        end

        return
    end

    if not xnxxActive then

        startXnxx()

        xnxxBtn.BackgroundColor3 =
            Color3.fromRGB(
                70,
                130,
                255
            )

        if getgenv().Notify then
            getgenv().Notify({
                Title = "XNXX",
                Content =
                    "XNXX TELAH DIAKTIFKAN!",
                Duration = 2
            })
        end

    else

        stopXnxx()

        xnxxBtn.BackgroundColor3 =
            Color3.fromRGB(
                25,
                30,
                40
            )

        if getgenv().Notify then
            getgenv().Notify({
                Title = "XNXX",
                Content =
                    "XNXX TELAH DIMATIKAN!",
                Duration = 2
            })
        end
    end
end)

--// Map Button
local function updateCopyHatButton()

    if isInCorrectMap() then

        copyHatBtn.BackgroundColor3 =
            Color3.fromRGB(
                25,
                30,
                40
            )

        copyHatBtn.TextColor3 =
            Color3.fromRGB(
                255,
                255,
                255
            )

    else

        copyHatBtn.BackgroundColor3 =
            Color3.fromRGB(
                25,
                30,
                40
            )

        copyHatBtn.TextColor3 =
            Color3.fromRGB(
                255,
                255,
                255
            )
    end
end

updateCopyHatButton()

--// Minimize / Maximize
minimizeBtn.MouseButton1Click:Connect(function()

    mainFrame.Visible = false
    minimizedBtn.Visible = true
end)

minimizedBtn.MouseButton1Click:Connect(function()

    mainFrame.Visible = true
    minimizedBtn.Visible = false

    mainFrame.Size =
        UDim2.new(0, 0, 0, 0)

    mainFrame.Position =
        UDim2.new(0.5, 0, 0.3, 0)

    mainFrame.BackgroundTransparency = 1

    SmoothTween(
        mainFrame,
        0.5,
        {
            Size =
                UDim2.new(
                    0,
                    240,
                    0,
                    253
                ),

            Position =
                UDim2.new(
                    0.5,
                    -120,
                    0.5,
                    -143
                ),

            BackgroundTransparency = 0
        }
    )
end)

--// Close
closeBtn.MouseButton1Click:Connect(function()

    StopTrack()

    stopShunshin()

    if spinConnection then
        spinConnection:Disconnect()
        spinConnection = nil
    end

    stopSwimming()

    if freeCamEnabled then
        disableFreeCam()
    end

    if xnxxActive then
        stopXnxx()
    end

    screenGui:Destroy()
end)

--// Position Update
RunService.RenderStepped:Connect(function()

    if character
        and character.PrimaryPart then

        lastPosition =
            character.PrimaryPart.Position
    end
end)

--// Character Respawn
player.CharacterAdded:Connect(function(newChar)

    character = newChar

    humanoid =
        character:WaitForChild(
            "Humanoid"
        )

    if freeCamEnabled then

        task.wait(0.1)

        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.JumpHeight = 0
    end

    if xnxxActive then

        task.wait(0.1)

        saveXnxxCollisionStates()

        task.wait(1)

        if xnxxActive
            and isGlitchActive then

            xnxxTrack =
                LoadXnxxTrack(
                    116241168989348
                )
        end
    end
end)