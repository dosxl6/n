local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer
local PlayerGui = game.CoreGui

local NotificationGui = Instance.new("ScreenGui")
NotificationGui.Name = "NotificationSystem"
NotificationGui.Parent = PlayerGui
NotificationGui.ResetOnSpawn = false

-- PLAY SOUND BY HANN.SXHTR
local SoundService = game:GetService("SoundService")
local function playSound(soundId)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. soundId
    sound.Parent = SoundService
    sound.Volume = 1.5
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

local activeNotifications = {}
local notificationCount = 0

local NOTIFICATION_WIDTH = 280
local NOTIFICATION_HEIGHT = 75
local NOTIFICATION_SPACING = 10
local SLIDE_DISTANCE = 400
local ANIMATION_SPEED = 0.5

local function createNotification(title, content, duration)
    notificationCount = notificationCount + 1

    -- Main Frame
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "Notification_" .. notificationCount
    notificationFrame.Size = UDim2.new(0, NOTIFICATION_WIDTH, 0, NOTIFICATION_HEIGHT)
    notificationFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    notificationFrame.BackgroundTransparency = 0.05
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Parent = NotificationGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notificationFrame
    
    playSound("18723584764")

    -- Sky Blue Stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(70, 130, 255) -- Sky Blue
    stroke.Thickness = 2
    stroke.Transparency = 0
    stroke.Parent = notificationFrame

    -- Title Label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -50, 0, 24)
    titleLabel.Position = UDim2.new(0, 12, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 15
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.Parent = notificationFrame

    -- Content Label
    local contentLabel = Instance.new("TextLabel")
    contentLabel.Name = "Content"
    contentLabel.Size = UDim2.new(1, -50, 0, 20)
    contentLabel.Position = UDim2.new(0, 12, 0, 32)
    contentLabel.BackgroundTransparency = 1
    contentLabel.Text = content
    contentLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    contentLabel.TextSize = 12
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.TextYAlignment = Enum.TextYAlignment.Top
    contentLabel.Font = Enum.Font.Gotham
    contentLabel.TextWrapped = true
    contentLabel.Parent = notificationFrame

    -- Progress Bar Container
    local progressContainer = Instance.new("Frame")
    progressContainer.Name = "ProgressContainer"
    progressContainer.Size = UDim2.new(1, -24, 0, 3)
    progressContainer.Position = UDim2.new(0, 12, 1, -10)
    progressContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    progressContainer.BackgroundTransparency = 0.3
    progressContainer.BorderSizePixel = 0
    progressContainer.Parent = notificationFrame

    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(1, 0)
    progressCorner.Parent = progressContainer

    -- Progress Bar
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(1, 0, 1, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressContainer

    local progressBarCorner = Instance.new("UICorner")
    progressBarCorner.CornerRadius = UDim.new(1, 0)
    progressBarCorner.Parent = progressBar

    -- Close Button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -38, 0, 8)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(180, 180, 200)
    closeButton.TextSize = 24
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = notificationFrame

    -- Close Button Hover Effect
    closeButton.MouseEnter:Connect(function()
        TweenService:Create(closeButton, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(255, 80, 80)
        }):Play()
    end)

    closeButton.MouseLeave:Connect(function()
        TweenService:Create(closeButton, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(180, 180, 200)
        }):Play()
    end)

    local yPosition = (#activeNotifications * (NOTIFICATION_HEIGHT + NOTIFICATION_SPACING)) + 50
    notificationFrame.Position = UDim2.new(1, SLIDE_DISTANCE, 0, yPosition)
    table.insert(activeNotifications, notificationFrame)

    local function updatePositions()
        for i, notification in ipairs(activeNotifications) do
            local newY = ((i - 1) * (NOTIFICATION_HEIGHT + NOTIFICATION_SPACING)) + 50
            local tweenInfo = TweenInfo.new(ANIMATION_SPEED, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            local tween = TweenService:Create(notification, tweenInfo, {
                Position = UDim2.new(1, -NOTIFICATION_WIDTH - 20, 0, newY)
            })
            tween:Play()
        end
    end

    -- Slide In Animation
    local slideInTween = TweenService:Create(notificationFrame, 
        TweenInfo.new(ANIMATION_SPEED, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -NOTIFICATION_WIDTH - 20, 0, yPosition)}
    )
    slideInTween:Play()

    local function removeNotification()
        for i, notification in ipairs(activeNotifications) do
            if notification == notificationFrame then
                table.remove(activeNotifications, i)
                break
            end
        end

        -- Fade out animation
        local fadeOutTween = TweenService:Create(notificationFrame,
            TweenInfo.new(ANIMATION_SPEED * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        )
        
        local strokeFadeTween = TweenService:Create(stroke,
            TweenInfo.new(ANIMATION_SPEED * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Transparency = 1}
        )

        local slideOutTween = TweenService:Create(notificationFrame,
            TweenInfo.new(ANIMATION_SPEED, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            {Position = UDim2.new(1, SLIDE_DISTANCE, 0, notificationFrame.Position.Y.Offset)}
        )

        fadeOutTween:Play()
        strokeFadeTween:Play()
        slideOutTween:Play()

        slideOutTween.Completed:Connect(function()
            notificationFrame:Destroy()
            updatePositions()
        end)
    end

    closeButton.MouseButton1Click:Connect(removeNotification)

    -- Progress Bar Animation
    if duration and duration > 0 then
        -- Animate progress bar shrinking
        local progressTween = TweenService:Create(progressBar,
            TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
            {Size = UDim2.new(0, 0, 1, 0)}
        )

        progressTween:Play()

        progressTween.Completed:Connect(function()
            if notificationFrame.Parent then
                removeNotification()
            end
        end)
    end
end

getgenv().Notify = function(options)
    local title = options.Title or "Notification"
    local content = options.Content or "No content provided"
    local duration = options.Duration or 5
    task.spawn(function()
        createNotification(title, content, duration)
    end)
end