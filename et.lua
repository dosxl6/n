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


local ScriptVersion = 5.55
local LastUsedVersion = ScriptVersion
local LaunchedTimes = 0
local TotalTimeUsed = 0 
local GuiActive = true
local GuiEmoter = nil
local AnimationHandler = "Animate"
local Player = game.Players.LocalPlayer
local IsInStudio = game:GetService("RunService"):IsStudio()
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ContextActionService = game:GetService("ContextActionService")


--Settings
local ToolAnimHighPriorEnabled = false
local AnimPreviewEnabled = true
local DebugInfoEnabled = false
local AnalyticsEnabled = true
local LoadAnimationsOnRestart = true
local LoadAllAnimationsOnRestart = false
local TopMost = false
local DragDelay = 0.1

local ToolIdleAnimHighPriorEnabled = false
local ToolActionAnimHighPriorEnabled = true
local AnimSwitchModeEnabled = false
local AnimSwitchModeRunIdleExceptionEnabled = true
local AnimSmoothFadeEnabled = true
local HigherPriorityEnabled = false

local IdleTypeEnabled = true
local RunningTypeEnabled = true
local RunningTypeStopStandingEnabled = true
local RunningTypeCharSpeedEnabled = true
local RunningTypeMinSpeedEnabled = true
local RunningTypeStopJumpingEnabled = true
local RunningTypeStopClimbingEnabled = true

local Theme = "LightPurple"
local UIGradientEnabled = true
local UICornerEnabled = true
local XSize = 460
local YSize = 285

local LoadGithubSGAEnabled = true
local LoadGithubCustomAnimsEnabled = true
local LoadLocalSGAEnabled = true
local LoadLocalCustomAnimsEnabled = true

local HotkeysEnabled = true
local DoubleHotkey = __SIEXTHER_VIP_GLASS_V1.Instance.new("StringValue")
local EmoteWheelHotkey = __SIEXTHER_VIP_GLASS_V1.Instance.new("StringValue")
local SearchHotkey = __SIEXTHER_VIP_GLASS_V1.Instance.new("StringValue")
local CloseHotkey = __SIEXTHER_VIP_GLASS_V1.Instance.new("StringValue")
local SitHotkey = __SIEXTHER_VIP_GLASS_V1.Instance.new("StringValue")
local SwitchAnimHotkey = __SIEXTHER_VIP_GLASS_V1.Instance.new("StringValue")
local AnimFadeHotkey = __SIEXTHER_VIP_GLASS_V1.Instance.new("StringValue")
local SettingsHotkey = __SIEXTHER_VIP_GLASS_V1.Instance.new("StringValue")
local StopAnimsHotkey = __SIEXTHER_VIP_GLASS_V1.Instance.new("StringValue")
local ResetCharHotkey = __SIEXTHER_VIP_GLASS_V1.Instance.new("StringValue")

CloseHotkey.Value = "T"
SettingsHotkey.Value = "Y"
SearchHotkey.Value = "DoubleH"
SitHotkey.Value = "J"
SwitchAnimHotkey.Value = "V"
StopAnimsHotkey.Value = "N"
AnimFadeHotkey.Value = "B"
ResetCharHotkey.Value = "DoubleR"

DoubleHotkey.Value = "LeftControl" --A secondary key for activating a DoubleHotkey
EmoteWheelHotkey.Value = "Comma" --Not affected by "Hotkeys Enabled" setting


local IsDefaultSettings = true
local ConfigFile = "SiextherEmote/EmoterConfig.json"
if not IsInStudio then
	local targetNumber = tostring(game.GameId)
	local folderPath = "SiextherEmote/SpecificSettings"
	local fileFound = false

	-- Some executors error when the settings folder does not exist yet.
	-- Do not abort the whole script, otherwise CreateGui() is never reached.
	if type(makefolder) == "function" then
		pcall(makefolder, "EmoterData")
		pcall(makefolder, folderPath)
	end

	local success, files = pcall(listfiles, folderPath)
	if not success or type(files) ~= "table" then
		files = {}
	end
	for _, filePath in ipairs(files) do
		local fileName = filePath:match("[^/\\]+$") or filePath
		local extractedNumber = fileName:match("(%d+)")

		if extractedNumber then
			if extractedNumber == targetNumber then
				fileFound = true
				ConfigFile = filePath
				IsDefaultSettings = false
				print("Found settings specifically for this game, loading...")
				break
			end
		end
	end
	
	if isfile("SiextherEmote/EmoterConfig.json") then
		local rawData = readfile("SiextherEmote/EmoterConfig.json")
		local DecodedSettings = HttpService:JSONDecode(rawData)
		if DecodedSettings.ConfLastUsedVersion then LastUsedVersion = tonumber(DecodedSettings.ConfLastUsedVersion) else LastUsedVersion = 5.5 end
		if DecodedSettings.ConfLaunchedTimes then LaunchedTimes = tonumber(DecodedSettings.ConfLaunchedTimes) end
		if DecodedSettings.ConfTotalTimeUsed then TotalTimeUsed = tonumber(DecodedSettings.ConfTotalTimeUsed) end
	end
	if isfile(ConfigFile) then
		local rawData = readfile(ConfigFile)
		local DecodedSettings = HttpService:JSONDecode(rawData)
		
		AnimPreviewEnabled = DecodedSettings.ConfAnimPreviewEnabled
		DebugInfoEnabled = DecodedSettings.ConfDebugInfoEnabled
		AnalyticsEnabled = DecodedSettings.ConfAnalyticsEnabled
		LoadAnimationsOnRestart = DecodedSettings.ConfLoadAnimationsOnRestart
		LoadAllAnimationsOnRestart = DecodedSettings.ConfLoadAllAnimationsOnRestart
		TopMost = DecodedSettings.ConfTopMost
		if DecodedSettings.ConfDragDelay then DragDelay = DecodedSettings.ConfDragDelay end

		ToolIdleAnimHighPriorEnabled = DecodedSettings.ConfToolIdleAnimHighPriorEnabled
		ToolActionAnimHighPriorEnabled = DecodedSettings.ConfToolActionAnimHighPriorEnabled
		AnimSwitchModeEnabled = DecodedSettings.ConfAnimSwitchModeEnabled
		AnimSwitchModeRunIdleExceptionEnabled = DecodedSettings.ConfAnimSwitchModeRunIdleExceptionEnabled
		AnimSmoothFadeEnabled = DecodedSettings.ConfAnimSmoothFadeEnabled
		HigherPriorityEnabled = DecodedSettings.ConfHigherPriorityEnabled

		IdleTypeEnabled = DecodedSettings.ConfIdleTypeEnabled
		RunningTypeEnabled = DecodedSettings.ConfRunningTypeEnabled
		RunningTypeStopStandingEnabled = DecodedSettings.ConfRunningTypeStopStandingEnabled
		RunningTypeCharSpeedEnabled = DecodedSettings.ConfRunningTypeCharSpeedEnabled
		RunningTypeMinSpeedEnabled = DecodedSettings.ConfRunningTypeMinSpeedEnabled
		RunningTypeStopJumpingEnabled = DecodedSettings.ConfRunningTypeStopJumpingEnabled
		RunningTypeStopClimbingEnabled = DecodedSettings.ConfRunningTypeStopClimbingEnabled

		Theme = DecodedSettings.ConfTheme
		UIGradientEnabled = DecodedSettings.ConfUIGradientEnabled
		UICornerEnabled = DecodedSettings.ConfUICornerEnabled
		XSize = DecodedSettings.ConfXSize
		YSize = DecodedSettings.ConfYSize

		LoadGithubSGAEnabled = DecodedSettings.ConfLoadGithubSGAEnabled
		LoadGithubCustomAnimsEnabled = DecodedSettings.ConfLoadGithubCustomAnimsEnabled
		LoadLocalSGAEnabled = DecodedSettings.ConfLoadLocalSGAEnabled
		LoadLocalCustomAnimsEnabled = DecodedSettings.ConfLoadLocalCustomAnimsEnabled

		HotkeysEnabled = DecodedSettings.ConfHotkeysEnabled
		if DecodedSettings.ConfDoubleHotkey then DoubleHotkey.Value = tostring(DecodedSettings.ConfDoubleHotkey) end
		if DecodedSettings.ConfEmoteWheelHotkey then EmoteWheelHotkey.Value = tostring(DecodedSettings.ConfEmoteWheelHotkey) end
		if DecodedSettings.ConfCloseHotkey then CloseHotkey.Value = tostring(DecodedSettings.ConfCloseHotkey) end
		if DecodedSettings.ConfSettingsHotkey then SettingsHotkey.Value = tostring(DecodedSettings.ConfSettingsHotkey) end
		if DecodedSettings.ConfSearchHotkey then SearchHotkey.Value = tostring(DecodedSettings.ConfSearchHotkey) end
		if DecodedSettings.ConfSitHotkey then SitHotkey.Value = tostring(DecodedSettings.ConfSitHotkey) end
		if DecodedSettings.ConfSwitchAnimHotkey then SwitchAnimHotkey.Value = tostring(DecodedSettings.ConfSwitchAnimHotkey) end
		if DecodedSettings.ConfAnimFadeHotkey then AnimFadeHotkey.Value = tostring(DecodedSettings.ConfAnimFadeHotkey) end
		if DecodedSettings.ConfStopAnimsHotkey then StopAnimsHotkey.Value = tostring(DecodedSettings.ConfStopAnimsHotkey) end
		if DecodedSettings.ConfResetCharHotkey then ResetCharHotkey.Value = tostring(DecodedSettings.ConfResetCharHotkey) end
	end
end

local function SaveData(Type)
	local SettingsToSave = {
		ConfLastUsedVersion = ScriptVersion,
		ConfLaunchedTimes = LaunchedTimes,
		ConfTotalTimeUsed = TotalTimeUsed,
		
		ConfAnimPreviewEnabled = AnimPreviewEnabled,
		ConfDebugInfoEnabled = DebugInfoEnabled,
		ConfAnalyticsEnabled = AnalyticsEnabled,
		ConfLoadAnimationsOnRestart = LoadAnimationsOnRestart,
		ConfLoadAllAnimationsOnRestart = LoadAllAnimationsOnRestart,
		ConfTopMost = TopMost,
		ConfDragDelay = DragDelay,

		ConfToolIdleAnimHighPriorEnabled = ToolIdleAnimHighPriorEnabled,
		ConfToolActionAnimHighPriorEnabled = ToolActionAnimHighPriorEnabled,
		ConfAnimSwitchModeEnabled = AnimSwitchModeEnabled,
		ConfAnimSwitchModeRunIdleExceptionEnabled = AnimSwitchModeRunIdleExceptionEnabled,
		ConfAnimSmoothFadeEnabled = AnimSmoothFadeEnabled,
		ConfHigherPriorityEnabled = HigherPriorityEnabled,

		ConfIdleTypeEnabled = IdleTypeEnabled,
		ConfRunningTypeEnabled = RunningTypeEnabled,
		ConfRunningTypeStopStandingEnabled = RunningTypeStopStandingEnabled,
		ConfRunningTypeCharSpeedEnabled = RunningTypeCharSpeedEnabled,
		ConfRunningTypeMinSpeedEnabled = RunningTypeMinSpeedEnabled,
		ConfRunningTypeStopJumpingEnabled = RunningTypeStopJumpingEnabled,
		ConfRunningTypeStopClimbingEnabled = RunningTypeStopClimbingEnabled,

		ConfTheme = Theme,
		ConfUIGradientEnabled = UIGradientEnabled,
		ConfUICornerEnabled = UICornerEnabled,
		ConfXSize = XSize,
		ConfYSize = YSize,

		ConfLoadGithubSGAEnabled = LoadGithubSGAEnabled,
		ConfLoadGithubCustomAnimsEnabled = LoadGithubCustomAnimsEnabled,
		ConfLoadLocalSGAEnabled = LoadLocalSGAEnabled,
		ConfLoadLocalCustomAnimsEnabled = LoadLocalCustomAnimsEnabled,

		ConfHotkeysEnabled = HotkeysEnabled,
		ConfDoubleHotkey = DoubleHotkey.Value,
		ConfEmoteWheelHotkey = EmoteWheelHotkey.Value,
		ConfCloseHotkey = CloseHotkey.Value,
		ConfSettingsHotkey = SettingsHotkey.Value,
		ConfSearchHotkey = SearchHotkey.Value,
		ConfSitHotkey = SitHotkey.Value,
		ConfSwitchAnimHotkey = SwitchAnimHotkey.Value,
		ConfAnimFadeHotkey = AnimFadeHotkey.Value,
		ConfStopAnimsHotkey = StopAnimsHotkey.Value,
		ConfResetCharHotkey = ResetCharHotkey.Value
	}
	local encodedData = HttpService:JSONEncode(SettingsToSave)

	if Type == "Default" then
		writefile("SiextherEmote/EmoterConfig.json", encodedData)
		game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Saved", Text = "Succesfully saved settings!", Duration = 3})
	elseif Type == "Specific" then
		local targetNumber = tostring(game.GameId)
		local folderPath = "SiextherEmote/SpecificSettings"
		local fileFound = false

		local success, files = pcall(listfiles, folderPath)
		if not success then
			return
		end
		for _, filePath in ipairs(files) do
			local fileName = filePath:match("[^/\\]+$") or filePath
			local extractedNumber = fileName:match("(%d+)")

			if extractedNumber then
				if extractedNumber == targetNumber then
					fileFound = true
					ConfigFile = filePath
					print("Found settings specifically for this game, saving...")
					break
				end
			end
		end
		if not fileFound then
			ConfigFile = "SiextherEmote/SpecificSettings/"..targetNumber.." (".. game:GetService("MarketplaceService"):GetProductInfoAsync(game.PlaceId).Name ..").json"
		end

		writefile(ConfigFile, encodedData)
		game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Saved", Text = "Succesfully saved settings for specific game!", Duration = 3})
	elseif Type == "Update" then
		local rawData = readfile("SiextherEmote/EmoterConfig.json")
		local DecodedData = HttpService:JSONDecode(rawData)
		
		DecodedData.ConfLaunchedTimes = LaunchedTimes + 1
		DecodedData.ConfLastUsedVersion = ScriptVersion
		DecodedData.ConfTotalTimeUsed = TotalTimeUsed
		
		local UpdatedData = HttpService:JSONEncode(DecodedData)
		writefile("SiextherEmote/EmoterConfig.json", UpdatedData)
	end
end

local BgColor = __SIEXTHER_VIP_GLASS_V1.bgColor
local ScrollBgColor = __SIEXTHER_VIP_GLASS_V1.buttonColor
local UiButColor = __SIEXTHER_VIP_GLASS_V1.textColor -- Color of GUI's buttons and Texts
local TextBgColor = __SIEXTHER_VIP_GLASS_V1.buttonColor
local ButtonCol = __SIEXTHER_VIP_GLASS_V1.buttonColor -- R6 Button Color
local ButtonSelectCol = __SIEXTHER_VIP_GLASS_V1.primaryColor -- R6 Button lighter color (idk how to make it just darker BgColor yet)

--Restart Values
local FirstLaunch = true
local GuiPos = nil
local SettingsPos = nil
local ScrollingFramePos = nil
local ScrollingFrameSpecificPos = nil
local GuiClosed = false
local OptionsOpened = false
local SettingsOpened = false
local CurrentSection = "Default"
local PriorityAltPressed = false
local RunAltPressed = false
local IdleAltPressed = false

local PrevAnimSpeedValue = ""
local SearchOpened = false
local PrevSearchText = ""
local CustomAnimOpened = false
local PrevCustomAnimId = ""

local RestartAnimations = {}

local EmoteWheelEmotes = {Emote1 = nil, Emote2 = nil, Emote3 = nil, Emote4 = nil, Emote5 = nil, Emote6 = nil, Emote7 = nil, Emote8 = nil}

if (Player.Character:WaitForChild("Humanoid").RigType == Enum.HumanoidRigType.R15) then
	EmoteWheelEmotes.Emote1 = "R15Wave"
	EmoteWheelEmotes.Emote2 = "R15FortniteDance"
	EmoteWheelEmotes.Emote3 = "R15GangnamStyle"
	EmoteWheelEmotes.Emote4 = "R15RussianKick"
	EmoteWheelEmotes.Emote5 = "R15Rambunctious"
	EmoteWheelEmotes.Emote6 = "R15Helicopter"
	EmoteWheelEmotes.Emote7 = "R15MiniWalk"
	EmoteWheelEmotes.Emote8 = "R15TakeTheL"
else
	EmoteWheelEmotes.Emote1 = "R6Dance1"
	EmoteWheelEmotes.Emote2 = "R6Dance2"
	EmoteWheelEmotes.Emote3 = "R6Dance3"
	EmoteWheelEmotes.Emote4 = "R6MovingDance"
	EmoteWheelEmotes.Emote5 = "R6Bang"
	EmoteWheelEmotes.Emote6 = "R6SpinDance"
	EmoteWheelEmotes.Emote7 = "R6FloatSit"
	EmoteWheelEmotes.Emote8 = "R6Spinner"
end


--GUI stuff and tables (Moved most of locales are here cuz of that stupid 200 locales limit in a single function and i have no idea how to fix it in another way)
local DefaultAnimsNameList
local ToolIdleAnimsList
local ToolActionAnimsList
local Emoter
local MainFrame
local ViewportFrame
local SideFrame
local SideFrameTitle
local OpenGUI
local SFDestroyGUI
local GuiTopFrame
local DestroyGUI
local CloseGUI
local Title
local GuiBottomFrame
local SpeedFrame
local CurAnimInfoTitle
local OptionsButton
local ScrollingFrame
local ScrollingFrameR15
local ScrollingFrameSpecific
local ScrollingFramesList
local OptionsFrame
local StopAnimsEvent
local PauseAnimsButton
local PauseAnimsOption
local StopDefAnimsButton
local PauseAnimateButton
local SitButton
local ReversePlayButton
local EmoteWheelButton
local SearchFrame
local SearchButton
local SearchBox
local BackButton
local CustomAnimFrame
local CustomAnimButton
local IdBox
local CustomAnimBackButton
local AddTempAnimButton
local DefaultSection
local SpecGameSection
local EmoteWheel
local EmoteWheelText local Emote1 local Emote2 local Emote3 local Emote4 local Emote5 local Emote6 local Emote7 local Emote8
local SettingsFrame
local GuiName
local AutorText
local VersionText
local SGSNotification
local DataNotification
local SettingsStuff
local DragDelayOption
local DragOptionText
local DelayNumBox
local ThemeOption
local ThemeOptionText
local PurpleThemeColor
local OrangeThemeColor
local YellowThemeColor
local BlackThemeColor
local HotkeysEditOption
local HotkeysFrame
local HotkeysStuff
local HotkeyFrameName
local MoreButtonsFrame
local SaveSettingsButton
local LaunchIdDetectorButton
local ResetButton
local GithubLinkButton

local function CreateGui()
	-- Prevent legacy UI flashing for a frame while it is being constructed.
	if Emoter then Emoter.Enabled = false end
	print("Loading Emoter GUI...")

	local SpeedNum = 0 --Value, adding to default speed of animation
	local AnimInfo = __SIEXTHER_VIP_GLASS_V1.Instance.new("StringValue")
	local AddedDataInfo = __SIEXTHER_VIP_GLASS_V1.Instance.new("StringValue")
	local NegativeNumber = 1
	local DefaultWalkSpeed = 16
	local SFHideTimeCount = 0
	local Humanoid = nil
	local ClonedChar = nil
	local RigType = nil
	local GuiLoaded = false
	local GuiRestarted = false
	if (Player.Character:WaitForChild("Humanoid").RigType == Enum.HumanoidRigType.R15) then
		RigType = "R15"
	elseif (Player.Character:WaitForChild("Humanoid").RigType == Enum.HumanoidRigType.R6) then
		RigType = "R6"
	else
		RigType = "R15"
	end

	DefaultAnimsNameList = {"Animation1", "Animation2", "Animation3", "ClimbAnim", "FallAnim", "JumpAnim", "RunAnim", "SitAnim", "ToolNoneAnim", "WalkAnim", "CheerAnim", "LaughAnim", "PointAnim", "Swim", "SwimIdle", "ToolLungeAnim", "ToolSlashAnim", "WaveAnim"}
	ToolIdleAnimsList = {"ToolNoneAnim", "507768375", "182393478"}
	ToolActionAnimsList = {"ToolLungeAnim", "ToolSlashAnim", "522638767", "522635514", "129967390", "129967478"}

	Emoter = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui") --The actual GUI
	MainFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame") --All of the stuff on the main frame
	local MFUIScale = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIScale", MainFrame)
	ViewportFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("ViewportFrame") --Frame with animation preview

	SideFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("CanvasGroup") --Visible when GUI is closed
	local SFUIScale = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIScale", SideFrame)
	SideFrameTitle = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
	OpenGUI = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")
	SFDestroyGUI = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")

	GuiTopFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame") --Top of the main frame
	DestroyGUI = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	CloseGUI = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")
	Title = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")

	GuiBottomFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame") --Bottom of the main frame
	SpeedFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame") -- Frame of Speed Changer
	CurAnimInfoTitle = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
	OptionsButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")

	ScrollingFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScrollingFrame") --Scrolling frame of R6 animations
	ScrollingFrameR15 = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScrollingFrame") --Scrolling frame of R15 animations
	ScrollingFrameSpecific = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScrollingFrame") --Scrolling frame of specific game animations
	ScrollingFramesList = {
		ScrollingFrame,
		ScrollingFrameR15,
		ScrollingFrameSpecific
	}

	OptionsFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame") --Frame of additional options
	StopAnimsEvent = __SIEXTHER_VIP_GLASS_V1.Instance.new("BindableEvent") --Event to stop animations when disabling StopDefaultAnims option
	PauseAnimsButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")
	PauseAnimsOption = false
	StopDefAnimsButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")
	PauseAnimateButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")
	SitButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")
	ReversePlayButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")
	EmoteWheelButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")

	SearchFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame") --Frame for searching anims
	SearchButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")
	SearchBox = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextBox")
	BackButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")

	CustomAnimFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame") --Frame for adding anims by it's Id
	CustomAnimButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")
	IdBox = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextBox")
	CustomAnimBackButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")
	AddTempAnimButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")

	DefaultSection = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton") --Sections in case when you have specific game anims
	SpecGameSection = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")

	EmoteWheel = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame") --Emote wheel 
	EmoteWheelText = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
	Emote1 = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	Emote2 = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	Emote3 = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	Emote4 = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	Emote5 = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	Emote6 = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	Emote7 = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	Emote8 = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")

	SettingsFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame") --Settings
	GuiName = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
	AutorText = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
	VersionText = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
	local WarningText = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
	SGSNotification = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")
	DataNotification = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")
	SettingsStuff = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScrollingFrame")
	DragDelayOption = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
	DragOptionText = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
	DelayNumBox = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextBox")
	ThemeOption = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
	ThemeOptionText = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
	PurpleThemeColor = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	OrangeThemeColor = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	YellowThemeColor = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	BlackThemeColor = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	HotkeysEditOption = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	HotkeysFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
	HotkeysStuff = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScrollingFrame")
	HotkeyFrameName = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
	MoreButtonsFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
	SaveSettingsButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")
	LaunchIdDetectorButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")
	ResetButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")
	GithubLinkButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")

	if Theme == "LightOrange" then
		BgColor = __SIEXTHER_VIP_GLASS_V1.bgColor
		ScrollBgColor = __SIEXTHER_VIP_GLASS_V1.buttonColor
		UiButColor = __SIEXTHER_VIP_GLASS_V1.textColor
		TextBgColor = __SIEXTHER_VIP_GLASS_V1.buttonColor
		ButtonCol = __SIEXTHER_VIP_GLASS_V1.buttonColor
		ButtonSelectCol = __SIEXTHER_VIP_GLASS_V1.primaryColor
	elseif Theme == "LightPurple" then
		BgColor = __SIEXTHER_VIP_GLASS_V1.bgColor
		ScrollBgColor = __SIEXTHER_VIP_GLASS_V1.buttonColor
		UiButColor = __SIEXTHER_VIP_GLASS_V1.textColor
		TextBgColor = __SIEXTHER_VIP_GLASS_V1.buttonColor
		ButtonCol = __SIEXTHER_VIP_GLASS_V1.buttonColor
		ButtonSelectCol = __SIEXTHER_VIP_GLASS_V1.primaryColor
	elseif Theme == "LightYellow" then
		BgColor = __SIEXTHER_VIP_GLASS_V1.bgColor
		ScrollBgColor = __SIEXTHER_VIP_GLASS_V1.buttonColor
		UiButColor = __SIEXTHER_VIP_GLASS_V1.textColor
		TextBgColor = __SIEXTHER_VIP_GLASS_V1.buttonColor
		ButtonCol = __SIEXTHER_VIP_GLASS_V1.buttonColor
		ButtonSelectCol = __SIEXTHER_VIP_GLASS_V1.primaryColor
	elseif Theme == "Black" then
		BgColor = __SIEXTHER_VIP_GLASS_V1.bgColor
		ScrollBgColor = __SIEXTHER_VIP_GLASS_V1.buttonColor
		UiButColor = __SIEXTHER_VIP_GLASS_V1.textColor
		TextBgColor = __SIEXTHER_VIP_GLASS_V1.buttonColor
		ButtonCol = __SIEXTHER_VIP_GLASS_V1.buttonColor
		ButtonSelectCol = __SIEXTHER_VIP_GLASS_V1.primaryColor
	end

	local function AddVPF()
		ViewportFrame.Parent = MainFrame
		ViewportFrame.Visible = false
		ViewportFrame.AnchorPoint = Vector2.new(0, 0.5)
		ViewportFrame.BackgroundTransparency = 1
		ViewportFrame.Size = UDim2.new(0, 225, 0, 285)
		ViewportFrame.Position = UDim2.new(1, 10, 0.5, 0)
		ViewportFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
		ViewportFrame.Ambient = Color3.fromRGB(175, 175, 175)
		ViewportFrame.LightColor = Color3.fromRGB(208, 208, 208)
		local UICorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
		UICorner.Parent = ViewportFrame
		local UIStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
		UIStroke.Parent = ViewportFrame
		UIStroke.Thickness = 1
		UIStroke.BorderStrokePosition = Enum.BorderStrokePosition.Outer

		local WorldModel = __SIEXTHER_VIP_GLASS_V1.Instance.new("WorldModel")
		WorldModel.Parent = ViewportFrame
		local Character = nil
		local function WaitForChar()
			while wait() do 
				if Player.Character:FindFirstChild("Humanoid") and Player.Character:FindFirstChild("HumanoidRootPart") then
					Character = Player.Character or Player.CharacterAdded:Wait()
					Humanoid = Character:FindFirstChild("Humanoid")
					return
				end
			end
		end
		WaitForChar()
		wait(0.5)
		local VPFcam = __SIEXTHER_VIP_GLASS_V1.Instance.new("Camera"); VPFcam.Parent = ViewportFrame
		VPFcam.CameraType = Enum.CameraType.Scriptable

		local targetPosition = nil
		targetPosition = Vector3.new(4.6, 0.2, 12)
		if RigType == "R15" then
			targetPosition = Vector3.new(4.6, 0.2, 12) -- if R15
		else
			targetPosition = Vector3.new(4.6, -1, 12)
		end

		local targetRotation = CFrame.Angles(0, math.rad(20), 0)
		VPFcam.CFrame = CFrame.new(targetPosition) * targetRotation
		ViewportFrame.CurrentCamera = VPFcam
		VPFcam.FieldOfView = 37
		Character.Archivable = true
		ClonedChar = Character:Clone()
		ClonedChar.Name = "VPFCharacter"
		ClonedChar.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		ClonedChar.Parent = WorldModel
		if ClonedChar:FindFirstChild(AnimationHandler) then
			ClonedChar:FindFirstChild(AnimationHandler):Destroy()
		end
		if ClonedChar:FindFirstChildOfClass("Tool") then
			ClonedChar:FindFirstChildOfClass("Tool"):Destroy()
		end
		ClonedChar:SetPrimaryPartCFrame(CFrame.new(Vector3.new(0,0,-0.4), Vector3.new(0,0,7)))
	end
	AddVPF()

	local function AddHoverText(Object, Text, Hotkey)
		local TextLabel = nil
		Object.MouseEnter:connect(function()
			TextLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
			TextLabel.Parent = Emoter
			TextLabel.Visible = false
			TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			TextLabel.AutomaticSize = Enum.AutomaticSize.XY
			TextLabel.Size = UDim2.new(0, 5, 0, 17)
			TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
			TextLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
			TextLabel.TextSize = 17
			TextLabel.TextWrapped = true
			TextLabel.Font = Enum.Font.SourceSans
			TextLabel.TextXAlignment = Enum.TextXAlignment.Left
			TextLabel.RichText = true

			if Text.Value then
				TextLabel.Text = Text.Value
			elseif Hotkey ~= nil and Hotkey.Value ~= "" then
				if Hotkey.Value:find("Double") then
					TextLabel.Text = Text.." ["..DoubleHotkey.Value.." + "..Hotkey.Value:gsub("Double", "").."]"
				else
					TextLabel.Text = Text.." ["..Hotkey.Value.."]"
				end
			else
				TextLabel.Text = Text
			end

			local UIPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
			UIPadding.PaddingLeft = UDim.new(0, 2)
			UIPadding.PaddingRight = UDim.new(0, 2)
			UIPadding.PaddingBottom = UDim.new(0, 2)
			UIPadding.Parent = TextLabel

			local UISizeConstraint = __SIEXTHER_VIP_GLASS_V1.Instance.new("UISizeConstraint")
			UISizeConstraint.Parent = TextLabel
			UISizeConstraint.MaxSize = Vector2.new(400, 3000)

			local UserInputService = game:GetService("UserInputService")
			local mouse = Player:GetMouse()
			TextLabel.Position = UDim2.new(0, mouse.X, 0, mouse.Y + 85)
			TextLabel.Visible = true
			mouse.Move:connect(function()
				TextLabel.Position = UDim2.new(0, mouse.X, 0, mouse.Y + 85)
			end)
			-- Add hover text
		end)
		Object.MouseLeave:connect(function()
			TextLabel:Destroy()
			-- Destroy hover text
		end)
	end

	local PlayingEmoteData = {}
	local function UpdateAnimInfo()
		local TextTable = {}

		for _, item in ipairs(PlayingEmoteData) do
			table.insert(TextTable, item.Name .. ": " .. tostring(item.Speed) .. ", " .. item.Priotity)
		end

		AnimInfo.Value = table.concat(TextTable, "\n")
		if AnimInfo.Value == "" then
			CurAnimInfoTitle.Visible = false
		else
			CurAnimInfoTitle.Visible = true
		end
	end
	local function AddEmoteInfo(EmoteName, SpeedValue, PriorityValue)
		for index, item in ipairs(PlayingEmoteData) do
			if item.Name == EmoteName then
				table.remove(PlayingEmoteData, index)
				break
			end
		end

		table.insert(PlayingEmoteData, 1, {Name = EmoteName, Speed = SpeedValue, Priotity = PriorityValue})
		UpdateAnimInfo()
	end
	local function RemoveEmoteInfo(EmoteName)
		for index, item in ipairs(PlayingEmoteData) do
			if item.Name == EmoteName then
				table.remove(PlayingEmoteData, index)
				break
			end
		end
		UpdateAnimInfo()
	end

	local function CreateAnimButton(Object, Name, Text, Type, LayoutPos)
		local Button = Object
		Button.Name = Name

		if Type == "R6" then
			if ScrollingFrame:FindFirstChild(Name) then 
				ScrollingFrame:FindFirstChild(Name):Destroy() 
				--print("Found copy of anim: "..Name)
			end
			Button.Parent = ScrollingFrame
		elseif Type == "R15" then
			if ScrollingFrameR15:FindFirstChild(Name) then 
				ScrollingFrameR15:FindFirstChild(Name):Destroy() 
				--print("Found copy of anim: "..Name)
			end
			Button.Parent = ScrollingFrameR15
		elseif Type == "Spec" then
			if ScrollingFrameSpecific:FindFirstChild(Name) then 
				ScrollingFrameSpecific:FindFirstChild(Name):Destroy() 
				--print("Found copy of anim: "..Name)
			end
			Button.Parent = ScrollingFrameSpecific
		end

		Button.BackgroundColor3 = ButtonCol
		Button.FontFace.Weight = Enum.FontWeight.Bold
		Button.Size = UDim2.new(0, 104, 0, 30)
		Button.TextColor3 = UiButColor
		Button.RichText = true
		Button.Font = Enum.Font.Roboto
		Button.Text = "<b>" .. Text .. "</b>"
		Button.TextScaled = true
		Button.LayoutOrder = LayoutPos

		local UIStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
		UIStroke.Parent = Button
		UIStroke.Thickness = 1
		UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		if UICornerEnabled then
			local UICorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
			UICorner.Parent = Button
			UICorner.CornerRadius = UDim.new(0, 3)
		end
		if UIGradientEnabled then
			local UIGradient = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient")
			UIGradient.Parent = Button
			UIGradient.Color = ColorSequence.new(Color3.fromRGB(207, 207, 207), Color3.fromRGB(255, 255, 255))
			UIGradient.Rotation = -90
		end

		local ButtonPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
		ButtonPadding.Parent = Button
		ButtonPadding.PaddingLeft = UDim.new(0, 2)
		ButtonPadding.PaddingRight = UDim.new(0, 2)
	end

	local function PlayAnim(Button, ID, FadeTime, Speed, Type, LoopedVal, NeedPause) -- Types Tutorial on Emotes section
		local Frame
		if Button.Parent.Name == "ScrollingFrame" then Frame = "R6"
		elseif Button.Parent.Name == "ScrollingFrameR15" then Frame = "R15"
		elseif Button.Parent.Name == "ScrollingFrameSpecific" then Frame = "Spec"
		end

		local AnimSpeed = nil
		local PauseAnimsOption = false
		local SwitchModeFactor = false
		local IsMoving = false
		local IsPlaying = false
		local IsRunning = false
		local IsIdle = false
		local AnimACTIVE = false

		Button:SetAttribute("Looped", LoopedVal)
		if LoopedVal == false then
			AddHoverText(Button, "Click RMB to loop")
		end

		if Type:find("Running") then
			IsRunning = true
		elseif Type:find("Idle") then
			IsIdle = true
		end

		local Humanoid = Player.Character:WaitForChild("Humanoid")
		local Anim = __SIEXTHER_VIP_GLASS_V1.Instance.new("Animation")
		Anim.Name = "AAnimation"
		Anim.AnimationId = "rbxassetid://"..ID
		local track = Humanoid:WaitForChild("Animator"):LoadAnimation(Anim)

		local AnimLoaded = true
		task.spawn(function()
			while wait() do
				if game:GetService("ContentProvider"):GetAssetFetchStatus(Anim.AnimationId) == Enum.AssetFetchStatus.Success then
					return
				elseif game:GetService("ContentProvider"):GetAssetFetchStatus(Anim.AnimationId) == Enum.AssetFetchStatus.Failure then
					AnimLoaded = false
					warn("Error with animation: ".. ID)
					Button.UIStroke.Thickness = 1
					Button.UIStroke.Color = Color3.fromRGB(70, 130, 255)
					AddHoverText(Button, "Couldn't load this animation by it's Id. Please type right Id and make sure this animation is working in this game")
					return
				end
			end
		end)

		local CurLooped = Button:GetAttribute("Looped")
		if CurLooped == false then
			track.Looped = false
		elseif CurLooped == true then
			track.Looped = true
		end

		if Type:find("PriorLow") then
			track.Priority = Enum.AnimationPriority.Action3
		elseif Type:find("PriorHigh") then
			track.Priority = Enum.AnimationPriority.Action4
		end		

		Button.Destroying:Connect(function()
			if GuiLoaded == false then
				track:Destroy()
				Anim:Destroy()
				Humanoid = nil
				track = nil
			end
		end)

		local function StartAnim()
			if DebugInfoEnabled then print(Button.Name.." - Id: "..string.match(track.Animation.AnimationId, "%d+")..", AnimLength: "..track.Length..", AnimSpeed: "..track.Speed..", AnimType: "..Type..", Looped: "..tostring(track.Looped)) end

			if RunAltPressed then
				if Type:find("Running") then
					IsRunning = false
				else
					IsRunning = true
				end
			else
				if Type:find("Running") then
					IsRunning = true
				end
			end
			if IdleAltPressed then
				if Type:find("Idle") then
					IsIdle = false
				else
					IsIdle = true
				end
			else
				if Type:find("Idle") then
					IsIdle = true
				end
			end

			if AnimSwitchModeEnabled == true then
				if not (((IsRunning and RunningTypeEnabled) or (IsIdle and IdleTypeEnabled)) and AnimSwitchModeRunIdleExceptionEnabled) then
					SwitchModeFactor = true
					StopAnimsEvent:Fire()
					AnimACTIVE = true
				end
			end

			local CurLooped = Button:GetAttribute("Looped")
			if CurLooped == false then
				track.Looped = false
			elseif CurLooped == true then
				track.Looped = true
			end

			local AnimWeight = 1
			if HigherPriorityEnabled then
				if Type:find("PriorHigh") then
					AnimWeight = 20000
				elseif Type:find("PriorLow") then
					track.Priority = Enum.AnimationPriority.Action4
					AnimWeight = 10000
				end
			end

			if PriorityAltPressed then
				if Type:find("PriorLow") then
					track.Priority = Enum.AnimationPriority.Action4
					if HigherPriorityEnabled then
						AnimWeight = 20000
					end
				elseif Type:find("PriorHigh") then
					track.Priority = Enum.AnimationPriority.Action3
					if HigherPriorityEnabled then
						track.Priority = Enum.AnimationPriority.Action4
						AnimWeight = 10000
					end
				end
			end

			AnimSpeed = Speed + SpeedNum
			ViewportFrame.Visible = false
			Button.BackgroundColor3 = ButtonSelectCol
			Button.UIStroke.Thickness = 1
			AddEmoteInfo(Button.Name, Speed + SpeedNum, track.Priority.Name)

			if IsRunning and RunningTypeEnabled then
				Button.UIStroke.Color = Color3.fromRGB(70, 130, 255)
			elseif IsIdle and IdleTypeEnabled then
				Button.UIStroke.Color = Color3.fromRGB(70, 130, 255)
			elseif Type:find("Pause") then
				Button.UIStroke.Color = Color3.fromRGB(70, 130, 255)
			else
				if track.Looped == true then
					Button.UIStroke.Color = Color3.fromRGB(70, 130, 255)
				else
					Button.UIStroke.Color = Color3.fromRGB(70, 130, 255)
				end
			end

			if IsRunning and RunningTypeEnabled and RunningTypeStopStandingEnabled and IsMoving == false then return end
			if IsIdle and IdleTypeEnabled and IsMoving == true then return end

			if AnimSmoothFadeEnabled == true then
				track:Play(FadeTime, AnimWeight, (Speed + SpeedNum) * NegativeNumber)
			else
				track:Play(0, AnimWeight, (Speed + SpeedNum) * NegativeNumber)
			end
			IsPlaying = true

			if PauseAnimsOption then
				track:AdjustSpeed(0)
			end

			if Type:find("Pause") then
				local NumberStr = string.match(Type, "Pause([%d%.]+)")
				local Number = tonumber(NumberStr) or 1
				local PauseTask = task.spawn(function()
					while wait() do
						if track.TimePosition >= Number then
							track:AdjustSpeed(0)
							track.TimePosition = Number
							if DebugInfoEnabled then print("Paused at "..track.TimePosition) end
							AnimSpeed = 0
							return
						end
					end
				end)
				while wait() do
					if AnimACTIVE == false then
						task.cancel(PauseTask)
						return
					end
				end
			end
		end
		local function StopAnim(Reason)
			if Type:find("PriorLow") then
				track.Priority = Enum.AnimationPriority.Action3
			elseif Type:find("PriorHigh") then
				track.Priority = Enum.AnimationPriority.Action4
			end	

			if not Type:find("Running") then
				IsRunning = false
			end
			if not Type:find("Idle") then
				IsIdle = false
			end

			if AnimSmoothFadeEnabled == false then
				track:Stop(0)
				track:Stop()
			else
				track:Stop(FadeTime)
			end
			IsPlaying = false

			if (Reason == "Destroy") then return end

			Button.BackgroundColor3 = ButtonCol
			Button.UIStroke.Thickness = 1
			Button.UIStroke.Color = Color3.fromRGB(70, 130, 255)
			RemoveEmoteInfo(Button.Name)
		end

		Button.MouseButton1Click:connect(function()
			if AnimLoaded == false then return end
			AnimACTIVE = not AnimACTIVE
			if AnimACTIVE then
				StartAnim()
			else
				StopAnim()
			end
		end)
		Button.MouseButton2Click:connect(function()
			if AnimLoaded == false then return end
			local CurLooped = Button:GetAttribute("Looped")
			if CurLooped == false then
				AnimACTIVE = not AnimACTIVE
				if AnimACTIVE then
					StartAnim()
					track.Looped = true
					Button.UIStroke.Color = Color3.fromRGB(70, 130, 255)
				else
					StopAnim()
				end
			end
		end)

		PauseAnimsButton.MouseButton1Click:Connect(function()
			PauseAnimsOption = not PauseAnimsOption
			if PauseAnimsOption then
				track:AdjustSpeed(0)
				PauseAnimsButton.BackgroundColor3 = ButtonSelectCol
				if DebugInfoEnabled and AnimACTIVE then print("Paused at:"..track.TimePosition) end
			else
				track:AdjustSpeed((Speed + SpeedNum) * NegativeNumber)
				PauseAnimsButton.BackgroundColor3 = ButtonCol
			end
		end)

		Button.Changed:connect(function()
			if GuiRestarted == true or GuiActive == false or not AnimLoaded then return end
			if __SIEXTHER_VIP_GLASS_V1.Read(Button, "BackgroundColor3") == ButtonCol and AnimACTIVE then
				AnimACTIVE = false
				StopAnim()
			elseif __SIEXTHER_VIP_GLASS_V1.Read(Button, "BackgroundColor3") == ButtonSelectCol and not AnimACTIVE then
				AnimACTIVE = true
				StartAnim()
			end
		end)

		track.Ended:connect(function()
			if (IsRunning and RunningTypeEnabled) or (IsIdle and IdleTypeEnabled) then return end
			AnimACTIVE = false
			Button.BackgroundColor3 = ButtonCol
			Button.UIStroke.Thickness = 1
			Button.UIStroke.Color = Color3.fromRGB(70, 130, 255)
			RemoveEmoteInfo(Button.Name)
		end)

		StopAnimsEvent.Event:Connect(function(Reason)
			if not (Reason == "Reset/Destroy" or Reason == "Forced") and AnimSwitchModeRunIdleExceptionEnabled and ((IsRunning and RunningTypeEnabled) or (IsIdle and IdleTypeEnabled)) then return end
			if AnimACTIVE == false or not AnimLoaded then return end

			if (Reason == "Reset/Destroy") and (LoadAnimationsOnRestart or LoadAllAnimationsOnRestart) then
				local Name = Button.Name
				if ((Type:find("Running") and RunningTypeEnabled) or (Type:find("Idle") and IdleTypeEnabled)) and LoadAnimationsOnRestart then
					if AnimACTIVE then
						table.insert(RestartAnimations, Frame..Name)
					end
				elseif LoadAllAnimationsOnRestart then
					if AnimACTIVE then
						table.insert(RestartAnimations, Frame..Name)
					end
				end

			end

			if SwitchModeFactor == true then 
				SwitchModeFactor = false	
				return 
			end
			if GuiActive == false or GuiRestarted == true then track:Destroy() end

			AnimACTIVE = false
			PauseAnimsOption = false
			if (Reason == "Reset/Destroy") then
				StopAnim("Destroy")
			else
				StopAnim()
			end
		end)

		local MinWalkSpeedNumStr = string.match(Type, "Running([%d%.]+)")
		local MinWalkSpeedNum = tonumber(MinWalkSpeedNumStr) or 0.5
		if tonumber(MinWalkSpeedNumStr) ~= nil then AddHoverText(Button, "Minimal WalkSpeed to play:"..MinWalkSpeedNum) end
		local RunningConnection
		local IdleConnection

		if RunningTypeMinSpeedEnabled == false then
			MinWalkSpeedNum = 0.5
		end
		RunningConnection = Humanoid.Running:Connect(function(currentSpeed)
			if not IsRunning then return end
			if GuiActive and GuiRestarted == false then
				if currentSpeed > 0.5 then
					IsMoving = true
				else
					IsMoving = false
				end
			else
				RunningConnection:Disconnect()
			end

			if AnimACTIVE and RunningTypeEnabled and GuiActive and GuiRestarted == false then
				if RunningTypeMinSpeedEnabled == false then
					MinWalkSpeedNum = 0.5
				end
				if currentSpeed > 0.5 and Humanoid.WalkSpeed >= MinWalkSpeedNum then

					local AnimWeight = 1
					if HigherPriorityEnabled then
						if Type:find("PriorHigh") then
							AnimWeight = 250
						elseif Type:find("PriorLow") then
							track.Priority = Enum.AnimationPriority.Action4
							AnimWeight = 100
						end
					end

					if not IsPlaying then
						if AnimSmoothFadeEnabled == true then
							track:Play(FadeTime, AnimWeight, (Speed + SpeedNum) * NegativeNumber)
						else
							track:Play(0, AnimWeight, (Speed + SpeedNum) * NegativeNumber)
						end
						IsPlaying = true
					end

					local characterRelativeSpeed = currentSpeed / DefaultWalkSpeed
					if RunningTypeStopStandingEnabled == false then
						characterRelativeSpeed = Humanoid.WalkSpeed / DefaultWalkSpeed
					end

					local finalAnimationSpeed = characterRelativeSpeed * (Speed + SpeedNum) * NegativeNumber
					if RunningTypeCharSpeedEnabled then
						track:AdjustSpeed(finalAnimationSpeed)
					end
				else
					if IsPlaying and RunningTypeStopStandingEnabled then
						if AnimSmoothFadeEnabled == false then
							track:Stop(0)
							track:Stop()
						else
							track:Stop()
						end
						IsPlaying = false
					end
				end
			elseif GuiActive and GuiRestarted == false then
				if IsPlaying and RunningTypeEnabled then
					if AnimSmoothFadeEnabled == false then
						track:Stop(0)
						track:Stop()
					else
						track:Stop()
					end
					IsPlaying = false
				end
			end
		end)

		IdleConnection = Humanoid.Running:Connect(function(currentSpeed)
			if not IsIdle then return end
			if GuiActive and GuiRestarted == false then
				if currentSpeed > 0.5 then
					IsMoving = true
				else
					IsMoving = false
				end
			else
				IdleConnection:Disconnect()
			end

			if AnimACTIVE and IdleTypeEnabled and GuiActive and GuiRestarted == false then
				if currentSpeed > 0.5 then
					if IsPlaying then
						track:Stop()
						IsPlaying = false
					end
				else
					if IsPlaying == false then
						local AnimWeight = 1
						if HigherPriorityEnabled then
							if Type:find("PriorHigh") then
								AnimWeight = 250
							elseif Type:find("PriorLow") then
								track.Priority = Enum.AnimationPriority.Action4
								AnimWeight = 100
							end
						end

						if not IsPlaying then
							if AnimSmoothFadeEnabled == true then
								track:Play(FadeTime, AnimWeight, (Speed + SpeedNum) * NegativeNumber)
							else
								track:Play(0, AnimWeight, (Speed + SpeedNum) * NegativeNumber)
							end
							IsPlaying = true
						end

						IsPlaying = true
					end
				end
			elseif GuiActive and GuiRestarted == false then
				if IsPlaying and IdleTypeEnabled then
					if AnimSmoothFadeEnabled == false then
						track:Stop(0)
						track:Stop()
					else
						track:Stop(FadeTime)
					end
					IsPlaying = false
				end
			end
		end)

		if not AnimLoaded then
			RunningConnection:Disconnect()
			IdleConnection:Disconnect()
		end

		Humanoid.Swimming:Connect(function()
			if IsPlaying and IdleTypeEnabled and IsIdle then
				track:Stop()
				IsPlaying = false
			end
			if IsPlaying and RunningTypeEnabled and IsRunning then
				track:Stop()
				IsPlaying = false
			end
		end)
		Humanoid.Jumping:Connect(function()
			if IsPlaying and IdleTypeEnabled and IsIdle then
				track:Stop()
				IsPlaying = false
			end
			if IsPlaying and RunningTypeEnabled and RunningTypeStopJumpingEnabled and IsRunning then
				track:Stop()
				IsPlaying = false
			end
		end)
		Humanoid.FreeFalling:Connect(function()
			if IsPlaying and IdleTypeEnabled and IsIdle then
				track:Stop()
				IsPlaying = false
			end
			if IsPlaying and RunningTypeEnabled and RunningTypeStopJumpingEnabled and IsRunning then
				track:Stop()
				IsPlaying = false
			end
		end)
		Humanoid.Climbing:Connect(function()
			if IsPlaying and IdleTypeEnabled and IsIdle then
				track:Stop()
				IsPlaying = false
			end
			if IsPlaying and RunningTypeEnabled and RunningTypeStopClimbingEnabled and IsRunning then
				track:Stop()
				IsPlaying = false
			end
		end)
		Humanoid.Seated:Connect(function()
			if IsPlaying and IdleTypeEnabled and IsIdle then
				track:Stop()
				IsPlaying = false
			end
		end)

		local VPFtrack = ClonedChar:WaitForChild("Humanoid"):LoadAnimation(Anim)
		local VPFActive = false
		local function ShowHoldPreview()
			if not AnimLoaded then return end
			ViewportFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
			ViewportFrame.BackgroundTransparency = 0
			if AnimPreviewEnabled and not AnimACTIVE then
				if Type:find("Running") and RunningTypeEnabled then
					ViewportFrame.UIStroke.Color = Color3.fromRGB(70, 130, 255)
				elseif Type:find("Idle") and IdleTypeEnabled then
					ViewportFrame.UIStroke.Color = Color3.fromRGB(70, 130, 255)
				elseif Type:find("Pause") then
					ViewportFrame.UIStroke.Color = Color3.fromRGB(70, 130, 255)
				else
					if track.Looped == true then
						ViewportFrame.UIStroke.Color = Color3.fromRGB(70, 130, 255)
					else
						ViewportFrame.UIStroke.Color = Color3.fromRGB(70, 130, 255)
					end
				end

				VPFActive = true
				VPFtrack.Looped = true
				VPFtrack:Play(0, 1, (Speed + SpeedNum) * NegativeNumber)
				ViewportFrame.Visible = true
				game.TweenService:Create(ViewportFrame, TweenInfo.new(.1), {BackgroundTransparency = 0}):Play()

				if Type:find("Pause") then
					local NumberStr = string.match(Type, "Pause([%d%.]+)")
					local Number = tonumber(NumberStr) or 1

					local PauseTask = task.spawn(function()
						wait(Number)
						VPFtrack:AdjustSpeed(0)
					end)
					while wait() do
						if VPFActive == false then
							task.cancel(PauseTask)
							return
						end
					end
				end
			end
		end

		local function HideHoldPreview()
			if AnimPreviewEnabled then
				VPFActive = false
				game.TweenService:Create(ViewportFrame, TweenInfo.new(.1), {BackgroundTransparency = 1}):Play()
				ViewportFrame.Visible = false
				VPFtrack:Stop()
			end
		end

		-- Desktop hover preview + mobile/desktop press-and-hold preview.
		Button.MouseEnter:Connect(ShowHoldPreview)
		Button.MouseLeave:Connect(HideHoldPreview)
		Button.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1 then
				ShowHoldPreview()
			end
		end)
		Button.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1 then
				HideHoldPreview()
			end
		end)

		for index, RestartedAnim in ipairs(RestartAnimations) do
			local prefix, suffix
			if string.match(RestartedAnim, "^R15") then
				prefix, suffix = string.match(RestartedAnim, "^(R15)(.+)$")
			elseif string.match(RestartedAnim, "^Spec") then
				prefix, suffix = string.match(RestartedAnim, "^(Spec)(.+)$")
			elseif string.match(RestartedAnim, "^R6") then
				prefix, suffix = string.match(RestartedAnim, "^(R6)(.+)$")
			end

			if prefix == Frame and suffix == Button.Name then
				task.spawn(function()
					while true do
						if GuiLoaded then
							break
						end
						wait()
					end
					Button:WaitForChild("UIStroke")
					if Button ~= nil and AnimLoaded then
						AnimACTIVE = true
						StartAnim()
					end
				end)
			end
		end
	end

	local function AddSettings(Setting, Title, Text, LayoutOrder)
		local OptionButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		OptionButton.Name = Title
		OptionButton.Size = UDim2.new(1, 0, 0, 25)
		OptionButton.BackgroundTransparency = 1
		OptionButton.LayoutOrder = LayoutOrder
		OptionButton.Position = UDim2.new(0, 0, 0.1558714, 0)
		OptionButton.TextTransparency = 1
		OptionButton.Parent = SettingsStuff

		local CheckImage = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageLabel")
		CheckImage.Name = "CheckImage"
		CheckImage.AnchorPoint = Vector2.new(0, 0.5)
		CheckImage.Size = UDim2.new(0, 15, 0, 15)
		CheckImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
		CheckImage.Position = UDim2.new(0, 0, 0.5, 0)
		CheckImage.BorderSizePixel = 1
		CheckImage.BackgroundColor3 = TextBgColor
		CheckImage.Image = "rbxassetid://130396712201457"
		CheckImage.ImageColor3 = UiButColor
		CheckImage.Parent = OptionButton
		if Setting == true then
			CheckImage.Image = "rbxassetid://130396712201457"
		else
			CheckImage.Image = ""
		end

		local UIStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
		UIStroke.Parent = CheckImage

		local UIListLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
		UIListLayout.FillDirection = Enum.FillDirection.Horizontal
		UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.Padding = UDim.new(0, 5)
		UIListLayout.Parent = OptionButton

		local TextLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
		TextLabel.Size = UDim2.new(0.9500334, -10, 0, 25)
		TextLabel.BackgroundTransparency = 1
		TextLabel.Position = UDim2.new(0.115608, 0, 0, 0)
		TextLabel.TextColor3 = UiButColor
		TextLabel.TextSize = 14
		TextLabel.Text = Text
		TextLabel.Font = Enum.Font.SourceSans
		TextLabel.TextXAlignment = Enum.TextXAlignment.Left
		TextLabel.Parent = OptionButton

		local UIPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
		UIPadding.PaddingBottom = UDim.new(0, 2)
		UIPadding.Parent = TextLabel
	end

	local function AddHotkey(Hotkey, FrameName, Text, Function)
		local IsDoubleKey = false
		local Key = Hotkey.Value:gsub("Double", "")

		if Hotkey.Value:find("Double") then 
			IsDoubleKey = true 
		end

		local function FunctionHotkey(ActionName, InputState, InputObject)
			if InputState.Name ~= "Begin" then return end
			if Hotkey.Value:find("Double") then
				if not UserInputService:IsKeyDown(Enum.KeyCode[DoubleHotkey.Value]) then return Enum.ContextActionResult.Pass end
			end	

			Function()

			if Hotkey.Value:find("Double") then
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end
		local function BindHotkey()
			if FrameName == "DoubleHotkey" then return end
			ContextActionService:UnbindAction("Emoter"..FrameName)
			ContextActionService:BindAction("Emoter"..FrameName, FunctionHotkey, false, Enum.KeyCode[Key])
		end

		if GuiActive == false or GuiRestarted or not HotkeysEnabled then
			ContextActionService:UnbindAction("Emoter"..FrameName)
			return
		end
		BindHotkey()

		if HotkeysStuff:FindFirstChild(FrameName) then return end

		local HotkeyFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
		local HotkeyText = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
		local RebindButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		local DoubleButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")

		HotkeyFrame.Name = FrameName
		HotkeyFrame.Size = UDim2.new(1, 0, 0, 25)
		HotkeyFrame.BackgroundTransparency = 1
		HotkeyFrame.Parent = HotkeysStuff

		HotkeyText.Size = UDim2.new(0, 135, 0, 25)
		HotkeyText.BackgroundTransparency = 1
		HotkeyText.TextColor3 = UiButColor
		HotkeyText.TextSize = 14
		HotkeyText.Text = Text
		HotkeyText.TextWrapped = true
		HotkeyText.Font = Enum.Font.SourceSans
		HotkeyText.TextXAlignment = Enum.TextXAlignment.Left
		HotkeyText.Parent = HotkeyFrame
		local UIPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
		UIPadding.PaddingBottom = UDim.new(0, 2)
		UIPadding.Parent = HotkeyText

		RebindButton.AnchorPoint = Vector2.new(1, 0.5)
		RebindButton.Size = UDim2.new(0, 43, 0, 21)
		RebindButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		RebindButton.Position = UDim2.new(1, 0, 0.5, 0)
		RebindButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		RebindButton.TextColor3 = Color3.new(0, 0, 0)
		RebindButton.TextSize = 14
		RebindButton.Text = Key or "..."
		RebindButton.Font = Enum.Font.SourceSans
		RebindButton.Parent = HotkeyFrame

		DoubleButton.Parent = HotkeyFrame
		DoubleButton.Name = "DoubleButton"
		DoubleButton.AnchorPoint = Vector2.new(1, 0.5)
		DoubleButton.Size = UDim2.new(0, 15, 0, 15)
		DoubleButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		DoubleButton.Position = UDim2.new(1, -48, 0.5, 0)
		DoubleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		DoubleButton.TextSize = 22
		DoubleButton.TextColor3 = Color3.fromRGB(129, 129, 129)
		DoubleButton.Text = "+"
		DoubleButton.TextWrapped = true
		DoubleButton.Font = Enum.Font.SourceSansBold
		if IsDoubleKey then
			DoubleButton.BorderSizePixel = 2
			DoubleButton.BorderColor3 = Color3.fromRGB(0, 174, 255)
			DoubleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		end
		AddHoverText(DoubleButton, "Activate Double Hotkey")

		if FrameName == "DoubleHotkey" then
			RebindButton.Size = UDim2.new(0, 65, 0, 21)
			DoubleButton:Destroy() 
		elseif FrameName == "EmoteWheelHotkey" then
			local SeparateFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
			SeparateFrame.Size = UDim2.new(1, 0, 0, 10)
			SeparateFrame.BackgroundTransparency = 1
			SeparateFrame.Parent = HotkeysStuff
		end

		local isListening = false
		RebindButton.MouseButton1Click:Connect(function()
			if isListening then return end

			isListening = true
			RebindButton.Text = "..."
		end)

		DoubleButton.MouseButton1Click:Connect(function()
			if isListening then return end
			IsDoubleKey = not IsDoubleKey
			if Key ~= "" then
				if IsDoubleKey then
					DoubleButton.BorderColor3 = Color3.fromRGB(0, 174, 255)
					DoubleButton.BorderSizePixel = 2
					DoubleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
					Hotkey.Value = "Double"..Key
					BindHotkey()
				else
					DoubleButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
					DoubleButton.BorderSizePixel = 1
					DoubleButton.TextColor3 = Color3.fromRGB(129, 129, 129)
					Hotkey.Value = Key
					BindHotkey()
				end
			end
			if DebugInfoEnabled then print(Hotkey.Value) end
		end)

		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed or not GuiActive or GuiRestarted then return end 

			if isListening then
				if input.UserInputType == Enum.UserInputType.Keyboard then
					if input.KeyCode.Name == "Backspace" or input.KeyCode.Name == "Enter" then
						Hotkey.Value = ""
						Key = ""
						isListening = false
						RebindButton.Text = ""
						DoubleButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
						DoubleButton.BorderSizePixel = 1
						DoubleButton.TextColor3 = Color3.fromRGB(129, 129, 129)
						ContextActionService:UnbindAction("Emoter"..FrameName)
						if DebugInfoEnabled then print("Unbinded") end
						return
					end
					Key = tostring(input.KeyCode.Name)
					if IsDoubleKey then
						Hotkey.Value = "Double"..tostring(input.KeyCode.Name)
					else
						Hotkey.Value = tostring(input.KeyCode.Name)
					end
					isListening = false
					RebindButton.Text = Key
					BindHotkey()
					if DebugInfoEnabled then print(Hotkey.Value) end
				end
				return
			end
		end)
	end

	local function CreateDivideFrame(Title, LayoutOrder, Type)
		local HasButton = false
		if Type == "Spec" then
			for _, v in pairs(ScrollingFrameSpecific:GetChildren()) do
				if v:IsA("TextButton") then
					if v.LayoutOrder == LayoutOrder + 1 then
						HasButton = true
						break
					end
				end		
			end
		else
			HasButton = true
		end
		if HasButton == false then return end

		local DivideFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
		local Line = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
		local TextLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")

		DivideFrame.Name = "DivideFrame"
		DivideFrame.Size = UDim2.new(0.98, 0, 0, 18)
		DivideFrame.BackgroundTransparency = 1
		DivideFrame.LayoutOrder = LayoutOrder

		Line.Name = "Line"
		Line.AnchorPoint = Vector2.new(0, 0.5)
		Line.Size = UDim2.new(1, 0, 0, 3)
		Line.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Line.Position = UDim2.new(0, 0, 0.5, 0)
		Line.BorderSizePixel = 0
		Line.BackgroundColor3 = UiButColor
		Line.Parent = DivideFrame

		TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		TextLabel.AutomaticSize = Enum.AutomaticSize.X
		TextLabel.Size = UDim2.new(0, 0, 0, 25)
		TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
		TextLabel.BorderSizePixel = 0
		TextLabel.BackgroundColor3 = ScrollBgColor
		TextLabel.TextSize = 25
		TextLabel.TextColor3 = UiButColor
		TextLabel.Text = Title
		TextLabel.Font = Enum.Font.SourceSansBold
		TextLabel.Parent = DivideFrame

		local UIPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
		UIPadding.PaddingLeft = UDim.new(0, 8)
		UIPadding.PaddingRight = UDim.new(0, 10)
		UIPadding.Parent = TextLabel

		if Type == "Settings" then
			DivideFrame.Size = UDim2.new(0.98, 0, 0, 15)
			Line.Size = UDim2.new(1, 0, 0, 2)
			TextLabel.Size = UDim2.new(0, 50, 0, 20)
			TextLabel.TextSize = 17
		end

		if Type == "R6" then
			DivideFrame.Parent = ScrollingFrame
		elseif Type == "R15" then
			DivideFrame.Parent = ScrollingFrameR15
		elseif Type == "Spec" then
			DivideFrame.Parent = ScrollingFrameSpecific
		elseif Type == "Settings" then
			DivideFrame.Parent = SettingsStuff
		end
	end

	local function DraggingFunction(Trigger, Frame) --System originally made by Real_IceyDev (@lceyDex) and modernized by me
		local DragToggle = nil
		local DragStart = nil
		local StartPos = nil

		local function updateInput(Input)
			local Delta = Input - DragStart
			local position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
			game:GetService('TweenService'):Create(Frame, TweenInfo.new(DragDelay), {Position = position}):Play()
		end
		Trigger.DragStart:Connect(function(input)
			DragToggle = true
			DragStart = input
			StartPos = Frame.Position
		end)
		Trigger.DragEnd:Connect(function()
			DragToggle = false
		end)
		Trigger.DragContinue:Connect(function(input)
			if DragToggle then
				updateInput(input)
			end
		end)
	end

	-- Creating Objects
	Emoter.Name = "Emoter"
	Emoter.ResetOnSpawn = false
	Emoter.IgnoreGuiInset = true
	Emoter.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	if IsInStudio then --Made this as i test script mostly in Studio
		Emoter.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
		Emoter.DisplayOrder = 100
	else
		-- CoreGui is blocked by some executors. Prefer gethui(), then CoreGui,
		-- and finally PlayerGui so the GUI still has somewhere valid to render.
		local guiParent
		if type(gethui) == "function" then
			local ok, result = pcall(gethui)
			if ok and result then guiParent = result end
		end
		if not guiParent then
			local ok, result = pcall(function() return game:GetService("CoreGui") end)
			if ok and result then guiParent = result end
		end
		if not guiParent then
			guiParent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
		end
		Emoter.Parent = guiParent
		if TopMost == true then
			Emoter.DisplayOrder = 100
		else
			Emoter.DisplayOrder = -1
		end
	end
	if not IsInStudio then
		Emoter.Enabled = false
	end

	-- SideFrame
	SideFrame.Name = "SideFrame"
	SideFrame.Parent = Emoter
	SideFrame.Active = true
	SideFrame.BackgroundColor3 = BgColor
	SideFrame.Size = UDim2.new(0, 215, 0, 28)
	SideFrame.Visible = false
	SideFrame.Position = UDim2.new(0, 10, 0, 10)

	local UIDragDetectorSideFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIDragDetector")
	UIDragDetectorSideFrame.Parent = SideFrame
	UIDragDetectorSideFrame.DragStyle = Enum.UIDragDetectorDragStyle.Scriptable
	UIDragDetectorSideFrame.ResponseStyle = Enum.UIDragDetectorResponseStyle.CustomOffset
	DraggingFunction(UIDragDetectorSideFrame, SideFrame)

	SideFrameTitle.Name = "SideFrameTitle"
	SideFrameTitle.Parent = SideFrame
	SideFrameTitle.AnchorPoint = Vector2.new(0.5, 0.5)
	SideFrameTitle.BackgroundTransparency = 1
	SideFrameTitle.Position = UDim2.new(0.5, 0, 0.5, 0)
	SideFrameTitle.Size = UDim2.new(0, 0, 0, 28)
	SideFrameTitle.Font = Enum.Font.SourceSansBold
	SideFrameTitle.TextColor3 = Color3.new(1, 1, 1)
	SideFrameTitle.Text = "Emote GUI"
	SideFrameTitle.TextSize = 22
	SideFrameTitle.TextStrokeTransparency = 0

	SFDestroyGUI.Name = "SFDestroyGUI"
	SFDestroyGUI.Parent = SideFrame
	SFDestroyGUI.AnchorPoint = Vector2.new(1, 0.5)
	SFDestroyGUI.BorderSizePixel = 0
	SFDestroyGUI.Position = UDim2.new(1, 0, 0.5, 0)
	SFDestroyGUI.Size = UDim2.new(0, 28, 0, 28)
	SFDestroyGUI.BackgroundColor3 = BgColor
	SFDestroyGUI.Font = Enum.Font.FredokaOne
	SFDestroyGUI.Text = "X"
	SFDestroyGUI.TextColor3 = UiButColor
	SFDestroyGUI.TextSize = 34
	SFDestroyGUI.TextScaled = true
	AddHoverText(SFDestroyGUI, "Delete GUI")

	OpenGUI.Name = "OpenGUI"
	OpenGUI.Parent = SideFrame
	OpenGUI.AnchorPoint = Vector2.new(0, 0.5)
	OpenGUI.BorderSizePixel = 0
	OpenGUI.BackgroundColor3 = BgColor
	OpenGUI.Position = UDim2.new(0, 0, 0.5, 0)
	OpenGUI.Size = UDim2.new(0, 28, 0, 28)
	OpenGUI.Image = "rbxassetid://101249930107274"
	OpenGUI.ImageColor3 = UiButColor
	AddHoverText(OpenGUI, "Open/Close GUI", CloseHotkey)


	-- MainFrame
	MainFrame.Name = "MainFrame"
	MainFrame.Parent = Emoter
	MainFrame.Visible = false
	MainFrame.BackgroundTransparency = 1
	MainFrame.Active = true
	MainFrame.BackgroundColor3 = BgColor
	MainFrame.BackgroundTransparency = 1
	MainFrame.Size = UDim2.new(0, XSize, 0, YSize)
	MainFrame.Position = UDim2.new(0, 10, 0, 70)

	-- GuiTopFrame
	GuiTopFrame.Name = "GuiTopFrame"
	GuiTopFrame.Parent = MainFrame
	GuiTopFrame.BackgroundColor3 = BgColor
	GuiTopFrame.BorderColor3 = Color3.new(0.243137, 0.243137, 0.243137)
	GuiTopFrame.Size = UDim2.new(1, 0, 0, 32)

	DestroyGUI.Name = "DestroyGUI"
	DestroyGUI.Parent = GuiTopFrame
	DestroyGUI.AnchorPoint = Vector2.new(1, 0.5)
	DestroyGUI.BorderSizePixel = 0
	DestroyGUI.BackgroundColor3 = BgColor
	DestroyGUI.Position = UDim2.new(1, 0, 0.5, 0)
	DestroyGUI.Size = UDim2.new(0, 32, 0, 32)
	DestroyGUI.Font = Enum.Font.FredokaOne
	DestroyGUI.Text = "X"
	DestroyGUI.TextColor3 = UiButColor
	DestroyGUI.TextSize = 34
	DestroyGUI.TextWrapped = true
	AddHoverText(DestroyGUI, "Delete GUI")

	CloseGUI.Name = "CloseGUI"
	CloseGUI.Parent = GuiTopFrame
	CloseGUI.AnchorPoint = Vector2.new(0, 0.5)
	CloseGUI.BackgroundColor3 = BgColor
	CloseGUI.BorderSizePixel = 0
	CloseGUI.Position = UDim2.new(0, 0, 0.5, 0)
	CloseGUI.Size = UDim2.new(0, 32, 0, 32)
	CloseGUI.Image = "rbxassetid://105612912027138"
	CloseGUI.ImageColor3 = UiButColor
	AddHoverText(CloseGUI, "Open/Close GUI", CloseHotkey)

	local SettingsButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")
	SettingsButton.Parent = GuiTopFrame
	SettingsButton.Name = "SettingsButton"
	SettingsButton.BorderSizePixel = 0
	SettingsButton.AnchorPoint = Vector2.new(1, 0.5)
	SettingsButton.Size = UDim2.new(0, 32, 0, 32)
	SettingsButton.Position = UDim2.new(1, -32, 0.5, 0)
	SettingsButton.BackgroundColor3 = BgColor
	SettingsButton.ImageColor3 = UiButColor
	SettingsButton.Image = "rbxassetid://129555881355020"
	AddHoverText(SettingsButton, "Settings", SettingsHotkey)

	Title.Name = "Title"
	Title.Parent = GuiTopFrame
	Title.AnchorPoint = Vector2.new(0.5, 0.5)
	Title.Position = UDim2.new(0.5, 0, 0.5, 0)
	Title.BackgroundColor3 = Color3.new(1, 1, 1)
	Title.BackgroundTransparency = 1
	Title.Size = UDim2.new(0, 0, 0, 31)
	Title.Text = "Emoter GUI"
	Title.Font = Enum.Font.SourceSansBold
	Title.TextColor3 = Color3.new(1, 1, 1)
	Title.TextSize = 24
	Title.TextStrokeTransparency = 0
	Title.TextWrapped = false

	local UIDragDetectorGuiTopFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIDragDetector")
	UIDragDetectorGuiTopFrame.Parent = GuiTopFrame
	UIDragDetectorGuiTopFrame.DragStyle = Enum.UIDragDetectorDragStyle.Scriptable
	UIDragDetectorGuiTopFrame.ResponseStyle = Enum.UIDragDetectorResponseStyle.CustomOffset
	DraggingFunction(UIDragDetectorGuiTopFrame, MainFrame)

	-- GuiBottomFrame
	GuiBottomFrame.Name = "GuiBottomFrame"
	GuiBottomFrame.Parent = MainFrame
	GuiBottomFrame.AnchorPoint = Vector2.new(0, 1)
	GuiBottomFrame.Size = UDim2.new(1, 0, 0, 35)
	GuiBottomFrame.Position = UDim2.new(0, 0, 1, 1)
	GuiBottomFrame.Active = true
	GuiBottomFrame.BackgroundColor3 = BgColor

	SpeedFrame.Name = "SpeedFrame"
	SpeedFrame.Parent = GuiBottomFrame
	SpeedFrame.Size = UDim2.new(0.5, 0, 0, 35)
	SpeedFrame.BackgroundTransparency = 1
	SpeedFrame.Active = true

	local SFLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGridLayout")
	SFLayout.Name = "UIGridLayout"
	SFLayout.Parent = SpeedFrame
	SFLayout.FillDirection = Enum.FillDirection.Vertical
	SFLayout.SortOrder = Enum.SortOrder.LayoutOrder
	SFLayout.CellSize = UDim2.new(0, 90, 0, 28)
	SFLayout.VerticalAlignment = Enum.VerticalAlignment.Center

	OptionsButton.Parent = GuiBottomFrame
	OptionsButton.Name = "OptionsButton"
	OptionsButton.AnchorPoint = Vector2.new(0.5, 0.5)
	OptionsButton.Size = UDim2.new(0, 35, 0, 35)
	OptionsButton.Position = UDim2.new(0.5, 0, 0.5, 0)
	OptionsButton.BorderSizePixel = 0
	OptionsButton.BackgroundColor3 = BgColor
	OptionsButton.ImageColor3 = UiButColor
	OptionsButton.Image = "rbxassetid://80468028389803"
	AddHoverText(OptionsButton, "Options")

	local SpeedValue = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextBox")
	SpeedValue.Parent = SpeedFrame
	SpeedValue.Name = "SpeedValue"
	SpeedValue.ClearTextOnFocus = false
	SpeedValue.AnchorPoint = Vector2.new(0.5, 0)
	SpeedValue.Size = UDim2.new(0, 100, 0, 40)
	SpeedValue.LayoutOrder = 2
	SpeedValue.Position = UDim2.new(0.5, 0, 0, 0)
	SpeedValue.BackgroundColor3 = TextBgColor
	SpeedValue.TextColor3 = UiButColor
	SpeedValue.Text = ""
	SpeedValue.PlaceholderText = "0 = Default"
	SpeedValue.Font = Enum.Font.SourceSans
	SpeedValue.TextScaled = true
	AddHoverText(SpeedValue, "Enter a number to add speed")

	local ValueText = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
	ValueText.Name = "ValueText"
	ValueText.Parent = SpeedFrame
	ValueText.Size = UDim2.new(0, 200, 0, 50)
	ValueText.BackgroundTransparency = 1
	ValueText.TextStrokeTransparency = 0
	ValueText.TextColor3 = Color3.fromRGB(255, 255, 255)
	ValueText.Text = "Add Speed"
	ValueText.Font = Enum.Font.SourceSansBold
	ValueText.TextScaled = true

	CurAnimInfoTitle.Name = "CurAnimInfoTitle"
	CurAnimInfoTitle.AnchorPoint = Vector2.new(1, 0)
	CurAnimInfoTitle.Size = UDim2.new(0, 0, 0, 35)
	CurAnimInfoTitle.AutomaticSize = Enum.AutomaticSize.X
	CurAnimInfoTitle.BackgroundTransparency = 1
	CurAnimInfoTitle.Position = UDim2.new(1, 0, 0, 0)
	CurAnimInfoTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	CurAnimInfoTitle.Text = "[info]"
	CurAnimInfoTitle.TextXAlignment = Enum.TextXAlignment.Right
	CurAnimInfoTitle.TextWrapped = true
	CurAnimInfoTitle.Font = Enum.Font.SourceSansBold
	CurAnimInfoTitle.TextScaled = true
	CurAnimInfoTitle.TextStrokeTransparency = 0
	CurAnimInfoTitle.Visible = false
	CurAnimInfoTitle.Parent = GuiBottomFrame
	AddHoverText(CurAnimInfoTitle, AnimInfo)


	--Scrolling Frames
	ScrollingFrame.Parent = MainFrame
	ScrollingFrame.BackgroundColor3 = ScrollBgColor
	ScrollingFrame.Position = UDim2.new(0, 0, 0, 34)
	ScrollingFrame.ScrollBarImageColor3 = UiButColor
	ScrollingFrame.Size = UDim2.new(1, 0, 1, -69)
	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0.5, 10)
	ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ScrollingFrame.ScrollBarThickness = 10

	local SF6UIListLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
	SF6UIListLayout.Parent = ScrollingFrame
	SF6UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	SF6UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	SF6UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	SF6UIListLayout.Wraps = true
	SF6UIListLayout.Padding = UDim.new(0, 5)

	ScrollingFrameR15.Name = "ScrollingFrameR15"
	ScrollingFrameR15.Parent = MainFrame
	ScrollingFrameR15.BackgroundColor3 = ScrollBgColor
	ScrollingFrameR15.Position = UDim2.new(0, 0, 0, 34)
	ScrollingFrameR15.ScrollBarImageColor3 = UiButColor
	ScrollingFrameR15.Size = UDim2.new(1, 0, 1, -69)
	ScrollingFrameR15.CanvasSize = UDim2.new(0, 0, 0.5, 10)
	ScrollingFrameR15.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ScrollingFrameR15.Visible = false
	ScrollingFrameR15.ScrollBarThickness = 10

	local SF15UIListLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
	SF15UIListLayout.Parent = ScrollingFrameR15
	SF15UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	SF15UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	SF15UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	SF15UIListLayout.Wraps = true
	SF15UIListLayout.Padding = UDim.new(0, 7)

	ScrollingFrameSpecific.Name = "ScrollingFrameSpecific"
	ScrollingFrameSpecific.Parent = MainFrame
	ScrollingFrameSpecific.BackgroundColor3 = ScrollBgColor
	ScrollingFrameSpecific.Position = UDim2.new(0, 0, 0, 34)
	ScrollingFrameSpecific.ScrollBarImageColor3 = UiButColor
	ScrollingFrameSpecific.Size = UDim2.new(1, 0, 1, -69)
	ScrollingFrameSpecific.CanvasSize = UDim2.new(0, 0, 0.5, 10)
	ScrollingFrameSpecific.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ScrollingFrameSpecific.Visible = false
	ScrollingFrameSpecific.ScrollBarThickness = 10

	local SFSpecListLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
	SFSpecListLayout.Parent = ScrollingFrameSpecific
	SFSpecListLayout.FillDirection = Enum.FillDirection.Horizontal
	SFSpecListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	SFSpecListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	SFSpecListLayout.Wraps = true
	SFSpecListLayout.Padding = UDim.new(0, 7)


	--Options Frame
	OptionsFrame.Parent = MainFrame
	OptionsFrame.Name = "OptionsFrame"
	OptionsFrame.AnchorPoint = Vector2.new(0.5, 0)
	OptionsFrame.Size = UDim2.new(0, 266, 0, 46)
	OptionsFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	OptionsFrame.Visible = false
	OptionsFrame.Position = UDim2.new(0.5, 0, 1, -43)
	OptionsFrame.BorderSizePixel = 0
	OptionsFrame.BackgroundColor3 = ScrollBgColor
	OptionsFrame.ZIndex = -1

	local OFUIGridLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGridLayout")
	OFUIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	OFUIGridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	OFUIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	OFUIGridLayout.CellSize = UDim2.new(0, 40, 0, 40)
	OFUIGridLayout.CellPadding = UDim2.new(0, 4, 0, 4)
	OFUIGridLayout.Parent = OptionsFrame

	PauseAnimsButton.Name = "PauseAnimsButton"
	PauseAnimsButton.Size = UDim2.new(0, 100, 0, 100)
	PauseAnimsButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	PauseAnimsButton.BorderSizePixel = 0
	PauseAnimsButton.BackgroundColor3 = ButtonCol
	PauseAnimsButton.Image = "rbxassetid://103681828169035"
	PauseAnimsButton.Parent = OptionsFrame
	PauseAnimsButton.ZIndex = 0
	AddHoverText(PauseAnimsButton, "Pause ALL Anims")

	StopDefAnimsButton.Name = "StopDefAnimsButton"
	StopDefAnimsButton.Size = UDim2.new(0, 100, 0, 100)
	StopDefAnimsButton.BorderSizePixel = 0
	StopDefAnimsButton.BackgroundColor3 = ButtonCol
	StopDefAnimsButton.Image = "rbxassetid://116957047917442"
	StopDefAnimsButton.Parent = OptionsFrame
	StopDefAnimsButton.ZIndex = 0
	if not Player.Character:FindFirstChild(AnimationHandler) then
		StopDefAnimsButton.ImageTransparency = 0.5
		StopDefAnimsButton.Interactable = false
		AddHoverText(StopDefAnimsButton, "This feature isn't supported on this game. Check Wiki for more info")
	else
		AddHoverText(StopDefAnimsButton, "Stop Default Anims. May not work on some games")
	end

	PauseAnimateButton.Name = "PauseAnimateButton"
	PauseAnimateButton.Size = UDim2.new(0, 100, 0, 100)
	PauseAnimateButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	PauseAnimateButton.BorderSizePixel = 0
	PauseAnimateButton.BackgroundColor3 = ButtonCol
	PauseAnimateButton.Image = "rbxassetid://109849420482663"
	PauseAnimateButton.Parent = OptionsFrame
	PauseAnimateButton.ZIndex = 0
	if not Player.Character:FindFirstChild(AnimationHandler) then
		PauseAnimateButton.ImageTransparency = 0.5
		PauseAnimateButton.Interactable = false
		AddHoverText(PauseAnimateButton, "This feature isn't supported on this game. Check Wiki for more info")
	else
		AddHoverText(PauseAnimateButton, "Pause Default Animate Script (will look like you're lagging)")
	end

	ReversePlayButton.Parent = OptionsFrame
	ReversePlayButton.Name = "ReversePlayButton"
	ReversePlayButton.ZIndex = 0
	ReversePlayButton.Size = UDim2.new(0, 100, 0, 100)
	ReversePlayButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ReversePlayButton.BorderSizePixel = 0
	ReversePlayButton.BackgroundColor3 = ButtonCol
	ReversePlayButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
	ReversePlayButton.Image = "rbxassetid://131026391298968"
	AddHoverText(ReversePlayButton, "Reverse Animation")

	SitButton.Name = "SitButton"
	SitButton.Size = UDim2.new(0, 100, 0, 100)
	SitButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SitButton.BorderSizePixel = 0
	SitButton.BackgroundColor3 = ButtonCol
	SitButton.Image = "rbxassetid://94572819761865"
	SitButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
	SitButton.Parent = OptionsFrame
	SitButton.ZIndex = 0
	AddHoverText(SitButton, "Ragdoll-like falling with sit animation", SitHotkey)

	EmoteWheelButton.Parent = OptionsFrame
	EmoteWheelButton.Name = "EmoteWheelButton"
	EmoteWheelButton.ZIndex = 0
	EmoteWheelButton.Size = UDim2.new(0, 100, 0, 100)
	EmoteWheelButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	EmoteWheelButton.BorderSizePixel = 0
	EmoteWheelButton.BackgroundColor3 = ButtonCol
	EmoteWheelButton.ImageColor3 = UiButColor
	EmoteWheelButton.Image = "rbxassetid://104869367027493"
	EmoteWheelButton.ScaleType = Enum.ScaleType.Crop
	AddHoverText(EmoteWheelButton, "Show Emote wheel", EmoteWheelHotkey)


	--Search Box
	SearchFrame.Parent = MainFrame
	SearchFrame.Name = "SearchFrame"
	SearchFrame.ZIndex = 0
	SearchFrame.AnchorPoint = Vector2.new(1, 0)
	SearchFrame.Size = UDim2.new(0, 164, 0, 35)
	SearchFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SearchFrame.Position = UDim2.new(1, 31, 0, 34)
	SearchFrame.BorderSizePixel = 0
	SearchFrame.BackgroundColor3 = BgColor

	SearchButton.Name = "SearchButton"
	SearchButton.ZIndex = 0
	SearchButton.AnchorPoint = Vector2.new(1, 0)
	SearchButton.Size = UDim2.new(0, 30, 1, 0)
	SearchButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SearchButton.LayoutOrder = 2
	SearchButton.Position = UDim2.new(1, 0, 0.075, 0)
	SearchButton.BorderSizePixel = 0
	SearchButton.BackgroundColor3 = BgColor
	SearchButton.ScaleType = Enum.ScaleType.Fit
	SearchButton.Image = "rbxassetid://118685771787843"
	SearchButton.ImageColor3 = UiButColor
	SearchButton.Parent = SearchFrame
	AddHoverText(SearchButton, "Search", SearchHotkey)

	SearchBox.Name = "SearchBox"
	SearchBox.ZIndex = 0
	SearchBox.Visible = false
	SearchBox.AnchorPoint = Vector2.new(0.5, 0)
	SearchBox.Size = UDim2.new(0, 139, 0, 29)
	SearchBox.LayoutOrder = 1
	SearchBox.Position = UDim2.new(0.469697, 0, 0.075, 0)
	SearchBox.BackgroundColor3 = TextBgColor
	SearchBox.TextColor3 = UiButColor
	SearchBox.PlaceholderText = "Search..."
	SearchBox.Text = ""
	SearchBox.Font = Enum.Font.SourceSans
	SearchBox.ClearTextOnFocus = false
	SearchBox.TextScaled = true
	SearchBox.TextXAlignment = Enum.TextXAlignment.Left
	SearchBox.Parent = SearchFrame

	BackButton.Name = "BackButton"
	BackButton.ZIndex = 0
	BackButton.Visible = false
	BackButton.AnchorPoint = Vector2.new(1, 0)
	BackButton.Size = UDim2.new(0, 19, 1, 0)
	BackButton.BorderSizePixel = 0
	BackButton.LayoutOrder = 0
	BackButton.Position = UDim2.new(1, 0, 0, 0)
	BackButton.BackgroundColor3 = BgColor
	BackButton.ScaleType = Enum.ScaleType.Crop
	BackButton.Image = "rbxassetid://2418687610"
	BackButton.ImageColor3 = UiButColor
	BackButton.Parent = SearchFrame
	AddHoverText(BackButton, "Hide")

	local SFUIListLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
	SFUIListLayout.FillDirection = Enum.FillDirection.Horizontal
	SFUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	SFUIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	SFUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	SFUIListLayout.Padding = UDim.new(0, 1)
	SFUIListLayout.Parent = SearchFrame


	--CustomAnimFrame
	CustomAnimFrame.Parent = MainFrame
	CustomAnimFrame.Name = "CustomAnimFrame"
	CustomAnimFrame.ZIndex = 0
	CustomAnimFrame.AnchorPoint = Vector2.new(1, 0)
	CustomAnimFrame.Size = UDim2.new(0, 194, 0, 35)
	CustomAnimFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	CustomAnimFrame.Position = UDim2.new(1, 31, 0, 73)
	CustomAnimFrame.BorderSizePixel = 0
	CustomAnimFrame.BackgroundColor3 = BgColor

	CustomAnimButton.Name = "CustomAnimButton"
	CustomAnimButton.ZIndex = 0
	CustomAnimButton.Visible = true
	CustomAnimButton.AnchorPoint = Vector2.new(1, 0)
	CustomAnimButton.Size = UDim2.new(0, 30, 1, 0)
	CustomAnimButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	CustomAnimButton.LayoutOrder = 2
	CustomAnimButton.BorderSizePixel = 0
	CustomAnimButton.BackgroundColor3 = BgColor
	CustomAnimButton.ScaleType = Enum.ScaleType.Fit
	CustomAnimButton.Image = "rbxassetid://119465590963527"
	CustomAnimButton.ImageColor3 = UiButColor
	CustomAnimButton.Parent = CustomAnimFrame
	AddHoverText(CustomAnimButton, "Add a temporary animation with Id (Adds to Default section and disappears after reset)")

	IdBox.Name = "IdBox"
	IdBox.ZIndex = 0
	IdBox.Visible = false
	IdBox.AnchorPoint = Vector2.new(0.5, 0)
	IdBox.Size = UDim2.new(0, 139, 0, 29)
	IdBox.LayoutOrder = 1
	IdBox.BackgroundColor3 = TextBgColor
	IdBox.TextWrapped = true
	IdBox.TextColor3 = UiButColor
	IdBox.PlaceholderText = "Enter Id..."
	IdBox.Text = ""
	IdBox.CursorPosition = -1
	IdBox.Font = Enum.Font.SourceSans
	IdBox.TextXAlignment = Enum.TextXAlignment.Left
	IdBox.ClearTextOnFocus = false
	IdBox.TextScaled = true
	IdBox.Parent = CustomAnimFrame

	CustomAnimBackButton.Name = "CustomAnimBackButton"
	CustomAnimBackButton.ZIndex = 0
	CustomAnimBackButton.Visible = false
	CustomAnimBackButton.AnchorPoint = Vector2.new(1, 0)
	CustomAnimBackButton.Size = UDim2.new(0, 19, 1, 0)
	CustomAnimBackButton.BorderSizePixel = 0
	CustomAnimBackButton.BackgroundColor3 = BgColor
	CustomAnimBackButton.ScaleType = Enum.ScaleType.Crop
	CustomAnimBackButton.ImageColor3 = UiButColor
	CustomAnimBackButton.Image = "rbxassetid://2418687610"
	CustomAnimBackButton.Parent = CustomAnimFrame
	AddHoverText(CustomAnimBackButton, "Hide")

	local CAFUIListLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
	CAFUIListLayout.FillDirection = Enum.FillDirection.Horizontal
	CAFUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	CAFUIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	CAFUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	CAFUIListLayout.Padding = UDim.new(0, 1)
	CAFUIListLayout.Parent = CustomAnimFrame

	AddTempAnimButton.Name = "PlayAnimButton"
	AddTempAnimButton.ZIndex = 0
	AddTempAnimButton.Visible = false
	AddTempAnimButton.AnchorPoint = Vector2.new(1, 0)
	AddTempAnimButton.Size = UDim2.new(0, 32, 1, 0)
	AddTempAnimButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	AddTempAnimButton.LayoutOrder = 3
	AddTempAnimButton.Position = UDim2.new(1, 0, 0, 0)
	AddTempAnimButton.BorderSizePixel = 0
	AddTempAnimButton.BackgroundColor3 = ButtonCol
	AddTempAnimButton.ScaleType = Enum.ScaleType.Fit
	AddTempAnimButton.ImageColor3 = UiButColor
	AddTempAnimButton.Image = "rbxassetid://15081504003"
	AddTempAnimButton.Parent = CustomAnimFrame
	AddHoverText(AddTempAnimButton, "Add animation (On start of animations frame)")


	--Choose ScrollingFrame Buttons
	DefaultSection.Parent = MainFrame
	DefaultSection.Name = "DefaultSection"
	DefaultSection.ZIndex = 0
	DefaultSection.AnchorPoint = Vector2.new(1, 0)
	DefaultSection.Size = UDim2.new(0, 52, 0, 32)
	DefaultSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
	DefaultSection.Position = UDim2.new(1, 51, 1, -104)
	DefaultSection.BorderSizePixel = 0
	DefaultSection.BackgroundColor3 = BgColor
	DefaultSection.TextSize = 26
	DefaultSection.TextColor3 = UiButColor
	DefaultSection.RichText = true
	DefaultSection.Text = "<b>R</b>"
	if RigType == "R15" then
		DefaultSection.Text = "<b>R15</b>"
	elseif RigType == "R6" then
		DefaultSection.Text = "<b>R6</b>"
	end
	DefaultSection.Font = Enum.Font.Roboto
	DefaultSection.TextXAlignment = Enum.TextXAlignment.Left
	AddHoverText(DefaultSection, "Default Animations")

	SpecGameSection.Parent = MainFrame
	SpecGameSection.Name = "SpecGameSection"
	SpecGameSection.ZIndex = 0
	SpecGameSection.AnchorPoint = Vector2.new(1, 0)
	SpecGameSection.Size = UDim2.new(0, 72, 0, 32)
	SpecGameSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SpecGameSection.Position = UDim2.new(1, 71, 1, -68)
	SpecGameSection.BorderSizePixel = 0
	SpecGameSection.BackgroundColor3 = BgColor
	SpecGameSection.TextSize = 26
	SpecGameSection.TextColor3 = UiButColor
	SpecGameSection.RichText = true
	SpecGameSection.Text = "<b>Game</b>"
	SpecGameSection.Font = Enum.Font.Roboto
	SpecGameSection.TextXAlignment = Enum.TextXAlignment.Left


	--EmoteWheel
	EmoteWheel.Parent = Emoter
	EmoteWheel.Name = "EmoteWheel"
	EmoteWheel.AnchorPoint = Vector2.new(0.5, 0.5)
	EmoteWheel.Size = UDim2.new(0, 380, 0, 380)
	EmoteWheel.BackgroundTransparency = 1
	EmoteWheel.Position = UDim2.new(0.5, 0, 0.5, 0)
	EmoteWheel.Visible = false
	local UIAspectRatioConstraint = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint.Parent = EmoteWheel

	local ShadowFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
	ShadowFrame.Parent = EmoteWheel
	ShadowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	ShadowFrame.Size = UDim2.new(1, 0, 1, 0)
	ShadowFrame.Position = UDim2.new(0.5,0,0.5,0)
	ShadowFrame.BackgroundTransparency = 1
	ShadowFrame.ZIndex = 100

	local UICorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
	UICorner.Parent = ShadowFrame
	UICorner.CornerRadius = UDim.new(1, 0)

	local OutUIShadow = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIShadow")
	OutUIShadow.Parent = ShadowFrame
	OutUIShadow.BlurRadius = UDim.new(0, 15)
	OutUIShadow.Transparency = 0.35
	OutUIShadow.Spread = UDim2.new(0.19, 0, 0.19, 0)
	OutUIShadow.ZIndex = 100
	local InUIShadow = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIShadow")
	InUIShadow.Parent = ShadowFrame
	InUIShadow.BlurRadius = UDim.new(0, 15)
	InUIShadow.Transparency = 0.35
	InUIShadow.Spread = UDim2.new(-0.4, 0, -0.4, 0)
	InUIShadow.ZIndex = 100

	EmoteWheelText.Parent = EmoteWheel
	EmoteWheelText.Name = "Text"
	EmoteWheelText.AnchorPoint = Vector2.new(0.5, 0.5)
	EmoteWheelText.Size = UDim2.new(0.5, 0, 0.1, 0)
	EmoteWheelText.BackgroundTransparency = 1
	EmoteWheelText.Position = UDim2.new(0.5, 0, 0.5, 0)
	EmoteWheelText.TextStrokeTransparency = 0
	EmoteWheelText.TextSize = 14
	EmoteWheelText.TextColor3 = Color3.fromRGB(255, 255, 255)
	EmoteWheelText.RichText = true
	EmoteWheelText.Font = Enum.Font.Roboto
	EmoteWheelText.Text = "<b>Select an Emote</b>"
	EmoteWheelText.TextScaled = true
	EmoteWheelText.ZIndex = 100

	Emote1.Name = "Emote1"
	Emote1.AnchorPoint = Vector2.new(0.5, 0.5)
	Emote1.Size = UDim2.new(0.23, 0, 0.23, 0)
	Emote1.Position = UDim2.new(0.5, 0, 0.09, 0)
	Emote1.BackgroundColor3 = ButtonCol
	Emote1.TextColor3 = UiButColor
	Emote1.Font = Enum.Font.SourceSansBold
	Emote1.TextScaled = true
	Emote1.ZIndex = 100
	Emote1.Parent = EmoteWheel

	Emote2.Name = "Emote2"
	Emote2.AnchorPoint = Vector2.new(0.5, 0.5)
	Emote2.Size = UDim2.new(0.23, 0, 0.23, 0)
	Emote2.Position = UDim2.new(0.8, 0, 0.2, 0)
	Emote2.BackgroundColor3 = ButtonCol
	Emote2.TextColor3 = UiButColor
	Emote2.Font = Enum.Font.SourceSansBold
	Emote2.TextScaled = true
	Emote2.ZIndex = 100
	Emote2.Parent = EmoteWheel

	Emote3.Name = "Emote3"
	Emote3.AnchorPoint = Vector2.new(0.5, 0.5)
	Emote3.Size = UDim2.new(0.23, 0, 0.23, 0)
	Emote3.Position = UDim2.new(0.91, 0, 0.5, 0)
	Emote3.BackgroundColor3 = ButtonCol
	Emote3.TextColor3 = UiButColor
	Emote3.Font = Enum.Font.SourceSansBold
	Emote3.TextScaled = true
	Emote3.ZIndex = 100
	Emote3.Parent = EmoteWheel

	Emote4.Name = "Emote4"
	Emote4.AnchorPoint = Vector2.new(0.5, 0.5)
	Emote4.Size = UDim2.new(0.23, 0, 0.23, 0)
	Emote4.Position = UDim2.new(0.8, 0, 0.8, 0)
	Emote4.BackgroundColor3 = ButtonCol
	Emote4.TextColor3 = UiButColor
	Emote4.Font = Enum.Font.SourceSansBold
	Emote4.TextScaled = true
	Emote4.ZIndex = 100
	Emote4.Parent = EmoteWheel

	Emote5.Name = "Emote5"
	Emote5.AnchorPoint = Vector2.new(0.5, 0.5)
	Emote5.Size = UDim2.new(0.23, 0, 0.23, 0)
	Emote5.Position = UDim2.new(0.5, 0, 0.91, 0)
	Emote5.BackgroundColor3 = ButtonCol
	Emote5.TextColor3 = UiButColor
	Emote5.Font = Enum.Font.SourceSansBold
	Emote5.TextScaled = true
	Emote5.ZIndex = 100
	Emote5.Parent = EmoteWheel

	Emote6.Name = "Emote6"
	Emote6.AnchorPoint = Vector2.new(0.5, 0.5)
	Emote6.Size = UDim2.new(0.23, 0, 0.23, 0)
	Emote6.Position = UDim2.new(0.2, 0, 0.8, 0)
	Emote6.BackgroundColor3 = ButtonCol
	Emote6.TextColor3 = UiButColor
	Emote6.Font = Enum.Font.SourceSansBold
	Emote6.TextScaled = true
	Emote6.ZIndex = 100
	Emote6.Parent = EmoteWheel

	Emote7.Name = "Emote7"
	Emote7.AnchorPoint = Vector2.new(0.5, 0.5)
	Emote7.Size = UDim2.new(0.23, 0, 0.23, 0)
	Emote7.Position = UDim2.new(0.09, 0, 0.5, 0)
	Emote7.BackgroundColor3 = ButtonCol
	Emote7.TextColor3 = UiButColor
	Emote7.Font = Enum.Font.SourceSansBold
	Emote7.TextScaled = true
	Emote7.ZIndex = 100
	Emote7.Parent = EmoteWheel

	Emote8.Name = "Emote8"
	Emote8.AnchorPoint = Vector2.new(0.5, 0.5)
	Emote8.Size = UDim2.new(0.23, 0, 0.23, 0)
	Emote8.Position = UDim2.new(0.2, 0, 0.2, 0)
	Emote8.BackgroundColor3 = ButtonCol
	Emote8.TextColor3 = UiButColor
	Emote8.Font = Enum.Font.SourceSansBold
	Emote8.TextScaled = true
	Emote8.ZIndex = 100
	Emote8.Parent = EmoteWheel


	--SettingsFrame
	CreateDivideFrame("Animation", 1, "Settings")
	CreateDivideFrame("Running & Idle", 2, "Settings")
	CreateDivideFrame("Style", 3, "Settings")
	CreateDivideFrame("Hotkeys", 4, "Settings")
	CreateDivideFrame("Data", 5, "Settings")

	SettingsFrame.Parent = Emoter
	SettingsFrame.Name = "SettingsFrame"
	SettingsFrame.AnchorPoint = Vector2.new(0.5, 0)
	SettingsFrame.Size = UDim2.new(0, 220, 0, 286)
	SettingsFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SettingsFrame.Position = MainFrame.Position + UDim2.new(-1, 0, 0, 0)
	SettingsFrame.BorderSizePixel = 0
	SettingsFrame.BackgroundColor3 = ScrollBgColor
	SettingsFrame.Visible = false

	local UIShadow = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIShadow")
	UIShadow.BlurRadius = UDim.new(0, 20)
	UIShadow.Transparency = 0.5
	UIShadow.Parent = SettingsFrame

	local UIDragDetectorSettings = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIDragDetector")
	UIDragDetectorSettings.Parent = SettingsFrame
	UIDragDetectorSettings.DragStyle = Enum.UIDragDetectorDragStyle.Scriptable
	UIDragDetectorSettings.ResponseStyle = Enum.UIDragDetectorResponseStyle.CustomOffset
	DraggingFunction(UIDragDetectorSettings, SettingsFrame)

	SGSNotification.Parent = SettingsFrame
	SGSNotification.Name = "SGSNotification"
	SGSNotification.AutoButtonColor = false
	SGSNotification.Size = UDim2.new(0, 20, 0, 20)
	SGSNotification.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SGSNotification.BackgroundTransparency = 1
	SGSNotification.Position = UDim2.new(0, 2, 0, 28)
	SGSNotification.BorderSizePixel = 0
	SGSNotification.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SGSNotification.Image = "rbxassetid://76962094933629"
	AddHoverText(SGSNotification, "The settings was loaded from file for only <b>this</b> game (click RMB to delete this file)")
	if IsDefaultSettings then
		SGSNotification.Visible = false
	end

	DataNotification.Parent = SettingsFrame
	DataNotification.Visible = false
	DataNotification.Name = "AddedDataNotification"
	DataNotification.AutoButtonColor = false
	DataNotification.Size = UDim2.new(0, 25, 0, 25)
	DataNotification.BorderColor3 = Color3.fromRGB(0, 0, 0)
	DataNotification.BackgroundTransparency = 1
	DataNotification.Position = UDim2.new(0, 0, 0, 1)
	DataNotification.BorderSizePixel = 0
	DataNotification.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	DataNotification.Image = "rbxassetid://85975257618857"
	AddHoverText(DataNotification, AddedDataInfo)

	GuiName.Name = "Name"
	GuiName.AnchorPoint = Vector2.new(0.5, 0)
	GuiName.Size = UDim2.new(0, 0, 0, 25)
	GuiName.BackgroundTransparency = 1
	GuiName.Position = UDim2.new(0.5, 0, 0, 5)
	GuiName.TextSize = 25
	GuiName.Text = "Emoter GUI"
	GuiName.Font = Enum.Font.Highway
	GuiName.TextColor3 = UiButColor
	GuiName.Parent = SettingsFrame

	AutorText.Name = "AutorText"
	AutorText.AnchorPoint = Vector2.new(0.5, 0)
	AutorText.Size = UDim2.new(0, 0, -0.025, 25)
	AutorText.LayoutOrder = 1
	AutorText.BackgroundTransparency = 1
	AutorText.Position = UDim2.new(0.5, 0, 0, 27)
	AutorText.TextSize = 17
	AutorText.Text = "by Fixel"
	AutorText.Font = Enum.Font.SourceSans
	AutorText.TextColor3 = UiButColor
	AutorText.Parent = SettingsFrame

	VersionText.Parent = SettingsFrame
	VersionText.Name = "VersionText"
	VersionText.AnchorPoint = Vector2.new(1, 0)
	VersionText.Size = UDim2.new(0.2124352, 0, -0.025, 25)
	VersionText.LayoutOrder = 1
	VersionText.BackgroundTransparency = 1
	VersionText.Position = UDim2.new(1, -2, 0, 0)
	VersionText.TextSize = 14
	VersionText.Text = "V"..ScriptVersion
	VersionText.TextColor3 = Color3.fromRGB(147, 147, 147)
	VersionText.TextWrapped = true
	VersionText.Font = Enum.Font.SourceSans
	VersionText.TextXAlignment = Enum.TextXAlignment.Right
	VersionText.TextYAlignment = Enum.TextYAlignment.Top

	WarningText.Parent = SettingsFrame
	WarningText.Name = "WarningText"
	WarningText.Visible = false
	WarningText.AnchorPoint = Vector2.new(0.5, 0)
	WarningText.Size = UDim2.new(0, 220, 0, 35)
	WarningText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	WarningText.BackgroundTransparency = 1
	WarningText.Position = UDim2.new(0.5, 0, 1, 5)
	WarningText.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
	WarningText.TextStrokeTransparency = 0
	WarningText.TextSize = 14
	WarningText.RichText = true
	WarningText.TextColor3 = Color3.fromRGB(0, 0, 0)
	WarningText.Text = "Do you want to save settings to main file while having specific settings? (Click again to proceed)"
	WarningText.TextWrapped = true
	WarningText.Font = Enum.Font.SourceSans

	local UIStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
	UIStroke.Color = Color3.fromRGB(255, 255, 255)
	UIStroke.Thickness = 1
	UIStroke.Parent = WarningText

	SettingsStuff.Name = "SettingsStuff"
	SettingsStuff.Size = UDim2.new(1, 0, 0.648, 0)
	SettingsStuff.BackgroundTransparency = 1
	SettingsStuff.Position = UDim2.new(0, 0, 0.18, 0)
	SettingsStuff.ScrollBarImageColor3 = UiButColor
	SettingsStuff.CanvasSize = UDim2.new(0, 0, 0.5, 10)
	SettingsStuff.AutomaticCanvasSize = Enum.AutomaticSize.Y
	SettingsStuff.ScrollBarThickness = 3
	SettingsStuff.Parent = SettingsFrame

	local UIListLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Parent = SettingsStuff

	ThemeOption.Name = "ThemeOption"
	ThemeOption.Size = UDim2.new(1, 0, 0, 25)
	ThemeOption.LayoutOrder = 3
	ThemeOption.BackgroundTransparency = 1
	ThemeOption.Parent = SettingsStuff

	local UIListLayout5 = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
	UIListLayout5.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout5.VerticalAlignment = Enum.VerticalAlignment.Center
	UIListLayout5.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout5.Padding = UDim.new(0, 5)
	UIListLayout5.Parent = ThemeOption

	ThemeOptionText.Name = "ThemeOptionText"
	ThemeOptionText.Size = UDim2.new(0, 124, 0, 25)
	ThemeOptionText.BackgroundTransparency = 1
	ThemeOptionText.TextSize = 14
	ThemeOptionText.TextColor3 = UiButColor
	ThemeOptionText.Text = "Theme"
	ThemeOptionText.Font = Enum.Font.SourceSans
	ThemeOptionText.TextXAlignment = Enum.TextXAlignment.Left
	ThemeOptionText.Parent = ThemeOption

	PurpleThemeColor.Name = "PurpleThemeColor"
	PurpleThemeColor.Size = UDim2.new(0, 15, 0, 15)
	PurpleThemeColor.BorderColor3 = Color3.fromRGB(0, 0, 0)
	PurpleThemeColor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	PurpleThemeColor.Text = ""
	PurpleThemeColor.Parent = ThemeOption
	AddHoverText(PurpleThemeColor, "Light theme with purple parts")

	local PurpleGradient = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient")
	PurpleGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(137, 165, 255)), ColorSequenceKeypoint.new(0.4342561, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))})
	PurpleGradient.Rotation = 90
	PurpleGradient.Parent = PurpleThemeColor

	OrangeThemeColor.Name = "OrangeThemeColor"
	OrangeThemeColor.Size = UDim2.new(0, 15, 0, 15)
	OrangeThemeColor.BorderColor3 = Color3.fromRGB(0, 0, 0)
	OrangeThemeColor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	OrangeThemeColor.Text = ""
	OrangeThemeColor.Parent = ThemeOption
	AddHoverText(OrangeThemeColor, "Light theme with orange parts")

	local OrangeGradient = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient")
	OrangeGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 171, 35)), ColorSequenceKeypoint.new(0.4342561, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))})
	OrangeGradient.Rotation = 90
	OrangeGradient.Parent = OrangeThemeColor

	YellowThemeColor.Name = "YellowThemeColor"
	YellowThemeColor.Size = UDim2.new(0, 15, 0, 15)
	YellowThemeColor.BorderColor3 = Color3.fromRGB(0, 0, 0)
	YellowThemeColor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	YellowThemeColor.Text = ""
	YellowThemeColor.Parent = ThemeOption
	AddHoverText(YellowThemeColor, "Light theme with yellow parts")

	local YellowGradient = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient")
	YellowGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 250, 112)), ColorSequenceKeypoint.new(0.4342561, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))})
	YellowGradient.Rotation = 90
	YellowGradient.Parent = YellowThemeColor

	BlackThemeColor.Name = "BlackThemeColor"
	BlackThemeColor.Size = UDim2.new(0, 15, 0, 15)
	BlackThemeColor.LayoutOrder = 1
	BlackThemeColor.BorderColor3 = UiButColor
	BlackThemeColor.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
	BlackThemeColor.Text = ""
	BlackThemeColor.Parent = ThemeOption
	AddHoverText(BlackThemeColor, "Black theme")

	local YSizeOption = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
	YSizeOption.Parent = SettingsStuff
	YSizeOption.Name = "YSizeOptionOption"
	YSizeOption.Size = UDim2.new(1, 0, 0, 25)
	YSizeOption.LayoutOrder = 3
	YSizeOption.BackgroundTransparency = 1

	local UIListLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Padding = UDim.new(0, 5)
	UIListLayout.Parent = YSizeOption

	local YSizeOptionText = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
	YSizeOptionText.Name = "YSizeOptionText"
	YSizeOptionText.Size = UDim2.new(0, 94, 0, 25)
	YSizeOptionText.BackgroundTransparency = 1
	YSizeOptionText.TextSize = 14
	YSizeOptionText.TextColor3 = UiButColor
	YSizeOptionText.Text = "Vertical size"
	YSizeOptionText.Font = Enum.Font.SourceSans
	YSizeOptionText.TextXAlignment = Enum.TextXAlignment.Left
	YSizeOptionText.Parent = YSizeOption

	local UIPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
	UIPadding.PaddingBottom = UDim.new(0, 2)
	UIPadding.Parent = YSizeOptionText

	local X05YSixe = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	X05YSixe.Name = "X05YSixe"
	X05YSixe.Size = UDim2.new(0, 25, 0, 15)
	X05YSixe.BorderColor3 = Color3.fromRGB(0, 0, 0)
	X05YSixe.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	X05YSixe.Text = "0.5x"
	X05YSixe.Parent = YSizeOption

	local X1YSize = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	X1YSize.Name = "X1YSize"
	X1YSize.Size = UDim2.new(0, 20, 0, 15)
	X1YSize.BorderColor3 = Color3.fromRGB(0, 0, 0)
	X1YSize.Position = UDim2.new(0.5861111, 0, 0.2, 0)
	X1YSize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	X1YSize.Text = "1x"
	X1YSize.Parent = YSizeOption

	local X15YSize = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	X15YSize.Name = "X15YSize"
	X15YSize.Size = UDim2.new(0, 25, 0, 15)
	X15YSize.BorderColor3 = Color3.fromRGB(0, 0, 0)
	X15YSize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	X15YSize.Text = "1.5x"
	X15YSize.Parent = YSizeOption

	local X2YSize = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	X2YSize.Name = "X2YSize"
	X2YSize.Size = UDim2.new(0, 20, 0, 15)
	X2YSize.BorderColor3 = Color3.fromRGB(0, 0, 0)
	X2YSize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	X2YSize.Text = "2x"
	X2YSize.Parent = YSizeOption

	local XSizeOption = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
	XSizeOption.Parent = SettingsStuff
	XSizeOption.Name = "XSizeOption"
	XSizeOption.Size = UDim2.new(1, 0, 0, 25)
	XSizeOption.LayoutOrder = 3
	XSizeOption.BackgroundTransparency = 1

	local UIListLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Padding = UDim.new(0, 5)
	UIListLayout.Parent = XSizeOption

	local XSizeOptionText = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
	XSizeOptionText.Name = "XSizeOptionText"
	XSizeOptionText.Size = UDim2.new(0, 104, 0, 25)
	XSizeOptionText.BackgroundTransparency = 1
	XSizeOptionText.TextSize = 14
	XSizeOptionText.TextColor3 = UiButColor
	XSizeOptionText.Text = "Horizontal size"
	XSizeOptionText.Font = Enum.Font.SourceSans
	XSizeOptionText.TextXAlignment = Enum.TextXAlignment.Left
	XSizeOptionText.Parent = XSizeOption

	local UIPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
	UIPadding.PaddingBottom = UDim.new(0, 2)
	UIPadding.Parent = XSizeOptionText

	local X2Size = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	X2Size.Name = "X2Sixe"
	X2Size.Size = UDim2.new(0, 20, 0, 15)
	X2Size.BorderColor3 = Color3.fromRGB(0, 0, 0)
	X2Size.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	X2Size.Text = "2x"
	X2Size.Parent = XSizeOption

	local X3Size = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	X3Size.Name = "X3Size"
	X3Size.Size = UDim2.new(0, 20, 0, 15)
	X3Size.BorderColor3 = Color3.fromRGB(0, 0, 0)
	X3Size.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	X3Size.Text = "3x"
	X3Size.Parent = XSizeOption

	local X4Size = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	X4Size.Name = "X4Size"
	X4Size.Size = UDim2.new(0, 20, 0, 15)
	X4Size.BorderColor3 = Color3.fromRGB(0, 0, 0)
	X4Size.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	X4Size.Text = "4x"
	X4Size.Parent = XSizeOption

	local X5Size = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	X5Size.Name = "X5Size"
	X5Size.Size = UDim2.new(0, 20, 0, 15)
	X5Size.BorderColor3 = Color3.fromRGB(0, 0, 0)
	X5Size.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	X5Size.Text = "5x"
	X5Size.Parent = XSizeOption

	AddSettings(AnimPreviewEnabled, "PreviewOption", "Enable Animation Preview", 0)
	AddSettings(DebugInfoEnabled, "DebugInfoOption", "Show Debug information", 0)
	AddSettings(AnalyticsEnabled, "AnalyticsOption", "Enable analytics (hover for info)", 0)
	AddSettings(LoadAnimationsOnRestart, "LoadAnimationsOnRestartOption", "Play 'Running' & 'Idle' anims on reset", 0)
	AddSettings(LoadAllAnimationsOnRestart, "LoadAllAnimationsOnRestartOption", "Play ALL animations on reset", 0)
	AddSettings(TopMost, "TopMostOption", "Top most", 0)

	AddSettings(ToolIdleAnimHighPriorEnabled, "ToolIdlePriorityOption", "High priority on ToolIdle anims", 1)
	AddSettings(ToolActionAnimHighPriorEnabled, "ToolActionPriorityOption", "High priority on ToolAction anims", 1)
	AddSettings(AnimSwitchModeEnabled, "SwitchOption", "Anims Switch mode", 1)
	AddSettings(AnimSwitchModeRunIdleExceptionEnabled, "SwitchRunIdleExceptionOption", "Exception for 'Running' and 'Idle'", 1)
	AddSettings(AnimSmoothFadeEnabled, "AnimFadeOption", "Anim smooth Start/Stop", 1)
	AddSettings(HigherPriorityEnabled, "HigherPriorityOption", "Animations Higher priority", 1)

	AddSettings(IdleTypeEnabled, "IdleTypeOption", "Enable 'Idle' type", 2)
	AddSettings(RunningTypeEnabled, "RunningTypeOption", "Enable 'Running' type", 2)
	AddSettings(RunningTypeStopStandingEnabled, "RunningTypeStopStandingOption", "Stop animation while not running", 2)
	AddSettings(RunningTypeCharSpeedEnabled, "RunningTypeCharSpeedOption", "AnimSpeed depends on character's", 2)
	AddSettings(RunningTypeMinSpeedEnabled, "RunningTypeMinSpeedOption", "Enable 'MinimumSpeed' value", 2)
	AddSettings(RunningTypeStopJumpingEnabled, "RunningTypeStopJumpingOption", "Stop animation while jumping", 2)
	AddSettings(RunningTypeStopClimbingEnabled, "RunningTypeStopClimbingOption", "Stop animation while climbing", 2)

	AddSettings(UICornerEnabled, "UICornerOption", "Enable UICorners", 3)
	AddSettings(UIGradientEnabled, "UIGradientOption", "Enable UIGradients", 3)
	AddSettings(HotkeysEnabled, "HotkeysOption", "Enable Hotkeys", 4)

	AddSettings(LoadGithubSGAEnabled, "LoadGithubSGAOption", "Load SpecificGameAnims from Github", 5)
	AddSettings(LoadGithubCustomAnimsEnabled, "LoadGithubCustomAnimOption", "Load AdditionalAnims from Github", 5)
	AddSettings(LoadLocalSGAEnabled, "LoadLocalSGAOption", "Load SpecificGameAnims from local", 5)
	AddSettings(LoadLocalCustomAnimsEnabled, "LoadLocalCustomAnimOption", "Load AdditionalAnims from local", 5)

	DragDelayOption.Parent = SettingsStuff
	DragDelayOption.LayoutOrder = 3
	DragDelayOption.Name = "DragDelayOption"
	DragDelayOption.Size = UDim2.new(1, 0, 0, 25)
	DragDelayOption.BackgroundTransparency = 1
	AddHoverText(DragDelayOption, "Number of drag smoothness. Еhe higher the number the smoother and slower GUI element will move. If at 0, it will move without smooth")

	local UIListLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Padding = UDim.new(0, 5)
	UIListLayout.Parent = DragDelayOption

	DragOptionText.Name = "DragOptionText"
	DragOptionText.Size = UDim2.new(0, 164, 0, 25)
	DragOptionText.BackgroundTransparency = 1
	DragOptionText.TextSize = 14
	DragOptionText.TextColor3 = UiButColor
	DragOptionText.Text = "Drag Smoothness"
	DragOptionText.Font = Enum.Font.SourceSans
	DragOptionText.TextXAlignment = Enum.TextXAlignment.Left
	DragOptionText.Parent = DragDelayOption

	DelayNumBox.Size = UDim2.new(0, 35, 0, 20)
	DelayNumBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
	DelayNumBox.BackgroundColor3 = TextBgColor
	DelayNumBox.TextSize = 14
	DelayNumBox.TextColor3 = UiButColor
	DelayNumBox.ClearTextOnFocus = false
	DelayNumBox.Text = DragDelay
	DelayNumBox.PlaceholderText = "0"
	DelayNumBox.CursorPosition = -1
	DelayNumBox.Font = Enum.Font.SourceSans
	DelayNumBox.Parent = DragDelayOption

	HotkeysEditOption.Name = "HotkeysEditOption"
	HotkeysEditOption.Size = UDim2.new(0.55, 0, 0, 20)
	HotkeysEditOption.BorderColor3 = Color3.fromRGB(0, 0, 0)
	HotkeysEditOption.LayoutOrder = 4
	HotkeysEditOption.Position = UDim2.new(0, 0, 0.1558714, 0)
	HotkeysEditOption.BorderSizePixel = 0
	HotkeysEditOption.BackgroundColor3 = ButtonCol
	HotkeysEditOption.TextColor3 = UiButColor
	HotkeysEditOption.TextSize = 14
	HotkeysEditOption.Text = "Edit Hotkeys..."
	HotkeysEditOption.Font = Enum.Font.SourceSans
	HotkeysEditOption.Parent = SettingsStuff

	local UIListLayout7 = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
	UIListLayout7.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout7.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayout7.VerticalAlignment = Enum.VerticalAlignment.Center
	UIListLayout7.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout7.Padding = UDim.new(0, 5)
	UIListLayout7.Parent = HotkeysEditOption

	HotkeysFrame.Name = "HotkeysFrame"
	HotkeysFrame.AnchorPoint = Vector2.new(0, 0.5)
	HotkeysFrame.Size = UDim2.new(0, 220, 0, 138)
	HotkeysFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	HotkeysFrame.Position = UDim2.new(1, 10, 0.76, 0)
	HotkeysFrame.BorderSizePixel = 0
	HotkeysFrame.BackgroundColor3 = ScrollBgColor
	HotkeysFrame.Visible = false
	HotkeysFrame.Parent = SettingsFrame

	HotkeysStuff.Name = "HotkeysStuff"
	HotkeysStuff.Size = UDim2.new(1, 0, 0.845, 0)
	HotkeysStuff.BackgroundTransparency = 1
	HotkeysStuff.Position = UDim2.new(0, 0, 0.155, 0)
	HotkeysStuff.ScrollBarImageColor3 = UiButColor
	HotkeysStuff.CanvasSize = UDim2.new(0, 0, 0.5, 10)
	HotkeysStuff.AutomaticCanvasSize = Enum.AutomaticSize.Y
	HotkeysStuff.HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	HotkeysStuff.ScrollBarThickness = 3
	HotkeysStuff.Parent = HotkeysFrame

	local UIListLayout8 = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
	UIListLayout8.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayout8.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout8.Parent = HotkeysStuff

	HotkeyFrameName.Name = "Name"
	HotkeyFrameName.Size = UDim2.new(1, 0, -0.043, 25)
	HotkeyFrameName.BackgroundTransparency = 1
	HotkeyFrameName.Position = UDim2.new(0, 0, 0.018, 0)
	HotkeyFrameName.TextColor3 = UiButColor
	HotkeyFrameName.TextSize = 14
	HotkeyFrameName.Text = "Hotkeys"
	HotkeyFrameName.TextWrapped = true
	HotkeyFrameName.Font = Enum.Font.Highway
	HotkeyFrameName.TextScaled = true
	HotkeyFrameName.Parent = HotkeysFrame

	MoreButtonsFrame.Parent = SettingsFrame
	MoreButtonsFrame.Name = "MoreButtonsFrame"
	MoreButtonsFrame.Interactable = true
	MoreButtonsFrame.AnchorPoint = Vector2.new(0, 1)
	MoreButtonsFrame.Size = UDim2.new(1, 0, 0, 50)
	MoreButtonsFrame.BackgroundTransparency = 1
	MoreButtonsFrame.Position = UDim2.new(0, 0, 1, 0)

	local UIListLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Padding = UDim.new(0, 22)
	UIListLayout.Parent = MoreButtonsFrame

	SaveSettingsButton.Name = "SaveSettingsButton"
	SaveSettingsButton.Size = UDim2.new(0, 35, 0, 35)
	SaveSettingsButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SaveSettingsButton.Position = UDim2.new(0.0518135, 0, 0.845614, 0)
	SaveSettingsButton.BorderSizePixel = 0
	SaveSettingsButton.BackgroundColor3 = ButtonCol
	SaveSettingsButton.Image = "rbxassetid://11768914234"
	SaveSettingsButton.ImageColor3 = UiButColor
	SaveSettingsButton.Parent = MoreButtonsFrame
	AddHoverText(SaveSettingsButton, "Save settings. RMB will save settings for <b>only</b> this game")

	LaunchIdDetectorButton.Name = "LaunchIdDetectorButton"
	LaunchIdDetectorButton.Size = UDim2.new(0, 35, 0, 35)
	LaunchIdDetectorButton.Position = UDim2.new(0.4093264, 0, 0.845614, 0)
	LaunchIdDetectorButton.BackgroundColor3 = ButtonCol
	LaunchIdDetectorButton.ImageColor3 = UiButColor
	LaunchIdDetectorButton.Image = "rbxassetid://88751076321975"
	LaunchIdDetectorButton.Parent = MoreButtonsFrame
	AddHoverText(LaunchIdDetectorButton, "Launch IdDetector Script")

	ResetButton.Parent = MoreButtonsFrame
	ResetButton.Name = "ResetButton"
	ResetButton.Size = UDim2.new(0, 35, 0, 35)
	ResetButton.Position = UDim2.new(0.2487047, 0, 0.8561404, 0)
	ResetButton.BackgroundColor3 = ButtonCol
	ResetButton.Image = "rbxassetid://84090157888894"
	ResetButton.ImageColor3 = UiButColor
	AddHoverText(ResetButton, "Reset Gui")

	GithubLinkButton.Name = "GithubLinkButton"
	GithubLinkButton.Size = UDim2.new(0, 35, 0, 35)
	GithubLinkButton.Position = UDim2.new(0.7720207, 0, 0.845614, 0)
	GithubLinkButton.BackgroundColor3 = ButtonCol
	GithubLinkButton.Image = "rbxassetid://133448000957069"
	GithubLinkButton.ImageColor3 = UiButColor
	GithubLinkButton.Parent = MoreButtonsFrame
	AddHoverText(GithubLinkButton, "Get the Github for Tutorials and more Info! (Copy Link)")


	--Hotkey Functions
	local function CloseGuiFunction()
		if MainFrame.Visible == true then
			SideFrame.Position = MainFrame.Position
		else
			MainFrame.Position = SideFrame.Position
		end
		MainFrame.Visible = not MainFrame.Visible
		SideFrame.Visible = not SideFrame.Visible
		if MainFrame.Visible == false then
			MFUIScale.Scale = 0.8
			game.TweenService:Create(SFUIScale, TweenInfo.new(.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Scale = 1}):Play()
		else
			game.TweenService:Create(MFUIScale, TweenInfo.new(.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Scale = 1}):Play()
			SFUIScale.Scale = 1.2
		end
		
		SFHideTimeCount = 0
		SideFrame.GroupTransparency = 0
		SideFrame.UIStroke.Transparency = 0
	end

	local function OpenSettingsFunction()
		SettingsFrame.Visible = not SettingsFrame.Visible
	end

	local SearchButtonClick = true
	local function OpenSearchFunction()
		if MainFrame.Visible == true then
			SearchBox:CaptureFocus()
			if SearchBox.Visible == false then
				SearchButtonClick = false
				SearchButton.Visible = false
				BackButton.Visible = true
				SearchBox.Visible = true
				SFUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
				game.TweenService:Create(SearchFrame, TweenInfo.new(.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Position = UDim2.new(1, 164, 0.119, 0)}):Play()
				wait(.3)
				SearchButtonClick = true
			end
		end
	end
	local SwitchOptionButton = SettingsStuff.SwitchOption
	local function SwitchAnimsFunction()
		AnimSwitchModeEnabled = not AnimSwitchModeEnabled
		if AnimSwitchModeEnabled == true then
			SwitchOptionButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			SwitchOptionButton.CheckImage.Image = ""
		end
	end
	local AnimFadeOptionButton = SettingsStuff.AnimFadeOption
	local function AnimSmoothFadeFunction()
		AnimSmoothFadeEnabled = not AnimSmoothFadeEnabled
		if AnimSmoothFadeEnabled == true then
			AnimFadeOptionButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			AnimFadeOptionButton.CheckImage.Image = ""
		end
	end
	local function StopAnimsFunction()
		StopAnimsEvent:Fire("Forced")
	end
	local function OpenEmoteWheelFunction()
		EmoteWheel.Visible = not EmoteWheel.Visible
	end
	local function SitFunction()
		if Humanoid.Sit == false then
			Humanoid.Sit = true
		else
			Humanoid.Sit = false
		end
	end
	local function ResetFunction()
		Player.Character.Humanoid.Health = 0
	end

	local function BindHotkeys(Reason)
		AddHotkey(DoubleHotkey, "DoubleHotkey", "Key for Double Hotkey")
		if Reason ~= "EnableHotkeys" then
			AddHotkey(EmoteWheelHotkey, "EmoteWheelHotkey", "Open Emote Wheel*", OpenEmoteWheelFunction)
		end
		AddHotkey(SearchHotkey, "SearchHotkey", "Search", OpenSearchFunction)
		AddHotkey(CloseHotkey, "CloseHotkey", "Close/Open Gui", CloseGuiFunction)
		AddHotkey(SitHotkey, "SitHotkey", "Ragdoll-like falling", SitFunction)
		AddHotkey(SettingsHotkey, "SettingsHotkey", "Open Settings", OpenSettingsFunction)
		AddHotkey(SwitchAnimHotkey, "SwitchAnimHotkey", "Switch Anim Setting", SwitchAnimsFunction)
		AddHotkey(AnimFadeHotkey, "AnimFadeHotkey", "Animation Fade Setting", AnimSmoothFadeFunction)
		AddHotkey(StopAnimsHotkey, "StopAnimsHotkey", "Stop all Animations", StopAnimsFunction)
		AddHotkey(ResetCharHotkey, "ResetCharHotkey", "Reset character", ResetFunction)
	end
	BindHotkeys()
	AddHoverText(HotkeysStuff:FindFirstChild("DoubleHotkey").TextLabel, "A secondary key needed for activating a Double Hotkey")
	AddHoverText(HotkeysStuff:FindFirstChild("EmoteWheelHotkey").TextLabel, "WARNING! This Hotkey is NOT affected by EnableHotkeys setting. To disable it you can press Backspace to unbind")

	-- Buttons and other functions
	local function DestroyGuiFunction()
		GuiActive = false
		BindHotkeys()
		StopAnimsEvent:Fire("Reset/Destroy")
		SettingsFrame.Visible = false
		EmoteWheel.Visible = false
		game.TweenService:Create(MFUIScale, TweenInfo.new(.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Scale = 0}):Play()
		game.TweenService:Create(SFUIScale, TweenInfo.new(.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Scale = 0}):Play()
		wait(.3)
		Emoter:Destroy()
	end
	DestroyGUI.MouseButton1Click:connect(DestroyGuiFunction)
	SFDestroyGUI.MouseButton1Click:connect(DestroyGuiFunction)

	OpenGUI.MouseButton1Click:connect(function()
		CloseGuiFunction()
	end)
	CloseGUI.MouseButton1Click:connect(function()
		CloseGuiFunction()
	end)
	SettingsButton.MouseButton1Click:Connect(function()
		OpenSettingsFunction()
	end)

	if RigType == "R15" then
		ScrollingFrame.Visible = false
		ScrollingFrameR15.Visible = true
		Title.Text = "Emoter GUI (R15)"
		SideFrameTitle.Text = "Emoter GUI (R15)"
	else
		ScrollingFrame.Visible = true
		ScrollingFrameR15.Visible = false
		Title.Text = "Emoter GUI (R6)"
		SideFrameTitle.Text = "Emoter GUI (R6)"
	end
	
	task.spawn(function()
		while GuiActive and not GuiRestarted do
			SFHideTimeCount = SFHideTimeCount + 1
			if SFHideTimeCount == 7 and SideFrame.Visible == true then
				SideFrame.GroupTransparency = 0.5
				SideFrame.UIStroke.Transparency = 0.5
			end
			wait(1)
		end
	end)
	SideFrame.MouseMoved:Connect(function()
		SFHideTimeCount = 0
		SideFrame.GroupTransparency = 0
		SideFrame.UIStroke.Transparency = 0
	end)

	SpeedValue:GetPropertyChangedSignal("Text"):Connect(function()
		SpeedNum = SpeedValue.Text 
		if SpeedValue.Text == "" then
			SpeedNum = 0
		end
	end)

	local OptionsButtonClick = true
	OptionsButton.MouseButton1Click:Connect(function()
		if OptionsButtonClick == true then
			if not OptionsFrame.Visible then
				OptionsButtonClick = false
				OptionsFrame.Visible = true
				game.TweenService:Create(OptionsFrame, TweenInfo.new(.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 1, 7)}):Play()
				wait(.3)
				OptionsButtonClick = true
			else
				OptionsButtonClick = false
				game.TweenService:Create(OptionsFrame, TweenInfo.new(.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 1, -43)}):Play()
				wait(.2)
				OptionsFrame.Visible = false
				OptionsButtonClick = true
			end
		end
	end)


	--Searchbox
	SearchButton.MouseButton1Click:Connect(function()
		if SearchButtonClick == true then
			SearchButtonClick = false
			SearchButton.Visible = false
			BackButton.Visible = true
			SearchBox.Visible = true
			SFUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			game.TweenService:Create(SearchFrame, TweenInfo.new(.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Position = UDim2.new(1, 164, 0, 34)}):Play()
			wait(.3)
			SearchButtonClick = true
		end
	end)
	BackButton.MouseButton1Click:Connect(function()
		if SearchButtonClick == true then
			SearchButtonClick = false
			game.TweenService:Create(SearchFrame, TweenInfo.new(.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Position = UDim2.new(1, 31, 0, 34)}):Play()
			wait(.2)
			SFUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			SearchButton.Visible = true
			BackButton.Visible = false
			SearchBox.Visible = false
			SearchButtonClick = true
		end
	end)

	if SearchOpened == true then
		SearchButton.Visible = false
		BackButton.Visible = true
		SearchBox.Visible = true
		SFUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		SearchFrame.Position = UDim2.new(1, 164, 0, 34)
	end

	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		for _, ScrollFrame in ipairs(ScrollingFramesList) do
			for _, Button in ipairs(ScrollFrame:GetDescendants()) do
				if Button:IsA("TextButton") and string.find(Button.Text:lower(), SearchBox.Text) then
					Button.Visible = true
				elseif Button:IsA("TextButton") and not string.find(Button.Text, SearchBox.Text) then
					Button.Visible = false
				elseif Button.Name == "DivideFrame" then
					Button.Visible = false
				end
				if SearchBox.Text == "" then
					if Button:IsA("TextButton") then
						Button.Visible = true
					elseif Button.Name == "DivideFrame"  then
						Button.Visible = true
					end

				end
			end
		end
	end)


	--Custom Anim Search
	local CustomAnimButtonClick = true
	CustomAnimButton.MouseButton1Click:Connect(function()
		if CustomAnimButtonClick == true then
			CustomAnimButtonClick = false
			CustomAnimButton.Visible = false
			CustomAnimBackButton.Visible = true
			IdBox.Visible = true
			AddTempAnimButton.Visible = true
			CAFUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			game.TweenService:Create(CustomAnimFrame, TweenInfo.new(.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Position = UDim2.new(1, 194, 0, 73)}):Play()
			wait(.3)
			CustomAnimButtonClick = true
		end
	end)
	CustomAnimBackButton.MouseButton1Click:Connect(function()
		if CustomAnimButtonClick == true then
			CustomAnimButtonClick = false
			game.TweenService:Create(CustomAnimFrame, TweenInfo.new(.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Position = UDim2.new(1, 31, 0, 73)}):Play()
			wait(.2)
			CAFUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			CustomAnimButton.Visible = true
			CustomAnimBackButton.Visible = false
			IdBox.Visible = false
			AddTempAnimButton.Visible = false
			CustomAnimButtonClick = true
		end
	end)

	AddTempAnimButton.MouseButton1Click:Connect(function()
		if IdBox.Text == "" or string.match(IdBox.Text, "%a") then
			game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Error", Text = "Anim Id is empty or has letters", Duration = 3})
			return end

		local SameResult = false

		for _, Frame in ipairs(ScrollingFramesList) do
			for i, Result in ipairs(Frame:GetDescendants()) do
				if Result:IsA("TextButton") and Result.Name == IdBox.Text then
					SameResult = true
					game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Error", Text = "There's already Anim with this Id", Duration = 3})
					break
				end
			end
		end

		if SameResult == false then
			local Anim = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
			if RigType == "R6" then
				CreateAnimButton(Anim, IdBox.Text, IdBox.Text, "R6", 0)
			else
				CreateAnimButton(Anim, IdBox.Text, IdBox.Text, "R15", 0)
			end
			PlayAnim(Anim, IdBox.Text, .1, 1, "PriorLow", false)
			local UiStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
			UiStroke.Parent = Anim
			UiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		end

	end)

	if CustomAnimOpened == true then
		CustomAnimButton.Visible = false
		CustomAnimBackButton.Visible = true
		IdBox.Visible = true
		AddTempAnimButton.Visible = true
		CAFUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		CustomAnimFrame.Position = UDim2.new(1, 194, 0, 73)
	end


	--Choose Section Buttons
	DefaultSection.MouseButton1Click:Connect(function()
		ScrollingFrameSpecific.Visible = false
		DefaultSection.UIStroke.Color = Color3.fromRGB(255, 255, 255)
		SpecGameSection.UIStroke.Color = Color3.fromRGB(0, 0, 0)
		if RigType == "R6" then
			ScrollingFrame.Visible = true
			ScrollingFrameR15.Visible = false
		else
			ScrollingFrame.Visible = false
			ScrollingFrameR15.Visible = true
		end
	end)

	SpecGameSection.MouseButton1Click:Connect(function()
		SpecGameSection.UIStroke.Color = Color3.fromRGB(255, 255, 255)
		DefaultSection.UIStroke.Color = Color3.fromRGB(0, 0, 0)
		ScrollingFrameSpecific.Visible = true
		ScrollingFrame.Visible = false
		ScrollingFrameR15.Visible = false
	end)


	--Option Buttons
	PauseAnimsButton.MouseButton1Click:Connect(function()
		PauseAnimsOption = not PauseAnimsOption
		if PauseAnimsOption then
			if Player.Character:FindFirstChild(AnimationHandler) then
				Player.Character:FindFirstChild(AnimationHandler).Disabled = true
			end
			local playingTracks = Player.Character.Humanoid:GetPlayingAnimationTracks()
			for _, animtrack in ipairs(playingTracks) do
				if animtrack.Name ~= "AAnimation" then
					animtrack:AdjustSpeed(0)
				end
			end
		else
			if Player.Character:FindFirstChild(AnimationHandler) then
				Player.Character:FindFirstChild(AnimationHandler).Disabled = false
			end
			local playingTracks = Player.Character.Humanoid:GetPlayingAnimationTracks()
			for _, animtrack in ipairs(playingTracks) do
				if animtrack.Name ~= "AAnimation" then
					animtrack:AdjustSpeed(1) -- always playing at speed 1
				end
			end
		end
	end)

	PauseAnimateButton.MouseButton1Click:Connect(function()
		local AnimateScript = Player.Character:FindFirstChild(AnimationHandler)
		if AnimateScript.Disabled == false then
			AnimateScript.Disabled = true
			PauseAnimateButton.BackgroundColor3 = ButtonSelectCol
		else
			StopAnimsEvent:Fire("Forced")
			AnimateScript.Disabled = false
			PauseAnimateButton.BackgroundColor3 = ButtonCol
			PauseAnimsOption = false
			PauseAnimsButton.BackgroundColor3 = ButtonCol
		end
	end)

	local StopDefAnimsOption = false
	StopDefAnimsButton.MouseButton1Click:Connect(function()
		StopDefAnimsOption = not StopDefAnimsOption
		if StopDefAnimsOption then

			local playingTracks = Player.Character.Humanoid:GetPlayingAnimationTracks()
			Player.Character.Animate.Disabled = true

			for _, animtrack in ipairs(playingTracks) do
				if table.find(DefaultAnimsNameList, animtrack.Name) then
					animtrack:Stop()
				end
			end
			StopDefAnimsButton.BackgroundColor3 = ButtonSelectCol

			PauseAnimateButton.BackgroundColor3 = ButtonCol
			PauseAnimateButton.ImageTransparency = 0.5
			PauseAnimateButton.Interactable = false
		else
			StopAnimsEvent:Fire("Forced")
			Player.Character.Animate.Disabled = false
			StopDefAnimsButton.BackgroundColor3 = ButtonCol

			PauseAnimsOption = false
			PauseAnimsButton.BackgroundColor3 = ButtonCol
			PauseAnimateButton.BackgroundColor3 = ButtonCol
			PauseAnimateButton.ImageTransparency = 0
			PauseAnimateButton.Interactable = true
		end
	end)

	local AnimReversed = false
	ReversePlayButton.MouseButton1Click:Connect(function()
		AnimReversed = not AnimReversed
		if AnimReversed then
			NegativeNumber = -1
			ReversePlayButton.BackgroundColor3 = ButtonSelectCol
		else
			NegativeNumber = 1
			ReversePlayButton.BackgroundColor3 = ButtonCol
		end
	end)
	EmoteWheelButton.MouseButton1Click:Connect(function()
		EmoteWheel.Visible = true
	end)

	SitButton.MouseButton1Click:Connect(function()
		if Humanoid.Sit == false then
			Humanoid.Sit = true
		else
			Humanoid.Sit = false
		end
	end)


	--Settings buttons
	SGSNotification.MouseButton2Click:Connect(function()
		delfile(ConfigFile)
		game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Deleted", Text = "Deleted specific game settings file", Duration = 3})
	end)

	DelayNumBox:GetPropertyChangedSignal("Text"):Connect(function()
		DragDelay = tonumber(DelayNumBox.Text)
		if DelayNumBox.Text == "" then
			DragDelay = 0
		end
	end)
	local PreviewOptionButton = SettingsStuff.PreviewOption
	PreviewOptionButton.MouseButton1Click:Connect(function()
		AnimPreviewEnabled = not AnimPreviewEnabled
		if AnimPreviewEnabled == true then
			PreviewOptionButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			ViewportFrame.Visible = false
			PreviewOptionButton.CheckImage.Image = ""
		end
	end)
	local DebugInfoButton = SettingsStuff.DebugInfoOption
	AddHoverText(DebugInfoButton, "Show debug information in Developer console (Animation data and other things)")
	DebugInfoButton.MouseButton1Click:Connect(function()
		DebugInfoEnabled = not DebugInfoEnabled
		if DebugInfoEnabled == true then
			DebugInfoButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			DebugInfoButton.CheckImage.Image = ""
		end
	end)
	local AnalyticsButton = SettingsStuff.AnalyticsOption
	AddHoverText(AnalyticsButton, "<b>DISCLAIMER</b>: these analytics are made only to see NUMBER of people using my script. I don't save or even share any personal data, UserId, Username and any other data. <b>IF</b> you let AnalyticsEnabled setting enabled you will get rid of one bug where specific settings couldn't load on first script execution")
	AnalyticsButton.MouseButton1Click:Connect(function()
		AnalyticsEnabled = not AnalyticsEnabled
		if AnalyticsEnabled == true then
			AnalyticsButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			AnalyticsButton.CheckImage.Image = ""
		end
	end)
	local LoadAnimationsOnRestartButton = SettingsStuff.LoadAnimationsOnRestartOption
	AddHoverText(LoadAnimationsOnRestartButton, "Automatically plays 'Running' and 'Idle' animations you played before restarting GUI or your character reappearing")
	LoadAnimationsOnRestartButton.MouseButton1Click:Connect(function()
		LoadAnimationsOnRestart = not LoadAnimationsOnRestart
		if LoadAnimationsOnRestart == true then
			LoadAnimationsOnRestartButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			LoadAnimationsOnRestartButton.CheckImage.Image = ""
		end
	end)
	local LoadAllAnimationsOnRestartButton = SettingsStuff.LoadAllAnimationsOnRestartOption
	AddHoverText(LoadAllAnimationsOnRestartButton, "Automatically plays ALL animations you played before restarting GUI or your character reappearing")
	LoadAllAnimationsOnRestartButton.MouseButton1Click:Connect(function()
		LoadAllAnimationsOnRestart = not LoadAllAnimationsOnRestart
		if LoadAllAnimationsOnRestart == true then
			LoadAllAnimationsOnRestartButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			LoadAllAnimationsOnRestartButton.CheckImage.Image = ""
		end
	end)
	local TopMostButton = SettingsStuff.TopMostOption
	AddHoverText(TopMostButton, "When enabled, GUI will stay on top of <b>ALL</b> other windows and GUIs")
	TopMostButton.MouseButton1Click:Connect(function()
		TopMost = not TopMost
		if TopMost == true then
			Emoter.DisplayOrder = 100
			TopMostButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			Emoter.DisplayOrder = -1
			TopMostButton.CheckImage.Image = ""
		end
	end)	

	if ToolIdleAnimHighPriorEnabled or ToolActionAnimHighPriorEnabled then
		ToolAnimHighPriorEnabled = true
	else
		ToolAnimHighPriorEnabled = false
	end

	local function ToolAnimPriorityCheck()
		if ToolAnimHighPriorEnabled == true then
			local playingTracks = Player.Character:WaitForChild("Humanoid"):GetPlayingAnimationTracks()
			local anyTrue = false
			for _, ScrollFrame in ipairs(ScrollingFramesList) do
				for _, item in ipairs(ScrollFrame:GetChildren()) do
					if item:IsA("TextButton") and __SIEXTHER_VIP_GLASS_V1.Read(item, "BackgroundColor3") == ButtonSelectCol then
						anyTrue = true
						break
					end
				end
			end

			if PauseAnimsOption then
				for _, animtrack in ipairs(playingTracks) do
					if animtrack.Name ~= "AAnimation" then
						animtrack:AdjustSpeed(0)
					end
				end
			end

			if anyTrue then
				for _, animtrack in ipairs(playingTracks) do
					local animationObject = animtrack.Animation
					local IdNumberString = string.match(animationObject.AnimationId, "%d+") 

					if (table.find(ToolIdleAnimsList, animtrack.Name) or table.find(ToolIdleAnimsList, IdNumberString)) and animtrack.Name ~= "AAnimation" and ToolIdleAnimHighPriorEnabled then
						animtrack.Priority = Enum.AnimationPriority.Action4
						if HigherPriorityEnabled then
							animtrack:AdjustWeight(30000)
						end
					elseif (table.find(ToolActionAnimsList, animtrack.Name) or table.find(ToolActionAnimsList, IdNumberString)) and animtrack.Name ~= "AAnimation" and ToolActionAnimHighPriorEnabled then
						animtrack.Priority = Enum.AnimationPriority.Action4
						animtrack:AdjustWeight(10000)
						if HigherPriorityEnabled then
							animtrack:AdjustWeight(40000)
						else
							animtrack:AdjustWeight(10000)
						end
					end
				end
			else
				for _, animtrack in ipairs(playingTracks) do
					local animationObject = animtrack.Animation
					local IdNumberString = string.match(animationObject.AnimationId, "%d+") 

					if (table.find(ToolIdleAnimsList, animtrack.Name) or table.find(ToolIdleAnimsList, IdNumberString)) and animtrack.Name ~= "AAnimation" then
						animtrack.Priority = Enum.AnimationPriority.Idle
						animtrack:AdjustWeight(1)
					elseif (table.find(ToolActionAnimsList, animtrack.Name) or table.find(ToolActionAnimsList, IdNumberString)) and animtrack.Name ~= "AAnimation" then
						animtrack.Priority = Enum.AnimationPriority.Action
						animtrack:AdjustWeight(1)
					end
				end
			end
		end
	end

	local function PauseAnimation()
		if PauseAnimsOption then
			local playingTracks = Player.Character.Humanoid:GetPlayingAnimationTracks()
			for _, animtrack in ipairs(playingTracks) do
				if animtrack.Name ~= "AAnimation" then
					animtrack:AdjustSpeed(0)
				end
			end
		end
	end

	Player.Character:WaitForChild("Humanoid").AnimationPlayed:Connect(function()
		if GuiActive and GuiRestarted == false then
			ToolAnimPriorityCheck()
			PauseAnimation()
		end
	end)

	local ToolIdleAnimPriorityButton = SettingsStuff.ToolIdlePriorityOption
	AddHoverText(ToolIdleAnimPriorityButton, "Makes tool <b>Idle</b> animations play even when your animations are playing (like white list). Doesn't work for ALL games and need to be configured. More information in my <b>Github</b>")
	ToolIdleAnimPriorityButton.MouseButton1Click:Connect(function()
		ToolIdleAnimHighPriorEnabled = not ToolIdleAnimHighPriorEnabled
		if ToolIdleAnimHighPriorEnabled or ToolActionAnimHighPriorEnabled then
			ToolAnimHighPriorEnabled = true
		else
			ToolAnimHighPriorEnabled = false
		end

		if ToolIdleAnimHighPriorEnabled == true then
			ToolIdleAnimPriorityButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			ToolIdleAnimPriorityButton.CheckImage.Image = ""
		end
		ToolAnimPriorityCheck()
	end)
	local ToolActionAnimPriorityButton = SettingsStuff.ToolActionPriorityOption
	AddHoverText(ToolActionAnimPriorityButton, "Makes tool <b>Action</b> or other <b>Action</b> animations play even when your animations are playing (like white list). Doesn't work for ALL games and need to be configured. More information in my <b>Github</b>")
	ToolActionAnimPriorityButton.MouseButton1Click:Connect(function()
		ToolActionAnimHighPriorEnabled = not ToolActionAnimHighPriorEnabled
		if ToolActionAnimHighPriorEnabled or ToolIdleAnimHighPriorEnabled then
			ToolAnimHighPriorEnabled = true
		else
			ToolAnimHighPriorEnabled = false
		end

		if ToolActionAnimHighPriorEnabled == true then
			ToolActionAnimPriorityButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			ToolActionAnimPriorityButton.CheckImage.Image = ""
		end
		ToolAnimPriorityCheck()
	end)

	AddHoverText(SwitchOptionButton, "<b>Switching</b> animations instead of <b>layering</b>", SwitchAnimHotkey)
	SwitchOptionButton.MouseButton1Click:Connect(function()
		AnimSwitchModeEnabled = not AnimSwitchModeEnabled
		if AnimSwitchModeEnabled == true then
			SwitchOptionButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			SwitchOptionButton.CheckImage.Image = ""
		end
	end)

	local SwitchRunIdleExceptionOptionButton = SettingsStuff.SwitchRunIdleExceptionOption
	AddHoverText(SwitchRunIdleExceptionOptionButton, "Make an exception of Switch mode for 'Running' and 'Idle' animation types")
	SwitchRunIdleExceptionOptionButton.MouseButton1Click:Connect(function()
		AnimSwitchModeRunIdleExceptionEnabled = not AnimSwitchModeRunIdleExceptionEnabled
		if AnimSwitchModeRunIdleExceptionEnabled == true then
			SwitchRunIdleExceptionOptionButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			SwitchRunIdleExceptionOptionButton.CheckImage.Image = ""
		end
	end)

	AddHoverText(AnimFadeOptionButton, "Enables <b>FadeTime</b> of animation. If disabled, animations will play instantly", AnimFadeHotkey)
	AnimFadeOptionButton.MouseButton1Click:Connect(function()
		AnimSmoothFadeEnabled = not AnimSmoothFadeEnabled
		if AnimSmoothFadeEnabled == true then
			AnimFadeOptionButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			AnimFadeOptionButton.CheckImage.Image = ""
		end
	end)

	local HigherPriorityOptionButton = SettingsStuff.HigherPriorityOption
	AddHoverText(HigherPriorityOptionButton, "Makes animations priority <b>higher</b>. This is made for games, where developers are making some or all of their animations with <b>Action4</b> priority (the highest one). Highly <b>not recommended</b> to use if not needed, as it uses high AnimWeight to overwrite animations, Which makes animations play not very good, especially if you play more than 1 animation")
	HigherPriorityOptionButton.MouseButton1Click:Connect(function()
		HigherPriorityEnabled = not HigherPriorityEnabled
		if HigherPriorityEnabled == true then
			HigherPriorityOptionButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			HigherPriorityOptionButton.CheckImage.Image = ""
		end
	end)

	local IdleTypeOptionButton = SettingsStuff.IdleTypeOption
	AddHoverText(IdleTypeOptionButton, "Enables 'Idle' function of most of <b>idle-like</b> animations. With this function animation is playing only when your character isn't moving")
	IdleTypeOptionButton.MouseButton1Click:Connect(function()
		IdleTypeEnabled = not IdleTypeEnabled
		if IdleTypeEnabled == true then
			IdleTypeOptionButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			IdleTypeOptionButton.CheckImage.Image = ""
		end
	end)

	local RunningTypeOptionButton = SettingsStuff.RunningTypeOption
	AddHoverText(RunningTypeOptionButton, "Enables 'Running' function of most of <b>running-like</b> animations. With this function animation speed is changing depending on the character's speed, and the animations themselves stop when your character stops")
	RunningTypeOptionButton.MouseButton1Click:Connect(function()
		RunningTypeEnabled = not RunningTypeEnabled
		if RunningTypeEnabled == true then
			RunningTypeOptionButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			RunningTypeOptionButton.CheckImage.Image = ""
		end
	end)

	local RunningTypeStopStandingOptionButton = SettingsStuff.RunningTypeStopStandingOption
	AddHoverText(RunningTypeStopStandingOptionButton, "Stop animation when your character is <b>not moving (standing)</b> and play it again when your character is running")
	RunningTypeStopStandingOptionButton.MouseButton1Click:Connect(function()
		RunningTypeStopStandingEnabled = not RunningTypeStopStandingEnabled
		if RunningTypeStopStandingEnabled == true then
			RunningTypeStopStandingOptionButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			RunningTypeStopStandingOptionButton.CheckImage.Image = ""
		end
	end)

	local RunningTypeStopJumpingOptionButton = SettingsStuff.RunningTypeStopJumpingOption
	AddHoverText(RunningTypeStopJumpingOptionButton, "Stop animation when your character is <b>jumping</b> and play it again when your character is running")
	RunningTypeStopJumpingOptionButton.MouseButton1Click:Connect(function()
		RunningTypeStopJumpingEnabled = not RunningTypeStopJumpingEnabled
		if RunningTypeStopJumpingEnabled == true then
			RunningTypeStopJumpingOptionButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			RunningTypeStopJumpingOptionButton.CheckImage.Image = ""
		end
	end)

	local RunningTypeStopClimbingOptionButton = SettingsStuff.RunningTypeStopClimbingOption
	AddHoverText(RunningTypeStopClimbingOptionButton, "Stop animation when your character is <b>climbing</b> and play it again when your character is running")
	RunningTypeStopClimbingOptionButton.MouseButton1Click:Connect(function()
		RunningTypeStopClimbingEnabled = not RunningTypeStopClimbingEnabled
		if RunningTypeStopClimbingEnabled == true then
			RunningTypeStopClimbingOptionButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			RunningTypeStopClimbingOptionButton.CheckImage.Image = ""
		end
	end)

	local RunningTypeCharSpeedOptionButton = SettingsStuff.RunningTypeCharSpeedOption
	AddHoverText(RunningTypeCharSpeedOptionButton, "Change animation speed depending on your character's speed")
	RunningTypeCharSpeedOptionButton.MouseButton1Click:Connect(function()
		RunningTypeCharSpeedEnabled = not RunningTypeCharSpeedEnabled
		if RunningTypeCharSpeedEnabled == true then
			RunningTypeCharSpeedOptionButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			RunningTypeCharSpeedOptionButton.CheckImage.Image = ""
		end
	end)

	local RunningTypeMinSpeedOption = SettingsStuff.RunningTypeMinSpeedOption
	AddHoverText(RunningTypeMinSpeedOption, "Some animations uses Value for 'Running' type, like some <b>sprinting</b> animations. This Value is minimum WalkSpeed of your character needed for animation to play it. If your character's WalkSpeed is less than this minimum, animation won't play")
	RunningTypeMinSpeedOption.MouseButton1Click:Connect(function()
		RunningTypeMinSpeedEnabled = not RunningTypeMinSpeedEnabled
		if RunningTypeMinSpeedEnabled == true then
			RunningTypeMinSpeedOption.CheckImage.Image = "rbxassetid://130396712201457"
		else
			RunningTypeMinSpeedOption.CheckImage.Image = ""
		end
	end)

	HotkeysEditOption.MouseButton1Click:Connect(function()
		HotkeysFrame.Visible = not HotkeysFrame.Visible
	end)

	PurpleThemeColor.MouseButton1Click:Connect(function()
		Theme = "LightPurple"
		game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Changed theme", Text = "Changed theme to LightPurple, please restart GUI", Duration = 3})
	end)
	OrangeThemeColor.MouseButton1Click:Connect(function()
		Theme = "LightOrange"
		game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Changed theme", Text = "Changed theme to LightOrange, please restart GUI", Duration = 3})
	end)
	YellowThemeColor.MouseButton1Click:Connect(function()
		Theme = "LightYellow"
		game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Changed theme", Text = "Changed theme to LightYellow, please restart GUI", Duration = 3})
	end)
	BlackThemeColor.MouseButton1Click:Connect(function()
		Theme = "Black"
		game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Changed theme", Text = "Changed theme to Black, please restart GUI", Duration = 3})
	end)

	local UICornerOptionButton = SettingsStuff.UICornerOption
	AddHoverText(UICornerOptionButton, "Enables rounded corners in GUI")
	UICornerOptionButton.MouseButton1Click:Connect(function()
		UICornerEnabled = not UICornerEnabled
		if UICornerEnabled == true then
			UICornerOptionButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			UICornerOptionButton.CheckImage.Image = ""
		end
	end)

	local UIGradientOptionButton = SettingsStuff.UIGradientOption
	AddHoverText(UIGradientOptionButton, "Enables gradient in GUI")
	UIGradientOptionButton.MouseButton1Click:Connect(function()
		UIGradientEnabled = not UIGradientEnabled
		if UIGradientEnabled == true then
			UIGradientOptionButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			UIGradientOptionButton.CheckImage.Image = ""
		end
	end)

	X05YSixe.MouseButton1Click:Connect(function()
		YSize = 209
		MainFrame.Size = UDim2.new(0, XSize, 0, YSize)
		ScrollingFrame.Size = UDim2.new(1, 0, 1, -69)
		ScrollingFrameR15.Size = UDim2.new(1, 0, 1, -69)
		ScrollingFrameSpecific.Size = UDim2.new(1, 0, 1, -69)
	end)
	X1YSize.MouseButton1Click:Connect(function()
		YSize = 285
		MainFrame.Size = UDim2.new(0, XSize, 0, YSize)
		ScrollingFrame.Size = UDim2.new(1, 0, 1, -69)
		ScrollingFrameR15.Size = UDim2.new(1, 0, 1, -69)
		ScrollingFrameSpecific.Size = UDim2.new(1, 0, 1, -69)
	end)
	X15YSize.MouseButton1Click:Connect(function()
		YSize = 450
		MainFrame.Size = UDim2.new(0, XSize, 0, YSize)
		ScrollingFrame.Size = UDim2.new(1, 0, 1, -69)
		ScrollingFrameR15.Size = UDim2.new(1, 0, 1, -69)
		ScrollingFrameSpecific.Size = UDim2.new(1, 0, 1, -69)
	end)
	X2YSize.MouseButton1Click:Connect(function()
		YSize = 660
		MainFrame.Size = UDim2.new(0, XSize, 0, YSize)
		ScrollingFrame.Size = UDim2.new(1, 0, 1, -69)
		ScrollingFrameR15.Size = UDim2.new(1, 0, 1, -69)
		ScrollingFrameSpecific.Size = UDim2.new(1, 0, 1, -69)
	end)

	X2Size.MouseButton1Click:Connect(function()
		XSize = 240
		MainFrame.Size = UDim2.new(0, XSize, 0, YSize)
		ScrollingFrame.Size = UDim2.new(1, 0, 1, -69)
		ScrollingFrameR15.Size = UDim2.new(1, 0, 1, -69)
		ScrollingFrameSpecific.Size = UDim2.new(1, 0, 1, -69)

		ValueText.Visible = false
		if RigType == "R15" then
			Title.Text = "Emoter R15"
		else
			Title.Text = "Emoter R6"
		end
	end)
	X3Size.MouseButton1Click:Connect(function()
		XSize = 350
		MainFrame.Size = UDim2.new(0, XSize, 0, YSize)
		ScrollingFrame.Size = UDim2.new(1, 0, 1, -69)
		ScrollingFrameR15.Size = UDim2.new(1, 0, 1, -69)
		ScrollingFrameSpecific.Size = UDim2.new(1, 0, 1, -69)

		ValueText.Visible = false
		if RigType == "R15" then
			Title.Text = "Emoter GUI (R15)"
		else
			Title.Text = "Emoter GUI (R6)"
		end
	end)
	X4Size.MouseButton1Click:Connect(function()
		XSize = 460
		MainFrame.Size = UDim2.new(0, XSize, 0, YSize)
		ScrollingFrame.Size = UDim2.new(1, 0, 1, -69)
		ScrollingFrameR15.Size = UDim2.new(1, 0, 1, -69)
		ScrollingFrameSpecific.Size = UDim2.new(1, 0, 1, -69)

		ValueText.Visible = true
		if RigType == "R15" then
			Title.Text = "Emoter GUI (R15)"
		else
			Title.Text = "Emoter GUI (R6)"
		end
	end)
	X5Size.MouseButton1Click:Connect(function()
		XSize = 571
		MainFrame.Size = UDim2.new(0, XSize, 0, YSize)
		ScrollingFrame.Size = UDim2.new(1, 0, 1, -69)
		ScrollingFrameR15.Size = UDim2.new(1, 0, 1, -69)
		ScrollingFrameSpecific.Size = UDim2.new(1, 0, 1, -69)

		ValueText.Visible = true
		if RigType == "R15" then
			Title.Text = "Emoter GUI (R15)"
		else
			Title.Text = "Emoter GUI (R6)"
		end
	end)

	local HotkeysOptionButton = SettingsStuff.HotkeysOption
	HotkeysOptionButton.MouseButton1Click:Connect(function()
		HotkeysEnabled = not HotkeysEnabled

		if HotkeysEnabled == true then
			BindHotkeys()
			HotkeysOptionButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			BindHotkeys("EnableHotkeys")
			HotkeysOptionButton.CheckImage.Image = ""
		end
	end)

	local LoadGithubSGAOptionButton = SettingsStuff.LoadGithubSGAOption
	AddHoverText(LoadGithubSGAOptionButton, "Enables loading SGA (SpecificGameAnims) from Github")
	LoadGithubSGAOptionButton.MouseButton1Click:Connect(function()
		LoadGithubSGAEnabled = not LoadGithubSGAEnabled
		if LoadGithubSGAEnabled == true then
			LoadGithubSGAOptionButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			LoadGithubSGAOptionButton.CheckImage.Image = ""
		end
	end)

	local LoadGithubCustomAnimOptionButton = SettingsStuff.LoadGithubCustomAnimOption
	AddHoverText(LoadGithubCustomAnimOptionButton, "Enables loading additional animations from Github")
	LoadGithubCustomAnimOptionButton.MouseButton1Click:Connect(function()
		LoadGithubCustomAnimsEnabled = not LoadGithubCustomAnimsEnabled
		if LoadGithubCustomAnimsEnabled == true then
			LoadGithubCustomAnimOptionButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			LoadGithubCustomAnimOptionButton.CheckImage.Image = ""
		end
	end)

	local LoadLocalSGAOptionButton = SettingsStuff.LoadLocalSGAOption
	AddHoverText(LoadLocalSGAOptionButton, "Enables loading SGA (SpecificGameAnims) from your local files. More information in my <b>Github</b>")
	LoadLocalSGAOptionButton.MouseButton1Click:Connect(function()
		LoadLocalSGAEnabled = not LoadLocalSGAEnabled
		if LoadLocalSGAEnabled == true then
			LoadLocalSGAOptionButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			LoadLocalSGAOptionButton.CheckImage.Image = ""
		end
	end)

	local LoadLocalCustomAnimOptionButton = SettingsStuff.LoadLocalCustomAnimOption
	AddHoverText(LoadLocalCustomAnimOptionButton, "Enables loading additional animations from your local files. More information in my <b>Github</b>")
	LoadLocalCustomAnimOptionButton.MouseButton1Click:Connect(function()
		LoadLocalCustomAnimsEnabled = not LoadLocalCustomAnimsEnabled
		if LoadLocalCustomAnimsEnabled == true then
			LoadLocalCustomAnimOptionButton.CheckImage.Image = "rbxassetid://130396712201457"
		else
			LoadLocalCustomAnimOptionButton.CheckImage.Image = ""
		end
	end)

	local WarningDelay = false
	SaveSettingsButton.MouseButton1Click:Connect(function()
		if ConfigFile == "SiextherEmote/EmoterConfig.json" then
			SaveData("Default")
		else
			if WarningDelay == false then
				task.spawn(function()
					WarningDelay = true
					WarningText.Visible = true
					task.wait(7)
					game.TweenService:Create(WarningText, TweenInfo.new(.5, Enum.EasingStyle.Linear), {TextTransparency = 1}):Play()
					game.TweenService:Create(WarningText.UIStroke, TweenInfo.new(.5, Enum.EasingStyle.Linear), {Transparency = 1}):Play()
					wait(.5)
					WarningText.Visible = false
					WarningText.TextTransparency = 0
					WarningText.UIStroke.Transparency = 0
					WarningDelay = false
				end)
			else
				SaveData("Default")
			end
		end
		--SaveData("Default")
	end)
	SaveSettingsButton.MouseButton2Click:Connect(function()
		SaveData("Specific")
	end)

	LaunchIdDetectorButton.MouseButton1Click:Connect(function()
		__SIEXTHER_VIP_GLASS_V1.LoadString(game:HttpGet("https://raw.githubusercontent.com/Fixel656/Emoter-GUI_Roblox-Animations-Script/refs/heads/main/AnimationIdDetector.lua",true))()
	end)

	ResetButton.MouseButton1Click:Connect(function()
		print("--- Restarting Emoter GUI... ---")
		game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Restarting", Text = "Restarting Gui...", Duration = 3})
		table.clear(RestartAnimations)
		StopAnimsEvent:Fire("Reset/Destroy")
		SettingsFrame.Visible = false
		GuiRestarted = true
		BindHotkeys()
		OnRestart()
	end)

	GithubLinkButton.MouseButton1Click:Connect(function()
		setclipboard("https://github.com/Fixel656/Emoter-GUI_Roblox-Animations-Script/tree/main")
		game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Copied", Text = "Copied link to your clipboard!", Duration = 3})
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if GuiActive == false then return end

		--EmoteWheelClosing
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if EmoteWheel.Visible then
				local mousePos = UserInputService:GetMouseLocation()
				local guiObjects = Player.PlayerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y - 60)
				if not IsInStudio then
					guiObjects = game.CoreGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y - 60)
				end

				local clickedInside = false
				for _, obj in ipairs(guiObjects) do
					if obj:IsDescendantOf(EmoteWheel) or obj == EmoteWheel then
						clickedInside = true
						break
					end
				end

				if not clickedInside then
					wait()
					EmoteWheel.Visible = false
				end
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if GuiActive == false then return end

		if input.KeyCode == Enum.KeyCode.LeftAlt then
			PriorityAltPressed = true
		end
		if input.KeyCode == Enum.KeyCode.RightAlt then
			RunAltPressed = true
		end
		if input.KeyCode == Enum.KeyCode.RightControl then
			IdleAltPressed = true
		end
	end) 
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftAlt then
			PriorityAltPressed = false
		end
		if input.KeyCode == Enum.KeyCode.RightAlt then
			RunAltPressed = false
		end
		if input.KeyCode == Enum.KeyCode.RightControl then
			IdleAltPressed = false
		end
	end)

	-- EMOTES

	--[[Functions Template
	local InstanceName = Instance.new("TextButton")
	CreateAnimButton(InstanceName, "ButtonName", "ButtonText", "SFrameType (R6, R15 or Spec)", LayoutOrder)
	PlayAnim(InstanceName, "AnimId", FadeTime, AnimSpeed, "PriorityPauseRunningIdle", Looped(true/false))
	]]
	print("Adding Emotes from script...")
	--DivideFrames
	CreateDivideFrame("Dances", 1, "R6")
	CreateDivideFrame("Actions", 2, "R6")
	CreateDivideFrame("Idles & Walks", 3, "R6")
	CreateDivideFrame("Weird", 4, "R6")
	CreateDivideFrame("Attack", 5, "R6")

	CreateDivideFrame("Dances", 1, "R15")
	CreateDivideFrame("Actions", 2, "R15")
	CreateDivideFrame("Walk & Run", 3, "R15")
	CreateDivideFrame("Poses & Idles", 4, "R15")
	CreateDivideFrame("Weird", 5, "R15")
	CreateDivideFrame("Attack", 6, "R15")


	-- R6 Emotes
	local function R6Anims()
		local Dance1 = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Dance1, "Dance1", "Dance 1", "R6", 1)
		PlayAnim(Dance1, "182491037", .1, 1, "PriorLow", true)
		local Dance2 = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Dance2, "Dance2", "Dance 2", "R6", 1)
		PlayAnim(Dance2, "182436842", .1, 1, "PriorLow", true)
		local Dance3 = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Dance3, "Dance3", "Dance 3", "R6", 1)
		PlayAnim(Dance3, "182491368", .1, 1, "PriorLow", true)
		local MoonDance = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(MoonDance, "MoonDance", "Moon Dance", "R6", 1)
		PlayAnim(MoonDance, "45834924", .1, 1, "PriorLow", true)
		local SpinDance = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(SpinDance, "SpinDance", "Spin Dance", "R6", 1)
		PlayAnim(SpinDance, "429730430", .1, 1, "PriorLow", true)
		local JumpingJacks = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(JumpingJacks, "JumpingJacks", "Jumping Jacks", "R6", 1)
		PlayAnim(JumpingJacks, "429681631", .1, 1, "PriorLow", true)
		local Bang = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Bang, "Bang", "Bang", "R6", 1)
		PlayAnim(Bang, "148840371", .1, 3, "PriorLow", true)
		local MovingDance = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(MovingDance, "MovingDance", "Moving Dance", "R6", 1)
		PlayAnim(MovingDance, "429703734", .1, 1, "PriorLow", true)
		local GoofyDance = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(GoofyDance, "GoofyDance", "Goofy Dance", "R6", 1)
		PlayAnim(GoofyDance, "27789359", .1, 0.8, "PriorLow", true)
		local WeirdDance = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(WeirdDance, "WeirdDance", "Weird Dance", "R6", 1)
		PlayAnim(WeirdDance, "28488254", .1, 0.8, "PriorLow", true)
		local Laugh = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Laugh, "Laugh", "Laugh", "R6", 2)
		PlayAnim(Laugh, "129423131", .1, 1, "PriorLow", false)
		local Cheer = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Cheer, "Cheer", "Cheer", "R6", 2)
		PlayAnim(Cheer, "129423030", .1, 1, "PriorLow", false)
		local Point = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Point, "Point", "Point", "R6", 2)
		PlayAnim(Point, "128853357", .1, 1, "PriorLow", false)
		local Wave = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Wave, "Wave", "Wave", "R6", 2)
		PlayAnim(Wave, "128777973", .1, 1, "PriorLow", false)
		local Dab = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Dab, "Dab", "Dab", "R6", 2)
		PlayAnim(Dab, "248263260", .1, 1, "PriorLow", true)
		local ToolHandle = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(ToolHandle, "ToolHandle", "Tool Handle", "R6", 2)
		PlayAnim(ToolHandle, "125750867", .1, 1, "PriorHigh", true)
		local Crouch = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Crouch, "Crouch", "Crouch", "R6", 3)
		PlayAnim(Crouch, "182724289", .1, 1, "PriorLow", true)
		local Faint = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Faint, "Faint", "Faint", "R6", 3)
		PlayAnim(Faint, "181526230", .1, 1, "PriorHigh", true)
		local FloorCrawl = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(FloorCrawl, "FloorCrawl", "Floor Crawl", "R6", 3)
		PlayAnim(FloorCrawl, "282574440", .1, 1, "PriorLow", true)
		local Levitate = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Levitate, "Levitate", "Levitate", "R6", 3)
		PlayAnim(Levitate, "313762630", .1, 1, "PriorHigh", true)
		local DinoWalk = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(DinoWalk, "DinoWalk", "Dino Walk", "R6", 3)
		PlayAnim(DinoWalk, "204328711", .1, 1.5, "PriorLowRunning", true)
		local Climb = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Climb, "Climb", "Climb Walk", "R6", 3)
		PlayAnim(Climb, "125750800", .1, 1, "PriorLow", true)
		local Scared = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Scared, "Scared", "Scared", "R6", 3)
		PlayAnim(Scared, "180612465", .1, 0.3, "PriorLowPause", true)
		local FloatingHead = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(FloatingHead, "FloatingHead", "Floating Head", "R6", 3)
		PlayAnim(FloatingHead, "121572214", .1, 1, "PriorHigh", true)
		local FloatSit = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(FloatSit, "FloatSit", "Float Sit", "R6", 3)
		PlayAnim(FloatSit, "179224234", .5, 1, "PriorLow", true)
		local Spinner = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Spinner, "Spinner", "Spinner", "R6", 4)
		PlayAnim(Spinner, "188632011", .1, 2, "PriorHigh", true)
		local StrangePos = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(StrangePos, "StrangePos", "Strange Position", "R6", 4)
		PlayAnim(StrangePos, "248336459", .1, 1, "PriorLow", true)
		local HeadThrow = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(HeadThrow, "HeadThrow", "Head Throw", "R6", 4)
		PlayAnim(HeadThrow, "35154961", .1, 1, "PriorHigh", false)
		local ArmTurbine = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(ArmTurbine, "ArmTurbine", "Arm Turbine", "R6", 4)
		PlayAnim(ArmTurbine, "259438880", .1, 3, "PriorLow", true)
		local BarrelRoll = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(BarrelRoll, "BarrelRoll", "Barrel Roll", "R6", 4)
		PlayAnim(BarrelRoll, "136801964", .1, 1, "PriorLow", true)
		local MegaInsane = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(MegaInsane, "MegaInsane", "Mega Insane", "R6", 4)
		PlayAnim(MegaInsane, "184574340", .1, 40, "PriorLow", true)
		local WeirdMove = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(WeirdMove, "WeirdMove", "Weird Move", "R6", 4)
		PlayAnim(WeirdMove, "215384594", .1, 1, "PriorLow", true)
		local CloneIllusion = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(CloneIllusion, "CloneIllusion", "Clone Illusion", "R6", 4)
		PlayAnim(CloneIllusion, "215384594", .1, 1e10, "PriorLow", true)
		local Insane = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Insane, "Insane", "Insane", "R6", 4)
		PlayAnim(Insane, "33796059", .1, 1e8, "PriorLow", true)
		local FullSwing = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(FullSwing, "FullSwing", "Full Swing", "R6", 5)
		PlayAnim(FullSwing, "218504594", .1, 1, "PriorHigh", false)
		local NunchakSlash = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(NunchakSlash, "NunchakSlash", "Nunchak Slash", "R6", 5)
		PlayAnim(NunchakSlash, "204292303", .1, 1.5, "PriorLow", false)
		local FullPunch = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(FullPunch, "FullPunch", "Full Punch", "R6", 5)
		PlayAnim(FullPunch, "204062532", .1, 1.5, "PriorLow", false)
		local SwordSpin = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(SwordSpin, "SwordSpin", "Sword Spin", "R6", 5)
		PlayAnim(SwordSpin, "186934910", .1, 0.8, "PriorLow", false)
		local Punches = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Punches, "Punches", "Punches", "R6", 5)
		PlayAnim(Punches, "126753849", .1, 2, "PriorLow", false)
		local HeroJump = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(HeroJump, "HeroJump", "Hero Jump", "R6", 5)
		PlayAnim(HeroJump, "184574340", .1, 1, "PriorLow", false)
		local DoubleSlash = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(DoubleSlash, "DoubleSlash", "Double Slash", "R6", 5)
		PlayAnim(DoubleSlash, "35978879", .1, 2, "PriorLow", false)
		local SwordSwing = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(SwordSwing, "SwordSwing", "Sword Swing", "R6", 5)
		PlayAnim(SwordSwing, "32659699", .1, 1, "PriorLow", false)
	end

	--R15 Emotes
	local function R15Anims()
		local Dance1 = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Dance1, "Dance1", "Dance 1", "R15", 1)
		PlayAnim(Dance1, "507771955", .1, 1, "PriorLow", true)
		local Dance2 = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Dance2, "Dance2", "Dance 2", "R15", 1)
		PlayAnim(Dance2, "507776720", .1, 1, "PriorLow", true)
		local Dance3 = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Dance3, "Dance3", "Dance 3", "R15", 1)
		PlayAnim(Dance3, "507777451", .1, 1, "PriorLow", true)
		local FlossDance = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(FlossDance, "FlossDance", "Floss Dance", "R15", 1)
		PlayAnim(FlossDance, "10714340543", .1, 1, "PriorLow", true)
		local Monkey = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Monkey, "Monkey", "Monkey", "R15", 1)
		PlayAnim(Monkey, "10714388352", .1, 1, "PriorLow", true)
		local IWantMoneyDance = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(IWantMoneyDance, "IWantMoneyDance", "IWantMoney Dance", "R15", 1)
		PlayAnim(IWantMoneyDance, "115781688996859", .1, 1, "PriorLow", true)
		local FortniteDance = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(FortniteDance, "FortniteDance", "Fortnite Dance", "R15", 1)
		PlayAnim(FortniteDance, "88455578674030", .1, 1, "PriorLow", true)
		local GangnamStyle = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(GangnamStyle, "GangnamStyle", "Gangnam Style", "R15", 1)
		PlayAnim(GangnamStyle, "129764254213842", .1, 0.9, "PriorLow", true)
		local RussianKick = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(RussianKick, "RussianKick", "Russian Kick", "R15", 1)
		PlayAnim(RussianKick, "70653974473742", .1, 1, "PriorLow", true)
		local MannrobicsDance = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(MannrobicsDance, "MannrobicsDance", "Mannrobics Dance", "R15", 1)
		PlayAnim(MannrobicsDance, "73932117454031", .1, 1, "PriorLow", true)
		local PennywiseDance = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(PennywiseDance, "PennywiseDance", "Pennywise Dance", "R15", 1)
		PlayAnim(PennywiseDance, "138755180984581", .1, 1, "PriorLow", true)
		local BreakDance = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(BreakDance, "BreakDance", "Break Dance", "R15", 1)
		PlayAnim(BreakDance, "10214311282", .1, 1, "PriorLow", true)
		local Rambunctious = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Rambunctious, "Rambunctious", "Rambunctious", "R15", 1)
		PlayAnim(Rambunctious, "129991743366120", .1, 1, "PriorLow", true)
		local NightmailDance = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(NightmailDance, "NightmailDance", "Nightmail Dance", "R15", 1)
		PlayAnim(NightmailDance, "103655955630769", .1, 1, "PriorLow", true)
		local TennaArmDance = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(TennaArmDance, "TennaArmDance", "Tenna Arm Dance", "R15", 1)
		PlayAnim(TennaArmDance, "140315159513795", .1, 1.1, "PriorLow", true)
		local TennaSwingDance = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(TennaSwingDance, "TennaSwingDance", "Tenna Swing Dance", "R15", 1)
		PlayAnim(TennaSwingDance, "77984841414450", .1, 1, "PriorLow", true)
		local TakeTheL = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(TakeTheL, "TakeTheL", "Take The L", "R15", 1)
		PlayAnim(TakeTheL, "78870781032132", .1, 1, "PriorLow", true)
		local JumpJacks = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(JumpJacks, "JumpJacks", "Jump Jacks", "R15", 1)
		PlayAnim(JumpJacks, "10714375667", .1, 1, "PriorLow", true)

		local Wave = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Wave, "Wave", "Wave", "R15", 2)
		PlayAnim(Wave, "10714359093", .1, 1, "PriorLow", false)
		local HighWave = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(HighWave, "HighWave", "HighWave", "R15", 2)
		PlayAnim(HighWave, "10714362852", .1, 1, "PriorLow", false)
		local AwkwardWave = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(AwkwardWave, "AwkwardWave", "Awkward Wave", "R15", 2)
		PlayAnim(AwkwardWave, "86074172929360", .1, 1, "PriorLow", true)
		local Point = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Point, "Point", "Point", "R15", 2)
		PlayAnim(Point, "10714395441", .1, 1, "PriorLow", false)
		local Beckon = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Beckon, "Beckon", "Beckon", "R15", 2)
		PlayAnim(Beckon, "10713984554", .1, 1, "PriorLow", false)
		local Happy = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Happy, "Happy", "Happy", "R15", 2)
		PlayAnim(Happy, "10714352626", .1, 1, "PriorLow", false)
		local Cheer = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Cheer, "Cheer", "Cheer", "R15", 2)
		PlayAnim(Cheer, "507770677", .1, 1, "PriorLow", false)
		local Celebrate = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Celebrate, "Celebrate", "Celebrate", "R15", 2)
		PlayAnim(Celebrate, "10714016223", .1, 1, "PriorLow", false)
		local Salute = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Salute, "Salute", "Salute", "R15", 2)
		PlayAnim(Salute, "10714389988", .1, 1, "PriorLow", false)
		local Shrug = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Shrug, "Shrug", "Shrug", "R15", 2)
		PlayAnim(Shrug, "10714374484", .1, 1, "PriorLow", false)
		local Thinking = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Thinking, "Thinking", "Thinking", "R15", 2)
		PlayAnim(Thinking, "123167401858016", .1, 1, "PriorLow", false)
		local Confused = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Confused, "Confused", "Confused", "R15", 2)
		PlayAnim(Confused, "4940561610", .1, 1, "PriorLow", false)
		local Agree = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Agree, "Agree", "Agree", "R15", 2)
		PlayAnim(Agree, "10713954623", .1, 1, "PriorLow", false)
		local Disagree = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Disagree, "Disagree", "Disagree", "R15", 2)
		PlayAnim(Disagree, "10714065135", .1, 1, "PriorLow", false)
		local DolphinBang = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(DolphinBang, "DolphinBang", "Dolphin Bang", "R15", 2)
		PlayAnim(DolphinBang, "10714068222", .1, 1, "PriorLow", false)
		local Twirl = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Twirl, "Twirl", "Twirl", "R15", 2)
		PlayAnim(Twirl, "10714293450", .1, 1, "PriorLow", false)
		local HeroLanding = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(HeroLanding, "HeroLanding", "Hero Landing", "R15", 2)
		PlayAnim(HeroLanding, "10714360164", .1, 1, "PriorLow", false)
		local Shy = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Shy, "Shy", "Shy", "R15", 2)
		PlayAnim(Shy, "10714369325", .1, 1, "PriorLow", false)
		local Coward = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Coward, "Coward", "Coward", "R15", 2)
		PlayAnim(Coward, "4940563117", .1, 1, "PriorLow", false)
		local Dizzy = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Dizzy, "Dizzy", "Dizzy", "R15", 2)
		PlayAnim(Dizzy, "10714066964", .1, 1, "PriorLow", false)
		local PushUp = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(PushUp, "PushUp", "Push Ups", "R15", 2)
		PlayAnim(PushUp, "80326183054599", .1, 1, "PriorLow", true)
		local Bodybuilder = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Bodybuilder, "Bodybuilder", "Bodybuilder", "R15", 2)
		PlayAnim(Bodybuilder, "10713990381", .1, 1, "PriorLow", true)
		local Laugh = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Laugh, "Laugh", "Laugh", "R15", 2)
		PlayAnim(Laugh, "507770818", .1, 1, "PriorLow", false)
		local BigLaugh = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(BigLaugh, "BigLaugh", "Big Laugh", "R15", 2)
		PlayAnim(BigLaugh, "98974619620224", .1, 1, "PriorLow", true)
		local Bored = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Bored, "Bored", "Bored", "R15", 2)
		PlayAnim(Bored, "10713992055", .1, 1, "PriorLow", true)
		local Applaud = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Applaud, "Applaud", "Applaud", "R15", 2)
		PlayAnim(Applaud, "10713966026", .1, 1, "PriorLow", true)
		local FakeDeath = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(FakeDeath, "FakeDeath", "FakeDeath", "R15", 2)
		PlayAnim(FakeDeath, "88130117312312", .1, 1, "PriorLowPause", true)

		local Tank = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Tank, "Tank", "Tank", "R15", 3)
		PlayAnim(Tank, "115951523870527", .5, 1, "PriorLow", true)
		local RaceCar = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(RaceCar, "RaceCar", "Race Car", "R15", 3)
		PlayAnim(RaceCar, "72382226286301", .5, 1, "PriorLow", true)
		local Helicopter = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Helicopter, "Helicopter", "Helicopter", "R15", 3)
		PlayAnim(Helicopter, "76510079095692", .5, 1, "PriorLow", true)
		local CarDriving = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(CarDriving, "CarDriving", "Car Driving", "R15", 3)
		PlayAnim(CarDriving, "132471972345518", .5, 0.5, "PriorLow", true)
		local Crawl = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Crawl, "Crawl", "Crawl", "R15", 3)
		PlayAnim(Crawl, "106501741606953", .1, 1, "PriorLow", true)
		local BigBadWolf = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(BigBadWolf, "BigBadWolf", "Big Bad Wolf", "R15", 3)
		PlayAnim(BigBadWolf, "84490859002106", .1, 1, "PriorLow", true)
		local Wheel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Wheel, "Wheel", "Wheel", "R15", 3)
		PlayAnim(Wheel, "116700088132671", .1, 0.65, "PriorLowRunning", true)
		local DefaultR6Run = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(DefaultR6Run, "DefaultR6Run", "R6 Run", "R15", 3)
		PlayAnim(DefaultR6Run, "88923549940250", .1, 1, "PriorLowRunning", true)
		local MiniWalk = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(MiniWalk, "MiniWalk", "Mini Walk", "R15", 3)
		PlayAnim(MiniWalk, "85887415033585", .1, 1.3, "PriorLowRunning", true)
		local MedusaWalk = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(MedusaWalk, "MedusaWalk", "Medusa Walk", "R15", 3)
		PlayAnim(MedusaWalk, "131663132818596", .1, 1.5, "PriorLowRunning", true)
		local TallWalk = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(TallWalk, "TallWalk", "Tall Walk", "R15", 3)
		PlayAnim(TallWalk, "134010853417610", .1, 1.5, "PriorLowRunning", true)
		local ShadowRun = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(ShadowRun, "ShadowRun", "Shadow Running", "R15", 3)
		PlayAnim(ShadowRun, "82598234841035", .1, 0.8, "PriorLowRunning", true)
		local AdidasRun = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(AdidasRun, "AdidasRun", "Adidas Running", "R15", 3)
		PlayAnim(AdidasRun, "18537384940", .1, 1, "PriorLowRunning", true)
		local HappyRun = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(HappyRun, "HappyRun", "Happy Run", "R15", 3)
		PlayAnim(HappyRun, "136336776520965", .1, 1, "PriorLowRunning", true)
		local FloatingRun = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(FloatingRun, "FloatingRun", "Floating Run", "R15", 3)
		PlayAnim(FloatingRun, "98995968630900", .1, 1, "PriorLowRunning", true)
		local MotionRun = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(MotionRun, "MotionRun", "Motion Run", "R15", 3)
		PlayAnim(MotionRun, "101925097435036", .1, 1, "PriorLowRunning", true)

		local HappyIdle = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(HappyIdle, "HappyIdle", "Happy Idle", "R15", 4)
		PlayAnim(HappyIdle, "88212525150688", .1, 1, "PriorLowIdle", true)
		local MiniIdle = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(MiniIdle, "MiniIdle", "Mini Idle", "R15", 4)
		PlayAnim(MiniIdle, "82127055873357", .1, 1, "PriorLowIdle", true)
		local VibeIdle = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(VibeIdle, "VibeIdle", "Vibe Idle", "R15", 4)
		PlayAnim(VibeIdle, "99638411514722", .1, 1, "PriorLowIdle", true)
		local TallIdle = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(TallIdle, "TallIdle", "Tall Idle", "R15", 4)
		PlayAnim(TallIdle, "73645108622491", .1, 1, "PriorLowIdle", true)
		local WheelIdle = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(WheelIdle, "WheelIdle", "Wheel Idle", "R15", 4)
		PlayAnim(WheelIdle, "116700088132671", .1, 0, "PriorLowIdle", true)
		local FloatingHeadSitting = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(FloatingHeadSitting, "FloatingHeadSitting", "Floating Head Sit", "R15", 4)
		PlayAnim(FloatingHeadSitting, "111681053387222", .1, 1, "PriorLow", true)
		local FloatChillSit = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(FloatChillSit, "FloatChillSit", "Float Chill Sit", "R15", 4)
		PlayAnim(FloatChillSit, "110211186840347", .1, 0.5, "PriorLow", true)
		local FloatIdle = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(FloatIdle, "FloatIdle", "Float Idle", "R15", 4)
		PlayAnim(FloatIdle, "90055248227279", .1, 1, "PriorLowIdle", true)
		local DefaultR6Idle = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(DefaultR6Idle, "DefaultR6Idle", "R6 Idle", "R15", 4)
		PlayAnim(DefaultR6Idle, "130392105157572", .1, 1, "PriorLowIdle", true)
		local TPose = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(TPose, "TPose", "T Pose", "R15", 4)
		PlayAnim(TPose, "121655148084031", .1, 1, "PriorLow", true)
		local CrouchR15 = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(CrouchR15, "CrouchR15", "Crouch", "R15", 4)
		PlayAnim(CrouchR15, "97517127273301", .3, 1, "PriorLow", true)
		local Sitting = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Sitting, "Sitting", "Sitting", "R15", 4)
		PlayAnim(Sitting, "94763556845023", .1, 1, "PriorLow", true)
		local MM2Sit = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(MM2Sit, "MM2Sit", "MM2 Sit", "R15", 4)
		PlayAnim(MM2Sit, "130577643309726", .1, 1, "PriorLow", true)
		local Box = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Box, "Box", "Box", "R15", 4)
		PlayAnim(Box, "73753845465382", .1, 1, "PriorLow", true)
		local Sleeping = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Sleeping, "Sleeping", "Sleeping", "R15", 4)
		PlayAnim(Sleeping, "121641415206650", .5, 1, "PriorLow", true)
		local HeadJuggle = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(HeadJuggle, "HeadJuggle", "Head Juggle", "R15", 4)
		PlayAnim(HeadJuggle, "136767849845319", .1, 1, "PriorLow", true)
		local FloatingOnClouds = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(FloatingOnClouds, "FloatingOnClouds", "Floating On Clouds", "R15", 4)
		PlayAnim(FloatingOnClouds, "77840765435893", .1, 1, "PriorLow", true)
		local SitAnim = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(SitAnim, "SitAnim", "Sit Anim", "R15", 4)
		PlayAnim(SitAnim, "507768133", .1, 1, "PriorLow", true)
		local ToolHandle = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(ToolHandle, "ToolHandle", "Tool Handle", "R15", 4)
		PlayAnim(ToolHandle, "507768375", .1, 1, "PriorHigh", true)
		local FightingIdle = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(FightingIdle, "FightingIdle", "Fighting Idle", "R15", 4)
		PlayAnim(FightingIdle, "105947156749343", .1, 1, "PriorLowIdle", true)

		local JumpingSpider = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(JumpingSpider, "JumpingSpider", "Jumping Spider", "R15", 5)
		PlayAnim(JumpingSpider, "139310328821985", .1, 1, "PriorLow", true)
		local InsaneDog = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(InsaneDog, "InsaneDog", "Insane Dog", "R15", 5)
		PlayAnim(InsaneDog, "96435804447949", .1, 1, "PriorLow", true)
		local WormAnim = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(WormAnim, "WormAnim", "Worm Fly", "R15", 5)
		PlayAnim(WormAnim, "135990691658209", .3, 1, "PriorLow", true)
		local Orbit = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Orbit, "Orbit", "Orbit", "R15", 5)
		PlayAnim(Orbit, "108359356964182", .5, 1, "PriorLow", true)
		local Hanging = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Hanging, "Hanging", "Hanging", "R15", 5)
		PlayAnim(Hanging, "125662782523118", .1, 1, "PriorLow", true)
		local LaggyWalkTroll = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(LaggyWalkTroll, "LaggyWalkTroll", "Laggy Walk Troll", "R15", 5)
		PlayAnim(LaggyWalkTroll, "119199812452698", .1, 1, "PriorLow", true)
		local InchWorm = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(InchWorm, "InchWorm", "Inch Worm", "R15", 5)
		PlayAnim(InchWorm, "119096405600200", .1, 1, "PriorLow", true)
		local GoofyWiggle = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(GoofyWiggle, "GoofyWiggle", "Goofy Wiggle", "R15", 5)
		PlayAnim(GoofyWiggle, "74917195706355", .1, 1, "PriorLow", true)
		local Tornado = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Tornado, "Tornado", "Tornado", "R15", 5)
		PlayAnim(Tornado, "135373056067761", .1, 1, "PriorLow", true)
		local AdminFly = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(AdminFly, "AdminFly", "Admin Fly", "R15", 5)
		PlayAnim(AdminFly, "85063861261432", .1, 1, "PriorLow", true)
		local ObbyHead = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(ObbyHead, "ObbyHead", "Little Obbyist", "R15", 5)
		PlayAnim(ObbyHead, "115569573258316", .1, 1, "PriorLow", true)
		local Insane = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Insane, "Insane", "Insane", "R15", 5)
		PlayAnim(Insane, "93087898023268", .1, 1, "PriorLow", true)
		local GoofyFLY = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(GoofyFLY, "GoofyFLY", "Goofy FLY", "R15", 5)
		PlayAnim(GoofyFLY, "118417760427139", .1, 1, "PriorLow", true)
		local BodyPhone = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(BodyPhone, "BodyPhone", "Body Phone", "R15", 5)
		PlayAnim(BodyPhone, "73390669780316", .1, 0.8, "PriorLow", false)
		local Spin = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Spin, "Spin", "Spin", "R15", 5)
		PlayAnim(Spin, "110792133024438", .1, 1, "PriorHigh", true)
		local HyperSpin = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(HyperSpin, "HyperSpin", "Hyper Spin", "R15", 5)
		PlayAnim(HyperSpin, "125165371323590", .1, 1, "PriorLow", true)
		local SpinAround = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(SpinAround, "SpinAround", "SpinAround", "R15", 5)
		PlayAnim(SpinAround, "91004858616595", .1, 1, "PriorLow", true)
		local FloatingSpace = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(FloatingSpace, "FloatingSpace", "Floating Space", "R15", 5)
		PlayAnim(FloatingSpace, "71209604118044", .1, 1, "PriorLow", true)
		local FloatingSpace2 = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(FloatingSpace2, "FloatingSpace2", "Floating Space 2", "R15", 5)
		PlayAnim(FloatingSpace2, "70394064781064", .1, 0.5, "PriorLow", true)

		local DaHoodStomp = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(DaHoodStomp, "DaHoodStomp", "DaHood Stomp", "R15", 6)
		PlayAnim(DaHoodStomp, "92249489340640", .1, 1, "PriorLow", false)
		local QuadPunch = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(QuadPunch, "QuadPunch", "Quad Punch", "R15", 6)
		PlayAnim(QuadPunch, "139643944264511", .1, 1, "PriorLow", false)
		local TennaKick = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(TennaKick, "TennaKick", "TennaKick", "R15", 6)
		PlayAnim(TennaKick, "118139885865308", .1, 1, "PriorLow", false)
		local Dropkick = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		CreateAnimButton(Dropkick, "Dropkick", "Dropkick", "R15", 6)
		PlayAnim(Dropkick, "133566007754001", .1, 1, "PriorLow", false)
	end

	if RigType == "R6" then
		R6Anims()
	else
		R15Anims()
	end

	local CAOutput = "<b>CustomAnims:</b>\n"
	local GSGAOutput = "<b>GameSpecificAnims from Github:</b>\n"
	local LSGAOutput = "<b>GameSpecificAnims from local file:</b>\n"
	local function AddDataOperation()
		AddedDataInfo.Value = "<b>ADDED DATA FROM FILES:</b>\n\n"

		local function AdditionalAnimsOperation()
			if DebugInfoEnabled then print("[AdditionalAnims File]: Adding animations from AdditionalAnims file in Github") end
			local finalUrl = "https://raw.githubusercontent.com/Fixel656/Emoter-GUI_Roblox-Animations-Script/refs/heads/main/SpecificGameAnimations/AdditionalAnimations"
			local success, fileContent = pcall(function()
				return game:HttpGet(finalUrl)
			end)
			if not success or not fileContent or fileContent == "404: Not Found" then
				if DebugInfoEnabled then warn("[AdditionalAnims File]: AdditionalAnims file wasn't found") end
				return 
			end
			local success2, data = pcall(function()
				return HttpService:JSONDecode(fileContent)
			end)
			if not success2 or not data then
				warn("[AdditionalAnims File]: Error in JSON structure in AdditionalAnims file")
				return
			end

			for categoryName, animationsList in pairs(data) do
				if categoryName == "CustomEmotes" and #data["CustomEmotes"] ~= 0 then
					if DebugInfoEnabled then print("[AdditionalAnims File]: Extracting Animations") end
					for _, info in ipairs(animationsList) do
						local danceButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
						CreateAnimButton(danceButton, info[1], info[2], info[3], info[4])
						PlayAnim(danceButton, info[5], info[6], info[7], info[8], info[9])
					end
				elseif categoryName == "DefaultAnims" and #data["DefaultAnims"] ~= 0 then
					if DebugInfoEnabled then print("[AdditionalAnims File]: Adding Default animations")end
					for _, id in ipairs(data["DefaultAnims"]) do
						if not table.find(DefaultAnimsNameList, id) then
							table.insert(DefaultAnimsNameList, tostring(id))
						end
					end
				end
			end
			print("[AdditionalAnims File]: Loaded Data!")
		end

		local function CustomAnimsOperation()
			if DebugInfoEnabled then print("[CustomAnims File]: Searching CustomAnims file") end
			local success, fileContent = pcall(function()
				return readfile("SiextherEmote/CustomAnims.json")
			end)
			if not success or not fileContent then 
				if DebugInfoEnabled then warn("[CustomAnims File]: CustomAnims file wasn't found") end
				return 
			end
			local success2, data = pcall(function()
				return HttpService:JSONDecode(fileContent)
			end)
			if not success2 or not data then
				warn("[CustomAnims File]: Error in JSON structure in CustomAnims file")
				return
			end

			for categoryName, animationsList in pairs(data) do
				if categoryName == "CustomEmotes" and #data["CustomEmotes"] ~= 0 then
					if DebugInfoEnabled then print("[CustomAnims File]: Extracting Animations") end
					CAOutput = CAOutput.."CustomEmotes\n"
					for _, info in ipairs(animationsList) do
						local danceButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
						CreateAnimButton(danceButton, info[1], info[2], info[3], info[4])
						PlayAnim(danceButton, info[5], info[6], info[7], info[8], info[9])
					end
				elseif categoryName == "DefaultAnims" and #data["DefaultAnims"] ~= 0 then
					if DebugInfoEnabled then print("[CustomAnims File]: Adding Default animations") end
					CAOutput = CAOutput.."DefaultAnims\n"
					for _, id in ipairs(data["DefaultAnims"]) do
						if not table.find(DefaultAnimsNameList, id) then
							table.insert(DefaultAnimsNameList, tostring(id))
						end
					end
				elseif categoryName == "ToolActionAnims" and #data["ToolActionAnims"] ~= 0 then
					if DebugInfoEnabled then print("[CustomAnims File]: Adding ToolAction Animations") end
					CAOutput = CAOutput.."ToolActionAnims\n"
					for _, id in ipairs(data["ToolActionAnims"]) do
						if not table.find(ToolActionAnimsList, id) then
							table.insert(ToolActionAnimsList, tostring(id))
						end
					end
				elseif categoryName == "ToolIdleAnims" and #data["ToolIdleAnims"] ~= 0 then
					if DebugInfoEnabled then print("[CustomAnims File]: Adding ToolIdle Animations") end
					CAOutput = CAOutput.."ToolIdleAnims\n"
					for _, id in ipairs(data["ToolIdleAnims"]) do
						if not table.find(ToolIdleAnimsList, id) then
							table.insert(ToolIdleAnimsList, tostring(id))
						end
					end
				end
				if categoryName == "R6EmoteWheelEmotes" and RigType == "R6" and next(data.R6EmoteWheelEmotes) ~= nil then
					if DebugInfoEnabled then print("[SpecGameAnims File]: Adding EmoteWhell Data") end
					CAOutput = CAOutput.."EmoteWheelEmotes\n"
					local info = data["R6EmoteWheelEmotes"]
					if info.Emote1 then EmoteWheelEmotes.Emote1 = info.Emote1 end
					if info.Emote2 then EmoteWheelEmotes.Emote2 = info.Emote2 end
					if info.Emote3 then EmoteWheelEmotes.Emote3 = info.Emote3 end
					if info.Emote4 then EmoteWheelEmotes.Emote4 = info.Emote4 end
					if info.Emote5 then EmoteWheelEmotes.Emote5 = info.Emote5 end
					if info.Emote6 then EmoteWheelEmotes.Emote6 = info.Emote6 end
					if info.Emote7 then EmoteWheelEmotes.Emote7 = info.Emote7 end
					if info.Emote8 then EmoteWheelEmotes.Emote8 = info.Emote8 end
				elseif categoryName == "R15EmoteWheelEmotes" and RigType == "R15" and next(data.R15EmoteWheelEmotes) ~= nil then
					if DebugInfoEnabled then print("[SpecGameAnims File]: Adding EmoteWhell Data") end
					CAOutput = CAOutput.."EmoteWheelEmotes\n"
					local info = data["R15EmoteWheelEmotes"]
					if info.Emote1 then EmoteWheelEmotes.Emote1 = info.Emote1 end
					if info.Emote2 then EmoteWheelEmotes.Emote2 = info.Emote2 end
					if info.Emote3 then EmoteWheelEmotes.Emote3 = info.Emote3 end
					if info.Emote4 then EmoteWheelEmotes.Emote4 = info.Emote4 end
					if info.Emote5 then EmoteWheelEmotes.Emote5 = info.Emote5 end
					if info.Emote6 then EmoteWheelEmotes.Emote6 = info.Emote6 end
					if info.Emote7 then EmoteWheelEmotes.Emote7 = info.Emote7 end
					if info.Emote8 then EmoteWheelEmotes.Emote8 = info.Emote8 end
				end
			end
			print("[CustomAnims File]: Loaded Data!")
			if CAOutput ~= "<b>CustomAnims:</b> " then
				AddedDataInfo.Value = AddedDataInfo.Value..CAOutput.."\n"
			end
		end

		local function GithubSpecGameAnimsOperation()
			if DebugInfoEnabled then print("[SpecGameAnims Github]: Searching Anims file in Github for game ".. game.GameId) end

			local baseUrl = "https://raw.githubusercontent.com/Fixel656/Emoter-GUI_Roblox-Animations-Script/refs/heads/main/SpecificGameAnimations/"
			local finalUrl = baseUrl .. tostring(game.GameId)
			local success, fileContent = pcall(function()
				return game:HttpGet(finalUrl)
			end)
			if not success or not fileContent or fileContent == "404: Not Found" then
				if DebugInfoEnabled then warn("[SpecGameAnims Github]: No file in Github for this game") end
				return
			end
			local success2, data = pcall(function()
				return HttpService:JSONDecode(fileContent)
			end)
			if not success2 or not data then
				warn("[SpecGameAnims Github]: Error in JSON structure in file")
				return
			end

			for categoryName, animationsList in pairs(data) do
				if categoryName == "CustomEmotes" and #data["CustomEmotes"] ~= 0 then
					if DebugInfoEnabled then print("[SpecGameAnims Github]: Extracting Animations") end
					GSGAOutput = GSGAOutput.."CustomEmotes\n"
					for _, info in ipairs(animationsList) do
						local danceButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
						CreateAnimButton(danceButton, info[1], info[2], info[3], info[4])
						PlayAnim(danceButton, info[5], info[6], info[7], info[8], info[9])
					end
				elseif categoryName == "DefaultAnims" and #data["DefaultAnims"] ~= 0 then
					if DebugInfoEnabled then print("[SpecGameAnims Github]: Adding Default animations") end
					GSGAOutput = GSGAOutput.."DefaultAnims\n"
					for _, id in ipairs(data["DefaultAnims"]) do
						if not table.find(DefaultAnimsNameList, id) then
							table.insert(DefaultAnimsNameList, tostring(id))
						end
					end
				elseif categoryName == "ToolActionAnims" and #data["ToolActionAnims"] ~= 0 then
					if DebugInfoEnabled then print("[SpecGameAnims Github]: Adding ToolAction Animations") end
					GSGAOutput = GSGAOutput.."ToolActionAnims\n"
					for _, id in ipairs(data["ToolActionAnims"]) do
						if not table.find(ToolActionAnimsList, id) then
							table.insert(ToolActionAnimsList, tostring(id))
						end
					end
				elseif categoryName == "ToolIdleAnims" and #data["ToolIdleAnims"] ~= 0 then
					if DebugInfoEnabled then print("[SpecGameAnims Github]: Adding ToolIdle Animations") end
					GSGAOutput = GSGAOutput.."ToolIdleAnims\n"
					for _, id in ipairs(data["ToolIdleAnims"]) do
						if not table.find(ToolIdleAnimsList, id) then
							table.insert(ToolIdleAnimsList, tostring(id))
						end
					end
				elseif categoryName == "EmoteWheelEmotes" and next(data.EmoteWheelEmotes) ~= nil then
					if DebugInfoEnabled then print("[SpecGameAnims File]: Adding EmoteWhell Data") end
					GSGAOutput = GSGAOutput.."EmoteWheelEmotes\n"
					local info = data["EmoteWheelEmotes"]
					if info.Emote1 then EmoteWheelEmotes.Emote1 = info.Emote1 end
					if info.Emote2 then EmoteWheelEmotes.Emote2 = info.Emote2 end
					if info.Emote3 then EmoteWheelEmotes.Emote3 = info.Emote3 end
					if info.Emote4 then EmoteWheelEmotes.Emote4 = info.Emote4 end
					if info.Emote5 then EmoteWheelEmotes.Emote5 = info.Emote5 end
					if info.Emote6 then EmoteWheelEmotes.Emote6 = info.Emote6 end
					if info.Emote7 then EmoteWheelEmotes.Emote7 = info.Emote7 end
					if info.Emote8 then EmoteWheelEmotes.Emote8 = info.Emote8 end
				end
				if categoryName == "AdditionalData" and next(data.AdditionalData) ~= nil then
					GSGAOutput = GSGAOutput.."AdditionalData\n"
					if data["AdditionalData"].DefaultWalkSpeed then
						DefaultWalkSpeed = data["AdditionalData"].DefaultWalkSpeed
						if DebugInfoEnabled then print("Chaged DefaultWalkSpeed to "..DefaultWalkSpeed) end
					elseif data["AdditionalData"].AnimationHandlerName then
						AnimationHandler = data["AdditionalData"].AnimationHandlerName
					end
				end
			end
			print("[SpecGameAnims Github]: Loaded Data!")
			if GSGAOutput ~= "<b>GameSpecificAnims from Github:</b> " then
				AddedDataInfo.Value = AddedDataInfo.Value..GSGAOutput.."\n"
			end
		end

		local function FileSpecGameAnimsOperation()
			if DebugInfoEnabled then print("[SpecGameAnims File]: Searching Specific GameAnims file") end
			local targetNumber = tostring(game.GameId)
			local folderPath = "SiextherEmote/SpecificAnims"
			local targetFilePath = nil
			local fileFound = false

			local success, files = pcall(listfiles, folderPath)
			if not success then
				if DebugInfoEnabled then warn("[SpecGameAnims File]: Your exploit doesn't support function listfiles() or folder id empty") end
				return
			end
			for _, filePath in ipairs(files) do
				local fileName = filePath:match("[^/\\]+$") or filePath
				local extractedNumber = fileName:match("(%d+)")

				if extractedNumber then
					if DebugInfoEnabled then print("[SpecGameAnims File]: Found file: " .. fileName .. " | Extracted number: " .. extractedNumber) end
					if extractedNumber == targetNumber then
						if DebugInfoEnabled then print("[SpecGameAnims File]: Found file: " .. filePath) end
						fileFound = true
						targetFilePath = filePath
						break
					end
				end
			end
			if not fileFound then
				if DebugInfoEnabled then warn("[SpecGameAnims File]: File with number " .. targetNumber .. "hasn't found in files") end
				return
			end
			local success2, fileContent = pcall(function()
				return readfile(targetFilePath)
			end)
			if not success2 or not fileContent then
				if DebugInfoEnabled then warn("[SpecGameAnims File]: Didn't read file") end
				return
			end
			local success3, data = pcall(function()
				return HttpService:JSONDecode(fileContent)
			end)
			if not success3 or not data then
				warn("[SpecGameAnims File]: Error in JSON structure in file")
				return
			end

			for categoryName, animationsList in pairs(data) do
				if categoryName == "CustomEmotes" and #data["CustomEmotes"] ~= 0 then
					if DebugInfoEnabled then print("[SpecGameAnims File]: Extracting Animations") end
					LSGAOutput = LSGAOutput.."CustomEmotes\n"
					for _, info in ipairs(animationsList) do
						local danceButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
						CreateAnimButton(danceButton, info[1], info[2], info[3], info[4])
						PlayAnim(danceButton, info[5], info[6], info[7], info[8], info[9])
					end
				elseif categoryName == "DefaultAnims" and #data["DefaultAnims"] ~= 0 then
					if DebugInfoEnabled then print("[SpecGameAnims File]: Adding Default animations") end
					LSGAOutput = LSGAOutput.."DefaultAnims\n"
					for _, id in ipairs(data["DefaultAnims"]) do
						if not table.find(DefaultAnimsNameList, id) then
							table.insert(DefaultAnimsNameList, tostring(id))
						end
					end
				elseif categoryName == "ToolActionAnims" and #data["ToolActionAnims"] ~= 0 then
					if DebugInfoEnabled then print("[SpecGameAnims File]: Adding ToolAction Animations") end
					LSGAOutput = LSGAOutput.."ToolActionAnims\n"
					for _, id in ipairs(data["ToolActionAnims"]) do
						if not table.find(ToolActionAnimsList, id) then
							table.insert(ToolActionAnimsList, tostring(id))
						end
					end
				elseif categoryName == "ToolIdleAnims" and #data["ToolIdleAnims"] ~= 0 then
					if DebugInfoEnabled then print("[SpecGameAnims File]: Adding ToolIdle Animations") end
					LSGAOutput = LSGAOutput.."ToolIdleAnims\n"
					for _, id in ipairs(data["ToolIdleAnims"]) do
						if not table.find(ToolIdleAnimsList, id) then
							table.insert(ToolIdleAnimsList, tostring(id))
						end
					end
				elseif categoryName == "EmoteWheelEmotes" and next(data.EmoteWheelEmotes) ~= nil then
					if DebugInfoEnabled then print("[SpecGameAnims File]: Adding EmoteWhell Data") end
					LSGAOutput = LSGAOutput.."EmoteWheelEmotes\n"
					local info = data["EmoteWheelEmotes"]
					if info.Emote1 then EmoteWheelEmotes.Emote1 = info.Emote1 end
					if info.Emote2 then EmoteWheelEmotes.Emote2 = info.Emote2 end
					if info.Emote3 then EmoteWheelEmotes.Emote3 = info.Emote3 end
					if info.Emote4 then EmoteWheelEmotes.Emote4 = info.Emote4 end
					if info.Emote5 then EmoteWheelEmotes.Emote5 = info.Emote5 end
					if info.Emote6 then EmoteWheelEmotes.Emote6 = info.Emote6 end
					if info.Emote7 then EmoteWheelEmotes.Emote7 = info.Emote7 end
					if info.Emote8 then EmoteWheelEmotes.Emote8 = info.Emote8 end
				end
				if categoryName == "AdditionalData" and next(data.AdditionalData) ~= nil then
					LSGAOutput = LSGAOutput.."AdditionalData\n"
					if data["AdditionalData"].DefaultWalkSpeed then
						DefaultWalkSpeed = data["AdditionalData"].DefaultWalkSpeed
						if DebugInfoEnabled then print("Chaged DefaultWalkSpeed to "..DefaultWalkSpeed) end
					elseif data["AdditionalData"].AnimationHandlerName then
						AnimationHandler = data["AdditionalData"].AnimationHandlerName
					end
				end
			end
			print("[SpecGameAnims File]: Loaded data!")
			if LSGAOutput ~= "<b>GameSpecificAnims from local file:</b> " then
				AddedDataInfo.Value = AddedDataInfo.Value..LSGAOutput
			end
		end

		print("Adding data from files...")
		if LoadGithubCustomAnimsEnabled then
			AdditionalAnimsOperation()
		end
		if LoadLocalCustomAnimsEnabled then
			CustomAnimsOperation()
		end
		if LoadGithubSGAEnabled then
			GithubSpecGameAnimsOperation()
		end
		if LoadLocalSGAEnabled then
			FileSpecGameAnimsOperation()
		end

		if AddedDataInfo.Value ~= "<b>ADDED DATA FROM FILES:</b>\n\n" then
			DataNotification.Visible = true
		end
	end

	if not IsInStudio then
		AddDataOperation()
	end

	if DebugInfoEnabled then
		for index, id in ipairs(ToolActionAnimsList) do
			print("Position: " .. index .. " | Id: " .. id)
		end
	end

	CreateDivideFrame("Dances", 0, "Spec")
	CreateDivideFrame("Actions", 1, "Spec")
	CreateDivideFrame("Walk & Run", 2, "Spec")
	CreateDivideFrame("Poses & Idles", 3, "Spec")
	CreateDivideFrame("Weird", 4, "Spec")
	CreateDivideFrame("Attack", 5, "Spec")

	if not ScrollingFrameSpecific:FindFirstChildOfClass("TextButton") then
		DefaultSection.Visible = false
		CurrentSection = "Default"
		SpecGameSection.Size = UDim2.new(0, 33, 0, 32)
		SpecGameSection.Position = UDim2.new(1, 31, 1, -67)
		SpecGameSection.Text = "<b> ?</b>"
		local Tip = SpecGameSection:Clone()
		Tip.AutoButtonColor = false
		Tip.Parent = MainFrame
		SpecGameSection.Visible = false
		AddHoverText(Tip, "Haven't found any animations for this specific game. \nWant to add it yourself? Check out <b>Emoter's Github</b> page!")
	else
		AddHoverText(SpecGameSection, "Specific game Animations")
	end

	--Emote wheel
	local function EmoteWheelButton(Button, AnimButtonName, KeyCode, ActionName)
		local NumLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
		NumLabel.Parent = Button
		NumLabel.Size = UDim2.new(1, 0, 1, 0)
		NumLabel.BackgroundTransparency = 1
		NumLabel.TextColor3 = UiButColor
		NumLabel.Text = string.match(ActionName, "%d+")
		NumLabel.Font = Enum.Font.Roboto
		NumLabel.TextTransparency = 0.87
		NumLabel.TextScaled = true
		NumLabel.ZIndex = 100

		local prefix, suffix
		if string.match(AnimButtonName, "^R15") then
			prefix, suffix = string.match(AnimButtonName, "^(R15)(.+)$")
		elseif string.match(AnimButtonName, "^Spec") then
			prefix, suffix = string.match(AnimButtonName, "^(Spec)(.+)$")
		elseif string.match(AnimButtonName, "^R6") then
			prefix, suffix = string.match(AnimButtonName, "^(R6)(.+)$")
		end

		local AnimButton
		if prefix == "R15" then
			AnimButton = ScrollingFrameR15:FindFirstChild(suffix) or ScrollingFrameR15:FindFirstChild("Dance1")
		elseif prefix == "R6" then
			AnimButton = ScrollingFrame:FindFirstChild(suffix) or ScrollingFrame:FindFirstChild("Dance1")
		elseif prefix == "Spec" then
			AnimButton = ScrollingFrameSpecific:FindFirstChild(suffix) or ScrollingFrame:FindFirstChild("Dance1")
		end
		Button.Text = string.gsub(AnimButton.Text, "<[^>]+>", "")

		local AnimActive = false
		Button.MouseButton1Click:connect(function()
			EmoteWheel.Visible = false
			AnimActive = not AnimActive
			if AnimActive == true then
				AnimButton.BackgroundColor3 = ButtonSelectCol
			else
				AnimButton.BackgroundColor3 = ButtonCol
			end
		end)

		AnimButton.Changed:Connect(function()
			if __SIEXTHER_VIP_GLASS_V1.Read(AnimButton, "BackgroundColor3") == ButtonSelectCol then
				Button.BackgroundColor3 = ButtonSelectCol
				AnimActive = true
			else
				Button.BackgroundColor3 = ButtonCol
				AnimActive = false
			end
		end)

		local function onKeyPress(actionName, inputState, inputObject)
			if inputState == Enum.UserInputState.Begin then
				EmoteWheel.Visible = false
				AnimActive = not AnimActive
				if AnimActive == true then
					AnimButton.BackgroundColor3 = ButtonSelectCol
				else
					AnimButton.BackgroundColor3 = ButtonCol
				end
			end
			return Enum.ContextActionResult.Sink
		end

		local function updateInputHandling()
			if EmoteWheel.Visible then
				ContextActionService:BindAction(ActionName, onKeyPress, false, KeyCode)
			else
				ContextActionService:UnbindAction(ActionName)
			end
		end

		updateInputHandling()
		EmoteWheel:GetPropertyChangedSignal("Visible"):Connect(updateInputHandling)

	end
	EmoteWheelButton(Emote1, EmoteWheelEmotes.Emote1, Enum.KeyCode.One, "InterceptKey1")
	EmoteWheelButton(Emote2, EmoteWheelEmotes.Emote2, Enum.KeyCode.Two, "InterceptKey2")
	EmoteWheelButton(Emote3, EmoteWheelEmotes.Emote3, Enum.KeyCode.Three, "InterceptKey3")
	EmoteWheelButton(Emote4, EmoteWheelEmotes.Emote4, Enum.KeyCode.Four, "InterceptKey4")
	EmoteWheelButton(Emote5, EmoteWheelEmotes.Emote5, Enum.KeyCode.Five, "InterceptKey5")
	EmoteWheelButton(Emote6, EmoteWheelEmotes.Emote6, Enum.KeyCode.Six, "InterceptKey6")
	EmoteWheelButton(Emote7, EmoteWheelEmotes.Emote7, Enum.KeyCode.Seven, "InterceptKey7")
	EmoteWheelButton(Emote8, EmoteWheelEmotes.Emote8, Enum.KeyCode.Eight, "InterceptKey8")


	-- UI Decorations
	local UiCornerParts = {"SpecGameSection", "DefaultSection", "Emote1", "Emote2", "Emote3", "Emote4", "Emote5", "Emote6", "Emote7", "Emote8", "ResetButton", "CustomAnimFrame", "PlayAnimButton", "CustomAnimButton", "HotkeysEditOption", "SaveSettingsButton", "LaunchIdDetectorButton", "GithubLinkButton", "HotkeysFrame", "SettingsFrame", "SettingsButton", "GuiTopFrame", "CloseGUI", "DestroyGUI", "GuiBottomFrame", "SpeedValue", "SideFrame", "OpenGUI", "ViewportFrame", "OptionsFrame", "PauseAnimsButton", "StopDefAnimsButton", "PauseAnimateButton", "SitButton", "EmoteWheelButton", "ReversePlayButton", "SearchFrame", "SearchButton"}
	local UiStrokeParts = {"SpecGameSection", "DefaultSection", "Emote1", "Emote2", "Emote3", "Emote4", "Emote5", "Emote6", "Emote7", "Emote8", "CustomAnimFrame", "HotkeysFrame", "SettingsFrame", "GuiTopFrame", "GuiBottomFrame", "SideFrame", "ScrollingFrame", "ScrollingFrameR15", "ScrollingFrameSpecific", "OptionsFrame", "SearchFrame"}
	local UiStroke1Parts = {"ResetButton", "PlayAnimButton", "IdBox", "HotkeysEditOption", "SaveSettingsButton", "LaunchIdDetectorButton", "GithubLinkButton", "SpeedValue", "SearchBox", "PauseAnimsButton", "StopDefAnimsButton", "PauseAnimateButton", "SitButton", "EmoteWheelButton", "ReversePlayButton"}
	local UiGradientParts = {"SpecGameSection", "DefaultSection", "Emote1", "Emote2", "Emote3", "Emote4", "Emote5", "Emote6", "Emote7", "Emote8", "CustomAnimBackButton", "BackButton", "CustomAnimFrame", "PlayAnimButton", "CustomAnimButton", "SettingsButton", "GuiTopFrame", "GuiBottomFrame", "SideFrame", "SettingsButton", "DestroyGUI", "CloseGUI", "OptionsButton", "PauseAnimsButton", "StopDefAnimsButton", "PauseAnimateButton", "SitButton", "EmoteWheelButton", "ReversePlayButton", "SearchFrame", "SearchButton", "BackButton"}

	for _, UiPart in ipairs(Emoter:GetDescendants()) do
		if table.find(UiCornerParts, UiPart.Name) and UICornerEnabled then
			local UICorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
			UICorner.Parent = UiPart
			UICorner.CornerRadius = UDim.new(0, 5)
			if UiPart.Name == "GuiTopFrame" then
				UICorner.BottomRightRadius = UDim.new(0, 0)
				UICorner.BottomLeftRadius = UDim.new(0, 0)
			elseif UiPart.Name == "GuiBottomFrame" then
				UICorner.TopLeftRadius = UDim.new(0, 0)
				UICorner.TopRightRadius = UDim.new(0, 0)
			elseif UiPart.Parent == EmoteWheel then
				UICorner.CornerRadius = UDim.new(0, 20)
			end

		end

		if table.find(UiStrokeParts, UiPart.Name) or table.find(UiStroke1Parts, UiPart.Name) then
			local UIStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
			UIStroke.Parent = UiPart
			UIStroke.Thickness = 1
			UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			if table.find(UiStroke1Parts, UiPart.Name) then
				UIStroke.Thickness = 1
			end
		end

		if table.find(UiGradientParts, UiPart.Name) and UIGradientEnabled then
			local UIGradient = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient")
			UIGradient.Parent = UiPart
			UIGradient.Color = ColorSequence.new(Color3.fromRGB(207, 207, 207), Color3.fromRGB(255, 255, 255))
			UIGradient.Rotation = -90
		end
	end

	local function AddUiPadding(Part, left, right, top, bottom)
		for _, UiPart in ipairs(Emoter:GetDescendants()) do
			if UiPart.Name == Part then
				local UIPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
				UIPadding.PaddingLeft = UDim.new(0, left)
				UIPadding.PaddingRight = UDim.new(0, right)
				UIPadding.PaddingTop = UDim.new(0, top)
				UIPadding.PaddingBottom = UDim.new(0, bottom)
				UIPadding.Parent = UiPart
			end
		end
	end

	AddUiPadding("GuiBottomFrame",5,5)
	AddUiPadding("SpeedValue",2,2)
	AddUiPadding("CurAnimInfoTitle",0,0,1,5)
	AddUiPadding("ScrollingFrame",5,16,5,6)
	AddUiPadding("ScrollingFrameR15",5,16,5,6)
	AddUiPadding("ScrollingFrameSpecific",5,16,5,6)
	AddUiPadding("SearchBox",2,2)
	AddUiPadding("SettingsStuff",5,8,3,5)
	AddUiPadding("SwitchRunIdleExceptionOption", 20)
	AddUiPadding("ThemeOptionText",0,0,0,2)
	AddUiPadding("DragOptionText",0,0,0,2)
	AddUiPadding("HotkeysEditOption",0,0,0,2)
	AddUiPadding("HotkeysStuff",10,10,5,5)
	AddUiPadding("SearchFrame",2)
	AddUiPadding("IdBox",2,2)
	AddUiPadding("CustomAnimFrame",2)
	AddUiPadding("DefaultSection",6,0,2)
	AddUiPadding("SpecGameSection",6,0,2)
	AddUiPadding("Emote1",3,3,3,3)
	AddUiPadding("Emote2",3,3,3,3)
	AddUiPadding("Emote3",3,3,3,3)
	AddUiPadding("Emote4",3,3,3,3)
	AddUiPadding("Emote5",3,3,3,3)
	AddUiPadding("Emote6",3,3,3,3)
	AddUiPadding("Emote7",3,3,3,3)
	AddUiPadding("Emote8",3,3,3,3)


	--OnRestart things
	if GuiPos ~= nil then
		SideFrame.Position = GuiPos
	end
	if GuiPos ~= nil then
		MainFrame.Position = GuiPos
	end
	if GuiClosed == true then
		SideFrame.Visible = true
		MainFrame.Visible = false
		MFUIScale.Scale = 0.8
	else
		SFUIScale.Scale = 1.2
	end
	if OptionsOpened == true then
		OptionsFrame.Visible = true
		OptionsFrame.Position = UDim2.new(0.5, 0, 1, 7)
	end
	if SettingsOpened == true then
		SettingsFrame.Visible = true
	end
	if CurrentSection == "Default" then
		DefaultSection.UIStroke.Color = Color3.fromRGB(255, 255, 255)
		if RigType == "R15" then
			ScrollingFrameR15.Visible = true
		else
			ScrollingFrame.Visible = true
		end
		ScrollingFrameSpecific.Visible = false
	elseif CurrentSection == "Specific" then
		SpecGameSection.UIStroke.Color = Color3.fromRGB(255, 255, 255)
		ScrollingFrameR15.Visible = false
		ScrollingFrame.Visible = false
		ScrollingFrameSpecific.Visible = true
	end

	if ScrollingFramePos ~= nil then
		ScrollingFrame.CanvasPosition = ScrollingFramePos
		ScrollingFrameR15.CanvasPosition = ScrollingFramePos
	end
	if ScrollingFrameSpecificPos ~= nil then
		ScrollingFrameSpecific.CanvasPosition = ScrollingFrameSpecificPos
	end
	SearchBox.Text = PrevSearchText
	IdBox.Text = PrevCustomAnimId
	SpeedValue.Text = PrevAnimSpeedValue
	if XSize < 460 then
		ValueText.Visible = false
		if XSize < 350 then
			if RigType == "R15" then
				Title.Text = "Emoter R15"
			else
				Title.Text = "Emoter R6"
			end
		end
	end
	if FirstLaunch then
		game.TweenService:Create(MFUIScale, TweenInfo.new(.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Scale = 1}):Play()
	end
	
	if FirstLaunch then
		MFUIScale.Scale = 0
	end

	-- IMPORTANT: keep the entire ScreenGui disabled until the modern UI is ready.
	-- The old code enabled Emoter here, then intentionally showed SettingsFrame
	-- and HotkeysFrame for one frame with wait(), which caused the legacy GUI flash.
	Emoter.Enabled = false
	SettingsFrame.Visible = false
	HotkeysFrame.Visible = false
	if SettingsPos ~= nil then
		SettingsFrame.Position = SettingsPos
	else
		SettingsFrame.Position = MainFrame.Position + UDim2.new(0, 590, 0, 0)
	end


	-- ============================================================
	-- MODERN LIST GUI
	-- Keeps the original emote/animation functions and button
	-- connections, but replaces the visible legacy interface.
	-- ============================================================
	do
		local BG = __SIEXTHER_VIP_GLASS_V1.bgColor
		local BLUE = __SIEXTHER_VIP_GLASS_V1.primaryColor
		local CARD = __SIEXTHER_VIP_GLASS_V1.buttonColor
		local CARD_HOVER = Color3.fromRGB(40, 44, 60)
		local TEXT = __SIEXTHER_VIP_GLASS_V1.textColor
		local SUBTEXT = Color3.fromRGB(150, 158, 185)

		-- Keep all legacy objects alive because the original emote logic
		-- references several of them internally. They are simply hidden.
		for _, obj in ipairs(MainFrame:GetChildren()) do
			local n = string.lower(obj.Name or "")
			local isPreview = string.find(n, "preview", 1, true)
				or string.find(n, "viewport", 1, true)
				or obj:IsA("ViewportFrame")
			if obj:IsA("GuiObject") then
				obj.Visible = false
			end
		end
		SideFrame.Visible = false
		MainFrame.BackgroundTransparency = 1
		MainFrame.Size = UDim2.fromOffset(300, 350)
		MainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)

		local Modern = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
		Modern.Name = "ModernEmoteList"
		Modern.Parent = MainFrame
		Modern.Visible = true
		Modern.Size = UDim2.fromScale(1, 1)
		Modern.BackgroundColor3 = BG
		Modern.BorderSizePixel = 0
		Modern.ClipsDescendants = true

		local modernCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
		modernCorner.CornerRadius = UDim.new(0, 14)
		modernCorner.Parent = Modern

		local modernStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
		modernStroke.Color = BLUE
		modernStroke.Thickness = 1.5
		modernStroke.Transparency = 0.05
		modernStroke.Parent = Modern

		local Header = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
		Header.Name = "Header"
		Header.Parent = Modern
		Header.Size = UDim2.new(1, 0, 0, 46)
		Header.BackgroundTransparency = 1

		local HeaderTitle = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
		HeaderTitle.Parent = Header
		HeaderTitle.BackgroundTransparency = 1
		HeaderTitle.Position = UDim2.fromOffset(14, 5)
		HeaderTitle.Size = UDim2.new(1, -105, 0, 22)
		HeaderTitle.Font = Enum.Font.GothamBold
		HeaderTitle.Text = "SIEXTHER EMOTE"
		HeaderTitle.TextColor3 = TEXT
		HeaderTitle.TextSize = 15
		HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left

		local RigLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
		RigLabel.Parent = Header
		RigLabel.BackgroundTransparency = 1
		RigLabel.BorderSizePixel = 0
		RigLabel.Position = UDim2.fromOffset(14, 25)
		RigLabel.Size = UDim2.new(1, -105, 0, 16)
		RigLabel.Font = Enum.Font.Gotham
		RigLabel.Text = "siexther@evo:~/linux$"
		RigLabel.TextColor3 = SUBTEXT
		RigLabel.TextSize = 10
		RigLabel.TextXAlignment = Enum.TextXAlignment.Left

		local function headerButton(textValue, xOffset)
			local b = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
			b.Parent = Header
			b.AnchorPoint = Vector2.new(1, 0.5)
			b.Position = UDim2.new(1, xOffset, 0.5, 0)
			b.Size = UDim2.fromOffset(32, 32)
			b.BackgroundColor3 = CARD
			b.BorderSizePixel = 0
			b.AutoButtonColor = false
			b.Font = Enum.Font.GothamBold
			b.Text = textValue
			b.TextColor3 = TEXT
			b.TextSize = 15
			local c = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 9)
			c.Parent = b
			b.MouseEnter:Connect(function() b.BackgroundColor3 = CARD_HOVER end)
			b.MouseLeave:Connect(function() b.BackgroundColor3 = CARD end)
			return b
		end

		local Minimize = headerButton("–", -44)
		local Kill = headerButton("x", -8)
		Kill.TextSize = 13


		-- Minimal search bar
		local SearchBox = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextBox")
		SearchBox.Name = "SearchBox"
		SearchBox.Parent = Modern
		SearchBox.Position = UDim2.fromOffset(10, 51)
		SearchBox.Size = UDim2.new(1, -20, 0, 34)
		SearchBox.BackgroundColor3 = CARD
		SearchBox.BackgroundTransparency = 0.15
		SearchBox.BorderSizePixel = 0
		SearchBox.ClearTextOnFocus = false
		SearchBox.Font = Enum.Font.Gotham
		SearchBox.PlaceholderText = "  Cari Emote...."
		SearchBox.PlaceholderColor3 = SUBTEXT
		SearchBox.Text = ""
		SearchBox.TextColor3 = TEXT
		SearchBox.TextSize = 12
		SearchBox.TextXAlignment = Enum.TextXAlignment.Left

		local searchCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
		searchCorner.CornerRadius = UDim.new(0, 9)
		searchCorner.Parent = SearchBox


		local searchPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
		searchPadding.PaddingLeft = UDim.new(0, 10)
		searchPadding.PaddingRight = UDim.new(0, 10)
		searchPadding.Parent = SearchBox

		-- Reuse the ORIGINAL scrolling frame/buttons, so all PlayAnim()
		-- connections and emote logic remain untouched.
		local ActiveList = (RigType == "R15") and ScrollingFrameR15 or ScrollingFrame
		ActiveList.Parent = Modern
		ActiveList.Visible = true
		ActiveList.Position = UDim2.fromOffset(9, 94)
		ActiveList.Size = UDim2.new(1, -18, 1, -103)
		ActiveList.BackgroundTransparency = 1
		ActiveList.BorderSizePixel = 0
		ActiveList.ClipsDescendants = true
		-- Force any legacy list background/black box to be invisible.
		pcall(function() ActiveList.BackgroundColor3 = BG end)
		for _, deco in ipairs(ActiveList:GetDescendants()) do
			if deco:IsA("Frame") or deco:IsA("ImageLabel") or deco:IsA("ImageButton") then
				-- Don't touch actual emote TextButtons; only legacy decoration.
				if not deco:IsA("TextButton") then
					deco.BackgroundTransparency = 1
					if deco:IsA("ImageLabel") or deco:IsA("ImageButton") then
						deco.ImageTransparency = 1
					end
					local ds = deco:FindFirstChildOfClass("UIStroke")
					if ds then ds.Transparency = 1 end
				end
			end
		end
		ActiveList.ScrollBarThickness = 3
		ActiveList.ScrollBarImageColor3 = BLUE
		local listStroke = ActiveList:FindFirstChildOfClass("UIStroke")
		if listStroke then listStroke.Transparency = 1 end
		ActiveList.CanvasSize = UDim2.new(0, 0, 0, 0)
		ActiveList.AutomaticCanvasSize = Enum.AutomaticSize.Y

		-- Remove legacy black/background decoration from the list container.
		for _, child in ipairs(ActiveList:GetChildren()) do
			if (child:IsA("Frame") or child:IsA("ImageLabel")) and not child:IsA("TextButton") then
				child.Visible = false
			end
		end

		-- Convert old grid to a clean vertical list.
		for _, child in ipairs(ActiveList:GetChildren()) do
			if child:IsA("UIGridLayout") or child:IsA("UIListLayout") then
				child:Destroy()
			end
		end

		local ListLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
		ListLayout.Parent = ActiveList
		ListLayout.FillDirection = Enum.FillDirection.Vertical
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 7)

		local ListPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
		ListPadding.Parent = ActiveList
		ListPadding.PaddingTop = UDim.new(0, 2)
		ListPadding.PaddingBottom = UDim.new(0, 8)
		ListPadding.PaddingLeft = UDim.new(0, 2)
		ListPadding.PaddingRight = UDim.new(0, 5)

		local function modernizeEmoteButton(obj)
			if not obj:IsA("TextButton") then return end
			-- Original animation logic changes BackgroundColor3/UIStroke colors
			-- for selected/running/idle states. Normalize those states to blue.
			obj:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
				if __SIEXTHER_VIP_GLASS_V1.Read(obj, "BackgroundColor3") == ButtonSelectCol then
					obj.BackgroundColor3 = BLUE
					obj.BackgroundTransparency = 0.18
				elseif __SIEXTHER_VIP_GLASS_V1.Read(obj, "BackgroundColor3") == ButtonCol then
					obj.BackgroundColor3 = CARD
					obj.BackgroundTransparency = 0
				end
			end)
			obj.Size = UDim2.new(1, -8, 0, 34)
			obj.BackgroundColor3 = CARD
			obj.BackgroundTransparency = 0
			obj.BorderSizePixel = 0
			obj.TextColor3 = TEXT
			obj.TextSize = 13
			obj.TextScaled = false
			obj.TextXAlignment = Enum.TextXAlignment.Left
			obj.Font = Enum.Font.GothamMedium
			obj.AutoButtonColor = false

			local padding = obj:FindFirstChildOfClass("UIPadding")
			if not padding then
				padding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
				padding.Parent = obj
			end
			padding.PaddingLeft = UDim.new(0, 13)
			padding.PaddingRight = UDim.new(0, 10)

			local corner = obj:FindFirstChildOfClass("UICorner") or __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
			corner.Parent = obj
			corner.CornerRadius = UDim.new(0, 9)

			local stroke = obj:FindFirstChildOfClass("UIStroke") or __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
			stroke.Parent = obj
			stroke.Color = BLUE
			stroke.Thickness = 1
			stroke.Transparency = 0.55

			obj.MouseEnter:Connect(function()
				stroke.Color = BLUE
				if __SIEXTHER_VIP_GLASS_V1.Read(obj, "BackgroundColor3") == CARD then
					obj.BackgroundColor3 = CARD_HOVER
				end
				stroke.Transparency = 0.15
			end)
			obj.MouseLeave:Connect(function()
				stroke.Color = BLUE
				if __SIEXTHER_VIP_GLASS_V1.Read(obj, "BackgroundColor3") == CARD_HOVER then
					obj.BackgroundColor3 = CARD
				end
				if stroke.Thickness <= 1 then
					stroke.Transparency = 0.55
				end
			end)
			stroke:GetPropertyChangedSignal("Color"):Connect(function()
				if stroke.Color ~= BLUE then
					stroke.Color = BLUE
				end
			end)
		end

		for _, child in ipairs(ActiveList:GetChildren()) do
			modernizeEmoteButton(child)
		end
		ActiveList.ChildAdded:Connect(function(child)
			task.defer(function()
				modernizeEmoteButton(child)
			end)
		end)

		local function ApplySearch()
			local query = string.lower(SearchBox.Text or "")
			for _, child in ipairs(ActiveList:GetChildren()) do
				if child:IsA("TextButton") then
					child.Visible = (query == "") or string.find(string.lower(child.Text or ""), query, 1, true) ~= nil
				end
			end
		end
		SearchBox:GetPropertyChangedSignal("Text"):Connect(ApplySearch)
		ApplySearch()

		-- Floating flower shown while minimized.
		local Floating = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
		Floating.Name = "FloatingFlower"
		Floating.Parent = Emoter
		Floating.Visible = false
		Floating.Position = UDim2.new(0, 18, 0.5, -25)
		Floating.Size = UDim2.new(0, 41, 0, 41)
		Floating.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
		Floating.BorderSizePixel = 0
		Floating.Text = "🌸"
		Floating.TextSize = 20
		Floating.AutoButtonColor = false
		
		
	

		local floatCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
		floatCorner.CornerRadius = UDim.new(0, 12)
		floatCorner.Parent = Floating


		Minimize.MouseButton1Click:Connect(function()
			Modern.Visible = false
			Floating.Visible = true
		end)
		Floating.MouseButton1Click:Connect(function()
			Floating.Visible = false
			Modern.Visible = true
		end)
		Kill.MouseButton1Click:Connect(function()
			DestroyGuiFunction()
		end)

		-- Drag by the header. Fallback implementation avoids relying on
		-- UIDragDetector support in the executor.
		do
			local dragging = false
			local dragStart, startPos
			Header.Active = true
			Header.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					dragStart = input.Position
					startPos = MainFrame.Position
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch) then
					local delta = input.Position - dragStart
					MainFrame.Position = UDim2.new(
						startPos.X.Scale, startPos.X.Offset + delta.X,
						startPos.Y.Scale, startPos.Y.Offset + delta.Y
					)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
		end
		-- Remove the legacy GUI from the visible hierarchy.
		-- Objects referenced by the original emote callbacks are detached rather
		-- than destroyed, so the animation logic can still use its references.
		for _, old in ipairs(MainFrame:GetChildren()) do
			local n = string.lower(old.Name or "")
			local isPreview = string.find(n, "preview", 1, true)
				or string.find(n, "viewport", 1, true)
				or old:IsA("ViewportFrame")

			if isPreview then
				-- Keep preview alive and hidden. Existing emote hold callbacks
				-- can set Visible=true, and release callbacks can hide it again.
				if old:IsA("GuiObject") then
					old.Visible = false
				end
			elseif old ~= Modern and old ~= ActiveList and not old:IsA("UIScale") then
				old.Parent = nil
			end
		end

		-- Only the new modern MainFrame/floating flower remain under ScreenGui.
		for _, old in ipairs(Emoter:GetChildren()) do
			if old ~= MainFrame and old ~= Floating then
				old.Parent = nil
			end
		end

		-- The modern list is the only visible GUI content.
		MainFrame.BackgroundTransparency = 1
		MainFrame.Visible = true
		Modern.Visible = true
		-- Expose the ScreenGui only after the legacy interface has been removed.
		Emoter.Enabled = true
	end

	GuiEmoter = Emoter
	GuiLoaded = true
	FirstLaunch = false

	local RestartPlayer
	RestartPlayer = Player.CharacterAdded:Connect(function()
		if not GuiActive or GuiRestarted then
			RestartPlayer:Disconnect()
		end
		if GuiActive and GuiRestarted == false and Player.Character:WaitForChild("Humanoid") then
			table.clear(RestartAnimations)
			StopAnimsEvent:Fire("Reset/Destroy")
			GuiRestarted = true
			BindHotkeys()
			OnRestart()
			RestartPlayer:Disconnect()
		end
		GuiRestarted = true
	end)
	print("Script loaded!")
end

function OnRestart()
	if GuiEmoter.MainFrame.Visible == true then
		GuiClosed = false
		GuiPos = GuiEmoter.MainFrame.Position
	elseif GuiEmoter.SideFrame.Visible == true then
		GuiClosed = true
		GuiPos = GuiEmoter.SideFrame.Position
	end
	if GuiEmoter.SettingsFrame.Visible == true then
		SettingsOpened = true
	else
		SettingsOpened = false
	end
	SettingsPos = GuiEmoter.SettingsFrame.Position
	if (game:GetService"Players".LocalPlayer.Character:WaitForChild("Humanoid").RigType == Enum.HumanoidRigType.R15) then
		ScrollingFramePos = GuiEmoter.MainFrame.ScrollingFrameR15.CanvasPosition
	else
		ScrollingFramePos = GuiEmoter.MainFrame.ScrollingFrame.CanvasPosition
	end
	ScrollingFrameSpecificPos = GuiEmoter.MainFrame.ScrollingFrameSpecific.CanvasPosition
	if GuiEmoter.MainFrame.OptionsFrame.Visible == true then
		OptionsOpened = true
	else
		OptionsOpened = false
	end
	if GuiEmoter.MainFrame.ScrollingFrameR15.Visible or GuiEmoter.MainFrame.ScrollingFrame.Visible then
		CurrentSection = "Default"
	elseif GuiEmoter.MainFrame.ScrollingFrameSpecific.Visible then
		CurrentSection = "Specific"
	end

	if GuiEmoter.MainFrame.SearchFrame.SearchBox.Visible == true then
		SearchOpened = true
	else
		SearchOpened = false
	end
	if GuiEmoter.MainFrame.CustomAnimFrame.IdBox.Visible == true then
		CustomAnimOpened = true
	else
		CustomAnimOpened = false
	end
	PrevAnimSpeedValue = GuiEmoter.MainFrame.GuiBottomFrame.SpeedFrame.SpeedValue.Text
	PrevSearchText = GuiEmoter.MainFrame.SearchFrame.SearchBox.Text
	PrevCustomAnimId = GuiEmoter.MainFrame.CustomAnimFrame.IdBox.Text

	GuiEmoter:Destroy()

	local CreateGuiOk, result = pcall(function()
		return CreateGui()
	end)
	if not CreateGuiOk then
		if Emoter and not IsInStudio then
			Emoter:Destroy()
		end
		warn(result)
	end

	if DebugInfoEnabled then
		for index, id in ipairs(RestartAnimations) do
			print("Restored: "..id)
		end
	end
end


--Launching the whole thing
local CreateGuiOk, result = pcall(function()
	return CreateGui()
end)
if not CreateGuiOk then
	if Emoter and not IsInStudio then
		Emoter:Destroy()
	end
	
else

	if LastUsedVersion < ScriptVersion then
	
	end
end
if not IsInStudio then
	-- First execution may not have a config yet. Save defaults first.
	if type(makefolder) == "function" then
		pcall(makefolder, "EmoterData")
		pcall(makefolder, "SiextherEmote/SpecificSettings")
	end
	if type(isfile) == "function" and not isfile("SiextherEmote/EmoterConfig.json") then
		pcall(function() SaveData("Default") end)
	else
		pcall(function() SaveData("Update") end)
	end
end
