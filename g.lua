local Screen = setmetatable({}, {
__index = function(_, key)
    local cam = workspace.CurrentCamera
    local size = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    if key == "Width" then
        return size.X
    elseif key == "Height" then
        return size.Y
    elseif key == "Size" then
        return size
    end
end})

function scale(axis, value)
    if axis == "X" then
        return value * (Screen.Width / 1920) * 1.5
    elseif axis == "Y" then
        return value * (Screen.Height / 1080) * 1.5
    end
end

-- Services setup
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
local AvatarEditorService = Services.AvatarEditorService
local HttpService = Services.HttpService

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local lastPosition = character.PrimaryPart and character.PrimaryPart.Position or Vector3.new()

player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
    lastPosition = character.PrimaryPart and character.PrimaryPart.Position or Vector3.new()
end)

-- Settings
local Settings = _G
Settings["Stop On Move"] = false
Settings["Fade In"] = 0.1
Settings["Fade Out"] = 0.1
Settings["Weight"] = 1
Settings["Speed"] = 1
Settings["Allow Invisible"] = true
Settings["Time Position"] = 0

-- Saved emotes data
local savedEmotes = {}
local SAVE_FILE = "SiextherEmote.json"

local function loadSavedEmotes()
    local success, data = pcall(function()
        if readfile and isfile and isfile(SAVE_FILE) then
            return HttpService:JSONDecode(readfile(SAVE_FILE))
        end
        return {}
    end)
    if success then
        savedEmotes = data
    else
        savedEmotes = {}
    end
end

local function saveEmotesToData()
    pcall(function()
        if writefile then
            writefile(SAVE_FILE, HttpService:JSONEncode(savedEmotes))
        end
    end)
end

loadSavedEmotes()

-- Animation track management
local CurrentTrack = nil

local function LoadTrack(id)
    if CurrentTrack then
        CurrentTrack:Stop(Settings["Fade Out"])
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

    local weight = Settings["Weight"]
    if weight == 0 then weight = 0.001 end

    newTrack:Play(Settings["Fade In"], weight, Settings["Speed"])
    CurrentTrack = newTrack
    CurrentTrack.TimePosition = math.clamp(Settings["Time Position"], 0, 1) * CurrentTrack.Length

    return newTrack
end

-- Stop on move functionality
RunService.RenderStepped:Connect(function()
    if character.PrimaryPart then
        if Settings["Stop On Move"] and CurrentTrack and CurrentTrack.IsPlaying then
            local moved = (character.PrimaryPart.Position - lastPosition).Magnitude > 0.1
            local jumped = humanoid and humanoid:GetState() == Enum.HumanoidStateType.Jumping

            if moved or jumped then
                CurrentTrack:Stop(Settings["Fade Out"])
                CurrentTrack = nil
            end
        end
        lastPosition = character.PrimaryPart.Position
    end
end)

-- === GUI ===
local CoreGui = Services.CoreGui
local gui = Instance.new("ScreenGui")
gui.Name = "HannSiexther Emote"
gui.Parent = CoreGui
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local function createGradient(parent, colorSequence)
    return
end

local function createCorner(parent, cornerRadius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, cornerRadius)
    corner.Parent = parent
    return corner
end

-- Helper function to add stroke
local function createStroke(parent, thickness, color)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 2
    stroke.Color = color or Color3.fromRGB(70, 130, 255)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

-- Minimize Ball (Bola Putih Kecil dengan Emoji)
local minimizeBall = Instance.new("TextButton")
minimizeBall.Name = "MinimizeBall"
minimizeBall.Size = UDim2.new(0, 70, 0, 70)
minimizeBall.Position = UDim2.new(0.9, -scale("X", 30), 0.1, 0)
minimizeBall.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
minimizeBall.Text = "💃"
minimizeBall.TextSize = 20
minimizeBall.Font = Enum.Font.GothamBold
minimizeBall.TextColor3 = Color3.fromRGB(70, 130, 255)
minimizeBall.Visible = false
minimizeBall.Active = true
minimizeBall.Draggable = true
minimizeBall.Parent = gui
minimizeBall.ZIndex = 999

createCorner(minimizeBall, 12)

-- Main container frame
local mainContainer = Instance.new("Frame")
mainContainer.Size = UDim2.new(0, scale("X", 600), 0, scale("Y", 400))
mainContainer.Position = UDim2.new(0.5, -scale("X", 300), 0.5, -scale("Y", 200))
mainContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainContainer.Active = true
mainContainer.Draggable = true
mainContainer.Parent = gui

createCorner(mainContainer, 12)
createStroke(mainContainer, 2, Color3.fromRGB(70, 130, 255))

-- Store original size untuk minimize
local originalSize = mainContainer.Size

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, scale("Y", 36))
title.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
title.Text = "SIEXTHER EMOTE"
title.TextColor3 = Color3.fromRGB(70, 130, 255)
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.Parent = mainContainer

createCorner(title, 8)

-- Close Button (X)
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, scale("X", 30), 0, scale("Y", 30))
closeBtn.Position = UDim2.new(1, -scale("X", 36), 0, scale("Y", 3))
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "X"
closeBtn.Parent = title
createCorner(closeBtn, 4)


-- Minimize Button (−)
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeButton"
minimizeBtn.Size = UDim2.new(0, scale("X", 30), 0, scale("Y", 30))
minimizeBtn.Position = UDim2.new(1, -scale("X", 72), 0, scale("Y", 3))
minimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
minimizeBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
minimizeBtn.TextScaled = true
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.Text = "−"
minimizeBtn.Parent = title
createCorner(minimizeBtn, 4)



-- State untuk minimize
local isMinimized = false

-- Close button functionality
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Minimize button functionality
minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = true
    
    mainContainer.Visible = false
    
    minimizeBall.Visible = true
    minimizeBall.Size = UDim2.new(0, 0, 0, 0)
    
    local openTween = TweenService:Create(
        minimizeBall,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, scale("X", 60), 0, scale("Y", 60))}
    )
    openTween:Play()
end)

-- Minimize ball click functionality
minimizeBall.MouseButton1Click:Connect(function()
    isMinimized = false
    
    local closeTween = TweenService:Create(
        minimizeBall,
        TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Size = UDim2.new(0, 0, 0, 0)}
    )
    
    closeTween.Completed:Connect(function()
        minimizeBall.Visible = false
        
        mainContainer.Visible = true
        mainContainer.Size = UDim2.new(0, 0, 0, 0)
        
        local expandTween = TweenService:Create(
            mainContainer,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = originalSize}
        )
        expandTween:Play()
    end)
    
    closeTween:Play()
end)

-- Tab buttons
local catalogTabBtn = Instance.new("TextButton")
catalogTabBtn.Size = UDim2.new(0.3, 0, 0, scale("Y", 24))
catalogTabBtn.Position = UDim2.new(0.05, 0, 0, scale("Y", 40))
catalogTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
catalogTabBtn.Text = "Catalog"
catalogTabBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
catalogTabBtn.Font = Enum.Font.GothamBold
catalogTabBtn.TextScaled = true
catalogTabBtn.Parent = mainContainer
createCorner(catalogTabBtn, 6)
createStroke(catalogTabBtn, 2, Color3.fromRGB(70, 130, 255))

local savedTabBtn = Instance.new("TextButton")
savedTabBtn.Size = UDim2.new(0.3, 0, 0, scale("Y", 24))
savedTabBtn.Position = UDim2.new(0.35, 0, 0, scale("Y", 40))
savedTabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
savedTabBtn.Text = "Saved"
savedTabBtn.TextColor3 = Color3.new(0.8, 0.8, 0.8)
savedTabBtn.Font = Enum.Font.GothamBold
savedTabBtn.TextScaled = true
savedTabBtn.Parent = mainContainer
createCorner(savedTabBtn, 6)
createStroke(savedTabBtn, 2, Color3.fromRGB(50, 50, 60))

-- Divider
local divider = Instance.new("Frame")
divider.Size = UDim2.new(0, scale("X", 2), 1, -scale("Y", 70))
divider.Position = UDim2.new(0.6, -scale("X", 1), 0, scale("Y", 70))
divider.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
divider.Parent = mainContainer
createCorner(divider, 1)

-- Catalog section
local catalogFrame = Instance.new("Frame")
catalogFrame.Size = UDim2.new(0.6, -scale("X", 10), 1, -scale("Y", 70))
catalogFrame.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 70))
catalogFrame.BackgroundTransparency = 1
catalogFrame.Visible = true
catalogFrame.Parent = mainContainer

-- Search box
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(0.6, -scale("X", 8), 0, scale("Y", 28))
searchBox.Position = UDim2.new(0, scale("X", 8), 0, 0)
searchBox.PlaceholderText = "Search..."
searchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
searchBox.TextColor3 = Color3.new(1, 1, 1)
searchBox.Font = Enum.Font.Gotham
searchBox.TextScaled = true
searchBox.ClearTextOnFocus = false
searchBox.Parent = catalogFrame

createCorner(searchBox, 6)

-- Search button
local searchBtn = Instance.new("TextButton")
searchBtn.Size = UDim2.new(0.2, -scale("X", 4), 0, scale("Y", 28))
searchBtn.Position = UDim2.new(0.6, scale("X", 4), 0, 0)
searchBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
searchBtn.Text = "Search"
searchBtn.Font = Enum.Font.GothamBold
searchBtn.TextScaled = true
searchBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
searchBtn.Parent = catalogFrame

createCorner(searchBtn, 6)


-- Sort button
local sortBtn = Instance.new("TextButton")
sortBtn.Size = UDim2.new(0.2, -scale("X", 8), 0, scale("Y", 28))
sortBtn.Position = UDim2.new(0.8, scale("X", 4), 0, 0)
sortBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
sortBtn.Text = "Sort: Relevance"
sortBtn.Font = Enum.Font.GothamBold
sortBtn.TextScaled = true
sortBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
sortBtn.Parent = catalogFrame

createCorner(sortBtn, 6)


-- Scroll frame for catalog items
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -scale("X", 16), 1, -scale("Y", 100))
scroll.Position = UDim2.new(0, scale("X", 8), 0, scale("Y", 36))
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 6
scroll.BackgroundTransparency = 1
scroll.Parent = catalogFrame

-- Empty results label
local emptyLabel = Instance.new("TextLabel")
emptyLabel.Size = UDim2.new(1, 0, 0, scale("Y", 36))
emptyLabel.Position = UDim2.new(0, 0, 0.5, -scale("Y", 18))
emptyLabel.BackgroundTransparency = 1
emptyLabel.Text = "Nothing Silly Here :3 (except me)"
emptyLabel.TextColor3 = Color3.fromRGB(70, 130, 255)
emptyLabel.Font = Enum.Font.GothamBold
emptyLabel.TextScaled = true
emptyLabel.Visible = false
emptyLabel.Parent = scroll

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.new(0, scale("X", 120), 0, scale("Y", 180))
layout.CellPadding = UDim2.new(0, scale("X", 8), 0, scale("Y", 8))
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = scroll

-- Navigation buttons
local prevBtn = Instance.new("TextButton")
prevBtn.Size = UDim2.new(0.4, -scale("X", 6), 0, scale("Y", 32))
prevBtn.Position = UDim2.new(0, scale("X", 4), 1, -scale("Y", 36))
prevBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
prevBtn.Text = "< Prev"
prevBtn.Font = Enum.Font.GothamBold
prevBtn.TextScaled = true
prevBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
prevBtn.Parent = catalogFrame

createCorner(prevBtn, 6)


local nextBtn = Instance.new("TextButton")
nextBtn.Size = UDim2.new(0.4, -scale("X", 6), 0, scale("Y", 32))
nextBtn.Position = UDim2.new(0.6, scale("X", 2), 1, -scale("Y", 36))
nextBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
nextBtn.Text = "Next >"
nextBtn.Font = Enum.Font.GothamBold
nextBtn.TextScaled = true
nextBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
nextBtn.Parent = catalogFrame

createCorner(nextBtn, 6)

-- Page label
local pageLabel = Instance.new("TextLabel")
pageLabel.Size = UDim2.new(0.2, 0, 0, scale("Y", 32))
pageLabel.Position = UDim2.new(0.4, scale("X", 2), 1, -scale("Y", 36))
pageLabel.BackgroundTransparency = 1
pageLabel.Font = Enum.Font.Gotham
pageLabel.TextScaled = true
pageLabel.TextColor3 = Color3.fromRGB(70, 130, 255)
pageLabel.Text = "Page 1"
pageLabel.Parent = catalogFrame

-- Saved section
local savedFrame = Instance.new("Frame")
savedFrame.Size = UDim2.new(0.6, -scale("X", 10), 1, -scale("Y", 70))
savedFrame.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 70))
savedFrame.BackgroundTransparency = 1
savedFrame.Visible = false
savedFrame.Parent = mainContainer

-- Saved scroll frame
local savedScroll = Instance.new("ScrollingFrame")
savedScroll.Size = UDim2.new(1, -scale("X", 16), 1, -scale("Y", 40))
savedScroll.Position = UDim2.new(0, scale("X", 8), 0, 0)
savedScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
savedScroll.ScrollBarThickness = 0
savedScroll.BackgroundTransparency = 1
savedScroll.Parent = savedFrame

-- Saved empty label
local savedEmptyLabel = Instance.new("TextLabel")
savedEmptyLabel.Size = UDim2.new(1, 0, 0, scale("Y", 36))
savedEmptyLabel.Position = UDim2.new(0, 0, 0.5, -scale("Y", 18))
savedEmptyLabel.BackgroundTransparency = 1
savedEmptyLabel.Text = "No saved emotes yet!"
savedEmptyLabel.TextColor3 = Color3.fromRGB(70, 130, 255)
savedEmptyLabel.Font = Enum.Font.GothamBold
savedEmptyLabel.TextScaled = true
savedEmptyLabel.Visible = false
savedEmptyLabel.Parent = savedScroll

local savedLayout = Instance.new("UIGridLayout")
savedLayout.CellSize = UDim2.new(0, scale("X", 120), 0, scale("Y", 180))
savedLayout.CellPadding = UDim2.new(0, scale("X", 8), 0, scale("Y", 8))
savedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
savedLayout.Parent = savedScroll

-- Settings section
local settingsFrame = Instance.new("Frame")
settingsFrame.Size = UDim2.new(0.4, -scale("X", 10), 1, -scale("Y", 70))
settingsFrame.Position = UDim2.new(0.6, scale("X", 5), 0, scale("Y", 70))
settingsFrame.BackgroundTransparency = 1
settingsFrame.Parent = mainContainer

-- Settings title
local settingsTitle = Instance.new("TextLabel")
settingsTitle.Size = UDim2.new(1, 0, 0, scale("Y", 28))
settingsTitle.BackgroundTransparency = 1
settingsTitle.Text = "Settings"
settingsTitle.TextColor3 = Color3.fromRGB(70, 130, 255)
settingsTitle.Font = Enum.Font.GothamBold
settingsTitle.TextScaled = true
settingsTitle.Parent = settingsFrame

-- Settings scroll frame
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -scale("X", 20), 1, -scale("Y", 40))
scrollFrame.Position = UDim2.new(0, scale("X", 10), 0, scale("Y", 30))
scrollFrame.BackgroundTransparency = 1
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = settingsFrame

local function lockX()
    scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.CanvasPosition.Y)
end
scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(lockX)

local listLayout = Instance.new("UIListLayout", scrollFrame)
listLayout.Padding = UDim.new(0, 6)
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

-- Slider creator function
local function createSlider(name, min, max, default)
    Settings[name] = default or min

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, scale("Y", 65))
    container.BackgroundTransparency = 1
    container.Parent = scrollFrame

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    bg.Parent = container
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)
    

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, -scale("X", 10), 0, scale("Y", 20))
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = string.format("%s: %.2f", name, Settings[name])
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = bg

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0.5, -scale("X", 20), 0, scale("Y", 20))
    textBox.Position = UDim2.new(0.5, scale("X", 10), 0, scale("Y", 5))
    textBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    textBox.Text = tostring(Settings[name])
    textBox.TextColor3 = Color3.new(1, 1, 1)
    textBox.Font = Enum.Font.Gotham
    textBox.TextScaled = true
    textBox.ClearTextOnFocus = false
    textBox.Parent = bg
    Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 6)

    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(1, -scale("X", 40), 0, scale("Y", 12))
    sliderBar.Position = UDim2.new(0, scale("X", 20), 0, scale("Y", 35))
    sliderBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    sliderBar.Parent = bg
    Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(0, 6)

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(0, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    sliderFill.Parent = sliderBar
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 6)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, scale("X", 20), 0, scale("Y", 20))
    thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    thumb.Position = UDim2.new(0, 0, 0.5, 0)
    thumb.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    thumb.Parent = sliderBar
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    local function tweenVisual(rel)
        local visualRel = math.clamp(rel, 0, 1)
        TweenService:Create(sliderFill, TweenInfo.new(0.15), {Size = UDim2.new(visualRel, 0, 1, 0)}):Play()
        TweenService:Create(thumb, TweenInfo.new(0.15), {Position = UDim2.new(visualRel, 0, 0.5, 0)}):Play()
    end

    local function applyValue(value)
        Settings[name] = value
        label.Text = string.format("%s: %.2f", name, value)
        textBox.Text = tostring(value)

        local visualValue = math.clamp(value, min, max)
        local rel = (visualValue - min) / (max - min)
        tweenVisual(rel)

        if CurrentTrack and CurrentTrack.IsPlaying then
            if name == "Speed" then
                CurrentTrack:AdjustSpeed(Settings["Speed"])
            elseif name == "Weight" then
                local weight = Settings["Weight"]
                if weight == 0 then weight = 0.001 end
                CurrentTrack:AdjustWeight(weight)
            elseif name == "Time Position" then
                if CurrentTrack and CurrentTrack.IsPlaying and CurrentTrack.Length > 0 then
                    CurrentTrack.TimePosition = math.clamp(value, 0, 1) * CurrentTrack.Length
                end
            end
        end
    end

    local dragging = false
    local function updateFromInput(input)
        local relX = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
        local value = math.floor((min + (max - min) * relX) * 100) / 100
        applyValue(value)
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

    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local num = tonumber(textBox.Text)
            if num then
                applyValue(num)
            else
                textBox.Text = tostring(Settings[name])
            end
        end
    end)

    applyValue(Settings[name])
end

-- Toggle creator function
local function createToggle(name)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, scale("Y", 40))
    container.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    container.Parent = scrollFrame
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
    

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, -scale("X", 10), 1, 0)
    label.Position = UDim2.new(0, scale("X", 10), 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, scale("X", 60), 0, scale("Y", 24))
    toggleBtn.Position = UDim2.new(1, -scale("X", 70), 0.5, -scale("Y", 12))
    toggleBtn.BackgroundColor3 = Settings[name] and Color3.fromRGB(70, 130, 255) or Color3.fromRGB(50, 50, 60)
    toggleBtn.Text = Settings[name] and "ON" or "OFF"
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextScaled = true
    toggleBtn.Parent = container
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

    toggleBtn.MouseButton1Click:Connect(function()
        Settings[name] = not Settings[name]
        if Settings[name] then
            toggleBtn.Text = "ON"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        else
            toggleBtn.Text = "OFF"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        end
    end)
end

-- Create settings controls
createToggle("Stop On Move")
createSlider("Time Position", 0, 1, Settings["Time Position"])
createSlider("Speed", 0, 5, Settings["Speed"])
createSlider("Weight", 0, 1, Settings["Weight"])
createSlider("Fade In", 0, 2, Settings["Fade In"])
createSlider("Fade Out", 0, 2, Settings["Fade Out"])
createToggle("Allow Invisible")

-- Allow Invisible functionality
local originalCollisionStates = {}
local lastFixClipState = Settings["Allow Invisible"]

local function saveCollisionStates()
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part ~= character.PrimaryPart then
            originalCollisionStates[part] = part.CanCollide
        end
    end
end

local function disableCollisionsExceptRootPart()
    if not Settings["Allow Invisible"] then
        return
    end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part ~= character.PrimaryPart then
            part.CanCollide = false
        end
    end
end

local function restoreCollisionStates()
    for part, canCollide in pairs(originalCollisionStates) do
        if part and part.Parent then
            part.CanCollide = canCollide
        end
    end
    originalCollisionStates = {}
end

saveCollisionStates()

local connection
connection = RunService.Stepped:Connect(function()
    if character and character.Parent then
        local currentFixClip = Settings["Allow Invisible"]

        if lastFixClipState ~= currentFixClip then
            if currentFixClip then
                saveCollisionStates()
                disableCollisionsExceptRootPart()
            else
                restoreCollisionStates()
            end
            lastFixClipState = currentFixClip
        elseif currentFixClip then
            disableCollisionsExceptRootPart()
        end
    else
        restoreCollisionStates()
        if connection then
            connection:Disconnect()
        end
    end
end)

player.CharacterAdded:Connect(function(newCharacter)
    restoreCollisionStates()
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")

    saveCollisionStates()
    lastFixClipState = Settings["Allow Invisible"]

    if connection then
        connection:Disconnect()
    end

    connection = RunService.Stepped:Connect(function()
        if character and character.Parent then
            local currentFixClip = Settings["Allow Invisible"]

            if lastFixClipState ~= currentFixClip then
                if currentFixClip then
                    saveCollisionStates()
                    disableCollisionsExceptRootPart()
                else
                    restoreCollisionStates()
                end
                lastFixClipState = currentFixClip
            elseif currentFixClip then
                disableCollisionsExceptRootPart()
            end
        else
            restoreCollisionStates()
            if connection then
                connection:Disconnect()
            end
        end
    end)
end)

-- === State ===
local sortModes = {
    {Enum.CatalogSortType.Relevance, "Relevance"},
    {Enum.CatalogSortType.PriceHighToLow, "Price High→Low"},
    {Enum.CatalogSortType.PriceLowToHigh, "Price Low→High"},
    {Enum.CatalogSortType.MostFavorited, "Most Favorited"},
    {Enum.CatalogSortType.RecentlyCreated, "Recently Created"},
    {Enum.CatalogSortType.Bestselling, "Bestselling"},
}
local currentSortIndex = 1
local currentKeyword = ""
local currentPages = nil
local currentPageNumber = 1

-- === Catalog fetch ===
local function getPages(keyword)
    local params = CatalogSearchParams.new()
    params.SearchKeyword = keyword or ""
    params.CategoryFilter = Enum.CatalogCategoryFilter.None
    params.SalesTypeFilter = Enum.SalesTypeFilter.All
    params.AssetTypes = { Enum.AvatarAssetType.EmoteAnimation }
    params.IncludeOffSale = true
    params.SortType = sortModes[currentSortIndex][1]
    params.Limit = 30

    local ok, pages = pcall(function()
        return AvatarEditorService:SearchCatalog(params)
    end)

    if not ok then
        warn("SearchCatalog failed:", pages)
        return nil
    end
    return pages
end

-- === Card builder ===
local function createCard(item)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, scale("X", 120), 0, scale("Y", 180))
    card.BackgroundColor3 = Color3.fromRGB(30, 30, 35)

    createCorner(card, 8)
    
    local thumbId = item.AssetId or item.Id
    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 90))
    img.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 5))
    img.BackgroundTransparency = 1
    img.ScaleType = Enum.ScaleType.Fit

    pcall(function()
        img.Image = "rbxthumb://type=Asset&id=" .. tostring(thumbId) .. "&w=150&h=150"
    end)

    if not img.Image or img.Image == "" then
        img.Image = "rbxassetid://5902417546"
    end

    img.Parent = card
    createCorner(img, 6)

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 28))
    name.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 100))
    name.BackgroundTransparency = 1
    name.Text = item.Name or "Unknown"
    name.TextScaled = true
    name.TextWrapped = true
    name.Font = Enum.Font.GothamBold
    name.TextColor3 = Color3.new(1, 1, 1)
    name.Parent = card

    local playBtn = Instance.new("TextButton")
    playBtn.Size = UDim2.new(0.45, -scale("X", 5), 0, scale("Y", 24))
    playBtn.Position = UDim2.new(0, scale("X", 5), 1, -scale("Y", 29))
    playBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    playBtn.Text = "Play"
    playBtn.Font = Enum.Font.GothamBold
    playBtn.TextScaled = true
    playBtn.TextColor3 = Color3.fromRGB(70, 255, 130)
    playBtn.Parent = card

    createCorner(playBtn, 6)
    createStroke(playBtn, 2, Color3.fromRGB(70, 255, 130))

    playBtn.MouseButton1Click:Connect(function()
        LoadTrack(thumbId)
    end)

    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.45, -scale("X", 5), 0, scale("Y", 24))
    saveBtn.Position = UDim2.new(0.55, 0, 1, -scale("Y", 29))
    saveBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    saveBtn.Text = "Save"
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextScaled = true
    saveBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
    saveBtn.Parent = card

    createCorner(saveBtn, 6)
    createStroke(saveBtn, 2, Color3.fromRGB(70, 130, 255))

    saveBtn.MouseButton1Click:Connect(function()
        local alreadySaved = false
        for _, saved in ipairs(savedEmotes) do
            if saved.Id == item.Id then
                alreadySaved = true
                break
            end
        end

        if not alreadySaved then
            table.insert(savedEmotes, {
                Id = item.Id,
                AssetId = thumbId,
                Name = item.Name or "Unknown"
            })
            saveEmotesToData()

            saveBtn.Text = "Saved!"
            saveBtn.TextColor3 = Color3.fromRGB(70, 255, 130)
            wait(1)
            saveBtn.Text = "Save"
            saveBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
        else
            saveBtn.Text = "Already Saved"
            wait(1)
            saveBtn.Text = "Save"
        end
    end)

    return card
end

-- === Saved card builder ===
local function createSavedCard(item)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, scale("X", 120), 0, scale("Y", 180))
    card.BackgroundColor3 = Color3.fromRGB(30, 30, 35)

    createCorner(card, 8)
    

    local thumbId = item.AssetId or item.Id
    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 90))
    img.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 5))
    img.BackgroundTransparency = 1
    img.ScaleType = Enum.ScaleType.Fit

    pcall(function()
        img.Image = "rbxthumb://type=Asset&id=" .. tostring(thumbId) .. "&w=150&h=150"
    end)

    if not img.Image or img.Image == "" then
        img.Image = "rbxassetid://5902417546"
    end

    img.Parent = card
    createCorner(img, 6)

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 28))
    name.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 100))
    name.BackgroundTransparency = 1
    name.Text = item.Name or "Unknown"
    name.TextScaled = true
    name.TextWrapped = true
    name.Font = Enum.Font.GothamBold
    name.TextColor3 = Color3.new(1, 1, 1)
    name.Parent = card

    local playBtn = Instance.new("TextButton")
    playBtn.Size = UDim2.new(0.45, -scale("X", 5), 0, scale("Y", 24))
    playBtn.Position = UDim2.new(0, scale("X", 5), 1, -scale("Y", 29))
    playBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    playBtn.Text = "Play"
    playBtn.Font = Enum.Font.GothamBold
    playBtn.TextScaled = true
    playBtn.TextColor3 = Color3.fromRGB(70, 255, 130)
    playBtn.Parent = card

    createCorner(playBtn, 6)
    createStroke(playBtn, 2, Color3.fromRGB(70, 255, 130))

    playBtn.MouseButton1Click:Connect(function()
        LoadTrack(thumbId)
    end)

    local removeBtn = Instance.new("TextButton")
    removeBtn.Size = UDim2.new(0.45, -scale("X", 5), 0, scale("Y", 24))
    removeBtn.Position = UDim2.new(0.55, 0, 1, -scale("Y", 29))
    removeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    removeBtn.Text = "Remove"
    removeBtn.Font = Enum.Font.GothamBold
    removeBtn.TextScaled = true
    removeBtn.TextColor3 = Color3.fromRGB(255, 70, 70)
    removeBtn.Parent = card

    createCorner(removeBtn, 6)
    createStroke(removeBtn, 2, Color3.fromRGB(255, 70, 70))

    removeBtn.MouseButton1Click:Connect(function()
        for i, saved in ipairs(savedEmotes) do
            if saved.Id == item.Id then
                table.remove(savedEmotes, i)
                saveEmotesToData()
                refreshSavedTab()
                break
            end
        end
    end)

    return card
end

-- === Refresh saved tab ===
function refreshSavedTab()
    for _, child in ipairs(savedScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    if savedEmotes and #savedEmotes > 0 then
        savedEmptyLabel.Visible = false
        for _, item in ipairs(savedEmotes) do
            createSavedCard(item).Parent = savedScroll
        end
    else
        savedEmptyLabel.Visible = true
    end

    savedScroll.CanvasSize = UDim2.new(0, 0, 0, savedLayout.AbsoluteContentSize.Y + 8)
end

-- === Update nav visibility ===
local function updateNavVisibility()
    prevBtn.Visible = (currentPageNumber > 1)
    if currentPages and typeof(currentPages.IsFinished) == "boolean" then
        nextBtn.Visible = not currentPages.IsFinished
    else
        nextBtn.Visible = true
    end
end

local function showPage(pages)
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local currentList = nil
    local ok, got = pcall(function() return pages:GetCurrentPage() end)
    if ok then
        currentList = got
    else
        warn("Failed to GetCurrentPage:", got)
    end

    if currentList and #currentList > 0 then
        emptyLabel.Visible = false
        for _, item in ipairs(currentList) do
            createCard(item).Parent = scroll
        end
    else
        emptyLabel.Visible = true
    end

    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
    pageLabel.Text = "Page " .. tostring(currentPageNumber)
    updateNavVisibility()
end

local function fetchPagesTo(targetPage)
    local pages = getPages(currentKeyword)
    if not pages then return nil end
    for i = 2, targetPage do
        if pages.IsFinished then break end
        local ok, err = pcall(function() pages:AdvanceToNextPageAsync() end)
        if not ok then break end
    end
    return pages
end

-- === Event handlers ===
local function doNewSearch(keyword)
    currentKeyword = keyword or ""
    currentPageNumber = 1
    searchBox.Text = currentKeyword
    currentPages = getPages(currentKeyword)
    if currentPages then
        showPage(currentPages)
    end
end

searchBtn.MouseButton1Click:Connect(function()
    doNewSearch(searchBox.Text)
end)

sortBtn.MouseButton1Click:Connect(function()
    currentSortIndex = currentSortIndex % #sortModes + 1
    sortBtn.Text = "Sort: " .. sortModes[currentSortIndex][2]
    doNewSearch(currentKeyword)
end)

searchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        doNewSearch(searchBox.Text)
    end
end)

nextBtn.MouseButton1Click:Connect(function()
    if not currentPages then return end
    if currentPages.IsFinished then return end

    local ok, err = pcall(function()
        currentPages:AdvanceToNextPageAsync()
    end)

    if ok then
        currentPageNumber = currentPageNumber + 1
        showPage(currentPages)
    else
        warn("AdvanceToNextPageAsync failed")
        local targetPage = currentPageNumber + 1
        local fresh = fetchPagesTo(targetPage)
        if fresh then
            currentPages = fresh
            currentPageNumber = math.min(targetPage, currentPageNumber + 1)
            showPage(currentPages)
        end
    end
end)

prevBtn.MouseButton1Click:Connect(function()
    if not currentPages then return end
    if currentPageNumber <= 1 then return end

    local ok, err = pcall(function()
        currentPages:AdvanceToPreviousPageAsync()
    end)

    if ok then
        currentPageNumber = math.max(1, currentPageNumber - 1)
        showPage(currentPages)
    else
        warn("AdvanceToPreviousPageAsync failed")
        local targetPage = math.max(1, currentPageNumber - 1)
        local fresh = fetchPagesTo(targetPage)
        if fresh then
            currentPages = fresh
            currentPageNumber = targetPage
            showPage(currentPages)
        end
    end
end)

-- Tab switching
catalogTabBtn.MouseButton1Click:Connect(function()
    catalogFrame.Visible = true
    savedFrame.Visible = false
    catalogTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    catalogTabBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
    catalogTabBtn:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(70, 130, 255)
    savedTabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    savedTabBtn.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    savedTabBtn:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(50, 50, 60)
end)

savedTabBtn.MouseButton1Click:Connect(function()
    catalogFrame.Visible = false
    savedFrame.Visible = true
    catalogTabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    catalogTabBtn.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    catalogTabBtn:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(50, 50, 60)
    savedTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    savedTabBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
    savedTabBtn:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(70, 130, 255)
    refreshSavedTab()
end)

-- === Initial load ===
doNewSearch("")