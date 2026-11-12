local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoTranslateGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

-- Main Frame (Lebih Kecil & Modern)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 150)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -75)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- Blue Sky Stroke (Outer Frame Only)
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(70, 130, 255)
MainStroke.Thickness = 2
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 32)
Header.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 10)
HeaderFix.Position = UDim2.new(0, 0, 1, -10)
HeaderFix.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

-- Title
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SIEXTHER TRANSLATE"
Title.TextColor3 = Color3.fromRGB(70, 130, 255)
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Minimize Button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 24, 0, 24)
MinimizeBtn.Position = UDim2.new(1, -54, 0.5, -12)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
MinimizeBtn.Text = "–"
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinimizeBtn.TextSize = 14
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.AutoButtonColor = false
MinimizeBtn.Parent = Header

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 6)
MinimizeCorner.Parent = MinimizeBtn

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -28, 0.5, -12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

-- Hover Effects for Buttons
MinimizeBtn.MouseEnter:Connect(function()
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
end)

MinimizeBtn.MouseLeave:Connect(function()
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
end)

CloseBtn.MouseEnter:Connect(function()
    CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
end)

CloseBtn.MouseLeave:Connect(function()
    CloseBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
end)

-- Minimized Button
local MinimizedBtn = Instance.new("TextButton")
MinimizedBtn.Name = "MinimizedBtn"
MinimizedBtn.Size = UDim2.new(0, 38, 0, 38)
MinimizedBtn.Position = UDim2.new(1, -60, 0.5, -19)
MinimizedBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MinimizedBtn.Text = "🌐"
MinimizedBtn.TextColor3 = Color3.fromRGB(70, 130, 255)
MinimizedBtn.TextSize = 18
MinimizedBtn.Font = Enum.Font.GothamBold
MinimizedBtn.BorderSizePixel = 0
MinimizedBtn.Visible = false
MinimizedBtn.Active = true
MinimizedBtn.Draggable = true
MinimizedBtn.AutoButtonColor = true
MinimizedBtn.Parent = ScreenGui

local MinimizedCorner = Instance.new("UICorner")
MinimizedCorner.CornerRadius = UDim.new(0, 10)
MinimizedCorner.Parent = MinimizedBtn

local MinimizedStroke = Instance.new("UIStroke")
MinimizedStroke.Color = Color3.fromRGB(70, 130, 255)
MinimizedStroke.Thickness = 2
MinimizedStroke.Parent = MinimizedBtn

-- Content Frame
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -16, 1, -40)
ContentFrame.Position = UDim2.new(0, 8, 0, 36)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Settings
local Settings = {
    TargetLanguage = "en",
    LanguageName = "English",
    LanguageFlag = "🇬🇧"
}

-- Info Label
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Name = "InfoLabel"
InfoLabel.Size = UDim2.new(1, 0, 0, 18)
InfoLabel.Position = UDim2.new(0, 0, 0, 2)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "🇮🇩 Indonesian → 🇬🇧 English"
InfoLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
InfoLabel.TextSize = 11
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.Parent = ContentFrame

-- Input Box
local InputBox = Instance.new("TextBox")
InputBox.Name = "InputBox"
InputBox.Size = UDim2.new(1, 0, 0, 42)
InputBox.Position = UDim2.new(0, 0, 0, 22)
InputBox.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
InputBox.Text = ""
InputBox.TextColor3 = Color3.fromRGB(220, 220, 230)
InputBox.TextSize = 12
InputBox.Font = Enum.Font.Gotham
InputBox.PlaceholderText = "Ketik pesan disini..."
InputBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
InputBox.TextWrapped = true
InputBox.TextXAlignment = Enum.TextXAlignment.Left
InputBox.TextYAlignment = Enum.TextYAlignment.Top
InputBox.ClearTextOnFocus = false
InputBox.MultiLine = true
InputBox.BorderSizePixel = 0
InputBox.Parent = ContentFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 8)
InputCorner.Parent = InputBox

-- Translate & Send Button (Kiri - Lebih Besar)
local TranslateBtn = Instance.new("TextButton")
TranslateBtn.Name = "TranslateBtn"
TranslateBtn.Size = UDim2.new(0.62, -2, 0, 34)
TranslateBtn.Position = UDim2.new(0, 0, 0, 70)
TranslateBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
TranslateBtn.Text = "TRANSLATE"
TranslateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TranslateBtn.TextSize = 12
TranslateBtn.Font = Enum.Font.GothamBold
TranslateBtn.BorderSizePixel = 0
TranslateBtn.AutoButtonColor = false
TranslateBtn.Parent = ContentFrame

local TranslateCorner = Instance.new("UICorner")
TranslateCorner.CornerRadius = UDim.new(0, 8)
TranslateCorner.Parent = TranslateBtn

-- Language Button (Kanan - Lebih Kecil)
local LanguageBtn = Instance.new("TextButton")
LanguageBtn.Name = "LanguageBtn"
LanguageBtn.Size = UDim2.new(0.38, -2, 0, 34)
LanguageBtn.Position = UDim2.new(0.62, 4, 0, 70)
LanguageBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
LanguageBtn.Text = "🇬🇧 EN"
LanguageBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
LanguageBtn.TextSize = 12
LanguageBtn.Font = Enum.Font.GothamSemibold
LanguageBtn.BorderSizePixel = 0
LanguageBtn.AutoButtonColor = false
LanguageBtn.Parent = ContentFrame

local LanguageCorner = Instance.new("UICorner")
LanguageCorner.CornerRadius = UDim.new(0, 8)
LanguageCorner.Parent = LanguageBtn

-- Button Hover Effects
TranslateBtn.MouseEnter:Connect(function()
    TranslateBtn.BackgroundColor3 = Color3.fromRGB(85, 145, 255)
end)

TranslateBtn.MouseLeave:Connect(function()
    TranslateBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
end)

LanguageBtn.MouseEnter:Connect(function()
    LanguageBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
end)

LanguageBtn.MouseLeave:Connect(function()
    LanguageBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
end)

-- Language Selection Frame (Hidden by default)
local LanguageFrame = Instance.new("Frame")
LanguageFrame.Name = "LanguageFrame"
LanguageFrame.Size = UDim2.new(0, 220, 0, 240)
LanguageFrame.Position = UDim2.new(0.5, -110, 0.5, -120)
LanguageFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
LanguageFrame.BorderSizePixel = 0
LanguageFrame.Visible = false
LanguageFrame.Parent = ScreenGui

local LanguageFrameCorner = Instance.new("UICorner")
LanguageFrameCorner.CornerRadius = UDim.new(0, 12)
LanguageFrameCorner.Parent = LanguageFrame

local LanguageFrameStroke = Instance.new("UIStroke")
LanguageFrameStroke.Color = Color3.fromRGB(70, 130, 255)
LanguageFrameStroke.Thickness = 2
LanguageFrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
LanguageFrameStroke.Parent = LanguageFrame

-- Language Frame Header
local LangHeader = Instance.new("Frame")
LangHeader.Name = "LangHeader"
LangHeader.Size = UDim2.new(1, 0, 0, 32)
LangHeader.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
LangHeader.BorderSizePixel = 0
LangHeader.Parent = LanguageFrame

local LangHeaderCorner = Instance.new("UICorner")
LangHeaderCorner.CornerRadius = UDim.new(0, 12)
LangHeaderCorner.Parent = LangHeader

local LangHeaderFix = Instance.new("Frame")
LangHeaderFix.Size = UDim2.new(1, 0, 0, 10)
LangHeaderFix.Position = UDim2.new(0, 0, 1, -10)
LangHeaderFix.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
LangHeaderFix.BorderSizePixel = 0
LangHeaderFix.Parent = LangHeader

local LangTitle = Instance.new("TextLabel")
LangTitle.Name = "LangTitle"
LangTitle.Size = UDim2.new(1, -36, 1, 0)
LangTitle.Position = UDim2.new(0, 10, 0, 0)
LangTitle.BackgroundTransparency = 1
LangTitle.Text = "PILIH BAHASA"
LangTitle.TextColor3 = Color3.fromRGB(70, 130, 255)
LangTitle.TextSize = 13
LangTitle.Font = Enum.Font.GothamBold
LangTitle.TextXAlignment = Enum.TextXAlignment.Left
LangTitle.Parent = LangHeader

local LangCloseBtn = Instance.new("TextButton")
LangCloseBtn.Name = "LangCloseBtn"
LangCloseBtn.Size = UDim2.new(0, 24, 0, 24)
LangCloseBtn.Position = UDim2.new(1, -28, 0.5, -12)
LangCloseBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
LangCloseBtn.Text = "X"
LangCloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
LangCloseBtn.TextSize = 12
LangCloseBtn.Font = Enum.Font.GothamBold
LangCloseBtn.BorderSizePixel = 0
LangCloseBtn.AutoButtonColor = false
LangCloseBtn.Parent = LangHeader

local LangCloseCorner = Instance.new("UICorner")
LangCloseCorner.CornerRadius = UDim.new(0, 6)
LangCloseCorner.Parent = LangCloseBtn

LangCloseBtn.MouseEnter:Connect(function()
    LangCloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
end)

LangCloseBtn.MouseLeave:Connect(function()
    LangCloseBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
end)

-- Scroll Frame for Languages
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "ScrollFrame"
ScrollFrame.Size = UDim2.new(1, -16, 1, -42)
ScrollFrame.Position = UDim2.new(0, 8, 0, 36)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
ScrollFrame.Parent = LanguageFrame

local ScrollCorner = Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(0, 8)
ScrollCorner.Parent = ScrollFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.Parent = ScrollFrame

-- Language List
local languages = {
    {code = "en", name = "English", flag = "🇬🇧", short = "EN"},
    {code = "es", name = "Spanish", flag = "🇪🇸", short = "ES"},
    {code = "fr", name = "French", flag = "🇫🇷", short = "FR"},
    {code = "de", name = "German", flag = "🇩🇪", short = "DE"},
    {code = "it", name = "Italian", flag = "🇮🇹", short = "IT"},
    {code = "pt", name = "Portuguese", flag = "🇵🇹", short = "PT"},
    {code = "ru", name = "Russian", flag = "🇷🇺", short = "RU"},
    {code = "ja", name = "Japanese", flag = "🇯🇵", short = "JP"},
    {code = "ko", name = "Korean", flag = "🇰🇷", short = "KR"},
    {code = "zh-CN", name = "Chinese", flag = "🇨🇳", short = "CN"},
    {code = "ms-MY", name = "Malaysia", flag = "🇲🇾", short = "MY"},
    {code = "ar", name = "Arabic", flag = "🇸🇦", short = "AR"},
    {code = "hi", name = "Hindi", flag = "🇮🇳", short = "HI"},
    {code = "th", name = "Thai", flag = "🇹🇭", short = "TH"},
    {code = "vi", name = "Vietnamese", flag = "🇻🇳", short = "VN"},
    {code = "nl", name = "Dutch", flag = "🇳🇱", short = "NL"},
    {code = "pl", name = "Polish", flag = "🇵🇱", short = "PL"},
    {code = "tr", name = "Turkish", flag = "🇹🇷", short = "TR"},
    {code = "jw", name = "Jawa", flag = "🇦🇶", short = "JV"},
    {code = "su", name = "Sunda", flag = "🏳️‍⚧️", short = "SU"},
}

-- Create Language Buttons
for i, lang in ipairs(languages) do
    local LangOptionBtn = Instance.new("TextButton")
    LangOptionBtn.Name = "Lang_" .. lang.code
    LangOptionBtn.Size = UDim2.new(1, -8, 0, 32)
    LangOptionBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
    LangOptionBtn.Text = lang.flag .. " " .. lang.name
    LangOptionBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
    LangOptionBtn.TextSize = 12
    LangOptionBtn.Font = Enum.Font.Gotham
    LangOptionBtn.BorderSizePixel = 0
    LangOptionBtn.AutoButtonColor = false
    LangOptionBtn.Parent = ScrollFrame
    
    local LangOptionCorner = Instance.new("UICorner")
    LangOptionCorner.CornerRadius = UDim.new(0, 6)
    LangOptionCorner.Parent = LangOptionBtn
    
    -- Click event
    LangOptionBtn.MouseButton1Click:Connect(function()
        Settings.TargetLanguage = lang.code
        Settings.LanguageName = lang.name
        Settings.LanguageFlag = lang.flag
        Settings.LanguageShort = lang.short
        
        LanguageBtn.Text = lang.flag .. " " .. lang.short
        InfoLabel.Text = "🇮🇩 Indonesian → " .. lang.flag .. " " .. lang.name
        
        -- Visual feedback
        LangOptionBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        task.wait(0.15)
        LangOptionBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
        
        -- Close language frame
        LanguageFrame.Visible = false
        LanguageBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    end)
    
    -- Hover effect
    LangOptionBtn.MouseEnter:Connect(function()
        LangOptionBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    end)
    
    LangOptionBtn.MouseLeave:Connect(function()
        LangOptionBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
    end)
end

-- Update ScrollFrame canvas size
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 8)

-- Language Button Click
LanguageBtn.MouseButton1Click:Connect(function()
    LanguageFrame.Visible = not LanguageFrame.Visible
    
    if LanguageFrame.Visible then
        LanguageBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    else
        LanguageBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    end
end)

-- Language Close Button
LangCloseBtn.MouseButton1Click:Connect(function()
    LanguageFrame.Visible = false
    LanguageBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
end)

-- Google Translate API Function
local function translateWithAPI(text, sourceLang, targetLang)
    local success, result = pcall(function()
        local encodedText = HttpService:UrlEncode(text)
        
        local url = string.format(
            "https://translate.googleapis.com/translate_a/single?client=gtx&sl=%s&tl=%s&dt=t&q=%s",
            sourceLang,
            targetLang,
            encodedText
        )
        
        local response = game:HttpGet(url)
        local data = HttpService:JSONDecode(response)
        
        if data and data[1] then
            local translatedText = ""
            for _, segment in ipairs(data[1]) do
                if segment[1] then
                    translatedText = translatedText .. segment[1]
                end
            end
            return translatedText
        end
        
        return nil
    end)
    
    if success and result then
        return result
    else
        warn("Translation failed:", result)
        return nil
    end
end

-- Alternative: MyMemory Translation API (backup)
local function translateWithMyMemory(text, sourceLang, targetLang)
    local success, result = pcall(function()
        local encodedText = HttpService:UrlEncode(text)
        
        local url = string.format(
            "https://api.mymemory.translated.net/get?q=%s&langpair=%s|%s",
            encodedText,
            sourceLang,
            targetLang
        )
        
        local response = game:HttpGet(url)
        local data = HttpService:JSONDecode(response)
        
        if data and data.responseData and data.responseData.translatedText then
            return data.responseData.translatedText
        end
        
        return nil
    end)
    
    if success and result then
        return result
    else
        warn("MyMemory translation failed:", result)
        return nil
    end
end

-- Main translation function with fallbacks
local function translateText(text)
    local translated = translateWithAPI(text, "id", Settings.TargetLanguage)
    
    if translated then
        return translated
    end
    
    translated = translateWithMyMemory(text, "id", Settings.TargetLanguage)
    
    if translated then
        return translated
    end
    
    return text
end

-- Send Chat Function
local function sendChat(message)
    if message and message ~= "" then
        pcall(function()
            local TextChatService = game:GetService("TextChatService")
            local chatChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            
            if chatChannel then
                chatChannel:SendAsync(message)
            else
                game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
            end
        end)
    end
end

-- Translate & Send Button Click
TranslateBtn.MouseButton1Click:Connect(function()
    local indonesianText = InputBox.Text
    
    if indonesianText and indonesianText ~= "" then
        TranslateBtn.Text = "Tunggu..."
        TranslateBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 150)
        
        local englishText = translateText(indonesianText)
        
        if englishText and englishText ~= indonesianText then
            TranslateBtn.Text = "Mengirim..."
            sendChat(englishText)
            
            task.wait(0.5)
            
            TranslateBtn.Text = "Terkirim!"
            TranslateBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 100)
            task.wait(1)
            TranslateBtn.Text = "TRANSLATE"
            TranslateBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
            
            InputBox.Text = ""
        else
            TranslateBtn.Text = "GAGAL!"
            TranslateBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
            task.wait(1.5)
            TranslateBtn.Text = "TRANSLATE"
            TranslateBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        end
    else
        TranslateBtn.Text = "TEKS KOSONG"
        TranslateBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        task.wait(1)
        TranslateBtn.Text = "TRANSLATE"
        TranslateBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    end
end)

-- Enter key to send
InputBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        TranslateBtn.MouseButton1Click:Fire()
    end
end)

-- Minimize/Maximize Functions
local function minimizeGUI()
    MainFrame.Visible = false
    MinimizedBtn.Visible = true
end

local function maximizeGUI()
    MinimizedBtn.Visible = false
    MainFrame.Visible = true
end

-- Minimize Button Click
MinimizeBtn.MouseButton1Click:Connect(function()
    minimizeGUI()
end)

-- Minimized Button Click
MinimizedBtn.MouseButton1Click:Connect(function()
    maximizeGUI()
end)

-- Close Button Click
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)