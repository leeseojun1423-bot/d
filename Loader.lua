local KEY = "발급받은_키"

print("KEY를 입력하세요:")
local input = io.read()

if input == KEY then
    print("✅ KEY 인증 성공!")

    loadstring(game:HttpGet("https://raw.githubusercontent.com/leeseojun1423-bot/d/refs/heads/main/Main.lua"))()

else
    print("❌ KEY가 올바르지 않습니다.")
end
