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

local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

-- State
local Active = true
local TargetList = {}
local CurrentIndex = 0
local CurrentTarget = nil
local FlingActive = false
local FlingThread = nil
local OriginalCFrame = nil
local FollowActive = false
local FollowConnection = nil
local FollowAnim = nil
local SendPartActive = false
local SendPartLoopThread = nil
local FreezeConnection = nil
local OriginalWalkSpeed = 16
local OriginalJumpPower = 50
local NetworkConnection = nil

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
    else humanoid = nil rootPart = nil end
end
refreshCharacterRefs()

LP.CharacterAdded:Connect(function(char)
    pcall(function() char:WaitForChild("Humanoid",5) char:WaitForChild("HumanoidRootPart",5) end)
    refreshCharacterRefs()
    if FollowActive then
        if FollowConnection then FollowConnection:Disconnect() FollowConnection = nil end
        if FollowAnim then pcall(function() FollowAnim:Stop() end) FollowAnim = nil end
        FollowActive = false
    end
end)

-- ========== FREEZE ==========
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
    if humanoid then humanoid.WalkSpeed = 0 humanoid.JumpPower = 0 end
end

local function unfreezeCharacter()
    if FreezeConnection then FreezeConnection:Disconnect() FreezeConnection = nil end
    if humanoid then
        humanoid.WalkSpeed = OriginalWalkSpeed
        humanoid.JumpPower = OriginalJumpPower
    end
end

-- ========== WARNA ==========
local BG_MAIN    = Color3.fromRGB(25, 25, 35)
local BG_CARD    = Color3.fromRGB(35, 35, 48)
local BG_BTN     = Color3.fromRGB(45, 45, 60)
local BG_BTN_HOV = Color3.fromRGB(60, 60, 78)
local COL_WHITE  = Color3.fromRGB(255, 255, 255)
local COL_GRAY   = Color3.fromRGB(155, 155, 175)
local COL_GREEN  = Color3.fromRGB(80, 220, 100)
local COL_RED    = Color3.fromRGB(220, 70, 70)
local COL_BORDER = Color3.fromRGB(70, 130, 255)

-- ========== SCREEN GUI ==========
local ScreenGui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
ScreenGui.Name = "SiextheR_Spectator"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ========== FLOATING ICON (saat minimize) ==========
-- Ukuran frame:
-- TitleBar: 32px
-- ProfileCard: 68px
-- 3 baris tombol: 3 * 38px = 114px
-- gap atas/bawah + antar: 8+8+5+5+5 = 31px
-- Total: 32 + 8 + 68 + 8 + 114 + 10 = 240px
local FULL_H = 250
local FULL_W = 300

local MainFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, FULL_W, 0, FULL_H)
MainFrame.Position = UDim2.new(0.5, -150, 0.12, 0)
MainFrame.BackgroundColor3 = BG_MAIN
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Active = true
MainFrame.Draggable = false -- manual drag via TitleBar

local MainCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 10)

local MainStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke", MainFrame)
MainStroke.Color = COL_BORDER
MainStroke.Thickness = 1.5

-- ========== TITLE BAR (32px) ==========
local TitleBar = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = BG_MAIN
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", TitleBar)
TitleCorner.CornerRadius = UDim.new(0, 10)

local TitleLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "SIEXTHER SPECTATOR"
TitleLabel.TextColor3 = COL_WHITE
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar
local TitleTextStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke", TitleLabel)
TitleTextStroke.Color = Color3.fromRGB(0, 0, 0)
TitleTextStroke.Thickness = 1.5
TitleTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

-- Minimize (—)
local MinimizeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 24, 0, 24)
MinimizeBtn.Position = UDim2.new(1, -54, 0.5, -12)
MinimizeBtn.BackgroundColor3 = BG_BTN
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Text = "–"
MinimizeBtn.TextColor3 = COL_WHITE
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 12
MinimizeBtn.Parent = TitleBar
__SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 5)

-- Close (□)
local CloseNavBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
CloseNavBtn.Size = UDim2.new(0, 24, 0, 24)
CloseNavBtn.Position = UDim2.new(1, -28, 0.5, -12)
CloseNavBtn.BackgroundColor3 = BG_BTN
CloseNavBtn.BorderSizePixel = 0
CloseNavBtn.Text = "x"
CloseNavBtn.TextColor3 = COL_WHITE
CloseNavBtn.Font = Enum.Font.GothamBold
CloseNavBtn.TextSize = 12
CloseNavBtn.Parent = TitleBar
__SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", CloseNavBtn).CornerRadius = UDim.new(0, 5)

-- (Separator/divider dihapus)

-- ========== CONTENT FRAME ==========
local ContentFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, 0, 1, -32)
ContentFrame.Position = UDim2.new(0, 0, 0, 32)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0
ContentFrame.Parent = MainFrame

-- ========== PROFILE CARD (68px, posisi Y=6) ==========
local ProfileCard = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
ProfileCard.Size = UDim2.new(1, -16, 0, 68)
ProfileCard.Position = UDim2.new(0, 8, 0, 8)
ProfileCard.BackgroundColor3 = BG_CARD
ProfileCard.BorderSizePixel = 0
ProfileCard.Parent = ContentFrame
__SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", ProfileCard).CornerRadius = UDim.new(0, 7)
local PS = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke", ProfileCard)
PS.Color = COL_BORDER PS.Thickness = 1

-- Avatar (48x48)
local Avatar = __SIEXTHER_VIP_GLASS_V1.Instance.new("ImageLabel")
Avatar.Size = UDim2.new(0, 48, 0, 48)
Avatar.Position = UDim2.new(0, 10, 0.5, -24)
Avatar.BackgroundColor3 = BG_BTN
Avatar.BorderSizePixel = 0
Avatar.Image = ""
Avatar.Parent = ProfileCard
__SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", Avatar).CornerRadius = UDim.new(0, 7)

-- Status dot
local StatusDot = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 9, 0, 9)
StatusDot.Position = UDim2.new(0, 10 + 48 - 10, 0.5, 24 - 10)
StatusDot.BackgroundColor3 = COL_RED
StatusDot.BorderSizePixel = 0
StatusDot.ZIndex = 2
StatusDot.Parent = ProfileCard
__SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)

-- Username
local UsernameLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
UsernameLabel.Size = UDim2.new(1, -70, 0, 22)
UsernameLabel.Position = UDim2.new(0, 66, 0, 10)
UsernameLabel.BackgroundTransparency = 1
UsernameLabel.Text = "Nama"
UsernameLabel.TextColor3 = COL_WHITE
UsernameLabel.Font = Enum.Font.GothamBold
UsernameLabel.TextSize = 13
UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left
UsernameLabel.Parent = ProfileCard

-- Age
local AgeLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
AgeLabel.Size = UDim2.new(1, -70, 0, 16)
AgeLabel.Position = UDim2.new(0, 66, 0, 32)
AgeLabel.BackgroundTransparency = 1
AgeLabel.Text = "Age: 0 days"
AgeLabel.TextColor3 = COL_GRAY
AgeLabel.Font = Enum.Font.Gotham
AgeLabel.TextSize = 11
AgeLabel.TextXAlignment = Enum.TextXAlignment.Left
AgeLabel.Parent = ProfileCard

-- ID
local IdLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
IdLabel.Size = UDim2.new(1, -70, 0, 14)
IdLabel.Position = UDim2.new(0, 66, 0, 48)
IdLabel.BackgroundTransparency = 1
IdLabel.Text = "ID: 0"
IdLabel.TextColor3 = COL_GRAY
IdLabel.Font = Enum.Font.Gotham
IdLabel.TextSize = 10
IdLabel.TextXAlignment = Enum.TextXAlignment.Left
IdLabel.Parent = ProfileCard

-- ========== TOMBOL GRID ==========
-- Mulai Y = 6 (top pad) + 68 (profile) + 6 (gap) = 80
-- Tiap baris: 38px tinggi, gap 4px
-- Lebar tiap tombol: (290 - 12 - 12 - 6) / 2 = 130px
local function makeBtn(parent, text, col, row)
    local padL = 8
    local gap = 6
    local btnW = 139  -- (300 - 16 - 6) / 2 = 139
    local btnH = 36
    local startY = 84  -- 8 (top pad) + 68 (profile) + 8 (gap)
    local xPos = padL + (col - 1) * (btnW + gap)
    local yPos = startY + (row - 1) * (btnH + gap)

    local Btn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
    Btn.Size = UDim2.new(0, btnW, 0, btnH)
    Btn.Position = UDim2.new(0, xPos, 0, yPos)
    Btn.BackgroundColor3 = BG_BTN
    Btn.BorderSizePixel = 0
    Btn.Text = text
    Btn.TextColor3 = COL_WHITE
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 12
    Btn.AutoButtonColor = false
    Btn.Parent = parent

    local bc = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", Btn)
    bc.CornerRadius = UDim.new(0, 7)

    local bs = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke", Btn)
    bs.Color = COL_BORDER
    bs.Thickness = 1
    bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.12), {BackgroundColor3 = BG_BTN_HOV}):Play()
    end)
    Btn.MouseLeave:Connect(function()
        if __SIEXTHER_VIP_GLASS_V1.Read(Btn, "BackgroundColor3") ~= COL_GREEN and __SIEXTHER_VIP_GLASS_V1.Read(Btn, "BackgroundColor3") ~= COL_RED then
            TweenService:Create(Btn, TweenInfo.new(0.12), {BackgroundColor3 = BG_BTN}):Play()
        end
    end)
    return Btn
end

-- Row 1: PREV | NEXT
local PrevBtn     = makeBtn(ContentFrame, "PREV",     1, 1)
local NextBtn     = makeBtn(ContentFrame, "NEXT",     2, 1)
-- Row 2: TELEPORT | KICK
local TeleBtn     = makeBtn(ContentFrame, "TELEPORT", 1, 2)
local KickBtn     = makeBtn(ContentFrame, "KICK",     2, 2)
-- Row 3: FOLLOW | SEND PART
local FollowBtn   = makeBtn(ContentFrame, "FOLLOW",   1, 3)
local SendPartBtn = makeBtn(ContentFrame, "SEND PART",2, 3)

-- ========== EYE BUTTON ==========
local EyeBtn = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
EyeBtn.Name = "EyeIcon"
EyeBtn.Size = UDim2.new(0, 41, 0, 41)
EyeBtn.Position = UDim2.new(0, 14, 0.5, -19) -- posisi default awal
EyeBtn.BackgroundColor3 = BG_MAIN
EyeBtn.BorderSizePixel = 0
EyeBtn.Text = "👁️"
EyeBtn.TextSize = 20
EyeBtn.Font = Enum.Font.GothamBold
EyeBtn.Visible = false
EyeBtn.Active = true
EyeBtn.Draggable = false -- kita handle manual biar smooth
EyeBtn.ZIndex = 5
EyeBtn.Parent = ScreenGui
__SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner", EyeBtn).CornerRadius = UDim.new(0, 12)
local EyeStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke", EyeBtn)
EyeStroke.Color = COL_BORDER
EyeStroke.Thickness = 1.5

-- ========== DRAG LOGIC UNTUK MAINFRAME (via TitleBar) ==========
local draggingMain = false
local dragInputMain, dragStartMain, startPosMain

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        draggingMain = true
        dragStartMain = input.Position
        startPosMain = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingMain = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or
       input.UserInputType == Enum.UserInputType.Touch then
        dragInputMain = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if draggingMain and input == dragInputMain then
        local delta = input.Position - dragStartMain
        MainFrame.Position = UDim2.new(
            startPosMain.X.Scale,
            startPosMain.X.Offset + delta.X,
            startPosMain.Y.Scale,
            startPosMain.Y.Offset + delta.Y
        )
    end
end)

-- ========== DRAG LOGIC UNTUK EYE BUTTON ==========
local dragging = false
local dragInput, dragStart, startPos
local dragMoved = false

EyeBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragMoved = false
        dragStart = input.Position
        startPos = EyeBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

EyeBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or
       input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        if delta.Magnitude > 4 then dragMoved = true end
        EyeBtn.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ========== MINIMIZE LOGIC ==========
local minimized = false

MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = true
    -- EyeBtn tetap di posisi terakhirnya, tidak ikut MainFrame
    MainFrame.Visible = false
    EyeBtn.Visible = true
end)

EyeBtn.MouseButton1Click:Connect(function()
    if dragMoved then dragMoved = false return end -- jangan trigger klik kalau habis drag
    minimized = false
    EyeBtn.Visible = false
    -- MainFrame muncul di posisi terakhirnya (tidak berubah saat minimize)
    MainFrame.Size = UDim2.new(0, FULL_W, 0, FULL_H)
    MainFrame.Visible = true
end)

-- ========== CLOSE ==========
CloseNavBtn.MouseButton1Click:Connect(function()
    Active = false
    FlingActive = false
    SendPartActive = false
    unfreezeCharacter()
    if FollowConnection then FollowConnection:Disconnect() FollowConnection = nil end
    if FollowAnim then pcall(function() FollowAnim:Stop() end) FollowAnim = nil end
    if LP.Character and LP.Character:FindFirstChild("Humanoid") then
        Cam.CameraSubject = LP.Character:FindFirstChild("Humanoid")
    end
    pcall(function() ScreenGui:Destroy() end)
end)

-- ========== UPDATE PROFILE ==========
local function updateProfile(plr)
    if plr and plr:IsA("Player") then
        UsernameLabel.Text = plr.Name
        AgeLabel.Text = "Age: " .. tostring(plr.AccountAge or 0) .. " days"
        IdLabel.Text = "ID: " .. tostring(plr.UserId)
        StatusDot.BackgroundColor3 = COL_GREEN
        pcall(function()
            Avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. plr.UserId .. "&width=150&height=150&format=png"
        end)
    else
        UsernameLabel.Text = "Nama"
        AgeLabel.Text = "Age: 0 days"
        IdLabel.Text = "ID: 0"
        Avatar.Image = ""
        StatusDot.BackgroundColor3 = COL_RED
    end
end

-- ========== SEND PART HELPERS ==========
local function OneTimeUnanchor()
    if _G.__JSY_UnanchorCooldown then return end
    _G.__JSY_UnanchorCooldown = true
    task.spawn(function()
        local start = tick()
        while tick() - start < 1 do
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("RopeConstraint") then
                    local p0 = obj.Attachment0 and obj.Attachment0.Parent
                    local p1 = obj.Attachment1 and obj.Attachment1.Parent
                    pcall(function() obj:Destroy() end)
                    if p0 and p0:IsA("BasePart") then p0.Anchored = false end
                    if p1 and p1:IsA("BasePart") then p1.Anchored = false end
                end
            end
            for _, part in ipairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") and not part.Anchored then
                    part.AssemblyLinearVelocity = Vector3.new(math.random(-50,50), math.random(20,100), math.random(-50,50))
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
        if obj:IsA("BasePart") then table.insert(parts, obj)
        elseif obj:IsA("Model") or obj:IsA("Folder") then
            for _, p in ipairs(GetAllPartsRecursive(obj)) do table.insert(parts, p) end
        end
    end
    return parts
end

local function EnableNetworkStabilizer()
    if NetworkConnection then return end
    pcall(function()
        NetworkConnection = RunService.Heartbeat:Connect(function()
            pcall(function()
                if sethiddenproperty then sethiddenproperty(LP, "SimulationRadius", math.huge) end
            end)
        end)
    end)
end

local function DisableNetworkStabilizer()
    if NetworkConnection then NetworkConnection:Disconnect() NetworkConnection = nil end
end

local function sendUnanchoredPartsToTarget(target)
    if not target or not target.Character then return end
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end

    EnableNetworkStabilizer()
    OneTimeUnanchor()

    local folder = Workspace:FindFirstChild("JSY_SendPartFolder") or __SIEXTHER_VIP_GLASS_V1.Instance.new("Folder", Workspace)
    folder.Name = "JSY_SendPartFolder"

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
        if v.Parent and v.Parent:FindFirstChildOfClass("Humanoid") then return end
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
                    if child:IsA("Attachment") and child ~= attach1 then
                        pcall(function() child:Destroy() end)
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
        pcall(function() if not p.Anchored then ForcePart(p) end end)
    end

    task.spawn(function()
        local start = tick()
        while tick() - start < 5 do
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

local function turnOffSendPart()
    if SendPartActive then
        SendPartActive = false
        SendPartBtn.Text = "SEND PART"
        TweenService:Create(SendPartBtn, TweenInfo.new(0.3), {BackgroundColor3 = BG_BTN}):Play()
        unfreezeCharacter()
    end
end

-- ========== TARGETING ==========
local function getTargetablePlayers()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(list, p)
        end
    end
    return list
end

local function refreshTargetList()
    local oldTarget = CurrentTarget
    TargetList = getTargetablePlayers()
    if #TargetList == 0 then
        CurrentIndex = 0; CurrentTarget = nil; updateProfile(nil); return
    end
    if oldTarget and table.find(TargetList, oldTarget) then
        CurrentIndex = table.find(TargetList, oldTarget)
        CurrentTarget = oldTarget; updateProfile(CurrentTarget); return
    end
    if oldTarget then
        for i, player in ipairs(TargetList) do
            if player.UserId == oldTarget.UserId then
                CurrentIndex = i; CurrentTarget = player; updateProfile(CurrentTarget); return
            end
        end
    end
    if CurrentIndex < 1 or CurrentIndex > #TargetList then CurrentIndex = 1 end
    CurrentTarget = TargetList[CurrentIndex]
    updateProfile(CurrentTarget)
end

local refreshDebounce = false
local function safeRefreshTargetList()
    if refreshDebounce then return end
    refreshDebounce = true
    refreshTargetList()
    task.wait(0.5)
    refreshDebounce = false
end

refreshTargetList()

Players.PlayerAdded:Connect(function() task.wait(0.1) safeRefreshTargetList() end)
Players.PlayerRemoving:Connect(function(plr)
    task.wait(0.1)
    safeRefreshTargetList()
    if CurrentTarget and plr == CurrentTarget then
        CurrentTarget = nil; updateProfile(nil)
        if FollowActive then
            FollowActive = false
            if FollowConnection then FollowConnection:Disconnect() FollowConnection = nil end
            if FollowAnim then pcall(function() FollowAnim:Stop() end) FollowAnim = nil end
            FollowBtn.Text = "FOLLOW"
            TweenService:Create(FollowBtn, TweenInfo.new(0.3), {BackgroundColor3 = BG_BTN}):Play()
        end
        if FlingActive then
            FlingActive = false; KickBtn.Text = "KICK"
            TweenService:Create(KickBtn, TweenInfo.new(0.3), {BackgroundColor3 = BG_BTN}):Play()
        end
        if SendPartActive then turnOffSendPart() end
    end
end)

-- ========== NAVIGATION ==========
PrevBtn.MouseButton1Click:Connect(function()
    if #TargetList == 0 then safeRefreshTargetList() end
    if #TargetList == 0 then return end
    local idx = CurrentIndex - 1
    if idx < 1 then idx = #TargetList end
    CurrentIndex = idx; CurrentTarget = TargetList[CurrentIndex]
    updateProfile(CurrentTarget); turnOffSendPart()
end)

NextBtn.MouseButton1Click:Connect(function()
    if #TargetList == 0 then safeRefreshTargetList() end
    if #TargetList == 0 then return end
    local idx = CurrentIndex + 1
    if idx > #TargetList then idx = 1 end
    CurrentIndex = idx; CurrentTarget = TargetList[CurrentIndex]
    updateProfile(CurrentTarget); turnOffSendPart()
end)

-- ========== CAMERA ==========
RunService.RenderStepped:Connect(function()
    if not Active then return end
    if CurrentTarget and CurrentTarget.Character then
        local hrp = CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
        if hrp then Cam.CameraSubject = hrp end
    end
end)

-- ========== TELEPORT ==========
TeleBtn.MouseButton1Click:Connect(function()
    if not CurrentTarget then return end
    local lpHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local targetHRP = CurrentTarget.Character and CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
    if lpHRP and targetHRP then
        lpHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
        TweenService:Create(TeleBtn, TweenInfo.new(0.3), {BackgroundColor3 = COL_GREEN}):Play()
        task.wait(0.5)
        TweenService:Create(TeleBtn, TweenInfo.new(0.3), {BackgroundColor3 = BG_BTN}):Play()
    end
end)

-- ========== KICK / FLING ==========
local function flingLoop()
    while FlingActive do
        RunService.Heartbeat:Wait()
        local lpHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local targetHRP = CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
        if lpHRP and targetHRP then
            local dir = (targetHRP.Position - lpHRP.Position)
            if dir.Magnitude > 0 then lpHRP.AssemblyLinearVelocity = dir.Unit * 500 end
            lpHRP.CFrame = targetHRP.CFrame
        end
    end
end

KickBtn.MouseButton1Click:Connect(function()
    if not CurrentTarget then return end
    local lpHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not lpHRP then return end
    FlingActive = not FlingActive
    if FlingActive then
        OriginalCFrame = lpHRP.CFrame
        KickBtn.Text = "KICKING..."
        TweenService:Create(KickBtn, TweenInfo.new(0.3), {BackgroundColor3 = COL_RED}):Play()
        if not FlingThread then FlingThread = task.spawn(flingLoop) end
    else
        FlingActive = false; KickBtn.Text = "KICK"
        TweenService:Create(KickBtn, TweenInfo.new(0.3), {BackgroundColor3 = BG_BTN}):Play()
        FlingThread = nil
        task.defer(function()
            pcall(function()
                if lpHRP and OriginalCFrame then
                    lpHRP.AssemblyLinearVelocity = Vector3.zero
                    lpHRP.AssemblyAngularVelocity = Vector3.zero
                    task.wait(0.1)
                    lpHRP.CFrame = OriginalCFrame
                end
            end)
        end)
    end
end)

-- ========== FOLLOW ==========
local function stopFollow()
    FollowActive = false
    if FollowConnection then FollowConnection:Disconnect() FollowConnection = nil end
    if FollowAnim then pcall(function() FollowAnim:Stop() end) FollowAnim = nil end
    FollowBtn.Text = "FOLLOW"
    TweenService:Create(FollowBtn, TweenInfo.new(0.3), {BackgroundColor3 = BG_BTN}):Play()
end

local function startFollowToTarget(target)
    if not target or not rootPart or not humanoid then return end
    FollowActive = true
    FollowBtn.Text = "FOLLOWING..."
    TweenService:Create(FollowBtn, TweenInfo.new(0.3), {BackgroundColor3 = COL_GREEN}):Play()
    pcall(function()
        local anim = __SIEXTHER_VIP_GLASS_V1.Instance.new("Animation")
        anim.AnimationId = "rbxassetid://100681208320300"
        FollowAnim = humanoid:LoadAnimation(anim)
        FollowAnim.Looped = true
        FollowAnim:Play()
    end)
    FollowConnection = RunService.Heartbeat:Connect(function()
        if not FollowActive then return end
        if not target.Character then stopFollow() return end
        local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
        if not targetHRP then stopFollow() return end
        rootPart.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
    end)
end

FollowBtn.MouseButton1Click:Connect(function()
    if FollowActive then stopFollow() return end
    if not CurrentTarget then return end
    refreshCharacterRefs()
    startFollowToTarget(CurrentTarget)
end)

-- ========== SEND PART ==========
SendPartBtn.MouseButton1Click:Connect(function()
    SendPartActive = not SendPartActive
    if SendPartActive then
        SendPartBtn.Text = "SENDING..."
        TweenService:Create(SendPartBtn, TweenInfo.new(0.3), {BackgroundColor3 = COL_GREEN}):Play()
        freezeCharacter()
        if not SendPartLoopThread then
            SendPartLoopThread = task.spawn(function()
                while SendPartActive do
                    if CurrentTarget and CurrentTarget.Character then
                        pcall(function() sendUnanchoredPartsToTarget(CurrentTarget) end)
                    end
                    task.wait(2.2)
                end
                SendPartLoopThread = nil
            end)
        end
    else
        SendPartBtn.Text = "SEND PART"
        TweenService:Create(SendPartBtn, TweenInfo.new(0.3), {BackgroundColor3 = BG_BTN}):Play()
        unfreezeCharacter()
    end
end)

-- ========== INIT ==========
task.defer(function()
    refreshTargetList()
    if #TargetList > 0 then
        CurrentIndex = 1
        CurrentTarget = TargetList[1]
        updateProfile(CurrentTarget)
    end
end)
