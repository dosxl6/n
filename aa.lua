local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

loadstring(game:HttpGet("https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/han.lua"))()

-- Database System
local DATABASE_NAME = "SiextherSpam"
local savedMessages = {}

local function loadMessages()
    local success, result = pcall(function()
        return HttpService:JSONDecode(readfile(DATABASE_NAME .. ".json"))
    end)
    
    if success and result then
        savedMessages = result
    else
        -- Default messages
        savedMessages = {
            "SIEXTHER",
            "SXTHR",
            "SIEXTHER WAS HERE",
            "WSP ALL KACUNG",
            "SIEXTHER 🔥🔥🔥",
            "",
            "",
            "",
            "",
            ""
        }
    end
end

-- Save messages to database
local function saveMessages()
    pcall(function()
        writefile(DATABASE_NAME .. ".json", HttpService:JSONEncode(savedMessages))
    end)
end

-- Initialize
loadMessages()

-- Spam Variables
local isSpamming = false
local DELAY = 0.001
local CHANGE_INTERVAL = 0.8
local currentMessageIndex = 1
local lastChangeTime = tick()

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SiextherSpamHan"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 380, 0, 340)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -199)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(70, 130, 255)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

-- Title fix for bottom corners
local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 10)
titleFix.Position = UDim2.new(0, 0, 1, -10)
titleFix.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

-- Title Text
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -75, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SIEXTHER SPAM  |  DWYOR!!!"
titleLabel.TextColor3 = Color3.fromRGB(70, 130, 255)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, 26, 0, 26)
minimizeBtn.Position = UDim2.new(1, -58, 0.5, -13)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
minimizeBtn.Text = "–"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextSize = 16
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 5)
minCorner.Parent = minimizeBtn

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -28, 0.5, -13)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 13
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = closeBtn

-- Content Frame
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -14, 1, -40)
contentFrame.Position = UDim2.new(0, 7, 0, 35)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local textBoxes = {}
local ROW_COUNT = 5
local COL_COUNT = 2
local BOX_WIDTH = 178
local BOX_HEIGHT = 48
local SPACING_X = 6
local SPACING_Y = 5

for row = 0, ROW_COUNT - 1 do
    for col = 0, COL_COUNT - 1 do
        local index = row * COL_COUNT + col + 1
        
        -- Container for each textbox + buttons
        local container = Instance.new("Frame")
        container.Name = "Container" .. index
        container.Size = UDim2.new(0, BOX_WIDTH, 0, BOX_HEIGHT)
        container.Position = UDim2.new(0, col * (BOX_WIDTH + SPACING_X), 0, row * (BOX_HEIGHT + SPACING_Y))
        container.BackgroundTransparency = 1
        container.Parent = contentFrame
        
        -- TextBox
        local textBox = Instance.new("TextBox")
        textBox.Name = "TextBox" .. index
        textBox.Size = UDim2.new(1, 0, 0, 26)
        textBox.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        textBox.Text = savedMessages[index] or ""
        textBox.PlaceholderText = "Message " .. index
        textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        textBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
        textBox.TextSize = 11
        textBox.Font = Enum.Font.Gotham
        textBox.ClearTextOnFocus = false
        textBox.TextXAlignment = Enum.TextXAlignment.Left
        textBox.BorderSizePixel = 0
        textBox.Parent = container
        
        local tbCorner = Instance.new("UICorner")
        tbCorner.CornerRadius = UDim.new(0, 5)
        tbCorner.Parent = textBox
        
        local tbPadding = Instance.new("UIPadding")
        tbPadding.PaddingLeft = UDim.new(0, 6)
        tbPadding.PaddingRight = UDim.new(0, 6)
        tbPadding.Parent = textBox
        
        table.insert(textBoxes, textBox)
        
        -- Save Button
        local saveBtn = Instance.new("TextButton")
        saveBtn.Name = "SaveBtn" .. index
        saveBtn.Size = UDim2.new(0.48, 0, 0, 18)
        saveBtn.Position = UDim2.new(0, 0, 0, 29)
        saveBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 80)
        saveBtn.Text = "Save"
        saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        saveBtn.TextSize = 9
        saveBtn.Font = Enum.Font.GothamBold
        saveBtn.BorderSizePixel = 0
        saveBtn.Parent = container
        
        local saveCorner = Instance.new("UICorner")
        saveCorner.CornerRadius = UDim.new(0, 4)
        saveCorner.Parent = saveBtn
        
        -- Reset Button
        local resetBtn = Instance.new("TextButton")
        resetBtn.Name = "ResetBtn" .. index
        resetBtn.Size = UDim2.new(0.48, 0, 0, 18)
        resetBtn.Position = UDim2.new(0.52, 0, 0, 29)
        resetBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
        resetBtn.Text = "Reset"
        resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        resetBtn.TextSize = 9
        resetBtn.Font = Enum.Font.GothamBold
        resetBtn.BorderSizePixel = 0
        resetBtn.Parent = container
        
        local resetCorner = Instance.new("UICorner")
        resetCorner.CornerRadius = UDim.new(0, 4)
        resetCorner.Parent = resetBtn
        
        -- Button Functions
        saveBtn.MouseButton1Click:Connect(function()
            savedMessages[index] = textBox.Text
            saveMessages()
            
            -- Notification
            getgenv().Notify({
                Title = 'MESSAGE SAVED', 
                Content = 'Message ' .. index .. ' saved successfully!', 
                Duration = 3
            })
            
            -- Animation
            local originalColor = saveBtn.BackgroundColor3
            saveBtn.BackgroundColor3 = Color3.fromRGB(70, 200, 100)
            wait(0.2)
            saveBtn.BackgroundColor3 = originalColor
        end)
        
        resetBtn.MouseButton1Click:Connect(function()
            textBox.Text = ""
            savedMessages[index] = ""
            saveMessages()
            
            -- Notification
            getgenv().Notify({
                Title = 'MESSAGE RESET', 
                Content = 'Message ' .. index .. ' has been cleared!', 
                Duration = 3
            })
            
            -- Animation
            local originalColor = resetBtn.BackgroundColor3
            resetBtn.BackgroundColor3 = Color3.fromRGB(220, 100, 70)
            wait(0.2)
            resetBtn.BackgroundColor3 = originalColor
        end)
    end
end

-- Control Buttons Frame
local controlFrame = Instance.new("Frame")
controlFrame.Name = "ControlFrame"
controlFrame.Size = UDim2.new(1, -14, 0, 35)
controlFrame.Position = UDim2.new(0, 7, 1, -40)
controlFrame.BackgroundTransparency = 1
controlFrame.Parent = mainFrame

-- Spam Button
local spamBtn = Instance.new("TextButton")
spamBtn.Name = "SpamBtn"
spamBtn.Size = UDim2.new(0.48, 0, 1, 0)
spamBtn.Position = UDim2.new(0, 0, 0, 0)
spamBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
spamBtn.Text = "START"
spamBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
spamBtn.TextSize = 12
spamBtn.Font = Enum.Font.GothamBold
spamBtn.BorderSizePixel = 0
spamBtn.Parent = controlFrame

local spamCorner = Instance.new("UICorner")
spamCorner.CornerRadius = UDim.new(0, 6)
spamCorner.Parent = spamBtn

-- Stop Button
local stopBtn = Instance.new("TextButton")
stopBtn.Name = "StopBtn"
stopBtn.Size = UDim2.new(0.48, 0, 1, 0)
stopBtn.Position = UDim2.new(0.52, 0, 0, 0)
stopBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
stopBtn.Text = "STOP"
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.TextSize = 12
stopBtn.Font = Enum.Font.GothamBold
stopBtn.BorderSizePixel = 0
stopBtn.Parent = controlFrame

local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius = UDim.new(0, 6)
stopCorner.Parent = stopBtn

local floatingBtn = Instance.new("TextButton")
floatingBtn.Name = "FloatingBtn"
floatingBtn.Size = UDim2.new(0, 41, 0, 41)
floatingBtn.Position = UDim2.new(1, -70, 0, 20)
floatingBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
floatingBtn.Text = "🦊"
floatingBtn.TextSize = 20
floatingBtn.Font = Enum.Font.GothamBold
floatingBtn.BorderSizePixel = 0
floatingBtn.Visible = false
floatingBtn.Parent = screenGui
floatingBtn.Draggable = true

local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(0, 12)
floatCorner.Parent = floatingBtn

-- Spam Function
local function startSpam()
    isSpamming = true
    spamBtn.Text = "SPAMMING..."
    spamBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
    
    -- Notification
    getgenv().Notify({
        Title = 'SPAM STARTED', 
        Content = 'Spamming is now active!', 
        Duration = 3
    })
    
    spawn(function()
        while isSpamming do
            if tick() - lastChangeTime >= CHANGE_INTERVAL then
                local availableMessages = {}
                for i, msg in ipairs(savedMessages) do
                    if msg and msg ~= "" then
                        table.insert(availableMessages, msg)
                    end
                end
                
                if #availableMessages > 0 then
                    currentMessageIndex = math.random(1, #availableMessages)
                    lastChangeTime = tick()
                end
            end
            
            local availableMessages = {}
            for i, msg in ipairs(savedMessages) do
                if msg and msg ~= "" then
                    table.insert(availableMessages, msg)
                end
            end
            
            if #availableMessages > 0 then
                local currentMessage = availableMessages[currentMessageIndex]
                
                pcall(function()
                    local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                    if channel then
                        channel:SendAsync(currentMessage)
                    end
                end)
                
                pcall(function()
                    ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(currentMessage, "All")
                end)
            end
            
            wait(DELAY)
        end
    end)
end

local function stopSpam()
    isSpamming = false
    spamBtn.Text = "START"
    spamBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    
    -- Notification
    getgenv().Notify({
        Title = 'SPAM STOPPED', 
        Content = 'Spamming has been disabled!', 
        Duration = 3
    })
end

-- Button Connections
spamBtn.MouseButton1Click:Connect(function()
    if not isSpamming then
        startSpam()
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    stopSpam()
end)

minimizeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    floatingBtn.Visible = true
end)

floatingBtn.MouseButton1Click:Connect(function()
    floatingBtn.Visible = false
    mainFrame.Visible = true
end)

closeBtn.MouseButton1Click:Connect(function()
    stopSpam()
    screenGui:Destroy()
end)

-- Make GUI Draggable
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Hover Effects
local function addHoverEffect(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = hoverColor
    end)
    
    button.MouseLeave:Connect(function()
        if button == spamBtn and isSpamming then
            button.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
        else
            button.BackgroundColor3 = normalColor
        end
    end)
end

addHoverEffect(minimizeBtn, Color3.fromRGB(30, 30, 35), Color3.fromRGB(50, 50, 55))
addHoverEffect(closeBtn, Color3.fromRGB(180, 50, 50), Color3.fromRGB(220, 70, 70))
addHoverEffect(spamBtn, Color3.fromRGB(70, 130, 255), Color3.fromRGB(90, 150, 255))
addHoverEffect(stopBtn, Color3.fromRGB(180, 0, 0), Color3.fromRGB(220, 70, 70))