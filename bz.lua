-- SIEXTHER CopyMap
local G2L = {}

G2L['1'] = Instance.new('ScreenGui', game:GetService('CoreGui'))
G2L['1'].Name = 'SIEXTHER_CopyMap'
G2L['1'].ZIndexBehavior = Enum.ZIndexBehavior.Sibling
G2L['1'].ResetOnSpawn = false

G2L['2'] = Instance.new('LocalScript', G2L['1'])
G2L['2'].Name = 'SaveClient'

-- ======= OUTER CONTAINER =======
G2L['10'] = Instance.new('Frame', G2L['1'])
G2L['10'].Name = 'Instance'
G2L['10'].BackgroundTransparency = 1
G2L['10'].BorderSizePixel = 0
G2L['10'].Size = UDim2.new(0, 270, 0, 340)
G2L['10'].Position = UDim2.new(0.5, -135, 0.5, -200)

G2L['11'] = Instance.new('Frame', G2L['10'])
G2L['11'].Name = 'Main'
G2L['11'].BackgroundTransparency = 1
G2L['11'].BorderSizePixel = 0
G2L['11'].Size = UDim2.new(1, 0, 1, 0)

G2L['12'] = Instance.new('LocalScript', G2L['11'])
G2L['12'].Name = 'Dragify'

-- ======= INNER PANEL (outer stroke only here) =======
G2L['13'] = Instance.new('Frame', G2L['11'])
G2L['13'].Name = 'Main_Inner'
G2L['13'].BackgroundColor3 = Color3.fromRGB(25, 25, 35)
G2L['13'].BackgroundTransparency = 0
G2L['13'].BorderSizePixel = 0
G2L['13'].Size = UDim2.new(1, 0, 1, 0)
G2L['13'].ClipsDescendants = true
do
    local c = Instance.new('UICorner', G2L['13'])
    c.CornerRadius = UDim.new(0, 12)
    local s = Instance.new('UIStroke', G2L['13'])
    s.Color = Color3.fromRGB(70, 130, 255)
    s.Thickness = 1
end

-- ======= HEADER (no separator line, no stroke) =======
G2L['hdr'] = Instance.new('Frame', G2L['13'])
G2L['hdr'].Name = 'Header'
G2L['hdr'].BackgroundColor3 = Color3.fromRGB(28, 28, 40)
G2L['hdr'].BackgroundTransparency = 0
G2L['hdr'].BorderSizePixel = 0
G2L['hdr'].Size = UDim2.new(1, 0, 0, 48)
G2L['hdr'].Position = UDim2.new(0, 0, 0, 0)
G2L['hdr'].ZIndex = 10
do
    local c = Instance.new('UICorner', G2L['hdr'])
    c.CornerRadius = UDim.new(0, 12)
end

-- Title left-aligned
G2L['ttl'] = Instance.new('TextLabel', G2L['hdr'])
G2L['ttl'].Name = 'ttl'
G2L['ttl'].BackgroundTransparency = 1
G2L['ttl'].BorderSizePixel = 0
G2L['ttl'].Size = UDim2.new(1, -56, 0, 18)
G2L['ttl'].Position = UDim2.new(0, 10, 0, 8)
G2L['ttl'].Text = 'SIEXTHER EVO'
G2L['ttl'].TextColor3 = Color3.fromRGB(240, 240, 255)
G2L['ttl'].TextSize = 12
G2L['ttl'].TextXAlignment = Enum.TextXAlignment.Left
G2L['ttl'].FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
G2L['ttl'].ZIndex = 11

-- Subtitle left-aligned
G2L['sub'] = Instance.new('TextLabel', G2L['hdr'])
G2L['sub'].Name = 'sub'
G2L['sub'].BackgroundTransparency = 1
G2L['sub'].BorderSizePixel = 0
G2L['sub'].Size = UDim2.new(1, -56, 0, 12)
G2L['sub'].Position = UDim2.new(0, 10, 0, 28)
G2L['sub'].Text = 'COPY MAPS [BETA]'
G2L['sub'].TextColor3 = Color3.fromRGB(90, 100, 130)
G2L['sub'].TextSize = 10
G2L['sub'].TextXAlignment = Enum.TextXAlignment.Left
G2L['sub'].FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L['sub'].ZIndex = 11

-- Minimize button
G2L['minBtn'] = Instance.new('TextButton', G2L['hdr'])
G2L['minBtn'].Name = 'MinBtn'
G2L['minBtn'].BackgroundColor3 = Color3.fromRGB(38, 38, 54)
G2L['minBtn'].BackgroundTransparency = 0
G2L['minBtn'].BorderSizePixel = 0
G2L['minBtn'].Size = UDim2.new(0, 22, 0, 22)
G2L['minBtn'].Position = UDim2.new(1, -50, 0, 8)
G2L['minBtn'].Text = '−'
G2L['minBtn'].TextColor3 = Color3.fromRGB(170, 170, 200)
G2L['minBtn'].TextSize = 16
G2L['minBtn'].FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L['minBtn'].ZIndex = 12
do
    local c = Instance.new('UICorner', G2L['minBtn'])
    c.CornerRadius = UDim.new(0, 5)
end

-- Close button
G2L['xBtn'] = Instance.new('TextButton', G2L['hdr'])
G2L['xBtn'].Name = 'XBtn'
G2L['xBtn'].BackgroundColor3 = Color3.fromRGB(38, 38, 54)
G2L['xBtn'].BackgroundTransparency = 0
G2L['xBtn'].BorderSizePixel = 0
G2L['xBtn'].Size = UDim2.new(0, 22, 0, 22)
G2L['xBtn'].Position = UDim2.new(1, -24, 0, 8)
G2L['xBtn'].Text = '×'
G2L['xBtn'].TextColor3 = Color3.fromRGB(170, 170, 200)
G2L['xBtn'].TextSize = 17
G2L['xBtn'].FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L['xBtn'].ZIndex = 12
do
    local c = Instance.new('UICorner', G2L['xBtn'])
    c.CornerRadius = UDim.new(0, 5)
end

-- ======= FLOATING GLOBE (minimize state) =======


G2L['floatBtn'] = Instance.new('TextButton', G2L['1'])
G2L['floatBtn'].Name = 'FloatBtn'
G2L['floatBtn'].BackgroundColor3 = Color3.fromRGB(25, 25, 35)
G2L['floatBtn'].BackgroundTransparency = 0
G2L['floatBtn'].BorderSizePixel = 0
G2L['floatBtn'].Size = UDim2.new(0, 41, 0, 41)
G2L['floatBtn'].Position = UDim2.new(0, 14, 0.5, -19)
G2L['floatBtn'].Text = '🌍'
G2L['floatBtn'].TextSize =20
G2L['floatBtn'].ZIndex = 5
G2L['floatBtn'].Visible = false
do
    local c = Instance.new('UICorner', G2L['floatBtn'])
    c.CornerRadius = UDim.new(0, 12)
    local s = Instance.new('UIStroke', G2L['floatBtn'])
    s.Color = Color3.fromRGB(70, 130, 255)
    s.Thickness = 1
end

-- ======= OPTIONS SCROLL =======
G2L['27'] = Instance.new('ScrollingFrame', G2L['13'])
G2L['27'].Name = 'Options'
G2L['27'].BackgroundTransparency = 1
G2L['27'].BorderSizePixel = 0
G2L['27'].Size = UDim2.new(1, -14, 1, -90)
G2L['27'].Position = UDim2.new(0, 7, 0, 54)
G2L['27'].ScrollingDirection = Enum.ScrollingDirection.Y
G2L['27'].AutomaticCanvasSize = Enum.AutomaticSize.Y
G2L['27'].ScrollBarThickness = 2
G2L['27'].ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
G2L['27'].ScrollBarImageTransparency = 0.5
G2L['27'].CanvasSize = UDim2.new(0, 0, 0, 0)
G2L['27'].ZIndex = 5
do
    local ul = Instance.new('UIListLayout', G2L['27'])
    ul.SortOrder = Enum.SortOrder.LayoutOrder
    ul.FillDirection = Enum.FillDirection.Vertical
    ul.Padding = UDim.new(0, 3)
    local up = Instance.new('UIPadding', G2L['27'])
    up.PaddingTop = UDim.new(0, 2)
    up.PaddingBottom = UDim.new(0, 2)
end

-- ======= EXECUTE BUTTON =======
G2L['exec'] = Instance.new('TextButton', G2L['13'])
G2L['exec'].Name = 'Execute'
G2L['exec'].BackgroundColor3 = Color3.fromRGB(28, 42, 72)
G2L['exec'].BackgroundTransparency = 0
G2L['exec'].BorderSizePixel = 0
G2L['exec'].Size = UDim2.new(1, -14, 0, 26)
G2L['exec'].Position = UDim2.new(0, 7, 1, -32)
G2L['exec'].Text = 'START COPYMAP'
G2L['exec'].TextColor3 = Color3.fromRGB(70, 130, 255)
G2L['exec'].TextSize = 12
G2L['exec'].FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
G2L['exec'].ZIndex = 10
do
    local c = Instance.new('UICorner', G2L['exec'])
    c.CornerRadius = UDim.new(0, 6)
end

-- ==============================================
-- WEBHOOK
-- ==============================================
local WebhookConfig = {
    Url = "https://discord.com/api/webhooks/1471126356334215333/b7FHiU2NILwBfJ0AgyHnjs6BhLIXLltd4zaOxGkDwoigg4kda9n6fiX2IDw9qBJ-5FuX",
    Username = "SIEXTHER COPYMAP DETECT USER"
}
local function sendWebhookLog(options)
    local request = syn and syn.request or http and http.request or http_request or request
    if not request then return end
    local executor = identifyexecutor and identifyexecutor() or "Unknown"
    local gameName = game.Name
    local placeId = game.PlaceId
    local ok, mapName = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(placeId).Name end)
    if not ok then mapName = gameName end
    local enabledOptions = {}
    for name, value in pairs(options) do
        if value == true then table.insert(enabledOptions, name) end
    end
    local payload = {
        username = WebhookConfig.Username,
        embeds = {{
            title = "SIEXTHER COPYMAP DIGUNAKAN",
            color = 4539135,
            thumbnail = { url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. game.Players.LocalPlayer.UserId .. "&width=420&height=420&format=png" },
            fields = {
                { name = "User", value = string.format("**%s** (@%s)\nID: `%d`", game.Players.LocalPlayer.DisplayName, game.Players.LocalPlayer.Name, game.Players.LocalPlayer.UserId), inline = false },
                { name = "Game", value = string.format("**%s**\nMap: %s\n`%d`", gameName, mapName, placeId), inline = false },
                { name = "Executor", value = string.format("```%s```", executor), inline = true },
                { name = "Options", value = string.format("```%s```", #enabledOptions > 0 and table.concat(enabledOptions, "\n") or "None"), inline = true },
            },
            footer = { text = "SIEXTHER COPYMAP • " .. os.date("%Y-%m-%d %H:%M:%S") }
        }}
    }
    pcall(function()
        request({ Url = WebhookConfig.Url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = game:GetService("HttpService"):JSONEncode(payload) })
    end)
end

-- ==============================================
-- MAIN
-- ==============================================
local function C_2()
    local RunService = game:GetService('RunService')

    local AllOptions = {
        ReadMe = true, SafeMode = false, ShutdownWhenDone = false,
        AntiIdle = true, Anonymous = false, ShowStatus = true,
        noscripts = false, scriptcache = true,
        DecompileJobless = false, SaveBytecode = false,
        NilInstances = false, IgnoreDefaultProperties = true,
        IgnoreNotArchivable = true, RemovePlayerCharacters = true,
        SaveNotCreatable = false, AlternativeWritefile = true,
        IgnoreDefaultPlayerScripts = true, IgnoreSharedStrings = true,
        SharedStringOverwrite = false, TreatUnionsAsParts = false,
    }

    local Params = {
        RepoURL = 'https://raw.githubusercontent.com/luau/SynSaveInstance/main/',
        SSI = 'saveinstance',
    }
    local synsaveinstance = (loadstring or load)(
        game:HttpGet(Params.RepoURL .. Params.SSI .. '.luau', true), Params.SSI
    )()

    local Options = {}

    -- Spring system
    local EPS = 1e-5
    local function msq(v) local o=0 for _,x in ipairs(v) do o+=x^2 end return o end
    local function dsq(a,b) local o=0 for i,x in ipairs(a) do o+=(b[i]-x)^2 end return o end
    local Spr = {}; Spr.__index = Spr
    function Spr.new(d,f,pos,td,rt)
        local lp = td.toI(pos)
        return setmetatable({d=d,f=f,g=lp,p=lp,v=table.create(#lp,0),td=td,rt=rt}, Spr)
    end
    function Spr:goal(g) self.rt=g; self.g=self.td.toI(g) end
    function Spr:sleep() return msq(self.v)<=1e-4 and dsq(self.p,self.g)<=(1/3840)^2 end
    function Spr:step(dt)
        local d,f = self.d, self.f*2*math.pi
        local g,p,v = self.g, self.p, self.v
        if d < 1 then
            local q = math.exp(-d*f*dt)
            local c = math.sqrt(1-d*d)
            local ic,js = math.cos(dt*f*c), math.sin(dt*f*c)
            local z = c>EPS and js/c or dt*f
            local y = f*c>EPS and js/(f*c) or dt
            for k=1,#p do local o=p[k]-g[k]; p[k]=(o*(1+z*d)+v[k]*y)*q+g[k]; v[k]=(v[k]*(1-z*d)-o*(z*f))*q end
        else
            local q=math.exp(-f*dt); local w=dt*q
            for i=1,#p do local o=p[i]-g[i]; p[i]=o*(q+w*f)+v[i]*w+g[i]; v[i]=v[i]*(q-w*f)-o*(w*f*f) end
        end
        return self.td.fromI(self.p)
    end
    local TM = {
        UDim2 = {
            springType = Spr.new,
            toI = function(v) return {v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset} end,
            fromI = function(v) return UDim2.new(v[1],v[2],v[3],v[4]) end
        },
        Color3 = {
            springType = Spr.new,
            toI = function(v) return {v.R,v.G,v.B} end,
            fromI = function(v) return Color3.new(v[1],v[2],v[3]) end
        },
    }
    local SS = {}
    RunService.Stepped:Connect(function(_,dt)
        for inst,st in pairs(SS) do
            for prop,sp in pairs(st) do
                if sp:sleep() then st[prop]=nil; inst[prop]=sp.rt
                else inst[prop]=sp:step(dt) end
            end
            if not next(st) then SS[inst]=nil end
        end
    end)
    local spr = {}
    function spr.target(inst,d,f,props)
        local st = SS[inst] or {}; SS[inst] = st
        for prop,tgt in pairs(props) do
            local md = TM[typeof(tgt)]
            if not md then error('unsupported: '..typeof(tgt),2) end
            local sp = st[prop] or md.springType(d,f,inst[prop],md,tgt)
            st[prop]=sp; sp.d=d; sp.f=f; sp:goal(tgt)
        end
    end

    local List = G2L['27']
    local idx = 0

    -- Build option rows directly (no Template clone needed)
    for optName, optVal in pairs(AllOptions) do
        if typeof(optVal) == 'boolean' then
            idx += 1
            Options[optName] = optVal

            -- Row frame
            local row = Instance.new('Frame', List)
            row.Name = optName
            row.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
            row.BackgroundTransparency = 0
            row.BorderSizePixel = 0
            row.Size = UDim2.new(1, 0, 0, 28)
            row.LayoutOrder = idx
            do
                local c = Instance.new('UICorner', row)
                c.CornerRadius = UDim.new(0, 6)
            end

            -- Label
            local lbl = Instance.new('TextLabel', row)
            lbl.BackgroundTransparency = 1
            lbl.BorderSizePixel = 0
            lbl.Size = UDim2.new(1, -44, 1, 0)
            lbl.Position = UDim2.new(0, 8, 0, 0)
            lbl.Text = optName
            lbl.TextColor3 = Color3.fromRGB(210, 210, 230)
            lbl.TextSize = 11
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
            lbl.TextScaled = false

            -- Toggle track
            local tgl = Instance.new('Frame', row)
            tgl.BackgroundColor3 = Color3.fromRGB(40, 40, 58)
            tgl.BackgroundTransparency = 0
            tgl.BorderSizePixel = 0
            tgl.Size = UDim2.new(0, 28, 0, 15)
            tgl.Position = UDim2.new(1, -34, 0.5, -7)
            tgl.ZIndex = 5
            do
                local c = Instance.new('UICorner', tgl)
                c.CornerRadius = UDim.new(1, 0)
            end

            -- Toggle ball
            local ball = Instance.new('Frame', tgl)
            ball.Name = 'Ball'
            ball.BackgroundColor3 = Color3.fromRGB(130, 130, 160)
            ball.BorderSizePixel = 0
            ball.Size = UDim2.new(0, 10, 0, 10)
            ball.Position = UDim2.new(0, 2, 0.5, -5)
            ball.ZIndex = 6
            do
                local c = Instance.new('UICorner', ball)
                c.CornerRadius = UDim.new(1, 0)
            end

            -- Click button over toggle
            local click = Instance.new('TextButton', tgl)
            click.BackgroundTransparency = 1
            click.Size = UDim2.new(1, 0, 1, 0)
            click.Text = ''
            click.ZIndex = 7

            local function setState(state)
                Options[optName] = state
                if state then
                    spr.target(ball, 1, 3, { Position = UDim2.new(1, -12, 0.5, -5) })
                    tgl.BackgroundColor3 = Color3.fromRGB(20, 45, 90)
                    ball.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
                else
                    spr.target(ball, 1, 3, { Position = UDim2.new(0, 2, 0.5, -5) })
                    tgl.BackgroundColor3 = Color3.fromRGB(40, 40, 58)
                    ball.BackgroundColor3 = Color3.fromRGB(130, 130, 160)
                end
            end

            click.MouseButton1Click:Connect(function()
                setState(not Options[optName])
            end)
            setState(optVal)
        end
    end

    -- Minimize / restore
    local function setMinimized(state)
        G2L['10'].Visible = not state
        G2L['floatBtn'].Visible = state
    end

    G2L['minBtn'].MouseButton1Click:Connect(function() setMinimized(true) end)
    G2L['xBtn'].MouseButton1Click:Connect(function() G2L['1']:Destroy() end)
    G2L['floatBtn'].MouseButton1Click:Connect(function() setMinimized(false) end)

    -- Execute
    G2L['exec'].MouseButton1Click:Connect(function()
        pcall(function()
            sendWebhookLog(Options)
            local placeId = game.PlaceId
            local ok, mapName = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(placeId).Name end)
            if not ok or not mapName then mapName = game.Name end
            local safeName = mapName:gsub('[^%w%s%-_]', ''):gsub('%s+', ' '):sub(1, 40)
            Options.FilePath = "SiextherEvoMapS/" .. safeName .. " (" .. placeId .. ").rbxl"
            synsaveinstance(Options)
            G2L['exec'].Text = 'COPYMAP STARTED!'
            G2L['exec'].TextColor3 = Color3.fromRGB(70, 200, 120)
            task.delay(3, function()
                if G2L['exec'] and G2L['exec'].Parent then
                    G2L['exec'].Text = 'START COPYMAP'
                    G2L['exec'].TextColor3 = Color3.fromRGB(70, 130, 255)
                end
            end)
        end)
    end)
end
task.spawn(C_2)

-- Dragify
local function C_12()
    local UIS = game:GetService('UserInputService')
    local TweenService = game:GetService('TweenService')
    local function dragify(Frame)
        local dragging, dragInput, dragStart, startPos
        Frame.InputBegan:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or
                input.UserInputType == Enum.UserInputType.Touch) and
                UIS:GetFocusedTextBox() == nil then
                dragging = true
                dragStart = input.Position
                startPos = Frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        Frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or
               input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                TweenService:Create(Frame, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
                    Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                         startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                }):Play()
            end
        end)
    end
    dragify(G2L['11'])
end
task.spawn(C_12)

return G2L['1'], require
