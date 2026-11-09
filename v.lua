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
local Gui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
local Main = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
local UICorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
local MainStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
local TopBar = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
local UICorner_2 = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
local Label = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
local CloseButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
local UICorner_3 = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
local MinimizeButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
local UICorner_4 = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
local ContentFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
local UICorner_5 = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
local SearchBox = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextBox")
local UICorner_6 = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
local SearchIcon = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
local PlayerList = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScrollingFrame")
local UIListLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
local UIPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
local ButtonContainer = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
local UICorner_7 = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
local Button = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
local UICorner_8 = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
local ButtonGradient = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient")
local BringAllButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
local UICorner_9 = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
local ButtonGradient_2 = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient")
local MinimizedButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
local UICorner_10 = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
local TargetInfo = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
local UICorner_12 = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")

--Properties:
local controlledParts = {}
local descendantConnection = nil
local renderLoop = nil

-- PartOrbit Variables
local getpart = 300
local currentMode = 2
local radius = 50
local speed = 2
local isActive = true
local lastValidPosition = Vector3.new(0, 0, 0)
local UPDATE_INTERVAL = 0
local lastUpdate = tick()
local ringParts = {}

Gui.Name = "IlhanSiextherBring"
Gui.Parent = gethui()
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Main.Name = "Main"
Main.Parent = Gui
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BackgroundTransparency = 0.05
Main.BorderSizePixel = 0
Main.Position = UDim2.new(0.5, -130, 0.5, -180)
Main.Size = UDim2.new(0, 260, 0, 320)
Main.Active = true
Main.Draggable = true
Main.ZIndex = 1

UICorner.CornerRadius = UDim.new(0, 16)
UICorner.Parent = Main

MainStroke.Name = "MainStroke"
MainStroke.Parent = Main
MainStroke.Color = Color3.fromRGB(70, 130, 255)
MainStroke.Thickness = 2
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

TopBar.Name = "TopBar"
TopBar.Parent = Main
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
TopBar.BackgroundTransparency = 0
TopBar.BorderSizePixel = 0
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.ZIndex = 2

UICorner_2.CornerRadius = UDim.new(0, 16)
UICorner_2.Parent = TopBar

Label.Name = "Label"
Label.Parent = TopBar
Label.BackgroundTransparency = 1
Label.Position = UDim2.new(0.04, 0, 0, 0)
Label.Size = UDim2.new(0.65, 0, 1, 0)
Label.Font = Enum.Font.GothamBold
Label.Text = "SIEXTHER BRING"
Label.TextColor3 = Color3.fromRGB(70, 130, 255)
Label.TextScaled = true
Label.TextSize = 16
Label.TextWrapped = true
Label.TextXAlignment = Enum.TextXAlignment.Left
Label.ZIndex = 3

local LabelPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
LabelPadding.Parent = Label
LabelPadding.PaddingLeft = UDim.new(0, 15)

MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Parent = TopBar
MinimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Position = UDim2.new(1, -63, 0, 5)
MinimizeButton.Size = UDim2.new(0, 28, 0, 23)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Text = "–"
MinimizeButton.TextColor3 = Color3.fromRGB(70, 130, 255)
MinimizeButton.TextSize = 18
MinimizeButton.ZIndex = 3

UICorner_4.CornerRadius = UDim.new(0, 8)
UICorner_4.Parent = MinimizeButton

CloseButton.Name = "CloseButton"
CloseButton.Parent = TopBar
CloseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
CloseButton.BorderSizePixel = 0
CloseButton.Position = UDim2.new(1, -30, 0, 5)
CloseButton.Size = UDim2.new(0, 28, 0, 23)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 80, 90)
CloseButton.TextSize = 20
CloseButton.ZIndex = 3

UICorner_3.CornerRadius = UDim.new(0, 8)
UICorner_3.Parent = CloseButton

ContentFrame.Name = "ContentFrame"
ContentFrame.Parent = Main
ContentFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
ContentFrame.BackgroundTransparency = 0
ContentFrame.BorderSizePixel = 0
ContentFrame.Position = UDim2.new(0.05, 0, 0, 45)
ContentFrame.Size = UDim2.new(0.9, 0, 0, 265)
ContentFrame.ZIndex = 2

UICorner_5.CornerRadius = UDim.new(0, 12)
UICorner_5.Parent = ContentFrame

SearchBox.Name = "SearchBox"
SearchBox.Parent = ContentFrame
SearchBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
SearchBox.BackgroundTransparency = 0
SearchBox.BorderSizePixel = 0
SearchBox.Position = UDim2.new(0.05, 0, 0, 8)
SearchBox.Size = UDim2.new(0.9, 0, 0, 30)
SearchBox.Font = Enum.Font.Gotham
SearchBox.PlaceholderText = "Search players..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(200, 200, 220)
SearchBox.TextSize = 13
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ZIndex = 3

UICorner_6.CornerRadius = UDim.new(0, 10)
UICorner_6.Parent = SearchBox

local SearchPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
SearchPadding.Parent = SearchBox
SearchPadding.PaddingLeft = UDim.new(0, 12)
SearchPadding.PaddingRight = UDim.new(0, 12)

PlayerList.Name = "PlayerList"
PlayerList.Parent = ContentFrame
PlayerList.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
PlayerList.BackgroundTransparency = 0
PlayerList.BorderSizePixel = 0
PlayerList.Position = UDim2.new(0.05, 0, 0, 46)
PlayerList.Size = UDim2.new(0.9, 0, 0, 140)
PlayerList.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerList.ScrollBarThickness = 3
PlayerList.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
PlayerList.ZIndex = 3

UIListLayout.Parent = PlayerList
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

UIPadding.Parent = PlayerList
UIPadding.PaddingTop = UDim.new(0, 6)
UIPadding.PaddingLeft = UDim.new(0, 6)
UIPadding.PaddingRight = UDim.new(0, 6)

ButtonContainer.Name = "ButtonContainer"
ButtonContainer.Parent = ContentFrame
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Position = UDim2.new(0.05, 0, 0, 220)
ButtonContainer.Size = UDim2.new(0.9, 0, 0, 50)
ButtonContainer.ZIndex = 2

TargetInfo.Name = "TargetInfo"
TargetInfo.Parent = ContentFrame
TargetInfo.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TargetInfo.BackgroundTransparency = 0
TargetInfo.BorderSizePixel = 0
TargetInfo.Position = UDim2.new(0.05, 0, 0, 192)
TargetInfo.Size = UDim2.new(0.9, 0, 0, 22)
TargetInfo.Font = Enum.Font.GothamBold
TargetInfo.Text = "Target: None"
TargetInfo.TextColor3 = Color3.fromRGB(70, 130, 255)
TargetInfo.TextSize = 13
TargetInfo.TextWrapped = true
TargetInfo.ZIndex = 3
TargetInfo.Visible = false

UICorner_12.CornerRadius = UDim.new(0, 10)
UICorner_12.Parent = TargetInfo

Button.Name = "Button"
Button.Parent = ButtonContainer
Button.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
Button.BorderSizePixel = 0
Button.Position = UDim2.new(0, 0, 0, 0)
Button.Size = UDim2.new(1, 0, 0, 22)
Button.Font = Enum.Font.GothamBold
Button.Text = "BRING SINGLE | OFF"
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.TextSize = 14
Button.ZIndex = 3

UICorner_8.CornerRadius = UDim.new(0, 10)
UICorner_8.Parent = Button

BringAllButton.Name = "BringAllButton"
BringAllButton.Parent = ButtonContainer
BringAllButton.BackgroundColor3 = Color3.fromRGB(255, 80, 100)
BringAllButton.BorderSizePixel = 0
BringAllButton.Position = UDim2.new(0, 0, 0, 28)
BringAllButton.Size = UDim2.new(1, 0, 0, 22)
BringAllButton.Font = Enum.Font.GothamBold
BringAllButton.Text = "BRING RANDOM | OFF"
BringAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BringAllButton.TextSize = 14
BringAllButton.ZIndex = 3

UICorner_9.CornerRadius = UDim.new(0, 10)
UICorner_9.Parent = BringAllButton

MinimizedButton.Name = "MinimizedButton"
MinimizedButton.Parent = Gui
MinimizedButton.BorderSizePixel = 0
MinimizedButton.Size = UDim2.new(0, 41, 0, 41)
MinimizedButton.Position = UDim2.new(0, 15, 0, 60)
MinimizedButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MinimizedButton.Font = Enum.Font.GothamBold
MinimizedButton.Text = "☠️"
MinimizedButton.TextColor3 = Color3.fromRGB(70, 130, 255)
MinimizedButton.TextSize = 20
MinimizedButton.Visible = false
MinimizedButton.Draggable = true
MinimizedButton.ZIndex = 5

UICorner_10.CornerRadius = UDim.new(0, 12)
UICorner_10.Parent = MinimizedButton

local MinimizedStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
MinimizedStroke.Parent = MinimizedButton
MinimizedStroke.Color = Color3.fromRGB(70, 130, 255)
MinimizedStroke.Thickness = 2

-- Scripts:

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local character
local humanoidRootPart
local selectedPlayer = nil
local allPlayersTargets = {}

-- Hover effects
local function addHoverEffect(button, normalColor, hoverColor)
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = normalColor}):Play()
	end)
end

addHoverEffect(CloseButton, Color3.fromRGB(40, 40, 50), Color3.fromRGB(255, 80, 90))
addHoverEffect(MinimizeButton, Color3.fromRGB(40, 40, 50), Color3.fromRGB(70, 130, 255))

-- Toggle visibility
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if input.KeyCode == Enum.KeyCode.RightControl and not gameProcessedEvent then
		if Main.Visible then
			Main.Visible = false
			MinimizedButton.Visible = true
		else
			Main.Visible = true
			MinimizedButton.Visible = false
		end
	end
end)

local Folder = __SIEXTHER_VIP_GLASS_V1.Instance.new("Folder", Workspace)
local Part = __SIEXTHER_VIP_GLASS_V1.Instance.new("Part", Folder)
local Attachment1 = __SIEXTHER_VIP_GLASS_V1.Instance.new("Attachment", Part)
Part.Anchored = true
Part.CanCollide = false
Part.Transparency = 1

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

-- PartOrbit Functions
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
    
    if currentMode == 2 then
        offsetX = math.cos(angle) * radius
        offsetZ = math.sin(angle) * radius
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

local function initializePartOrbit()
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

-- Function to get nearest player
local function getNearestPlayer()
	if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
		return nil
	end
	
	local myPos = LocalPlayer.Character.HumanoidRootPart.Position
	local nearestPlayer = nil
	local shortestDistance = math.huge
	
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local distance = (player.Character.HumanoidRootPart.Position - myPos).Magnitude
			if distance < shortestDistance then
				shortestDistance = distance
				nearestPlayer = player
			end
		end
	end
	
	return nearestPlayer
end

local blackHoleActive = false
local bringAllActive = false
local DescendantAddedConnection

local function toggleBlackHole()
	blackHoleActive = not blackHoleActive
	if blackHoleActive then
		Button.Text = "BRING SELECTED | ON"
		Button.BackgroundColor3 = Color3.fromRGB(50, 255, 100)
		ButtonGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 255, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 200, 80))
		}
		
		for _, v in ipairs(Workspace:GetDescendants()) do
			ForcePart(v)
		end

		DescendantAddedConnection = Workspace.DescendantAdded:Connect(function(v)
			if blackHoleActive then
				ForcePart(v)
			end
		end)

		spawn(function()
			while blackHoleActive and RunService.RenderStepped:Wait() do
				if humanoidRootPart then
					Attachment1.WorldCFrame = humanoidRootPart.CFrame
				end
			end
		end)
	else
		Button.Text = "BRING SELECTED | OFF"
		Button.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
		ButtonGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 130, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 100, 200))
		}
		if DescendantAddedConnection then
			DescendantAddedConnection:Disconnect()
		end
	end
end

local bringAllConnection

local function toggleBringAll()
	bringAllActive = not bringAllActive
	if bringAllActive then
		BringAllButton.Text = "BRING RANDOM | ON"
		BringAllButton.BackgroundColor3 = Color3.fromRGB(50, 255, 100)
		ButtonGradient_2.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 255, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 200, 80))
		}
		
		for _, v in ipairs(Workspace:GetDescendants()) do
			ForcePart(v)
		end

		DescendantAddedConnection = Workspace.DescendantAdded:Connect(function(v)
			if bringAllActive then
				ForcePart(v)
			end
		end)

		bringAllConnection = RunService.RenderStepped:Connect(function()
			if bringAllActive then
				local nearestPlayer = getNearestPlayer()
				if nearestPlayer and nearestPlayer.Character and nearestPlayer.Character:FindFirstChild("HumanoidRootPart") then
					Attachment1.WorldCFrame = nearestPlayer.Character.HumanoidRootPart.CFrame
					TargetInfo.Text = "Targeting: " .. nearestPlayer.DisplayName .. " (@" .. nearestPlayer.Name .. ")"
					TargetInfo.Visible = true
				else
					TargetInfo.Text = "No nearby players"
					TargetInfo.Visible = true
				end
			end
		end)
	else
		BringAllButton.Text = "BRING RANDOM | OFF"
		BringAllButton.BackgroundColor3 = Color3.fromRGB(255, 80, 100)
		ButtonGradient_2.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 60, 80))
		}
		TargetInfo.Visible = false
		TargetInfo.Text = "Target: None"
		if DescendantAddedConnection then
			DescendantAddedConnection:Disconnect()
		end
		if bringAllConnection then
			bringAllConnection:Disconnect()
		end
	end
end

local function createPlayerButton(player)
	local playerButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
	playerButton.Name = player.Name
	playerButton.Parent = PlayerList
	playerButton.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
	playerButton.BackgroundTransparency = 0
	playerButton.BorderSizePixel = 0
	playerButton.Size = UDim2.new(1, -10, 0, 32)
	playerButton.Font = Enum.Font.Gotham
	playerButton.Text = player.DisplayName .. " (@" .. player.Name .. ")"
	playerButton.TextColor3 = Color3.fromRGB(180, 180, 200)
	playerButton.TextSize = 13
	playerButton.TextXAlignment = Enum.TextXAlignment.Left
	playerButton.TextTruncate = Enum.TextTruncate.AtEnd
	playerButton.ZIndex = 4
	
	local corner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = playerButton
	
	local padding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
	padding.Parent = playerButton
	padding.PaddingLeft = UDim.new(0, 12)
	
	playerButton.MouseEnter:Connect(function()
		if selectedPlayer ~= player then
			TweenService:Create(playerButton, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(45, 45, 60),
				BackgroundTransparency = 0
			}):Play()
		end
	end)
	
	playerButton.MouseLeave:Connect(function()
		if selectedPlayer ~= player then
			TweenService:Create(playerButton, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(30, 30, 42),
				BackgroundTransparency = 0
			}):Play()
		end
	end)
	
	playerButton.MouseButton1Click:Connect(function()
		selectedPlayer = player
		for _, btn in pairs(PlayerList:GetChildren()) do
			if btn:IsA("TextButton") then
				TweenService:Create(btn, TweenInfo.new(0.2), {
					BackgroundColor3 = Color3.fromRGB(30, 30, 42),
					BackgroundTransparency = 0,
					TextColor3 = Color3.fromRGB(180, 180, 200)
				}):Play()
			end
		end
		TweenService:Create(playerButton, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(70, 130, 255),
			BackgroundTransparency = 0,
			TextColor3 = Color3.fromRGB(255, 255, 255)
		}):Play()
		print("✅ Selected player:", player.DisplayName .. " (@" .. player.Name .. ")")
	end)
	
	return playerButton
end

local function updatePlayerList(searchText)
	for _, child in pairs(PlayerList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	local searchLower = string.lower(searchText or "")
	local count = 0
	
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local nameLower = string.lower(player.Name)
			local displayLower = string.lower(player.DisplayName)
			
			if searchText == "" or string.find(nameLower, searchLower) or string.find(displayLower, searchLower) then
				createPlayerButton(player)
				count = count + 1
			end
		end
	end
	
	PlayerList.CanvasSize = UDim2.new(0, 0, 0, count * 37)
end

updatePlayerList("")

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	updatePlayerList(SearchBox.Text)
end)

Players.PlayerAdded:Connect(function()
	wait(0.1)
	updatePlayerList(SearchBox.Text)
end)

Players.PlayerRemoving:Connect(function()
	wait(0.1)
	updatePlayerList(SearchBox.Text)
end)

Button.MouseButton1Click:Connect(function()
	if selectedPlayer then
		character = selectedPlayer.Character or selectedPlayer.CharacterAdded:Wait()
		humanoidRootPart = character:WaitForChild("HumanoidRootPart")
		toggleBlackHole()
	else
		local originalText = Button.Text
		Button.Text = "Select Player First!"
		wait(2)
		Button.Text = originalText
	end
end)

BringAllButton.MouseButton1Click:Connect(function()
	toggleBringAll()
end)

CloseButton.MouseButton1Click:Connect(function()
	
	Gui:Destroy()
end)

MinimizeButton.MouseButton1Click:Connect(function()
	Main.Visible = false
	MinimizedButton.Visible = true
end)

MinimizedButton.MouseButton1Click:Connect(function()
	Main.Visible = true
	MinimizedButton.Visible = false
end)

-- Initialize character and humanoidRootPart for PartOrbit
LocalPlayer.CharacterAdded:Connect(function(char)
	wait(1)
	humanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)

if LocalPlayer.Character then
	humanoidRootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
end

-- Initialize PartOrbit
spawn(function()
	wait(1)
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
		humanoidRootPart = LocalPlayer.Character.HumanoidRootPart
		initializePartOrbit()
	end
end)