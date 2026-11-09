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
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Settings = {
    BringPartRadius = 100,
    BringPartSpeed = 200,
    UnanchorRadius = 500,
    PositionMode = "torso"
}


local aktif = false
local character, humanoidRootPart, torso, head

local folder, attachment1, koneksi1

local blackHoleActive = false
local DescendantAddedConnection
local NetworkConnection
local BringFolder, TargetPart, Attachment1

local ScreenGui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
ScreenGui.Name = "SiextherChoticHan"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 200)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -100)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local mainCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = MainFrame

local mainStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(70, 130, 255)
mainStroke.Thickness = 2
mainStroke.Parent = MainFrame

-- Navbar
local Navbar = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
Navbar.Size = UDim2.new(1, 0, 0, 30)
Navbar.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
Navbar.Parent = MainFrame

local navCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
navCorner.CornerRadius = UDim.new(0, 10)
navCorner.Parent = Navbar

local TitleLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -65, 1, 0)
TitleLabel.Position = UDim2.new(0, 8, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "SIEXTHER CHAOTIC"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.TextColor3 = Color3.fromRGB(70, 130, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Navbar

local TitleGradient = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient")
TitleGradient.Parent = TitleLabel
TitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
TitleGradient.Offset = Vector2.new(-1, 0)

task.spawn(function()
    while TitleLabel and TitleLabel.Parent do
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

-- Minimize Button
local MinimizeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 24, 0, 24)
MinimizeBtn.Position = UDim2.new(1, -56, 0.5, -12)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MinimizeBtn.Text = "–"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 16
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Parent = Navbar

local minimizeCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 5)
minimizeCorner.Parent = MinimizeBtn

-- Close Button
local CloseBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -28, 0.5, -12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Parent = Navbar

local closeCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = CloseBtn

-- Mini Frame
local MiniFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
MiniFrame.Size = UDim2.new(0, 41, 0, 41)
MiniFrame.Position = UDim2.new(0, 15, 0.5, -22)
MiniFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MiniFrame.Text = "SX"
MiniFrame.Font = Enum.Font.GothamBold
MiniFrame.TextSize = 25
MiniFrame.TextColor3 = Color3.fromRGB(70, 130, 255)
MiniFrame.Visible = false
MiniFrame.Active = true
MiniFrame.Draggable = true
MiniFrame.Parent = ScreenGui

local MinimizedGradient = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient")
MinimizedGradient.Parent = MiniFrame
MinimizedGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
MinimizedGradient.Offset = Vector2.new(-1, 0)

task.spawn(function()
    while MiniFrame and MiniFrame.Parent do
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

local miniCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(0, 12)
miniCorner.Parent = MiniFrame

-- Content Container
local Content = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
Content.Size = UDim2.new(1, -16, 1, -40)
Content.Position = UDim2.new(0, 8, 0, 35)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- Toggle Button
local ToggleBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, 0, 0, 38)
ToggleBtn.Position = UDim2.new(0, 0, 0, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
ToggleBtn.Text = "SIEXTHER | OFF"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Parent = Content

local toggleCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 7)
toggleCorner.Parent = ToggleBtn

-- Mode Label
local ModeLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
ModeLabel.Size = UDim2.new(1, 0, 0, 18)
ModeLabel.Position = UDim2.new(0, 0, 0, 48)
ModeLabel.BackgroundTransparency = 1
ModeLabel.Text = "MODE POSISI: BADAN"
ModeLabel.Font = Enum.Font.GothamBold
ModeLabel.TextSize = 11
ModeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
ModeLabel.TextXAlignment = Enum.TextXAlignment.Left
ModeLabel.Parent = Content

-- Mode Buttons Container
local ModeContainer = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
ModeContainer.Size = UDim2.new(1, 0, 0, 70)
ModeContainer.Position = UDim2.new(0, 0, 0, 68)
ModeContainer.BackgroundTransparency = 1
ModeContainer.Parent = Content

-- Function to create mode button
local function createModeButton(text, position, mode)
    local btn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    btn.Size = UDim2.new(0.48, 0, 0, 32)
    btn.Position = position
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Parent = ModeContainer
    
    local corner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        Settings.PositionMode = mode
        
        -- Update all buttons
        for _, child in pairs(ModeContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            end
        end
        
        -- Highlight selected
        btn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        
        -- Update label
        local modeText = {
            torso = "BADAN",
            head = "KEPALA",
            feet = "KAKI",
            front = "DEPAN"
        }
        ModeLabel.Text = "MODE POSISI: " .. modeText[mode]
    end)
    
    return btn
end

-- Create 4 mode buttons
local TorsoBtn = createModeButton("BADAN", UDim2.new(0, 0, 0, 0), "torso")
local HeadBtn = createModeButton("KEPALA", UDim2.new(0.52, 0, 0, 0), "head")
local FeetBtn = createModeButton("KAKI", UDim2.new(0, 0, 0, 38), "feet")
local FrontBtn = createModeButton("DEPAN", UDim2.new(0.52, 0, 0, 38), "front")

-- Set default selected
TorsoBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)

local FooterText1 = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
FooterText1.Size = UDim2.new(1, 0, 0, 16)
FooterText1.Position = UDim2.new(0, 0, 1, -16)
FooterText1.BackgroundTransparency = 1
FooterText1.Text = "SIEXTHER"
FooterText1.Font = Enum.Font.GothamBold
FooterText1.TextSize = 12
FooterText1.TextColor3 = Color3.fromRGB(255, 255, 255)
FooterText1.TextTransparency = 0
FooterText1.Parent = Content

local FooterGradient1 = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient")
FooterGradient1.Parent = FooterText1
FooterGradient1.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
FooterGradient1.Offset = Vector2.new(-1, 0)

local FooterText2 = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
FooterText2.Size = UDim2.new(1, 0, 0, 16)
FooterText2.Position = UDim2.new(0, 0, 1, -16)
FooterText2.BackgroundTransparency = 1
FooterText2.Text = "PILIH MODE SESUKA KALIAN"
FooterText2.Font = Enum.Font.GothamBold
FooterText2.TextSize = 12
FooterText2.TextColor3 = Color3.fromRGB(255, 255, 255)
FooterText2.TextTransparency = 1
FooterText2.Parent = Content

local FooterGradient2 = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient")
FooterGradient2.Parent = FooterText2
FooterGradient2.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
FooterGradient2.Offset = Vector2.new(-1, 0)

-- Footer Animation
task.spawn(function()
    while FooterText1 and FooterText1.Parent do
        TweenService:Create(FooterText1, TweenInfo.new(1, Enum.EasingStyle.Sine), {TextTransparency = 0}):Play()
        TweenService:Create(FooterText2, TweenInfo.new(1, Enum.EasingStyle.Sine), {TextTransparency = 1}):Play()
        
        TweenService:Create(FooterGradient1, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(1, 0)
        }):Play()
        task.wait(3)
        
        TweenService:Create(FooterGradient1, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(-1, 0)
        }):Play()
        task.wait(2)
        
        TweenService:Create(FooterText1, TweenInfo.new(1, Enum.EasingStyle.Sine), {TextTransparency = 1}):Play()
        task.wait(1)
        
        TweenService:Create(FooterText2, TweenInfo.new(1, Enum.EasingStyle.Sine), {TextTransparency = 0}):Play()
        
        TweenService:Create(FooterGradient2, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(1, 0)
        }):Play()
        task.wait(3)
        
        TweenService:Create(FooterGradient2, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(-1, 0)
        }):Play()
        task.wait(2)
        
        TweenService:Create(FooterText2, TweenInfo.new(1, Enum.EasingStyle.Sine), {TextTransparency = 1}):Play()
        task.wait(1)
    end
end)

local function getTargetPosition()
    if not character then return nil end
    
    if Settings.PositionMode == "torso" then
        return torso and torso.CFrame
    elseif Settings.PositionMode == "head" then
        return head and head.CFrame
    elseif Settings.PositionMode == "feet" then
        if humanoidRootPart then
            return humanoidRootPart.CFrame * CFrame.new(0, -3, 0)
        end
    elseif Settings.PositionMode == "front" then
        if humanoidRootPart then
            return humanoidRootPart.CFrame * CFrame.new(0, 0, -5)
        end
    end
    
    return torso and torso.CFrame
end

local function scanParts()
    local parts = {}
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return parts end

    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") 
        and not part.Anchored 
        and not part:IsDescendantOf(character) then
            local dist = (part.Position - root.Position).Magnitude
            if dist <= Settings.UnanchorRadius then
                table.insert(parts, part)
            end
        end
    end
    return parts
end

local function applyForce(part)
    if not part or not part.Parent then return end
    part.CanCollide = false

    for _, x in next, part:GetChildren() do
        if x:IsA("BodyAngularVelocity") or x:IsA("BodyForce") or x:IsA("BodyGyro") 
        or x:IsA("BodyPosition") or x:IsA("BodyThrust") or x:IsA("BodyVelocity")
        or x:IsA("RocketPropulsion") then
            x:Destroy()
        end
    end

    if not part:FindFirstChildOfClass("Torque") then
        local torque = __SIEXTHER_VIP_GLASS_V1.Instance.new("Torque", part)
        torque.Torque = Vector3.new(100000,100000,100000)
        local align = __SIEXTHER_VIP_GLASS_V1.Instance.new("AlignPosition", part)
        local at2 = __SIEXTHER_VIP_GLASS_V1.Instance.new("Attachment", part)
        torque.Attachment0 = at2
        align.MaxForce = 9e15
        align.MaxVelocity = math.huge
        align.Responsiveness = 200
        align.Attachment0 = at2
        if attachment1 then
            align.Attachment1 = attachment1
        end
    end

    if attachment1 then
        local dist = (part.Position - attachment1.WorldPosition).Magnitude
        if dist <= Settings.UnanchorRadius then
            local arah = (attachment1.WorldPosition - part.Position).Unit
            part.AssemblyLinearVelocity = arah * 200
        end
    end
end

local function mulaiUnanchor()
    folder = __SIEXTHER_VIP_GLASS_V1.Instance.new("Folder", workspace)
    local part = __SIEXTHER_VIP_GLASS_V1.Instance.new("Part", folder)
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    attachment1 = __SIEXTHER_VIP_GLASS_V1.Instance.new("Attachment", part)

    task.spawn(function()
        settings().Physics.AllowSleep = false
        while aktif and task.wait() do
            for _, pl in next, game.Players:GetPlayers() do
                if pl ~= LocalPlayer then
                    pl.MaximumSimulationRadius = 0
                    sethiddenproperty(pl, "SimulationRadius", 0)
                end
            end
            LocalPlayer.MaximumSimulationRadius = math.pow(math.huge, math.huge)
            setsimulationradius(math.huge)
        end
    end)

    koneksi1 = RunService.Stepped:Connect(function()
        local list = scanParts()
        for _, v in pairs(list) do
            applyForce(v)
        end
    end)
end

local function stopUnanchor()
    if koneksi1 then koneksi1:Disconnect() end
    if folder then folder:Destroy() end
    folder, attachment1 = nil, nil
end

-- ========== BRINGPART FUNCTIONS ==========
if not getgenv().Network then
    getgenv().Network = {
        BaseParts = {},
        Velocity = Vector3.new(14.46, 14.46, 14.46)
    }

    function Network.RetainPart(part)
        if part:IsA("BasePart") and part:IsDescendantOf(Workspace) then
            table.insert(Network.BaseParts, part)
            part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            part.CanCollide = false
        end
    end
end

local function EnableNetwork()
    if NetworkConnection then return end
    NetworkConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
        end)
    end)
end

local function DisableNetwork()
    if NetworkConnection then
        NetworkConnection:Disconnect()
        NetworkConnection = nil
    end
end

local function ForcePart(v)
    if v:IsA("BasePart") 
    and not v.Anchored 
    and not v.Parent:FindFirstChildOfClass("Humanoid") 
    and not v.Parent:FindFirstChild("Head") 
    and v.Name ~= "Handle" then

        for _, x in ipairs(v:GetChildren()) do
            if x:IsA("BodyMover") or x:IsA("RocketPropulsion") then
                x:Destroy()
            end
        end

        if v:FindFirstChild("Attachment") then v:FindFirstChild("Attachment"):Destroy() end
        if v:FindFirstChild("AlignPosition") then v:FindFirstChild("AlignPosition"):Destroy() end
        if v:FindFirstChild("Torque") then v:FindFirstChild("Torque"):Destroy() end

        v.CanCollide = false
        local Torque = __SIEXTHER_VIP_GLASS_V1.Instance.new("Torque", v)
        Torque.Torque = Vector3.new(100000, 100000, 100000)
        local AlignPosition = __SIEXTHER_VIP_GLASS_V1.Instance.new("AlignPosition", v)
        local Attachment2 = __SIEXTHER_VIP_GLASS_V1.Instance.new("Attachment", v)
        Torque.Attachment0 = Attachment2
        AlignPosition.MaxForce = math.huge
        AlignPosition.MaxVelocity = math.huge
        AlignPosition.Responsiveness = Settings.BringPartSpeed
        AlignPosition.Attachment0 = Attachment2
        AlignPosition.Attachment1 = Attachment1
    end
end

local function OneTimeUnanchor()
    if getgenv().UnanchorCooldown then return end
    getgenv().UnanchorCooldown = true

    task.spawn(function()
        local startTime = tick()
        
        -- Simpan posisi awal player
        local originalCFrame = humanoidRootPart.CFrame
        local wasAnchored = humanoidRootPart.Anchored

        while tick() - startTime < 1 do
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("RopeConstraint") then
                    local part0 = obj.Attachment0 and obj.Attachment0.Parent
                    local part1 = obj.Attachment1 and obj.Attachment1.Parent
                    pcall(function() obj:Destroy() end)
                    if part0 and part0:IsA("BasePart") and not part0:IsDescendantOf(character) then 
                        part0.Anchored = false 
                    end
                    if part1 and part1:IsA("BasePart") and not part1:IsDescendantOf(character) then 
                        part1.Anchored = false 
                    end
                end
            end

            for _, part in pairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") 
                and not part.Anchored 
                and not part:IsDescendantOf(character) then
                    part.AssemblyLinearVelocity = Vector3.new(
                        math.random(-50, 50),
                        math.random(20, 100),
                        math.random(-50, 50)
                    )
                end
            end
            
            -- Kunci posisi player agar tidak terbang
            if humanoidRootPart and humanoidRootPart.Parent then
                humanoidRootPart.CFrame = originalCFrame
                humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end

            task.wait(0.1)
        end
        
        -- Kembalikan ke state normal
        if humanoidRootPart and humanoidRootPart.Parent then
            humanoidRootPart.Anchored = wasAnchored
        end

        getgenv().UnanchorCooldown = false
    end)
end

local function GetAllPartsRecursive(parent)
    local parts = {}
    for _, obj in ipairs(parent:GetChildren()) do
        if obj:IsA("BasePart") then
            table.insert(parts, obj)
        elseif obj:IsA("Folder") or obj:IsA("Model") then
            for _, childPart in ipairs(GetAllPartsRecursive(obj)) do
                table.insert(parts, childPart)
            end
        end
    end
    return parts
end

local playerStabilizer

local function mulaBringPart()
    BringFolder = __SIEXTHER_VIP_GLASS_V1.Instance.new("Folder", Workspace)
    BringFolder.Name = "BringPartFolder"
    TargetPart = __SIEXTHER_VIP_GLASS_V1.Instance.new("Part", BringFolder)
    TargetPart.Anchored = true
    TargetPart.CanCollide = false
    TargetPart.Transparency = 1
    Attachment1 = __SIEXTHER_VIP_GLASS_V1.Instance.new("Attachment", TargetPart)

    EnableNetwork()
    OneTimeUnanchor()

    for _, v in ipairs(GetAllPartsRecursive(Workspace)) do
        if not v:IsDescendantOf(character) then
            local dist = (v.Position - humanoidRootPart.Position).Magnitude
            if dist <= Settings.BringPartRadius then
                ForcePart(v)
            end
        end
    end

    DescendantAddedConnection = Workspace.DescendantAdded:Connect(function(v)
        if blackHoleActive and v:IsA("BasePart") and not v:IsDescendantOf(character) then
            local dist = (v.Position - humanoidRootPart.Position).Magnitude
            if dist <= Settings.BringPartRadius then
                ForcePart(v)
            end
        end
    end)

    -- Stabilizer untuk mencegah player terbang
    playerStabilizer = RunService.Heartbeat:Connect(function()
        if humanoidRootPart and humanoidRootPart.Parent and character then
            -- Reset velocity yang tidak wajar
            local velocity = humanoidRootPart.AssemblyLinearVelocity
            if velocity.Y > 50 or velocity.Magnitude > 100 then
                humanoidRootPart.AssemblyLinearVelocity = Vector3.new(
                    velocity.X * 0.5,
                    math.min(velocity.Y, 20),
                    velocity.Z * 0.5
                )
            end
            
            -- Reset angular velocity
            if humanoidRootPart.AssemblyAngularVelocity.Magnitude > 10 then
                humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end
    end)

    task.spawn(function()
        while blackHoleActive and RunService.RenderStepped:Wait() do
            local targetCF = getTargetPosition()
            if targetCF then
                Attachment1.WorldCFrame = targetCF
            end
        end
    end)
end

local function stopBringPart()
    DisableNetwork()
    if DescendantAddedConnection then
        DescendantAddedConnection:Disconnect()
        DescendantAddedConnection = nil
    end
    if playerStabilizer then
        playerStabilizer:Disconnect()
        playerStabilizer = nil
    end
    if BringFolder then
        BringFolder:Destroy()
        BringFolder = nil
    end
end

-- ========== TOGGLE BUTTON ==========
ToggleBtn.MouseButton1Click:Connect(function()
    aktif = not aktif
    blackHoleActive = aktif

    character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    head = character:FindFirstChild("Head")

    if aktif then
        ToggleBtn.Text = "SIEXTHER | AKTIF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        
        mulaiUnanchor()
        mulaBringPart()
    else
        ToggleBtn.Text = "SIEXTHER | OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        
        stopUnanchor()
        stopBringPart()
    end
end)

-- ========== WINDOW CONTROLS ==========
CloseBtn.MouseButton1Click:Connect(function()
    local tween = TweenService:Create(MainFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 0)})
    tween:Play()
    tween.Completed:Wait()
    ScreenGui:Destroy()
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    local tween = TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 0, 0)})
    tween:Play()
    tween.Completed:Connect(function()
        MainFrame.Visible = false
        MiniFrame.Visible = true
    end)
end)

MiniFrame.MouseButton1Click:Connect(function()
    MiniFrame.Visible = false
    MainFrame.Visible = true
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    local tween = TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 280, 0, 200)})
    tween:Play()
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    if aktif then
        aktif = false
        blackHoleActive = false
        stopUnanchor()
        stopBringPart()
        ToggleBtn.Text = "SIEXTHER | OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    end
end)


