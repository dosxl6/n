-- SIEXTHER
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SIEXTHERxFLING"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 350)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Main Frame Stroke
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(70, 130, 255)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- Main Frame Corner
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

-- Title Bar Corner
local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

-- Title Bar Bottom Cover (to square bottom corners)
local TitleCover = Instance.new("Frame")
TitleCover.Size = UDim2.new(1, 0, 0, 10)
TitleCover.Position = UDim2.new(0, 0, 1, -10)
TitleCover.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
TitleCover.BorderSizePixel = 0
TitleCover.Parent = TitleBar

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SIEXTHER FLING"
Title.TextColor3 = Color3.fromRGB(70, 130, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 17
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Position = UDim2.new(1, -35, 0.5, -12)
CloseButton.Size = UDim2.new(0, 24, 0, 24)
CloseButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 20
CloseButton.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

-- Minimize Button
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Position = UDim2.new(1, -65, 0.5, -12)
MinimizeButton.Size = UDim2.new(0, 24, 0, 24)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Text = "—"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 16
MinimizeButton.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinimizeButton

-- Restore Button (Minimized State)
local RestoreButton = Instance.new("TextButton")
RestoreButton.Size = UDim2.new(0, 41, 0, 41)
RestoreButton.Position = UDim2.new(0, 15, 0.5, -22.5)
RestoreButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
RestoreButton.BorderSizePixel = 0
RestoreButton.Text = "💀️"
RestoreButton.TextColor3 = Color3.fromRGB(70, 130, 255)
RestoreButton.Font = Enum.Font.GothamBold
RestoreButton.TextSize = 20
RestoreButton.Draggable = true
RestoreButton.Active = true
RestoreButton.Visible = false
RestoreButton.Parent = ScreenGui
RestoreButton.ZIndex = 5

local RestoreCorner = Instance.new("UICorner")
RestoreCorner.CornerRadius = UDim.new(0, 12)
RestoreCorner.Parent = RestoreButton

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Position = UDim2.new(0, 15, 0, 50)
StatusLabel.Size = UDim2.new(1, -30, 0, 25)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Pilih target untuk difling"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 14
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

-- Player Selection Frame
local SelectionFrame = Instance.new("Frame")
SelectionFrame.Position = UDim2.new(0, 15, 0, 80)
SelectionFrame.Size = UDim2.new(1, -30, 0, 175)
SelectionFrame.BackgroundColor3 = Color3.fromRGB(25, 30, 35)
SelectionFrame.BorderSizePixel = 0
SelectionFrame.Parent = MainFrame

local SelectionStroke = Instance.new("UIStroke")
SelectionStroke.Color = Color3.fromRGB(70, 130, 255)
SelectionStroke.Thickness = 1
SelectionStroke.Transparency = 0.5
SelectionStroke.Parent = SelectionFrame

local SelectionCorner = Instance.new("UICorner")
SelectionCorner.CornerRadius = UDim.new(0, 8)
SelectionCorner.Parent = SelectionFrame

-- Player List ScrollFrame
local PlayerScrollFrame = Instance.new("ScrollingFrame")
PlayerScrollFrame.Position = UDim2.new(0, 8, 0, 8)
PlayerScrollFrame.Size = UDim2.new(1, -16, 1, -16)
PlayerScrollFrame.BackgroundTransparency = 1
PlayerScrollFrame.BorderSizePixel = 0
PlayerScrollFrame.ScrollBarThickness = 4
PlayerScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
PlayerScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerScrollFrame.Parent = SelectionFrame

-- Start Fling Button
local StartButton = Instance.new("TextButton")
StartButton.Position = UDim2.new(0, 15, 0, 265)
StartButton.Size = UDim2.new(0.5, -20, 0, 38)
StartButton.BackgroundColor3 = Color3.fromRGB(50, 180, 100)
StartButton.BorderSizePixel = 0
StartButton.Text = "MULAI"
StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StartButton.Font = Enum.Font.GothamBold
StartButton.TextSize = 15
StartButton.Parent = MainFrame

local StartCorner = Instance.new("UICorner")
StartCorner.CornerRadius = UDim.new(0, 8)
StartCorner.Parent = StartButton

-- Stop Fling Button
local StopButton = Instance.new("TextButton")
StopButton.Position = UDim2.new(0.5, 5, 0, 265)
StopButton.Size = UDim2.new(0.5, -20, 0, 38)
StopButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
StopButton.BorderSizePixel = 0
StopButton.Text = "BERHENTI"
StopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StopButton.Font = Enum.Font.GothamBold
StopButton.TextSize = 15
StopButton.Parent = MainFrame

local StopCorner = Instance.new("UICorner")
StopCorner.CornerRadius = UDim.new(0, 8)
StopCorner.Parent = StopButton

-- Select/Deselect Buttons
local SelectAllButton = Instance.new("TextButton")
SelectAllButton.Position = UDim2.new(0, 15, 0, 312)
SelectAllButton.Size = UDim2.new(0.5, -20, 0, 28)
SelectAllButton.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
SelectAllButton.BorderSizePixel = 0
SelectAllButton.Text = "PILIH SEMUA"
SelectAllButton.TextColor3 = Color3.fromRGB(200, 200, 200)
SelectAllButton.Font = Enum.Font.Gotham
SelectAllButton.TextSize = 12
SelectAllButton.Parent = MainFrame

local SelectAllCorner = Instance.new("UICorner")
SelectAllCorner.CornerRadius = UDim.new(0, 6)
SelectAllCorner.Parent = SelectAllButton

local DeselectAllButton = Instance.new("TextButton")
DeselectAllButton.Position = UDim2.new(0.5, 5, 0, 312)
DeselectAllButton.Size = UDim2.new(0.5, -20, 0, 28)
DeselectAllButton.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
DeselectAllButton.BorderSizePixel = 0
DeselectAllButton.Text = "BATALKAN SEMUA"
DeselectAllButton.TextColor3 = Color3.fromRGB(200, 200, 200)
DeselectAllButton.Font = Enum.Font.Gotham
DeselectAllButton.TextSize = 12
DeselectAllButton.Parent = MainFrame

local DeselectAllCorner = Instance.new("UICorner")
DeselectAllCorner.CornerRadius = UDim.new(0, 6)
DeselectAllCorner.Parent = DeselectAllButton

-- Variables
local SelectedTargets = {}
local PlayerCheckboxes = {}
local FlingActive = false
local FlingConnection = nil
getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight

-- Function to update player list
local function RefreshPlayerList()
    for _, child in pairs(PlayerScrollFrame:GetChildren()) do
        child:Destroy()
    end
    PlayerCheckboxes = {}
    
    local PlayerList = Players:GetPlayers()
    table.sort(PlayerList, function(a, b) return a.Name:lower() < b.Name:lower() end)
    
    local yPosition = 5
    for _, player in ipairs(PlayerList) do
        if player ~= Player then
            local PlayerEntry = Instance.new("TextButton")
            PlayerEntry.Size = UDim2.new(1, -10, 0, 42)
            PlayerEntry.Position = UDim2.new(0, 5, 0, yPosition)
            PlayerEntry.BackgroundColor3 = Color3.fromRGB(35, 40, 48)
            PlayerEntry.BorderSizePixel = 0
            PlayerEntry.Text = ""
            PlayerEntry.AutoButtonColor = false
            PlayerEntry.Parent = PlayerScrollFrame
            
            local EntryCorner = Instance.new("UICorner")
            EntryCorner.CornerRadius = UDim.new(0, 6)
            EntryCorner.Parent = PlayerEntry
            
            local EntryStroke = Instance.new("UIStroke")
            EntryStroke.Color = Color3.fromRGB(70, 130, 255)
            EntryStroke.Thickness = 1
            EntryStroke.Transparency = 0.8
            EntryStroke.Parent = PlayerEntry
            
            -- Avatar Image
            local Avatar = Instance.new("ImageLabel")
            Avatar.Size = UDim2.new(0, 32, 0, 32)
            Avatar.Position = UDim2.new(0, 6, 0.5, -16)
            Avatar.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
            Avatar.BorderSizePixel = 0
            Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=48&h=48"
            Avatar.Parent = PlayerEntry
            
            local AvatarCorner = Instance.new("UICorner")
            AvatarCorner.CornerRadius = UDim.new(0.5, 0)
            AvatarCorner.Parent = Avatar
            
            -- Display Name
            local DisplayName = Instance.new("TextLabel")
            DisplayName.Size = UDim2.new(1, -50, 0, 16)
            DisplayName.Position = UDim2.new(0, 44, 0, 6)
            DisplayName.BackgroundTransparency = 1
            DisplayName.Text = player.DisplayName
            DisplayName.TextColor3 = Color3.fromRGB(220, 220, 220)
            DisplayName.TextSize = 13
            DisplayName.Font = Enum.Font.GothamBold
            DisplayName.TextXAlignment = Enum.TextXAlignment.Left
            DisplayName.TextTruncate = Enum.TextTruncate.AtEnd
            DisplayName.Parent = PlayerEntry
            
            -- Username
            local Username = Instance.new("TextLabel")
            Username.Size = UDim2.new(1, -50, 0, 14)
            Username.Position = UDim2.new(0, 44, 0, 22)
            Username.BackgroundTransparency = 1
            Username.Text = "@" .. player.Name
            Username.TextColor3 = Color3.fromRGB(140, 140, 140)
            Username.TextSize = 11
            Username.Font = Enum.Font.Gotham
            Username.TextXAlignment = Enum.TextXAlignment.Left
            Username.TextTruncate = Enum.TextTruncate.AtEnd
            Username.Parent = PlayerEntry
            
            PlayerEntry.MouseButton1Click:Connect(function()
                if SelectedTargets[player.Name] then
                    SelectedTargets[player.Name] = nil
                    PlayerEntry.BackgroundColor3 = Color3.fromRGB(35, 40, 48)
                else
                    SelectedTargets[player.Name] = player
                    PlayerEntry.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
                end
                UpdateStatus()
            end)
            
            -- Set initial state
            if SelectedTargets[player.Name] then
                PlayerEntry.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
            end
            
            PlayerCheckboxes[player.Name] = {
                Entry = PlayerEntry
            }
            
            yPosition = yPosition + 47
        end
    end
    
    PlayerScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPosition + 5)
end

local function CountSelectedTargets()
    local count = 0
    for _ in pairs(SelectedTargets) do
        count = count + 1
    end
    return count
end

local function UpdateStatus()
    local count = CountSelectedTargets()
    if FlingActive then
        StatusLabel.Text = "SIEXTHER FLING — " .. count .. " terpilih"
        StatusLabel.TextColor3 = Color3.fromRGB(70, 130, 255)
    else
        StatusLabel.Text = count .. " SIEXTHER FLING terpilih" 
        StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end

local function ToggleAllPlayers(select)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Player then
            local checkboxData = PlayerCheckboxes[player.Name]
            if checkboxData then
                if select then
                    SelectedTargets[player.Name] = player
                    checkboxData.Entry.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
                else
                    SelectedTargets[player.Name] = nil
                    checkboxData.Entry.BackgroundColor3 = Color3.fromRGB(35, 40, 48)
                end
            end
        end
    end
    UpdateStatus()
end

local function Message(Title, Text, Time)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = Title,
        Text = Text,
        Duration = Time or 5
    })
end

local function SkidFling(TargetPlayer)
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end
    
    local THumanoid, TRootPart, THead, Accessory, Handle
    if TCharacter:FindFirstChildOfClass("Humanoid") then
        THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    end
    if THumanoid and THumanoid.RootPart then
        TRootPart = THumanoid.RootPart
    end
    if TCharacter:FindFirstChild("Head") then
        THead = TCharacter.Head
    end
    if TCharacter:FindFirstChildOfClass("Accessory") then
        Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    end
    if Accessory and Accessory:FindFirstChild("Handle") then
        Handle = Accessory.Handle
    end
    
    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then
            getgenv().OldPos = RootPart.CFrame
        end
        
        if THumanoid and THumanoid.Sit then
            return Message("TERJADI MASALAH", TargetPlayer.Name .. " SEDANG DUDUK", 2)
        end
        
        if THead then
            workspace.CurrentCamera.CameraSubject = THead
        elseif Handle then
            workspace.CurrentCamera.CameraSubject = Handle
        elseif THumanoid and TRootPart then
            workspace.CurrentCamera.CameraSubject = THumanoid
        end
        
        if not TCharacter:FindFirstChildWhichIsA("BasePart") then
            return
        end
        
        local FPos = function(BasePart, Pos, Ang)
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
        
        local SFBasePart = function(BasePart)
            local TimeToWait = 2
            local Time = tick()
            local Angle = 0
            repeat
                if RootPart and THumanoid then
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = Angle + 100
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                    end
                end
            until Time + TimeToWait < tick() or not FlingActive
        end
        
        workspace.FallenPartsDestroyHeight = 0/0
        
        local BV = Instance.new("BodyVelocity")
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(0, 0, 0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        
        if TRootPart then
            SFBasePart(TRootPart)
        elseif THead then
            SFBasePart(THead)
        elseif Handle then
            SFBasePart(Handle)
        else
            return Message("TERJADI MASALAH", TargetPlayer.Name .. " TIDAK MEMILIKI BAGIAN YANG VALID", 2)
        end
        
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid
        
        if getgenv().OldPos then
            repeat
                RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState("GettingUp")
                for _, part in pairs(Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.Velocity, part.RotVelocity = Vector3.new(), Vector3.new()
                    end
                end
                task.wait()
            until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
            workspace.FallenPartsDestroyHeight = getgenv().FPDH
        end
    else
        return Message("TERJADI MASALAH", "KARAKTER KAMU BELUM SIAP", 2)
    end
end

local function StartFling()
    if FlingActive then return end
    
    local count = CountSelectedTargets()
    if count == 0 then
        StatusLabel.Text = "Tidak ada target yang dipilih!"
        wait(1)
        StatusLabel.Text = "Pilih target untuk difling"
        return
    end
    
    FlingActive = true
    UpdateStatus()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/han.lua"))()
    getgenv().Notify({Title = 'SIEXTHER FLING', Content = "FLINGING " .. count .. " target", Duration = 4})
    
    spawn(function()
        while FlingActive do
            local validTargets = {}
            
            for name, player in pairs(SelectedTargets) do
                if player and player.Parent then
                    validTargets[name] = player
                else
                    SelectedTargets[name] = nil
                    local checkbox = PlayerCheckboxes[name]
                    if checkbox then
                        checkbox.Entry.BackgroundColor3 = Color3.fromRGB(35, 40, 48)
                    end
                end
            end
            
            for _, player in pairs(validTargets) do
                if FlingActive then
                    SkidFling(player)
                    wait(0.1)
                else
                    break
                end
            end
            
            UpdateStatus()
            wait(0.5)
        end
    end)
end

local function StopFling()
    if not FlingActive then return end
    FlingActive = false
    UpdateStatus()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/han.lua"))()
    getgenv().Notify({Title = 'SIEXTHER FLING', Content = 'FLING TELAH DIHENTIKAN', Duration = 2})
end

StartButton.MouseButton1Click:Connect(StartFling)
StopButton.MouseButton1Click:Connect(StopFling)
SelectAllButton.MouseButton1Click:Connect(function() ToggleAllPlayers(true) end)
DeselectAllButton.MouseButton1Click:Connect(function() ToggleAllPlayers(false) end)
CloseButton.MouseButton1Click:Connect(function()
    StopFling()
    ScreenGui:Destroy()
end)

MinimizeButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    RestoreButton.Visible = true
end)

RestoreButton.MouseButton1Click:Connect(function()
    RestoreButton.Visible = false
    MainFrame.Visible = true
end)

Players.PlayerAdded:Connect(RefreshPlayerList)
Players.PlayerRemoving:Connect(function(player)
    if SelectedTargets[player.Name] then
        SelectedTargets[player.Name] = nil
    end
    RefreshPlayerList()
    UpdateStatus()
end)

RefreshPlayerList()
UpdateStatus()