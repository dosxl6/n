--### SIEXTHER ### HANN NEW
local main = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local FrameCorner = Instance.new("UICorner")
local FrameStroke = Instance.new("UIStroke")
local TextLabel = Instance.new("TextLabel")
local TextLabelCorner = Instance.new("UICorner")
local speedDisplay = Instance.new("TextLabel")
local speedDisplayCorner = Instance.new("UICorner")
local minus = Instance.new("TextButton")
local minusCorner = Instance.new("UICorner")
local plus = Instance.new("TextButton")
local plusCorner = Instance.new("UICorner")
local onof = Instance.new("TextButton")
local onofCorner = Instance.new("UICorner")
local closebutton = Instance.new("TextButton")
local closebuttonCorner = Instance.new("UICorner")
local mini = Instance.new("TextButton")
local miniCorner = Instance.new("UICorner")
local mini2 = Instance.new("TextButton")
local mini2Corner = Instance.new("UICorner")

main.Name = "main"
main.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
main.ResetOnSpawn = false

Frame.Parent = main
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Frame.BackgroundTransparency = 0.1
Frame.BorderSizePixel = 0
Frame.Position = UDim2.new(0.100320168, 0, 0.379746825, 0)
Frame.Size = UDim2.new(0, 200, 0, 90)

FrameCorner.CornerRadius = UDim.new(0, 12)
FrameCorner.Parent = Frame

FrameStroke.Parent = Frame
FrameStroke.Color = Color3.fromRGB(70, 130, 255)
FrameStroke.Thickness = 2
FrameStroke.Transparency = 0
FrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

TextLabel.Parent = Frame
TextLabel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
TextLabel.BackgroundTransparency = 1
TextLabel.BorderSizePixel = 0
TextLabel.Position = UDim2.new(0.05, 0, 0.08, 0)
TextLabel.Size = UDim2.new(0, 80, 0, 25)
TextLabel.Font = Enum.Font.GothamBold
TextLabel.Text = "SIEXTHER"
TextLabel.TextColor3 = Color3.fromRGB(70, 130, 255)
TextLabel.TextSize = 18.000
TextLabel.TextXAlignment = Enum.TextXAlignment.Left

speedDisplay.Name = "speedDisplay"
speedDisplay.Parent = Frame
speedDisplay.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
speedDisplay.BackgroundTransparency = 0
speedDisplay.BorderSizePixel = 0
speedDisplay.Position = UDim2.new(0.05, 0, 0.45, 0)
speedDisplay.Size = UDim2.new(0, 50, 0, 35)
speedDisplay.Font = Enum.Font.GothamBold
speedDisplay.Text = "1"
speedDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
speedDisplay.TextSize = 20.000

speedDisplayCorner.CornerRadius = UDim.new(0, 8)
speedDisplayCorner.Parent = speedDisplay

minus.Name = "minus"
minus.Parent = Frame
minus.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
minus.BackgroundTransparency = 0
minus.BorderSizePixel = 0
minus.Position = UDim2.new(0.35, 0, 0.45, 0)
minus.Size = UDim2.new(0, 35, 0, 35)
minus.Font = Enum.Font.GothamBold
minus.Text = "-"
minus.TextColor3 = Color3.fromRGB(255, 255, 255)
minus.TextSize = 24.000

minusCorner.CornerRadius = UDim.new(0, 999)
minusCorner.Parent = minus

plus.Name = "plus"
plus.Parent = Frame
plus.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
plus.BackgroundTransparency = 0
plus.BorderSizePixel = 0
plus.Position = UDim2.new(0.565, 0, 0.45, 0)
plus.Size = UDim2.new(0, 35, 0, 35)
plus.Font = Enum.Font.GothamBold
plus.Text = "+"
plus.TextColor3 = Color3.fromRGB(255, 255, 255)
plus.TextSize = 24.000

plusCorner.CornerRadius = UDim.new(0, 999)
plusCorner.Parent = plus

onof.Name = "onof"
onof.Parent = Frame
onof.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
onof.BackgroundTransparency = 0
onof.BorderSizePixel = 0
onof.Position = UDim2.new(0.525, 0, 0.08, 0)
onof.Size = UDim2.new(0, 85, 0, 25)
onof.Font = Enum.Font.GothamBold
onof.Text = "FLY"
onof.TextColor3 = Color3.fromRGB(255, 255, 255)
onof.TextSize = 14.000

onofCorner.CornerRadius = UDim.new(0, 8)
onofCorner.Parent = onof

closebutton.Name = "Close"
closebutton.Parent = Frame
closebutton.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
closebutton.BackgroundTransparency = 0
closebutton.BorderSizePixel = 0
closebutton.Font = Enum.Font.GothamBold
closebutton.Size = UDim2.new(0, 30, 0, 30)
closebutton.Text = "X"
closebutton.TextColor3 = Color3.fromRGB(255, 85, 85)
closebutton.TextSize = 18
closebutton.Position = UDim2.new(0, 170, 0, -35)

closebuttonCorner.CornerRadius = UDim.new(0, 8)
closebuttonCorner.Parent = closebutton

mini.Name = "minimize"
mini.Parent = Frame
mini.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
mini.BackgroundTransparency = 0
mini.BorderSizePixel = 0
mini.Font = Enum.Font.GothamBold
mini.Size = UDim2.new(0, 30, 0, 30)
mini.Text = "-"
mini.TextColor3 = Color3.fromRGB(70, 130, 255)
mini.TextSize = 26
mini.Position = UDim2.new(0, 135, 0, -35)

miniCorner.CornerRadius = UDim.new(0, 8)
miniCorner.Parent = mini

mini2.Name = "minimize2"
mini2.Parent = main
mini2.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mini2.BorderSizePixel = 0
mini2.Font = Enum.Font.GothamBold
mini2.Size = UDim2.new(0, 41, 0, 41)
mini2.Text = "FLY"
mini2.TextColor3 = Color3.fromRGB(255, 255, 255)
mini2.TextSize = 20
mini2.Position = UDim2.new(1, -65, 0, 15)
mini2.Visible = false
mini2.Active = true
mini2.Draggable = true
mini2.ZIndex = 5

mini2Corner.CornerRadius = UDim.new(0, 12)
mini2Corner.Parent = mini2

speeds = 1

local speaker = game:GetService("Players").LocalPlayer
local chr = game.Players.LocalPlayer.Character
local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")

nowe = false

-- Emote system variables (DARI SCRIPT KEDUA)
local CurrentTrack = nil
-- Random Emote IDs - 5 Different Fly Modes
local EMOTE_IDS = {
	"127260900197753",
	"102256275785620",
	"124591303389670",
	"101697162917215"
}
local function getRandomEmoteID()
	return EMOTE_IDS[math.random(1, #EMOTE_IDS)]
end

-- Function to load and play emote (DARI SCRIPT KEDUA)
local function LoadTrack(id)
    if CurrentTrack then 
        CurrentTrack:Stop(0) 
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
    local newTrack = hum:LoadAnimation(newAnim)
    newTrack.Priority = Enum.AnimationPriority.Action4

    newTrack:Play(0.1, 1, 1)
    
    CurrentTrack = newTrack

    return newTrack
end

-- Function to stop emote (DARI SCRIPT KEDUA)
local function StopTrack()
    if CurrentTrack then
        CurrentTrack:Stop(0.1)
        CurrentTrack = nil
    end
end

Frame.Active = true
Frame.Draggable = true

onof.MouseButton1Down:connect(function()

	if nowe == true then
		nowe = false
		
		-- Stop emote when fly is disabled
		StopTrack()

		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,true)
		speaker.Character.Humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
	else 
		nowe = true
		
		-- Play random emote when fly is enabled
		local randomEmoteID = getRandomEmoteID()
		LoadTrack(randomEmoteID)

		for i = 1, speeds do
			spawn(function()
				local hb = game:GetService("RunService").Heartbeat	
				tpwalking = true
				local chr = game.Players.LocalPlayer.Character
				local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
				while tpwalking and hb:Wait() and chr and hum and hum.Parent do
					if hum.MoveDirection.Magnitude > 0 then
						chr:TranslateBy(hum.MoveDirection)
					end
				end
			end)
		end
		game.Players.LocalPlayer.Character.Animate.Disabled = true
		local Char = game.Players.LocalPlayer.Character
		local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")

		for i,v in next, Hum:GetPlayingAnimationTracks() do
			v:AdjustSpeed(0)
		end
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,false)
		speaker.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
	end

	if game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R6 then
		local plr = game.Players.LocalPlayer
		local torso = plr.Character.Torso
		local flying = true
		local deb = true
		local ctrl = {f = 0, b = 0, l = 0, r = 0}
		local lastctrl = {f = 0, b = 0, l = 0, r = 0}
		local maxspeed = 50
		local speed = 0

		local bg = Instance.new("BodyGyro", torso)
		bg.P = 9e4
		bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
		bg.cframe = torso.CFrame
		local bv = Instance.new("BodyVelocity", torso)
		bv.velocity = Vector3.new(0,0.1,0)
		bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
		if nowe == true then
			plr.Character.Humanoid.PlatformStand = true
		end
		while nowe == true or game:GetService("Players").LocalPlayer.Character.Humanoid.Health == 0 do
			game:GetService("RunService").RenderStepped:Wait()

			if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
				speed = speed+.5+(speed/maxspeed)
				if speed > maxspeed then
					speed = maxspeed
				end
			elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
				speed = speed-1
				if speed < 0 then
					speed = 0
				end
			end
			if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
				bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f+ctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
				lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
			elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
				bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f+lastctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l+lastctrl.r,(lastctrl.f+lastctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
			else
				bv.velocity = Vector3.new(0,0,0)
			end
			bg.cframe = game.Workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*speed/maxspeed),0,0)
		end
		ctrl = {f = 0, b = 0, l = 0, r = 0}
		lastctrl = {f = 0, b = 0, l = 0, r = 0}
		speed = 0
		bg:Destroy()
		bv:Destroy()
		plr.Character.Humanoid.PlatformStand = false
		game.Players.LocalPlayer.Character.Animate.Disabled = false
		tpwalking = false

	else
		local plr = game.Players.LocalPlayer
		local UpperTorso = plr.Character.UpperTorso
		local flying = true
		local deb = true
		local ctrl = {f = 0, b = 0, l = 0, r = 0}
		local lastctrl = {f = 0, b = 0, l = 0, r = 0}
		local maxspeed = 50
		local speed = 0

		local bg = Instance.new("BodyGyro", UpperTorso)
		bg.P = 9e4
		bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
		bg.cframe = UpperTorso.CFrame
		local bv = Instance.new("BodyVelocity", UpperTorso)
		bv.velocity = Vector3.new(0,0.1,0)
		bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
		if nowe == true then
			plr.Character.Humanoid.PlatformStand = true
		end
		while nowe == true or game:GetService("Players").LocalPlayer.Character.Humanoid.Health == 0 do
			wait()

			if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
				speed = speed+.5+(speed/maxspeed)
				if speed > maxspeed then
					speed = maxspeed
				end
			elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
				speed = speed-1
				if speed < 0 then
					speed = 0
				end
			end
			if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
				bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f+ctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
				lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
			elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
				bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f+lastctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l+lastctrl.r,(lastctrl.f+lastctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
			else
				bv.velocity = Vector3.new(0,0,0)
			end
			bg.cframe = game.Workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*speed/maxspeed),0,0)
		end
		ctrl = {f = 0, b = 0, l = 0, r = 0}
		lastctrl = {f = 0, b = 0, l = 0, r = 0}
		speed = 0
		bg:Destroy()
		bv:Destroy()
		plr.Character.Humanoid.PlatformStand = false
		game.Players.LocalPlayer.Character.Animate.Disabled = false
		tpwalking = false
	end
end)

game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(char)
	wait(0.7)
	game.Players.LocalPlayer.Character.Humanoid.PlatformStand = false
	game.Players.LocalPlayer.Character.Animate.Disabled = false
	StopTrack()
end)

plus.MouseButton1Down:connect(function()
	speeds = speeds + 1
	speedDisplay.Text = speeds
	if nowe == true then

		tpwalking = false
		for i = 1, speeds do
			spawn(function()
				local hb = game:GetService("RunService").Heartbeat	
				tpwalking = true
				local chr = game.Players.LocalPlayer.Character
				local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
				while tpwalking and hb:Wait() and chr and hum and hum.Parent do
					if hum.MoveDirection.Magnitude > 0 then
						chr:TranslateBy(hum.MoveDirection)
					end
				end
			end)
		end
	end
end)

minus.MouseButton1Down:connect(function()
	if speeds == 1 then
		speedDisplay.Text = 'min 1'
		wait(1)
		speedDisplay.Text = speeds
	else
		speeds = speeds - 1
		speedDisplay.Text = speeds
		if nowe == true then
			tpwalking = false
			for i = 1, speeds do
				spawn(function()
					local hb = game:GetService("RunService").Heartbeat	
					tpwalking = true
					local chr = game.Players.LocalPlayer.Character
					local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
					while tpwalking and hb:Wait() and chr and hum and hum.Parent do
						if hum.MoveDirection.Magnitude > 0 then
							chr:TranslateBy(hum.MoveDirection)
						end
					end
				end)
			end
		end
	end
end)

closebutton.MouseButton1Click:Connect(function()
	StopTrack()
	main:Destroy()
end)

mini.MouseButton1Click:Connect(function()
	TextLabel.Visible = false
	onof.Visible = false
	speedDisplay.Visible = false
	minus.Visible = false
	plus.Visible = false
	mini.Visible = false
	closebutton.Visible = false
	mini2.Visible = true
	Frame.Visible = false
end)

mini2.MouseButton1Click:Connect(function()
	TextLabel.Visible = true
	onof.Visible = true
	speedDisplay.Visible = true
	minus.Visible = true
	plus.Visible = true
	mini.Visible = true
	closebutton.Visible = true
	mini2.Visible = false
	Frame.Visible = true
end)