local Gui = Instance.new("ScreenGui")
local Main = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local MainStroke = Instance.new("UIStroke")
local TopBar = Instance.new("Frame")
local UICorner_2 = Instance.new("UICorner")
local Label = Instance.new("TextLabel")
local CloseButton = Instance.new("TextButton")
local UICorner_3 = Instance.new("UICorner")
local MinimizeButton = Instance.new("TextButton")
local UICorner_4 = Instance.new("UICorner")
local ContentFrame = Instance.new("Frame")
local UICorner_5 = Instance.new("UICorner")
local SearchBox = Instance.new("TextBox")
local UICorner_6 = Instance.new("UICorner")
local SearchIcon = Instance.new("TextLabel")
local PlayerList = Instance.new("ScrollingFrame")
local UIListLayout = Instance.new("UIListLayout")
local UIPadding = Instance.new("UIPadding")
local ButtonContainer = Instance.new("Frame")
local UICorner_7 = Instance.new("UICorner")
local Button = Instance.new("TextButton")
local UICorner_8 = Instance.new("UICorner")
local ButtonGradient = Instance.new("UIGradient")
local BringAllButton = Instance.new("TextButton")
local UICorner_9 = Instance.new("UICorner")
local ButtonGradient_2 = Instance.new("UIGradient")
local MinimizedButton = Instance.new("TextButton")
local UICorner_10 = Instance.new("UICorner")
local TargetInfo = Instance.new("TextLabel")
local UICorner_12 = Instance.new("UICorner")

--Properties:
local controlledParts = {}
local descendantConnection = nil
local renderLoop = nil

-- PartOrbit Variables
local getpart = 300
local currentMode = 2
local radius = 50
local speed = 2
local isActive = true
local lastValidPosition = Vector3.new(0, 0, 0)
local UPDATE_INTERVAL = 0
local lastUpdate = tick()
local ringParts = {}

Gui.Name = "IlhanSiextherBring"
Gui.Parent = gethui()
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Main.Name = "Main"
Main.Parent = Gui
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BackgroundTransparency = 0.05
Main.BorderSizePixel = 0
Main.Position = UDim2.new(0.5, -130, 0.5, -180)
Main.Size = UDim2.new(0, 260, 0, 320)
Main.Active = true
Main.Draggable = true
Main.ZIndex = 1

UICorner.CornerRadius = UDim.new(0, 16)
UICorner.Parent = Main

MainStroke.Name = "MainStroke"
MainStroke.Parent = Main
MainStroke.Color = Color3.fromRGB(70, 130, 255)
MainStroke.Thickness = 2
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

TopBar.Name = "TopBar"
TopBar.Parent = Main
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
TopBar.BackgroundTransparency = 0
TopBar.BorderSizePixel = 0
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.ZIndex = 2

UICorner_2.CornerRadius = UDim.new(0, 16)
UICorner_2.Parent = TopBar

Label.Name = "Label"
Label.Parent = TopBar
Label.BackgroundTransparency = 1
Label.Position = UDim2.new(0.04, 0, 0, 0)
Label.Size = UDim2.new(0.65, 0, 1, 0)
Label.Font = Enum.Font.GothamBold
Label.Text = "SIEXTHER BRING"
Label.TextColor3 = Color3.fromRGB(70, 130, 255)
Label.TextScaled = true
Label.TextSize = 16
Label.TextWrapped = true
Label.TextXAlignment = Enum.TextXAlignment.Left
Label.ZIndex = 3

local LabelPadding = Instance.new("UIPadding")
LabelPadding.Parent = Label
LabelPadding.PaddingLeft = UDim.new(0, 15)

MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Parent = TopBar
MinimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Position = UDim2.new(1, -63, 0, 5)
MinimizeButton.Size = UDim2.new(0, 28, 0, 23)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Text = "–"
MinimizeButton.TextColor3 = Color3.fromRGB(70, 130, 255)
MinimizeButton.TextSize = 18
MinimizeButton.ZIndex = 3

UICorner_4.CornerRadius = UDim.new(0, 8)
UICorner_4.Parent = MinimizeButton

CloseButton.Name = "CloseButton"
CloseButton.Parent = TopBar
CloseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
CloseButton.BorderSizePixel = 0
CloseButton.Position = UDim2.new(1, -30, 0, 5)
CloseButton.Size = UDim2.new(0, 28, 0, 23)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 80, 90)
CloseButton.TextSize = 20
CloseButton.ZIndex = 3

UICorner_3.CornerRadius = UDim.new(0, 8)
UICorner_3.Parent = CloseButton

ContentFrame.Name = "ContentFrame"
ContentFrame.Parent = Main
ContentFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
ContentFrame.BackgroundTransparency = 0
ContentFrame.BorderSizePixel = 0
ContentFrame.Position = UDim2.new(0.05, 0, 0, 45)
ContentFrame.Size = UDim2.new(0.9, 0, 0, 265)
ContentFrame.ZIndex = 2

UICorner_5.CornerRadius = UDim.new(0, 12)
UICorner_5.Parent = ContentFrame

SearchBox.Name = "SearchBox"
SearchBox.Parent = ContentFrame
SearchBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
SearchBox.BackgroundTransparency = 0
SearchBox.BorderSizePixel = 0
SearchBox.Position = UDim2.new(0.05, 0, 0, 8)
SearchBox.Size = UDim2.new(0.9, 0, 0, 30)
SearchBox.Font = Enum.Font.Gotham
SearchBox.PlaceholderText = "Search players..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(200, 200, 220)
SearchBox.TextSize = 13
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ZIndex = 3

UICorner_6.CornerRadius = UDim.new(0, 10)
UICorner_6.Parent = SearchBox

local SearchPadding = Instance.new("UIPadding")
SearchPadding.Parent = SearchBox
SearchPadding.PaddingLeft = UDim.new(0, 12)
SearchPadding.PaddingRight = UDim.new(0, 12)

PlayerList.Name = "PlayerList"
PlayerList.Parent = ContentFrame
PlayerList.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
PlayerList.BackgroundTransparency = 0
PlayerList.BorderSizePixel = 0
PlayerList.Position = UDim2.new(0.05, 0, 0, 46)
PlayerList.Size = UDim2.new(0.9, 0, 0, 140)
PlayerList.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerList.ScrollBarThickness = 3
PlayerList.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
PlayerList.ZIndex = 3

UIListLayout.Parent = PlayerList
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

UIPadding.Parent = PlayerList
UIPadding.PaddingTop = UDim.new(0, 6)
UIPadding.PaddingLeft = UDim.new(0, 6)
UIPadding.PaddingRight = UDim.new(0, 6)

ButtonContainer.Name = "ButtonContainer"
ButtonContainer.Parent = ContentFrame
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Position = UDim2.new(0.05, 0, 0, 220)
ButtonContainer.Size = UDim2.new(0.9, 0, 0, 50)
ButtonContainer.ZIndex = 2

TargetInfo.Name = "TargetInfo"
TargetInfo.Parent = ContentFrame
TargetInfo.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TargetInfo.BackgroundTransparency = 0
TargetInfo.BorderSizePixel = 0
TargetInfo.Position = UDim2.new(0.05, 0, 0, 192)
TargetInfo.Size = UDim2.new(0.9, 0, 0, 22)
TargetInfo.Font = Enum.Font.GothamBold
TargetInfo.Text = "Target: None"
TargetInfo.TextColor3 = Color3.fromRGB(70, 130, 255)
TargetInfo.TextSize = 13
TargetInfo.TextWrapped = true
TargetInfo.ZIndex = 3
TargetInfo.Visible = false

UICorner_12.CornerRadius = UDim.new(0, 10)
UICorner_12.Parent = TargetInfo

Button.Name = "Button"
Button.Parent = ButtonContainer
Button.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
Button.BorderSizePixel = 0
Button.Position = UDim2.new(0, 0, 0, 0)
Button.Size = UDim2.new(1, 0, 0, 22)
Button.Font = Enum.Font.GothamBold
Button.Text = "BRING SINGLE | OFF"
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.TextSize = 14
Button.ZIndex = 3

UICorner_8.CornerRadius = UDim.new(0, 10)
UICorner_8.Parent = Button

BringAllButton.Name = "BringAllButton"
BringAllButton.Parent = ButtonContainer
BringAllButton.BackgroundColor3 = Color3.fromRGB(255, 80, 100)
BringAllButton.BorderSizePixel = 0
BringAllButton.Position = UDim2.new(0, 0, 0, 28)
BringAllButton.Size = UDim2.new(1, 0, 0, 22)
BringAllButton.Font = Enum.Font.GothamBold
BringAllButton.Text = "BRING RANDOM | OFF"
BringAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BringAllButton.TextSize = 14
BringAllButton.ZIndex = 3

UICorner_9.CornerRadius = UDim.new(0, 10)
UICorner_9.Parent = BringAllButton

MinimizedButton.Name = "MinimizedButton"
MinimizedButton.Parent = Gui
MinimizedButton.BorderSizePixel = 0
MinimizedButton.Size = UDim2.new(0, 41, 0, 41)
MinimizedButton.Position = UDim2.new(0, 15, 0, 60)
MinimizedButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MinimizedButton.Font = Enum.Font.GothamBold
MinimizedButton.Text = "☠️"
MinimizedButton.TextColor3 = Color3.fromRGB(70, 130, 255)
MinimizedButton.TextSize = 20
MinimizedButton.Visible = false
MinimizedButton.Draggable = true
MinimizedButton.ZIndex = 5

UICorner_10.CornerRadius = UDim.new(0, 12)
UICorner_10.Parent = MinimizedButton

local MinimizedStroke = Instance.new("UIStroke")
MinimizedStroke.Parent = MinimizedButton
MinimizedStroke.Color = Color3.fromRGB(70, 130, 255)
MinimizedStroke.Thickness = 2

-- Scripts:

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local character
local humanoidRootPart
local selectedPlayer = nil
local allPlayersTargets = {}

-- Hover effects
local function addHoverEffect(button, normalColor, hoverColor)
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = normalColor}):Play()
	end)
end

addHoverEffect(CloseButton, Color3.fromRGB(40, 40, 50), Color3.fromRGB(255, 80, 90))
addHoverEffect(MinimizeButton, Color3.fromRGB(40, 40, 50), Color3.fromRGB(70, 130, 255))

-- Toggle visibility
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if input.KeyCode == Enum.KeyCode.RightControl and not gameProcessedEvent then
		if Main.Visible then
			Main.Visible = false
			MinimizedButton.Visible = true
		else
			Main.Visible = true
			MinimizedButton.Visible = false
		end
	end
end)

local Folder = Instance.new("Folder", Workspace)
local Part = Instance.new("Part", Folder)
local Attachment1 = Instance.new("Attachment", Part)
Part.Anchored = true
Part.CanCollide = false
Part.Transparency = 1

-- Network setup
if not getgenv().Network then
    getgenv().Network = {
        BaseParts = {},
        FPS = 20,
        Velocity = Vector3.new(25.1, 0, 0)
    }
    
    local function EnableNetwork()
        local function UpdateNetwork()
            if not isActive then return end
            pcall(function()
                sethiddenproperty(LocalPlayer, "MaxSimulationRadius", getpart)
                sethiddenproperty(LocalPlayer, "SimulationRadius", getpart)
            end)
            local partsToProcess = {}
            for part in pairs(Network.BaseParts) do
                table.insert(partsToProcess, part)
            end
            for _, part in ipairs(partsToProcess) do
                if not part or not part.Parent then
                    Network.BaseParts[part] = nil
                    continue
                end
                pcall(function()
                    sethiddenproperty(part, "NetworkOwnership", Enum.NetworkOwnership.Manual)
                    sethiddenproperty(part, "CustomPhysicalProperties", PhysicalProperties.new(0.7, 0.3, 0.5))
                    part.Velocity = Network.Velocity
                end)
            end
        end
        RunService.Heartbeat:Connect(UpdateNetwork)
    end
    EnableNetwork()
end

-- PartOrbit Functions
local function processPart(part)
    if part:IsA("Part") and not part.Anchored and 
       not part.Parent:FindFirstChild("Humanoid") and 
       not part.Parent:FindFirstChild("Head") and 
       part.Name ~= "Handle" then
        
        if not pcall(function() return part.Parent end) then
            return nil
        end
        
        for _, child in pairs(part:GetChildren()) do
            if child:IsA("BodyAngularVelocity") or child:IsA("BodyForce") or 
               child:IsA("BodyGyro") or child:IsA("BodyPosition") or 
               child:IsA("BodyThrust") or child:IsA("BodyVelocity") or 
               child:IsA("RocketPropulsion") or child:IsA("Attachment") or 
               child:IsA("AlignPosition") or child:IsA("AlignOrientation") or 
               child:IsA("LinearVelocity") or child:IsA("BodyMover") then
                child:Destroy()
            end
        end
        
        part.CanCollide = false
        part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        
        local attachment = Instance.new("Attachment", part)
        local alignPos = Instance.new("AlignPosition", part)
        alignPos.Attachment0 = attachment
        alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
        alignPos.Responsiveness = 200
        
        return {
            part = part,
            align = alignPos,
            index = 0
        }
    end
    return nil
end

local function calculateRingPosition(index, totalParts, center)
    local angle = (index / totalParts) * (2 * math.pi) + tick() * speed
    local offsetX, offsetY, offsetZ = 0, 0, 0
    
    if currentMode == 2 then
        offsetX = math.cos(angle) * radius
        offsetZ = math.sin(angle) * radius
    end
    
    return center + Vector3.new(offsetX, offsetY, offsetZ)
end

local function updateRingPositions()
    if not isActive then return end
    local currentTime = tick()
    if currentTime - lastUpdate < UPDATE_INTERVAL then return end
    lastUpdate = currentTime
    local position = (humanoidRootPart and humanoidRootPart.Position) or lastValidPosition
    if position then
        lastValidPosition = position
        local totalParts = #ringParts
        for i = #ringParts, 1, -1 do
            local data = ringParts[i]
            local validPart = pcall(function() return data.part.Parent ~= nil end)
            if validPart then
                local targetPos = calculateRingPosition(i, totalParts, position)
                data.align.Position = targetPos
            else
                Network.BaseParts[data.part] = nil
                table.remove(ringParts, i)
            end
        end
    end
end

local function initializePartOrbit()
    ringParts = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        local partData = processPart(v)
        if partData then
            table.insert(ringParts, partData)
            Network.BaseParts[partData.part] = true
        end
    end
    
    local connection
    connection = Workspace.DescendantAdded:Connect(function(v)
        if not isActive then
            connection:Disconnect()
            return
        end
        local partData = processPart(v)
        if partData then
            table.insert(ringParts, partData)
            Network.BaseParts[partData.part] = true
        end
    end)
    
    RunService.Heartbeat:Connect(updateRingPositions)
end

local function ForcePart(v)
    if v:IsA("Part") and not v.Anchored and not v.Parent:FindFirstChild("Humanoid") and not v.Parent:FindFirstChild("Head") and v.Name ~= "Handle" then
        for _, x in next, v:GetChildren() do
            if x:IsA("BodyAngularVelocity") or x:IsA("BodyForce") or x:IsA("BodyGyro") or x:IsA("BodyPosition") or x:IsA("BodyThrust") or x:IsA("BodyVelocity") or x:IsA("RocketPropulsion") then
                x:Destroy()
            end
        end
        if v:FindFirstChild("Attachment") then v:FindFirstChild("Attachment"):Destroy() end
        if v:FindFirstChild("AlignPosition") then v:FindFirstChild("AlignPosition"):Destroy() end
        if v:FindFirstChild("Torque") then v:FindFirstChild("Torque"):Destroy() end
        v.CanCollide = false
        local Torque = Instance.new("Torque", v)
        Torque.Torque = Vector3.new(1000000, 1000000, 1000000)
        local AlignPosition = Instance.new("AlignPosition", v)
        local Attachment2 = Instance.new("Attachment", v)
        Torque.Attachment0 = Attachment2
        AlignPosition.MaxForce = math.huge
        AlignPosition.MaxVelocity = math.huge
        AlignPosition.Responsiveness = 500
        AlignPosition.Attachment0 = Attachment2
        AlignPosition.Attachment1 = Attachment1
        controlledParts[v] = {
            Torque = Torque,
            AlignPosition = AlignPosition,
            Attachment = Attachment2
        }
    end
end

local function releaseAllParts()
    for part, constraints in pairs(controlledParts) do
        if part and part.Parent then
            for _, constraint in pairs(constraints) do
                if constraint and constraint.Parent then
                    constraint:Destroy()
                end
            end
        end
    end
    controlledParts = {}
end

-- Function to get nearest player
local function getNearestPlayer()
	if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
		return nil
	end
	
	local myPos = LocalPlayer.Character.HumanoidRootPart.Position
	local nearestPlayer = nil
	local shortestDistance = math.huge
	
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local distance = (player.Character.HumanoidRootPart.Position - myPos).Magnitude
			if distance < shortestDistance then
				shortestDistance = distance
				nearestPlayer = player
			end
		end
	end
	
	return nearestPlayer
end

local blackHoleActive = false
local bringAllActive = false
local DescendantAddedConnection

local function toggleBlackHole()
	blackHoleActive = not blackHoleActive
	if blackHoleActive then
		Button.Text = "BRING SELECTED | ON"
		Button.BackgroundColor3 = Color3.fromRGB(50, 255, 100)
		ButtonGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 255, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 200, 80))
		}
		
		for _, v in ipairs(Workspace:GetDescendants()) do
			ForcePart(v)
		end

		DescendantAddedConnection = Workspace.DescendantAdded:Connect(function(v)
			if blackHoleActive then
				ForcePart(v)
			end
		end)

		spawn(function()
			while blackHoleActive and RunService.RenderStepped:Wait() do
				if humanoidRootPart then
					Attachment1.WorldCFrame = humanoidRootPart.CFrame
				end
			end
		end)
	else
		Button.Text = "BRING SELECTED | OFF"
		Button.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
		ButtonGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 130, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 100, 200))
		}
		if DescendantAddedConnection then
			DescendantAddedConnection:Disconnect()
		end
	end
end

local bringAllConnection

local function toggleBringAll()
	bringAllActive = not bringAllActive
	if bringAllActive then
		BringAllButton.Text = "BRING RANDOM | ON"
		BringAllButton.BackgroundColor3 = Color3.fromRGB(50, 255, 100)
		ButtonGradient_2.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 255, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 200, 80))
		}
		
		for _, v in ipairs(Workspace:GetDescendants()) do
			ForcePart(v)
		end

		DescendantAddedConnection = Workspace.DescendantAdded:Connect(function(v)
			if bringAllActive then
				ForcePart(v)
			end
		end)

		bringAllConnection = RunService.RenderStepped:Connect(function()
			if bringAllActive then
				local nearestPlayer = getNearestPlayer()
				if nearestPlayer and nearestPlayer.Character and nearestPlayer.Character:FindFirstChild("HumanoidRootPart") then
					Attachment1.WorldCFrame = nearestPlayer.Character.HumanoidRootPart.CFrame
					TargetInfo.Text = "Targeting: " .. nearestPlayer.DisplayName .. " (@" .. nearestPlayer.Name .. ")"
					TargetInfo.Visible = true
				else
					TargetInfo.Text = "No nearby players"
					TargetInfo.Visible = true
				end
			end
		end)
	else
		BringAllButton.Text = "BRING RANDOM | OFF"
		BringAllButton.BackgroundColor3 = Color3.fromRGB(255, 80, 100)
		ButtonGradient_2.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 60, 80))
		}
		TargetInfo.Visible = false
		TargetInfo.Text = "Target: None"
		if DescendantAddedConnection then
			DescendantAddedConnection:Disconnect()
		end
		if bringAllConnection then
			bringAllConnection:Disconnect()
		end
	end
end

local function createPlayerButton(player)
	local playerButton = Instance.new("TextButton")
	playerButton.Name = player.Name
	playerButton.Parent = PlayerList
	playerButton.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
	playerButton.BackgroundTransparency = 0
	playerButton.BorderSizePixel = 0
	playerButton.Size = UDim2.new(1, -10, 0, 32)
	playerButton.Font = Enum.Font.Gotham
	playerButton.Text = player.DisplayName .. " (@" .. player.Name .. ")"
	playerButton.TextColor3 = Color3.fromRGB(180, 180, 200)
	playerButton.TextSize = 13
	playerButton.TextXAlignment = Enum.TextXAlignment.Left
	playerButton.TextTruncate = Enum.TextTruncate.AtEnd
	playerButton.ZIndex = 4
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = playerButton
	
	local padding = Instance.new("UIPadding")
	padding.Parent = playerButton
	padding.PaddingLeft = UDim.new(0, 12)
	
	playerButton.MouseEnter:Connect(function()
		if selectedPlayer ~= player then
			TweenService:Create(playerButton, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(45, 45, 60),
				BackgroundTransparency = 0
			}):Play()
		end
	end)
	
	playerButton.MouseLeave:Connect(function()
		if selectedPlayer ~= player then
			TweenService:Create(playerButton, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(30, 30, 42),
				BackgroundTransparency = 0
			}):Play()
		end
	end)
	
	playerButton.MouseButton1Click:Connect(function()
		selectedPlayer = player
		for _, btn in pairs(PlayerList:GetChildren()) do
			if btn:IsA("TextButton") then
				TweenService:Create(btn, TweenInfo.new(0.2), {
					BackgroundColor3 = Color3.fromRGB(30, 30, 42),
					BackgroundTransparency = 0,
					TextColor3 = Color3.fromRGB(180, 180, 200)
				}):Play()
			end
		end
		TweenService:Create(playerButton, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(70, 130, 255),
			BackgroundTransparency = 0,
			TextColor3 = Color3.fromRGB(255, 255, 255)
		}):Play()
		print("✅ Selected player:", player.DisplayName .. " (@" .. player.Name .. ")")
	end)
	
	return playerButton
end

local function updatePlayerList(searchText)
	for _, child in pairs(PlayerList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	local searchLower = string.lower(searchText or "")
	local count = 0
	
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local nameLower = string.lower(player.Name)
			local displayLower = string.lower(player.DisplayName)
			
			if searchText == "" or string.find(nameLower, searchLower) or string.find(displayLower, searchLower) then
				createPlayerButton(player)
				count = count + 1
			end
		end
	end
	
	PlayerList.CanvasSize = UDim2.new(0, 0, 0, count * 37)
end

updatePlayerList("")

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	updatePlayerList(SearchBox.Text)
end)

Players.PlayerAdded:Connect(function()
	wait(0.1)
	updatePlayerList(SearchBox.Text)
end)

Players.PlayerRemoving:Connect(function()
	wait(0.1)
	updatePlayerList(SearchBox.Text)
end)

Button.MouseButton1Click:Connect(function()
	if selectedPlayer then
		character = selectedPlayer.Character or selectedPlayer.CharacterAdded:Wait()
		humanoidRootPart = character:WaitForChild("HumanoidRootPart")
		toggleBlackHole()
	else
		local originalText = Button.Text
		Button.Text = "Select Player First!"
		wait(2)
		Button.Text = originalText
	end
end)

BringAllButton.MouseButton1Click:Connect(function()
	toggleBringAll()
end)

CloseButton.MouseButton1Click:Connect(function()
	
	Gui:Destroy()
end)

MinimizeButton.MouseButton1Click:Connect(function()
	Main.Visible = false
	MinimizedButton.Visible = true
end)

MinimizedButton.MouseButton1Click:Connect(function()
	Main.Visible = true
	MinimizedButton.Visible = false
end)

-- Initialize character and humanoidRootPart for PartOrbit
LocalPlayer.CharacterAdded:Connect(function(char)
	wait(1)
	humanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)

if LocalPlayer.Character then
	humanoidRootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
end

-- Initialize PartOrbit
spawn(function()
	wait(1)
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
		humanoidRootPart = LocalPlayer.Character.HumanoidRootPart
		initializePartOrbit()
	end
end)