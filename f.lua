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
pcall(function()

if not game.Players.LocalPlayer.Character or game.Players.LocalPlayer.Character:WaitForChild("Humanoid").RigType ~= Enum.HumanoidRigType.R15 then 
    game.StarterGui:SetCore("SendNotification", {Title = "R6", Text = "Kamu pakai R6, Silahkan Ganti ke R15!", Duration = 60})
    return end

local st = os.clock()
local TweenService = game:GetService("TweenService")
cloneref = cloneref or function(o) return o end
local GazeGoGui = cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui") or game.Players.LocalPlayer:WaitForChild("PlayerGui")

local Notifbro = {}

function Notify(titletxt, text, time)
    coroutine.wrap(function()
        local GUI = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
        local Main = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame", GUI)
        local title = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel", Main)
        local message = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel", Main)

        GUI.Name = "BackgroundNotif"
        GUI.Parent = GazeGoGui

        local sw = workspace.CurrentCamera.ViewportSize.X
        local sh = workspace.CurrentCamera.ViewportSize.Y
        local nh = sh / 7
        local nw = sw / 5

        Main.Name = "MainFrame"
        Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        Main.BackgroundTransparency = 0
        Main.BorderSizePixel = 0
        Main.Size = UDim2.new(0, nw, 0, nh)

        title.BackgroundColor3 = Color3.new(0, 0, 0)
        title.BackgroundTransparency = 0.9
        title.Size = UDim2.new(1, 0, 0, nh / 2)
        title.Font = Enum.Font.GothamBold
        title.Text = titletxt
        title.TextColor3 = Color3.new(1, 1, 1)
        title.TextScaled = true

        message.BackgroundColor3 = Color3.new(0, 0, 0)
        message.BackgroundTransparency = 1
        message.Position = UDim2.new(0, 0, 0, nh / 2)
        message.Size = UDim2.new(1, 0, 1, -nh / 2)
        message.Font = Enum.Font.Gotham
        message.Text = text
        message.TextColor3 = Color3.new(1, 1, 1)
        message.TextScaled = true

        local offset = 50
        for _, notif in ipairs(Notifbro) do
            offset = offset + notif.Size.Y.Offset + 10
        end

        Main.Position = UDim2.new(1, 5, 0, offset)
        table.insert(Notifbro, Main)

        task.wait(0.1)
        Main:TweenPosition(UDim2.new(1, -nw, 0, offset), Enum.EasingDirection.Out, Enum.EasingStyle.Bounce, 0.5, true)
        Main:TweenSize(UDim2.new(0, nw * 1.06, 0, nh * 1.06), Enum.EasingDirection.Out, Enum.EasingStyle.Elastic, 0.5, true)
        task.wait(0.1)
        Main:TweenSize(UDim2.new(0, nw, 0, nh), Enum.EasingDirection.Out, Enum.EasingStyle.Elastic, 0.2, true)

        task.wait(time)

        Main:TweenSize(UDim2.new(0, nw * 1.06, 0, nh * 1.06), Enum.EasingDirection.In, Enum.EasingStyle.Elastic, 0.2, true)
        task.wait(0.2)
        Main:TweenSize(UDim2.new(0, nw, 0, nh), Enum.EasingDirection.In, Enum.EasingStyle.Elastic, 0.2, true)
        task.wait(0.2)
        Main:TweenPosition(UDim2.new(1, 5, 0, offset), Enum.EasingDirection.In, Enum.EasingStyle.Bounce, 0.5, true)
        task.wait(0.1)

        GUI:Destroy()
        for i, notif in ipairs(Notifbro) do
            if notif == Main then
                table.remove(Notifbro, i)
                break
            end
        end

        for i, notif in ipairs(Notifbro) do
            local newOffset = 50 + (nh + 10) * (i - 1)
            notif:TweenPosition(UDim2.new(1, -nw, 0, newOffset), Enum.EasingDirection.Out, Enum.EasingStyle.Bounce, 0.5, true)
        end
    end)() 
end

task.wait(0.1)

local guiName = "Hann.Siexther"

if GazeGoGui:FindFirstChild(guiName) then
    Notify("TERJADI MASALAH","SUDAH AKTIF", 1)
    return
end

local screenGui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
screenGui.Name = guiName
screenGui.Parent = GazeGoGui

local screenGuiContainer = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
screenGuiContainer.Name = "DraggableGui"
screenGuiContainer.Parent = cloneref(game.CoreGui)

local camera = workspace.CurrentCamera 

local function getScaledSize(relativeWidth, relativeHeight)
    local viewportSize = camera.ViewportSize
    return UDim2.new(0, viewportSize.X * relativeWidth, 0, viewportSize.Y * relativeHeight)
end

-- MAIN FRAME (GUI diperbesar dan lebih tinggi)
local frame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
frame.Name = "HANN.SIEXTHER"
frame.Size = getScaledSize(0.36, 0.78)  -- Lebih tinggi lagi (78% layar)
frame.Position = UDim2.new(0.5, -frame.Size.X.Offset / 2, 0.5, -frame.Size.Y.Offset / 2)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
frame.BackgroundTransparency = 0
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = false
frame.Parent = screenGuiContainer

local frameStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(70, 130, 255)
frameStroke.Thickness = 2
frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
frameStroke.Parent = frame

local frameCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = frame

-- HEADER BAR
local headerBar = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
headerBar.Name = "HeaderBar"
headerBar.Size = UDim2.new(1, 0, 0, 35)
headerBar.Position = UDim2.new(0, 0, 0, 0)
headerBar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
headerBar.BorderSizePixel = 0
headerBar.Parent = frame

local headerCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = headerBar

local headerMask = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
headerMask.Name = "HeaderMask"
headerMask.Size = UDim2.new(1, 0, 0.5, 0)
headerMask.Position = UDim2.new(0, 0, 0.5, 0)
headerMask.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
headerMask.BorderSizePixel = 0
headerMask.Parent = headerBar

-- TITLE LABEL
local titleLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Text = "SIEXTHER ANIMATED"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.BackgroundTransparency = 1
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = headerBar

-- CLOSE BUTTON
local closeButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Parent = headerBar
closeButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Size = UDim2.new(0, 25, 0, 25)
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -5, 0.5, 0)
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 17
closeButton.ZIndex = 2

local closeCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

-- MINIMIZE BUTTON
local minimizeButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
minimizeButton.Name = "MinimizeButton"
minimizeButton.Parent = headerBar
minimizeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
minimizeButton.BorderSizePixel = 0
minimizeButton.Size = UDim2.new(0, 25, 0, 25)
minimizeButton.AnchorPoint = Vector2.new(1, 0.5)
minimizeButton.Position = UDim2.new(1, -35, 0.5, 0)
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.Text = "–"
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.TextSize = 16
minimizeButton.ZIndex = 2

local minCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minimizeButton

-- DRAGGING FUNCTIONALITY (Untuk seluruh frame)
local UserInputService = game:GetService("UserInputService")
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- FLOATING BUTTON
local floatingButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
floatingButton.Name = "FloatingButton"
floatingButton.Text = "🌸"
floatingButton.TextSize = 20
floatingButton.Font = Enum.Font.GothamBold
floatingButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
floatingButton.BorderSizePixel = 0
floatingButton.Size = UDim2.new(0, 41, 0, 41)
floatingButton.Position = UDim2.new(0, 10, 0.5, -30)
floatingButton.Visible = false
floatingButton.Active = true
floatingButton.Draggable = true
floatingButton.Parent = screenGuiContainer

local floatCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(0, 12)
floatCorner.Parent = floatingButton

-- SEARCH BAR
local searchBar = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextBox")
searchBar.Name = "SearchBar"
searchBar.Text = ""
searchBar.PlaceholderText = "Search animations..."
searchBar.Font = Enum.Font.Gotham
searchBar.TextSize = 12
searchBar.TextColor3 = Color3.fromRGB(220, 220, 220)
searchBar.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
searchBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
searchBar.BorderSizePixel = 0
searchBar.Size = UDim2.new(0.94, 0, 0, 32)
searchBar.Position = UDim2.new(0.03, 0, 0, 45)
searchBar.ClearTextOnFocus = true
searchBar.Parent = frame

local searchCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 8)
searchCorner.Parent = searchBar

-- CATEGORY CONTAINER (Grid Layout - Lebih compact)
local categoryFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
categoryFrame.Name = "CategoryFrame"
categoryFrame.Size = UDim2.new(0.94, 0, 0, 50)  -- 2 baris
categoryFrame.Position = UDim2.new(0.03, 0, 0, 85)
categoryFrame.BackgroundTransparency = 1
categoryFrame.Parent = frame

local categoryGrid = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGridLayout")
categoryGrid.CellSize = UDim2.new(0, 62, 0, 22)  -- Lebih kecil dan compact
categoryGrid.CellPadding = UDim2.new(0, 4, 0, 4)
categoryGrid.FillDirection = Enum.FillDirection.Horizontal
categoryGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left
categoryGrid.SortOrder = Enum.SortOrder.LayoutOrder
categoryGrid.Parent = categoryFrame

-- SCROLL FRAME (Lebih tinggi)
local scrollFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScrollingFrame")
scrollFrame.Name = "ScrollFrame"
scrollFrame.Size = UDim2.new(0.94, 0, 0, frame.AbsoluteSize.Y - 148)  -- Lebih panjang
scrollFrame.Position = UDim2.new(0.03, 0, 0, 143)
scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 5
scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y 
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarImageTransparency = 0.3
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
scrollFrame.Parent = frame

local scrollCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 8)
scrollCorner.Parent = scrollFrame

-- Variables
local buttons = {}
local currentCategory = "All"

-- Category Buttons (Compact size)
local categories = {"All", "Idle", "Walk", "Run", "Jump", "Fall", "Climb", "Swim"}

local function createCategoryButton(name, order)
    local btn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    btn.Name = name .. "Cat"
    btn.Text = name
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 9  -- Lebih kecil
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order
    btn.Parent = categoryFrame
    
    local btnCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        currentCategory = name
        for _, child in pairs(categoryFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
                child.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
        end
        btn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        local order = 0
        for _, button in ipairs(buttons) do
            local buttonType = button:GetAttribute("AnimType")
            if currentCategory == "All" or buttonType == currentCategory then
                button.Visible = true
                button.Position = UDim2.new(0, 4, 0, order * 30)  -- Spacing lebih kecil
                order = order + 1
            else
                button.Visible = false
            end
        end
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, order * 30 + 10)
    end)
    
    return btn
end

-- Create category buttons
for i, cat in ipairs(categories) do
    createCategoryButton(cat, i)
end

-- Set "All" as default selected
local allBtn = categoryFrame:FindFirstChild("AllCat")
if allBtn then
    allBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    allBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end

-- Create Animation Button Function (Compact)
local function createTheButton(text, animType, callback)
    local button = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    button.Text = text
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 10  -- Lebih kecil
    button.TextColor3 = Color3.fromRGB(230, 230, 230)
    button.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    button.Size = UDim2.new(1, -8, 0, 26)  -- Lebih kecil
    button.Position = UDim2.new(1, 0, 0, #buttons * 30)
    button.BackgroundTransparency = 1 
    button.BorderSizePixel = 0
    button:SetAttribute("AnimType", animType)
    button.Parent = scrollFrame

    local buttonCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = button

    button.MouseButton1Click:Connect(callback)
    
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 130, 255)}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 38)}):Play()
    end)
    
    local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local goal = {
        Position = UDim2.new(0, 4, 0, #buttons * 30),
        BackgroundTransparency = 0 
    }
    local tween = TweenService:Create(button, tweenInfo, goal)
    tween:Play()

    table.insert(buttons, button)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #buttons * 30 + 10)
end

-- Search Functionality
searchBar:GetPropertyChangedSignal("Text"):Connect(function()
    local searchText = searchBar.Text:lower()
    local order = 0
    for _, button in ipairs(buttons) do
        local buttonType = button:GetAttribute("AnimType")
        local matchesCategory = currentCategory == "All" or buttonType == currentCategory
        local matchesSearch = searchText == "" or button.Text:lower():find(searchText)
        
        if matchesCategory and matchesSearch then
            button.Visible = true
            button.Position = UDim2.new(0, 4, 0, order * 30)
            order = order + 1
        else
            button.Visible = false
        end
    end
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, order * 30 + 10)
end)

-- Minimize/Maximize Functionality
local isMinimized = false

minimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        frame.Visible = false
        floatingButton.Visible = true
    else
        frame.Visible = true
        floatingButton.Visible = false
    end
end)

floatingButton.MouseButton1Click:Connect(function()
    isMinimized = false
    frame.Visible = true
    floatingButton.Visible = false
end)

-- Close Functionality
closeButton.MouseButton1Click:Connect(function()
    screenGuiContainer:Destroy()
    screenGui:Destroy()
end)

-- Hover Effects
closeButton.MouseEnter:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 70, 70)}):Play()
end)

closeButton.MouseLeave:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 50, 50)}):Play()
end)

minimizeButton.MouseEnter:Connect(function()
    TweenService:Create(minimizeButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 90, 105)}):Play()
end)

minimizeButton.MouseLeave:Connect(function()
    TweenService:Create(minimizeButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 75)}):Play()
end)

floatingButton.MouseEnter:Connect(function()
    TweenService:Create(floatingButton, TweenInfo.new(0.2), {Size = UDim2.new(0, 65, 0, 65)}):Play()
end)

floatingButton.MouseLeave:Connect(function()
    TweenService:Create(floatingButton, TweenInfo.new(0.2), {Size = UDim2.new(0, 60, 0, 60)}):Play()
end)

-- REST OF YOUR ORIGINAL CODE (Animation logic, functions, etc.)
local CurrentIdle = "None"
local CurrentWalk = "None"
local CurrentRun = "None"
local CurrentJump = "None"
local CurrentFall = "None"
local CurrentSwimIdle = "None"
local CurrentSwim = "None"
local CurrentClimb = "None"
local HttpService = game:GetService("HttpService")

local Players = game:GetService("Players")
local speaker = Players.LocalPlayer
local Char = speaker.Character
local Animate = Char.Animate

local function Wait1()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:wait(0.1)
    local humanoid = character:WaitForChild("Humanoid")
    while humanoid.Health <= 2 do
        task.wait(0.3) 
    end
end

local function Wait2()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:wait(0.1)
    local humanoid = character:WaitForChild("Humanoid")
    while humanoid:GetState() == Enum.HumanoidStateType.Dead or 
          humanoid:GetState() == Enum.HumanoidStateType.Ragdoll do
        task.wait(0.3)  
    end
end

local lastAnimations = {} 

local function StopAnim()
    local speaker = Players.LocalPlayer
    local Char = speaker.Character or speaker.CharacterAdded:Wait()
    local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")

    if Hum then
        for _, track in ipairs(Hum:GetPlayingAnimationTracks()) do
            track:Stop(0)
        end
    end
end

local function refresh()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:wait(0.1)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
end

local function refreshswim()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:wait(0.1)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    task.wait(0.1)
    humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
end

local function refreshclimb()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:wait(0.1)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    task.wait(0.1)
    humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
end

task.wait(0.1)

local Animations = {
    ["Idle"] = {
        ["Adidas Aura"] = {"110211186840347", "114191137265065"},
        ["2016 Animation (mm2)"] = {"387947158", "387947464"},
        ["(UGC) Oh Really?"] = {"98004748982532", "98004748982532"},
        ["Astronaut"] = {"891621366", "891633237"},
        ["Adidas Community"] = {"122257458498464", "102357151005774"},
        ["Bold"] = {"16738333868", "16738334710"},
        ["(UGC) Slasher"] = {"140051337061095", "140051337061095"},
        ["(UGC) Retro"] = {"80479383912838", "80479383912838"},
        ["(UGC) Magician"] = {"139433213852503", "139433213852503"},
        ["(UGC) John Doe"] = {"72526127498800", "72526127498800"},
        ["(UGC) Noli"] = {"139360856809483", "139360856809483"},
        ["(UGC) Coolkid"] = {"95203125292023", "95203125292023"},
        ["(UGC) Survivor Injured"] = {"73905365652295", "73905365652295"},
        ["(UGC) Retro Zombie"] = {"90806086002292", "90806086002292"},
        ["(UGC) 1x1x1x1"] = {"76780522821306", "76780522821306"},
        ["Borock"] = {"3293641938", "3293642554"},
        ["Bubbly"] = {"910004836", "910009958"},
        ["Cartoony"] = {"742637544", "742638445"},
        ["Confident"] = {"1069977950", "1069987858"},
        ["Catwalk Glam"] = {"133806214992291","94970088341563"},
        ["Cowboy"] = {"1014390418", "1014398616"},
        ["Drooling Zombie"] = {"3489171152", "3489171152"},
        ["Elder"] = {"10921101664", "10921102574"},
        ["Ghost"] = {"616006778","616008087"},
        ["Knight"] = {"657595757", "657568135"},
        ["Levitation"] = {"616006778", "616008087"},
        ["Mage"] = {"707742142", "707855907"},
        ["MrToilet"] = {"4417977954", "4417978624"},
        ["Ninja"] = {"656117400", "656118341"},
        ["NFL"] = {"92080889861410", "74451233229259"},
        ["OldSchool"] = {"10921230744", "10921232093"},
        ["Patrol"] = {"1149612882", "1150842221"},
        ["Pirate"] = {"750781874", "750782770"},
        ["Default Retarget"] = {"95884606664820", "95884606664820"},
        ["Very Long"] = {"18307781743", "18307781743"},
        ["Sway"] = {"560832030", "560833564"},
        ["Popstar"] = {"1212900985", "1150842221"},
        ["Princess"] = {"941003647", "941013098"},
        ["R6"] = {"12521158637","12521162526"},
        ["R15 Reanimated"] = {"4211217646", "4211218409"},
        ["Realistic"] = {"17172918855", "17173014241"},
        ["Robot"] = {"616088211", "616089559"},
        ["Sneaky"] = {"1132473842", "1132477671"},
        ["Sports (Adidas)"] = {"18537376492", "18537371272"},
        ["Soldier"] = {"3972151362", "3972151362"},
        ["Stylish"] = {"616136790", "616138447"},
        ["Stylized Female"] = {"4708191566", "4708192150"},
        ["Superhero"] = {"10921288909", "10921290167"},
        ["Toy"] = {"782841498", "782845736"},
        ["Udzal"] = {"3303162274", "3303162549"},
        ["Vampire"] = {"1083445855", "1083450166"},
        ["Werewolf"] = {"1083195517", "1083214717"},
        ["Wicked (Popular)"] = {"118832222982049", "76049494037641"},
        ["No Boundaries (Walmart)"] = {"18747067405", "18747063918"},
        ["Zombie"] = {"616158929", "616160636"},
        ["(UGC) Zombie"] = {"77672872857991", "77672872857991"},
        ["(UGC) TailWag"] = {"129026910898635", "129026910898635"}
    },
    ["Walk"] = {
            ["Amazon Unboxed"] = "90478085024465",
              ["Adidas Aura"] = "83842218823011",
        ["Gojo"] = "95643163365384",
        ["Geto"] = "85811471336028",
        ["Astronaut"] = "891667138",
        ["(UGC) Zombie"] = "113603435314095",
        ["Adidas Community"] = "122150855457006",
        ["Bold"] = "16738340646",
        ["Bubbly"] = "910034870",
        ["(UGC) Smooth"] = "76630051272791",
        ["Cartoony"] = "742640026",
        ["Confident"] = "1070017263",
        ["Cowboy"] = "1014421541",
        ["(UGC) Retro"] = "107806791584829",
        ["(UGC) Retro Zombie"] = "140703855480494",
        ["Catwalk Glam"] = "109168724482748",
        ["Drooling Zombie"] = "3489174223",
        ["Elder"] = "10921111375",
        ["Ghost"] = "616013216",
        ["Knight"] = "10921127095",
        ["Levitation"] = "616013216",
        ["Mage"] = "707897309",
        ["Ninja"] = "656121766",
        ["NFL"] = "110358958299415",
        ["OldSchool"] = "10921244891",
        ["Patrol"] = "1151231493",
        ["Pirate"] = "750785693",
        ["Default Retarget"] = "115825677624788",
        ["Popstar"] = "1212980338",
        ["Princess"] = "941028902",
        ["R6"] = "12518152696",
        ["R15 Reanimated"] = "4211223236",
        ["2016 Animation (mm2)"] = "387947975",
        ["Robot"] = "616095330",
        ["Sneaky"] = "1132510133",
        ["Sports (Adidas)"] = "18537392113",
        ["Stylish"] = "616146177",
        ["Stylized Female"] = "4708193840",
        ["Superhero"] = "10921298616",
        ["Toy"] = "782843345",
        ["Udzal"] = "3303162967",
        ["Vampire"] = "1083473930",
        ["Werewolf"] = "1083178339",
        ["Wicked (Popular)"] = "92072849924640",
        ["No Boundaries (Walmart)"] = "18747074203",
        ["Zombie"] = "616168032"
    },
    ["Run"] = {
       ["Amazon Unboxed"] = "134824450619865",
       ["Adidas Aura"] = "118320322718866",
        ["Billie Elish"] = "107895705891639",
        ["2016 Animation (mm2)"] = "387947975",
        ["(UGC) Soccer"] = "116881956670910",
        ["Adidas Community"] = "82598234841035",
        ["Astronaut"] = "10921039308",
        ["Bold"] = "16738337225",
        ["Bubbly"] = "10921057244",
        ["Cartoony"] = "10921076136",
        ["(UGC) Dog"] = "130072963359721",
        ["Confident"] = "1070001516",
        ["(UGC) Pride"] = "116462200642360",
        ["(UGC) Retro"] = "107806791584829",
        ["(UGC) Retro Zombie"] = "140703855480494", 
        ["Cowboy"] = "1014401683",
        ["Catwalk Glam"] = "81024476153754",
        ["Drooling Zombie"] = "3489173414",
        ["Elder"] = "10921104374",
        ["Ghost"] = "616013216",
        ["Heavy Run (Udzal / Borock)"] = "3236836670",
        ["Knight"] = "10921121197",
        ["Levitation"] = "616010382",
        ["Mage"] = "10921148209",
        ["MrToilet"] = "4417979645",
        ["Ninja"] = "656118852",
        ["NFL"] = "117333533048078",
        ["OldSchool"] = "10921240218",
        ["Patrol"] = "1150967949",
        ["Pirate"] = "750783738",
        ["Default Retarget"] = "102294264237491",
        ["Popstar"] = "1212980348",
        ["Princess"] = "941015281",
        ["R6"] = "12518152696",
        ["R15 Reanimated"] = "4211220381",
        ["Robot"] = "10921250460",
        ["Sneaky"] = "1132494274",
        ["Sports (Adidas)"] = "18537384940",
        ["Stylish"] = "10921276116",
        ["Stylized Female"] = "4708192705",
        ["Superhero"] = "10921291831",
        ["Toy"] = "10921306285",
        ["Vampire"] = "10921320299",
        ["Werewolf"] = "10921336997",
        ["Wicked (Popular)"] = "72301599441680",
        ["No Boundaries (Walmart)"] = "18747070484",
        ["Zombie"] = "616163682"
    },
    ["Jump"] = {
           ["Amazon Unboxed"] = "121454505477205",
                         ["Adidas Aura"] = "109996626521204",
                                 ["Billie Elish"] = "114806832298003",
        ["Astronaut"] = "891627522",
        ["Adidas Community"] = "75290611992385",
        ["Bold"] = "16738336650",
        ["Bubbly"] = "910016857",
        ["Cartoony"] = "742637942",
        ["Catwalk Glam"] = "116936326516985",
        ["Confident"] = "1069984524",
        ["Cowboy"] = "1014394726",
        ["Elder"] = "10921107367",
        ["Ghost"] = "616008936",
        ["Knight"] = "910016857",
        ["Levitation"] = "616008936",
        ["Mage"] = "10921149743",
        ["Ninja"] = "656117878",
        ["NFL"] = "119846112151352",
        ["OldSchool"] = "10921242013",
        ["Patrol"] = "1148811837",
        ["Pirate"] = "750782230",
        ["(UGC) Retro"] = "139390570947836",
        ["Default Retarget"] = "117150377950987",
        ["Popstar"] = "1212954642",
        ["Princess"] = "941008832",
        ["Robot"] = "616090535",
        ["R15 Reanimated"] = "4211219390",
        ["R6"] = "12520880485",
        ["Sneaky"] = "1132489853",
        ["Sports (Adidas)"] = "18537380791",
        ["Stylish"] = "616139451",
        ["Stylized Female"] = "4708188025",
        ["Superhero"] = "10921294559",
        ["Toy"] = "10921308158",
        ["Vampire"] = "1083455352",
        ["Werewolf"] = "1083218792",
        ["Wicked (Popular)"] = "104325245285198",
        ["No Boundaries (Walmart)"] = "18747069148",
        ["Zombie"] = "616161997"
    },
    ["Fall"] = {
           ["Amazon Unboxed"] = "94788218468396",
        ["Astronaut"] = "891617961",
                      ["Adidas Aura"] = "95603166884636",
                  ["Billie Elish"] = "132771121298158",
        ["Adidas Community"] = "98600215928904",
        ["Bold"] = "16738333171",
        ["Bubbly"] = "910001910",
        ["Cartoony"] = "742637151",
        ["Catwalk Glam"] = "92294537340807",
        ["Confident"] = "1069973677",
        ["Cowboy"] = "1014384571",
        ["Elder"] = "10921105765",
        ["Knight"] = "10921122579",
        ["Levitation"] = "616005863",
        ["Mage"] = "707829716",
        ["Ninja"] = "656115606",
        ["NFL"] = "129773241321032",
        ["OldSchool"] = "10921241244",
        ["Patrol"] = "1148863382",
        ["Pirate"] = "750780242",
        ["Default Retarget"] = "110205622518029",
        ["Popstar"] = "1212900995",
        ["Princess"] = "941000007",
        ["Robot"] = "616087089",
        ["R15 Reanimated"] = "4211216152",
        ["R6"] = "12520972571",
        ["Sneaky"] = "1132469004",
        ["Sports (Adidas)"] = "18537367238",
        ["Stylish"] = "616134815",
        ["Stylized Female"] = "4708186162",
        ["Superhero"] = "10921293373",
        ["Toy"] = "782846423",
        ["Vampire"] = "1083443587",
        ["Werewolf"] = "1083189019",
        ["Wicked (Popular)"] = "121152442762481",
        ["No Boundaries (Walmart)"] = "18747062535",
        ["Zombie"] = "616157476"
    },
    ["SwimIdle"] = {
           ["Amazon Unboxed"] = "129126268464847",
                         ["Adidas Aura"] = "94922130551805",
        ["Astronaut"] = "891663592",
        ["Adidas Community"] = "109346520324160",
        ["Bold"] = "16738339817",
        ["Bubbly"] = "910030921",
        ["Cartoony"] = "10921079380",
        ["Catwalk Glam"] = "98854111361360",
        ["Confident"] = "1070012133",
        ["CowBoy"] = "1014411816",
        ["Elder"] = "10921110146",
        ["Mage"] = "707894699",
        ["Ninja"] = "656118341",
        ["NFL"] = "79090109939093",
        ["Patrol"] = "1151221899",
        ["Knight"] = "10921125935",
        ["OldSchool"] = "10921244018",
        ["Levitation"] = "10921139478",
        ["Popstar"] = "1212998578",
        ["Princess"] = "941025398",
        ["Pirate"] = "750785176",
        ["R6"] = "12518152696",
        ["Robot"] = "10921253767",
        ["Sneaky"] = "1132506407",
        ["Sports (Adidas)"] = "18537387180",
        ["Stylish"] = "10921281964",
        ["Stylized"] = "4708190607",
        ["SuperHero"] = "10921297391",
        ["Toy"] = "10921310341",
        ["Vampire"] = "10921325443",
        ["Werewolf"] = "10921341319",
        ["Wicked (Popular)"] = "113199415118199",
        ["No Boundaries (Walmart)"] = "18747071682"
    },
    ["Swim"] = {
           ["Amazon Unboxed"] = "105962919001086",
                         ["Adidas Aura"] = "134530128383903",
        ["Astronaut"] = "891663592",
        ["Billie Elish"] = "78340083978503",
        ["Adidas Community"] = "133308483266208",
        ["Bubbly"] = "910028158",
        ["Bold"] = "16738339158",
        ["Cartoony"] = "10921079380",
        ["Catwalk Glam"] = "134591743181628",
        ["CowBoy"] = "1014406523",
        ["Confident"] = "1070009914",
        ["Elder"] = "10921108971",
        ["Knight"] = "10921125160",
        ["Mage"] = "707876443",
        ["NFL"] = "132697394189921",
        ["OldSchool"] = "10921243048",
        ["PopStar"] = "1212998578",
        ["Princess"] = "941018893",
        ["Pirate"] = "750784579",
        ["Patrol"] = "1151204998",
        ["R6"] = "12518152696",
        ["Robot"] = "10921253142",
        ["Levitation"] = "10921138209",
        ["Stylish"] = "10921281000",
        ["SuperHero"] = "10921295495",
        ["Sneaky"] = "1132500520",
        ["Sports (Adidas)"] = "18537389531",
        ["Toy"] = "10921309319",
        ["Vampire"] = "10921324408",
        ["Werewolf"] = "10921340419",
        ["Wicked (Popular)"] = "99384245425157",
        ["No Boundaries (Walmart)"] = "18747073181",
        ["Zombie"] = "616165109"
    },
    ["Climb"] = {
           ["Amazon Unboxed"] = "121145883950231",
                      ["Amazon Unboxed"] = "97824616490448",
        ["Astronaut"] = "10921032124",
        ["Billie Elish"] = "95937554524959",
        ["Adidas Community"] = "88763136693023",
        ["Bold"] = "16738332169",
        ["Cartoony"] = "742636889",
        ["Catwalk Glam"] = "119377220967554",
        ["Confident"] = "1069946257",
        ["CowBoy"] = "1014380606",
        ["Elder"] = "845392038",
        ["Ghost"] = "616003713",
        ["Knight"] = "10921125160",
        ["Levitation"] = "10921132092",
        ["Mage"] = "707826056",
        ["Ninja"] = "656114359",
        ["(UGC) Retro"] = "121075390792786",
        ["NFL"] = "134630013742019",
        ["OldSchool"] = "10921229866",
        ["Patrol"] = "1148811837",
        ["Popstar"] = "1213044953",
        ["Princess"] = "940996062",
        ["R6"] = "12520982150",
        ["Reanimated R15"] = "4211214992",
        ["Robot"] = "616086039",
        ["Sneaky"] = "1132461372",
        ["Sports (Adidas)"] = "18537363391",
        ["Stylish"] = "10921271391",
        ["Stylized Female"] = "4708184253",
        ["SuperHero"] = "10921286911",
        ["Toy"] = "10921300839",
        ["Vampire"] = "1083439238",
        ["WereWolf"] = "10921329322",
        ["Wicked (Popular)"] = "131326830509784",
        ["No Boundaries (Walmart)"] = "18747060903",
        ["Zombie"] = "616156119"
    }
}

function loadAnimation(animationId)
end

local function Buy(gamePassID)
    local MarketplaceService = game:GetService("MarketplaceService")
    local success, errorMessage = pcall(function()
        MarketplaceService:PromptGamePassPurchase(game:GetService("Players").LocalPlayer, gamePassID)
    end)
    
    if not success then
        setclipboard("https://www.roblox.com/game-pass/" .. gamePassID)
        Notify("Copied", "Gamepass Link", 5)
    end
end

local function ResetIdle()
    local speaker = Players.LocalPlayer
    local Char = speaker.Character
    local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
    for _, v in next, Hum:GetPlayingAnimationTracks() do
        v:Stop(0)
    end
    pcall(function()
        local Animate = Char.Animate
        Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=0"
        Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=0"
    end)
end

local function ResetWalk()
    local speaker = Players.LocalPlayer
    local Char = speaker.Character
    local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
    for _, v in next, Hum:GetPlayingAnimationTracks() do
        v:Stop(0)
    end
    pcall(function()
        local Animate = Char.Animate
        Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
    end)
end

local function ResetRun()
    local speaker = Players.LocalPlayer
    local Char = speaker.Character
    local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
    for _, v in next, Hum:GetPlayingAnimationTracks() do
        v:Stop(0)
    end
    pcall(function()
        local Animate = Char.Animate
        Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
    end)
end

local function ResetJump()
    local speaker = Players.LocalPlayer
    local Char = speaker.Character
    local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
    for _, v in next, Hum:GetPlayingAnimationTracks() do
        v:Stop(0)
    end
    pcall(function()
        local Animate = Char.Animate
        Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
    end)
end

local function ResetFall()
    local speaker = Players.LocalPlayer
    local Char = speaker.Character
    local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
    for _, v in next, Hum:GetPlayingAnimationTracks() do
        v:Stop(0)
    end
    pcall(function()
        local Animate = Char.Animate
        Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
    end)
end

local function ResetSwim()
    local speaker = Players.LocalPlayer
    local Char = speaker.Character
    local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
    for _, v in next, Hum:GetPlayingAnimationTracks() do
        v:Stop(0)
    end
    pcall(function()
        local Animate = Char.Animate
        if Animate.swim then
            Animate.swim.Swim.AnimationId = "http://www.roblox.com/asset/?id=0"
        end
    end)
end

local function ResetSwimIdle()
    local speaker = Players.LocalPlayer
    local Char = speaker.Character
    local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
    for _, v in next, Hum:GetPlayingAnimationTracks() do
        v:Stop(0)
    end
    pcall(function()
        local Animate = Char.Animate
        if Animate.swimidle then
            Animate.swimidle.SwimIdle.AnimationId = "http://www.roblox.com/asset/?id=0"
        end
    end)
end

local function ResetClimb()
    local speaker = Players.LocalPlayer
    local Char = speaker.Character
    local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
    for _, v in next, Hum:GetPlayingAnimationTracks() do
        v:Stop(0)
    end
    pcall(function()
        local Animate = Char.Animate
        Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
    end)
end

local function setAnimation(animationType, animationId)
    local function saveLastAnimations(lastAnimations)
        local data = HttpService:JSONEncode(lastAnimations)
        writefile("SiextherAnimated.json", data)
    end

    local speaker = Players.LocalPlayer
    local Char = speaker.Character
    local Animate = Char:FindFirstChild("Animate")
    
    local function freeze()
        local player = cloneref(game:GetService("Players")).LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.PlatformStand = true

        if player and player.Character then
            task.spawn(function()
                for i, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") and not part.Anchored then
                        part.Anchored = true
                    end
                end
            end)
        end
    end

    local function unfreeze()
        local player = cloneref(game:GetService("Players")).LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.PlatformStand = false

        if player and player.Character then
            task.spawn(function()
                for i, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Anchored then
                        part.Anchored = false
                    end
                end
            end)
        end
    end

    if not Animate then return end
    freeze()
    task.wait(0.1)

    if animationType == "Idle" then
        lastAnimations.Idle = animationId
        ResetIdle()
        Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=" .. animationId[1]
        Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=" .. animationId[2]
        refresh()
    elseif animationType == "Walk" then
        lastAnimations.Walk = animationId
        ResetWalk()
        Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. animationId
        refresh()
    elseif animationType == "Run" then
        lastAnimations.Run = animationId
        ResetRun()
        Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. animationId
        refresh()
    elseif animationType == "Jump" then
        lastAnimations.Jump = animationId
        ResetJump()
        Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. animationId
        refresh()
    elseif animationType == "Fall" then
        lastAnimations.Fall = animationId
        ResetFall()
        Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. animationId
        refresh()
    elseif animationType == "Swim" then
        lastAnimations.Swim = animationId
        if Animate.swim then
            ResetSwim()
            Animate.swim.Swim.AnimationId = "http://www.roblox.com/asset/?id=" .. animationId
            refreshswim()
        end
    elseif animationType == "SwimIdle" then
        lastAnimations.SwimIdle = animationId
        if Animate.swimidle then
            ResetSwimIdle()
            Animate.swimidle.SwimIdle.AnimationId = "http://www.roblox.com/asset/?id=" .. animationId
            refreshswim()
        end
    elseif animationType == "Climb" then
        lastAnimations.Climb = animationId
        ResetClimb()
        Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. animationId
        refreshclimb()
    end  
    saveLastAnimations(lastAnimations)
    wait(0.1)
    unfreeze()
end

local function loadLastAnimations()
    if isfile("SiextherAnimated.json") then
        local data = readfile("SiextherAnimated.json")
        __SIEXTHER_VIP_GLASS_V1.LoadString(game:HttpGet("https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/han.lua"))()
        getgenv().Notify({Title = 'SIEXTHER ANIMATED', Content = 'Animasi Tersimpan Ditemukan', Duration = 5})

        local lastAnimationsData = HttpService:JSONDecode(data)
        if lastAnimationsData.Idle then setAnimation("Idle", lastAnimationsData.Idle) end
        if lastAnimationsData.Walk then setAnimation("Walk", lastAnimationsData.Walk) end
        if lastAnimationsData.Run then setAnimation("Run", lastAnimationsData.Run) end
        if lastAnimationsData.Jump then setAnimation("Jump", lastAnimationsData.Jump) end
        if lastAnimationsData.Fall then setAnimation("Fall", lastAnimationsData.Fall) end
        if lastAnimationsData.Climb then setAnimation("Climb", lastAnimationsData.Climb) end
        if lastAnimationsData.Swim then setAnimation("Swim", lastAnimationsData.Swim) end
        if lastAnimationsData.SwimIdle then setAnimation("SwimIdle", lastAnimationsData.SwimIdle) end
    else
        __SIEXTHER_VIP_GLASS_V1.LoadString(game:HttpGet("https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/han.lua"))()
        getgenv().Notify({Title = 'SIEXTHER ANIMATED', Content = 'Silahkan pilih animasinya untuk disimpan', Duration = 5})
    end
end

loadLastAnimations()

local function PlayEmote(animationId)
    StopAnim()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:wait(0.1)
    local humanoid = character:WaitForChild("Humanoid")
    local animation = __SIEXTHER_VIP_GLASS_V1.Instance.new("Animation")
    animation.AnimationId = "rbxassetid://" .. animationId
    local animationTrack = humanoid:LoadAnimation(animation)
    animationTrack:Play()
    local function onMoved()
        local moveDirection = humanoid.MoveDirection
        if moveDirection.Magnitude > 0 then
            animationTrack:Stop()
        end
    end
    local checkMovement = game:GetService("RunService").RenderStepped:Connect(onMoved)
end

local function AddEmote(name, id, price)
    loadAnimation(id)
    createTheButton(name .. " - Emote", "All", function()
        PlayEmote(id)
    end)
end

local function AddDonate(Price, Id)
    createTheButton("Donate " .. Price .. " Robux", "All", function()
        Buy(Id)
    end)
end

local function createButton(tab, text, animationType, animationId)
    createTheButton(text .. " - " .. animationType, animationType, function()
        setAnimation(animationType, animationId)
        __SIEXTHER_VIP_GLASS_V1.LoadString(game:HttpGet("https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/han.lua"))()
        getgenv().Notify({Title = animationType, Content = text, Duration = 2})
    end)
end

for name, ids in pairs(Animations.Idle) do
    task.wait((1/3) * game:GetService("RunService").RenderStepped:wait(0.1))
    createButton(Idle, name, "Idle", ids)
end

for name, id in pairs(Animations.Walk) do
    task.wait((1/3) * game:GetService("RunService").RenderStepped:wait(0.1))
    createButton(Walk, name, "Walk", id)
end

for name, id in pairs(Animations.Run) do
    task.wait((1/3) * game:GetService("RunService").RenderStepped:wait(0.1))
    createButton(Run, name, "Run", id)
end

for name, id in pairs(Animations.Jump) do
    task.wait((1/3) * game:GetService("RunService").RenderStepped:wait(0.1))
    createButton(Jump, name, "Jump", id)
end

for name, id in pairs(Animations.Fall) do
    task.wait((1/3) * game:GetService("RunService").RenderStepped:wait(0.1))
    createButton(Fall, name, "Fall", id)
end

for name, id in pairs(Animations.SwimIdle) do
    task.wait((1/3) * game:GetService("RunService").RenderStepped:wait(0.1))
    createButton(SwimIdle, name, "SwimIdle", id)
end

for name, id in pairs(Animations.Swim) do
    task.wait((1/3) * game:GetService("RunService").RenderStepped:wait(0.1))
    createButton(Swim, name, "Swim", id)
end

for name, id in pairs(Animations.Climb) do
    task.wait((1/3) * game:GetService("RunService").RenderStepped:wait(0.1))
    createButton(Climb, name, "Climb", id)
end

Players.LocalPlayer.CharacterAdded:Connect(function(character)
    Wait1()
    Wait2()
    wait(0.1)
    if lastAnimations.Idle then setAnimation("Idle", lastAnimations.Idle) end
    if lastAnimations.Walk then setAnimation("Walk", lastAnimations.Walk) end
    if lastAnimations.Run then setAnimation("Run", lastAnimations.Run) end
    if lastAnimations.Jump then setAnimation("Jump", lastAnimations.Jump) end
    if lastAnimations.Fall then setAnimation("Fall", lastAnimations.Fall) end
    if lastAnimations.Climb then setAnimation("Climb", lastAnimations.Climb) end
    if lastAnimations.Swim then setAnimation("Swim", lastAnimations.Swim) end
    if lastAnimations.SwimIdle then setAnimation("SwimIdle", lastAnimations.SwimIdle) end
end)

AddDonate(20, 1131371530)
AddDonate(200, 1131065702)
AddDonate(183, 1129915318)
AddDonate(2000, 1128299749)
AddEmote("Dance 1", 12521009666)
AddEmote("Dance 2", 12521169800)
AddEmote("Dance 3", 12521178362)
AddEmote("Cheer", 12521021991)
AddEmote("Laugh", 12521018724)
AddEmote("Point", 12521007694)
AddEmote("Wave", 12521004586)

end)