

local Players        = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local CoreGui        = game:GetService("CoreGui")
local HttpService    = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- bersihkan instance lama
local old = PlayerGui:FindFirstChild("CrosshairHub_UI")
if old then old:Destroy() end
pcall(function()
	local cg = CoreGui:FindFirstChild("CrosshairHub_UI")
	if cg then cg:Destroy() end
end)


local DB_FILE = "SiextherCross.json"

local DEFAULT_SETTINGS = {
	Style     = "Cross",
	Size      = 10,
	Thickness = 2,
	Gap       = 4,
	Opacity   = 0,
	OffsetX   = 0,
	OffsetY   = 0,
	ColorMode = "Blue",
}

local function dbLoad()
	local ok, raw = pcall(readfile, DB_FILE)
	if not ok or not raw or raw == "" then return DEFAULT_SETTINGS end
	local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok2 or type(data) ~= "table" then return DEFAULT_SETTINGS end
	-- merge dengan default supaya field baru selalu ada
	for k, v in pairs(DEFAULT_SETTINGS) do
		if data[k] == nil then data[k] = v end
	end
	return data
end

local function dbSave(s)
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, {
		Style     = s.Style,
		Size      = s.Size,
		Thickness = s.Thickness,
		Gap       = s.Gap,
		Opacity   = s.Opacity,
		OffsetX   = s.OffsetX,
		OffsetY   = s.OffsetY,
		ColorMode = s.ColorMode,
	})
	if ok then
		pcall(writefile, DB_FILE, encoded)
	end
end

----------------------------------------------------------------
-- SETTINGS (load dari DB)
----------------------------------------------------------------
local db = dbLoad()

local Settings = {
	Style     = db.Style,
	Size      = db.Size,
	Thickness = db.Thickness,
	Gap       = db.Gap,
	Color     = Color3.fromRGB(70, 130, 255),
	Opacity   = db.Opacity,
	OffsetX   = db.OffsetX,
	OffsetY   = db.OffsetY,
}

local function save()
	db.Style     = Settings.Style
	db.Size      = Settings.Size
	db.Thickness = Settings.Thickness
	db.Gap       = Settings.Gap
	db.Opacity   = Settings.Opacity
	db.OffsetX   = Settings.OffsetX
	db.OffsetY   = Settings.OffsetY
	db.ColorMode = currentColorMode or "Blue"
	dbSave(db)
end

-- debounce save supaya gak spam IO
local saveDebounce = nil
local function scheduleSave()
	if saveDebounce then task.cancel(saveDebounce) end
	saveDebounce = task.delay(0.8, save)
end

----------------------------------------------------------------
-- BELANG COLORS (16 warna)
----------------------------------------------------------------
local BELANG_COLORS = {
	Color3.fromRGB(70,  130, 255), -- blue
	Color3.fromRGB(255,  60,  60), -- red
	Color3.fromRGB( 60, 255, 120), -- green
	Color3.fromRGB(255, 230,  60), -- yellow
	Color3.fromRGB(255,  60, 220), -- pink
	Color3.fromRGB(255, 165,   0), -- orange
	Color3.fromRGB( 60, 220, 255), -- cyan
	Color3.fromRGB(180,  60, 255), -- purple
	Color3.fromRGB(255, 255, 255), -- white
	Color3.fromRGB(255, 140, 100), -- salmon
	Color3.fromRGB(100, 255, 200), -- mint
	Color3.fromRGB(255, 200,  60), -- gold
	Color3.fromRGB(200,  80, 150), -- rose
	Color3.fromRGB( 80, 200, 120), -- lime
	Color3.fromRGB(150, 200, 255), -- sky
	Color3.fromRGB(255, 100, 180), -- hot pink
}

local belangIndex  = 1
local belangThread = nil
local currentColorMode = db.ColorMode or "Blue"

local function stopBelang()
	if belangThread then task.cancel(belangThread) belangThread = nil end
end

-- forward declare drawCrosshair
local drawCrosshair

local function startBelang()
	stopBelang()
	belangThread = task.spawn(function()
		while true do
			task.wait(1,3)
			belangIndex = (belangIndex % #BELANG_COLORS) + 1
			Settings.Color = BELANG_COLORS[belangIndex]
			if drawCrosshair then drawCrosshair() end
		end
	end)
end

local function applyColorMode(mode, noSave)
	currentColorMode = mode
	stopBelang()
	if mode == "Blue" then
		Settings.Color = Color3.fromRGB(70, 130, 255)
		if drawCrosshair then drawCrosshair() end
	elseif mode == "Red" then
		Settings.Color = Color3.fromRGB(255, 60, 60)
		if drawCrosshair then drawCrosshair() end
	elseif mode == "Belang" then
		Settings.Color = BELANG_COLORS[belangIndex]
		if drawCrosshair then drawCrosshair() end
		startBelang()
	end
	if not noSave then scheduleSave() end
end

----------------------------------------------------------------
-- STYLES
----------------------------------------------------------------
local STYLES = {
	"Cross","Dot","Circle","Cross+Dot","X","T","Square","Circle+Dot",
}

----------------------------------------------------------------
-- ROOT GUI
----------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name             = "CrosshairHub_UI"
ScreenGui.ResetOnSpawn     = false
ScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder     = 999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = PlayerGui end

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------
local function corner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = inst
	return c
end

local function mkstroke(inst, col, thick)
	local s = Instance.new("UIStroke")
	s.Color            = col or Color3.fromRGB(70,130,255)
	s.Thickness        = thick or 1.5
	s.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
	s.Parent           = inst
	return s
end

local function makeDraggable(handle, target)
	local drag, ds, sp
	handle.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1
		or inp.UserInputType == Enum.UserInputType.Touch then
			drag = true; ds = inp.Position; sp = target.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then drag = false end
			end)
		end
	end)
	local function move(inp)
		if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement
		or inp.UserInputType == Enum.UserInputType.Touch) then
			local d = inp.Position - ds
			target.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
		end
	end
	handle.InputChanged:Connect(move)
	UserInputService.InputChanged:Connect(move)
end

----------------------------------------------------------------
-- CROSSHAIR HOLDER
----------------------------------------------------------------
local CrosshairHolder = Instance.new("Frame")
CrosshairHolder.Name               = "CrosshairHolder"
CrosshairHolder.AnchorPoint        = Vector2.new(0.5, 0.5)
CrosshairHolder.Position           = UDim2.new(0.5, Settings.OffsetX, 0.5, Settings.OffsetY)
CrosshairHolder.Size               = UDim2.new(0, 180, 0, 180)
CrosshairHolder.BackgroundTransparency = 1
CrosshairHolder.Active             = false
CrosshairHolder.ZIndex             = 1
CrosshairHolder.Parent             = ScreenGui

local function clearHolder()
	for _, c in ipairs(CrosshairHolder:GetChildren()) do c:Destroy() end
end

local function bar(w, h, rot)
	local f = Instance.new("Frame")
	f.AnchorPoint        = Vector2.new(0.5, 0.5)
	f.Position           = UDim2.new(0.5, 0, 0.5, 0)
	f.Size               = UDim2.new(0, w, 0, h)
	f.Rotation           = rot or 0
	f.BackgroundColor3   = Settings.Color
	f.BackgroundTransparency = Settings.Opacity
	f.BorderSizePixel    = 0
	f.ZIndex             = 2
	f.Parent             = CrosshairHolder
	if Settings.Outline then mkstroke(f, Color3.fromRGB(0,0,0), 1) end
	return f
end

local function obar(w, h, dx, dy, rot)
	local f = bar(w, h, rot)
	f.Position = UDim2.new(0.5, dx, 0.5, dy)
	return f
end

drawCrosshair = function()
	clearHolder()
	local sz  = Settings.Size
	local tk  = Settings.Thickness
	local gp  = Settings.Gap
	local sty = Settings.Style

	if sty == "Cross" or sty == "Cross+Dot" then
		obar(sz, tk, -(gp+sz/2), 0)
		obar(sz, tk,  (gp+sz/2), 0)
		obar(tk, sz, 0, -(gp+sz/2))
		obar(tk, sz, 0,  (gp+sz/2))
		if sty == "Cross+Dot" then bar(tk+2, tk+2) end
	elseif sty == "Dot" then
		corner(bar(tk*2, tk*2), 99)
	elseif sty == "Circle" or sty == "Circle+Dot" then
		local ring = Instance.new("Frame")
		ring.AnchorPoint        = Vector2.new(0.5,0.5)
		ring.Position           = UDim2.new(0.5,0,0.5,0)
		ring.Size               = UDim2.new(0, sz*2, 0, sz*2)
		ring.BackgroundTransparency = 1
		ring.ZIndex             = 2
		ring.Parent             = CrosshairHolder
		corner(ring, 99)
		local st = mkstroke(ring, Settings.Color, tk)
		st.Transparency = Settings.Opacity
		if sty == "Circle+Dot" then corner(bar(tk*2,tk*2),99) end
	elseif sty == "X" then
		bar(sz*1.6, tk,  45)
		bar(sz*1.6, tk, -45)
	elseif sty == "T" then
		obar(sz, tk, -(gp+sz/2), 0)
		obar(sz, tk,  (gp+sz/2), 0)
		obar(tk, sz, 0, (gp+sz/2))
	elseif sty == "Square" then
		local sq = Instance.new("Frame")
		sq.AnchorPoint        = Vector2.new(0.5,0.5)
		sq.Position           = UDim2.new(0.5,0,0.5,0)
		sq.Size               = UDim2.new(0, sz*1.6, 0, sz*1.6)
		sq.BackgroundTransparency = 1
		sq.ZIndex             = 2
		sq.Parent             = CrosshairHolder
		local st = mkstroke(sq, Settings.Color, tk)
		st.Transparency = Settings.Opacity
	end
end

local function updateHolderPos()
	CrosshairHolder.Position = UDim2.new(0.5, Settings.OffsetX, 0.5, Settings.OffsetY)
end

----------------------------------------------------------------
-- DRAG POSISI CROSSHAIR (fixed — update Settings)
----------------------------------------------------------------
local dragPosEnabled  = false
local chDragging      = false
local chDragStart     = nil
local chStartOffset   = nil
local syncOffsetSliders = nil   -- diisi setelah slider dibuat

UserInputService.InputBegan:Connect(function(inp)
	if not dragPosEnabled then return end
	if inp.UserInputType ~= Enum.UserInputType.MouseButton1
	and inp.UserInputType ~= Enum.UserInputType.Touch then return end
	local mp  = inp.Position
	local abs = CrosshairHolder.AbsolutePosition
	local sz  = CrosshairHolder.AbsoluteSize
	if mp.X >= abs.X and mp.X <= abs.X+sz.X
	and mp.Y >= abs.Y and mp.Y <= abs.Y+sz.Y then
		chDragging    = true
		chDragStart   = Vector2.new(mp.X, mp.Y)
		chStartOffset = Vector2.new(Settings.OffsetX, Settings.OffsetY)
	end
end)

UserInputService.InputChanged:Connect(function(inp)
	if not (dragPosEnabled and chDragging) then return end
	if inp.UserInputType ~= Enum.UserInputType.MouseMovement
	and inp.UserInputType ~= Enum.UserInputType.Touch then return end
	local delta = Vector2.new(inp.Position.X, inp.Position.Y) - chDragStart
	Settings.OffsetX = math.clamp(math.floor(chStartOffset.X + delta.X), -300, 300)
	Settings.OffsetY = math.clamp(math.floor(chStartOffset.Y + delta.Y), -300, 300)
	updateHolderPos()
	if syncOffsetSliders then syncOffsetSliders(Settings.OffsetX, Settings.OffsetY) end
	scheduleSave()
end)

UserInputService.InputEnded:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1
	or inp.UserInputType == Enum.UserInputType.Touch then
		chDragging = false
	end
end)

----------------------------------------------------------------
-- MAIN PANEL  (lebih kecil: 260 × 390)
----------------------------------------------------------------
local PANEL_W = 260
local PANEL_H = 390

local MainFrame = Instance.new("Frame")
MainFrame.Name              = "MainFrame"
MainFrame.Size              = UDim2.new(0, PANEL_W, 0, PANEL_H)
MainFrame.Position          = UDim2.new(0.5, -PANEL_W/2, 0.5, -PANEL_H/2)
MainFrame.BackgroundColor3  = Color3.fromRGB(22, 22, 32)
MainFrame.BorderSizePixel   = 0
MainFrame.ClipsDescendants  = true
MainFrame.Parent            = ScreenGui
corner(MainFrame, 10)
mkstroke(MainFrame, Color3.fromRGB(70,130,255), 1.5)

-- Top bar
local TopBar = Instance.new("Frame")
TopBar.Size             = UDim2.new(1, 0, 0, 34)
TopBar.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
TopBar.BorderSizePixel  = 0
TopBar.Parent           = MainFrame
corner(TopBar, 10)
-- patch rounded bawah topbar
local TBPatch = Instance.new("Frame")
TBPatch.Size            = UDim2.new(1, 0, 0, 10)
TBPatch.Position        = UDim2.new(0, 0, 1, -10)
TBPatch.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
TBPatch.BorderSizePixel = 0
TBPatch.ZIndex          = 0
TBPatch.Parent          = TopBar

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position  = UDim2.new(0, 12, 0, 0)
Title.Size      = UDim2.new(1, -80, 1, 0)
Title.Font      = Enum.Font.GothamBold
Title.Text      = "SIEXTHER CROSSHAIR"
Title.TextColor3 = Color3.fromRGB(225, 225, 240)
Title.TextSize  = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent    = TopBar

local function topBtn(xOff, txt, bg, tc)
	local b = Instance.new("TextButton")
	b.Size              = UDim2.new(0, 24, 0, 24)
	b.Position          = UDim2.new(1, xOff, 0.5, -12)
	b.BackgroundColor3  = bg
	b.Text              = txt
	b.Font              = Enum.Font.GothamBold
	b.TextSize          = 12
	b.TextColor3        = tc
	b.AutoButtonColor   = true
	b.Parent            = TopBar
	corner(b, 6)
	return b
end

local CloseBtn = topBtn(-30, "X", Color3.fromRGB(45,22,28), Color3.fromRGB(255,90,90))
local MinBtn   = topBtn(-58, "–", Color3.fromRGB(28,28,40), Color3.fromRGB(180,180,200))
makeDraggable(TopBar, MainFrame)

-- Scroll body
local Body = Instance.new("ScrollingFrame")
Body.Position             = UDim2.new(0, 0, 0, 34)
Body.Size                 = UDim2.new(1, 0, 1, -34)
Body.BackgroundTransparency = 1
Body.BorderSizePixel      = 0
Body.ScrollBarThickness   = 3
Body.ScrollBarImageColor3 = Color3.fromRGB(70,130,255)
Body.CanvasSize           = UDim2.new(0, 0, 0, 999) -- diupdate nanti
Body.Parent               = MainFrame

local bodyY = 8   -- running Y cursor dalam body

local function sectionLabel(text)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position  = UDim2.new(0, 12, 0, bodyY)
	l.Size      = UDim2.new(1, -24, 0, 15)
	l.Font      = Enum.Font.GothamBold
	l.Text      = text
	l.TextColor3 = Color3.fromRGB(70,130,255)
	l.TextSize  = 11
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent    = Body
	bodyY = bodyY + 18
end

----------------------------------------------------------------
-- STYLE GRID
----------------------------------------------------------------
sectionLabel("————————— S I E X T H E R —————————")

local StyleGrid = Instance.new("Frame")
StyleGrid.BackgroundTransparency = 1
StyleGrid.Position = UDim2.new(0, 12, 0, bodyY)
StyleGrid.Size     = UDim2.new(1, -24, 0, 70)
StyleGrid.Parent   = Body

local GridLayout = Instance.new("UIGridLayout")
GridLayout.CellSize    = UDim2.new(0, 70, 0, 24)
GridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
GridLayout.Parent      = StyleGrid

bodyY = bodyY + 76

local styleButtons = {}
local function refreshStyleBtns()
	for sty, btn in pairs(styleButtons) do
		if sty == Settings.Style then
			btn.BackgroundColor3 = Color3.fromRGB(70,130,255)
			btn.TextColor3       = Color3.fromRGB(255,255,255)
		else
			btn.BackgroundColor3 = Color3.fromRGB(33,33,46)
			btn.TextColor3       = Color3.fromRGB(180,180,200)
		end
	end
end

for _, sty in ipairs(STYLES) do
	local b = Instance.new("TextButton")
	b.Size             = UDim2.new(0,70,0,24)
	b.BackgroundColor3 = Color3.fromRGB(33,33,46)
	b.Text             = sty
	b.Font             = Enum.Font.Gotham
	b.TextSize         = 10
	b.TextColor3       = Color3.fromRGB(180,180,200)
	b.AutoButtonColor  = true
	b.Parent           = StyleGrid
	corner(b, 5)
	b.MouseButton1Click:Connect(function()
		Settings.Style = sty
		refreshStyleBtns()
		drawCrosshair()
		scheduleSave()
	end)
	styleButtons[sty] = b
end
refreshStyleBtns()

local function createSlider(labelText, minV, maxV, defaultV, onChange)
	-- total tinggi per slider: label 14 + track row 22 = 36 + 4 padding = 40
	local ITEM_H = 42
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Position = UDim2.new(0, 12, 0, bodyY)
	holder.Size     = UDim2.new(1, -24, 0, ITEM_H)
	holder.Parent   = Body
	bodyY = bodyY + ITEM_H

	-- label kiri atas
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size      = UDim2.new(1, 0, 0, 14)
	lbl.Font      = Enum.Font.Gotham
	lbl.Text      = labelText
	lbl.TextColor3 = Color3.fromRGB(185,185,205)
	lbl.TextSize  = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent    = holder

	-- track area (kiri dari textbox)
	local TBOX_W = 38
	local GAP    = 6
	local track = Instance.new("Frame")
	track.Position        = UDim2.new(0, 0, 0, 18)
	track.Size            = UDim2.new(1, -(TBOX_W+GAP), 0, 6)
	track.BackgroundColor3 = Color3.fromRGB(38,38,52)
	track.BorderSizePixel = 0
	track.Parent          = holder
	corner(track, 99)

	local ratio0 = math.clamp((defaultV - minV)/(maxV - minV), 0, 1)

	local fill = Instance.new("Frame")
	fill.Size             = UDim2.new(ratio0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(70,130,255)
	fill.BorderSizePixel  = 0
	fill.Parent           = track
	corner(fill, 99)

	local knob = Instance.new("Frame")
	knob.AnchorPoint      = Vector2.new(0.5, 0.5)
	knob.Position         = UDim2.new(ratio0, 0, 0.5, 0)
	knob.Size             = UDim2.new(0, 12, 0, 12)
	knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
	knob.ZIndex           = 2
	knob.Parent           = track
	corner(knob, 99)

	-- textbox kecil
	local tbox = Instance.new("TextBox")
	tbox.Position         = UDim2.new(1, -(TBOX_W), 0, 14)
	tbox.Size             = UDim2.new(0, TBOX_W, 0, 18)
	tbox.BackgroundColor3 = Color3.fromRGB(33,33,46)
	tbox.Text             = tostring(defaultV)
	tbox.Font             = Enum.Font.GothamBold
	tbox.TextSize         = 10
	tbox.TextColor3       = Color3.fromRGB(200,200,220)
	tbox.ClearTextOnFocus = false
	tbox.BorderSizePixel  = 0
	tbox.ZIndex           = 3
	tbox.Parent           = holder
	corner(tbox, 4)
	mkstroke(tbox, Color3.fromRGB(60,60,80), 1)

	local currentVal = defaultV

	local function applyValue(v)
		v = math.clamp(math.floor(v + 0.5), minV, maxV)
		currentVal = v
		local rel = math.clamp((v-minV)/(maxV-minV), 0, 1)
		fill.Size     = UDim2.new(rel, 0, 1, 0)
		knob.Position = UDim2.new(rel, 0, 0.5, 0)
		tbox.Text     = tostring(v)
		onChange(v)
	end

	local function setFromX(x)
		local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		applyValue(minV + (maxV-minV)*rel)
	end

	local function setValue(v) applyValue(v) end

	-- drag slider
	local dragging = false
	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1
		or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true; setFromX(inp.Position.X)
		end
	end)
	knob.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1
		or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
		or inp.UserInputType == Enum.UserInputType.Touch) then
			setFromX(inp.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1
		or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	-- textbox input: Enter atau FocusLost apply
	tbox.FocusLost:Connect(function(enterPressed)
		local num = tonumber(tbox.Text)
		if num then
			applyValue(num)
			scheduleSave()
		else
			tbox.Text = tostring(currentVal)
		end
	end)

	return holder, setValue
end

----------------------------------------------------------------
-- SLIDERS
----------------------------------------------------------------
sectionLabel("")

local _, setSize = createSlider("Size", 4, 40, Settings.Size, function(v)
	Settings.Size = v; drawCrosshair(); scheduleSave()
end)
local _, setThick = createSlider("Thickness", 1, 10, Settings.Thickness, function(v)
	Settings.Thickness = v; drawCrosshair(); scheduleSave()
end)
local _, setGap = createSlider("Gap", 0, 20, Settings.Gap, function(v)
	Settings.Gap = v; drawCrosshair(); scheduleSave()
end)
local _, setOpacity = createSlider("Opacity", 0, 90, math.floor(Settings.Opacity*100), function(v)
	Settings.Opacity = v/100; drawCrosshair(); scheduleSave()
end)

sectionLabel("POSITION")

local _, setSliderX = createSlider("Offset X", -300, 300, Settings.OffsetX, function(v)
	Settings.OffsetX = v; updateHolderPos(); scheduleSave()
end)
local _, setSliderY = createSlider("Offset Y", -300, 300, Settings.OffsetY, function(v)
	Settings.OffsetY = v; updateHolderPos(); scheduleSave()
end)

syncOffsetSliders = function(x, y)
	setSliderX(x); setSliderY(y)
end

-- Row: Drag + Reset Center (berdampingan)
local posRowY = bodyY
local DragPosBtn = Instance.new("TextButton")
DragPosBtn.Position        = UDim2.new(0, 12, 0, posRowY)
DragPosBtn.Size            = UDim2.new(0.56, -8, 0, 26)
DragPosBtn.BackgroundColor3 = Color3.fromRGB(33,33,46)
DragPosBtn.Text            = "DRAG : OFF"
DragPosBtn.Font            = Enum.Font.GothamBold
DragPosBtn.TextSize        = 10
DragPosBtn.TextColor3      = Color3.fromRGB(180,180,200)
DragPosBtn.Parent          = Body
corner(DragPosBtn, 6)

local CenterBtn = Instance.new("TextButton")
CenterBtn.Position        = UDim2.new(0.56, 4, 0, posRowY)
CenterBtn.Size            = UDim2.new(0.44, -16, 0, 26)
CenterBtn.BackgroundColor3 = Color3.fromRGB(33,33,46)
CenterBtn.Text            = "RESET"
CenterBtn.Font            = Enum.Font.GothamBold
CenterBtn.TextSize        = 10
CenterBtn.TextColor3      = Color3.fromRGB(180,180,200)
CenterBtn.Parent          = Body
corner(CenterBtn, 6)

bodyY = bodyY + 32

-- Drag toggle
DragPosBtn.MouseButton1Click:Connect(function()
	dragPosEnabled = not dragPosEnabled
	if dragPosEnabled then
		DragPosBtn.Text            = "DRAG : ON"
		DragPosBtn.BackgroundColor3 = Color3.fromRGB(70,130,255)
		DragPosBtn.TextColor3      = Color3.fromRGB(255,255,255)
	else
		DragPosBtn.Text            = "DRAG : OFF"
		DragPosBtn.BackgroundColor3 = Color3.fromRGB(33,33,46)
		DragPosBtn.TextColor3      = Color3.fromRGB(180,180,200)
	end
end)

-- Reset to center
CenterBtn.MouseButton1Click:Connect(function()
	Settings.OffsetX = 0
	Settings.OffsetY = 0
	updateHolderPos()
	syncOffsetSliders(0, 0)
	scheduleSave()
end)

----------------------------------------------------------------
-- WARNA (3 MODE)
----------------------------------------------------------------
sectionLabel("COLOR")

local MODE_CFG = {
	{ mode="Blue",   label="DEFAULT",   active=Color3.fromRGB(70,130,255), inactive=Color3.fromRGB(33,33,46) },
	{ mode="Red",    label="RED",    active=Color3.fromRGB(200,50,50),  inactive=Color3.fromRGB(33,33,46) },
	{ mode="Belang", label="RANDOM", active=Color3.fromRGB(140,50,200), inactive=Color3.fromRGB(33,33,46) },
}

local colorModeRow = Instance.new("Frame")
colorModeRow.BackgroundTransparency = 1
colorModeRow.Position = UDim2.new(0, 12, 0, bodyY)
colorModeRow.Size     = UDim2.new(1, -24, 0, 28)
colorModeRow.Parent   = Body

local cmLayout = Instance.new("UIListLayout")
cmLayout.FillDirection = Enum.FillDirection.Horizontal
cmLayout.Padding       = UDim.new(0, 7)
cmLayout.Parent        = colorModeRow

bodyY = bodyY + 34

local colorModeBtns = {}
local function refreshColorBtns()
	for _, cfg in ipairs(MODE_CFG) do
		local btn = colorModeBtns[cfg.mode]
		if currentColorMode == cfg.mode then
			btn.BackgroundColor3 = cfg.active
			btn.TextColor3       = Color3.fromRGB(255,255,255)
		else
			btn.BackgroundColor3 = cfg.inactive
			btn.TextColor3       = Color3.fromRGB(180,180,200)
		end
	end
end

for _, cfg in ipairs(MODE_CFG) do
	local btn = Instance.new("TextButton")
	btn.Size             = UDim2.new(0, 72, 0, 28)
	btn.BackgroundColor3 = Color3.fromRGB(33,33,46)
	btn.Text             = cfg.label
	btn.Font             = Enum.Font.GothamBold
	btn.TextSize         = 11
	btn.TextColor3       = Color3.fromRGB(180,180,200)
	btn.AutoButtonColor  = false
	btn.Parent           = colorModeRow
	corner(btn, 7)
	colorModeBtns[cfg.mode] = btn
	btn.MouseButton1Click:Connect(function()
		applyColorMode(cfg.mode)
		refreshColorBtns()
	end)
end
refreshColorBtns()

-- update canvas
bodyY = bodyY + 10
Body.CanvasSize = UDim2.new(0, 0, 0, bodyY)

----------------------------------------------------------------
-- FLOATING ICON (minimize)
----------------------------------------------------------------
local FloatIcon = Instance.new("TextButton")
FloatIcon.Name             = "FloatIcon"
FloatIcon.Size             = UDim2.new(0, 41, 0, 41)
FloatIcon.Position         = UDim2.new(1, -65, 0, 15)
FloatIcon.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
FloatIcon.Text             = "⭐"
FloatIcon.Font             = Enum.Font.GothamBold
FloatIcon.TextSize         = 20
FloatIcon.TextColor3       = Color3.fromRGB(70,130,255)
FloatIcon.Visible          = false
FloatIcon.ZIndex           = 5
FloatIcon.Parent           = ScreenGui
corner(FloatIcon, 12)
makeDraggable(FloatIcon, FloatIcon)


local function setMinimized(state)
	MainFrame.Visible = not state
	FloatIcon.Visible = state
end

MinBtn.MouseButton1Click:Connect(function() setMinimized(true) end)
FloatIcon.MouseButton1Click:Connect(function() setMinimized(false) end)

----------------------------------------------------------------
-- CLOSE
----------------------------------------------------------------
local function shutdown()
	stopBelang()
	save()   -- final save saat close
	local tw = TweenService:Create(MainFrame, TweenInfo.new(0.18), {
		Size     = UDim2.new(0,0,0,0),
		Position = MainFrame.Position + UDim2.new(0,PANEL_W/2,0,PANEL_H/2),
	})
	tw:Play()
	tw.Completed:Wait()
	ScreenGui:Destroy()
end

CloseBtn.MouseButton1Click:Connect(shutdown)


applyColorMode(currentColorMode, true)
drawCrosshair()