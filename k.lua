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
local BLACK = Color3.fromRGB(25, 25, 35)
local DARK_GRAY = Color3.fromRGB(35, 35, 45)
local WHITE = Color3.fromRGB(255, 255, 255)
local SKY_BLUE = Color3.fromRGB(70, 130, 255)
local BLUE_STROKE = Color3.fromRGB(70, 130, 255)
local MENU_ALPHA = 0.95

-- OPTIMIZED: Menggunakan thumbnail format untuk loading lebih cepat
local ICON_IMAGE = "rbxthumb://type=Asset&id=11560341824&w=150&h=150"

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- Load notification system
__SIEXTHER_VIP_GLASS_V1.LoadString(game:HttpGet("https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/han.lua"))()

-- Get creator thumbnail
local creatorUserId = nil
local creatorThumbnail = ""
local success, result = pcall(function()
    return Players:GetUserIdFromNameAsync("akuramaa_xd")
end)
if success then
    creatorUserId = result
    success, result = pcall(function()
        return Players:GetUserThumbnailAsync(creatorUserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if success then
        creatorThumbnail = result
    end
end

-- Notification function using new system
local function sendNotif(titleT, textT)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = titleT,
            Text = textT,
            Duration = 3
        })
    end)
end

-- State
local selectedProductId = nil
local selectedProductName = ""
local spamBuyActive = false
local spamBuyConnection = nil

-- Bypass function
local function Finished(id)
	pcall(function()
		MarketplaceService:SignalPromptProductPurchaseFinished(player.UserId, id, true)
	end)
end

-- Function spam buy
local function startSpamBuy()
    if not selectedProductId then        
        getgenv().Notify({Title = 'TERJADI KESALAHAN', Content = "Pilih item terlebih dahulu!", Duration = 3})
        return
    end
    
    spamBuyActive = true
    while spamBuyActive and selectedProductId do
        Finished(selectedProductId)
        task.wait(0.1)
    end
end

-- Hover effect function
local function hover(btn, col)
	local orig = btn.BackgroundColor3
	btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.16), {BackgroundColor3 = col}):Play() end)
	btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.16), {BackgroundColor3 = orig}):Play() end)
end

-- GUI interface
local function createSIEXTHERHan()
    local PlayerGui = player:WaitForChild("PlayerGui")
    if PlayerGui:FindFirstChild("SIEXTHERHan") then PlayerGui["SIEXTHERHan"]:Destroy() end

    local main = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
    main.Name = "SIEXTHERHan"
    main.ResetOnSpawn = false
    main.Parent = PlayerGui

    -- Main frame
    local Frame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
    Frame.Name = "Frame"
    Frame.Size = UDim2.new(0, 240, 0, 290)
    Frame.Position = UDim2.new(0.5, -120, 0.5, -145)
    Frame.BackgroundColor3 = BLACK
    
    Frame.BorderSizePixel = 0
    Frame.Active = false
    Frame.ClipsDescendants = true
    Frame.Parent = main
    
    local frameCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 10)
    frameCorner.Parent = Frame
    
    -- Blue stroke
    local frameStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
    frameStroke.Color = BLUE_STROKE
    frameStroke.Thickness = 2
    frameStroke.Parent = Frame

    -- Floating button (hidden initially) - CHANGED TO FRAME
    local floatingBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
    floatingBtn.Name = "FloatingButton"
    floatingBtn.Size = UDim2.new(0, 41, 0, 41)
    floatingBtn.Position = UDim2.new(1, -65, 0, 15)
    floatingBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    floatingBtn.Visible = false
    floatingBtn.Parent = main
    
    local floatCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
    floatCorner.CornerRadius = UDim.new(0, 12)
    floatCorner.Parent = floatingBtn

    -- ADD IMAGEBUTTON INSIDE FLOATING BUTTON (OPTIMIZED)
    local floatImage = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageButton")
    floatImage.Name = "FloatIcon"
    floatImage.Size = UDim2.new(1, -6, 1, -6)
    floatImage.Position = UDim2.new(0, 3, 0, 3)
    floatImage.BackgroundTransparency = 1
    floatImage.Image = ICON_IMAGE  -- OPTIMIZED
    floatImage.ScaleType = Enum.ScaleType.Fit
    floatImage.Parent = floatingBtn
    
    local floatIconCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
    floatIconCorner.CornerRadius = UDim.new(0, 10)
    floatIconCorner.Parent = floatImage

    -- Title bar for dragging
    local titleBar = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = Frame
    titleBar.Active = true

    -- Title
    local title = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
    title.Size = UDim2.new(1, -70, 0, 35)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.Text = "SIEXTHER FAKE DONATE"
    title.TextColor3 = WHITE
    title.BackgroundTransparency = 1
    title.BorderSizePixel = 0
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    -- Minimize button
    local miniBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    miniBtn.Name = "MinimizeButton"
    miniBtn.Size = UDim2.new(0, 28, 0, 28)
    miniBtn.Position = UDim2.new(1, -62, 0, 3.5)
    miniBtn.Text = "–"
    miniBtn.Font = Enum.Font.GothamBold
    miniBtn.TextSize = 18
    miniBtn.TextColor3 = WHITE
    miniBtn.BackgroundColor3 = DARK_GRAY
    miniBtn.Parent = titleBar
    
    local miniCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
    miniCorner.CornerRadius = UDim.new(0, 6)
    miniCorner.Parent = miniBtn
    hover(miniBtn, Color3.fromRGB(50, 50, 60))

    -- Close button
    local closeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -32, 0, 3.5)
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = Color3.fromRGB(255, 70, 70)
    closeBtn.BackgroundColor3 = DARK_GRAY
    closeBtn.Parent = titleBar
    closeBtn.ZIndex = 2
    
    local closeCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    hover(closeBtn, Color3.fromRGB(255, 100, 100))

    local draggingTitleBar = false
    local dragStart, startPos

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingTitleBar = true
            dragStart = input.Position
            startPos = Frame.Position
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingTitleBar = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingTitleBar and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Dragging for floating button - UPDATED TO USE IMAGEBUTTON
    local draggingFloat = false
    local floatDragStart, floatStartPos

    floatImage.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingFloat = true
            floatDragStart = input.Position
            floatStartPos = floatingBtn.Position
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingFloat = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingFloat and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - floatDragStart
            floatingBtn.Position = UDim2.new(floatStartPos.X.Scale, floatStartPos.X.Offset + delta.X, floatStartPos.Y.Scale, floatStartPos.Y.Offset + delta.Y)
        end
    end)

    local minimized = false
    miniBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Frame.Visible = false
            floatingBtn.Visible = true
        else
            Frame.Visible = true
            floatingBtn.Visible = false
        end
    end)

    -- Floating button click to restore - UPDATED TO USE IMAGEBUTTON
    floatImage.MouseButton1Click:Connect(function()
        Frame.Visible = true
        floatingBtn.Visible = false
        minimized = false
    end)

    -- Close logic
    closeBtn.MouseButton1Click:Connect(function()
        main:Destroy()
    end)

    -- Scroll list
    local scroll = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -83)
    scroll.Position = UDim2.new(0, 10, 0, 45)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = BLUE_STROKE
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.None
    scroll.ClipsDescendants = true
    scroll.Parent = Frame
    
    local layout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = scroll

    -- Button container di bawah (HORIZONTAL layout)
    local btnContainer = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
    btnContainer.Size = UDim2.new(1, -20, 0, 28)
    btnContainer.Position = UDim2.new(0, 10, 1, -38)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = Frame

    -- Purchase button (sky blue) - LEFT side
    local buy = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    buy.Name = "BuyButton"
    buy.Text = "BUY"
    buy.Font = Enum.Font.GothamBold
    buy.TextSize = 12
    buy.TextColor3 = WHITE
    buy.BackgroundColor3 = SKY_BLUE
    buy.Size = UDim2.new(0.48, 0, 1, 0)
    buy.Position = UDim2.new(0, 0, 0, 0)
    buy.Active = false
    buy.Parent = btnContainer
    __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", buy).CornerRadius = UDim.new(0, 8)
    hover(buy, Color3.fromRGB(90, 150, 255))

    -- SPAM BUY button (sky blue) - RIGHT side
    local spamBuy = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    spamBuy.Name = "SpamBuyButton"
    spamBuy.Text = "SPAM BUY"
    spamBuy.Font = Enum.Font.GothamBold
    spamBuy.TextSize = 12
    spamBuy.TextColor3 = WHITE
    spamBuy.BackgroundColor3 = SKY_BLUE
    spamBuy.Size = UDim2.new(0.48, 0, 1, 0)
    spamBuy.Position = UDim2.new(0.52, 0, 0, 0)
    spamBuy.Active = false
    spamBuy.Parent = btnContainer
    __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", spamBuy).CornerRadius = UDim.new(0, 8)
    hover(spamBuy, Color3.fromRGB(90, 150, 255))

    -- Card template
    local temp = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
    temp.Size = UDim2.new(1, 0, 0, 48)
    temp.BackgroundColor3 = DARK_GRAY
    temp.BackgroundTransparency = 0.18
    temp.Visible = false
    temp.Parent = scroll
    __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", temp).CornerRadius = UDim.new(0, 8)

    local hbg = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
    hbg.Size = UDim2.new(1, 0, 1, 0)
    hbg.BackgroundColor3 = DARK_GRAY
    hbg.BackgroundTransparency = 1
    hbg.Name = "HoverBg"
    hbg.Parent = temp
    __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", hbg).CornerRadius = UDim.new(0, 8)

    local sbg = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
    sbg.Size = UDim2.new(1, 0, 1, 0)
    sbg.BackgroundColor3 = BLUE_STROKE
    sbg.BackgroundTransparency = 1
    sbg.Name = "SelectedBg"
    sbg.Parent = temp
    __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", sbg).CornerRadius = UDim.new(0, 8)

    -- Icon ImageLabel (OPTIMIZED)
    local icon = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageLabel")
    icon.Name = "ItemIcon"
    icon.Size = UDim2.new(0, 38, 0, 38)
    icon.Position = UDim2.new(0, 5, 0.5, -19)
    icon.BackgroundTransparency = 1
    icon.Image = ICON_IMAGE  -- OPTIMIZED: Menggunakan thumbnail
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = temp
    
    local iconCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 6)
    iconCorner.Parent = icon

    local n = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
    n.Name = "NameLabel"
    n.Text = "Name: ..."
    n.Font = Enum.Font.GothamBold
    n.TextColor3 = WHITE
    n.TextSize = 11
    n.BackgroundTransparency = 1
    n.Size = UDim2.new(0.65, -48, 0, 18)
    n.Position = UDim2.new(0, 48, 0, 4)
    n.TextXAlignment = Enum.TextXAlignment.Left
    n.Parent = temp

    local p = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
    p.Name = "PriceLabel"
    p.Text = "0 Robux"
    p.Font = Enum.Font.GothamBold
    p.TextColor3 = Color3.fromRGB(155, 155, 155)
    p.TextSize = 10
    p.BackgroundTransparency = 1
    p.Size = UDim2.new(0.4, 0, 0, 16)
    p.Position = UDim2.new(0, 48, 0, 26)
    p.TextXAlignment = Enum.TextXAlignment.Left
    p.Parent = temp

    local clk = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    clk.Size = UDim2.new(1, 0, 1, 0)
    clk.BackgroundTransparency = 1
    clk.Text = ""
    clk.Name = "Click"
    clk.Parent = temp

    -- Load products + sort by price
    task.spawn(function()
        local success, products = pcall(MarketplaceService.GetDeveloperProductsAsync, MarketplaceService)
        if not success then 
            getgenv().Notify({Title = 'TERJADI KESALAHAN', Content = "Gagal memuat produk", Duration = 3})
            return 
        end

        local all = {}
        local page = products
        repeat
            for _, v in ipairs(page:GetCurrentPage()) do
                table.insert(all, v)
            end
            if not page.IsFinished then
                page:AdvanceToNextPageAsync()
                task.wait(0.05)
            end
        until page.IsFinished

        if #all == 0 then 
            getgenv().Notify({Title = 'TERJADI KESALAHAN', Content = "Tidak ada item yang ditemukan!", Duration = 3})
            return 
        end

        for _, c in ipairs(scroll:GetChildren()) do
            if c:IsA("Frame") and c ~= temp then c:Destroy() end
        end

        -- Sort from lowest to highest price
        table.sort(all, function(a, b)
            local priceA = a.PriceInRobux or 0
            local priceB = b.PriceInRobux or 0
            return priceA < priceB
        end)

        getgenv().Notify({Title = "MEMUAT", Content = #all .. " items", Duration = 4})

        local totalH = 0
        for _, info in ipairs(all) do
            local card = temp:Clone()
            card.Visible = true
            card.Parent = scroll
            card.NameLabel.Text = (info.Name or "???")
            card.PriceLabel.Text = (info.PriceInRobux or 0) .. " Robux"

            -- Hover effect
            card.Click.MouseEnter:Connect(function()
                if selectedProductId ~= info.ProductId then
                    TweenService:Create(card.HoverBg, TweenInfo.new(0.2), {BackgroundTransparency = 0.58}):Play()
                end
            end)
            card.Click.MouseLeave:Connect(function()
                if selectedProductId ~= info.ProductId then
                    TweenService:Create(card.HoverBg, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                end
            end)

            -- Select/Unselect
            card.Click.MouseButton1Click:Connect(function()
                if selectedProductId == info.ProductId then
                    -- Unselect
                    selectedProductId = nil
                    selectedProductName = ""
                    buy.Active = false
                    spamBuy.Active = false

                    TweenService:Create(card.SelectedBg, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                else
                    -- Select
                    selectedProductId = info.ProductId
                    selectedProductName = info.Name or "Unknown"
                    buy.Active = true
                    spamBuy.Active = true

                    for _, otherCard in ipairs(scroll:GetChildren()) do
                        if otherCard:IsA("Frame") and otherCard:FindFirstChild("SelectedBg") and otherCard ~= card then
                            TweenService:Create(otherCard.SelectedBg, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                        end
                    end
                    TweenService:Create(card.SelectedBg, TweenInfo.new(0.2), {BackgroundTransparency = 0.75}):Play()
                end
            end)

            totalH = totalH + card.Size.Y.Offset + layout.Padding.Offset
        end

        scroll.CanvasSize = UDim2.new(0, 0, 0, totalH + 8)
    end)

    -- Purchase button
    buy.MouseButton1Click:Connect(function()
        if not selectedProductId then 
            getgenv().Notify({Title = 'TERJADI KESALAHAN', Content = "Pilih item terlebih dahulu!", Duration = 3})
            return 
        end
        
        Finished(selectedProductId)
        getgenv().Notify({Title = 'SUCCESS', Content = "Pembelian berhasil!", Duration = 3})
        
        task.delay(1, function()
            buy.Text = "BUY"
            buy.BackgroundColor3 = SKY_BLUE
        end)
    end)

    -- Spam buy button
    spamBuy.MouseButton1Click:Connect(function()
        if not selectedProductId then
            getgenv().Notify({Title = 'TERJADI KESALAHAN', Content = "Pilih item terlebih dahulu!", Duration = 3})
            return
        end
        
        if spamBuyActive then
            spamBuyActive = false
            if spamBuyConnection then
                spamBuyConnection:Disconnect()
            end
            getgenv().Notify({Title = 'SPAM BUY', Content = 'DIMATIKAN', Duration = 3})
            spamBuy.Text = "SPAM BUY"
            spamBuy.BackgroundColor3 = SKY_BLUE
        else
            spamBuy.Text = "STOP"
            getgenv().Notify({Title = 'SPAM BUY', Content = 'AKTIF', Duration = 3})
            spamBuy.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            startSpamBuy()
        end
    end)

    return main
end

-- Initialize GUI
local guiInstance = createSIEXTHERHan()
guiInstance.Enabled = true