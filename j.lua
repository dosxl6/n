local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- === NERFED CONFIG ===
local baseMaxSpeed = 5
local topMaxSpeed = 120
local accel = 0.5
local speedBuildRate = 3
local speedDecayRate = 15
local boostMultiplier = 1.3
local boostKey = Enum.KeyCode.LeftShift
local jumpPower = 50
local tauntDuration = 200
local tauntCooldownTime = 5
local maxJumps = 5

local runAnimId   = "rbxassetid://98377335607360"
local jumpAnimId  = "rbxassetid://123364707044126"
local tauntAnimId = "rbxassetid://75602578104627"
local idleAnimId  = "rbxassetid://90613618252787"
local fakeDeathAnimId = "rbxassetid://82378425345026"

local speed = 0
local currentMaxSpeed = baseMaxSpeed
local boostActive = false
local tauntCooldown = false
local jumpCount = 0

local humanoid, rootPart, character
local runTrack, jumpTrack, tauntTrack, idleTrack
local leftFootSmoke, rightFootSmoke, leftFootTrail, rightFootTrail

local fakeDeathTrack = nil
local isFakingDeath = false
local tallManEnabled = false

-- === GUI CREATION ===
local function createGUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SiextherTall"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- Main Frame (Smaller)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 280, 0, 180)
	mainFrame.Position = UDim2.new(0.5, -140, 0.5, -90)
	mainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
	mainFrame.BorderSizePixel = 0
	mainFrame.Active = true
	mainFrame.Draggable = true
	mainFrame.Parent = screenGui
	
	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 16)
	mainCorner.Parent = mainFrame
	
	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = Color3.fromRGB(60, 120, 255)
	mainStroke.Thickness = 2
	mainStroke.Parent = mainFrame
	
	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 45)
	header.BackgroundTransparency = 1
	header.BorderSizePixel = 0
	header.Parent = mainFrame
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -50, 1, 0)
	titleLabel.Position = UDim2.new(0, 15, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "SIEXTHER TALL MAN"
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 16
	titleLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = header
	
	-- Close Button (X) - Red button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 28, 0, 28)
	closeBtn.Position = UDim2.new(1, -38, 0, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
	closeBtn.Text = "X"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 16
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.BorderSizePixel = 0
	closeBtn.Parent = header
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)
	closeCorner.Parent = closeBtn
	
	-- Minimize Button (Top right corner, rounded) - Next to X button
	local minimizeBtn = Instance.new("TextButton")
	minimizeBtn.Name = "MinimizeBtn"
	minimizeBtn.Size = UDim2.new(0, 28, 0, 28)
	minimizeBtn.Position = UDim2.new(1, -70, 0, 8)
	minimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
	minimizeBtn.Text = "–"
	minimizeBtn.Font = Enum.Font.GothamBold
	minimizeBtn.TextSize = 20
	minimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	minimizeBtn.BorderSizePixel = 0
	minimizeBtn.Parent = header
	
	local minCorner = Instance.new("UICorner")
	minCorner.CornerRadius = UDim.new(1, 0)
	minCorner.Parent = minimizeBtn
	
	-- Content Frame
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.Size = UDim2.new(1, -24, 1, -55)
	contentFrame.Position = UDim2.new(0, 12, 0, 50)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = mainFrame
	
	-- Info Text (Smaller, centered)
	local infoText = Instance.new("TextLabel")
	infoText.Name = "InfoText"
	infoText.Size = UDim2.new(1, 0, 0, 40)
	infoText.Position = UDim2.new(0, 0, 0, 5)
	infoText.BackgroundTransparency = 1
	infoText.Text = "NOS DI PC PAKE SHIFT"
	infoText.Font = Enum.Font.Gotham
	infoText.TextSize = 10
	infoText.TextColor3 = Color3.fromRGB(150, 150, 160)
	infoText.TextXAlignment = Enum.TextXAlignment.Center
	infoText.TextYAlignment = Enum.TextYAlignment.Top
	infoText.TextWrapped = true
	infoText.Parent = contentFrame
	
	-- Apply Boost Button (Large, centered, blue)
	local applyBtn = Instance.new("TextButton")
	applyBtn.Name = "ApplyBtn"
	applyBtn.Size = UDim2.new(1, -20, 0, 48)
	applyBtn.Position = UDim2.new(0, 10, 0, 55)
	applyBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
	applyBtn.Text = "AKTIFKAN"
	applyBtn.Font = Enum.Font.GothamBold
	applyBtn.TextSize = 16
	applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	applyBtn.BorderSizePixel = 0
	applyBtn.Parent = contentFrame
	
	local applyCorner = Instance.new("UICorner")
	applyCorner.CornerRadius = UDim.new(0, 12)
	applyCorner.Parent = applyBtn
	
	-- Made By Text
	local madeByText = Instance.new("TextLabel")
	madeByText.Name = "MadeByText"
	madeByText.Size = UDim2.new(1, 0, 0, 20)
	madeByText.Position = UDim2.new(0, 0, 1, -25)
	madeByText.BackgroundTransparency = 1
	madeByText.Text = "Made By Hann.Siexther"
	madeByText.Font = Enum.Font.Gotham
	madeByText.TextSize = 10
	madeByText.TextColor3 = Color3.fromRGB(100, 100, 120)
	madeByText.TextXAlignment = Enum.TextXAlignment.Center
	madeByText.Parent = contentFrame
	
	-- Floating Button (Hidden by default)
	local floatingBtn = Instance.new("TextButton")
	floatingBtn.Name = "FloatingBtn"
	floatingBtn.Size = UDim2.new(0, 41, 0, 41)
	floatingBtn.Position = UDim2.new(0, 20, 0.5, -25)
	floatingBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	floatingBtn.Text = "🦒"
	floatingBtn.Font = Enum.Font.GothamBold
	floatingBtn.TextSize = 20
	floatingBtn.BorderSizePixel = 0
	floatingBtn.Visible = false
	floatingBtn.Active = true
	floatingBtn.Draggable = true
	floatingBtn.Parent = screenGui	
	
	local floatCorner = Instance.new("UICorner")
	floatCorner.CornerRadius = UDim.new(0, 12)
	floatCorner.Parent = floatingBtn
	
	
	-- BOOST BUTTON (Tengah kanan)
	local boostBtn = Instance.new("TextButton")
	boostBtn.Name = "BoostBtn"
	boostBtn.Size = UDim2.new(0, 43, 0, 43)
	boostBtn.Position = UDim2.new(0.76, 0, 0.6, 0)
	boostBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	boostBtn.Text = "NOS"
	boostBtn.Font = Enum.Font.GothamBold
	boostBtn.TextSize = 18
	boostBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	boostBtn.BorderSizePixel = 0
	boostBtn.Active = true
	boostBtn.Visible = false  
	boostBtn.BackgroundTransparency = 0.3
	boostBtn.Parent = screenGui
	
	local boostCorner = Instance.new("UICorner")
	boostCorner.CornerRadius = UDim.new(0, 12)
	boostCorner.Parent = boostBtn
	
	-- Button Functions
	applyBtn.MouseButton1Click:Connect(function()
		tallManEnabled = not tallManEnabled
		if tallManEnabled then
			applyBtn.Text = "MATIKAN"
			applyBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
			boostBtn.Visible = true
		else
			applyBtn.Text = "AKTIFKAN"
			applyBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
			boostBtn.Visible = false
			-- Stop all animations when disabled
			if runTrack and runTrack.IsPlaying then runTrack:Stop() end
			if jumpTrack and jumpTrack.IsPlaying then jumpTrack:Stop() end
			if idleTrack and idleTrack.IsPlaying then idleTrack:Stop() end
			speed = 0
			if humanoid then humanoid.WalkSpeed = 16 end
		end
	end)
	
	-- Boost button touch handlers
	boostBtn.MouseButton1Down:Connect(function()
		if tallManEnabled then
			boostActive = true
			boostBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		end
	end)
	
	boostBtn.MouseButton1Up:Connect(function()
		boostActive = false
		boostBtn.BackgroundTransparency = 0.3
		boostBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	end)
	
	minimizeBtn.MouseButton1Click:Connect(function()
		mainFrame.Visible = false
		floatingBtn.Visible = true
	end)
	
	closeBtn.MouseButton1Click:Connect(function()
		screenGui:Destroy()
		tallManEnabled = false
		-- Cleanup and stop all animations
		if runTrack then runTrack:Stop() end
		if jumpTrack then jumpTrack:Stop() end
		if tauntTrack then tauntTrack:Stop() end
		if idleTrack then idleTrack:Stop() end
		if fakeDeathTrack then fakeDeathTrack:Stop() end
		-- Reset humanoid speed
		if humanoid then humanoid.WalkSpeed = 16 end
	end)
	
	floatingBtn.MouseButton1Click:Connect(function()
		mainFrame.Visible = true
		floatingBtn.Visible = false
	end)
	
	screenGui.Parent = playerGui
end

-- === ORIGINAL FUNCTIONS ===
local function createTrailAttachment(part, name, position)
	local a = Instance.new("Attachment")
	a.Name = name
	a.Position = position
	a.Parent = part
	return a
end

local function loadAnimations()
	local runAnim = Instance.new("Animation")
	runAnim.AnimationId = runAnimId
	runTrack = humanoid:LoadAnimation(runAnim)

	local jumpAnim = Instance.new("Animation")
	jumpAnim.AnimationId = jumpAnimId
	jumpTrack = humanoid:LoadAnimation(jumpAnim)
	jumpTrack.Looped = true

	local tauntAnim = Instance.new("Animation")
	tauntAnim.AnimationId = tauntAnimId
	tauntTrack = humanoid:LoadAnimation(tauntAnim)

	local idleAnim = Instance.new("Animation")
	idleAnim.AnimationId = idleAnimId
	idleTrack = humanoid:LoadAnimation(idleAnim)
end

local function doTaunt()
	if not tallManEnabled then return end
	if tauntCooldown then return end
	tauntCooldown = true
	if runTrack.IsPlaying then runTrack:Stop() end
	if idleTrack.IsPlaying then idleTrack:Stop() end
	if jumpTrack.IsPlaying then jumpTrack:Stop() end
	tauntTrack:Play()

	task.delay(tauntDuration, function()
		tauntTrack:Stop()
		if speed <= 0 then idleTrack:Play() else runTrack:Play() end
	end)

	task.delay(tauntCooldownTime, function()
		tauntCooldown = false
	end)
end

local function getSlopeNormal()
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {character}
	params.FilterType = Enum.RaycastFilterType.Blacklist
	local result = workspace:Raycast(rootPart.Position, Vector3.new(0, -5, 0), params)
	return result and result.Normal or Vector3.new(0, 1, 0)
end

local function setupVFX()
	local leftFoot = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg")
	local rightFoot = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg")
	if not (leftFoot and rightFoot) then return end

	local function makeSmoke(parent)
		local e = Instance.new("ParticleEmitter")
		e.Enabled = false
		e.Texture = "rbxassetid://7712212245"
		e.Lifetime = NumberRange.new(0.5, 1)
		e.Speed = NumberRange.new(0.5, 1)
		e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0)})
		e.Transparency = NumberSequence.new(0.1, 1)
		e.RotSpeed = NumberRange.new(-50, 50)
		e.SpreadAngle = Vector2.new(45, 45)
		e.Rate = 20
		e.Parent = parent
		return e
	end

	leftFootSmoke = makeSmoke(leftFoot)
	rightFootSmoke = makeSmoke(rightFoot)

	local leftStart  = createTrailAttachment(leftFoot, "TrailStart", Vector3.new(0, 0.3, 0))
	local leftEnd    = createTrailAttachment(leftFoot, "TrailEnd",   Vector3.new(0, -0.3, -0.5))
	local rightStart = createTrailAttachment(rightFoot, "TrailStart",Vector3.new(0, 0.3, 0))
	local rightEnd   = createTrailAttachment(rightFoot, "TrailEnd",  Vector3.new(0, -0.3, -0.5))

	leftFootTrail = Instance.new("Trail")
	leftFootTrail.Attachment0 = leftStart
	leftFootTrail.Attachment1 = leftEnd
	leftFootTrail.Enabled = false
	leftFootTrail.Texture = "rbxassetid://13211689684"
	leftFootTrail.TextureLength = 5
	leftFootTrail.Lifetime = 0.2
	leftFootTrail.LightEmission = 1
	leftFootTrail.Transparency = NumberSequence.new(0.3, 1)
	leftFootTrail.Parent = leftFoot

	rightFootTrail = Instance.new("Trail")
	rightFootTrail.Attachment0 = rightStart
	rightFootTrail.Attachment1 = rightEnd
	rightFootTrail.Enabled = false
	rightFootTrail.Texture = "rbxassetid://13211689684"
	rightFootTrail.TextureLength = 5
	rightFootTrail.Lifetime = 0.2
	rightFootTrail.LightEmission = 1
	rightFootTrail.Transparency = NumberSequence.new(0.3, 1)
	rightFootTrail.Parent = rightFoot
end

local function doAirJump()
	if not tallManEnabled then return end
	local vel = rootPart.Velocity
	rootPart.Velocity = Vector3.new(vel.X, jumpPower, vel.Z)
	jumpTrack:Stop()
	jumpTrack:Play()
end

local function toggleFakeDeath(actionName, inputState, inputObject)
	if not tallManEnabled then return end
	if inputState == Enum.UserInputState.Begin then
		if not isFakingDeath then
			fakeDeathTrack:Play()
			isFakingDeath = true
		else
			fakeDeathTrack:Stop()
			isFakingDeath = false
		end
	end
end

local function setupCharacter(char)
	character = char
	humanoid  = char:WaitForChild("Humanoid")
	rootPart  = char:WaitForChild("HumanoidRootPart")

	speed = 0
	currentMaxSpeed = baseMaxSpeed
	boostActive = false
	tauntCooldown = false
	jumpCount = 0

	loadAnimations()
	if tallManEnabled then
		idleTrack:Play()
	end
	setupVFX()

	local fakeDeathAnim = Instance.new("Animation")
	fakeDeathAnim.AnimationId = fakeDeathAnimId
	fakeDeathTrack = humanoid:LoadAnimation(fakeDeathAnim)
	isFakingDeath = false

	humanoid.Jumping:Connect(function(active)
		if not tallManEnabled then return end
		if active and not tauntCooldown then
			jumpCount += 1
			if runTrack.IsPlaying then runTrack:Stop() end
			if idleTrack.IsPlaying then idleTrack:Stop() end
			if not jumpTrack.IsPlaying then jumpTrack:Play() end
		end
	end)

	humanoid.StateChanged:Connect(function(_, newState)
		if not tallManEnabled then return end
		local onGround = (
			newState == Enum.HumanoidStateType.Landed or
			newState == Enum.HumanoidStateType.Running or
			newState == Enum.HumanoidStateType.RunningNoPhysics
		)
		if onGround then
			jumpCount = 0
			if jumpTrack.IsPlaying then jumpTrack:Stop() end
			if speed > 0 then runTrack:Play() else idleTrack:Play() end
		end
	end)
end

UserInputService.JumpRequest:Connect(function()
	if not tallManEnabled then return end
	if not humanoid then return end
	local state = humanoid:GetState()
	local onGround = (
		state == Enum.HumanoidStateType.Running or
		state == Enum.HumanoidStateType.RunningNoPhysics or
		state == Enum.HumanoidStateType.Landed
	)
	if not onGround and jumpCount < maxJumps then
		jumpCount += 1
		doAirJump()
	end
end)

RunService.Heartbeat:Connect(function(dt)
	if not tallManEnabled then return end
	if not humanoid or not rootPart then return end

	local moveDir = humanoid.MoveDirection
	local state = humanoid:GetState()
	local onGround = (
		state == Enum.HumanoidStateType.Running or
		state == Enum.HumanoidStateType.RunningNoPhysics or
		state == Enum.HumanoidStateType.Landed
	)

	if moveDir.Magnitude > 0 then
		if boostActive then
			if leftFootSmoke then leftFootSmoke.Enabled = true end
			if rightFootSmoke then rightFootSmoke.Enabled = true end
			if leftFootTrail then leftFootTrail.Enabled = true end
			if rightFootTrail then rightFootTrail.Enabled = true end
		else
			if leftFootSmoke then leftFootSmoke.Enabled = false end
			if rightFootSmoke then rightFootSmoke.Enabled = false end
			if leftFootTrail then leftFootTrail.Enabled = false end
			if rightFootTrail then rightFootTrail.Enabled = false end
		end

		if boostActive then
			currentMaxSpeed = math.min(currentMaxSpeed + speedBuildRate * dt, topMaxSpeed)
			currentMaxSpeed = math.max(currentMaxSpeed, baseMaxSpeed)
		else
			currentMaxSpeed = math.min(currentMaxSpeed + speedBuildRate * dt, baseMaxSpeed)
		end

		local targetMax = boostActive and topMaxSpeed or baseMaxSpeed

		local slopeNormal = getSlopeNormal()
		local slopeMoveDir = (moveDir - slopeNormal * moveDir:Dot(slopeNormal)).Unit
		speed = math.min(speed + accel * dt * 60, targetMax)

		if onGround and not runTrack.IsPlaying and not tauntCooldown then
			idleTrack:Stop()
			runTrack:Play()
		end

		humanoid.WalkSpeed = speed
		rootPart.Velocity = slopeMoveDir * speed + Vector3.new(0, rootPart.Velocity.Y, 0)

	else
		speed = 0
		currentMaxSpeed = math.max(currentMaxSpeed - speedDecayRate * dt, baseMaxSpeed)

		if runTrack.IsPlaying then runTrack:Stop() end
		if leftFootSmoke then leftFootSmoke.Enabled = false end
		if rightFootSmoke then rightFootSmoke.Enabled = false end
		if leftFootTrail then leftFootTrail.Enabled = false end
		if rightFootTrail then rightFootTrail.Enabled = false end

		if onGround and not idleTrack.IsPlaying and not tauntCooldown then
			idleTrack:Play()
		end

		humanoid.WalkSpeed = 0
		rootPart.Velocity = Vector3.new(0, rootPart.Velocity.Y, 0)
	end
end)

-- Keyboard controls
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.T then
		doTaunt()
	elseif input.KeyCode == Enum.KeyCode.F then
		toggleFakeDeath("FakeDeathToggle", Enum.UserInputState.Begin, input)
	elseif input.KeyCode == boostKey then
		boostActive = true
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == boostKey then
		boostActive = false
	end
end)

-- Initialize
createGUI()
player.CharacterAdded:Connect(setupCharacter)
if player.Character then setupCharacter(player.Character) end