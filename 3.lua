

local cloneref = cloneref or function(...) return ... end

local Services = setmetatable({}, {
    __index = function(_, name)
        return cloneref(game:GetService(name))
    end
})

local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService

local player = Players.LocalPlayer

loadstring(game:HttpGet("https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/han.lua"))()

-- SPECTATOR GUI
local spectatorGui = Instance.new("ScreenGui")
spectatorGui.Name = "SIEXTHERSpectator"
spectatorGui.ResetOnSpawn = false
spectatorGui.DisplayOrder = 999 
spectatorGui.Parent = Services.CoreGui
spectatorGui.Enabled = true

local spectatorFrame = Instance.new("Frame")
spectatorFrame.Size = UDim2.new(0, 280, 0, 50)
spectatorFrame.Position = UDim2.new(0.5, -140, 1, -70)
spectatorFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
spectatorFrame.BorderSizePixel = 0
spectatorFrame.Parent = spectatorGui

local spectatorFrameCorner = Instance.new("UICorner", spectatorFrame)
spectatorFrameCorner.CornerRadius = UDim.new(0, 10)

local spectatorFrameStroke = Instance.new("UIStroke", spectatorFrame)
spectatorFrameStroke.Color = Color3.fromRGB(70, 130, 255)
spectatorFrameStroke.Thickness = 2

-- Close Button (X) - Di pojok kanan atas layar
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 41, 0, 41)
closeBtn.Position = UDim2.new(1, -70, 0, -45)  
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 23
closeBtn.Parent = spectatorGui

local closeBtnCorner = Instance.new("UICorner", closeBtn)
closeBtnCorner.CornerRadius = UDim.new(0, 12)

local prevBtn = Instance.new("TextButton")
prevBtn.Size = UDim2.new(0, 40, 0, 30)
prevBtn.Position = UDim2.new(0, 10, 0.5, -15)
prevBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
prevBtn.BorderSizePixel = 0
prevBtn.Text = "←"
prevBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
prevBtn.Font = Enum.Font.GothamBold
prevBtn.TextSize = 18
prevBtn.Parent = spectatorFrame

local prevBtnCorner = Instance.new("UICorner", prevBtn)
prevBtnCorner.CornerRadius = UDim.new(0, 7)

local playerNameLabel = Instance.new("TextLabel")
playerNameLabel.Size = UDim2.new(0, 170, 0, 30)
playerNameLabel.Position = UDim2.new(0, 55, 0.5, -15)
playerNameLabel.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
playerNameLabel.BorderSizePixel = 0
playerNameLabel.Text = "NO PLAYER"
playerNameLabel.TextColor3 = Color3.fromRGB(70, 130, 255)
playerNameLabel.Font = Enum.Font.GothamBold
playerNameLabel.TextSize = 13
playerNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
playerNameLabel.Parent = spectatorFrame

local playerNameCorner = Instance.new("UICorner", playerNameLabel)
playerNameCorner.CornerRadius = UDim.new(0, 7)

local nextBtn = Instance.new("TextButton")
nextBtn.Size = UDim2.new(0, 40, 0, 30)
nextBtn.Position = UDim2.new(1, -50, 0.5, -15)
nextBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
nextBtn.BorderSizePixel = 0
nextBtn.Text = "→"
nextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
nextBtn.Font = Enum.Font.GothamBold
nextBtn.TextSize = 18
nextBtn.Parent = spectatorFrame

local nextBtnCorner = Instance.new("UICorner", nextBtn)
nextBtnCorner.CornerRadius = UDim.new(0, 7)

-- SPECTATOR LOGIC
local spectatorEnabled = true
local spectatorIndex = 1
local spectatorPlayers = {}

local function updateSpectatorList()
    spectatorPlayers = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") then
            table.insert(spectatorPlayers, p)
        end
    end
end

local function spectatePlayer(targetPlayer)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") then
        workspace.CurrentCamera.CameraSubject = targetPlayer.Character.Humanoid
        playerNameLabel.Text = targetPlayer.DisplayName
    end
end

local function stopSpectating()
    workspace.CurrentCamera.CameraSubject = player.Character.Humanoid
    playerNameLabel.Text = "NO PLAYER"
end

-- Close Button Action
closeBtn.MouseButton1Click:Connect(function()
    spectatorEnabled = false
    spectatorGui.Enabled = false
    stopSpectating()
    getgenv().Notify({Title = "SPECTATOR", Content = "DIMATIKAN", Duration = 2})
end)

-- PREV BUTTON
prevBtn.MouseButton1Click:Connect(function()
    if spectatorEnabled and #spectatorPlayers > 0 then
        updateSpectatorList()
        spectatorIndex = spectatorIndex - 1
        if spectatorIndex < 1 then spectatorIndex = #spectatorPlayers end
        spectatePlayer(spectatorPlayers[spectatorIndex])
    end
end)

-- NEXT BUTTON
nextBtn.MouseButton1Click:Connect(function()
    if spectatorEnabled and #spectatorPlayers > 0 then
        updateSpectatorList()
        spectatorIndex = (spectatorIndex % #spectatorPlayers) + 1
        spectatePlayer(spectatorPlayers[spectatorIndex])
    end
end)

-- KEYBOARD CONTROLS
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not spectatorEnabled then return end
    
    if input.KeyCode == Enum.KeyCode.Left then
        prevBtn.MouseButton1Click:Fire()
    elseif input.KeyCode == Enum.KeyCode.Right then
        nextBtn.MouseButton1Click:Fire()
    end
end)

-- Auto start spectating
updateSpectatorList()
if #spectatorPlayers > 0 then
    spectatorIndex = 1
    spectatePlayer(spectatorPlayers[spectatorIndex])
    getgenv().Notify({Title = "SPECTATOR", Content = "AKTIF", Duration = 2})
else
    getgenv().Notify({Title = "SPECTATOR", Content = "TIDAK ADA PLAYER", Duration = 2})
end

