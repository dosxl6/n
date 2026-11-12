local BLACK = Color3.fromRGB(25, 25, 35)
local DARK_GRAY = Color3.fromRGB(35, 35, 45)
local WHITE = Color3.fromRGB(255, 255, 255)
local SKY_BLUE = Color3.fromRGB(70, 130, 255)
local BLUE_STROKE = Color3.fromRGB(70, 130, 255)
local MENU_ALPHA = 0.95

-- OPTIMIZED: Menggunakan thumbnail format untuk loading lebih cepat
local ICON_IMAGE = "rbxthumb://type=Asset&id=11560341824&w=150&h=150"

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- Load notification system
loadstring(game:HttpGet("https://raw.githubusercontent.com/dosxl6/n/refs/heads/main/han.lua"))()

-- Get creator thumbnail
local creatorUserId = nil
local creatorThumbnail = ""
local success, result = pcall(function()
    return Players:GetUserIdFromNameAsync("akuramaa_xd")
end)
if success then
    creatorUserId = result
    success, result = pcall(function()
        return Players:GetUserThumbnailAsync(creatorUserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if success then
        creatorThumbnail = result
    end
end

-- Notification function using new system
local function sendNotif(titleT, textT)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = titleT,
            Text = textT,
            Duration = 3
        })
    end)
end

-- State
local selectedProductId = nil
local selectedProductName = ""
local spamBuyActive = false
local spamBuyConnection = nil

-- Bypass function
local function Finished(id)
	pcall(function()
		MarketplaceService:SignalPromptProductPurchaseFinished(player.UserId, id, true)
	end)
end

-- Function spam buy
local function startSpamBuy()
    if not selectedProductId then        
        getgenv().Notify({Title = 'TERJADI KESALAHAN', Content = "Pilih item terlebih dahulu!", Duration = 3})
        return
    end
    
    spamBuyActive = true
    while spamBuyActive and selectedProductId do
        Finished(selectedProductId)
        task.wait(0.1)
    end
end

-- Hover effect function
local function hover(btn, col)
	local orig = btn.BackgroundColor3
	btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.16), {BackgroundColor3 = col}):Play() end)
	btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.16), {BackgroundColor3 = orig}):Play() end)
end

-- GUI interface
local function createSIEXTHERHan()
    local PlayerGui = player:WaitForChild("PlayerGui")
    if PlayerGui:FindFirstChild("SIEXTHERHan") then PlayerGui["SIEXTHERHan"]:Destroy() end

    local main = Instance.new("ScreenGui")
    main.Name = "SIEXTHERHan"
    main.ResetOnSpawn = false
    main.Parent = PlayerGui

    -- Main frame
    local Frame = Instance.new("Frame")
    Frame.Name = "Frame"
    Frame.Size = UDim2.new(0, 240, 0, 290)
    Frame.Position = UDim2.new(0.5, -120, 0.5, -145)
    Frame.BackgroundColor3 = BLACK
    
    Frame.BorderSizePixel = 0
    Frame.Active = false
    Frame.ClipsDescendants = true
    Frame.Parent = main
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 10)
    frameCorner.Parent = Frame
    
    -- Blue stroke
    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = BLUE_STROKE
    frameStroke.Thickness = 2
    frameStroke.Parent = Frame

    -- Floating button (hidden initially) - CHANGED TO FRAME
    local floatingBtn = Instance.new("Frame")
    floatingBtn.Name = "FloatingButton"
    floatingBtn.Size = UDim2.new(0, 41, 0, 41)
    floatingBtn.Position = UDim2.new(1, -65, 0, 15)
    floatingBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    floatingBtn.Visible = false
    floatingBtn.Parent = main
    
    local floatCorner = Instance.new("UICorner")
    floatCorner.CornerRadius = UDim.new(0, 12)
    floatCorner.Parent = floatingBtn

    -- ADD IMAGEBUTTON INSIDE FLOATING BUTTON (OPTIMIZED)
    local floatImage = Instance.new("ImageButton")
    floatImage.Name = "FloatIcon"
    floatImage.Size = UDim2.new(1, -6, 1, -6)
    floatImage.Position = UDim2.new(0, 3, 0, 3)
    floatImage.BackgroundTransparency = 1
    floatImage.Image = ICON_IMAGE  -- OPTIMIZED
    floatImage.ScaleType = Enum.ScaleType.Fit
    floatImage.Parent = floatingBtn
    
    local floatIconCorner = Instance.new("UICorner")
    floatIconCorner.CornerRadius = UDim.new(0, 10)
    floatIconCorner.Parent = floatImage

    -- Title bar for dragging
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = Frame
    titleBar.Active = true

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -70, 0, 35)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.Text = "SIEXTHER FAKE DONATE"
    title.TextColor3 = WHITE
    title.BackgroundTransparency = 1
    title.BorderSizePixel = 0
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    -- Minimize button
    local miniBtn = Instance.new("TextButton")
    miniBtn.Name = "MinimizeButton"
    miniBtn.Size = UDim2.new(0, 28, 0, 28)
    miniBtn.Position = UDim2.new(1, -62, 0, 3.5)
    miniBtn.Text = "–"
    miniBtn.Font = Enum.Font.GothamBold
    miniBtn.TextSize = 18
    miniBtn.TextColor3 = WHITE
    miniBtn.BackgroundColor3 = DARK_GRAY
    miniBtn.Parent = titleBar
    
    local miniCorner = Instance.new("UICorner")
    miniCorner.CornerRadius = UDim.new(0, 6)
    miniCorner.Parent = miniBtn
    hover(miniBtn, Color3.fromRGB(50, 50, 60))

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -32, 0, 3.5)
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = Color3.fromRGB(255, 70, 70)
    closeBtn.BackgroundColor3 = DARK_GRAY
    closeBtn.Parent = titleBar
    closeBtn.ZIndex = 2
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    hover(closeBtn, Color3.fromRGB(255, 100, 100))

    local draggingTitleBar = false
    local dragStart, startPos

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingTitleBar = true
            dragStart = input.Position
            startPos = Frame.Position
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingTitleBar = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingTitleBar and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Dragging for floating button - UPDATED TO USE IMAGEBUTTON
    local draggingFloat = false
    local floatDragStart, floatStartPos

    floatImage.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingFloat = true
            floatDragStart = input.Position
            floatStartPos = floatingBtn.Position
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingFloat = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingFloat and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - floatDragStart
            floatingBtn.Position = UDim2.new(floatStartPos.X.Scale, floatStartPos.X.Offset + delta.X, floatStartPos.Y.Scale, floatStartPos.Y.Offset + delta.Y)
        end
    end)

    local minimized = false
    miniBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Frame.Visible = false
            floatingBtn.Visible = true
        else
            Frame.Visible = true
            floatingBtn.Visible = false
        end
    end)

    -- Floating button click to restore - UPDATED TO USE IMAGEBUTTON
    floatImage.MouseButton1Click:Connect(function()
        Frame.Visible = true
        floatingBtn.Visible = false
        minimized = false
    end)

    -- Close logic
    closeBtn.MouseButton1Click:Connect(function()
        main:Destroy()
    end)

    -- Scroll list
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -83)
    scroll.Position = UDim2.new(0, 10, 0, 45)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = BLUE_STROKE
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.None
    scroll.ClipsDescendants = true
    scroll.Parent = Frame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = scroll

    -- Button container di bawah (HORIZONTAL layout)
    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(1, -20, 0, 28)
    btnContainer.Position = UDim2.new(0, 10, 1, -38)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = Frame

    -- Purchase button (sky blue) - LEFT side
    local buy = Instance.new("TextButton")
    buy.Name = "BuyButton"
    buy.Text = "BUY"
    buy.Font = Enum.Font.GothamBold
    buy.TextSize = 12
    buy.TextColor3 = WHITE
    buy.BackgroundColor3 = SKY_BLUE
    buy.Size = UDim2.new(0.48, 0, 1, 0)
    buy.Position = UDim2.new(0, 0, 0, 0)
    buy.Active = false
    buy.Parent = btnContainer
    Instance.new("UICorner", buy).CornerRadius = UDim.new(0, 8)
    hover(buy, Color3.fromRGB(90, 150, 255))

    -- SPAM BUY button (sky blue) - RIGHT side
    local spamBuy = Instance.new("TextButton")
    spamBuy.Name = "SpamBuyButton"
    spamBuy.Text = "SPAM BUY"
    spamBuy.Font = Enum.Font.GothamBold
    spamBuy.TextSize = 12
    spamBuy.TextColor3 = WHITE
    spamBuy.BackgroundColor3 = SKY_BLUE
    spamBuy.Size = UDim2.new(0.48, 0, 1, 0)
    spamBuy.Position = UDim2.new(0.52, 0, 0, 0)
    spamBuy.Active = false
    spamBuy.Parent = btnContainer
    Instance.new("UICorner", spamBuy).CornerRadius = UDim.new(0, 8)
    hover(spamBuy, Color3.fromRGB(90, 150, 255))

    -- Card template
    local temp = Instance.new("Frame")
    temp.Size = UDim2.new(1, 0, 0, 48)
    temp.BackgroundColor3 = DARK_GRAY
    temp.BackgroundTransparency = 0.18
    temp.Visible = false
    temp.Parent = scroll
    Instance.new("UICorner", temp).CornerRadius = UDim.new(0, 8)

    local hbg = Instance.new("Frame")
    hbg.Size = UDim2.new(1, 0, 1, 0)
    hbg.BackgroundColor3 = DARK_GRAY
    hbg.BackgroundTransparency = 1
    hbg.Name = "HoverBg"
    hbg.Parent = temp
    Instance.new("UICorner", hbg).CornerRadius = UDim.new(0, 8)

    local sbg = Instance.new("Frame")
    sbg.Size = UDim2.new(1, 0, 1, 0)
    sbg.BackgroundColor3 = BLUE_STROKE
    sbg.BackgroundTransparency = 1
    sbg.Name = "SelectedBg"
    sbg.Parent = temp
    Instance.new("UICorner", sbg).CornerRadius = UDim.new(0, 8)

    -- Icon ImageLabel (OPTIMIZED)
    local icon = Instance.new("ImageLabel")
    icon.Name = "ItemIcon"
    icon.Size = UDim2.new(0, 38, 0, 38)
    icon.Position = UDim2.new(0, 5, 0.5, -19)
    icon.BackgroundTransparency = 1
    icon.Image = ICON_IMAGE  -- OPTIMIZED: Menggunakan thumbnail
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = temp
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 6)
    iconCorner.Parent = icon

    local n = Instance.new("TextLabel")
    n.Name = "NameLabel"
    n.Text = "Name: ..."
    n.Font = Enum.Font.GothamBold
    n.TextColor3 = WHITE
    n.TextSize = 11
    n.BackgroundTransparency = 1
    n.Size = UDim2.new(0.65, -48, 0, 18)
    n.Position = UDim2.new(0, 48, 0, 4)
    n.TextXAlignment = Enum.TextXAlignment.Left
    n.Parent = temp

    local p = Instance.new("TextLabel")
    p.Name = "PriceLabel"
    p.Text = "0 Robux"
    p.Font = Enum.Font.GothamBold
    p.TextColor3 = Color3.fromRGB(155, 155, 155)
    p.TextSize = 10
    p.BackgroundTransparency = 1
    p.Size = UDim2.new(0.4, 0, 0, 16)
    p.Position = UDim2.new(0, 48, 0, 26)
    p.TextXAlignment = Enum.TextXAlignment.Left
    p.Parent = temp

    local clk = Instance.new("TextButton")
    clk.Size = UDim2.new(1, 0, 1, 0)
    clk.BackgroundTransparency = 1
    clk.Text = ""
    clk.Name = "Click"
    clk.Parent = temp

    -- Load products + sort by price
    task.spawn(function()
        local success, products = pcall(MarketplaceService.GetDeveloperProductsAsync, MarketplaceService)
        if not success then 
            getgenv().Notify({Title = 'TERJADI KESALAHAN', Content = "Gagal memuat produk", Duration = 3})
            return 
        end

        local all = {}
        local page = products
        repeat
            for _, v in ipairs(page:GetCurrentPage()) do
                table.insert(all, v)
            end
            if not page.IsFinished then
                page:AdvanceToNextPageAsync()
                task.wait(0.05)
            end
        until page.IsFinished

        if #all == 0 then 
            getgenv().Notify({Title = 'TERJADI KESALAHAN', Content = "Tidak ada item yang ditemukan!", Duration = 3})
            return 
        end

        for _, c in ipairs(scroll:GetChildren()) do
            if c:IsA("Frame") and c ~= temp then c:Destroy() end
        end

        -- Sort from lowest to highest price
        table.sort(all, function(a, b)
            local priceA = a.PriceInRobux or 0
            local priceB = b.PriceInRobux or 0
            return priceA < priceB
        end)

        getgenv().Notify({Title = "MEMUAT", Content = #all .. " items", Duration = 4})

        local totalH = 0
        for _, info in ipairs(all) do
            local card = temp:Clone()
            card.Visible = true
            card.Parent = scroll
            card.NameLabel.Text = (info.Name or "???")
            card.PriceLabel.Text = (info.PriceInRobux or 0) .. " Robux"

            -- Hover effect
            card.Click.MouseEnter:Connect(function()
                if selectedProductId ~= info.ProductId then
                    TweenService:Create(card.HoverBg, TweenInfo.new(0.2), {BackgroundTransparency = 0.58}):Play()
                end
            end)
            card.Click.MouseLeave:Connect(function()
                if selectedProductId ~= info.ProductId then
                    TweenService:Create(card.HoverBg, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                end
            end)

            -- Select/Unselect
            card.Click.MouseButton1Click:Connect(function()
                if selectedProductId == info.ProductId then
                    -- Unselect
                    selectedProductId = nil
                    selectedProductName = ""
                    buy.Active = false
                    spamBuy.Active = false

                    TweenService:Create(card.SelectedBg, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                else
                    -- Select
                    selectedProductId = info.ProductId
                    selectedProductName = info.Name or "Unknown"
                    buy.Active = true
                    spamBuy.Active = true

                    for _, otherCard in ipairs(scroll:GetChildren()) do
                        if otherCard:IsA("Frame") and otherCard:FindFirstChild("SelectedBg") and otherCard ~= card then
                            TweenService:Create(otherCard.SelectedBg, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                        end
                    end
                    TweenService:Create(card.SelectedBg, TweenInfo.new(0.2), {BackgroundTransparency = 0.75}):Play()
                end
            end)

            totalH = totalH + card.Size.Y.Offset + layout.Padding.Offset
        end

        scroll.CanvasSize = UDim2.new(0, 0, 0, totalH + 8)
    end)

    -- Purchase button
    buy.MouseButton1Click:Connect(function()
        if not selectedProductId then 
            getgenv().Notify({Title = 'TERJADI KESALAHAN', Content = "Pilih item terlebih dahulu!", Duration = 3})
            return 
        end
        
        Finished(selectedProductId)
        getgenv().Notify({Title = 'SUCCESS', Content = "Pembelian berhasil!", Duration = 3})
        
        task.delay(1, function()
            buy.Text = "BUY"
            buy.BackgroundColor3 = SKY_BLUE
        end)
    end)

    -- Spam buy button
    spamBuy.MouseButton1Click:Connect(function()
        if not selectedProductId then
            getgenv().Notify({Title = 'TERJADI KESALAHAN', Content = "Pilih item terlebih dahulu!", Duration = 3})
            return
        end
        
        if spamBuyActive then
            spamBuyActive = false
            if spamBuyConnection then
                spamBuyConnection:Disconnect()
            end
            getgenv().Notify({Title = 'SPAM BUY', Content = 'DIMATIKAN', Duration = 3})
            spamBuy.Text = "SPAM BUY"
            spamBuy.BackgroundColor3 = SKY_BLUE
        else
            spamBuy.Text = "STOP"
            getgenv().Notify({Title = 'SPAM BUY', Content = 'AKTIF', Duration = 3})
            spamBuy.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            startSpamBuy()
        end
    end)

    return main
end

-- Initialize GUI
local guiInstance = createSIEXTHERHan()
guiInstance.Enabled = true