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
local plrs = game:GetService("Players")
local as = game:GetService("AssetService")
local aes = game:GetService("AvatarEditorService")
local rs = game:GetService("RunService")
local hs = game:GetService("HttpService")
local cp = game:GetService("ContentProvider")
local ts = game:GetService("TweenService")
local lp = plrs.LocalPlayer

local m = {
	["runanimation"]      = "run",
	["climbanimation"]    = "climb",
	["jumpanimation"]     = "jump",
	["fallanimation"]     = "fall",
	["idleanimation"]     = "idle",
	["swimidleanimation"] = "swimidle",
	["swimanimation"]     = "swim",
	["walkanimation"]     = "walk"
}

local shortNames = {
	["idleanimation"]     = "Idle",
	["walkanimation"]     = "Walk",
	["runanimation"]      = "Run",
	["jumpanimation"]     = "Jump",
	["fallanimation"]     = "Fall",
	["climbanimation"]    = "Climb",
	["swimidleanimation"] = "S.Idle",
	["swimanimation"]     = "Swim"
}

local buttonOrder = {
	"idleanimation",
	"walkanimation",
	"runanimation",
	"jumpanimation",
	"fallanimation",
	"climbanimation",
	"swimidleanimation",
	"swimanimation"
}

local CACHE_FILE_NAME = "SiextherAnimtedV2_cache.json"
local ANIM_CACHE_URL = "https://raw.githubusercontent.com/TribalFootball/TuffTeto/main/animation_bundle_data_cache.json"
local SEEN_BUNDLES_FILE = "SiextherAnimtedV2_seen.json"
local EQUIPPED_FILE = "SiextherAnimtedV2.json"
local SAVED_BUNDLES_FILE = "HannSiextherAnimtedV2.json"

local assetCache, fileCache, seenBundles, equippedAnims = {}, {}, {}, {}
local savedBookmarks = {}

local function loadJSON(file)
	local ok, content = pcall(function()
		if isfile and not isfile(file) then return nil end
		return readfile(file)
	end)
	if ok and content then
		local suc, decoded = pcall(function() return hs:JSONDecode(content) end)
		return suc and decoded or {}
	end
	return {}
end

local function saveJSON(file, data)
	pcall(function() writefile(file, hs:JSONEncode(data)) end)
end

fileCache = loadJSON(CACHE_FILE_NAME)
seenBundles = loadJSON(SEEN_BUNDLES_FILE)
equippedAnims = loadJSON(EQUIPPED_FILE)
savedBookmarks = loadJSON(SAVED_BUNDLES_FILE)

task.spawn(function()
	local ok, onlineContent = pcall(function() return game:HttpGet(ANIM_CACHE_URL) end)
	if ok and onlineContent then
		pcall(function()
			local onlineData = hs:JSONDecode(onlineContent)
			for k, v in pairs(onlineData) do if not fileCache[k] then fileCache[k] = v end end
			saveJSON(CACHE_FILE_NAME, fileCache)
		end)
	end
end)

local function applySavedAnimations(char)
	if not char then return end
	local animate = char:WaitForChild("Animate", 5)
	local human = char:WaitForChild("Humanoid", 5)
	if not animate or not human then return end
	
	for _, tr in ipairs(human:GetPlayingAnimationTracks()) do 
		pcall(function() tr:AdjustWeight(0,0); tr:Stop(0) end) 
	end
	
	animate.Disabled = true
	
	for slotType, animList in pairs(equippedAnims) do
		local fId = m[string.lower(slotType)]
		if fId then
			local folder = animate:FindFirstChild(fId)
			if folder then
				for _, o in ipairs(folder:GetChildren()) do 
					if o:IsA("Animation") then o:Destroy() end 
				end
				for _, animData in ipairs(animList) do
					local newAnim = __SIEXTHER_VIP_GLASS_V1.Instance.new("Animation", folder)
					newAnim.Name = animData.Name
					newAnim.AnimationId = animData.AnimationId
				end
			end
		end
	end
	
	task.wait(0.05)
	animate.Disabled = false
end

local function initAutoEquip(char)
	if not char then return end
	task.spawn(function()
		local animate = char:WaitForChild("Animate", 5)
		local human = char:WaitForChild("Humanoid", 5)
		
		if animate and human then
			local idleFolder = animate:WaitForChild("idle", 5)
			if idleFolder then
				idleFolder:WaitForChild("Animation1", 3) 
			end
			
			task.wait(0.1)
			applySavedAnimations(char)
		end
	end)
end

if lp.Character then
	initAutoEquip(lp.Character)
end

lp.CharacterAdded:Connect(initAutoEquip)

local function get(id, bundleId, assetType)
	local stringId = tostring(id)
	if assetCache[stringId] then return assetCache[stringId] end
	if fileCache[stringId] then
		local reconstructed = {}
		for _, data in ipairs(fileCache[stringId]) do
			local anim = __SIEXTHER_VIP_GLASS_V1.Instance.new("Animation")
			anim.Name, anim.AnimationId = data.Name, data.AnimationId
			table.insert(reconstructed, anim)
		end
		assetCache[stringId] = reconstructed
		return reconstructed
	end

	local t, serializableData = {}, {}
	local descProp = "IdleAnimation"
	local lowerType = assetType and string.lower(assetType) or ""

	if lowerType:find("idle") and not lowerType:find("swim") then descProp = "IdleAnimation"
	elseif lowerType:find("walk") then descProp = "WalkAnimation"
	elseif lowerType:find("run") then descProp = "RunAnimation"
	elseif lowerType:find("jump") then descProp = "JumpAnimation"
	elseif lowerType:find("fall") then descProp = "FallAnimation"
	elseif lowerType:find("climb") then descProp = "ClimbAnimation"
	elseif lowerType:find("swim") then descProp = "SwimAnimation"
	end

	pcall(function()
		local desc = __SIEXTHER_VIP_GLASS_V1.Instance.new("HumanoidDescription")
		desc[descProp] = tonumber(id)
		local dummy = plrs:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
		local animate = dummy:FindFirstChild("Animate")
		if animate then
			local targetFolders = (descProp == "SwimAnimation") and {"swim", "swimidle"} or {string.lower(string.gsub(descProp, "Animation", ""))}
			for _, folderName in ipairs(targetFolders) do
				local folder = animate:FindFirstChild(folderName)
				if folder then
					for _, child in ipairs(folder:GetChildren()) do
						if child:IsA("Animation") and child.AnimationId ~= "" then
							local clone = child:Clone()
							table.insert(t, clone)
							table.insert(serializableData, { Name = clone.Name, AnimationId = clone.AnimationId, BundleId = tostring(bundleId) })
						end
					end
				end
			end
		end
		dummy:Destroy()
	end)

	if #t == 0 then
		pcall(function() 
			local objs = game:GetObjects("rbxassetid://" .. stringId) 
			if objs and #objs > 0 then
				local function processItem(item)
					if item:IsA("Animation") then
						table.insert(t, item:Clone())
						table.insert(serializableData, { Name = item.Name, AnimationId = item.AnimationId, BundleId = tostring(bundleId) })
					end
				end
				processItem(objs[1])
				for _, c in ipairs(objs[1]:GetDescendants()) do processItem(c) end
			end
		end)
	end

	assetCache[stringId] = t
	fileCache[stringId] = serializableData
	saveJSON(CACHE_FILE_NAME, fileCache)
	return t
end

local function clearAssetCache(id)
	local stringId = tostring(id)
	assetCache[stringId], fileCache[stringId] = nil, nil
	saveJSON(CACHE_FILE_NAME, fileCache)
end

local vp = workspace.CurrentCamera.ViewportSize
local scale = math.clamp(math.min(vp.X / 1920, vp.Y / 1080), 0.55, 3.0) * 1.45
local function s(n) return math.round(n * scale) end

-- ===== MODERN DARK THEME (blue accent) =====
local C = {
	bg = Color3.fromRGB(25, 25, 35), panel = Color3.fromRGB(32, 32, 44),
	surface = Color3.fromRGB(40, 40, 54), surfaceHi = Color3.fromRGB(54, 54, 72),
	accent = Color3.fromRGB(70, 130, 255), green = Color3.fromRGB(70, 130, 255),
	purple = Color3.fromRGB(70, 130, 255), text = Color3.fromRGB(255, 255, 255),
	textDim = Color3.fromRGB(255, 255, 255), textMuted = Color3.fromRGB(255, 255, 255),
	overlay = Color3.fromRGB(16, 16, 24), fav = Color3.fromRGB(255, 255, 255),
	danger = Color3.fromRGB(70, 130, 255)
}

local PAD_TOP = s(26) 
local PAD_SIDES = s(12)
local W, H = s(510), s(350) 
local INNER_W = W - (PAD_SIDES * 2)
local LEFT_W = s(260)
local RIGHT_W = INNER_W - LEFT_W - s(1)

local scrollW = s(4)
local FOOT_H = s(28)
local VP_H = s(140)
local MIN_BTN_SIZE = s(60)
local UI_BUSY = false
local TOGGLE_COOLDOWN = 0.15

local function stroke(parent, color, thickness)
	local st = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke", parent)
	st.Color = color or C.accent
	st.Thickness = thickness or 1
	st.Transparency = 0.15
	return st
end

local function corner(parent, radius)
	local cr = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", parent)
	cr.CornerRadius = UDim.new(0, radius or s(6))
	return cr
end

local function applyCoolGradient(parent)
	local grad = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient", parent)
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 55, 85)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 30, 42)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))
	})
	grad.Rotation = 45
end

local function applyShimmer(obj, colorStart, colorMid)
	if obj:FindFirstChild("ShimmerGrad") then return end
	local grad = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGradient", obj)
	grad.Name = "ShimmerGrad"
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colorStart),
		ColorSequenceKeypoint.new(0.5, colorMid),
		ColorSequenceKeypoint.new(1, colorStart)
	})
	grad.Rotation = 35
	grad.Offset = Vector2.new(-1, 0)
	
	local tw = ts:Create(grad, TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Offset = Vector2.new(1, 0)})
	tw:Play()
end

local function removeShimmer(obj)
	local g = obj:FindFirstChild("ShimmerGrad")
	if g then g:Destroy() end
end

local gp = (typeof(gethui) == "function" and gethui()) or game:GetService("CoreGui")
if gp:FindFirstChild("StudioAnimStudio") then gp.StudioAnimStudio:Destroy() end

local g = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui", gp)
g.Name = "SiextherAnimated"
g.ResetOnSpawn = false
if not g.Parent then g.Parent = lp:WaitForChild("PlayerGui") end

local mf = __SIEXTHER_VIP_GLASS_V1.Instance.new("CanvasGroup", g)
mf.Size, mf.Position, mf.AnchorPoint = UDim2.new(0, 0, 0, 0), UDim2.new(0.5, 0, 0.5, 0), Vector2.new(0.5, 0.5)
mf.BackgroundColor3, mf.BackgroundTransparency = C.bg, 0.05
mf.GroupTransparency = 1 
mf.Active, mf.Draggable = true, true
corner(mf, s(10)); applyCoolGradient(mf); stroke(mf, C.accent, 1.5)

local mfPad = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding", mf)
mfPad.PaddingTop = UDim.new(0, PAD_TOP)
mfPad.PaddingBottom = UDim.new(0, PAD_SIDES)
mfPad.PaddingLeft = UDim.new(0, PAD_SIDES)
mfPad.PaddingRight = UDim.new(0, PAD_SIDES)

task.delay(0.1, function()
	ts:Create(mf, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, W, 0, H), GroupTransparency = 0}):Play()
end)

local minBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("CanvasGroup", g)
minBtn.Size, minBtn.Position, minBtn.AnchorPoint = UDim2.new(0, 0, 0, 0), UDim2.new(1, -s(40), 0, s(30)), Vector2.new(0.5, 0.5)
minBtn.BackgroundTransparency = 1
minBtn.GroupTransparency = 1
minBtn.Visible = false
minBtn.Active, minBtn.Draggable, minBtn.ClipsDescendants = true, true, true

local minBtnBg = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame", minBtn)
minBtnBg.Size, minBtnBg.BackgroundColor3, minBtnBg.BorderSizePixel = UDim2.new(1, 0, 1, 0), C.panel, 0
local minBtnCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", minBtnBg)
minBtnCorner.CornerRadius = UDim.new(0.5, 0)


local minBtnLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel", minBtn)
minBtnLabel.Size, minBtnLabel.BackgroundTransparency = UDim2.new(1, 0, 1, 0), 1
minBtnLabel.Text, minBtnLabel.TextColor3, minBtnLabel.Font, minBtnLabel.TextSize = "✨", C.text, Enum.Font.GothamBlack, s(20)
minBtnLabel.ClipsDescendants = true

local minBtnHit = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton", minBtn)
minBtnHit.Size, minBtnHit.BackgroundTransparency, minBtnHit.Text, minBtnHit.ClipsDescendants = UDim2.new(1, 0, 1, 0), 1, "", true

minBtnHit.MouseButton1Click:Connect(function()
	if UI_BUSY then return end
	UI_BUSY = true

	minBtn.Visible = false
	minBtn.GroupTransparency = 1
	minBtn.Size = UDim2.new(0, 0, 0, 0)

	mf.Size = UDim2.new(0, W, 0, H)
	mf.GroupTransparency = 0
	mf.Visible = true

	task.wait(TOGGLE_COOLDOWN)
	UI_BUSY = false
end)

local lp_frame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame", mf)
lp_frame.Size, lp_frame.Position, lp_frame.BackgroundTransparency = UDim2.new(0, LEFT_W, 1, 0), UDim2.new(0, 0, 0, 0), 1

local titleLbl = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel", lp_frame)
titleLbl.Size, titleLbl.Position, titleLbl.BackgroundTransparency = UDim2.new(1, 0, 0, s(22)), UDim2.new(0, s(4), 0, 0), 1
titleLbl.Text, titleLbl.TextColor3, titleLbl.Font, titleLbl.TextSize = "SIEXTHER ANIMATED", C.text, Enum.Font.GothamBlack, s(15)
titleLbl.TextXAlignment, titleLbl.ClipsDescendants = Enum.TextXAlignment.Left, true

local header = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame", lp_frame)
header.Size, header.Position, header.BackgroundTransparency = UDim2.new(1, -s(8), 0, s(26)), UDim2.new(0, s(4), 0, s(28)), 1

local tabDiscoverBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton", header)
tabDiscoverBtn.Size, tabDiscoverBtn.Position = UDim2.new(0.48, 0, 1, 0), UDim2.new(0, 0, 0, 0)
tabDiscoverBtn.Text, tabDiscoverBtn.Font, tabDiscoverBtn.TextSize = "Discover", Enum.Font.GothamBold, s(12)
tabDiscoverBtn.BackgroundColor3, tabDiscoverBtn.TextColor3, tabDiscoverBtn.ClipsDescendants = C.accent, C.text, true
corner(tabDiscoverBtn, s(4))

local tabSavedBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton", header)
tabSavedBtn.Size, tabSavedBtn.Position = UDim2.new(0.48, 0, 1, 0), UDim2.new(0.52, 0, 0, 0)
tabSavedBtn.Text, tabSavedBtn.Font, tabSavedBtn.TextSize = "Saved", Enum.Font.GothamBold, s(12)
tabSavedBtn.BackgroundColor3, tabSavedBtn.TextColor3, tabSavedBtn.ClipsDescendants = C.accent, C.text, true
corner(tabSavedBtn, s(4))

local minWindowBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton", mf)
minWindowBtn.Size, minWindowBtn.Position, minWindowBtn.AnchorPoint = UDim2.new(0, s(30), 0, s(30)), UDim2.new(1, PAD_SIDES - s(4) - s(34), 0, -PAD_TOP + s(4)), Vector2.new(1, 0)
minWindowBtn.BackgroundColor3, minWindowBtn.BackgroundTransparency = C.accent, 0.35
minWindowBtn.Text, minWindowBtn.TextColor3, minWindowBtn.Font, minWindowBtn.TextSize, minWindowBtn.ClipsDescendants = "–", C.text, Enum.Font.GothamBold, s(20), true
corner(minWindowBtn, s(5))

local closeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton", mf)
closeBtn.Size, closeBtn.Position, closeBtn.AnchorPoint = UDim2.new(0, s(30), 0, s(30)), UDim2.new(1, PAD_SIDES - s(4), 0, -PAD_TOP + s(4)), Vector2.new(1, 0)
closeBtn.BackgroundColor3, closeBtn.BackgroundTransparency = C.accent, 0.35
closeBtn.Text, closeBtn.TextColor3, closeBtn.Font, closeBtn.TextSize, closeBtn.ClipsDescendants = "x", C.text, Enum.Font.GothamBlack, s(20), true
corner(closeBtn, s(5))

closeBtn.MouseEnter:Connect(function() closeBtn.BackgroundColor3 = C.accent; closeBtn.TextColor3 = C.text end)
closeBtn.MouseLeave:Connect(function() closeBtn.BackgroundColor3 = C.accent; closeBtn.TextColor3 = C.text end)
minWindowBtn.MouseEnter:Connect(function() minWindowBtn.BackgroundColor3 = C.accent; minWindowBtn.TextColor3 = C.text end)
minWindowBtn.MouseLeave:Connect(function() minWindowBtn.BackgroundColor3 = C.accent; minWindowBtn.TextColor3 = C.text end)

closeBtn.MouseButton1Click:Connect(function()
	if UI_BUSY then return end
	UI_BUSY = true
	local tw = ts:Create(mf, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0), GroupTransparency = 1})
	tw:Play()
	tw.Completed:Wait()
	g:Destroy()
end)

minWindowBtn.MouseButton1Click:Connect(function() 
	if UI_BUSY then return end
	UI_BUSY = true

	mf.Visible = false
	mf.GroupTransparency = 1
	mf.Size = UDim2.new(0, 0, 0, 0)

	minBtn.Size = UDim2.new(0, MIN_BTN_SIZE, 0, MIN_BTN_SIZE)
	minBtn.GroupTransparency = 0
	minBtn.Visible = true

	task.wait(TOGGLE_COOLDOWN)
	UI_BUSY = false
end)

local searchRow = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame", lp_frame)
searchRow.Size, searchRow.Position, searchRow.BackgroundTransparency = UDim2.new(1, -s(8), 0, s(26)), UDim2.new(0, s(4), 0, s(60)), 1

local sb = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextBox", searchRow)
sb.Size, sb.PlaceholderText, sb.Text = UDim2.new(1, -s(58), 1, 0), "Search...", ""
sb.BackgroundColor3, sb.BackgroundTransparency, sb.TextColor3, sb.ClipsDescendants = C.surface, 0.2, C.text, true
sb.Font, sb.TextSize = Enum.Font.Gotham, s(11)
corner(sb, s(4)); stroke(sb, C.surfaceHi, 1)
local sbPad = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding", sb) sbPad.PaddingLeft = UDim.new(0, s(8))

local searchBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton", searchRow)
searchBtn.Size, searchBtn.Position = UDim2.new(0, s(52), 1, 0), UDim2.new(1, -s(52), 0, 0)
searchBtn.Text, searchBtn.BackgroundColor3, searchBtn.TextColor3, searchBtn.ClipsDescendants = "Search", C.accent, C.text, true
searchBtn.Font, searchBtn.TextSize = Enum.Font.GothamBold, s(11)
corner(searchBtn, s(4))

local gridScroller = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScrollingFrame", lp_frame)
gridScroller.Size, gridScroller.Position = UDim2.new(1, -s(8), 1, -s(126)), UDim2.new(0, s(4), 0, s(92))
gridScroller.BackgroundColor3, gridScroller.BackgroundTransparency, gridScroller.BorderSizePixel = C.surface, 0.55, 0
gridScroller.ScrollBarThickness = scrollW
gridScroller.ScrollBarImageColor3 = C.accent
corner(gridScroller, s(6))
stroke(gridScroller, C.surfaceHi, 1)

local loadingOverlay = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel", lp_frame)
loadingOverlay.Size, loadingOverlay.Position = gridScroller.Size, gridScroller.Position
loadingOverlay.BackgroundColor3, loadingOverlay.BackgroundTransparency, loadingOverlay.ZIndex = C.bg, 0.15, 10
loadingOverlay.Text, loadingOverlay.TextColor3, loadingOverlay.Font, loadingOverlay.ClipsDescendants = "Loading...", C.text, Enum.Font.GothamBold, true
loadingOverlay.Visible = false; corner(loadingOverlay, s(6))
applyShimmer(loadingOverlay, C.surface, C.surfaceHi)

local footer = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame", lp_frame)
footer.Size, footer.Position, footer.BackgroundTransparency = UDim2.new(1, -s(8), 0, FOOT_H), UDim2.new(0, s(4), 1, -FOOT_H), 1

local prevBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton", footer)
prevBtn.Size, prevBtn.Text, prevBtn.BackgroundColor3, prevBtn.ClipsDescendants = UDim2.new(0, s(52), 1, 0), "← Back", C.accent, true
prevBtn.Font, prevBtn.TextSize, prevBtn.TextColor3 = Enum.Font.GothamBold, s(10), C.text
corner(prevBtn, s(4))

local pageLbl = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel", footer)
pageLbl.Size, pageLbl.Position, pageLbl.Text, pageLbl.ClipsDescendants = UDim2.new(1, -s(114), 1, 0), UDim2.new(0, s(57), 0, 0), "Page 1", true
pageLbl.BackgroundTransparency, pageLbl.TextColor3, pageLbl.Font = 1, C.text, Enum.Font.Gotham

local nextBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton", footer)
nextBtn.Size, nextBtn.Position, nextBtn.Text, nextBtn.ClipsDescendants = UDim2.new(0, s(52), 1, 0), UDim2.new(1, -s(52), 0, 0), "Next →", true
nextBtn.BackgroundColor3, nextBtn.Font, nextBtn.TextSize = C.accent, Enum.Font.GothamBold, s(10)
nextBtn.TextColor3 = C.text
corner(nextBtn, s(4))

local divider = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame", mf)
divider.Size, divider.Position, divider.BackgroundColor3 = UDim2.new(0, 1, 1, 0), UDim2.new(0, LEFT_W, 0, 0), C.accent
divider.BackgroundTransparency = 0.6
divider.BorderSizePixel = 0

local rp = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame", mf)
rp.Size, rp.Position, rp.BackgroundTransparency = UDim2.new(0, RIGHT_W, 1, 0), UDim2.new(0, LEFT_W + s(1), 0, 0), 1

local masterViewport = __SIEXTHER_VIP_GLASS_V1.Instance.new("ViewportFrame", rp)
masterViewport.Size, masterViewport.Position = UDim2.new(1, -s(16), 0, VP_H), UDim2.new(0, s(8), 0, 0)
masterViewport.BackgroundColor3, masterViewport.BackgroundTransparency = C.overlay, 0.1
corner(masterViewport, s(6)); stroke(masterViewport, C.accent, 1)

local statusFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame", rp)
statusFrame.Size, statusFrame.Position = UDim2.new(1, -s(16), 0, s(28)), UDim2.new(0, s(8), 0, VP_H + s(8))
statusFrame.BackgroundColor3, statusFrame.BackgroundTransparency = C.surface, 0.4
corner(statusFrame, s(4))

local statusLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel", statusFrame)
statusLabel.Size, statusLabel.Position, statusLabel.BackgroundTransparency = UDim2.new(1, -s(12), 1, 0), UDim2.new(0, s(6), 0, 0), 1
statusLabel.Text, statusLabel.TextColor3, statusLabel.ClipsDescendants = "No bundle selected", C.text, true
statusLabel.Font, statusLabel.TextSize, statusLabel.TextXAlignment = Enum.Font.GothamSemibold, s(10), Enum.TextXAlignment.Left

local buttonContainer = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame", rp)
buttonContainer.Size, buttonContainer.Position = UDim2.new(1, -s(16), 0, s(50)), UDim2.new(0, s(8), 0, VP_H + s(44))
buttonContainer.BackgroundTransparency = 1
local gridBtnLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIGridLayout", buttonContainer)
local btnW = math.floor((RIGHT_W - s(16) - s(12)) / 4)
gridBtnLayout.CellSize, gridBtnLayout.CellPadding = UDim2.new(0, btnW, 0, s(22)), UDim2.new(0, s(4), 0, s(4))

local actRow = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame", rp)
actRow.Size, actRow.Position, actRow.BackgroundTransparency = UDim2.new(1, -s(16), 0, s(60)), UDim2.new(0, s(8), 1, -s(60)), 1

local bookmarkBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton", actRow)
bookmarkBtn.Size, bookmarkBtn.Position = UDim2.new(1, 0, 0, s(28)), UDim2.new(0, 0, 0, 0)
bookmarkBtn.BackgroundColor3, bookmarkBtn.Text = C.accent, "Save to Saved Tab"
bookmarkBtn.Font, bookmarkBtn.TextSize, bookmarkBtn.TextColor3 = Enum.Font.GothamBold, s(11), C.text
bookmarkBtn.Visible, bookmarkBtn.ClipsDescendants = false, true
corner(bookmarkBtn, s(4))

local wearSelectedBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton", actRow)
wearSelectedBtn.Size, wearSelectedBtn.Position, wearSelectedBtn.Text = UDim2.new(0.48, 0, 0, s(28)), UDim2.new(0, 0, 1, -s(28)), "Wear Selected"
wearSelectedBtn.BackgroundColor3, wearSelectedBtn.TextColor3, wearSelectedBtn.ClipsDescendants = C.accent, C.text, true
wearSelectedBtn.Font, wearSelectedBtn.TextSize, wearSelectedBtn.Visible = Enum.Font.GothamBold, s(10), false
corner(wearSelectedBtn, s(4))

local wearAllBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton", actRow)
wearAllBtn.Size, wearAllBtn.Position, wearAllBtn.Text = UDim2.new(0.48, 0, 0, s(28)), UDim2.new(0.52, 0, 1, -s(28)), "Wear All"
wearAllBtn.BackgroundColor3, wearAllBtn.TextColor3, wearAllBtn.ClipsDescendants = C.accent, C.text, true
wearAllBtn.Font, wearAllBtn.TextSize, wearAllBtn.Visible = Enum.Font.GothamBold, s(10), false
corner(wearAllBtn, s(4))

local activeGridThreads, currentBundleItems, animationButtons = {}, {}, {}
local targetBundleItems, activeMasterTrack, activeMasterType = nil, nil, nil
local activeBundleName, activeBundleId = "None", nil
local searchResults, savedTabList = {}, {}
local catalogCursor, currentPageIndex, itemsPerPage = nil, 1, 5 
local currentTab = "Discover"
local userSelectedAnimSlot = "idleanimation"

local function preloadAnimations(tracks)
	local i = {}
	for _, t in ipairs(tracks) do table.insert(i, t) end
	if #i > 0 then pcall(function() cp:PreloadAsync(i) end) end
end

local function buildViewportSkeleton(vpFrame)
	local wm = vpFrame:FindFirstChildOfClass("WorldModel")
	if not wm then wm = __SIEXTHER_VIP_GLASS_V1.Instance.new("WorldModel", vpFrame) else for _,c in ipairs(wm:GetChildren()) do c:Destroy() end end
	local char = lp.Character or lp.CharacterAdded:Wait()
	char.Archivable = true
	local clone = char:Clone(); clone.Parent = wm
	local root, human = clone:WaitForChild("HumanoidRootPart"), clone:FindFirstChildOfClass("Humanoid")
	local anim = human:FindFirstChildOfClass("Animator") or __SIEXTHER_VIP_GLASS_V1.Instance.new("Animator", human)
	if clone:FindFirstChild("Animate") then clone.Animate.Disabled = true end
	local cam = vpFrame:FindFirstChildOfClass("Camera") or __SIEXTHER_VIP_GLASS_V1.Instance.new("Camera", vpFrame)
	vpFrame.CurrentCamera = cam
	cam.CFrame = CFrame.new(Vector3.new(0, 1.5, 6), Vector3.new(0, 0, 0))
	local angle = 0
	local conn = rs.RenderStepped:Connect(function(dt)
		if clone and root then angle = angle + math.rad(25*dt); clone:PivotTo(CFrame.new(0,0,0) * CFrame.Angles(0, angle, 0)) end
	end)
	return clone, anim, conn
end

local function applyAnimationToCharacter(character, targetAnimations, slotType)
	local animate = character:WaitForChild("Animate", 5)
	local human = character:FindFirstChildOfClass("Humanoid")
	if not animate or not human then return end
	for _, tr in ipairs(human:GetPlayingAnimationTracks()) do pcall(function() tr:AdjustWeight(0,0); tr:Stop(0) end) end
	animate.Disabled = true
	local cleanSlot = string.lower(slotType or "")
	local fId = m[cleanSlot]
	if fId then
		local folder = animate:FindFirstChild(fId)
		if folder then
			for _, o in ipairs(folder:GetChildren()) do if o:IsA("Animation") then o:Destroy() end end
			equippedAnims[cleanSlot] = {}
			for _, animAsset in ipairs(targetAnimations) do
				local newAnim = __SIEXTHER_VIP_GLASS_V1.Instance.new("Animation", folder)
				newAnim.Name, newAnim.AnimationId = animAsset.Name, animAsset.AnimationId
				table.insert(equippedAnims[cleanSlot], {Name=newAnim.Name, AnimationId=newAnim.AnimationId})
			end
			saveJSON(EQUIPPED_FILE, equippedAnims)
		end
	end
	task.wait(0.05); animate.Disabled = false
end

local function getSpecificTrack(fetchedTracks, targetType)
	if #fetchedTracks == 0 then return nil end
	if targetType == "swimidleanimation" then
		for _, tr in ipairs(fetchedTracks) do if string.lower(tr.Name):find("idle") then return tr end end
		return fetchedTracks[2] or fetchedTracks[1]
	elseif targetType == "swimanimation" then
		for _, tr in ipairs(fetchedTracks) do if string.lower(tr.Name) == "swim" then return tr end end
	end
	return fetchedTracks[1]
end

local function truncate(str, maxLen) return #str > maxLen and str:sub(1, maxLen-1).."…" or str end

local function tryPlayTrack(animator, track, looped)
	local ok, pt = pcall(function() local tr = animator:LoadAnimation(track); tr.Looped=looped; tr:Play(); return tr end)
	if not ok or not pt then return false, nil end
	task.wait(0.15)
	if not pt.IsPlaying then pcall(function() pt:Stop() end); return false, nil end
	return true, pt
end

local function applyBundleItemsToCharacter(items)
	if not lp.Character then return end
	local tLoad, tApply = {}, {}
	for _, lt in ipairs(buttonOrder) do
		local pay = items[lt]
		if pay then
			local t = get(pay.Id, nil, pay.AssetType)
			if lt == "idleanimation" then
				tApply[lt] = t; for _,x in ipairs(t) do table.insert(tLoad, x) end
			else
				local spec = getSpecificTrack(t, lt)
				if spec then tApply[lt] = {spec}; table.insert(tLoad, spec) end
			end
		end
	end
	preloadAnimations(tLoad)
	for slot, tracks in pairs(tApply) do applyAnimationToCharacter(lp.Character, tracks, slot) end
end

local function wearBundleQuickly(bundleId, onDone)
	task.spawn(function()
		local ok, res = pcall(function() return as:GetBundleDetailsAsync(bundleId) end)
		if ok and res and res.Items and lp.Character then
			local items = {}
			for _, item in ipairs(res.Items) do
				local lt = string.lower(item.AssetType or "")
				if lt == "swimanimation" then
					items["swimanimation"] = item; items["swimidleanimation"] = item
				elseif shortNames[lt] then
					items[lt] = item
				end
			end
			applyBundleItemsToCharacter(items)
		end
		if onDone then onDone() end
	end)
end

local function toggleBookmark(bundleId, bundleName)
	local sId = tostring(bundleId)
	local nowSaved
	if savedBookmarks[sId] then
		savedBookmarks[sId] = nil
		nowSaved = false
	else
		savedBookmarks[sId] = {Id = bundleId, Name = bundleName, Fav = false, Time = tick()}
		nowSaved = true
	end
	saveJSON(SAVED_BUNDLES_FILE, savedBookmarks)
	return nowSaved
end

local masterRenderGen = 0 
local function renderMasterTrack(itemPayload, assetTypeName)
	if activeMasterTrack then activeMasterTrack:Stop() activeMasterTrack = nil end
	masterRenderGen = masterRenderGen + 1
	local myGen = masterRenderGen
	local dummy, animator = buildViewportSkeleton(masterViewport)
	local lowerType = string.lower(assetTypeName or "")
	local displayType = shortNames[lowerType] or "Track"

	statusLabel.Text = truncate(activeBundleName, 22) .. " • " .. displayType .. " (loading...)"
	applyShimmer(statusLabel, C.textDim, Color3.new(1,1,1))
	
	local vpShimmer = masterViewport:FindFirstChild("LoadingShimmer")
	if not vpShimmer then
		vpShimmer = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame", masterViewport)
		vpShimmer.Name = "LoadingShimmer"
		vpShimmer.Size, vpShimmer.BackgroundColor3, vpShimmer.BorderSizePixel = UDim2.new(1,0,1,0), C.overlay, 0
		corner(vpShimmer, s(6))
		applyShimmer(vpShimmer, C.overlay, C.surfaceHi)
	end
	
	task.spawn(function()
		local attempt, fetchedTracks, trackToPlay = 0, nil, nil
		while myGen == masterRenderGen do
			fetchedTracks = get(itemPayload.Id, nil, itemPayload.AssetType)
			trackToPlay = (#fetchedTracks>0) and getSpecificTrack(fetchedTracks, lowerType) or nil
			if trackToPlay then break end
			attempt = attempt + 1
			statusLabel.Text = truncate(activeBundleName, 22) .. " • " .. displayType .. " (reloading..." .. attempt .. ")"
			clearAssetCache(itemPayload.Id)
			task.wait(math.min(0.5 + attempt * 0.3, 3))
		end
		
		if myGen ~= masterRenderGen then return end
		
		if trackToPlay then
			removeShimmer(statusLabel)
			if masterViewport:FindFirstChild("LoadingShimmer") then masterViewport.LoadingShimmer:Destroy() end
		end

		activeMasterType = assetTypeName
		statusLabel.Text = truncate(activeBundleName, 22) .. " • " .. displayType
		local isIdle = (lowerType == "idleanimation")
		if isIdle and fetchedTracks and #fetchedTracks > 1 then
			local pointer = 1
			while myGen == masterRenderGen and dummy and dummy.Parent do
				if activeMasterTrack then activeMasterTrack:Stop() end
				local ok, playedTrack = tryPlayTrack(animator, fetchedTracks[pointer], false)
				while not ok and myGen == masterRenderGen do
					clearAssetCache(itemPayload.Id)
					fetchedTracks = get(itemPayload.Id, nil, itemPayload.AssetType)
					pointer = pointer > #fetchedTracks and 1 or pointer
					task.wait(0.4); ok, playedTrack = tryPlayTrack(animator, fetchedTracks[pointer], false)
				end
				if myGen ~= masterRenderGen then return end
				activeMasterTrack = playedTrack; activeMasterTrack.Stopped:Wait()
				pointer = (pointer % #fetchedTracks) + 1
			end
		elseif trackToPlay then
			local ok, playedTrack = tryPlayTrack(animator, trackToPlay, true)
			while not ok and myGen == masterRenderGen do
				clearAssetCache(itemPayload.Id)
				task.wait(0.4)
				local reloaded = get(itemPayload.Id, nil, itemPayload.AssetType)
				trackToPlay = (#reloaded>0) and getSpecificTrack(reloaded, lowerType) or nil
				if trackToPlay then ok, playedTrack = tryPlayTrack(animator, trackToPlay, true) end
			end
			if myGen ~= masterRenderGen then return end
			activeMasterTrack = playedTrack
		end
	end)
end

for _, lowerType in ipairs(buttonOrder) do
	local btn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton", buttonContainer)
	btn.BackgroundColor3, btn.BackgroundTransparency, btn.TextColor3 = C.accent, 0.25, C.text
	btn.Text, btn.Font, btn.TextSize, btn.ClipsDescendants = shortNames[lowerType], Enum.Font.GothamBold, s(10), true
	corner(btn, s(4))
	
	btn.MouseButton1Click:Connect(function()
		userSelectedAnimSlot = lowerType
		local payload = currentBundleItems[lowerType]
		if payload then
			wearSelectedBtn.Visible = true
			renderMasterTrack(payload, lowerType)
			for slot, b in pairs(animationButtons) do
				b.BackgroundColor3 = C.accent
				b.TextColor3 = C.text
			end
		end
	end)
	animationButtons[lowerType] = btn
end

local function refreshBookmarkBtn()
	if not activeBundleId then bookmarkBtn.Visible = false return end
	bookmarkBtn.Visible = true
	if savedBookmarks[tostring(activeBundleId)] then
		bookmarkBtn.Text, bookmarkBtn.TextColor3 = "Saved to Saved Tab", C.text
	else
		bookmarkBtn.Text, bookmarkBtn.TextColor3 = "Save to Saved Tab", C.text
	end
end

bookmarkBtn.MouseButton1Click:Connect(function()
	toggleBookmark(activeBundleId, activeBundleName)
	refreshBookmarkBtn()
	if currentTab == "Saved" then searchBtn.MouseButton1Click:Fire() end
end)

local function inspectBundleDetails(bundleId, bundleName)
	table.clear(currentBundleItems)
	wearSelectedBtn.Visible, wearAllBtn.Visible = false, false
	activeBundleName, activeBundleId = bundleName or "Unknown", bundleId
	statusLabel.Text = truncate(activeBundleName, 22) .. " • Loading..."
	applyShimmer(statusLabel, C.textDim, Color3.new(1,1,1))
	refreshBookmarkBtn()
	for _, btn in pairs(animationButtons) do btn.BackgroundColor3, btn.TextColor3 = C.accent, C.text end

	task.spawn(function()
		local ok, res = pcall(function() return as:GetBundleDetailsAsync(bundleId) end)
		if not ok or not res or not res.Items then 
			statusLabel.Text = truncate(activeBundleName, 22) .. " • Error" 
			removeShimmer(statusLabel)
			return 
		end
		targetBundleItems = res.Items
		wearAllBtn.Visible = true

		for _, item in ipairs(res.Items) do
			local lt = string.lower(item.AssetType or "")
			if lt == "swimanimation" then
				currentBundleItems["swimanimation"] = item; currentBundleItems["swimidleanimation"] = item
			elseif shortNames[lt] then
				currentBundleItems[lt] = item
			end
		end
		
		local slotToPlay = currentBundleItems[userSelectedAnimSlot] and userSelectedAnimSlot or "idleanimation"
		
		for slot, b in pairs(animationButtons) do
			if currentBundleItems[slot] then b.BackgroundColor3, b.TextColor3 = C.accent, C.text end
		end
		
		if currentBundleItems[slotToPlay] then
			animationButtons[slotToPlay].BackgroundColor3 = C.accent
			wearSelectedBtn.Visible = true
			renderMasterTrack(currentBundleItems[slotToPlay], slotToPlay)
		else
			statusLabel.Text = truncate(activeBundleName, 22) .. " • Missing Anim"
			removeShimmer(statusLabel)
		end
	end)
end

local function clearActiveGridContext()
	for _, t in ipairs(activeGridThreads) do task.cancel(t) end
	activeGridThreads = {}
	for _, c in ipairs(gridScroller:GetChildren()) do if c:IsA("ViewportFrame") then c:Destroy() end end
end

local function drawGridPage(dataList)
	clearActiveGridContext()
	loadingOverlay.Visible = false
	local start = (currentPageIndex - 1) * itemsPerPage + 1
	local ending = math.min(currentPageIndex * itemsPerPage, #dataList)
	
	local usableWidth = LEFT_W - s(8) - scrollW 
	local boxHeight = s(96)
	local actionRowH = s(16)
	local nameRowH = s(14)
	
	local idx = 1
	for i = start, ending do
		local bundle = dataList[i]
		if not bundle then break end

		local box = __SIEXTHER_VIP_GLASS_V1.Instance.new("ViewportFrame", gridScroller)
		box.BackgroundColor3, box.BackgroundTransparency = C.panel, 0.15
		corner(box, s(8)); stroke(box, C.surfaceHi, 1)

		local boxWidth, posX, posY = 0, 0, 0
		
		if idx <= 2 then
			boxWidth = math.floor((usableWidth - s(24)) / 2)
			posX = s(8) + (idx - 1) * (boxWidth + s(8))
			posY = s(8)
		else
			boxWidth = math.floor((usableWidth - s(32)) / 3)
			local col = idx - 3
			posX = s(8) + col * (boxWidth + s(8))
			posY = s(8) + boxHeight + s(8)
		end
		
		box.AnchorPoint = Vector2.new(0.5, 0.5)
		box.Position = UDim2.new(0, posX + boxWidth/2, 0, posY + boxHeight/2)
		box.Size = UDim2.new(0, 0, 0, 0)
		
		ts:Create(box, TweenInfo.new(0.3 + (idx * 0.05), Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, boxWidth, 0, boxHeight)}):Play()

		local skeleton = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame", box)
		skeleton.Size, skeleton.BackgroundColor3, skeleton.BorderSizePixel, skeleton.ZIndex = UDim2.new(1,0,1,0), C.panel, 0, 2
		corner(skeleton, s(8))
		applyShimmer(skeleton, C.panel, C.surfaceHi)

		local label = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel", box)
		label.Size, label.Position, label.BackgroundColor3, label.BackgroundTransparency = UDim2.new(1, 0, 0, nameRowH), UDim2.new(0, 0, 1, -(nameRowH + actionRowH)), C.overlay, 0.25
		label.Text, label.TextColor3, label.Font, label.TextSize, label.ZIndex, label.ClipsDescendants = truncate(bundle.Name, 9), C.text, Enum.Font.GothamBold, s(8), 3, true
		
		local hitBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton", box)
		hitBtn.Size, hitBtn.Position, hitBtn.BackgroundTransparency, hitBtn.Text, hitBtn.ZIndex, hitBtn.ClipsDescendants = UDim2.new(1, 0, 1, -actionRowH), UDim2.new(0,0,0,0), 1, "", 4, true
		hitBtn.MouseEnter:Connect(function() box.BackgroundColor3 = C.surfaceHi end)
		hitBtn.MouseLeave:Connect(function() box.BackgroundColor3 = C.panel end)
		hitBtn.MouseButton1Click:Connect(function() inspectBundleDetails(bundle.Id, bundle.Name) end)
		
		if currentTab == "Saved" then
			local favBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton", box)
			favBtn.Size, favBtn.Position, favBtn.BackgroundTransparency = UDim2.new(0, s(20), 0, s(20)), UDim2.new(1, -s(22), 0, s(2)), 1
			favBtn.Text, favBtn.Font, favBtn.TextSize, favBtn.ZIndex, favBtn.ClipsDescendants = (bundle.Fav and "★" or "☆"), Enum.Font.GothamBold, s(14), 5, true
			favBtn.TextColor3 = C.text
			
			favBtn.MouseButton1Click:Connect(function()
				local sId = tostring(bundle.Id)
				if savedBookmarks[sId] then
					savedBookmarks[sId].Fav = not savedBookmarks[sId].Fav
					saveJSON(SAVED_BUNDLES_FILE, savedBookmarks)
					
					bundle.Fav = savedBookmarks[sId].Fav
					favBtn.Text = bundle.Fav and "★" or "☆"
					favBtn.TextColor3 = C.text
				end
			end)
		end

		local cardActions = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame", box)
		cardActions.Size, cardActions.Position, cardActions.BackgroundTransparency = UDim2.new(1, 0, 0, actionRowH), UDim2.new(0, 0, 1, -actionRowH), 1
		cardActions.ZIndex = 6

		local alreadySaved = savedBookmarks[tostring(bundle.Id)] ~= nil

		local saveCardBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton", cardActions)
		saveCardBtn.Size, saveCardBtn.Position = UDim2.new(0.5, -s(1), 1, 0), UDim2.new(0, 0, 0, 0)
		saveCardBtn.BackgroundColor3, saveCardBtn.BackgroundTransparency = C.accent, 0.05
		saveCardBtn.Text = alreadySaved and "✓ Saved" or "+ Save"
		saveCardBtn.TextColor3 = C.text
		saveCardBtn.Font, saveCardBtn.TextSize, saveCardBtn.ZIndex, saveCardBtn.ClipsDescendants = Enum.Font.GothamBold, s(7), 6, true
		corner(saveCardBtn, s(3))

		local wearCardBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton", cardActions)
		wearCardBtn.Size, wearCardBtn.Position = UDim2.new(0.5, -s(1), 1, 0), UDim2.new(0.5, s(2), 0, 0)
		wearCardBtn.BackgroundColor3, wearCardBtn.BackgroundTransparency = C.accent, 0.05
		wearCardBtn.Text, wearCardBtn.TextColor3 = "▶ Wear", C.text
		wearCardBtn.Font, wearCardBtn.TextSize, wearCardBtn.ZIndex, wearCardBtn.ClipsDescendants = Enum.Font.GothamBold, s(7), 6, true
		corner(wearCardBtn, s(3))

		saveCardBtn.MouseButton1Click:Connect(function()
			local nowSaved = toggleBookmark(bundle.Id, bundle.Name)
			saveCardBtn.Text = nowSaved and "✓ Saved" or "+ Save"
			saveCardBtn.TextColor3 = C.text
			if activeBundleId == bundle.Id then refreshBookmarkBtn() end
			if currentTab == "Saved" and not nowSaved then
				searchBtn.MouseButton1Click:Fire()
			end
		end)

		wearCardBtn.MouseButton1Click:Connect(function()
			wearCardBtn.Text = "…"
			wearBundleQuickly(bundle.Id, function()
				if wearCardBtn and wearCardBtn.Parent then wearCardBtn.Text = "▶ Wear" end
			end)
		end)

		local dummy, animator, conn = buildViewportSkeleton(box)
		local loopThread = task.spawn(function()
			local ok, details = pcall(function() return as:GetBundleDetailsAsync(bundle.Id) end)
			if not ok or not details or not details.Items then return end
			local usableTracks = {}
			for _, subItem in ipairs(details.Items) do if m[string.lower(subItem.AssetType or "")] then table.insert(usableTracks, subItem) end end
			if #usableTracks == 0 then return end
			local tIdx, cellTrack = 1, nil
			while box and box.Parent do
				local subItem = usableTracks[tIdx]
				local assets = get(subItem.Id, bundle.Id, subItem.AssetType)
				if #assets > 0 then
					if cellTrack then cellTrack:Stop() end
					cellTrack = animator:LoadAnimation(assets[1]); cellTrack.Looped = true
					if skeleton.Parent then skeleton:Destroy() end
					cellTrack:Play()
				end
				task.wait(3.0); tIdx = (tIdx % #usableTracks) + 1
			end
		end)
		table.insert(activeGridThreads, loopThread)
		box.Destroying:Connect(function() task.cancel(loopThread); conn:Disconnect() end)
		
		idx = idx + 1
	end
	
	gridScroller.CanvasSize = UDim2.new(0, 0, 0, s(220))
	pageLbl.Text = "Page " .. tostring(currentPageIndex)
	prevBtn.BackgroundTransparency, prevBtn.TextColor3 = (currentPageIndex > 1) and 0.25 or 0.6, C.text
end

local function executeSearch(query)
	currentPageIndex = 1
	loadingOverlay.Visible, pageLbl.Text = true, "Loading..."
	
	if currentTab == "Saved" then
		savedTabList = {}
		local q = string.lower(query or "")
		for _, v in pairs(savedBookmarks) do
			if q == "" or string.lower(v.Name):find(q) then table.insert(savedTabList, v) end
		end
		table.sort(savedTabList, function(a, b)
			if a.Fav == b.Fav then return (a.Time or 0) > (b.Time or 0) end
			return a.Fav and not b.Fav
		end)
		drawGridPage(savedTabList)
	else
		searchResults, catalogCursor = {}, nil
		local p = CatalogSearchParams.new()
		p.SearchKeyword, p.BundleTypes, p.IncludeOffSale, p.Limit = query or "", {Enum.BundleType.Animations}, true, 120
		pcall(function() p.CreatorType = Enum.CreatorType.User end)
		pcall(function() p.SalesTypeFilter = Enum.SalesTypeFilter.All end)
		pcall(function() p.SortType = Enum.CatalogSortType.RecentlyCreated end)
		task.spawn(function()
			local ok, pages = pcall(function() return aes:SearchCatalog(p) end)
			if ok and pages then
				catalogCursor = pages
				searchResults = pages:GetCurrentPage()
				drawGridPage(searchResults)
			else
				pageLbl.Text, loadingOverlay.Text = "Error", "Search Error"
			end
		end)
	end
end

tabDiscoverBtn.MouseButton1Click:Connect(function()
	if currentTab == "Discover" then return end
	currentTab = "Discover"
	tabDiscoverBtn.BackgroundColor3, tabDiscoverBtn.TextColor3 = C.accent, C.text
	tabSavedBtn.BackgroundColor3, tabSavedBtn.TextColor3 = C.accent, C.text
	executeSearch(sb.Text)
end)

tabSavedBtn.MouseButton1Click:Connect(function()
	if currentTab == "Saved" then return end
	currentTab = "Saved"
	tabSavedBtn.BackgroundColor3, tabSavedBtn.TextColor3 = C.accent, C.text
	tabDiscoverBtn.BackgroundColor3, tabDiscoverBtn.TextColor3 = C.accent, C.text
	executeSearch(sb.Text)
end)

nextBtn.MouseButton1Click:Connect(function()
	local activeList = (currentTab == "Saved") and savedTabList or searchResults
	if (currentPageIndex * itemsPerPage < #activeList) then
		currentPageIndex = currentPageIndex + 1
		loadingOverlay.Visible = true; drawGridPage(activeList)
	elseif currentTab == "Discover" and catalogCursor and not catalogCursor.IsFinished then
		loadingOverlay.Visible, pageLbl.Text = true, "Loading..."
		task.spawn(function()
			local ok = pcall(function() catalogCursor:AdvanceToNextPageAsync() end)
			if ok then
				local nc = catalogCursor:GetCurrentPage()
				for _, v in ipairs(nc) do table.insert(searchResults, v) end
				currentPageIndex = currentPageIndex + 1; drawGridPage(searchResults)
			end
		end)
	end
end)

prevBtn.MouseButton1Click:Connect(function()
	if currentPageIndex > 1 then
		currentPageIndex = currentPageIndex - 1
		loadingOverlay.Visible = true; drawGridPage((currentTab == "Saved") and savedTabList or searchResults)
	end
end)

wearSelectedBtn.MouseButton1Click:Connect(function()
	if not activeMasterType or not lp.Character then return end
	wearSelectedBtn.Text = "Loading..."
	applyShimmer(wearSelectedBtn, C.green, Color3.new(1,1,1))
	local payload = currentBundleItems[string.lower(activeMasterType)]
	if payload then
		local tracks = get(payload.Id, nil, payload.AssetType)
		local tPlay = getSpecificTrack(tracks, string.lower(activeMasterType))
		if tPlay then preloadAnimations({tPlay}); applyAnimationToCharacter(lp.Character, {tPlay}, activeMasterType) end
	end
	wearSelectedBtn.Text = "Wear Selected"
	removeShimmer(wearSelectedBtn)
end)

wearAllBtn.MouseButton1Click:Connect(function()
	if not lp.Character then return end
	wearAllBtn.Text = "Loading..."
	applyShimmer(wearAllBtn, C.purple, Color3.new(1,1,1))
	applyBundleItemsToCharacter(currentBundleItems)
	wearAllBtn.Text = "Wear All"
	removeShimmer(wearAllBtn)
end)

searchBtn.MouseButton1Click:Connect(function() executeSearch(sb.Text) end)
sb.FocusLost:Connect(function(enterPressed) if enterPressed then executeSearch(sb.Text) end end)

executeSearch("")
