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
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local Players          = game:GetService("Players")
local LP               = Players.LocalPlayer


local BG     = Color3.fromRGB(25, 25, 35)
local DARK   = Color3.fromRGB(18, 18, 28)
local ACCENT = Color3.fromRGB(70, 130, 255)
local BTN    = Color3.fromRGB(35, 35, 52)
local BTN_ON = Color3.fromRGB(26, 45, 85)
local TEXT   = Color3.fromRGB(210, 215, 255)
local MUTED  = Color3.fromRGB(110, 115, 165)

-- ── Lighting helpers ─────────────────────────
local origLight = {
    Ambient    = Lighting.Ambient,
    Brightness = Lighting.Brightness,
    ClockTime  = Lighting.ClockTime,
    FogColor   = Lighting.FogColor,
    FogEnd     = Lighting.FogEnd,
}

local function getEff(cls, name)
    local e = Lighting:FindFirstChild(name)
    if e then return e end
    e = __SIEXTHER_VIP_GLASS_V1.Instance.new(cls)
    e.Name = name
    e.Parent = Lighting
    return e
end

local function remEff(list)
    for _, n in pairs(list) do
        local e = Lighting:FindFirstChild(n)
        if e then e:Destroy() end
    end
end

-- ── Shader definitions ───────────────────────
local SHADERS = {
    {
        name  = "RTX SHADER",
        color = Color3.fromRGB(100, 180, 255),
        on = function()
            local b = getEff("BloomEffect","SX_B1")
            b.Intensity = 1.5; b.Size = 24; b.Threshold = 0.85
            local c = getEff("ColorCorrectionEffect","SX_C1")
            c.Brightness = 0.05; c.Contrast = 0.2; c.Saturation = 0.3
            c.TintColor = Color3.fromRGB(240,248,255)
            local s = getEff("SunRaysEffect","SX_S1")
            s.Intensity = 0.25; s.Spread = 0.5
            Lighting.Ambient = Color3.fromRGB(80,90,120)
            Lighting.Brightness = 3
        end,
        off = function() remEff({"SX_B1","SX_C1","SX_S1"}) end,
    },
    {
        name  = "SHADER FULL MAX FPS",
        color = Color3.fromRGB(80, 255, 150),
        on = function()
            local c = getEff("ColorCorrectionEffect","SX_C2")
            c.Brightness = 0.08; c.Contrast = 0.15; c.Saturation = -0.1
            c.TintColor = Color3.fromRGB(255,255,255)
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.fromRGB(120,120,120)
        end,
        off = function() remEff({"SX_C2"}) end,
    },
    {
        name  = "REALISTIC SHADER",
        color = Color3.fromRGB(255, 200, 100),
        on = function()
            local b = getEff("BloomEffect","SX_B3")
            b.Intensity = 0.8; b.Size = 16; b.Threshold = 0.9
            local c = getEff("ColorCorrectionEffect","SX_C3")
            c.Brightness = 0.02; c.Contrast = 0.25; c.Saturation = 0.4
            c.TintColor = Color3.fromRGB(255,248,235)
            local s = getEff("SunRaysEffect","SX_S3")
            s.Intensity = 0.2; s.Spread = 0.4
            Lighting.Ambient = Color3.fromRGB(90,85,75)
            Lighting.Brightness = 2.5; Lighting.ClockTime = 14
        end,
        off = function() remEff({"SX_B3","SX_C3","SX_S3"}) end,
    },
    {
        name  = "ULTRA GRAPHICS SHADER",
        color = Color3.fromRGB(200, 100, 255),
        on = function()
            local b = getEff("BloomEffect","SX_B4")
            b.Intensity = 2.5; b.Size = 28; b.Threshold = 0.75
            local c = getEff("ColorCorrectionEffect","SX_C4")
            c.Brightness = 0.1; c.Contrast = 0.35; c.Saturation = 0.5
            c.TintColor = Color3.fromRGB(235,245,255)
            local s = getEff("SunRaysEffect","SX_S4")
            s.Intensity = 0.35; s.Spread = 0.7
            local d = getEff("DepthOfFieldEffect","SX_D4")
            d.FocusDistance = 50; d.InFocusRadius = 30
            d.NearIntensity = 0.05; d.FarIntensity = 0.3
            Lighting.Ambient = Color3.fromRGB(60,65,90); Lighting.Brightness = 3.5
        end,
        off = function() remEff({"SX_B4","SX_C4","SX_S4","SX_D4"}) end,
    },
    {
        name  = "CINEMATIC SHADER",
        color = Color3.fromRGB(255, 140, 100),
        on = function()
            local b = getEff("BloomEffect","SX_B5")
            b.Intensity = 1.2; b.Size = 20; b.Threshold = 0.88
            local c = getEff("ColorCorrectionEffect","SX_C5")
            c.Brightness = -0.05; c.Contrast = 0.4; c.Saturation = 0.2
            c.TintColor = Color3.fromRGB(255,235,210)
            local d = getEff("DepthOfFieldEffect","SX_D5")
            d.FocusDistance = 40; d.InFocusRadius = 20
            d.NearIntensity = 0.2; d.FarIntensity = 0.6
            local s = getEff("SunRaysEffect","SX_S5")
            s.Intensity = 0.15; s.Spread = 0.3
            Lighting.Ambient = Color3.fromRGB(70,55,45); Lighting.Brightness = 2.8
        end,
        off = function() remEff({"SX_B5","SX_C5","SX_D5","SX_S5"}) end,
    },
    {
        name  = "NIGHT SHADERS",
        color = Color3.fromRGB(80, 100, 220),
        on = function()
            local c = getEff("ColorCorrectionEffect","SX_C6")
            c.Brightness = -0.2; c.Contrast = 0.3; c.Saturation = -0.15
            c.TintColor = Color3.fromRGB(180,190,255)
            local b = getEff("BloomEffect","SX_B6")
            b.Intensity = 2.0; b.Size = 22; b.Threshold = 0.7
            Lighting.Ambient    = Color3.fromRGB(20,25,60)
            Lighting.Brightness = 0.5
            Lighting.ClockTime  = 0
            Lighting.FogColor   = Color3.fromRGB(10,15,40)
            Lighting.FogEnd     = 500
        end,
        off = function()
            remEff({"SX_C6","SX_B6"})
            Lighting.ClockTime = origLight.ClockTime
            Lighting.FogColor  = origLight.FogColor
            Lighting.FogEnd    = origLight.FogEnd
        end,
    },
    {
        name  = "8 BIT SHADERS",
        color = Color3.fromRGB(255, 100, 150),
        on = function()
            local c = getEff("ColorCorrectionEffect","SX_C7")
            c.Brightness = 0.15; c.Contrast = 0.6; c.Saturation = 0.8
            c.TintColor = Color3.fromRGB(255,240,255)
            Lighting.Brightness = 2
            Lighting.Ambient    = Color3.fromRGB(80,80,80)
        end,
        off = function() remEff({"SX_C7"}) end,
    },
    {
        name  = "SUNRISE SHADERS",
        color = Color3.fromRGB(255, 175, 80),
        on = function()
            local c = getEff("ColorCorrectionEffect","SX_C8")
            c.Brightness = 0.14; c.Contrast = 0.22; c.Saturation = 0.45
            c.TintColor = Color3.fromRGB(255, 235, 180)
            local b = getEff("BloomEffect","SX_B8")
            b.Intensity = 1.4; b.Size = 22; b.Threshold = 0.82
            local s = getEff("SunRaysEffect","SX_S8")
            s.Intensity = 0.45; s.Spread = 0.75
            Lighting.Ambient    = Color3.fromRGB(130, 90, 55)
            Lighting.Brightness = 3.2
            Lighting.ClockTime  = 6.5
        end,
        off = function()
            remEff({"SX_C8","SX_B8","SX_S8"})
            Lighting.ClockTime = origLight.ClockTime
        end,
    },
    {
        name  = "SUNSET SHADERS",
        color = Color3.fromRGB(255, 110, 70),
        on = function()
            local c = getEff("ColorCorrectionEffect","SX_C10")
            c.Brightness = 0.06; c.Contrast = 0.3; c.Saturation = 0.55
            c.TintColor = Color3.fromRGB(255, 190, 150)
            local b = getEff("BloomEffect","SX_B10")
            b.Intensity = 1.6; b.Size = 26; b.Threshold = 0.78
            local s = getEff("SunRaysEffect","SX_S10")
            s.Intensity = 0.5; s.Spread = 0.85
            Lighting.Ambient    = Color3.fromRGB(140, 70, 60)
            Lighting.Brightness = 2.4
            Lighting.ClockTime  = 18.5
        end,
        off = function()
            remEff({"SX_C10","SX_B10","SX_S10"})
            Lighting.ClockTime = origLight.ClockTime
        end,
    },
    {
        name  = "SNOW SHADERS",
        color = Color3.fromRGB(200, 225, 255),
        on = function()
            local c = getEff("ColorCorrectionEffect","SX_C11")
            c.Brightness = 0.18; c.Contrast = 0.1; c.Saturation = -0.35
            c.TintColor = Color3.fromRGB(225, 240, 255)
            local b = getEff("BloomEffect","SX_B11")
            b.Intensity = 1.0; b.Size = 20; b.Threshold = 0.85
            Lighting.Ambient    = Color3.fromRGB(160, 175, 195)
            Lighting.Brightness = 3.4
            Lighting.FogColor   = Color3.fromRGB(210, 225, 240)
            Lighting.FogEnd     = 700
        end,
        off = function()
            remEff({"SX_C11","SX_B11"})
            Lighting.FogColor = origLight.FogColor
            Lighting.FogEnd   = origLight.FogEnd
        end,
    },
    {
        name  = "THUNDER SHADERS",
        color = Color3.fromRGB(120, 130, 160),
        on = function()
            local c = getEff("ColorCorrectionEffect","SX_C12")
            c.Brightness = -0.15; c.Contrast = 0.5; c.Saturation = -0.4
            c.TintColor = Color3.fromRGB(190, 200, 220)
            local b = getEff("BloomEffect","SX_B12")
            b.Intensity = 0.6; b.Size = 14; b.Threshold = 0.95
            Lighting.Ambient    = Color3.fromRGB(45, 48, 60)
            Lighting.Brightness = 1.1
            Lighting.FogColor   = Color3.fromRGB(60, 63, 75)
            Lighting.FogEnd     = 350
        end,
        off = function()
            remEff({"SX_C12","SX_B12"})
            Lighting.FogColor = origLight.FogColor
            Lighting.FogEnd   = origLight.FogEnd
        end,
    },
    {
        name  = "VERY ULTRA HIGH GRAPHICS",
        color = Color3.fromRGB(255, 60, 180),
        on = function()
            local b = getEff("BloomEffect","SX_B13")
            b.Intensity = 3.2; b.Size = 32; b.Threshold = 0.6
            local c = getEff("ColorCorrectionEffect","SX_C13")
            c.Brightness = 0.12; c.Contrast = 0.5; c.Saturation = 0.55
            c.TintColor = Color3.fromRGB(250,250,255)
            local s = getEff("SunRaysEffect","SX_S13")
            s.Intensity = 0.5; s.Spread = 0.9
            local d = getEff("DepthOfFieldEffect","SX_D13")
            d.FocusDistance = 55; d.InFocusRadius = 35
            d.NearIntensity = 0.1; d.FarIntensity = 0.35
            Lighting.Ambient    = Color3.fromRGB(90,95,130)
            Lighting.Brightness = 4.2
        end,
        off = function() remEff({"SX_B13","SX_C13","SX_S13","SX_D13"}) end,
    },
    {
        name  = "ROBLOX 4K GRAPHIC SHADER",
        color = Color3.fromRGB(60, 220, 255),
        on = function()
            local b = getEff("BloomEffect","SX_B14")
            b.Intensity = 1.1; b.Size = 12; b.Threshold = 0.92
            local c = getEff("ColorCorrectionEffect","SX_C14")
            c.Brightness = 0.05; c.Contrast = 0.42; c.Saturation = 0.35
            c.TintColor = Color3.fromRGB(245,250,255)
            local s = getEff("SunRaysEffect","SX_S14")
            s.Intensity = 0.2; s.Spread = 0.35
            Lighting.Ambient    = Color3.fromRGB(100,105,120)
            Lighting.Brightness = 3
        end,
        off = function() remEff({"SX_B14","SX_C14","SX_S14"}) end,
    },
    {
        name  = "HDR GRAPHICS SHADERS",
        color = Color3.fromRGB(255, 220, 50),
        on = function()
            local b = getEff("BloomEffect","SX_B9")
            b.Intensity = 3.0; b.Size = 30; b.Threshold = 0.65
            local c = getEff("ColorCorrectionEffect","SX_C9")
            c.Brightness = 0.12; c.Contrast = 0.45; c.Saturation = 0.6
            c.TintColor = Color3.fromRGB(255,250,240)
            local s = getEff("SunRaysEffect","SX_S9")
            s.Intensity = 0.4; s.Spread = 0.8
            local d = getEff("DepthOfFieldEffect","SX_D9")
            d.FocusDistance = 60; d.InFocusRadius = 40
            d.NearIntensity = 0.08; d.FarIntensity = 0.25
            Lighting.Ambient    = Color3.fromRGB(85,90,115)
            Lighting.Brightness = 4.0
        end,
        off = function() remEff({"SX_B9","SX_C9","SX_S9","SX_D9"}) end,
    },
}

-- ── GUI parent (executor safe) ────────────────
local guiParent = (gethui and gethui()) or LP:WaitForChild("PlayerGui")

-- ── ScreenGui ─────────────────────────────────
local SG = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
SG.Name           = "SIEXTHERShaders"
SG.ResetOnSpawn   = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset = true
SG.DisplayOrder   = 999
SG.Parent         = guiParent

-- ── Tiny helpers ──────────────────────────────
local function mk(cls, props, par)
    local o = __SIEXTHER_VIP_GLASS_V1.Instance.new(cls)
    for k, v in pairs(props) do o[k] = v end
    if par then o.Parent = par end
    return o
end
local function rnd(r, p)
    mk("UICorner", {CornerRadius = UDim.new(0, r)}, p)
end
local function strk(col, thk, tr, p)
    mk("UIStroke", {Color = col, Thickness = thk, Transparency = tr}, p)
end
local TI = function(t, s, d)
    return TweenInfo.new(t, s or Enum.EasingStyle.Quad, d or Enum.EasingDirection.Out)
end


local Main = mk("Frame", {
    Name             = "Main",
    Size             = UDim2.new(0, 188, 0, 316),
    Position         = UDim2.new(0.5, -94, 0.5, -158),
    BackgroundColor3 = BG,
    BorderSizePixel  = 0,
    ClipsDescendants = true,
    ZIndex           = 2,
}, SG)
rnd(10, Main)
strk(ACCENT, 1.5, 0.25, Main)

-- subtle inner gradient
mk("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 45)),
        ColorSequenceKeypoint.new(1, BG),
    }),
    Rotation = 135,
}, Main)

-- ══════════════════════════════════════════════
--   TITLE BAR
-- ══════════════════════════════════════════════
local TBar = mk("Frame", {
    Size             = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = DARK,
    BorderSizePixel  = 0,
    ZIndex           = 3,
}, Main)
rnd(10, TBar)

-- fill bottom corners of titlebar
mk("Frame", {
    Size             = UDim2.new(1, 0, 0, 12),
    Position         = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = DARK,
    BorderSizePixel  = 0,
    ZIndex           = 3,
}, TBar)

-- bottom border line
mk("Frame", {
    Size             = UDim2.new(1, 0, 0, 1),
    Position         = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = ACCENT,
    BorderSizePixel  = 0,
    ZIndex           = 4,
    BackgroundTransparency = 0.65,
}, TBar)

-- icon + title
mk("TextLabel", {
    Size                 = UDim2.new(1, -78, 1, 0),
    Position             = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text                 = "SIEXTHER SHADER",
    TextColor3           = ACCENT,
    TextSize             = 11,
    Font                 = Enum.Font.GothamBold,
    TextXAlignment       = Enum.TextXAlignment.Left,
    ZIndex               = 5,
}, TBar)

mk("TextLabel", {
    Size                 = UDim2.new(0, 60, 0, 10),
    Position             = UDim2.new(0, 10, 0, 23),
    BackgroundTransparency = 1,
    Text                 = "Made By Hann.Siexther",
    TextColor3           = MUTED,
    TextSize             = 6,
    Font                 = Enum.Font.GothamBold,
    TextXAlignment       = Enum.TextXAlignment.Left,
    ZIndex               = 5,
}, TBar)

-- ── Minimize button ───────────────────────────
local MinBtn = mk("TextButton", {
    Size             = UDim2.new(0, 23, 0, 23),
    Position         = UDim2.new(1, -50, 0.5, -11),
    BackgroundColor3 = Color3.fromRGB(42, 42, 62),
    BorderSizePixel  = 0,
    Text             = "–",
    TextColor3       = Color3.fromRGB(180, 185, 255),
    TextSize         = 14,
    Font             = Enum.Font.GothamBold,
    ZIndex           = 6,
    AutoButtonColor  = false,
}, TBar)
rnd(6, MinBtn)

-- ── Close button ──────────────────────────────
local CloseBtn = mk("TextButton", {
    Size             = UDim2.new(0, 23, 0, 23),
    Position         = UDim2.new(1, -25, 0.5, -11),
    BackgroundColor3 = Color3.fromRGB(42, 42, 62),
    BorderSizePixel  = 0,
    Text             = "X",
    TextColor3       = Color3.fromRGB(255, 85, 85),
    TextSize         = 10,
    Font             = Enum.Font.GothamBold,
    ZIndex           = 6,
    AutoButtonColor  = false,
}, TBar)
rnd(6, CloseBtn)

-- button hover effects
for _, b in pairs({MinBtn, CloseBtn}) do
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TI(0.12), {BackgroundColor3 = Color3.fromRGB(55, 55, 78)}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TI(0.12), {BackgroundColor3 = Color3.fromRGB(42, 42, 62)}):Play()
    end)
end

-- ── Section label ─────────────────────────────
mk("TextLabel", {
    Size                 = UDim2.new(1, -14, 0, 13),
    Position             = UDim2.new(0, 8, 0, 41),
    BackgroundTransparency = 1,
    Text                 = "——— PILIH SHADER ———",
    TextColor3           = MUTED,
    TextSize             = 7,
    Font                 = Enum.Font.GothamBold,
    TextXAlignment       = Enum.TextXAlignment.Left,
    ZIndex               = 3,
}, Main)

-- divider
mk("Frame", {
    Size             = UDim2.new(1, -16, 0, 1),
    Position         = UDim2.new(0, 8, 0, 54),
    BackgroundColor3 = ACCENT,
    BackgroundTransparency = 0.8,
    BorderSizePixel  = 0,
    ZIndex           = 3,
}, Main)

-- ══════════════════════════════════════════════
--   SCROLL FRAME
-- ══════════════════════════════════════════════
local Scroll = mk("ScrollingFrame", {
    Size                 = UDim2.new(1, -10, 1, -62),
    Position             = UDim2.new(0, 5, 0, 58),
    BackgroundTransparency = 1,
    BorderSizePixel      = 0,
    ScrollBarThickness   = 2,
    ScrollBarImageColor3 = ACCENT,
    ScrollBarImageTransparency = 0.45,
    CanvasSize           = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize  = Enum.AutomaticSize.Y,
    ZIndex               = 3,
}, Main)

mk("UIListLayout", {
    Padding                  = UDim.new(0, 4),
    SortOrder                = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment      = Enum.HorizontalAlignment.Center,
}, Scroll)

mk("UIPadding", {
    PaddingTop    = UDim.new(0, 2),
    PaddingBottom = UDim.new(0, 5),
    PaddingLeft   = UDim.new(0, 2),
    PaddingRight  = UDim.new(0, 2),
}, Scroll)

-- ══════════════════════════════════════════════
--   SHADER BUTTONS  (icon dihapus, hanya teks)
-- ══════════════════════════════════════════════
local activeState = {}
local btnRefs     = {}

local function refreshBtn(data)
    local isOn = activeState[data.name]
    local btn  = btnRefs[data.name]
    if not btn then return end

    local pill = btn:FindFirstChild("Pill")
    local ind  = pill and pill:FindFirstChild("Ind")
    local plbl = pill and pill:FindFirstChild("Lbl")
    local pst  = pill and pill:FindFirstChildOfClass("UIStroke")
    local bst  = btn:FindFirstChildOfClass("UIStroke")
    local glow = btn:FindFirstChild("Glow")
    local tw   = TI(0.18)

    TweenService:Create(btn, tw, {
        BackgroundColor3 = isOn and BTN_ON or BTN
    }):Play()

    if bst then
        TweenService:Create(bst, tw, {
            Color        = isOn and ACCENT or Color3.fromRGB(52, 52, 72),
            Transparency = isOn and 0.05 or 0.72,
        }):Play()
    end
    if glow then
        TweenService:Create(glow, tw, {
            BackgroundTransparency = isOn and 0.82 or 1,
        }):Play()
    end
    if pill then
        TweenService:Create(pill, tw, {
            BackgroundColor3 = isOn and Color3.fromRGB(18, 35, 68) or Color3.fromRGB(38, 38, 58)
        }):Play()
    end
    if pst then
        TweenService:Create(pst, tw, {
            Color        = isOn and ACCENT or Color3.fromRGB(52, 52, 72),
            Transparency = isOn and 0.1 or 0.72,
        }):Play()
    end
    if ind then
        TweenService:Create(ind, tw, {
            Position         = isOn and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
            BackgroundColor3 = isOn and ACCENT or Color3.fromRGB(62, 62, 88),
        }):Play()
    end
    if plbl then
        plbl.Text      = isOn and "ON" or "OFF"
        plbl.TextColor3 = isOn and ACCENT or MUTED
    end
end

for i, data in ipairs(SHADERS) do
    -- main button
    local Btn = mk("TextButton", {
        Name             = data.name,
        Size             = UDim2.new(1, -4, 0, 32),
        BackgroundColor3 = BTN,
        BorderSizePixel  = 0,
        Text             = "",
        LayoutOrder      = i,
        AutoButtonColor  = false,
        ZIndex           = 4,
    }, Scroll)
    rnd(8, Btn)
    strk(Color3.fromRGB(52, 52, 72), 1, 0.72, Btn)

    -- accent glow (visible when ON)
    local Glow = mk("Frame", {
        Name                 = "Glow",
        Size                 = UDim2.new(1, 0, 1, 0),
        BackgroundColor3     = data.color,
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        ZIndex               = 4,
    }, Btn)
    rnd(8, Glow)

    -- left color stripe (menggantikan ikon)
    local stripe = mk("Frame", {
        Size             = UDim2.new(0, 3, 0.52, 0),
        Position         = UDim2.new(0, 8, 0.24, 0),
        BackgroundColor3 = data.color,
        BorderSizePixel  = 0,
        ZIndex           = 5,
    }, Btn)
    rnd(3, stripe)

    -- shader name (mulai lebih ke kiri karena tidak ada ikon)
    mk("TextLabel", {
        Size                 = UDim2.new(1, -68, 1, 0),
        Position             = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Text                 = data.name,
        TextColor3           = TEXT,
        TextSize             = 9,
        Font                 = Enum.Font.GothamBold,
        TextXAlignment       = Enum.TextXAlignment.Left,
        TextTruncate         = Enum.TextTruncate.AtEnd,
        ZIndex               = 5,
    }, Btn)

    -- toggle pill background
    local Pill = mk("Frame", {
        Name             = "Pill",
        Size             = UDim2.new(0, 40, 0, 20),
        Position         = UDim2.new(1, -46, 0.5, -10),
        BackgroundColor3 = Color3.fromRGB(38, 38, 58),
        BorderSizePixel  = 0,
        ZIndex           = 5,
    }, Btn)
    rnd(10, Pill)
    strk(Color3.fromRGB(52, 52, 72), 1, 0.72, Pill)

    -- sliding circle
    local Ind = mk("Frame", {
        Name             = "Ind",
        Size             = UDim2.new(0, 12, 0, 12),
        Position         = UDim2.new(0, 3, 0.5, -6),
        BackgroundColor3 = Color3.fromRGB(62, 62, 88),
        BorderSizePixel  = 0,
        ZIndex           = 6,
    }, Pill)
    rnd(6, Ind)

    -- ON/OFF label
    mk("TextLabel", {
        Name                 = "Lbl",
        Size                 = UDim2.new(1, -14, 1, 0),
        Position             = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text                 = "OFF",
        TextColor3           = MUTED,
        TextSize             = 6,
        Font                 = Enum.Font.GothamBold,
        ZIndex               = 6,
    }, Pill)

    btnRefs[data.name] = Btn

    -- hover
    Btn.MouseEnter:Connect(function()
        if not activeState[data.name] then
            TweenService:Create(Btn, TI(0.12), {BackgroundColor3 = Color3.fromRGB(40, 40, 58)}):Play()
        end
    end)
    Btn.MouseLeave:Connect(function()
        if not activeState[data.name] then
            TweenService:Create(Btn, TI(0.12), {BackgroundColor3 = BTN}):Play()
        end
    end)

    -- click toggle
    Btn.MouseButton1Click:Connect(function()
        activeState[data.name] = not activeState[data.name]
        if activeState[data.name] then data.on() else data.off() end
        refreshBtn(data)
    end)
end

-- ══════════════════════════════════════════════
--   FLOATING BUTTON (minimized state)
-- ══════════════════════════════════════════════
local FloatBtn = mk("TextButton", {
    Name             = "FloatBtn",
    Size             = UDim2.new(0, 40, 0, 40),
    Position         = UDim2.new(0, 18, 0.5, -22),
    BackgroundColor3 = Color3.fromRGB(25, 25, 35),
    BorderSizePixel  = 0,
    Text             = "🪐",
    TextSize         = 20,
    Visible          = false,
    ZIndex           = 10,
    AutoButtonColor  = false,
}, SG)
rnd(12, FloatBtn)

do
    local drag, ds, sp = false, nil, nil
    TBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = i.Position; sp = Main.Position
        end
    end)
    TBar.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
                  or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X,
                                      sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

-- Float button drag (with click detection)
local fbDrag, fbDS, fbSP, fbMoved = false, nil, nil, false
FloatBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        fbDrag = true; fbMoved = false
        fbDS = i.Position; fbSP = FloatBtn.Position
    end
end)
FloatBtn.InputChanged:Connect(function(i)
    if fbDrag and (i.UserInputType == Enum.UserInputType.MouseMovement
               or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - fbDS
        if math.abs(d.X) > 5 or math.abs(d.Y) > 5 then fbMoved = true end
        FloatBtn.Position = UDim2.new(fbSP.X.Scale, fbSP.X.Offset + d.X,
                                      fbSP.Y.Scale,  fbSP.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then fbDrag = false end
end)

-- ══════════════════════════════════════════════
--   MINIMIZE  →  floating 🩷
-- ══════════════════════════════════════════════
MinBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TI(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 188, 0, 0),
    }):Play()
    task.wait(0.22)
    Main.Visible    = false
    FloatBtn.Visible = true
    FloatBtn.Size   = UDim2.new(0, 0, 0, 0)
    TweenService:Create(FloatBtn, TI(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 44, 0, 44),
    }):Play()
end)

-- ══════════════════════════════════════════════
--   RESTORE from floating
-- ══════════════════════════════════════════════
FloatBtn.MouseButton1Click:Connect(function()
    if fbMoved then return end
    FloatBtn.Visible = false
    Main.Visible     = true
    Main.Size        = UDim2.new(0, 188, 0, 0)
    TweenService:Create(Main, TI(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 188, 0, 316),
    }):Play()
end)

-- ══════════════════════════════════════════════
--   CLOSE  →  destroy script
-- ══════════════════════════════════════════════
CloseBtn.MouseButton1Click:Connect(function()
    -- disable all active shaders first
    for _, d in ipairs(SHADERS) do
        if activeState[d.name] then
            pcall(d.off)
        end
    end
    -- restore original lighting
    Lighting.Ambient    = origLight.Ambient
    Lighting.Brightness = origLight.Brightness
    Lighting.ClockTime  = origLight.ClockTime
    Lighting.FogColor   = origLight.FogColor
    Lighting.FogEnd     = origLight.FogEnd

    TweenService:Create(Main, TI(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size                 = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
    }):Play()
    task.wait(0.22)
    SG:Destroy()
end)
