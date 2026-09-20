-- UconfigE Key Authentication
-- Key-only authentication UI
-- API: https://vacations-formed-produce-denied.trycloudflare.com

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- =========================================================
-- 설정
-- =========================================================

local API_URL =
    "https://vacations-formed-produce-denied.trycloudflare.com/validate"

-- =========================================================
-- 기존 UI 제거
-- =========================================================

pcall(function()
    local old = PlayerGui:FindFirstChild("UconfigEKeyUI")
    if old then
        old:Destroy()
    end
end)

-- =========================================================
-- ScreenGui
-- =========================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UconfigEKeyUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- =========================================================
-- Main
-- =========================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 430, 0, 300)
Main.Position = UDim2.new(0.5, -215, 0.5, -150)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

-- =========================================================
-- Shadow
-- =========================================================

local Shadow = Instance.new("Frame")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(1, 12, 1, 12)
Shadow.Position = UDim2.new(0, -6, 0, -6)
Shadow.BackgroundTransparency = 1
Shadow.ZIndex = 0
Shadow.Parent = Main

-- =========================================================
-- Top Bar
-- =========================================================

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 48)
TopBar.BackgroundColor3 = Color3.fromRGB(27, 27, 32)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 12)
TopCorner.Parent = TopBar

-- 아래쪽을 덮어서 모서리 문제 방지
local TopFix = Instance.new("Frame")
TopFix.Size = UDim2.new(1, 0, 0, 12)
TopFix.Position = UDim2.new(0, 0, 1, -12)
TopFix.BackgroundColor3 = Color3.fromRGB(27, 27, 32)
TopFix.BorderSizePixel = 0
TopFix.Parent = TopBar

-- =========================================================
-- Title
-- =========================================================

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 18, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "UconfigE  •  Key System"
Title.TextColor3 = Color3.fromRGB(240, 240, 245)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 17
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- =========================================================
-- Minimize Button
-- =========================================================

local Minimize = Instance.new("TextButton")
Minimize.Name = "Minimize"
Minimize.Size = UDim2.new(0, 32, 0, 32)
Minimize.Position = UDim2.new(1, -72, 0, 8)
Minimize.BackgroundColor3 = Color3.fromRGB(40, 40, 47)
Minimize.BorderSizePixel = 0
Minimize.Text = "—"
Minimize.TextColor3 = Color3.fromRGB(230, 230, 235)
Minimize.Font = Enum.Font.GothamBold
Minimize.TextSize = 18
Minimize.Parent = TopBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 8)
MinCorner.Parent = Minimize

-- =========================================================
-- Close Button
-- =========================================================

local Close = Instance.new("TextButton")
Close.Name = "Close"
Close.Size = UDim2.new(0, 32, 0, 32)
Close.Position = UDim2.new(1, -36, 0, 8)
Close.BackgroundColor3 = Color3.fromRGB(45, 40, 44)
Close.BorderSizePixel = 0
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(240, 220, 225)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 20
Close.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = Close

-- =========================================================
-- Content
-- =========================================================

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -40, 1, -68)
Content.Position = UDim2.new(0, 20, 0, 58)
Content.BackgroundTransparency = 1
Content.Parent = Main

-- =========================================================
-- Description
-- =========================================================

local Description = Instance.new("TextLabel")
Description.Name = "Description"
Description.Size = UDim2.new(1, 0, 0, 55)
Description.Position = UDim2.new(0, 0, 0, 4)
Description.BackgroundTransparency = 1
Description.Text = "발급받은 KEY를 입력하여 인증하세요."
Description.TextColor3 = Color3.fromRGB(175, 175, 185)
Description.Font = Enum.Font.Gotham
Description.TextSize = 14
Description.TextWrapped = true
Description.TextXAlignment = Enum.TextXAlignment.Left
Description.TextYAlignment = Enum.TextYAlignment.Top
Description.Parent = Content

-- =========================================================
-- Key TextBox
-- =========================================================

local KeyBox = Instance.new("TextBox")
KeyBox.Name = "KeyBox"
KeyBox.Size = UDim2.new(1, 0, 0, 48)
KeyBox.Position = UDim2.new(0, 0, 0, 65)
KeyBox.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
KeyBox.BorderSizePixel = 0
KeyBox.ClearTextOnFocus = false
KeyBox.PlaceholderText = "Enter your key..."
KeyBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 120)
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.fromRGB(235, 235, 240)
KeyBox.Font = Enum.Font.Gotham
KeyBox.TextSize = 14
KeyBox.TextXAlignment = Enum.TextXAlignment.Left
KeyBox.Parent = Content

local KeyPadding = Instance.new("UIPadding")
KeyPadding.PaddingLeft = UDim.new(0, 14)
KeyPadding.PaddingRight = UDim.new(0, 14)
KeyPadding.Parent = KeyBox

local KeyCorner = Instance.new("UICorner")
KeyCorner.CornerRadius = UDim.new(0, 9)
KeyCorner.Parent = KeyBox

local KeyStroke = Instance.new("UIStroke")
KeyStroke.Color = Color3.fromRGB(55, 55, 65)
KeyStroke.Thickness = 1
KeyStroke.Transparency = 0.2
KeyStroke.Parent = KeyBox

-- =========================================================
-- Verify Button
-- =========================================================

local Verify = Instance.new("TextButton")
Verify.Name = "Verify"
Verify.Size = UDim2.new(1, 0, 0, 46)
Verify.Position = UDim2.new(0, 0, 0, 125)
Verify.BackgroundColor3 = Color3.fromRGB(128, 213, 247)
Verify.BorderSizePixel = 0
Verify.Text = "VERIFY KEY"
Verify.TextColor3 = Color3.fromRGB(15, 20, 24)
Verify.Font = Enum.Font.GothamBold
Verify.TextSize = 14
Verify.Parent = Content

local VerifyCorner = Instance.new("UICorner")
VerifyCorner.CornerRadius = UDim.new(0, 9)
VerifyCorner.Parent = Verify

-- =========================================================
-- Status
-- =========================================================

local Status = Instance.new("TextLabel")
Status.Name = "Status"
Status.Size = UDim2.new(1, 0, 0, 35)
Status.Position = UDim2.new(0, 0, 0, 181)
Status.BackgroundTransparency = 1
Status.Text = "Status: Waiting for key..."
Status.TextColor3 = Color3.fromRGB(150, 150, 160)
Status.Font = Enum.Font.Gotham
Status.TextSize = 13
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Content

-- =========================================================
-- API 상태 표시
-- =========================================================

local APIStatus = Instance.new("TextLabel")
APIStatus.Name = "APIStatus"
APIStatus.Size = UDim2.new(1, 0, 0, 25)
APIStatus.Position = UDim2.new(0, 0, 0, 216)
APIStatus.BackgroundTransparency = 1
APIStatus.Text = "● Key API"
APIStatus.TextColor3 = Color3.fromRGB(120, 120, 130)
APIStatus.Font = Enum.Font.Gotham
APIStatus.TextSize = 12
APIStatus.TextXAlignment = Enum.TextXAlignment.Left
APIStatus.Parent = Content

-- =========================================================
-- 드래그 기능
-- =========================================================

local dragging = false
local dragStart = nil
local startPosition = nil

local function updateDrag(input)
    local delta = input.Position - dragStart

    Main.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging then
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            updateDrag(input)
        end
    end
end)

-- =========================================================
-- Minimize
-- =========================================================

local minimized = false

Minimize.MouseButton1Click:Connect(function()
    minimized = not minimized

    if minimized then
        Content.Visible = false
        Main.Size = UDim2.new(0, 430, 0, 48)
        Minimize.Text = "+"
    else
        Content.Visible = true
        Main.Size = UDim2.new(0, 430, 0, 300)
        Minimize.Text = "—"
    end
end)

-- =========================================================
-- Close
-- =========================================================

Close.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- =========================================================
-- API 요청
-- =========================================================

local function ValidateKey(key)
    if not key or key == "" then
        return false, "KEY를 입력해주세요."
    end

    local encodedKey = HttpService:UrlEncode(key)

    local url = API_URL .. "?key=" .. encodedKey

    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        return false, "API 연결 실패"
    end

    local decoded

    local jsonSuccess = pcall(function()
        decoded = HttpService:JSONDecode(response)
    end)

    if not jsonSuccess or type(decoded) ~= "table" then
        return false, "API 응답 오류"
    end

    if decoded.valid == true then
        return true, decoded
    end

    if decoded.reason == "expired" then
        return false, "KEY가 만료되었습니다."
    elseif decoded.reason == "invalid_key" then
        return false, "존재하지 않는 KEY입니다."
    elseif decoded.reason == "invalid_format" then
        return false, "KEY 형식이 올바르지 않습니다."
    elseif decoded.reason == "missing_key" then
        return false, "KEY를 입력해주세요."
    end

    return false, "인증 실패"
end

-- =========================================================
-- 인증 성공 처리
-- =========================================================

local function OnAuthenticated(data)
    Status.Text = "Status: Authentication successful!"
    Status.TextColor3 = Color3.fromRGB(100, 230, 150)

    APIStatus.Text = "● Key API  •  Authenticated"
    APIStatus.TextColor3 = Color3.fromRGB(100, 230, 150)

    task.wait(0.8)

    -- 인증 UI 숨기기
    ScreenGui.Enabled = false

    -- =====================================================
    loadstring(game:HttpGet("https://raw.githubusercontent.com/leeseojun1423-bot/d/refs/heads/main/Main.lua"))()
    -- =====================================================
    --
    -- 여기에 네가 사용하려는 일반적인 Roblox 코드가 있다면
    -- 넣으면 된다.
    --
    -- 예:
    --
    -- print("Authentication successful!")
    --
    -- =====================================================

    print("UconfigE authentication successful.")
end

-- =========================================================
-- Verify
-- =========================================================

local verifying = false

Verify.MouseButton1Click:Connect(function()

    if verifying then
        return
    end

    local key = KeyBox.Text

    if key == "" then
        Status.Text = "Status: KEY를 입력해주세요."
        Status.TextColor3 = Color3.fromRGB(255, 180, 100)
        return
    end

    verifying = true

    Verify.Text = "VERIFYING..."
    Verify.AutoButtonColor = false
    Verify.BackgroundColor3 = Color3.fromRGB(80, 130, 150)

    Status.Text = "Status: Checking key..."
    Status.TextColor3 = Color3.fromRGB(180, 180, 190)

    APIStatus.Text = "● Key API  •  Connecting..."
    APIStatus.TextColor3 = Color3.fromRGB(255, 200, 100)

    local success, result = ValidateKey(key)

    if success then

        Verify.Text = "VERIFIED"
        Verify.BackgroundColor3 = Color3.fromRGB(100, 220, 150)

        OnAuthenticated(result)

    else

        Verify.Text = "VERIFY KEY"
        Verify.AutoButtonColor = true
        Verify.BackgroundColor3 = Color3.fromRGB(128, 213, 247)

        Status.Text = "Status: " .. tostring(result)
        Status.TextColor3 = Color3.fromRGB(255, 110, 110)

        APIStatus.Text = "● Key API  •  Authentication failed"
        APIStatus.TextColor3 = Color3.fromRGB(255, 110, 110)

    end

    verifying = false
end)

-- =========================================================
-- Enter 키로 인증
-- =========================================================

KeyBox.FocusLost:Connect(function(enterPressed)

    if enterPressed then
        Verify:Activate()
    end

end)

-- =========================================================
-- 버튼 Hover
-- =========================================================

Verify.MouseEnter:Connect(function()
    if not verifying then
        Verify.BackgroundColor3 = Color3.fromRGB(150, 220, 250)
    end
end)

Verify.MouseLeave:Connect(function()
    if not verifying then
        Verify.BackgroundColor3 = Color3.fromRGB(128, 213, 247)
    end
end)

-- =========================================================
-- 초기 상태
-- =========================================================

Status.Text = "Status: Waiting for key..."
APIStatus.Text = "● Key API  •  Ready"

print("UconfigE Key System loaded.")
