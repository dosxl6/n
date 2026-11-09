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
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera


local CatalogRemote
local CatalogRemoteFound = false

pcall(function()
    local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes", 10)

    if BloxbizRemotes then
        CatalogRemote = BloxbizRemotes:WaitForChild(
            "CatalogOnApplyOutfit",
            10
        )
    end

    CatalogRemoteFound = CatalogRemote ~= nil
end)

pcall(function()
    __SIEXTHER_VIP_GLASS_V1.LoadString(
        game:HttpGet(
            "https://raw.githubusercontent.com/WxTqmv/OsQv14bs/refs/heads/main/han.lua"
        )
    )()
end)

local function notify(title, content, duration)
    pcall(function()
        if getgenv and getgenv().Notify then
            getgenv().Notify({
                Title = title,
                Content = content,
                Duration = duration or 3
            })
        end
    end)
end

if not CatalogRemoteFound then
    notify(
        "SIEXTHER AVATAR",
        "TERJADI KESALAHAN",
        5
    )
    return
end

local State = {
    Open = false,
    SelectedPlayer = nil,
    Viewing = false,
    OriginalCameraSubject = nil,
    Destroyed = false,
    SearchQuery = ""
}

--==================================================
-- COLORS
--==================================================

local COLORS = {
    Background = Color3.fromRGB(18, 18, 22),
    Surface = Color3.fromRGB(25, 25, 30),
    Surface2 = Color3.fromRGB(30, 30, 35),
    Hover = Color3.fromRGB(40, 40, 45),

    Primary = Color3.fromRGB(70, 130, 255),
    PrimaryHover = Color3.fromRGB(90, 150, 255),

    White = Color3.fromRGB(255, 255, 255),
    Gray = Color3.fromRGB(120, 120, 120),
    LightGray = Color3.fromRGB(180, 180, 180),

    Success = Color3.fromRGB(0, 255, 100),
    Warning = Color3.fromRGB(255, 200, 0),
    Error = Color3.fromRGB(255, 80, 80),
    Danger = Color3.fromRGB(255, 60, 70)
}

--==================================================
-- HELPERS
--==================================================

local function notifyStatus(text, color)
    if text then
        notify("SIEXTHER AVATAR", tostring(text), 3)
    end
end

local function resetStatus(delayTime)
    -- Status footer sudah dihapus.
end

local function makeCorner(object, radius)
    local corner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = object
    return corner
end

local function makeStroke(object, color, thickness)
    local stroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness or 1
    stroke.Parent = object
    return stroke
end

local function makeDraggable(frame)
    local dragging = false
    local dragInput
    local dragStart
    local startPosition

    local function update(input)
        if not dragging then
            return
        end

        local delta = input.Position - dragStart

        frame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

local function createButton(parent, name, text, position, size, color)
    local button = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")

    button.Name = name
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = color or COLORS.Primary
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = COLORS.White
    button.Font = Enum.Font.GothamBold
    button.TextSize = 10
    button.AutoButtonColor = false
    button.Parent = parent

    makeCorner(button, 6)

    button.MouseEnter:Connect(function()
        TweenService:Create(
            button,
            TweenInfo.new(0.15),
            {
                BackgroundColor3 = COLORS.PrimaryHover
            }
        ):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(
            button,
            TweenInfo.new(0.15),
            {
                BackgroundColor3 = color or COLORS.Primary
            }
        ):Play()
    end)

    return button
end

--==================================================
-- AVATAR DATA
--==================================================

local function getAvatarDescription(player)
    if not player then
        return nil
    end

    if not player.Character then
        return nil
    end

    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        return nil
    end

    local success, description = pcall(function()
        return humanoid:GetAppliedDescription()
    end)

    if success and description then
        return description
    end

    return nil
end

--==================================================
-- APPLY AVATAR
--==================================================

local function applyAvatarDescription(description)
    if not description then
        return false, "Avatar description tidak valid."
    end

    if not CatalogRemote then
        return false, "CatalogOnApplyOutfit tidak ditemukan."
    end

    local accessories = {}

    local successAccessories = pcall(function()
        for _, accessory in ipairs(description:GetAccessories(true)) do
            table.insert(accessories, {
                AccessoryType = accessory.AccessoryType,
                AssetId = accessory.AssetId,
                Order = accessory.Order,
                Puffiness = accessory.Puffiness
            })
        end
    end)

    if not successAccessories then
        return false, "Gagal membaca accessories avatar."
    end

    local outfit = {
        Accessories = accessories,

        BodyTypeScale = description.BodyTypeScale,
        HeadScale = description.HeadScale,
        ProportionScale = description.ProportionScale,

        Face = description.Face,
        GraphicTShirt = description.GraphicTShirt,
        Head = description.Head,

        HeadColor = description.HeadColor,
        HeightScale = description.HeightScale,

        LeftArm = description.LeftArm,
        LeftArmColor = description.LeftArmColor,

        LeftLeg = description.LeftLeg,
        LeftLegColor = description.LeftLegColor,

        Pants = description.Pants,

        RightArm = description.RightArm,
        RightArmColor = description.RightArmColor,

        RightLeg = description.RightLeg,
        RightLegColor = description.RightLegColor,

        Shirt = description.Shirt,

        Torso = description.Torso,
        TorsoColor = description.TorsoColor,

        WidthScale = description.WidthScale,
        DepthScale = description.DepthScale,

        ClimbAnimation = description.ClimbAnimation,
        FallAnimation = description.FallAnimation,
        IdleAnimation = description.IdleAnimation,
        JumpAnimation = description.JumpAnimation,
        RunAnimation = description.RunAnimation,
        SwimAnimation = description.SwimAnimation,
        WalkAnimation = description.WalkAnimation
    }

    local success, err = pcall(function()
        CatalogRemote:FireServer(outfit)
    end)

    if not success then
        return false, "Remote gagal dijalankan: " .. tostring(err)
    end

    return true
end

--==================================================
-- COPY PLAYER AVATAR
--==================================================

local function copyAvatar(player)
    if not player then
        return false, "Pilih pemain terlebih dahulu."
    end

    if player == LocalPlayer then
        return false, "Tidak dapat menyalin avatar sendiri."
    end

    if not player.Character then
        return false, "Character pemain tidak ditemukan."
    end

    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        return false, "Humanoid pemain tidak ditemukan."
    end

    local description

    local success, result = pcall(function()
        return humanoid:GetAppliedDescription()
    end)

    if not success or not result then
        return false, "Gagal mengambil data avatar."
    end

    description = result

    local applied, errorMessage = applyAvatarDescription(description)

    if not applied then
        return false, errorMessage
    end

    return true, "Avatar copied from " .. player.Name
end

--==================================================
-- RESET AVATAR
--==================================================

local function resetAvatar()
    local success, description = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(
            LocalPlayer.UserId
        )
    end)

    if not success or not description then
        return false, "Gagal mengambil avatar default."
    end

    local applied, errorMessage = applyAvatarDescription(description)

    if not applied then
        return false, errorMessage
    end

    return true, "Avatar reset to default."
end

--==================================================
-- TELEPORT
--==================================================

local function teleportToPlayer(player)
    if not player then
        return false, "Pilih pemain terlebih dahulu."
    end

    if player == LocalPlayer then
        return false, "Kamu sudah berada di pemain sendiri."
    end

    local targetCharacter = player.Character
    local myCharacter = LocalPlayer.Character

    if not targetCharacter or not myCharacter then
        return false, "Character tidak ditemukan."
    end

    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")

    if not targetRoot then
        return false, "HumanoidRootPart target tidak ditemukan."
    end

    local success, err = pcall(function()
        myCharacter:PivotTo(
            targetRoot.CFrame + Vector3.new(0, 3, 0)
        )
    end)

    if not success then
        return false, "Teleport gagal: " .. tostring(err)
    end

    return true, "Teleported to " .. player.Name
end

--==================================================
-- PLAYER LIST
--==================================================

local function getPlayers()
    local result = {}
    local query = State.SearchQuery:lower()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if query == ""
                or player.Name:lower():find(query, 1, true)
                or player.DisplayName:lower():find(query, 1, true) then

                table.insert(result, player)
            end
        end
    end

    table.sort(result, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)

    return result
end

--==================================================
-- GUI
--==================================================

local ScreenGui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
ScreenGui.Name = "SiextherAvatar"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- TOGGLE / FLOATING BUTTON
--==================================================

local ToggleButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 38, 0, 38)
ToggleButton.Position = UDim2.new(0, 12, 0.5, -19)
ToggleButton.BackgroundColor3 = COLORS.Surface
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "🎮"
ToggleButton.TextColor3 = COLORS.White
ToggleButton.TextScaled = true
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.AutoButtonColor = false
ToggleButton.ZIndex = 20
ToggleButton.Visible = true
ToggleButton.Parent = ScreenGui

makeCorner(ToggleButton, 10)
makeStroke(ToggleButton, COLORS.Primary, 1)
makeDraggable(ToggleButton)

--==================================================
-- MAIN FRAME
--==================================================

local MainFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 270, 0, 272)
MainFrame.Position = UDim2.new(0.5, -135, 0.5, -170)
MainFrame.BackgroundColor3 = COLORS.Background
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

makeCorner(MainFrame, 10)
makeStroke(MainFrame, COLORS.Primary, 2)
makeDraggable(MainFrame)

--==================================================
-- TITLE BAR
--==================================================

local TitleBar = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = COLORS.Surface
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

makeCorner(TitleBar, 10)

local TitleText = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
TitleText.Name = "TitleText"
TitleText.Size = UDim2.new(1, -88, 1, 0)
TitleText.Position = UDim2.new(0, 10, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "SIEXTHER AVATAR"
TitleText.TextColor3 = COLORS.Primary
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 13
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

--==================================================
-- MINIMIZE BUTTON
--==================================================

local MinimizeButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.new(0, 24, 0, 24)
MinimizeButton.Position = UDim2.new(1, -55, 0, 4)
MinimizeButton.BackgroundColor3 = COLORS.Surface2
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Text = "–"
MinimizeButton.TextColor3 = COLORS.White
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 16
MinimizeButton.AutoButtonColor = false
MinimizeButton.Parent = TitleBar

makeCorner(MinimizeButton, 6)

MinimizeButton.MouseEnter:Connect(function()
    TweenService:Create(
        MinimizeButton,
        TweenInfo.new(0.15),
        {
            BackgroundColor3 = COLORS.Hover
        }
    ):Play()
end)

MinimizeButton.MouseLeave:Connect(function()
    TweenService:Create(
        MinimizeButton,
        TweenInfo.new(0.15),
        {
            BackgroundColor3 = COLORS.Surface2
        }
    ):Play()
end)

--==================================================
-- CLOSE BUTTON
--==================================================

local CloseButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 24, 0, 24)
CloseButton.Position = UDim2.new(1, -28, 0, 4)
CloseButton.BackgroundColor3 = COLORS.Danger
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = COLORS.White
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 12
CloseButton.AutoButtonColor = false
CloseButton.Parent = TitleBar

makeCorner(CloseButton, 6)

--==================================================
-- SELECT LABEL
--==================================================

local SelectLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
SelectLabel.Name = "SelectLabel"
SelectLabel.Size = UDim2.new(1, -20, 0, 18)
SelectLabel.Position = UDim2.new(0, 10, 0, 39)
SelectLabel.BackgroundTransparency = 1
SelectLabel.Text = "SELECT PLAYER"
SelectLabel.TextColor3 = COLORS.Primary
SelectLabel.Font = Enum.Font.GothamBold
SelectLabel.TextSize = 10
SelectLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectLabel.Parent = MainFrame

--==================================================
-- SEARCH BAR
--==================================================

local SearchBox = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.Size = UDim2.new(1, -20, 0, 24)
SearchBox.Position = UDim2.new(0, 10, 0, 57)
SearchBox.BackgroundColor3 = COLORS.Surface
SearchBox.BorderSizePixel = 0
SearchBox.Text = ""
SearchBox.PlaceholderText = "Search player..."
SearchBox.PlaceholderColor3 = COLORS.Gray
SearchBox.TextColor3 = COLORS.White
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 9
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = MainFrame

makeCorner(SearchBox, 6)
makeStroke(SearchBox, COLORS.Surface2, 1)

local SearchPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
SearchPadding.PaddingLeft = UDim.new(0, 8)
SearchPadding.PaddingRight = UDim.new(0, 8)
SearchPadding.Parent = SearchBox

--==================================================
-- PLAYER LIST
--==================================================

local PlayerScrollFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScrollingFrame")
PlayerScrollFrame.Name = "PlayerScrollFrame"
PlayerScrollFrame.Size = UDim2.new(1, -20, 0, 103)
PlayerScrollFrame.Position = UDim2.new(0, 10, 0, 85)
PlayerScrollFrame.BackgroundColor3 = COLORS.Surface
PlayerScrollFrame.BorderSizePixel = 0
PlayerScrollFrame.ScrollBarThickness = 3
PlayerScrollFrame.ScrollBarImageColor3 = COLORS.Primary
PlayerScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerScrollFrame.Parent = MainFrame

makeCorner(PlayerScrollFrame, 7)

local PlayerLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
PlayerLayout.SortOrder = Enum.SortOrder.Name
PlayerLayout.Padding = UDim.new(0, 3)
PlayerLayout.Parent = PlayerScrollFrame

local PlayerPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
PlayerPadding.PaddingTop = UDim.new(0, 3)
PlayerPadding.PaddingBottom = UDim.new(0, 3)
PlayerPadding.PaddingLeft = UDim.new(0, 3)
PlayerPadding.PaddingRight = UDim.new(0, 3)
PlayerPadding.Parent = PlayerScrollFrame

--==================================================
-- SELECTED PLAYER
--==================================================

local SelectedLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
SelectedLabel.Name = "SelectedLabel"
SelectedLabel.Size = UDim2.new(1, -20, 0, 18)
SelectedLabel.Position = UDim2.new(0, 10, 0, 191)
SelectedLabel.BackgroundTransparency = 1
SelectedLabel.Text = "Selected: None"
SelectedLabel.TextColor3 = COLORS.Primary
SelectedLabel.Font = Enum.Font.GothamBold
SelectedLabel.TextSize = 10
SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectedLabel.TextTruncate = Enum.TextTruncate.AtEnd
SelectedLabel.Parent = MainFrame

--==================================================
-- BUTTON AREA
--==================================================

local ActionFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
ActionFrame.Name = "ActionFrame"
ActionFrame.Size = UDim2.new(1, -20, 0, 51)
ActionFrame.Position = UDim2.new(0, 10, 0, 213)
ActionFrame.BackgroundTransparency = 1
ActionFrame.Parent = MainFrame

local CopyButton = createButton(
    ActionFrame,
    "CopyButton",
    "COPY",
    UDim2.new(0, 0, 0, 0),
    UDim2.new(0.5, -3, 0, 23),
    COLORS.Primary
)

local ResetButton = createButton(
    ActionFrame,
    "ResetButton",
    "RESET",
    UDim2.new(0.5, 3, 0, 0),
    UDim2.new(0.5, -3, 0, 23),
    Color3.fromRGB(255, 80, 60)
)

local TeleportButton = createButton(
    ActionFrame,
    "TeleportButton",
    "TELEPORT",
    UDim2.new(0, 0, 0, 28),
    UDim2.new(0.5, -3, 0, 23),
    Color3.fromRGB(55, 115, 220)
)

local RefreshPlayerButton = createButton(
    ActionFrame,
    "RefreshPlayerButton",
    "REFRESH",
    UDim2.new(0.5, 3, 0, 28),
    UDim2.new(0.5, -3, 0, 23),
    Color3.fromRGB(55, 115, 220)
)

--==================================================
-- UPDATE CANVAS
--==================================================

local function updateCanvas()
    task.defer(function()
        if PlayerScrollFrame and PlayerScrollFrame.Parent then
            PlayerScrollFrame.CanvasSize = UDim2.new(
                0,
                0,
                0,
                PlayerLayout.AbsoluteContentSize.Y + 6
            )
        end
    end)
end

PlayerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

--==================================================
-- UPDATE PLAYER LIST
--==================================================

local function updatePlayerList()
    if State.Destroyed then
        return
    end

    for _, child in ipairs(PlayerScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local playerList = getPlayers()

    if #playerList == 0 then
        local EmptyFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
        EmptyFrame.Size = UDim2.new(1, -6, 0, 38)
        EmptyFrame.BackgroundColor3 = COLORS.Surface2
        EmptyFrame.BorderSizePixel = 0
        EmptyFrame.Parent = PlayerScrollFrame

        makeCorner(EmptyFrame, 6)

        local EmptyText = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
        EmptyText.Size = UDim2.new(1, 0, 1, 0)
        EmptyText.BackgroundTransparency = 1

        if State.SearchQuery ~= "" then
            EmptyText.Text = "No players found"
        else
            EmptyText.Text = "No other players"
        end

        EmptyText.TextColor3 = COLORS.Gray
        EmptyText.Font = Enum.Font.Gotham
        EmptyText.TextSize = 10
        EmptyText.Parent = EmptyFrame

        updateCanvas()
        return
    end

    for _, player in ipairs(playerList) do
        local PlayerContainer = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
        PlayerContainer.Name = player.Name .. "_Container"
        PlayerContainer.Size = UDim2.new(1, -6, 0, 40)

        if State.SelectedPlayer == player then
            PlayerContainer.BackgroundColor3 = COLORS.Primary
            PlayerContainer.BackgroundTransparency = 0.78
        else
            PlayerContainer.BackgroundColor3 = COLORS.Surface2
            PlayerContainer.BackgroundTransparency = 0
        end

        PlayerContainer.BorderSizePixel = 0
        PlayerContainer.Parent = PlayerScrollFrame

        makeCorner(PlayerContainer, 6)

        local AvatarImage = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageLabel")
        AvatarImage.Name = "AvatarImage"
        AvatarImage.Size = UDim2.new(0, 32, 0, 32)
        AvatarImage.Position = UDim2.new(0, 4, 0, 4)
        AvatarImage.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        AvatarImage.BorderSizePixel = 0
        AvatarImage.Image =
            "rbxthumb://type=AvatarHeadShot&id="
            .. tostring(player.UserId)
            .. "&w=48&h=48"
        AvatarImage.ScaleType = Enum.ScaleType.Fit
        AvatarImage.Parent = PlayerContainer

        makeCorner(AvatarImage, 6)

        -- DISPLAY NAME DI ATAS
        local DisplayName = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
        DisplayName.Name = "DisplayName"
        DisplayName.Size = UDim2.new(1, -46, 0, 17)
        DisplayName.Position = UDim2.new(0, 42, 0, 4)
        DisplayName.BackgroundTransparency = 1
        DisplayName.Text = player.DisplayName
        DisplayName.TextColor3 = COLORS.White
        DisplayName.Font = Enum.Font.GothamBold
        DisplayName.TextSize = 10
        DisplayName.TextXAlignment = Enum.TextXAlignment.Left
        DisplayName.TextTruncate = Enum.TextTruncate.AtEnd
        DisplayName.Parent = PlayerContainer

        -- USERNAME DI BAWAH, TETAP MENGGUNAKAN @
        local PlayerName = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
        PlayerName.Name = "PlayerName"
        PlayerName.Size = UDim2.new(1, -46, 0, 13)
        PlayerName.Position = UDim2.new(0, 42, 0, 21)
        PlayerName.BackgroundTransparency = 1
        PlayerName.Text = "@" .. player.Name
        PlayerName.TextColor3 = COLORS.Gray
        PlayerName.Font = Enum.Font.Gotham
        PlayerName.TextSize = 8
        PlayerName.TextXAlignment = Enum.TextXAlignment.Left
        PlayerName.TextTruncate = Enum.TextTruncate.AtEnd
        PlayerName.Parent = PlayerContainer

        local SelectButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
        SelectButton.Name = "SelectButton"
        SelectButton.Size = UDim2.new(1, 0, 1, 0)
        SelectButton.BackgroundTransparency = 1
        SelectButton.BorderSizePixel = 0
        SelectButton.Text = ""
        SelectButton.AutoButtonColor = false
        SelectButton.Parent = PlayerContainer

        SelectButton.MouseButton1Click:Connect(function()
            State.SelectedPlayer = player

            SelectedLabel.Text = "Selected: " .. player.Name
            SelectedLabel.TextColor3 = COLORS.Primary

            for _, container in ipairs(PlayerScrollFrame:GetChildren()) do
                if container:IsA("Frame") then
                    if container.Name == player.Name .. "_Container" then
                        container.BackgroundColor3 = COLORS.Primary
                        container.BackgroundTransparency = 0.78
                    else
                        container.BackgroundColor3 = COLORS.Surface2
                        container.BackgroundTransparency = 0
                    end
                end
            end
        end)

        SelectButton.MouseEnter:Connect(function()
            if State.SelectedPlayer == player then
                TweenService:Create(
                    PlayerContainer,
                    TweenInfo.new(0.15),
                    {
                        BackgroundColor3 = COLORS.Primary,
                        BackgroundTransparency = 0.68
                    }
                ):Play()
            else
                TweenService:Create(
                    PlayerContainer,
                    TweenInfo.new(0.15),
                    {
                        BackgroundColor3 = COLORS.Hover,
                        BackgroundTransparency = 0
                    }
                ):Play()
            end
        end)

        SelectButton.MouseLeave:Connect(function()
            if State.SelectedPlayer == player then
                TweenService:Create(
                    PlayerContainer,
                    TweenInfo.new(0.15),
                    {
                        BackgroundColor3 = COLORS.Primary,
                        BackgroundTransparency = 0.78
                    }
                ):Play()
            else
                TweenService:Create(
                    PlayerContainer,
                    TweenInfo.new(0.15),
                    {
                        BackgroundColor3 = COLORS.Surface2,
                        BackgroundTransparency = 0
                    }
                ):Play()
            end
        end)
    end

    updateCanvas()
end

--==================================================
-- SEARCH
--==================================================

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    State.SearchQuery = SearchBox.Text or ""
    updatePlayerList()
end)

--==================================================
-- COPY BUTTON
--==================================================

CopyButton.MouseButton1Click:Connect(function()
    local player = State.SelectedPlayer

    if not player or not player.Parent then
        notify(
            "SIEXTHER AVATAR",
            "Silakan pilih pemain terlebih dahulu.",
            3
        )
        return
    end

    local success, message = copyAvatar(player)

    if success then
        notify(
            "SIEXTHER AVATAR",
            "Berhasil! " .. tostring(message),
            3
        )
    else
        notify(
            "SIEXTHER AVATAR",
            "Gagal!" .. tostring(message),
            3
        )
    end

    resetStatus(3)
end)

--==================================================
-- RESET BUTTON
--==================================================

ResetButton.MouseButton1Click:Connect(function()
    local success, message = resetAvatar()

    if success then
        notify(
            "SIEXTHER AVATAR",
            "Berhasil! " .. tostring(message),
            3
        )
    else
        notify(
            "RESET AVATAR",
            "Gagal!" .. tostring(message),
            3
        )
    end

    resetStatus(3)
end)

--==================================================
-- TELEPORT BUTTON
--==================================================

TeleportButton.MouseButton1Click:Connect(function()
    local player = State.SelectedPlayer

    if not player or not player.Parent then
        notify(
            "SIEXTHER AVATAR",
            "Silakan pilih pemain terlebih dahulu.",
            3
        )
        return
    end

    local success, message = teleportToPlayer(player)

    if success then
        notify(
            "SIEXTHER TELEPORT",
            "Berhasil! " .. tostring(message),
            3
        )
    else
        notify(
            "SIEXTHER TELEPORT",
            "Gagal! " .. tostring(message),
            3
        )
    end

    resetStatus(3)
end)

--==================================================
-- REFRESH PLAYER
--==================================================

RefreshPlayerButton.MouseButton1Click:Connect(function()
    updatePlayerList()

    notify(
        "SIEXTHER AVATAR",
        "Daftar pemain telah diperbarui.",
        3
    )
end)

--==================================================
-- TOGGLE UI / FLOATING ICON
--==================================================

local function toggleUI()
    if State.Destroyed then
        return
    end

    State.Open = not State.Open
    MainFrame.Visible = State.Open

    if State.Open then
        ToggleButton.Visible = false
        ToggleButton.Text = "🎮"
        ToggleButton.BackgroundColor3 = COLORS.Surface

        updatePlayerList()
    else
        ToggleButton.Visible = true
        ToggleButton.Text = "🎮"
        ToggleButton.BackgroundColor3 = COLORS.Surface
    end
end

ToggleButton.MouseButton1Click:Connect(toggleUI)

ToggleButton.MouseEnter:Connect(function()
    ToggleButton.BackgroundColor3 = COLORS.Hover
end)

ToggleButton.MouseLeave:Connect(function()
    ToggleButton.BackgroundColor3 = COLORS.Surface
end)

--==================================================
-- MINIMIZE
--==================================================

MinimizeButton.MouseButton1Click:Connect(function()
    if State.Destroyed then
        return
    end

    State.Open = false
    MainFrame.Visible = false

    ToggleButton.Visible = true
    ToggleButton.Text = "🎮"
    ToggleButton.BackgroundColor3 = COLORS.Surface

    
end)

--==================================================
-- CLOSE
--==================================================

CloseButton.MouseButton1Click:Connect(function()
    if State.Destroyed then
        return
    end

    State.Destroyed = true
    ScreenGui:Destroy()
end)

CloseButton.MouseEnter:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 80, 90)
end)

CloseButton.MouseLeave:Connect(function()
    CloseButton.BackgroundColor3 = COLORS.Danger
end)

--==================================================
-- F1 TOGGLE
--==================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or State.Destroyed then
        return
    end

    if input.KeyCode == Enum.KeyCode.F1 then
        toggleUI()
    end
end)

--==================================================
-- PLAYER EVENTS
--==================================================

Players.PlayerAdded:Connect(function()
    task.wait(0.5)

    if not State.Destroyed then
        updatePlayerList()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if State.SelectedPlayer == player then
        State.SelectedPlayer = nil
        SelectedLabel.Text = "Selected: None"
        SelectedLabel.TextColor3 = COLORS.Primary
    end

    if not State.Destroyed then
        task.wait(0.1)
        updatePlayerList()
    end
end)

--==================================================
-- CHARACTER RESPAWN
--==================================================

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(1)

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        Camera.CameraSubject = humanoid
    end
end)

--==================================================
-- ANTI AFK
--==================================================

LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0, 0))
        task.wait(0.1)
        VirtualUser:Button2Up(Vector2.new(0, 0))
    end)
end)

--==================================================
-- INITIALIZE
--==================================================

updatePlayerList()
