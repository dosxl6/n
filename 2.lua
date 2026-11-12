local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Variables
local freeCamEnabled = true
local moveSpeed = 1

-- Simpan pengaturan kamera original
local originalCameraType = camera.CameraType
local originalCameraSubject = camera.CameraSubject

-- Movement states
local isMovingUp = false
local isMovingDown = false
local isMovingLeft = false
local isMovingRight = false
local isMovingForward = false
local isMovingBackward = false

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SIEXTHERFREECAM"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999 
screenGui.Parent = player:WaitForChild("PlayerGui")

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 41, 0, 41)
closeButton.Position = UDim2.new(1, -70, 0, -45)  
closeButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 23
closeButton.Font = Enum.Font.GothamBold
closeButton.BorderSizePixel = 0
closeButton.Parent = screenGui

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 12)
closeCorner.Parent = closeButton

local speedFrame = Instance.new("Frame")
speedFrame.Name = "SpeedFrame"
speedFrame.Size = UDim2.new(0, 130, 0, 65)  
speedFrame.Position = UDim2.new(1, -150, 0, 20)
speedFrame.BackgroundTransparency = 0.1
speedFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30) 
speedFrame.BorderSizePixel = 0
speedFrame.Parent = screenGui

local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 10)
speedCorner.Parent = speedFrame

local speedStroke = Instance.new("UIStroke")
speedStroke.Color = Color3.fromRGB(70, 130, 255) 
speedStroke.Thickness = 2
speedStroke.Parent = speedFrame

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, 0, 0, 22)  
speedLabel.Position = UDim2.new(0, 0, 0, 3)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "SIEXTHER SPEED CAM"
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.TextSize = 10
speedLabel.Font = Enum.Font.GothamBold
speedLabel.Parent = speedFrame

local decreaseButton = Instance.new("TextButton")
decreaseButton.Size = UDim2.new(0, 28, 0, 28)  
decreaseButton.Position = UDim2.new(0, 8, 0, 30)
decreaseButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
decreaseButton.Text = "<"
decreaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
decreaseButton.TextSize = 18  
decreaseButton.Font = Enum.Font.GothamBold
decreaseButton.BorderSizePixel = 0
decreaseButton.Parent = speedFrame

local decreaseCorner = Instance.new("UICorner")
decreaseCorner.CornerRadius = UDim.new(0, 8)
decreaseCorner.Parent = decreaseButton

local speedTextBox = Instance.new("TextBox")
speedTextBox.Size = UDim2.new(0, 42, 0, 28)  
speedTextBox.Position = UDim2.new(0, 44, 0, 30)
speedTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
speedTextBox.Text = "1.0"
speedTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedTextBox.TextSize = 14  
speedTextBox.Font = Enum.Font.GothamBold
speedTextBox.BorderSizePixel = 0
speedTextBox.ClearTextOnFocus = false
speedTextBox.Parent = speedFrame

local textBoxCorner = Instance.new("UICorner")
textBoxCorner.CornerRadius = UDim.new(0, 8)
textBoxCorner.Parent = speedTextBox

local increaseButton = Instance.new("TextButton")
increaseButton.Size = UDim2.new(0, 28, 0, 28)  
increaseButton.Position = UDim2.new(0, 94, 0, 30)
increaseButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
increaseButton.Text = ">"
increaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
increaseButton.TextSize = 18  
increaseButton.Font = Enum.Font.GothamBold
increaseButton.BorderSizePixel = 0
increaseButton.Parent = speedFrame

local increaseCorner = Instance.new("UICorner")
increaseCorner.CornerRadius = UDim.new(0, 8)
increaseCorner.Parent = increaseButton

-- ========== D-PAD HORIZONTAL ==========
local dpadContainer = Instance.new("Frame")
dpadContainer.Name = "DPadContainer"
dpadContainer.Size = UDim2.new(0, 160, 0, 160)
dpadContainer.Position = UDim2.new(0, 30, 1, -190)
dpadContainer.BackgroundTransparency = 1
dpadContainer.Parent = screenGui

local function createDPadButton(name, position, text, size)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size or UDim2.new(0, 50, 0, 50)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    button.BackgroundTransparency = 0.3
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 24
    button.Font = Enum.Font.GothamBold
    button.BorderSizePixel = 0
    button.Parent = dpadContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button
    
    return button
end

local upButton = createDPadButton("Up", UDim2.new(0.5, -25, 0, 0), "▲")
local leftButton = createDPadButton("Left", UDim2.new(0, 0, 0.5, -25), "◀")
local rightButton = createDPadButton("Right", UDim2.new(1, -50, 0.5, -25), "▶")
local downButton = createDPadButton("Down", UDim2.new(0.5, -25, 1, -50), "▼")

-- ========== D-PAD VERTIKAL ==========
local verticalPadContainer = Instance.new("Frame")
verticalPadContainer.Name = "VerticalPadContainer"
verticalPadContainer.Size = UDim2.new(0, 60, 0, 130)
verticalPadContainer.Position = UDim2.new(1, -90, 1, -160)
verticalPadContainer.BackgroundTransparency = 1
verticalPadContainer.Parent = screenGui

local function createVerticalButton(name, position, text)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(0, 60, 0, 60)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    button.BackgroundTransparency = 0.3
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 28
    button.Font = Enum.Font.GothamBold
    button.BorderSizePixel = 0
    button.Parent = verticalPadContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button
   
    return button
end

local jumpButton = createVerticalButton("Jump", UDim2.new(0, 0, 0, 0), "▲")
local crouchButton = createVerticalButton("Crouch", UDim2.new(0, 0, 0, 70), "▼")

-- ========== FUNGSI KECEPATAN ==========
local function updateSpeed(newSpeed)
    moveSpeed = math.clamp(newSpeed, 0.1, 10)
    speedTextBox.Text = string.format("%.1f", moveSpeed)
end

decreaseButton.MouseButton1Click:Connect(function()
    updateSpeed(moveSpeed - 0.5)
    decreaseButton.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    wait(0.1)
    decreaseButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
end)

increaseButton.MouseButton1Click:Connect(function()
    updateSpeed(moveSpeed + 0.5)
    increaseButton.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    wait(0.1)
    increaseButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
end)

speedTextBox.FocusLost:Connect(function()
    local newSpeed = tonumber(speedTextBox.Text)
    if newSpeed then
        updateSpeed(newSpeed)
    else
        speedTextBox.Text = string.format("%.1f", moveSpeed)
    end
end)

-- ========== FUNGSI FREECAM ==========
local function disableFreeCam()
    freeCamEnabled = false
    
    -- Kembalikan kamera ke pengaturan default
    camera.CameraType = originalCameraType
    
    -- Kembalikan camera subject ke character
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        camera.CameraSubject = player.Character.Humanoid
    else
        camera.CameraSubject = originalCameraSubject
    end
    
    -- Destroy GUI dan anchor part
    screenGui:Destroy()
end

local function buttonPressEffect(button)
    button.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    wait(0.1)
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
end

-- ========== D-PAD HORIZONTAL CONTROLS ==========
upButton.MouseButton1Down:Connect(function()
    isMovingForward = true
    spawn(function() buttonPressEffect(upButton) end)
end)
upButton.MouseButton1Up:Connect(function()
    isMovingForward = false
end)

downButton.MouseButton1Down:Connect(function()
    isMovingBackward = true
    spawn(function() buttonPressEffect(downButton) end)
end)
downButton.MouseButton1Up:Connect(function()
    isMovingBackward = false
end)

leftButton.MouseButton1Down:Connect(function()
    isMovingLeft = true
    spawn(function() buttonPressEffect(leftButton) end)
end)
leftButton.MouseButton1Up:Connect(function()
    isMovingLeft = false
end)

rightButton.MouseButton1Down:Connect(function()
    isMovingRight = true
    spawn(function() buttonPressEffect(rightButton) end)
end)
rightButton.MouseButton1Up:Connect(function()
    isMovingRight = false
end)

-- ========== D-PAD VERTIKAL CONTROLS ==========
jumpButton.MouseButton1Down:Connect(function()
    isMovingUp = true
    spawn(function() buttonPressEffect(jumpButton) end)
end)
jumpButton.MouseButton1Up:Connect(function()
    isMovingUp = false
end)

crouchButton.MouseButton1Down:Connect(function()
    isMovingDown = true
    spawn(function() buttonPressEffect(crouchButton) end)
end)
crouchButton.MouseButton1Up:Connect(function()
    isMovingDown = false
end)

closeButton.MouseButton1Click:Connect(function()
    disableFreeCam()
end)

-- ========== KEYBOARD SUPPORT ==========
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.W then isMovingForward = true end
    if input.KeyCode == Enum.KeyCode.S then isMovingBackward = true end
    if input.KeyCode == Enum.KeyCode.A then isMovingLeft = true end
    if input.KeyCode == Enum.KeyCode.D then isMovingRight = true end
    if input.KeyCode == Enum.KeyCode.Space then isMovingUp = true end
    if input.KeyCode == Enum.KeyCode.LeftShift then isMovingDown = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then isMovingForward = false end
    if input.KeyCode == Enum.KeyCode.S then isMovingBackward = false end
    if input.KeyCode == Enum.KeyCode.A then isMovingLeft = false end
    if input.KeyCode == Enum.KeyCode.D then isMovingRight = false end
    if input.KeyCode == Enum.KeyCode.Space then isMovingUp = false end
    if input.KeyCode == Enum.KeyCode.LeftShift then isMovingDown = false end
end)

-- ========== CAMERA MOVEMENT LOOP ==========
local anchorPart = Instance.new("Part")
anchorPart.Name = "FreeCamAnchor"
anchorPart.Size = Vector3.new(1, 1, 1)
anchorPart.Transparency = 1
anchorPart.CanCollide = false
anchorPart.Anchored = true
anchorPart.CFrame = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.CFrame or CFrame.new(0, 10, 0)
anchorPart.Parent = workspace

camera.CameraSubject = anchorPart

RunService.RenderStepped:Connect(function(deltaTime)
    if freeCamEnabled and anchorPart then
        local moveVector = Vector3.new(0, 0, 0)
        
        if isMovingForward then moveVector = moveVector + Vector3.new(0, 0, -1) end
        if isMovingBackward then moveVector = moveVector + Vector3.new(0, 0, 1) end
        if isMovingLeft then moveVector = moveVector + Vector3.new(-1, 0, 0) end
        if isMovingRight then moveVector = moveVector + Vector3.new(1, 0, 0) end
        if isMovingUp then moveVector = moveVector + Vector3.new(0, 1, 0) end
        if isMovingDown then moveVector = moveVector + Vector3.new(0, -1, 0) end
        
        if moveVector.Magnitude > 0 then
            moveVector = moveVector.Unit
        end
        
        local cameraCFrame = camera.CFrame
        local moveDelta = cameraCFrame:VectorToWorldSpace(moveVector * moveSpeed * deltaTime * 60)
        anchorPart.CFrame = anchorPart.CFrame + moveDelta
    end
end)

-- Cleanup ketika GUI dihapus
screenGui.AncestryChanged:Connect(function()
    if not screenGui.Parent then
        -- Kembalikan kamera ke default
        camera.CameraType = originalCameraType
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            camera.CameraSubject = player.Character.Humanoid
        else
            camera.CameraSubject = originalCameraSubject
        end
        
        -- Hapus anchor part
        if anchorPart then
            anchorPart:Destroy()
        end
    end
end)