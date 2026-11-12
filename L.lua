
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Variables
local following = false
local targetPlayer = nil
local connection = nil
local selectedPlayer = nil
local followMode = "default"

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SIEXTHERxTROLL"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame (Lebih kecil & Modern Dark)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 220, 0, 320)
mainFrame.Position = UDim2.new(0.5, -110, 0.5, -188)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(70, 130, 255)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 30)
header.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 12)
headerFix.Position = UDim2.new(0, 0, 1, -12)
headerFix.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "SIEXTHER TROLL"
title.TextColor3 = Color3.fromRGB(70, 130, 255)
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, 22, 0, 22)
minimizeBtn.Position = UDim2.new(1, -50, 0.5, -11)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
minimizeBtn.Text = "–"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextSize = 12
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = header

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minimizeBtn

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -24, 0.5, -11)
closeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 11
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 38)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Tidak aktif"
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
statusLabel.TextSize = 10
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

-- Search Box
local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, -20, 0, 26)
searchBox.Position = UDim2.new(0, 10, 0, 60)
searchBox.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
searchBox.BorderSizePixel = 0
searchBox.PlaceholderText = "Cari player..."
searchBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 110)
searchBox.Text = ""
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.TextSize = 10
searchBox.Font = Enum.Font.Gotham
searchBox.ClearTextOnFocus = false
searchBox.Parent = mainFrame

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 6)
searchCorner.Parent = searchBox

local searchPadding = Instance.new("UIPadding")
searchPadding.PaddingLeft = UDim.new(0, 8)
searchPadding.PaddingRight = UDim.new(0, 8)
searchPadding.Parent = searchBox

-- ScrollFrame for players
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "PlayerList"
scrollFrame.Size = UDim2.new(1, -20, 1, -210)
scrollFrame.Position = UDim2.new(0, 10, 0, 92)
scrollFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
scrollFrame.Parent = mainFrame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 6)
scrollCorner.Parent = scrollFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Padding = UDim.new(0, 3)
listLayout.Parent = scrollFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 5)
listPadding.PaddingBottom = UDim.new(0, 5)
listPadding.PaddingLeft = UDim.new(0, 5)
listPadding.PaddingRight = UDim.new(0, 5)
listPadding.Parent = scrollFrame

-- Control Buttons Container
local controlFrame = Instance.new("Frame")
controlFrame.Name = "ControlFrame"
controlFrame.Size = UDim2.new(1, -20, 0, 105)
controlFrame.Position = UDim2.new(0, 10, 1, -112)
controlFrame.BackgroundTransparency = 1
controlFrame.Parent = mainFrame

-- Selected Player Label
local selectedLabel = Instance.new("TextLabel")
selectedLabel.Name = "SelectedLabel"
selectedLabel.Size = UDim2.new(1, 0, 0, 14)
selectedLabel.Position = UDim2.new(0, 0, 0, 0)
selectedLabel.BackgroundTransparency = 1
selectedLabel.Text = "Dipilih: Tidak ada"
selectedLabel.TextColor3 = Color3.fromRGB(130, 130, 150)
selectedLabel.TextSize = 9
selectedLabel.Font = Enum.Font.Gotham
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Parent = controlFrame

-- Mode Buttons Container
local modeFrame = Instance.new("Frame")
modeFrame.Name = "ModeFrame"
modeFrame.Size = UDim2.new(1, 0, 0, 50)
modeFrame.Position = UDim2.new(0, 0, 0, 18)
modeFrame.BackgroundTransparency = 1
modeFrame.Parent = controlFrame

-- Mode Label
local modeLabel = Instance.new("TextLabel")
modeLabel.Size = UDim2.new(1, 0, 0, 12)
modeLabel.BackgroundTransparency = 1
modeLabel.Text = "TROLL MODE:"
modeLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
modeLabel.TextSize = 8
modeLabel.Font = Enum.Font.GothamBold
modeLabel.TextXAlignment = Enum.TextXAlignment.Left
modeLabel.Parent = modeFrame

-- Mode Buttons (2x2 Grid)
local modeButtons = {}
local modes = {
    {name = "default", label = "FOLLOW", color = Color3.fromRGB(70, 130, 255)},
    {name = "carry", label = "CARRY", color = Color3.fromRGB(180, 100, 200)},
    {name = "attach", label = "TEMPEL", color = Color3.fromRGB(255, 150, 80)},
    {name = "drag", label = "SERET", color = Color3.fromRGB(150, 80, 180)}
}

for i, mode in ipairs(modes) do
    local row = math.floor((i - 1) / 2)
    local col = (i - 1) % 2
    
    local btn = Instance.new("TextButton")
    btn.Name = mode.name .. "Btn"
    btn.Size = UDim2.new(0.48, 0, 0, 16)
    btn.Position = UDim2.new(col * 0.52, 0, 0, 14 + row * 19)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    btn.Text = mode.label
    btn.TextColor3 = Color3.fromRGB(180, 180, 200)
    btn.TextSize = 8
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.Parent = modeFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5)
    btnCorner.Parent = btn
    
    modeButtons[mode.name] = {button = btn, color = mode.color}
    
    btn.MouseButton1Click:Connect(function()
        followMode = mode.name
        for _, mBtn in pairs(modeButtons) do
            mBtn.button.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            mBtn.button.TextColor3 = Color3.fromRGB(180, 180, 200)
        end
        btn.BackgroundColor3 = mode.color
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    
    btn.MouseEnter:Connect(function()
        if followMode ~= mode.name then
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        end
    end)
    
    btn.MouseLeave:Connect(function()
        if followMode ~= mode.name then
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        end
    end)
end

-- Highlight default mode
modeButtons["default"].button.BackgroundColor3 = modes[1].color
modeButtons["default"].button.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Toggle Follow Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleBtn"
toggleBtn.Size = UDim2.new(1, 0, 0, 32)
toggleBtn.Position = UDim2.new(0, 0, 0, 73)
toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
toggleBtn.Text = "MULAI"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 11
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = controlFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleBtn

-- Modern Dark Fire Button
local fireBtn = Instance.new("TextButton")
fireBtn.Name = "FireBtn"
fireBtn.Size = UDim2.new(0, 41, 0, 41)
fireBtn.Position = UDim2.new(0, 15, 0, 60)
fireBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
fireBtn.Text = ""
fireBtn.BorderSizePixel = 0
fireBtn.Visible = false
fireBtn.Active = true
fireBtn.Parent = screenGui

local fireCorner = Instance.new("UICorner")
fireCorner.CornerRadius = UDim.new(0, 12)
fireCorner.Parent = fireBtn

local fireStroke = Instance.new("UIStroke")
fireStroke.Color = Color3.fromRGB(70, 130, 255)
fireStroke.Thickness = 2
fireStroke.Parent = fireBtn

local fireIcon = Instance.new("TextLabel")
fireIcon.Size = UDim2.new(1, 0, 1, 0)
fireIcon.BackgroundTransparency = 1
fireIcon.Text = "👺"
fireIcon.TextSize = 20
fireIcon.Font = Enum.Font.GothamBold
fireIcon.TextColor3 = Color3.fromRGB(70, 130, 255)
fireIcon.Parent = fireBtn

-- Ultra Smooth Follow Function
local function startFollowing()
    if not selectedPlayer or not selectedPlayer.Character then return end
    
    following = true
    targetPlayer = selectedPlayer
    local modeName = followMode == "default" and "Follow" or 
                     followMode == "carry" and "Carry" or
                     followMode == "attach" and "Tempel" or "Seret"
    statusLabel.Text = "Status: Troll " .. (targetPlayer.DisplayName or targetPlayer.Name) .. " [" .. modeName .. "]"
    statusLabel.TextColor3 = Color3.fromRGB(70, 255, 150)
    
    if connection then
        connection:Disconnect()
    end
    
    local lastJumpTime = 0
    local wasInAir = false
    
    connection = RunService.Heartbeat:Connect(function(deltaTime)
        if not following or not targetPlayer or not targetPlayer.Character then
            if connection then
                connection:Disconnect()
                connection = nil
            end
            return
        end
        
        local targetChar = targetPlayer.Character
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        local targetHumanoid = targetChar:FindFirstChild("Humanoid")
        
        if not player.Character or not targetRoot or not targetHumanoid then return end
        
        local myRoot = player.Character:FindFirstChild("HumanoidRootPart")
        local myHumanoid = player.Character:FindFirstChild("Humanoid")
        
        if not myRoot or not myHumanoid then return end
        
        if followMode == "default" then
            local followOffset = targetRoot.CFrame.LookVector * -2.5
            local followPos = targetRoot.Position + followOffset
            local distance = (myRoot.Position - followPos).Magnitude
            
            if distance > 1.5 then
                myHumanoid:MoveTo(followPos)
                myHumanoid.WalkSpeed = targetHumanoid.WalkSpeed
            else
                myHumanoid.WalkSpeed = targetHumanoid.WalkSpeed * 0.5
            end
            
            local targetIsJumping = targetHumanoid:GetState() == Enum.HumanoidStateType.Jumping or
                                    targetHumanoid:GetState() == Enum.HumanoidStateType.Freefall
            local targetVelocity = targetRoot.AssemblyLinearVelocity
            local isMovingUp = targetVelocity.Y > 5
            local currentTime = tick()
            
            if (targetIsJumping or isMovingUp) and not wasInAir then
                if currentTime - lastJumpTime > 0.3 then
                    myHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    lastJumpTime = currentTime
                end
            end
            wasInAir = targetIsJumping or isMovingUp
            
            if targetHumanoid.Sit ~= myHumanoid.Sit then
                myHumanoid.Sit = targetHumanoid.Sit
            end
            
        elseif followMode == "carry" then
            local carryOffset = targetRoot.CFrame.LookVector * -1.2 + Vector3.new(0, 1, 0)
            local carryPos = targetRoot.Position + carryOffset
            myRoot.CFrame = CFrame.new(carryPos, targetRoot.Position + targetRoot.CFrame.LookVector)
            myRoot.AssemblyLinearVelocity = targetRoot.AssemblyLinearVelocity
            myHumanoid.Sit = false
            
        elseif followMode == "attach" then
            myRoot.CFrame = targetRoot.CFrame
            myRoot.AssemblyLinearVelocity = targetRoot.AssemblyLinearVelocity
            myRoot.AssemblyAngularVelocity = targetRoot.AssemblyAngularVelocity
            myHumanoid.Sit = targetHumanoid.Sit
            myHumanoid.WalkSpeed = targetHumanoid.WalkSpeed
            
            if targetHumanoid:GetState() ~= myHumanoid:GetState() then
                myHumanoid:ChangeState(targetHumanoid:GetState())
            end
            
        elseif followMode == "drag" then
            local dragOffset = targetRoot.CFrame.LookVector * -2.8
            local targetDragPos = targetRoot.Position + dragOffset + Vector3.new(0, -1.8, 0)
            myHumanoid.PlatformStand = true
            
            local currentPos = myRoot.Position
            local lerpAlpha = 0.35
            local newPos = currentPos:Lerp(targetDragPos, lerpAlpha)
            local lookDirection = (targetRoot.Position - myRoot.Position).Unit
            myRoot.CFrame = CFrame.new(newPos, newPos + lookDirection) * CFrame.Angles(math.rad(90), 0, 0)
            myRoot.AssemblyLinearVelocity = targetRoot.AssemblyLinearVelocity * 0.95
            myRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            
            local distance = (myRoot.Position - targetDragPos).Magnitude
            if distance > 0.5 then
                local dragForce = (targetDragPos - myRoot.Position) * 8
                myRoot.AssemblyLinearVelocity = myRoot.AssemblyLinearVelocity + dragForce
            end
        end
    end)
end

local function stopFollowing()
    following = false
    targetPlayer = nil
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    if player.Character then
        local myHumanoid = player.Character:FindFirstChild("Humanoid")
        if myHumanoid then
            myHumanoid.PlatformStand = false
        end
    end
    
    statusLabel.Text = "Status: Tidak aktif"
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
end

local function createPlayerButton(targetPlayer)
    local displayName = targetPlayer.DisplayName or targetPlayer.Name
    local userName = targetPlayer.Name
    local fullName = displayName .. " (@" .. userName .. ")"
    
    local btn = Instance.new("TextButton")
    btn.Name = targetPlayer.Name
    btn.Size = UDim2.new(1, -10, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.ClipsDescendants = true
    btn.Parent = scrollFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5)
    btnCorner.Parent = btn
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 1, 0)
    nameLabel.Position = UDim2.new(0, 8, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = fullName
    nameLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    nameLabel.TextSize = 9
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        selectedPlayer = Players:FindFirstChild(btn.Name)
        selectedLabel.Text = "Dipilih: " .. displayName
        selectedLabel.TextColor3 = Color3.fromRGB(70, 130, 255)
        
        for _, child in pairs(scrollFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            end
        end
        btn.BackgroundColor3 = Color3.fromRGB(50, 70, 100)
    end)
    
    btn.MouseEnter:Connect(function()
        if selectedPlayer ~= Players:FindFirstChild(btn.Name) then
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        end
    end)
    
    btn.MouseLeave:Connect(function()
        if selectedPlayer ~= Players:FindFirstChild(btn.Name) then
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        end
    end)
    
    return btn
end

local function updatePlayerList(searchText)
    searchText = searchText and searchText:lower() or ""
    
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            local displayName = (plr.DisplayName or plr.Name):lower()
            local userName = plr.Name:lower()
            
            if searchText == "" or displayName:find(searchText, 1, true) or userName:find(searchText, 1, true) then
                createPlayerButton(plr)
            end
        end
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end

toggleBtn.MouseButton1Click:Connect(function()
    if not following then
        if selectedPlayer then
            startFollowing()
            toggleBtn.Text = "STOP"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
        end
    else
        stopFollowing()
        toggleBtn.Text = "MULAI"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    end
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    updatePlayerList(searchBox.Text)
end)

-- Dragging
local dragging = false
local dragInput, mousePos, framePos

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        mousePos = input.Position
        framePos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        mainFrame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
    end
end)

-- Fire Button Dragging
local fireDragging = false
local fireDragInput, fireMousePos, fireFramePos

fireBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        fireDragging = true
        fireMousePos = input.Position
        fireFramePos = fireBtn.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                fireDragging = false
            end
        end)
    end
end)

fireBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        fireDragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == fireDragInput and fireDragging then
        local delta = input.Position - fireMousePos
        fireBtn.Position = UDim2.new(fireFramePos.X.Scale, fireFramePos.X.Offset + delta.X, fireFramePos.Y.Scale, fireFramePos.Y.Offset + delta.Y)
    end
end)

fireBtn.MouseButton1Click:Connect(function()
    if not fireDragging then
        mainFrame.Visible = true
        fireBtn.Visible = false
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    stopFollowing()
    screenGui:Destroy()
end)

minimizeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    fireBtn.Visible = true
end)

-- Hover effects
local function addHoverEffect(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = hoverColor
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = normalColor
    end)
end

addHoverEffect(closeBtn, Color3.fromRGB(35, 35, 45), Color3.fromRGB(255, 80, 80))
addHoverEffect(minimizeBtn, Color3.fromRGB(35, 35, 45), Color3.fromRGB(255, 200, 80))
addHoverEffect(fireBtn, Color3.fromRGB(18, 18, 24), Color3.fromRGB(28, 28, 36))

toggleBtn.MouseEnter:Connect(function()
    if not following then
        toggleBtn.BackgroundColor3 = Color3.fromRGB(90, 150, 255)
    else
        toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 90, 90)
    end
end)

toggleBtn.MouseLeave:Connect(function()
    if not following then
        toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    else
        toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
    end
end)

-- Initial load
updatePlayerList()

Players.PlayerAdded:Connect(function()
    updatePlayerList(searchBox.Text)
end)

Players.PlayerRemoving:Connect(function()
    wait(0.1)
    updatePlayerList(searchBox.Text)
end)