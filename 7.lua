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


local ScreenGui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
ScreenGui.Name = "ModernAudioScanner"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
local MainFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 280)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local outerStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
outerStroke.Color = Color3.fromRGB(70, 130, 255)
outerStroke.Thickness = 2
outerStroke.Parent = MainFrame

local mainCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = MainFrame

-- Title Bar
local TitleBar = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 28)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local titleCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = TitleBar

local TitleLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -70, 1, 0)
TitleLabel.Position = UDim2.new(0, 8, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "SIEXTHER AUDIO SCANNER"
TitleLabel.TextColor3 = Color3.fromRGB(70, 130, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Close Button
local CloseButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
CloseButton.Name = "Close"
CloseButton.Size = UDim2.new(0, 24, 0, 20)
CloseButton.Position = UDim2.new(1, -26, 0, 4)
CloseButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 13
CloseButton.BorderSizePixel = 0
CloseButton.Parent = TitleBar

local closeCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = CloseButton

-- Minimize Button
local MinimizeButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
MinimizeButton.Name = "Minimize"
MinimizeButton.Size = UDim2.new(0, 24, 0, 20)
MinimizeButton.Position = UDim2.new(1, -52, 0, 4)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(50, 130, 180)
MinimizeButton.Text = "–"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 15
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Parent = TitleBar

local minCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 5)
minCorner.Parent = MinimizeButton

-- ScrollingFrame for Audio Logs
local LogsFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScrollingFrame")
LogsFrame.Name = "Logs"
LogsFrame.Size = UDim2.new(1, -16, 1, -68)
LogsFrame.Position = UDim2.new(0, 8, 0, 34)
LogsFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 22)
LogsFrame.BorderSizePixel = 0
LogsFrame.ScrollBarThickness = 4
LogsFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
LogsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
LogsFrame.Parent = MainFrame

local logsCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
logsCorner.CornerRadius = UDim.new(0, 8)
logsCorner.Parent = LogsFrame

-- Scan Button
local ScanButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
ScanButton.Name = "Scan"
ScanButton.Size = UDim2.new(1, -16, 0, 28)
ScanButton.Position = UDim2.new(0, 8, 1, -33)
ScanButton.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
ScanButton.Text = "SCAN"
ScanButton.TextColor3 = Color3.fromRGB(200, 200, 200)
ScanButton.Font = Enum.Font.GothamBold
ScanButton.TextSize = 12
ScanButton.BorderSizePixel = 0
ScanButton.Parent = MainFrame

local scanCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
scanCorner.CornerRadius = UDim.new(0, 6)
scanCorner.Parent = ScanButton

local scanStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
scanStroke.Color = Color3.fromRGB(50, 55, 65)
scanStroke.Thickness = 1
scanStroke.Parent = ScanButton

-- Loading Bar
local LoadBar = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
LoadBar.Name = "Load"
LoadBar.Size = UDim2.new(0, 0, 0, 2)
LoadBar.Position = UDim2.new(0, 0, 0, 33)
LoadBar.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
LoadBar.BorderSizePixel = 0
LoadBar.Visible = false
LoadBar.Parent = MainFrame

-- Audio Item Template
local AudioTemplate = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
AudioTemplate.Name = "Audio"
AudioTemplate.Size = UDim2.new(1, -10, 0, 26)
AudioTemplate.BackgroundColor3 = Color3.fromRGB(25, 30, 38)
AudioTemplate.BorderSizePixel = 0
AudioTemplate.Visible = false
AudioTemplate.Parent = LogsFrame

local audioCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
audioCorner.CornerRadius = UDim.new(0, 6)
audioCorner.Parent = AudioTemplate

local AudioIcon = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
AudioIcon.Name = "Icon"
AudioIcon.Size = UDim2.new(0, 22, 0, 22)
AudioIcon.Position = UDim2.new(0, 3, 0.5, -11)
AudioIcon.BackgroundTransparency = 1
AudioIcon.Text = "🎵"
AudioIcon.TextSize = 16
AudioIcon.TextColor3 = Color3.fromRGB(135, 206, 250)
AudioIcon.Parent = AudioTemplate

local AudioLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
AudioLabel.Name = "TextLabel"
AudioLabel.Size = UDim2.new(1, -60, 1, 0)
AudioLabel.Position = UDim2.new(0, 28, 0, 0)
AudioLabel.BackgroundTransparency = 1
AudioLabel.Text = "Audio Name"
AudioLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
AudioLabel.Font = Enum.Font.Gotham
AudioLabel.TextSize = 10
AudioLabel.TextXAlignment = Enum.TextXAlignment.Left
AudioLabel.TextTruncate = Enum.TextTruncate.AtEnd
AudioLabel.Parent = AudioTemplate

local ClickButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
ClickButton.Name = "Click"
ClickButton.Size = UDim2.new(1, 0, 1, 0)
ClickButton.BackgroundTransparency = 1
ClickButton.Text = ""
ClickButton.Parent = AudioTemplate

-- Info Panel
local InfoPanel = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
InfoPanel.Name = "Info"
InfoPanel.Size = UDim2.new(0, 280, 0, 240)
InfoPanel.Position = UDim2.new(0.5, -140, 0.5, -120)
InfoPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
InfoPanel.BorderSizePixel = 0
InfoPanel.Visible = false
InfoPanel.Parent = ScreenGui

local infoStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
infoStroke.Color = Color3.fromRGB(70, 130, 255)
infoStroke.Thickness = 2
infoStroke.Parent = InfoPanel

local infoCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 10)
infoCorner.Parent = InfoPanel

local InfoTitle = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
InfoTitle.Size = UDim2.new(1, -35, 0, 26)
InfoTitle.Position = UDim2.new(0, 8, 0, 4)
InfoTitle.BackgroundTransparency = 1
InfoTitle.Text = "SIEXTHER AUDIO"
InfoTitle.TextColor3 = Color3.fromRGB(70, 130, 255)
InfoTitle.Font = Enum.Font.GothamBold
InfoTitle.TextSize = 12
InfoTitle.TextXAlignment = Enum.TextXAlignment.Left
InfoTitle.Parent = InfoPanel

local InfoClose = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
InfoClose.Name = "Close"
InfoClose.Size = UDim2.new(0, 22, 0, 22)
InfoClose.Position = UDim2.new(1, -26, 0, 4)
InfoClose.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
InfoClose.Text = "X"
InfoClose.TextColor3 = Color3.fromRGB(255, 255, 255)
InfoClose.Font = Enum.Font.GothamBold
InfoClose.TextSize = 12
InfoClose.BorderSizePixel = 0
InfoClose.Parent = InfoPanel

local infoCloseCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
infoCloseCorner.CornerRadius = UDim.new(0, 6)
infoCloseCorner.Parent = InfoClose

local InfoText = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
InfoText.Name = "TextLabel"
InfoText.Size = UDim2.new(1, -16, 0, 40)
InfoText.Position = UDim2.new(0, 8, 0, 34)
InfoText.BackgroundColor3 = Color3.fromRGB(15, 18, 22)
InfoText.Text = ""
InfoText.TextColor3 = Color3.fromRGB(200, 200, 200)
InfoText.Font = Enum.Font.GothamBold
InfoText.TextSize = 11
InfoText.TextWrapped = true
InfoText.BorderSizePixel = 0
InfoText.Parent = InfoPanel

local infoTextCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
infoTextCorner.CornerRadius = UDim.new(0, 6)
infoTextCorner.Parent = InfoText

local padding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingTop = UDim.new(0, 8)
padding.Parent = InfoText

-- RGB Visualizer
local VisualizerFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
VisualizerFrame.Name = "Visualizer"
VisualizerFrame.Size = UDim2.new(1, -16, 0, 100)
VisualizerFrame.Position = UDim2.new(0, 8, 0, 82)
VisualizerFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 22)
VisualizerFrame.BorderSizePixel = 0
VisualizerFrame.Parent = InfoPanel

local vizCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
vizCorner.CornerRadius = UDim.new(0, 6)
vizCorner.Parent = VisualizerFrame

local bars = {}
for i = 1, 20 do
	local bar = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
	bar.Name = "Bar" .. i
	bar.Size = UDim2.new(0, 10, 0, 5)
	bar.Position = UDim2.new(0, (i-1) * 13 + 5, 1, -10)
	bar.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
	bar.BorderSizePixel = 0
	bar.AnchorPoint = Vector2.new(0, 1)
	bar.Parent = VisualizerFrame
	local barCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 2)
	barCorner.Parent = bar
	bars[i] = bar
end

-- Button Container for Info Panel
local InfoButtonContainer = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
InfoButtonContainer.Size = UDim2.new(1, -16, 0, 30)
InfoButtonContainer.Position = UDim2.new(0, 8, 1, -34)
InfoButtonContainer.BackgroundTransparency = 1
InfoButtonContainer.Parent = InfoPanel

local CopyButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
CopyButton.Name = "Copy"
CopyButton.Size = UDim2.new(0.31, 0, 1, 0)
CopyButton.Position = UDim2.new(0, 0, 0, 0)
CopyButton.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
CopyButton.Text = "COPY ID"
CopyButton.TextColor3 = Color3.fromRGB(200, 200, 200)
CopyButton.Font = Enum.Font.GothamBold
CopyButton.TextSize = 10
CopyButton.BorderSizePixel = 0
CopyButton.Parent = InfoButtonContainer
local copyCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
copyCorner.CornerRadius = UDim.new(0, 6)
copyCorner.Parent = CopyButton
local copyStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
copyStroke.Color = Color3.fromRGB(50, 55, 65)
copyStroke.Thickness = 1
copyStroke.Parent = CopyButton

local ListenButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
ListenButton.Name = "Listen"
ListenButton.Size = UDim2.new(0.31, 0, 1, 0)
ListenButton.Position = UDim2.new(0.345, 0, 0, 0)
ListenButton.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
ListenButton.Text = "PLAY"
ListenButton.TextColor3 = Color3.fromRGB(200, 200, 200)
ListenButton.Font = Enum.Font.GothamBold
ListenButton.TextSize = 10
ListenButton.BorderSizePixel = 0
ListenButton.Parent = InfoButtonContainer
local listenCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
listenCorner.CornerRadius = UDim.new(0, 6)
listenCorner.Parent = ListenButton
local listenStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
listenStroke.Color = Color3.fromRGB(50, 55, 65)
listenStroke.Thickness = 1
listenStroke.Parent = ListenButton

local DownloadButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
DownloadButton.Name = "Download"
DownloadButton.Size = UDim2.new(0.31, 0, 1, 0)
DownloadButton.Position = UDim2.new(0.69, 0, 0, 0)
DownloadButton.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
DownloadButton.Text = "UNDUH"
DownloadButton.TextColor3 = Color3.fromRGB(200, 200, 200)
DownloadButton.Font = Enum.Font.GothamBold
DownloadButton.TextSize = 10
DownloadButton.BorderSizePixel = 0
DownloadButton.Parent = InfoButtonContainer
local downloadCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
downloadCorner.CornerRadius = UDim.new(0, 6)
downloadCorner.Parent = DownloadButton
local downloadStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
downloadStroke.Color = Color3.fromRGB(50, 55, 65)
downloadStroke.Thickness = 1
downloadStroke.Parent = DownloadButton

-- Floating Button
local FloatingButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
FloatingButton.Name = "FloatingButton"
FloatingButton.Size = UDim2.new(0, 41, 0, 41)
FloatingButton.Position = UDim2.new(1, -55, 0.5, -21)
FloatingButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
FloatingButton.Text = "🎵"
FloatingButton.TextSize = 20
FloatingButton.Font = Enum.Font.GothamBold
FloatingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingButton.BorderSizePixel = 0
FloatingButton.Visible = false
FloatingButton.Parent = ScreenGui
local fbCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
fbCorner.CornerRadius = UDim.new(0, 12)
fbCorner.Parent = FloatingButton

-- Load Notify
__SIEXTHER_VIP_GLASS_V1.LoadString(game:HttpGet("https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/han.lua"))()

local function CustomNotify(title, content)
	getgenv().Notify({
		Title = title,
		Content = content,
		Duration = 2
	})
end

-- ============================================================
-- STATE VARIABLES
-- ============================================================
local selectedaudio = nil
local selectedaudioname = nil
local min = false
local visualizerRunning = false

-- Scan engine state (dari script 2)
local on = true       -- script aktif
local sc = false      -- sedang scanning
local swept = false   -- sudah di-sweep
local cnt = 0
local f = {}          -- found sounds {num -> {n=name, o=obj, sid=soundId}}
local r = {}          -- row frames {num -> frame}
local cn = {}         -- connections
local pos = 0         -- posisi list di LogsFrame

-- ============================================================
-- VISUALIZER
-- ============================================================
function startVisualizer()
	visualizerRunning = true
	spawn(function()
		while visualizerRunning do
			for i, bar in pairs(bars) do
				local height = math.random(10, 90)
				local hue = (tick() * 50 + i * 10) % 360
				bar:TweenSize(UDim2.new(0, 10, 0, height), "Out", "Sine", 0.1, true)
				bar.BackgroundColor3 = Color3.fromHSV(hue / 360, 1, 1)
			end
			wait(0.1)
		end
	end)
end

function stopVisualizer()
	visualizerRunning = false
	for i, bar in pairs(bars) do
		bar.Size = UDim2.new(0, 10, 0, 5)
		bar.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
	end
end

-- ============================================================
-- SCAN ENGINE (dari script 2, diintegrasikan ke GUI SIEXTHER)
-- ============================================================

-- Tambah row audio ke LogsFrame SIEXTHER
local function addAudioRow(soundId, audioname, soundObj)
	local newsound = AudioTemplate:Clone()
	newsound.Parent = LogsFrame
	newsound.Name = soundId
	newsound.Visible = true
	newsound.Position = UDim2.new(0, 5, 0, pos)
	LogsFrame.CanvasSize = UDim2.new(0, 0, 0, pos + 31)
	pos = pos + 31
	newsound.TextLabel.Text = audioname

	local data = __SIEXTHER_VIP_GLASS_V1.Instance.new("StringValue")
	data.Parent = newsound
	data.Value = soundId
	data.Name = "ID"

	local data2 = __SIEXTHER_VIP_GLASS_V1.Instance.new("StringValue")
	data2.Parent = newsound
	data2.Value = audioname
	data2.Name = "NAME"

	newsound.Click.MouseButton1Click:Connect(function()
		if not InfoPanel.Visible then
			InfoText.Text = audioname
			selectedaudio = soundId
			selectedaudioname = audioname
			InfoPanel.Visible = true
		end
	end)

	return newsound
end

-- Core: coba tambah sound ke list
local function ta(obj)
	if not on then return end
	if typeof(obj) ~= "Instance" then return end

	local s, sid = pcall(function() return obj.SoundId end)
	if not s or not sid or sid == "" then return end
	if not string.find(sid, "rbxassetid") then return end

	local num = sid:match("(%d+)")
	if not num or f[num] then return end

	-- Cek sudah ada di GUI
	if LogsFrame:FindFirstChild(sid) then return end

	local nm = "Unknown"
	pcall(function() nm = obj.Name end)

	-- Coba ambil nama dari MarketplaceService
	local audioname = nm
	pcall(function()
		local info = game:GetService("MarketplaceService"):GetProductInfo(num)
		if info and info.Name then
			audioname = info.Name
		end
	end)

	f[num] = {n = audioname, o = obj, sid = sid}
	r[num] = addAudioRow(sid, audioname, obj)
	cnt = cnt + 1

	TitleLabel.Text = "SIEXTHER (" .. cnt .. ")"
end

-- Sweep semua sumber (game tree, nil instances, modules, gc)
local function dosweep()
	local i = 0

	-- Game tree
	if sc then
		local d = game:GetDescendants()
		for j = 1, #d do
			if not sc then break end
			if typeof(d[j]) == "Instance" then
				local ok, is = pcall(d[j].IsA, d[j], "Sound")
				if ok and is then ta(d[j]) end
			end
			i = i + 1
			if i % 300 == 0 then task.wait() end
		end
		d = nil
		task.wait()
	end

	-- Nil instances
	if sc then
		pcall(function()
			local ni = getnilinstances()
			for j = 1, #ni do
				if not sc then return end
				pcall(function()
					if ni[j]:IsA("Sound") then ta(ni[j]) end
				end)
				i = i + 1
				if i % 300 == 0 then task.wait() end
			end
		end)
		task.wait()
	end

	-- Loaded modules
	if sc then
		pcall(function()
			local md = getloadedmodules()
			for j = 1, #md do
				if not sc then return end
				pcall(function()
					if md[j]:IsA("ModuleScript") then
						local ch = md[j]:GetDescendants()
						for x = 1, #ch do
							if not sc then return end
							pcall(function()
								if ch[x]:IsA("Sound") then ta(ch[x]) end
							end)
							i = i + 1
							if i % 300 == 0 then task.wait() end
						end
					end
				end)
			end
		end)
		task.wait()
	end

	-- All instances
	if sc then
		pcall(function()
			local al = getinstances()
			for j = 1, #al do
				if not sc then return end
				pcall(function()
					if al[j]:IsA("Sound") then ta(al[j]) end
				end)
				i = i + 1
				if i % 300 == 0 then task.wait() end
			end
			al = nil
		end)
		task.wait()
	end

	-- Garbage collector
	if sc then
		pcall(function()
			local gc = getgc(true)
			for j = 1, #gc do
				if not sc then return end
				if typeof(gc[j]) == "Instance" then
					pcall(function()
						if gc[j]:IsA("Sound") then ta(gc[j]) end
					end)
				end
				i = i + 1
				if i % 600 == 0 then task.wait() end
			end
			gc = nil
		end)
	end

	if sc then
		swept = true
		ScanButton.Text = "SCAN"
		ScanButton.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
		sc = false
		CustomNotify("SIEXTHER AUDIO SCANNER", "Scan selesai! " .. cnt .. " audio ditemukan")
	end
end

-- Auto-detect sound baru masuk game
cn[#cn+1] = game.DescendantAdded:Connect(function(obj)
	if not on then return end
	pcall(function()
		if obj:IsA("Sound") then task.defer(ta, obj) end
	end)
end)

-- ============================================================
-- BUTTON EVENTS
-- ============================================================

CloseButton.MouseButton1Click:Connect(function()
	on = false
	sc = false
	for _, c in next, cn do
		pcall(function() c:Disconnect() end)
	end
	ScreenGui:Destroy()
end)

MinimizeButton.MouseButton1Click:Connect(function()
	if min == false then
		MainFrame.Visible = false
		FloatingButton.Visible = true
		min = true
	else
		FloatingButton.Visible = false
		MainFrame.Visible = true
		min = false
	end
end)

FloatingButton.MouseButton1Click:Connect(function()
	FloatingButton.Visible = false
	MainFrame.Visible = true
	min = false
end)

-- Scan Button: toggle scan on/off
ScanButton.MouseButton1Click:Connect(function()
	sc = not sc
	if sc then
		ScanButton.Text = "STOP"
		ScanButton.BackgroundColor3 = Color3.fromRGB(60, 25, 25)
		LoadBar.Visible = true
		LoadBar.Size = UDim2.new(0, 0, 0, 2)
		LoadBar:TweenSize(UDim2.new(1, 0, 0, 2), "Out", "Quad", 0.5, true)
		CustomNotify("SIEXTHER AUDIO SCANNER", "Scanning dimulai...")
		if not swept then
			task.spawn(dosweep)
		end
	else
		ScanButton.Text = "SCAN"
		ScanButton.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
		LoadBar.Visible = false
		LoadBar.Size = UDim2.new(0, 0, 0, 2)
	end
end)

InfoClose.MouseButton1Click:Connect(function()
	InfoPanel.Visible = false
	stopVisualizer()
	for _, sound in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetChildren()) do
		if sound.Name == "SampleSound" then
			sound:Destroy()
		end
	end
	ListenButton.Text = "PLAY"
end)

ListenButton.MouseButton1Click:Connect(function()
	if ListenButton.Text == "PLAY" then
		local samplesound = __SIEXTHER_VIP_GLASS_V1.Instance.new("Sound")
		samplesound.Parent = game:GetService("Players").LocalPlayer.PlayerGui
		samplesound.Looped = true
		samplesound.SoundId = selectedaudio
		samplesound:Play()
		samplesound.Name = "SampleSound"
		samplesound.Volume = 1
		ListenButton.Text = "STOP"
		startVisualizer()
	else
		stopVisualizer()
		for _, sound in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetChildren()) do
			if sound.Name == "SampleSound" then
				sound:Destroy()
			end
		end
		ListenButton.Text = "PLAY"
	end
end)

CopyButton.MouseButton1Click:Connect(function()
	if pcall(function() Synapse:Copy(selectedaudio) end) then
	else
		local clip = setclipboard or Clipboard.set
		clip(selectedaudio)
	end
	CustomNotify("SIEXTHER AUDIO SCANNER", "Disalin ke papan klip")
end)

DownloadButton.MouseButton1Click:Connect(function()
	if selectedaudio then
		local id = string.match(selectedaudio, "%d+")
		if id then
			local safefilename = selectedaudioname:gsub("[^%w%s%-_]", ""):gsub("%s+", "_")
			local filename = safefilename .. ".mp3"
			local downloadurl = "https://assetdelivery.roblox.com/v1/asset?id=" .. id
			local success, err = pcall(function()
				if not isfolder("SiextherMusic") then
					makefolder("SiextherMusic")
				end
				local audiodata = game:HttpGet(downloadurl)
				local filepath = "SiextherMusic/" .. filename
				writefile(filepath, audiodata)
				CustomNotify("UNDUHAN SELESAI", filename)
			end)
			if not success then
				local clip = setclipboard or Clipboard.set
				clip(downloadurl)
				CustomNotify("SIEXTHER AUDIO SCANNER", "URL unduhan disalin!")
			end
		else
			CustomNotify("SIEXTHER AUDIO SCANNER", "Terjadi masalah!")
		end
	else
		CustomNotify("SIEXTHER AUDIO SCANNER", "Tidak ada audio yang dipilih!")
	end
end)

-- ============================================================
-- DRAG
-- ============================================================
function drag(gui)
	spawn(function()
		local UserInputService = game:GetService("UserInputService")
		local dragging, dragInput, dragStart, startPos
		local function update(input)
			local delta = input.Position - dragStart
			gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
		gui.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = gui.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		gui.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if input == dragInput and dragging then
				update(input)
			end
		end)
	end)
end

drag(MainFrame)
drag(FloatingButton)

-- Notifikasi awal
CustomNotify("SIEXTHER AUDIO SCANNER", "Siap! Tekan SCAN untuk mulai")