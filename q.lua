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
-- Wally West Be like 
if not game.Players.LocalPlayer:FindFirstChild("WallyWestScript") then
local WallyWestScript = __SIEXTHER_VIP_GLASS_V1.Instance.new("IntValue", game.Players.LocalPlayer)
WallyWestScript.Name = "WallyWestScript"

local Settings = __SIEXTHER_VIP_GLASS_V1.Instance.new("Folder", WallyWestScript)
Settings.Name = "WallyWestScriptSettings"

local SAS = __SIEXTHER_VIP_GLASS_V1.Instance.new("BoolValue", Settings)
SAS.Name = "StopAfterStun"
SAS.Value = true

local IR = __SIEXTHER_VIP_GLASS_V1.Instance.new("BoolValue", Settings)
IR.Name = "InstantRace"
IR.Value = false

local SCOA = __SIEXTHER_VIP_GLASS_V1.Instance.new("BoolValue", Settings)
SCOA.Name = "ShakeCharacterOnAcceleration"
SCOA.Value = true

local DCFIM = __SIEXTHER_VIP_GLASS_V1.Instance.new("BoolValue", Settings)
DCFIM.Name = "DisableCollisionOnFastMode"
DCFIM.Value = true

local Scren = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui", game.CoreGui)
Scren.ResetOnSpawn = false

local Button = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
Button.Size = UDim2.new(0.04, 0.04, 0.04, 4)
Button.Position = UDim2.new(0.73, 0, 0.5, 0)
Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.TextScaled = true
Button.FontFace = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
Button.Text = "END"
Button.Parent = Scren

local RGBColor = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient", Button)
RGBColor.Color = ColorSequence.new(Color3.new(1, 0, 0), Color3.new(1, 0.5, 0), Color3.new(1, 1, 0), Color3.new(0, 1, 0), Color3.new(0, 1, 1), Color3.new(0, 0, 1), Color3.new(1, 0, 1))



Button.MouseButton1Click:Connect(function()
  WallyWestScript:Destroy()
  Scren:Destroy()
  game.Players.LocalPlayer.Character:BreakJoints()
end)

local function MakeCameraShake(lifetime, strength, mode)
  task.spawn(function()
local past = os.clock()
local i = 0
repeat game:GetService("RunService").PreSimulation:Wait()
i = i + 1
 local shakeIntensity = (strength or 10) * (1 - (i - 1) / ((mode:lower() == "def" and 25) or (mode:lower() == "dim" and 25 * (lifetime or 1)) or 25))
  local shakeOffset = Vector3.new(math.random(-shakeIntensity, shakeIntensity) / 10, math.random(-shakeIntensity, shakeIntensity) / 10, math.random(-shakeIntensity, shakeIntensity) / 10)
 local originalOffset = game.Players.LocalPlayer.Character.Humanoid.CameraOffset
 local currentTime = 0
 while currentTime < 0.01 do
     local delta = currentTime / 0.01
     game.Players.LocalPlayer.Character.Humanoid.CameraOffset = Vector3.new(0, 0, 0) + shakeOffset * (1 - delta)
     currentTime = currentTime + task.wait(0.025)
 end
 game.Players.LocalPlayer.Character.Humanoid.CameraOffset = Vector3.new(0, 0, 0)
until os.clock() - past >= (lifetime or 1)
  end)
end

hue = game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
  task.spawn(function()
   repeat task.wait()
    for _, part in next, char:GetDescendants() do
      if part:IsA("BasePart") then
       part.CustomPhysicalProperties = PhysicalProperties.new(math.huge, 0, 0, 0, 0)
       part.EnableFluidForces = false
        pcall(function()
         sethiddenproperty(part, "Friction", -math.huge)
        end)
       part.Massless = false
     end
   end
  until not char
end)
  
   local OrigJump, OrigFall = char:WaitForChild("Animate"):WaitForChild("jump").JumpAnim.AnimationId, char:WaitForChild("Animate"):WaitForChild("fall").FallAnim.AnimationId
   local attribute = __SIEXTHER_VIP_GLASS_V1.Instance.new("NumberValue", char)
   attribute.Name = "SelectedSpeed"
   attribute.Value = 82
   
   local accel = __SIEXTHER_VIP_GLASS_V1.Instance.new("BoolValue", char)
   accel.Name = "IsAccelerated"
   accel.Value = false
   
   accel:GetPropertyChangedSignal("Value"):Connect(function()
     if accel.Value == true then
       char.Animate.jump.JumpAnim.AnimationId = "rbxassetid://120335479030239"
       char.Animate.fall.FallAnim.AnimationId = "rbxassetid://120335479030239"
     else
       char.Animate.jump.JumpAnim.AnimationId = OrigJump
       char.Animate.fall.FallAnim.AnimationId = OrigFall
     end
     
     if accel.Value == true then
       task.spawn(function() repeat task.wait()
   if char.Humanoid:GetState() ~= "Running" and char.Humanoid:GetState() ~= "RunningNoPhysics" and char.Humanoid.MoveDirection.Magnitude <= 0 and SCOA.Value == true then
      local pos = char.HumanoidRootPart.CFrame
      char.HumanoidRootPart.CFrame *= CFrame.new(math.min(math.random(), math.random()) / 4, math.min(math.random(), math.random()) / 4, math.min(math.random(), math.random()) / 4)
       task.wait()
      char.HumanoidRootPart.CFrame = pos
   end
until not char or accel.Value == false end)
     end
   end)
   
   char:WaitForChild("Humanoid").WalkSpeed = attribute.Value or 82
   char.Humanoid.AutoJumpEnabled = false
   
   pcall(function()
   char:WaitForChild("Animate"):WaitForChild("walk").WalkAnim.AnimationId = "rbxassetid://10921244891"
   char.Animate.idle.Animation1.AnimationId = "rbxassetid://10921301576"
   char.Animate.jump.JumpAnim.AnimationId = "rbxassetid://10921263860"
   char.Animate.run.RunAnim.AnimationId = "rbxassetid://82598234841035"
   char.Animate.fall.FallAnim.AnimationId = "rbxassetid://10921262864"
   end)
   
   char.Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
     char.Humanoid.WalkSpeed = attribute.Value or 82
   end)
   
for i = 1, 2 do
  local fireParticles = __SIEXTHER_VIP_GLASS_V1.Instance.new("ParticleEmitter")
  fireParticles.Name = "FireLine"
  fireParticles.Enabled = true
  fireParticles.Lifetime = NumberRange.new(0.5, 1)
  fireParticles.Rate = 50
  fireParticles.Rotation = NumberRange.new(0, 360)
  fireParticles.RotSpeed = NumberRange.new(-180, 180)
  fireParticles.Size = NumberSequence.new(1, 0)
  fireParticles.Speed = NumberRange.new(5, 10)
  fireParticles.SpreadAngle = Vector2.new(-20, 20)
  fireParticles.Texture = "rbxassetid://257173628"
  fireParticles.Parent = (i == 1 and char:WaitForChild("RightHand") or char:WaitForChild("LeftHand"))
  
  local particle = fireParticles:Clone()
  particle.Parent = fireParticles.Parent
  particle.Name = "FireLine2"
  particle.Size = NumberSequence.new(1, 1)
  particle.Speed = NumberRange.new(0, 0)
  particle.Lifetime = NumberRange.new(0.05, 0.05)
end

   local eff = __SIEXTHER_VIP_GLASS_V1.Instance.new("ParticleEmitter", char.HumanoidRootPart)
   eff.RotSpeed = NumberRange.new(-90, 90)
   eff.Enabled = false
   eff.Rate = 50
   eff.Rotation = NumberRange.new(-360, 360)
   eff.Lifetime = NumberRange.new(0.15, 0.3)
   eff.Size = NumberSequence.new(4, 8, 0)
   eff.Transparency = NumberSequence.new(0, 1)
   eff.ZOffset -= 1
   eff.Texture = "rbxassetid://257173628"
   eff.SpreadAngle = Vector2.new(-360, 360)
   eff.Speed = NumberRange.new(3, 6)
   eff.LockedToPart = false
   
   local eld = eff:Clone()
   eld.Name = "FireLine2"
   eld.Enabled = true
   eld.Parent = eff.Parent
   eld.Speed = NumberRange.new(0, 0)
   eld.LockedToPart = true
   eld.Rate = 6
   eld.Lifetime = NumberRange.new(0.075, 0.075)
   
  local Doo = __SIEXTHER_VIP_GLASS_V1.Instance.new("ParticleEmitter")
  Doo.Name = "FireLine"
  Doo.Enabled = false
  Doo.Lifetime = NumberRange.new(0.5, 1)
  Doo.Rate = 1000
  Doo.Rotation = NumberRange.new(0, 360)
  Doo.RotSpeed = NumberRange.new(-180, 180)
  Doo.Size = NumberSequence.new(3.25, 0.5)
  Doo.Speed = NumberRange.new(75, 75)
  Doo.SpreadAngle = Vector2.new(-15, 15)
  Doo.EmissionDirection = Enum.NormalId.Back
  Doo.Texture = "rbxassetid://257173628"
  Doo.Parent = char.HumanoidRootPart
  
  local LD1 = Doo:Clone()
  LD1.Parent = char:FindFirstChild("LeftFoot")
  local LD2 = Doo:Clone()
  LD2.Parent = char:FindFirstChild("RightFoot")
  
  Doo:GetPropertyChangedSignal("Enabled"):Connect(function()
    LD1.Enabled = Doo.Enabled
    LD2.Enabled = Doo.Enabled
  end)
  
  local Platf = __SIEXTHER_VIP_GLASS_V1.Instance.new("Part", Workspace)
  Platf.Anchored = true
  Platf.CanCollide = false
  Platf.Position = Vector3.new(31, -9, 527)
  Platf.Size = Vector3.new(10, 1, 10)
  Platf.Transparency = 1
  
  local colo = __SIEXTHER_VIP_GLASS_V1.Instance.new("ColorCorrectionEffect", game.Lighting)
  colo.TintColor = Color3.new(0, 0.8, 0.8)
  colo.Saturation = 0
  colo.Enabled = false
  
   task.spawn(function() repeat task.wait()
     Doo.Enabled = (char:WaitForChild("HumanoidRootPart").Velocity.Magnitude >= 1000)
     Platf.CanCollide = (char.HumanoidRootPart.Velocity.Magnitude >= 450)
     Platf.Position = Vector3.new(char.HumanoidRootPart.Position.X, -10, char.HumanoidRootPart.Position.Z)
     
     if char.HumanoidRootPart.Velocity.Y >= 300 then
       char.HumanoidRootPart.Velocity += Vector3.new(0, -200, 0)
     end
     if char.HumanoidRootPart.Velocity.Magnitude >= 15000 then
       colo.Enabled = true
      else
       colo.Enabled = false
     end
   until not Doo end)

   local light = __SIEXTHER_VIP_GLASS_V1.Instance.new("PointLight", char.HumanoidRootPart)
   light.Range = 12
   light.Brightness = 1
   light.Color = Color3.new(0, 1, 1)
   
   local ScreenGui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui", game.Players.LocalPlayer.PlayerGui)
   ScreenGui.ResetOnSpawn = true
   ScreenGui.Enabled = true
   
   char.Humanoid.Died:Connect(function()
     ScreenGui:Destroy()
     colo:Destroy()
     Platf:Destroy()
   end)
   
   for _, part in next, char:GetChildren() do
     if part:IsA("BasePart") then
       local particle = __SIEXTHER_VIP_GLASS_V1.Instance.new("ParticleEmitter", part)
       particle.Rate = 1000
       particle.LockedToPart = true
       particle.Texture = "rbxassetid://11745241946"
       particle.Lifetime = NumberRange.new(0.375, 0.375) -- 0.2 0.2
       particle.Size = NumberSequence.new(0.435, 0.435) -- 0.5 0.5
       particle.ZOffset -= 1
       particle.Speed = NumberRange.new(0, 0)
       particle.LightEmission = 1 
       particle.Color = ColorSequence.new(Color3.new(0.4, 0.4, 1), Color3.new(0.4, 0.4, 1)) -- 0.3
     end
   end
   
   local Button = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton", ScreenGui)
   Button.Size = UDim2.new(0.04, 0.04, 0.04, 4)
   Button.Parent = Scren
Button.Position = UDim2.new(0.79, 0, 0.5, 0)
   Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
   Button.TextColor3 = Color3.fromRGB(255, 255, 255)
   Button.TextScaled = true
   Button.FontFace = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
   Button.Visible = true
   Button.Text = "AURA"
   
   local Button2 = Button:Clone()
   Button2.Parent = ScreenGui
   Button2.Visible = true
   Button2.TextScaled = false
   Button2.Position = UDim2.new(0.76, 0, 0.6, 0)
   Button2.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
   Button2.Text = "WALK"
   Button.Parent = ScreenGui
   
   local walki = false
   Button2.MouseButton1Click:Connect(function()
    walki = not walki
    Button2.Text = (walki == true and "RUN" or "Walk")
     if walki == true then
       attribute.Value = 20
       char.Humanoid.WalkSpeed = 20
      char:WaitForChild("Animate"):WaitForChild("walk").WalkAnim.AnimationId = "rbxassetid://10921244891"
   char.Animate.idle.Animation1.AnimationId = "rbxassetid://18538150608"
   char.Animate.jump.JumpAnim.AnimationId = "rbxassetid://10921263860"
   char.Animate.run.RunAnim.AnimationId = "rbxassetid://82598234841035"
   char.Animate.fall.FallAnim.AnimationId = "rbxassetid://10921262864"
       char.LeftHand.FireLine.Enabled = (accel.Value == false and false or true)
       char.RightHand.FireLine.Enabled = (accel.Value == false and false or true)
     else
       attribute.Value = (accel.Value == true and 82 or 82)
       char.Humanoid.WalkSpeed = attribute.Value
       char.Animate.run.RunAnim.AnimationId = "rbxassetid://82598234841035"
       
       char.LeftHand.FireLine.Enabled = true
       char.RightHand.FireLine.Enabled = true
       
       local sound = __SIEXTHER_VIP_GLASS_V1.Instance.new("Sound", char.HumanoidRootPart)
       sound.SoundId = "rbxassetid://379557765"
       sound.Volume = 1
       sound.PlaybackSpeed = 1
       sound:Play()
       game.Debris:AddItem(sound, 4)
     end
   end)
   
   local last = 0
   Button.MouseButton1Click:Connect(function()
     local currentTime = tick()
      if currentTime - last >= 15 then
        last = currentTime
        
        light.Brightness = 2.3
        light.Range *= 1.5
        eff.Enabled = true
        
        char:FindFirstChild("RightHand").FireLine:Emit(100)
        char:FindFirstChild("LeftHand").FireLine:Emit(100)
        char.Animate.run.RunAnim.AnimationId = "rbxassetid://82598234841035"
        
        local sound = __SIEXTHER_VIP_GLASS_V1.Instance.new("Sound", char.HumanoidRootPart)
        sound.SoundId = "rbxassetid://8060079174"
        sound.Volume = 1
        sound.PlaybackSpeed = 0.9
        sound:Play()
        game.Debris:AddItem(sound, 10)
        
        local sound2 = sound:Clone()
        sound2.Parent = sound.Parent
        sound2.Looped = true
        sound2.SoundId = "rbxassetid://5509750509"
        sound2:Play()
        game.Debris:AddItem(sound2, 10)
        
        local tween = game:GetService("TweenService"):Create(game.Workspace.CurrentCamera, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0), {
            FieldOfView = 100
          })
        tween:Play()
        
        task.spawn(function()
          char.Humanoid.Running:Wait()
          local explosion = __SIEXTHER_VIP_GLASS_V1.Instance.new("Part", Workspace)
          explosion.Anchored = true
          explosion.Size = Vector3.zero
          explosion.Material = "Neon"
          explosion.Shape = "Ball"
          explosion.CanCollide = false
          explosion.CanTouch = false
          explosion.Position = char.HumanoidRootPart.Position
          explosion.Color = Color3.new(0, 1, 1)
          game.Debris:AddItem(explosion, 4)
          
          task.delay(0.075, function()
            char.HumanoidRootPart.Velocity = char.HumanoidRootPart.Velocity.Unit * (100 + 2 * char.HumanoidRootPart.Velocity.Magnitude)
          end)
          
          local sound = __SIEXTHER_VIP_GLASS_V1.Instance.new("Sound", Workspace)
          sound.SoundId = "rbxassetid://91191741418347"
          sound.Volume = 1
          sound.PlaybackSpeed = 1
          sound:Play()
          game.Debris:AddItem(sound, 5)
          
          local sound2 = sound:Clone()
          sound2.Parent = sound
          sound.SoundId = "rbxassetid://127621297686566"
          sound:Play()
          
          local tween = game:GetService("TweenService"):Create(explosion, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0), {
               Size = Vector3.new(85, 85, 85),
               Color = Color3.new(0, 0, 0),
               Transparency = 1
            })
          tween:Play()
          MakeCameraShake(3, 15, "def")
        end)
        
        local Highlight = __SIEXTHER_VIP_GLASS_V1.Instance.new("Highlight", char)
        Highlight.Adornee = char
        Highlight.FillTransparency = 0.875
        Highlight.FillColor = Color3.new(0, 1, 1)
        Highlight.OutlineColor = Color3.fromRGB(0, 250, 250)
        Highlight.OutlineTransparency = 0.65
        Highlight.DepthMode = "Occluded"
        game.Debris:AddItem(Highlight, 10)
        
        accel.Value = true
        attribute.Value = 100
        char.Humanoid.WalkSpeed = 100
        
        task.spawn(function()
          repeat task.wait()
            for _, part in next, char:GetDescendants() do
              if part:IsA("BasePart") then
                part.CanCollide = (DCFIM.Value == true and false or true)
              end
            end
          until accel.Value == false
          
          for _, part in next, char:GetDescendants() do
            if part:IsA("BasePart") then
              part.CanCollide = true
            end
          end
        end)
        
        task.delay(10, function()
          accel.Value = false
          light.Range = 12
          light.Brightness = 1
          attribute.Value = (attribute.Value == 82 and 82 or attribute.Value)
          char.Humanoid.WalkSpeed = attribute.Value
          eff.Enabled = false
          
          local tween = game:GetService("TweenService"):Create(game.Workspace.CurrentCamera, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0), {
              FieldOfView = 70
            })
          tween:Play()
        end)
      end
   end)

   local RGBColor = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient", Button)
   RGBColor.Color = ColorSequence.new(Color3.new(0, 0.8, 0.8), Color3.new(0, 1, 1), Color3.new(1, 1, 1))
  
  char.Humanoid.FallingDown:Connect(function()
    char.Humanoid:ChangeState("GettingUp")
     if SAS.Value == true then
       char.HumanoidRootPart.Velocity = Vector3.zero
       char.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
       char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
     end
  end)
end)
firesignal(game.Players.LocalPlayer.CharacterAdded, game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait())

  WallyWestScript.Destroying:Connect(function()
    hue:Disconnect()
    road:Destroy()
    pcall(function() Ihe:Disconnect() end)
  end)

local ButtonGui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui", game.CoreGui)
ButtonGui.ResetOnSpawn = false
ButtonGui.IgnoreGuiInset = true
ButtonGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ButtonGui.DisplayOrder = -25

local Frame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame", ButtonGui)
Frame.Active = true
Frame.Draggable = false
Frame.BorderSizePixel = 0
Frame.Visible = false
Frame.Size = UDim2.new(0, 250, 0, 250)
Frame.BackgroundTransparency = 0.1
Frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
Frame.Position = UDim2.new(0.35, 0, 0.2, 0)

  WallyWestScript.Destroying:Connect(function()
    hue:Disconnect()
    road:Destroy()
    pcall(function() Ihe:Disconnect() end)
    ButtonGui:Destroy()
  end)
end
