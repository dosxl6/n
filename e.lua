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
-- BY @muhmdilhan_
function missing(t, f, fallback)
    if type(f) == t then return f end
    return fallback 
end

cloneref = missing("function", cloneref, function(...) return ... end)

local Services = setmetatable({}, {
    __index = function(_, name)
        return cloneref(game:GetService(name))
    end
})

local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService
local StarterGui = Services.StarterGui

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
end)

--// Settings
local Settings = {}
Settings["Speed"] = 1

-- Mode configurations
local GlitchModes = {
    {name = "SIEXTHER GLITCH V1 ⭐", id1 = "93224413172183", id2 = "93195109588878"},
    {name = "SIEXTHER GLITCH V2 ⭐", id1 = "70883871260184", id2 = nil},
    {name = "SIEXTHER GLITCH V3 ⭐", id1 = "93224413172183", id2 = "109501168073514"},
    {name = "SIEXTHER GLITCH V4 ⭐", id1 = "93224413172183", id2 = "75924260262717"},    
    {name = "SIEXTHER GLITCH V5 ⭐", id1 = "93224413172183", id2 = "123821472330376"},
    {name = "SIEXTHER GLITCH V6 ⭐", id1 = "93224413172183", id2 = "84662057365559"},
    {name = "SIEXTHER GLITCH V7 ⭐", id1 = "93224413172183", id2 = "78760916873658"},
   {name = "SIEXTHER GLITCH V8 ⭐", id1 = "93224413172183", id2 = "110172609245744"}, 
    {name = "SIEXTHER GLITCH V9", id1 = "93224413172183", id2 = "140356607168824"},
    {name = "SIEXTHER GLITCH v10", id1 = "93224413172183", id2 = "137822800022978"},
    {name = "SIEXTHER GLITCH V11", id1 = "93224413172183", id2 = "95337497384937"},
    {name = "SIEXTHER GLITCH V12", id1 = "93224413172183", id2 = "131029312743794"},
    {name = "SIEXTHER GLITCH V13", id1 = "93224413172183", id2 = "137869087140582"},
    {name = "SIEXTHER GLITCH V14", id1 = "93224413172183", id2 = "82743213236172"},
    {name = "SIEXTHER GLITCH V15", id1 = "93224413172183", id2 = "94438242882874"},
    {name = "SIEXTHER GLITCH V16", id1 = "93224413172183", id2 = "107199542682215"}
}

local selectedMode = nil
local isGlitchActive = false

local CurrentTrack1
local CurrentTrack2
local lastPosition = character.PrimaryPart and character.PrimaryPart.Position or Vector3.new()

-- FreeCam Variables
local freeCamEnabled = false
local freeCamConnection
local keysDown = {}
local rotating = false
local touchPos
local onMobile = not UserInputService.KeyboardEnabled
local freeCamSpeed = 25
local freeCamSens = 0.3
local originalWalkSpeed = 16
local originalJumpPower = 50
local originalJumpHeight = 7.2
local originalCamera = workspace.CurrentCamera.CameraType

freeCamSpeed = freeCamSpeed / 25

if onMobile then
    freeCamSens = freeCamSens * 2
end

-- Function to check if in correct map
local function isInCorrectMap()
    return game.PlaceId == 6358567974
end

local function extractIdFromInput(input)
    local num = tonumber(input)
    if num then
        return num
    end
    local assetIdMatch = string.match(input, "rbxassetid://(%d+)")
    if assetIdMatch then
        return tonumber(assetIdMatch)
    end
    local catalogMatch = string.match(input, "roblox%.com/catalog/(%d+)")
    if catalogMatch then
        return tonumber(catalogMatch)
    end
    local libraryMatch = string.match(input, "roblox%.com/library/(%d+)")
    if libraryMatch then
        return tonumber(libraryMatch)
    end
    local assetMatch = string.match(input, "roblox%.com/asset/%?id=(%d+)")
    if assetMatch then
        return tonumber(assetMatch)
    end
    return tonumber(input)
end

local function LoadTrack(id)
    if CurrentTrack1 then 
        CurrentTrack1:Stop(0) 
    end

    local animId
    local ok, result = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(id))
    end)

    if ok and result and #result > 0 then
        local anim = result[1]
        if anim:IsA("Animation") then
            animId = anim.AnimationId
        else
            animId = "rbxassetid://" .. tostring(id)
        end
    else
        animId = "rbxassetid://" .. tostring(id)
    end

    local newAnim = __SIEXTHER_VIP_GLASS_V1.Instance.new("Animation")
    newAnim.AnimationId = animId
    local newTrack = humanoid:LoadAnimation(newAnim)
    newTrack.Priority = Enum.AnimationPriority.Action4

    newTrack:Play(0.1, 1, Settings["Speed"])
    
    CurrentTrack1 = newTrack

    return newTrack
end

local function LoadTrack2(id)
    if CurrentTrack2 then 
        CurrentTrack2:Stop(0) 
    end

    local animId
    local ok, result = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(id))
    end)

    if ok and result and #result > 0 then
        local anim = result[1]
        if anim:IsA("Animation") then
            animId = anim.AnimationId
        else
            animId = "rbxassetid://" .. tostring(id)
        end
    else
        animId = "rbxassetid://" .. tostring(id)
    end

    local newAnim = __SIEXTHER_VIP_GLASS_V1.Instance.new("Animation")
    newAnim.AnimationId = animId
    local newTrack = humanoid:LoadAnimation(newAnim)
    newTrack.Priority = Enum.AnimationPriority.Action3

    newTrack:Play(0.1, 1, Settings["Speed"])
    
    CurrentTrack2 = newTrack

    return newTrack
end

local function StopTrack()
    if CurrentTrack1 then
        CurrentTrack1:Stop(0.1)
        CurrentTrack1 = nil
    end
    if CurrentTrack2 then
        CurrentTrack2:Stop(0.1)
        CurrentTrack2 = nil
    end
end

local function SmoothTween(obj, time, properties)
    local tween = TweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    tween:Play()
    return tween
end

-- FreeCam Functions
local function freeCamRenderStep()
    local cam = workspace.CurrentCamera
    
    if rotating then
        local delta = UserInputService:GetMouseDelta()
        local cf = cam.CFrame
        local yAngle = cf:ToEulerAngles(Enum.RotationOrder.YZX)
        local newAmount = math.deg(yAngle) + delta.Y
        
        if newAmount > 65 or newAmount < -65 then
            if not (yAngle < 0 and delta.Y < 0) and not (yAngle > 0 and delta.Y > 0) then
                delta = Vector2.new(delta.X, 0)
            end
        end
        
        cf = cf * CFrame.Angles(-math.rad(delta.Y), 0, 0)
        cf = CFrame.Angles(0, -math.rad(delta.X), 0) * (cf - cf.Position) + cf.Position
        cf = CFrame.lookAt(cf.Position, cf.Position + cf.LookVector)
        
        if delta ~= Vector2.new(0, 0) then
            cam.CFrame = cam.CFrame:Lerp(cf, freeCamSens)
        end
        
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
    
    if keysDown["Enum.KeyCode.W"] then
        cam.CFrame = cam.CFrame * CFrame.new(Vector3.new(0, 0, -freeCamSpeed))
    end
    if keysDown["Enum.KeyCode.A"] then
        cam.CFrame = cam.CFrame * CFrame.new(Vector3.new(-freeCamSpeed, 0, 0))
    end
    if keysDown["Enum.KeyCode.S"] then
        cam.CFrame = cam.CFrame * CFrame.new(Vector3.new(0, 0, freeCamSpeed))
    end
    if keysDown["Enum.KeyCode.D"] then
        cam.CFrame = cam.CFrame * CFrame.new(Vector3.new(freeCamSpeed, 0, 0))
    end
end

local function enableFreeCam()
    if freeCamEnabled then return end
    freeCamEnabled = true
    
    if player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            originalWalkSpeed = hum.WalkSpeed
            originalJumpPower = hum.JumpPower
            originalJumpHeight = hum.JumpHeight
            
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum.JumpHeight = 0
        end
    end
    
    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
    freeCamConnection = RunService.RenderStepped:Connect(freeCamRenderStep)
end

local function disableFreeCam()
    if not freeCamEnabled then return end
    freeCamEnabled = false
    
    if freeCamConnection then
        freeCamConnection:Disconnect()
        freeCamConnection = nil
    end
    
    if player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = originalWalkSpeed
            hum.JumpPower = originalJumpPower
            hum.JumpHeight = originalJumpHeight
        end
    end
    
    workspace.CurrentCamera.CameraSubject = player.Character.Humanoid
    workspace.CurrentCamera.CameraType = originalCamera
    
    keysDown = {}
    rotating = false
end

-- Input handling for FreeCam
local validKeys = {"Enum.KeyCode.W", "Enum.KeyCode.A", "Enum.KeyCode.S", "Enum.KeyCode.D"}

UserInputService.InputBegan:Connect(function(Input)
    if not freeCamEnabled then return end
    
    for i, key in pairs(validKeys) do
        if key == tostring(Input.KeyCode) then
            keysDown[key] = true
        end
    end
    
    if Input.UserInputType == Enum.UserInputType.MouseButton2 or 
       (Input.UserInputType == Enum.UserInputType.Touch and UserInputService:GetMouseLocation().X > (workspace.CurrentCamera.ViewportSize.X / 2)) then
        rotating = true
    end
    
    if Input.UserInputType == Enum.UserInputType.Touch then
        if Input.Position.X < workspace.CurrentCamera.ViewportSize.X / 2 then
            touchPos = Input.Position
        end
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if not freeCamEnabled then return end
    
    for key, v in pairs(keysDown) do
        if key == tostring(Input.KeyCode) then
            keysDown[key] = false
        end
    end
    
    if Input.UserInputType == Enum.UserInputType.MouseButton2 or 
       (Input.UserInputType == Enum.UserInputType.Touch and UserInputService:GetMouseLocation().X > (workspace.CurrentCamera.ViewportSize.X / 2)) then
        rotating = false
    end
    
    if Input.UserInputType == Enum.UserInputType.Touch and touchPos then
        if Input.Position.X < workspace.CurrentCamera.ViewportSize.X / 2 then
            touchPos = nil
            keysDown["Enum.KeyCode.W"] = false
            keysDown["Enum.KeyCode.A"] = false
            keysDown["Enum.KeyCode.S"] = false
            keysDown["Enum.KeyCode.D"] = false
        end
    end
end)

UserInputService.TouchMoved:Connect(function(input)
    if not freeCamEnabled then return end
    
    if touchPos then
        if input.Position.X < workspace.CurrentCamera.ViewportSize.X / 2 then
            if input.Position.Y < touchPos.Y then
                keysDown["Enum.KeyCode.W"] = true
                keysDown["Enum.KeyCode.S"] = false
            else
                keysDown["Enum.KeyCode.W"] = false
                keysDown["Enum.KeyCode.S"] = true
            end
            
            if input.Position.X < (touchPos.X - 15) then
                keysDown["Enum.KeyCode.A"] = true
                keysDown["Enum.KeyCode.D"] = false
            elseif input.Position.X > (touchPos.X + 15) then
                keysDown["Enum.KeyCode.A"] = false
                keysDown["Enum.KeyCode.D"] = true
            else
                keysDown["Enum.KeyCode.A"] = false
                keysDown["Enum.KeyCode.D"] = false
            end
        end
    end
end)

local screenGui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
screenGui.Name = "SiextherByHann.Sxthr"
screenGui.ResetOnSpawn = false
screenGui.Parent = Services.CoreGui

-- MAIN FRAME
local mainFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 250)
mainFrame.Position = UDim2.new(0.5, -120, 0.5, -125)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = false
mainFrame.Parent = screenGui

local mainCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 10)

local mainStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(70, 130, 255)
mainStroke.Thickness = 2

-- Minimize Button
local minimizeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 26, 0, 26)
minimizeBtn.Position = UDim2.new(1, -60, 0, 6)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
minimizeBtn.Text = "–"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 18
minimizeBtn.ZIndex = 10
minimizeBtn.Parent = mainFrame

local minimizeCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", minimizeBtn)
minimizeCorner.CornerRadius = UDim.new(0, 6)

-- Close Button
local closeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -30, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.ZIndex = 10
closeBtn.Parent = mainFrame

local closeCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", closeBtn)
closeCorner.CornerRadius = UDim.new(0, 6)

-- Minimized Button
local minimizedBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
minimizedBtn.Size = UDim2.new(0, 41, 0, 41)
minimizedBtn.Position = UDim2.new(0, 15, 0, 60)
minimizedBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
minimizedBtn.Text = "SX"
minimizedBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
minimizedBtn.Font = Enum.Font.GothamBold
minimizedBtn.TextSize = 25
minimizedBtn.Visible = false
minimizedBtn.Active = true
minimizedBtn.Draggable = true
minimizedBtn.Parent = screenGui
minimizedBtn.ZIndex = 5

-- Gradient Animation untuk Minimized Button
local MinimizedGradient = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient")
MinimizedGradient.Parent = minimizedBtn
MinimizedGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
MinimizedGradient.Offset = Vector2.new(-1, 0)

task.spawn(function()
    while minimizedBtn and minimizedBtn.Parent do
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

local minimizedCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", minimizedBtn)
minimizedCorner.CornerRadius = UDim.new(0, 12)

local title = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
title.Size = UDim2.new(1, -95, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "SIEXTHER GLITCHER"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(70, 130, 255)
title.Parent = mainFrame

local TitleGradient = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient")
TitleGradient.Parent = title
TitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
TitleGradient.Offset = Vector2.new(-1, 0)

task.spawn(function()
    while title and title.Parent do
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

-- Load notification system
__SIEXTHER_VIP_GLASS_V1.LoadString(game:HttpGet("https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/han.lua"))()

-- Dropdown Button untuk Mode Selection
local dropdownBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
dropdownBtn.Size = UDim2.new(1, -20, 0, 30)
dropdownBtn.Position = UDim2.new(0, 10, 0, 38)
dropdownBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
dropdownBtn.BorderSizePixel = 0
dropdownBtn.Text = "PILIH MODE ▼"
dropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dropdownBtn.Font = Enum.Font.GothamBold
dropdownBtn.TextSize = 12
dropdownBtn.ZIndex = 5
dropdownBtn.Parent = mainFrame

local dropdownCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", dropdownBtn)
dropdownCorner.CornerRadius = UDim.new(0, 7)

-- Dropdown Frame (akan muncul di luar mainFrame)
local dropdownFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScrollingFrame")
dropdownFrame.Size = UDim2.new(0, 220, 0, 200)
dropdownFrame.Position = UDim2.new(0, 10, 0, 70)
dropdownFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
dropdownFrame.BorderSizePixel = 0
dropdownFrame.Visible = false
dropdownFrame.ScrollBarThickness = 6
dropdownFrame.CanvasSize = UDim2.new(0, 0, 0, #GlitchModes * 32 + 10)
dropdownFrame.ZIndex = 100
dropdownFrame.Parent = mainFrame

local dropdownFrameCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", dropdownFrame)
dropdownFrameCorner.CornerRadius = UDim.new(0, 7)

local dropdownStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke", dropdownFrame)
dropdownStroke.Color = Color3.fromRGB(70, 130, 255)
dropdownStroke.Thickness = 2

-- Create mode buttons in dropdown
for i, mode in ipairs(GlitchModes) do
    local modeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    modeBtn.Size = UDim2.new(1, -10, 0, 28)
    modeBtn.Position = UDim2.new(0, 5, 0, (i - 1) * 32 + 5)
    modeBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
    modeBtn.BorderSizePixel = 0
    modeBtn.Text = mode.name
    modeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    modeBtn.Font = Enum.Font.GothamMedium
    modeBtn.TextSize = 11
    modeBtn.ZIndex = 101
    modeBtn.Parent = dropdownFrame
    
    local modeBtnCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", modeBtn)
    modeBtnCorner.CornerRadius = UDim.new(0, 5)
    
    modeBtn.MouseButton1Click:Connect(function()
        selectedMode = i
        dropdownBtn.Text = mode.name .. " ▼"
        dropdownFrame.Visible = false      
        
        -- If glitch already active, change mode directly
        if isGlitchActive then
            StopTrack()
            
            local id1 = extractIdFromInput(mode.id1)
            if id1 then
                LoadTrack(id1)
            end
            
            if mode.id2 then
                local id2 = extractIdFromInput(mode.id2)
                if id2 then
                    LoadTrack2(id2)
                end
            end
            
            getgenv().Notify({Title = "MODE BERUBAH", Content = "GLITCH BERGANTI KE " .. mode.name, Duration = 2})
            
        end
    end)
    
    modeBtn.MouseEnter:Connect(function()
        TweenService:Create(modeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 130, 255)}):Play()
        modeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    
    modeBtn.MouseLeave:Connect(function()
        TweenService:Create(modeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 40, 50)}):Play()
        modeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    end)
end

-- Toggle dropdown visibility
dropdownBtn.MouseButton1Click:Connect(function()
    dropdownFrame.Visible = not dropdownFrame.Visible
end)

-- Activate/Deactivate Button
local activateBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
activateBtn.Size = UDim2.new(1, -20, 0, 30)
activateBtn.Position = UDim2.new(0, 10, 0, 72)
activateBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
activateBtn.BorderSizePixel = 0
activateBtn.Text = "AKTIFKAN GLITCH"
activateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
activateBtn.Font = Enum.Font.GothamBold
activateBtn.TextSize = 12
activateBtn.Parent = mainFrame

local activateCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", activateBtn)
activateCorner.CornerRadius = UDim.new(0, 7)

activateBtn.MouseButton1Click:Connect(function()
    if not isGlitchActive then
        if not selectedMode then
        getgenv().Notify({Title = "TERJADI KESALAHAN", Content = "PILIH MODE DULU SAYANG!", Duration = 2})            
            return
        end
        
        local mode = GlitchModes[selectedMode]
        local id1 = extractIdFromInput(mode.id1)
        
        if id1 then
            LoadTrack(id1)
        end
        
        if mode.id2 then
            local id2 = extractIdFromInput(mode.id2)
            if id2 then
                LoadTrack2(id2)
            end
        end
        
        activateBtn.Text = "MATIKAN GLITCH"
        activateBtn.TextColor3 = Color3.fromRGB(255, 59, 48)
        isGlitchActive = true
        
        getgenv().Notify({Title = "SIEXTHER GLITCH", Content = mode.name .. " TELAH DIAKTIFKAN!", Duration = 2})
        

    else
        StopTrack()
        activateBtn.Text = "AKTIFKAN GLITCH"
        activateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        isGlitchActive = false
        
                getgenv().Notify({Title = "SIEXTHER GLITCH", Content = "GLITCH TELAH DIMATIKAN!", Duration = 2})
        

    end
end)

-- Speed Slider Container
local speedContainer = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
speedContainer.Size = UDim2.new(1, -20, 0, 48)
speedContainer.Position = UDim2.new(0, 10, 0, 107)
speedContainer.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
speedContainer.BorderSizePixel = 0
speedContainer.Parent = mainFrame

local speedCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", speedContainer)
speedCorner.CornerRadius = UDim.new(0, 7)

local speedStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke", speedContainer)
speedStroke.Color = Color3.fromRGB(70, 130, 255)
speedStroke.Thickness = 1
speedStroke.Transparency = 0.5

local speedLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -16, 0, 16)
speedLabel.Position = UDim2.new(0, 8, 0, 4)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = string.format("SPEED GLITCH: X%.1f", Settings["Speed"]) 
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.Font = Enum.Font.GothamMedium
speedLabel.TextSize = 11
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedContainer

local sliderBar = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
sliderBar.Size = UDim2.new(1, -16, 0, 7)
sliderBar.Position = UDim2.new(0, 8, 0, 28)
sliderBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
sliderBar.BorderSizePixel = 0
sliderBar.Parent = speedContainer

local sliderCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", sliderBar)
sliderCorner.CornerRadius = UDim.new(1, 0)

local sliderFill = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
sliderFill.Size = UDim2.new(0.2, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBar

local fillCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", sliderFill)
fillCorner.CornerRadius = UDim.new(1, 0)

local thumb = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
thumb.Size = UDim2.new(0, 14, 0, 14)
thumb.AnchorPoint = Vector2.new(0.5, 0.5)
thumb.Position = UDim2.new(0.2, 0, 0.5, 0)
thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
thumb.BorderSizePixel = 0
thumb.Parent = sliderBar

local thumbCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", thumb)
thumbCorner.CornerRadius = UDim.new(1, 0)

local thumbStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke", thumb)
thumbStroke.Color = Color3.fromRGB(70, 130, 255)
thumbStroke.Thickness = 2

-- TOOLS Divider dengan garis kiri kanan
local toolsDividerContainer = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
toolsDividerContainer.Size = UDim2.new(1, -20, 0, 18)
toolsDividerContainer.Position = UDim2.new(0, 10, 0, 161)
toolsDividerContainer.BackgroundTransparency = 1
toolsDividerContainer.Parent = mainFrame

local leftLine = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
leftLine.Size = UDim2.new(0.25, 0, 0, 1)
leftLine.Position = UDim2.new(0, 0, 0.5, 0)
leftLine.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
leftLine.BorderSizePixel = 0
leftLine.Parent = toolsDividerContainer

local toolsDivider = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
toolsDivider.Size = UDim2.new(0.5, 0, 1, 0)
toolsDivider.Position = UDim2.new(0.25, 0, 0, 0)
toolsDivider.BackgroundTransparency = 1
toolsDivider.Text = "TOOLS"
toolsDivider.TextColor3 = Color3.fromRGB(70, 130, 255)
toolsDivider.Font = Enum.Font.GothamBold
toolsDivider.TextSize = 11
toolsDivider.Parent = toolsDividerContainer

local rightLine = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
rightLine.Size = UDim2.new(0.25, 0, 0, 1)
rightLine.Position = UDim2.new(0.75, 0, 0.5, 0)
rightLine.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
rightLine.BorderSizePixel = 0
rightLine.Parent = toolsDividerContainer

-- Spin Button
local spinBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
spinBtn.Size = UDim2.new(0.48, -5, 0, 28)
spinBtn.Position = UDim2.new(0, 10, 0, 184)
spinBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
spinBtn.BorderSizePixel = 0
spinBtn.Text = "SPIN"
spinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
spinBtn.Font = Enum.Font.GothamBold
spinBtn.TextSize = 11
spinBtn.Parent = mainFrame

local spinCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", spinBtn)
spinCorner.CornerRadius = UDim.new(0, 7)

-- Swimming Button
local swimBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
swimBtn.Size = UDim2.new(0.48, -5, 0, 28)
swimBtn.Position = UDim2.new(0.52, 0, 0, 184)
swimBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
swimBtn.BorderSizePixel = 0
swimBtn.Text = "SWIM"
swimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
swimBtn.Font = Enum.Font.GothamBold
swimBtn.TextSize = 11
swimBtn.Parent = mainFrame

local swimCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", swimBtn)
swimCorner.CornerRadius = UDim.new(0, 7)

-- Copy Hat IDs Button
local copyHatBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
copyHatBtn.Size = UDim2.new(1, -20, 0, 28)
copyHatBtn.Position = UDim2.new(0, 10, 0, 217)
copyHatBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
copyHatBtn.BorderSizePixel = 0
copyHatBtn.Text = "COPY HAT"
copyHatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyHatBtn.Font = Enum.Font.GothamBold
copyHatBtn.TextSize = 11
copyHatBtn.Parent = mainFrame

local copyHatCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", copyHatBtn)
copyHatCorner.CornerRadius = UDim.new(0, 7)

-- Update button state based on map
local function updateCopyHatButton()
    if isInCorrectMap() then
        copyHatBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
        copyHatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        copyHatBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
        copyHatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        
    end
end

-- Initial button state check
updateCopyHatButton()

-- Speed Slider
local function updateSpeedSlider(value)
    Settings["Speed"] = value
    speedLabel.Text = string.format("SPEED GLITCH: X%.1f", value)
    local rel = math.clamp((value - 0) / (10 - 0), 0, 1)
    TweenService:Create(sliderFill, TweenInfo.new(0.15), {Size = UDim2.new(rel, 0, 1, 0)}):Play()
    TweenService:Create(thumb, TweenInfo.new(0.15), {Position = UDim2.new(rel, 0, 0.5, 0)}):Play()

    if CurrentTrack1 and CurrentTrack1.IsPlaying then
        CurrentTrack1:AdjustSpeed(Settings["Speed"])
    end
    if CurrentTrack2 and CurrentTrack2.IsPlaying then
        CurrentTrack2:AdjustSpeed(Settings["Speed"])
    end
end

local dragging = false
local function updateFromInput(input)
    local relX = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
    local value = math.floor((0 + (10 - 0) * relX) * 10) / 10
    updateSpeedSlider(value)
end

sliderBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        updateFromInput(input)
    end
end)

thumb.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        updateFromInput(input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateFromInput(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        dragging = false
    end
end)

-- Spin Button Logic
local isSpinning = false
local spinConnection

spinBtn.MouseButton1Click:Connect(function()
    if not isSpinning then
        isSpinning = true
        spinBtn.Text = "SPIN"
        spinBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        
        spinConnection = RunService.RenderStepped:Connect(function(dt)
            if character.PrimaryPart then
                character.PrimaryPart.CFrame = character.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(40), 0)
            end
        end)
    else
        isSpinning = false
        spinBtn.Text = "SPIN"
        spinBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
        
        if spinConnection then
            spinConnection:Disconnect()
            spinConnection = nil
        end
    end
end)

-- Swimming Logic
local swimming = false
local oldgrav = nil
local gravReset = nil
local swimbeat = nil

local function startSwimming()
    if player and character and humanoid then
        oldgrav = workspace.Gravity
        workspace.Gravity = 0
        
        local function swimDied()
            workspace.Gravity = oldgrav
            swimming = false
            if gravReset then
                gravReset:Disconnect()
            end
            if swimbeat then
                swimbeat:Disconnect()
                swimbeat = nil
            end
            local enums = Enum.HumanoidStateType:GetEnumItems()
            table.remove(enums, table.find(enums, Enum.HumanoidStateType.None))
            for _, v in pairs(enums) do
                humanoid:SetStateEnabled(v, true)
            end
        end
        
        gravReset = humanoid.Died:Connect(swimDied)
        local enums = Enum.HumanoidStateType:GetEnumItems()
        table.remove(enums, table.find(enums, Enum.HumanoidStateType.None))
        for _, v in pairs(enums) do
            humanoid:SetStateEnabled(v, false)
        end
        humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
        
        swimbeat = RunService.Heartbeat:Connect(function()
            pcall(function()
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local rootPart = character.HumanoidRootPart
                    if humanoid.MoveDirection ~= Vector3.new() then
                        rootPart.Velocity = Vector3.new(0, 10, 0)
                    else
                        rootPart.Velocity = Vector3.new()
                    end
                end
            end)
        end)
        
        swimming = true
    end
end

local function stopSwimming()
    if swimming then
        workspace.Gravity = oldgrav
        swimming = false
        if gravReset then
            gravReset:Disconnect()
            gravReset = nil
        end
        if swimbeat then
            swimbeat:Disconnect()
            swimbeat = nil
        end
        local enums = Enum.HumanoidStateType:GetEnumItems()
        table.remove(enums, table.find(enums, Enum.HumanoidStateType.None))
        for _, v in pairs(enums) do
            humanoid:SetStateEnabled(v, true)
        end
    end
end

swimBtn.MouseButton1Click:Connect(function()
    if swimming then
        stopSwimming()
        swimBtn.Text = "SWIM"
        swimBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
    else
        startSwimming()
        swimBtn.Text = "SWIM"
        swimBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    end
end)

-- Copy Hat IDs Button Logic
copyHatBtn.MouseButton1Click:Connect(function()
    __SIEXTHER_VIP_GLASS_V1.LoadString(game:HttpGet("https://app.buddy.works/ilhamfleast123/kyzn/repository/raw/branch/master/cc"))()
end)

-- Variable untuk menyimpan posisi frame
local savedFramePosition = mainFrame.Position

-- Minimize/Maximize Logic dengan Animasi
minimizeBtn.MouseButton1Click:Connect(function()
    savedFramePosition = mainFrame.Position
    
    mainFrame.Visible = false
    minimizedBtn.Visible = true
end)

minimizedBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    minimizedBtn.Visible = false
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = savedFramePosition
    mainFrame.BackgroundTransparency = 1
    
    SmoothTween(mainFrame, 0.5, {
        Size = UDim2.new(0, 240, 0, 250),
        Position = savedFramePosition,
        BackgroundTransparency = 0
    })
end)

-- Close Button Logic dengan Animasi
closeBtn.MouseButton1Click:Connect(function()
    StopTrack()
    if spinConnection then
        spinConnection:Disconnect()
    end
    stopSwimming()
    if freeCamEnabled then
        disableFreeCam()
    end
    screenGui:Destroy()
end)

RunService.RenderStepped:Connect(function()
    if character.PrimaryPart then
        lastPosition = character.PrimaryPart.Position
    end
end)

-- Handle character respawn for FreeCam
player.CharacterAdded:Connect(function(newChar)
    if freeCamEnabled then
        task.wait(0.1)
        local hum = newChar:WaitForChild("Humanoid")
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        hum.JumpHeight = 0
    end
end)