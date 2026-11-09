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
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Variables dari script asli
local getpart = 300
local currentMode = 2
local radius = 50
local speed = 2
local isActive = false
local lastValidPosition = Vector3.new(0, 0, 0)
local UPDATE_INTERVAL = 0
local lastUpdate = tick()
local ringParts = {}
local humanoidRootPart
local blackHoleActive = false
local bhradius = 8
local angleSpeed = 10
local angle = 1
local currentTargetPlayer = LocalPlayer
local Folder, Attachment1
local controlledParts = {}
local descendantConnection = nil
local renderLoop = nil

local modes = {
    "VERTICAL", "HORIZONTAL", "VERTICAL & HORIZONTAL",
    "Left Tilt", "Right Tilt", "Left & Right Tilt", "Spiral", "Figure 8",
    "HELIX", "Flower Pattern", "Galaxy Spiral", "Infinity", "Wave Pattern",
    "Atomic Orbit", "Butterfly", "Tornado", "Heart", "Vortex", "Pendulum",
    "Lemniscate 3D", "Star Pattern", "Trefoil Knot", "Double Spiral",
    "Mobius Strip", "Hypocycloid", "Sphere Spiral", "Asteroid Belt",
    "Rose Curve", "Lissajous", "Polygonal Orbit"
}

-- Network setup
if not getgenv().Network then
    getgenv().Network = {
        BaseParts = {},
        FPS = 20,
        Velocity = Vector3.new(25.1, 0, 0)
    }
    
    local function EnableNetwork()
        local function UpdateNetwork()
            if not isActive then return end
            pcall(function()
                sethiddenproperty(LocalPlayer, "MaxSimulationRadius", getpart)
                sethiddenproperty(LocalPlayer, "SimulationRadius", getpart)
            end)
            local partsToProcess = {}
            for part in pairs(Network.BaseParts) do
                table.insert(partsToProcess, part)
            end
            for _, part in ipairs(partsToProcess) do
                if not part or not part.Parent then
                    Network.BaseParts[part] = nil
                    continue
                end
                pcall(function()
                    sethiddenproperty(part, "NetworkOwnership", Enum.NetworkOwnership.Manual)
                    sethiddenproperty(part, "CustomPhysicalProperties", PhysicalProperties.new(0.7, 0.3, 0.5))
                    part.Velocity = Network.Velocity
                end)
            end
        end
        RunService.Heartbeat:Connect(UpdateNetwork)
    end
    EnableNetwork()
end

-- Fungsi helper
local function GetPlayer(name)
    if not name or name == "" then return LocalPlayer end
    if string.lower(name) == "You" then return LocalPlayer end
    name = string.lower(name)
    for _, plr in pairs(Players:GetPlayers()) do
        if string.find(string.lower(plr.Name), name) or string.find(string.lower(plr.DisplayName), name) then
            return plr
        end
    end
    return LocalPlayer
end

local function GetPlayerList()
    local playerList = {{
        name = "You", 
        display = LocalPlayer.DisplayName .. " (You)", 
        username = "You"
    }}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerList, {
                name = player.Name,
                display = player.DisplayName .. " (@" .. player.Name .. ")",
                username = player.Name
            })
        end
    end
    return playerList
end

local function setupPlayer(targetPlayer)
    local character = targetPlayer.Character
    if not character then
        character = targetPlayer.CharacterAdded:Wait()
    end
    local rootPart = character:WaitForChild("HumanoidRootPart")
    if Folder then
        Folder:Destroy()
        Folder = nil
    end
    Folder = __SIEXTHER_VIP_GLASS_V1.Instance.new("Folder", Workspace)
    Folder.Name = "BlackHoleAttachments"
    local Part = __SIEXTHER_VIP_GLASS_V1.Instance.new("Part", Folder)
    Part.Name = "BlackHoleCenter"
    Attachment1 = __SIEXTHER_VIP_GLASS_V1.Instance.new("Attachment", Part)
    Part.Anchored = true
    Part.CanCollide = false
    Part.Transparency = 1
    return rootPart, Attachment1
end

humanoidRootPart, Attachment1 = setupPlayer(LocalPlayer)

local function processPart(part)
    if part:IsA("Part") and not part.Anchored and 
       not part.Parent:FindFirstChild("Humanoid") and 
       not part.Parent:FindFirstChild("Head") and 
       part.Name ~= "Handle" then
        
        if not pcall(function() return part.Parent end) then
            return nil
        end
        
        for _, child in pairs(part:GetChildren()) do
            if child:IsA("BodyAngularVelocity") or child:IsA("BodyForce") or 
               child:IsA("BodyGyro") or child:IsA("BodyPosition") or 
               child:IsA("BodyThrust") or child:IsA("BodyVelocity") or 
               child:IsA("RocketPropulsion") or child:IsA("Attachment") or 
               child:IsA("AlignPosition") or child:IsA("AlignOrientation") or 
               child:IsA("LinearVelocity") or child:IsA("BodyMover") then
                child:Destroy()
            end
        end
        
        part.CanCollide = false
        part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        
        local attachment = __SIEXTHER_VIP_GLASS_V1.Instance.new("Attachment", part)
        local alignPos = __SIEXTHER_VIP_GLASS_V1.Instance.new("AlignPosition", part)
        alignPos.Attachment0 = attachment
        alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
        alignPos.Responsiveness = 200
        
        return {
            part = part,
            align = alignPos,
            index = 0
        }
    end
    return nil
end

local function calculateRingPosition(index, totalParts, center)
    local angle = (index / totalParts) * (2 * math.pi) + tick() * speed
    local offsetX, offsetY, offsetZ = 0, 0, 0
    
    if currentMode == 1 then
        offsetX = math.cos(angle) * radius
        offsetY = math.sin(angle) * radius
    elseif currentMode == 2 then
        offsetX = math.cos(angle) * radius
        offsetZ = math.sin(angle) * radius
    elseif currentMode == 3 then
        local angle2 = angle + math.pi/2
        offsetX = math.cos(angle) * radius
        offsetY = math.sin(angle2) * radius
        offsetZ = math.sin(angle) * radius
    elseif currentMode == 4 then
        offsetX = math.cos(angle) * radius
        offsetY = math.sin(angle) * radius * 0.5
        offsetZ = math.sin(angle) * radius * 0.866
    elseif currentMode == 5 then
        offsetX = math.cos(angle) * radius
        offsetY = math.sin(angle) * radius * 0.5
        offsetZ = -math.sin(angle) * radius * 0.866
    elseif currentMode == 6 then
        local tiltAngle = math.sin(tick() * speed * 0.5) * math.pi/3
        offsetX = math.cos(angle) * radius
        offsetY = math.sin(angle) * radius * math.cos(tiltAngle)
        offsetZ = math.sin(angle) * radius * math.sin(tiltAngle)
    elseif currentMode == 7 then
        local heightOffset = ((index / totalParts) * 2 - 1) * radius
        offsetX = math.cos(angle) * radius
        offsetY = heightOffset
        offsetZ = math.sin(angle) * radius
    elseif currentMode == 8 then
        local scale = 1.5
        offsetX = math.cos(angle) * radius
        offsetY = math.sin(2 * angle) * radius * 0.5
        offsetZ = math.sin(angle) * radius * scale
    elseif currentMode == 9 then
        local heightOffset = math.sin(tick() * speed) * radius
        offsetX = math.cos(angle) * radius
        offsetY = math.cos(angle * 2) * radius + heightOffset
        offsetZ = math.sin(angle) * radius
    elseif currentMode == 10 then
        local petalCount = 5
        local r = math.cos(petalCount * angle) * radius
        offsetX = math.cos(angle) * r
        offsetY = math.sin(angle) * r
        offsetZ = math.sin(petalCount * angle) * radius * 0.5
    elseif currentMode == 11 then
        local spiralTightness = 0.2
        local r = (1 + angle * spiralTightness) * radius
        offsetX = math.cos(angle) * r
        offsetY = math.sin(tick() * speed) * radius * 0.2
        offsetZ = math.sin(angle) * r
    elseif currentMode == 12 then
        local scale = 1.5
        offsetX = math.cos(angle) * radius * scale
        offsetY = math.sin(2 * angle) * radius * 0.5
        offsetZ = math.sin(angle) * radius
    elseif currentMode == 13 then
        offsetX = angle * radius * 0.1
        offsetY = math.sin(angle * 2) * radius
        offsetZ = math.cos(angle * 2) * radius
    elseif currentMode == 14 then
        local subOrbitRadius = radius * 0.3
        local mainAngle = tick() * speed
        local subAngle = angle * 3
        offsetX = math.cos(mainAngle) * radius + math.cos(subAngle) * subOrbitRadius
        offsetY = math.sin(mainAngle) * radius + math.sin(subAngle) * subOrbitRadius
        offsetZ = math.cos(subAngle) * subOrbitRadius
    elseif currentMode == 15 then
        local t = angle
        offsetX = math.sin(t) * (math.exp(math.cos(t)) - 2 * math.cos(4*t) - math.pow(math.sin(t/12), 5)) * radius * 0.5
        offsetY = math.cos(t) * (math.exp(math.cos(t)) - 2 * math.cos(4*t) - math.pow(math.sin(t/12), 5)) * radius * 0.5
        offsetZ = math.sin(t * 3) * radius * 0.3
    elseif currentMode == 16 then
        local heightScale = 2
        local r = radius * (1 - (index / totalParts))
        offsetX = math.cos(angle) * r
        offsetY = (index / totalParts) * radius * heightScale
        offsetZ = math.sin(angle) * r
    elseif currentMode == 17 then
        local t = angle
        offsetX = 16 * math.sin(t) ^ 3 * (radius * 0.1)
        offsetY = (13 * math.cos(t) - 5 * math.cos(2*t) - 2 * math.cos(3*t) - math.cos(4*t)) * (radius * 0.1)
        offsetZ = math.sin(t * 2) * radius * 0.3
    elseif currentMode == 18 then
        local spiral = angle * 0.1
        local height = math.sin(tick() * speed) * radius
        offsetX = (radius + spiral) * math.cos(angle)
        offsetY = height + (index / totalParts) * radius
        offsetZ = (radius + spiral) * math.sin(angle)
    elseif currentMode == 19 then
        local swingAngle = math.sin(tick() * speed) * math.pi/2
        offsetX = math.sin(swingAngle) * radius
        offsetY = -math.cos(swingAngle) * radius
        offsetZ = math.sin(angle) * radius * 0.3
    elseif currentMode == 20 then
        local t = angle
        local scale = radius * 0.8
        offsetX = scale * math.cos(t) / (1 + math.sin(t)^2)
        offsetY = scale * math.sin(t) * math.cos(t) / (1 + math.sin(t)^2)
        offsetZ = math.sin(t * 2) * radius * 0.5
    elseif currentMode == 21 then
        local points = 5
        local innerRadius = radius * 0.4
        local t = angle * points
        local r = innerRadius + (radius - innerRadius) * math.abs(math.sin(t))
        offsetX = r * math.cos(angle)
        offsetY = r * math.sin(angle)
        offsetZ = math.sin(angle * points) * radius * 0.3
    elseif currentMode == 22 then
        local t = angle
        offsetX = (2 + math.cos(3*t)) * math.cos(2*t) * radius * 0.2
        offsetY = (2 + math.cos(3*t)) * math.sin(2*t) * radius * 0.2
        offsetZ = math.sin(3*t) * radius * 0.2
    elseif currentMode == 23 then
        local t = angle
        local r1 = radius * (0.5 + 0.5 * math.cos(t * 5))
        local r2 = radius * (0.5 + 0.5 * math.sin(t * 5))
        offsetX = math.cos(t) * r1
        offsetY = math.sin(t) * r1
        offsetZ = math.cos(t) * r2
    elseif currentMode == 24 then
        local t = angle
        local s = (index / totalParts) * 2 - 1
        offsetX = (radius + s * math.cos(t/2)) * math.cos(t)
        offsetY = (radius + s * math.cos(t/2)) * math.sin(t)
        offsetZ = s * math.sin(t/2)
    elseif currentMode == 25 then
        local a = radius
        local b = radius * 0.2
        local t = angle * 4
        offsetX = (a - b) * math.cos(t) + b * math.cos((a-b)/b * t)
        offsetY = (a - b) * math.sin(t) - b * math.sin((a-b)/b * t)
        offsetZ = math.sin(t * 2) * radius * 0.3
    elseif currentMode == 26 then
        local phi = angle
        local theta = (index / totalParts) * math.pi
        offsetX = radius * math.sin(theta) * math.cos(phi)
        offsetY = radius * math.sin(theta) * math.sin(phi)
        offsetZ = radius * math.cos(theta)
    elseif currentMode == 27 then
        local baseAngle = (index / totalParts) * (2 * math.pi)
        local wobble = math.sin(tick() * speed + baseAngle * 3) * (radius * 0.2)
        local r = radius + wobble
        offsetX = math.cos(angle) * r
        offsetY = math.sin(baseAngle * 2) * (radius * 0.1)
        offsetZ = math.sin(angle) * r
    elseif currentMode == 28 then
        local n = 3
        local d = 2
        local k = n/d
        local r = radius * math.cos(k * angle)
        offsetX = r * math.cos(angle)
        offsetY = r * math.sin(angle)
        offsetZ = math.sin(angle * k) * radius * 0.3
    elseif currentMode == 29 then
        local a = 3
        local b = 2
        offsetX = radius * math.sin(a * angle)
        offsetY = radius * math.cos(b * angle)
        offsetZ = radius * math.sin((a+b) * angle) * 0.3
    elseif currentMode == 30 then
        local sides = 6
        local angleSnap = math.floor(angle * sides / (2 * math.pi)) * (2 * math.pi / sides)
        local transition = (angle * sides / (2 * math.pi)) % 1
        local nextAngleSnap = angleSnap + (2 * math.pi / sides)
        local currentX = math.cos(angleSnap) * radius
        local currentZ = math.sin(angleSnap) * radius
        local nextX = math.cos(nextAngleSnap) * radius
        local nextZ = math.sin(nextAngleSnap) * radius
        offsetX = currentX + (nextX - currentX) * transition
        offsetY = math.sin(angle * 2) * radius * 0.2
        offsetZ = currentZ + (nextZ - currentZ) * transition
    end
    
    return center + Vector3.new(offsetX, offsetY, offsetZ)
end

local function updateRingPositions()
    if not isActive then return end
    local currentTime = tick()
    if currentTime - lastUpdate < UPDATE_INTERVAL then return end
    lastUpdate = currentTime
    local position = (humanoidRootPart and humanoidRootPart.Position) or lastValidPosition
    if position then
        lastValidPosition = position
        local totalParts = #ringParts
        for i = #ringParts, 1, -1 do
            local data = ringParts[i]
            local validPart = pcall(function() return data.part.Parent ~= nil end)
            if validPart then
                local targetPos = calculateRingPosition(i, totalParts, position)
                data.align.Position = targetPos
            else
                Network.BaseParts[data.part] = nil
                table.remove(ringParts, i)
            end
        end
    end
end

local function orbite()
    isActive = not isActive
    if isActive then
        ringParts = {}
        for _, v in ipairs(Workspace:GetDescendants()) do
            local partData = processPart(v)
            if partData then
                table.insert(ringParts, partData)
                Network.BaseParts[partData.part] = true
            end
        end
        local connection
        connection = Workspace.DescendantAdded:Connect(function(v)
            if not isActive then
                connection:Disconnect()
                return
            end
            local partData = processPart(v)
            if partData then
                table.insert(ringParts, partData)
                Network.BaseParts[partData.part] = true
            end
        end)
        RunService.Heartbeat:Connect(updateRingPositions)
    else
        for i = #ringParts, 1, -1 do
            local data = ringParts[i]
            if data.part and data.part.Parent then
                Network.BaseParts[data.part] = nil
                if data.align then 
                    pcall(function() data.align:Destroy() end)
                end
            end
        end
        ringParts = {}
    end
end

local function ForcePart(v)
    if v:IsA("Part") and not v.Anchored and not v.Parent:FindFirstChild("Humanoid") and not v.Parent:FindFirstChild("Head") and v.Name ~= "Handle" then
        for _, x in next, v:GetChildren() do
            if x:IsA("BodyAngularVelocity") or x:IsA("BodyForce") or x:IsA("BodyGyro") or x:IsA("BodyPosition") or x:IsA("BodyThrust") or x:IsA("BodyVelocity") or x:IsA("RocketPropulsion") then
                x:Destroy()
            end
        end
        if v:FindFirstChild("Attachment") then v:FindFirstChild("Attachment"):Destroy() end
        if v:FindFirstChild("AlignPosition") then v:FindFirstChild("AlignPosition"):Destroy() end
        if v:FindFirstChild("Torque") then v:FindFirstChild("Torque"):Destroy() end
        v.CanCollide = false
        local Torque = __SIEXTHER_VIP_GLASS_V1.Instance.new("Torque", v)
        Torque.Torque = Vector3.new(1000000, 1000000, 1000000)
        local AlignPosition = __SIEXTHER_VIP_GLASS_V1.Instance.new("AlignPosition", v)
        local Attachment2 = __SIEXTHER_VIP_GLASS_V1.Instance.new("Attachment", v)
        Torque.Attachment0 = Attachment2
        AlignPosition.MaxForce = math.huge
        AlignPosition.MaxVelocity = math.huge
        AlignPosition.Responsiveness = 500
        AlignPosition.Attachment0 = Attachment2
        AlignPosition.Attachment1 = Attachment1
        controlledParts[v] = {
            Torque = Torque,
            AlignPosition = AlignPosition,
            Attachment = Attachment2
        }
    end
end

local function releaseAllParts()
    for part, constraints in pairs(controlledParts) do
        if part and part.Parent then
            for _, constraint in pairs(constraints) do
                if constraint and constraint.Parent then
                    constraint:Destroy()
                end
            end
        end
    end
    controlledParts = {}
end

local function togglebh()
    blackHoleActive = not blackHoleActive
    if blackHoleActive then
        humanoidRootPart, Attachment1 = setupPlayer(currentTargetPlayer)
        for _, v in next, Workspace:GetDescendants() do
            ForcePart(v)
        end
        descendantConnection = Workspace.DescendantAdded:Connect(function(v)
            if blackHoleActive then
                ForcePart(v)
            end
        end)
        renderLoop = RunService.RenderStepped:Connect(function()
            if not blackHoleActive then
                if renderLoop then
                    renderLoop:Disconnect()
                    renderLoop = nil
                end
                return
            end
            if humanoidRootPart and humanoidRootPart.Parent then
                angle = angle + math.rad(angleSpeed)
                local offsetX = math.cos(angle) * bhradius
                local offsetZ = math.sin(angle) * bhradius
                Attachment1.WorldCFrame = humanoidRootPart.CFrame * CFrame.new(offsetX, 0, offsetZ)
            else
                humanoidRootPart, Attachment1 = setupPlayer(currentTargetPlayer)
            end
        end)
    else
        if descendantConnection then
            descendantConnection:Disconnect()
            descendantConnection = nil
        end
        if renderLoop then
            renderLoop:Disconnect()
            renderLoop = nil
        end
        releaseAllParts()
        if Attachment1 then
            Attachment1.WorldCFrame = CFrame.new(0, -10000, 0)
        end
        if Folder then
            Folder:Destroy()
            Folder = nil
        end
    end
end

-- GUI Creation
local ScreenGui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
ScreenGui.Name = "PartOrbitBlackHoleGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- Main Frame (Ukuran disesuaikan tanpa space kosong)
local MainFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -135, 0.5, -100)
MainFrame.Size = UDim2.new(0, 270, 0, 200)
MainFrame.Parent = ScreenGui

local UIStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(70, 130, 255)
UIStroke.Thickness = 2
UIStroke.Parent = MainFrame

local UICorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Floating Button (Hidden by default)
local FloatingBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
FloatingBtn.Name = "FloatingBtn"
FloatingBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
FloatingBtn.BorderSizePixel = 0
FloatingBtn.Position = UDim2.new(0, 15, 0.5, -22.5)
FloatingBtn.Size = UDim2.new(0, 41, 0, 41)
FloatingBtn.Font = Enum.Font.GothamBold
FloatingBtn.Text = "☠️"
FloatingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingBtn.TextSize = 20
FloatingBtn.Visible = false
FloatingBtn.Parent = ScreenGui
FloatingBtn.ZIndex = 5

local FloatCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(0, 12)
FloatCorner.Parent = FloatingBtn

-- Title Bar
local TitleBar = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
TitleBar.BorderSizePixel = 0
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.Parent = MainFrame

local TitleCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

local Title = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
Title.Name = "Title"
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 8, 0, 0)
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "SIEXTHER PART-CONTROLLER"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Minimize Button
local MinimizeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Position = UDim2.new(1, -53, 0, 4)
MinimizeBtn.Size = UDim2.new(0, 22, 0, 22)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Text = "–"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 16
MinimizeBtn.Parent = TitleBar

local MinCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 4)
MinCorner.Parent = MinimizeBtn

-- Close Button
local CloseBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
CloseBtn.BorderSizePixel = 0
CloseBtn.Position = UDim2.new(1, -27, 0, 4)
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 12
CloseBtn.Parent = TitleBar

local CloseCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseBtn

-- Tab Buttons Container
local TabContainer = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.BackgroundTransparency = 1
TabContainer.Position = UDim2.new(0, 0, 0, 30)
TabContainer.Size = UDim2.new(1, 0, 0, 32)
TabContainer.Parent = MainFrame

local Tab1Btn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
Tab1Btn.Name = "Tab1Btn"
Tab1Btn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
Tab1Btn.BorderSizePixel = 0
Tab1Btn.Position = UDim2.new(0, 8, 0, 4)
Tab1Btn.Size = UDim2.new(0.48, -10, 0, 24)
Tab1Btn.Font = Enum.Font.GothamBold
Tab1Btn.Text = "SIEXTHER"
Tab1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
Tab1Btn.TextSize = 12
Tab1Btn.Parent = TabContainer

local Tab1Corner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
Tab1Corner.CornerRadius = UDim.new(0, 5)
Tab1Corner.Parent = Tab1Btn

local Tab2Btn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
Tab2Btn.Name = "Tab2Btn"
Tab2Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Tab2Btn.BorderSizePixel = 0
Tab2Btn.Position = UDim2.new(0.52, 2, 0, 4)
Tab2Btn.Size = UDim2.new(0.48, -10, 0, 24)
Tab2Btn.Font = Enum.Font.GothamBold
Tab2Btn.Text = "MORBVEIL"
Tab2Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
Tab2Btn.TextSize = 12
Tab2Btn.Parent = TabContainer

local Tab2Corner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
Tab2Corner.CornerRadius = UDim.new(0, 5)
Tab2Corner.Parent = Tab2Btn

-- Content Frame
local ContentFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 8, 0, 66)
ContentFrame.Size = UDim2.new(1, -16, 1, -72)
ContentFrame.Parent = MainFrame

-- PartOrbit Tab Content
local PartOrbitTab = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
PartOrbitTab.Name = "PartOrbitTab"
PartOrbitTab.BackgroundTransparency = 1
PartOrbitTab.Size = UDim2.new(1, 0, 1, 0)
PartOrbitTab.Visible = true
PartOrbitTab.Parent = ContentFrame

-- Toggle Button
local ToggleBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Position = UDim2.new(0, 0, 0, 0)
ToggleBtn.Size = UDim2.new(1, 0, 0, 28)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Text = "AKTIFKAN"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 11
ToggleBtn.Parent = PartOrbitTab

local ToggleCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 5)
ToggleCorner.Parent = ToggleBtn

-- Radius Controls
local RadiusLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
RadiusLabel.Name = "RadiusLabel"
RadiusLabel.BackgroundTransparency = 1
RadiusLabel.Position = UDim2.new(0, 0, 0, 34)
RadiusLabel.Size = UDim2.new(1, 0, 0, 14)
RadiusLabel.Font = Enum.Font.GothamSemibold
RadiusLabel.Text = "Radius: 50"
RadiusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
RadiusLabel.TextSize = 10
RadiusLabel.TextXAlignment = Enum.TextXAlignment.Left
RadiusLabel.Parent = PartOrbitTab

local RadiusSlider = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
RadiusSlider.Name = "RadiusSlider"
RadiusSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
RadiusSlider.BorderSizePixel = 0
RadiusSlider.Position = UDim2.new(0, 0, 0, 50)
RadiusSlider.Size = UDim2.new(0.68, 0, 0, 18)
RadiusSlider.Parent = PartOrbitTab

local RadSliderCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
RadSliderCorner.CornerRadius = UDim.new(0, 4)
RadSliderCorner.Parent = RadiusSlider

local RadiusFill = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
RadiusFill.Name = "Fill"
RadiusFill.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
RadiusFill.BorderSizePixel = 0
RadiusFill.Size = UDim2.new(0.5, 0, 1, 0)
RadiusFill.Parent = RadiusSlider

local RadFillCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
RadFillCorner.CornerRadius = UDim.new(0, 4)
RadFillCorner.Parent = RadiusFill

local RadiusInput = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextBox")
RadiusInput.Name = "RadiusInput"
RadiusInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
RadiusInput.BorderSizePixel = 0
RadiusInput.Position = UDim2.new(0.72, 0, 0, 50)
RadiusInput.Size = UDim2.new(0.28, 0, 0, 18)
RadiusInput.Font = Enum.Font.GothamSemibold
RadiusInput.PlaceholderText = "50"
RadiusInput.Text = "50"
RadiusInput.TextColor3 = Color3.fromRGB(255, 255, 255)
RadiusInput.TextSize = 10
RadiusInput.Parent = PartOrbitTab

local RadInputCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
RadInputCorner.CornerRadius = UDim.new(0, 4)
RadInputCorner.Parent = RadiusInput

-- Speed Controls
local SpeedLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
SpeedLabel.Name = "SpeedLabel"
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Position = UDim2.new(0, 0, 0, 74)
SpeedLabel.Size = UDim2.new(1, 0, 0, 14)
SpeedLabel.Font = Enum.Font.GothamSemibold
SpeedLabel.Text = "Speed: 2"
SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedLabel.TextSize = 10
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent = PartOrbitTab

local SpeedSlider = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
SpeedSlider.Name = "SpeedSlider"
SpeedSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
SpeedSlider.BorderSizePixel = 0
SpeedSlider.Position = UDim2.new(0, 0, 0, 90)
SpeedSlider.Size = UDim2.new(0.68, 0, 0, 18)
SpeedSlider.Parent = PartOrbitTab

local SpdSliderCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
SpdSliderCorner.CornerRadius = UDim.new(0, 4)
SpdSliderCorner.Parent = SpeedSlider

local SpeedFill = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
SpeedFill.Name = "Fill"
SpeedFill.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
SpeedFill.BorderSizePixel = 0
SpeedFill.Size = UDim2.new(0.2, 0, 1, 0)
SpeedFill.Parent = SpeedSlider

local SpdFillCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
SpdFillCorner.CornerRadius = UDim.new(0, 4)
SpdFillCorner.Parent = SpeedFill

local SpeedInput = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextBox")
SpeedInput.Name = "SpeedInput"
SpeedInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
SpeedInput.BorderSizePixel = 0
SpeedInput.Position = UDim2.new(0.72, 0, 0, 90)
SpeedInput.Size = UDim2.new(0.28, 0, 0, 18)
SpeedInput.Font = Enum.Font.GothamSemibold
SpeedInput.PlaceholderText = "2"
SpeedInput.Text = "2"
SpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedInput.TextSize = 10
SpeedInput.Parent = PartOrbitTab

local SpdInputCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
SpdInputCorner.CornerRadius = UDim.new(0, 4)
SpdInputCorner.Parent = SpeedInput

-- Black Hole Tab Content
local BlackHoleTab = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
BlackHoleTab.Name = "BlackHoleTab"
BlackHoleTab.BackgroundTransparency = 1
BlackHoleTab.Size = UDim2.new(1, 0, 1, 0)
BlackHoleTab.Visible = false
BlackHoleTab.Parent = ContentFrame

-- BH Toggle Button
local BHToggleBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
BHToggleBtn.Name = "BHToggleBtn"
BHToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
BHToggleBtn.BorderSizePixel = 0
BHToggleBtn.Position = UDim2.new(0, 0, 0, 0)
BHToggleBtn.Size = UDim2.new(1, 0, 0, 28)
BHToggleBtn.Font = Enum.Font.GothamBold
BHToggleBtn.Text = "AKTIFKAN"
BHToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BHToggleBtn.TextSize = 11
BHToggleBtn.Parent = BlackHoleTab

local BHToggleCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
BHToggleCorner.CornerRadius = UDim.new(0, 5)
BHToggleCorner.Parent = BHToggleBtn

-- BH Radius Controls
local BHRadiusLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
BHRadiusLabel.Name = "BHRadiusLabel"
BHRadiusLabel.BackgroundTransparency = 1
BHRadiusLabel.Position = UDim2.new(0, 0, 0, 34)
BHRadiusLabel.Size = UDim2.new(1, 0, 0, 14)
BHRadiusLabel.Font = Enum.Font.GothamSemibold
BHRadiusLabel.Text = "Radius: 8"
BHRadiusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
BHRadiusLabel.TextSize = 10
BHRadiusLabel.TextXAlignment = Enum.TextXAlignment.Left
BHRadiusLabel.Parent = BlackHoleTab

local BHRadiusSlider = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
BHRadiusSlider.Name = "BHRadiusSlider"
BHRadiusSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
BHRadiusSlider.BorderSizePixel = 0
BHRadiusSlider.Position = UDim2.new(0, 0, 0, 50)
BHRadiusSlider.Size = UDim2.new(0.68, 0, 0, 18)
BHRadiusSlider.Parent = BlackHoleTab

local BHRadSliderCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
BHRadSliderCorner.CornerRadius = UDim.new(0, 4)
BHRadSliderCorner.Parent = BHRadiusSlider

local BHRadiusFill = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
BHRadiusFill.Name = "Fill"
BHRadiusFill.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
BHRadiusFill.BorderSizePixel = 0
BHRadiusFill.Size = UDim2.new(0.08, 0, 1, 0)
BHRadiusFill.Parent = BHRadiusSlider

local BHRadFillCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
BHRadFillCorner.CornerRadius = UDim.new(0, 4)
BHRadFillCorner.Parent = BHRadiusFill

local BHRadiusInput = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextBox")
BHRadiusInput.Name = "BHRadiusInput"
BHRadiusInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
BHRadiusInput.BorderSizePixel = 0
BHRadiusInput.Position = UDim2.new(0.72, 0, 0, 50)
BHRadiusInput.Size = UDim2.new(0.28, 0, 0, 18)
BHRadiusInput.Font = Enum.Font.GothamSemibold
BHRadiusInput.PlaceholderText = "8"
BHRadiusInput.Text = "8"
BHRadiusInput.TextColor3 = Color3.fromRGB(255, 255, 255)
BHRadiusInput.TextSize = 10
BHRadiusInput.Parent = BlackHoleTab

local BHRadInputCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
BHRadInputCorner.CornerRadius = UDim.new(0, 4)
BHRadInputCorner.Parent = BHRadiusInput

-- Rotation Speed Controls
local RotSpeedLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
RotSpeedLabel.Name = "RotSpeedLabel"
RotSpeedLabel.BackgroundTransparency = 1
RotSpeedLabel.Position = UDim2.new(0, 0, 0, 74)
RotSpeedLabel.Size = UDim2.new(1, 0, 0, 14)
RotSpeedLabel.Font = Enum.Font.GothamSemibold
RotSpeedLabel.Text = "Rotation Speed: 10"
RotSpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
RotSpeedLabel.TextSize = 10
RotSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
RotSpeedLabel.Parent = BlackHoleTab

local RotSpeedSlider = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
RotSpeedSlider.Name = "RotSpeedSlider"
RotSpeedSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
RotSpeedSlider.BorderSizePixel = 0
RotSpeedSlider.Position = UDim2.new(0, 0, 0, 90)
RotSpeedSlider.Size = UDim2.new(0.68, 0, 0, 18)
RotSpeedSlider.Parent = BlackHoleTab

local RotSliderCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
RotSliderCorner.CornerRadius = UDim.new(0, 4)
RotSliderCorner.Parent = RotSpeedSlider

local RotSpeedFill = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
RotSpeedFill.Name = "Fill"
RotSpeedFill.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
RotSpeedFill.BorderSizePixel = 0
RotSpeedFill.Size = UDim2.new(0.1, 0, 1, 0)
RotSpeedFill.Parent = RotSpeedSlider

local RotFillCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
RotFillCorner.CornerRadius = UDim.new(0, 4)
RotFillCorner.Parent = RotSpeedFill

local RotSpeedInput = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextBox")
RotSpeedInput.Name = "RotSpeedInput"
RotSpeedInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
RotSpeedInput.BorderSizePixel = 0
RotSpeedInput.Position = UDim2.new(0.72, 0, 0, 90)
RotSpeedInput.Size = UDim2.new(0.28, 0, 0, 18)
RotSpeedInput.Font = Enum.Font.GothamSemibold
RotSpeedInput.PlaceholderText = "10"
RotSpeedInput.Text = "10"
RotSpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
RotSpeedInput.TextSize = 10
RotSpeedInput.Parent = BlackHoleTab

local RotInputCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
RotInputCorner.CornerRadius = UDim.new(0, 4)
RotInputCorner.Parent = RotSpeedInput

-- Functionality
local minimized = false
local dragging = false
local dragInput, dragStart, startPos

-- Dragging Main Frame
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Dragging Floating Button
local floatDragging = false
local floatDragInput, floatDragStart, floatStartPos

FloatingBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        floatDragging = true
        floatDragStart = input.Position
        floatStartPos = FloatingBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                floatDragging = false
            end
        end)
    end
end)

FloatingBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        floatDragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == floatDragInput and floatDragging then
        local delta = input.Position - floatDragStart
        FloatingBtn.Position = UDim2.new(floatStartPos.X.Scale, floatStartPos.X.Offset + delta.X, floatStartPos.Y.Scale, floatStartPos.Y.Offset + delta.Y)
    end
end)

-- Minimize with Floating Button
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame.Visible = false
        FloatingBtn.Visible = true
    else
        FloatingBtn.Visible = false
        MainFrame.Visible = true
    end
end)

-- Floating Button Click to Restore
FloatingBtn.MouseButton1Click:Connect(function()
    minimized = false
    FloatingBtn.Visible = false
    MainFrame.Visible = true
end)

-- Close
CloseBtn.MouseButton1Click:Connect(function()
    if isActive then orbite() end
    if blackHoleActive then togglebh() end
    ScreenGui:Destroy()
end)

-- Tab Switching
Tab1Btn.MouseButton1Click:Connect(function()
    Tab1Btn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    Tab1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tab2Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    Tab2Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    PartOrbitTab.Visible = true
    BlackHoleTab.Visible = false
end)

Tab2Btn.MouseButton1Click:Connect(function()
    Tab2Btn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    Tab2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tab1Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    Tab1Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    BlackHoleTab.Visible = true
    PartOrbitTab.Visible = false
end)

-- PartOrbit Toggle
ToggleBtn.MouseButton1Click:Connect(function()
    orbite()
    ToggleBtn.Text = isActive and "SIEXTHER : AKTIF" or "SIEXTHER : OFF"
    ToggleBtn.BackgroundColor3 = isActive and Color3.fromRGB(70, 130, 255) or Color3.fromRGB(40, 40, 45)
end)

-- Radius Slider
local radiusDragging = false
RadiusSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        radiusDragging = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        radiusDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if radiusDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = input.Position.X
        local sliderPos = RadiusSlider.AbsolutePosition.X
        local sliderSize = RadiusSlider.AbsoluteSize.X
        local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
        radius = math.floor(percent * 100)
        RadiusFill.Size = UDim2.new(percent, 0, 1, 0)
        RadiusLabel.Text = "Radius: " .. radius
        RadiusInput.Text = tostring(radius)
    end
end)

RadiusInput.FocusLost:Connect(function()
    local val = tonumber(RadiusInput.Text)
    if val and val >= 0 and val <= 100 then
        radius = val
        RadiusFill.Size = UDim2.new(val / 100, 0, 1, 0)
        RadiusLabel.Text = "Radius: " .. radius
    else
        RadiusInput.Text = tostring(radius)
    end
end)

-- Speed Slider
local speedDragging = false
SpeedSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        speedDragging = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        speedDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if speedDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = input.Position.X
        local sliderPos = SpeedSlider.AbsolutePosition.X
        local sliderSize = SpeedSlider.AbsoluteSize.X
        local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
        speed = math.floor(percent * 10)
        SpeedFill.Size = UDim2.new(percent, 0, 1, 0)
        SpeedLabel.Text = "Speed: " .. speed
        SpeedInput.Text = tostring(speed)
    end
end)

SpeedInput.FocusLost:Connect(function()
    local val = tonumber(SpeedInput.Text)
    if val and val >= 0 and val <= 10 then
        speed = val
        SpeedFill.Size = UDim2.new(val / 10, 0, 1, 0)
        SpeedLabel.Text = "Speed: " .. speed
    else
        SpeedInput.Text = tostring(speed)
    end
end)

-- Black Hole Toggle
BHToggleBtn.MouseButton1Click:Connect(function()
    togglebh()
    BHToggleBtn.Text = blackHoleActive and "MORBVEIL : AKTIF" or "MORBVEIL : OFF"
    BHToggleBtn.BackgroundColor3 = blackHoleActive and Color3.fromRGB(70, 130, 255) or Color3.fromRGB(40, 40, 45)
end)

-- BH Radius Slider
local bhRadiusDragging = false
BHRadiusSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        bhRadiusDragging = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        bhRadiusDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if bhRadiusDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = input.Position.X
        local sliderPos = BHRadiusSlider.AbsolutePosition.X
        local sliderSize = BHRadiusSlider.AbsoluteSize.X
        local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
        bhradius = math.floor(percent * 100)
        BHRadiusFill.Size = UDim2.new(percent, 0, 1, 0)
        BHRadiusLabel.Text = "Radius: " .. bhradius
        BHRadiusInput.Text = tostring(bhradius)
    end
end)

BHRadiusInput.FocusLost:Connect(function()
    local val = tonumber(BHRadiusInput.Text)
    if val and val >= 0 and val <= 100 then
        bhradius = val
        BHRadiusFill.Size = UDim2.new(val / 100, 0, 1, 0)
        BHRadiusLabel.Text = "Radius: " .. bhradius
    else
        BHRadiusInput.Text = tostring(bhradius)
    end
end)

-- Rotation Speed Slider
local rotSpeedDragging = false
RotSpeedSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        rotSpeedDragging = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        rotSpeedDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if rotSpeedDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = input.Position.X
        local sliderPos = RotSpeedSlider.AbsolutePosition.X
        local sliderSize = RotSpeedSlider.AbsoluteSize.X
        local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
        angleSpeed = math.floor(percent * 100)
        RotSpeedFill.Size = UDim2.new(percent, 0, 1, 0)
        RotSpeedLabel.Text = "Rotation Speed: " .. angleSpeed
        RotSpeedInput.Text = tostring(angleSpeed)
    end
end)

RotSpeedInput.FocusLost:Connect(function()
    local val = tonumber(RotSpeedInput.Text)
    if val and val >= 0 and val <= 100 then
        angleSpeed = val
        RotSpeedFill.Size = UDim2.new(val / 100, 0, 1, 0)
        RotSpeedLabel.Text = "Rotation Speed: " .. angleSpeed
    else
        RotSpeedInput.Text = tostring(angleSpeed)
    end
end)

-- Character respawn handler
LocalPlayer.CharacterAdded:Connect(function(character)
    wait(1)
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    if currentTargetPlayer == LocalPlayer then
        humanoidRootPart, Attachment1 = setupPlayer(LocalPlayer)
        if blackHoleActive then
            togglebh()
            wait(0.1)
            togglebh()
        end
    end
end)