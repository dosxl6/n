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
-- SIEXTHER - Modern Dark Blue Design
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Pengaturan ESP
local ESPSettings = {
    Enabled = true,
    ShowName = false,
    ShowHealth = false,
    ShowLine = false,
    ShowGlow = false,
    ShowNPC = false,
    ShowNPCHealth = false,
    ShowNPCDistance = false,
    ShowNPCLine = false,
    ShowItems = false,
    ShowItemDistance = false,
    ShowItemLine = false
}

local ESPObjects = {}
local NPCObjects = {}
local ItemObjects = {}

-- Fungsi untuk membuat GUI
local ScreenGui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
ScreenGui.Name = "ESPPlayerGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

-- Frame utama dengan modern dark design
local MainFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 400)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- Stroke biru sky untuk frame utama (hanya luar)
local MainStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(70, 130, 255)
MainStroke.Thickness = 2
MainStroke.Transparency = 0
MainStroke.Parent = MainFrame

-- Header dengan gradient effect
local Header = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local HeaderFix = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 12)
HeaderFix.Position = UDim2.new(0, 0, 1, -12)
HeaderFix.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

-- Title dengan glow effect
local Title = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SIEXTHER ESP PLAYER"
Title.TextColor3 = Color3.fromRGB(70, 130, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Button Minimize (modern style)
local MinimizeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -65, 0.5, -15)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
MinimizeBtn.Text = "─"
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinimizeBtn.TextSize = 16
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Parent = Header

local MinimizeCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 8)
MinimizeCorner.Parent = MinimizeBtn

-- Button Close (modern style)
local CloseBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -32, 0.5, -15)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 60)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Header

local CloseCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

-- ScrollingFrame dengan dark design
local ScrollFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScrollingFrame")
ScrollFrame.Name = "ScrollFrame"
ScrollFrame.Size = UDim2.new(1, -20, 1, -55)
ScrollFrame.Position = UDim2.new(0, 10, 0, 50)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 520)
ScrollFrame.Parent = MainFrame

-- Fungsi untuk membuat divider modern
local function createDivider(yPos, text)
    local Divider = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
    Divider.Name = "Divider"
    Divider.Size = UDim2.new(1, 0, 0, 30)
    Divider.Position = UDim2.new(0, 0, 0, yPos)
    Divider.BackgroundTransparency = 1
    Divider.Parent = ScrollFrame
    
    local Label = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(70, 130, 255)
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamBold
    Label.Parent = Divider
    
    return Divider
end

-- Fungsi untuk membuat toggle button modern
local function createToggleButton(name, yPos, setting)
    local Button = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    Button.Name = name
    Button.Size = UDim2.new(1, 0, 0, 36)
    Button.Position = UDim2.new(0, 0, 0, yPos)
    Button.BackgroundColor3 = ESPSettings[setting] and Color3.fromRGB(70, 130, 255) or Color3.fromRGB(28, 28, 35)
    Button.Text = ""
    Button.BorderSizePixel = 0
    Button.Parent = ScrollFrame
    
    local BtnCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 10)
    BtnCorner.Parent = Button
    
    -- Label text
    local ButtonLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
    ButtonLabel.Size = UDim2.new(1, -70, 1, 0)
    ButtonLabel.Position = UDim2.new(0, 12, 0, 0)
    ButtonLabel.BackgroundTransparency = 1
    ButtonLabel.Text = name
    ButtonLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    ButtonLabel.TextSize = 13
    ButtonLabel.Font = Enum.Font.Gotham
    ButtonLabel.TextXAlignment = Enum.TextXAlignment.Left
    ButtonLabel.Parent = Button
    
    -- Status indicator dengan background
    local StatusBg = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
    StatusBg.Size = UDim2.new(0, 48, 0, 22)
    StatusBg.Position = UDim2.new(1, -56, 0.5, -11)
    StatusBg.BackgroundColor3 = ESPSettings[setting] and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(40, 40, 50)
    StatusBg.BorderSizePixel = 0
    StatusBg.Parent = Button
    
    local StatusCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 11)
    StatusCorner.Parent = StatusBg
    
    local StatusText = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
    StatusText.Name = "Status"
    StatusText.Size = UDim2.new(1, 0, 1, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = ESPSettings[setting] and "ON" or "OFF"
    StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatusText.TextSize = 11
    StatusText.Font = Enum.Font.GothamBold
    StatusText.Parent = StatusBg
    
    Button.MouseButton1Click:Connect(function()
        ESPSettings[setting] = not ESPSettings[setting]
        Button.BackgroundColor3 = ESPSettings[setting] and Color3.fromRGB(70, 130, 255) or Color3.fromRGB(28, 28, 35)
        StatusBg.BackgroundColor3 = ESPSettings[setting] and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(40, 40, 50)
        StatusText.Text = ESPSettings[setting] and "ON" or "OFF"
    end)
    
    return Button
end

-- === ESP PLAYER SECTION ===
createToggleButton("DISPLAY NAME", 0, "ShowName")
createToggleButton("HEALTH BAR", 41, "ShowHealth")
createToggleButton("LINE PLAYER", 82, "ShowLine")
createToggleButton("CHARACTER", 123, "ShowGlow")

-- === DIVIDER 1 ===
createDivider(169, "━━━━ ESP NPC ━━━━")

-- === ESP NPC SECTION ===
createToggleButton("SHOW NPC", 204, "ShowNPC")
createToggleButton("NPC HEALTH", 245, "ShowNPCHealth")
createToggleButton("NPC DISTANCE", 286, "ShowNPCDistance")
createToggleButton("NPC LINE", 327, "ShowNPCLine")

-- === DIVIDER 2 ===
createDivider(373, "━━━━ ESP ITEMS ━━━━")

-- === ESP ITEMS SECTION ===
createToggleButton("SHOW ITEMS", 408, "ShowItems")
createToggleButton("ITEM DISTANCE", 449, "ShowItemDistance")
createToggleButton("ITEM LINE", 490, "ShowItemLine")

-- Button Fire dengan modern design
local FireButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
FireButton.Name = "FireButton"
FireButton.Size = UDim2.new(0, 41, 0, 41)
FireButton.Position = UDim2.new(0, 15, 0.5, -22.5)
FireButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
FireButton.Text = "👁️"
FireButton.TextSize = 20
FireButton.Font = Enum.Font.GothamBold
FireButton.BorderSizePixel = 0
FireButton.Visible = false
FireButton.Active = true
FireButton.Draggable = true
FireButton.Parent = ScreenGui

local FireCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
FireCorner.CornerRadius = UDim.new(0, 12)
FireCorner.Parent = FireButton


-- Fungsi minimize
local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    MainFrame.Visible = not isMinimized
    FireButton.Visible = isMinimized
end)

FireButton.MouseButton1Click:Connect(function()
    isMinimized = false
    MainFrame.Visible = true
    FireButton.Visible = false
end)

-- Variable untuk connection
local renderConnection = nil

-- Fungsi close
CloseBtn.MouseButton1Click:Connect(function()
    ESPSettings.Enabled = false
    
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
    
    for _, espObj in pairs(ESPObjects) do
        if espObj.DisplayName then espObj.DisplayName:Remove() end
        if espObj.Username then espObj.Username:Remove() end
        if espObj.Health then espObj.Health:Remove() end
        if espObj.Line then espObj.Line:Remove() end
        if espObj.Highlight then espObj.Highlight:Destroy() end
    end
    
    for _, npcObj in pairs(NPCObjects) do
        if npcObj.Name then npcObj.Name:Remove() end
        if npcObj.Health then npcObj.Health:Remove() end
        if npcObj.Distance then npcObj.Distance:Remove() end
        if npcObj.Line then npcObj.Line:Remove() end
        if npcObj.Highlight then npcObj.Highlight:Destroy() end
    end
    
    for _, itemObj in pairs(ItemObjects) do
        if itemObj.Name then itemObj.Name:Remove() end
        if itemObj.Distance then itemObj.Distance:Remove() end
        if itemObj.Line then itemObj.Line:Remove() end
        if itemObj.Highlight then itemObj.Highlight:Destroy() end
    end
    
    ESPObjects = {}
    NPCObjects = {}
    ItemObjects = {}
    
    ScreenGui:Destroy()
    
    print("ESP GUI closed successfully!")
end)

-- [SISANYA SAMA SEPERTI KODE ASLI - FUNGSI ESP TIDAK BERUBAH]
-- Saya sengaja tidak menyalin ulang fungsi ESP karena hanya GUI yang diubah

local function createESP(player)
    if player == LocalPlayer then return end
    
    local esp = {
        DisplayName = nil,
        Username = nil,
        Health = nil,
        Line = nil,
        Highlight = nil
    }
    
    local displayLabel = Drawing.new("Text")
    displayLabel.Visible = false
    displayLabel.Center = true
    displayLabel.Outline = true
    displayLabel.Font = 2
    displayLabel.Size = 14
    displayLabel.Color = Color3.new(1, 1, 1)
    esp.DisplayName = displayLabel
    
    local usernameLabel = Drawing.new("Text")
    usernameLabel.Visible = false
    usernameLabel.Center = true
    usernameLabel.Outline = true
    usernameLabel.Font = 2
    usernameLabel.Size = 13
    usernameLabel.Color = Color3.new(0.7, 0.7, 0.7)
    esp.Username = usernameLabel
    
    local healthLabel = Drawing.new("Text")
    healthLabel.Visible = false
    healthLabel.Center = true
    healthLabel.Outline = true
    healthLabel.Font = 2
    healthLabel.Size = 12
    healthLabel.Color = Color3.new(0, 1, 0)
    esp.Health = healthLabel
    
    local line = Drawing.new("Line")
    line.Visible = false
    line.Thickness = 1
    line.Color = Color3.new(1, 1, 1)
    esp.Line = line
    
    ESPObjects[player] = esp
end

local function createPlayerHighlight(character)
    if not character then return nil end
    
    local existingHighlight = character:FindFirstChild("PlayerESPHighlight")
    if existingHighlight then
        return existingHighlight
    end
    
    local highlight = __SIEXTHER_VIP_GLASS_V1.Instance.new("Highlight")
    highlight.Name = "PlayerESPHighlight"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(135, 206, 250)
    highlight.OutlineColor = Color3.fromRGB(135, 206, 250)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    highlight.Parent = character
    
    return highlight
end

local function isNPC(model)
    if model:FindFirstChildOfClass("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character == model then
                return false
            end
        end
        return true
    end
    return false
end

local function createNPCESP(npcModel)
    if NPCObjects[npcModel] then return end
    
    local npcEsp = {
        Name = nil,
        Health = nil,
        Distance = nil,
        Line = nil,
        Highlight = nil
    }
    
    local nameLabel = Drawing.new("Text")
    nameLabel.Visible = false
    nameLabel.Center = true
    nameLabel.Outline = true
    nameLabel.Font = 2
    nameLabel.Size = 14
    nameLabel.Color = Color3.new(1, 0.3, 0.3)
    npcEsp.Name = nameLabel
    
    local healthLabel = Drawing.new("Text")
    healthLabel.Visible = false
    healthLabel.Center = true
    healthLabel.Outline = true
    healthLabel.Font = 2
    healthLabel.Size = 12
    healthLabel.Color = Color3.new(1, 0.5, 0)
    npcEsp.Health = healthLabel
    
    local distLabel = Drawing.new("Text")
    distLabel.Visible = false
    distLabel.Center = true
    distLabel.Outline = true
    distLabel.Font = 2
    distLabel.Size = 11
    distLabel.Color = Color3.new(0.8, 0.8, 0.8)
    npcEsp.Distance = distLabel
    
    local line = Drawing.new("Line")
    line.Visible = false
    line.Thickness = 1
    line.Color = Color3.new(1, 0.3, 0.3)
    npcEsp.Line = line
    
    local highlight = __SIEXTHER_VIP_GLASS_V1.Instance.new("Highlight")
    highlight.Name = "NPCHighlight"
    highlight.Adornee = npcModel
    highlight.FillColor = Color3.fromRGB(255, 80, 80)
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    highlight.Parent = npcModel
    npcEsp.Highlight = highlight
    
    NPCObjects[npcModel] = npcEsp
end

local function isPickupItem(obj)
    if obj:IsA("Tool") or obj:IsA("Model") then
        if obj:FindFirstChildOfClass("ClickDetector") or 
           obj:FindFirstChildOfClass("ProximityPrompt") or
           obj:FindFirstChild("Handle") then
            return true
        end
    elseif obj:IsA("Part") or obj:IsA("MeshPart") then
        if obj:FindFirstChildOfClass("ClickDetector") or 
           obj:FindFirstChildOfClass("ProximityPrompt") then
            return true
        end
    end
    return false
end

local function createItemESP(item)
    if ItemObjects[item] then return end
    
    local itemEsp = {
        Name = nil,
        Distance = nil,
        Line = nil,
        Highlight = nil
    }
    
    local nameLabel = Drawing.new("Text")
    nameLabel.Visible = false
    nameLabel.Center = true
    nameLabel.Outline = true
    nameLabel.Font = 2
    nameLabel.Size = 13
    nameLabel.Color = Color3.new(1, 1, 0)
    itemEsp.Name = nameLabel
    
    local distLabel = Drawing.new("Text")
    distLabel.Visible = false
    distLabel.Center = true
    distLabel.Outline = true
    distLabel.Font = 2
    distLabel.Size = 11
    distLabel.Color = Color3.new(0.9, 0.9, 0.9)
    itemEsp.Distance = distLabel
    
    local line = Drawing.new("Line")
    line.Visible = false
    line.Thickness = 1
    line.Color = Color3.new(1, 1, 0)
    itemEsp.Line = line
    
    local highlight = __SIEXTHER_VIP_GLASS_V1.Instance.new("Highlight")
    highlight.Name = "ItemHighlight"
    highlight.Adornee = item
    highlight.FillColor = Color3.fromRGB(255, 255, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    highlight.Parent = item
    itemEsp.Highlight = highlight
    
    ItemObjects[item] = itemEsp
end

local function updatePlayerESP()
    if not ESPSettings.Enabled then return end
    
    for player, esp in pairs(ESPObjects) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local hrp = player.Character.HumanoidRootPart
            local humanoid = player.Character.Humanoid
            
            local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            
            if onScreen then
                if ESPSettings.ShowName and esp.DisplayName then
                    esp.DisplayName.Visible = true
                    esp.DisplayName.Position = Vector2.new(vector.X, vector.Y - 50)
                    esp.DisplayName.Text = player.DisplayName
                    
                    esp.Username.Visible = true
                    esp.Username.Position = Vector2.new(vector.X, vector.Y - 35)
                    esp.Username.Text = "@" .. player.Name
                else
                    esp.DisplayName.Visible = false
                    esp.Username.Visible = false
                end
                
                if ESPSettings.ShowHealth and esp.Health then
                    esp.Health.Visible = true
                    esp.Health.Position = Vector2.new(vector.X, vector.Y - 20)
                    esp.Health.Text = string.format("HP: %d/%d", math.floor(humanoid.Health), math.floor(humanoid.MaxHealth))
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    esp.Health.Color = Color3.new(1 - healthPercent, healthPercent, 0)
                else
                    esp.Health.Visible = false
                end
                
                if ESPSettings.ShowLine and esp.Line then
                    esp.Line.Visible = true
                    esp.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    esp.Line.To = Vector2.new(vector.X, vector.Y)
                else
                    esp.Line.Visible = false
                end
                
                if ESPSettings.ShowGlow then
                    local highlight = createPlayerHighlight(player.Character)
                    if highlight then
                        highlight.Enabled = true
                        esp.Highlight = highlight
                    end
                else
                    if esp.Highlight then
                        esp.Highlight.Enabled = false
                    end
                end
            else
                esp.DisplayName.Visible = false
                esp.Username.Visible = false
                esp.Health.Visible = false
                esp.Line.Visible = false
                if esp.Highlight then
                    esp.Highlight.Enabled = false
                end
            end
        else
            esp.DisplayName.Visible = false
            esp.Username.Visible = false
            esp.Health.Visible = false
            esp.Line.Visible = false
            if esp.Highlight then
                esp.Highlight.Enabled = false
            end
        end
    end
end

local function updateNPCESP()
    if not ESPSettings.ShowNPC then
        for _, npcEsp in pairs(NPCObjects) do
            npcEsp.Name.Visible = false
            if npcEsp.Health then npcEsp.Health.Visible = false end
            if npcEsp.Distance then npcEsp.Distance.Visible = false end
            if npcEsp.Line then npcEsp.Line.Visible = false end
            if npcEsp.Highlight then npcEsp.Highlight.Enabled = false end
        end
        return
    end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isNPC(obj) then
            createNPCESP(obj)
        end
    end
    
    for npcModel, npcEsp in pairs(NPCObjects) do
        if npcModel and npcModel.Parent and npcModel:FindFirstChild("HumanoidRootPart") then
            local hrp = npcModel.HumanoidRootPart
            local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
            
            local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            
            if onScreen then
                npcEsp.Name.Visible = true
                npcEsp.Name.Position = Vector2.new(vector.X, vector.Y - 40)
                npcEsp.Name.Text = npcModel.Name
                
                if ESPSettings.ShowNPCHealth and humanoid and npcEsp.Health then
                    npcEsp.Health.Visible = true
                    npcEsp.Health.Position = Vector2.new(vector.X, vector.Y - 25)
                    npcEsp.Health.Text = string.format("HP: %d", math.floor(humanoid.Health))
                else
                    npcEsp.Health.Visible = false
                end
                
                if ESPSettings.ShowNPCDistance and npcEsp.Distance and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                    npcEsp.Distance.Visible = true
                    npcEsp.Distance.Position = Vector2.new(vector.X, vector.Y - 10)
                    npcEsp.Distance.Text = string.format("[%.1fm]", distance)
                else
                    npcEsp.Distance.Visible = false
                end
                
                if ESPSettings.ShowNPCLine and npcEsp.Line then
                    npcEsp.Line.Visible = true
                    npcEsp.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    npcEsp.Line.To = Vector2.new(vector.X, vector.Y)
                else
                    npcEsp.Line.Visible = false
                end
                
                if npcEsp.Highlight then
                    npcEsp.Highlight.Enabled = true
                end
            else
                npcEsp.Name.Visible = false
                if npcEsp.Health then npcEsp.Health.Visible = false end
                if npcEsp.Distance then npcEsp.Distance.Visible = false end
                if npcEsp.Line then npcEsp.Line.Visible = false end
                if npcEsp.Highlight then npcEsp.Highlight.Enabled = false end
            end
        end
    end
end

local function updateItemESP()
    if not ESPSettings.ShowItems then
        for _, itemEsp in pairs(ItemObjects) do
            itemEsp.Name.Visible = false
            if itemEsp.Distance then itemEsp.Distance.Visible = false end
            if itemEsp.Line then itemEsp.Line.Visible = false end
            if itemEsp.Highlight then itemEsp.Highlight.Enabled = false end
        end
        return
    end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isPickupItem(obj) then
            createItemESP(obj)
        end
    end
    
    for item, itemEsp in pairs(ItemObjects) do
        if item and item.Parent and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local pos = item:IsA("Model") and item:GetPivot().Position or item.Position
            local vector, onScreen = Camera:WorldToViewportPoint(pos)
            
            if onScreen then
                itemEsp.Name.Visible = true
                itemEsp.Name.Position = Vector2.new(vector.X, vector.Y - 20)
                itemEsp.Name.Text = item.Name
                
                if ESPSettings.ShowItemDistance and itemEsp.Distance then
                    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - pos).Magnitude
                    itemEsp.Distance.Visible = true
                    itemEsp.Distance.Position = Vector2.new(vector.X, vector.Y - 5)
                    itemEsp.Distance.Text = string.format("[%.1fm]", distance)
                else
                    itemEsp.Distance.Visible = false
                end
                
                if ESPSettings.ShowItemLine and itemEsp.Line then
                    itemEsp.Line.Visible = true
                    itemEsp.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    itemEsp.Line.To = Vector2.new(vector.X, vector.Y)
                else
                    itemEsp.Line.Visible = false
                end
                
                if itemEsp.Highlight then
                    itemEsp.Highlight.Enabled = true
                end
            else
                itemEsp.Name.Visible = false
                if itemEsp.Distance then itemEsp.Distance.Visible = false end
                if itemEsp.Line then itemEsp.Line.Visible = false end
                if itemEsp.Highlight then itemEsp.Highlight.Enabled = false end
            end
        end
    end
end

-- Initialize ESP for existing players
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

-- Handle new players
Players.PlayerAdded:Connect(function(player)
    createESP(player)
end)

-- Handle player removing
Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        if ESPObjects[player].DisplayName then ESPObjects[player].DisplayName:Remove() end
        if ESPObjects[player].Username then ESPObjects[player].Username:Remove() end
        if ESPObjects[player].Health then ESPObjects[player].Health:Remove() end
        if ESPObjects[player].Line then ESPObjects[player].Line:Remove() end
        if ESPObjects[player].Highlight then ESPObjects[player].Highlight:Destroy() end
        ESPObjects[player] = nil
    end
end)

-- Main render loop
renderConnection = RunService.RenderStepped:Connect(function()
    if ESPSettings.Enabled then
        updatePlayerESP()
        updateNPCESP()
        updateItemESP()
    end
end)
