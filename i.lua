
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera


local CatalogRemote
local CatalogRemoteFound = false

pcall(function()
    local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes", 10)

    if BloxbizRemotes then
        CatalogRemote = BloxbizRemotes:WaitForChild(
            "CatalogOnApplyOutfit",
            10
        )
    end

    CatalogRemoteFound = CatalogRemote ~= nil
end)

pcall(function()
    loadstring(
        game:HttpGet(
            "https://raw.githubusercontent.com/WxTqmv/OsQv14bs/refs/heads/main/han.lua"
        )
    )()
end)

local function notify(title, content, duration)
    pcall(function()
        if getgenv and getgenv().Notify then
            getgenv().Notify({
                Title = title,
                Content = content,
                Duration = duration or 3
            })
        end
    end)
end

if not CatalogRemoteFound then
    notify(
        "SIEXTHER AVATAR",
        "TERJADI KESALAHAN",
        5
    )
    return
end

local State = {
    Open = false,
    SelectedPlayer = nil,
    Viewing = false,
    OriginalCameraSubject = nil,
    Destroyed = false,
    SearchQuery = ""
}

--==================================================
-- COLORS
--==================================================

local COLORS = {
    Background = Color3.fromRGB(18, 18, 22),
    Surface = Color3.fromRGB(25, 25, 30),
    Surface2 = Color3.fromRGB(30, 30, 35),
    Hover = Color3.fromRGB(40, 40, 45),

    Primary = Color3.fromRGB(70, 130, 255),
    PrimaryHover = Color3.fromRGB(90, 150, 255),

    White = Color3.fromRGB(255, 255, 255),
    Gray = Color3.fromRGB(120, 120, 120),
    LightGray = Color3.fromRGB(180, 180, 180),

    Success = Color3.fromRGB(0, 255, 100),
    Warning = Color3.fromRGB(255, 200, 0),
    Error = Color3.fromRGB(255, 80, 80),
    Danger = Color3.fromRGB(255, 60, 70)
}

--==================================================
-- HELPERS
--==================================================

local function notifyStatus(text, color)
    if text then
        notify("SIEXTHER AVATAR", tostring(text), 3)
    end
end

local function resetStatus(delayTime)
    -- Status footer sudah dihapus.
end

local function makeCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = object
    return corner
end

local function makeStroke(object, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness or 1
    stroke.Parent = object
    return stroke
end

local function makeDraggable(frame)
    local dragging = false
    local dragInput
    local dragStart
    local startPosition

    local function update(input)
        if not dragging then
            return
        end

        local delta = input.Position - dragStart

        frame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

local function createButton(parent, name, text, position, size, color)
    local button = Instance.new("TextButton")

    button.Name = name
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = color or COLORS.Primary
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = COLORS.White
    button.Font = Enum.Font.GothamBold
    button.TextSize = 10
    button.AutoButtonColor = false
    button.Parent = parent

    makeCorner(button, 6)

    button.MouseEnter:Connect(function()
        TweenService:Create(
            button,
            TweenInfo.new(0.15),
            {
                BackgroundColor3 = COLORS.PrimaryHover
            }
        ):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(
            button,
            TweenInfo.new(0.15),
            {
                BackgroundColor3 = color or COLORS.Primary
            }
        ):Play()
    end)

    return button
end

--==================================================
-- AVATAR DATA
--==================================================

local function getAvatarDescription(player)
    if not player then
        return nil
    end

    if not player.Character then
        return nil
    end

    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        return nil
    end

    local success, description = pcall(function()
        return humanoid:GetAppliedDescription()
    end)

    if success and description then
        return description
    end

    return nil
end

--==================================================
-- APPLY AVATAR
--==================================================

local function applyAvatarDescription(description)
    if not description then
        return false, "Avatar description tidak valid."
    end

    if not CatalogRemote then
        return false, "CatalogOnApplyOutfit tidak ditemukan."
    end

    local accessories = {}

    local successAccessories = pcall(function()
        for _, accessory in ipairs(description:GetAccessories(true)) do
            table.insert(accessories, {
                AccessoryType = accessory.AccessoryType,
                AssetId = accessory.AssetId,
                Order = accessory.Order,
                Puffiness = accessory.Puffiness
            })
        end
    end)

    if not successAccessories then
        return false, "Gagal membaca accessories avatar."
    end

    local outfit = {
        Accessories = accessories,

        BodyTypeScale = description.BodyTypeScale,
        HeadScale = description.HeadScale,
        ProportionScale = description.ProportionScale,

        Face = description.Face,
        GraphicTShirt = description.GraphicTShirt,
        Head = description.Head,

        HeadColor = description.HeadColor,
        HeightScale = description.HeightScale,

        LeftArm = description.LeftArm,
        LeftArmColor = description.LeftArmColor,

        LeftLeg = description.LeftLeg,
        LeftLegColor = description.LeftLegColor,

        Pants = description.Pants,

        RightArm = description.RightArm,
        RightArmColor = description.RightArmColor,

        RightLeg = description.RightLeg,
        RightLegColor = description.RightLegColor,

        Shirt = description.Shirt,

        Torso = description.Torso,
        TorsoColor = description.TorsoColor,

        WidthScale = description.WidthScale,
        DepthScale = description.DepthScale,

        ClimbAnimation = description.ClimbAnimation,
        FallAnimation = description.FallAnimation,
        IdleAnimation = description.IdleAnimation,
        JumpAnimation = description.JumpAnimation,
        RunAnimation = description.RunAnimation,
        SwimAnimation = description.SwimAnimation,
        WalkAnimation = description.WalkAnimation
    }

    local success, err = pcall(function()
        CatalogRemote:FireServer(outfit)
    end)

    if not success then
        return false, "Remote gagal dijalankan: " .. tostring(err)
    end

    return true
end

--==================================================
-- COPY PLAYER AVATAR
--==================================================

local function copyAvatar(player)
    if not player then
        return false, "Pilih pemain terlebih dahulu."
    end

    if player == LocalPlayer then
        return false, "Tidak dapat menyalin avatar sendiri."
    end

    if not player.Character then
        return false, "Character pemain tidak ditemukan."
    end

    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        return false, "Humanoid pemain tidak ditemukan."
    end

    local description

    local success, result = pcall(function()
        return humanoid:GetAppliedDescription()
    end)

    if not success or not result then
        return false, "Gagal mengambil data avatar."
    end

    description = result

    local applied, errorMessage = applyAvatarDescription(description)

    if not applied then
        return false, errorMessage
    end

    return true, "Avatar copied from " .. player.Name
end

--==================================================
-- RESET AVATAR
--==================================================

local function resetAvatar()
    local success, description = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(
            LocalPlayer.UserId
        )
    end)

    if not success or not description then
        return false, "Gagal mengambil avatar default."
    end

    local applied, errorMessage = applyAvatarDescription(description)

    if not applied then
        return false, errorMessage
    end

    return true, "Avatar reset to default."
end

--==================================================
-- TELEPORT
--==================================================

local function teleportToPlayer(player)
    if not player then
        return false, "Pilih pemain terlebih dahulu."
    end

    if player == LocalPlayer then
        return false, "Kamu sudah berada di pemain sendiri."
    end

    local targetCharacter = player.Character
    local myCharacter = LocalPlayer.Character

    if not targetCharacter or not myCharacter then
        return false, "Character tidak ditemukan."
    end

    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")

    if not targetRoot then
        return false, "HumanoidRootPart target tidak ditemukan."
    end

    local success, err = pcall(function()
        myCharacter:PivotTo(
            targetRoot.CFrame + Vector3.new(0, 3, 0)
        )
    end)

    if not success then
        return false, "Teleport gagal: " .. tostring(err)
    end

    return true, "Teleported to " .. player.Name
end

--==================================================
-- PLAYER LIST
--==================================================

local function getPlayers()
    local result = {}
    local query = State.SearchQuery:lower()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if query == ""
                or player.Name:lower():find(query, 1, true)
                or player.DisplayName:lower():find(query, 1, true) then

                table.insert(result, player)
            end
        end
    end

    table.sort(result, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)

    return result
end

--==================================================
-- GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SiextherAvatar"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- TOGGLE / FLOATING BUTTON
--==================================================

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 38, 0, 38)
ToggleButton.Position = UDim2.new(0, 12, 0.5, -19)
ToggleButton.BackgroundColor3 = COLORS.Surface
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "🎮"
ToggleButton.TextColor3 = COLORS.White
ToggleButton.TextScaled = true
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.AutoButtonColor = false
ToggleButton.ZIndex = 20
ToggleButton.Visible = true
ToggleButton.Parent = ScreenGui

makeCorner(ToggleButton, 10)
makeStroke(ToggleButton, COLORS.Primary, 1)
makeDraggable(ToggleButton)

--==================================================
-- MAIN FRAME
--==================================================

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 270, 0, 272)
MainFrame.Position = UDim2.new(0.5, -135, 0.5, -170)
MainFrame.BackgroundColor3 = COLORS.Background
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

makeCorner(MainFrame, 10)
makeStroke(MainFrame, COLORS.Primary, 2)
makeDraggable(MainFrame)

--==================================================
-- TITLE BAR
--==================================================

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = COLORS.Surface
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

makeCorner(TitleBar, 10)

local TitleText = Instance.new("TextLabel")
TitleText.Name = "TitleText"
TitleText.Size = UDim2.new(1, -88, 1, 0)
TitleText.Position = UDim2.new(0, 10, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "SIEXTHER AVATAR"
TitleText.TextColor3 = COLORS.Primary
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 13
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

--==================================================
-- MINIMIZE BUTTON
--==================================================

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.new(0, 24, 0, 24)
MinimizeButton.Position = UDim2.new(1, -55, 0, 4)
MinimizeButton.BackgroundColor3 = COLORS.Surface2
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Text = "–"
MinimizeButton.TextColor3 = COLORS.White
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 16
MinimizeButton.AutoButtonColor = false
MinimizeButton.Parent = TitleBar

makeCorner(MinimizeButton, 6)

MinimizeButton.MouseEnter:Connect(function()
    TweenService:Create(
        MinimizeButton,
        TweenInfo.new(0.15),
        {
            BackgroundColor3 = COLORS.Hover
        }
    ):Play()
end)

MinimizeButton.MouseLeave:Connect(function()
    TweenService:Create(
        MinimizeButton,
        TweenInfo.new(0.15),
        {
            BackgroundColor3 = COLORS.Surface2
        }
    ):Play()
end)

--==================================================
-- CLOSE BUTTON
--==================================================

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 24, 0, 24)
CloseButton.Position = UDim2.new(1, -28, 0, 4)
CloseButton.BackgroundColor3 = COLORS.Danger
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = COLORS.White
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 12
CloseButton.AutoButtonColor = false
CloseButton.Parent = TitleBar

makeCorner(CloseButton, 6)

--==================================================
-- SELECT LABEL
--==================================================

local SelectLabel = Instance.new("TextLabel")
SelectLabel.Name = "SelectLabel"
SelectLabel.Size = UDim2.new(1, -20, 0, 18)
SelectLabel.Position = UDim2.new(0, 10, 0, 39)
SelectLabel.BackgroundTransparency = 1
SelectLabel.Text = "SELECT PLAYER"
SelectLabel.TextColor3 = COLORS.Primary
SelectLabel.Font = Enum.Font.GothamBold
SelectLabel.TextSize = 10
SelectLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectLabel.Parent = MainFrame

--==================================================
-- SEARCH BAR
--==================================================

local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.Size = UDim2.new(1, -20, 0, 24)
SearchBox.Position = UDim2.new(0, 10, 0, 57)
SearchBox.BackgroundColor3 = COLORS.Surface
SearchBox.BorderSizePixel = 0
SearchBox.Text = ""
SearchBox.PlaceholderText = "Search player..."
SearchBox.PlaceholderColor3 = COLORS.Gray
SearchBox.TextColor3 = COLORS.White
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 9
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = MainFrame

makeCorner(SearchBox, 6)
makeStroke(SearchBox, COLORS.Surface2, 1)

local SearchPadding = Instance.new("UIPadding")
SearchPadding.PaddingLeft = UDim.new(0, 8)
SearchPadding.PaddingRight = UDim.new(0, 8)
SearchPadding.Parent = SearchBox

--==================================================
-- PLAYER LIST
--==================================================

local PlayerScrollFrame = Instance.new("ScrollingFrame")
PlayerScrollFrame.Name = "PlayerScrollFrame"
PlayerScrollFrame.Size = UDim2.new(1, -20, 0, 103)
PlayerScrollFrame.Position = UDim2.new(0, 10, 0, 85)
PlayerScrollFrame.BackgroundColor3 = COLORS.Surface
PlayerScrollFrame.BorderSizePixel = 0
PlayerScrollFrame.ScrollBarThickness = 3
PlayerScrollFrame.ScrollBarImageColor3 = COLORS.Primary
PlayerScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerScrollFrame.Parent = MainFrame

makeCorner(PlayerScrollFrame, 7)

local PlayerLayout = Instance.new("UIListLayout")
PlayerLayout.SortOrder = Enum.SortOrder.Name
PlayerLayout.Padding = UDim.new(0, 3)
PlayerLayout.Parent = PlayerScrollFrame

local PlayerPadding = Instance.new("UIPadding")
PlayerPadding.PaddingTop = UDim.new(0, 3)
PlayerPadding.PaddingBottom = UDim.new(0, 3)
PlayerPadding.PaddingLeft = UDim.new(0, 3)
PlayerPadding.PaddingRight = UDim.new(0, 3)
PlayerPadding.Parent = PlayerScrollFrame

--==================================================
-- SELECTED PLAYER
--==================================================

local SelectedLabel = Instance.new("TextLabel")
SelectedLabel.Name = "SelectedLabel"
SelectedLabel.Size = UDim2.new(1, -20, 0, 18)
SelectedLabel.Position = UDim2.new(0, 10, 0, 191)
SelectedLabel.BackgroundTransparency = 1
SelectedLabel.Text = "Selected: None"
SelectedLabel.TextColor3 = COLORS.Primary
SelectedLabel.Font = Enum.Font.GothamBold
SelectedLabel.TextSize = 10
SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectedLabel.TextTruncate = Enum.TextTruncate.AtEnd
SelectedLabel.Parent = MainFrame

--==================================================
-- BUTTON AREA
--==================================================

local ActionFrame = Instance.new("Frame")
ActionFrame.Name = "ActionFrame"
ActionFrame.Size = UDim2.new(1, -20, 0, 51)
ActionFrame.Position = UDim2.new(0, 10, 0, 213)
ActionFrame.BackgroundTransparency = 1
ActionFrame.Parent = MainFrame

local CopyButton = createButton(
    ActionFrame,
    "CopyButton",
    "COPY",
    UDim2.new(0, 0, 0, 0),
    UDim2.new(0.5, -3, 0, 23),
    COLORS.Primary
)

local ResetButton = createButton(
    ActionFrame,
    "ResetButton",
    "RESET",
    UDim2.new(0.5, 3, 0, 0),
    UDim2.new(0.5, -3, 0, 23),
    Color3.fromRGB(255, 80, 60)
)

local TeleportButton = createButton(
    ActionFrame,
    "TeleportButton",
    "TELEPORT",
    UDim2.new(0, 0, 0, 28),
    UDim2.new(0.5, -3, 0, 23),
    Color3.fromRGB(55, 115, 220)
)

local RefreshPlayerButton = createButton(
    ActionFrame,
    "RefreshPlayerButton",
    "REFRESH",
    UDim2.new(0.5, 3, 0, 28),
    UDim2.new(0.5, -3, 0, 23),
    Color3.fromRGB(55, 115, 220)
)

--==================================================
-- UPDATE CANVAS
--==================================================

local function updateCanvas()
    task.defer(function()
        if PlayerScrollFrame and PlayerScrollFrame.Parent then
            PlayerScrollFrame.CanvasSize = UDim2.new(
                0,
                0,
                0,
                PlayerLayout.AbsoluteContentSize.Y + 6
            )
        end
    end)
end

PlayerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

--==================================================
-- UPDATE PLAYER LIST
--==================================================

local function updatePlayerList()
    if State.Destroyed then
        return
    end

    for _, child in ipairs(PlayerScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local playerList = getPlayers()

    if #playerList == 0 then
        local EmptyFrame = Instance.new("Frame")
        EmptyFrame.Size = UDim2.new(1, -6, 0, 38)
        EmptyFrame.BackgroundColor3 = COLORS.Surface2
        EmptyFrame.BorderSizePixel = 0
        EmptyFrame.Parent = PlayerScrollFrame

        makeCorner(EmptyFrame, 6)

        local EmptyText = Instance.new("TextLabel")
        EmptyText.Size = UDim2.new(1, 0, 1, 0)
        EmptyText.BackgroundTransparency = 1

        if State.SearchQuery ~= "" then
            EmptyText.Text = "No players found"
        else
            EmptyText.Text = "No other players"
        end

        EmptyText.TextColor3 = COLORS.Gray
        EmptyText.Font = Enum.Font.Gotham
        EmptyText.TextSize = 10
        EmptyText.Parent = EmptyFrame

        updateCanvas()
        return
    end

    for _, player in ipairs(playerList) do
        local PlayerContainer = Instance.new("Frame")
        PlayerContainer.Name = player.Name .. "_Container"
        PlayerContainer.Size = UDim2.new(1, -6, 0, 40)

        if State.SelectedPlayer == player then
            PlayerContainer.BackgroundColor3 = COLORS.Primary
            PlayerContainer.BackgroundTransparency = 0.78
        else
            PlayerContainer.BackgroundColor3 = COLORS.Surface2
            PlayerContainer.BackgroundTransparency = 0
        end

        PlayerContainer.BorderSizePixel = 0
        PlayerContainer.Parent = PlayerScrollFrame

        makeCorner(PlayerContainer, 6)

        local AvatarImage = Instance.new("ImageLabel")
        AvatarImage.Name = "AvatarImage"
        AvatarImage.Size = UDim2.new(0, 32, 0, 32)
        AvatarImage.Position = UDim2.new(0, 4, 0, 4)
        AvatarImage.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        AvatarImage.BorderSizePixel = 0
        AvatarImage.Image =
            "rbxthumb://type=AvatarHeadShot&id="
            .. tostring(player.UserId)
            .. "&w=48&h=48"
        AvatarImage.ScaleType = Enum.ScaleType.Fit
        AvatarImage.Parent = PlayerContainer

        makeCorner(AvatarImage, 6)

        -- DISPLAY NAME DI ATAS
        local DisplayName = Instance.new("TextLabel")
        DisplayName.Name = "DisplayName"
        DisplayName.Size = UDim2.new(1, -46, 0, 17)
        DisplayName.Position = UDim2.new(0, 42, 0, 4)
        DisplayName.BackgroundTransparency = 1
        DisplayName.Text = player.DisplayName
        DisplayName.TextColor3 = COLORS.White
        DisplayName.Font = Enum.Font.GothamBold
        DisplayName.TextSize = 10
        DisplayName.TextXAlignment = Enum.TextXAlignment.Left
        DisplayName.TextTruncate = Enum.TextTruncate.AtEnd
        DisplayName.Parent = PlayerContainer

        -- USERNAME DI BAWAH, TETAP MENGGUNAKAN @
        local PlayerName = Instance.new("TextLabel")
        PlayerName.Name = "PlayerName"
        PlayerName.Size = UDim2.new(1, -46, 0, 13)
        PlayerName.Position = UDim2.new(0, 42, 0, 21)
        PlayerName.BackgroundTransparency = 1
        PlayerName.Text = "@" .. player.Name
        PlayerName.TextColor3 = COLORS.Gray
        PlayerName.Font = Enum.Font.Gotham
        PlayerName.TextSize = 8
        PlayerName.TextXAlignment = Enum.TextXAlignment.Left
        PlayerName.TextTruncate = Enum.TextTruncate.AtEnd
        PlayerName.Parent = PlayerContainer

        local SelectButton = Instance.new("TextButton")
        SelectButton.Name = "SelectButton"
        SelectButton.Size = UDim2.new(1, 0, 1, 0)
        SelectButton.BackgroundTransparency = 1
        SelectButton.BorderSizePixel = 0
        SelectButton.Text = ""
        SelectButton.AutoButtonColor = false
        SelectButton.Parent = PlayerContainer

        SelectButton.MouseButton1Click:Connect(function()
            State.SelectedPlayer = player

            SelectedLabel.Text = "Selected: " .. player.Name
            SelectedLabel.TextColor3 = COLORS.Primary

            for _, container in ipairs(PlayerScrollFrame:GetChildren()) do
                if container:IsA("Frame") then
                    if container.Name == player.Name .. "_Container" then
                        container.BackgroundColor3 = COLORS.Primary
                        container.BackgroundTransparency = 0.78
                    else
                        container.BackgroundColor3 = COLORS.Surface2
                        container.BackgroundTransparency = 0
                    end
                end
            end
        end)

        SelectButton.MouseEnter:Connect(function()
            if State.SelectedPlayer == player then
                TweenService:Create(
                    PlayerContainer,
                    TweenInfo.new(0.15),
                    {
                        BackgroundColor3 = COLORS.Primary,
                        BackgroundTransparency = 0.68
                    }
                ):Play()
            else
                TweenService:Create(
                    PlayerContainer,
                    TweenInfo.new(0.15),
                    {
                        BackgroundColor3 = COLORS.Hover,
                        BackgroundTransparency = 0
                    }
                ):Play()
            end
        end)

        SelectButton.MouseLeave:Connect(function()
            if State.SelectedPlayer == player then
                TweenService:Create(
                    PlayerContainer,
                    TweenInfo.new(0.15),
                    {
                        BackgroundColor3 = COLORS.Primary,
                        BackgroundTransparency = 0.78
                    }
                ):Play()
            else
                TweenService:Create(
                    PlayerContainer,
                    TweenInfo.new(0.15),
                    {
                        BackgroundColor3 = COLORS.Surface2,
                        BackgroundTransparency = 0
                    }
                ):Play()
            end
        end)
    end

    updateCanvas()
end

--==================================================
-- SEARCH
--==================================================

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    State.SearchQuery = SearchBox.Text or ""
    updatePlayerList()
end)

--==================================================
-- COPY BUTTON
--==================================================

CopyButton.MouseButton1Click:Connect(function()
    local player = State.SelectedPlayer

    if not player or not player.Parent then
        notify(
            "SIEXTHER AVATAR",
            "Silakan pilih pemain terlebih dahulu.",
            3
        )
        return
    end

    local success, message = copyAvatar(player)

    if success then
        notify(
            "SIEXTHER AVATAR",
            "Berhasil! " .. tostring(message),
            3
        )
    else
        notify(
            "SIEXTHER AVATAR",
            "Gagal!" .. tostring(message),
            3
        )
    end

    resetStatus(3)
end)

--==================================================
-- RESET BUTTON
--==================================================

ResetButton.MouseButton1Click:Connect(function()
    local success, message = resetAvatar()

    if success then
        notify(
            "SIEXTHER AVATAR",
            "Berhasil! " .. tostring(message),
            3
        )
    else
        notify(
            "RESET AVATAR",
            "Gagal!" .. tostring(message),
            3
        )
    end

    resetStatus(3)
end)

--==================================================
-- TELEPORT BUTTON
--==================================================

TeleportButton.MouseButton1Click:Connect(function()
    local player = State.SelectedPlayer

    if not player or not player.Parent then
        notify(
            "SIEXTHER AVATAR",
            "Silakan pilih pemain terlebih dahulu.",
            3
        )
        return
    end

    local success, message = teleportToPlayer(player)

    if success then
        notify(
            "SIEXTHER TELEPORT",
            "Berhasil! " .. tostring(message),
            3
        )
    else
        notify(
            "SIEXTHER TELEPORT",
            "Gagal! " .. tostring(message),
            3
        )
    end

    resetStatus(3)
end)

--==================================================
-- REFRESH PLAYER
--==================================================

RefreshPlayerButton.MouseButton1Click:Connect(function()
    updatePlayerList()

    notify(
        "SIEXTHER AVATAR",
        "Daftar pemain telah diperbarui.",
        3
    )
end)

--==================================================
-- TOGGLE UI / FLOATING ICON
--==================================================

local function toggleUI()
    if State.Destroyed then
        return
    end

    State.Open = not State.Open
    MainFrame.Visible = State.Open

    if State.Open then
        ToggleButton.Visible = false
        ToggleButton.Text = "🎮"
        ToggleButton.BackgroundColor3 = COLORS.Surface

        updatePlayerList()
    else
        ToggleButton.Visible = true
        ToggleButton.Text = "🎮"
        ToggleButton.BackgroundColor3 = COLORS.Surface
    end
end

ToggleButton.MouseButton1Click:Connect(toggleUI)

ToggleButton.MouseEnter:Connect(function()
    ToggleButton.BackgroundColor3 = COLORS.Hover
end)

ToggleButton.MouseLeave:Connect(function()
    ToggleButton.BackgroundColor3 = COLORS.Surface
end)

--==================================================
-- MINIMIZE
--==================================================

MinimizeButton.MouseButton1Click:Connect(function()
    if State.Destroyed then
        return
    end

    State.Open = false
    MainFrame.Visible = false

    ToggleButton.Visible = true
    ToggleButton.Text = "🎮"
    ToggleButton.BackgroundColor3 = COLORS.Surface

    
end)

--==================================================
-- CLOSE
--==================================================

CloseButton.MouseButton1Click:Connect(function()
    if State.Destroyed then
        return
    end

    State.Destroyed = true
    ScreenGui:Destroy()
end)

CloseButton.MouseEnter:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 80, 90)
end)

CloseButton.MouseLeave:Connect(function()
    CloseButton.BackgroundColor3 = COLORS.Danger
end)

--==================================================
-- F1 TOGGLE
--==================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or State.Destroyed then
        return
    end

    if input.KeyCode == Enum.KeyCode.F1 then
        toggleUI()
    end
end)

--==================================================
-- PLAYER EVENTS
--==================================================

Players.PlayerAdded:Connect(function()
    task.wait(0.5)

    if not State.Destroyed then
        updatePlayerList()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if State.SelectedPlayer == player then
        State.SelectedPlayer = nil
        SelectedLabel.Text = "Selected: None"
        SelectedLabel.TextColor3 = COLORS.Primary
    end

    if not State.Destroyed then
        task.wait(0.1)
        updatePlayerList()
    end
end)

--==================================================
-- CHARACTER RESPAWN
--==================================================

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(1)

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        Camera.CameraSubject = humanoid
    end
end)

--==================================================
-- ANTI AFK
--==================================================

LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0, 0))
        task.wait(0.1)
        VirtualUser:Button2Up(Vector2.new(0, 0))
    end)
end)

--==================================================
-- INITIALIZE
--==================================================

updatePlayerList()
