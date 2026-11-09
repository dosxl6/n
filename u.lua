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
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

-- State Variables
local CurrentTarget = nil
local OriginalCameraSubject = nil
local IsCameraLocked = false
local SendPartActive = false
local SendPartLoopThread = nil
local NetworkConnection = nil
local FreezeConnection = nil
local OriginalWalkSpeed = 16
local OriginalJumpPower = 50
local IsRandomMode = false

-- Colors (Updated Modern Dark Theme)
local COLORS = {
    DARK_BG = Color3.fromRGB(18, 18, 18),
    MEDIUM_BG = Color3.fromRGB(28, 28, 30),
    STROKE_BLUE = Color3.fromRGB(70, 130, 255),
    TEXT_WHITE = Color3.fromRGB(255, 255, 255),
    TEXT_GRAY = Color3.fromRGB(150, 150, 155),
    BUTTON_INACTIVE = Color3.fromRGB(35, 35, 37),
    BUTTON_ACTIVE = Color3.fromRGB(70, 130, 255),
    BUTTON_HOVER = Color3.fromRGB(45, 45, 48),
    GREEN = Color3.fromRGB(0, 255, 128),
    RED = Color3.fromRGB(255, 70, 70),
    YELLOW = Color3.fromRGB(255, 200, 0)
}

-- Character refs
local humanoid, rootPart
local function refreshCharacterRefs()
    local char = LP.Character
    if char then
        humanoid = char:FindFirstChildOfClass("Humanoid")
        rootPart = char:FindFirstChild("HumanoidRootPart")
        if humanoid then
            OriginalWalkSpeed = humanoid.WalkSpeed
            OriginalJumpPower = humanoid.JumpPower
        end
    else
        humanoid = nil
        rootPart = nil
    end
end
refreshCharacterRefs()

LP.CharacterAdded:Connect(function(char)
    pcall(function()
        char:WaitForChild("Humanoid", 5)
        char:WaitForChild("HumanoidRootPart", 5)
    end)
    refreshCharacterRefs()
end)

-- Helper: Check if part belongs to any player character
local function isPlayerCharacterPart(part)
    local parent = part.Parent
    if parent and parent:FindFirstChildOfClass("Humanoid") then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character == parent then
                return true
            end
        end
    end
    return false
end

-- ========== FREEZE SYSTEM ==========
local function freezeCharacter()
    if FreezeConnection then FreezeConnection:Disconnect() end
    FreezeConnection = RunService.Heartbeat:Connect(function()
        if humanoid and rootPart then
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
            pcall(function()
                rootPart.AssemblyLinearVelocity = Vector3.zero
                rootPart.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end)
    if humanoid then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
    end
end

local function unfreezeCharacter()
    if FreezeConnection then
        FreezeConnection:Disconnect()
        FreezeConnection = nil
    end
    if humanoid then
        humanoid.WalkSpeed = OriginalWalkSpeed
        humanoid.JumpPower = OriginalJumpPower
    end
end

-- ========== NETWORK & SEND PART FUNCTIONS ==========
local function OneTimeUnanchor()
    if _G.__JSY_UnanchorCooldown then return end
    _G.__JSY_UnanchorCooldown = true
    task.spawn(function()
        local start = tick()
        while tick() - start < 1 do
            -- Destroy RopeConstraints
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("RopeConstraint") then
                    local p0 = obj.Attachment0 and obj.Attachment0.Parent
                    local p1 = obj.Attachment1 and obj.Attachment1.Parent
                    pcall(function() obj:Destroy() end)
                    if p0 and p0:IsA("BasePart") and not isPlayerCharacterPart(p0) then 
                        p0.Anchored = false 
                    end
                    if p1 and p1:IsA("BasePart") and not isPlayerCharacterPart(p1) then 
                        p1.Anchored = false 
                    end
                end
            end
            
            -- Apply velocity only to NON-CHARACTER parts
            for _, part in ipairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") and not part.Anchored and not isPlayerCharacterPart(part) then
                    pcall(function()
                        part.AssemblyLinearVelocity = Vector3.new(
                            math.random(-50,50), 
                            math.random(20,100), 
                            math.random(-50,50)
                        )
                    end)
                end
            end
            task.wait(0.2)
        end
        _G.__JSY_UnanchorCooldown = false
    end)
end

local function GetAllPartsRecursive(parent)
    local parts = {}
    for _, obj in ipairs(parent:GetChildren()) do
        if obj:IsA("BasePart") then
            table.insert(parts, obj)
        elseif obj:IsA("Model") or obj:IsA("Folder") then
            for _, p in ipairs(GetAllPartsRecursive(obj)) do
                table.insert(parts, p)
            end
        end
    end
    return parts
end

local function EnableNetworkStabilizer()
    if NetworkConnection then return end
    pcall(function()
        NetworkConnection = RunService.Heartbeat:Connect(function()
            pcall(function()
                if sethiddenproperty then
                    sethiddenproperty(LP, "SimulationRadius", math.huge)
                end
            end)
        end)
    end)
end

local function DisableNetworkStabilizer()
    if NetworkConnection then
        NetworkConnection:Disconnect()
        NetworkConnection = nil
    end
end

local function sendUnanchoredPartsToTarget(target)
    if not target or not target.Character then return end
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end

    EnableNetworkStabilizer()
    OneTimeUnanchor()

    local folder = Workspace:FindFirstChild("SIEXTHERCHAOS") or __SIEXTHER_VIP_GLASS_V1.Instance.new("Folder", Workspace)
    folder.Name = "SIEXTHERCHAOS"

    local targetPart = folder:FindFirstChild("TargetPart") or __SIEXTHER_VIP_GLASS_V1.Instance.new("Part", folder)
    targetPart.Name = "TargetPart"
    targetPart.Anchored = true
    targetPart.CanCollide = false
    targetPart.Transparency = 1
    targetPart.Size = Vector3.new(1,1,1)
    targetPart.CFrame = targetHRP.CFrame
    local attach1 = targetPart:FindFirstChild("Attachment") or __SIEXTHER_VIP_GLASS_V1.Instance.new("Attachment", targetPart)

    local function ForcePart(v)
        if not v:IsA("BasePart") then return end
        if v.Anchored then return end
        if isPlayerCharacterPart(v) then return end -- SKIP PLAYER PARTS
        if v.Name == "Handle" then return end

        local originalCFrame = v.CFrame
        local originalAnchored = v.Anchored
        local originalCanCollide = v.CanCollide

        for _, x in ipairs(v:GetChildren()) do
            if x:IsA("BodyMover") or x:IsA("AlignPosition") or x:IsA("Torque") or x:IsA("RocketPropulsion") or x:IsA("AlignOrientation") then
                pcall(function() x:Destroy() end)
            end
        end

        v.CanCollide = false

        local torque = __SIEXTHER_VIP_GLASS_V1.Instance.new("Torque")
        torque.Parent = v
        torque.Torque = Vector3.new(100000,100000,100000)

        local align = __SIEXTHER_VIP_GLASS_V1.Instance.new("AlignPosition")
        align.Parent = v
        align.MaxForce = math.huge
        align.MaxVelocity = math.huge
        align.Responsiveness = 200

        local attach2 = __SIEXTHER_VIP_GLASS_V1.Instance.new("Attachment", v)
        torque.Attachment0 = attach2
        align.Attachment0 = attach2
        align.Attachment1 = attach1

        task.spawn(function()
            local started = tick()
            while tick() - started < 2 do
                if not v or not v.Parent then break end
                task.wait(0.05)
            end
            pcall(function()
                if v and v:IsA("BasePart") then
                    v.AssemblyLinearVelocity = Vector3.zero
                    v.AssemblyAngularVelocity = Vector3.zero
                end
                if align and align.Parent then align:Destroy() end
                if torque and torque.Parent then torque:Destroy() end
                for _, child in ipairs(v:GetChildren()) do
                    if child:IsA("Attachment") then
                        if child ~= attach1 then
                            pcall(function() child:Destroy() end)
                        end
                    end
                end
                if v and v.Parent then
                    pcall(function()
                        v.CanCollide = originalCanCollide
                        v.Anchored = originalAnchored
                        task.wait(0.05)
                        v.CFrame = originalCFrame
                    end)
                end
            end)
        end)
    end

    local parts = GetAllPartsRecursive(Workspace)
    for _, p in ipairs(parts) do
        pcall(function()
            if not p.Anchored and not isPlayerCharacterPart(p) then
                ForcePart(p)
            end
        end)
    end

    task.spawn(function()
        local duration = 5
        local start = tick()
        while tick() - start < duration do
            if attach1 and targetHRP then
                pcall(function()
                    attach1.WorldCFrame = targetHRP.CFrame
                    targetPart.CFrame = targetHRP.CFrame
                end)
            end
            task.wait()
        end
        pcall(function() folder:Destroy() end)
        DisableNetworkStabilizer()
    end)
end

-- ========== DRAG FUNCTION (UNIVERSAL) ==========
local function makeDraggable(frame)
    local dragging = false
    local dragInput, dragStart, startPos
    
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
end

-- ========== GUI CREATION (SMALLER SIZE) ==========
local ScreenGui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
ScreenGui.Name = "SIEXTHERCHAOSSX"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Floating Button (Minimized State)
local FloatingButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
FloatingButton.Size = UDim2.new(0, 41, 0, 41)
FloatingButton.Position = UDim2.new(0, 15, 0.5, -25)
FloatingButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
FloatingButton.BorderSizePixel = 0
FloatingButton.Text = "☠️"
FloatingButton.TextSize = 13
FloatingButton.TextColor3 = COLORS.TEXT_WHITE
FloatingButton.Visible = false
FloatingButton.Active = true
FloatingButton.Parent = ScreenGui

local FloatCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", FloatingButton)
FloatCorner.CornerRadius = UDim.new(0, 12)

makeDraggable(FloatingButton)

-- Main Frame
local MainFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 320)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -185)
MainFrame.BackgroundColor3 = COLORS.DARK_BG
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 8)

local MainStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke", MainFrame)
MainStroke.Color = COLORS.STROKE_BLUE
MainStroke.Thickness = 2

makeDraggable(MainFrame)

-- Header
local Header = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundColor3 = COLORS.MEDIUM_BG
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", Header)
HeaderCorner.CornerRadius = UDim.new(0, 8)

local Title = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
Title.Size = UDim2.new(1, -65, 1, 0)
Title.Position = UDim2.new(0, 8, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SIEXTHER BRING"
Title.TextColor3 = COLORS.STROKE_BLUE
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Minimize Button
local MinimizeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 22, 0, 22)
MinimizeBtn.Position = UDim2.new(1, -52, 0.5, -11)
MinimizeBtn.BackgroundColor3 = COLORS.BUTTON_INACTIVE
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Text = "–"
MinimizeBtn.TextSize = 16
MinimizeBtn.TextColor3 = COLORS.TEXT_WHITE
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = Header

local MinCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", MinimizeBtn)
MinCorner.CornerRadius = UDim.new(0, 4)

-- Close Button
local CloseBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -26, 0.5, -11)
CloseBtn.BackgroundColor3 = COLORS.RED
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = COLORS.TEXT_WHITE
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = Header

local CloseCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", CloseBtn)
CloseCorner.CornerRadius = UDim.new(0, 4)

-- Search Bar
local SearchFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
SearchFrame.Size = UDim2.new(1, -16, 0, 28)
SearchFrame.Position = UDim2.new(0, 8, 0, 38)
SearchFrame.BackgroundColor3 = COLORS.MEDIUM_BG
SearchFrame.BorderSizePixel = 0
SearchFrame.Parent = MainFrame

local SearchCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", SearchFrame)
SearchCorner.CornerRadius = UDim.new(0, 5)

local SearchBox = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -12, 1, 0)
SearchBox.Position = UDim2.new(0, 6, 0, 0)
SearchBox.BackgroundTransparency = 1
SearchBox.PlaceholderText = "Cari player..."
SearchBox.PlaceholderColor3 = COLORS.TEXT_GRAY
SearchBox.Text = ""
SearchBox.TextColor3 = COLORS.TEXT_WHITE
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 11
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = SearchFrame

-- Player List Scroll
local PlayerListFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScrollingFrame")
PlayerListFrame.Size = UDim2.new(1, -16, 1, -114)
PlayerListFrame.Position = UDim2.new(0, 8, 0, 72)
PlayerListFrame.BackgroundColor3 = COLORS.MEDIUM_BG
PlayerListFrame.BorderSizePixel = 0
PlayerListFrame.ScrollBarThickness = 3
PlayerListFrame.ScrollBarImageColor3 = COLORS.STROKE_BLUE
PlayerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerListFrame.Parent = MainFrame

local ListCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", PlayerListFrame)
ListCorner.CornerRadius = UDim.new(0, 5)

local ListLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 2)
ListLayout.SortOrder = Enum.SortOrder.Name
ListLayout.Parent = PlayerListFrame

-- Bottom Buttons Frame
local BottomFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
BottomFrame.Size = UDim2.new(1, -16, 0, 38)
BottomFrame.Position = UDim2.new(0, 8, 1, -46)
BottomFrame.BackgroundTransparency = 1
BottomFrame.Parent = MainFrame

local function createBottomButton(text, position, inactiveColor)
    local btn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    btn.Size = UDim2.new(0.31, 0, 1, 0)
    btn.Position = position
    btn.BackgroundColor3 = inactiveColor
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = COLORS.TEXT_WHITE
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.AutoButtonColor = false
    btn.Parent = BottomFrame
    
    local corner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 5)
    
    btn.MouseEnter:Connect(function()
        if __SIEXTHER_VIP_GLASS_V1.Read(btn, "BackgroundColor3") ~= COLORS.BUTTON_ACTIVE and __SIEXTHER_VIP_GLASS_V1.Read(btn, "BackgroundColor3") ~= COLORS.RED then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.BUTTON_HOVER}):Play()
        end
    end)
    
    btn.MouseLeave:Connect(function()
        if __SIEXTHER_VIP_GLASS_V1.Read(btn, "BackgroundColor3") ~= COLORS.BUTTON_ACTIVE and __SIEXTHER_VIP_GLASS_V1.Read(btn, "BackgroundColor3") ~= COLORS.RED then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = inactiveColor}):Play()
        end
    end)
    
    return btn
end

local BringBtn = createBottomButton("EXECUTE", UDim2.new(0, 0, 0, 0), COLORS.BUTTON_INACTIVE)
local CancelBtn = createBottomButton("STOP", UDim2.new(0.345, 0, 0, 0), COLORS.RED)
local RandomBtn = createBottomButton("RANDOM", UDim2.new(0.69, 0, 0, 0), COLORS.BUTTON_INACTIVE)

CancelBtn.Visible = false

-- ========== CAMERA SYSTEM ==========
local function lockCamera(target)
    if not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if not IsCameraLocked then
        OriginalCameraSubject = Cam.CameraSubject
    end
    
    IsCameraLocked = true
    CurrentTarget = target
    Cam.CameraSubject = hrp
    CancelBtn.Visible = true
end

local function unlockCamera()
    IsCameraLocked = false
    CurrentTarget = nil
    
    if OriginalCameraSubject then
        Cam.CameraSubject = OriginalCameraSubject
    else
        if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
            Cam.CameraSubject = LP.Character:FindFirstChildOfClass("Humanoid")
        end
    end
    
    CancelBtn.Visible = false
end

-- ========== PLAYER LIST CREATION ==========
local PlayerButtons = {}

local function createPlayerButton(player)
    if PlayerButtons[player] then return end
    
    local btn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 36)
    btn.BackgroundColor3 = COLORS.DARK_BG
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.Name = player.Name
    btn.Parent = PlayerListFrame
    
    local corner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 4)
    
    local avatar = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageLabel")
    avatar.Size = UDim2.new(0, 28, 0, 28)
    avatar.Position = UDim2.new(0, 4, 0.5, -14)
    avatar.BackgroundTransparency = 1
    avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=48&height=48&format=png"
    avatar.Parent = btn
    
    local avatarCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", avatar)
    avatarCorner.CornerRadius = UDim.new(0, 5)
    
    local displayName = player.DisplayName or player.Name
    local username = "@" .. player.Name
    local fullText = displayName .. " " .. username
    
    local nameLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -38, 1, 0)
    nameLabel.Position = UDim2.new(0, 36, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = fullText
    nameLabel.TextColor3 = COLORS.TEXT_WHITE
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextSize = 10
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = btn
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.MEDIUM_BG}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.DARK_BG}):Play()
    end)
    
    btn.MouseButton1Click:Connect(function()
        lockCamera(player)
    end)
    
    PlayerButtons[player] = btn
end

local function updatePlayerList(searchTerm)
    searchTerm = searchTerm or ""
    searchTerm = searchTerm:lower()
    
    for player, btn in pairs(PlayerButtons) do
        if not player or not player.Parent then
            btn:Destroy()
            PlayerButtons[player] = nil
        else
            local name = player.Name:lower()
            local displayName = (player.DisplayName or ""):lower()
            
            if searchTerm == "" or name:find(searchTerm) or displayName:find(searchTerm) then
                btn.Visible = true
            else
                btn.Visible = false
            end
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            if not PlayerButtons[player] then
                createPlayerButton(player)
            end
        end
    end
    
    ListLayout:ApplyLayout()
    PlayerListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 6)
end

-- ========== BUTTON FUNCTIONS ==========
BringBtn.MouseButton1Click:Connect(function()
    if not CurrentTarget then return end
    if IsRandomMode then return end
    
    SendPartActive = not SendPartActive
    
    if SendPartActive then
        BringBtn.Text = "STOP"
        BringBtn.BackgroundColor3 = COLORS.RED
        freezeCharacter()
        
        if not SendPartLoopThread then
            SendPartLoopThread = task.spawn(function()
                while SendPartActive do
                    if CurrentTarget and CurrentTarget.Character then
                        pcall(function()
                            sendUnanchoredPartsToTarget(CurrentTarget)
                        end)
                    end
                    task.wait(2.2)
                end
                SendPartLoopThread = nil
            end)
        end
    else
        BringBtn.Text = "EXECUTE"
        BringBtn.BackgroundColor3 = COLORS.BUTTON_INACTIVE
        unfreezeCharacter()
    end
end)

CancelBtn.MouseButton1Click:Connect(function()
    SendPartActive = false
    IsRandomMode = false
    BringBtn.Text = "EXECUTE"
    BringBtn.BackgroundColor3 = COLORS.BUTTON_INACTIVE
    RandomBtn.BackgroundColor3 = COLORS.BUTTON_INACTIVE
    unfreezeCharacter()
    unlockCamera()
end)

RandomBtn.MouseButton1Click:Connect(function()
    IsRandomMode = not IsRandomMode
    
    if IsRandomMode then
        TweenService:Create(RandomBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BUTTON_ACTIVE}):Play()
        
        local players = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                if rootPart then
                    local distance = (hrp.Position - rootPart.Position).Magnitude
                    table.insert(players, {player = player, distance = distance})
                end
            end
        end
        
        table.sort(players, function(a, b) return a.distance < b.distance end)
        
        if #players > 0 then
            local closestPlayer = players[1].player
            
            lockCamera(closestPlayer)
            
            SendPartActive = true
            freezeCharacter()
            
            pcall(function()
                sendUnanchoredPartsToTarget(closestPlayer)
            end)
            
            if not SendPartLoopThread then
                SendPartLoopThread = task.spawn(function()
                    while SendPartActive and IsRandomMode do
                        if CurrentTarget and CurrentTarget.Character then
                            pcall(function()
                                sendUnanchoredPartsToTarget(CurrentTarget)
                            end)
                        end
                        task.wait(2.2)
                    end
                    SendPartLoopThread = nil
                end)
            end
        else
            IsRandomMode = false
            task.wait(0.3)
            TweenService:Create(RandomBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BUTTON_INACTIVE}):Play()
        end
    else
        SendPartActive = false
        unfreezeCharacter()
        unlockCamera()
        TweenService:Create(RandomBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BUTTON_INACTIVE}):Play()
    end
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    FloatingButton.Visible = true
end)

FloatingButton.MouseButton1Click:Connect(function()
    FloatingButton.Visible = false
    MainFrame.Visible = true
end)

CloseBtn.MouseButton1Click:Connect(function()
    SendPartActive = false
    IsRandomMode = false
    unfreezeCharacter()
    unlockCamera()
    DisableNetworkStabilizer()
    pcall(function() ScreenGui:Destroy() end)
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    updatePlayerList(SearchBox.Text)
end)

Players.PlayerAdded:Connect(function(player)
    task.wait(0.5)
    updatePlayerList(SearchBox.Text)
end)

Players.PlayerRemoving:Connect(function(player)
    if PlayerButtons[player] then
        PlayerButtons[player]:Destroy()
        PlayerButtons[player] = nil
    end
    
    if CurrentTarget == player then
        unlockCamera()
        SendPartActive = false
        IsRandomMode = false
        BringBtn.Text = "EXECUTE"
        BringBtn.BackgroundColor3 = COLORS.BUTTON_INACTIVE
        RandomBtn.BackgroundColor3 = COLORS.BUTTON_INACTIVE
        unfreezeCharacter()
    end
    
    task.wait(0.5)
    updatePlayerList(SearchBox.Text)
end)

-- Initial Update
task.defer(function()
    updatePlayerList()
end)