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
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Variables
local following = false
local targetPlayer = nil
local connection = nil
local selectedPlayer = nil
local followMode = "default"

-- Create ScreenGui
local screenGui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
screenGui.Name = "SIEXTHERxTROLL"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame (Lebih kecil & Modern Dark)
local mainFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 220, 0, 320)
mainFrame.Position = UDim2.new(0.5, -110, 0.5, -188)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local mainCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local mainStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(70, 130, 255)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

-- Header
local header = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 30)
header.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local headerFix = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 12)
headerFix.Position = UDim2.new(0, 0, 1, -12)
headerFix.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

-- Title
local title = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "SIEXTHER TROLL"
title.TextColor3 = Color3.fromRGB(70, 130, 255)
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Minimize Button
local minimizeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, 22, 0, 22)
minimizeBtn.Position = UDim2.new(1, -50, 0.5, -11)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
minimizeBtn.Text = "–"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextSize = 12
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = header

local minCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minimizeBtn

-- Close Button
local closeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -24, 0.5, -11)
closeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 11
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = header

local closeCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

-- Status Label
local statusLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 38)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Tidak aktif"
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
statusLabel.TextSize = 10
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

-- Search Box
local searchBox = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, -20, 0, 26)
searchBox.Position = UDim2.new(0, 10, 0, 60)
searchBox.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
searchBox.BorderSizePixel = 0
searchBox.PlaceholderText = "Cari player..."
searchBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 110)
searchBox.Text = ""
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.TextSize = 10
searchBox.Font = Enum.Font.Gotham
searchBox.ClearTextOnFocus = false
searchBox.Parent = mainFrame

local searchCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 6)
searchCorner.Parent = searchBox

local searchPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
searchPadding.PaddingLeft = UDim.new(0, 8)
searchPadding.PaddingRight = UDim.new(0, 8)
searchPadding.Parent = searchBox

-- ScrollFrame for players
local scrollFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScrollingFrame")
scrollFrame.Name = "PlayerList"
scrollFrame.Size = UDim2.new(1, -20, 1, -210)
scrollFrame.Position = UDim2.new(0, 10, 0, 92)
scrollFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
scrollFrame.Parent = mainFrame

local scrollCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 6)
scrollCorner.Parent = scrollFrame

local listLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Padding = UDim.new(0, 3)
listLayout.Parent = scrollFrame

local listPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 5)
listPadding.PaddingBottom = UDim.new(0, 5)
listPadding.PaddingLeft = UDim.new(0, 5)
listPadding.PaddingRight = UDim.new(0, 5)
listPadding.Parent = scrollFrame

-- Control Buttons Container
local controlFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
controlFrame.Name = "ControlFrame"
controlFrame.Size = UDim2.new(1, -20, 0, 105)
controlFrame.Position = UDim2.new(0, 10, 1, -112)
controlFrame.BackgroundTransparency = 1
controlFrame.Parent = mainFrame

-- Selected Player Label
local selectedLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
selectedLabel.Name = "SelectedLabel"
selectedLabel.Size = UDim2.new(1, 0, 0, 14)
selectedLabel.Position = UDim2.new(0, 0, 0, 0)
selectedLabel.BackgroundTransparency = 1
selectedLabel.Text = "Dipilih: Tidak ada"
selectedLabel.TextColor3 = Color3.fromRGB(130, 130, 150)
selectedLabel.TextSize = 9
selectedLabel.Font = Enum.Font.Gotham
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Parent = controlFrame

-- Mode Buttons Container
local modeFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
modeFrame.Name = "ModeFrame"
modeFrame.Size = UDim2.new(1, 0, 0, 50)
modeFrame.Position = UDim2.new(0, 0, 0, 18)
modeFrame.BackgroundTransparency = 1
modeFrame.Parent = controlFrame

-- Mode Label
local modeLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
modeLabel.Size = UDim2.new(1, 0, 0, 12)
modeLabel.BackgroundTransparency = 1
modeLabel.Text = "TROLL MODE:"
modeLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
modeLabel.TextSize = 8
modeLabel.Font = Enum.Font.GothamBold
modeLabel.TextXAlignment = Enum.TextXAlignment.Left
modeLabel.Parent = modeFrame

-- Mode Buttons (2x2 Grid)
local modeButtons = {}
local modes = {
    {name = "default", label = "FOLLOW", color = Color3.fromRGB(70, 130, 255)},
    {name = "carry", label = "CARRY", color = Color3.fromRGB(180, 100, 200)},
    {name = "attach", label = "TEMPEL", color = Color3.fromRGB(255, 150, 80)},
    {name = "drag", label = "SERET", color = Color3.fromRGB(150, 80, 180)}
}

for i, mode in ipairs(modes) do
    local row = math.floor((i - 1) / 2)
    local col = (i - 1) % 2
    
    local btn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    btn.Name = mode.name .. "Btn"
    btn.Size = UDim2.new(0.48, 0, 0, 16)
    btn.Position = UDim2.new(col * 0.52, 0, 0, 14 + row * 19)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    btn.Text = mode.label
    btn.TextColor3 = Color3.fromRGB(180, 180, 200)
    btn.TextSize = 8
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.Parent = modeFrame
    
    local btnCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5)
    btnCorner.Parent = btn
    
    modeButtons[mode.name] = {button = btn, color = mode.color}
    
    btn.MouseButton1Click:Connect(function()
        followMode = mode.name
        for _, mBtn in pairs(modeButtons) do
            mBtn.button.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            mBtn.button.TextColor3 = Color3.fromRGB(180, 180, 200)
        end
        btn.BackgroundColor3 = mode.color
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    
    btn.MouseEnter:Connect(function()
        if followMode ~= mode.name then
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        end
    end)
    
    btn.MouseLeave:Connect(function()
        if followMode ~= mode.name then
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        end
    end)
end

-- Highlight default mode
modeButtons["default"].button.BackgroundColor3 = modes[1].color
modeButtons["default"].button.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Toggle Follow Button
local toggleBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
toggleBtn.Name = "ToggleBtn"
toggleBtn.Size = UDim2.new(1, 0, 0, 32)
toggleBtn.Position = UDim2.new(0, 0, 0, 73)
toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
toggleBtn.Text = "MULAI"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 11
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = controlFrame

local toggleCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleBtn

-- Modern Dark Fire Button
local fireBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
fireBtn.Name = "FireBtn"
fireBtn.Size = UDim2.new(0, 41, 0, 41)
fireBtn.Position = UDim2.new(0, 15, 0, 60)
fireBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
fireBtn.Text = ""
fireBtn.BorderSizePixel = 0
fireBtn.Visible = false
fireBtn.Active = true
fireBtn.Parent = screenGui

local fireCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
fireCorner.CornerRadius = UDim.new(0, 12)
fireCorner.Parent = fireBtn

local fireStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
fireStroke.Color = Color3.fromRGB(70, 130, 255)
fireStroke.Thickness = 2
fireStroke.Parent = fireBtn

local fireIcon = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
fireIcon.Size = UDim2.new(1, 0, 1, 0)
fireIcon.BackgroundTransparency = 1
fireIcon.Text = "👺"
fireIcon.TextSize = 20
fireIcon.Font = Enum.Font.GothamBold
fireIcon.TextColor3 = Color3.fromRGB(70, 130, 255)
fireIcon.Parent = fireBtn

-- Ultra Smooth Follow Function
local function startFollowing()
    if not selectedPlayer or not selectedPlayer.Character then return end
    
    following = true
    targetPlayer = selectedPlayer
    local modeName = followMode == "default" and "Follow" or 
                     followMode == "carry" and "Carry" or
                     followMode == "attach" and "Tempel" or "Seret"
    statusLabel.Text = "Status: Troll " .. (targetPlayer.DisplayName or targetPlayer.Name) .. " [" .. modeName .. "]"
    statusLabel.TextColor3 = Color3.fromRGB(70, 255, 150)
    
    if connection then
        connection:Disconnect()
    end
    
    local lastJumpTime = 0
    local wasInAir = false
    
    connection = RunService.Heartbeat:Connect(function(deltaTime)
        if not following or not targetPlayer or not targetPlayer.Character then
            if connection then
                connection:Disconnect()
                connection = nil
            end
            return
        end
        
        local targetChar = targetPlayer.Character
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        local targetHumanoid = targetChar:FindFirstChild("Humanoid")
        
        if not player.Character or not targetRoot or not targetHumanoid then return end
        
        local myRoot = player.Character:FindFirstChild("HumanoidRootPart")
        local myHumanoid = player.Character:FindFirstChild("Humanoid")
        
        if not myRoot or not myHumanoid then return end
        
        if followMode == "default" then
            local followOffset = targetRoot.CFrame.LookVector * -2.5
            local followPos = targetRoot.Position + followOffset
            local distance = (myRoot.Position - followPos).Magnitude
            
            if distance > 1.5 then
                myHumanoid:MoveTo(followPos)
                myHumanoid.WalkSpeed = targetHumanoid.WalkSpeed
            else
                myHumanoid.WalkSpeed = targetHumanoid.WalkSpeed * 0.5
            end
            
            local targetIsJumping = targetHumanoid:GetState() == Enum.HumanoidStateType.Jumping or
                                    targetHumanoid:GetState() == Enum.HumanoidStateType.Freefall
            local targetVelocity = targetRoot.AssemblyLinearVelocity
            local isMovingUp = targetVelocity.Y > 5
            local currentTime = tick()
            
            if (targetIsJumping or isMovingUp) and not wasInAir then
                if currentTime - lastJumpTime > 0.3 then
                    myHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    lastJumpTime = currentTime
                end
            end
            wasInAir = targetIsJumping or isMovingUp
            
            if targetHumanoid.Sit ~= myHumanoid.Sit then
                myHumanoid.Sit = targetHumanoid.Sit
            end
            
        elseif followMode == "carry" then
            local carryOffset = targetRoot.CFrame.LookVector * -1.2 + Vector3.new(0, 1, 0)
            local carryPos = targetRoot.Position + carryOffset
            myRoot.CFrame = CFrame.new(carryPos, targetRoot.Position + targetRoot.CFrame.LookVector)
            myRoot.AssemblyLinearVelocity = targetRoot.AssemblyLinearVelocity
            myHumanoid.Sit = false
            
        elseif followMode == "attach" then
            myRoot.CFrame = targetRoot.CFrame
            myRoot.AssemblyLinearVelocity = targetRoot.AssemblyLinearVelocity
            myRoot.AssemblyAngularVelocity = targetRoot.AssemblyAngularVelocity
            myHumanoid.Sit = targetHumanoid.Sit
            myHumanoid.WalkSpeed = targetHumanoid.WalkSpeed
            
            if targetHumanoid:GetState() ~= myHumanoid:GetState() then
                myHumanoid:ChangeState(targetHumanoid:GetState())
            end
            
        elseif followMode == "drag" then
            local dragOffset = targetRoot.CFrame.LookVector * -2.8
            local targetDragPos = targetRoot.Position + dragOffset + Vector3.new(0, -1.8, 0)
            myHumanoid.PlatformStand = true
            
            local currentPos = myRoot.Position
            local lerpAlpha = 0.35
            local newPos = currentPos:Lerp(targetDragPos, lerpAlpha)
            local lookDirection = (targetRoot.Position - myRoot.Position).Unit
            myRoot.CFrame = CFrame.new(newPos, newPos + lookDirection) * CFrame.Angles(math.rad(90), 0, 0)
            myRoot.AssemblyLinearVelocity = targetRoot.AssemblyLinearVelocity * 0.95
            myRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            
            local distance = (myRoot.Position - targetDragPos).Magnitude
            if distance > 0.5 then
                local dragForce = (targetDragPos - myRoot.Position) * 8
                myRoot.AssemblyLinearVelocity = myRoot.AssemblyLinearVelocity + dragForce
            end
        end
    end)
end

local function stopFollowing()
    following = false
    targetPlayer = nil
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    if player.Character then
        local myHumanoid = player.Character:FindFirstChild("Humanoid")
        if myHumanoid then
            myHumanoid.PlatformStand = false
        end
    end
    
    statusLabel.Text = "Status: Tidak aktif"
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
end

local function createPlayerButton(targetPlayer)
    local displayName = targetPlayer.DisplayName or targetPlayer.Name
    local userName = targetPlayer.Name
    local fullName = displayName .. " (@" .. userName .. ")"
    
    local btn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    btn.Name = targetPlayer.Name
    btn.Size = UDim2.new(1, -10, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.ClipsDescendants = true
    btn.Parent = scrollFrame
    
    local btnCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5)
    btnCorner.Parent = btn
    
    local nameLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 1, 0)
    nameLabel.Position = UDim2.new(0, 8, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = fullName
    nameLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    nameLabel.TextSize = 9
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        selectedPlayer = Players:FindFirstChild(btn.Name)
        selectedLabel.Text = "Dipilih: " .. displayName
        selectedLabel.TextColor3 = Color3.fromRGB(70, 130, 255)
        
        for _, child in pairs(scrollFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            end
        end
        btn.BackgroundColor3 = Color3.fromRGB(50, 70, 100)
    end)
    
    btn.MouseEnter:Connect(function()
        if selectedPlayer ~= Players:FindFirstChild(btn.Name) then
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        end
    end)
    
    btn.MouseLeave:Connect(function()
        if selectedPlayer ~= Players:FindFirstChild(btn.Name) then
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        end
    end)
    
    return btn
end

local function updatePlayerList(searchText)
    searchText = searchText and searchText:lower() or ""
    
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            local displayName = (plr.DisplayName or plr.Name):lower()
            local userName = plr.Name:lower()
            
            if searchText == "" or displayName:find(searchText, 1, true) or userName:find(searchText, 1, true) then
                createPlayerButton(plr)
            end
        end
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end

toggleBtn.MouseButton1Click:Connect(function()
    if not following then
        if selectedPlayer then
            startFollowing()
            toggleBtn.Text = "STOP"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
        end
    else
        stopFollowing()
        toggleBtn.Text = "MULAI"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    end
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    updatePlayerList(searchBox.Text)
end)

-- Dragging
local dragging = false
local dragInput, mousePos, framePos

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        mousePos = input.Position
        framePos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        mainFrame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
    end
end)

-- Fire Button Dragging
local fireDragging = false
local fireDragInput, fireMousePos, fireFramePos

fireBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        fireDragging = true
        fireMousePos = input.Position
        fireFramePos = fireBtn.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                fireDragging = false
            end
        end)
    end
end)

fireBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        fireDragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == fireDragInput and fireDragging then
        local delta = input.Position - fireMousePos
        fireBtn.Position = UDim2.new(fireFramePos.X.Scale, fireFramePos.X.Offset + delta.X, fireFramePos.Y.Scale, fireFramePos.Y.Offset + delta.Y)
    end
end)

fireBtn.MouseButton1Click:Connect(function()
    if not fireDragging then
        mainFrame.Visible = true
        fireBtn.Visible = false
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    stopFollowing()
    screenGui:Destroy()
end)

minimizeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    fireBtn.Visible = true
end)

-- Hover effects
local function addHoverEffect(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = hoverColor
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = normalColor
    end)
end

addHoverEffect(closeBtn, Color3.fromRGB(35, 35, 45), Color3.fromRGB(255, 80, 80))
addHoverEffect(minimizeBtn, Color3.fromRGB(35, 35, 45), Color3.fromRGB(255, 200, 80))
addHoverEffect(fireBtn, Color3.fromRGB(18, 18, 24), Color3.fromRGB(28, 28, 36))

toggleBtn.MouseEnter:Connect(function()
    if not following then
        toggleBtn.BackgroundColor3 = Color3.fromRGB(90, 150, 255)
    else
        toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 90, 90)
    end
end)

toggleBtn.MouseLeave:Connect(function()
    if not following then
        toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    else
        toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
    end
end)

-- Initial load
updatePlayerList()

Players.PlayerAdded:Connect(function()
    updatePlayerList(searchBox.Text)
end)

Players.PlayerRemoving:Connect(function()
    wait(0.1)
    updatePlayerList(searchBox.Text)
end)