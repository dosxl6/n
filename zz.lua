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
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local Working_Scripts = 0
local UnWorking_Scripts = 0


local ScreenGui = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScreenGui")
ScreenGui.Name = "SxthrUNC"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Main = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 220, 0, 280)
Main.Position = UDim2.new(0.5, -110, 0.5, -140)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = Main

local MainStroke = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(70, 130, 255)
MainStroke.Thickness = 1.5
MainStroke.Parent = Main

-- Title bar
local Title = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 28)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
Title.BorderSizePixel = 0
Title.Active = true
Title.Parent = Main

local TitleCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

local TitleFix = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 10)
TitleFix.Position = UDim2.new(0, 0, 1, -10)
TitleFix.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = Title

local TitleLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
TitleLabel.BackgroundTransparency = 1
TitleLabel.Size = UDim2.new(1, -34, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.Text = "Siexther UNC Checker"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Title

-- Close (X) button
local CloseButton = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 22, 0, 22)
CloseButton.Position = UDim2.new(1, -26, 0, 3)
CloseButton.BackgroundColor3 = Color3.fromRGB(35, 35, 46)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 90, 90)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 13
CloseButton.AutoButtonColor = true
CloseButton.Parent = Title

local CloseCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Status label (works/failed count)
local StatusLabel = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.BackgroundTransparency = 1
StatusLabel.Size = UDim2.new(1, -16, 0, 16)
StatusLabel.Position = UDim2.new(0, 8, 0, 32)
StatusLabel.Text = "Menjalankan tes..."
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 195)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Main

-- Scrolling list of results
local ScrollFrame = __SIEXTHER_VIP_GLASS_V1.Instance.new("ScrollingFrame")
ScrollFrame.Name = "ResultList"
ScrollFrame.Size = UDim2.new(1, -16, 1, -56)
ScrollFrame.Position = UDim2.new(0, 8, 0, 50)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 3
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.Parent = Main

local ScrollCorner = __SIEXTHER_VIP_GLASS_V1.Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(0, 6)
ScrollCorner.Parent = ScrollFrame

local ListLayout = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 1)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = ScrollFrame

local ListPadding = __SIEXTHER_VIP_GLASS_V1.Instance.new("UIPadding")
ListPadding.PaddingTop = UDim.new(0, 4)
ListPadding.PaddingLeft = UDim.new(0, 4)
ListPadding.PaddingRight = UDim.new(0, 4)
ListPadding.Parent = ScrollFrame

-- ===== DRAGGING (seluruh Main, drag via Title) =====
local dragging = false
local dragStart = nil
local startPos = nil

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ===== TEST FUNCTION (dengan GUI) =====
local order = 0
local function test(name, func)
    order = order + 1
    local row = __SIEXTHER_VIP_GLASS_V1.Instance.new("Frame")
    row.Name = name
    row.Size = UDim2.new(1, 0, 0, 18)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order
    row.Parent = ScrollFrame

    local icon = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.new(0, 18, 1, 0)
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 12
    icon.Parent = row

    local label = __SIEXTHER_VIP_GLASS_V1.Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 20, 0, 0)
    label.Text = name
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    if func ~= nil then
        icon.Text = "✅"
        icon.TextColor3 = Color3.fromRGB(80, 220, 130)
        Working_Scripts = Working_Scripts + 1
    else
        icon.Text = "📛"
        icon.TextColor3 = Color3.fromRGB(255, 80, 90)
        UnWorking_Scripts = UnWorking_Scripts + 1
    end
end

game.StarterGui:SetCore("DevConsoleVisible", true)

task.spawn(function()
    -- synapse
    test("syn", syn)

    -- default luau
    test("game", game)
    test("game.CoreGui", game.CoreGui)
    test("workspace", workspace)
    test("task", task)
    test("table", table)
    test("string", string)

    -- teleport
    test("Teleport", Teleport)
    test("TeleportAsync", TeleportAsync)
    test("TeleportToPlaceInstance", TeleportToPlaceInstance)

    -- property
    test("sethiddenproperty", sethiddenproperty)
    test("gethiddenproperty", gethiddenproperty)
    test("set_hidden_property", set_hidden_property)
    test("get_hidden_property", get_hiddenp_roperty)
    test("setrenderproperty", setrenderproperty)
    test("getrenderproperty", getrenderproperty)
    test("setsimulationradius", setsimulationradius)
    test("set_simulation_radius", set_simulation_radius)
    test("set_render_property", set_render_property)
    test("get_render_property", get_render_property)

    -- clipboard
    test("setclipboard", setclipboard)
    test("setrbxclipboard", setrbxclipboard)
    test("getclipboard", getclipboard)
    test("toclipboard", toclipboard)
    test("writeclipboard", writeclipboard)
    test("messagebox", messagebox)

    -- files
    test("makefolder", makefolder)
    test("writefile", writefile)
    test("appendfile", appendfile)
    test("loadfile", loadfile)
    test("isfolder", isfolder)
    test("isfile", isfile)
    test("readfile", readfile)
    test("listfiles", listfiles)
    test("dofile", dofile)
    test("delfile", delfile)
    test("delfolder", delfolder)
    test("readprotectedfile", readprotectedfile)
    test("writeprotectedfile", writeprotectedfile)

    -- env
    test("getgenv", getgenv)
    test("getfenv", getfenv)
    test("getsenv", getsenv)
    test("getreg", getreg)
    test("getgc", getgc)
    test("getrenv", getrenv)
    test("setfenv", setfenv)

    -- instances
    test("getinstances", getinstances)
    test("getnilinstances", getnilinstances)
    test("gethiddeninstances", gethiddeninstances)
    test("sethiddeninstances", sethiddeninstances)
    test("compareinstances", compareinstances)

    -- instance
    test("Instance", __SIEXTHER_VIP_GLASS_V1.Instance)
    test("dumpinstance", dumpinstance)
    test("dump_instance", dump_instance)
    test("spoofinstance", spoofinstance)
    test("unspoofinstance", unspoofinstance)
    test("spoof_instance", spoof_instance)
    test("unspoof_instance", unspoof_instance)
    test("hookinstance", hookinstance)
    test("unhookinstance", unhookinstance)
    test("hook_instance", hook_instance)
    test("unhook_instance", unhook_instance)
    test("saveinstance", saveinstance)
    test("save_instance", save_instance)
    test("protectinstance", protectinstance)
    test("unprotectinstance", unprotectinstance)
    test("protect_instance", protect_instance)
    test("unprotect_instance", protect_instance)

    -- console
    test("rconsolesettitle", rconsolesettitle)
    test("rconsoleprint", rconsoleprint)
    test("rconsoleerr", rconsoleerr)
    test("rconsolewarn", rconsolewarn)
    test("rconsolecreate", rconsolecreate)
    test("rconsoledestroy", rconsoledestroy)
    test("rconsoleclear", rconsoleclear)
    test("rconsoleinput", rconsoleinput)
    test("consolesettitle", consolesettitle)
    test("consoleprint", consoleprint)
    test("consoleerr", consoleerr)
    test("consolewarn", consolewarn)
    test("consolecreate", consolecreate)
    test("consoledestroy", consoledestroy)
    test("consoleclear", consoleclear)
    test("consoleinput", consoleinput)

    -- execute
    test("require", require)
    test("loadstring", __SIEXTHER_VIP_GLASS_V1.LoadString)
    test("LoadString", LoadString)

    -- globals
    test("getglobals", getglobals)
    test("setglobals", setglobals)

    -- queue
    test("queueonteleport", queueonteleport)
    test("queue_on_teleport", queue_on_teleport)

    -- networkowner
    test("isnetworkowner", isnetworkowner)
    test("setnetworkowner", setnetworkowner)
    test("getnetworkowner", getnetworkowner)

    -- machine
    test("gethwid", gethwid)
    test("getmachineid", getmachineid)
    test("getfingerprint", getfingerprint)

    -- executor
    test("getexecutorname", getexecutorname)
    test("identifyexecutor", identifyexecutor)

    -- identify
    test("getidentify", getidentify)
    test("setidentify", setidentify)

    -- dump
    test("dumpstring", dumpstring)
    test("decompile", decompile)

    -- active
    test("isgameactive", isgameactive)
    test("isrbxactive", isrbxactive)

    -- threads
    test("getthreadcontext", getthreadcontext)
    test("getthreadidentity", getthreadidentity)
    test("setthreadidentity", setthreadidentity)

    -- asset
    test("getsynasset", getsynasset)
    test("getcustomasset", getcustomasset)
    test("getspecialinfo", getspecialinfo)

    -- modules
    test("getmodules", getmodules)
    test("getmoduleinfo", getmoduleinfo)
    test("getloadedmodules", getloadedmodules)
    test("getthreads", getthreads)

    -- fflag
    test("setfflag", setfflag)
    test("getfflag", getfflag)

    -- fps
    test("setfpscap", setfpscap)
    test("setfps", setfps)
    test("getfps", getfps)

    -- compress
    test("lz4compress", lz4compress)
    test("lz4decompress", lz4decompress)

    -- closure
    test("islclosure", islclosure)
    test("isourclosure", isourclosure)
    test("iscclosure", iscclosure)
    test("newcclosure", newcclosure)
    test("iskrnlclosure", iskrnlclosure)
    test("issynclosure", issynclosure)
    test("is_l_closure", is_l_closure)
    test("isexecclosure", isexecclosure)
    test("isexecutorclosure", isexecutorclosure)
    test("getscriptclosure", getscriptclosure)
    test("checkclosure", checkclosure)
    test("replacesclosure", replacesclosure)

    -- function
    test("hookfunc", hookfunc)
    test("hookfunction", hookfunction)
    test("ishooked", ishooked)
    test("isfunctionhooked", isfunctionhooked)
    test("clonefunction", clonefunction)
    test("clonefunc", clonefunc)
    test("restorefunction", restorefunction)
    test("is_exploit_function", is_exploit_function)
    test("is_synapse_function", is_synapse_function)
    test("getfunctionhash", getfunctionhash)

    -- script
    test("getscripts", getscripts)
    test("get_scripts", get_scripts)
    test("setscriptable", setscriptable)
    test("isscriptable", isscriptable)
    test("getcallingscript", getcallingscript)
    test("getrunningscripts", getrunningscripts)
    test("getscripthash", getscripthash)
    test("setscriptbytecode", setscriptbytecode)
    test("getscriptbytecode", getscriptbytecode)
    test("restorescriptbytecode", restorescriptbytecode)

    -- gui
    test("getprotectedguis", getprotectedguis)
    test("protectgui", protectgui)
    test("unprotectgui", unprotectgui)
    test("protect_gui", protect_gui)
    test("unprotect_gui", unprotect_gui)
    test("sethui", sethui)
    test("gethui", gethui)

    -- fire
    test("fireserver", fireserver)
    test("fireclient", fireclient)
    test("firesignal", firesignal)
    test("fireclickdetector", fireclickdetector)
    test("fireproximityprompt", fireproximityprompt)
    test("firetouchinterest", firetouchinterest)
    test("replicatesignal", replicatesignal)
    test("cansignalreplicate", cansignalreplicate)
    test("getsignalarguments", getsignalarguments)

    -- metatable
    test("getmetatable", getmetatable)
    test("setmetatable", setmetatable)
    test("checkmetatable", checkmetatable)
    test("spoofmetatable", spoofmetatable)
    test("getrawmetatable", getrawmetatable)
    test("setrawmetatable", setrawmetatable)
    test("readonly", readonly)
    test("setreadonly", setreadonly)
    test("isreadonly", isreadonly)
    test("hookmetamethod", hookmetamethod)
    test("unhookmetamethod", unhookmetamethod)

    -- Drawing
    test("Drawing", Drawing)
    test("Drawing.new", Drawing.Fonts)
    test("Drawing.Fonts", Drawing.Fonts)
    test("cleardrawcache", cleardrawcache)
    test("isrenderobj", isrenderobj)

    -- debug
    test("debug", debug)
    test("setupvalue", setupvalue)
    test("getupvalues", getupvalues)
    test("setproto", setproto)
    test("traceback", traceback)
    test("setstack", setstack)
    test("getstack", getstack)
    test("debug.getinfo", debug.getinfo)
    test("debug.setupvalue", debug.setupvalue)
    test("debug.getupvalues", debug.getupvalues)
    test("debug.setproto", debug.setproto)
    test("debug.setstack", debug.setstack)
    test("debug.getstack", debug.getstack)
    test("debug.traceback", debug.traceback)
    test("debug.getmetatable", debug.getmetatable)
    test("debug.setmetatable", debug.setmetatable)
    test("debug.getregistry", debug.getregistry)
    test("debug.getconstants", debug.getconstants)
    test("debug.setconstant", debug.setconstant)

    -- connections
    test("getconnections", getconnections)
    test("disableconnection", disableconnection)
    test("enableconnection", enableconnection)
    test("isconnectionenabled", isconnectionenabled)
    test("disconnect_all_connections", disconnect_all_connections)

    -- mouse
    test("mouse1press", mouse1press)
    test("mouse2press", mouse2press)
    test("mouse1click", mouse1press)
    test("mouse2click", mouse2press)
    test("mouse1release", mouse1release)
    test("mouse2release", mouse2release)
    test("mousescroll", mousescroll)
    test("keypress", keypress)
    test("keyrelease", keyrelease)
    test("mousemove", mousemove)
    test("mousemoveabs", mousemoveabs)
    test("mousemoverel", mousemoverel)

    -- cache
    test("cache", cache)
    test("cache.iscached", cache.iscached)
    test("cache.invalidate", cache.invalidate)
    test("cache.replace", cache.replace)

    -- crypt
    test("crypt", crypt)
    test("crypt.base64decode", crypt.base64decode)
    test("crypt.base64encode", crypt.base64encode)
    test("crypt.decrypt", crypt.decrypt)
    test("crypt.encrypt", crypt.encrypt)

    -- calls
    test("getcaller", getcaller)
    test("checkcaller", checkcaller)
    test("getnamecallmethod", getnamecallmethod)
    test("setnamecallmethod", setnamecallmethod)
    test("getcallbackvalue", getcallbackvalue)
    test("setcallbackvalue", setcallbackvalue)

    -- http
    test("request", request)
    test("http_request", http_request)
    test("HttpGet", HttpGet)
    test("HttpSpy", HttpSpy)
    test("httpget", httpget)
    test("httppost", httppost)
    test("WebSocket", WebSocket)
    test("WebSocket.Connect", WebSocket.Connect)

    StatusLabel.Text = string.format("✅ %d  |  📛 %d  (%.0f%%)", Working_Scripts, UnWorking_Scripts, (Working_Scripts/130)*100)
end)