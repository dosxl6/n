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
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- === NERFED CONFIG ===
local baseMaxSpeed = 5
local topMaxSpeed = 120
local accel = 0.5
local speedBuildRate = 3
local speedDecayRate = 15
local boostMultiplier = 1.3
local boostKey = Enum.KeyCode.LeftShift
local jumpPower = 50
local tauntDuration = 200
local tauntCooldownTime = 5
local maxJumps = 5

local runAnimId   = "rbxassetid://98377335607360"
local jumpAnimId  = "rbxassetid://123364707044126"
local tauntAnimId = "rbxassetid://75602578104627"
local idleAnimId  = "rbxassetid://90613618252787"
local fakeDeathAnimId = "rbxassetid://82378425345026"

local speed = 0
local currentMaxSpeed = baseMaxSpeed
local boostActive = false
local tauntCooldown = false
local jumpCount = 0

local humanoid, rootPart, character
local runTrack, jumpTrack, tauntTrack, idleTrack
local leftFootSmoke, rightFootSmoke, leftFootTrail, rightFootTrail

local fakeDeathTrack = nil
local isFakingDeath = false
local tallManEnabled = false

-- === GUI CREATION ===
local function createGUI()
	local screenGui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
	screenGui.Name = "SiextherTall"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- Main Frame (Smaller)
	local mainFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 280, 0, 180)
	mainFrame.Position = UDim2.new(0.5, -140, 0.5, -90)
	mainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
	mainFrame.BorderSizePixel = 0
	mainFrame.Active = true
	mainFrame.Draggable = true
	mainFrame.Parent = screenGui
	
	local mainCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 16)
	mainCorner.Parent = mainFrame
	
	local mainStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
	mainStroke.Color = Color3.fromRGB(60, 120, 255)
	mainStroke.Thickness = 2
	mainStroke.Parent = mainFrame
	
	-- Header
	local header = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 45)
	header.BackgroundTransparency = 1
	header.BorderSizePixel = 0
	header.Parent = mainFrame
	
	local titleLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -50, 1, 0)
	titleLabel.Position = UDim2.new(0, 15, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "SIEXTHER TALL MAN"
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 16
	titleLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = header
	
	-- Close Button (X) - Red button
	local closeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 28, 0, 28)
	closeBtn.Position = UDim2.new(1, -38, 0, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
	closeBtn.Text = "X"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 16
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.BorderSizePixel = 0
	closeBtn.Parent = header
	
	local closeCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)
	closeCorner.Parent = closeBtn
	
	-- Minimize Button (Top right corner, rounded) - Next to X button
	local minimizeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	minimizeBtn.Name = "MinimizeBtn"
	minimizeBtn.Size = UDim2.new(0, 28, 0, 28)
	minimizeBtn.Position = UDim2.new(1, -70, 0, 8)
	minimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
	minimizeBtn.Text = "–"
	minimizeBtn.Font = Enum.Font.GothamBold
	minimizeBtn.TextSize = 20
	minimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	minimizeBtn.BorderSizePixel = 0
	minimizeBtn.Parent = header
	
	local minCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
	minCorner.CornerRadius = UDim.new(1, 0)
	minCorner.Parent = minimizeBtn
	
	-- Content Frame
	local contentFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.Size = UDim2.new(1, -24, 1, -55)
	contentFrame.Position = UDim2.new(0, 12, 0, 50)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = mainFrame
	
	-- Info Text (Smaller, centered)
	local infoText = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
	infoText.Name = "InfoText"
	infoText.Size = UDim2.new(1, 0, 0, 40)
	infoText.Position = UDim2.new(0, 0, 0, 5)
	infoText.BackgroundTransparency = 1
	infoText.Text = "NOS DI PC PAKE SHIFT"
	infoText.Font = Enum.Font.Gotham
	infoText.TextSize = 10
	infoText.TextColor3 = Color3.fromRGB(150, 150, 160)
	infoText.TextXAlignment = Enum.TextXAlignment.Center
	infoText.TextYAlignment = Enum.TextYAlignment.Top
	infoText.TextWrapped = true
	infoText.Parent = contentFrame
	
	-- Apply Boost Button (Large, centered, blue)
	local applyBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	applyBtn.Name = "ApplyBtn"
	applyBtn.Size = UDim2.new(1, -20, 0, 48)
	applyBtn.Position = UDim2.new(0, 10, 0, 55)
	applyBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
	applyBtn.Text = "AKTIFKAN"
	applyBtn.Font = Enum.Font.GothamBold
	applyBtn.TextSize = 16
	applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	applyBtn.BorderSizePixel = 0
	applyBtn.Parent = contentFrame
	
	local applyCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
	applyCorner.CornerRadius = UDim.new(0, 12)
	applyCorner.Parent = applyBtn
	
	-- Made By Text
	local madeByText = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
	madeByText.Name = "MadeByText"
	madeByText.Size = UDim2.new(1, 0, 0, 20)
	madeByText.Position = UDim2.new(0, 0, 1, -25)
	madeByText.BackgroundTransparency = 1
	madeByText.Text = "Made By Hann.Siexther"
	madeByText.Font = Enum.Font.Gotham
	madeByText.TextSize = 10
	madeByText.TextColor3 = Color3.fromRGB(100, 100, 120)
	madeByText.TextXAlignment = Enum.TextXAlignment.Center
	madeByText.Parent = contentFrame
	
	-- Floating Button (Hidden by default)
	local floatingBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	floatingBtn.Name = "FloatingBtn"
	floatingBtn.Size = UDim2.new(0, 41, 0, 41)
	floatingBtn.Position = UDim2.new(0, 20, 0.5, -25)
	floatingBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	floatingBtn.Text = "🦒"
	floatingBtn.Font = Enum.Font.GothamBold
	floatingBtn.TextSize = 20
	floatingBtn.BorderSizePixel = 0
	floatingBtn.Visible = false
	floatingBtn.Active = true
	floatingBtn.Draggable = true
	floatingBtn.Parent = screenGui	
	
	local floatCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
	floatCorner.CornerRadius = UDim.new(0, 12)
	floatCorner.Parent = floatingBtn
	
	
	-- BOOST BUTTON (Tengah kanan)
	local boostBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	boostBtn.Name = "BoostBtn"
	boostBtn.Size = UDim2.new(0, 43, 0, 43)
	boostBtn.Position = UDim2.new(0.76, 0, 0.6, 0)
	boostBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	boostBtn.Text = "NOS"
	boostBtn.Font = Enum.Font.GothamBold
	boostBtn.TextSize = 18
	boostBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	boostBtn.BorderSizePixel = 0
	boostBtn.Active = true
	boostBtn.Visible = false  
	boostBtn.BackgroundTransparency = 0.3
	boostBtn.Parent = screenGui
	
	local boostCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
	boostCorner.CornerRadius = UDim.new(0, 12)
	boostCorner.Parent = boostBtn
	
	-- Button Functions
	applyBtn.MouseButton1Click:Connect(function()
		tallManEnabled = not tallManEnabled
		if tallManEnabled then
			applyBtn.Text = "MATIKAN"
			applyBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
			boostBtn.Visible = true
		else
			applyBtn.Text = "AKTIFKAN"
			applyBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
			boostBtn.Visible = false
			-- Stop all animations when disabled
			if runTrack and runTrack.IsPlaying then runTrack:Stop() end
			if jumpTrack and jumpTrack.IsPlaying then jumpTrack:Stop() end
			if idleTrack and idleTrack.IsPlaying then idleTrack:Stop() end
			speed = 0
			if humanoid then humanoid.WalkSpeed = 16 end
		end
	end)
	
	-- Boost button touch handlers
	boostBtn.MouseButton1Down:Connect(function()
		if tallManEnabled then
			boostActive = true
			boostBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		end
	end)
	
	boostBtn.MouseButton1Up:Connect(function()
		boostActive = false
		boostBtn.BackgroundTransparency = 0.3
		boostBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	end)
	
	minimizeBtn.MouseButton1Click:Connect(function()
		mainFrame.Visible = false
		floatingBtn.Visible = true
	end)
	
	closeBtn.MouseButton1Click:Connect(function()
		screenGui:Destroy()
		tallManEnabled = false
		-- Cleanup and stop all animations
		if runTrack then runTrack:Stop() end
		if jumpTrack then jumpTrack:Stop() end
		if tauntTrack then tauntTrack:Stop() end
		if idleTrack then idleTrack:Stop() end
		if fakeDeathTrack then fakeDeathTrack:Stop() end
		-- Reset humanoid speed
		if humanoid then humanoid.WalkSpeed = 16 end
	end)
	
	floatingBtn.MouseButton1Click:Connect(function()
		mainFrame.Visible = true
		floatingBtn.Visible = false
	end)
	
	screenGui.Parent = playerGui
end

-- === ORIGINAL FUNCTIONS ===
local function createTrailAttachment(part, name, position)
	local a = __SIEXTHER_VIP_GLASS_V1.Instance.new("Attachment")
	a.Name = name
	a.Position = position
	a.Parent = part
	return a
end

local function loadAnimations()
	local runAnim = __SIEXTHER_VIP_GLASS_V1.Instance.new("Animation")
	runAnim.AnimationId = runAnimId
	runTrack = humanoid:LoadAnimation(runAnim)

	local jumpAnim = __SIEXTHER_VIP_GLASS_V1.Instance.new("Animation")
	jumpAnim.AnimationId = jumpAnimId
	jumpTrack = humanoid:LoadAnimation(jumpAnim)
	jumpTrack.Looped = true

	local tauntAnim = __SIEXTHER_VIP_GLASS_V1.Instance.new("Animation")
	tauntAnim.AnimationId = tauntAnimId
	tauntTrack = humanoid:LoadAnimation(tauntAnim)

	local idleAnim = __SIEXTHER_VIP_GLASS_V1.Instance.new("Animation")
	idleAnim.AnimationId = idleAnimId
	idleTrack = humanoid:LoadAnimation(idleAnim)
end

local function doTaunt()
	if not tallManEnabled then return end
	if tauntCooldown then return end
	tauntCooldown = true
	if runTrack.IsPlaying then runTrack:Stop() end
	if idleTrack.IsPlaying then idleTrack:Stop() end
	if jumpTrack.IsPlaying then jumpTrack:Stop() end
	tauntTrack:Play()

	task.delay(tauntDuration, function()
		tauntTrack:Stop()
		if speed <= 0 then idleTrack:Play() else runTrack:Play() end
	end)

	task.delay(tauntCooldownTime, function()
		tauntCooldown = false
	end)
end

local function getSlopeNormal()
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {character}
	params.FilterType = Enum.RaycastFilterType.Blacklist
	local result = workspace:Raycast(rootPart.Position, Vector3.new(0, -5, 0), params)
	return result and result.Normal or Vector3.new(0, 1, 0)
end

local function setupVFX()
	local leftFoot = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg")
	local rightFoot = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg")
	if not (leftFoot and rightFoot) then return end

	local function makeSmoke(parent)
		local e = __SIEXTHER_VIP_GLASS_V1.Instance.new("ParticleEmitter")
		e.Enabled = false
		e.Texture = "rbxassetid://7712212245"
		e.Lifetime = NumberRange.new(0.5, 1)
		e.Speed = NumberRange.new(0.5, 1)
		e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0)})
		e.Transparency = NumberSequence.new(0.1, 1)
		e.RotSpeed = NumberRange.new(-50, 50)
		e.SpreadAngle = Vector2.new(45, 45)
		e.Rate = 20
		e.Parent = parent
		return e
	end

	leftFootSmoke = makeSmoke(leftFoot)
	rightFootSmoke = makeSmoke(rightFoot)

	local leftStart  = createTrailAttachment(leftFoot, "TrailStart", Vector3.new(0, 0.3, 0))
	local leftEnd    = createTrailAttachment(leftFoot, "TrailEnd",   Vector3.new(0, -0.3, -0.5))
	local rightStart = createTrailAttachment(rightFoot, "TrailStart",Vector3.new(0, 0.3, 0))
	local rightEnd   = createTrailAttachment(rightFoot, "TrailEnd",  Vector3.new(0, -0.3, -0.5))

	leftFootTrail = __SIEXTHER_VIP_GLASS_V1.Instance.new("Trail")
	leftFootTrail.Attachment0 = leftStart
	leftFootTrail.Attachment1 = leftEnd
	leftFootTrail.Enabled = false
	leftFootTrail.Texture = "rbxassetid://13211689684"
	leftFootTrail.TextureLength = 5
	leftFootTrail.Lifetime = 0.2
	leftFootTrail.LightEmission = 1
	leftFootTrail.Transparency = NumberSequence.new(0.3, 1)
	leftFootTrail.Parent = leftFoot

	rightFootTrail = __SIEXTHER_VIP_GLASS_V1.Instance.new("Trail")
	rightFootTrail.Attachment0 = rightStart
	rightFootTrail.Attachment1 = rightEnd
	rightFootTrail.Enabled = false
	rightFootTrail.Texture = "rbxassetid://13211689684"
	rightFootTrail.TextureLength = 5
	rightFootTrail.Lifetime = 0.2
	rightFootTrail.LightEmission = 1
	rightFootTrail.Transparency = NumberSequence.new(0.3, 1)
	rightFootTrail.Parent = rightFoot
end

local function doAirJump()
	if not tallManEnabled then return end
	local vel = rootPart.Velocity
	rootPart.Velocity = Vector3.new(vel.X, jumpPower, vel.Z)
	jumpTrack:Stop()
	jumpTrack:Play()
end

local function toggleFakeDeath(actionName, inputState, inputObject)
	if not tallManEnabled then return end
	if inputState == Enum.UserInputState.Begin then
		if not isFakingDeath then
			fakeDeathTrack:Play()
			isFakingDeath = true
		else
			fakeDeathTrack:Stop()
			isFakingDeath = false
		end
	end
end

local function setupCharacter(char)
	character = char
	humanoid  = char:WaitForChild("Humanoid")
	rootPart  = char:WaitForChild("HumanoidRootPart")

	speed = 0
	currentMaxSpeed = baseMaxSpeed
	boostActive = false
	tauntCooldown = false
	jumpCount = 0

	loadAnimations()
	if tallManEnabled then
		idleTrack:Play()
	end
	setupVFX()

	local fakeDeathAnim = __SIEXTHER_VIP_GLASS_V1.Instance.new("Animation")
	fakeDeathAnim.AnimationId = fakeDeathAnimId
	fakeDeathTrack = humanoid:LoadAnimation(fakeDeathAnim)
	isFakingDeath = false

	humanoid.Jumping:Connect(function(active)
		if not tallManEnabled then return end
		if active and not tauntCooldown then
			jumpCount += 1
			if runTrack.IsPlaying then runTrack:Stop() end
			if idleTrack.IsPlaying then idleTrack:Stop() end
			if not jumpTrack.IsPlaying then jumpTrack:Play() end
		end
	end)

	humanoid.StateChanged:Connect(function(_, newState)
		if not tallManEnabled then return end
		local onGround = (
			newState == Enum.HumanoidStateType.Landed or
			newState == Enum.HumanoidStateType.Running or
			newState == Enum.HumanoidStateType.RunningNoPhysics
		)
		if onGround then
			jumpCount = 0
			if jumpTrack.IsPlaying then jumpTrack:Stop() end
			if speed > 0 then runTrack:Play() else idleTrack:Play() end
		end
	end)
end

UserInputService.JumpRequest:Connect(function()
	if not tallManEnabled then return end
	if not humanoid then return end
	local state = humanoid:GetState()
	local onGround = (
		state == Enum.HumanoidStateType.Running or
		state == Enum.HumanoidStateType.RunningNoPhysics or
		state == Enum.HumanoidStateType.Landed
	)
	if not onGround and jumpCount < maxJumps then
		jumpCount += 1
		doAirJump()
	end
end)

RunService.Heartbeat:Connect(function(dt)
	if not tallManEnabled then return end
	if not humanoid or not rootPart then return end

	local moveDir = humanoid.MoveDirection
	local state = humanoid:GetState()
	local onGround = (
		state == Enum.HumanoidStateType.Running or
		state == Enum.HumanoidStateType.RunningNoPhysics or
		state == Enum.HumanoidStateType.Landed
	)

	if moveDir.Magnitude > 0 then
		if boostActive then
			if leftFootSmoke then leftFootSmoke.Enabled = true end
			if rightFootSmoke then rightFootSmoke.Enabled = true end
			if leftFootTrail then leftFootTrail.Enabled = true end
			if rightFootTrail then rightFootTrail.Enabled = true end
		else
			if leftFootSmoke then leftFootSmoke.Enabled = false end
			if rightFootSmoke then rightFootSmoke.Enabled = false end
			if leftFootTrail then leftFootTrail.Enabled = false end
			if rightFootTrail then rightFootTrail.Enabled = false end
		end

		if boostActive then
			currentMaxSpeed = math.min(currentMaxSpeed + speedBuildRate * dt, topMaxSpeed)
			currentMaxSpeed = math.max(currentMaxSpeed, baseMaxSpeed)
		else
			currentMaxSpeed = math.min(currentMaxSpeed + speedBuildRate * dt, baseMaxSpeed)
		end

		local targetMax = boostActive and topMaxSpeed or baseMaxSpeed

		local slopeNormal = getSlopeNormal()
		local slopeMoveDir = (moveDir - slopeNormal * moveDir:Dot(slopeNormal)).Unit
		speed = math.min(speed + accel * dt * 60, targetMax)

		if onGround and not runTrack.IsPlaying and not tauntCooldown then
			idleTrack:Stop()
			runTrack:Play()
		end

		humanoid.WalkSpeed = speed
		rootPart.Velocity = slopeMoveDir * speed + Vector3.new(0, rootPart.Velocity.Y, 0)

	else
		speed = 0
		currentMaxSpeed = math.max(currentMaxSpeed - speedDecayRate * dt, baseMaxSpeed)

		if runTrack.IsPlaying then runTrack:Stop() end
		if leftFootSmoke then leftFootSmoke.Enabled = false end
		if rightFootSmoke then rightFootSmoke.Enabled = false end
		if leftFootTrail then leftFootTrail.Enabled = false end
		if rightFootTrail then rightFootTrail.Enabled = false end

		if onGround and not idleTrack.IsPlaying and not tauntCooldown then
			idleTrack:Play()
		end

		humanoid.WalkSpeed = 0
		rootPart.Velocity = Vector3.new(0, rootPart.Velocity.Y, 0)
	end
end)

-- Keyboard controls
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.T then
		doTaunt()
	elseif input.KeyCode == Enum.KeyCode.F then
		toggleFakeDeath("FakeDeathToggle", Enum.UserInputState.Begin, input)
	elseif input.KeyCode == boostKey then
		boostActive = true
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == boostKey then
		boostActive = false
	end
end)

-- Initialize
createGUI()
player.CharacterAdded:Connect(setupCharacter)
if player.Character then setupCharacter(player.Character) end