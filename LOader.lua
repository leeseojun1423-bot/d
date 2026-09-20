local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- =========================================================
-- 설정
-- =========================================================

local API_URL =
    "https://elementary-gage-dimensions-clerk.trycloudflare.com/validate"

-- =========================================================
-- ScreenGui
-- =========================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UconfigEKeyUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- =========================================================
-- 메인 창
-- =========================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(430, 260)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

-- =========================================================
-- 상단 바
-- =========================================================

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 50)
TopBar.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -110, 1, 0)
Title.Position = UDim2.fromOffset(15, 0)
Title.BackgroundTransparency = 1
Title.Text = "UconfigE - KEY 인증"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 19
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- =========================================================
-- 최소화 버튼
-- =========================================================

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.fromOffset(40, 40)
MinimizeButton.Position = UDim2.new(1, -90, 0, 5)
MinimizeButton.BackgroundTransparency = 1
MinimizeButton.Text = "—"
MinimizeButton.TextColor3 = Color3.fromRGB(220, 220, 220)
MinimizeButton.TextSize = 22
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Parent = TopBar

-- =========================================================
-- 닫기 버튼
-- =========================================================

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.fromOffset(40, 40)
CloseButton.Position = UDim2.new(1, -45, 0, 5)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseButton.TextSize = 25
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = TopBar

-- =========================================================
-- 내용 영역
-- =========================================================

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 1, -50)
Content.Position = UDim2.fromOffset(0, 50)
Content.BackgroundTransparency = 1
Content.Parent = Main

-- =========================================================
-- KEY 입력창
-- =========================================================

local KeyBox = Instance.new("TextBox")
KeyBox.Name = "KeyBox"
KeyBox.Size = UDim2.new(1, -40, 0, 45)
KeyBox.Position = UDim2.fromOffset(20, 25)
KeyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
KeyBox.BorderSizePixel = 0
KeyBox.PlaceholderText = "발급받은 KEY를 입력하세요"
KeyBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyBox.TextSize = 16
KeyBox.Font = Enum.Font.Gotham
KeyBox.ClearTextOnFocus = false
KeyBox.Parent = Content

local KeyBoxCorner = Instance.new("UICorner")
KeyBoxCorner.CornerRadius = UDim.new(0, 8)
KeyBoxCorner.Parent = KeyBox

-- =========================================================
-- 인증 버튼
-- =========================================================

local VerifyButton = Instance.new("TextButton")
VerifyButton.Name = "VerifyButton"
VerifyButton.Size = UDim2.new(1, -40, 0, 45)
VerifyButton.Position = UDim2.fromOffset(20, 85)
VerifyButton.BackgroundColor3 = Color3.fromRGB(128, 213, 247)
VerifyButton.BorderSizePixel = 0
VerifyButton.Text = "KEY 인증"
VerifyButton.TextColor3 = Color3.fromRGB(20, 20, 20)
VerifyButton.TextSize = 16
VerifyButton.Font = Enum.Font.GothamBold
VerifyButton.Parent = Content

local VerifyCorner = Instance.new("UICorner")
VerifyCorner.CornerRadius = UDim.new(0, 8)
VerifyCorner.Parent = VerifyButton

-- =========================================================
-- 상태 표시
-- =========================================================

local Status = Instance.new("TextLabel")
Status.Name = "Status"
Status.Size = UDim2.new(1, -40, 0, 40)
Status.Position = UDim2.fromOffset(20, 140)
Status.BackgroundTransparency = 1
Status.Text = "KEY를 입력해주세요."
Status.TextColor3 = Color3.fromRGB(180, 180, 180)
Status.TextSize = 14
Status.Font = Enum.Font.Gotham
Status.TextWrapped = true
Status.Parent = Content

-- =========================================================
-- 크기 조절 핸들
-- =========================================================

local ResizeHandle = Instance.new("TextButton")
ResizeHandle.Name = "ResizeHandle"
ResizeHandle.Size = UDim2.fromOffset(25, 25)
ResizeHandle.Position = UDim2.new(1, -25, 1, -25)
ResizeHandle.BackgroundTransparency = 1
ResizeHandle.Text = "◢"
ResizeHandle.TextColor3 = Color3.fromRGB(130, 130, 140)
ResizeHandle.TextSize = 16
ResizeHandle.Parent = Main

-- =========================================================
-- 창 드래그
-- PC + 모바일
-- =========================================================

local Dragging = false
local DragStart = nil
local StartPosition = nil

local function StartDrag(Input)
    Dragging = true
    DragStart = Input.Position
    StartPosition = Main.Position
end

local function UpdateDrag(Input)
    if not Dragging then
        return
    end

    local Delta = Input.Position - DragStart

    Main.Position = UDim2.new(
        StartPosition.X.Scale,
        StartPosition.X.Offset + Delta.X,
        StartPosition.Y.Scale,
        StartPosition.Y.Offset + Delta.Y
    )
end

local function StopDrag()
    Dragging = false
end

TopBar.InputBegan:Connect(function(Input)

    if Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.Touch then

        StartDrag(Input)
    end
end)

UserInputService.InputChanged:Connect(function(Input)

    if Input.UserInputType == Enum.UserInputType.MouseMovement
        or Input.UserInputType == Enum.UserInputType.Touch then

        UpdateDrag(Input)
    end
end)

UserInputService.InputEnded:Connect(function(Input)

    if Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.Touch then

        StopDrag()
    end
end)

-- =========================================================
-- 최소화
-- =========================================================

local Minimized = false
local NormalSize = Main.Size

MinimizeButton.MouseButton1Click:Connect(function()

    Minimized = not Minimized

    if Minimized then
        NormalSize = Main.Size

        Content.Visible = false
        ResizeHandle.Visible = false

        Main.Size = UDim2.fromOffset(
            NormalSize.X.Offset,
            50
        )

        MinimizeButton.Text = "□"

    else

        Main.Size = NormalSize

        Content.Visible = true
        ResizeHandle.Visible = true

        MinimizeButton.Text = "—"
    end
end)

-- =========================================================
-- 닫기
-- =========================================================

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- =========================================================
-- 크기 조절
-- =========================================================

local Resizing = false
local ResizeStart = nil
local ResizeStartSize = nil

ResizeHandle.InputBegan:Connect(function(Input)

    if Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.Touch then

        Resizing = true
        ResizeStart = Input.Position
        ResizeStartSize = Main.Size
    end
end)

UserInputService.InputChanged:Connect(function(Input)

    if not Resizing then
        return
    end

    if Input.UserInputType ~= Enum.UserInputType.MouseMovement
        and Input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local Delta = Input.Position - ResizeStart

    local NewWidth = math.max(
        320,
        ResizeStartSize.X.Offset + Delta.X
    )

    local NewHeight = math.max(
        220,
        ResizeStartSize.Y.Offset + Delta.Y
    )

    Main.Size = UDim2.fromOffset(
        NewWidth,
        NewHeight
    )
end)

UserInputService.InputEnded:Connect(function(Input)

    if Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.Touch then

        Resizing = false
    end
end)

-- =========================================================
-- KEY API 검증
-- =========================================================

local function ValidateKey(Key)

    if Key == nil or Key == "" then
        return false, "KEY를 입력해주세요."
    end

    local Success, Response = pcall(function()

        return game:HttpGet(
            API_URL .. "?key=" .. HttpService:UrlEncode(Key)
        )

    end)

    if not Success then
        return false, "API 서버에 연결할 수 없습니다."
    end

    local DecodeSuccess, Data = pcall(function()

        return HttpService:JSONDecode(Response)

    end)

    if not DecodeSuccess or type(Data) ~= "table" then
        return false, "API 응답을 읽을 수 없습니다."
    end

    if Data.valid == true then
        return true, "KEY 인증 성공!"
    end

    if Data.reason == "expired" then
        return false, "KEY가 만료되었습니다."

    elseif Data.reason == "invalid_key" then
        return false, "존재하지 않는 KEY입니다."

    elseif Data.reason == "invalid_format" then
        return false, "KEY 형식이 올바르지 않습니다."
    end

    return false, "KEY 인증에 실패했습니다."
end

-- =========================================================
-- 인증 성공
-- =========================================================

local function OnAuthenticated()

    Status.Text = "KEY 인증 성공!"
    Status.TextColor3 = Color3.fromRGB(100, 255, 140)

    VerifyButton.Text = "인증 완료"

    task.wait(0.5)

    ScreenGui:Destroy()

    -- =====================================================
    loadstring(game:HttpGet("https://raw.githubusercontent.com/leeseojun1423-bot/d/refs/heads/main/Main.lua"))()
    -- =====================================================

    print("[UconfigE] 인증 성공")
end

-- =========================================================
-- 인증 버튼
-- =========================================================

VerifyButton.MouseButton1Click:Connect(function()

    local Key = KeyBox.Text

    VerifyButton.Text = "확인 중..."
    VerifyButton.Active = false

    Status.Text = "서버에서 KEY를 확인하고 있습니다..."
    Status.TextColor3 = Color3.fromRGB(255, 220, 100)

    task.spawn(function()

        local Success, Message = ValidateKey(Key)

        if Success then

            OnAuthenticated()

        else

            Status.Text = Message
            Status.TextColor3 = Color3.fromRGB(255, 100, 100)

            VerifyButton.Text = "KEY 인증"
            VerifyButton.Active = true

        end
    end)
end)

-- =========================================================
-- 시작 메시지
-- =========================================================

print("[UconfigE] KEY UI 실행 완료")
