-- SIEXTHER: liquid glass from VIPUNIV.lua; original feature code follows below.
do
    local environment = (type(getgenv) == "function" and getgenv()) or _G
    if not environment.__SIEXTHER_VIP_GLASS_V1 then
        environment.__SIEXTHER_VIP_GLASS_V1 = (function()
            -- SIEXTHER / VIP UNIV liquid glass.
            -- The palette, surface(), edge/fill gradients and blur strength come from VIPUNIV.lua.
            -- This module owns only ScreenGuis constructed through its private Instance facade.
            -- It does not hook Roblox globals or restyle the game's own interface.
            local nativeInstance = Instance
            local nativeLoadString = loadstring
            local nativeGetEnvironment = getfenv
            local nativeSetEnvironment = setfenv
            local scheduler = task
            local TweenService = game:GetService("TweenService")
            local Lighting = game:GetService("Lighting")
            
            local Glass = {
                Version = "VIPUNIV-1.0",
                primaryColor = Color3.fromRGB(70, 130, 255),
                accentColor = Color3.fromRGB(100, 200, 255),
                bgColor = Color3.fromRGB(43, 62, 91),
                buttonColor = Color3.fromRGB(219, 232, 255),
                textColor = Color3.fromRGB(255, 255, 255),
                panelTransparency = 0.48,
                cardTransparency = 0.88,
                blurSize = 18,
            }
            local prefix = "__VIPGlass_"
            local roots = {}
            local objects = setmetatable({}, {__mode = "k"})
            local environmentCache = setmetatable({}, {__mode = "k"})
            local blur, blurTween, blurTarget
            local refreshQueued = false
            local styleObject, queueObject, refreshBlur
            
            local function own(object)
                return object.Name:sub(1, #prefix) == prefix
            end
            local function put(record, property, value)
                record.output[property] = value
                if record.object[property] ~= value then record.object[property] = value end
            end
            local function namedChild(object, class, name)
                local child = object:FindFirstChild(name)
                if not child then
                    child = nativeInstance.new(class)
                    child.Name = name
                    child.Parent = object
                end
                return child
            end
            local function gradient(object, name, rotation, colors, alpha)
                local existing = object:FindFirstChild(prefix .. name)
                if existing then return existing end
                local fill = namedChild(object, "UIGradient", prefix .. name)
                fill.Rotation = rotation
                fill.Color = ColorSequence.new(colors)
                if alpha then fill.Transparency = NumberSequence.new(alpha) end
                return fill
            end
            local function visible(object, root)
                if not root.Parent or not root.Enabled then return false end
                local parent = object
                while parent and parent ~= root do
                    if parent:IsA("GuiObject") and not parent.Visible then return false end
                    parent = parent.Parent
                end
                return parent == root
            end
            local function dimensions(object)
                local size, absolute = object.Size, object.AbsoluteSize
                local width = absolute.X > 0 and absolute.X or size.X.Offset
                local height = absolute.Y > 0 and absolute.Y or size.Y.Offset
                return width, height
            end
            local function hasLayout(object)
                return object:FindFirstChildOfClass("UIListLayout")
                    or object:FindFirstChildOfClass("UIGridLayout")
                    or object:FindFirstChildOfClass("UIPageLayout")
                    or object:FindFirstChildOfClass("UITableLayout")
            end
            local function skip(object, root)
                -- Reticles, radar artwork, sampled colors and viewport renders are content, not panels.
                if root:GetAttribute("VIPGlassIgnore") then return true end
                local rootName = root.Name:lower()
                if rootName == "hannsiexther_crosshair" or rootName == "explorerselections"
                    or rootName == "alignindicator" then return true end
                local current = object
                while current and current ~= root do
                    if current:GetAttribute("VIPGlassIgnore") or current:IsA("ViewportFrame")
                        or current:IsA("BillboardGui") or current:IsA("SurfaceGui")
                        or own(current) then return true end
                    local name = current.Name:lower()
                    if name == "crosshairpreview" or name == "crosshaircanvas"
                        or name == "radarcanvas" or name == "radarmap"
                        or name == "hue" or name == "saturation" or name == "colorwheel"
                        or name == "colorchoice" or name:find("swatch", 1, true)
                        or name == "syntaxhighlight" then return true end
                    current = current.Parent
                end
                return false
            end
            local function saturated(color)
                local _, saturation, value = color:ToHSV()
                return saturation > 0.32 and value > 0.22
            end
            local function statusColor(color)
                local h, s, v = color:ToHSV()
                return s > 0.4 and v > 0.55 and (h < 0.17 or (h > 0.2 and h < 0.48) or h > 0.95)
            end
            local function hasOpaqueAncestor(object, root)
                local parent = object.Parent
                while parent and parent ~= root do
                    if parent:IsA("GuiObject") then
                        local record = objects[parent]
                        local alpha = record and record.source.BackgroundTransparency or parent.BackgroundTransparency
                        if alpha < 1 then return true end
                    end
                    parent = parent.Parent
                end
                return false
            end
            
            -- Adapted directly from settings.Glass.surface in VIPUNIV.lua.
            function Glass.surface(object, transparency, radius, edge)
                object.BackgroundTransparency = transparency
                object.BorderSizePixel = 0
                local corner = object:FindFirstChildOfClass("UICorner")
                if not corner then corner = namedChild(object, "UICorner", prefix .. "Corner") end
                corner.CornerRadius = UDim.new(0, radius)
                local stroke = namedChild(object, "UIStroke", prefix .. "Edge")
                stroke.Enabled = true
                stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                stroke.Color = Glass.primaryColor
                stroke.Thickness = radius >= 20 and 1.6 or 1
                stroke.Transparency = edge or 0.78
                gradient(stroke, "GlassEdge", 125, {
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(133, 184, 255)),
                    ColorSequenceKeypoint.new(0.35, Glass.primaryColor),
                    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(55, 108, 211)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(139, 194, 255)),
                }, {
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.38, 0.36),
                    NumberSequenceKeypoint.new(0.72, 0.78),
                    NumberSequenceKeypoint.new(1, 0.12),
                })
            end
            local function fill(record, panel)
                local object = record.object
                for _, child in ipairs(object:GetChildren()) do
                    if child:IsA("UIGradient") and not own(child) then child.Enabled = false end
                end
                local tint
                if panel then
                    tint = gradient(object, "GlassTint", 100, {
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(230, 244, 255)),
                        ColorSequenceKeypoint.new(0.42, Color3.fromRGB(148, 185, 233)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(209, 231, 255)),
                    })
                else
                    tint = gradient(object, "GlassFill", 105, {
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(183, 207, 243)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 244, 255)),
                    })
                end
                tint.Enabled = true
                return tint
            end
            local function clearSurface(record)
                local object = record.object
                for _, name in ipairs({"Edge", "GlassTint", "GlassFill"}) do
                    local child = object:FindFirstChild(prefix .. name)
                    if child then child.Enabled = false end
                end
            end
            local function stopSheen(record)
                if record.sweep then record.sweep:Cancel(); record.sweep = nil end
                if record.sheen then record.sheen:Destroy(); record.sheen = nil end
                if record.rim then record.rim:Destroy(); record.rim = nil end
            end
            local function panelDetail(record)
                local object = record.object
                -- Extra GuiObjects must never become entries in an existing automatic layout.
                if hasLayout(object) then stopSheen(record); return end
                if not record.rim then
                    local rim = namedChild(object, "Frame", prefix .. "LiquidInnerRim")
                    rim.Active = false
                    rim.Selectable = false
                    rim.Size = UDim2.new(1, -6, 1, -6)
                    rim.Position = UDim2.new(0, 3, 0, 3)
                    rim.BackgroundTransparency = 1
                    rim.BorderSizePixel = 0
                    rim.ZIndex = object.ZIndex
                    namedChild(rim, "UICorner", prefix .. "Corner").CornerRadius = UDim.new(0, 19)
                    local stroke = namedChild(rim, "UIStroke", prefix .. "RimEdge")
                    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    stroke.Color = Color3.fromRGB(146, 193, 255)
                    stroke.Transparency = 0.77
                    stroke.Thickness = 1
                    gradient(stroke, "RimShine", 105, {
                        ColorSequenceKeypoint.new(0, Glass.textColor),
                        ColorSequenceKeypoint.new(1, Glass.textColor),
                    }, {
                        NumberSequenceKeypoint.new(0, 0.08),
                        NumberSequenceKeypoint.new(0.48, 0.85),
                        NumberSequenceKeypoint.new(1, 0.26),
                    })
                    record.rim = rim
                end
                -- VIP UNIV's clipped light sweep; do not enable clipping on an existing popup host.
                if object.ClipsDescendants and not record.sheen then
                    local sheen = namedChild(object, "Frame", prefix .. "LiquidSheen")
                    sheen.Active = false
                    sheen.Selectable = false
                    sheen.Position = UDim2.new(0, -90, 0, 0)
                    sheen.Size = UDim2.new(0, 92, 1, 0)
                    sheen.Rotation = -12
                    sheen.BackgroundColor3 = Color3.fromRGB(178, 219, 255)
                    sheen.BackgroundTransparency = 0.95
                    sheen.BorderSizePixel = 0
                    sheen.ZIndex = object.ZIndex
                    gradient(sheen, "SheenFade", 0, {
                        ColorSequenceKeypoint.new(0, Glass.textColor),
                        ColorSequenceKeypoint.new(1, Glass.textColor),
                    }, {
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(0.45, 0.18),
                        NumberSequenceKeypoint.new(0.55, 0.18),
                        NumberSequenceKeypoint.new(1, 1),
                    })
                    record.sheen = sheen
                    record.sweep = TweenService:Create(sheen,
                        TweenInfo.new(1.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 7),
                        {Position = UDim2.new(1, 60, 0, 0)})
                end
                if record.sweep then
                    if visible(object, record.root) then record.sweep:Play() else record.sweep:Pause() end
                end
            end
            local function shadow(record)
                local object = record.object
                if object.Parent ~= record.root or hasLayout(record.root) then return end
                -- Global ZIndex layouts may place their text at level 1. Never raise their panel over it.
                if object.ZIndex <= 1 and record.root.ZIndexBehavior == Enum.ZIndexBehavior.Global then return end
                if not record.shadow then
                    local holder = namedChild(record.root, "Frame", prefix .. "Shadow_" .. tostring(record.id))
                    holder.Active = false
                    holder.Selectable = false
                    holder.BackgroundTransparency = 1
                    holder.BorderSizePixel = 0
                    holder.ZIndex = math.max(1, object.ZIndex - 1)
                    if object.ZIndex == 1 then put(record, "ZIndex", 2) end
                    for i = 1, 5 do
                        local layer = nativeInstance.new("Frame")
                        layer.Name = prefix .. "ShadowLayer"
                        layer.Active = false
                        layer.AnchorPoint = Vector2.new(0.5, 0.5)
                        layer.Position = UDim2.new(0.5, 0, 0.5, 5)
                        layer.Size = UDim2.new(1, i * 5, 1, i * 5)
                        layer.BackgroundColor3 = Color3.fromRGB(4, 8, 18)
                        layer.BackgroundTransparency = 0.96
                        layer.BorderSizePixel = 0
                        layer.ZIndex = holder.ZIndex
                        namedChild(layer, "UICorner", prefix .. "Corner").CornerRadius = UDim.new(0, 22 + i * 2)
                        layer.Parent = holder
                    end
                    record.shadow = holder
                end
                local holder = record.shadow
                holder.Position = object.Position
                holder.Size = object.Size
                holder.AnchorPoint = object.AnchorPoint
                holder.Visible = visible(object, record.root)
                holder.ZIndex = math.max(1, object.ZIndex - 1)
                local scale = object:FindFirstChildOfClass("UIScale")
                local copy = holder:FindFirstChildOfClass("UIScale")
                if scale then
                    copy = copy or namedChild(holder, "UIScale", prefix .. "Scale")
                    copy.Scale = scale.Scale
                elseif copy then copy.Scale = 1 end
            end
            local function setPanel(record, isPanel)
                record.panel = isPanel
                local state = roots[record.root]
                if state then state.panels[record.object] = isPanel and record or nil end
                if isPanel then panelDetail(record); shadow(record)
                else
                    stopSheen(record)
                    if record.shadow then record.shadow:Destroy(); record.shadow = nil end
                end
            end
            local function watch(record, signal, callback)
                record.connections[#record.connections + 1] = signal:Connect(callback)
            end
            local function dispose(record)
                if record.dead then return end
                record.dead = true
                for _, connection in ipairs(record.connections) do connection:Disconnect() end
                record.connections = {}
                stopSheen(record)
                if record.shadow then record.shadow:Destroy(); record.shadow = nil end
                objects[record.object] = nil
                local root = roots[record.root]
                if root then root.objects[record.object] = nil; root.panels[record.object] = nil end
            end
            
            styleObject = function(record)
                local object, root = record.object, record.root
                if record.dead or not object.Parent or not object:IsDescendantOf(root) or skip(object, root) then
                    if record.panel then setPanel(record, false) end
                    return
                end
                local source = record.source
                local width, height = dimensions(object)
                local name = object.Name:lower()
                local text = object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")
                local image = object:IsA("ImageLabel") or object:IsA("ImageButton")
                local button = object:IsA("GuiButton")
                local imageSurface = image and height >= 64 and object.Image ~= ""
                    and not name:find("shadow", 1, true) and not name:find("glow", 1, true)
                    and (object.ScaleType == Enum.ScaleType.Slice or name == "main" or name == "window"
                        or name == "background" or name == "mainframe")
                record.writing = true
                put(record, "BorderSizePixel", 0)
                if text then
                    -- Code editors and ASCII diagrams need their original character widths.
                    if source.Font ~= Enum.Font.Code and source.Font ~= Enum.Font.RobotoMono then
                        put(record, "Font", Enum.Font.GothamBold)
                    end
                    put(record, "TextColor3", statusColor(source.TextColor3) and source.TextColor3 or Glass.textColor)
                    put(record, "TextStrokeTransparency", 1)
                    if object:IsA("TextBox") then put(record, "PlaceholderColor3", Color3.fromRGB(180, 191, 210)) end
                    for _, child in ipairs(object:GetChildren()) do
                        if child:IsA("UIGradient") and not own(child) then
                            child.Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Glass.textColor),
                                ColorSequenceKeypoint.new(0.3, Glass.primaryColor),
                                ColorSequenceKeypoint.new(0.6, Glass.primaryColor),
                                ColorSequenceKeypoint.new(1, Glass.textColor),
                            })
                        end
                    end
                end
                if object:IsA("ScrollingFrame") then
                    put(record, "ScrollBarImageColor3", Glass.primaryColor)
                    put(record, "ScrollBarThickness", math.min(source.ScrollBarThickness, 4))
                end
                if button then put(record, "AutoButtonColor", false) end
                -- Sprite sheets, profile pictures and artwork keep their image colors and gradients.
                if image and object.Image ~= "" and not imageSurface then
                    setPanel(record, false)
                    if source.BackgroundTransparency < 1 then
                        put(record, "BackgroundColor3", Glass.buttonColor)
                        put(record, "BackgroundTransparency", Glass.cardTransparency)
                        record.output.BackgroundTransparency = Glass.cardTransparency
                        Glass.surface(object, Glass.cardTransparency, 11, 0.62)
                    end
                    record.writing = false
                    return
                end
                local transparent = not imageSurface and source.BackgroundTransparency >= 1
                local compact = object.Size.Y.Scale == 0 and height > 0 and height <= 10
                local knob = name:find("knob", 1, true) or name:find("dragger", 1, true)
                    or name:find("thumb", 1, true) or name == "toggleindicator"
                local track = (name:find("switch", 1, true) or name:find("toggle", 1, true))
                    and width <= 70 and height <= 30
                if not track and button and text and object.Text == "" and width > 22 and width <= 65
                    and height > 12 and height <= 28 and #object:GetChildren() > 0 then track = true end
                local panel = not transparent and (object:IsA("Frame") or imageSurface) and not object:IsA("ScrollingFrame")
                    and not compact and not knob and not track
                    and (((not hasOpaqueAncestor(object, root)) and (height >= 64 or object.Size.Y.Scale > 0))
                        or ((name:find("popup", 1, true) or name:find("modal", 1, true)
                            or name == "mainframe" or name == "window") and height >= 64))
                if imageSurface then put(record, "ImageTransparency", 1) end
                setPanel(record, panel)
                if transparent then
                    clearSurface(record)
                    put(record, "BackgroundTransparency", 1)
                elseif compact or knob or track then
                    clearSurface(record)
                    local active = saturated(source.BackgroundColor3)
                    local color = knob and Glass.textColor or (active and Glass.primaryColor or Color3.fromRGB(176, 189, 211))
                    local alpha = knob and 0 or (track and (active and 0.08 or 0.7) or (active and 0 or 0.8))
                    put(record, "BackgroundColor3", color)
                    put(record, "BackgroundTransparency", alpha)
                    local corner = object:FindFirstChildOfClass("UICorner")
                    if corner then corner.CornerRadius = UDim.new(1, 0) end
                else
                    local active = not panel and button and saturated(source.BackgroundColor3)
                    local section = not panel and (name:find("sidebar", 1, true) or name:find("header", 1, true)
                        or name == "topbar" or name == "titlebar" or name == "sxthr")
                    local search = object:IsA("TextBox") or name:find("search", 1, true)
                    local alpha = panel and Glass.panelTransparency or (active and 0.28 or (section and 0.94 or (search and 0.9 or Glass.cardTransparency)))
                    local color = panel and Glass.bgColor or (active and Glass.primaryColor or Glass.buttonColor)
                    put(record, "BackgroundColor3", color)
                    put(record, "BackgroundTransparency", record.hovering and not panel and math.min(alpha, 0.84) or alpha)
                    local actualAlpha = record.output.BackgroundTransparency
                    Glass.surface(object, actualAlpha, panel and 22 or (search and 12 or 11), panel and 0.18 or 0.62)
                    record.output.BackgroundTransparency = actualAlpha
                    fill(record, panel)
                end
                for _, child in ipairs(object:GetChildren()) do
                    if child:IsA("UIStroke") and not own(child) then child.Enabled = false end
                end
                record.writing = false
            end
            
            queueObject = function(root, object)
                local state = roots[root]
                if not state or state.dead or own(object) then return end
                if not object:IsA("GuiObject") then
                    if object.Parent and object.Parent:IsA("GuiObject") then queueObject(root, object.Parent) end
                    return
                end
                if skip(object, root) then return end
                local record = objects[object]
                if record and record.root ~= root then dispose(record); record = nil end
                if not record then
                    state.serial = state.serial + 1
                    record = {object = object, root = root, source = {}, output = {}, connections = {}, id = state.serial}
                    objects[object] = record
                    state.objects[object] = record
                    local properties = {"BackgroundColor3", "BackgroundTransparency", "BorderSizePixel"}
                    if object:IsA("TextLabel") or object:IsA("TextBox") or object:IsA("TextButton") then
                        for _, property in ipairs({"TextColor3", "Font", "TextStrokeTransparency"}) do
                            properties[#properties + 1] = property
                        end
                    end
                    if object:IsA("ScrollingFrame") then
                        properties[#properties + 1] = "ScrollBarImageColor3"
                        properties[#properties + 1] = "ScrollBarThickness"
                    end
                    for _, property in ipairs(properties) do
                        record.source[property] = object[property]
                        watch(record, object:GetPropertyChangedSignal(property), function()
                            if record.dead or record.writing or object[property] == record.output[property] then return end
                            record.source[property] = object[property]
                            queueObject(root, object)
                        end)
                    end
                    for _, property in ipairs({"Visible", "Size", "AbsoluteSize", "ClipsDescendants", "Name"}) do
                        watch(record, object:GetPropertyChangedSignal(property), function()
                            if not record.dead then queueObject(root, object); refreshBlur() end
                        end)
                    end
                    for _, property in ipairs({"Position", "AnchorPoint"}) do
                        watch(record, object:GetPropertyChangedSignal(property), function()
                            if not record.dead and record.panel then shadow(record) end
                        end)
                    end
                    watch(record, object.Destroying, function() dispose(record); refreshBlur() end)
                    if object:IsA("GuiButton") then
                        watch(record, object.MouseEnter, function() record.hovering = true; queueObject(root, object) end)
                        watch(record, object.MouseLeave, function() record.hovering = false; queueObject(root, object) end)
                    end
                end
                state.pending[object] = record
                if state.queued then return end
                state.queued = true
                scheduler.defer(function()
                    if state.dead then return end
                    state.queued = false
                    local pending = state.pending
                    state.pending = {}
                    local count = 0
                    for _, item in pairs(pending) do
                        if not item.dead then styleObject(item) end
                        count = count + 1
                        if count % 80 == 0 then scheduler.wait() end
                    end
                    refreshBlur()
                end)
            end
            
            refreshBlur = function()
                if refreshQueued then return end
                refreshQueued = true
                scheduler.defer(function()
                    refreshQueued = false
                    local active, any = false, false
                    for root, state in pairs(roots) do
                        if not state.dead then
                            any = true
                            for _, record in pairs(state.panels) do
                                if record.panel and not record.dead then
                                    local _, height = dimensions(record.object)
                                    local shown = visible(record.object, root)
                                    if record.shadow then record.shadow.Visible = shown end
                                    if record.sweep then
                                        if shown then record.sweep:Play() else record.sweep:Pause() end
                                    end
                                    if shown and height >= 64 then active = true end
                                end
                            end
                        end
                    end
                    if not any then
                        if blurTween then blurTween:Cancel(); blurTween = nil end
                        if blur then blur:Destroy(); blur = nil end
                        blurTarget = nil
                        return
                    end
                    if not active and not blur then return end
                    if not blur or not blur.Parent then
                        blur = nativeInstance.new("BlurEffect")
                        blur.Name = prefix .. "Blur"
                        blur.Size = 0
                        blur.Parent = Lighting
                        blurTarget = nil
                    end
                    local target = active and Glass.blurSize or 0
                    if target == blurTarget then return end
                    blurTarget = target
                    if blurTween then blurTween:Cancel() end
                    blurTween = TweenService:Create(blur, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = target})
                    blurTween:Play()
                end)
            end
            
            function Glass.attach(root)
                if not root:IsA("ScreenGui") or roots[root] then return root end
                local state = {objects = {}, panels = {}, pending = {}, connections = {}, serial = 0}
                roots[root] = state
                local function connect(signal, callback)
                    state.connections[#state.connections + 1] = signal:Connect(callback)
                end
                local function scan()
                    if state.dead then return end
                    for _, object in ipairs(root:GetDescendants()) do
                        if not own(object) then queueObject(root, object) end
                    end
                    refreshBlur()
                end
                connect(root.DescendantAdded, function(object)
                    queueObject(root, object)
                    if object:IsA("UIScale") then
                        connect(object:GetPropertyChangedSignal("Scale"), function()
                            if object.Parent then queueObject(root, object.Parent) end
                        end)
                    end
                end)
                connect(root.DescendantRemoving, function(object)
                    local record = objects[object]
                    if record and record.root == root then
                        scheduler.defer(function()
                            if not record.dead and not object:IsDescendantOf(root) then dispose(record); refreshBlur() end
                        end)
                    end
                end)
                connect(root:GetPropertyChangedSignal("Enabled"), refreshBlur)
                connect(root:GetPropertyChangedSignal("Name"), scan)
                connect(root.AncestryChanged, refreshBlur)
                connect(root.Destroying, function()
                    state.dead = true
                    for _, connection in ipairs(state.connections) do connection:Disconnect() end
                    local toRemove = {}
                    for _, record in pairs(state.objects) do toRemove[#toRemove + 1] = record end
                    for _, record in ipairs(toRemove) do dispose(record) end
                    roots[root] = nil
                    refreshBlur()
                end)
                scheduler.defer(scan)
                return root
            end
            
            Glass.Instance = setmetatable({}, {__index = nativeInstance})
            function Glass.Instance.new(class, parent)
                local object = nativeInstance.new(class)
                if class == "ScreenGui" then Glass.attach(object) end
                if parent then object.Parent = parent end
                return object
            end
            
            local function environmentFor(base)
                base = base or _G
                local cached = environmentCache[base]
                if cached then return cached end
                local wrapped = setmetatable({}, {
                    __index = function(_, key)
                        if key == "Instance" then return Glass.Instance end
                        if key == "loadstring" then return Glass.LoadString end
                        if key == "getfenv" then return Glass.GetEnvironment end
                        return base[key]
                    end,
                    __newindex = function(_, key, value) base[key] = value end,
                })
                environmentCache[base] = wrapped
                environmentCache[wrapped] = wrapped
                return wrapped
            end
            function Glass.GetEnvironment(level)
                local base
                if nativeGetEnvironment then
                    if level == nil then base = nativeGetEnvironment(2)
                    elseif type(level) == "number" then base = nativeGetEnvironment(level == 0 and 0 or level + 1)
                    else base = nativeGetEnvironment(level) end
                end
                return environmentFor(base)
            end
            function Glass.LoadString(source, chunkName)
                local compiled, message = nativeLoadString(source, chunkName)
                if compiled and nativeSetEnvironment then
                    local base = nativeGetEnvironment and nativeGetEnvironment(compiled) or _G
                    nativeSetEnvironment(compiled, environmentFor(base))
                end
                return compiled, message
            end
            
            -- A few original menus use their old paint colors as selection state.
            -- Those comparisons must keep reading the source value after a glass repaint.
            function Glass.Read(object, property)
                local record = objects[object]
                if record and record.source[property] ~= nil and object[property] == record.output[property] then
                    return record.source[property]
                end
                return object[property]
            end
            
            return Glass
        end)()
    end
    __SIEXTHER_VIP_GLASS_V1 = environment.__SIEXTHER_VIP_GLASS_V1
end
-- BEGIN ORIGINAL FEATURE CODE (GUI construction uses the VIP UNIV theme).
if _G.SiextherVD then
    for _, v in pairs(_G.SiextherVD) do pcall(function() v:Disconnect() end) end
    _G.SiextherVD = nil
end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

_G.SiextherVD = {}
local Connections = _G.SiextherVD

-- NOTIFY
__SIEXTHER_VIP_GLASS_V1.LoadString(game:HttpGet("https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/han.lua"))()

local function Notif(title, content, duration)
    pcall(function()
        getgenv().Notify({
            Title    = title or "SIEXTHER VD",
            Content  = content or "",
            Duration = duration or 3,
        })
    end)
end

-- THEME
local C = {
    bg      = Color3.fromRGB(25, 25, 35),
    surface = Color3.fromRGB(20, 20, 32),
    card    = Color3.fromRGB(26, 26, 40),
    stroke  = Color3.fromRGB(70, 130, 255),
    accent  = Color3.fromRGB(100, 180, 255),
    text    = Color3.fromRGB(230, 230, 240),
    subtext = Color3.fromRGB(120, 130, 155),
    onClr   = Color3.fromRGB(70, 130, 255),
    offClr  = Color3.fromRGB(38, 38, 52),
    red     = Color3.fromRGB(220, 60, 60),
    redHov  = Color3.fromRGB(255, 80, 80),
    minClr  = Color3.fromRGB(40, 90, 200),
    minHov  = Color3.fromRGB(70, 130, 255),
}

local TW = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- HELPERS
local function tween(obj, props) TweenService:Create(obj, TW, props):Play() end

local function corner(parent, radius)
    local c = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thick)
    local s = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
    s.Color = color or C.stroke
    s.Thickness = thick or 1.5
    s.Parent = parent
    return s
end

local function makeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))
end

-- IS KILLER DETECTION
local function IsKiller(player)
    if not player or player == LocalPlayer then return false end
    if player:GetAttribute("Role") == "Killer" or player:GetAttribute("Killerost") then return true end
    local char = player.Character
    if char then
        for _, n in ipairs({"Weapon","Knife","Axe","Sword","Gun","KillerTool","MurderTool"}) do
            if char:FindFirstChild(n) then return true end
        end
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") then
                local nm = child.Name:lower()
                if nm:find("weapon") or nm:find("knife") or nm:find("gun") then return true end
            end
        end
    end
    return false
end

local function isKiller()
    return LocalPlayer.Team and LocalPlayer.Team.Name == "Killer"
end

local function getCharacterRootPart()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then return nil end
    return result
end

-- CROSSHAIR
local function ToggleCrosshair(state)
    local nm = "SVD_CrosshairGui"
    local cg = game:GetService("CoreGui")
    local ex = cg:FindFirstChild(nm) or PlayerGui:FindFirstChild(nm)
    if ex then ex:Destroy() end
    if not state then return end

    local gui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
    gui.Name = nm; gui.DisplayOrder = 999
    gui.IgnoreGuiInset = true; gui.ResetOnSpawn = false

    

    local ring = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Size = UDim2.fromOffset(14, 14)
    ring.Position = UDim2.fromScale(0.5, 0.5)
    ring.BackgroundTransparency = 1
    ring.Parent = gui
    stroke(ring, C.stroke, 1.5)
    corner(ring, 7)

    local dot = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Size = UDim2.fromOffset(4, 4)
    dot.Position = UDim2.fromScale(0.5, 0.5)
    dot.BackgroundColor3 = C.accent
    dot.BorderSizePixel = 0
    dot.Parent = gui
    corner(dot, 2)

    gui.Parent = cg
end

-- NOCLIP
local function ToggleNoclip(state)
    if Connections.NoclipLoop then
        pcall(function() Connections.NoclipLoop:Disconnect() end)
        Connections.NoclipLoop = nil
    end

    if state then
        Connections.NoclipLoop = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
        Notif("SIEXTHER VD", "Noclip ON", 2)
    else
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
        Notif("SIEXTHER VD", "Noclip OFF", 2)
    end
end

-- SURVIVOR ESP
local SurvivorESPActive = false

local function ClearSurvivorESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            if char then
                local hl = char:FindFirstChild("SVD_SurvHL")
                if hl then hl:Destroy() end
                local bb = char:FindFirstChild("SVD_SurvBB")
                if bb then bb:Destroy() end
            end
        end
    end
end

local function ApplySurvivorESPToChar(char, player)
    if not char then return end
    if not char:FindFirstChild("SVD_SurvHL") then
        local hl = __SIEXTHER_VIP_GLASS_V1.Instance.new("Highlight")
        hl.Name = "SVD_SurvHL"
        hl.FillColor = Color3.fromRGB(70, 130, 255)
        hl.OutlineColor = Color3.fromRGB(130, 180, 255)
        hl.FillTransparency = 0.4
        hl.OutlineTransparency = 0
        hl.Adornee = char
        hl.Parent = char
    end

    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if rootPart and not char:FindFirstChild("SVD_SurvBB") then
        local bb = __SIEXTHER_VIP_GLASS_V1.Instance.new("BillboardGui")
        bb.Name = "SVD_SurvBB"
        bb.Size = UDim2.new(0, 90, 0, 34)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.AlwaysOnTop = true
        bb.Adornee = rootPart
        bb.Parent = char

        local nameLbl = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, 0, 0.55, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextColor3 = Color3.fromRGB(70, 130, 255)
        nameLbl.TextStrokeTransparency = 0
        nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLbl.TextSize = 11
        nameLbl.Text = player.Name
        nameLbl.Parent = bb

        local distLbl = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
        distLbl.Size = UDim2.new(1, 0, 0.45, 0)
        distLbl.Position = UDim2.new(0, 0, 0.55, 0)
        distLbl.BackgroundTransparency = 1
        distLbl.Font = Enum.Font.Gotham
        distLbl.TextColor3 = Color3.fromRGB(160, 190, 255)
        distLbl.TextStrokeTransparency = 0
        distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        distLbl.TextSize = 9
        distLbl.Text = "..."
        distLbl.Parent = bb

        table.insert(Connections, RunService.RenderStepped:Connect(function()
            if not SurvivorESPActive then return end
            local lc = LocalPlayer.Character
            local hrp = lc and lc:FindFirstChild("HumanoidRootPart")
            if hrp and rootPart and rootPart.Parent then
                local dist = math.floor((hrp.Position - rootPart.Position).Magnitude)
                distLbl.Text = dist .. " studs"
            end
        end))
    end
end

local function ToggleSurvivorESP(state)
    SurvivorESPActive = state
    if Connections.SurvESPLoop then
        pcall(function() Connections.SurvESPLoop:Disconnect() end)
        Connections.SurvESPLoop = nil
    end
    if state then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not IsKiller(p) and p.Character then
                ApplySurvivorESPToChar(p.Character, p)
            end
        end
        Connections.SurvESPLoop = RunService.Heartbeat:Connect(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and not IsKiller(p) and p.Character then
                    if not p.Character:FindFirstChild("SVD_SurvHL") then
                        ApplySurvivorESPToChar(p.Character, p)
                    end
                end
            end
        end)
        Notif("SIEXTHER VD", "Survivor ESP ON", 2)
    else
        ClearSurvivorESP()
        Notif("SIEXTHER VD", "Survivor ESP OFF", 2)
    end
end

-- KILLER ESP
local KillerESPActive = false

local function ClearKillerESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            if char then
                local hl = char:FindFirstChild("SVD_KillerHL")
                if hl then hl:Destroy() end
                local bb = char:FindFirstChild("SVD_KillerBB")
                if bb then bb:Destroy() end
            end
        end
    end
end

local function ApplyKillerESPToChar(char, player)
    if not char then return end
    if not char:FindFirstChild("SVD_KillerHL") then
        local hl = __SIEXTHER_VIP_GLASS_V1.Instance.new("Highlight")
        hl.Name = "SVD_KillerHL"
        hl.FillColor = Color3.fromRGB(220, 30, 30)
        hl.OutlineColor = Color3.fromRGB(255, 80, 80)
        hl.FillTransparency = 0.4
        hl.OutlineTransparency = 0
        hl.Adornee = char
        hl.Parent = char
    end

    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if rootPart and not char:FindFirstChild("SVD_KillerBB") then
        local bb = __SIEXTHER_VIP_GLASS_V1.Instance.new("BillboardGui")
        bb.Name = "SVD_KillerBB"
        bb.Size = UDim2.new(0, 90, 0, 34)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.AlwaysOnTop = true
        bb.Adornee = rootPart
        bb.Parent = char

        local nameLbl = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, 0, 0.55, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
        nameLbl.TextStrokeTransparency = 0
        nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLbl.TextSize = 11
        nameLbl.Text = player.Name
        nameLbl.Parent = bb

        local distLbl = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
        distLbl.Size = UDim2.new(1, 0, 0.45, 0)
        distLbl.Position = UDim2.new(0, 0, 0.55, 0)
        distLbl.BackgroundTransparency = 1
        distLbl.Font = Enum.Font.Gotham
        distLbl.TextColor3 = Color3.fromRGB(255, 180, 180)
        distLbl.TextStrokeTransparency = 0
        distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        distLbl.TextSize = 9
        distLbl.Text = "..."
        distLbl.Parent = bb

        table.insert(Connections, RunService.RenderStepped:Connect(function()
            if not KillerESPActive then return end
            local lc = LocalPlayer.Character
            local hrp = lc and lc:FindFirstChild("HumanoidRootPart")
            if hrp and rootPart and rootPart.Parent then
                local dist = math.floor((hrp.Position - rootPart.Position).Magnitude)
                distLbl.Text = dist .. " studs"
            end
        end))
    end
end

local function ToggleKillerESP(state)
    KillerESPActive = state
    if Connections.KillerESPLoop then
        pcall(function() Connections.KillerESPLoop:Disconnect() end)
        Connections.KillerESPLoop = nil
    end
    if state then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and IsKiller(p) and p.Character then
                ApplyKillerESPToChar(p.Character, p)
            end
        end
        Connections.KillerESPLoop = RunService.Heartbeat:Connect(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and IsKiller(p) and p.Character then
                    if not p.Character:FindFirstChild("SVD_KillerHL") then
                        ApplyKillerESPToChar(p.Character, p)
                    end
                end
            end
        end)
        Notif("SIEXTHER VD", "Killer ESP ON", 2)
    else
        ClearKillerESP()
        Notif("SIEXTHER VD", "Killer ESP OFF", 2)
    end
end

-- GENERATOR ESP
local GeneratorESPActive = false
local Highlights_Gen = {}
local BillboardGuis_Gen = {}

local function validateInstance(instance)
    return instance and typeof(instance) == "Instance" and instance.Parent ~= nil
end

local function isGeneratorComplete(obj)
    local val = obj:FindFirstChild("GeneratorValue") or obj:FindFirstChild("Progress") or obj:FindFirstChild("Repaired")
    if val then
        if val:IsA("BoolValue") and val.Value == true then return true end
        if (val:IsA("NumberValue") or val:IsA("IntValue")) and val.Value >= 100 then return true end
    end
    for _, child in ipairs(obj:GetChildren()) do
        local nm = child.Name:lower()
        if nm:find("complet") or nm:find("done") or nm:find("finish") then
            if child:IsA("BoolValue") and child.Value == true then return true end
        end
    end
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt")
    if prompt and not prompt.Enabled then return true end
    return false
end

local function createGeneratorHighlight(obj)
    if not validateInstance(obj) then return end
    if Highlights_Gen[obj] and validateInstance(Highlights_Gen[obj]) then return end
    if Highlights_Gen[obj] then Highlights_Gen[obj] = nil end
    local existingH = obj:FindFirstChild("SVD_GenHL2")
    if existingH then existingH:Destroy() end
    safeCall(function()
        local h = __SIEXTHER_VIP_GLASS_V1.Instance.new("Highlight")
        h.Name = "SVD_GenHL2"
        h.Adornee = obj
        h.FillColor = Color3.fromRGB(255, 255, 0)
        h.OutlineColor = Color3.fromRGB(255, 255, 0)
        h.FillTransparency = 0.5
        h.OutlineTransparency = 0
        h.Parent = obj
        Highlights_Gen[obj] = h
    end)
end

local function removeGeneratorHighlight(obj)
    if Highlights_Gen[obj] then
        safeCall(function()
            if validateInstance(Highlights_Gen[obj]) then
                Highlights_Gen[obj]:Destroy()
            end
        end)
        Highlights_Gen[obj] = nil
    end
    local existingH = obj:FindFirstChild("SVD_GenHL2")
    if existingH then pcall(function() existingH:Destroy() end) end
end

local function createGeneratorLabel(obj)
    if not validateInstance(obj) then return end
    local playerRoot = getCharacterRootPart()
    if not playerRoot then return end
    local rootPart = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart")
        or (obj:IsA("BasePart") and obj or nil)
    if not rootPart then return end
    local distance = (playerRoot.Position - rootPart.Position).Magnitude
    if BillboardGuis_Gen[obj] and validateInstance(BillboardGuis_Gen[obj]) then
        local textLabel = BillboardGuis_Gen[obj]:FindFirstChild("TextLabel")
        if textLabel then
            textLabel.Text = string.format("Gen\n%.0fm", distance)
        end
        return
    end
    BillboardGuis_Gen[obj] = nil
    safeCall(function()
        local billboard = __SIEXTHER_VIP_GLASS_V1.Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 80, 0, 30)
        billboard.AlwaysOnTop = true
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Adornee = rootPart
        billboard.Parent = obj

        local textLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        textLabel.TextStrokeTransparency = 0
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 10
        textLabel.Text = string.format("Gen\n%.0fm", distance)
        textLabel.Parent = billboard

        BillboardGuis_Gen[obj] = billboard
    end)
end

local function removeGeneratorLabel(obj)
    if BillboardGuis_Gen[obj] then
        safeCall(function()
            if validateInstance(BillboardGuis_Gen[obj]) then
                BillboardGuis_Gen[obj]:Destroy()
            end
        end)
        BillboardGuis_Gen[obj] = nil
    end
end

local function clearAllGeneratorESP()
    for obj, _ in pairs(Highlights_Gen) do removeGeneratorHighlight(obj) end
    for obj, _ in pairs(BillboardGuis_Gen) do removeGeneratorLabel(obj) end
    Highlights_Gen = {}
    BillboardGuis_Gen = {}
end

local function updateGeneratorESP()
    if not GeneratorESPActive then return end
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Generator" then
            if isGeneratorComplete(obj) then
                removeGeneratorHighlight(obj)
                removeGeneratorLabel(obj)
            else
                createGeneratorHighlight(obj)
                createGeneratorLabel(obj)
            end
        end
    end
end

local function ToggleGeneratorESP(state)
    GeneratorESPActive = state
    if Connections.GenESPLoop then
        pcall(function() Connections.GenESPLoop:Disconnect() end)
        Connections.GenESPLoop = nil
    end
    if state then
        Connections.GenESPLoop = RunService.Heartbeat:Connect(function()
            updateGeneratorESP()
        end)
        Notif("SIEXTHER VD", "Generator ESP ON", 3)
    else
        clearAllGeneratorESP()
        Notif("SIEXTHER VD", "Generator ESP OFF", 2)
    end
end

-- TELEPORT
local function TeleportToSurvivor()
    local lc = LocalPlayer.Character
    if not lc or not lc:FindFirstChild("HumanoidRootPart") then return end
    local tgt, md = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not IsKiller(p) and p.Character
            and p.Character:FindFirstChild("HumanoidRootPart") then
            local d = (lc.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if d < md then md = d; tgt = p end
        end
    end
    if tgt then
        lc.HumanoidRootPart.CFrame = tgt.Character.HumanoidRootPart.CFrame
        Notif("SIEXTHER VD", "Teleported to " .. tgt.Name, 2)
    else
        Notif("SIEXTHER VD", "No survivor found", 2)
    end
end

local function TeleportToKiller()
    local lc = LocalPlayer.Character
    if not lc or not lc:FindFirstChild("HumanoidRootPart") then return end
    local tgt, md = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsKiller(p) and p.Character
            and p.Character:FindFirstChild("HumanoidRootPart") then
            local d = (lc.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if d < md then md = d; tgt = p end
        end
    end
    if tgt then
        lc.HumanoidRootPart.CFrame = tgt.Character.HumanoidRootPart.CFrame
        Notif("SIEXTHER VD", "Teleported to Killer: " .. tgt.Name, 2)
    else
        Notif("SIEXTHER VD", "No killer found", 2)
    end
end

-- AUTO COMPLETE GENERATORS
local AutoGeneratorActive = false

task.spawn(function()
    while true do
        task.wait(0.2)
        if AutoGeneratorActive then
            safeCall(function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if not remotes then return end
                local genRemotes = remotes:FindFirstChild("Generator")
                if not genRemotes then return end
                local repairEvent = genRemotes:FindFirstChild("RepairEvent")
                local skillCheckEvent = genRemotes:FindFirstChild("SkillCheckResultEvent")
                if not repairEvent or not skillCheckEvent then return end
                local map = workspace:FindFirstChild("Map")
                if not map then return end
                for _, obj in ipairs(map:GetDescendants()) do
                    if obj:IsA("Model") and obj.Name == "Generator" then
                        for _, point in ipairs(obj:GetChildren()) do
                            if point.Name:find("GeneratorPoint") then
                                pcall(function()
                                    repairEvent:FireServer(point, true)
                                    skillCheckEvent:FireServer("success", 1, obj, point)
                                end)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- AUTO ATTACK
local AutoAttackActive = false
local AutoAttackRange = 10
local AutoAttackConnection = nil
local lastAttackTime = 0
local ATTACK_COOLDOWN = 0.3

local function findClosestSurvivor()
    if not isKiller() then return nil, nil end
    local hrp = getCharacterRootPart()
    if not hrp then return nil, nil end
    local closestPlayer = nil
    local closestDist = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team and player.Team.Name == "Survivors" and player.Character then
            local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local dist = (targetHRP.Position - hrp.Position).Magnitude
                if dist < closestDist and dist <= AutoAttackRange then
                    closestDist = dist
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer, closestDist
end

local function performAutoAttack()
    if not isKiller() then return end
    local target, _ = findClosestSurvivor()
    if not target then return end
    safeCall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local attacks = remotes:FindFirstChild("Attacks")
        if not attacks then return end
        local basicAttack = attacks:FindFirstChild("BasicAttack")
        if basicAttack then basicAttack:FireServer(false) end
    end)
end

local function startAutoAttack()
    if AutoAttackConnection then return end
    if not isKiller() then
        Notif("SIEXTHER VD", "Must be Killer!", 3)
        return
    end
    AutoAttackConnection = RunService.Heartbeat:Connect(function()
        if not AutoAttackActive then return end
        local now = tick()
        if now - lastAttackTime < ATTACK_COOLDOWN then return end
        lastAttackTime = now
        performAutoAttack()
    end)
    table.insert(Connections, AutoAttackConnection)
    Notif("SIEXTHER VD", "Auto Attack ON | Range: " .. AutoAttackRange, 3)
end

local function stopAutoAttack()
    if AutoAttackConnection then
        AutoAttackConnection:Disconnect()
        AutoAttackConnection = nil
    end
    Notif("SIEXTHER VD", "Auto Attack OFF", 2)
end

-- MAIN SCREEN GUI
local Root = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
Root.Name = "SiextherVD_GUI"
Root.DisplayOrder = 999
Root.ResetOnSpawn = false
Root.IgnoreGuiInset = true
Root.Parent = PlayerGui

local FULL_W    = 190
local FULL_H    = 360
local FULL_SIZE = UDim2.new(0, FULL_W, 0, FULL_H)

-- FLOATING SX BUTTON
local floatBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
floatBtn.Name = "FloatSX"
floatBtn.Size = UDim2.new(0, 41, 0, 41)
floatBtn.Position = UDim2.new(0, 18, 0.5, -18)
floatBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
floatBtn.Text = "SX"
floatBtn.Font = Enum.Font.GothamBold
floatBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
floatBtn.TextSize = 25
floatBtn.BorderSizePixel = 0
floatBtn.Visible = true
floatBtn.ZIndex = 200
floatBtn.Parent = Root
corner(floatBtn, 10)
makeDraggable(floatBtn, floatBtn)

-- Animasi teks ganti-ganti SX / VD
local floatTexts = {"SX", "VD"}
local floatTextIndex = 1

task.spawn(function()
    while floatBtn and floatBtn.Parent do
        task.wait(3)
        floatTextIndex = (floatTextIndex % #floatTexts) + 1
        -- Fade out
        TweenService:Create(floatBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 1
        }):Play()
        task.wait(0.35)
        -- Ganti teks
        floatBtn.Text = floatTexts[floatTextIndex]
        -- Fade in
        TweenService:Create(floatBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 0
        }):Play()
    end
end)

-- Gradient animasi
local MinimizedGradient = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient")
MinimizedGradient.Parent = floatBtn
MinimizedGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
MinimizedGradient.Offset = Vector2.new(-1, 0)

task.spawn(function()
    while floatBtn and floatBtn.Parent do
        TweenService:Create(MinimizedGradient, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(1, 0)
        }):Play()
        task.wait(2)
        TweenService:Create(MinimizedGradient, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(-1, 0)
        }):Play()
        task.wait(2)
    end
end)

-- MAIN FRAME
local Main = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
Main.Name = "Main"
Main.Size = FULL_SIZE
Main.Position = UDim2.new(0.5, -(FULL_W/2), 0.15, 0)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = Root
corner(Main, 10)
stroke(Main, C.stroke, 1.5)

local grad = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient")
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 38)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 18)),
})
grad.Rotation = 135
grad.Parent = Main

-- TITLE BAR
local TitleBar = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 28)
TitleBar.BackgroundColor3 = C.surface
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 10
TitleBar.Parent = Main
corner(TitleBar, 10)

local tbFix = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
tbFix.Size = UDim2.new(1, 0, 0, 12)
tbFix.Position = UDim2.new(0, 0, 1, -12)
tbFix.BackgroundColor3 = C.surface
tbFix.BorderSizePixel = 0
tbFix.ZIndex = 10
tbFix.Parent = TitleBar

local accentBar = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
accentBar.Size = UDim2.new(0, 3, 0.6, 0)
accentBar.Position = UDim2.new(0, 6, 0.2, 0)
accentBar.BackgroundColor3 = C.stroke
accentBar.BorderSizePixel = 0
accentBar.ZIndex = 12
accentBar.Parent = TitleBar
corner(accentBar, 2)

local titleLbl = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -90, 1, 0)
titleLbl.Position = UDim2.new(0, 14, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "SIEXTHER VD"
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextColor3 = Color3.fromRGB(70, 130, 255)
titleLbl.TextSize = 12
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.ZIndex = 12
titleLbl.Parent = TitleBar

local minBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 20, 0, 16)
minBtn.Position = UDim2.new(1, -44, 0.5, -8)
minBtn.BackgroundColor3 = C.minClr
minBtn.BorderSizePixel = 0
minBtn.Text = "–"
minBtn.Font = Enum.Font.GothamBold
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.TextSize = 9
minBtn.ZIndex = 13
minBtn.Parent = TitleBar
corner(minBtn, 4)

minBtn.MouseEnter:Connect(function() tween(minBtn, {BackgroundColor3 = C.minHov}) end)
minBtn.MouseLeave:Connect(function() tween(minBtn, {BackgroundColor3 = C.minClr}) end)

local closeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 20, 0, 16)
closeBtn.Position = UDim2.new(1, -22, 0.5, -8)
closeBtn.BackgroundColor3 = C.red
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 9
closeBtn.ZIndex = 13
closeBtn.Parent = TitleBar
corner(closeBtn, 4)

closeBtn.MouseEnter:Connect(function() tween(closeBtn, {BackgroundColor3 = C.redHov}) end)
closeBtn.MouseLeave:Connect(function() tween(closeBtn, {BackgroundColor3 = C.red}) end)

closeBtn.MouseButton1Click:Connect(function()
    ToggleCrosshair(false)
    ToggleNoclip(false)
    ToggleSurvivorESP(false)
    ToggleKillerESP(false)
    ToggleGeneratorESP(false)
    AutoGeneratorActive = false
    AutoAttackActive = false
    stopAutoAttack()
    for k, v in pairs(Connections) do
        pcall(function()
            if typeof(v) == "RBXScriptConnection" then v:Disconnect() end
        end)
        Connections[k] = nil
    end
    _G.SiextherVD = nil
    Root:Destroy()
end)

minBtn.MouseButton1Click:Connect(function()
    tween(Main, {Size = UDim2.new(0, FULL_W, 0, 0)})
    task.wait(0.18)
    Main.Visible = false
    floatBtn.Visible = true
end)

floatBtn.MouseButton1Click:Connect(function()
    floatBtn.Visible = false
    Main.Visible = true
    Main.Size = UDim2.new(0, FULL_W, 0, 0)
    tween(Main, {Size = FULL_SIZE})
end)

-- DRAG
makeDraggable(Main, TitleBar)

-- SCROLL CONTENT
local Scroll = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -8, 1, -34)
Scroll.Position = UDim2.new(0, 4, 0, 30)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = C.stroke
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.ClipsDescendants = true
Scroll.Parent = Main

local Layout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 3)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Scroll

local Pad = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
Pad.PaddingBottom = UDim.new(0, 4)
Pad.PaddingTop = UDim.new(0, 2)
Pad.Parent = Scroll

Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 8)
end)

local order = 0
local function nextO() order = order + 1; return order end

-- DIVIDER
local function Divider(txt)
    local f = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
    f.LayoutOrder = nextO()
    f.Size = UDim2.new(1, 0, 0, 18)
    f.BackgroundTransparency = 1
    f.Parent = Scroll

    local line1 = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
    line1.Size = UDim2.new(0.5, -45, 0, 1)
    line1.Position = UDim2.new(0, 0, 0.5, 0)
    line1.BackgroundColor3 = Color3.fromRGB(40, 50, 72)
    line1.BorderSizePixel = 0
    line1.Parent = f

    local lbl = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 84, 1, 0)
    lbl.Position = UDim2.new(0.5, -42, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.Font = Enum.Font.GothamBold
    lbl.TextColor3 = C.stroke
    lbl.TextSize = 8
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.Parent = f

    local line2 = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
    line2.Size = UDim2.new(0.5, -45, 0, 1)
    line2.Position = UDim2.new(0.5, 45, 0.5, 0)
    line2.BackgroundColor3 = Color3.fromRGB(40, 50, 72)
    line2.BorderSizePixel = 0
    line2.Parent = f
end

-- TOGGLE
local function Toggle(txt, default, cb)
    local f = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
    f.LayoutOrder = nextO()
    f.Size = UDim2.new(1, 0, 0, 26)
    f.BackgroundColor3 = C.card
    f.BorderSizePixel = 0
    f.Parent = Scroll
    corner(f, 6)
    stroke(f, Color3.fromRGB(35, 35, 55), 1)

    local lbl = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -52, 1, 0)
    lbl.Position = UDim2.new(0, 7, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.Font = Enum.Font.GothamBold
    lbl.TextColor3 = C.text
    lbl.TextSize = 8
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f

    local pill = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    pill.Size = UDim2.new(0, 36, 0, 16)
    pill.Position = UDim2.new(1, -42, 0.5, -8)
    pill.BackgroundColor3 = default and C.onClr or C.offClr
    pill.BorderSizePixel = 0
    pill.Text = default and "ON" or "OFF"
    pill.Font = Enum.Font.GothamBold
    pill.TextColor3 = Color3.fromRGB(255, 255, 255)
    pill.TextSize = 7
    pill.ZIndex = 5
    pill.Parent = f
    corner(pill, 4)

    local state = default
    pill.MouseButton1Click:Connect(function()
        state = not state
        pill.Text = state and "ON" or "OFF"
        tween(pill, {BackgroundColor3 = state and C.onClr or C.offClr})
        cb(state)
    end)

    return f
end

-- SLIDER
local function Slider(txt, min, max, default, cb)
    local f = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
    f.LayoutOrder = nextO()
    f.Size = UDim2.new(1, 0, 0, 40)
    f.BackgroundColor3 = C.card
    f.BorderSizePixel = 0
    f.Parent = Scroll
    corner(f, 6)
    stroke(f, Color3.fromRGB(35, 35, 55), 1)

    local lbl = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 0, 16)
    lbl.Position = UDim2.new(0, 7, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextColor3 = C.text
    lbl.TextSize = 8
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = txt .. ": " .. default
    lbl.Parent = f

    local track = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
    track.Size = UDim2.new(1, -14, 0, 5)
    track.Position = UDim2.new(0, 7, 0, 26)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    track.BorderSizePixel = 0
    track.Parent = f
    corner(track, 3)

    local fill = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = C.stroke
    fill.BorderSizePixel = 0
    fill.Parent = track
    corner(fill, 3)

    local knob = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0)
    knob.BackgroundColor3 = C.accent
    knob.BorderSizePixel = 0
    knob.Text = ""
    knob.ZIndex = 5
    knob.Parent = track
    corner(knob, 6)

    local dragging = false
    knob.MouseButton1Down:Connect(function() dragging = true end)
    table.insert(Connections, UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end))
    table.insert(Connections, UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            local trackAbs = track.AbsolutePosition
            local trackSize = track.AbsoluteSize
            local rel = math.clamp((i.Position.X - trackAbs.X) / trackSize.X, 0, 1)
            local val = math.floor(min + (max - min) * rel)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, 0, 0.5, 0)
            lbl.Text = txt .. ": " .. val
            cb(val)
        end
    end))
end

-- BUTTON
local function Button(txt, cb)
    local btn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    btn.LayoutOrder = nextO()
    btn.Size = UDim2.new(1, 0, 0, 26)
    btn.BackgroundColor3 = C.card
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.ZIndex = 2
    btn.Parent = Scroll
    corner(btn, 6)
    stroke(btn, Color3.fromRGB(35, 35, 55), 1)

    local arw = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
    arw.Size = UDim2.new(0, 12, 1, 0)
    arw.Position = UDim2.new(0, 7, 0, 0)
    arw.BackgroundTransparency = 1
    arw.Text = "›"
    arw.Font = Enum.Font.GothamBold
    arw.TextColor3 = C.stroke
    arw.TextSize = 13
    arw.TextXAlignment = Enum.TextXAlignment.Left
    arw.ZIndex = 3
    arw.Parent = btn

    local lbl2 = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
    lbl2.Size = UDim2.new(1, -22, 1, 0)
    lbl2.Position = UDim2.new(0, 20, 0, 0)
    lbl2.BackgroundTransparency = 1
    lbl2.Text = txt
    lbl2.Font = Enum.Font.GothamBold
    lbl2.TextColor3 = C.text
    lbl2.TextSize = 8
    lbl2.TextXAlignment = Enum.TextXAlignment.Left
    lbl2.ZIndex = 3
    lbl2.Parent = btn

    btn.MouseEnter:Connect(function()
        tween(btn, {BackgroundColor3 = Color3.fromRGB(32, 32, 50)})
        tween(arw, {TextColor3 = C.accent})
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, {BackgroundColor3 = C.card})
        tween(arw, {TextColor3 = C.stroke})
    end)
    btn.MouseButton1Click:Connect(function()
        tween(btn, {BackgroundColor3 = Color3.fromRGB(40, 60, 100)})
        task.wait(0.12)
        tween(btn, {BackgroundColor3 = C.card})
        task.spawn(cb)
    end)
end

-- BUILD UI
Divider("S I E X T H E R")
Toggle("Auto Complete Generators", false, function(v)
    AutoGeneratorActive = v
    Notif("SIEXTHER VD", "Auto Generator " .. (v and "ON" or "OFF"), 2)
end)
Toggle("Crosshair Center", false, function(v)
    ToggleCrosshair(v)
    Notif("SIEXTHER VD", "Crosshair " .. (v and "ON" or "OFF"), 2)
end)
Toggle("Noclip", false, function(v)
    ToggleNoclip(v)
end)

Divider("TELEPORT")
Button("Teleport to Survivors", TeleportToSurvivor)
Button("Teleport to Killer", TeleportToKiller)

Divider("ESP")
Toggle("Survivor ESP", false, function(v)
    ToggleSurvivorESP(v)
end)
Toggle("Killer ESP", false, function(v)
    ToggleKillerESP(v)
end)
Toggle("Generator ESP", false, function(v)
    ToggleGeneratorESP(v)
end)

Divider("KILLER ONLY")
Toggle("Auto Attack Survivors", false, function(v)
    AutoAttackActive = v
    if v then
        startAutoAttack()
    else
        stopAutoAttack()
    end
end)
Slider("Attack Range", 5, 20, 10, function(v)
    AutoAttackRange = v
end)
Button("Activate Killer Power", function()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then Notif("SIEXTHER VD", "Remotes not found", 2) return end
    local killerRemotes = remotes:FindFirstChild("Killers")
    if not killerRemotes then Notif("SIEXTHER VD", "Killers remote not found", 2) return end
    local killerFolder = killerRemotes:FindFirstChild("Killer")
    if not killerFolder then Notif("SIEXTHER VD", "Killer folder not found", 2) return end
    local activatePower = killerFolder:FindFirstChild("ActivatePower")
    if activatePower then
        activatePower:FireServer()
        Notif("SIEXTHER VD", "Killer power triggered", 2)
    else
        Notif("SIEXTHER VD", "ActivatePower not found", 2)
    end
end)
Button("Basic Attack", function()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then Notif("SIEXTHER VD", "Remotes not found", 2) return end
    local attacks = remotes:FindFirstChild("Attacks")
    if not attacks then Notif("SIEXTHER VD", "Attacks remote not found", 2) return end
    local basicAttack = attacks:FindFirstChild("BasicAttack")
    if basicAttack then
        basicAttack:FireServer(false)
        Notif("SIEXTHER VD", "Basic attack executed", 2)
    else
        Notif("SIEXTHER VD", "BasicAttack not found", 2)
    end
end)

-- startup notify
Notif("SIEXTHER VD", "HANN.SIEXTHER", 3)