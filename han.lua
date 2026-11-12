
local environment = (type(getgenv) == "function" and getgenv()) or _G
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
assert(player, "Run SIEXTHER notifications on the client.")

local previous = environment.__SIEXTHER_IOS_NOTIFICATIONS
if type(previous) == "table" and type(previous.Destroy) == "function" then
    pcall(previous.Destroy)
end

local Config = {
    AppName = "SIEXTHER EVO",
    Width = 240,
    Margin = 12,
    Top = 5, -- Near the screen's safe top edge, without the Roblox topbar offset.
    Gap = 5,
    Radius = 15,
    MaxVisible = 3,
    MaxQueued = 40,
    Accent = Color3.fromRGB(70, 130, 255),
    Background = Color3.fromRGB(43, 62, 91),
    BackgroundTransparency = 0.48,
    BodySize = 11,
    Text = Color3.fromRGB(255, 255, 255),
    Secondary = Color3.fromRGB(200, 214, 236),
    SoundId = "rbxassetid://18723584764",
    Volume = 0.22,
    NativeBlur = true,
}

local Controller = { Config = Config }
local active, pending, connections, records = {}, {}, {}, {}
local destroyed, dragging, pumping, pumpAgain = false, nil, false, false
local sequence = 0
local blurStatus = "not-attempted"
local pump, reflow, dismiss, layoutRecord

local function make(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function connect(signal, callback, bucket)
    local connection = signal:Connect(callback)
    table.insert(bucket or connections, connection)
    return connection
end

local function cancelThread(thread)
    if thread then
        pcall(task.cancel, thread)
    end
end

local function cancelTween(tween)
    if tween then
        tween:Cancel()
    end
end

local function tween(record, slot, object, duration, style, direction, goal)
    cancelTween(record.tweens[slot])
    local result = TweenService:Create(object, TweenInfo.new(duration, style, direction), goal)
    record.tweens[slot] = result
    result:Play()
    return result
end

local function corner(object, radius)
    return make("UICorner", { CornerRadius = UDim.new(0, radius) }, object)
end

local gui = make("ScreenGui", {
    Name = "SIEXTHER_iOS_Notifications",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 10000,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
-- Existing global glass wrappers must leave this deliberately styled GUI alone.
gui:SetAttribute("VIPGlassIgnore", true)
pcall(function()
    gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
    gui.ClipToDeviceSafeArea = true
end)

local playerGui = player:WaitForChild("PlayerGui")
local coreGui
pcall(function() coreGui = game:GetService("CoreGui") end)
local hosted = false
if coreGui then
    hosted = pcall(function() gui.Parent = coreGui end)
end
if not hosted then
    gui.Parent = playerGui
end

-- Remove the old banner container only when its structure matches the supplied code.
for _, parent in ipairs({ playerGui, coreGui or playerGui }) do
    local old = parent:FindFirstChild("NotificationSystem")
    if old and old:IsA("ScreenGui") then
        local recognized = #old:GetChildren() == 0
        for _, child in ipairs(old:GetChildren()) do
            if child.Name:match("^Notification_%d+$") and child:FindFirstChild("ProgressContainer") then
                recognized = true
                break
            end
        end
        if recognized then old:Destroy() end
    end
end

local host = make("Frame", {
    Name = "BannerHost",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Active = false,
    ClipsDescendants = false,
}, gui)

local function screenSize()
    local size = host.AbsoluteSize
    if size.X > 0 and size.Y > 0 then return size end
    local camera = workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(390, 740)
end

local function bannerWidth()
    return math.max(1, math.min(Config.Width, screenSize().X - Config.Margin * 2))
end

local function bodyHeight(text, width)
    if text == "" then return 0 end
    local ok, bounds = pcall(function()
        return TextService:GetTextSize(text, Config.BodySize, Enum.Font.Gotham, Vector2.new(width, 10000))
    end)
    return math.clamp(ok and math.ceil(bounds.Y) + 2 or 28, 14, 42)
end

local function measure(record)
    record.width = bannerWidth()
    record.bodyHeight = bodyHeight(record.content, math.max(1, record.width - 24))
    record.height = record.content == "" and 45 or 38 + record.bodyHeight
end

local function attemptBlur(surface)
    if not Config.NativeBlur or blurStatus == "unavailable" then return end
    local blur
    local ok = pcall(function()
        blur = Instance.new("UIBlur")
        blur.Name = "LocalBackdrop"
        blur.Enabled = true
        -- Protect each experimental property separately across client versions.
        pcall(function() blur.Color = Color3.new(1, 1, 1) end)
        pcall(function() blur.Color3 = Color3.new(1, 1, 1) end)
        pcall(function() blur.Strength = Enum.UIBlurStrength.Heavy end)
        pcall(function() blur.Transparency = 0 end)
        blur.Parent = surface
    end)
    if ok then
        blurStatus = "component-created-rendering-unverified"
    else
        if blur then blur:Destroy() end
        blurStatus = "unavailable"
    end
end

local function playSound(record)
    if record.options.Sound == false or Config.Volume <= 0 then return end
    local sound = make("Sound", {
        Name = "SIEXTHER_NotificationSound",
        SoundId = Config.SoundId,
        Volume = Config.Volume,
    }, SoundService)
    record.sound = sound
    Debris:AddItem(sound, 6)
    sound:Play()
end

local function removeFrom(list, record)
    local index = table.find(list, record)
    if index then table.remove(list, index) end
end

local function finish(record)
    if record.finished then return end
    record.finished = true
    cancelThread(record.timer)
    cancelThread(record.enterTimer)
    cancelThread(record.cleanupTimer)
    for _, animation in pairs(record.tweens) do cancelTween(animation) end
    for _, connection in ipairs(record.connections) do connection:Disconnect() end
    if dragging and dragging.record == record then dragging = nil end
    if record.sound then record.sound:Destroy() end
    if record.frame then record.frame:Destroy() end
    removeFrom(active, record)
    removeFrom(pending, record)
    records[record] = nil
end

local function fade(record, alpha, duration)
    for index, target in ipairs(record.fades) do
        local value = target.base + (1 - target.base) * alpha
        tween(record, "fade" .. index, target.object, duration,
            Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { [target.property] = value })
    end
end

local function registerFade(record, object, property)
    record.fades[#record.fades + 1] = {
        object = object,
        property = property,
        base = object[property],
    }
    object[property] = 1
end

local function label(record, name, text, size, color, font, position, dimensions)
    local result = make("TextLabel", {
        Name = name,
        Text = text,
        TextSize = size,
        TextColor3 = color,
        Font = font,
        RichText = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = position,
        Size = dimensions,
        ZIndex = 3,
    }, record.surface)
    registerFade(record, result, "TextTransparency")
    return result
end

local function createVisual(record)
    local frame = make("Frame", {
        Name = "Notification_" .. record.id,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, -record.height - 24),
        Size = UDim2.fromOffset(record.width, record.height),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 10 + record.id % 100,
    }, host)
    record.frame = frame
    record.scale = make("UIScale", { Scale = 0.9 }, frame)

    -- Soft rounded depth, kept behind the glass rather than on its edges.
    for index, expansion in ipairs({ 6, 4, 2 }) do
        local shadow = make("Frame", {
            Name = "SoftShadow" .. index,
            Position = UDim2.fromOffset(-expansion, 3 - expansion),
            Size = UDim2.new(1, expansion * 2, 1, expansion * 2),
            BackgroundColor3 = Color3.fromRGB(10, 19, 39),
            BackgroundTransparency = 0.965 - index * 0.008,
            BorderSizePixel = 0,
            ZIndex = 1,
        }, frame)
        corner(shadow, Config.Radius + expansion)
        registerFade(record, shadow, "BackgroundTransparency")
    end

    local surface = make("Frame", {
        Name = "LiquidGlass",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Config.Background,
        BackgroundTransparency = Config.BackgroundTransparency,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 2,
    }, frame)
    record.surface = surface
    corner(surface, Config.Radius)
    -- Same panel tint and opacity as the supplied VIPUNIV.lua main window.
    make("UIGradient", {
        Name = "GlassTint",
        Rotation = 100,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(230, 244, 255)),
            ColorSequenceKeypoint.new(0.42, Color3.fromRGB(148, 185, 233)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(209, 231, 255)),
        }),
    }, surface)
    registerFade(record, surface, "BackgroundTransparency")
    attemptBlur(surface)

    local edge = make("UIStroke", {
        Name = "GlassRim",
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = Config.Accent,
        Thickness = 1,
        Transparency = 0.18,
    }, surface)
    make("UIGradient", {
        Name = "GlassEdge",
        Rotation = 125,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(133, 184, 255)),
            ColorSequenceKeypoint.new(0.35, Config.Accent),
            ColorSequenceKeypoint.new(0.75, Color3.fromRGB(55, 108, 211)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(139, 194, 255)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.38, 0.36),
            NumberSequenceKeypoint.new(0.72, 0.78),
            NumberSequenceKeypoint.new(1, 0.12),
        }),
    }, edge)
    registerFade(record, edge, "Transparency")

    local sheen = make("Frame", {
        Name = "LiquidReflection",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(178, 219, 255),
        BackgroundTransparency = 0.95,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, surface)
    corner(sheen, Config.Radius)
    record.shine = make("UIGradient", {
        Rotation = -18,
        Offset = Vector2.new(-1, 0),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.34, 1),
            NumberSequenceKeypoint.new(0.49, 0.08),
            NumberSequenceKeypoint.new(0.56, 0.08),
            NumberSequenceKeypoint.new(0.72, 1),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, sheen)
    registerFade(record, sheen, "BackgroundTransparency")

    record.app = label(record, "AppName", record.appName, 8, Config.Secondary,
        Enum.Font.GothamMedium, UDim2.fromOffset(12, 6), UDim2.new(1, -76, 0, 10))
    record.time = label(record, "Time", "sekarang", 8, Config.Secondary,
        Enum.Font.Gotham, UDim2.new(1, -63, 0, 6), UDim2.fromOffset(51, 10))
    record.time.TextXAlignment = Enum.TextXAlignment.Right
    record.titleLabel = label(record, "Title", record.title, 12, Config.Text,
        Enum.Font.GothamBold, UDim2.fromOffset(12, 18), UDim2.new(1, -24, 0, 14))
    record.bodyLabel = label(record, "Content", record.content, Config.BodySize, Config.Text,
        Enum.Font.Gotham, UDim2.fromOffset(12, 34), UDim2.new(1, -24, 0, record.bodyHeight))
    record.bodyLabel.TextWrapped = true
    record.bodyLabel.TextYAlignment = Enum.TextYAlignment.Top
    record.bodyLabel.Visible = record.content ~= ""

    local hit = make("TextButton", {
        Name = "TapOrSwipeToDismiss",
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        AutoButtonColor = false,
        ZIndex = 20,
    }, surface)
    corner(hit, Config.Radius)
    connect(hit.InputBegan, function(input)
        local kind = input.UserInputType
        if destroyed or record.closing or dragging then return end
        if kind ~= Enum.UserInputType.Touch and kind ~= Enum.UserInputType.MouseButton1 then return end
        cancelTween(record.tweens.position)
        dragging = {
            record = record,
            input = input,
            kind = kind,
            start = Vector2.new(input.Position.X, input.Position.Y),
            origin = frame.Position,
            delta = Vector2.new(0, 0),
        }
    end, record.connections)
end

layoutRecord = function(record)
    measure(record)
    if record.frame then
        record.frame.Size = UDim2.fromOffset(record.width, record.height)
        record.bodyLabel.Size = UDim2.new(1, -24, 0, record.bodyHeight)
    end
end

reflow = function()
    local y = Config.Top
    for _, record in ipairs(active) do
        record.restY = y
        if not dragging or dragging.record ~= record then
            tween(record, "position", record.frame, record.entering and 0.48 or 0.32,
                record.entering and Enum.EasingStyle.Back or Enum.EasingStyle.Quint,
                Enum.EasingDirection.Out, { Position = UDim2.new(0.5, 0, 0, y) })
        end
        y = y + record.height + Config.Gap
    end
end

dismiss = function(record, direction)
    if destroyed or record.finished or record.closing then return end
    record.closing = true
    if dragging and dragging.record == record then dragging = nil end
    cancelThread(record.timer)
    cancelThread(record.enterTimer)
    if not record.frame then
        finish(record)
        pump()
        return
    end
    removeFrom(active, record)
    reflow()
    fade(record, 1, 0.22)
    tween(record, "scale", record.scale, 0.25, Enum.EasingStyle.Quart,
        Enum.EasingDirection.In, { Scale = 0.92 })
    local goal = UDim2.new(0.5, 0, 0, -record.height - 24)
    if direction == "right" then
        goal = UDim2.new(1, record.width, 0, record.frame.Position.Y.Offset)
    end
    tween(record, "position", record.frame, 0.28, Enum.EasingStyle.Quart,
        Enum.EasingDirection.In, { Position = goal })
    record.cleanupTimer = task.delay(0.3, function()
        record.cleanupTimer = nil
        finish(record)
    end)
    pump()
end

local function show(record)
    record.entering = true
    table.insert(active, record)
    createVisual(record)
    fade(record, 0, 0.25)
    tween(record, "scale", record.scale, 0.5, Enum.EasingStyle.Back,
        Enum.EasingDirection.Out, { Scale = 1 })
    tween(record, "shine", record.shine, 1.2, Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut, { Offset = Vector2.new(1, 0) })
    reflow()
    playSound(record)
    record.enterTimer = task.delay(0.52, function()
        record.enterTimer = nil
        if destroyed or record.closing or record.finished then return end
        record.entering = false
        if record.duration > 0 then
            record.timer = task.delay(record.duration, function()
                record.timer = nil
                dismiss(record)
            end)
        end
    end)
end

pump = function()
    if destroyed then return end
    if pumping then pumpAgain = true; return end
    pumping = true
    repeat
        pumpAgain = false
        while #pending > 0 and #active < Config.MaxVisible do
            local nextRecord = pending[1]
            measure(nextRecord)
            local used = Config.Top
            for _, record in ipairs(active) do used = used + record.height + Config.Gap end
            if #active > 0 and used + nextRecord.height > screenSize().Y - Config.Margin then break end
            table.remove(pending, 1)
            show(nextRecord)
        end
    until not pumpAgain
    pumping = false
end

connect(UserInputService.InputChanged, function(input)
    local gesture = dragging
    if not gesture then return end
    if gesture.kind == Enum.UserInputType.Touch then
        if input ~= gesture.input then return end
    elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
        return
    end
    local record = gesture.record
    local delta = Vector2.new(input.Position.X, input.Position.Y) - gesture.start
    gesture.delta = delta
    record.frame.Position = UDim2.new(gesture.origin.X.Scale,
        gesture.origin.X.Offset + math.max(0, delta.X), 0,
        gesture.origin.Y.Offset + (delta.Y < 0 and delta.Y or delta.Y * 0.18))
end)

connect(UserInputService.InputEnded, function(input)
    local gesture = dragging
    if not gesture then return end
    if gesture.kind == Enum.UserInputType.Touch then
        if input ~= gesture.input then return end
    elseif input.UserInputType ~= Enum.UserInputType.MouseButton1 then
        return
    end
    dragging = nil
    local record, delta = gesture.record, gesture.delta
    if record.finished or record.closing then return end
    if delta.Y < -32 or delta.X > record.width * 0.22 then
        dismiss(record, delta.X > math.abs(delta.Y) and "right" or "up")
    elseif delta.Magnitude < 9 then
        dismiss(record)
        if type(record.options.OnClick) == "function" then
            task.spawn(function()
                local ok, message = pcall(record.options.OnClick)
                if not ok then warn("SIEXTHER notification OnClick: " .. tostring(message)) end
            end)
        end
    else
        reflow()
    end
end)

connect(UserInputService.WindowFocusReleased, function()
    if dragging then dragging = nil; reflow() end
end)

connect(host:GetPropertyChangedSignal("AbsoluteSize"), function()
    if destroyed then return end
    dragging = nil
    for _, record in ipairs(active) do layoutRecord(record) end
    -- On rotation, move excess cards back into the queue without dropping them.
    local used, overflow = Config.Top, {}
    for index, record in ipairs(active) do
        if index > 1 and used + record.height > screenSize().Y - Config.Margin then
            table.insert(overflow, record)
        else
            used = used + record.height + Config.Gap
        end
    end
    for index = #overflow, 1, -1 do
        local record = overflow[index]
        removeFrom(active, record)
        cancelThread(record.timer)
        cancelThread(record.enterTimer)
        record.timer, record.enterTimer = nil, nil
        for _, animation in pairs(record.tweens) do cancelTween(animation) end
        for _, connection in ipairs(record.connections) do connection:Disconnect() end
        if record.sound then record.sound:Destroy(); record.sound = nil end
        record.frame:Destroy()
        record.frame, record.tweens, record.connections, record.fades = nil, {}, {}, {}
        table.insert(pending, 1, record)
    end
    reflow()
    pump()
end)

function Controller.Notify(options)
    if destroyed then return nil, "Notification system has been destroyed." end
    options = type(options) == "table" and options or { Content = tostring(options or "") }
    if #pending >= Config.MaxQueued then return nil, "Notification queue is full." end
    local duration = tonumber(options.Duration)
    if not duration or duration ~= duration then duration = 5 end
    duration = math.clamp(duration, 0, 86400) -- 0 keeps the banner until dismissed.
    sequence = sequence + 1
    local record = {
        id = sequence,
        options = options,
        title = tostring(options.Title or "Notification"),
        content = tostring(options.Content or "No content provided"),
        appName = tostring(options.AppName or Config.AppName),
        duration = duration,
        tweens = {},
        connections = {},
        fades = {},
    }
    local handle = {}
    function handle.Close() dismiss(record) end
    function handle.IsClosed() return record.closing == true or record.finished == true end
    records[record] = true
    table.insert(pending, record)
    pump()
    return handle
end

function Controller.Clear()
    local queued = pending
    pending = {}
    for _, record in ipairs(queued) do record.closing = true; finish(record) end
    local shown = {}
    for _, record in ipairs(active) do table.insert(shown, record) end
    for _, record in ipairs(shown) do dismiss(record) end
end

function Controller.Status()
    return {
        Active = #active,
        Queued = #pending,
        NativeBlur = blurStatus,
        RenderingVerified = false,
        CameraEffects = false,
    }
end

function Controller.Destroy()
    if destroyed then return end
    destroyed = true
    dragging = nil
    for _, connection in ipairs(connections) do connection:Disconnect() end
    -- Include queued banners and banners already in their closing animation.
    local remaining = {}
    for record in pairs(records) do table.insert(remaining, record) end
    for _, record in ipairs(remaining) do finish(record) end
    gui:Destroy()
    if environment.Notify == Controller.Notify then environment.Notify = nil end
    if environment.__SIEXTHER_IOS_NOTIFICATIONS == Controller then
        environment.__SIEXTHER_IOS_NOTIFICATIONS = nil
    end
end

environment.__SIEXTHER_IOS_NOTIFICATIONS = Controller
environment.Notify = Controller.Notify

return Controller
