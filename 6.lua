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
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Create GUI
local ScreenGui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
ScreenGui.Name = "DayCycleChanger"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

-- Main Frame (Dark Modern)
local MainFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 320)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(70, 130, 255)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- Header
local Header = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local HeaderFix = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 12)
HeaderFix.Position = UDim2.new(0, 0, 1, -12)
HeaderFix.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

-- Title
local Title = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SIEXTHER SKY"
Title.TextColor3 = Color3.fromRGB(70, 130, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Minimize Button
local MinimizeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 28, 0, 28)
MinimizeBtn.Position = UDim2.new(1, -64, 0.5, -14)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MinimizeBtn.Text = "–"
MinimizeBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
MinimizeBtn.TextSize = 16
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.AutoButtonColor = false
MinimizeBtn.Parent = Header

local MinimizeCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 7)
MinimizeCorner.Parent = MinimizeBtn

-- Close Button
local CloseBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -32, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 70, 70)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Header

local CloseCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 7)
CloseCorner.Parent = CloseBtn

-- Minimized Button
local MinimizedBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
MinimizedBtn.Name = "MinimizedBtn"
MinimizedBtn.Size = UDim2.new(0, 41, 0, 41)
MinimizedBtn.Position = UDim2.new(1, -70, 0.5, -22)
MinimizedBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MinimizedBtn.Text = "🌤️"
MinimizedBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
MinimizedBtn.TextSize = 20
MinimizedBtn.Font = Enum.Font.GothamBold
MinimizedBtn.BorderSizePixel = 0
MinimizedBtn.Visible = false
MinimizedBtn.Active = true
MinimizedBtn.Draggable = true
MinimizedBtn.AutoButtonColor = false
MinimizedBtn.Parent = ScreenGui


local MinimizedCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
MinimizedCorner.CornerRadius = UDim.new(0, 12)
MinimizedCorner.Parent = MinimizedBtn


-- Content Frame
local ContentFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -24, 1, -52)
ContentFrame.Position = UDim2.new(0, 12, 0, 46)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Info Label
local InfoLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
InfoLabel.Name = "InfoLabel"
InfoLabel.Size = UDim2.new(1, 0, 0, 18)
InfoLabel.Position = UDim2.new(0, 0, 0, 0)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "SAAT INI: Default"
InfoLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
InfoLabel.TextSize = 12
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.Parent = ContentFrame

-- Scroll Frame for Options (Grid Layout)
local ScrollFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScrollingFrame")
ScrollFrame.Name = "ScrollFrame"
ScrollFrame.Size = UDim2.new(1, 0, 1, -25)
ScrollFrame.Position = UDim2.new(0, 0, 0, 22)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent = ContentFrame

local ScrollCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(0, 8)
ScrollCorner.Parent = ScrollFrame

-- Grid Layout (2 kolom, compact)
local GridLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGridLayout")
GridLayout.CellSize = UDim2.new(0.5, -6, 0, 55)
GridLayout.CellPadding = UDim2.new(0, 4, 0, 4)
GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
GridLayout.Parent = ScrollFrame

local ScrollPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
ScrollPadding.PaddingTop = UDim.new(0, 8)
ScrollPadding.PaddingBottom = UDim.new(0, 8)
ScrollPadding.PaddingLeft = UDim.new(0, 8)
ScrollPadding.PaddingRight = UDim.new(0, 8)
ScrollPadding.Parent = ScrollFrame

-- Day Cycle Presets
local presets = {
    {
        name = "☀️ Pagi",
        shortName = "Pagi",
        emoji = "☀️",
        timeOfDay = 7,
        settings = {
            Brightness = 2,
            ColorShift_Top = Color3.fromRGB(255, 200, 150),
            ColorShift_Bottom = Color3.fromRGB(255, 230, 200),
            OutdoorAmbient = Color3.fromRGB(180, 180, 180),
            Ambient = Color3.fromRGB(150, 150, 150),
            FogColor = Color3.fromRGB(200, 220, 255),
            FogEnd = 100000,
            FogStart = 0,
            ClockTime = 7
        }
    },
    {
        name = "🌞 Siang",
        shortName = "Siang",
        emoji = "🌞",
        timeOfDay = 12,
        settings = {
            Brightness = 3,
            ColorShift_Top = Color3.fromRGB(0, 0, 0),
            ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
            OutdoorAmbient = Color3.fromRGB(127, 127, 127),
            Ambient = Color3.fromRGB(100, 100, 100),
            FogColor = Color3.fromRGB(191, 191, 191),
            FogEnd = 100000,
            FogStart = 0,
            ClockTime = 12
        }
    },
    {
        name = "🌅 Sore",
        shortName = "Sore",
        emoji = "🌅",
        timeOfDay = 18,
        settings = {
            Brightness = 1.5,
            ColorShift_Top = Color3.fromRGB(255, 100, 50),
            ColorShift_Bottom = Color3.fromRGB(255, 150, 100),
            OutdoorAmbient = Color3.fromRGB(150, 100, 80),
            Ambient = Color3.fromRGB(120, 80, 60),
            FogColor = Color3.fromRGB(255, 150, 100),
            FogEnd = 80000,
            FogStart = 0,
            ClockTime = 18
        }
    },
    {
        name = "🌙 Malam",
        shortName = "Malam",
        emoji = "🌙",
        timeOfDay = 0,
        settings = {
            Brightness = 0.5,
            ColorShift_Top = Color3.fromRGB(0, 0, 50),
            ColorShift_Bottom = Color3.fromRGB(0, 0, 30),
            OutdoorAmbient = Color3.fromRGB(50, 50, 80),
            Ambient = Color3.fromRGB(30, 30, 50),
            FogColor = Color3.fromRGB(20, 20, 40),
            FogEnd = 50000,
            FogStart = 0,
            ClockTime = 0
        }
    },
    {
        name = "🌧️ Hujan",
        shortName = "Hujan",
        emoji = "🌧️",
        timeOfDay = 14,
        settings = {
            Brightness = 1,
            ColorShift_Top = Color3.fromRGB(100, 100, 120),
            ColorShift_Bottom = Color3.fromRGB(80, 80, 100),
            OutdoorAmbient = Color3.fromRGB(100, 100, 110),
            Ambient = Color3.fromRGB(80, 80, 90),
            FogColor = Color3.fromRGB(150, 150, 160),
            FogEnd = 40000,
            FogStart = 0,
            ClockTime = 14
        },
        effects = {"rain"}
    },
    {
        name = "❄️ Salju",
        shortName = "Salju",
        emoji = "❄️",
        timeOfDay = 10,
        settings = {
            Brightness = 2.5,
            ColorShift_Top = Color3.fromRGB(200, 220, 255),
            ColorShift_Bottom = Color3.fromRGB(220, 230, 255),
            OutdoorAmbient = Color3.fromRGB(180, 200, 220),
            Ambient = Color3.fromRGB(160, 180, 200),
            FogColor = Color3.fromRGB(230, 240, 255),
            FogEnd = 50000,
            FogStart = 0,
            ClockTime = 10
        },
        effects = {"snow"}
    },
    {
        name = "🌫️ Kabut",
        shortName = "Kabut",
        emoji = "🌫️",
        timeOfDay = 6,
        settings = {
            Brightness = 0.8,
            ColorShift_Top = Color3.fromRGB(180, 180, 190),
            ColorShift_Bottom = Color3.fromRGB(160, 160, 170),
            OutdoorAmbient = Color3.fromRGB(120, 120, 130),
            Ambient = Color3.fromRGB(100, 100, 110),
            FogColor = Color3.fromRGB(200, 200, 210),
            FogEnd = 200,
            FogStart = 0,
            ClockTime = 6
        },
        effects = {"fog"}
    },
    {
        name = "⛈️ Badai",
        shortName = "Badai",
        emoji = "⛈️",
        timeOfDay = 15,
        settings = {
            Brightness = 0.5,
            ColorShift_Top = Color3.fromRGB(50, 50, 70),
            ColorShift_Bottom = Color3.fromRGB(30, 30, 50),
            OutdoorAmbient = Color3.fromRGB(60, 60, 80),
            Ambient = Color3.fromRGB(40, 40, 60),
            FogColor = Color3.fromRGB(80, 80, 100),
            FogEnd = 25000,
            FogStart = 0,
            ClockTime = 15
        },
        effects = {"rain", "wind"}
    },
    {
        name = "🌆 Sunset",
        shortName = "Sunset",
        emoji = "🌆",
        timeOfDay = 19,
        settings = {
            Brightness = 1,
            ColorShift_Top = Color3.fromRGB(255, 80, 0),
            ColorShift_Bottom = Color3.fromRGB(255, 120, 50),
            OutdoorAmbient = Color3.fromRGB(130, 70, 50),
            Ambient = Color3.fromRGB(100, 60, 40),
            FogColor = Color3.fromRGB(255, 100, 50),
            FogEnd = 70000,
            FogStart = 0,
            ClockTime = 19
        }
    },
    {
        name = "🔄 Random",
        shortName = "Random",
        emoji = "🔄",
        timeOfDay = 12,
        settings = {
            Brightness = 2,
            ColorShift_Top = Color3.fromRGB(0, 0, 0),
            ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
            OutdoorAmbient = Color3.fromRGB(127, 127, 127),
            Ambient = Color3.fromRGB(100, 100, 100),
            FogColor = Color3.fromRGB(191, 191, 191),
            FogEnd = 100000,
            FogStart = 0,
            ClockTime = 12
        },
        effects = {"random_cycle"}
    }
}

-- Variables
local currentPreset = nil
local activeEffects = {}
local auroraConnection = nil
local randomCycleRunning = false
local randomCycleConnection = nil
local activeButton = nil

-- Random cycle presets
local cyclePresets = {
    {
        name = "Pagi",
        settings = {
            Brightness = 2,
            ColorShift_Top = Color3.fromRGB(255, 200, 150),
            ColorShift_Bottom = Color3.fromRGB(255, 230, 200),
            OutdoorAmbient = Color3.fromRGB(180, 180, 180),
            Ambient = Color3.fromRGB(150, 150, 150),
            FogColor = Color3.fromRGB(200, 220, 255),
            FogEnd = 100000,
            FogStart = 0,
            ClockTime = 7
        }
    },
    {
        name = "Siang",
        settings = {
            Brightness = 3,
            ColorShift_Top = Color3.fromRGB(0, 0, 0),
            ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
            OutdoorAmbient = Color3.fromRGB(127, 127, 127),
            Ambient = Color3.fromRGB(100, 100, 100),
            FogColor = Color3.fromRGB(191, 191, 191),
            FogEnd = 100000,
            FogStart = 0,
            ClockTime = 12
        }
    },
    {
        name = "Sore",
        settings = {
            Brightness = 1.5,
            ColorShift_Top = Color3.fromRGB(255, 100, 50),
            ColorShift_Bottom = Color3.fromRGB(255, 150, 100),
            OutdoorAmbient = Color3.fromRGB(150, 100, 80),
            Ambient = Color3.fromRGB(120, 80, 60),
            FogColor = Color3.fromRGB(255, 150, 100),
            FogEnd = 80000,
            FogStart = 0,
            ClockTime = 18
        }
    },
    {
        name = "Malam",
        settings = {
            Brightness = 0.5,
            ColorShift_Top = Color3.fromRGB(0, 0, 50),
            ColorShift_Bottom = Color3.fromRGB(0, 0, 30),
            OutdoorAmbient = Color3.fromRGB(50, 50, 80),
            Ambient = Color3.fromRGB(30, 30, 50),
            FogColor = Color3.fromRGB(20, 20, 40),
            FogEnd = 50000,
            FogStart = 0,
            ClockTime = 0
        }
    }
}

-- Function to clear effects
local function clearEffects()
    for _, effect in ipairs(activeEffects) do
        if effect and effect.Parent then
            effect:Destroy()
        end
    end
    activeEffects = {}
    
    if auroraConnection then
        auroraConnection:Disconnect()
        auroraConnection = nil
    end
    
    if randomCycleConnection then
        randomCycleConnection:Disconnect()
        randomCycleConnection = nil
        randomCycleRunning = false
    end
end

-- Function to create rain effect
local function createRainEffect()
    local rain = __SIEXTHER_VIP_GLASS_V1.Instance.new("ParticleEmitter")
    rain.Name = "RainEffect"
    rain.Texture = "rbxasset://textures/particles/smoke_main.dds"
    rain.Color = ColorSequence.new(Color3.fromRGB(150, 180, 200))
    rain.Size = NumberSequence.new(0.3)
    rain.Transparency = NumberSequence.new(0.5)
    rain.Lifetime = NumberRange.new(1, 2)
    rain.Rate = 300
    rain.Speed = NumberRange.new(50, 80)
    rain.SpreadAngle = Vector2.new(10, 10)
    rain.VelocityInheritance = -0.5
    rain.Acceleration = Vector3.new(0, -100, 0)
    rain.Parent = workspace.CurrentCamera
    
    table.insert(activeEffects, rain)
    return rain
end

-- Function to create snow effect
local function createSnowEffect()
    local snow = __SIEXTHER_VIP_GLASS_V1.Instance.new("ParticleEmitter")
    snow.Name = "SnowEffect"
    snow.Texture = "rbxasset://textures/particles/smoke_main.dds"
    snow.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    snow.Size = NumberSequence.new(0.2, 0.4)
    snow.Transparency = NumberSequence.new(0)
    snow.Lifetime = NumberRange.new(5, 8)
    snow.Rate = 100
    snow.Speed = NumberRange.new(5, 10)
    snow.SpreadAngle = Vector2.new(20, 20)
    snow.Rotation = NumberRange.new(0, 360)
    snow.RotSpeed = NumberRange.new(-50, 50)
    snow.VelocityInheritance = -0.3
    snow.Acceleration = Vector3.new(0, -5, 0)
    snow.Parent = workspace.CurrentCamera
    
    table.insert(activeEffects, snow)
    return snow
end

-- Function to create fog effect
local function createFogEffect()
    for i = 1, 3 do
        local fog = __SIEXTHER_VIP_GLASS_V1.Instance.new("ParticleEmitter")
        fog.Name = "FogEffect_" .. i
        fog.Texture = "rbxasset://textures/particles/smoke_main.dds"
        fog.Color = ColorSequence.new(Color3.fromRGB(200, 200, 210))
        fog.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 20),
            NumberSequenceKeypoint.new(0.5, 30),
            NumberSequenceKeypoint.new(1, 40)
        }
        fog.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(0.5, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        }
        fog.Lifetime = NumberRange.new(8, 12)
        fog.Rate = 15
        fog.Speed = NumberRange.new(2, 5)
        fog.SpreadAngle = Vector2.new(180, 180)
        fog.Rotation = NumberRange.new(0, 360)
        fog.RotSpeed = NumberRange.new(-10, 10)
        fog.VelocityInheritance = -0.2
        fog.Acceleration = Vector3.new(0, 0.5, 0)
        fog.Parent = workspace.CurrentCamera
        
        table.insert(activeEffects, fog)
    end
end

-- Function to start random cycle
local function startRandomCycle()
    randomCycleRunning = true
    
    local function applyCyclePreset(cyclePreset)
        local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        
        for property, value in pairs(cyclePreset.settings) do
            if Lighting:FindFirstChild(property) or property == "ClockTime" or property == "Brightness" or property == "Ambient" or property == "OutdoorAmbient" or property == "FogEnd" or property == "FogStart" or property == "FogColor" or property == "ColorShift_Top" or property == "ColorShift_Bottom" then
                local tween = TweenService:Create(Lighting, tweenInfo, {[property] = value})
                tween:Play()
            end
        end
        
        InfoLabel.Text = "Random Cycle: " .. cyclePreset.name
    end
    
    spawn(function()
        local currentIndex = 1
        
        while randomCycleRunning do
            applyCyclePreset(cyclePresets[currentIndex])
            wait(300)
            
            currentIndex = currentIndex + 1
            if currentIndex > #cyclePresets then
                currentIndex = 1
            end
        end
    end)
end

-- Function to apply preset
local function applyPreset(preset)
    clearEffects()
    
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    
    for property, value in pairs(preset.settings) do
        if Lighting:FindFirstChild(property) or property == "ClockTime" or property == "Brightness" or property == "Ambient" or property == "OutdoorAmbient" or property == "FogEnd" or property == "FogStart" or property == "FogColor" or property == "ColorShift_Top" or property == "ColorShift_Bottom" then
            local tween = TweenService:Create(Lighting, tweenInfo, {[property] = value})
            tween:Play()
        end
    end
    
    if preset.effects then
        task.wait(0.5)
        
        for _, effect in ipairs(preset.effects) do
            if effect == "rain" then
                createRainEffect()
            elseif effect == "snow" then
                createSnowEffect()
            elseif effect == "fog" then
                createFogEffect()
            elseif effect == "random_cycle" then
                startRandomCycle()
            end
        end
    end
    
    currentPreset = preset.name
    if not randomCycleRunning then
        InfoLabel.Text = "SAAT INI: " .. preset.shortName
    end
end

-- Function to create preset button (Dark Modern)
local function createPresetButton(preset, index)
    local PresetBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    PresetBtn.Name = "Preset_" .. index
    PresetBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    PresetBtn.BorderSizePixel = 0
    PresetBtn.Text = ""
    PresetBtn.AutoButtonColor = false
    PresetBtn.LayoutOrder = index
    PresetBtn.Parent = ScrollFrame
    
    local PresetCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
    PresetCorner.CornerRadius = UDim.new(0, 8)
    PresetCorner.Parent = PresetBtn
    
    -- Emoji
    local EmojiLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
    EmojiLabel.Size = UDim2.new(1, 0, 0, 24)
    EmojiLabel.Position = UDim2.new(0, 0, 0, 4)
    EmojiLabel.BackgroundTransparency = 1
    EmojiLabel.Text = preset.emoji
    EmojiLabel.TextSize = 20
    EmojiLabel.Font = Enum.Font.GothamBold
    EmojiLabel.Parent = PresetBtn
    
    -- Name
    local NameLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -8, 0, 18)
    NameLabel.Position = UDim2.new(0, 4, 0, 30)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = preset.shortName
    NameLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    NameLabel.TextSize = 10
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Center
    NameLabel.Parent = PresetBtn
    
    -- Click event
    PresetBtn.MouseButton1Click:Connect(function()
        -- Reset previous active button
        if activeButton and activeButton ~= PresetBtn then
            activeButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        end
        
        -- Set new active button
        activeButton = PresetBtn
        PresetBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        
        applyPreset(preset)
    end)
    
    -- Hover effect
    PresetBtn.MouseEnter:Connect(function()
        if activeButton ~= PresetBtn then
            PresetBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        end
    end)
    
    PresetBtn.MouseLeave:Connect(function()
        if activeButton ~= PresetBtn then
            PresetBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        end
    end)
    
    return PresetBtn
end

-- Create all preset buttons
for i, preset in ipairs(presets) do
    createPresetButton(preset, i)
end

-- Update canvas size
task.wait(0.1)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#presets / 2) * 59 + 16)

-- Minimize/Maximize
local function minimizeGUI()
    MainFrame.Visible = false
    MinimizedBtn.Visible = true
end

local function maximizeGUI()
    MinimizedBtn.Visible = false
    MainFrame.Visible = true
end

MinimizeBtn.MouseButton1Click:Connect(function()
    minimizeGUI()
end)

MinimizedBtn.MouseButton1Click:Connect(function()
    maximizeGUI()
end)

-- Close Button
CloseBtn.MouseButton1Click:Connect(function()
    clearEffects()
    ScreenGui:Destroy()
end)

-- Cleanup on player leaving
LocalPlayer.AncestryChanged:Connect(function()
    if not LocalPlayer:IsDescendantOf(game) then
        clearEffects()
    end
end)
