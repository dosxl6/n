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


local SX = {
    Alive = true,
    Connections = {},
    Instances = {},
    Threads = {},
    Tweens = {},
    Cleanups = {},
    Characters = setmetatable({}, { __mode = "k" }),
    Minimized = false,
}
local nativeTask = task
local environment = (type(getgenv) == "function" and getgenv()) or _G
local previous = environment.__SIEXTHER_ANIMATION_WINDOW
if type(previous) == "table" and type(previous.Close) == "function" then
    pcall(previous.Close)
end
environment.__SIEXTHER_ANIMATION_WINDOW = SX

-- Own only this window's scheduled work, so X also stops pending requests.
local task = {}
local function schedule(kind, delaySeconds, callback, ...)
    if not SX.Alive then return nil end
    local args = table.pack(...)
    local thread = coroutine.create(function()
        if SX.Alive then
            local ok, message = pcall(callback, table.unpack(args, 1, args.n))
            if not ok and SX.Alive then warn("[SIEXTHER Animation] " .. tostring(message)) end
        end
        SX.Threads[coroutine.running()] = nil
    end)
    SX.Threads[thread] = true
    if kind == "delay" then nativeTask.delay(delaySeconds, thread)
    elseif kind == "defer" then nativeTask.defer(thread)
    else nativeTask.spawn(thread) end
    return thread
end
function task.spawn(callback, ...) return schedule("spawn", nil, callback, ...) end
function task.defer(callback, ...) return schedule("defer", nil, callback, ...) end
function task.delay(seconds, callback, ...) return schedule("delay", seconds, callback, ...) end
task.wait = nativeTask.wait
task.cancel = nativeTask.cancel

local function _eA(name)
    local ok, service = pcall(function() return game:GetService(name) end)
    return ok and service or nil
end
local _eE, _eF, _eG = _eA("TweenService"), _eA("UserInputService"), _eA("Players")
local _eI = _eA("ContentProvider")
local _cu, _cv, _cw = Enum.AutomaticSize.Y, Enum.AutomaticSize.X, Enum.ScrollBarInset.Always
local _cx = Enum.AssetFetchStatus.Failure
local function _ex() return SX.Alive end
local function _ey(connection)
    if connection then SX.Connections[#SX.Connections + 1] = connection end
    return connection
end
local function _jq(callback, ...)
    if not SX.Alive or type(callback) ~= "function" then return end
    local ok, message = pcall(callback, ...)
    if not ok then warn("[SIEXTHER Animation] " .. tostring(message)) end
end
local function _jx(signal, callback)
    if not SX.Alive or not signal or type(callback) ~= "function" then return nil end
    local ok, connection = pcall(function()
        return signal:Connect(function(...) return _jq(callback, ...) end)
    end)
    return ok and _ey(connection) or nil
end
local function _jJ(object, member)
    if not object then return nil end
    local ok, signal = pcall(function() return object[member] end)
    return ok and signal or nil
end
local function _jO(object, property, value)
    if object then pcall(function() object[property] = value end) end
end
local function _jS()
    pcall(function()
        if type(setthreadidentity) == "function" then setthreadidentity(7)
        elseif type(set_thread_identity) == "function" then set_thread_identity(7)
        elseif type(syn) == "table" and type(syn.set_thread_identity) == "function" then
            syn.set_thread_identity(7)
        end
    end)
end
local function _qc() end

-- Neutral interior. The exact requested blue is used on the outer border only.
local _kA = {
    Background = Color3.fromRGB(20, 20, 30),
    Glass = Color3.fromRGB(27, 28, 39),
    GlassLight = Color3.fromRGB(32, 33, 45),
    GlassSurface = Color3.fromRGB(26, 27, 38),
    Element = Color3.fromRGB(27, 28, 39),
    ElementHover = Color3.fromRGB(43, 45, 58),
    ElementActive = Color3.fromRGB(49, 51, 65),
    Border = Color3.fromRGB(59, 61, 75),
    Stroke = Color3.fromRGB(92, 94, 108),
    Accent = Color3.fromRGB(220, 223, 233),
    Text = Color3.fromRGB(241, 242, 247),
    SubText = Color3.fromRGB(182, 185, 199),
    TextMuted = Color3.fromRGB(133, 137, 154),
    Success = Color3.fromRGB(86, 204, 147),
    Danger = Color3.fromRGB(241, 111, 126),
    Home = {
        Edge = Color3.fromRGB(97, 100, 117),
        Tile = Color3.fromRGB(32, 33, 46),
        Muted = Color3.fromRGB(136, 140, 157),
        EdgeRest = 0.8, EdgeHover = 0.35, EdgeActive = 0.2,
    },
    Typo = {
        Display = Enum.Font.GothamBlack, Bold = Enum.Font.GothamBold,
        Medium = Enum.Font.GothamMedium, Body = Enum.Font.Gotham,
        SM = 10, MD = 11, LG = 12, XL = 13,
    },
    Metric = { R_SM = 6, R_MD = 8 },
    SubTab = {
        Gap = 8, TextSize = 12, PadX = 19,
        FontOn = Enum.Font.GothamBold, FontOff = Enum.Font.GothamMedium,
    },
}
local _kF = {
    ARROW_L = "<", ARROW_R = ">", MIDDOT = "·", CHECK = "✓",
    WARNING = "⚠", STAR4 = "★", RELOAD = "§", MINUS_FW = "–", PLUS_FW = "+",
}
local function _qz(class, properties, children)
    local object = __SIEXTHER_VIP_GLASS_V1.Instance.new(class)
    SX.Instances[#SX.Instances + 1] = object
    if object:IsA("GuiObject") then object.BorderSizePixel = 0 end
    if object:IsA("TextLabel") or object:IsA("TextBox") or object:IsA("TextButton") then
        object.RichText = false
    end
    if object:IsA("ScrollingFrame") then
        object.VerticalScrollBarInset = Enum.ScrollBarInset.Always
    end
    for key, value in pairs(properties or {}) do
        if key ~= "Parent" then object[key] = value end
    end
    -- Keep stroke objects for the original hover callbacks, but render no interior outlines.
    if class == "UIStroke" then object.Enabled = false end
    if children then
        for _, child in ipairs(children) do child.Parent = object end
    end
    if properties and properties.Parent then object.Parent = properties.Parent end
    if class == "TextLabel" and properties and properties.Text == "Search a bundle or pick a state to begin." then
        SX.Status = object
    end
    return object
end
local function _ry(object, seconds, style, direction, properties)
    if not SX.Alive or not object then return nil end
    local ok, tween = pcall(function()
        return _eE:Create(object,
            TweenInfo.new(seconds or 0.18, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
            properties)
    end)
    if ok then
        SX.Tweens[tween] = true
        tween:Play()
        _jx(tween.Completed, function() SX.Tweens[tween] = nil end)
        return tween
    end
    for key, value in pairs(properties) do pcall(function() object[key] = value end) end
    return nil
end
local function _sf(object, radius)
    _qz("UICorner", {CornerRadius = radius >= 50 and UDim.new(1, 0) or UDim.new(0, radius), Parent = object})
    return object
end
local function _so(object, color, thickness, transparency)
    return _qz("UIStroke", {
        Color = color or _kA.Stroke, Thickness = thickness or 1, Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = object,
    })
end
local _sv = {}
function _sv.Stroke(object, color, thickness, transparency)
    return _so(object, color, thickness, transparency)
end
local function _vy(object, left, right, top, bottom)
    return _qz("UIPadding", {
        PaddingLeft = UDim.new(0, left or 8), PaddingRight = UDim.new(0, right or 8),
        PaddingTop = UDim.new(0, top or 8), PaddingBottom = UDim.new(0, bottom or 8), Parent = object,
    })
end
local function setStatus(message, failed)
    if not SX.Status or not SX.Status.Parent then return end
    SX.Status.Text = tostring(message or "Ready.")
    SX.Status.TextColor3 = failed and _kA.Danger or _kA.SubText
    for _, child in ipairs(SX.Status.Parent:GetChildren()) do
        if child:IsA("Frame") then child.BackgroundColor3 = failed and _kA.Danger or _kA.Success end
    end
end

local function snapshotCharacter(character)
    if not character or SX.Characters[character] then return end
    local animate = character:FindFirstChild("Animate")
    if animate then
        SX.Characters[character] = { Animate = animate, Disabled = animate.Disabled }
    end
end
local function onShutdown(callback) SX.Cleanups[#SX.Cleanups + 1] = callback end

function SX.Close()
    if not SX.Alive then return end
    SX.Alive = false
    for thread in pairs(SX.Threads) do
        if thread ~= coroutine.running() then pcall(nativeTask.cancel, thread) end
    end
    table.clear(SX.Threads)
    for _, callback in ipairs(SX.Cleanups) do pcall(callback) end
    if SX.Flush then pcall(SX.Flush) end
    for _, connection in ipairs(SX.Connections) do pcall(function() connection:Disconnect() end) end
    for tween in pairs(SX.Tweens) do pcall(function() tween:Cancel() end) end
    for character, snapshot in pairs(SX.Characters) do
        if character.Parent and snapshot.Animate.Parent then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
            if animator and snapshot.Animate.Disabled ~= snapshot.Disabled then
                pcall(function()
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop(0.15) end
                end)
            end
            pcall(function() snapshot.Animate.Disabled = snapshot.Disabled end)
        end
    end
    for index = #SX.Instances, 1, -1 do pcall(function() SX.Instances[index]:Destroy() end) end
    table.clear(SX.Instances)
    table.clear(SX.Connections)
    table.clear(SX.Tweens)
    table.clear(SX.Cleanups)
    if environment.__SIEXTHER_ANIMATION_WINDOW == SX then environment.__SIEXTHER_ANIMATION_WINDOW = nil end
end

_jS()
local player = _eG.LocalPlayer
if not player then
    SX.Close()
    error("SIEXTHER Animation must run on the local client.")
end
snapshotCharacter(player.Character)
if player.Character then
    local initialCharacter = player.Character
    task.spawn(function()
        initialCharacter:WaitForChild("Animate", 10)
        snapshotCharacter(initialCharacter)
    end)
end
_jx(player.CharacterAdded, function(character)
    task.spawn(function()
        character:WaitForChild("Humanoid", 10)
        character:WaitForChild("Animate", 10)
        snapshotCharacter(character)
    end)
end)

local screen = _qz("ScreenGui", {
    Name = "SIEXTHER_Animation", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 650,
    IgnoreGuiInset = false,
})
SX.Gui = screen
local parented = false
if type(gethui) == "function" then
    parented = pcall(function() screen.Parent = gethui() end) and screen.Parent ~= nil
end
if not parented then
    parented = pcall(function() screen.Parent = game:GetService("CoreGui") end) and screen.Parent ~= nil
end
if not parented then screen.Parent = player:WaitForChild("PlayerGui", 10) end
if not screen.Parent then SX.Close(); error("No GUI container is available.") end

local root = _qz("Frame", {
    Name = "Window", AnchorPoint = Vector2.new(0, 0), Size = UDim2.fromOffset(640, 610),
    Position = UDim2.fromOffset(20, 20), BackgroundColor3 = _kA.Background,
    ClipsDescendants = true, Active = true, Parent = screen,
})
SX.Root = root
_sf(root, 16)
-- The only visible UIStroke in this interface.
local outerStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
outerStroke.Name = "SkyBlueOuterStroke"
outerStroke.Color = Color3.fromRGB(70, 130, 255)
outerStroke.Thickness = 1.5
outerStroke.Transparency = 0
outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
outerStroke.Parent = root
local top = _qz("Frame", {
    Name = "TitleBar", Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1, Parent = root,
})
local dragHandle = _qz("Frame", {
    Name = "DragHandle", Size = UDim2.new(1, -100, 1, 0), BackgroundTransparency = 1,
    Active = true, Parent = top,
})
local mark = _qz("Frame", {
    Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(16, 14),
    BackgroundColor3 = _kA.ElementActive, Parent = dragHandle,
})
_sf(mark, 10)
_qz("TextLabel", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "SX",
    Font = Enum.Font.GothamBold, TextSize = 17, TextColor3 = _kA.Text, Parent = mark,
})
_qz("TextLabel", {
    Position = UDim2.fromOffset(56, 13), Size = UDim2.new(1, -62, 0, 17), BackgroundTransparency = 1,
    Text = "SIEXTHER ANIMATED", Font = Enum.Font.GothamBold, TextSize = 14,
    TextColor3 = _kA.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = dragHandle,
})
_qz("TextLabel", {
    Position = UDim2.fromOffset(56, 32), Size = UDim2.new(1, -62, 0, 12), BackgroundTransparency = 1,
    Text = "すべてのアニメーションを無料でお楽しみください", Font = Enum.Font.GothamMedium, TextSize = 10,
    TextColor3 = _kA.TextMuted, TextXAlignment = Enum.TextXAlignment.Left, Parent = dragHandle,
})
_qz("Frame", {
    Size = UDim2.new(1, -32, 0, 1), Position = UDim2.fromOffset(16, 57),
    BackgroundColor3 = _kA.Border, BackgroundTransparency = 0.55, Parent = top,
})
local function chromeButton(name, text, offset)
    local button = _qz("TextButton", {
        Name = name, Text = text, Font = Enum.Font.GothamMedium, TextSize = 19,
        TextColor3 = _kA.SubText, BackgroundColor3 = _kA.Element,
        Position = UDim2.new(1, offset, 0, 12), Size = UDim2.fromOffset(34, 34),
        AutoButtonColor = false, Parent = top,
    })
    _sf(button, 10)
    _jx(button.MouseEnter, function()
        _ry(button, 0.15, nil, nil, {BackgroundColor3 = _kA.ElementHover, TextColor3 = _kA.Text})
    end)
    _jx(button.MouseLeave, function()
        _ry(button, 0.15, nil, nil, {BackgroundColor3 = _kA.Element, TextColor3 = _kA.SubText})
    end)
    return button
end
local minimize = chromeButton("Minimize", "−", -88)
local close = chromeButton("Close", "×", -48)
local floating = _qz("TextButton", {
    Name = "FlowerRestore", Text = "🌸", TextSize = 20, Font = Enum.Font.Gotham,
    TextColor3 = _kA.Text, Size = UDim2.fromOffset(41, 41), Position = UDim2.new(1, -65, 0, 15),
    BackgroundColor3 = _kA.Background, AutoButtonColor = false, Visible = false, Active = true, Parent = screen,
})
_sf(floating, 12)
SX.Floating = floating


local page = _qz("ScrollingFrame", {
    Name = "AnimationPage", Position = UDim2.fromOffset(14, 70), Size = UDim2.new(1, -28, 1, -84),
    BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
    ScrollBarThickness = 3, ScrollBarImageColor3 = _kA.Home.Muted,
    ScrollBarImageTransparency = 0.5, ClipsDescendants = true, Parent = root,
})
_vy(page, 0, 5, 0, 4)
_qz("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Parent = page})
local _NK, _LM = {}, {}
_LM.Animation = {Page = page}
function _LM.Animation:CreateSection()
    local section = _qz("Frame", {
        Name = "AnimationSection", Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = self.Page,
    })
    local body = _qz("Frame", {
        Name = "AnimationBody", Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = section,
    })
    _qz("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = body})
    _vy(body, 0, 0, 1, 1)
    return {Frame = section, Body = body, Accent = _kA.Accent}
end

local function viewportSize()
    if screen.AbsoluteSize.X > 0 and screen.AbsoluteSize.Y > 0 then return screen.AbsoluteSize end
    local camera = workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(800, 600)
end
local function clampPosition(object, x, y)
    local viewport = viewportSize()
    local size = object.AbsoluteSize
    return UDim2.fromOffset(
        math.clamp(x, 8, math.max(8, viewport.X - size.X - 8)),
        math.clamp(y, 8, math.max(8, viewport.Y - size.Y - 8)))
end
local firstFit = true
local function fitWindow()
    local viewport = viewportSize()
    local width, height = math.min(640, viewport.X - 24), math.min(640, viewport.Y - 24)
    root.Size = UDim2.fromOffset(math.max(240, width), math.max(180, height))
    if firstFit then
        firstFit = false
        root.Position = UDim2.fromOffset(math.max(8, (viewport.X - width) / 2), math.max(8, (viewport.Y - height) / 2))
    else
        root.Position = clampPosition(root, root.Position.X.Offset, root.Position.Y.Offset)
    end
    floating.Position = clampPosition(floating, floating.Position.X.Offset, floating.Position.Y.Offset)
end
local drag = nil
local flowerDraggedUntil = 0
local function makeDraggable(handle, target)
    _jx(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            drag = {Input = input, Target = target, Start = input.Position, Position = target.Position, Moved = false}
        end
    end)
end
makeDraggable(dragHandle, root)
makeDraggable(floating, floating)
_jx(_eF.InputChanged, function(input)
    if not drag then return end
    local matching = drag.Input.UserInputType == Enum.UserInputType.Touch and input == drag.Input
    if not matching and not (drag.Input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then return end
    local delta = input.Position - drag.Start
    if delta.Magnitude > 6 then drag.Moved = true end
    if drag.Moved then
        drag.Target.Position = clampPosition(drag.Target, drag.Position.X.Offset + delta.X, drag.Position.Y.Offset + delta.Y)
        if drag.Target == floating then flowerDraggedUntil = os.clock() + 0.3 end
    end
end)
_jx(_eF.InputEnded, function(input)
    if drag and (input == drag.Input or input.UserInputType == Enum.UserInputType.MouseButton1) then
        if drag.Moved and drag.Target == floating then flowerDraggedUntil = os.clock() + 0.3 end
        drag = nil
    end
end)
_jx(minimize.Activated, function()
    SX.Minimized = true
    root.Visible = false
    floating.Visible = true
    floating.Position = UDim2.new(1, -65, 0, 15)
end)
_jx(floating.Activated, function()
    if os.clock() < flowerDraggedUntil then return end
    SX.Minimized = false
    floating.Visible = false
    root.Visible = true
    fitWindow()
end)
_jx(close.Activated, SX.Close)
_jx(screen:GetPropertyChangedSignal("AbsoluteSize"), fitWindow)
_jx(screen.Destroying, SX.Close)
fitWindow()


-- Original config/cache persistence, including legacy config migration.

local _gV = _eG and _eG.LocalPlayer
local _gW = _eA("HttpService")
local _gX = "SIEXTHER"
local _gY = _gX .. "/data.json"
local _gZ = _gX .. "/data"
local _ha = 1024 * 1024
local _hb = (typeof(writefile) == "function") and (typeof(readfile) == "function")
local _hc = { _meta = { version = 1 } }
local _hd = false
local function _he()
    pcall(function()
        if typeof(makefolder) == "function" and typeof(isfolder) == "function" then
            if not isfolder(_gX) then
                makefolder(_gX)
            end
            if not isfolder(_gZ) then
                makefolder(_gZ)
            end
        end
    end)
end
local _hf = {}
local _hg = {}
local _hh = nil
local _hi = {}
local _hj = {}
local function _hk(_hl, _hm)
    if _hl.all then
        _hl.cache, _hl.all = {}, false
    end
    local _hn, _ho, _hp = _hl.cache, {}, 0
    for _hq, _hr in pairs(_hm) do
        if type(_hq) ~= "string" then
            return nil
        end
        local _hs = _hn[_hq]
        if not _hs then
            _hs = _gW:JSONEncode(_hq) .. ":" .. _gW:JSONEncode(_hr)
            _hn[_hq] = _hs
        end
        _hp = _hp + 1
        _ho[_hp] = _hs
    end
    for _ht in pairs(_hn) do
        if _hm[_ht] == nil then
            _hn[_ht] = nil
        end
    end
    if _hp == 0 then
        return "[]"
    end
    return "{" .. table.concat(_ho, ",") .. "}"
end
local function _hu(_hv)
    return (
        tostring(_hv):gsub("[^%w%-]", function(_hw)
            return string.format("_%02X", string.byte(_hw))
        end)
    )
end
local function _hx(_hy, _hz)
    return string.format("%s/%s.part%04d", _gZ, _hu(_hy), _hz)
end
local function _hA(_hB)
    local _hC, _hD, _hE, _hF = {}, 0, 1, #_hB
    while _hE <= _hF do
        local _hG = math.min(_hE + _ha - 1, _hF)
        if _hG < _hF then
            local _hH = 0
            while _hG > _hE and _hH < 4 do
                local _hI = string.byte(_hB, _hG + 1)
                if _hI and _hI >= 0x80 and _hI < 0xc0 then
                    _hG = _hG - 1
                    _hH = _hH + 1
                else
                    break
                end
            end
        end
        _hD = _hD + 1
        _hC[_hD] = string.sub(_hB, _hE, _hG)
        _hE = _hG + 1
    end
    if _hD == 0 then
        _hC[1] = ""
    end
    return _hC
end
local function _hJ(_hK)
    if typeof(delfile) ~= "function" or typeof(isfile) ~= "function" then
        return
    end
    pcall(function()
        if isfile(_hK) then
            delfile(_hK)
        end
    end)
end
local function _hL(_hM, _hN)
    local _hO = type(_hN) == "table" and tonumber(_hN.parts) or 0
    if _hO < 1 then
        return false, "no parts listed"
    end
    local _hP = {}
    for _hQ = 1, _hO do
        local _hR = _hx(_hM, _hQ)
        if typeof(isfile) == "function" and not isfile(_hR) then
            return false, "missing " .. _hR
        end
        local _hS, _hT = pcall(readfile, _hR)
        if not _hS or type(_hT) ~= "string" then
            return false, "cannot read " .. _hR
        end
        _hP[_hQ] = _hT
    end
    local _hU = table.concat(_hP)
    local _hV = tonumber(_hN.bytes)
    if _hV and #_hU ~= _hV then
        return false, "size mismatch"
    end
    local _hW, _hX = pcall(function()
        return _gW:JSONDecode(_hU)
    end)
    if not _hW then
        return false, "decode failed"
    end
    return true, _hX, _hU, _hO
end
local _hY = {
    { key = "encounters", path = "SIEXTHER_Universal/encounters.json" },
    { key = "playerNotes", path = "SIEXTHER_Universal/player_notes.json" },
    { key = "playerHistory", path = "SIEXTHER_Universal/player_history.json" },
    { key = "animationsConfig", path = "SIEXTHER_Animations/config.json" },
    { key = "animationsCache", path = "SIEXTHER_Animations/anims_cache.json" },
    { key = "visualConfig", path = "SIEXTHER_Visual/config.json" },
}
local function _hZ()
    if _hd then
        return
    end
    _hd = true
    if not _hb or not _gW then
        return
    end
    if typeof(isfile) == "function" and isfile(_gY) then
        local _ia, _ib = pcall(function()
            return readfile(_gY)
        end)
        if _ia and type(_ib) == "string" then
            local _ic, _id = pcall(function()
                return _gW:JSONDecode(_ib)
            end)
            if _ic and type(_id) == "table" then
                if type(_id._meta) == "table" and _id._meta.chunked == true then
                    _hc = { _meta = { version = 2 } }
                    _hh = _ib
                    if type(_id.sections) == "table" then
                        for _ie, _if in pairs(_id.sections) do
                            local _ig, _ih, _ii, _ij = _hL(_ie, _if)
                            if _ig then
                                _hc[_ie] = _ih
                                _hf[_ie] = { encoded = _ii, parts = _ij }
                            else
                                _hg[_ie] = _if
                                warn(
                                    "[SIEXTHER] data section '"
                                        .. tostring(_ie)
                                        .. "' unreadable ("
                                        .. tostring(_ih)
                                        .. "), left untouched on disk"
                                )
                            end
                        end
                    end
                    return
                end
                _hc = _id
                _hc._meta = _hc._meta or { version = 1 }
                return
            else
                warn("[SIEXTHER] data.json corrupt, backed up and reset:", _id)
                pcall(function()
                    writefile(_gY .. ".corrupt", _ib)
                end)
            end
        else
            warn("[SIEXTHER] Failed to read data.json:", _ib)
        end
    end
    local _ik = false
    for _il, _im in ipairs(_hY) do
        if not _ex() then
            break
        end
        if typeof(isfile) == "function" and isfile(_im.path) then
            local _in, _io = pcall(function()
                return readfile(_im.path)
            end)
            if _in and type(_io) == "string" then
                local _ip, _iq = pcall(function()
                    return _gW:JSONDecode(_io)
                end)
                if _ip and type(_iq) == "table" then
                    _hc[_im.key] = _iq
                    _ik = true
                end
            end
        end
    end
    if _ik then
        warn("[SIEXTHER] Migrated legacy per-feature JSON files into " .. _gY)
    end
end
_hZ()
local function _ir()
    _he()
    local _is = { _meta = { version = 2, chunked = true, chunkBytes = _ha }, sections = {} }
    local _it = {}
    for _iu in pairs(_hc) do
        if _iu ~= "_meta" then
            _it[#_it + 1] = _iu
        end
    end
    table.sort(_it)
    for _iv, _iw in ipairs(_it) do
        local _ix = _hf[_iw]
        local _iy, _iz
        if _ix and _hj[_iw] and not _hi[_iw] then
            _iy, _iz = true, _ix.encoded
        else
            _hi[_iw] = nil
            local _iA, _iB = _hj[_iw], _hc[_iw]
            if _iA and _iA.tbl == _iB then
                _iy, _iz = pcall(_hk, _iA, _iB)
                if _iy and _iz == nil then
                    _iy = false
                end
                if not _iy then
                    _iA.all = true
                end
            end
            if not _iy then
                _iy, _iz = pcall(function()
                    return _gW:JSONEncode(_iB)
                end)
            end
        end
        if _iy and type(_iz) == "string" then
            if _ix and _ix.encoded == _iz then
                _is.sections[_iw] = { parts = _ix.parts, bytes = #_iz }
            else
                local _iC = _hA(_iz)
                local _iD = true
                for _iE, _iF in ipairs(_iC) do
                    local _iG, _iH = pcall(writefile, _hx(_iw, _iE), _iF)
                    if not _iG then
                        warn("[SIEXTHER] Failed to write part " .. _iE .. " of '" .. tostring(_iw) .. "':", _iH)
                        _iD = false
                        break
                    end
                    if _iE % 4 == 0 then
                        task.wait()
                    end
                end
                if _iD then
                    if _ix and _ix.parts > #_iC then
                        for _iI = #_iC + 1, _ix.parts do
                            _hJ(_hx(_iw, _iI))
                        end
                    end
                    _hf[_iw] = { encoded = _iz, parts = #_iC }
                    _is.sections[_iw] = { parts = #_iC, bytes = #_iz }
                else
                    _hi[_iw] = true
                    if _ix then
                        _is.sections[_iw] = { parts = _ix.parts, bytes = #_ix.encoded }
                    end
                end
            end
        else
            _hi[_iw] = true
            warn("[SIEXTHER] Failed to encode section '" .. tostring(_iw) .. "':", _iz)
            if _ix then
                _is.sections[_iw] = { parts = _ix.parts, bytes = #_ix.encoded }
            end
        end
    end
    for _iJ, _iK in pairs(_hf) do
        if _hc[_iJ] == nil then
            for _iL = 1, _iK.parts do
                _hJ(_hx(_iJ, _iL))
            end
            _hf[_iJ] = nil
        end
    end
    for _iM, _iN in pairs(_hg) do
        if _hc[_iM] == nil then
            _is.sections[_iM] = _iN
        else
            _hg[_iM] = nil
        end
    end
    local _iO, _iP = pcall(function()
        return _gW:JSONEncode(_is)
    end)
    if _iO and type(_iP) == "string" and _iP ~= _hh then
        local _iQ, _iR = pcall(writefile, _gY, _iP)
        if _iQ then
            _hh = _iP
        else
            warn("[SIEXTHER] Failed to write data.json:", _iR)
        end
    end
end
local _iS = false
local _iT = false
local _iU = 3
local _iV = 0
local function _iW()
    if not _hb or not _gW then
        return
    end
    if _iS then
        _iT = true
        return
    end
    local _iX = os.clock() - _iV
    if _iX < _iU then
        if _iT then
            return
        end
        _iT = true
        local _iY = _iU - _iX
        if _iY < 0 then
            _iY = 0.01
        end
        task.delay(_iY, function()
            if _iT and not _iS then
                _iT = false
                _iW()
            end
        end)
        return
    end
    _iS = true
    task.defer(function()
        local _iZ = 0
        repeat
            _iZ = _iZ + 1
            if _iZ > 10 then
                _iT = false
                break
            end
            _iT = false
            local _ja, _jb = pcall(_ir)
            if not _ja then
                warn("[SIEXTHER] Failed to write data:", _jb)
            end
        until not _iT
        _iV = os.clock()
        _iS = false
    end)
end
local function _jc(_jd, _je)
    local _jf = _hc[_jd]
    if _jf ~= nil then
        return _jf
    end
    return _je
end
local function _jg(_jh, _ji)
    if type(_jh) ~= "string" then
        return
    end
    _hc[_jh] = _ji
    _hi[_jh] = true
    _iW()
end

SX.Flush = _ir


-- Original visual controls and catalog filter helpers.

_sv.GlyphData = {
    ["search:14"] = "314141R151k271g181N122B132r252V162F172V182r192o1A241134123r133c1834193k214R124r19441A4v1B4J115k125V1A5c1B5Y116k126F1A6V1B6k117g127V1A7g1B7V118N128r138419881A8z1B8F129o139k14941898199o1A9k12A413Ak14Av15Ac16AV17Ag18Az19Ak1AAz1BAN14BJ15BY16Bk17BV18BF1ABN1BBz1CBN1BCN1CCY1",
    ["search:16"] = "51N161Y171k181V191F132F142r152z162k282o192z1A2k1B24123F133z143g1534193F1A3o2C34124r134g1A441B4r1C4c115N125z13541B5N1C5z1D54116Y126k1B641C6z1D6F117k2C7z1D7F118V128o1B8B1C8z1D8B119F129z139F1B9Y1C9r12Ak13Ao14A41AAJ1BAz1CAR12B413Bo14Br15BN16B418BB19BY1ABz2CBN13C414Cc15Cz49Cr1ACR1BCN1CCz1DCN15D416DF28DB1CDN1DDz1EDN1DEN2",
    ["search:18"] = "61F171V291N1A18142J152r162z5B2c1C24133V143z153o163J1734193B1A3V1B3z1C3r1D38124J134z144c1B4B1C4v1D4o125r135o1C5J1D5z1E5N116F126z136J1D6o1E6k117V127z13741D7Y1E7z118V128z1D8V1E8z119N129z139B1D9g1E9r11A812Az13AV1CA41DAv1EAc12Bc13Bz14BB1CBg1DBz1EB812C413Cr14Cv15CJ1AC41BCg1CCz1DCk13D814Do15Dz16Do17DY18DV19Dg1ADv1BDz1CDk1DDz1EDc15EN16Ek17Ez29Er1AEc1BE81DEc1EEz1FEc1EFc1FFz1GFR1FGR1GGB1",
    ["forest:18"] = "81J272F182z2A2F163B173v183o2A3v1B3B154B164v174o18442A4o1B4v1C4B155k165z17541A541B5z1C5k156R166z176R1A6R1B6z1C6R1474157o167v177B1A7B1B7v1C7o1D741384148o158v168B1B8B1C8v1D8o1E84139B149z159Y1C9Y1D9z1E9B14Av15Az1CAz1DAv13Bc14Bz15BN1CBN1DBz1EBc12CY13Cz14CN1DCN1ECz1FCY12Dc13Dz14DVAEDz1FDc12E813EzCFE818Fk28Gk28H82",
    ["forestfling:18"] = "548164419441A4V6G4B145B155v165o1754195B1A5z6G5R1364146r156v276o1864137c147z157F277z187V138g148z158B168N178z188c19851A8R5F85129R139z149V179c189z199O1A9R5F9512AR13Az14AJ17AR18Az19AN11BB12Bv13Bo14B417B418Bo19Bv1AB811CR12Cz13Co14Ck48Cr19Cz1ACa1BCL5GC911D412Dg13Dk25Dv27Dk29Dg1ADB6GD415Eg2",
}
local _sM = {}
for _sN = 1, 62 do
    _sM[string.byte("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz", _sN)] = _sN - 1
end
_sv.DrawGlyph = function(_sO, _sP, _sQ, _sR)
    local _sS = _sv.GlyphData[_sP .. ":" .. tostring(_sQ)] or ""
    local _sT, _sU = pcall(__SIEXTHER_VIP_GLASS_V1.Instance.new, "CanvasGroup")
    if _sT and _sU then
        _sU.Name, _sU.BackgroundTransparency, _sU.BorderSizePixel = "JH_Glyph", 1, 0
        _sU.Size, _sU.GroupColor3 = UDim2.fromScale(1, 1), _sR or _kA.SubText
        pcall(function()
            _sU.Interactable = false
        end)
        _sU.Parent = _sO
    else
        _sU = nil
    end
    local _sV, _sW, _sX = { Group = _sU }, _sU and Color3.new(1, 1, 1) or (_sR or _kA.SubText), _sM
    local _sY = string.byte
    for _sZ = 1, #_sS - 3, 4 do
        _sV[#_sV + 1] = _qz(
            "Frame",
            {
                Size = UDim2.fromOffset(_sX[_sY(_sS, _sZ + 3)], 1),
                Position = UDim2.fromOffset(_sX[_sY(_sS, _sZ)], _sX[_sY(_sS, _sZ + 1)]),
                BackgroundColor3 = _sW,
                BackgroundTransparency = 1 - _sX[_sY(_sS, _sZ + 2)] / 61,
                Parent = _sU or _sO,
            }
        )
    end
    return _sV
end
_sv.TintGlyph = function(_ta, _tb, _tc)
    if not _ta then
        return
    end
    if _ta.Group then
        if _tc then
            _ry(_ta.Group, _tc, nil, nil, { GroupColor3 = _tb })
        else
            _ta.Group.GroupColor3 = _tb
        end
        return
    end
    for _td, _te in ipairs(_ta) do
        _te.BackgroundColor3 = _tb
    end
end
_sv.DrawSearch = function(_tf, _tg)
    return _sv.DrawGlyph(_tf, "search", _tg)
end

local _vE = TweenInfo.new(0.16, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local _vF = TweenInfo.new(0.28, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local function _vG(_vH, _vI, _vJ)
    if not _vH then
        return
    end
    _vJ = _vJ == nil and 0.12 or _vJ
    local _vK = 0
    pcall(function()
        _vK = _vH.BackgroundTransparency
    end)
    local _vL = nil
    if _vI then
        pcall(function()
            if
                _vI.Transparency >= 0.95
                and _vH:IsA("TextButton")
                and _vH.Text ~= ""
                and __SIEXTHER_VIP_GLASS_V1.Read(_vH, "BackgroundTransparency") < 0.5
            then
                _vI.Color = _kA.Home.Edge
                _vI.Transparency = _kA.Home.EdgeRest
            end
        end)
        local _vM, _vN = pcall(function()
            return _vI.Transparency
        end)
        if _vM then
            _vL = _vN
        end
    end
    local _vO = _vJ > 0 and math.max(0, _vK - _vJ) or nil
    local _vP = (_vI and _vL) and math.max(0, _vL - 0.35) or nil
    local _vQ, _vR = nil, nil
    local function _vS(_vT, _vU, _vV, _vW)
        if _vT then
            pcall(function()
                _vT:Cancel()
            end)
        end
        local _vY, _vZ = pcall(function()
            local _vX = _eE:Create(_vU, _vV, _vW)
            _vX:Play()
            return _vX
        end)
        return _vY and _vZ or nil
    end
    _jx(_jJ(_vH, "MouseEnter"), function()
        if _vO and _vH.Parent then
            _vQ = _vS(_vQ, _vH, _vE, { BackgroundTransparency = _vO })
        end
        if _vI and _vP and _vI.Parent then
            _vR = _vS(_vR, _vI, _vE, { Transparency = _vP })
        end
    end)
    _jx(_jJ(_vH, "MouseLeave"), function()
        if _vO and _vH.Parent then
            _vQ = _vS(_vQ, _vH, _vF, { BackgroundTransparency = _vK })
        end
        if _vI and _vL and _vI.Parent then
            _vR = _vS(_vR, _vI, _vF, { Transparency = _vL })
        end
    end)
end
_kA.HomeBtn = {
    Bg = _kA.Home.Tile,
    BgHover = _kA.ElementHover,
    BgOn = _kA.ElementActive,
    Text = _kA.SubText,
    TextOn = _kA.Text,
    TextDim = _kA.TextMuted,
    Edge = _kA.Home.Edge,
    EdgeRest = _kA.Home.EdgeRest,
    EdgeHover = _kA.Home.EdgeHover,
    EdgeOn = _kA.Home.EdgeActive,
}
_kA.Btn =
    { Bg = _kA.Home.Tile, Hover = _kA.ElementHover, Active = _kA.ElementActive, ActiveHover = _kA.Border }
function _sv.HomeBtnState(_wa, _wb)
    if not _wa then
        return
    end
    local _wc = _kA.HomeBtn
    local _wd = _wa:FindFirstChildOfClass("UIStroke")
    pcall(function()
        _wa:SetAttribute("HBState", _wb)
    end)
    local _we, _wf, _wg = _wc.Bg, _wc.Text, _wc.EdgeRest
    if _wb == "on" then
        _we, _wf, _wg = _wc.BgOn, _wc.TextOn, _wc.EdgeOn
    elseif _wb == "dim" then
        _wf = _wc.TextDim
    end
    _ry(_wa, 0.15, nil, nil, { BackgroundColor3 = _we, BackgroundTransparency = 0 })
    if _wa:IsA("TextButton") then
        _ry(_wa, 0.15, nil, nil, { TextColor3 = _wf })
    end
    if _wd then
        _ry(_wd, 0.15, nil, nil, { Color = _wc.Edge, Transparency = _wg })
    end
end
function _sv.HomeBtn(_wh)
    if not _wh then
        return nil
    end
    local _wi = _kA.HomeBtn
    local _wj = _wh:FindFirstChildOfClass("UIStroke") or _sv.Stroke(_wh, _wi.Edge, 1, _wi.EdgeRest)
    pcall(function()
        _wh.AutoButtonColor = false
        _wh.BackgroundColor3 = _wi.Bg
        _wh.BackgroundTransparency = 0
        _wj.Color, _wj.Transparency, _wj.Thickness = _wi.Edge, _wi.EdgeRest, 1
        _wj.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        if _wh:IsA("TextButton") then
            _wh.TextColor3 = _wi.Text
        end
        _wh:SetAttribute("HBState", "rest")
    end)
    local _wk = _wh:IsA("TextButton")
    local function _wl()
        return (_wh:GetAttribute("HBState") or "rest") == "rest"
    end
    _jx(_jJ(_wh, "MouseEnter"), function()
        if not _wl() then
            return
        end
        _qc("Hover")
        _ry(_wh, 0.14, nil, nil, { BackgroundColor3 = _wi.BgHover })
        if _wk then
            _ry(_wh, 0.14, nil, nil, { TextColor3 = _wi.TextOn })
        end
        _ry(_wj, 0.14, nil, nil, { Transparency = _wi.EdgeHover })
    end)
    _jx(_jJ(_wh, "MouseLeave"), function()
        if not _wl() then
            return
        end
        _ry(_wh, 0.18, nil, nil, { BackgroundColor3 = _wi.Bg })
        if _wk then
            _ry(_wh, 0.18, nil, nil, { TextColor3 = _wi.Text })
        end
        _ry(_wj, 0.18, nil, nil, { Transparency = _wi.EdgeRest })
    end)
    _jx(_jJ(_wh, "MouseButton1Down"), function()
        if _wl() then
            _ry(_wj, 0.08, nil, nil, { Transparency = _wi.EdgeOn })
        end
    end)
    _jx(_jJ(_wh, "MouseButton1Up"), function()
        if _wl() then
            _ry(_wj, 0.14, nil, nil, { Transparency = _wi.EdgeHover })
        end
    end)
    return _wj
end
function _sv.SubTabs(_wm, _wn, _wo, _wp)
    _wp = _wp or {}
    local _wq = _kA.SubTab
    local _wr = math.max(1, #_wn)
    local _ws = _wp.Scroll == true
    local _wt = Color3.fromRGB(255, 255, 255)
    local _wu = _kA.Btn.Active
    local _wv = _wq.Gap - 2
    local _ww = _qz(
        "Frame",
        {
            Name = "SubTabs",
            Size = _wp.Size or UDim2.new(1, 0, 0, _wp.Height or 36),
            Position = _wp.Position,
            AnchorPoint = _wp.AnchorPoint,
            BackgroundColor3 = _kA.Element,
            BackgroundTransparency = 0.3,
            LayoutOrder = _wp.LayoutOrder,
            Parent = _wm,
        }
    )
    _sf(_ww, 10)
    _so(_ww, _kA.Home.Edge, 1, 0.8)
    local _wx, _wy, _wz = {}, {}, 0
    if _ws then
        local _wA = _eA("TextService")
        local _wB = 0
        for _wC, _wD in ipairs(_wn) do
            local _wE = 50
            if _wA then
                local _wF, _wG = pcall(function()
                    return _wA:GetTextSize(
                        tostring(_wD.label or _wD.name or _wD.key),
                        _wq.TextSize,
                        _wq.FontOn,
                        Vector2.new(1000, 20)
                    )
                end)
                if _wF and _wG then
                    _wE = _wG.X
                end
            end
            _wE = math.max(_wp.MinWidth or 56, _wE + _wq.PadX * 2)
            _wx[_wC], _wy[_wC] = _wB, _wE
            _wB = _wB + _wE + _wv
        end
        _wz = math.max(0, _wB - _wv)
        if _wp.Spinner then
            _wz = _wz + _wv + 20
        end
    end
    local _wH
    if _ws then
        _wH = _qz(
            "ScrollingFrame",
            {
                Size = UDim2.new(1, -6, 1, -6),
                Position = UDim2.new(0, 3, 0, 3),
                BackgroundTransparency = 1,
                ScrollingDirection = Enum.ScrollingDirection.X,
                ScrollBarThickness = 0,
                CanvasSize = UDim2.new(0, _wz, 0, 0),
                VerticalScrollBarInset = Enum.ScrollBarInset.None,
                ClipsDescendants = true,
                Parent = _ww,
            }
        )
    else
        _wH = _qz(
            "Frame",
            {
                Size = UDim2.new(1, -6, 1, -6),
                Position = UDim2.new(0, 3, 0, 3),
                BackgroundTransparency = 1,
                Parent = _ww,
            }
        )
    end
    local _wI = _qz("Frame", { BackgroundColor3 = _wu, ZIndex = 1, Visible = false, Parent = _wH })
    _sf(_wI, 8)
    local _wJ, _wK
    if _wp.Pages then
        local _wL = _wp.Pages
        _wK = _qz(
            "Frame",
            {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = _cu or Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = _wL.LayoutOrder,
                Parent = _wL.Parent,
            }
        )
        _wJ = {}
    end
    local _wM, _wN, _wO, _wP = {}, nil, false, false
    if not _wp.NoInitial then
        _wN = _wp.Default or (_wn[1] and _wn[1].key)
    end
    local _wQ = { Bar = _ww, Track = _wH, Indicator = _wI, Buttons = _wM, Pages = _wJ, Container = _wK }
    local function _wR(_wS)
        if _ws then
            return UDim2.new(0, _wx[_wS] + 1, 0, 0), UDim2.new(0, _wy[_wS] - 2, 1, 0)
        end
        return UDim2.new((_wS - 1) / _wr, 1, 0, 0), UDim2.new(1 / _wr, -2, 1, 0)
    end
    local function _wT(_wU)
        if not _ws then
            return
        end
        pcall(function()
            local _wV, _wW = _wx[_wU], _wx[_wU] + _wy[_wU]
            local _wX = _wH.AbsoluteWindowSize.X
            local _wY = _wH.CanvasPosition.X
            local _wZ = math.max(0, _wz - _wX)
            local _xa
            if _wV < _wY then
                _xa = _wV - 8
            elseif _wW > _wY + _wX then
                _xa = _wW - _wX + 8
            end
            if _xa then
                _ry(_wH, 0.2, nil, nil, { CanvasPosition = Vector2.new(math.clamp(_xa, 0, _wZ), 0) })
            end
        end)
    end
    local function _xb(_xc)
        for _xd, _xe in pairs(_wM) do
            local _xf = (_xd == _wN)
            if _xc then
                _ry(_xe.Btn, 0.18, nil, nil, { TextColor3 = _xf and _wt or _kA.Home.Muted })
            else
                _xe.Btn.TextColor3 = _xf and _wt or _kA.Home.Muted
            end
            _xe.Btn.Font = _xf and _wq.FontOn or _wq.FontOff
        end
        local _xg = _wN and _wM[_wN]
        if not _xg then
            _wI.Visible = false
            _wP = false
            return
        end
        local _xh, _xi = _wR(_xg.Index)
        if _xc and _wP then
            _ry(_wI, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Position = _xh, Size = _xi })
        else
            _wI.Position, _wI.Size = _xh, _xi
        end
        _wI.Visible = true
        _wP = true
    end
    local function _xj()
        if not _wJ then
            return
        end
        for _xk, _xl in pairs(_wJ) do
            _xl.Visible = (_xk == _wN)
        end
    end
    local _xm = { moved = false }
    for _xn, _xo in ipairs(_wn) do
        local _xp = tostring(_xo.label or _xo.name or _xo.key)
        local _xq = _qz(
            "TextButton",
            {
                Size = _ws and UDim2.new(0, _wy[_xn], 1, 0) or UDim2.new(1 / _wr, 0, 1, 0),
                Position = _ws and UDim2.new(0, _wx[_xn], 0, 0) or UDim2.new((_xn - 1) / _wr, 0, 0, 0),
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                ZIndex = 2,
                Font = _wq.FontOff,
                TextSize = _wq.TextSize,
                TextColor3 = _kA.Home.Muted,
                Text = _xp,
                Parent = _wH,
            }
        )
        _wM[_xo.key] = { Btn = _xq, Def = _xo, Index = _xn }
        if _wJ then
            local _xr = _wp.Pages
            local _xs
            if _xr.Plain then
                _xs = _qz(
                    "Frame",
                    {
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = _cu or Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Visible = false,
                        Parent = _wK,
                    }
                )
                _qz(
                    "UIListLayout",
                    { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = _xs }
                )
            else
                _xs = _qz(
                    "ScrollingFrame",
                    {
                        Size = UDim2.new(1, 0, 0, _xr.Height or 0),
                        AutomaticSize = (not _xr.Height) and (_cu or Enum.AutomaticSize.Y) or nil,
                        CanvasSize = UDim2.new(0, 0, 0, 0),
                        AutomaticCanvasSize = _cu or Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Visible = false,
                        ScrollBarThickness = 2,
                        ScrollBarImageColor3 = _xr.Accent or _kA.Accent,
                        ScrollBarImageTransparency = 0.4,
                        VerticalScrollBarInset = Enum.ScrollBarInset.None,
                        Parent = _wK,
                    }
                )
                _qz(
                    "UIListLayout",
                    { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = _xs }
                )
                _vy(_xs, 1, 1, 1, 2)
            end
            _wJ[_xo.key] = _xs
        end
        _jx(_jJ(_xq, "MouseEnter"), function()
            if _wN ~= _xo.key then
                _ry(_xq, 0.1, nil, nil, { TextColor3 = _kA.SubText })
            end
        end)
        _jx(_jJ(_xq, "MouseLeave"), function()
            if _wN ~= _xo.key then
                _ry(_xq, 0.1, nil, nil, { TextColor3 = _kA.Home.Muted })
            end
        end)
        _jx(_jJ(_xq, "MouseButton1Click"), function()
            if _wO then
                return
            end
            if _xm.moved then
                _xm.moved = false
                return
            end
            _wQ.Select(_xo.key)
        end)
    end
    _wQ.Select = function(_xt, _xu)
        if not _wM[_xt] then
            return
        end
        _wN = _xt
        _xb(true)
        _xj()
        _wT(_wM[_xt].Index)
        if _wJ then
            pcall(function()
                local _xv = getgenv().__JH_REFRESH
                if _xv then
                    _xv(_wJ[_xt])
                end
            end)
        end
        if not _xu and _wo then
            _jq(_wo, _xt)
        end
    end
    _wQ.Set = function(_xw)
        _wN = (_xw ~= nil and _wM[_xw]) and _xw or nil
        _xb(true)
        _xj()
    end
    _wQ.Refresh = function()
        _xb(false)
        _xj()
        if _wJ and _wN then
            pcall(function()
                local _xx = getgenv().__JH_REFRESH
                if _xx then
                    _xx(_wJ[_wN])
                end
            end)
        end
    end
    _wQ.Key = function()
        return _wN
    end
    _wQ.IsLocked = function()
        return _wO
    end
    if _wp.Spinner then
        local _xy = _qz(
            "Frame",
            {
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(0, _wz - 20, 0.5, -10),
                BackgroundTransparency = 1,
                Visible = false,
                Parent = _wH,
            }
        )
        local _xz = _qz(
            "TextLabel",
            {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.GothamBold,
                Text = _wp.SpinnerText or _kF.RELOAD,
                TextColor3 = _kA.SubText,
                TextSize = 14,
                Parent = _xy,
            }
        )
        local _xA
        local function _xB()
            _xz.Rotation = 0
            _xA = _ry(_xz, 0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, { Rotation = 360 })
            if _xA then
                _xA.Completed:Connect(function()
                    if _wO then
                        _xB()
                    end
                end)
            end
        end
        _wQ.Lock = function(_xC)
            _wO = _xC and true or false
            _xy.Visible = _wO
            if _xA then
                pcall(function()
                    _xA:Cancel()
                end)
                _xA = nil
            end
            if _wO then
                _xB()
            end
        end
    else
        _wQ.Lock = function(_xD)
            _wO = _xD and true or false
        end
    end
    if _ws and _eF then
        local _xE, _xF, _xG, _xH, _xI = false, 0, 0, nil, nil
        local function _xJ()
            _xE = false
            if _xH then
                pcall(function()
                    _xH:Disconnect()
                end)
                _xH = nil
            end
            if _xI then
                pcall(function()
                    _xI:Disconnect()
                end)
                _xI = nil
            end
        end
        local function _xK(_xL)
            if _xL.UserInputType ~= Enum.UserInputType.MouseButton1 then
                return
            end
            _xJ()
            _xE, _xm.moved = true, false
            _xF, _xG = _xL.Position.X, _wH.CanvasPosition.X
            _xH = _jx(_jJ(_eF, "InputChanged"), function(_xM)
                if _xE and _xM.UserInputType == Enum.UserInputType.MouseMovement then
                    local _xN = _xM.Position.X - _xF
                    if math.abs(_xN) > 6 then
                        _xm.moved = true
                    end
                    if _xm.moved then
                        pcall(function()
                            local _xO = math.max(0, _wH.AbsoluteCanvasSize.X - _wH.AbsoluteWindowSize.X)
                            _wH.CanvasPosition = Vector2.new(math.clamp(_xG - _xN, 0, _xO), 0)
                        end)
                    end
                end
            end)
            _xI = _jx(_jJ(_eF, "InputEnded"), function(_xP)
                if _xP.UserInputType == Enum.UserInputType.MouseButton1 then
                    _xJ()
                end
            end)
        end
        _jx(_jJ(_wH, "InputBegan"), _xK)
        for _xQ, _xR in pairs(_wM) do
            _jx(_jJ(_xR.Btn, "InputBegan"), _xK)
        end
        _jx(_jJ(_wH, "InputChanged"), function(_xS)
            if _xS.UserInputType == Enum.UserInputType.MouseWheel then
                pcall(function()
                    local _xT = math.max(0, _wH.AbsoluteCanvasSize.X - _wH.AbsoluteWindowSize.X)
                    _wH.CanvasPosition =
                        Vector2.new(math.clamp(_wH.CanvasPosition.X - _xS.Position.Z * 90, 0, _xT), 0)
                end)
            end
        end)
    end
    _xb(false)
    _xj()
    return _wQ
end

local _ze = {
    { label = "Relevansi", names = { "Relevance" } },
    { label = "Penjualan Terbanyak", names = { "Sales", "Bestselling", "MostSold" } },
    { label = "Most Favorited", names = { "MostFavorited", "Favorited" } },
    { label = "Recently published", names = { "Updated", "RecentlyPublished", "Newest" } },
    { label = "Price (Low to High)", names = { "PriceAsc", "PriceLowToHigh" } },
    { label = "Price (High to Low)", names = { "PriceDesc", "PriceHighToLow" } },
}
local _zf = {
    { label = "Everything", names = {} },
    { label = "Pengguna", names = { "User" } },
    { label = "Kelompok", names = { "Group" } },
}
local _zg = 0.012
local function _zh(_zi)
    _zi = math.max(1, _zi)
    return (1 - (_zi - 1) * _zg) / _zi
end
local _zj = UDim2.new(_zg, 0, 0, 10)
local _zk = { [3] = UDim2.new(_zh(3), 0, 0, 140), [4] = UDim2.new(_zh(4), 0, 0, 132) }
local function _zl(_zm, _zn)
    for _zo, _zp in ipairs(_zn) do
        local _zq, _zr = pcall(function()
            return _zm[_zp]
        end)
        if _zq and _zr then
            return _zr
        end
    end
    return nil
end
local function _zs(_zt, _zu, _zv)
    local _zw = _qz(
        "Frame",
        {
            Size = UDim2.new(0, 10, 0, 10),
            Position = UDim2.new(1, -(_zv or 16), 0.5, -5),
            BackgroundTransparency = 1,
            ZIndex = (_zt.ZIndex or 1) + 1,
            Parent = _zt,
        }
    )
    local _zx = _qz(
        "Frame",
        {
            Size = UDim2.new(0, 6, 0, 2),
            Position = UDim2.new(0, 0, 0, 2),
            Rotation = 45,
            BackgroundColor3 = _zu,
            ZIndex = _zw.ZIndex,
            Parent = _zw,
        }
    )
    _sf(_zx, 1)
    local _zy = _qz(
        "Frame",
        {
            Size = UDim2.new(0, 6, 0, 2),
            Position = UDim2.new(0, 4, 0, 2),
            Rotation = -45,
            BackgroundColor3 = _zu,
            ZIndex = _zw.ZIndex,
            Parent = _zw,
        }
    )
    _sf(_zy, 1)
    return _zw
end
local function _zz(_zA, _zB)
    local _zC = _qz(
        "Frame",
        { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = (_zA.ZIndex or 1) + 1, Parent = _zA }
    )
    local _zD = _qz(
        "Frame",
        {
            Size = UDim2.new(0, 12, 0, 2),
            Position = UDim2.new(0.5, -6, 0.5, -1),
            Rotation = 45,
            BackgroundColor3 = _zB,
            ZIndex = _zC.ZIndex,
            Parent = _zC,
        }
    )
    _sf(_zD, 1)
    local _zE = _qz(
        "Frame",
        {
            Size = UDim2.new(0, 12, 0, 2),
            Position = UDim2.new(0.5, -6, 0.5, -1),
            Rotation = -45,
            BackgroundColor3 = _zB,
            ZIndex = _zC.ZIndex,
            Parent = _zC,
        }
    )
    _sf(_zE, 1)
    return _zC
end
local function _zF(_zG, _zH)
    local _zI = _qz(
        "Frame",
        {
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(0.5, -7, 0.5, -7),
            BackgroundTransparency = 1,
            ZIndex = (_zG.ZIndex or 1) + 1,
            Parent = _zG,
        }
    )
    for _zJ, _zK in ipairs({ 14, 10, 6 }) do
        local _zL = _qz(
            "Frame",
            {
                Size = UDim2.new(0, _zK, 0, 2),
                Position = UDim2.new(0.5, -_zK / 2, 0, (_zJ - 1) * 6),
                BackgroundColor3 = _zH,
                ZIndex = _zI.ZIndex,
                Parent = _zI,
            }
        )
        _sf(_zL, 1)
    end
    return _zI
end
local function _zM(_zN, _zO, _zP)
    local _zQ = _qz(
        "TextButton",
        {
            Size = UDim2.new(0, 30, 0, 24),
            BackgroundColor3 = _kA.Glass,
            BackgroundTransparency = 0.15,
            Text = "",
            Parent = _zN,
        }
    )
    _sf(_zQ, 10)
    local _zR = _so(_zQ, _zP, 1, 0.55)
    _vG(_zQ, _zR)
    _zF(_zQ, _kA.SubText)
    local _zS = _qz(
        "Frame",
        {
            Size = UDim2.new(1, -20, 0, 0),
            AutomaticSize = _cu or Enum.AutomaticSize.Y,
            Position = UDim2.new(0, 10, 0, 60),
            BackgroundColor3 = _kA.Glass,
            BackgroundTransparency = 0.02,
            Visible = false,
            ZIndex = 60,
            Parent = _zO,
        }
    )
    _sf(_zS, 16)
    _so(_zS, _zP, 1.2, 0.2)
    _vy(_zS, 12, 12, 10, 10)
    _qz("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = _zS })
    local _zT =
        _qz("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, ZIndex = 61, Parent = _zS })
    _qz(
        "TextLabel",
        {
            Size = UDim2.new(1, -24, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = "Opsi Pencarian",
            TextColor3 = _kA.Text,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 61,
            Parent = _zT,
        }
    )
    local _zU = _qz(
        "TextButton",
        {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(1, -20, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 61,
            Parent = _zT,
        }
    )
    _zz(_zU, _kA.SubText)
    local function _zV(_zW, _zX)
        _qz(
            "TextLabel",
            {
                Size = UDim2.new(1, 0, 0, 14),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium,
                Text = _zW,
                TextColor3 = _kA.SubText,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 61,
                Parent = _zX,
            }
        )
    end
    local _zY =
        _qz("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, ZIndex = 61, Parent = _zS })
    _zV("Sort Type", _zY)
    local _zZ = { index = 1 }
    local _Aa = _qz(
        "TextButton",
        {
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 0, 14),
            BackgroundColor3 = _kA.Element,
            BackgroundTransparency = 0.1,
            Font = Enum.Font.GothamMedium,
            Text = "  " .. _ze[1].label,
            TextColor3 = _kA.Text,
            TextSize = 10.5,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 61,
            Parent = _zY,
        }
    )
    _sf(_Aa, 8)
    _so(_Aa, _zP, 1, 0.6)
    _zs(_Aa, _kA.SubText, 12)
    local _Ab = _qz(
        "Frame",
        {
            Size = UDim2.new(1, 0, 0, #_ze * 22),
            Position = UDim2.new(0, 0, 0, 36),
            BackgroundColor3 = _kA.Element,
            BackgroundTransparency = 0.05,
            Visible = false,
            ZIndex = 62,
            Parent = _zY,
        }
    )
    _sf(_Ab, 8)
    _so(_Ab, _zP, 1, 0.4)
    _qz("UIListLayout", { Padding = UDim.new(0, 1), Parent = _Ab })
    for _Ac, _Ad in ipairs(_ze) do
        local _Ae = _qz(
            "TextButton",
            {
                Size = UDim2.new(1, 0, 0, 21),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium,
                Text = "  " .. _Ad.label,
                TextColor3 = _kA.SubText,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 62,
                Parent = _Ab,
            }
        )
        _jx(_jJ(_Ae, "MouseButton1Click"), function()
            _zZ.index = _Ac
            _Aa.Text = "  " .. _Ad.label
            _Ab.Visible = false
        end)
        _jx(_jJ(_Ae, "MouseEnter"), function()
            _ry(_Ae, 0.1, nil, nil, { TextColor3 = _kA.Text })
        end)
        _jx(_jJ(_Ae, "MouseLeave"), function()
            _ry(_Ae, 0.1, nil, nil, { TextColor3 = _kA.SubText })
        end)
    end
    _jx(_jJ(_Aa, "MouseButton1Click"), function()
        _Ab.Visible = not _Ab.Visible
    end)
    local _Af =
        _qz("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, ZIndex = 61, Parent = _zS })
    _zV("Harga", _Af)
    local _Ag = _qz(
        "Frame",
        {
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 0, 14),
            BackgroundTransparency = 1,
            ZIndex = 61,
            Parent = _Af,
        }
    )
    _qz(
        "UIListLayout",
        { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = _Ag }
    )
    local function _Ah(_Ai)
        local _Aj = _qz(
            "Frame",
            {
                Size = UDim2.new(0.48, 0, 1, 0),
                BackgroundColor3 = _kA.Element,
                BackgroundTransparency = 0.1,
                ZIndex = 61,
                Parent = _Ag,
            }
        )
        _sf(_Aj, 8)
        _so(_Aj, _zP, 1, 0.6)
        local _Ak = _qz(
            "TextBox",
            {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 8, 0, 0),
                Size = UDim2.new(1, -12, 1, 0),
                Font = Enum.Font.GothamMedium,
                PlaceholderText = _Ai,
                Text = "",
                TextColor3 = _kA.Text,
                PlaceholderColor3 = _kA.SubText,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 61,
                Parent = _Aj,
            }
        )
        return _Ak
    end
    local _Al = _Ah("Harga Min")
    local _Am = _Ah("Harga Maks")
    local _An =
        _qz("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, ZIndex = 61, Parent = _zS })
    _zV("Pencipta", _An)
    local _Ao = _qz(
        "Frame",
        {
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 0, 14),
            BackgroundTransparency = 1,
            ZIndex = 61,
            Parent = _An,
        }
    )
    local _Ap = _qz(
        "Frame",
        {
            Size = UDim2.new(0.62, -4, 1, 0),
            BackgroundColor3 = _kA.Element,
            BackgroundTransparency = 0.1,
            ZIndex = 61,
            Parent = _Ao,
        }
    )
    _sf(_Ap, 8)
    _so(_Ap, _zP, 1, 0.6)
    local _Aq = _qz(
        "TextBox",
        {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(1, -12, 1, 0),
            Font = Enum.Font.GothamMedium,
            PlaceholderText = "Username/Group Name",
            Text = "",
            TextColor3 = _kA.Text,
            PlaceholderColor3 = _kA.SubText,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 61,
            Parent = _Ap,
        }
    )
    local _Ar = { index = 1 }
    local _As = _qz(
        "TextButton",
        {
            Size = UDim2.new(0.36, 0, 1, 0),
            Position = UDim2.new(0.64, 4, 0, 0),
            BackgroundColor3 = _kA.Element,
            BackgroundTransparency = 0.1,
            Font = Enum.Font.GothamMedium,
            Text = "  " .. _zf[1].label,
            TextColor3 = _kA.Text,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 61,
            Parent = _Ao,
        }
    )
    _sf(_As, 8)
    _so(_As, _zP, 1, 0.6)
    _zs(_As, _kA.SubText, 12)
    local _At = _qz(
        "Frame",
        {
            Size = UDim2.new(0.36, 0, 0, #_zf * 20),
            Position = UDim2.new(0.64, 4, 0, 22),
            BackgroundColor3 = _kA.Element,
            BackgroundTransparency = 0.05,
            Visible = false,
            ZIndex = 62,
            Parent = _Ao,
        }
    )
    _sf(_At, 8)
    _so(_At, _zP, 1, 0.4)
    _qz("UIListLayout", { Parent = _At })
    for _Au, _Av in ipairs(_zf) do
        local _Aw = _qz(
            "TextButton",
            {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium,
                Text = "  " .. _Av.label,
                TextColor3 = _kA.SubText,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 62,
                Parent = _At,
            }
        )
        _jx(_jJ(_Aw, "MouseButton1Click"), function()
            _Ar.index = _Au
            _As.Text = "  " .. _Av.label
            _At.Visible = false
        end)
    end
    _jx(_jJ(_As, "MouseButton1Click"), function()
        _At.Visible = not _At.Visible
    end)
    local function _Ax(_Ay, _Az)
        local _AA = _qz(
            "Frame",
            { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, ZIndex = 61, Parent = _zS }
        )
        _qz(
            "TextLabel",
            {
                Size = UDim2.new(1, -46, 1, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium,
                Text = _Ay,
                TextColor3 = _kA.Text,
                TextSize = 10.5,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 61,
                Parent = _AA,
            }
        )
        local _AB = { value = _Az }
        local _AC = _qz(
            "Frame",
            {
                Size = UDim2.new(0, 34, 0, 16),
                Position = UDim2.new(1, -34, 0.5, -8),
                BackgroundColor3 = _Az and _zP or _kA.Element,
                ZIndex = 61,
                Parent = _AA,
            }
        )
        _sf(_AC, 999)
        _so(_AC, _zP, 1, 0.5)
        local _AD = _qz(
            "Frame",
            {
                Size = UDim2.new(0, 12, 0, 12),
                Position = _Az and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
                BackgroundColor3 = _kA.Text,
                ZIndex = 62,
                Parent = _AC,
            }
        )
        _sf(_AD, 999)
        local _AE = _qz(
            "TextButton",
            { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 62, Parent = _AC }
        )
        _jx(_jJ(_AE, "MouseButton1Click"), function()
            _AB.value = not _AB.value
            _ry(_AC, 0.15, nil, nil, { BackgroundColor3 = _AB.value and _zP or _kA.Element })
            _ry(
                _AD,
                0.15,
                nil,
                nil,
                { Position = _AB.value and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6) }
            )
        end)
        return _AB
    end
    local _AF = _Ax("Off-Sale Items", true)
    local _AG = _Ax("Personalized Results", true)
    local _AH = _qz(
        "TextButton",
        {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = _zP,
            BackgroundTransparency = 0.1,
            Font = Enum.Font.GothamBold,
            Text = "APPLY CHANGES",
            TextColor3 = _kA.Text,
            TextSize = 11,
            ZIndex = 61,
            Parent = _zS,
        }
    )
    _sf(_AH, 10)
    _vG(_AH)
    _jx(_jJ(_zQ, "MouseButton1Click"), function()
        _zS.Visible = not _zS.Visible
        _Ab.Visible = false
        _At.Visible = false
    end)
    _jx(_jJ(_zU, "MouseButton1Click"), function()
        _zS.Visible = false
    end)
    _jx(_jJ(_AH, "MouseButton1Click"), function()
        _zS.Visible = false
    end)
    return {
        GearBtn = _zQ,
        Modal = _zS,
        MinPriceBox = _Al,
        MaxPriceBox = _Am,
        CreatorBox = _Aq,
        ApplyBtn = _AH,
        GetSort = function()
            return _ze[_zZ.index]
        end,
        GetCreatorType = function()
            return _zf[_Ar.index]
        end,
        GetOffSale = function()
            return _AF.value
        end,
        GetPersonalized = function()
            return _AG.value
        end,
    }
end
local function _AI(_AJ, _AK, _AL)
    local _AM = _AL or 4
    local _AN = {}
    local _AO = _qz(
        "Frame",
        { Size = UDim2.new(0, 56, 0, 24), BackgroundColor3 = _kA.Glass, BackgroundTransparency = 0.15, Parent = _AJ }
    )
    _sf(_AO, 10)
    _so(_AO, _AK, 1, 0.55)
    _qz(
        "UIListLayout",
        { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Parent = _AO }
    )
    local function _AP()
        local _AQ = _zk[_AM] or _zk[4]
        for _AR, _AS in ipairs(_AN) do
            if _AS and _AS.Parent then
                pcall(function()
                    _ry(_AS, 0.18, nil, nil, { CellSize = _AQ })
                end)
            end
        end
    end
    local _AT = _qz(
        "TextButton",
        {
            Size = UDim2.new(0.5, 0, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = _kF.MINUS_FW,
            TextColor3 = _kA.SubText,
            TextSize = 13,
            Parent = _AO,
        }
    )
    local _AU = _qz(
        "TextButton",
        {
            Size = UDim2.new(0.5, 0, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = _kF.PLUS_FW,
            TextColor3 = _kA.SubText,
            TextSize = 13,
            Parent = _AO,
        }
    )
    _jx(_jJ(_AT, "MouseButton1Click"), function()
        _AM = math.min(4, _AM + 1)
        _AP()
    end)
    _jx(_jJ(_AU, "MouseButton1Click"), function()
        _AM = math.max(3, _AM - 1)
        _AP()
    end)
    return {
        RegisterGrid = function(_AV)
            table.insert(_AN, _AV)
            pcall(function()
                _AV.CellSize = _zk[_AM] or _zk[4]
            end)
        end,
        GetCellSize = function()
            return _zk[_AM] or _zk[4]
        end,
    }
end

local function _AX(image)
    if image and image.Parent then image.ImageTransparency = 1 end
end

local function _Be(_Bf, _Bg, _Bh)
    if not _Bf then
        return
    end
    pcall(function()
        _Bf.Image = _Bg
    end)
    if not _eI then
        return
    end
    task.spawn(function()
        local _Bi
        local _Bl = pcall(function()
            _eI:PreloadAsync({ _Bg }, function(_Bj, _Bk)
                _Bi = _Bk
            end)
        end)
        if not (_Bf and _Bf.Parent) then
            return
        end
        if _Bl and (_Bi == _cx or _Bi == Enum.AssetFetchStatus.Failure) then
            if _Bh ~= false then
                task.wait(0.4)
                if _Bf and _Bf.Parent then
                    _Be(_Bf, _Bg, false)
                end
            else
                _AX(_Bf)
            end
        end
    end)
end

local function _BO(_BP)
    pcall(function()
        _BP:SetAttribute("JH_NoTheme", true)
    end)
    return _BP
end
local _BQ = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local _BR = TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function _BS(_BT, _BU)
    local _BV = _BO(
        _qz(
            "Frame",
            {
                Size = UDim2.new(1, 0, 0, _BU or 36),
                BackgroundColor3 = _kA.Home.Tile,
                BackgroundTransparency = 0.35,
                Parent = _BT,
            }
        )
    )
    _sf(_BV, 10)
    local _BW = _so(_BV, _kA.Home.Edge, 1, 1)
    local _BX, _BY
    local function _BZ(_Ca, _Cb, _Cc)
        if _BX then
            _BX:Cancel()
        end
        if _BY then
            _BY:Cancel()
        end
        _BX = _eE:Create(_BW, _Ca, { Transparency = _Cb })
        _BY = _eE:Create(_BV, _Ca, { BackgroundTransparency = _Cc })
        _BX:Play()
        _BY:Play()
    end
    _jx(_jJ(_BV, "MouseEnter"), function()
        pcall(_BZ, _BQ, 0.78, 0.12)
    end)
    _jx(_jJ(_BV, "MouseLeave"), function()
        pcall(_BZ, _BR, 1, 0.35)
    end)
    return _BV
end
local function _Cd(_Ce, _Cf, _Cg, _Ch)
    if _Cf and tostring(_Cf) ~= "" then
        pcall(function()
            _Ce:SetAttribute("SIEXTHERSearchTitle", string.lower(tostring(_Cf)))
        end)
    end
    local _Ci =
        _qz("Frame", { Size = UDim2.new(1, -(_Ch or 0), 1, 0), BackgroundTransparency = 1, Parent = _Ce })
    _vy(_Ci, 11, 10, 4, 4)
    _qz(
        "UIListLayout",
        {
            FillDirection = Enum.FillDirection.Vertical,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 2),
            Parent = _Ci,
        }
    )
    local _Cj = _qz(
        "TextLabel",
        {
            Text = (_Cf and tostring(_Cf)) or "Example",
            Font = _kA.Typo.Medium,
            TextSize = _kA.Typo.LG,
            TextColor3 = _kA.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            LayoutOrder = 1,
            Parent = _Ci,
        }
    )
    local _Ck = nil
    if _Cg and tostring(_Cg) ~= "" then
        _Ck = _qz(
            "TextLabel",
            {
                Text = tostring(_Cg),
                Font = _kA.Typo.Body,
                TextSize = _kA.Typo.SM,
                TextColor3 = _kA.Home.Muted,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 12),
                LayoutOrder = 2,
                Parent = _Ci,
            }
        )
    end
    return { Holder = _Ci, TitleLabel = _Cj, SubtitleLabel = _Ck }
end

local _CB = {}
_CB.__index = _CB

local function _CS(_CT, _CU, _CV, _CW)
    if _CU then
        for _CX, _CY in pairs(_CW) do
            _CT[_CX] = _CY
        end
    else
        _ry(_CT, _CV, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, _CW)
    end
end
function _CB:CreateButtonImpl(_CZ)
    _CZ = (type(_CZ) == "table") and _CZ or {}
    local _Da = _BS(self.Body, 36)
    _Cd(_Da, _CZ.Title, _CZ.Subtitle, 78)
    local _Db = _qz(
        "TextButton",
        {
            Text = _CZ.ButtonText or "Run",
            Font = _kA.Typo.Bold,
            TextSize = _kA.Typo.SM,
            AnchorPoint = Vector2.new(1, 0.5),
            Size = UDim2.new(0, 64, 0, 24),
            Position = UDim2.new(1, -8, 0.5, 0),
            Parent = _Da,
        }
    )
    _sf(_Db, _kA.Metric.R_MD)
    _sv.HomeBtn(_Db)
    local _Dc = 0
    local function _Dd()
        if os.clock() - _Dc < 0.1 then
            return
        end
        _Dc = os.clock()
        _qc("Click")
        if _CZ.Callback then
            _jq(_CZ.Callback)
        end
    end
    _jx(_jJ(_Db, "MouseButton1Click"), _Dd)
    _jx(_jJ(_Db, "Activated"), _Dd)
    return _Da
end
function _CB:CreateButton(_De)
    local _Df, _Dg = pcall(function()
        return self:CreateButtonImpl(_De)
    end)
    if _Df and _Dg then
        return _Dg
    end
    warn("[SIEXTHER] CreateButton failed to build, using safe fallback element:", _Dg)
    return _BS(self.Body, 10)
end
local _Dh, _Di = UDim2.new(1, -15, 0.5, 0), UDim2.new(0, 3, 0.5, 0)
local _Dj = Color3.fromRGB(18, 18, 21)
function _CB:CreateToggleImpl(_Dk)
    _Dk = (type(_Dk) == "table") and _Dk or {}
    local _Dl = (_Dk.Default == true)
    local _Dm = _BS(self.Body, 36)
    _Cd(_Dm, _Dk.Title, _Dk.Subtitle, 56)
    local _Dn = _qz(
        "Frame",
        {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -11, 0.5, 0),
            Size = UDim2.new(0, 34, 0, 18),
            BackgroundColor3 = _kA.Home.Tile,
            Parent = _Dm,
        }
    )
    _qz("UICorner", { CornerRadius = UDim.new(1, 0), Parent = _Dn })
    local _Do = _so(_Dn, _kA.Home.Edge, 1, _kA.Home.EdgeRest)
    local _Dp = _qz(
        "Frame",
        {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = _Di,
            Size = UDim2.new(0, 12, 0, 12),
            BackgroundColor3 = _kA.Home.Muted,
            Parent = _Dn,
        }
    )
    _qz("UICorner", { CornerRadius = UDim.new(1, 0), Parent = _Dp })
    local _Dq = _qz(
        "TextButton",
        { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 2, Parent = _Dm }
    )
    local _Dr = false
    local function _Ds(_Dt)
        _CS(_Dn, _Dt, 0.2, { BackgroundColor3 = _Dl and _kA.Accent or _kA.Home.Tile })
        _CS(
            _Do,
            _Dt,
            0.2,
            { Transparency = _Dl and _kA.Home.EdgeActive or (_Dr and _kA.Home.EdgeHover or _kA.Home.EdgeRest) }
        )
        _CS(
            _Dp,
            _Dt,
            0.22,
            {
                Position = _Dl and _Dh or _Di,
                BackgroundColor3 = _Dl and _Dj or (_Dr and _kA.SubText or _kA.Home.Muted),
            }
        )
    end
    _Ds(true)
    _jx(_jJ(_Dq, "MouseEnter"), function()
        _Dr = true
        _Ds(false)
    end)
    _jx(_jJ(_Dq, "MouseLeave"), function()
        _Dr = false
        _Ds(false)
    end)
    local function _Du(_Dv, _Dw)
        _Dl = (_Dv == true)
        _Ds(false)
        if _Dw and _Dk.Callback then
            _jq(_Dk.Callback, _Dl)
        end
    end
    local _Dx = 0
    local function _Dy()
        if os.clock() - _Dx < 0.2 then
            return
        end
        _Dx = os.clock()
        _Dl = not _Dl
        _qc(_Dl and "ToggleOn" or "ToggleOff")
        _Ds(false)
        if _Dk.Callback then
            _jq(_Dk.Callback, _Dl)
        end
    end
    _jx(_jJ(_Dq, "Activated"), _Dy)
    return { Root = _Dm, Set = _Du }
end
function _CB:CreateToggle(_Dz)
    local _DA, _DB = pcall(function()
        return self:CreateToggleImpl(_Dz)
    end)
    if _DA and _DB then
        return _DB
    end
    warn("[SIEXTHER] CreateToggle failed to build, using safe fallback element:", _DB)
    return { Root = _BS(self.Body, 10), Set = function() end }
end
local function _DC(_DD, _DE, _DF, _DG)
    local _DH = _qz(
        "TextButton",
        {
            Text = _DE,
            Font = _kA.Typo.Bold,
            TextSize = _kA.Typo.XL,
            AnchorPoint = Vector2.new(_DF, 0.5),
            Position = UDim2.new(_DF, _DG, 1, -14),
            Size = UDim2.new(0, 20, 0, 18),
            Parent = _DD,
        }
    )
    _sf(_DH, _kA.Metric.R_SM)
    _sv.HomeBtn(_DH)
    return _DH
end
function _CB:CreateSliderImpl(_DI)
    _DI = (type(_DI) == "table") and _DI or {}
    local _DJ = tonumber(_DI.Min) or 0
    local _DK = tonumber(_DI.Max) or 100
    if _DK <= _DJ then
        _DK = _DJ + 1
    end
    local _DL = tonumber(_DI.Step) or 1
    if _DL <= 0 then
        _DL = 1
    end
    local _DM = math.clamp(tonumber(_DI.Default) or _DJ, _DJ, _DK)
    local _DN = _BS(self.Body, 56)
    local _DO = _Cd(_DN, _DI.Title, _DI.Subtitle, 64)
    _DO.Holder.Size = UDim2.new(1, -64, 0, 34)
    local _DP = _qz(
        "TextBox",
        {
            Text = tostring(_DM),
            Font = _kA.Typo.Medium,
            TextSize = _kA.Typo.MD,
            TextColor3 = _kA.Text,
            BackgroundColor3 = _kA.Home.Tile,
            ClearTextOnFocus = false,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -10, 0, 8),
            Size = UDim2.new(0, 46, 0, 20),
            Parent = _DN,
        }
    )
    _sf(_DP, _kA.Metric.R_SM)
    local _DQ = _so(_DP, _kA.Home.Edge, 1, _kA.Home.EdgeRest)
    local _DR = _DC(_DN, "-", 0, 10)
    local _DS = _DC(_DN, "+", 1, -10)
    local _DT = _qz(
        "Frame",
        {
            BackgroundTransparency = 1,
            Active = true,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 38, 1, -14),
            Size = UDim2.new(1, -76, 0, 18),
            Parent = _DN,
        }
    )
    local _DU = _qz(
        "Frame",
        {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 0, 4),
            BackgroundColor3 = _kA.ElementActive,
            Parent = _DT,
        }
    )
    _qz("UICorner", { CornerRadius = UDim.new(1, 0), Parent = _DU })
    local _DV = _qz("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = _kA.Home.Edge, Parent = _DU })
    _qz("UICorner", { CornerRadius = UDim.new(1, 0), Parent = _DV })
    local _DW = _qz(
        "Frame",
        {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 12, 0, 12),
            BackgroundColor3 = _kA.Text,
            Parent = _DV,
        }
    )
    _qz("UICorner", { CornerRadius = UDim.new(1, 0), Parent = _DW })
    _jx(_jJ(_DP, "MouseEnter"), function()
        if not _DP:IsFocused() then
            _ry(_DQ, 0.16, nil, nil, { Transparency = _kA.Home.EdgeHover })
        end
    end)
    _jx(_jJ(_DP, "MouseLeave"), function()
        if not _DP:IsFocused() then
            _ry(_DQ, 0.24, nil, nil, { Transparency = _kA.Home.EdgeRest })
        end
    end)
    _jx(_jJ(_DP, "Focused"), function()
        _ry(_DQ, 0.16, nil, nil, { Transparency = _kA.Home.EdgeActive })
    end)
    local _DX = false
    local _DY = 0
    local _DZ = tostring(_DL)
    if _DZ:find("%.") then
        _DY = #_DZ:match("%.(%d+)")
    end
    local _Ea = 10 ^ _DY
    local function _Eb(_Ec)
        local _Ed = math.floor((_Ec - _DJ) / _DL + 0.5)
        return math.floor((_Ed * _DL + _DJ) * _Ea + 0.5) / _Ea
    end
    local function _Ee(_Ef, _Eg)
        local _Eh = math.clamp((_Ef - _DJ) / math.max(1e-6, (_DK - _DJ)), 0, 1)
        if _Eg then
            _DV.Size = UDim2.new(_Eh, 0, 1, 0)
        else
            _ry(_DV, 0.16, nil, nil, { Size = UDim2.new(_Eh, 0, 1, 0) })
        end
    end
    local _Ei = false
    local function _Ej(_Ek, _El)
        _Ek = math.clamp(_Eb(tonumber(_Ek) or _DM), _DJ, _DK)
        if _Ei and _El and _DX and _Ek == _DM then
            return
        end
        _Ei = true
        _DM = _Ek
        _Ee(_Ek, _El)
        _DP.Text = tostring(_DM)
        if _DI.Callback then
            _jq(_DI.Callback, _DM)
        end
    end
    local function _Em(_En)
        _En = math.floor((tonumber(_En) or _DM) * _Ea + 0.5) / _Ea
        _DM = _En
        _Ee(_En, false)
        _DP.Text = tostring(_DM)
        if _DI.Callback then
            _jq(_DI.Callback, _DM)
        end
    end
    _Ej(_DM, true)
    local _Eo = 0
    local function _Ep(_Eq)
        if os.clock() - _Eo < 0.05 then
            return
        end
        _Eo = os.clock()
        _Ej(_DM + _Eq)
    end
    _jx(_jJ(_DR, "Activated"), function()
        _Ep(-_DL)
    end)
    _jx(_jJ(_DS, "Activated"), function()
        _Ep(_DL)
    end)
    _jx(_jJ(_DP, "FocusLost"), function()
        _ry(_DQ, 0.24, nil, nil, { Transparency = _kA.Home.EdgeRest })
        local _Er = tonumber(_DP.Text)
        if _Er then
            _Em(_Er)
        else
            _DP.Text = tostring(_DM)
        end
    end)
    local _Es, _Et
    local function _Eu()
        if _DX then
            _qc("Slider")
        end
        _DX = false
        _ry(_DW, 0.18, nil, nil, { Size = UDim2.new(0, 12, 0, 12) })
        if _Es then
            pcall(_Es.Disconnect, _Es)
            _Es = nil
        end
        if _Et then
            pcall(_Et.Disconnect, _Et)
            _Et = nil
        end
    end
    local function _Ev(_Ew)
        return math.clamp((_Ew - _DU.AbsolutePosition.X) / math.max(1, _DU.AbsoluteSize.X), 0, 1)
    end
    _jx(_jJ(_DT, "InputBegan"), function(_Ex)
        if
            _Ex.UserInputType == Enum.UserInputType.MouseButton1
            or _Ex.UserInputType == Enum.UserInputType.Touch
        then
            _DX = true
            _qc("Slider")
            _ry(_DW, 0.16, nil, nil, { Size = UDim2.new(0, 14, 0, 14) })
            _Ej(_DJ + _Ev(_Ex.Position.X) * (_DK - _DJ), true)
            if not _Es then
                _Es = _jx(_jJ(_eF, "InputChanged"), function(_Ey)
                    if not _DX then
                        return
                    end
                    if
                        _Ey.UserInputType == Enum.UserInputType.MouseMovement
                        or _Ey.UserInputType == Enum.UserInputType.Touch
                    then
                        _Ej(_DJ + _Ev(_Ey.Position.X) * (_DK - _DJ), true)
                    end
                end)
                _Et = _jx(_jJ(_eF, "InputEnded"), function(_Ez)
                    if
                        _Ez.UserInputType == Enum.UserInputType.MouseButton1
                        or _Ez.UserInputType == Enum.UserInputType.Touch
                    then
                        _Eu()
                    end
                end)
            end
        end
    end)
    return {
        Root = _DN,
        Set = function(_EA)
            _Ej(_EA, true)
        end,
    }
end
function _CB:CreateSlider(_EB)
    local _EC, _ED = pcall(function()
        return self:CreateSliderImpl(_EB)
    end)
    if _EC and _ED then
        return _ED
    end
    warn("[SIEXTHER] CreateSlider failed to build, using safe fallback element:", _ED)
    return { Root = _BS(self.Body, 10), Set = function() end }
end


-- Original animation asset loading and Roblox throttling helpers.

local _LQ = {
    backoff = {},
    strikes = {},
    nextSlot = {},
    cache = {},
    inflight = {},
    objCache = {},
    TTL = 90,
    CACHE_MAX = 300,
    RETRIES = 3,
    DEFAULT_GAP = 0.4,
    GAP = {
        ["friends.roblox.com"] = 1,
        ["groups.roblox.com"] = 0.7,
        ["users.roblox.com"] = 0.6,
        ["presence.roblox.com"] = 0.7,
        ["games.roblox.com"] = 0.7,
        ["badges.roblox.com"] = 0.7,
        ["avatar.roblox.com"] = 0.6,
        ["inventory.roblox.com"] = 0.8,
        ["catalog.roblox.com"] = 0.8,
        ["economy.roblox.com"] = 0.8,
        ["apis.roblox.com"] = 0.7,
        ["thumbnails.roblox.com"] = 0.6,
        ["assetdelivery.roblox.com"] = 0.35,
    },
}

function _LQ.noteLimited(_LY)
    if not _LY then
        return
    end
    local _LZ = (_LQ.strikes[_LY] or 0) + 1
    _LQ.strikes[_LY] = _LZ
    local _Ma = os.clock() + math.min(5 * (2 ^ (_LZ - 1)), 60)
    if _Ma > (_LQ.backoff[_LY] or 0) then
        _LQ.backoff[_LY] = _Ma
    end
    if _Ma > (_LQ.nextSlot[_LY] or 0) then
        _LQ.nextSlot[_LY] = _Ma
    end
end
function _LQ.noteOk(_Mb)
    if not _Mb then
        return
    end
    _LQ.strikes[_Mb] = nil
    _LQ.backoff[_Mb] = nil
end
function _LQ.reserve(_Mc)
    if not _Mc then
        return
    end
    local _Md = os.clock()
    local _Me = _LQ.GAP[_Mc] or _LQ.DEFAULT_GAP
    local _Mf = math.max(_Md, _LQ.nextSlot[_Mc] or 0, _LQ.backoff[_Mc] or 0)
    _LQ.nextSlot[_Mc] = _Mf + _Me
    local _Mg = _Mf - _Md
    if _Mg > 0 then
        task.wait(math.min(_Mg, 65))
    end
end

function _LQ.getObjects(_Mu)
    local _Mv = tostring(_Mu):match("%d+") or tostring(_Mu)
    local _Mw = _LQ.objCache[_Mv]
    if _Mw and (os.clock() - _Mw.t) < 600 then
        return true, _Mw.objs
    end
    local _Mx = "assetdelivery.roblox.com"
    local _My, _Mz
    for _MA = 1, _LQ.RETRIES do
        _LQ.reserve(_Mx)
        _My, _Mz = pcall(function()
            return game:GetObjects("rbxassetid://" .. _Mv)
        end)
        if _My and _Mz and #_Mz > 0 then
            _LQ.noteOk(_Mx)
            _LQ.objCache[_Mv] = { t = os.clock(), objs = _Mz }
            return _My, _Mz
        end
        local _MB = tostring(_Mz):lower()
        if _MB:find("429", 1, true) or _MB:find("too many", 1, true) or _MB:find("throttl", 1, true) then
            _LQ.noteLimited(_Mx)
        end
    end
    return _My, _Mz
end

onShutdown(function()
    for _, entry in pairs(_LQ.objCache) do
        for _, object in ipairs(entry.objs) do pcall(function() object:Destroy() end) end
    end
    table.clear(_LQ.objCache)
end)


-- BEGIN ORIGINAL ANIMATION MODULE (only the shutdown registration is added)

_NK.Animations = function()
    local _cvS = _LM and _LM["Animation"]
    if not _cvS or not _cvS.CreateSection then
        return
    end
    local _cvT = _eA("AvatarEditorService")
    local _cvU =
        { lastBundle = nil, lastBundleName = nil, speed = 1, autoLoad = true, emoteSpeed = 1, emoteHold = false }
    local function _cvV()
        _jg("animationsConfig", _cvU)
    end
    local function _cvW()
        local _cvX = _jc("animationsConfig", nil)
        if type(_cvX) ~= "table" then
            return
        end
        _cvU.lastBundle = _cvX.lastBundle
        _cvU.lastBundleName = _cvX.lastBundleName
        _cvU.stateOverrides = (type(_cvX.stateOverrides) == "table") and _cvX.stateOverrides or {}
        _cvU.speed = tonumber(_cvX.speed) or 1
        _cvU.emoteSpeed = tonumber(_cvX.emoteSpeed) or 1
        if type(_cvX.autoLoad) == "boolean" then
            _cvU.autoLoad = _cvX.autoLoad
        end
        if type(_cvX.emoteHold) == "boolean" then
            _cvU.emoteHold = _cvX.emoteHold
        end
    end
    _cvW()
    local _cvY = {}
    local _cvZ = false
    do
        local _cwa = _jc("animationsCache", nil)
        if type(_cwa) == "table" then
            _cvY = _cwa
            local _cwb = 0
            for _cwc, _cwd in pairs(_cvY) do
                if type(_cwd) == "table" then
                    local _cwe = _cwd["IdleAnimation"] ~= nil
                    local _cwf = _cwd["WalkAnimation"] ~= nil or _cwd["RunAnimation"] ~= nil
                    if not (_cwe and _cwf) then
                        _cvY[_cwc] = nil
                        _cwb = _cwb + 1
                    end
                end
            end
            if _cwb > 0 then
                warn(
                    "[SIEXTHER] Cleaned up "
                        .. _cwb
                        .. " old incomplete animation cache, will be re-resolved when used."
                )
                _cvZ = true
            end
        end
    end
    local function _cwg()
        _jg("animationsCache", _cvY)
    end
    if _cvZ then
        _cwg()
    end
    local _cwh = {
        IdleAnimation = true,
        WalkAnimation = true,
        RunAnimation = true,
        JumpAnimation = true,
        FallAnimation = true,
        ClimbAnimation = true,
        SwimAnimation = true,
    }
    local _cwi = { "all", "idle", "walk", "run", "jump", "fall", "climb", "swim" }
    local _cwj = {
        all = "All (default)",
        idle = "Idle",
        walk = "Walk",
        run = "Run",
        jump = "Jump",
        fall = "Fall",
        climb = "Climb",
        swim = "Swim",
    }
    local _cwk = {
        idle = "IdleAnimation",
        walk = "WalkAnimation",
        run = "RunAnimation",
        jump = "JumpAnimation",
        fall = "FallAnimation",
        climb = "ClimbAnimation",
        swim = "SwimAnimation",
    }
    local _cwl = { idle = "Animation1" }
    local _cwm = {
        IdleAnimation = 1,
        WalkAnimation = 2,
        RunAnimation = 3,
        JumpAnimation = 4,
        FallAnimation = 5,
        ClimbAnimation = 6,
        SwimAnimation = 7,
    }
    local _cwn = { IdleAnimation = true, WalkAnimation = true, RunAnimation = true }
    local _cwo = {}
    local function _cwp(_cwq)
        if _cwo[_cwq] then
            return _cwo[_cwq]
        end
        if not _cvT then
            return nil
        end
        local _cwr, _cws = pcall(function()
            return _cvT:GetItemDetails(_cwq, Enum.AvatarItemType.Bundle)
        end)
        if _cwr and _cws then
            _cwo[_cwq] = _cws
            return _cws
        end
        return nil
    end
    local function _cwt(_cwu)
        return _cvY[tostring(_cwu)] ~= nil
    end
    local function _cwv(_cww, _cwx, _cwy)
        local _cwz = tostring(_cww)
        if _cvY[_cwz] then
            return _cvY[_cwz], _cwo[_cww]
        end
        local _cwA = _cwp(_cww)
        if not _cwA or not _cwA.BundledItems then
            return nil
        end
        local _cwB = {}
        for _cwC, _cwD in ipairs(_cwA.BundledItems) do
            local _cwE = tostring(_cwD.AssetType)
            if _cwh[_cwE] and _cwD.Id then
                _cwB[#_cwB + 1] = { at = _cwE, id = _cwD.Id }
            end
        end
        table.sort(_cwB, function(_cwF, _cwG)
            return (_cwm[_cwF.at] or 99) < (_cwm[_cwG.at] or 99)
        end)
        local _cwH = 0
        for _cwI, _cwJ in ipairs(_cwB) do
            if _cwn[_cwJ.at] then
                _cwH = _cwI
            end
        end
        local _cwK = {}
        for _cwL, _cwM in ipairs(_cwB) do
            local _cwN, _cwO = _LQ.getObjects(_cwM.id)
            if _cwN and _cwO then
                local _cwP = {}
                for _cwQ, _cwR in ipairs(_cwO) do
                    for _cwS, _cwT in ipairs(_cwR:GetDescendants()) do
                        if _cwT:IsA("Animation") then
                            _cwP[_cwT.Name] = _cwT.AnimationId
                        end
                    end
                end
                if next(_cwP) then
                    _cwK[_cwM.at] = _cwP
                end
            end
            if _cwx then
                pcall(_cwx, _cwL, #_cwB)
            end
            if _cwL == _cwH and _cwy and next(_cwK) then
                pcall(_cwy, _cwK)
            end
            task.wait()
        end
        local _cwU = _cwK["IdleAnimation"] ~= nil
        local _cwV = _cwK["WalkAnimation"] ~= nil or _cwK["RunAnimation"] ~= nil
        local _cwW = _cwU and _cwV
        if next(_cwK) and _cwW then
            _cvY[_cwz] = _cwK
            _cwg()
            return _cwK, _cwA
        end
        return nil, _cwA
    end
    local _cwX = {
        token = 0,
        conns = {},
        tracks = {},
        current = nil,
        pose = "Standing",
        speedMul = tonumber(_cvU.speed) or 1,
        curBase = 1,
    }
    local function _cwY()
        if _cwX.current and _cwX.curBase then
            pcall(function()
                _cwX.current:AdjustSpeed(_cwX.curBase * (_cwX.speedMul or 1))
            end)
        end
    end
    local function _cwZ()
        _cwX.token = _cwX.token + 1
        for _cxa, _cxb in ipairs(_cwX.conns) do
            pcall(function()
                _cxb:Disconnect()
            end)
        end
        _cwX.conns = {}
        for _cxc, _cxd in pairs(_cwX.tracks) do
            pcall(function()
                _cxd:Stop(0)
            end)
        end
        _cwX.tracks = {}
        _cwX.current = nil
    end
    local function _cxe(_cxf, _cxg, _cxh)
        local _cxi = _cxf[_cxg]
        if not _cxi then
            return nil
        end
        local _cxj = _cxh and _cxi[_cxh]
        if not _cxj then
            for _cxk, _cxl in pairs(_cxi) do
                _cxj = _cxl
                break
            end
        end
        return _cxj
    end
    local function _cxm(_cxn, _cxo, _cxp, _cxq)
        if not _cxo then
            return nil
        end
        local _cxr = tostring(_cxo):match("%d+")
        if not _cxr then
            return nil
        end
        local _cxs = __SIEXTHER_VIP_GLASS_V1.Instance.new("Animation")
        _cxs.AnimationId = "rbxassetid://" .. _cxr
        local _cxt, _cxu = pcall(function()
            return _cxn:LoadAnimation(_cxs)
        end)
        if not _cxt or not _cxu then
            return nil
        end
        _cxu.Looped = (_cxq ~= false)
        _cxu.Priority = _cxp or Enum.AnimationPriority.Core
        return _cxu
    end
    local function _cxv(_cxw)
        if not _cxw then
            return false
        end
        if _cxw:FindFirstChild("RightUpperLeg") then
            return false
        end
        if _cxw:FindFirstChild("Right Leg") then
            return true
        end
        local _cxx = _cxw:FindFirstChildOfClass("Humanoid")
        return _cxx ~= nil and _cxx.RigType == Enum.HumanoidRigType.R6
    end
    local function _cxy(_cxz, _cxA)
        _cwZ()
        local _cxB = _cwX.token
        local _cxC = _cxz:FindFirstChildOfClass("Humanoid")
        if not _cxC then
            return false
        end
        local _cxD = _cxC:FindFirstChildOfClass("Animator")
        if not _cxD then
            return false
        end
        local _cxE = _cxz:FindFirstChild("Animate")
        if _cxE then
            _cxE.Disabled = true
        end
        for _cxF, _cxG in ipairs(_cxD:GetPlayingAnimationTracks()) do
            pcall(function()
                _cxG:Stop(0)
            end)
        end
        local _cxH = Enum.AnimationPriority
        local _cxI = {
            idle = _cxm(_cxD, _cxe(_cxA, "IdleAnimation", "Animation1"), _cxH.Idle),
            walk = _cxm(_cxD, _cxe(_cxA, "WalkAnimation"), _cxH.Movement),
            run = _cxm(_cxD, _cxe(_cxA, "RunAnimation"), _cxH.Movement),
            jump = _cxm(_cxD, _cxe(_cxA, "JumpAnimation"), _cxH.Action, false),
            fall = _cxm(_cxD, _cxe(_cxA, "FallAnimation"), _cxH.Action),
            climb = _cxm(_cxD, _cxe(_cxA, "ClimbAnimation"), _cxH.Movement),
            swim = _cxm(_cxD, _cxe(_cxA, "SwimAnimation", "Swim"), _cxH.Movement),
            swimidle = _cxm(_cxD, _cxe(_cxA, "SwimAnimation", "SwimIdle"), _cxH.Idle),
        }
        _cwX.tracks = _cxI
        local _cxJ = 16
        local _cxK = nil
        local function _cxL(_cxM, _cxN, _cxO)
            if not _cxM then
                return
            end
            if _cwX.current ~= _cxM then
                if _cwX.current then
                    pcall(function()
                        _cwX.current:Stop(_cxN or 0.15)
                    end)
                end
                _cwX.current = _cxM
                pcall(function()
                    _cxM:Play(_cxN or 0.15)
                end)
            end
            if _cxO then
                _cwX.curBase = _cxO
                pcall(function()
                    _cxM:AdjustSpeed(_cxO * (_cwX.speedMul or 1))
                end)
            end
        end
        local function _cxP(_cxQ)
            if _cxK then
                local _cxR = _cxK
                _cxK = nil
                pcall(function()
                    _cxR:Stop(_cxQ or 0.2)
                end)
            end
        end
        local function _cxS()
            local _cxT = _cxC.RootPart
            if not _cxT then
                return 0
            end
            local _cxU = _cxT.AssemblyLinearVelocity
            return Vector3.new(_cxU.X, 0, _cxU.Z).Magnitude
        end
        local function _cxV(_cxW)
            if _cxB ~= _cwX.token then
                return
            end
            if _cxW > 0.5 then
                if _cxK then
                    _cxP(0.1)
                end
                _cwX.pose = "Running"
                local _cxX = (_cxW > 9 and _cxI.run) or _cxI.walk or _cxI.run
                _cxL(_cxX, 0.15, _cxW / _cxJ)
            elseif _cxK then
                return
            elseif _cwX.pose ~= "Jumping" and _cwX.pose ~= "FreeFall" then
                _cwX.pose = "Standing"
                _cxL(_cxI.idle, 0.2, 1)
            end
        end
        local function _cxY()
            if _cxB ~= _cwX.token then
                return
            end
            _cxP(0.1)
            _cwX.pose = "Jumping"
            _cxL(_cxI.jump or _cxI.fall, 0.1, 1)
        end
        local function _cxZ(_cya)
            if _cxB ~= _cwX.token then
                return
            end
            if _cya then
                _cxP(0.1)
                _cwX.pose = "FreeFall"
                _cxL(_cxI.fall or _cxI.jump, 0.25, 1)
            else
                _cwX.pose = "Landed"
                _cxV(_cxS())
            end
        end
        local function _cyb(_cyc)
            if _cxB ~= _cwX.token then
                return
            end
            _cxP(0.1)
            _cwX.pose = "Climbing"
            _cxL(_cxI.climb, 0.15, _cyc / 5)
        end
        local function _cyd(_cye)
            if _cxB ~= _cwX.token then
                return
            end
            _cwX.pose = "Swimming"
            if math.abs(_cye or 0) > 1 then
                _cxL(_cxI.swim, 0.2, 1)
            else
                _cxL(_cxI.swimidle or _cxI.swim, 0.2, 1)
            end
        end
        local function _cyf(_cyg)
            local _cyh
            if typeof(_cyg) == "Instance" and _cyg:IsA("Animation") then
                _cyh = _cyg.AnimationId:match("%d+")
            elseif type(_cyg) == "string" and _cxE and not tonumber(_cyg) then
                local _cyi = _cxE:FindFirstChild(_cyg)
                if _cyi then
                    local _cyj = _cyi:FindFirstChildOfClass("Animation")
                    if _cyj then
                        return _cyj.AnimationId:match("%d+")
                    end
                end
                return nil
            elseif tonumber(_cyg) then
                _cyh = tostring(tonumber(_cyg))
            end
            if not _cyh then
                return nil
            end
            local _cyk = "e" .. _cyh
            if _cvY[_cyk] then
                return _cvY[_cyk]
            end
            local _cyl = false
            local _cym = __SIEXTHER_VIP_GLASS_V1.Instance.new("Animation")
            _cym.AnimationId = "rbxassetid://" .. _cyh
            local _cyn, _cyo = pcall(function()
                return _cxD:LoadAnimation(_cym)
            end)
            if _cyn and _cyo then
                for _cyp = 1, 8 do
                    if _cyo.Length > 0 then
                        _cyl = true
                        break
                    end
                    task.wait(0.05)
                end
                pcall(function()
                    _cyo:Destroy()
                end)
            end
            if _cyl then
                _cvY[_cyk] = _cyh
                _cwg()
                return _cyh
            end
            local _cyq, _cyr = _LQ.getObjects(_cyh)
            if _cyq and _cyr then
                for _cys, _cyt in ipairs(_cyr) do
                    for _cyu, _cyv in ipairs(_cyt:GetDescendants()) do
                        if _cyv:IsA("Animation") then
                            local _cyw = _cyv.AnimationId:match("%d+")
                            if _cyw then
                                _cvY[_cyk] = _cyw
                                _cwg()
                                return _cyw
                            end
                        end
                    end
                end
            end
            return _cyh
        end
        local function _cyx(_cyy)
            local _cyz = _cyf(_cyy)
            if not _cyz then
                return false
            end
            _cxP(0)
            local _cyA = __SIEXTHER_VIP_GLASS_V1.Instance.new("Animation")
            _cyA.AnimationId = "rbxassetid://" .. _cyz
            local _cyB, _cyC = pcall(function()
                return _cxD:LoadAnimation(_cyA)
            end)
            if not _cyB or not _cyC then
                return false
            end
            _cyC.Priority = Enum.AnimationPriority.Action4
            _cxK = _cyC
            if _cwX.current then
                pcall(function()
                    _cwX.current:Stop(0.15)
                end)
            end
            _cwX.current = nil
            _cwX.pose = "Emote"
            pcall(function()
                _cyC:Play(0.1)
            end)
            pcall(function()
                _cyC.Stopped:Once(function()
                    if _cxK == _cyC then
                        _cxK = nil
                        if _cxB == _cwX.token then
                            _cxV(_cxS())
                        end
                    end
                end)
            end)
            return true
        end
        if _cxE then
            local _cyD = _cxE:FindFirstChild("PlayEmote")
            if _cyD and _cyD:IsA("BindableFunction") then
                pcall(function()
                    _cyD.OnInvoke = function(_cyE)
                        return _cyx(_cyE)
                    end
                end)
            end
        end
        table.insert(_cwX.conns, _jx(_jJ(_cxC, "Running"), _cxV))
        table.insert(_cwX.conns, _jx(_jJ(_cxC, "Jumping"), _cxY))
        table.insert(_cwX.conns, _jx(_jJ(_cxC, "FreeFalling"), _cxZ))
        table.insert(_cwX.conns, _jx(_jJ(_cxC, "Climbing"), _cyb))
        table.insert(_cwX.conns, _jx(_jJ(_cxC, "Swimming"), _cyd))
        table.insert(
            _cwX.conns,
            _jx(_jJ(_cxC, "Seated"), function(_cyF)
                if not _cyF then
                    _cxV(0)
                end
            end)
        )
        table.insert(
            _cwX.conns,
            _jx(_jJ(_cxC, "StateChanged"), function(_cyG, _cyH)
                if _cxB ~= _cwX.token then
                    return
                end
                if
                    _cyH == Enum.HumanoidStateType.Landed
                    or _cyH == Enum.HumanoidStateType.Running
                    or _cyH == Enum.HumanoidStateType.RunningNoPhysics
                then
                    if _cwX.pose == "Jumping" or _cwX.pose == "FreeFall" then
                        _cwX.pose = "Landed"
                        _cxV(_cxS())
                    end
                end
            end)
        )
        _cxL(_cxI.idle, 0.2, 1)
        task.spawn(function()
            while _cxB == _cwX.token do
                if _cxE and not _cxE.Disabled then
                    _cxE.Disabled = true
                end
                local _cyI = _cwX.current
                if _cyI and _cyI.Looped and not _cyI.IsPlaying then
                    pcall(function()
                        _cyI:Play(0.1)
                    end)
                end
                task.wait(0.4)
            end
        end)
        return true
    end
    local function _cyJ(_cyK)
        local _cyL = {}
        if not _cyK then
            return _cyL
        end
        local _cyM = _cyK:FindFirstChild("Animate")
        if not _cyM then
            return _cyL
        end
        local _cyN = {
            idle = "IdleAnimation",
            walk = "WalkAnimation",
            run = "RunAnimation",
            jump = "JumpAnimation",
            fall = "FallAnimation",
            climb = "ClimbAnimation",
            swim = "SwimAnimation",
            swimidle = "SwimAnimation",
        }
        for _cyO, _cyP in ipairs(_cyM:GetChildren()) do
            local _cyQ = _cyN[_cyP.Name:lower()]
            if _cyQ then
                local _cyT = pcall(function()
                    for _cyR, _cyS in ipairs(_cyP:GetDescendants()) do
                        if _cyS:IsA("Animation") and _cyS.AnimationId ~= "" then
                            _cyL[_cyQ] = _cyL[_cyQ] or {}
                            _cyL[_cyQ][_cyS.Name] = _cyS.AnimationId
                        end
                    end
                end)
                if not _cyT then
                end
            end
        end
        return _cyL
    end
    local _cyU = {}
    local _cyV = nil
    local _cyW = _cvU.lastBundleName
    local _cyX = _cvU.lastBundle
    local _cyY
    local function _cyZ()
        local _cza = {}
        for _czb, _czc in pairs(_cyU) do
            local _czd = {}
            for _cze, _czf in pairs(_czc) do
                _czd[_cze] = _czf
            end
            _cza[_czb] = _czd
        end
        if _cyV then
            for _czg, _czh in pairs(_cyV) do
                local _czi = {}
                for _czj, _czk in pairs(_czh) do
                    _czi[_czj] = _czk
                end
                _cza[_czg] = _czi
            end
        end
        for _czl, _czm in pairs(_cvU.stateOverrides or {}) do
            local _czn = _cwk[_czl]
            if _czn and _czm and _czm.id then
                if _czn == "SwimAnimation" then
                    _cza[_czn] = { Swim = _czm.id, SwimIdle = _czm.id }
                else
                    local _czo = _cwl[_czl] or "Animation"
                    _cza[_czn] = { [_czo] = _czm.id }
                end
            end
        end
        return _cza
    end
    local function _czp()
        local _czq = _gV and _gV.Character
        if not _czq then
            return false
        end
        if _cxv(_czq) then
            _cwZ()
            local _czr = _czq:FindFirstChild("Animate")
            if _czr then
                _czr.Disabled = false
            end
            return false
        end
        local _czs = _cyZ()
        if not next(_czs) then
            return false
        end
        return _cxy(_czq, _czs)
    end
    local _czt = setmetatable({}, { __mode = "k" })
    local function _czu(_czv, _czw, _czx)
        local _czy = _gV and _gV.Character
        if not _czy or not _czy:FindFirstChildOfClass("Humanoid") then
            return false, "Character not found."
        end
        local _czz = tostring(_czv)
        local _czA = _czt[_czz]
        if _czA and (os.clock() - _czA) < 30 then
        else
            _czt[_czz] = os.clock()
        end
        if _cxv(_czy) then
            return false,
                "This animation bundle was made for the R15 rig. Applying it on R6 would make your pose stiff/broken, so it was cancelled automatically. Switch to R15 first in the Body tab if you want to use it."
        end
        _czx = _czx or "all"
        local _czC, _czD = _cwv(_czv, _czw, function(_czB)
            if _czx == "all" then
                _cyV = _czB
                _czp()
            end
        end)
        if not _czC then
            return false, "Failed to load bundle animation (ID: " .. tostring(_czv) .. ")"
        end
        if _czx == "all" then
            _cyV = _czC
            if not _czp() then
                return false, "Failed to apply (no Animator)."
            end
            _cyX = tostring(_czv)
            _cyW = (_czD and _czD.Name) or nil
            _cvU.lastBundle = tostring(_czv)
            _cvU.lastBundleName = _cyW
            _cvV()
            if _cyY then
                _cyY()
            end
            return true, "Applied to all states: " .. (_cyW or ("ID " .. _czv))
        end
        local _czE = _cwk[_czx]
        if not _czE then
            return false, "Unknown state: " .. tostring(_czx)
        end
        local _czF = _cxe(_czC, _czE, _cwl[_czx])
        if not _czF then
            return false, (_cwj[_czx] or _czx) .. " not available in this bundle."
        end
        _cvU.stateOverrides = _cvU.stateOverrides or {}
        _cvU.stateOverrides[_czx] = {
            id = tostring(_czF):match("%d+") or tostring(_czF),
            name = (_czD and _czD.Name) or ("ID " .. _czv),
            bundleId = tostring(_czv),
        }
        _cvV()
        if not _czp() then
            return false, "Failed to apply (no Animator)."
        end
        if _cyY then
            _cyY()
        end
        return true, (_cwj[_czx] or _czx) .. " applied from: " .. ((_czD and _czD.Name) or ("ID " .. _czv))
    end
    local function _czG()
        _cyV = nil
        _cyW = nil
        _cyX = nil
        _cvU.lastBundle = nil
        _cvU.lastBundleName = nil
        _cvV()
        _czp()
        if _cyY then
            _cyY()
        end
        return true, "'All' bundle removed. Animations reverted to default/per-state overrides."
    end
    local function _czH()
        _cwZ()
        local _czI = _gV and _gV.Character
        local _czJ = _czI and _czI:FindFirstChild("Animate")
        if _czJ then
            pcall(function()
                _czJ.Disabled = true
                task.wait(0.1)
                _czJ.Disabled = false
            end)
        end
        _cvU.lastBundle = nil
        _cvU.lastBundleName = nil
        _cvU.stateOverrides = {}
        _cyV = nil
        _cyW = nil
        _cyX = nil
        _cvV()
        if _cyY then
            _cyY()
        end
        return true, "Default animation restored."
    end
    local _czK, _czL = nil, nil
    local function _czM()
        if _czL then
            pcall(function()
                _czL:Disconnect()
            end)
            _czL = nil
        end
        if _czK then
            pcall(function()
                _czK:Stop(0.2)
            end)
            _czK = nil
        end
    end
    local function _czN(_czO)
        local _czP = tostring(_czO):match("%d+")
        if not _czP then
            return nil
        end
        local _czQ = "e" .. _czP
        if _cvY[_czQ] then
            return _cvY[_czQ]
        end
        local _czR, _czS = _LQ.getObjects(_czP)
        if _czR and _czS then
            for _czT, _czU in ipairs(_czS) do
                local _czV = { _czU }
                for _czW, _czX in ipairs(_czU:GetDescendants()) do
                    _czV[#_czV + 1] = _czX
                end
                for _czY, _czZ in ipairs(_czV) do
                    if _czZ:IsA("Animation") then
                        local _cAa = _czZ.AnimationId:match("%d+")
                        if _cAa then
                            _cvY[_czQ] = _cAa
                            _cwg()
                            return _cAa
                        end
                    end
                end
            end
        end
        return _czP
    end
    local function _cAb(_cAc, _cAd, _cAe)
        local _cAf = _gV and _gV.Character
        local _cAg = _cAf and _cAf:FindFirstChildOfClass("Humanoid")
        local _cAh = _cAg and _cAg:FindFirstChildOfClass("Animator")
        if not _cAh then
            return false, "Character not found."
        end
        if _cxv(_cAf) then
            return false,
                "This catalog emote was made for the R15 rig and would break the pose on R6, so it was cancelled automatically."
        end
        local _cAi = _czN(_cAc)
        if not _cAi then
            return false, "Failed to load emote."
        end
        _czM()
        local _cAj = __SIEXTHER_VIP_GLASS_V1.Instance.new("Animation")
        _cAj.AnimationId = "rbxassetid://" .. _cAi
        local _cAk, _cAl = pcall(function()
            return _cAh:LoadAnimation(_cAj)
        end)
        if not _cAk or not _cAl then
            return false, "Failed to load emote."
        end
        _cAl.Priority = Enum.AnimationPriority.Action4
        _cAl.Looped = true
        _czK = _cAl
        pcall(function()
            _cAl:Play(0.15)
        end)
        pcall(function()
            _cAl:AdjustSpeed(_cvU.emoteSpeed or 1)
        end)
        if not _cAe then
            _czL = _jx(_jJ(_cAg, "Running"), function(_cAm)
                if not _cvU.emoteHold and _cAm and _cAm > 0.5 then
                    _czM()
                end
            end)
        end
        return true, "Memutar emote: " .. (_cAd or ("ID " .. _cAi))
    end
    local function _cAn()
        if _czK then
            pcall(function()
                _czK:AdjustSpeed(_cvU.emoteSpeed or 1)
            end)
        end
    end
    if _gV then
        _jx(_jJ(_gV, "CharacterAdded"), function(_cAo)
            task.spawn(function()
                pcall(function()
                    _cAo:WaitForChild("Humanoid", 10)
                end)
                task.wait(1)
                _cyU = _cyJ(_cAo)
                if _cvU.lastBundle then
                    _czu(tonumber(_cvU.lastBundle))
                else
                    _czp()
                end
            end)
        end)
    end
    local _cAp =
        _cvS:CreateSection("Animations", "Change idle/walk/run/emote animations via official Roblox bundles")
    local _cAq = _cAp.Accent or _kA.Accent
    local _cAr = Color3.fromRGB(190, 190, 190)
    local _cAs = _kA.Home.Tile
    local _cAt = 0.35
    local _cAu, _cAv, _cAw = _kA.Btn.Bg, _kA.Btn.Active, Color3.fromRGB(170, 170, 170)
    local function _cAx(_cAy)
        return nil
    end
    local _cAz = _cAp.Body
    if not _cAz then
        return
    end
    local _cAA = {
        { key = "bundle", label = "Bundles" },
        { key = "emote", label = "Emotes" },
        { key = "settings", label = "Settings" },
    }
    local _cAB
    local _cAD = _sv.SubTabs(_cAz, _cAA, function(_cAC)
        _cAB(_cAC)
    end, { Scroll = true, Spinner = true, LayoutOrder = -9, Default = "bundle" })
    local _cAE = _qz(
        "Frame",
        { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = _cAs, BackgroundTransparency = _cAt, Parent = _cAz }
    )
    _sf(_cAE, 10)
    local _cAF = _so(_cAE, _cAr, 1, _kA.Home.EdgeRest)
    local _cAG = _qz(
        "Frame",
        {
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 12, 0.5, -8),
            BackgroundTransparency = 1,
            Parent = _cAE,
        }
    )
    _sv.DrawSearch(_cAG, 16)
    local _cAH = _qz(
        "TextBox",
        {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 36, 0, 0),
            Size = UDim2.new(1, -206, 1, 0),
            Font = Enum.Font.GothamMedium,
            Text = "",
            PlaceholderText = "Search bundle",
            TextColor3 = _kA.Text,
            PlaceholderColor3 = _kA.TextMuted,
            TextSize = 12,
            ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = _cAE,
        }
    )
    _jx(_jJ(_cAH, "Focused"), function()
        _ry(_cAF, 0.15, nil, nil, { Color = _cAr, Transparency = _kA.Home.EdgeActive })
    end)
    _jx(_jJ(_cAH, "FocusLost"), function()
        _ry(_cAF, 0.22, nil, nil, { Color = _cAr, Transparency = _kA.Home.EdgeRest })
    end)
    local _cAI = _qz(
        "TextButton",
        {
            Position = UDim2.new(1, -66, 0.5, -12),
            Size = UDim2.new(0, 58, 0, 24),
            Font = Enum.Font.GothamBold,
            Text = "SEARCH",
            TextSize = 9,
            Parent = _cAE,
        }
    )
    _sf(_cAI, 8)
    _sv.HomeBtn(_cAI)
    local _cAJ, _cAK, _cAL, _cAM, _cAN, _cAO
    do
        local _cAP = _qz(
            "Frame",
            {
                AutomaticSize = _cv or Enum.AutomaticSize.X,
                Size = UDim2.new(0, 0, 0, 24),
                Position = UDim2.new(1, -78, 0.5, -12),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Parent = _cAE,
            }
        )
        _qz(
            "UIListLayout",
            {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 6),
                VerticalAlignment = Enum.VerticalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = _cAP,
            }
        )
        _cAJ = _AI(_cAP, _cAq, 4)
        _cAK = _zM(_cAP, _cAz, _cAq)
        _cAL = _cAK.MinPriceBox
        _cAM = _cAK.MaxPriceBox
        _cAN = _cAK.CreatorBox
        _cAO = _cAK.ApplyBtn
    end
    local function _cAQ(_cAR)
        local _cAS = tonumber(_cAL and _cAL.Text or "")
        if _cAS then
            pcall(function()
                _cAR.MinPrice = math.max(0, math.floor(_cAS))
            end)
        end
        local _cAT = tonumber(_cAM and _cAM.Text or "")
        if _cAT then
            pcall(function()
                _cAR.MaxPrice = math.max(0, math.floor(_cAT))
            end)
        end
        local _cAU = (_cAN and _cAN.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if _cAU ~= "" then
            pcall(function()
                _cAR.CreatorName = _cAU
            end)
        end
        local _cAV = _cAK.GetSort and _cAK.GetSort()
        if _cAV then
            local _cAW = _zl(Enum.CatalogSortType, _cAV.names)
            if _cAW then
                pcall(function()
                    _cAR.SortType = _cAW
                end)
            end
        end
        local _cAX = _cAK.GetCreatorType and _cAK.GetCreatorType()
        if _cAX and #_cAX.names > 0 then
            local _cAY = _zl(Enum.CatalogCreatorType, _cAX.names)
            if _cAY then
                pcall(function()
                    _cAR.CreatorType = _cAY
                end)
            end
        end
        if _cAK.GetOffSale then
            pcall(function()
                _cAR.IncludeOffSale = _cAK.GetOffSale()
            end)
        end
    end
    local _cAZ = 1
    local function _cBa()
        return _cwi[_cAZ]
    end
    local _cBb = _qz(
        "Frame",
        { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = _cAs, BackgroundTransparency = _cAt, Parent = _cAz }
    )
    _sf(_cBb, 10)
    _qz(
        "TextLabel",
        {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(0, 64, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = "APPLY TO",
            TextColor3 = _kA.Home.Muted,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = _cBb,
        }
    )
    local function _cBc(_cBd, _cBe)
        local _cBf = _qz(
            "TextButton",
            {
                BackgroundColor3 = _cAs,
                BackgroundTransparency = _cAt,
                Position = _cBe,
                Size = UDim2.new(0, 24, 0, 24),
                AutoButtonColor = false,
                Font = Enum.Font.GothamBold,
                Text = _cBd,
                TextColor3 = _kA.SubText,
                TextSize = 16,
                Visible = false,
                Parent = _cBb,
            }
        )
        return _cBf
    end
    local _cBg = _cBc(_kF.ARROW_L, UDim2.new(0, 74, 0.5, -12))
    local _cBh = _qz(
        "TextLabel",
        {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 80, 0, 0),
            Size = UDim2.new(1, -160, 1, 0),
            Font = Enum.Font.GothamMedium,
            Text = "",
            TextColor3 = _kA.Text,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = _cBb,
        }
    )
    local _cBi = _cBc(_kF.ARROW_R, UDim2.new(1, -100, 0.5, -12))
    local _cBj = _qz(
        "TextButton",
        {
            Position = UDim2.new(1, -70, 0.5, -12),
            Size = UDim2.new(0, 62, 0, 24),
            Font = Enum.Font.GothamBold,
            Text = "CLEAR",
            TextSize = 9,
            Visible = false,
            Parent = _cBb,
        }
    )
    _sf(_cBj, 8)
    _sv.HomeBtn(_cBj)
    local _cBk = _qz("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Parent = _cAz })
    _qz(
        "UIListLayout",
        {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = _cBk,
        }
    )
    local _cBl = {
        all = "All",
        idle = "Idle",
        walk = "Walk",
        run = "Run",
        jump = "Jump",
        fall = "Fall",
        climb = "Climb",
        swim = "Swim",
    }
    local _cBm, _cBn, _cBo = {}, {}, {}
    local _cBp = #_cwi
    for _cBq, _cBr in ipairs(_cwi) do
        local _cBs = _qz(
            "TextButton",
            {
                Size = UDim2.new(1 / _cBp, -(4 * (_cBp - 1)) / _cBp, 1, 0),
                BackgroundColor3 = _cAs,
                BackgroundTransparency = _cAt,
                AutoButtonColor = false,
                Font = Enum.Font.GothamBold,
                Text = _cBl[_cBr] or _cBr,
                TextColor3 = _kA.Home.Muted,
                TextSize = 10,
                LayoutOrder = _cBq,
                Parent = _cBk,
            }
        )
        _sf(_cBs, 8)
        local _cBt = _so(_cBs, _cAr, 1, 1)
        _jx(_jJ(_cBs, "MouseEnter"), function()
            if _cAZ ~= _cBq then
                _ry(_cBt, 0.14, nil, nil, { Transparency = _kA.Home.EdgeRest })
            end
        end)
        _jx(_jJ(_cBs, "MouseLeave"), function()
            if _cAZ ~= _cBq then
                _ry(_cBt, 0.2, nil, nil, { Transparency = 1 })
            end
        end)
        local _cBu = _qz(
            "Frame",
            {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -5, 0, 5),
                Size = UDim2.new(0, 5, 0, 5),
                BackgroundColor3 = _kA.Success,
                BorderSizePixel = 0,
                Visible = false,
                Parent = _cBs,
            }
        )
        _sf(_cBu, 100)
        _cBm[_cBq] = _cBs
        _cBn[_cBq] = _cBt
        _cBo[_cBq] = _cBu
        _jx(_jJ(_cBs, "MouseButton1Click"), function()
            _cAZ = _cBq
            _cyY()
        end)
    end
    _cyY = function()
        local _cBv = _cBa()
        local _cBw = _cwj[_cBv] or _cBv
        if _cBv == "all" then
            if _cyW or _cyX then
                _cBh.Text = _cBw
                    .. " "
                    .. _kF.MIDDOT
                    .. " "
                    .. tostring(_cyW or "Bundle")
                    .. (_cyX and (" [ID: " .. tostring(_cyX) .. "]") or "")
            else
                _cBh.Text = _cBw
            end
            _cBj.Visible = (_cyW ~= nil or _cyX ~= nil)
        else
            local _cBx = _cvU.stateOverrides and _cvU.stateOverrides[_cBv]
            if _cBx then
                _cBh.Text = _cBw
                    .. " "
                    .. _kF.MIDDOT
                    .. " "
                    .. tostring(_cBx.name)
                    .. (_cBx.id and (" [ID: " .. tostring(_cBx.id) .. "]") or "")
            else
                local _cBy = _cwk[_cBv]
                local _cBz = _cBy and _cyV and _cyV[_cBy] and next(_cyV[_cBy])
                local _cBA = _cBy and _cyU[_cBy] and next(_cyU[_cBy])
                if _cBz and _cyW then
                    _cBh.Text = _cBw .. " " .. _kF.MIDDOT .. " from Bundle: " .. tostring(_cyW)
                elseif _cBA then
                    _cBh.Text = _cBw .. " " .. _kF.MIDDOT .. " Bawaan Roblox (terdeteksi)"
                else
                    _cBh.Text = _cBw .. " " .. _kF.MIDDOT .. " empty"
                end
            end
            _cBj.Visible = _cBx ~= nil
        end
        if _cBm then
            for _cBB, _cBC in ipairs(_cBm) do
                local _cBD = _cwi[_cBB]
                local _cBE
                if _cBD == "all" then
                    _cBE = (_cyW ~= nil or _cyX ~= nil)
                else
                    _cBE = (_cvU.stateOverrides and _cvU.stateOverrides[_cBD]) ~= nil
                end
                local _cBF = (_cBB == _cAZ)
                _ry(
                    _cBC,
                    0.16,
                    nil,
                    nil,
                    {
                        BackgroundColor3 = _cBF and _kA.ElementActive or _cAs,
                        BackgroundTransparency = _cBF and 0 or _cAt,
                        TextColor3 = _cBF and _kA.Text or (_cBE and _kA.SubText or _kA.Home.Muted),
                    }
                )
                if _cBn[_cBB] then
                    _ry(
                        _cBn[_cBB],
                        0.16,
                        nil,
                        nil,
                        { Color = _cAr, Transparency = _cBF and _kA.Home.EdgeActive or 1 }
                    )
                end
                if _cBo[_cBB] then
                    _cBo[_cBB].Visible = _cBE
                end
            end
        end
    end
    do
        local _cBG = _gV and _gV.Character
        if _cBG then
            _cyU = _cyJ(_cBG)
        end
    end
    _jx(_jJ(_cBg, "MouseButton1Click"), function()
        _cAZ = _cAZ - 1
        if _cAZ < 1 then
            _cAZ = #_cwi
        end
        _cyY()
    end)
    _jx(_jJ(_cBi, "MouseButton1Click"), function()
        _cAZ = _cAZ + 1
        if _cAZ > #_cwi then
            _cAZ = 1
        end
        _cyY()
    end)
    _jx(_jJ(_cBj, "MouseButton1Click"), function()
        local _cBH = _cBa()
        if _cBH == "all" then
            local _cBI, _cBJ = _czG()
            setStatus(_cBJ, not _cBI)
            return
        end
        if not _cvU.stateOverrides then
            return
        end
        _cvU.stateOverrides[_cBH] = nil
        _cvV()
        if _czp then
            _czp()
        end
        _cyY()
        setStatus(_cwj[_cBH] .. " reverted to default.", false)
    end)
    _cyY()
    local _cBK = _qz(
        "Frame",
        {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = _cu or Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Visible = false,
            Parent = _cAz,
        }
    )
    _qz("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = _cBK })
    local _cBL
    local _cBM = _qz(
        "Frame",
        { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = _cAs, BackgroundTransparency = _cAt, Parent = _cAz }
    )
    _sf(_cBM, 10)
    local _cBN = _qz(
        "Frame",
        {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 12, 0.5, 0),
            Size = UDim2.new(0, 6, 0, 6),
            BackgroundColor3 = _kA.Home.Muted,
            Parent = _cBM,
        }
    )
    _qz("UICorner", { CornerRadius = UDim.new(1, 0), Parent = _cBN })
    local _cBO = _qz(
        "TextLabel",
        {
            Position = UDim2.new(0, 26, 0, 0),
            Size = UDim2.new(1, -38, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            Text = "Search a bundle or pick a state to begin.",
            TextColor3 = _kA.Home.Muted,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = _cBM,
        }
    )
    local function _cBP(_cBQ, _cBR)
        pcall(function()
            local _cBS = tostring(_cBQ or "")
            _cBO.Text = (_cBS ~= "") and _cBS or "Ready."
            _cBO.TextColor3 = _cBR and _kA.Danger or _kA.SubText
            _cBN.BackgroundColor3 = _cBR and _kA.Danger or ((_cBS ~= "") and _kA.Success or _kA.Home.Muted)
        end)
    end
    local _cBT = _qz(
        "ScrollingFrame",
        {
            Size = UDim2.new(1, 0, 0, 300),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = _cAq,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = _cu or Enum.AutomaticSize.Y,
            ClipsDescendants = true,
            Parent = _cAz,
        }
    )
    local function _cBU()
        local _cBV = _qz(
            "Frame",
            {
                Position = UDim2.new(0, 4, 0, 4),
                Size = UDim2.new(0, 100, 0, 0),
                AutomaticSize = _cu or Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = _cBT,
            }
        )
        local function _cBW()
            local _cBX = 0
            pcall(function()
                _cBX = _cBT.AbsoluteWindowSize.X
            end)
            if _cBX > 20 then
                pcall(function()
                    _cBV.Size = UDim2.new(0, _cBX - 14, 0, 0)
                end)
            end
        end
        _cBW()
        local _cBY = {}
        for _cBZ, _cCa in ipairs({ "AbsoluteWindowSize", "AbsoluteSize" }) do
            local _cCb, _cCc = pcall(function()
                return _cBT:GetPropertyChangedSignal(_cCa)
            end)
            if _cCb and _cCc then
                local _cCd = _jx(_cCc, _cBW)
                if _cCd then
                    _cBY[#_cBY + 1] = _cCd
                end
            end
        end
        pcall(function()
            _cBV.Destroying:Connect(function()
                for _cCe, _cCf in ipairs(_cBY) do
                    pcall(function()
                        _cCf:Disconnect()
                    end)
                end
            end)
        end)
        local _cCg = _qz(
            "UIGridLayout",
            { SortOrder = Enum.SortOrder.LayoutOrder, CellPadding = _zj, CellSize = _cAJ.GetCellSize(), Parent = _cBV }
        )
        _cAJ.RegisterGrid(_cCg)
        return _cBV
    end
    local function _cCh()
        for _cCi, _cCj in ipairs(_cBT:GetChildren()) do
            if _cCj:IsA("GuiObject") then
                local _cCk = false
                if _cBL then
                    for _cCl, _cCm in pairs(_cBL) do
                        if _cCm.activeHolder == _cCj then
                            _cCk = true
                            break
                        end
                    end
                end
                if _cCk then
                    _cCj.Parent = nil
                else
                    pcall(function()
                        _cCj:Destroy()
                    end)
                end
            end
        end
        pcall(function()
            _cBT.CanvasPosition = Vector2.new(0, 0)
        end)
    end
    local function _cCn(_cCo, _cCp, _cCq)
        local _cCr = _cCo.Price or _cCo.LowestPrice
        local _cCs
        if _cCo.IsForSale == false and not _cCr then
            _cCs = "Off sale"
        elseif _cCr == nil then
            _cCs = "--"
        elseif tonumber(_cCr) == 0 then
            _cCs = "Free"
        else
            _cCs = "R$ " .. tostring(_cCr)
        end
        local _cCt = _cCo.CreatorName and tostring(_cCo.CreatorName) or ""
        if _cCt ~= "" then
            _cCs = _cCs .. " " .. _kF.MIDDOT .. " " .. _cCt
            if _cCo.CreatorHasVerifiedBadge then
                _cCs = _cCs .. " " .. _kF.CHECK
            end
        end
        return _qz(
            "TextLabel",
            {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 8, 0, _cCq),
                Size = UDim2.new(1, -16, 0, 12),
                Font = Enum.Font.Gotham,
                Text = _cCs,
                TextColor3 = _kA.SubText,
                TextSize = 9,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = _cCp,
            }
        )
    end
    local _cCu = setmetatable({ Body = _cBK, Accent = _cAq }, _CB)
    local function _cCv(_cCw)
        local _cCx, _cCy = pcall(_cCw)
        if not _cCx then
            warn("[SIEXTHER] Animation settings element failed:", _cCy)
        end
    end
    _cCv(function()
        _cCu:CreateSlider({
            Title = "Animation Speed",
            Subtitle = "Idle/walk/run playback speed (50% - 200%)",
            Min = 50,
            Max = 200,
            Step = 5,
            Default = math.floor((_cvU.speed or 1) * 100 + 0.5),
            Callback = function(_cCz)
                _cvU.speed = _cCz / 100
                _cwX.speedMul = _cvU.speed
                _cwY()
                _cvV()
            end,
        })
    end)
    _cCv(function()
        _cCu:CreateSlider({
            Title = "Emote Speed",
            Subtitle = "Playback speed for catalog emotes (50% - 200%)",
            Min = 50,
            Max = 200,
            Step = 5,
            Default = math.floor((_cvU.emoteSpeed or 1) * 100 + 0.5),
            Callback = function(_cCA)
                _cvU.emoteSpeed = _cCA / 100
                _cAn()
                _cvV()
            end,
        })
    end)
    _cCv(function()
        _cCu:CreateToggle({
            Title = "Auto-load Last Bundle",
            Subtitle = "Re-apply your animations after respawn and on startup",
            Default = _cvU.autoLoad == true,
            Callback = function(_cCB)
                _cvU.autoLoad = _cCB == true
                _cvV()
            end,
        })
    end)
    _cCv(function()
        _cCu:CreateToggle({
            Title = "Hold Emote While Moving",
            Subtitle = "Keep the emote playing when you walk",
            Default = _cvU.emoteHold == true,
            Callback = function(_cCC)
                _cvU.emoteHold = _cCC == true
                _cvV()
            end,
        })
    end)
    _cCv(function()
        _cCu:CreateButton({
            Title = "Stop Emote",
            Subtitle = "Stop the emote currently playing",
            ButtonText = "Stop",
            Callback = function()
                _czM()
            end,
        })
    end)
    _cCv(function()
        _cCu:CreateButton({
            Title = "Reset Animations",
            Subtitle = "Restore the default Roblox animations",
            ButtonText = "Reset",
            Callback = function()
                local _cCD, _cCE = _czH()
                _cBP(_cCE, false)
            end,
        })
    end)
    local function _cCF(_cCG, _cCH, _cCI)
        local _cCJ = _cCG.Id
        local _cCK = _qz(
            "Frame",
            { BackgroundColor3 = _cAs, BackgroundTransparency = _cAt, ClipsDescendants = true, Parent = _cCI }
        )
        _sf(_cCK, 10)
        local _cCL = _so(_cCK, _cAr, 1, _kA.Home.EdgeRest)
        _jx(_jJ(_cCK, "MouseEnter"), function()
            _ry(_cCK, 0.14, nil, nil, { BackgroundTransparency = 0.1 })
            _ry(_cCL, 0.14, nil, nil, { Color = _cAr, Transparency = _kA.Home.EdgeHover })
        end)
        _jx(_jJ(_cCK, "MouseLeave"), function()
            _ry(_cCK, 0.22, nil, nil, { BackgroundTransparency = _cAt })
            _ry(_cCL, 0.22, nil, nil, { Color = _cAr, Transparency = _kA.Home.EdgeRest })
        end)
        local _cCM = _cCH == "emote" and ("rbxthumb://type=Asset&id=%s&w=150&h=150"):format(_cCJ)
            or ("rbxthumb://type=BundleThumbnail&id=%s&w=150&h=150"):format(_cCJ)
        local _cCN = _qz(
            "ImageLabel",
            {
                BackgroundColor3 = _kA.GlassLight,
                BackgroundTransparency = 0,
                Position = UDim2.new(0, 6, 0, 6),
                Size = UDim2.new(1, -12, 0, 58),
                ScaleType = Enum.ScaleType.Fit,
                Parent = _cCK,
            }
        )
        _Be(_cCN, _cCM)
        _sf(_cCN, 8)
        _qz(
            "TextLabel",
            {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 8, 0, 68),
                Size = UDim2.new(1, -16, 0, 14),
                Font = Enum.Font.GothamMedium,
                Text = _cCG.Name or ((_cCH == "emote" and "Emote " or "Bundle ") .. _cCJ),
                TextColor3 = _kA.Text,
                TextSize = 10,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                Parent = _cCK,
            }
        )
        _cCn(_cCG, _cCK, 84)
        local _cCO = _qz(
            "TextButton",
            {
                Position = UDim2.new(0, 6, 1, -27),
                Size = UDim2.new(1, -12, 0, 22),
                Font = Enum.Font.GothamBold,
                Text = _cCH == "emote" and "PLAY" or "APPLY",
                TextSize = 9,
                Parent = _cCK,
            }
        )
        _sf(_cCO, 8)
        _sv.HomeBtn(_cCO)
        _jx(_jJ(_cCO, "MouseButton1Click"), function()
            local _cCP = _cBa()
            if _cCH == "emote" then
                task.spawn(function()
                    if _cCP == "all" then
                        _cBP("Memutar emote...", false)
                        local _cCQ, _cCR = _cAb(tonumber(_cCJ), _cCG.Name)
                        _cBP(_cCR, not _cCQ)
                        return
                    end
                    _cBP("Applying to " .. (_cwj[_cCP] or _cCP) .. ": " .. tostring(_cCG.Name or _cCJ), false)
                    local _cCS = _czN(_cCJ)
                    if not _cCS then
                        _cBP("Failed to load animation.", true)
                        return
                    end
                    _cvU.stateOverrides = _cvU.stateOverrides or {}
                    _cvU.stateOverrides[_cCP] = {
                        id = tostring(_cCS):match("%d+") or tostring(_cCS),
                        name = _cCG.Name or ("Emote " .. tostring(_cCJ)),
                    }
                    _cvV()
                    local _cCT = _czp()
                    _cBP(
                        _cCT
                                and ((_cwj[_cCP] or _cCP) .. " applied from: " .. (_cCG.Name or ("Emote " .. tostring(
                                    _cCJ
                                ))))
                            or "Failed to apply (no Animator).",
                        not _cCT
                    )
                    if _cCT and _cyY then
                        _cyY()
                    end
                end)
            else
                task.spawn(function()
                    local _cCU = not _cwt(_cCJ)
                    _cBP(
                        _cCU and "Loading animation for the first time (faster next time)..."
                            or ("Applying to " .. (_cwj[_cCP] or _cCP) .. ": " .. tostring(_cCG.Name or _cCJ)),
                        false
                    )
                    local _cCX, _cCY = _czu(tonumber(_cCJ), (_cCU and function(_cCV, _cCW)
                        _cBP(("Loading animation... %d/%d"):format(_cCV, _cCW), false)
                    end or nil), _cCP)
                    _cBP(_cCY, not _cCX)
                    if _cCX and _cyY then
                        _cyY()
                    end
                end)
            end
        end)
    end
    _cBL = {
        bundle = { pages = nil, count = 0, activeHolder = nil, loadingMore = false, kind = "bundle" },
        emote = { pages = nil, count = 0, activeHolder = nil, loadingMore = false, kind = "emote" },
    }
    local _cCZ = "bundle"
    local function _cDa(_cDb, _cDc)
        local _cDd = _cBL[_cDb]
        if not _cDd.activeHolder then
            _cDd.activeHolder = _cBU()
        end
        for _cDe, _cDf in ipairs(_cDc) do
            _cDd.count = _cDd.count + 1
            _cCF(
                {
                    Id = _cDf.Id,
                    Name = _cDf.Name,
                    Price = _cDf.Price,
                    LowestPrice = _cDf.LowestPrice,
                    CreatorName = _cDf.CreatorName,
                    IsForSale = _cDf.IsForSale,
                    CreatorHasVerifiedBadge = _cDf.CreatorHasVerifiedBadge,
                },
                _cDd.kind,
                _cDd.activeHolder
            )
        end
    end
    local _cDg = 0
    local _cDh = {}
    local _cDi = 0.7
    local _cDj = { 1, 2, 4, 8 }
    local _cDk = {}
    local function _cDl(_cDm)
        local _cDn = _cDk[_cDm]
        if not _cDn then
            return
        end
        local _cDo = _cBL[_cDm]
        local _cDp, _cDq = pcall(function()
            return _cDo.pages and _cDo.pages.IsFinished
        end)
        local _cDr = _cDp and _cDq
        pcall(function()
            _cDn.Visible = (_cDo.pages ~= nil) and not _cDr and (_cCZ == _cDm)
            _cDn.Text = _cDo.loadingMore and "LOADING..."
                or ("LOAD MORE  " .. _kF.MIDDOT .. "  " .. tostring(_cDo.count) .. " ITEMS")
        end)
    end
    local function _cDs(_cDt)
        local _cDu = _cBL[_cDt]
        if _cDu.loadingMore or not _cDu.pages then
            return
        end
        local _cDv, _cDw = pcall(function()
            return _cDu.pages.IsFinished
        end)
        if _cDv and _cDw then
            _cBP(
                _kF.CHECK
                    .. " All "
                    .. tostring(_cDu.count)
                    .. " "
                    .. (_cDu.kind == "emote" and "emote" or "bundle")
                    .. " loaded.",
                false
            )
            _cDl(_cDt)
            return
        end
        local _cDx = os.clock()
        if _cDx - _cDg < _cDi then
            return
        end
        _cDh[_cDt] = _cDh[_cDt] or 0
        _cDu.loadingMore = true
        _cDl(_cDt)
        _cBP("Loading more...", false)
        task.spawn(function()
            _cDg = os.clock()
            local _cDy = pcall(function()
                _jS()
                _cDu.pages:AdvanceToNextPageAsync()
            end)
            if not _cDy then
                _cDh[_cDt] = math.min(_cDh[_cDt] + 1, #_cDj)
                local _cDz = _cDj[_cDh[_cDt]]
                _cBP((_kF.WARNING .. " Rate limit! Retry in " .. _cDz .. "s..."), true)
                task.wait(_cDz)
                _cDu.loadingMore = false
                _cDg = os.clock()
                _cDl(_cDt)
                if _cDh[_cDt] < #_cDj then
                    _cDs(_cDt)
                else
                    _cBP("✕ Failed after several retries. Try again manually.", true)
                    _cDh[_cDt] = 0
                end
                return
            end
            _cDh[_cDt] = 0
            local _cDA, _cDB = pcall(function()
                return _cDu.pages:GetCurrentPage()
            end)
            _cDu.loadingMore = false
            if _cDA and _cDB then
                _cDa(_cDt, _cDB)
                local _cDC, _cDD = pcall(function()
                    return _cDu.pages.IsFinished
                end)
                if _cDC and _cDD then
                    _cBP(
                        _kF.CHECK
                            .. " All "
                            .. tostring(_cDu.count)
                            .. " "
                            .. (_cDu.kind == "emote" and "emote" or "bundle")
                            .. " loaded.",
                        false
                    )
                else
                    _cBP(
                        ("%s loaded: %d"):format(_cDu.kind == "emote" and "Emotes" or "Bundles", _cDu.count),
                        false
                    )
                end
            end
            _cDl(_cDt)
        end)
    end
    local function _cDE(_cDF, _cDG)
        local _cDH = _cBL[_cDF]
        _cDH.pages, _cDH.count, _cDH.activeHolder, _cDH.loadingMore = nil, 0, nil, false
        _cDh[_cDF] = 0
        _cDg = 0
        _cCh()
        for _cDI, _cDJ in pairs(_cDk) do
            pcall(function()
                _cDJ.Visible = false
            end)
        end
        _cBP(
            _cDG ~= "" and ("Searching «" .. _cDG .. "»...")
                or (_kF.STAR4 .. " Memuat " .. (_cDH.kind == "emote" and "emotes" or "bundles") .. "..."),
            false
        )
        if not _cvT then
            _cBP("AvatarEditorService is not available on this executor.", true)
            return
        end
        task.spawn(function()
            task.wait(0.15)
            local _cDM, _cDN = pcall(function()
                local _cDK = CatalogSearchParams.new()
                if _cDG and _cDG ~= "" then
                    _cDK.SearchKeyword = _cDG
                    pcall(function()
                        _cDK.SortType = Enum.CatalogSortType.Relevance
                    end)
                else
                    local _cDL = pcall(function()
                        _cDK.SortType = Enum.CatalogSortType.Featured
                    end)
                    if not _cDL then
                        pcall(function()
                            _cDK.SortType = Enum.CatalogSortType.MostFavorited
                        end)
                    end
                end
                if _cDF == "emote" then
                    _cDK.AssetTypes = { Enum.AvatarAssetType.EmoteAnimation }
                else
                    _cDK.BundleTypes = { Enum.BundleType.Animations }
                end
                _cAQ(_cDK)
                return _cDK
            end)
            if not _cDM then
                _cBP("Failed to build search parameters.", true)
                return
            end
            local _cDO, _cDP = pcall(function()
                _jS()
                return _cvT:SearchCatalog(_cDN)
            end)
            if not _cDO or not _cDP then
                _cBP("Search failed (rate limit?). Wait a moment then try again.", true)
                return
            end
            _cDH.pages = _cDP
            _cDg = os.clock()
            local _cDQ, _cDR = pcall(function()
                return _cDP:GetCurrentPage()
            end)
            if _cDQ and _cDR then
                _cDa(_cDF, _cDR)
                local _cDS = _cDG ~= "" and ("Result: " .. tostring(_cDH.count))
                    or (_kF.STAR4 .. " " .. tostring(_cDH.count))
                _cBP(_cDS .. " " .. (_cDH.kind == "emote" and "emote" or "bundle"), false)
            end
            _cDl(_cDF)
        end)
    end
    local _cDT = 0
    _cAB = function(_cDU)
        _cCZ = _cDU
        local _cDV = _cDU == "bundle" or _cDU == "emote"
        _jO(_cAE, "Visible", _cDV)
        _jO(_cBO, "Visible", _cDV)
        _jO(_cBT, "Visible", _cDU == "bundle" or _cDU == "emote")
        _jO(_cBK, "Visible", _cDU == "settings")
        for _cDW in pairs(_cDk) do
            if _cDW == _cDU then
                _cDl(_cDW)
            else
                pcall(function()
                    _cDk[_cDW].Visible = false
                end)
            end
        end
        _cDT = _cDT + 1
        local _cDX = _cDT
        _cAD.Lock(true)
        if _cDU == "bundle" or _cDU == "emote" then
            _cAH.PlaceholderText = _cDU == "emote" and "Search emote" or "Search bundle"
            if not _cBL[_cDU].pages then
                _cBP("Loading " .. (_cDU == "emote" and "emote" or "bundle") .. "...", false)
                task.spawn(function()
                    task.wait(0.2)
                    if _cDT ~= _cDX then
                        return
                    end
                    _cDE(_cDU, "")
                    if _cDT == _cDX then
                        _cAD.Lock(false)
                    end
                end)
            else
                _cCh()
                if _cBL[_cDU].activeHolder then
                    pcall(function()
                        _cBL[_cDU].activeHolder.Parent = _cBT
                    end)
                end
                _cBP(
                    (
                        _kF.STAR4
                        .. " "
                        .. tostring(_cBL[_cDU].count)
                        .. " "
                        .. (_cDU == "emote" and "emote" or "bundle")
                        .. " loaded"
                    ),
                    false
                )
                _cDl(_cDU)
                task.delay(0.25, function()
                    if _cDT == _cDX then
                        _cAD.Lock(false)
                    end
                end)
            end
        else
            _cCh()
            task.delay(0.25, function()
                if _cDT == _cDX then
                    _cAD.Lock(false)
                end
            end)
        end
    end
    local function _cDY()
        if _cCZ ~= "bundle" and _cCZ ~= "emote" then
            return
        end
        _cDE(_cCZ, _cAH.Text or "")
    end
    _jx(_jJ(_cAI, "MouseButton1Click"), _cDY)
    _jx(_jJ(_cAH, "FocusLost"), function(_cDZ)
        if _cDZ then
            _cDY()
        end
    end)
    _jx(_jJ(_cAO, "MouseButton1Click"), _cDY)
    _jx(_jJ(_cAL, "FocusLost"), function(_cEa)
        if _cEa then
            _cDY()
        end
    end)
    _jx(_jJ(_cAM, "FocusLost"), function(_cEb)
        if _cEb then
            _cDY()
        end
    end)
    _jx(_jJ(_cAN, "FocusLost"), function(_cEc)
        if _cEc then
            _cDY()
        end
    end)
    for _cEd, _cEe in ipairs({ "bundle", "emote" }) do
        local _cEf = _qz(
            "TextButton",
            {
                Size = UDim2.new(1, 0, 0, 30),
                Font = Enum.Font.GothamBold,
                Text = "LOAD MORE",
                TextSize = 10,
                Visible = false,
                Parent = _cAz,
            }
        )
        _sf(_cEf, 10)
        _sv.HomeBtn(_cEf)
        _cDk[_cEe] = _cEf
        local _cEg = _cEe
        _jx(_jJ(_cEf, "MouseButton1Click"), function()
            _cDs(_cEg)
        end)
    end
    _jx(_cBT:GetPropertyChangedSignal("CanvasPosition"), function()
        if _cCZ ~= "bundle" and _cCZ ~= "emote" then
            return
        end
        local _cEh = _cBT.CanvasSize.Y.Offset - _cBT.AbsoluteWindowSize.Y
        if _cEh > 0 and _cBT.CanvasPosition.Y >= _cEh - 180 then
            _cDs(_cCZ)
        end
    end)
    pcall(function()
        local _cEi = _cAp.Frame
        if _cEi then
            _cEi.BackgroundTransparency = 1
            local _cEj = _cEi:FindFirstChildOfClass("UIStroke")
            if _cEj then
                _cEj.Transparency = 1
            end
            local _cEk = _cEi:FindFirstChildOfClass("UIGradient")
            if _cEk then
                _cEk.Enabled = false
            end
            for _cEl, _cEm in ipairs(_cEi:GetChildren()) do
                if _cEm:IsA("Frame") and _cEm ~= _cAz then
                    _cEm.Visible = false
                end
            end
        end
        _cAz.Position = UDim2.new(0, 0, 0, 0)
        local _cEn = _cAz:FindFirstChildOfClass("UIPadding")
        if _cEn then
            _cEn.PaddingLeft = UDim.new(0, 0)
            _cEn.PaddingRight = UDim.new(0, 0)
            _cEn.PaddingTop = UDim.new(0, 1)
            _cEn.PaddingBottom = UDim.new(0, 1)
        end
        local _cEo = _cAz:FindFirstChildOfClass("UIListLayout")
        if _cEo then
            _cEo.Padding = UDim.new(0, 10)
            _cEo.SortOrder = Enum.SortOrder.LayoutOrder
        end
    end)
    local function _cEp(_cEq, _cEr, _cEs)
        local _cEt = _qz(
            "Frame",
            {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = _cu or Enum.AutomaticSize.Y,
                BackgroundColor3 = _kA.Element,
                BackgroundTransparency = 0.1,
                LayoutOrder = _cEq,
                Parent = _cAz,
            }
        )
        _sf(_cEt, 12)
        _so(_cEt, _kA.Home.Edge, 1, 0.8)
        _qz(
            "UIGradient",
            { Color = ColorSequence.new(_kA.GlassLight, _kA.Element), Rotation = 100, Parent = _cEt }
        )
        local _cEu = 0
        if _cEr then
            _cEu = 44
            _qz(
                "TextLabel",
                {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 14, 0, 9),
                    Size = UDim2.new(1, -28, 0, 16),
                    Font = Enum.Font.GothamBold,
                    Text = _cEr,
                    TextColor3 = _kA.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = _cEt,
                }
            )
            _qz(
                "TextLabel",
                {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 14, 0, 26),
                    Size = UDim2.new(1, -28, 0, 12),
                    Font = Enum.Font.Gotham,
                    Text = _cEs or "",
                    TextColor3 = _kA.TextMuted,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = _cEt,
                }
            )
            local _cEv = _qz(
                "Frame",
                {
                    Position = UDim2.new(0, 0, 0, _cEu - 1),
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = _kA.Home.Edge,
                    BackgroundTransparency = 0.7,
                    BorderSizePixel = 0,
                    Parent = _cEt,
                }
            )
            _qz(
                "UIGradient",
                {
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(0.5, 0.3),
                        NumberSequenceKeypoint.new(1, 1),
                    }),
                    Parent = _cEv,
                }
            )
        end
        local _cEw = _qz(
            "Frame",
            {
                Position = UDim2.new(0, 0, 0, _cEu),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = _cu or Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = _cEt,
            }
        )
        _vy(_cEw, 10, 10, 10, 10)
        _qz(
            "UIListLayout",
            { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = _cEw }
        )
        return _cEt, _cEw
    end
    local function _cEx(_cEy, _cEz, _cEA, _cEB)
        local _cEC = _qz(
            "Frame",
            {
                Size = UDim2.new(0, 0, 0, 20),
                AutomaticSize = _cv or Enum.AutomaticSize.X,
                BackgroundColor3 = _cEA or _kA.Home.Tile,
                BackgroundTransparency = _cEA and 0.84 or 0.2,
                LayoutOrder = _cEB or 0,
                Parent = _cEy,
            }
        )
        _qz("UICorner", { CornerRadius = UDim.new(1, 0), Parent = _cEC })
        _vy(_cEC, 8, 9, 0, 0)
        _qz(
            "UIListLayout",
            {
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = _cEC,
            }
        )
        local _cED = _qz(
            "Frame",
            {
                Size = UDim2.new(0, 5, 0, 5),
                BackgroundColor3 = _cEA or _kA.Home.Muted,
                BorderSizePixel = 0,
                LayoutOrder = 1,
                Parent = _cEC,
            }
        )
        _qz("UICorner", { CornerRadius = UDim.new(1, 0), Parent = _cED })
        local _cEE = _qz(
            "TextLabel",
            {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = _cv or Enum.AutomaticSize.X,
                Font = Enum.Font.GothamBold,
                Text = _cEz,
                TextColor3 = _cEA or _kA.Text,
                TextSize = 9,
                LayoutOrder = 2,
                Parent = _cEC,
            }
        )
        return _cEC, _cED, _cEE
    end
    local _cEF = _qz(
        "Frame",
        {
            Size = UDim2.new(1, 0, 0, 52),
            BackgroundColor3 = _kA.Element,
            BackgroundTransparency = 0.1,
            ClipsDescendants = true,
            LayoutOrder = -10,
            Parent = _cAz,
        }
    )
    _sf(_cEF, 12)
    _so(_cEF, _kA.Home.Edge, 1, 0.8)
    _qz(
        "UIGradient",
        { Color = ColorSequence.new(_kA.GlassLight, _kA.Element), Rotation = 100, Parent = _cEF }
    )
    _qz(
        "TextLabel",
        {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 14, 0, 10),
            Size = UDim2.new(0.55, -14, 0, 16),
            Font = Enum.Font.GothamBold,
            Text = "Animation",
            TextColor3 = _kA.Text,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = _cEF,
        }
    )
    _qz(
        "TextLabel",
        {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 14, 0, 27),
            Size = UDim2.new(0.55, -14, 0, 12),
            Font = Enum.Font.Gotham,
            Text = "Bundles, emotes and per-state animations",
            TextColor3 = _kA.TextMuted,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = _cEF,
        }
    )
    local _cEG = _qz(
        "Frame",
        {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.new(0, 0, 0, 20),
            AutomaticSize = _cv or Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Parent = _cEF,
        }
    )
    _qz(
        "UIListLayout",
        {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = _cEG,
        }
    )
    local _cEH, _cEI, _cEJ = _cEx(_cEG, "R15", nil, 1)
    local _cEK, _cEL, _cEM = _cEx(_cEG, "0/" .. tostring(#_cwi) .. " SET", nil, 2)
    task.spawn(function()
        while _cEF.Parent do
            if _cvS.Page.Visible then
                pcall(function()
                    local _cEN = _gV and _gV.Character
                    local _cEO = _cEN and _cEN:FindFirstChildOfClass("Humanoid")
                    if _cEO then
                        _cEJ.Text = (_cEO.RigType == Enum.HumanoidRigType.R6) and "R6" or "R15"
                    end
                    local _cEP = 0
                    for _cEQ, _cER in ipairs(_cBo) do
                        if _cER.Visible then
                            _cEP = _cEP + 1
                        end
                    end
                    _cEM.Text = tostring(_cEP) .. "/" .. tostring(#_cwi) .. " SET"
                    _cEL.BackgroundColor3 = (_cEP > 0) and Color3.fromRGB(46, 160, 90) or _kA.Home.Muted
                end)
            end
            task.wait(1)
        end
    end)
    local _cES, _cET = _cEp(-8, "Animation Slot", "Pick a state, then browse bundles or emotes")
    _cBk.LayoutOrder = 1
    _cBk.Parent = _cET
    _cBb.LayoutOrder = 2
    _cBb.Parent = _cET
    _cAE.LayoutOrder = 3
    _cAE.Parent = _cET
    for _cEU, _cEV in ipairs(_cAz:GetChildren()) do
        if _cEV:IsA("Frame") and _cEV.ZIndex == 60 then
            pcall(function()
                _cEV.LayoutOrder = -7
                _cEV.Size = UDim2.new(1, 0, 0, 0)
                _cEV.BackgroundColor3 = _kA.Element
                _cEV.BackgroundTransparency = 0.05
                local _cEW = _cEV:FindFirstChildOfClass("UICorner")
                if _cEW then
                    _cEW.CornerRadius = UDim.new(0, 12)
                end
                local _cEX = _cEV:FindFirstChildOfClass("UIStroke")
                if _cEX then
                    _cEX.Thickness = 1
                    _cEX.Color = _kA.Home.Edge
                    _cEX.Transparency = 0.8
                end
            end)
        end
    end
    local _cEY, _cEZ = _cEp(-6, nil, nil)
    _cBM.LayoutOrder = 1
    _cBM.Parent = _cEZ
    _cBT.LayoutOrder = 2
    _cBT.Parent = _cEZ
    pcall(function()
        _cBT.ScrollBarThickness = 2
        _cBT.ScrollBarImageTransparency = 0.4
    end)
    for _cFa, _cFb in pairs(_cDk) do
        pcall(function()
            _cFb.LayoutOrder = 3
            _cFb.Parent = _cEZ
        end)
    end
    _cBK.LayoutOrder = 5
    _cBK.Parent = _cEZ
    -- Window lifecycle only: stop owned playback when the close button is used.
    onShutdown(function()
        _czM()
        _cwZ()
    end)
    _cAD.Select("bundle")
    do
        local _cFc = _cvU.lastBundle ~= nil
        local _cFd = type(_cvU.stateOverrides) == "table" and next(_cvU.stateOverrides) ~= nil
        if _cvU.autoLoad and (_cFc or _cFd) then
            task.spawn(function()
                local _cFe = _gV and (_gV.Character or _gV.CharacterAdded:Wait())
                if _cFe then
                    pcall(function()
                        _cFe:WaitForChild("Humanoid", 10)
                    end)
                    task.wait(0.5)
                    if _cFc then
                        _czu(tonumber(_cvU.lastBundle))
                    else
                        _czp()
                    end
                end
            end)
        end
    end
end

-- END ORIGINAL ANIMATION MODULE


local built, buildError = pcall(_NK.Animations)
if not built then
    SX.Close()
    error("SIEXTHER Animation could not build: " .. tostring(buildError))
end
return SX
