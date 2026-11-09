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

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local RF = game:GetService("ReplicatedFirst")
local TS = game:GetService("TeleportService")
local UIS = game:GetService("UserInputService")
local WS = game:GetService("Workspace")
local TW = game:GetService("TweenService")
local HS = game:GetService("HttpService")
local LP = Players.LocalPlayer

local S = {
    remotes={}, selected={}, pianos={}, allKeys={}, seat=nil,
    v1={act=false,gen=0,conns={},fired=0,rate=0,mode="nuke",ki=1,lvl=10,tM=1,kM=1,lastC=0,lastRT=0,lastT=0,bucket=0},
    v2={act=false,gen=0,conns={},fired=0,credit=0,cap=4000},
}
for i = 1, 61 do S.allKeys[i] = i end

-- HM HOOK
local hmOK, hmOrig, hmCount = false, nil, 20
local hmWatch = {}
local function setRO(t, ro)
    if typeof(setreadonly)=="function" then pcall(setreadonly, t, not ro)
    elseif typeof(make_writeable)=="function" and ro then pcall(make_writeable, t) end
end
local function wrap(fn) if typeof(newcclosure)=="function" then return newcclosure(fn) end return fn end
local function refreshWatch()
    hmWatch = {}
    for _, r in ipairs(S.selected) do if r and r.Parent then hmWatch[r]=true end end
end
local function installHM()
    if hmOK then return end
    if typeof(hookmetamethod)~="function" or typeof(getrawmetatable)~="function" then return end
    pcall(function() if getgenv()._HM_Uninstall then getgenv()._HM_Uninstall() end end)
    local mt = getrawmetatable(game)
    hmOrig = mt.__namecall
    local o = hmOrig
    setRO(mt, true)
    mt.__namecall = wrap(function(self, ...)
        local m = getnamecallmethod()
        if m~="FireServer" and m~="InvokeServer" then return o(self,...) end
        if hmCount>0 and hmWatch[self] then
            local a,b = ...
            if m=="InvokeServer" then
                for i=1,hmCount do task.spawn(o,self,a,b) end
            else
                for i=1,hmCount do o(self,a,b) end
            end
        end
        return o(self,...)
    end)
    setRO(mt, false)
    hmOK = true
end
local function uninstallHM()
    if not hmOK then return end
    local mt = getrawmetatable(game)
    setRO(mt, true); if hmOrig then mt.__namecall = hmOrig end; setRO(mt, false)
    hmOK, hmWatch = false, {}
end
getgenv()._HM_Install = installHM
getgenv()._HM_Uninstall = uninstallHM
getgenv()._HM_SetPianoExtra = function(n) hmCount = math.clamp(math.floor(tonumber(n) or 20),1,999) end
getgenv()._HM_SetExtras = getgenv()._HM_SetPianoExtra

local PKEY = {"piano","keyboard","key"}
local SKEY = {"bench","seat","stool","chair","sofa","throne","pew"}
local SRANGE = 80
local function matchKW(str, list)
    local l = str:lower()
    for _,k in ipairs(list) do if l:find(k,1,true) then return true end end
    return false
end
local function scanRemotes()
    S.remotes = {}; local seen = {}
    local srcs = {RS, WS}; pcall(function() table.insert(srcs, RF) end)
    for _, src in ipairs(srcs) do
        pcall(function()
            for _, obj in ipairs(src:GetDescendants()) do
                if not seen[obj] and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
                    local n = obj.Name:lower(); local sc = 0
                    if n:find("piano") then sc = sc + 1 end
                    if n:find("connector") then sc = sc + 1 end
                    if sc>=2 then
                        seen[obj] = true
                        local path, par, d = obj.Name, obj.Parent, 0
                        while par and par~=game and d<6 do path=par.Name.."."..path; par=par.Parent; d=d+1 end
                        table.insert(S.remotes, {name=obj.Name, remote=obj, path=path, score=sc})
                    end
                end
            end
        end)
    end
    table.sort(S.remotes, function(a,b) return a.score>b.score end)
    return S.remotes
end
local function findGPC()
    local ok,o = pcall(function() return WS:FindFirstChild("GlobalPianoConnector") end)
    return (ok and o) or nil
end
local function findSeat(pos, all)
    local best, bestD = nil, SRANGE
    for _, o in ipairs(all) do
        local isS = o:IsA("Seat") or o:IsA("VehicleSeat")
        if not isS and matchKW(o.Name, SKEY) then isS = true end
        if isS then
            local p = o:IsA("BasePart") and o or (o:IsA("Model") and (o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart")))
            if p then
                local d = (p.Position-pos).Magnitude
                if d<bestD then bestD,best = d,p end
            end
        end
    end
    return best, bestD
end
local function scanPianos()
    S.pianos = {}; local all = WS:GetDescendants(); local seen = {}
    local function add(pos,name)
        for _,p in ipairs(S.pianos) do if (p.pianoPos-pos).Magnitude<5 then return end end
        local seat, sd = findSeat(pos, all)
        table.insert(S.pianos, {name=name, pianoPos=pos, seatPart=seat, seatDist=sd,
            label=name.." ["..math.floor(pos.X)..","..math.floor(pos.Y)..","..math.floor(pos.Z).."]"})
    end
    local gpc = WS:FindFirstChild("GlobalPianoConnector")
    if gpc and gpc.Parent then
        pcall(function()
            local p = gpc.Parent:IsA("BasePart") and gpc.Parent or (gpc.Parent:IsA("Model") and (gpc.Parent.PrimaryPart or gpc.Parent:FindFirstChildWhichIsA("BasePart")))
            if p then add(p.Position,"GlobalPianoConnector") end
        end)
    end
    for _, r in ipairs(S.remotes) do
        pcall(function()
            local obj = r.remote; if not obj or not obj.Parent then return end
            local par = obj.Parent
            while par and not par:IsA("Workspace") do
                if par:IsA("Model") then
                    local p = par.PrimaryPart or par:FindFirstChildWhichIsA("BasePart")
                    if p then add(p.Position,par.Name) end; break
                elseif par:IsA("BasePart") then add(par.Position,par.Name); break end
                par = par.Parent
            end
        end)
    end
    for _, obj in ipairs(all) do
        if obj:IsA("ProximityPrompt") then
            pcall(function()
                local a,b = (obj.ActionText or ""):lower(), (obj.ObjectText or ""):lower()
                if matchKW(a,PKEY) or matchKW(b,PKEY) then
                    local p = obj.Parent
                    if p and p:IsA("BasePart") then add(p.Position,p.Name)
                    elseif p and p:IsA("Model") then
                        local q = p.PrimaryPart or p:FindFirstChildWhichIsA("BasePart")
                        if q then add(q.Position,p.Name) end
                    end
                end
            end)
        end
    end
    for _, obj in ipairs(all) do
        if obj:IsA("Model") and not seen[obj] then
            pcall(function()
                if matchKW(obj.Name,PKEY) then
                    seen[obj] = true
                    local p = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if p then add(p.Position,obj.Name) end
                end
            end)
        end
    end
    for _, obj in ipairs(all) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            pcall(function()
                if matchKW(obj.Name,PKEY) then
                    local par = obj.Parent and obj.Parent:IsA("Model") and obj.Parent
                    if par and seen[par] then return end
                    add(obj.Position,obj.Name); if par then seen[par]=true end
                end
            end)
        end
    end
    return S.pianos
end
local function tpSit()
    local ok, err = pcall(function()
        local c = LP.Character; if not c then error("No character") end
        local h,hu = c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
        if not (h and hu) then error("No HRP/Humanoid") end
        if not (S.seat and S.seat.Parent and S.seat:IsDescendantOf(WS)) then
            S.seat=nil; error("Seat gone — rescan") end
        h.CFrame = CFrame.new(S.seat.Position + Vector3.new(0,3,0))
        local t = tick(); while tick()-t<0.25 do RunService.Heartbeat:Wait() end
        if S.seat:IsA("Seat") or S.seat:IsA("VehicleSeat") then S.seat:Sit(hu) end
    end)
    return ok, err
end

local WHITE={}; for i=1,36 do WHITE[i]=i end
local BLACK={}; for i=37,61 do BLACK[i-36]=i end
local ALLK={}; for i=1,61 do ALLK[i]=i end
local function genKeys(n)
    local m,k,st = S.v1.mode,{},S.v1.ki
    if m=="sequential" or m=="nuke" then
        for i=1,n do k[i]=ALLK[((st+i-2)%#ALLK)+1] end; S.v1.ki=((st+n-1)%#ALLK)+1
    elseif m=="chromatic" then
        for i=1,n do k[i]=WHITE[((st+i-2)%#WHITE)+1] end; S.v1.ki=((st+n-1)%#WHITE)+1
    elseif m=="chord" then
        local p={}; for _,v in ipairs(ALLK) do p[#p+1]=v end
        local nn = math.min(n*2, #p)
        for i=1,nn do local j=math.random(i,#p); p[i],p[j]=p[j],p[i] end
        for i=1,nn do k[i]=p[i] end
    elseif m=="whiteflood" then for i=1,n do k[i]=WHITE[((i-1)%#WHITE)+1] end
    elseif m=="blackflood" then for i=1,n do k[i]=BLACK[((i-1)%#BLACK)+1] end
    elseif m=="chaos" then
        local p = (S.v1.ki%2==0) and WHITE or BLACK
        for i=1,n do k[i]=p[math.random(1,#p)] end; S.v1.ki=S.v1.ki+1
    elseif m=="thunderclap" then
        local p = (S.v1.ki%2==0) and ALLK or BLACK
        for i=1,n do k[i]=p[((st+i-2)%#p)+1] end; S.v1.ki=((st+n-1)%#p)+1
    elseif m=="all" then for i=1,n do k[i]=ALLK[((i-1)%#ALLK)+1] end
    else for i=1,n do k[i]=ALLK[math.random(1,#ALLK)] end end
    return k
end

local LT = {
    {c=14,b=0.00060,s=0.0016},{c=20,b=0.00050,s=0.0019},{c=27,b=0.00040,s=0.0022},
    {c=34,b=0.00033,s=0.0024},{c=42,b=0.00027,s=0.0026},{c=54,b=0.00021,s=0.0028},
    {c=68,b=0.00017,s=0.0030},{c=88,b=0.00013,s=0.0030},{c=114,b=0.00010,s=0.0030},
    {c=150,b=0.00008,s=0.0030},
}
for i=11,100 do
    local p = (i-10)/90
    LT[i] = {c=math.floor(150+(2200-150)*(p^0.7)), b=0.00008*math.exp(-p*6.4), s=0.0020}
end

local function stopV1()
    S.v1.act=false; S.v1.gen=S.v1.gen+1
    for _,c in ipairs(S.v1.conns) do pcall(c.Disconnect,c) end
    S.v1.conns={}; uninstallHM()
end
local function startV1()
    stopV1()
    if #S.selected==0 then return "no_remote" end
    installHM(); refreshWatch()
    S.v1.act=true; S.v1.gen=S.v1.gen+1; S.v1.fired=0; S.v1.ki=1; S.v1.conns={}
    S.v1.bucket=0; S.v1.lastT=os.clock(); S.v1.lastC=0; S.v1.lastRT=os.clock()
    local gen=S.v1.gen; local lv=math.clamp(S.v1.lvl,1,100); local cfg=LT[lv]
    local keys=genKeys(61); local eRem,fRem={},{}
    for _,r in ipairs(S.selected) do
        if r and r.Parent then
            if r:IsA("RemoteEvent") then eRem[#eRem+1]=r
            elseif r:IsA("RemoteFunction") then fRem[#fRem+1]=r end
        end
    end
    local gpc=findGPC()
    if gpc then if gpc:IsA("RemoteEvent") then eRem[#eRem+1]=gpc
    elseif gpc:IsA("RemoteFunction") then fRem[#fRem+1]=gpc end end
    if #eRem==0 and #fRem==0 then S.v1.act=false; uninstallHM(); return "no_valid" end
    local eN,fN=#eRem,#fRem; local totalN,keysN=eN+fN,#keys; local fIdx=0
    local cap = tonumber(getgenv().JEYHUB_LAGSVR_RATE_CAP) or 150000
    local function fireRound()
        local i = (fIdx%totalN)+1; fIdx=fIdx+1; local c=0
        if i<=eN then
            local r=eRem[i]
            if r.Parent then for k=1,keysN do r:FireServer("play",keys[k]) end; c=keysN end
        else
            local r=fRem[i-eN]
            if r.Parent then for k=1,keysN do task.spawn(r.InvokeServer,r,"play",keys[k]) end; c=keysN end
        end
        return c
    end
    local bpp = math.min((cfg.c/4)*cfg.b, cfg.s)
    local function phase()
        if not S.v1.act or gen~=S.v1.gen or S.v1.bucket>=cap then return end
        local t0 = os.clock()+bpp; local batch=0
        repeat
            for k=1,keysN do batch=batch+fireRound() end
            if os.clock()>=t0 then break end
        until S.v1.bucket+batch>=cap
        S.v1.fired=S.v1.fired+batch; S.v1.bucket=S.v1.bucket+batch
    end
    for _,sig in ipairs({RunService.Heartbeat,RunService.Stepped,RunService.PreSimulation,RunService.PostSimulation}) do
        local ok,c = pcall(function() return sig:Connect(phase) end)
        if ok and c then table.insert(S.v1.conns,c) end
    end
    table.insert(S.v1.conns, RunService.Heartbeat:Connect(function()
        local now=os.clock()
        if now-S.v1.lastT>=1 then S.v1.lastT=now; S.v1.bucket=0 end
        if now-S.v1.lastRT>=0.2 then
            local dt=now-S.v1.lastRT
            S.v1.rate = dt>0 and math.floor((S.v1.fired-S.v1.lastC)/dt) or 0
            S.v1.lastRT=now; S.v1.lastC=S.v1.fired
            if _G.__v1Upd then _G.__v1Upd() end
        end
    end))
    return "ok"
end
local function stopV2()
    S.v2.act=false; S.v2.gen=S.v2.gen+1
    for _,c in ipairs(S.v2.conns) do pcall(c.Disconnect,c) end
    S.v2.conns={}; uninstallHM()
end
local function startV2()
    stopV2()
    if #S.selected==0 and not findGPC() then return "no_remote" end
    installHM(); refreshWatch()
    S.v2.act=true; S.v2.gen=S.v2.gen+1; S.v2.fired=0; S.v2.credit=0; S.v2.conns={}
    local gen=S.v2.gen; local eRem,fRem={},{}
    for _,r in ipairs(S.selected) do
        if r and r.Parent then
            if r:IsA("RemoteEvent") then eRem[#eRem+1]=r
            elseif r:IsA("RemoteFunction") then fRem[#fRem+1]=r end
        end
    end
    local gpc=findGPC()
    if gpc then if gpc:IsA("RemoteEvent") then eRem[#eRem+1]=gpc
    elseif gpc:IsA("RemoteFunction") then fRem[#fRem+1]=gpc end end
    if #eRem==0 and #fRem==0 then S.v2.act=false; return "no_valid" end
    local eN,fN=#eRem,#fRem; local totalN,keysN=eN+fN,#S.allKeys; local idx=0
    local cap = math.clamp(S.v2.cap or 4000, 1, 4000)
    local function fire1()
        local i=(idx%totalN)+1; idx=idx+1
        if i<=eN then
            local r=eRem[i]
            if r.Parent then for k=1,keysN do r:FireServer("play",S.allKeys[k]) end; return keysN end
        else
            local r=fRem[i-eN]
            if r.Parent then for k=1,keysN do task.spawn(r.InvokeServer,r,"play",S.allKeys[k]) end; return keysN end
        end
        return 0
    end
    table.insert(S.v2.conns, RunService.Heartbeat:Connect(function(dt)
        if not S.v2.act or gen~=S.v2.gen or totalN==0 then return end
        S.v2.credit = math.min(S.v2.credit+cap*dt, keysN*4)
        local batch=0
        while S.v2.credit>=keysN do
            S.v2.credit = S.v2.credit-keysN
            local c=fire1(); if c==0 then S.v2.credit=0; break end
            batch=batch+c
        end
        if batch>0 then S.v2.fired=S.v2.fired+batch end
    end))
    local lu=0
    table.insert(S.v2.conns, RunService.Heartbeat:Connect(function()
        local now=os.clock()
        if now-lu>=0.2 then lu=now; if _G.__v2Upd then _G.__v2Upd() end end
    end))
    return "ok"
end

local T = {
    bg=Color3.fromRGB(14,14,16), bg2=Color3.fromRGB(20,20,23), bg3=Color3.fromRGB(26,26,30),
    el=Color3.fromRGB(32,32,36), hov=Color3.fromRGB(44,44,50),
    text=Color3.fromRGB(240,240,245), sub=Color3.fromRGB(160,160,170),
    muted=Color3.fromRGB(110,110,120), accent=Color3.fromRGB(70,130,255),
    success=Color3.fromRGB(80,200,120), danger=Color3.fromRGB(230,70,70),
}
local function I(class, props, parent)
    local o = __SIEXTHER_VIP_GLASS_V1.Instance.new(class)
    if props then for k,v in pairs(props) do if k~="Parent" then pcall(function() o[k]=v end) end end end
    if parent then o.Parent = parent end
    return o
end
local function corner(p, r) return I("UICorner", {CornerRadius=UDim.new(0,r or 6)}, p) end
local function stroke(p, c, th, tr)
    return I("UIStroke", {Color=c or T.accent, Thickness=th or 1, Transparency=tr or 0,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border}, p)
end
local function hoverFx(btn, bg, hov, tx, htx)
    local ti = TweenInfo.new(0.14)
    btn.MouseEnter:Connect(function()
        if bg then TW:Create(btn, ti, {BackgroundColor3=hov or T.hov}):Play() end
        if btn:IsA("TextButton") and tx then TW:Create(btn, ti, {TextColor3=htx or T.text}):Play() end
    end)
    btn.MouseLeave:Connect(function()
        if bg then TW:Create(btn, ti, {BackgroundColor3=bg}):Play() end
        if btn:IsA("TextButton") and tx then TW:Create(btn, ti, {TextColor3=tx}):Play() end
    end)
end

local gui = I("ScreenGui", {Name="JEYHUB_PianoGUI", ResetOnSpawn=false, IgnoreGuiInset=true,
    DisplayOrder=999, ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
pcall(function()
    if typeof(gethui)=="function" then gui.Parent = gethui()
    else gui.Parent = LP:WaitForChild("PlayerGui") end
end)

local WW, WH = 300, 380
local win = I("Frame", {Name="MainFrame", Size=UDim2.new(0,WW,0,WH),
    Position=UDim2.new(0.5,-WW/2,0.5,-WH/2),
    BackgroundColor3=T.bg, BorderSizePixel=0, ClipsDescendants=true, Active=true}, gui)
corner(win, 12)
stroke(win, T.accent, 1.6, 0.05)

local dragging, dsI, dsP = false, nil, nil
win.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging=true; dsI=input.Position; dsP=win.Position
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then dragging=false end
end)
UIS.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
       or input.UserInputType == Enum.UserInputType.Touch then
        local d = input.Position - dsI
        win.Position = UDim2.new(dsP.X.Scale, dsP.X.Offset+d.X, dsP.Y.Scale, dsP.Y.Offset+d.Y)
    end
end)

local topBar = I("Frame", {Size=UDim2.new(1,0,0,34), BackgroundColor3=T.bg2,
    BorderSizePixel=0, ZIndex=2}, win)
corner(topBar, 12)
I("TextLabel", {Size=UDim2.new(1,-90,1,0), Position=UDim2.new(0,12,0,0),
    BackgroundTransparency=1, Font=Enum.Font.GothamBold, Text="SIEXTHER PIANO LAGGER",
    TextColor3=T.text, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3}, topBar)

local minBtn = I("TextButton", {Size=UDim2.new(0,22,0,22), Position=UDim2.new(1,-52,0.5,-11),
    BackgroundColor3=T.el, Font=Enum.Font.GothamBold, Text="–",
    TextColor3=T.sub, TextSize=14, AutoButtonColor=false, ZIndex=3}, topBar)
corner(minBtn, 5)
hoverFx(minBtn, T.el, T.hov, T.sub, T.text)

local closeBtn = I("TextButton", {Size=UDim2.new(0,22,0,22), Position=UDim2.new(1,-26,0.5,-11),
    BackgroundColor3=T.el, Font=Enum.Font.GothamBold, Text="×",
    TextColor3=T.sub, TextSize=13, AutoButtonColor=false, ZIndex=3}, topBar)
corner(closeBtn, 5)
hoverFx(closeBtn, T.el, T.danger, T.sub, Color3.new(1,1,1))

local tabBar = I("Frame", {Size=UDim2.new(1,0,0,28), Position=UDim2.new(0,0,0,34),
    BackgroundColor3=T.bg2, BorderSizePixel=0, ZIndex=2}, win)
I("Frame", {Size=UDim2.new(1,-16,0,1), Position=UDim2.new(0,8,1,-1),
    BackgroundColor3=T.accent, BackgroundTransparency=0.8, BorderSizePixel=0, ZIndex=3}, tabBar)

local function mkTab(text, x)
    local b = I("TextButton", {Size=UDim2.new(0.5,-3,0,22), Position=UDim2.new(x,3,0,3),
        BackgroundColor3=T.el, Font=Enum.Font.GothamBold, Text=text,
        TextColor3=T.text, TextSize=10, AutoButtonColor=false, ZIndex=3}, tabBar)
    corner(b, 5)
    return b
end
local tV1 = mkTab("PIANO V1", 0)
local tV2 = mkTab("PIANO V2", 0.5)
tV2.BackgroundTransparency = 0.5; tV2.TextColor3 = T.sub

local content = I("Frame", {Size=UDim2.new(1,-14,1,-70), Position=UDim2.new(0,7,0,62),
    BackgroundTransparency=1, ZIndex=2}, win)

local function mkPage(vis)
    local s = I("ScrollingFrame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        ScrollBarThickness=2, ScrollBarImageColor3=T.accent, ScrollBarImageTransparency=0.3,
        BorderSizePixel=0, CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y, Visible=vis, ZIndex=3}, content)
    I("UIListLayout", {Padding=UDim.new(0,7), SortOrder=Enum.SortOrder.LayoutOrder}, s)
    return s
end
local pV1 = mkPage(true)
local pV2 = mkPage(false)

tV1.MouseButton1Click:Connect(function()
    pV1.Visible=true; pV2.Visible=false
    tV1.BackgroundTransparency=0; tV1.TextColor3=T.text
    tV2.BackgroundTransparency=0.5; tV2.TextColor3=T.sub
end)
tV2.MouseButton1Click:Connect(function()
    pV1.Visible=false; pV2.Visible=true
    tV1.BackgroundTransparency=0.5; tV1.TextColor3=T.sub
    tV2.BackgroundTransparency=0; tV2.TextColor3=T.text
end)

local openDD = nil
local function closeDDs() if openDD then pcall(function() openDD.Visible=false end); openDD=nil end end

local function card(parent, title, sub)
    local c = I("Frame", {Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundColor3=T.bg3, BorderSizePixel=0, ZIndex=3}, parent)
    corner(c, 8)
    I("UIPadding", {PaddingLeft=UDim.new(0,9), PaddingRight=UDim.new(0,9),
        PaddingTop=UDim.new(0,7), PaddingBottom=UDim.new(0,9)}, c)
    local h = I("Frame", {Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, ZIndex=4}, c)
    I("TextLabel", {Size=UDim2.new(1,0,0,14), BackgroundTransparency=1,
        Font=Enum.Font.GothamBold, Text=title, TextColor3=T.text, TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4}, h)
    if sub then
        I("TextLabel", {Size=UDim2.new(1,0,0,10), Position=UDim2.new(0,0,0,15),
            BackgroundTransparency=1, Font=Enum.Font.Gotham, Text=sub,
            TextColor3=T.muted, TextSize=8, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4}, h)
    end
    local body = I("Frame", {Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,28),
        AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=4}, c)
    I("UIListLayout", {Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder}, body)
    return c, body
end

local function btn(parent, text, h, cb)
    local b = I("TextButton", {Size=UDim2.new(1,0,0,h or 24), BackgroundColor3=T.el,
        Font=Enum.Font.GothamBold, Text=text, TextColor3=T.text, TextSize=9,
        AutoButtonColor=false, ZIndex=4}, parent)
    corner(b, 6)
    hoverFx(b, T.el, T.hov, T.text, T.text)
    b.MouseButton1Click:Connect(function() if cb then cb(b) end end)
    return b
end

local function slider(parent, label, minV, maxV, defV, step, cb)
    step = step or 1
    local w = I("Frame", {Size=UDim2.new(1,0,0,38), BackgroundColor3=T.bg2,
        BorderSizePixel=0, ZIndex=4}, parent)
    corner(w, 6)
    I("UIPadding", {PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8),
        PaddingTop=UDim.new(0,5), PaddingBottom=UDim.new(0,5)}, w)
    I("TextLabel", {Size=UDim2.new(1,-46,0,11), BackgroundTransparency=1,
        Font=Enum.Font.GothamBold, Text=label, TextColor3=T.text, TextSize=9,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5}, w)
    local vl = I("TextLabel", {Size=UDim2.new(0,44,0,11), Position=UDim2.new(1,-44,0,0),
        BackgroundTransparency=1, Font=Enum.Font.GothamBold, Text=tostring(defV),
        TextColor3=T.accent, TextSize=9, TextXAlignment=Enum.TextXAlignment.Right, ZIndex=5}, w)
    local tr = I("TextButton", {Size=UDim2.new(1,0,0,5), Position=UDim2.new(0,0,0,20),
        BackgroundColor3=T.bg, BorderSizePixel=0, Text="", AutoButtonColor=false, ZIndex=5}, w)
    corner(tr, 3)
    local fl = I("Frame", {Size=UDim2.new(0,0,1,0), BackgroundColor3=T.accent,
        BorderSizePixel=0, ZIndex=6}, tr)
    corner(fl, 3)
    local kn = I("Frame", {Size=UDim2.new(0,10,0,10), AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0,0,0.5,0), BackgroundColor3=Color3.new(1,1,1),
        BorderSizePixel=0, ZIndex=7}, tr)
    corner(kn, 5)
    local val, drag = defV, false
    local function set(v, fire)
        v = math.clamp(math.floor((v-minV)/step+0.5)*step+minV, minV, maxV)
        val = v
        local pct = (v-minV)/math.max(maxV-minV,1)
        fl.Size = UDim2.new(pct,0,1,0); kn.Position = UDim2.new(pct,0,0.5,0)
        vl.Text = tostring(v); if fire and cb then cb(v) end
    end
    tr.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1
           or input.UserInputType==Enum.UserInputType.Touch then
            drag=true
            local p = math.clamp((input.Position.X-tr.AbsolutePosition.X)/math.max(tr.AbsoluteSize.X,1),0,1)
            set(minV+p*(maxV-minV), true)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1
           or input.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    UIS.InputChanged:Connect(function(input)
        if drag and (input.UserInputType==Enum.UserInputType.MouseMovement
            or input.UserInputType==Enum.UserInputType.Touch) then
            local p = math.clamp((input.Position.X-tr.AbsolutePosition.X)/math.max(tr.AbsoluteSize.X,1),0,1)
            set(minV+p*(maxV-minV), true)
        end
    end)
    set(defV, false)
    return {set=set}
end

local function dropdown(parent, label, options, def, cb)
    local w = I("Frame", {Size=UDim2.new(1,0,0,28), BackgroundColor3=T.bg2,
        BorderSizePixel=0, ZIndex=4}, parent)
    corner(w, 6)
    I("UIPadding", {PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8),
        PaddingTop=UDim.new(0,3), PaddingBottom=UDim.new(0,3)}, w)
    I("TextLabel", {Size=UDim2.new(1,-80,1,0), BackgroundTransparency=1,
        Font=Enum.Font.GothamBold, Text=label, TextColor3=T.text, TextSize=9,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5}, w)
    local sb = I("TextButton", {Size=UDim2.new(0,74,1,0), Position=UDim2.new(1,-74,0,0),
        BackgroundColor3=T.el, Font=Enum.Font.Gotham, Text=def, TextColor3=T.sub,
        TextSize=9, AutoButtonColor=false, TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=5}, w)
    corner(sb, 5)
    local list = I("Frame", {BackgroundColor3=T.bg3, BorderSizePixel=0, ClipsDescendants=true,
        Visible=false, Size=UDim2.new(0,160,0,0), ZIndex=500}, gui)
    corner(list, 6)
    stroke(list, T.muted, 1, 0.6)
    local sc = I("ScrollingFrame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        ScrollBarThickness=2, ScrollBarImageColor3=T.accent, BorderSizePixel=0,
        CanvasSize=UDim2.new(0,0,0,#options*22), ZIndex=501}, list)
    I("UIListLayout", {Padding=UDim.new(0,1), SortOrder=Enum.SortOrder.LayoutOrder}, sc)
    local sel = def; local btns = {}
    local function upd()
        for _,b in ipairs(btns) do
            local s = b.Text==sel
            b.BackgroundTransparency = s and 0 or 0.5
            b.TextColor3 = s and T.text or T.sub
        end
    end
    for i, opt in ipairs(options) do
        local b = I("TextButton", {Size=UDim2.new(1,0,0,20), BackgroundColor3=T.el,
            BackgroundTransparency=opt==def and 0 or 0.5, Font=Enum.Font.Gotham,
            Text=opt, TextColor3=opt==def and T.text or T.sub, TextSize=9,
            AutoButtonColor=false, LayoutOrder=i, ZIndex=502}, sc)
        b.MouseButton1Click:Connect(function()
            sel=opt; sb.Text=opt; list.Visible=false; openDD=nil; upd()
            if cb then cb(opt) end
        end)
        btns[#btns+1] = b
    end
    sb.MouseButton1Click:Connect(function()
        if list.Visible then list.Visible=false; openDD=nil; return end
        closeDDs()
        local ap, as_ = w.AbsolutePosition, w.AbsoluteSize
        list.Position = UDim2.new(0, ap.X+8, 0, ap.Y+as_.Y+4)
        list.Size = UDim2.new(0, math.max(as_.X-16, 160), 0, math.min(#options*22+4, 200))
        list.Visible = true; openDD = list
    end)
    return {set=function(v) sel=v; sb.Text=v; upd() end}
end

do
    local _, body = card(pV1, "Setup", "Scan piano · teleport · spawn")
    btn(body, "SCAN PIANO", 24, function() scanPianos(); updatePListV1() end)
    local pl = I("Frame", {Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=4}, body)
    I("UIListLayout", {Padding=UDim.new(0,3), SortOrder=Enum.SortOrder.LayoutOrder}, pl)
    _G.__v1PL = pl
    local sl = I("TextLabel", {Size=UDim2.new(1,0,0,11), BackgroundTransparency=1,
        Font=Enum.Font.Gotham, Text="Selected: —", TextColor3=T.muted, TextSize=8,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4}, body)
    _G.__v1SL = sl
    btn(body, "TELEPORT & SIT", 24, function()
        if not S.seat then sl.Text="⚠ Select piano!"; sl.TextColor3=T.danger; return end
        local ok, err = tpSit()
        if ok then sl.Text="✓ Seated."; sl.TextColor3=T.success
        else sl.Text="✗ "..tostring(err); sl.TextColor3=T.danger end
    end)
    local spt = I("TextLabel", {Size=UDim2.new(1,0,0,11), BackgroundTransparency=1,
        Font=Enum.Font.Gotham, Text="Spawn: —", TextColor3=T.muted, TextSize=8,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4}, body)
    local sp = nil
    btn(body, "SCAN SPAWN", 24, function()
        local f = {}; local c = LP.Character
        local h = c and c:FindFirstChild("HumanoidRootPart")
        local p = h and h.Position or Vector3.zero
        for _, o in ipairs(WS:GetDescendants()) do
            if o:IsA("SpawnLocation") then f[#f+1] = {part=o, d=(o.Position-p).Magnitude} end
        end
        table.sort(f, function(a,b) return a.d<b.d end)
        if #f==0 then spt.Text="⚠ No spawn"; spt.TextColor3=T.danger; return end
        sp = f[1].part
        spt.Text = "Spawn: "..f[1].part.Name.." (~"..math.floor(f[1].d)..")"
        spt.TextColor3 = T.success
    end)
    btn(body, "TP TO SPAWN", 24, function()
        if not sp then spt.Text="⚠ Scan first"; spt.TextColor3=T.danger; return end
        local c = LP.Character; local h = c and c:FindFirstChild("HumanoidRootPart")
        if h then h.CFrame = sp.CFrame + Vector3.new(0,3,0) end
    end)
end

do
    local _, body = card(pV1, "Piano Remote", "Max 2 remotes")
    btn(body, "SCAN REMOTES", 24, function() scanRemotes(); updateRList("__v1RL","__v1RSL") end)
    local rl = I("Frame", {Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=4}, body)
    I("UIListLayout", {Padding=UDim.new(0,3), SortOrder=Enum.SortOrder.LayoutOrder}, rl)
    _G.__v1RL = rl
    local rsl = I("TextLabel", {Size=UDim2.new(1,0,0,11), BackgroundTransparency=1,
        Font=Enum.Font.Gotham, Text="Active: —", TextColor3=T.muted, TextSize=8,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4}, body)
    _G.__v1RSL = rsl
end

do
    local _, body = card(pV1, "Spam Control", "Level · mode · start")
    slider(body, "Level (1-100)", 1, 100, 10, 1, function(v) S.v1.lvl=v end)
    slider(body, "Thread Mult", 1, 610, 1, 1, function(v) S.v1.tM=v end)
    slider(body, "Key Mult", 1, 610, 1, 1, function(v) S.v1.kM=v end)
    dropdown(body, "Mode", {
        "Random","Sequential","Chromatic Run","Burst Chord","All Keys Hammer",
        "NUKE — Full Flood","White Keys Flood","Black Keys Flood",
        "Chaos (Alt White/Black)","Thunderclap (All+Black burst)",
    }, "NUKE — Full Flood", function(v)
        local m = {
            ["Random"]="random",["Sequential"]="sequential",["Chromatic Run"]="chromatic",
            ["Burst Chord"]="chord",["All Keys Hammer"]="all",["NUKE — Full Flood"]="nuke",
            ["White Keys Flood"]="whiteflood",["Black Keys Flood"]="blackflood",
            ["Chaos (Alt White/Black)"]="chaos",["Thunderclap (All+Black burst)"]="thunderclap",
        }
        S.v1.mode = m[v] or "nuke"
    end)
    local row = I("Frame", {Size=UDim2.new(1,0,0,26), BackgroundTransparency=1, ZIndex=4}, body)
    local sb = I("TextButton", {Size=UDim2.new(0.5,-2,1,0), BackgroundColor3=T.accent,
        Font=Enum.Font.GothamBold, Text="▶ START", TextColor3=Color3.new(1,1,1),
        TextSize=9, AutoButtonColor=false, ZIndex=5}, row)
    corner(sb, 6)
    local rb = I("TextButton", {Size=UDim2.new(0.5,-2,1,0), Position=UDim2.new(0.5,2,0,0),
        BackgroundColor3=T.el, Font=Enum.Font.GothamBold, Text="REJOIN",
        TextColor3=T.text, TextSize=9, AutoButtonColor=false, ZIndex=5}, row)
    corner(rb, 6)
    hoverFx(rb, T.el, T.hov, T.text, T.text)
    sb.MouseButton1Click:Connect(function()
        local r = startV1()
        if r=="ok" then sb.Text="✓ ACTIVE"; sb.BackgroundColor3=T.success; __v1Stat("✓ Spam V1 active", T.success)
        elseif r=="no_remote" then __v1Stat("⚠ Scan & select remote!", T.danger)
        else __v1Stat("✗ "..tostring(r), T.danger) end
    end)
    rb.MouseButton1Click:Connect(function()
        stopV1(); __v1Stat("Rejoining...", T.sub)
        task.spawn(function()
            pcall(function()
                local j = game.JobId
                if j and j~="" then TS:TeleportToPlaceInstance(game.PlaceId, j, LP)
                else TS:Teleport(game.PlaceId, LP) end
            end)
        end)
    end)
end

do
    local _, body = card(pV1, "Status", "Live stats")
    local stl = I("TextLabel", {Size=UDim2.new(1,0,0,12), BackgroundTransparency=1,
        Font=Enum.Font.GothamBold, Text="[IDLE]", TextColor3=T.muted, TextSize=9,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4}, body)
    _G.__v1SLBL = stl
    local ctl = I("TextLabel", {Size=UDim2.new(1,0,0,11), BackgroundTransparency=1,
        Font=Enum.Font.Gotham, Text="Keys: 0", TextColor3=T.sub, TextSize=8,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4}, body)
    _G.__v1CNT = ctl
    local rtl = I("TextLabel", {Size=UDim2.new(1,0,0,11), BackgroundTransparency=1,
        Font=Enum.Font.Gotham, Text="Rate: 0/s", TextColor3=T.sub, TextSize=8,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4}, body)
    _G.__v1RT = rtl
end

function __v1Stat(t, c)
    if _G.__v1SLBL and _G.__v1SLBL.Parent then
        _G.__v1SLBL.Text=t; _G.__v1SLBL.TextColor3=c or T.text end
end
function __v1Upd()
    if _G.__v1CNT and _G.__v1CNT.Parent then _G.__v1CNT.Text="Keys: "..tostring(S.v1.fired) end
    if _G.__v1RT and _G.__v1RT.Parent then _G.__v1RT.Text="Rate: "..tostring(S.v1.rate).."/s" end
    if _G.__v1SLBL and _G.__v1SLBL.Parent and S.v1.act then
        _G.__v1SLBL.Text="[ACTIVE] Lv."..S.v1.lvl; _G.__v1SLBL.TextColor3=T.success
    end
end

function updatePListV1()
    local f = _G.__v1PL; if not f then return end
    for _,c in ipairs(f:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
    if #S.pianos==0 then
        I("TextLabel", {Size=UDim2.new(1,0,0,16), BackgroundTransparency=1,
            Font=Enum.Font.Gotham, Text="  No piano found", TextColor3=T.muted,
            TextSize=8, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4}, f)
        return
    end
    for i,p in ipairs(S.pianos) do
        local hs = p.seatPart~=nil
        local b = I("TextButton", {Size=UDim2.new(1,0,0,26), BackgroundColor3=T.bg2,
            Text="", AutoButtonColor=false, LayoutOrder=i, ZIndex=4}, f)
        corner(b, 5)
        local d = I("Frame", {Size=UDim2.new(0,5,0,5), Position=UDim2.new(0,8,0.5,-2.5),
            BackgroundColor3=hs and T.success or T.muted, BorderSizePixel=0, ZIndex=5}, b)
        corner(d, 3)
        I("TextLabel", {Size=UDim2.new(1,-22,0,12), Position=UDim2.new(0,18,0,2),
            BackgroundTransparency=1, Font=Enum.Font.GothamBold, Text="["..i.."] "..p.label,
            TextColor3=T.text, TextSize=8, TextXAlignment=Enum.TextXAlignment.Left,
            TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=5}, b)
        I("TextLabel", {Size=UDim2.new(1,-22,0,10), Position=UDim2.new(0,18,0,14),
            BackgroundTransparency=1, Font=Enum.Font.Gotham,
            Text=hs and ("seat ~"..math.floor(p.seatDist)) or "no seat",
            TextColor3=T.muted, TextSize=7.5, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5}, b)
        b.MouseButton1Click:Connect(function()
            if p.seatPart and p.seatPart.Parent then
                S.seat = p.seatPart
                if _G.__v1SL then _G.__v1SL.Text="Selected: "..p.name; _G.__v1SL.TextColor3=T.success end
            else
                S.seat = nil
                if _G.__v1SL then _G.__v1SL.Text=p.name.." (no seat)"; _G.__v1SL.TextColor3=T.sub end
            end
        end)
    end
end

function updateRList(pk, slk)
    local f = _G[pk]; if not f then return end
    for _,c in ipairs(f:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
    if #S.remotes==0 then
        I("TextLabel", {Size=UDim2.new(1,0,0,16), BackgroundTransparency=1,
            Font=Enum.Font.Gotham, Text="  No remote", TextColor3=T.muted,
            TextSize=8, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4}, f)
        return
    end
    local function idx(r) for i,s in ipairs(S.selected) do if s==r then return i end end return nil end
    for i,r in ipairs(S.remotes) do
        local si = idx(r.remote)
        local b = I("TextButton", {Size=UDim2.new(1,0,0,22), BackgroundColor3=si and T.hov or T.bg2,
            Text="", AutoButtonColor=false, LayoutOrder=i, ZIndex=4}, f)
        corner(b, 5)
        I("TextLabel", {Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,8,0,0),
            BackgroundTransparency=1, Font=Enum.Font.GothamBold,
            Text=(si and ("["..si.."] ") or "")..r.path,
            TextColor3=si and T.text or T.sub, TextSize=8,
            TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=5}, b)
        b.MouseButton1Click:Connect(function()
            local ii = idx(r.remote)
            if ii then table.remove(S.selected, ii)
            elseif #S.selected<2 then table.insert(S.selected, r.remote)
            else S.selected[2] = r.remote end
            refreshWatch(); updateRList(pk, slk)
            local names = {}
            for _,s in ipairs(S.selected) do pcall(function() table.insert(names, s.Name) end) end
            local lbl = _G[slk]
            if lbl then
                lbl.Text = "Active: "..(#names>0 and table.concat(names," + ") or "none")
                lbl.TextColor3 = #names>0 and T.success or T.muted
            end
        end)
    end
end

do
    local _, body = card(pV2, "Piano V2", "Smooth rate-capped flood")
    slider(body, "Rate Cap", 100, 4000, 4000, 50, function(v) S.v2.cap=v end)
    btn(body, "SCAN REMOTES V2", 24, function() scanRemotes(); updateRList("__v2RL","__v2RSL") end)
    local rl = I("Frame", {Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=4}, body)
    I("UIListLayout", {Padding=UDim.new(0,3), SortOrder=Enum.SortOrder.LayoutOrder}, rl)
    _G.__v2RL = rl
    local rsl = I("TextLabel", {Size=UDim2.new(1,0,0,11), BackgroundTransparency=1,
        Font=Enum.Font.Gotham, Text="Active: —", TextColor3=T.muted, TextSize=8,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4}, body)
    _G.__v2RSL = rsl
    local row = I("Frame", {Size=UDim2.new(1,0,0,26), BackgroundTransparency=1, ZIndex=4}, body)
    local sb = I("TextButton", {Size=UDim2.new(0.5,-2,1,0), BackgroundColor3=T.accent,
        Font=Enum.Font.GothamBold, Text="▶ START V2", TextColor3=Color3.new(1,1,1),
        TextSize=9, AutoButtonColor=false, ZIndex=5}, row)
    corner(sb, 6)
    local stb = I("TextButton", {Size=UDim2.new(0.5,-2,1,0), Position=UDim2.new(0.5,2,0,0),
        BackgroundColor3=T.el, Font=Enum.Font.GothamBold, Text="■ STOP",
        TextColor3=T.text, TextSize=9, AutoButtonColor=false, ZIndex=5}, row)
    corner(stb, 6)
    hoverFx(stb, T.el, T.danger, T.text, Color3.new(1,1,1))
    sb.MouseButton1Click:Connect(function()
        local r = startV2()
        if r=="ok" then sb.Text="✓ ACTIVE"; sb.BackgroundColor3=T.success; __v2Stat("V2 active", T.success)
        elseif r=="no_remote" then __v2Stat("⚠ Scan & select!", T.danger)
        else __v2Stat("✗ "..tostring(r), T.danger) end
    end)
    stb.MouseButton1Click:Connect(function()
        stopV2(); sb.Text="▶ START V2"; sb.BackgroundColor3=T.accent
        __v2Stat("Stopped", T.sub)
    end)
    local stl = I("TextLabel", {Size=UDim2.new(1,0,0,12), BackgroundTransparency=1,
        Font=Enum.Font.Gotham, Text="Fired: 0", TextColor3=T.sub, TextSize=9,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4}, body)
    _G.__v2STL = stl
end

function __v2Stat(t, c)
    if _G.__v2STL and _G.__v2STL.Parent then _G.__v2STL.Text=t; _G.__v2STL.TextColor3=c or T.sub end
end
function __v2Upd()
    if _G.__v2STL and _G.__v2STL.Parent then
        if S.v2.act then
            _G.__v2STL.Text="● ACTIVE — "..tostring(S.v2.fired); _G.__v2STL.TextColor3=T.success
        else
            _G.__v2STL.Text="● IDLE — "..tostring(S.v2.fired); _G.__v2STL.TextColor3=T.sub
        end
    end
end

local fbtn = I("TextButton", {Size=UDim2.new(0,42,0,42), Position=UDim2.new(0,20,0.5,-24),
    BackgroundColor3=T.bg, Text="🎹", TextColor3=T.text, TextSize=20,
    AutoButtonColor=false, Visible=false, Font=Enum.Font.GothamBold, ZIndex=999}, gui)
corner(fbtn, 12)


minBtn.MouseButton1Click:Connect(function() closeDDs(); win.Visible=false; fbtn.Visible=true end)
fbtn.MouseButton1Click:Connect(function() win.Visible=true; fbtn.Visible=false end)
closeBtn.MouseButton1Click:Connect(function()
    stopV1(); stopV2(); uninstallHM()
    pcall(function() if getgenv()._JH_StopAll then getgenv()._JH_StopAll() end end)
    pcall(function() gui:Destroy() end)
end)

LP.CharacterAdded:Connect(function()
    if S.v1.act then stopV1(); __v1Stat("[RESPAWN] Stopped", T.muted) end
    if S.v2.act then stopV2(); __v2Stat("[RESPAWN] Stopped", T.muted) end
end)

task.spawn(function()
    task.wait(0.5)
    pcall(function()
        scanRemotes()
        updateRList("__v1RL", "__v1RSL")
        updateRList("__v2RL", "__v2RSL")
    end)
end)

