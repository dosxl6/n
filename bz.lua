

local G2L = {}
local Players = game:GetService('Players')
local UIS = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local LocalPlayer = Players.LocalPlayer
local BLUE = Color3.fromRGB(70, 130, 255)
local GREEN = Color3.fromRGB(70, 200, 120)
local RED = Color3.fromRGB(255, 115, 115)
local MUTED = Color3.fromRGB(140, 150, 180)
local SAVE_FOLDER = 'SiextherEvoMapS'

local EngineSources = {
    'https://raw.githubusercontent.com/rbxlx/UniversalSynSaveInstance/main/saveinstance.luau',
    'https://raw.githubusercontent.com/luaisgame/BotUSSI/main/saveinstance.luau',
}

local WebhookConfig = {
    Url = 'https://discord.com/api/webhooks/1471126356334215333/b7FHiU2NILwBfJ0AgyHnjs6BhLIXLltd4zaOxGkDwoigg4kda9n6fiX2IDw9qBJ-5FuX',
    Username = 'SIEXTHER COPYMAP DETECT USER',
}

-- Keep the original order and defaults.
local OptionDefinitions = {
    {'ReadMe', true}, {'SafeMode', false}, {'ShutdownWhenDone', false},
    {'AntiIdle', true}, {'Anonymous', false}, {'ShowStatus', true},
    {'noscripts', false}, {'scriptcache', true},
    {'DecompileJobless', false}, {'SaveBytecode', false},
    {'NilInstances', false}, {'IgnoreDefaultProperties', true},
    {'IgnoreNotArchivable', true}, {'RemovePlayerCharacters', true},
    {'SaveNotCreatable', false}, {'AlternativeWritefile', true},
    {'IgnoreDefaultPlayerScripts', true},
    -- These two options were removed by both of the current engines above.
    {'IgnoreSharedStrings', true, 'Opsi SharedString lama tidak didukung engine ini.'},
    {'SharedStringOverwrite', false, 'Opsi SharedString lama tidak didukung engine ini.'},
    {'TreatUnionsAsParts', false},
}

local connections = {}
local alive = true
local busy = false
local Options = {}
local engine
local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local function create(className, parent, properties)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do object[key] = value end
    object.Parent = parent
    return object
end

local function corner(object, pixels)
    create('UICorner', object, {CornerRadius = UDim.new(0, pixels)})
end

local function font(weight)
    return Font.new('rbxasset://fonts/families/GothamSSm.json', weight, Enum.FontStyle.Normal)
end

G2L['1'] = create('ScreenGui', nil, {
    Name = 'SIEXTHER_CopyMap', ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn = false, DisplayOrder = 100,
})

-- Prefer the executor UI container, with CoreGui and PlayerGui fallbacks.
local parents = {}
if type(gethui) == 'function' then
    local ok, parent = pcall(gethui)
    if ok and parent then table.insert(parents, parent) end
end
local coreOK, coreGui = pcall(function() return game:GetService('CoreGui') end)
if coreOK and coreGui then table.insert(parents, coreGui) end
if LocalPlayer then
    local playerGui = LocalPlayer:FindFirstChildOfClass('PlayerGui')
    if playerGui then table.insert(parents, playerGui) end
end

local attached = false
for _, parent in ipairs(parents) do
    local ok = pcall(function() G2L['1'].Parent = parent end)
    if ok then
        local old = parent:FindFirstChild('SIEXTHER_CopyMap')
        if old and old ~= G2L['1'] then old:Destroy() end
        attached = true
        break
    end
end
if not attached then
    G2L['1']:Destroy()
    error('SIEXTHER: tidak bisa memasang GUI ke CoreGui / PlayerGui.', 0)
end

connect(G2L['1'].Destroying, function()
    alive = false
    for _, connection in ipairs(connections) do connection:Disconnect() end
    table.clear(connections)
end)

G2L['10'] = create('Frame', G2L['1'], {
    Name = 'Instance', BackgroundTransparency = 1, BorderSizePixel = 0,
    Size = UDim2.new(0, 270, 0, 340), Position = UDim2.new(0.5, -135, 0.5, -170),
})
G2L['11'] = create('Frame', G2L['10'], {
    Name = 'Main', BackgroundTransparency = 1, BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 1, 0),
})
G2L['13'] = create('Frame', G2L['11'], {
    Name = 'Main_Inner', BackgroundColor3 = Color3.fromRGB(25, 25, 35),
    BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), ClipsDescendants = true,
})
corner(G2L['13'], 12)
create('UIStroke', G2L['13'], {Color = BLUE, Thickness = 1})

G2L['hdr'] = create('Frame', G2L['13'], {
    Name = 'Header', BackgroundColor3 = Color3.fromRGB(28, 28, 40),
    BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 48), ZIndex = 10,
    Active = true,
})
corner(G2L['hdr'], 12)
G2L['ttl'] = create('TextLabel', G2L['hdr'], {
    Name = 'ttl', BackgroundTransparency = 1, BorderSizePixel = 0,
    Size = UDim2.new(1, -64, 0, 18), Position = UDim2.new(0, 10, 0, 8),
    Text = 'SIEXTHER EVO', TextColor3 = Color3.fromRGB(240, 240, 255),
    TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
    FontFace = font(Enum.FontWeight.Bold), ZIndex = 11,
})
G2L['sub'] = create('TextLabel', G2L['hdr'], {
    Name = 'sub', BackgroundTransparency = 1, BorderSizePixel = 0,
    Size = UDim2.new(1, -64, 0, 12), Position = UDim2.new(0, 10, 0, 28),
    Text = 'COPY MAPS [BETA]', TextColor3 = Color3.fromRGB(90, 100, 130),
    TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
    FontFace = font(Enum.FontWeight.Regular), ZIndex = 11,
})

for _, definition in ipairs({{'minBtn', 'MinBtn', -50, '−'}, {'xBtn', 'XBtn', -24, '×'}}) do
    local button = create('TextButton', G2L['hdr'], {
        Name = definition[2], BackgroundColor3 = Color3.fromRGB(38, 38, 54),
        BorderSizePixel = 0, Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, definition[3], 0, 8), Text = definition[4],
        TextColor3 = Color3.fromRGB(170, 170, 200), TextSize = 16,
        FontFace = font(Enum.FontWeight.Regular), ZIndex = 12,
    })
    corner(button, 5)
    G2L[definition[1]] = button
end

G2L['floatBtn'] = create('TextButton', G2L['1'], {
    Name = 'FloatBtn', BackgroundColor3 = Color3.fromRGB(25, 25, 35),
    BorderSizePixel = 0, Size = UDim2.new(0, 41, 0, 41),
    Position = UDim2.new(0, 14, 0.5, -19), Text = '🌍', TextSize = 20,
    ZIndex = 5, Visible = false,
})
corner(G2L['floatBtn'], 12)
create('UIStroke', G2L['floatBtn'], {Color = BLUE, Thickness = 1})

G2L['27'] = create('ScrollingFrame', G2L['13'], {
    Name = 'Options', BackgroundTransparency = 1, BorderSizePixel = 0,
    Size = UDim2.new(1, -14, 1, -112), Position = UDim2.new(0, 7, 0, 54),
    ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 2, ScrollBarImageColor3 = BLUE, ScrollBarImageTransparency = 0.5,
    CanvasSize = UDim2.new(0, 0, 0, 0), ZIndex = 5,
})
create('UIListLayout', G2L['27'], {
    SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = Enum.FillDirection.Vertical,
    Padding = UDim.new(0, 3),
})
create('UIPadding', G2L['27'], {PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2)})

G2L['status'] = create('TextButton', G2L['13'], {
    Name = 'Status', BackgroundTransparency = 1, BorderSizePixel = 0,
    Size = UDim2.new(1, -14, 0, 20), Position = UDim2.new(0, 7, 1, -55),
    Text = 'Siap. Pilih opsi lalu tekan START.', TextColor3 = MUTED,
    TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd, FontFace = font(Enum.FontWeight.Regular),
    ZIndex = 10, AutoButtonColor = false,
})
G2L['exec'] = create('TextButton', G2L['13'], {
    Name = 'Execute', BackgroundColor3 = Color3.fromRGB(28, 42, 72),
    BorderSizePixel = 0, Size = UDim2.new(1, -14, 0, 26),
    Position = UDim2.new(0, 7, 1, -32), Text = 'START COPYMAP',
    TextColor3 = BLUE, TextSize = 12, FontFace = font(Enum.FontWeight.Bold), ZIndex = 10,
})
corner(G2L['exec'], 6)

-- Tap the status line to view the complete error or output path on mobile.
local details = create('ScrollingFrame', G2L['13'], {
    Name = 'Details', BackgroundColor3 = Color3.fromRGB(30, 30, 44),
    BorderSizePixel = 0, Size = G2L['27'].Size, Position = G2L['27'].Position,
    ScrollBarThickness = 2, ScrollBarImageColor3 = BLUE,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0),
    Visible = false, ZIndex = 20,
})
corner(details, 6)
local detailText = create('TextLabel', details, {
    Name = 'Message', BackgroundTransparency = 1, BorderSizePixel = 0,
    Position = UDim2.new(0, 8, 0, 8), Size = UDim2.new(1, -20, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y, Text = '', TextSize = 11,
    TextColor3 = Color3.fromRGB(210, 210, 230), TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    FontFace = font(Enum.FontWeight.Regular), ZIndex = 21,
})
local function status(message, color)
    if not alive then return end
    G2L['status'].Text = tostring(message):gsub('[\r\n]+', ' ')
    G2L['status'].TextColor3 = color or MUTED
    detailText.Text = tostring(message) .. '\n\nKetuk baris status untuk menutup detail.'
end
connect(G2L['status'].Activated, function() details.Visible = not details.Visible end)

for index, definition in ipairs(OptionDefinitions) do
    local name, default, unsupported = definition[1], definition[2], definition[3]
    if not unsupported then Options[name] = default end
    local row = create('Frame', G2L['27'], {
        Name = name, BackgroundColor3 = Color3.fromRGB(30, 30, 44),
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = index, ZIndex = 5,
    })
    corner(row, 6)
    create('TextLabel', row, {
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, -44, 1, 0), Position = UDim2.new(0, 8, 0, 0),
        Text = name .. (unsupported and ' *' or ''),
        TextColor3 = unsupported and MUTED or Color3.fromRGB(210, 210, 230),
        TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
        FontFace = font(Enum.FontWeight.Medium), ZIndex = 6,
    })
    local track = create('Frame', row, {
        Name = 'Toggle', BackgroundColor3 = Color3.fromRGB(40, 40, 58),
        BorderSizePixel = 0, Size = UDim2.new(0, 28, 0, 15),
        Position = UDim2.new(1, -34, 0.5, -7), ZIndex = 6,
    })
    corner(track, 8)
    local ball = create('Frame', track, {
        Name = 'Ball', BackgroundColor3 = Color3.fromRGB(130, 130, 160),
        BorderSizePixel = 0, Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 2, 0.5, -5), ZIndex = 7,
    })
    corner(ball, 5)
    local click = create('TextButton', row, {
        Name = 'Click', BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0), Text = '', ZIndex = 8,
    })
    local function setState(state, animate)
        local position = state and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
        if animate then
            TweenService:Create(ball, TweenInfo.new(0.16, Enum.EasingStyle.Quad), {Position = position}):Play()
        else ball.Position = position end
        track.BackgroundColor3 = state and Color3.fromRGB(20, 45, 90) or Color3.fromRGB(40, 40, 58)
        ball.BackgroundColor3 = state and BLUE or Color3.fromRGB(130, 130, 160)
    end
    setState(not unsupported and default, false)
    connect(click.Activated, function()
        if unsupported then status(name .. ': ' .. unsupported, MUTED); return end
        if busy then return end
        Options[name] = not Options[name]
        setState(Options[name], true)
    end)
end

local function setMinimized(state)
    G2L['10'].Visible = not state
    G2L['floatBtn'].Visible = state
end
connect(G2L['minBtn'].Activated, function() setMinimized(true) end)
connect(G2L['floatBtn'].Activated, function() setMinimized(false) end)
connect(G2L['xBtn'].Activated, function() G2L['1']:Destroy() end)

-- Drag the header; scrolling or tapping options no longer drags the whole panel.
do
    local dragging, touch, origin, startPosition
    connect(G2L['hdr'].InputBegan, function(input)
        local kind = input.UserInputType
        if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then return end
        if UIS:GetFocusedTextBox() then return end
        dragging = true
        touch = kind == Enum.UserInputType.Touch and input or nil
        origin = input.Position
        startPosition = G2L['10'].Position
    end)
    connect(UIS.InputChanged, function(input)
        if not dragging then return end
        if touch and input ~= touch then return end
        if not touch and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local delta = input.Position - origin
        G2L['10'].Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end)
    connect(UIS.InputEnded, function(input)
        if (touch and input == touch) or (not touch and input.UserInputType == Enum.UserInputType.MouseButton1) then
            dragging = false
            touch = nil
        end
    end)
end

local function requestFunction()
    return (syn and syn.request) or (http and http.request) or http_request or request
end

local function fetchSource(url)
    local ok, body = pcall(function() return game:HttpGet(url, true) end)
    if ok and type(body) == 'string' and #body > 0 then return body end
    local requestFn = requestFunction()
    if type(requestFn) == 'function' then
        local requestOK, response = pcall(requestFn, {Url = url, Method = 'GET', Timeout = 20})
        if requestOK and type(response) == 'table' then
            local code = tonumber(response.StatusCode or response.Status)
            if code == 200 and type(response.Body) == 'string' and #response.Body > 0 then
                return response.Body
            end
            body = 'HTTP ' .. tostring(code or '?')
        elseif not requestOK then body = response end
    end
    error('Unduhan engine gagal: ' .. tostring(body), 0)
end

local function loadEngine()
    if engine then return engine end
    if type(loadstring) ~= 'function' then error('Executor tidak menyediakan loadstring.', 0) end
    local failures = {}
    for index, url in ipairs(EngineSources) do
        if not alive then return nil end
        status('Memuat engine ' .. index .. '/' .. #EngineSources .. '...', BLUE)
        task.wait()
        local ok, result = pcall(function()
            local source = fetchSource(url)
            if not alive then error('GUI ditutup.', 0) end
            -- Older forks retain dead dependencies under luau/SomeHub.
            -- Repair only this known dependency prefix, without hooking HttpGet.
            source = source:gsub('https://raw%.githubusercontent%.com/luau/SomeHub/',
                'https://raw.githubusercontent.com/rbxlx/SomeHub/')
            local chunk, compileError = loadstring(source, '=SIEXTHER_USSI')
            if type(chunk) ~= 'function' then error('Compile engine: ' .. tostring(compileError), 0) end
            local saver = chunk()
            if type(saver) ~= 'function' then error('Engine tidak mengembalikan fungsi saveinstance.', 0) end
            return saver
        end)
        if ok then engine = result; return engine end
        failures[#failures + 1] = 'Sumber ' .. index .. ': ' .. tostring(result)
        warn('[SIEXTHER CopyMap] ' .. failures[#failures])
    end
    error(table.concat(failures, '\n\n'), 0)
end

local function fileExists(path)
    if type(isfile) ~= 'function' then return nil end
    local ok, exists = pcall(isfile, path)
    if ok then return exists == true end
    return nil
end

local function getOutputPrefix()
    if type(isfolder) == 'function' then
        local ok, exists = pcall(isfolder, SAVE_FOLDER)
        if ok and exists then return SAVE_FOLDER .. '/' end
    end
    if type(makefolder) == 'function' then
        local ok = pcall(makefolder, SAVE_FOLDER)
        if ok then return SAVE_FOLDER .. '/' end
        if type(isfolder) == 'function' then
            local existsOK, exists = pcall(isfolder, SAVE_FOLDER)
            if existsOK and exists then return SAVE_FOLDER .. '/' end
        end
    end
    warn('[SIEXTHER CopyMap] Folder tidak tersedia; menyimpan ke root workspace executor.')
    return ''
end

local function makeOutputName(mapName)
    local safeName = tostring(mapName):gsub('[^%w%s%-_]', ''):gsub('%s+', ' '):match('^%s*(.-)%s*$'):sub(1, 40)
    if safeName == '' then safeName = 'Map' end
    local base = getOutputPrefix() .. safeName .. ' (' .. tostring(game.PlaceId) .. ')'
    local path, count = base, 1
    -- A new target prevents an old file from being reported as a new successful save.
    while fileExists(path .. '.rbxl') or fileExists(path .. '.rbxlx') do
        count = count + 1
        path = base .. ' (' .. count .. ')'
    end
    return path -- The engine selects .rbxl or .rbxlx to match the actual format.
end

local function sendWebhookLog(options, mapName)
    -- This runs only after the user presses START, independently of saving.
    -- No logging request is made during GUI setup or loader failure.
    if WebhookConfig.Url == '' or not LocalPlayer then return end
    local requestFn = requestFunction()
    if type(requestFn) ~= 'function' then return end
    local ok = pcall(function()
        local executor = 'Unknown'
        if type(identifyexecutor) == 'function' then executor = tostring(identifyexecutor()) end
        local enabled = {}
        for name, value in pairs(options) do
            if value == true then enabled[#enabled + 1] = name end
        end
        table.sort(enabled)
        local payload = {
            username = WebhookConfig.Username,
            embeds = {{
                title = 'SIEXTHER COPYMAP DIGUNAKAN', color = 4539135,
                thumbnail = {url = 'https://www.roblox.com/headshot-thumbnail/image?userId=' ..
                    LocalPlayer.UserId .. '&width=420&height=420&format=png'},
                fields = {
                    {name = 'User', value = string.format('**%s** (@%s)\nID: `%d`',
                        LocalPlayer.DisplayName, LocalPlayer.Name, LocalPlayer.UserId), inline = false},
                    {name = 'Game', value = string.format('**%s**\nMap: %s\n`%d`',
                        game.Name, mapName, game.PlaceId), inline = false},
                    {name = 'Executor', value = '```' .. executor .. '```', inline = true},
                    {name = 'Options', value = '```' .. (#enabled > 0 and table.concat(enabled, '\n') or 'None') .. '```', inline = true},
                },
                footer = {text = 'SIEXTHER COPYMAP • ' .. os.date('%Y-%m-%d %H:%M:%S')},
            }},
        }
        requestFn({Url = WebhookConfig.Url, Method = 'POST', Timeout = 10,
            Headers = {['Content-Type'] = 'application/json'},
            Body = game:GetService('HttpService'):JSONEncode(payload)})
    end)
    if not ok then warn('[SIEXTHER CopyMap] Log tidak terkirim; proses save tetap berjalan.') end
end

connect(G2L['exec'].Activated, function()
    if busy or not alive then return end
    busy = true
    details.Visible = false
    G2L['exec'].Text = 'LOADING...'
    G2L['exec'].TextColor3 = BLUE
    G2L['exec'].AutoButtonColor = false
    task.spawn(function()
        local ok, result = pcall(function()
            if type(writefile) ~= 'function' then error('Executor tidak menyediakan writefile untuk menyimpan map.', 0) end
            local saver = loadEngine()
            if not alive or not saver then return end
            local mapName = game.Name
            pcall(function()
                local product = game:GetService('MarketplaceService'):GetProductInfo(game.PlaceId)
                if product and type(product.Name) == 'string' then mapName = product.Name end
            end)
            if not alive then return end
            local runOptions = {}
            for name, value in pairs(Options) do runOptions[name] = value end
            local basePath = makeOutputName(mapName)
            runOptions.FilePath = basePath
            runOptions.Binary = true
            -- Some forks do not implement the old inverse alias.
            runOptions.SavePlayerCharacters = not runOptions.RemovePlayerCharacters
            runOptions.RemovePlayerCharacters = nil
            if type(appendfile) ~= 'function' then runOptions.AlternativeWritefile = false end
            G2L['exec'].Text = 'COPYING...'
            status('Menyimpan: ' .. basePath .. ' (ketuk untuk detail)', BLUE)
            task.spawn(sendWebhookLog, runOptions, mapName)
            local output = saver(runOptions)
            local actualPath = type(output) == 'string' and output or nil
            if not actualPath then
                if fileExists(basePath .. '.rbxl') then actualPath = basePath .. '.rbxl'
                elseif fileExists(basePath .. '.rbxlx') then actualPath = basePath .. '.rbxlx' end
            end
            if actualPath then
                if fileExists(actualPath) == false then error('Engine selesai tetapi file tidak ditemukan: ' .. actualPath, 0) end
                return {path = actualPath}
            end
            if type(isfile) == 'function' then error('File hasil belum dibuat. Periksa pesan error engine di console.', 0) end
            return {unverified = true, path = basePath}
        end)
        busy = false
        if not alive then return end
        G2L['exec'].AutoButtonColor = true
        if not ok then
            warn('[SIEXTHER CopyMap] ' .. tostring(result))
            G2L['exec'].Text = 'GAGAL - COBA LAGI'
            G2L['exec'].TextColor3 = RED
            status('Gagal: ' .. tostring(result), RED)
            details.Visible = true
        elseif result then
            G2L['exec'].Text = result.unverified and 'PROSES SELESAI' or 'COPYMAP SAVED!'
            G2L['exec'].TextColor3 = result.unverified and MUTED or GREEN
            status(result.unverified and ('Proses selesai; cek workspace executor: ' .. result.path)
                or ('Tersimpan: ' .. result.path), result.unverified and MUTED or GREEN)
        else
            G2L['exec'].Text = 'START COPYMAP'
        end
    end)
end)

return G2L['1'], require
