-- Wally West Be like 
if not game.Players.LocalPlayer:FindFirstChild("WallyWestScript") then
local WallyWestScript = Instance.new("IntValue", game.Players.LocalPlayer)
WallyWestScript.Name = "WallyWestScript"

local Settings = Instance.new("Folder", WallyWestScript)
Settings.Name = "WallyWestScriptSettings"

local SAS = Instance.new("BoolValue", Settings)
SAS.Name = "StopAfterStun"
SAS.Value = true

local IR = Instance.new("BoolValue", Settings)
IR.Name = "InstantRace"
IR.Value = false

local SCOA = Instance.new("BoolValue", Settings)
SCOA.Name = "ShakeCharacterOnAcceleration"
SCOA.Value = true

local DCFIM = Instance.new("BoolValue", Settings)
DCFIM.Name = "DisableCollisionOnFastMode"
DCFIM.Value = true

local Scren = Instance.new("ScreenGui", game.CoreGui)
Scren.ResetOnSpawn = false

local Button = Instance.new("TextButton")
Button.Size = UDim2.new(0.04, 0.04, 0.04, 4)
Button.Position = UDim2.new(0.73, 0, 0.5, 0)
Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.TextScaled = true
Button.FontFace = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
Button.Text = "END"
Button.Parent = Scren

local RGBColor = Instance.new("UIGradient", Button)
RGBColor.Color = ColorSequence.new(Color3.new(1, 0, 0), Color3.new(1, 0.5, 0), Color3.new(1, 1, 0), Color3.new(0, 1, 0), Color3.new(0, 1, 1), Color3.new(0, 0, 1), Color3.new(1, 0, 1))



Button.MouseButton1Click:Connect(function()
  WallyWestScript:Destroy()
  Scren:Destroy()
  game.Players.LocalPlayer.Character:BreakJoints()
end)

local function MakeCameraShake(lifetime, strength, mode)
  task.spawn(function()
local past = os.clock()
local i = 0
repeat game:GetService("RunService").PreSimulation:Wait()
i = i + 1
 local shakeIntensity = (strength or 10) * (1 - (i - 1) / ((mode:lower() == "def" and 25) or (mode:lower() == "dim" and 25 * (lifetime or 1)) or 25))
  local shakeOffset = Vector3.new(math.random(-shakeIntensity, shakeIntensity) / 10, math.random(-shakeIntensity, shakeIntensity) / 10, math.random(-shakeIntensity, shakeIntensity) / 10)
 local originalOffset = game.Players.LocalPlayer.Character.Humanoid.CameraOffset
 local currentTime = 0
 while currentTime < 0.01 do
     local delta = currentTime / 0.01
     game.Players.LocalPlayer.Character.Humanoid.CameraOffset = Vector3.new(0, 0, 0) + shakeOffset * (1 - delta)
     currentTime = currentTime + task.wait(0.025)
 end
 game.Players.LocalPlayer.Character.Humanoid.CameraOffset = Vector3.new(0, 0, 0)
until os.clock() - past >= (lifetime or 1)
  end)
end

hue = game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
  task.spawn(function()
   repeat task.wait()
    for _, part in next, char:GetDescendants() do
      if part:IsA("BasePart") then
       part.CustomPhysicalProperties = PhysicalProperties.new(math.huge, 0, 0, 0, 0)
       part.EnableFluidForces = false
        pcall(function()
         sethiddenproperty(part, "Friction", -math.huge)
        end)
       part.Massless = false
     end
   end
  until not char
end)
  
   local OrigJump, OrigFall = char:WaitForChild("Animate"):WaitForChild("jump").JumpAnim.AnimationId, char:WaitForChild("Animate"):WaitForChild("fall").FallAnim.AnimationId
   local attribute = Instance.new("NumberValue", char)
   attribute.Name = "SelectedSpeed"
   attribute.Value = 82
   
   local accel = Instance.new("BoolValue", char)
   accel.Name = "IsAccelerated"
   accel.Value = false
   
   accel:GetPropertyChangedSignal("Value"):Connect(function()
     if accel.Value == true then
       char.Animate.jump.JumpAnim.AnimationId = "rbxassetid://120335479030239"
       char.Animate.fall.FallAnim.AnimationId = "rbxassetid://120335479030239"
     else
       char.Animate.jump.JumpAnim.AnimationId = OrigJump
       char.Animate.fall.FallAnim.AnimationId = OrigFall
     end
     
     if accel.Value == true then
       task.spawn(function() repeat task.wait()
   if char.Humanoid:GetState() ~= "Running" and char.Humanoid:GetState() ~= "RunningNoPhysics" and char.Humanoid.MoveDirection.Magnitude <= 0 and SCOA.Value == true then
      local pos = char.HumanoidRootPart.CFrame
      char.HumanoidRootPart.CFrame *= CFrame.new(math.min(math.random(), math.random()) / 4, math.min(math.random(), math.random()) / 4, math.min(math.random(), math.random()) / 4)
       task.wait()
      char.HumanoidRootPart.CFrame = pos
   end
until not char or accel.Value == false end)
     end
   end)
   
   char:WaitForChild("Humanoid").WalkSpeed = attribute.Value or 82
   char.Humanoid.AutoJumpEnabled = false
   
   pcall(function()
   char:WaitForChild("Animate"):WaitForChild("walk").WalkAnim.AnimationId = "rbxassetid://10921244891"
   char.Animate.idle.Animation1.AnimationId = "rbxassetid://10921301576"
   char.Animate.jump.JumpAnim.AnimationId = "rbxassetid://10921263860"
   char.Animate.run.RunAnim.AnimationId = "rbxassetid://82598234841035"
   char.Animate.fall.FallAnim.AnimationId = "rbxassetid://10921262864"
   end)
   
   char.Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
     char.Humanoid.WalkSpeed = attribute.Value or 82
   end)
   
for i = 1, 2 do
  local fireParticles = Instance.new("ParticleEmitter")
  fireParticles.Name = "FireLine"
  fireParticles.Enabled = true
  fireParticles.Lifetime = NumberRange.new(0.5, 1)
  fireParticles.Rate = 50
  fireParticles.Rotation = NumberRange.new(0, 360)
  fireParticles.RotSpeed = NumberRange.new(-180, 180)
  fireParticles.Size = NumberSequence.new(1, 0)
  fireParticles.Speed = NumberRange.new(5, 10)
  fireParticles.SpreadAngle = Vector2.new(-20, 20)
  fireParticles.Texture = "rbxassetid://257173628"
  fireParticles.Parent = (i == 1 and char:WaitForChild("RightHand") or char:WaitForChild("LeftHand"))
  
  local particle = fireParticles:Clone()
  particle.Parent = fireParticles.Parent
  particle.Name = "FireLine2"
  particle.Size = NumberSequence.new(1, 1)
  particle.Speed = NumberRange.new(0, 0)
  particle.Lifetime = NumberRange.new(0.05, 0.05)
end

   local eff = Instance.new("ParticleEmitter", char.HumanoidRootPart)
   eff.RotSpeed = NumberRange.new(-90, 90)
   eff.Enabled = false
   eff.Rate = 50
   eff.Rotation = NumberRange.new(-360, 360)
   eff.Lifetime = NumberRange.new(0.15, 0.3)
   eff.Size = NumberSequence.new(4, 8, 0)
   eff.Transparency = NumberSequence.new(0, 1)
   eff.ZOffset -= 1
   eff.Texture = "rbxassetid://257173628"
   eff.SpreadAngle = Vector2.new(-360, 360)
   eff.Speed = NumberRange.new(3, 6)
   eff.LockedToPart = false
   
   local eld = eff:Clone()
   eld.Name = "FireLine2"
   eld.Enabled = true
   eld.Parent = eff.Parent
   eld.Speed = NumberRange.new(0, 0)
   eld.LockedToPart = true
   eld.Rate = 6
   eld.Lifetime = NumberRange.new(0.075, 0.075)
   
  local Doo = Instance.new("ParticleEmitter")
  Doo.Name = "FireLine"
  Doo.Enabled = false
  Doo.Lifetime = NumberRange.new(0.5, 1)
  Doo.Rate = 1000
  Doo.Rotation = NumberRange.new(0, 360)
  Doo.RotSpeed = NumberRange.new(-180, 180)
  Doo.Size = NumberSequence.new(3.25, 0.5)
  Doo.Speed = NumberRange.new(75, 75)
  Doo.SpreadAngle = Vector2.new(-15, 15)
  Doo.EmissionDirection = Enum.NormalId.Back
  Doo.Texture = "rbxassetid://257173628"
  Doo.Parent = char.HumanoidRootPart
  
  local LD1 = Doo:Clone()
  LD1.Parent = char:FindFirstChild("LeftFoot")
  local LD2 = Doo:Clone()
  LD2.Parent = char:FindFirstChild("RightFoot")
  
  Doo:GetPropertyChangedSignal("Enabled"):Connect(function()
    LD1.Enabled = Doo.Enabled
    LD2.Enabled = Doo.Enabled
  end)
  
  local Platf = Instance.new("Part", Workspace)
  Platf.Anchored = true
  Platf.CanCollide = false
  Platf.Position = Vector3.new(31, -9, 527)
  Platf.Size = Vector3.new(10, 1, 10)
  Platf.Transparency = 1
  
  local colo = Instance.new("ColorCorrectionEffect", game.Lighting)
  colo.TintColor = Color3.new(0, 0.8, 0.8)
  colo.Saturation = 0
  colo.Enabled = false
  
   task.spawn(function() repeat task.wait()
     Doo.Enabled = (char:WaitForChild("HumanoidRootPart").Velocity.Magnitude >= 1000)
     Platf.CanCollide = (char.HumanoidRootPart.Velocity.Magnitude >= 450)
     Platf.Position = Vector3.new(char.HumanoidRootPart.Position.X, -10, char.HumanoidRootPart.Position.Z)
     
     if char.HumanoidRootPart.Velocity.Y >= 300 then
       char.HumanoidRootPart.Velocity += Vector3.new(0, -200, 0)
     end
     if char.HumanoidRootPart.Velocity.Magnitude >= 15000 then
       colo.Enabled = true
      else
       colo.Enabled = false
     end
   until not Doo end)

   local light = Instance.new("PointLight", char.HumanoidRootPart)
   light.Range = 12
   light.Brightness = 1
   light.Color = Color3.new(0, 1, 1)
   
   local ScreenGui = Instance.new("ScreenGui", game.Players.LocalPlayer.PlayerGui)
   ScreenGui.ResetOnSpawn = true
   ScreenGui.Enabled = true
   
   char.Humanoid.Died:Connect(function()
     ScreenGui:Destroy()
     colo:Destroy()
     Platf:Destroy()
   end)
   
   for _, part in next, char:GetChildren() do
     if part:IsA("BasePart") then
       local particle = Instance.new("ParticleEmitter", part)
       particle.Rate = 1000
       particle.LockedToPart = true
       particle.Texture = "rbxassetid://11745241946"
       particle.Lifetime = NumberRange.new(0.375, 0.375) -- 0.2 0.2
       particle.Size = NumberSequence.new(0.435, 0.435) -- 0.5 0.5
       particle.ZOffset -= 1
       particle.Speed = NumberRange.new(0, 0)
       particle.LightEmission = 1 
       particle.Color = ColorSequence.new(Color3.new(0.4, 0.4, 1), Color3.new(0.4, 0.4, 1)) -- 0.3
     end
   end
   
   local Button = Instance.new("TextButton", ScreenGui)
   Button.Size = UDim2.new(0.04, 0.04, 0.04, 4)
   Button.Parent = Scren
Button.Position = UDim2.new(0.79, 0, 0.5, 0)
   Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
   Button.TextColor3 = Color3.fromRGB(255, 255, 255)
   Button.TextScaled = true
   Button.FontFace = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
   Button.Visible = true
   Button.Text = "AURA"
   
   local Button2 = Button:Clone()
   Button2.Parent = ScreenGui
   Button2.Visible = true
   Button2.TextScaled = false
   Button2.Position = UDim2.new(0.76, 0, 0.6, 0)
   Button2.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
   Button2.Text = "WALK"
   Button.Parent = ScreenGui
   
   local walki = false
   Button2.MouseButton1Click:Connect(function()
    walki = not walki
    Button2.Text = (walki == true and "RUN" or "Walk")
     if walki == true then
       attribute.Value = 20
       char.Humanoid.WalkSpeed = 20
      char:WaitForChild("Animate"):WaitForChild("walk").WalkAnim.AnimationId = "rbxassetid://10921244891"
   char.Animate.idle.Animation1.AnimationId = "rbxassetid://18538150608"
   char.Animate.jump.JumpAnim.AnimationId = "rbxassetid://10921263860"
   char.Animate.run.RunAnim.AnimationId = "rbxassetid://82598234841035"
   char.Animate.fall.FallAnim.AnimationId = "rbxassetid://10921262864"
       char.LeftHand.FireLine.Enabled = (accel.Value == false and false or true)
       char.RightHand.FireLine.Enabled = (accel.Value == false and false or true)
     else
       attribute.Value = (accel.Value == true and 82 or 82)
       char.Humanoid.WalkSpeed = attribute.Value
       char.Animate.run.RunAnim.AnimationId = "rbxassetid://82598234841035"
       
       char.LeftHand.FireLine.Enabled = true
       char.RightHand.FireLine.Enabled = true
       
       local sound = Instance.new("Sound", char.HumanoidRootPart)
       sound.SoundId = "rbxassetid://379557765"
       sound.Volume = 1
       sound.PlaybackSpeed = 1
       sound:Play()
       game.Debris:AddItem(sound, 4)
     end
   end)
   
   local last = 0
   Button.MouseButton1Click:Connect(function()
     local currentTime = tick()
      if currentTime - last >= 15 then
        last = currentTime
        
        light.Brightness = 2.3
        light.Range *= 1.5
        eff.Enabled = true
        
        char:FindFirstChild("RightHand").FireLine:Emit(100)
        char:FindFirstChild("LeftHand").FireLine:Emit(100)
        char.Animate.run.RunAnim.AnimationId = "rbxassetid://82598234841035"
        
        local sound = Instance.new("Sound", char.HumanoidRootPart)
        sound.SoundId = "rbxassetid://8060079174"
        sound.Volume = 1
        sound.PlaybackSpeed = 0.9
        sound:Play()
        game.Debris:AddItem(sound, 10)
        
        local sound2 = sound:Clone()
        sound2.Parent = sound.Parent
        sound2.Looped = true
        sound2.SoundId = "rbxassetid://5509750509"
        sound2:Play()
        game.Debris:AddItem(sound2, 10)
        
        local tween = game:GetService("TweenService"):Create(game.Workspace.CurrentCamera, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0), {
            FieldOfView = 100
          })
        tween:Play()
        
        task.spawn(function()
          char.Humanoid.Running:Wait()
          local explosion = Instance.new("Part", Workspace)
          explosion.Anchored = true
          explosion.Size = Vector3.zero
          explosion.Material = "Neon"
          explosion.Shape = "Ball"
          explosion.CanCollide = false
          explosion.CanTouch = false
          explosion.Position = char.HumanoidRootPart.Position
          explosion.Color = Color3.new(0, 1, 1)
          game.Debris:AddItem(explosion, 4)
          
          task.delay(0.075, function()
            char.HumanoidRootPart.Velocity = char.HumanoidRootPart.Velocity.Unit * (100 + 2 * char.HumanoidRootPart.Velocity.Magnitude)
          end)
          
          local sound = Instance.new("Sound", Workspace)
          sound.SoundId = "rbxassetid://91191741418347"
          sound.Volume = 1
          sound.PlaybackSpeed = 1
          sound:Play()
          game.Debris:AddItem(sound, 5)
          
          local sound2 = sound:Clone()
          sound2.Parent = sound
          sound.SoundId = "rbxassetid://127621297686566"
          sound:Play()
          
          local tween = game:GetService("TweenService"):Create(explosion, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0), {
               Size = Vector3.new(85, 85, 85),
               Color = Color3.new(0, 0, 0),
               Transparency = 1
            })
          tween:Play()
          MakeCameraShake(3, 15, "def")
        end)
        
        local Highlight = Instance.new("Highlight", char)
        Highlight.Adornee = char
        Highlight.FillTransparency = 0.875
        Highlight.FillColor = Color3.new(0, 1, 1)
        Highlight.OutlineColor = Color3.fromRGB(0, 250, 250)
        Highlight.OutlineTransparency = 0.65
        Highlight.DepthMode = "Occluded"
        game.Debris:AddItem(Highlight, 10)
        
        accel.Value = true
        attribute.Value = 100
        char.Humanoid.WalkSpeed = 100
        
        task.spawn(function()
          repeat task.wait()
            for _, part in next, char:GetDescendants() do
              if part:IsA("BasePart") then
                part.CanCollide = (DCFIM.Value == true and false or true)
              end
            end
          until accel.Value == false
          
          for _, part in next, char:GetDescendants() do
            if part:IsA("BasePart") then
              part.CanCollide = true
            end
          end
        end)
        
        task.delay(10, function()
          accel.Value = false
          light.Range = 12
          light.Brightness = 1
          attribute.Value = (attribute.Value == 82 and 82 or attribute.Value)
          char.Humanoid.WalkSpeed = attribute.Value
          eff.Enabled = false
          
          local tween = game:GetService("TweenService"):Create(game.Workspace.CurrentCamera, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0), {
              FieldOfView = 70
            })
          tween:Play()
        end)
      end
   end)

   local RGBColor = Instance.new("UIGradient", Button)
   RGBColor.Color = ColorSequence.new(Color3.new(0, 0.8, 0.8), Color3.new(0, 1, 1), Color3.new(1, 1, 1))
  
  char.Humanoid.FallingDown:Connect(function()
    char.Humanoid:ChangeState("GettingUp")
     if SAS.Value == true then
       char.HumanoidRootPart.Velocity = Vector3.zero
       char.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
       char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
     end
  end)
end)
firesignal(game.Players.LocalPlayer.CharacterAdded, game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait())

  WallyWestScript.Destroying:Connect(function()
    hue:Disconnect()
    road:Destroy()
    pcall(function() Ihe:Disconnect() end)
  end)

local ButtonGui = Instance.new("ScreenGui", game.CoreGui)
ButtonGui.ResetOnSpawn = false
ButtonGui.IgnoreGuiInset = true
ButtonGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ButtonGui.DisplayOrder = -25

local Frame = Instance.new("Frame", ButtonGui)
Frame.Active = true
Frame.Draggable = false
Frame.BorderSizePixel = 0
Frame.Visible = false
Frame.Size = UDim2.new(0, 250, 0, 250)
Frame.BackgroundTransparency = 0.1
Frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
Frame.Position = UDim2.new(0.35, 0, 0.2, 0)

  WallyWestScript.Destroying:Connect(function()
    hue:Disconnect()
    road:Destroy()
    pcall(function() Ihe:Disconnect() end)
    ButtonGui:Destroy()
  end)
end
