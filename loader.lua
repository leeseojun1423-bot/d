local HttpService = game:GetService("HttpService")

local API_URL = "https://elementary-gage-dimensions-clerk.trycloudflare.com/validate"

local KEY = "8d4241f98f408176f49c0e8471de0c4d"

local function checkKey(key)
    local url = API_URL .. "?key=" .. HttpService:UrlEncode(key)

    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        return false, "API 연결 실패"
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)

    if not ok then
        return false, "API 응답 오류"
    end

    if data.valid == true then
        return true
    end

    return false, data.reason or "잘못된 KEY"
end

local valid, reason = checkKey(KEY)

if valid then
    print("✅ KEY 인증 성공!")

    -- 인증 성공 후 실행할 일반적인 Roblox 코드
    print("인증된 코드 실행")

else
    warn("❌ KEY 인증 실패: " .. tostring(reason))
end
