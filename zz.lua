

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local Working_Scripts = 0
local UnWorking_Scripts = 0


local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SxthrUNC"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 220, 0, 280)
Main.Position = UDim2.new(0.5, -110, 0.5, -140)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(70, 130, 255)
MainStroke.Thickness = 1.5
MainStroke.Parent = Main

-- Title bar
local Title = Instance.new("Frame")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 28)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
Title.BorderSizePixel = 0
Title.Active = true
Title.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 10)
TitleFix.Position = UDim2.new(0, 0, 1, -10)
TitleFix.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = Title

local TitleLabel = Instance.new("TextLabel")
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
local CloseButton = Instance.new("TextButton")
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

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Status label (works/failed count)
local StatusLabel = Instance.new("TextLabel")
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
local ScrollFrame = Instance.new("ScrollingFrame")
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

local ScrollCorner = Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(0, 6)
ScrollCorner.Parent = ScrollFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 1)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = ScrollFrame

local ListPadding = Instance.new("UIPadding")
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
    local row = Instance.new("Frame")
    row.Name = name
    row.Size = UDim2.new(1, 0, 0, 18)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order
    row.Parent = ScrollFrame

    local icon = Instance.new("TextLabel")
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.new(0, 18, 1, 0)
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 12
    icon.Parent = row

    local label = Instance.new("TextLabel")
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
    test("Instance", Instance)
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
    test("loadstring", loadstring)
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