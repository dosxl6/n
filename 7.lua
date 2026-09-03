

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ModernAudioScanner"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 280)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local outerStroke = Instance.new("UIStroke")
outerStroke.Color = Color3.fromRGB(70, 130, 255)
outerStroke.Thickness = 2
outerStroke.Parent = MainFrame

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 28)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -70, 1, 0)
TitleLabel.Position = UDim2.new(0, 8, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "SIEXTHER AUDIO SCANNER"
TitleLabel.TextColor3 = Color3.fromRGB(70, 130, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "Close"
CloseButton.Size = UDim2.new(0, 24, 0, 20)
CloseButton.Position = UDim2.new(1, -26, 0, 4)
CloseButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 13
CloseButton.BorderSizePixel = 0
CloseButton.Parent = TitleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = CloseButton

-- Minimize Button
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "Minimize"
MinimizeButton.Size = UDim2.new(0, 24, 0, 20)
MinimizeButton.Position = UDim2.new(1, -52, 0, 4)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(50, 130, 180)
MinimizeButton.Text = "–"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 15
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Parent = TitleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 5)
minCorner.Parent = MinimizeButton

-- ScrollingFrame for Audio Logs
local LogsFrame = Instance.new("ScrollingFrame")
LogsFrame.Name = "Logs"
LogsFrame.Size = UDim2.new(1, -16, 1, -68)
LogsFrame.Position = UDim2.new(0, 8, 0, 34)
LogsFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 22)
LogsFrame.BorderSizePixel = 0
LogsFrame.ScrollBarThickness = 4
LogsFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
LogsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
LogsFrame.Parent = MainFrame

local logsCorner = Instance.new("UICorner")
logsCorner.CornerRadius = UDim.new(0, 8)
logsCorner.Parent = LogsFrame

-- Scan Button
local ScanButton = Instance.new("TextButton")
ScanButton.Name = "Scan"
ScanButton.Size = UDim2.new(1, -16, 0, 28)
ScanButton.Position = UDim2.new(0, 8, 1, -33)
ScanButton.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
ScanButton.Text = "SCAN"
ScanButton.TextColor3 = Color3.fromRGB(200, 200, 200)
ScanButton.Font = Enum.Font.GothamBold
ScanButton.TextSize = 12
ScanButton.BorderSizePixel = 0
ScanButton.Parent = MainFrame

local scanCorner = Instance.new("UICorner")
scanCorner.CornerRadius = UDim.new(0, 6)
scanCorner.Parent = ScanButton

local scanStroke = Instance.new("UIStroke")
scanStroke.Color = Color3.fromRGB(50, 55, 65)
scanStroke.Thickness = 1
scanStroke.Parent = ScanButton

-- Loading Bar
local LoadBar = Instance.new("Frame")
LoadBar.Name = "Load"
LoadBar.Size = UDim2.new(0, 0, 0, 2)
LoadBar.Position = UDim2.new(0, 0, 0, 33)
LoadBar.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
LoadBar.BorderSizePixel = 0
LoadBar.Visible = false
LoadBar.Parent = MainFrame

-- Audio Item Template
local AudioTemplate = Instance.new("Frame")
AudioTemplate.Name = "Audio"
AudioTemplate.Size = UDim2.new(1, -10, 0, 26)
AudioTemplate.BackgroundColor3 = Color3.fromRGB(25, 30, 38)
AudioTemplate.BorderSizePixel = 0
AudioTemplate.Visible = false
AudioTemplate.Parent = LogsFrame

local audioCorner = Instance.new("UICorner")
audioCorner.CornerRadius = UDim.new(0, 6)
audioCorner.Parent = AudioTemplate

local AudioIcon = Instance.new("TextLabel")
AudioIcon.Name = "Icon"
AudioIcon.Size = UDim2.new(0, 22, 0, 22)
AudioIcon.Position = UDim2.new(0, 3, 0.5, -11)
AudioIcon.BackgroundTransparency = 1
AudioIcon.Text = "🎵"
AudioIcon.TextSize = 16
AudioIcon.TextColor3 = Color3.fromRGB(135, 206, 250)
AudioIcon.Parent = AudioTemplate

local AudioLabel = Instance.new("TextLabel")
AudioLabel.Name = "TextLabel"
AudioLabel.Size = UDim2.new(1, -60, 1, 0)
AudioLabel.Position = UDim2.new(0, 28, 0, 0)
AudioLabel.BackgroundTransparency = 1
AudioLabel.Text = "Audio Name"
AudioLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
AudioLabel.Font = Enum.Font.Gotham
AudioLabel.TextSize = 10
AudioLabel.TextXAlignment = Enum.TextXAlignment.Left
AudioLabel.TextTruncate = Enum.TextTruncate.AtEnd
AudioLabel.Parent = AudioTemplate

local ClickButton = Instance.new("TextButton")
ClickButton.Name = "Click"
ClickButton.Size = UDim2.new(1, 0, 1, 0)
ClickButton.BackgroundTransparency = 1
ClickButton.Text = ""
ClickButton.Parent = AudioTemplate

-- Info Panel
local InfoPanel = Instance.new("Frame")
InfoPanel.Name = "Info"
InfoPanel.Size = UDim2.new(0, 280, 0, 240)
InfoPanel.Position = UDim2.new(0.5, -140, 0.5, -120)
InfoPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
InfoPanel.BorderSizePixel = 0
InfoPanel.Visible = false
InfoPanel.Parent = ScreenGui

local infoStroke = Instance.new("UIStroke")
infoStroke.Color = Color3.fromRGB(70, 130, 255)
infoStroke.Thickness = 2
infoStroke.Parent = InfoPanel

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 10)
infoCorner.Parent = InfoPanel

local InfoTitle = Instance.new("TextLabel")
InfoTitle.Size = UDim2.new(1, -35, 0, 26)
InfoTitle.Position = UDim2.new(0, 8, 0, 4)
InfoTitle.BackgroundTransparency = 1
InfoTitle.Text = "SIEXTHER AUDIO"
InfoTitle.TextColor3 = Color3.fromRGB(70, 130, 255)
InfoTitle.Font = Enum.Font.GothamBold
InfoTitle.TextSize = 12
InfoTitle.TextXAlignment = Enum.TextXAlignment.Left
InfoTitle.Parent = InfoPanel

local InfoClose = Instance.new("TextButton")
InfoClose.Name = "Close"
InfoClose.Size = UDim2.new(0, 22, 0, 22)
InfoClose.Position = UDim2.new(1, -26, 0, 4)
InfoClose.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
InfoClose.Text = "X"
InfoClose.TextColor3 = Color3.fromRGB(255, 255, 255)
InfoClose.Font = Enum.Font.GothamBold
InfoClose.TextSize = 12
InfoClose.BorderSizePixel = 0
InfoClose.Parent = InfoPanel

local infoCloseCorner = Instance.new("UICorner")
infoCloseCorner.CornerRadius = UDim.new(0, 6)
infoCloseCorner.Parent = InfoClose

local InfoText = Instance.new("TextLabel")
InfoText.Name = "TextLabel"
InfoText.Size = UDim2.new(1, -16, 0, 40)
InfoText.Position = UDim2.new(0, 8, 0, 34)
InfoText.BackgroundColor3 = Color3.fromRGB(15, 18, 22)
InfoText.Text = ""
InfoText.TextColor3 = Color3.fromRGB(200, 200, 200)
InfoText.Font = Enum.Font.GothamBold
InfoText.TextSize = 11
InfoText.TextWrapped = true
InfoText.BorderSizePixel = 0
InfoText.Parent = InfoPanel

local infoTextCorner = Instance.new("UICorner")
infoTextCorner.CornerRadius = UDim.new(0, 6)
infoTextCorner.Parent = InfoText

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingTop = UDim.new(0, 8)
padding.Parent = InfoText

-- RGB Visualizer
local VisualizerFrame = Instance.new("Frame")
VisualizerFrame.Name = "Visualizer"
VisualizerFrame.Size = UDim2.new(1, -16, 0, 100)
VisualizerFrame.Position = UDim2.new(0, 8, 0, 82)
VisualizerFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 22)
VisualizerFrame.BorderSizePixel = 0
VisualizerFrame.Parent = InfoPanel

local vizCorner = Instance.new("UICorner")
vizCorner.CornerRadius = UDim.new(0, 6)
vizCorner.Parent = VisualizerFrame

local bars = {}
for i = 1, 20 do
	local bar = Instance.new("Frame")
	bar.Name = "Bar" .. i
	bar.Size = UDim2.new(0, 10, 0, 5)
	bar.Position = UDim2.new(0, (i-1) * 13 + 5, 1, -10)
	bar.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
	bar.BorderSizePixel = 0
	bar.AnchorPoint = Vector2.new(0, 1)
	bar.Parent = VisualizerFrame
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 2)
	barCorner.Parent = bar
	bars[i] = bar
end

-- Button Container for Info Panel
local InfoButtonContainer = Instance.new("Frame")
InfoButtonContainer.Size = UDim2.new(1, -16, 0, 30)
InfoButtonContainer.Position = UDim2.new(0, 8, 1, -34)
InfoButtonContainer.BackgroundTransparency = 1
InfoButtonContainer.Parent = InfoPanel

local CopyButton = Instance.new("TextButton")
CopyButton.Name = "Copy"
CopyButton.Size = UDim2.new(0.31, 0, 1, 0)
CopyButton.Position = UDim2.new(0, 0, 0, 0)
CopyButton.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
CopyButton.Text = "COPY ID"
CopyButton.TextColor3 = Color3.fromRGB(200, 200, 200)
CopyButton.Font = Enum.Font.GothamBold
CopyButton.TextSize = 10
CopyButton.BorderSizePixel = 0
CopyButton.Parent = InfoButtonContainer
local copyCorner = Instance.new("UICorner")
copyCorner.CornerRadius = UDim.new(0, 6)
copyCorner.Parent = CopyButton
local copyStroke = Instance.new("UIStroke")
copyStroke.Color = Color3.fromRGB(50, 55, 65)
copyStroke.Thickness = 1
copyStroke.Parent = CopyButton

local ListenButton = Instance.new("TextButton")
ListenButton.Name = "Listen"
ListenButton.Size = UDim2.new(0.31, 0, 1, 0)
ListenButton.Position = UDim2.new(0.345, 0, 0, 0)
ListenButton.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
ListenButton.Text = "PLAY"
ListenButton.TextColor3 = Color3.fromRGB(200, 200, 200)
ListenButton.Font = Enum.Font.GothamBold
ListenButton.TextSize = 10
ListenButton.BorderSizePixel = 0
ListenButton.Parent = InfoButtonContainer
local listenCorner = Instance.new("UICorner")
listenCorner.CornerRadius = UDim.new(0, 6)
listenCorner.Parent = ListenButton
local listenStroke = Instance.new("UIStroke")
listenStroke.Color = Color3.fromRGB(50, 55, 65)
listenStroke.Thickness = 1
listenStroke.Parent = ListenButton

local DownloadButton = Instance.new("TextButton")
DownloadButton.Name = "Download"
DownloadButton.Size = UDim2.new(0.31, 0, 1, 0)
DownloadButton.Position = UDim2.new(0.69, 0, 0, 0)
DownloadButton.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
DownloadButton.Text = "UNDUH"
DownloadButton.TextColor3 = Color3.fromRGB(200, 200, 200)
DownloadButton.Font = Enum.Font.GothamBold
DownloadButton.TextSize = 10
DownloadButton.BorderSizePixel = 0
DownloadButton.Parent = InfoButtonContainer
local downloadCorner = Instance.new("UICorner")
downloadCorner.CornerRadius = UDim.new(0, 6)
downloadCorner.Parent = DownloadButton
local downloadStroke = Instance.new("UIStroke")
downloadStroke.Color = Color3.fromRGB(50, 55, 65)
downloadStroke.Thickness = 1
downloadStroke.Parent = DownloadButton

-- Floating Button
local FloatingButton = Instance.new("TextButton")
FloatingButton.Name = "FloatingButton"
FloatingButton.Size = UDim2.new(0, 41, 0, 41)
FloatingButton.Position = UDim2.new(1, -55, 0.5, -21)
FloatingButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
FloatingButton.Text = "🎵"
FloatingButton.TextSize = 20
FloatingButton.Font = Enum.Font.GothamBold
FloatingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingButton.BorderSizePixel = 0
FloatingButton.Visible = false
FloatingButton.Parent = ScreenGui
local fbCorner = Instance.new("UICorner")
fbCorner.CornerRadius = UDim.new(0, 12)
fbCorner.Parent = FloatingButton

-- Load Notify
loadstring(game:HttpGet("https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/han.lua"))()

local function CustomNotify(title, content)
	getgenv().Notify({
		Title = title,
		Content = content,
		Duration = 2
	})
end

-- ============================================================
-- STATE VARIABLES
-- ============================================================
local selectedaudio = nil
local selectedaudioname = nil
local min = false
local visualizerRunning = false

-- Scan engine state (dari script 2)
local on = true       -- script aktif
local sc = false      -- sedang scanning
local swept = false   -- sudah di-sweep
local cnt = 0
local f = {}          -- found sounds {num -> {n=name, o=obj, sid=soundId}}
local r = {}          -- row frames {num -> frame}
local cn = {}         -- connections
local pos = 0         -- posisi list di LogsFrame

-- ============================================================
-- VISUALIZER
-- ============================================================
function startVisualizer()
	visualizerRunning = true
	spawn(function()
		while visualizerRunning do
			for i, bar in pairs(bars) do
				local height = math.random(10, 90)
				local hue = (tick() * 50 + i * 10) % 360
				bar:TweenSize(UDim2.new(0, 10, 0, height), "Out", "Sine", 0.1, true)
				bar.BackgroundColor3 = Color3.fromHSV(hue / 360, 1, 1)
			end
			wait(0.1)
		end
	end)
end

function stopVisualizer()
	visualizerRunning = false
	for i, bar in pairs(bars) do
		bar.Size = UDim2.new(0, 10, 0, 5)
		bar.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
	end
end

-- ============================================================
-- SCAN ENGINE (dari script 2, diintegrasikan ke GUI SIEXTHER)
-- ============================================================

-- Tambah row audio ke LogsFrame SIEXTHER
local function addAudioRow(soundId, audioname, soundObj)
	local newsound = AudioTemplate:Clone()
	newsound.Parent = LogsFrame
	newsound.Name = soundId
	newsound.Visible = true
	newsound.Position = UDim2.new(0, 5, 0, pos)
	LogsFrame.CanvasSize = UDim2.new(0, 0, 0, pos + 31)
	pos = pos + 31
	newsound.TextLabel.Text = audioname

	local data = Instance.new("StringValue")
	data.Parent = newsound
	data.Value = soundId
	data.Name = "ID"

	local data2 = Instance.new("StringValue")
	data2.Parent = newsound
	data2.Value = audioname
	data2.Name = "NAME"

	newsound.Click.MouseButton1Click:Connect(function()
		if not InfoPanel.Visible then
			InfoText.Text = audioname
			selectedaudio = soundId
			selectedaudioname = audioname
			InfoPanel.Visible = true
		end
	end)

	return newsound
end

-- Core: coba tambah sound ke list
local function ta(obj)
	if not on then return end
	if typeof(obj) ~= "Instance" then return end

	local s, sid = pcall(function() return obj.SoundId end)
	if not s or not sid or sid == "" then return end
	if not string.find(sid, "rbxassetid") then return end

	local num = sid:match("(%d+)")
	if not num or f[num] then return end

	-- Cek sudah ada di GUI
	if LogsFrame:FindFirstChild(sid) then return end

	local nm = "Unknown"
	pcall(function() nm = obj.Name end)

	-- Coba ambil nama dari MarketplaceService
	local audioname = nm
	pcall(function()
		local info = game:GetService("MarketplaceService"):GetProductInfo(num)
		if info and info.Name then
			audioname = info.Name
		end
	end)

	f[num] = {n = audioname, o = obj, sid = sid}
	r[num] = addAudioRow(sid, audioname, obj)
	cnt = cnt + 1

	TitleLabel.Text = "SIEXTHER (" .. cnt .. ")"
end

-- Sweep semua sumber (game tree, nil instances, modules, gc)
local function dosweep()
	local i = 0

	-- Game tree
	if sc then
		local d = game:GetDescendants()
		for j = 1, #d do
			if not sc then break end
			if typeof(d[j]) == "Instance" then
				local ok, is = pcall(d[j].IsA, d[j], "Sound")
				if ok and is then ta(d[j]) end
			end
			i = i + 1
			if i % 300 == 0 then task.wait() end
		end
		d = nil
		task.wait()
	end

	-- Nil instances
	if sc then
		pcall(function()
			local ni = getnilinstances()
			for j = 1, #ni do
				if not sc then return end
				pcall(function()
					if ni[j]:IsA("Sound") then ta(ni[j]) end
				end)
				i = i + 1
				if i % 300 == 0 then task.wait() end
			end
		end)
		task.wait()
	end

	-- Loaded modules
	if sc then
		pcall(function()
			local md = getloadedmodules()
			for j = 1, #md do
				if not sc then return end
				pcall(function()
					if md[j]:IsA("ModuleScript") then
						local ch = md[j]:GetDescendants()
						for x = 1, #ch do
							if not sc then return end
							pcall(function()
								if ch[x]:IsA("Sound") then ta(ch[x]) end
							end)
							i = i + 1
							if i % 300 == 0 then task.wait() end
						end
					end
				end)
			end
		end)
		task.wait()
	end

	-- All instances
	if sc then
		pcall(function()
			local al = getinstances()
			for j = 1, #al do
				if not sc then return end
				pcall(function()
					if al[j]:IsA("Sound") then ta(al[j]) end
				end)
				i = i + 1
				if i % 300 == 0 then task.wait() end
			end
			al = nil
		end)
		task.wait()
	end

	-- Garbage collector
	if sc then
		pcall(function()
			local gc = getgc(true)
			for j = 1, #gc do
				if not sc then return end
				if typeof(gc[j]) == "Instance" then
					pcall(function()
						if gc[j]:IsA("Sound") then ta(gc[j]) end
					end)
				end
				i = i + 1
				if i % 600 == 0 then task.wait() end
			end
			gc = nil
		end)
	end

	if sc then
		swept = true
		ScanButton.Text = "SCAN"
		ScanButton.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
		sc = false
		CustomNotify("SIEXTHER AUDIO SCANNER", "Scan selesai! " .. cnt .. " audio ditemukan")
	end
end

-- Auto-detect sound baru masuk game
cn[#cn+1] = game.DescendantAdded:Connect(function(obj)
	if not on then return end
	pcall(function()
		if obj:IsA("Sound") then task.defer(ta, obj) end
	end)
end)

-- ============================================================
-- BUTTON EVENTS
-- ============================================================

CloseButton.MouseButton1Click:Connect(function()
	on = false
	sc = false
	for _, c in next, cn do
		pcall(function() c:Disconnect() end)
	end
	ScreenGui:Destroy()
end)

MinimizeButton.MouseButton1Click:Connect(function()
	if min == false then
		MainFrame.Visible = false
		FloatingButton.Visible = true
		min = true
	else
		FloatingButton.Visible = false
		MainFrame.Visible = true
		min = false
	end
end)

FloatingButton.MouseButton1Click:Connect(function()
	FloatingButton.Visible = false
	MainFrame.Visible = true
	min = false
end)

-- Scan Button: toggle scan on/off
ScanButton.MouseButton1Click:Connect(function()
	sc = not sc
	if sc then
		ScanButton.Text = "STOP"
		ScanButton.BackgroundColor3 = Color3.fromRGB(60, 25, 25)
		LoadBar.Visible = true
		LoadBar.Size = UDim2.new(0, 0, 0, 2)
		LoadBar:TweenSize(UDim2.new(1, 0, 0, 2), "Out", "Quad", 0.5, true)
		CustomNotify("SIEXTHER AUDIO SCANNER", "Scanning dimulai...")
		if not swept then
			task.spawn(dosweep)
		end
	else
		ScanButton.Text = "SCAN"
		ScanButton.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
		LoadBar.Visible = false
		LoadBar.Size = UDim2.new(0, 0, 0, 2)
	end
end)

InfoClose.MouseButton1Click:Connect(function()
	InfoPanel.Visible = false
	stopVisualizer()
	for _, sound in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetChildren()) do
		if sound.Name == "SampleSound" then
			sound:Destroy()
		end
	end
	ListenButton.Text = "PLAY"
end)

ListenButton.MouseButton1Click:Connect(function()
	if ListenButton.Text == "PLAY" then
		local samplesound = Instance.new("Sound")
		samplesound.Parent = game:GetService("Players").LocalPlayer.PlayerGui
		samplesound.Looped = true
		samplesound.SoundId = selectedaudio
		samplesound:Play()
		samplesound.Name = "SampleSound"
		samplesound.Volume = 1
		ListenButton.Text = "STOP"
		startVisualizer()
	else
		stopVisualizer()
		for _, sound in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetChildren()) do
			if sound.Name == "SampleSound" then
				sound:Destroy()
			end
		end
		ListenButton.Text = "PLAY"
	end
end)

CopyButton.MouseButton1Click:Connect(function()
	if pcall(function() Synapse:Copy(selectedaudio) end) then
	else
		local clip = setclipboard or Clipboard.set
		clip(selectedaudio)
	end
	CustomNotify("SIEXTHER AUDIO SCANNER", "Disalin ke papan klip")
end)

DownloadButton.MouseButton1Click:Connect(function()
	if selectedaudio then
		local id = string.match(selectedaudio, "%d+")
		if id then
			local safefilename = selectedaudioname:gsub("[^%w%s%-_]", ""):gsub("%s+", "_")
			local filename = safefilename .. ".mp3"
			local downloadurl = "https://assetdelivery.roblox.com/v1/asset?id=" .. id
			local success, err = pcall(function()
				if not isfolder("SiextherMusic") then
					makefolder("SiextherMusic")
				end
				local audiodata = game:HttpGet(downloadurl)
				local filepath = "SiextherMusic/" .. filename
				writefile(filepath, audiodata)
				CustomNotify("UNDUHAN SELESAI", filename)
			end)
			if not success then
				local clip = setclipboard or Clipboard.set
				clip(downloadurl)
				CustomNotify("SIEXTHER AUDIO SCANNER", "URL unduhan disalin!")
			end
		else
			CustomNotify("SIEXTHER AUDIO SCANNER", "Terjadi masalah!")
		end
	else
		CustomNotify("SIEXTHER AUDIO SCANNER", "Tidak ada audio yang dipilih!")
	end
end)

-- ============================================================
-- DRAG
-- ============================================================
function drag(gui)
	spawn(function()
		local UserInputService = game:GetService("UserInputService")
		local dragging, dragInput, dragStart, startPos
		local function update(input)
			local delta = input.Position - dragStart
			gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
		gui.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = gui.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		gui.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if input == dragInput and dragging then
				update(input)
			end
		end)
	end)
end

drag(MainFrame)
drag(FloatingButton)

-- Notifikasi awal
CustomNotify("SIEXTHER AUDIO SCANNER", "Siap! Tekan SCAN untuk mulai")