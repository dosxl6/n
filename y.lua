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
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local Folder = __SIEXTHER_VIP_GLASS_V1.Instance.new("Folder", Workspace)
local Part = __SIEXTHER_VIP_GLASS_V1.Instance.new("Part", Folder)
local Attachment1 = __SIEXTHER_VIP_GLASS_V1.Instance.new("Attachment", Part)
Part.Anchored = true
Part.CanCollide = false
Part.Transparency = 1

-- Network setup from second script (orbit script)
local getpart = 300
local currentMode = 2
local orbitRadius = 50
local orbitSpeed = 2
local isActive = true
local lastValidPosition = Vector3.new(0, 0, 0)
local UPDATE_INTERVAL = 0
local lastUpdate = tick()
local ringParts = {}

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
    local angle = (index / totalParts) * (2 * math.pi) + tick() * orbitSpeed
    local offsetX, offsetY, offsetZ = 0, 0, 0
    
    if currentMode == 2 then
        offsetX = math.cos(angle) * orbitRadius
        offsetZ = math.sin(angle) * orbitRadius
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



-- COMPACT MODERN DARK GUI WITH BLUE STROKE (SMALLER)
local ScreenGui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
ScreenGui.Name = "SuperRingPartsGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame (Even smaller size)
local MainFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 180, 0, 130)
MainFrame.Position = UDim2.new(0.5, -90, 0.5, -65)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BackgroundTransparency = 0
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Blue Stroke
local UIStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(70, 130, 255)
UIStroke.Thickness = 2
UIStroke.Parent = MainFrame

-- Title bar
local Title = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
Title.Size = UDim2.new(0.6, 0, 0, 32)
Title.Position = UDim2.new(0, 8, 0, 0)
Title.Text = "SIEXTHER RING"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BorderSizePixel = 0
Title.Parent = MainFrame

-- Close button (X)
local CloseButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 22, 0, 22)
CloseButton.Position = UDim2.new(1, -27, 0, 5)
CloseButton.Text = "X"
CloseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
CloseButton.BackgroundTransparency = 0
CloseButton.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 12
CloseButton.BorderSizePixel = 0
CloseButton.Parent = MainFrame

local CloseCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(1, 0)
CloseCorner.Parent = CloseButton

-- Minimize button (-)
local MinimizeButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 22, 0, 22)
MinimizeButton.Position = UDim2.new(1, -54, 0, 5)
MinimizeButton.Text = "–"
MinimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
MinimizeButton.BackgroundTransparency = 0
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 14
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Parent = MainFrame

local MinimizeCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(1, 0)
MinimizeCorner.Parent = MinimizeButton

-- Floating Button (top right corner)
local FloatingButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
FloatingButton.Size = UDim2.new(0, 38, 0, 38)
FloatingButton.Position = UDim2.new(1, -55, 0, 15)
FloatingButton.Text = "💫"
FloatingButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
FloatingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingButton.Font = Enum.Font.GothamBold
FloatingButton.TextSize = 18
FloatingButton.BorderSizePixel = 0
FloatingButton.Visible = false
FloatingButton.Parent = ScreenGui
FloatingButton.ZIndex = 5

local FloatingCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
FloatingCorner.CornerRadius = UDim.new(0, 10)
FloatingCorner.Parent = FloatingButton

-- Toggle button
local ToggleButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0.85, 0, 0, 30)
ToggleButton.Position = UDim2.new(0.075, 0, 0.29, 0)
ToggleButton.Text = "RING | OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(238, 0, 0)
ToggleButton.BackgroundTransparency = 0
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 12
ToggleButton.BorderSizePixel = 0
ToggleButton.Parent = MainFrame

local ToggleCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleButton

-- Radius Controls
local DecreaseRadius = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
DecreaseRadius.Size = UDim2.new(0.22, 0, 0, 30)
DecreaseRadius.Position = UDim2.new(0.075, 0, 0.65, 0)
DecreaseRadius.Text = "<"
DecreaseRadius.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
DecreaseRadius.BackgroundTransparency = 0
DecreaseRadius.TextColor3 = Color3.fromRGB(70, 130, 255)
DecreaseRadius.Font = Enum.Font.GothamBold
DecreaseRadius.TextSize = 16
DecreaseRadius.BorderSizePixel = 0
DecreaseRadius.Parent = MainFrame

local DecreaseCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
DecreaseCorner.CornerRadius = UDim.new(0, 8)
DecreaseCorner.Parent = DecreaseRadius

local IncreaseRadius = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
IncreaseRadius.Size = UDim2.new(0.22, 0, 0, 30)
IncreaseRadius.Position = UDim2.new(0.705, 0, 0.65, 0)
IncreaseRadius.Text = ">"
IncreaseRadius.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
IncreaseRadius.BackgroundTransparency = 0
IncreaseRadius.TextColor3 = Color3.fromRGB(70, 130, 255)
IncreaseRadius.Font = Enum.Font.GothamBold
IncreaseRadius.TextSize = 16
IncreaseRadius.BorderSizePixel = 0
IncreaseRadius.Parent = MainFrame

local IncreaseCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
IncreaseCorner.CornerRadius = UDim.new(0, 8)
IncreaseCorner.Parent = IncreaseRadius

local RadiusDisplay = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
RadiusDisplay.Size = UDim2.new(0.42, 0, 0, 30)
RadiusDisplay.Position = UDim2.new(0.29, 0, 0.65, 0)
RadiusDisplay.Text = "Radius: 8"
RadiusDisplay.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
RadiusDisplay.BackgroundTransparency = 0
RadiusDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
RadiusDisplay.Font = Enum.Font.GothamBold
RadiusDisplay.TextSize = 11
RadiusDisplay.BorderSizePixel = 0
RadiusDisplay.Parent = MainFrame

local RadiusCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
RadiusCorner.CornerRadius = UDim.new(0, 8)
RadiusCorner.Parent = RadiusDisplay

-- Close button functionality
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    ringPartsEnabled = false
    parts = {}
    isActive = false
    
end)

-- Minimize Functionality
local minimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame.Visible = false
        FloatingButton.Visible = true
    else
        MainFrame.Visible = true
        FloatingButton.Visible = false
    end
end)

-- Floating button restore
FloatingButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    FloatingButton.Visible = false
    minimized = false
end)

-- Draggable GUI (MainFrame)
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
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
        update(input)
    end
end)

-- Draggable Floating Button
local floatingDragging, floatingDragInput, floatingDragStart, floatingStartPos
local function updateFloating(input)
    local delta = input.Position - floatingDragStart
    FloatingButton.Position = UDim2.new(floatingStartPos.X.Scale, floatingStartPos.X.Offset + delta.X, floatingStartPos.Y.Scale, floatingStartPos.Y.Offset + delta.Y)
end
FloatingButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        floatingDragging = true
        floatingDragStart = input.Position
        floatingStartPos = FloatingButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                floatingDragging = false
            end
        end)
    end
end)
FloatingButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        floatingDragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == floatingDragInput and floatingDragging then
        updateFloating(input)
    end
end)

-- Ring Parts Logic
local radius = 8
local height = 100
local rotationSpeed = 1
local attractionStrength = 1000
local ringPartsEnabled = false

local function RetainPart(Part)
    if Part:IsA("BasePart") and not Part.Anchored and Part:IsDescendantOf(workspace) then
        if Part.Parent == LocalPlayer.Character or Part:IsDescendantOf(LocalPlayer.Character) then
            return false
        end

        Part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        Part.CanCollide = false
        return true
    end
    return false
end

local parts = {}
local function addPart(part)
    if RetainPart(part) then
        if not table.find(parts, part) then
            table.insert(parts, part)
        end
    end
end

local function removePart(part)
    local index = table.find(parts, part)
    if index then
        table.remove(parts, index)
    end
end

for _, part in pairs(workspace:GetDescendants()) do
    addPart(part)
end

workspace.DescendantAdded:Connect(addPart)
workspace.DescendantRemoving:Connect(removePart)

RunService.Heartbeat:Connect(function()
    if not ringPartsEnabled then return end
    
    local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local tornadoCenter = humanoidRootPart.Position
        for _, part in pairs(parts) do
            if part.Parent and not part.Anchored then
                local pos = part.Position
                local distance = (Vector3.new(pos.X, tornadoCenter.Y, pos.Z) - tornadoCenter).Magnitude
                local angle = math.atan2(pos.Z - tornadoCenter.Z, pos.X - tornadoCenter.X)
                local newAngle = angle + math.rad(rotationSpeed)
                local targetPos = Vector3.new(
                    tornadoCenter.X + math.cos(newAngle) * math.min(radius, distance),
                    tornadoCenter.Y + (height * (math.abs(math.sin((pos.Y - tornadoCenter.Y) / height)))),
                    tornadoCenter.Z + math.sin(newAngle) * math.min(radius, distance)
                )
                local directionToTarget = (targetPos - part.Position).unit
                part.Velocity = directionToTarget * attractionStrength
            end
        end
    end
end)

-- Button functionality
ToggleButton.MouseButton1Click:Connect(function()
    ringPartsEnabled = not ringPartsEnabled
    ToggleButton.Text = ringPartsEnabled and "RING | ON" or "RING | OFF"
    ToggleButton.BackgroundColor3 = ringPartsEnabled and Color3.fromRGB(70, 130, 255)or Color3.fromRGB(238, 0, 0)
end)

DecreaseRadius.MouseButton1Click:Connect(function()
    radius = math.max(1, radius - 2)
    RadiusDisplay.Text = "Radius: " .. radius
end)

IncreaseRadius.MouseButton1Click:Connect(function()
    radius = math.min(1000, radius + 2)
    RadiusDisplay.Text = "Radius: " .. radius
end)

-- Update humanoidRootPart on character respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    wait(1)
    humanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)
