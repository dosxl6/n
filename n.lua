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
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Variables
local autoHeadsitEnabled = false
local autoHeadsitConnection = nil
local godModeConnection = nil
local movementConnection = nil
local currentTarget = nil
local selectedPlayer = nil
local currentAnimation = nil
local currentMode = 1 

-- Create ScreenGui
local screenGui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
screenGui.Name = "SIEXTHERHANN"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 240, 0, 345)
mainFrame.Position = UDim2.new(0.5, -120, 0.5, -203)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
mainFrame.BackgroundTransparency = 0
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Add rounded corners
local mainCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Add Blue Stroke to Main Frame
local mainStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(70, 130, 255)
mainStroke.Thickness = 2
mainStroke.Transparency = 0
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
mainStroke.Parent = mainFrame

-- Create Top Bar
local topBar = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 38)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
topBar.BackgroundTransparency = 0
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local topBarCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 12)
topBarCorner.Parent = topBar

-- Fix bottom corners of topBar
local topBarFix = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
topBarFix.Size = UDim2.new(1, 0, 0, 12)
topBarFix.Position = UDim2.new(0, 0, 1, -12)
topBarFix.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
topBarFix.BackgroundTransparency = 0
topBarFix.BorderSizePixel = 0
topBarFix.Parent = topBar

-- Title
local title = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -70, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "SIEXTHER KIMOCHI"
title.TextColor3 = Color3.fromRGB(70, 130, 255)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

-- Minimize Button
local minimizeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, 26, 0, 26)
minimizeBtn.Position = UDim2.new(1, -58, 0.5, -13)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
minimizeBtn.Text = "–"
minimizeBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
minimizeBtn.TextSize = 18
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = topBar

local minimizeBtnCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
minimizeBtnCorner.CornerRadius = UDim.new(0, 6)
minimizeBtnCorner.Parent = minimizeBtn

-- Close Button
local closeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -28, 0.5, -13)
closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 70, 90)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = topBar

local closeBtnCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent = closeBtn

-- Content Frame
local contentFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -20, 1, -48)
contentFrame.Position = UDim2.new(0, 10, 0, 43)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Status Label
local statusLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "STATUS: TIDAK AKTIF"
statusLabel.TextColor3 = Color3.fromRGB(255, 70, 90)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Parent = contentFrame

-- Player List Label
local playerListLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
playerListLabel.Name = "PlayerListLabel"
playerListLabel.Size = UDim2.new(1, 0, 0, 16)
playerListLabel.Position = UDim2.new(0, 0, 0, 22)
playerListLabel.BackgroundTransparency = 1
playerListLabel.Text = "Pilih Player:"
playerListLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
playerListLabel.TextSize = 11
playerListLabel.Font = Enum.Font.Gotham
playerListLabel.TextXAlignment = Enum.TextXAlignment.Left
playerListLabel.Parent = contentFrame

-- Search Box
local searchBox = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, 0, 0, 30)
searchBox.Position = UDim2.new(0, 0, 0, 40)
searchBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
searchBox.BackgroundTransparency = 0
searchBox.BorderSizePixel = 0
searchBox.PlaceholderText = "Cari Player..."
searchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
searchBox.Text = ""
searchBox.TextColor3 = Color3.fromRGB(200, 200, 210)
searchBox.TextSize = 11
searchBox.Font = Enum.Font.Gotham
searchBox.ClearTextOnFocus = false
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Parent = contentFrame

local searchBoxCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
searchBoxCorner.CornerRadius = UDim.new(0, 6)
searchBoxCorner.Parent = searchBox

local searchBoxPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
searchBoxPadding.PaddingLeft = UDim.new(0, 8)
searchBoxPadding.PaddingRight = UDim.new(0, 8)
searchBoxPadding.Parent = searchBox

-- Player Count Label
local playerCountLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
playerCountLabel.Name = "PlayerCountLabel"
playerCountLabel.Size = UDim2.new(1, 0, 0, 14)
playerCountLabel.Position = UDim2.new(0, 0, 0, 74)
playerCountLabel.BackgroundTransparency = 1
playerCountLabel.Text = "PLAYERS: 0"
playerCountLabel.TextColor3 = Color3.fromRGB(120, 120, 130)
playerCountLabel.TextSize = 9
playerCountLabel.Font = Enum.Font.Gotham
playerCountLabel.TextXAlignment = Enum.TextXAlignment.Left
playerCountLabel.Parent = contentFrame

-- Player List ScrollFrame
local playerListFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScrollingFrame")
playerListFrame.Name = "PlayerListFrame"
playerListFrame.Size = UDim2.new(1, 0, 0, 95)
playerListFrame.Position = UDim2.new(0, 0, 0, 90)
playerListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
playerListFrame.BackgroundTransparency = 0
playerListFrame.BorderSizePixel = 0
playerListFrame.ScrollBarThickness = 3
playerListFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
playerListFrame.Parent = contentFrame

local playerListCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
playerListCorner.CornerRadius = UDim.new(0, 6)
playerListCorner.Parent = playerListFrame

local listLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 3)
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Parent = playerListFrame

local listPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 3)
listPadding.PaddingBottom = UDim.new(0, 3)
listPadding.PaddingLeft = UDim.new(0, 3)
listPadding.PaddingRight = UDim.new(0, 3)
listPadding.Parent = playerListFrame

-- Mode Selection Frame
local modeFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
modeFrame.Name = "ModeFrame"
modeFrame.Size = UDim2.new(1, 0, 0, 34)
modeFrame.Position = UDim2.new(0, 0, 0, 193)
modeFrame.BackgroundTransparency = 1
modeFrame.Parent = contentFrame

-- Mode 1 Button (Sit)
local mode1Btn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
mode1Btn.Name = "Mode1Btn"
mode1Btn.Size = UDim2.new(0.48, 0, 1, 0)
mode1Btn.Position = UDim2.new(0, 0, 0, 0)
mode1Btn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
mode1Btn.Text = "KIMOCHI"
mode1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
mode1Btn.TextSize = 11
mode1Btn.Font = Enum.Font.GothamBold
mode1Btn.BorderSizePixel = 0
mode1Btn.Parent = modeFrame

local mode1BtnCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
mode1BtnCorner.CornerRadius = UDim.new(0, 6)
mode1BtnCorner.Parent = mode1Btn

-- Mode 2 Button (Stand)
local mode2Btn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
mode2Btn.Name = "Mode2Btn"
mode2Btn.Size = UDim2.new(0.48, 0, 1, 0)
mode2Btn.Position = UDim2.new(0.52, 0, 0, 0)
mode2Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
mode2Btn.Text = "RODOK"
mode2Btn.TextColor3 = Color3.fromRGB(150, 150, 160)
mode2Btn.TextSize = 11
mode2Btn.Font = Enum.Font.GothamBold
mode2Btn.BorderSizePixel = 0
mode2Btn.Parent = modeFrame

local mode2BtnCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
mode2BtnCorner.CornerRadius = UDim.new(0, 6)
mode2BtnCorner.Parent = mode2Btn

-- Toggle Button
local toggleBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
toggleBtn.Name = "ToggleBtn"
toggleBtn.Size = UDim2.new(1, 0, 0, 38)
toggleBtn.Position = UDim2.new(0, 0, 0, 235)
toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
toggleBtn.Text = "AKTIFKAN"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 13
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = contentFrame

local toggleBtnCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
toggleBtnCorner.CornerRadius = UDim.new(0, 7)
toggleBtnCorner.Parent = toggleBtn

-- Info Label
local infoLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
infoLabel.Name = "InfoLabel"
infoLabel.Size = UDim2.new(1, 0, 0, 16)
infoLabel.Position = UDim2.new(0, 0, 1, -16)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Pilih pemain yang ingin ditargetkan!"
infoLabel.TextColor3 = Color3.fromRGB(130, 130, 140)
infoLabel.TextSize = 10
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextWrapped = true
infoLabel.Parent = contentFrame

-- Minimized Button (Fire)
local fireBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
fireBtn.Name = "FireBtn"
fireBtn.Size = UDim2.new(0, 41, 0, 41)
fireBtn.Position = UDim2.new(1, -70, 0.5, -22)
fireBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
fireBtn.Text = "SX"
fireBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
fireBtn.TextSize = 25
fireBtn.Font = Enum.Font.GothamBold
fireBtn.BorderSizePixel = 0
fireBtn.Visible = false
fireBtn.Active = true
fireBtn.Draggable = true
fireBtn.Parent = screenGui

-- Gradient Animation untuk Minimized Button
local MinimizedGradient = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient")
MinimizedGradient.Parent = fireBtn
MinimizedGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
MinimizedGradient.Offset = Vector2.new(-1, 0)

task.spawn(function()
    while fireBtn and fireBtn.Parent do
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

local fireBtnCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
fireBtnCorner.CornerRadius = UDim.new(0, 12)
fireBtnCorner.Parent = fireBtn

-- God Mode Function
local function enableGodMode()
    if godModeConnection then
        godModeConnection:Disconnect()
    end
    
    godModeConnection = RunService.Heartbeat:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            local humanoid = char.Humanoid
            
            if humanoid.Health < humanoid.MaxHealth then
                humanoid.Health = humanoid.MaxHealth
            end
            
            humanoid.MaxHealth = math.huge
            humanoid.Health = math.huge
        end
    end)
end

local function disableGodMode()
    if godModeConnection then
        godModeConnection:Disconnect()
        godModeConnection = nil
    end
    
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        local humanoid = char.Humanoid
        humanoid.MaxHealth = 100
        humanoid.Health = 100
    end
end

-- Load and play animation
local function loadAnimation()
    local char = player.Character
    if not char then return end
    
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    if currentAnimation then
        currentAnimation:Stop()
        currentAnimation = nil
    end
    
    local animation = __SIEXTHER_VIP_GLASS_V1.Instance.new("Animation")
    animation.AnimationId = "rbxassetid://698251653"
    
    currentAnimation = humanoid:LoadAnimation(animation)
    currentAnimation.Looped = false
    currentAnimation:Play()
    currentAnimation.TimePosition = 0.58
    currentAnimation:AdjustSpeed(0.4)
    
    task.spawn(function()
        while currentAnimation and currentAnimation.IsPlaying and autoHeadsitEnabled do
            if currentAnimation.TimePosition >= 0.63 then
                currentAnimation.TimePosition = 0.58
            end
            task.wait()
        end
    end)
end

-- Fungsi animasi maju mundur untuk Mode 1 (Sit)
local function startForwardBackwardMovement()
    if movementConnection then
        movementConnection:Disconnect()
    end
    
    local movementSpeed = 15
    local movementDistance = 0.3
    local time = 0
    
    movementConnection = RunService.Heartbeat:Connect(function(deltaTime)
        time = time + deltaTime * movementSpeed
        
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            return
        end
        
        if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("Head") then
            local targetHead = selectedPlayer.Character.Head
            local targetHRP = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if targetHRP then
                local targetLook = targetHRP.CFrame.LookVector
                local headPosition = targetHead.CFrame.Position
                
                -- Tambahkan offset maju mundur menggunakan sin wave
                local forwardBackwardOffset = math.sin(time) * movementDistance
                
                local offsetPosition = headPosition + Vector3.new(0, 0.4, 0) - (targetLook * (-1.8 + forwardBackwardOffset))
                local oppositeLook = -targetLook
                
                char.HumanoidRootPart.CFrame = CFrame.new(
                    offsetPosition,
                    offsetPosition + oppositeLook
                )
            end
        end
    end)
end

-- Fungsi untuk Mode 2 (Stand Behind) dengan speed 35
local function startStandBehindMovement()
    if movementConnection then
        movementConnection:Disconnect()
    end
    
    local movementSpeed = 25
    local movementDistance = 0.3
    local time = 0
    
    movementConnection = RunService.Heartbeat:Connect(function(deltaTime)
        time = time + deltaTime * movementSpeed
        
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            return
        end
        
        if selectedPlayer and selectedPlayer.Character then
            local targetHRP = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if targetHRP then
                local targetLook = targetHRP.CFrame.LookVector
                local targetPosition = targetHRP.CFrame.Position
                
                -- Tambahkan offset maju mundur menggunakan sin wave
                local forwardBackwardOffset = math.sin(time) * movementDistance
                
                -- Posisi di belakang target dengan jarak 2 studs + animasi maju mundur
                local offsetPosition = targetPosition - (targetLook * (1 + forwardBackwardOffset))
                
                -- Menghadap ke arah yang sama dengan target
                char.HumanoidRootPart.CFrame = CFrame.new(
                    offsetPosition,
                    offsetPosition + targetLook
                )
            end
        end
    end)
end

local function stopForwardBackwardMovement()
    if movementConnection then
        movementConnection:Disconnect()
        movementConnection = nil
    end
end

-- Functions
local function updatePlayerList(searchText)
    searchText = searchText or ""
    searchText = searchText:lower()
    
    for _, child in pairs(playerListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local playerCount = 0
    
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local displayName = otherPlayer.DisplayName:lower()
            local userName = otherPlayer.Name:lower()
            
            if searchText == "" or displayName:find(searchText, 1, true) or userName:find(searchText, 1, true) then
                playerCount = playerCount + 1
                
                local playerBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
                playerBtn.Name = otherPlayer.Name
                playerBtn.Size = UDim2.new(1, -6, 0, 36)
                playerBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
                playerBtn.BackgroundTransparency = 0
                playerBtn.BorderSizePixel = 0
                playerBtn.Text = ""
                playerBtn.AutoButtonColor = false
                playerBtn.Parent = playerListFrame
                
                local playerBtnCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
                playerBtnCorner.CornerRadius = UDim.new(0, 5)
                playerBtnCorner.Parent = playerBtn
                
                -- Avatar Image
                local avatarImg = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageLabel")
                avatarImg.Name = "Avatar"
                avatarImg.Size = UDim2.new(0, 28, 0, 28)
                avatarImg.Position = UDim2.new(0, 4, 0.5, -14)
                avatarImg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                avatarImg.BorderSizePixel = 0
                avatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. otherPlayer.UserId .. "&w=48&h=48"
                avatarImg.Parent = playerBtn
                
                local avatarCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
                avatarCorner.CornerRadius = UDim.new(0, 14)
                avatarCorner.Parent = avatarImg
                
                -- Display Name
                local displayNameLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
                displayNameLabel.Size = UDim2.new(1, -42, 0, 14)
                displayNameLabel.Position = UDim2.new(0, 36, 0, 4)
                displayNameLabel.BackgroundTransparency = 1
                displayNameLabel.Text = otherPlayer.DisplayName
                displayNameLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
                displayNameLabel.TextSize = 11
                displayNameLabel.Font = Enum.Font.GothamBold
                displayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
                displayNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                displayNameLabel.Parent = playerBtn
                
                -- Username
                local userNameLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
                userNameLabel.Size = UDim2.new(1, -42, 0, 11)
                userNameLabel.Position = UDim2.new(0, 36, 0, 18)
                userNameLabel.BackgroundTransparency = 1
                userNameLabel.Text = "@" .. otherPlayer.Name
                userNameLabel.TextColor3 = Color3.fromRGB(120, 120, 130)
                userNameLabel.TextSize = 9
                userNameLabel.Font = Enum.Font.Gotham
                userNameLabel.TextXAlignment = Enum.TextXAlignment.Left
                userNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                userNameLabel.Parent = playerBtn
                
                playerBtn.MouseButton1Click:Connect(function()
                    selectedPlayer = otherPlayer
                    
                    for _, btn in pairs(playerListFrame:GetChildren()) do
                        if btn:IsA("TextButton") then
                            btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
                        end
                    end
                    
                    playerBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
                    infoLabel.Text = "Selected: " .. otherPlayer.DisplayName
                end)
                
                playerBtn.MouseEnter:Connect(function()
                    if selectedPlayer ~= otherPlayer then
                        TweenService:Create(playerBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 45)}):Play()
                    end
                end)
                
                playerBtn.MouseLeave:Connect(function()
                    if selectedPlayer ~= otherPlayer then
                        TweenService:Create(playerBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(25, 25, 35)}):Play()
                    end
                end)
            end
        end
    end
    
    playerCountLabel.Text = "Players: " .. playerCount
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 6)
end

local function startHeadsit()
    if autoHeadsitConnection then
        autoHeadsitConnection:Disconnect()
    end
    
    if not selectedPlayer then
        infoLabel.Text = "Silahkan pilih target dulu!"
        return
    end
    
    enableGodMode()
    
    if currentMode == 1 then
        -- Mode 1: Sit
        loadAnimation()
        startForwardBackwardMovement()
        
        autoHeadsitConnection = RunService.Heartbeat:Connect(function()
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then
                return
            end
            
            if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("Head") then
                currentTarget = selectedPlayer.Name
                
                if char:FindFirstChild("Humanoid") then
                    char.Humanoid.Sit = true
                end
            else
                infoLabel.Text = "Pemain target tidak ditemukan!"
                infoLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
            end
        end)
    else
        -- Mode 2: Stand Behind dengan animasi
        loadAnimation()  -- Tetap pakai animasi
        startStandBehindMovement()  -- Pakai movement maju mundur dengan speed 35
        
        autoHeadsitConnection = RunService.Heartbeat:Connect(function()
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then
                return
            end
            
            if selectedPlayer and selectedPlayer.Character then
                currentTarget = selectedPlayer.Name
                
                -- Tidak set Sit = true, biarkan berdiri
                if char:FindFirstChild("Humanoid") then
                    char.Humanoid.Sit = false
                end
            else
                infoLabel.Text = "Pemain target tidak ditemukan!"
                infoLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
            end
        end)
    end
end

local function stopHeadsit()
    if autoHeadsitConnection then
        autoHeadsitConnection:Disconnect()
        autoHeadsitConnection = nil
    end
    
    stopForwardBackwardMovement()
    
    if currentAnimation then
        currentAnimation:Stop()
        currentAnimation = nil
    end
    
    disableGodMode()
    
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.Sit = false
        char.Humanoid.PlatformStand = false
    end
    
    currentTarget = nil
end

-- Fungsi untuk mengganti mode dengan restart otomatis jika sedang aktif
local function switchMode(newMode)
    if currentMode == newMode then
        return -- Sudah di mode yang sama
    end
    
    local wasEnabled = autoHeadsitEnabled
    
    -- Jika sedang aktif, stop dulu
    if wasEnabled then
        stopHeadsit()
    end
    
    -- Ganti mode
    currentMode = newMode
    
    -- Update tampilan button
    if currentMode == 1 then
        mode1Btn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        mode1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        mode2Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        mode2Btn.TextColor3 = Color3.fromRGB(150, 150, 160)
    else
        mode2Btn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        mode2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        mode1Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        mode1Btn.TextColor3 = Color3.fromRGB(150, 150, 160)
    end
    
    -- Jika sebelumnya aktif, start lagi dengan mode baru
    if wasEnabled then
        startHeadsit()
        
        -- Update info label
        if currentMode == 1 then
            infoLabel.Text = "KIMOCHI: " .. selectedPlayer.DisplayName
        else
            infoLabel.Text = "RODOK: " .. selectedPlayer.DisplayName
        end
        infoLabel.TextColor3 = Color3.fromRGB(70, 255, 130)
    else
        -- Update info label untuk mode yang dipilih
        if currentMode == 1 then
            infoLabel.Text = "Mode Kimochi"
        else
            infoLabel.Text = "Mode Rodok"
        end
        infoLabel.TextColor3 = Color3.fromRGB(70, 130, 255)
    end
end

-- Mode Selection - Sekarang bisa ganti kapan saja
mode1Btn.MouseButton1Click:Connect(function()
    switchMode(1)
end)

mode2Btn.MouseButton1Click:Connect(function()
    switchMode(2)
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    updatePlayerList(searchBox.Text)
end)

searchBox.Focused:Connect(function()
    searchBox.PlaceholderText = "Ketik untuk mencari..."
end)

searchBox.FocusLost:Connect(function()
    searchBox.PlaceholderText = "Cari player..."
end)

toggleBtn.MouseButton1Click:Connect(function()
    if not selectedPlayer then
        infoLabel.Text = "Silahkan pilih target dulu!"
        infoLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
        
        TweenService:Create(toggleBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(255, 150, 100)}):Play()
        wait(0.1)
        TweenService:Create(toggleBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(70, 130, 255)}):Play()
        
        wait(2)
        infoLabel.TextColor3 = Color3.fromRGB(130, 130, 140)
        infoLabel.Text = "Pilih pemain yang ingin ditargetkan!"
        return
    end
    
    autoHeadsitEnabled = not autoHeadsitEnabled
    
    if autoHeadsitEnabled then
        toggleBtn.Text = "MATIKAN"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 90)
        statusLabel.Text = "STATUS: AKTIF"
        statusLabel.TextColor3 = Color3.fromRGB(70, 255, 130)
        
        if currentMode == 1 then
            infoLabel.Text = "KIMOCHI: " .. selectedPlayer.DisplayName
        else
            infoLabel.Text = "FOLLOWING: " .. selectedPlayer.DisplayName
        end
        
        infoLabel.TextColor3 = Color3.fromRGB(70, 255, 130)
        startHeadsit()
    else
        toggleBtn.Text = "AKTIFKAN"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        statusLabel.Text = "STATUS: TIDAK AKTIF"
        statusLabel.TextColor3 = Color3.fromRGB(255, 70, 90)
        infoLabel.Text = "Pilih pemain yang ingin ditargetkan!"
        infoLabel.TextColor3 = Color3.fromRGB(130, 130, 140)
        stopHeadsit()
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(mainFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    TweenService:Create(mainStroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
    for _, child in pairs(mainFrame:GetDescendants()) do
        if child:IsA("GuiObject") then
            local props = {BackgroundTransparency = 1}
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                props.TextTransparency = 1
            end
            TweenService:Create(child, TweenInfo.new(0.3), props):Play()
        end
    end
    
    wait(0.3)
    stopHeadsit()
    screenGui:Destroy()
end)

minimizeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    fireBtn.Visible = true
end)

fireBtn.MouseButton1Click:Connect(function()
    fireBtn.Visible = false
    mainFrame.Visible = true
end)

local function addHoverEffect(btn, normalColor, hoverColor)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = normalColor}):Play()
    end)
end

addHoverEffect(closeBtn, Color3.fromRGB(30, 30, 40), Color3.fromRGB(255, 70, 90))
addHoverEffect(minimizeBtn, Color3.fromRGB(30, 30, 40), Color3.fromRGB(70, 130, 255))
addHoverEffect(fireBtn, Color3.fromRGB(15, 15, 20), Color3.fromRGB(70, 130, 255))

-- Hover effects untuk mode buttons
mode1Btn.MouseEnter:Connect(function()
    if currentMode ~= 1 then
        TweenService:Create(mode1Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
    end
end)

mode1Btn.MouseLeave:Connect(function()
    if currentMode ~= 1 then
        TweenService:Create(mode1Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
    end
end)

mode2Btn.MouseEnter:Connect(function()
    if currentMode ~= 2 then
        TweenService:Create(mode2Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
    end
end)

mode2Btn.MouseLeave:Connect(function()
    if currentMode ~= 2 then
        TweenService:Create(mode2Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
    end
end)

toggleBtn.MouseEnter:Connect(function()
    if autoHeadsitEnabled then
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 50, 70)}):Play()
    else
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(90, 150, 255)}):Play()
    end
end)

toggleBtn.MouseLeave:Connect(function()
    if autoHeadsitEnabled then
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 70, 90)}):Play()
    else
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 130, 255)}):Play()
    end
end)

updatePlayerList()

Players.PlayerAdded:Connect(function()
    wait(0.5)
    updatePlayerList(searchBox.Text)
end)

Players.PlayerRemoving:Connect(function(removingPlayer)
    updatePlayerList(searchBox.Text)
    
    if selectedPlayer == removingPlayer then
        selectedPlayer = nil
        if autoHeadsitEnabled then
            autoHeadsitEnabled = false
            toggleBtn.Text = "AKTIFKAN"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
            statusLabel.Text = "STATUS: TIDAK AKTIF"
            statusLabel.TextColor3 = Color3.fromRGB(255, 70, 90)
            infoLabel.Text = "Pemain yang menjadi target keluar dari permainan."
            infoLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
            stopHeadsit()
        end
    end
end)