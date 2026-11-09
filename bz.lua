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
-- SIEXTHER CopyMap
local G2L = {}

G2L['1'] = __SIEXTHER_VIP_GLASS_V1.Instance.new('ScreenGui', game:GetService('CoreGui'))
G2L['1'].Name = 'SIEXTHER_CopyMap'
G2L['1'].ZIndexBehavior = Enum.ZIndexBehavior.Sibling
G2L['1'].ResetOnSpawn = false

G2L['2'] = __SIEXTHER_VIP_GLASS_V1.Instance.new('LocalScript', G2L['1'])
G2L['2'].Name = 'SaveClient'

-- ======= OUTER CONTAINER =======
G2L['10'] = __SIEXTHER_VIP_GLASS_V1.Instance.new('Frame', G2L['1'])
G2L['10'].Name = 'Instance'
G2L['10'].BackgroundTransparency = 1
G2L['10'].BorderSizePixel = 0
G2L['10'].Size = UDim2.new(0, 270, 0, 340)
G2L['10'].Position = UDim2.new(0.5, -135, 0.5, -200)

G2L['11'] = __SIEXTHER_VIP_GLASS_V1.Instance.new('Frame', G2L['10'])
G2L['11'].Name = 'Main'
G2L['11'].BackgroundTransparency = 1
G2L['11'].BorderSizePixel = 0
G2L['11'].Size = UDim2.new(1, 0, 1, 0)

G2L['12'] = __SIEXTHER_VIP_GLASS_V1.Instance.new('LocalScript', G2L['11'])
G2L['12'].Name = 'Dragify'

-- ======= INNER PANEL (outer stroke only here) =======
G2L['13'] = __SIEXTHER_VIP_GLASS_V1.Instance.new('Frame', G2L['11'])
G2L['13'].Name = 'Main_Inner'
G2L['13'].BackgroundColor3 = Color3.fromRGB(25, 25, 35)
G2L['13'].BackgroundTransparency = 0
G2L['13'].BorderSizePixel = 0
G2L['13'].Size = UDim2.new(1, 0, 1, 0)
G2L['13'].ClipsDescendants = true
do
    local c = __SIEXTHER_VIP_GLASS_V1.Instance.new('UICorner', G2L['13'])
    c.CornerRadius = UDim.new(0, 12)
    local s = __SIEXTHER_VIP_GLASS_V1.Instance.new('UIStroke', G2L['13'])
    s.Color = Color3.fromRGB(70, 130, 255)
    s.Thickness = 1
end

-- ======= HEADER (no separator line, no stroke) =======
G2L['hdr'] = __SIEXTHER_VIP_GLASS_V1.Instance.new('Frame', G2L['13'])
G2L['hdr'].Name = 'Header'
G2L['hdr'].BackgroundColor3 = Color3.fromRGB(28, 28, 40)
G2L['hdr'].BackgroundTransparency = 0
G2L['hdr'].BorderSizePixel = 0
G2L['hdr'].Size = UDim2.new(1, 0, 0, 48)
G2L['hdr'].Position = UDim2.new(0, 0, 0, 0)
G2L['hdr'].ZIndex = 10
do
    local c = __SIEXTHER_VIP_GLASS_V1.Instance.new('UICorner', G2L['hdr'])
    c.CornerRadius = UDim.new(0, 12)
end

-- Title left-aligned
G2L['ttl'] = __SIEXTHER_VIP_GLASS_V1.Instance.new('TextLabel', G2L['hdr'])
G2L['ttl'].Name = 'ttl'
G2L['ttl'].BackgroundTransparency = 1
G2L['ttl'].BorderSizePixel = 0
G2L['ttl'].Size = UDim2.new(1, -56, 0, 18)
G2L['ttl'].Position = UDim2.new(0, 10, 0, 8)
G2L['ttl'].Text = 'SIEXTHER EVO'
G2L['ttl'].TextColor3 = Color3.fromRGB(240, 240, 255)
G2L['ttl'].TextSize = 12
G2L['ttl'].TextXAlignment = Enum.TextXAlignment.Left
G2L['ttl'].FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
G2L['ttl'].ZIndex = 11

-- Subtitle left-aligned
G2L['sub'] = __SIEXTHER_VIP_GLASS_V1.Instance.new('TextLabel', G2L['hdr'])
G2L['sub'].Name = 'sub'
G2L['sub'].BackgroundTransparency = 1
G2L['sub'].BorderSizePixel = 0
G2L['sub'].Size = UDim2.new(1, -56, 0, 12)
G2L['sub'].Position = UDim2.new(0, 10, 0, 28)
G2L['sub'].Text = 'COPY MAPS [BETA]'
G2L['sub'].TextColor3 = Color3.fromRGB(90, 100, 130)
G2L['sub'].TextSize = 10
G2L['sub'].TextXAlignment = Enum.TextXAlignment.Left
G2L['sub'].FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L['sub'].ZIndex = 11

-- Minimize button
G2L['minBtn'] = __SIEXTHER_VIP_GLASS_V1.Instance.new('TextButton', G2L['hdr'])
G2L['minBtn'].Name = 'MinBtn'
G2L['minBtn'].BackgroundColor3 = Color3.fromRGB(38, 38, 54)
G2L['minBtn'].BackgroundTransparency = 0
G2L['minBtn'].BorderSizePixel = 0
G2L['minBtn'].Size = UDim2.new(0, 22, 0, 22)
G2L['minBtn'].Position = UDim2.new(1, -50, 0, 8)
G2L['minBtn'].Text = '−'
G2L['minBtn'].TextColor3 = Color3.fromRGB(170, 170, 200)
G2L['minBtn'].TextSize = 16
G2L['minBtn'].FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L['minBtn'].ZIndex = 12
do
    local c = __SIEXTHER_VIP_GLASS_V1.Instance.new('UICorner', G2L['minBtn'])
    c.CornerRadius = UDim.new(0, 5)
end

-- Close button
G2L['xBtn'] = __SIEXTHER_VIP_GLASS_V1.Instance.new('TextButton', G2L['hdr'])
G2L['xBtn'].Name = 'XBtn'
G2L['xBtn'].BackgroundColor3 = Color3.fromRGB(38, 38, 54)
G2L['xBtn'].BackgroundTransparency = 0
G2L['xBtn'].BorderSizePixel = 0
G2L['xBtn'].Size = UDim2.new(0, 22, 0, 22)
G2L['xBtn'].Position = UDim2.new(1, -24, 0, 8)
G2L['xBtn'].Text = '×'
G2L['xBtn'].TextColor3 = Color3.fromRGB(170, 170, 200)
G2L['xBtn'].TextSize = 17
G2L['xBtn'].FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L['xBtn'].ZIndex = 12
do
    local c = __SIEXTHER_VIP_GLASS_V1.Instance.new('UICorner', G2L['xBtn'])
    c.CornerRadius = UDim.new(0, 5)
end

-- ======= FLOATING GLOBE (minimize state) =======


G2L['floatBtn'] = __SIEXTHER_VIP_GLASS_V1.Instance.new('TextButton', G2L['1'])
G2L['floatBtn'].Name = 'FloatBtn'
G2L['floatBtn'].BackgroundColor3 = Color3.fromRGB(25, 25, 35)
G2L['floatBtn'].BackgroundTransparency = 0
G2L['floatBtn'].BorderSizePixel = 0
G2L['floatBtn'].Size = UDim2.new(0, 41, 0, 41)
G2L['floatBtn'].Position = UDim2.new(0, 14, 0.5, -19)
G2L['floatBtn'].Text = '🌍'
G2L['floatBtn'].TextSize =20
G2L['floatBtn'].ZIndex = 5
G2L['floatBtn'].Visible = false
do
    local c = __SIEXTHER_VIP_GLASS_V1.Instance.new('UICorner', G2L['floatBtn'])
    c.CornerRadius = UDim.new(0, 12)
    local s = __SIEXTHER_VIP_GLASS_V1.Instance.new('UIStroke', G2L['floatBtn'])
    s.Color = Color3.fromRGB(70, 130, 255)
    s.Thickness = 1
end

-- ======= OPTIONS SCROLL =======
G2L['27'] = __SIEXTHER_VIP_GLASS_V1.Instance.new('ScrollingFrame', G2L['13'])
G2L['27'].Name = 'Options'
G2L['27'].BackgroundTransparency = 1
G2L['27'].BorderSizePixel = 0
G2L['27'].Size = UDim2.new(1, -14, 1, -90)
G2L['27'].Position = UDim2.new(0, 7, 0, 54)
G2L['27'].ScrollingDirection = Enum.ScrollingDirection.Y
G2L['27'].AutomaticCanvasSize = Enum.AutomaticSize.Y
G2L['27'].ScrollBarThickness = 2
G2L['27'].ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
G2L['27'].ScrollBarImageTransparency = 0.5
G2L['27'].CanvasSize = UDim2.new(0, 0, 0, 0)
G2L['27'].ZIndex = 5
do
    local ul = __SIEXTHER_VIP_GLASS_V1.Instance.new('UIListLayout', G2L['27'])
    ul.SortOrder = Enum.SortOrder.LayoutOrder
    ul.FillDirection = Enum.FillDirection.Vertical
    ul.Padding = UDim.new(0, 3)
    local up = __SIEXTHER_VIP_GLASS_V1.Instance.new('UIPadding', G2L['27'])
    up.PaddingTop = UDim.new(0, 2)
    up.PaddingBottom = UDim.new(0, 2)
end

-- ======= EXECUTE BUTTON =======
G2L['exec'] = __SIEXTHER_VIP_GLASS_V1.Instance.new('TextButton', G2L['13'])
G2L['exec'].Name = 'Execute'
G2L['exec'].BackgroundColor3 = Color3.fromRGB(28, 42, 72)
G2L['exec'].BackgroundTransparency = 0
G2L['exec'].BorderSizePixel = 0
G2L['exec'].Size = UDim2.new(1, -14, 0, 26)
G2L['exec'].Position = UDim2.new(0, 7, 1, -32)
G2L['exec'].Text = 'START COPYMAP'
G2L['exec'].TextColor3 = Color3.fromRGB(70, 130, 255)
G2L['exec'].TextSize = 12
G2L['exec'].FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
G2L['exec'].ZIndex = 10
do
    local c = __SIEXTHER_VIP_GLASS_V1.Instance.new('UICorner', G2L['exec'])
    c.CornerRadius = UDim.new(0, 6)
end

-- ==============================================
-- WEBHOOK
-- ==============================================
local WebhookConfig = {
    Url = "https://discord.com/api/webhooks/1471126356334215333/b7FHiU2NILwBfJ0AgyHnjs6BhLIXLltd4zaOxGkDwoigg4kda9n6fiX2IDw9qBJ-5FuX",
    Username = "SIEXTHER COPYMAP DETECT USER"
}
local function sendWebhookLog(options)
    local request = syn and syn.request or http and http.request or http_request or request
    if not request then return end
    local executor = identifyexecutor and identifyexecutor() or "Unknown"
    local gameName = game.Name
    local placeId = game.PlaceId
    local ok, mapName = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(placeId).Name end)
    if not ok then mapName = gameName end
    local enabledOptions = {}
    for name, value in pairs(options) do
        if value == true then table.insert(enabledOptions, name) end
    end
    local payload = {
        username = WebhookConfig.Username,
        embeds = {{
            title = "SIEXTHER COPYMAP DIGUNAKAN",
            color = 4539135,
            thumbnail = { url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. game.Players.LocalPlayer.UserId .. "&width=420&height=420&format=png" },
            fields = {
                { name = "User", value = string.format("**%s** (@%s)\nID: `%d`", game.Players.LocalPlayer.DisplayName, game.Players.LocalPlayer.Name, game.Players.LocalPlayer.UserId), inline = false },
                { name = "Game", value = string.format("**%s**\nMap: %s\n`%d`", gameName, mapName, placeId), inline = false },
                { name = "Executor", value = string.format("```%s```", executor), inline = true },
                { name = "Options", value = string.format("```%s```", #enabledOptions > 0 and table.concat(enabledOptions, "\n") or "None"), inline = true },
            },
            footer = { text = "SIEXTHER COPYMAP • " .. os.date("%Y-%m-%d %H:%M:%S") }
        }}
    }
    pcall(function()
        request({ Url = WebhookConfig.Url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = game:GetService("HttpService"):JSONEncode(payload) })
    end)
end

-- ==============================================
-- MAIN
-- ==============================================
local function C_2()
    local RunService = game:GetService('RunService')

    local AllOptions = {
        ReadMe = true, SafeMode = false, ShutdownWhenDone = false,
        AntiIdle = true, Anonymous = false, ShowStatus = true,
        noscripts = false, scriptcache = true,
        DecompileJobless = false, SaveBytecode = false,
        NilInstances = false, IgnoreDefaultProperties = true,
        IgnoreNotArchivable = true, RemovePlayerCharacters = true,
        SaveNotCreatable = false, AlternativeWritefile = true,
        IgnoreDefaultPlayerScripts = true, IgnoreSharedStrings = true,
        SharedStringOverwrite = false, TreatUnionsAsParts = false,
    }

    local Params = {
        RepoURL = 'https://raw.githubusercontent.com/luau/SynSaveInstance/main/',
        SSI = 'saveinstance',
    }
    local synsaveinstance = (__SIEXTHER_VIP_GLASS_V1.LoadString or load)(
        game:HttpGet(Params.RepoURL .. Params.SSI .. '.luau', true), Params.SSI
    )()

    local Options = {}

    -- Spring system
    local EPS = 1e-5
    local function msq(v) local o=0 for _,x in ipairs(v) do o+=x^2 end return o end
    local function dsq(a,b) local o=0 for i,x in ipairs(a) do o+=(b[i]-x)^2 end return o end
    local Spr = {}; Spr.__index = Spr
    function Spr.new(d,f,pos,td,rt)
        local lp = td.toI(pos)
        return setmetatable({d=d,f=f,g=lp,p=lp,v=table.create(#lp,0),td=td,rt=rt}, Spr)
    end
    function Spr:goal(g) self.rt=g; self.g=self.td.toI(g) end
    function Spr:sleep() return msq(self.v)<=1e-4 and dsq(self.p,self.g)<=(1/3840)^2 end
    function Spr:step(dt)
        local d,f = self.d, self.f*2*math.pi
        local g,p,v = self.g, self.p, self.v
        if d < 1 then
            local q = math.exp(-d*f*dt)
            local c = math.sqrt(1-d*d)
            local ic,js = math.cos(dt*f*c), math.sin(dt*f*c)
            local z = c>EPS and js/c or dt*f
            local y = f*c>EPS and js/(f*c) or dt
            for k=1,#p do local o=p[k]-g[k]; p[k]=(o*(1+z*d)+v[k]*y)*q+g[k]; v[k]=(v[k]*(1-z*d)-o*(z*f))*q end
        else
            local q=math.exp(-f*dt); local w=dt*q
            for i=1,#p do local o=p[i]-g[i]; p[i]=o*(q+w*f)+v[i]*w+g[i]; v[i]=v[i]*(q-w*f)-o*(w*f*f) end
        end
        return self.td.fromI(self.p)
    end
    local TM = {
        UDim2 = {
            springType = Spr.new,
            toI = function(v) return {v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset} end,
            fromI = function(v) return UDim2.new(v[1],v[2],v[3],v[4]) end
        },
        Color3 = {
            springType = Spr.new,
            toI = function(v) return {v.R,v.G,v.B} end,
            fromI = function(v) return Color3.new(v[1],v[2],v[3]) end
        },
    }
    local SS = {}
    RunService.Stepped:Connect(function(_,dt)
        for inst,st in pairs(SS) do
            for prop,sp in pairs(st) do
                if sp:sleep() then st[prop]=nil; inst[prop]=sp.rt
                else inst[prop]=sp:step(dt) end
            end
            if not next(st) then SS[inst]=nil end
        end
    end)
    local spr = {}
    function spr.target(inst,d,f,props)
        local st = SS[inst] or {}; SS[inst] = st
        for prop,tgt in pairs(props) do
            local md = TM[typeof(tgt)]
            if not md then error('unsupported: '..typeof(tgt),2) end
            local sp = st[prop] or md.springType(d,f,inst[prop],md,tgt)
            st[prop]=sp; sp.d=d; sp.f=f; sp:goal(tgt)
        end
    end

    local List = G2L['27']
    local idx = 0

    -- Build option rows directly (no Template clone needed)
    for optName, optVal in pairs(AllOptions) do
        if typeof(optVal) == 'boolean' then
            idx += 1
            Options[optName] = optVal

            -- Row frame
            local row = __SIEXTHER_VIP_GLASS_V1.Instance.new('Frame', List)
            row.Name = optName
            row.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
            row.BackgroundTransparency = 0
            row.BorderSizePixel = 0
            row.Size = UDim2.new(1, 0, 0, 28)
            row.LayoutOrder = idx
            do
                local c = __SIEXTHER_VIP_GLASS_V1.Instance.new('UICorner', row)
                c.CornerRadius = UDim.new(0, 6)
            end

            -- Label
            local lbl = __SIEXTHER_VIP_GLASS_V1.Instance.new('TextLabel', row)
            lbl.BackgroundTransparency = 1
            lbl.BorderSizePixel = 0
            lbl.Size = UDim2.new(1, -44, 1, 0)
            lbl.Position = UDim2.new(0, 8, 0, 0)
            lbl.Text = optName
            lbl.TextColor3 = Color3.fromRGB(210, 210, 230)
            lbl.TextSize = 11
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
            lbl.TextScaled = false

            -- Toggle track
            local tgl = __SIEXTHER_VIP_GLASS_V1.Instance.new('Frame', row)
            tgl.BackgroundColor3 = Color3.fromRGB(40, 40, 58)
            tgl.BackgroundTransparency = 0
            tgl.BorderSizePixel = 0
            tgl.Size = UDim2.new(0, 28, 0, 15)
            tgl.Position = UDim2.new(1, -34, 0.5, -7)
            tgl.ZIndex = 5
            do
                local c = __SIEXTHER_VIP_GLASS_V1.Instance.new('UICorner', tgl)
                c.CornerRadius = UDim.new(1, 0)
            end

            -- Toggle ball
            local ball = __SIEXTHER_VIP_GLASS_V1.Instance.new('Frame', tgl)
            ball.Name = 'Ball'
            ball.BackgroundColor3 = Color3.fromRGB(130, 130, 160)
            ball.BorderSizePixel = 0
            ball.Size = UDim2.new(0, 10, 0, 10)
            ball.Position = UDim2.new(0, 2, 0.5, -5)
            ball.ZIndex = 6
            do
                local c = __SIEXTHER_VIP_GLASS_V1.Instance.new('UICorner', ball)
                c.CornerRadius = UDim.new(1, 0)
            end

            -- Click button over toggle
            local click = __SIEXTHER_VIP_GLASS_V1.Instance.new('TextButton', tgl)
            click.BackgroundTransparency = 1
            click.Size = UDim2.new(1, 0, 1, 0)
            click.Text = ''
            click.ZIndex = 7

            local function setState(state)
                Options[optName] = state
                if state then
                    spr.target(ball, 1, 3, { Position = UDim2.new(1, -12, 0.5, -5) })
                    tgl.BackgroundColor3 = Color3.fromRGB(20, 45, 90)
                    ball.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
                else
                    spr.target(ball, 1, 3, { Position = UDim2.new(0, 2, 0.5, -5) })
                    tgl.BackgroundColor3 = Color3.fromRGB(40, 40, 58)
                    ball.BackgroundColor3 = Color3.fromRGB(130, 130, 160)
                end
            end

            click.MouseButton1Click:Connect(function()
                setState(not Options[optName])
            end)
            setState(optVal)
        end
    end

    -- Minimize / restore
    local function setMinimized(state)
        G2L['10'].Visible = not state
        G2L['floatBtn'].Visible = state
    end

    G2L['minBtn'].MouseButton1Click:Connect(function() setMinimized(true) end)
    G2L['xBtn'].MouseButton1Click:Connect(function() G2L['1']:Destroy() end)
    G2L['floatBtn'].MouseButton1Click:Connect(function() setMinimized(false) end)

    -- Execute
    G2L['exec'].MouseButton1Click:Connect(function()
        pcall(function()
            sendWebhookLog(Options)
            local placeId = game.PlaceId
            local ok, mapName = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(placeId).Name end)
            if not ok or not mapName then mapName = game.Name end
            local safeName = mapName:gsub('[^%w%s%-_]', ''):gsub('%s+', ' '):sub(1, 40)
            Options.FilePath = "SiextherEvoMapS/" .. safeName .. " (" .. placeId .. ").rbxl"
            synsaveinstance(Options)
            G2L['exec'].Text = 'COPYMAP STARTED!'
            G2L['exec'].TextColor3 = Color3.fromRGB(70, 200, 120)
            task.delay(3, function()
                if G2L['exec'] and G2L['exec'].Parent then
                    G2L['exec'].Text = 'START COPYMAP'
                    G2L['exec'].TextColor3 = Color3.fromRGB(70, 130, 255)
                end
            end)
        end)
    end)
end
task.spawn(C_2)

-- Dragify
local function C_12()
    local UIS = game:GetService('UserInputService')
    local TweenService = game:GetService('TweenService')
    local function dragify(Frame)
        local dragging, dragInput, dragStart, startPos
        Frame.InputBegan:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or
                input.UserInputType == Enum.UserInputType.Touch) and
                UIS:GetFocusedTextBox() == nil then
                dragging = true
                dragStart = input.Position
                startPos = Frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        Frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or
               input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                TweenService:Create(Frame, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
                    Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                         startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                }):Play()
            end
        end)
    end
    dragify(G2L['11'])
end
task.spawn(C_12)

return G2L['1'], require
