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
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LclPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- Fungsi helper dari script asli
local function cloneref(obj)
    return obj
end

-- Semua fungsi utility dari script asli
function isNumber(p235)
    if tonumber(p235) ~= nil or p235 == "inf" then
        return true
    end
end

function GetPlayer(p198, _)
    local v199 = Players.LocalPlayer
    if p198 == nil then
        return {v199.Name}
    end
    local results = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if string.find(string.lower(player.Name), string.lower(p198)) or 
           string.find(string.lower(player.DisplayName), string.lower(p198)) then
            table.insert(results, player.Name)
        end
    end
    return results
end

-- Fungsi blackhole dari script asli
local vu652 = true
function suckblackhole(pu653, pu654)
    vu652 = true
    local v655 = __SIEXTHER_VIP_GLASS_V1.Instance.new("Folder", workspace)
    local v656 = __SIEXTHER_VIP_GLASS_V1.Instance.new("Part", v655)
    local vu657 = __SIEXTHER_VIP_GLASS_V1.Instance.new("Attachment", v656)
    v656.Anchored = true
    v656.CanCollide = false
    v656.Transparency = 1
    
    function ForcePart(p658)
        if p658:IsA("BasePart") and p658.Anchored == false and 
           not p658:IsDescendantOf(LclPlayer.Character) and
           p658.Name ~= "Torso" and p658.Name ~= "Head" and
           p658.Name ~= "HumanoidRootPart" then
            
            for _, v in ipairs(p658:GetChildren()) do
                if v:IsA("BodyAngularVelocity") or v:IsA("BodyForce") or 
                   v:IsA("BodyGyro") or v:IsA("BodyPosition") then
                    v:Destroy()
                end
            end
            
            if p658:FindFirstChild("Attachment") then
                p658:FindFirstChild("Attachment"):Destroy()
            end
            if p658:FindFirstChild("AlignPosition") then
                p658:FindFirstChild("AlignPosition"):Destroy()
            end
            if p658:FindFirstChild("Torque") then
                p658:FindFirstChild("Torque"):Destroy()
            end
            
            p658.CanCollide = false
            local v663 = __SIEXTHER_VIP_GLASS_V1.Instance.new("Torque", p658)
            v663.Torque = Vector3.new(100000, 100000, 100000)
            local v664 = __SIEXTHER_VIP_GLASS_V1.Instance.new("AlignPosition", p658)
            local v665 = __SIEXTHER_VIP_GLASS_V1.Instance.new("Attachment", p658)
            v663.Attachment0 = v665
            v664.MaxForce = 9999999999999998
            v664.MaxVelocity = math.huge
            v664.Responsiveness = 200
            v664.Attachment0 = v665
            v664.Attachment1 = vu657
        end
    end
    
    if vu652 then
        for _, v in ipairs(workspace:GetDescendants()) do
            ForcePart(v)
        end
    end
    
    workspace.DescendantAdded:Connect(function(p670)
        if vu652 then
            ForcePart(p670)
        end
    end)
    
    if pu653 then
        LclPlayer:GetMouse().Button1Down:Connect(function()
            if vu652 then
                vu657.WorldCFrame = LclPlayer:GetMouse().Hit
            end
        end)
    else
        spawn(function()
            while vu652 and RunService.RenderStepped:Wait() do
                pcall(function()
                    vu657.WorldCFrame = pu654.Character:FindFirstChild("HumanoidRootPart").CFrame
                end)
            end
        end)
    end
end

-- Fungsi delete unanchored parts
local delpar = false
coroutine.wrap(function()
    while task.wait(0.1) do
        if delpar then
            local v601 = {}
            for _, v602 in ipairs(workspace:GetDescendants()) do
                if v602:IsA("BasePart") and v602.Anchored == false and 
                   not v602:IsDescendantOf(LclPlayer.Character) and
                   v602.Name ~= "Torso" and v602.Name ~= "Head" and
                   v602.Name ~= "HumanoidRootPart" then
                    
                    for _, v606 in ipairs(v602:GetChildren()) do
                        if v606:IsA("BodyPosition") or v606:IsA("BodyGyro") then
                            v606:Destroy()
                        end
                    end
                    
                    local v607 = __SIEXTHER_VIP_GLASS_V1.Instance.new("BodyPosition")
                    v607.Parent = v602
                    v607.P = 1000000
                    v607.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    table.insert(v601, v607)
                end
            end
            
            for _, v611 in ipairs(v601) do
                v611.Position = Vector3.new(99999999999, 99999999999, 99999999999)
            end
        end
    end
end)()

-- Fungsi freeze parts (tetap ada untuk keperluan lain)
local frozen = false
local vu612 = nil
local frozenParts = {}

local function freezeParts()
    frozen = true
    local function freezePart(p614)
        if p614:IsA("BasePart") and p614.Anchored == false and
           not p614:IsDescendantOf(LclPlayer.Character) then
            
            for _, v620 in ipairs(p614:GetChildren()) do
                if v620:IsA("BodyPosition") or v620:IsA("BodyGyro") then
                    v620:Destroy()
                end
            end
            
            local v621 = __SIEXTHER_VIP_GLASS_V1.Instance.new("BodyPosition")
            v621.Parent = p614
            v621.Position = p614.Position
            v621.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            
            local v622 = __SIEXTHER_VIP_GLASS_V1.Instance.new("BodyGyro")
            v622.Parent = p614
            v622.CFrame = p614.CFrame
            v622.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            
            if not table.find(frozenParts, p614) then
                table.insert(frozenParts, p614)
            end
        end
    end
    
    for _, v627 in ipairs(workspace:GetDescendants()) do
        freezePart(v627)
    end
    
    vu612 = workspace.DescendantAdded:Connect(freezePart)
end

local function unfreezeParts()
    frozen = false
    if vu612 then
        vu612:Disconnect()
    end
    
    for _, v632 in ipairs(frozenParts) do
        for _, v636 in ipairs(v632:GetChildren()) do
            if v636:IsA("BodyPosition") or v636:IsA("BodyGyro") then
                v636:Destroy()
            end
        end
    end
    frozenParts = {}
end

-- FUNGSI UNANCHOR DARI SCRIPT KEDUA (SAMA PERSIS)
local player = game.Players.LocalPlayer
local aktif = false
local folder, attachment1, koneksi1
local RADIUS = 500

-- Scan part sekitar player
local function scanParts()
    local parts = {}
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return parts end

    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") 
        and not part.Anchored 
        and not part:IsDescendantOf(player.Character) then
            local dist = (part.Position - root.Position).Magnitude
            if dist <= RADIUS then
                table.insert(parts, part)
            end
        end
    end
    return parts
end

-- Apply force ke part
local function applyForce(part)
    if not part or not part.Parent then return end
    part.CanCollide = false

    for _, x in next, part:GetChildren() do
        if x:IsA("BodyAngularVelocity") or x:IsA("BodyForce") or x:IsA("BodyGyro") 
        or x:IsA("BodyPosition") or x:IsA("BodyThrust") or x:IsA("BodyVelocity")
        or x:IsA("RocketPropulsion") then
            x:Destroy()
        end
    end

    if not part:FindFirstChildOfClass("Torque") then
        local torque = __SIEXTHER_VIP_GLASS_V1.Instance.new("Torque", part)
        torque.Torque = Vector3.new(100000,100000,100000)
        local align = __SIEXTHER_VIP_GLASS_V1.Instance.new("AlignPosition", part)
        local at2 = __SIEXTHER_VIP_GLASS_V1.Instance.new("Attachment", part)
        torque.Attachment0 = at2
        align.MaxForce = 9e15
        align.MaxVelocity = math.huge
        align.Responsiveness = 200
        align.Attachment0 = at2
        if attachment1 then
            align.Attachment1 = attachment1
        end
    end

    if attachment1 then
        local dist = (part.Position - attachment1.WorldPosition).Magnitude
        if dist <= RADIUS then
            local arah = (attachment1.WorldPosition - part.Position).Unit
            part.AssemblyLinearVelocity = arah * 200
        end
    end
end

-- === Network stabilizer (aktif hanya saat tombol ON) ===
if not getgenv().Network then
    getgenv().Network = {
        BaseParts = {},
        Velocity = Vector3.new(14.46, 14.46, 14.46)
    }

    function Network.RetainPart(part)
        if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
            table.insert(Network.BaseParts, part)
            part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            part.CanCollide = false
        end
    end
end

local NetworkConnection = nil

local function EnableNetwork()
    if NetworkConnection then return end
    NetworkConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            sethiddenproperty(LclPlayer, "SimulationRadius", math.huge)
        end)
    end)
end

local function DisableNetwork()
    if NetworkConnection then
        NetworkConnection:Disconnect()
        NetworkConnection = nil
    end
end

-- Mulai Unanchor
local function mulaiUnanchor()
    folder = __SIEXTHER_VIP_GLASS_V1.Instance.new("Folder", workspace)
    local part = __SIEXTHER_VIP_GLASS_V1.Instance.new("Part", folder)
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    attachment1 = __SIEXTHER_VIP_GLASS_V1.Instance.new("Attachment", part)

    -- Enable Network saat unanchor aktif
    EnableNetwork()

    task.spawn(function()
        settings().Physics.AllowSleep = false
        while aktif and task.wait() do
            for _, pl in next, game.Players:GetPlayers() do
                if pl ~= player then
                    pl.MaximumSimulationRadius = 0
                    sethiddenproperty(pl, "SimulationRadius", 0)
                end
            end
            player.MaximumSimulationRadius = math.pow(math.huge, math.huge)
            setsimulationradius(math.huge)
        end
    end)

    koneksi1 = game:GetService("RunService").Stepped:Connect(function()
        local list = scanParts()
        for _, v in pairs(list) do
            applyForce(v)
        end
    end)
end

-- Stop Unanchor
local function stopUnanchor()
    -- Disable Network saat unanchor dimatikan
    DisableNetwork()
    
    if koneksi1 then koneksi1:Disconnect() end
    if folder then folder:Destroy() end
    folder, attachment1 = nil, nil
end

-- GUI Creation - Ultra Compact
local ScreenGui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
ScreenGui.Name = "SiextherUnachor"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame (Lebih kecil dan compact)
local MainFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -120)
MainFrame.Size = UDim2.new(0, 250, 0, 240)
MainFrame.ClipsDescendants = true

local MainStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
MainStroke.Parent = MainFrame
MainStroke.Color = Color3.fromRGB(70, 130, 255)
MainStroke.Thickness = 2
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local MainCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
MainCorner.Parent = MainFrame
MainCorner.CornerRadius = UDim.new(0, 10)

-- Title Bar
local TitleBar = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
TitleBar.BorderSizePixel = 0
TitleBar.Size = UDim2.new(1, 0, 0, 28)

local TitleCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
TitleCorner.Parent = TitleBar
TitleCorner.CornerRadius = UDim.new(0, 10)

-- Title Text
local Title = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
Title.Name = "Title"
Title.Parent = TitleBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 8, 0, 0)
Title.Size = UDim2.new(0.65, 0, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "SIEXTHER BROKEN"
Title.TextColor3 = Color3.fromRGB(70, 130, 255)
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left

local TitleGradient = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient")
TitleGradient.Parent = Title
TitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), 
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)), 
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))  
})
TitleGradient.Offset = Vector2.new(-1, 0)
TitleGradient.Rotation = 0

task.spawn(function()
    while Title and Title.Parent do
        TweenService:Create(TitleGradient, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(1, 0)
        }):Play()
        task.wait(2)
        TweenService:Create(TitleGradient, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(-1, 0)
        }):Play()
        task.wait(2)
    end
end)

-- Minimize Button
local MinimizeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Parent = TitleBar
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Position = UDim2.new(1, -48, 0.5, -8)
MinimizeBtn.Size = UDim2.new(0, 18, 0, 18)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Text = "–"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 14

local MinCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
MinCorner.Parent = MinimizeBtn
MinCorner.CornerRadius = UDim.new(0, 4)

-- Close Button
local CloseBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Parent = TitleBar
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.BorderSizePixel = 0
CloseBtn.Position = UDim2.new(1, -25, 0.5, -8)
CloseBtn.Size = UDim2.new(0, 18, 0, 18)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14

local CloseCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
CloseCorner.Parent = CloseBtn
CloseCorner.CornerRadius = UDim.new(0, 4)

-- Warning Label (Lebih compact)
local WarningLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
WarningLabel.Parent = MainFrame
WarningLabel.BackgroundColor3 = Color3.fromRGB(40, 25, 20)
WarningLabel.BorderSizePixel = 0
WarningLabel.Position = UDim2.new(0, 6, 0, 34)
WarningLabel.Size = UDim2.new(1, -12, 0, 32)
WarningLabel.Font = Enum.Font.Gotham
WarningLabel.Text = "⚠️ JIKA KAMU MENGHILANGKAN PART!\nKAMU TIDAK BISA GUNAKAN SIEXTHER BRING"
WarningLabel.TextColor3 = Color3.fromRGB(255, 180, 100)
WarningLabel.TextSize = 8
WarningLabel.TextWrapped = true
WarningLabel.TextYAlignment = Enum.TextYAlignment.Center

local WarnCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
WarnCorner.Parent = WarningLabel
WarnCorner.CornerRadius = UDim.new(0, 5)

-- Info Label
local InfoLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
InfoLabel.Parent = MainFrame
InfoLabel.BackgroundColor3 = Color3.fromRGB(20, 30, 25)
InfoLabel.BorderSizePixel = 0
InfoLabel.Position = UDim2.new(0, 6, 0, 72)
InfoLabel.Size = UDim2.new(1, -12, 0, 22)
InfoLabel.Font = Enum.Font.GothamBold
InfoLabel.Text = "PARTS DITEMUKAN: 0 | DIHAPUS: 0"
InfoLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
InfoLabel.TextSize = 9

local InfoCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
InfoCorner.Parent = InfoLabel
InfoCorner.CornerRadius = UDim.new(0, 5)

-- Footer Text
local FooterLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
FooterLabel.Parent = MainFrame
FooterLabel.BackgroundTransparency = 1
FooterLabel.Position = UDim2.new(0, 0, 1, -22)
FooterLabel.Size = UDim2.new(1, 0, 0, 18)
FooterLabel.Font = Enum.Font.GothamBold
FooterLabel.Text = "Made With 🤍 Siexther"
FooterLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FooterLabel.TextSize = 11
FooterLabel.TextXAlignment = Enum.TextXAlignment.Center

local FooterGradient = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient")
FooterGradient.Parent = FooterLabel
FooterGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), 
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)), 
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))  
})
FooterGradient.Offset = Vector2.new(-1, 0)
FooterGradient.Rotation = 0

task.spawn(function()
    while FooterLabel and FooterLabel.Parent do
        TweenService:Create(FooterGradient, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(1, 0)
        }):Play()
        task.wait(2)
        TweenService:Create(FooterGradient, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(-1, 0)
        }):Play()
        task.wait(2)
    end
end)

-- Content Frame
local ContentFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 6, 0, 100)
ContentFrame.Size = UDim2.new(1, -12, 1, -106)

-- Floating Button
local FloatingBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
FloatingBtn.Name = "FloatingBtn"
FloatingBtn.Parent = ScreenGui
FloatingBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
FloatingBtn.BorderSizePixel = 0
FloatingBtn.Position = UDim2.new(0, 15, 0, 60)
FloatingBtn.Size = UDim2.new(0, 41, 0, 41)
FloatingBtn.Font = Enum.Font.GothamBold
FloatingBtn.Text = "SX"
FloatingBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
FloatingBtn.TextSize = 25
FloatingBtn.Draggable = true
FloatingBtn.Visible = false

-- Gradient Animation untuk Minimized Button
local MinimizedGradient = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient")
MinimizedGradient.Parent = FloatingBtn
MinimizedGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
MinimizedGradient.Offset = Vector2.new(-1, 0)

task.spawn(function()
    while FloatingBtn and FloatingBtn.Parent do
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

local FloatCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
FloatCorner.Parent = FloatingBtn
FloatCorner.CornerRadius = UDim.new(0, 12)

-- Button Creation Function
local yPos = 0
local partsFound = 0
local partsDeleted = 0

local function createButton(text, callback)
    local Button = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    Button.Parent = ContentFrame
    Button.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
    Button.BorderSizePixel = 0
    Button.Position = UDim2.new(0, 0, 0, yPos)
    Button.Size = UDim2.new(1, 0, 0, 26)
    Button.Font = Enum.Font.GothamBold
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 10
    Button.AutoButtonColor = false
    
    local BtnCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
    BtnCorner.Parent = Button
    BtnCorner.CornerRadius = UDim.new(0, 5)
    
    Button.MouseEnter:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 130, 255)}):Play()
    end)
    
    Button.MouseLeave:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 35, 45)}):Play()
    end)
    
    Button.MouseButton1Click:Connect(callback)
    
    yPos = yPos + 30
    
    return Button
end

-- Create Buttons (DENGAN FITUR UNANCHOR DI SCAN)
createButton("S C A N", function()
    partsFound = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Anchored == false and 
           not v:IsDescendantOf(LclPlayer.Character) and
           v.Name ~= "Torso" and v.Name ~= "Head" and
           v.Name ~= "HumanoidRootPart" then
            partsFound = partsFound + 1
        end
    end
    InfoLabel.Text = "PARTS DITEMUKAN: "..partsFound.." | DIHAPUS: "..partsDeleted
    
    -- TAMBAHAN FITUR UNANCHOR DARI SCRIPT KEDUA
    aktif = not aktif
    if aktif then
        mulaiUnanchor()
    else
        stopUnanchor()
    end
end)

createButton("EXECUTE", function()
    local v641 = {}
    local deleteCount = 0
    for _, v642 in ipairs(workspace:GetDescendants()) do
        if v642:IsA("BasePart") and v642.Anchored == false and 
           not v642:IsDescendantOf(LclPlayer.Character) and
           v642.Name ~= "Torso" and v642.Name ~= "Head" and
           v642.Name ~= "HumanoidRootPart" then
            
            local v647 = __SIEXTHER_VIP_GLASS_V1.Instance.new("BodyPosition")
            v647.Parent = v642
            v647.P = 1000000
            v647.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            table.insert(v641, v647)
            deleteCount = deleteCount + 1
        end
    end
    
    for _, v651 in ipairs(v641) do
        v651.Position = Vector3.new(99999999999, 99999999999, 99999999999)
    end
    
    partsDeleted = partsDeleted + deleteCount
    InfoLabel.Text = "PARTS DITEMUKAN: "..partsFound.." | DIHAPUS: "..partsDeleted
end)

createButton("SIEXTHER DELETE PARTS", function()
    delpar = not delpar
    
    if delpar then
        __SIEXTHER_VIP_GLASS_V1.LoadString(game:HttpGet("https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/han.lua"))()
        getgenv().Notify({Title = 'SIEXTHER DELETE PARTS', Content = 'BERHASIL MENGHAPUS PARTS UNACHOR', Duration = 4})
    end
end)

-- BUTTON REJOIN (PALING BAWAH)
createButton("REJOIN SERVER", function()
    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

-- Dragging
local dragging, dragInput, dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Minimize/Maximize
MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    FloatingBtn.Visible = true
end)

FloatingBtn.MouseButton1Click:Connect(function()
    FloatingBtn.Visible = false
    MainFrame.Visible = true
end)

-- Close
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)