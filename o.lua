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
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Create GUI
local ScreenGui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
ScreenGui.Name = "AutoTranslateGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

-- Main Frame (Lebih Kecil & Modern)
local MainFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 150)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -75)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- Blue Sky Stroke (Outer Frame Only)
local MainStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(70, 130, 255)
MainStroke.Thickness = 2
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame

-- Header
local Header = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 32)
Header.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local HeaderFix = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 10)
HeaderFix.Position = UDim2.new(0, 0, 1, -10)
HeaderFix.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

-- Title
local Title = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SIEXTHER TRANSLATE"
Title.TextColor3 = Color3.fromRGB(70, 130, 255)
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Minimize Button
local MinimizeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 24, 0, 24)
MinimizeBtn.Position = UDim2.new(1, -54, 0.5, -12)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
MinimizeBtn.Text = "–"
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinimizeBtn.TextSize = 14
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.AutoButtonColor = false
MinimizeBtn.Parent = Header

local MinimizeCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 6)
MinimizeCorner.Parent = MinimizeBtn

-- Close Button
local CloseBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -28, 0.5, -12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Header

local CloseCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

-- Hover Effects for Buttons
MinimizeBtn.MouseEnter:Connect(function()
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
end)

MinimizeBtn.MouseLeave:Connect(function()
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
end)

CloseBtn.MouseEnter:Connect(function()
    CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
end)

CloseBtn.MouseLeave:Connect(function()
    CloseBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
end)

-- Minimized Button
local MinimizedBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
MinimizedBtn.Name = "MinimizedBtn"
MinimizedBtn.Size = UDim2.new(0, 38, 0, 38)
MinimizedBtn.Position = UDim2.new(1, -60, 0.5, -19)
MinimizedBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MinimizedBtn.Text = "🌐"
MinimizedBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
MinimizedBtn.TextSize = 18
MinimizedBtn.Font = Enum.Font.GothamBold
MinimizedBtn.BorderSizePixel = 0
MinimizedBtn.Visible = false
MinimizedBtn.Active = true
MinimizedBtn.Draggable = true
MinimizedBtn.AutoButtonColor = true
MinimizedBtn.Parent = ScreenGui

local MinimizedCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
MinimizedCorner.CornerRadius = UDim.new(0, 10)
MinimizedCorner.Parent = MinimizedBtn

local MinimizedStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
MinimizedStroke.Color = Color3.fromRGB(70, 130, 255)
MinimizedStroke.Thickness = 2
MinimizedStroke.Parent = MinimizedBtn

-- Content Frame
local ContentFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -16, 1, -40)
ContentFrame.Position = UDim2.new(0, 8, 0, 36)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Settings
local Settings = {
    TargetLanguage = "en",
    LanguageName = "English",
    LanguageFlag = "🇬🇧"
}

-- Info Label
local InfoLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
InfoLabel.Name = "InfoLabel"
InfoLabel.Size = UDim2.new(1, 0, 0, 18)
InfoLabel.Position = UDim2.new(0, 0, 0, 2)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "🇮🇩 Indonesian → 🇬🇧 English"
InfoLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
InfoLabel.TextSize = 11
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.Parent = ContentFrame

-- Input Box
local InputBox = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextBox")
InputBox.Name = "InputBox"
InputBox.Size = UDim2.new(1, 0, 0, 42)
InputBox.Position = UDim2.new(0, 0, 0, 22)
InputBox.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
InputBox.Text = ""
InputBox.TextColor3 = Color3.fromRGB(220, 220, 230)
InputBox.TextSize = 12
InputBox.Font = Enum.Font.Gotham
InputBox.PlaceholderText = "Ketik pesan disini..."
InputBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
InputBox.TextWrapped = true
InputBox.TextXAlignment = Enum.TextXAlignment.Left
InputBox.TextYAlignment = Enum.TextYAlignment.Top
InputBox.ClearTextOnFocus = false
InputBox.MultiLine = true
InputBox.BorderSizePixel = 0
InputBox.Parent = ContentFrame

local InputCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 8)
InputCorner.Parent = InputBox

-- Translate & Send Button (Kiri - Lebih Besar)
local TranslateBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
TranslateBtn.Name = "TranslateBtn"
TranslateBtn.Size = UDim2.new(0.62, -2, 0, 34)
TranslateBtn.Position = UDim2.new(0, 0, 0, 70)
TranslateBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
TranslateBtn.Text = "TRANSLATE"
TranslateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TranslateBtn.TextSize = 12
TranslateBtn.Font = Enum.Font.GothamBold
TranslateBtn.BorderSizePixel = 0
TranslateBtn.AutoButtonColor = false
TranslateBtn.Parent = ContentFrame

local TranslateCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
TranslateCorner.CornerRadius = UDim.new(0, 8)
TranslateCorner.Parent = TranslateBtn

-- Language Button (Kanan - Lebih Kecil)
local LanguageBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
LanguageBtn.Name = "LanguageBtn"
LanguageBtn.Size = UDim2.new(0.38, -2, 0, 34)
LanguageBtn.Position = UDim2.new(0.62, 4, 0, 70)
LanguageBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
LanguageBtn.Text = "🇬🇧 EN"
LanguageBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
LanguageBtn.TextSize = 12
LanguageBtn.Font = Enum.Font.GothamSemibold
LanguageBtn.BorderSizePixel = 0
LanguageBtn.AutoButtonColor = false
LanguageBtn.Parent = ContentFrame

local LanguageCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
LanguageCorner.CornerRadius = UDim.new(0, 8)
LanguageCorner.Parent = LanguageBtn

-- Button Hover Effects
TranslateBtn.MouseEnter:Connect(function()
    TranslateBtn.BackgroundColor3 = Color3.fromRGB(85, 145, 255)
end)

TranslateBtn.MouseLeave:Connect(function()
    TranslateBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
end)

LanguageBtn.MouseEnter:Connect(function()
    LanguageBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
end)

LanguageBtn.MouseLeave:Connect(function()
    LanguageBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
end)

-- Language Selection Frame (Hidden by default)
local LanguageFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
LanguageFrame.Name = "LanguageFrame"
LanguageFrame.Size = UDim2.new(0, 220, 0, 240)
LanguageFrame.Position = UDim2.new(0.5, -110, 0.5, -120)
LanguageFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
LanguageFrame.BorderSizePixel = 0
LanguageFrame.Visible = false
LanguageFrame.Parent = ScreenGui

local LanguageFrameCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
LanguageFrameCorner.CornerRadius = UDim.new(0, 12)
LanguageFrameCorner.Parent = LanguageFrame

local LanguageFrameStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
LanguageFrameStroke.Color = Color3.fromRGB(70, 130, 255)
LanguageFrameStroke.Thickness = 2
LanguageFrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
LanguageFrameStroke.Parent = LanguageFrame

-- Language Frame Header
local LangHeader = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
LangHeader.Name = "LangHeader"
LangHeader.Size = UDim2.new(1, 0, 0, 32)
LangHeader.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
LangHeader.BorderSizePixel = 0
LangHeader.Parent = LanguageFrame

local LangHeaderCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
LangHeaderCorner.CornerRadius = UDim.new(0, 12)
LangHeaderCorner.Parent = LangHeader

local LangHeaderFix = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
LangHeaderFix.Size = UDim2.new(1, 0, 0, 10)
LangHeaderFix.Position = UDim2.new(0, 0, 1, -10)
LangHeaderFix.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
LangHeaderFix.BorderSizePixel = 0
LangHeaderFix.Parent = LangHeader

local LangTitle = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
LangTitle.Name = "LangTitle"
LangTitle.Size = UDim2.new(1, -36, 1, 0)
LangTitle.Position = UDim2.new(0, 10, 0, 0)
LangTitle.BackgroundTransparency = 1
LangTitle.Text = "PILIH BAHASA"
LangTitle.TextColor3 = Color3.fromRGB(70, 130, 255)
LangTitle.TextSize = 13
LangTitle.Font = Enum.Font.GothamBold
LangTitle.TextXAlignment = Enum.TextXAlignment.Left
LangTitle.Parent = LangHeader

local LangCloseBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
LangCloseBtn.Name = "LangCloseBtn"
LangCloseBtn.Size = UDim2.new(0, 24, 0, 24)
LangCloseBtn.Position = UDim2.new(1, -28, 0.5, -12)
LangCloseBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
LangCloseBtn.Text = "X"
LangCloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
LangCloseBtn.TextSize = 12
LangCloseBtn.Font = Enum.Font.GothamBold
LangCloseBtn.BorderSizePixel = 0
LangCloseBtn.AutoButtonColor = false
LangCloseBtn.Parent = LangHeader

local LangCloseCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
LangCloseCorner.CornerRadius = UDim.new(0, 6)
LangCloseCorner.Parent = LangCloseBtn

LangCloseBtn.MouseEnter:Connect(function()
    LangCloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
end)

LangCloseBtn.MouseLeave:Connect(function()
    LangCloseBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
end)

-- Scroll Frame for Languages
local ScrollFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScrollingFrame")
ScrollFrame.Name = "ScrollFrame"
ScrollFrame.Size = UDim2.new(1, -16, 1, -42)
ScrollFrame.Position = UDim2.new(0, 8, 0, 36)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
ScrollFrame.Parent = LanguageFrame

local ScrollCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(0, 8)
ScrollCorner.Parent = ScrollFrame

local UIListLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.Parent = ScrollFrame

-- Language List
local languages = {
    {code = "en", name = "English", flag = "🇬🇧", short = "EN"},
    {code = "es", name = "Spanish", flag = "🇪🇸", short = "ES"},
    {code = "fr", name = "French", flag = "🇫🇷", short = "FR"},
    {code = "de", name = "German", flag = "🇩🇪", short = "DE"},
    {code = "it", name = "Italian", flag = "🇮🇹", short = "IT"},
    {code = "pt", name = "Portuguese", flag = "🇵🇹", short = "PT"},
    {code = "ru", name = "Russian", flag = "🇷🇺", short = "RU"},
    {code = "ja", name = "Japanese", flag = "🇯🇵", short = "JP"},
    {code = "ko", name = "Korean", flag = "🇰🇷", short = "KR"},
    {code = "zh-CN", name = "Chinese", flag = "🇨🇳", short = "CN"},
    {code = "ms-MY", name = "Malaysia", flag = "🇲🇾", short = "MY"},
    {code = "ar", name = "Arabic", flag = "🇸🇦", short = "AR"},
    {code = "hi", name = "Hindi", flag = "🇮🇳", short = "HI"},
    {code = "th", name = "Thai", flag = "🇹🇭", short = "TH"},
    {code = "vi", name = "Vietnamese", flag = "🇻🇳", short = "VN"},
    {code = "nl", name = "Dutch", flag = "🇳🇱", short = "NL"},
    {code = "pl", name = "Polish", flag = "🇵🇱", short = "PL"},
    {code = "tr", name = "Turkish", flag = "🇹🇷", short = "TR"},
    {code = "jw", name = "Jawa", flag = "🇦🇶", short = "JV"},
    {code = "su", name = "Sunda", flag = "🏳️‍⚧️", short = "SU"},
}

-- Create Language Buttons
for i, lang in ipairs(languages) do
    local LangOptionBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    LangOptionBtn.Name = "Lang_" .. lang.code
    LangOptionBtn.Size = UDim2.new(1, -8, 0, 32)
    LangOptionBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
    LangOptionBtn.Text = lang.flag .. " " .. lang.name
    LangOptionBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
    LangOptionBtn.TextSize = 12
    LangOptionBtn.Font = Enum.Font.Gotham
    LangOptionBtn.BorderSizePixel = 0
    LangOptionBtn.AutoButtonColor = false
    LangOptionBtn.Parent = ScrollFrame
    
    local LangOptionCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
    LangOptionCorner.CornerRadius = UDim.new(0, 6)
    LangOptionCorner.Parent = LangOptionBtn
    
    -- Click event
    LangOptionBtn.MouseButton1Click:Connect(function()
        Settings.TargetLanguage = lang.code
        Settings.LanguageName = lang.name
        Settings.LanguageFlag = lang.flag
        Settings.LanguageShort = lang.short
        
        LanguageBtn.Text = lang.flag .. " " .. lang.short
        InfoLabel.Text = "🇮🇩 Indonesian → " .. lang.flag .. " " .. lang.name
        
        -- Visual feedback
        LangOptionBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        task.wait(0.15)
        LangOptionBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
        
        -- Close language frame
        LanguageFrame.Visible = false
        LanguageBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    end)
    
    -- Hover effect
    LangOptionBtn.MouseEnter:Connect(function()
        LangOptionBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    end)
    
    LangOptionBtn.MouseLeave:Connect(function()
        LangOptionBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
    end)
end

-- Update ScrollFrame canvas size
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 8)

-- Language Button Click
LanguageBtn.MouseButton1Click:Connect(function()
    LanguageFrame.Visible = not LanguageFrame.Visible
    
    if LanguageFrame.Visible then
        LanguageBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    else
        LanguageBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    end
end)

-- Language Close Button
LangCloseBtn.MouseButton1Click:Connect(function()
    LanguageFrame.Visible = false
    LanguageBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
end)

-- Google Translate API Function
local function translateWithAPI(text, sourceLang, targetLang)
    local success, result = pcall(function()
        local encodedText = HttpService:UrlEncode(text)
        
        local url = string.format(
            "https://translate.googleapis.com/translate_a/single?client=gtx&sl=%s&tl=%s&dt=t&q=%s",
            sourceLang,
            targetLang,
            encodedText
        )
        
        local response = game:HttpGet(url)
        local data = HttpService:JSONDecode(response)
        
        if data and data[1] then
            local translatedText = ""
            for _, segment in ipairs(data[1]) do
                if segment[1] then
                    translatedText = translatedText .. segment[1]
                end
            end
            return translatedText
        end
        
        return nil
    end)
    
    if success and result then
        return result
    else
        warn("Translation failed:", result)
        return nil
    end
end

-- Alternative: MyMemory Translation API (backup)
local function translateWithMyMemory(text, sourceLang, targetLang)
    local success, result = pcall(function()
        local encodedText = HttpService:UrlEncode(text)
        
        local url = string.format(
            "https://api.mymemory.translated.net/get?q=%s&langpair=%s|%s",
            encodedText,
            sourceLang,
            targetLang
        )
        
        local response = game:HttpGet(url)
        local data = HttpService:JSONDecode(response)
        
        if data and data.responseData and data.responseData.translatedText then
            return data.responseData.translatedText
        end
        
        return nil
    end)
    
    if success and result then
        return result
    else
        warn("MyMemory translation failed:", result)
        return nil
    end
end

-- Main translation function with fallbacks
local function translateText(text)
    local translated = translateWithAPI(text, "id", Settings.TargetLanguage)
    
    if translated then
        return translated
    end
    
    translated = translateWithMyMemory(text, "id", Settings.TargetLanguage)
    
    if translated then
        return translated
    end
    
    return text
end

-- Send Chat Function
local function sendChat(message)
    if message and message ~= "" then
        pcall(function()
            local TextChatService = game:GetService("TextChatService")
            local chatChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            
            if chatChannel then
                chatChannel:SendAsync(message)
            else
                game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
            end
        end)
    end
end

-- Translate & Send Button Click
TranslateBtn.MouseButton1Click:Connect(function()
    local indonesianText = InputBox.Text
    
    if indonesianText and indonesianText ~= "" then
        TranslateBtn.Text = "Tunggu..."
        TranslateBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 150)
        
        local englishText = translateText(indonesianText)
        
        if englishText and englishText ~= indonesianText then
            TranslateBtn.Text = "Mengirim..."
            sendChat(englishText)
            
            task.wait(0.5)
            
            TranslateBtn.Text = "Terkirim!"
            TranslateBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 100)
            task.wait(1)
            TranslateBtn.Text = "TRANSLATE"
            TranslateBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
            
            InputBox.Text = ""
        else
            TranslateBtn.Text = "GAGAL!"
            TranslateBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
            task.wait(1.5)
            TranslateBtn.Text = "TRANSLATE"
            TranslateBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        end
    else
        TranslateBtn.Text = "TEKS KOSONG"
        TranslateBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        task.wait(1)
        TranslateBtn.Text = "TRANSLATE"
        TranslateBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    end
end)

-- Enter key to send
InputBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        TranslateBtn.MouseButton1Click:Fire()
    end
end)

-- Minimize/Maximize Functions
local function minimizeGUI()
    MainFrame.Visible = false
    MinimizedBtn.Visible = true
end

local function maximizeGUI()
    MinimizedBtn.Visible = false
    MainFrame.Visible = true
end

-- Minimize Button Click
MinimizeBtn.MouseButton1Click:Connect(function()
    minimizeGUI()
end)

-- Minimized Button Click
MinimizedBtn.MouseButton1Click:Connect(function()
    maximizeGUI()
end)

-- Close Button Click
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)