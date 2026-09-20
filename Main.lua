-- UconfigE - Halmu Ragebot + Movement + Emote + ESP with Advanced Config System

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

pcall(function()
	local old = PlayerGui:FindFirstChild("UconfigEUI")
	if old then old:Destroy() end
end)

local Accent = Color3.fromRGB(128, 213, 247)

local ConfigBasePath = "UconfigE_Configs"

local function GetConfigPath(name)
	return ConfigBasePath .. "/" .. name
end

local function SaveConfig(name, configData)
	pcall(function()
		local jsonConfig = game:GetService("HttpService"):JSONEncode(configData)
		writefile(GetConfigPath(name) .. ".json", jsonConfig)
	end)
end

local function LoadConfig(name)
	local result = nil
	pcall(function()
		if readfile and pcall(function() readfile(GetConfigPath(name) .. ".json") end) then
			local jsonConfig = readfile(GetConfigPath(name) .. ".json")
			result = game:GetService("HttpService"):JSONDecode(jsonConfig)
		end
	end)
	return result
end

local function GetAllConfigs()
	local configs = {}
	pcall(function()
		for _, file in ipairs(listfiles(ConfigBasePath)) do
			if file:endswith(".json") then
				local name = file:match("([^/]+)%.json$")
				if name then table.insert(configs, name) end
			end
		end
	end)
	return configs
end

local function CreateDefaultConfig()
	return {
		AutoLoad = false,
		AutoLoadConfig = "default",
		AutoSaveConfig = "default",
		RageBotEnabled = false,
		AutoEquipCategory = "gun",
		VoidSpamEnabled = false,
		EmoteEnabled = false,
		ESPEnabled = false,
		WalkSpeed = 16,
		JumpPower = 50,
		InfiniteJump = false,
		NoClip = false,
	}
end

local Config = CreateDefaultConfig()

-----------------------------------------------------------
-- Ragebot Core
-----------------------------------------------------------
local _halmu = {
	rageEnabled = false,
	currentTarget = nil,
	currentTargetPlayer = nil,
	rageConn = nil,
	findConn = nil,
}

local FighterCtrl, EnumLib, useItemRemote, ssEnum, meleeSsEnum
local equipRemote = nil  -- 무기 장착 Remote

task.spawn(function()
	local okF, fc = pcall(function()
		return require(LocalPlayer.PlayerScripts.Controllers.FighterController)
	end)
	if okF then FighterCtrl = fc end

	local okE, el = pcall(function()
		return require(ReplicatedStorage.Modules.EnumLibrary)
	end)
	if okE then EnumLib = el end

	pcall(function()
		useItemRemote = ReplicatedStorage.Remotes.Replication.Fighter.UseItem
	end)

	pcall(function()
		if EnumLib then
			ssEnum = EnumLib:ToEnum("StartShooting")
			-- 칼 찌르기(우클릭/보조공격) 전용 Enum 탐색
			for _, name in ipairs({
				"StartSecondary", "StartMelee", "StartAltFire",
				"SecondaryFire", "MeleeAttack", "StartStab"
			}) do
				local ok, e = pcall(function() return EnumLib:ToEnum(name) end)
				if ok and e then
					meleeSsEnum = e
					print("[UconfigE] Melee enum found: " .. name)
					break
				end
			end
		end
	end)

	-- 무기 장착 Remote 자동 탐색
	task.wait(1)
	pcall(function()
		for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
			if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
				local n = v.Name:lower()
				if n:match("equip") or n:match("select") or n:match("slot") or n:match("switch") then
					equipRemote = v
					print("[UconfigE] Equip remote found: " .. v.Name)
					break
				end
			end
		end
	end)
end)

local function isSameTeam(plr)
	local a = LocalPlayer:GetAttribute("TeamID")
	local b = plr:GetAttribute("TeamID")
	if a == nil or b == nil then return false end
	return a == b
end

local function getRageHead(char)
	if not char then return nil end
	return char:FindFirstChild("HitboxHead")
		or char:FindFirstChild("HitboxHeadSmall")
		or char:FindFirstChild("Head")
end

local function hasShield(plr, char)
	if not char then return false end
	local s = plr:GetAttribute("Shielded") or plr:GetAttribute("Invincible")
		or char:GetAttribute("Shielded") or char:GetAttribute("Invincible")
	if s then return true end
	if char:FindFirstChildOfClass("ForceField") then return true end
	if char:FindFirstChild("Shield") or char:FindFirstChild("SpawnShield") then return true end
	return false
end

local function getObjId()
	if not (FighterCtrl and FighterCtrl.LocalFighter) then return nil end
	local item = FighterCtrl.LocalFighter.EquippedItem
	if not item then return nil end
	local ok, id = pcall(function() return item:Get("ObjectID") end)
	if ok and id then return id end
	ok, id = pcall(function() return item.Data and item.Data.ObjectID end)
	return ok and id or nil
end

-- 현재 든 무기가 칼인지 체크
local function isKnifeWeapon()
	if not (FighterCtrl and FighterCtrl.LocalFighter) then return false end
	local item = FighterCtrl.LocalFighter.EquippedItem
	if not item then return false end
	local ok, itemName = pcall(function() return item.Name end)
	if ok and itemName then
		local n = tostring(itemName):lower()
		if n:match("knife") or n:match("blade") or n:match("dagger") then
			return true
		end
	end
	-- Type 기반 체크
	local ok2, itemType = pcall(function()
		return item:Get("Type") or (item.Data and item.Data.Type)
	end)
	if ok2 and itemType then
		local t = tostring(itemType):lower()
		if t == "knife" or t == "melee" then return true end
	end
	return false
end

local function buildShot(originPos, targetPart)
	local targetPos = targetPart.Position
	local lookCF = CFrame.lookAt(originPos, targetPos)
	local lX, lY, lZ = lookCF:ToOrientation()
	local originStruct = {
		[utf8.char(0)] = originPos.X, [utf8.char(1)] = originPos.Y, [utf8.char(2)] = originPos.Z,
		[utf8.char(3)] = lX, [utf8.char(4)] = lY, [utf8.char(5)] = lZ,
	}
	local relCF = targetPart.CFrame:ToObjectSpace(CFrame.new(targetPos))
	local rX, rY, rZ = relCF:ToOrientation()
	return {
		[utf8.char(1)] = {
			[utf8.char(0)] = originStruct,
			[utf8.char(1)] = originStruct,
			[utf8.char(2)] = targetPart,
			[utf8.char(3)] = {
				[utf8.char(0)] = relCF.X, [utf8.char(1)] = relCF.Y, [utf8.char(2)] = relCF.Z,
				[utf8.char(3)] = rX, [utf8.char(4)] = rY, [utf8.char(5)] = rZ,
			},
		},
	}
end

local function startTargetFinder()
	if _halmu.findConn then return end
	_halmu.findConn = RunService.Heartbeat:Connect(function()
		if not _halmu.rageEnabled then
			_halmu.currentTarget = nil
			_halmu.currentTargetPlayer = nil
			return
		end
		local ref = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		local refPos = ref and ref.Position or Vector3.zero
		local closest, closestPlr, best = nil, nil, math.huge
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character and not isSameTeam(plr) then
				local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
				local hum = plr.Character:FindFirstChildOfClass("Humanoid")
				if hrp and hum and hum.Health > 0 and not hasShield(plr, plr.Character) then
					local d = (Vector3.new(refPos.X,0,refPos.Z) - Vector3.new(hrp.Position.X,0,hrp.Position.Z)).Magnitude
					if d < best then
						best = d
						closest = plr.Character
						closestPlr = plr
					end
				end
			end
		end
		_halmu.currentTarget = closest and getRageHead(closest) or nil
		_halmu.currentTargetPlayer = closestPlr
	end)
end

-- 텔레포트 오프셋
local TELEPORT_OFFSET_RANGED = Vector3.new(-2, 3, 0)  -- 총
local TELEPORT_OFFSET_KNIFE  = Vector3.new(-2, 0, 0)  -- 칼 찌르기

local function startRageFire()
	if _halmu.rageConn then
		_halmu.rageConn:Disconnect()
		_halmu.rageConn = nil
	end
	if not _halmu.rageEnabled then return end

	local cachedId = nil
	_halmu.rageConn = RunService.Heartbeat:Connect(function()
		if not _halmu.rageEnabled then return end
		if not useItemRemote or not ssEnum then return end
		local target = _halmu.currentTarget
		local targetPlr = _halmu.currentTargetPlayer
		if not target or not target.Parent then return end
		if targetPlr and hasShield(targetPlr, targetPlr.Character) then return end

		local objId = getObjId()
		if objId then cachedId = objId else objId = cachedId end
		if not objId then return end

		local isKnife = isKnifeWeapon()
		local offset = isKnife and TELEPORT_OFFSET_KNIFE or TELEPORT_OFFSET_RANGED
		local origin = target.Position + offset

		pcall(function()
			-- 칼이면 우클릭(찌르기) Enum 사용, 없으면 기본 ssEnum
			local fireEnum = (isKnife and meleeSsEnum) or ssEnum
			useItemRemote:FireServer(objId, fireEnum, buildShot(origin, target), nil)
		end)
	end)
end

-----------------------------------------------------------
-- 텔레포트: 상대 기준으로 계속 이동
-- 칼이면 (-2,0,0), 총이면 (-2,3,0)
-- 타겟 죽으면 원래 위치로 복귀
-----------------------------------------------------------
local _savedReturnCFrame = nil
local _teleportRestoreCFrame = nil
local restoreName = "uconfig_restore"

RunService.Heartbeat:Connect(function()
	if not (_halmu.rageEnabled and _halmu.currentTarget) then
		_teleportRestoreCFrame = nil
		return
	end

	local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	if not _savedReturnCFrame then
		_savedReturnCFrame = hrp.CFrame
	end

	_teleportRestoreCFrame = hrp.CFrame

	local isKnife = isKnifeWeapon()
	local offset = isKnife and TELEPORT_OFFSET_KNIFE or TELEPORT_OFFSET_RANGED
	local tp = _halmu.currentTarget.Position
	hrp.CFrame = CFrame.new(tp + offset, tp)

	-- 타겟 사망 시 원래 위치로 복귀
	local targetPlr = _halmu.currentTargetPlayer
	if targetPlr and targetPlr.Character then
		local hum = targetPlr.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health <= 0 then
			if _savedReturnCFrame then
				hrp.CFrame = _savedReturnCFrame
				_savedReturnCFrame = nil
				_halmu.currentTarget = nil
				_halmu.currentTargetPlayer = nil
			end
		end
	end
end)

RunService:BindToRenderStep(restoreName, 150, function()
	local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if hrp and _teleportRestoreCFrame then
		hrp.CFrame = _teleportRestoreCFrame
		_teleportRestoreCFrame = nil
	end
end)

local function updateAllHead(on)
	if not on then return end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			for _, part in ipairs(plr.Character:GetDescendants()) do
				if part.Name:match("Hitbox") then
					pcall(function()
						part.CanCollide = false
						part.Transparency = 1
					end)
				end
			end
		end
	end
end

RunService.Heartbeat:Connect(function()
	updateAllHead(_halmu.rageEnabled)
end)

-----------------------------------------------------------
-- 자동 무기 장착 (모바일/PC 모두)
-- FighterController의 EquippedItem을 직접 바꾸거나
-- 내부 선택 함수를 호출하는 방식
-----------------------------------------------------------
local AutoEquipCategory = "gun"
local autoEquipConn = nil

local CATEGORY_SLOT = {
	["gun"]      = 1,
	["bojo gun"] = 2,
	["melee"]    = 3,
}

local function tryEquipSlot(slotNum)
	local success = false

	-- 방법 1: FighterController 내부 함수 직접 호출
	pcall(function()
		local lf = FighterCtrl and FighterCtrl.LocalFighter
		if not lf then return end

		-- 가능한 함수명 목록 시도
		local fnames = {
			"SelectSlot", "EquipSlot", "EquipIndex",
			"SetSlot", "ChangeSlot", "SwitchSlot",
			"SelectWeapon", "EquipWeapon",
		}
		for _, fname in ipairs(fnames) do
			local ok = pcall(function() lf[fname](lf, slotNum) end)
			if ok then success = true break end
		end

		-- 방법 2: CurrentSlot, SelectedSlot 등 속성 직접 변경
		if not success then
			for _, attr in ipairs({"CurrentSlot","SelectedSlot","SlotIndex","ActiveSlot"}) do
				local ok = pcall(function()
					lf[attr] = slotNum
					success = true
				end)
				if ok then break end
			end
		end

		-- 방법 3: Inventory에서 해당 슬롯 아이템을 꺼내 Equip 함수 호출
		if not success then
			local inv = lf.Inventory or lf.Items or lf.Slots
			if inv then
				local item = inv[slotNum]
				if item then
					for _, fname in ipairs({"Equip","EquipItem","Select","Use"}) do
						local ok = pcall(function() lf[fname](lf, item) end)
						if ok then success = true break end
					end
				end
			end
		end
	end)

	-- 방법 4: 장착 Remote 직접 파이어 (자동 탐색된 Remote 사용)
	if not success and equipRemote then
		pcall(function()
			if equipRemote:IsA("RemoteEvent") then
				equipRemote:FireServer(slotNum)
				success = true
			elseif equipRemote:IsA("RemoteFunction") then
				equipRemote:InvokeServer(slotNum)
				success = true
			end
		end)
	end

	-- 방법 5: 장착 Remote를 실시간으로 다시 탐색해서 파이어
	if not success then
		pcall(function()
			for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
				if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
					local n = v.Name:lower()
					if n:match("equip") or n:match("select") or n:match("slot") or n:match("switch") then
						if v:IsA("RemoteEvent") then
							v:FireServer(slotNum)
						else
							v:InvokeServer(slotNum)
						end
						success = true
						break
					end
				end
			end
		end)
	end

	return success
end

local function startAutoEquip()
	if autoEquipConn then return end
	local lastEquip = 0
	autoEquipConn = RunService.Heartbeat:Connect(function()
		if not _halmu.rageEnabled then return end
		if tick() - lastEquip < 0.3 then return end
		lastEquip = tick()

		local slotNum = CATEGORY_SLOT[AutoEquipCategory]
		if slotNum then
			tryEquipSlot(slotNum)
		end
	end)
end

local function stopAutoEquip()
	if autoEquipConn then
		autoEquipConn:Disconnect()
		autoEquipConn = nil
	end
end

-- 무반동
local NoRecoilEnabled = true
local noRecoilConn = nil

local function setNoRecoil(on)
	NoRecoilEnabled = on
	if noRecoilConn then noRecoilConn:Disconnect() noRecoilConn = nil end
	if on then
		noRecoilConn = RunService.RenderStepped:Connect(function()
			local _, cy, _ = Camera.CFrame:ToOrientation()
			Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.fromOrientation(0, cy, 0)
		end)
	end
end

-- 무스프레드 패치
local function patchSpread()
	task.spawn(function()
		while true do
			task.wait(0.1)
			if not FighterCtrl then continue end
			pcall(function()
				local lf = FighterCtrl.LocalFighter
				if not lf then return end
				local item = lf.EquippedItem
				if not item then return end
				for _, field in ipairs({"Spread","SpreadAmount","BulletSpread","Accuracy"}) do
					pcall(function()
						if item.Data and item.Data[field] ~= nil then item.Data[field] = 0 end
					end)
					pcall(function()
						if item[field] ~= nil then item[field] = 0 end
					end)
				end
			end)
		end
	end)
end
patchSpread()

local function setRage(on)
	_halmu.rageEnabled = on and true or false
	if on then
		_savedReturnCFrame = nil
		startTargetFinder()
		startRageFire()
		startAutoEquip()
		setNoRecoil(true)
	else
		if _halmu.rageConn then
			_halmu.rageConn:Disconnect()
			_halmu.rageConn = nil
		end
		if _savedReturnCFrame then
			local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp then hrp.CFrame = _savedReturnCFrame end
			_savedReturnCFrame = nil
		end
		_halmu.currentTarget = nil
		_halmu.currentTargetPlayer = nil
		stopAutoEquip()
		setNoRecoil(false)
	end
end

-----------------------------------------------------------
-- Void Spam
-----------------------------------------------------------
local VoidSpamEnabled = false
local voidSpamConn = nil
local voidRestoreName = "uconfig_void_restore"
local _voidRealCFrame = nil

local function setVoidSpam(on)
	VoidSpamEnabled = on
	if voidSpamConn then voidSpamConn:Disconnect() voidSpamConn = nil end
	pcall(function() RunService:UnbindFromRenderStep(voidRestoreName) end)

	if on then
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp then _voidRealCFrame = hrp.CFrame end

		voidSpamConn = RunService.Heartbeat:Connect(function()
			local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not myHrp then return end
			myHrp.CFrame = CFrame.new(
				math.random(-100000, 100000),
				math.random(-100000, 100000),
				math.random(-100000, 100000)
			)
		end)

		RunService:BindToRenderStep(voidRestoreName, 200, function()
			local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if myHrp and _voidRealCFrame then myHrp.CFrame = _voidRealCFrame end
		end)
	else
		_voidRealCFrame = nil
	end
end

-----------------------------------------------------------
-- Movement
-----------------------------------------------------------
local InfiniteJumpEnabled = false
local noclipConn = nil

local function applyWalkSpeed(v)
	Config.WalkSpeed = v
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = v end
end

local function applyJumpPower(v)
	Config.JumpPower = v
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.UseJumpPower = true hum.JumpPower = v end
end

LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = Config.WalkSpeed
		hum.UseJumpPower = true
		hum.JumpPower = Config.JumpPower
	end
	if VoidSpamEnabled then
		task.wait(0.5)
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then _voidRealCFrame = hrp.CFrame end
	end
end)

UserInputService.JumpRequest:Connect(function()
	if InfiniteJumpEnabled then
		local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

local function setNoClip(on)
	if noclipConn then noclipConn:Disconnect() noclipConn = nil end
	if on then
		noclipConn = RunService.Stepped:Connect(function()
			local char = LocalPlayer.Character
			if not char then return end
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end)
	else
		local char = LocalPlayer.Character
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = true end
			end
		end
	end
end

-----------------------------------------------------------
-- Emote
-----------------------------------------------------------
local EmoteEnabled = false
local emoteTrack = nil
local EMOTESPEED = 250
local EMOTES = {
	"rbxassetid://507771019","rbxassetid://507776043",
	"rbxassetid://507777623","rbxassetid://3698339488",
	"rbxassetid://92281817840531",
}

local function stopEmote()
	EmoteEnabled = false
	if emoteTrack then pcall(function() emoteTrack:Stop() end) emoteTrack = nil end
end

local function playEmote(char)
	if not EmoteEnabled then return end
	char = char or LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid",3)
	if not hum then return end
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator",hum)
	for _, id in ipairs(EMOTES) do
		local ok, track = pcall(function()
			local a = Instance.new("Animation")
			a.AnimationId = id
			local t = animator:LoadAnimation(a)
			t.Priority = Enum.AnimationPriority.Action4
			t.Looped = true
			t:Play(0.1,1,EMOTESPEED)
			return t
		end)
		if ok and track then
			emoteTrack = track
			track.Stopped:Connect(function()
				if EmoteEnabled then task.defer(function() playEmote(char) end) end
			end)
			return
		end
	end
end

LocalPlayer.CharacterAdded:Connect(function(char)
	if EmoteEnabled then
		task.delay(0.5, function() if EmoteEnabled then playEmote(char) end end)
	end
end)

-----------------------------------------------------------
-- ESP
-----------------------------------------------------------
local ESPEnabled = false
local ESPLines = {}

local function CreateESPLine(player)
	if player == LocalPlayer then return end
	local line = Drawing.new("Line")
	line.Visible = false
	line.Color = Color3.fromRGB(255,0,0)
	line.Thickness = 2
	line.Transparency = 1
	ESPLines[player] = line
end

local function RemoveESPLine(player)
	if ESPLines[player] then ESPLines[player]:Remove() ESPLines[player] = nil end
end

local function UpdateESP(player)
	if not ESPEnabled then
		for _,line in pairs(ESPLines) do line.Visible = false end
		return
	end
	local line = ESPLines[player]
	if not line then return end
	local character = player.Character
	if not character then line.Visible = false return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then line.Visible = false return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then line.Visible = false return end
	local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
	if not onScreen then line.Visible = false return end
	line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
	line.To = Vector2.new(pos.X, pos.Y)
	line.Visible = true
	line.Color = (player.Team == LocalPlayer.Team) and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
end

-----------------------------------------------------------
-- UI
-----------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UconfigEUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0,70,0,36)
ToggleBtn.Position = UDim2.new(0,16,0,16)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(28,28,30)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = ""
ToggleBtn.AutoButtonColor = false
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner",ToggleBtn).CornerRadius = UDim.new(0,6)
local ts = Instance.new("UIStroke",ToggleBtn)
ts.Color = Accent
ts.Thickness = 1.5

local tl1 = Instance.new("TextLabel",ToggleBtn)
tl1.Size = UDim2.new(1,-6,0,16)
tl1.Position = UDim2.new(0,3,0,2)
tl1.BackgroundTransparency = 1
tl1.Font = Enum.Font.GothamBold
tl1.Text = "Menu"
tl1.TextColor3 = Color3.fromRGB(230,230,230)
tl1.TextSize = 12
tl1.TextXAlignment = Enum.TextXAlignment.Left

local tl2 = Instance.new("TextLabel",ToggleBtn)
tl2.Size = UDim2.new(1,-6,0,14)
tl2.Position = UDim2.new(0,3,0,18)
tl2.BackgroundTransparency = 1
tl2.Font = Enum.Font.Gotham
tl2.Text = "Open"
tl2.TextColor3 = Accent
tl2.TextSize = 11
tl2.TextXAlignment = Enum.TextXAlignment.Left

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0,560,0,300)
Main.AnchorPoint = Vector2.new(0.5,0.5)
Main.Position = UDim2.new(0.5,0,0.5,0)
Main.BackgroundColor3 = Color3.fromRGB(20,20,22)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Main.ClipsDescendants = true
Instance.new("UICorner",Main).CornerRadius = UDim.new(0,6)
local mainStroke = Instance.new("UIStroke",Main)
mainStroke.Color = Accent
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.35

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1,0,0,32)
TopBar.BackgroundColor3 = Color3.fromRGB(28,28,30)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main
Instance.new("UICorner",TopBar).CornerRadius = UDim.new(0,6)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,-16,1,0)
Title.Position = UDim2.new(0,12,0,0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.Code
Title.Text = "UconfigE"
Title.TextColor3 = Color3.fromRGB(230,230,230)
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local AccentLine = Instance.new("Frame")
AccentLine.Size = UDim2.new(1,0,0,1)
AccentLine.Position = UDim2.new(0,0,1,-1)
AccentLine.BackgroundColor3 = Accent
AccentLine.BorderSizePixel = 0
AccentLine.Parent = TopBar

do
	local dragging, dragStart, startPos
	TopBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = Main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
		end
	end)
end

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1,0,0,36)
TabBar.Position = UDim2.new(0,0,0,32)
TabBar.BackgroundColor3 = Color3.fromRGB(25,25,27)
TabBar.BorderSizePixel = 0
TabBar.Parent = Main

local TabBarLayout = Instance.new("UIListLayout",TabBar)
TabBarLayout.FillDirection = Enum.FillDirection.Horizontal
TabBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabBarLayout.Padding = UDim.new(0,0)

local TabContents = Instance.new("Frame")
TabContents.Size = UDim2.new(1,0,1,-68)
TabContents.Position = UDim2.new(0,0,0,68)
TabContents.BackgroundTransparency = 1
TabContents.BorderSizePixel = 0
TabContents.Parent = Main

local function CreateTab(tabName)
	local TabBtn = Instance.new("TextButton")
	TabBtn.Size = UDim2.new(0,100,1,0)
	TabBtn.BackgroundColor3 = Color3.fromRGB(28,28,30)
	TabBtn.BorderSizePixel = 0
	TabBtn.Text = tabName
	TabBtn.TextColor3 = Color3.fromRGB(150,150,150)
	TabBtn.Font = Enum.Font.Code
	TabBtn.TextSize = 12
	TabBtn.AutoButtonColor = false
	TabBtn.LayoutOrder = tabName=="Main" and 1 or (tabName=="Movement" and 2 or 3)
	TabBtn.Parent = TabBar

	local TabContent = Instance.new("ScrollingFrame")
	TabContent.Name = tabName
	TabContent.Size = UDim2.new(1,-16,1,0)
	TabContent.Position = UDim2.new(0,8,0,0)
	TabContent.BackgroundTransparency = 1
	TabContent.BorderSizePixel = 0
	TabContent.ScrollBarThickness = 5
	TabContent.ScrollBarImageColor3 = Accent
	TabContent.ScrollingDirection = Enum.ScrollingDirection.Y
	TabContent.ElasticBehavior = Enum.ElasticBehavior.Always
	TabContent.CanvasSize = UDim2.new(0,0,0,0)
	TabContent.Visible = false
	TabContent.Parent = TabContents

	local List = Instance.new("UIListLayout",TabContent)
	List.SortOrder = Enum.SortOrder.LayoutOrder
	List.Padding = UDim.new(0,8)
	List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		TabContent.CanvasSize = UDim2.new(0,0,0,List.AbsoluteContentSize.Y+12)
	end)

	TabBtn.MouseButton1Click:Connect(function()
		for _,child in pairs(TabContents:GetChildren()) do
			if child:IsA("ScrollingFrame") then child.Visible = false end
		end
		TabContent.Visible = true
		for _,btn in pairs(TabBar:GetChildren()) do
			if btn:IsA("TextButton") then
				btn.TextColor3 = Color3.fromRGB(150,150,150)
				btn.BackgroundColor3 = Color3.fromRGB(28,28,30)
			end
		end
		TabBtn.TextColor3 = Accent
		TabBtn.BackgroundColor3 = Color3.fromRGB(35,35,37)
	end)

	local api = {}

	function api:AddSection(name)
		local Section = Instance.new("Frame")
		Section.Size = UDim2.new(1,0,0,28)
		Section.BackgroundColor3 = Color3.fromRGB(30,30,32)
		Section.BorderSizePixel = 0
		Section.Parent = TabContent
		Instance.new("UICorner",Section).CornerRadius = UDim.new(0,4)

		local SecTitle = Instance.new("TextLabel")
		SecTitle.Size = UDim2.new(1,-12,0,20)
		SecTitle.Position = UDim2.new(0,8,0,4)
		SecTitle.BackgroundTransparency = 1
		SecTitle.Font = Enum.Font.Code
		SecTitle.Text = name
		SecTitle.TextColor3 = Accent
		SecTitle.TextSize = 13
		SecTitle.TextXAlignment = Enum.TextXAlignment.Left
		SecTitle.Parent = Section

		local ItemHolder = Instance.new("Frame")
		ItemHolder.Size = UDim2.new(1,-12,0,0)
		ItemHolder.Position = UDim2.new(0,6,0,24)
		ItemHolder.BackgroundTransparency = 1
		ItemHolder.Parent = Section

		local ItemList = Instance.new("UIListLayout",ItemHolder)
		ItemList.SortOrder = Enum.SortOrder.LayoutOrder
		ItemList.Padding = UDim.new(0,4)

		local function update()
			Section.Size = UDim2.new(1,0,0,ItemList.AbsoluteContentSize.Y+28)
		end
		ItemList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)

		local secApi = {}

		function secApi:Toggle(text, default, callback)
			local Btn = Instance.new("TextButton")
			Btn.Size = UDim2.new(1,0,0,22)
			Btn.BackgroundColor3 = Color3.fromRGB(38,38,40)
			Btn.BorderSizePixel = 0
			Btn.Text = ""
			Btn.AutoButtonColor = false
			Btn.Parent = ItemHolder
			Instance.new("UICorner",Btn).CornerRadius = UDim.new(0,3)

			local Box = Instance.new("Frame")
			Box.Size = UDim2.new(0,12,0,12)
			Box.Position = UDim2.new(0,6,0.5,-6)
			Box.BackgroundColor3 = Color3.fromRGB(28,28,28)
			Box.BorderSizePixel = 0
			Box.Parent = Btn
			Instance.new("UICorner",Box).CornerRadius = UDim.new(0,2)

			local Check = Instance.new("Frame")
			Check.Size = UDim2.new(0,8,0,8)
			Check.Position = UDim2.new(0,2,0,2)
			Check.BackgroundColor3 = Accent
			Check.BorderSizePixel = 0
			Check.Visible = default
			Check.Parent = Box
			Instance.new("UICorner",Check).CornerRadius = UDim.new(0,1)

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(1,-28,1,0)
			Label.Position = UDim2.new(0,24,0,0)
			Label.BackgroundTransparency = 1
			Label.Font = Enum.Font.Code
			Label.Text = text
			Label.TextColor3 = Color3.fromRGB(200,200,200)
			Label.TextSize = 13
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Parent = Btn

			local on = default
			Btn.MouseButton1Click:Connect(function()
				on = not on
				Check.Visible = on
				pcall(callback, on)
			end)
			update()
		end

		function secApi:Slider(text, min, max, default, callback)
			local Row = Instance.new("Frame")
			Row.Size = UDim2.new(1,0,0,36)
			Row.BackgroundTransparency = 1
			Row.Parent = ItemHolder

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(1,0,0,14)
			Label.BackgroundTransparency = 1
			Label.Font = Enum.Font.Code
			Label.Text = text..": "..tostring(default)
			Label.TextColor3 = Color3.fromRGB(200,200,200)
			Label.TextSize = 12
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Parent = Row

			local Bar = Instance.new("Frame")
			Bar.Size = UDim2.new(1,0,0,10)
			Bar.Position = UDim2.new(0,0,0,20)
			Bar.BackgroundColor3 = Color3.fromRGB(40,40,44)
			Bar.BorderSizePixel = 0
			Bar.Parent = Row
			Instance.new("UICorner",Bar).CornerRadius = UDim.new(0,3)

			local Fill = Instance.new("Frame")
			Fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
			Fill.BackgroundColor3 = Accent
			Fill.BorderSizePixel = 0
			Fill.Parent = Bar
			Instance.new("UICorner",Fill).CornerRadius = UDim.new(0,3)

			local val = default
			local sliding = false
			local function setFromX(x)
				local rel = math.clamp((x-Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X,0,1)
				val = math.floor(min+(max-min)*rel+0.5)
				Fill.Size = UDim2.new(rel,0,1,0)
				Label.Text = text..": "..tostring(val)
				pcall(callback, val)
			end
			Bar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = true
					setFromX(input.Position.X)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					setFromX(input.Position.X)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = false
				end
			end)
			update()
		end

		function secApi:Button(text, callback)
			local Btn = Instance.new("TextButton")
			Btn.Size = UDim2.new(1,0,0,30)
			Btn.BackgroundColor3 = Color3.fromRGB(38,38,40)
			Btn.BorderSizePixel = 0
			Btn.Text = text
			Btn.TextColor3 = Accent
			Btn.Font = Enum.Font.Code
			Btn.TextSize = 12
			Btn.Parent = ItemHolder
			Instance.new("UICorner",Btn).CornerRadius = UDim.new(0,3)
			Btn.MouseButton1Click:Connect(callback)
			update()
		end

		function secApi:Dropdown(text, options, default, callback)
			local Row = Instance.new("Frame")
			Row.Size = UDim2.new(1,0,0,30)
			Row.BackgroundTransparency = 1
			Row.Parent = ItemHolder

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(1,0,0,12)
			Label.BackgroundTransparency = 1
			Label.Font = Enum.Font.Code
			Label.Text = text
			Label.TextColor3 = Color3.fromRGB(150,150,150)
			Label.TextSize = 11
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Parent = Row

			local DropBtn = Instance.new("TextButton")
			DropBtn.Size = UDim2.new(1,0,0,14)
			DropBtn.Position = UDim2.new(0,0,0,14)
			DropBtn.BackgroundColor3 = Color3.fromRGB(38,38,40)
			DropBtn.BorderSizePixel = 0
			DropBtn.Text = default
			DropBtn.TextColor3 = Accent
			DropBtn.Font = Enum.Font.Code
			DropBtn.TextSize = 11
			DropBtn.Parent = Row
			Instance.new("UICorner",DropBtn).CornerRadius = UDim.new(0,2)

			local menu = Instance.new("Frame")
			menu.BackgroundColor3 = Color3.fromRGB(30,30,32)
			menu.BorderSizePixel = 0
			menu.ZIndex = 50
			menu.Visible = false
			menu.Parent = Main
			Instance.new("UICorner",menu).CornerRadius = UDim.new(0,2)
			Instance.new("UIListLayout",menu).SortOrder = Enum.SortOrder.LayoutOrder

			local selected = default

			for _, option in ipairs(options) do
				local opt = Instance.new("TextButton")
				opt.Size = UDim2.new(1,0,0,16)
				opt.BackgroundColor3 = Color3.fromRGB(35,35,37)
				opt.BorderSizePixel = 0
				opt.Text = option
				opt.TextColor3 = Accent
				opt.Font = Enum.Font.Code
				opt.TextSize = 10
				opt.ZIndex = 51
				opt.Parent = menu
				opt.MouseButton1Click:Connect(function()
					selected = option
					DropBtn.Text = selected
					menu.Visible = false
					pcall(callback, selected)
				end)
			end

			DropBtn.MouseButton1Click:Connect(function()
				if menu.Visible then
					menu.Visible = false
				else
					local relX = DropBtn.AbsolutePosition.X - Main.AbsolutePosition.X
					local relY = DropBtn.AbsolutePosition.Y - Main.AbsolutePosition.Y + DropBtn.AbsoluteSize.Y
					menu.Size = UDim2.new(0, DropBtn.AbsoluteSize.X, 0, #options*16)
					menu.Position = UDim2.new(0, relX, 0, relY)
					menu.Visible = true
				end
			end)

			UserInputService.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					if menu.Visible then
						local mx,my = input.Position.X, input.Position.Y
						local ap,as = menu.AbsolutePosition, menu.AbsoluteSize
						if mx<ap.X or mx>ap.X+as.X or my<ap.Y or my>ap.Y+as.Y then
							menu.Visible = false
						end
					end
				end
			end)

			update()
		end

		update()
		return secApi
	end

	return api
end

local uiVisible = true
local function setUI(v)
	uiVisible = v
	Main.Visible = v
	tl2.Text = v and "Open" or "Closed"
	tl2.TextColor3 = v and Accent or Color3.fromRGB(180,80,80)
end
ToggleBtn.MouseButton1Click:Connect(function() setUI(not uiVisible) end)
UserInputService.InputBegan:Connect(function(input,gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.RightShift then setUI(not uiVisible) end
end)

-----------------------------------------------------------
-- Main Tab
-----------------------------------------------------------
local MainTab = CreateTab("Main")

local RageSec = MainTab:AddSection("Ragebot")
RageSec:Toggle("Ragebot (All Head + Teleport)", false, function(v)
	setRage(v)
	Config.RageBotEnabled = v
	if Config.AutoSaveConfig then SaveConfig(Config.AutoSaveConfig, Config) end
end)
RageSec:Dropdown("Auto Equip", {"gun","bojo gun","melee"}, "gun", function(selected)
	AutoEquipCategory = selected
	Config.AutoEquipCategory = selected
	if Config.AutoSaveConfig then SaveConfig(Config.AutoSaveConfig, Config) end
end)

local WeaponSec = MainTab:AddSection("Weapon")
WeaponSec:Toggle("No Recoil", true, function(v) setNoRecoil(v) end)
WeaponSec:Toggle("No Spread", true, function(v)
	print("[UconfigE] No Spread: "..tostring(v))
end)

local VoidSec = MainTab:AddSection("Void Spam")
VoidSec:Toggle("Void Spam", false, function(v)
	setVoidSpam(v)
	Config.VoidSpamEnabled = v
	if Config.AutoSaveConfig then SaveConfig(Config.AutoSaveConfig, Config) end
end)

local EmoteSec = MainTab:AddSection("Emote")
EmoteSec:Toggle("Emote Glitch", false, function(v)
	if v then EmoteEnabled = true playEmote(LocalPlayer.Character)
	else stopEmote() end
	Config.EmoteEnabled = v
	if Config.AutoSaveConfig then SaveConfig(Config.AutoSaveConfig, Config) end
end)

local ESPSec = MainTab:AddSection("ESP")
ESPSec:Toggle("Tracers", false, function(v)
	ESPEnabled = v
	Config.ESPEnabled = v
	if not v then for _,line in pairs(ESPLines) do line.Visible = false end end
	if Config.AutoSaveConfig then SaveConfig(Config.AutoSaveConfig, Config) end
end)

-----------------------------------------------------------
-- Movement Tab
-----------------------------------------------------------
local MovementTab = CreateTab("Movement")

local SpeedSec = MovementTab:AddSection("Speed")
SpeedSec:Slider("Walk Speed", 16, 200, 16, function(v)
	applyWalkSpeed(v)
	if Config.AutoSaveConfig then SaveConfig(Config.AutoSaveConfig, Config) end
end)
SpeedSec:Slider("Jump Power", 50, 300, 50, function(v)
	applyJumpPower(v)
	if Config.AutoSaveConfig then SaveConfig(Config.AutoSaveConfig, Config) end
end)

local MoveSec = MovementTab:AddSection("Movement")
MoveSec:Toggle("Infinite Jump", false, function(v)
	InfiniteJumpEnabled = v
	Config.InfiniteJump = v
	if Config.AutoSaveConfig then SaveConfig(Config.AutoSaveConfig, Config) end
end)
MoveSec:Toggle("No Clip", false, function(v)
	setNoClip(v)
	Config.NoClip = v
	if Config.AutoSaveConfig then SaveConfig(Config.AutoSaveConfig, Config) end
end)

-----------------------------------------------------------
-- Config Tab
-----------------------------------------------------------
local ConfigTab = CreateTab("Config")

local AutoSec = ConfigTab:AddSection("Auto Settings")
local allConfigs = GetAllConfigs()
table.insert(allConfigs, 1, "default")

AutoSec:Toggle("Auto Load", false, function(v)
	Config.AutoLoad = v
	if Config.AutoSaveConfig then SaveConfig(Config.AutoSaveConfig, Config) end
end)
AutoSec:Dropdown("Auto Load Config", allConfigs, Config.AutoLoadConfig, function(selected)
	Config.AutoLoadConfig = selected
	if Config.AutoSaveConfig then SaveConfig(Config.AutoSaveConfig, Config) end
end)
AutoSec:Dropdown("Auto Save Config", allConfigs, Config.AutoSaveConfig, function(selected)
	Config.AutoSaveConfig = selected
	if Config.AutoSaveConfig then SaveConfig(Config.AutoSaveConfig, Config) end
end)

local ManualSec = ConfigTab:AddSection("Manual Control")
ManualSec:Button("Save Current Config", function()
	if Config.AutoSaveConfig then SaveConfig(Config.AutoSaveConfig, Config) end
end)
ManualSec:Button("Load Selected Config", function()
	local loaded = LoadConfig(Config.AutoLoadConfig)
	if loaded then
		Config = loaded
		AutoEquipCategory = Config.AutoEquipCategory or "gun"
		setRage(Config.RageBotEnabled)
		setVoidSpam(Config.VoidSpamEnabled)
		applyWalkSpeed(Config.WalkSpeed)
		applyJumpPower(Config.JumpPower)
		InfiniteJumpEnabled = Config.InfiniteJump
		setNoClip(Config.NoClip)
		if Config.EmoteEnabled then EmoteEnabled = true playEmote(LocalPlayer.Character) end
		ESPEnabled = Config.ESPEnabled
	end
end)

local CreateSec = ConfigTab:AddSection("Create New Config")

local nameInputBg = Instance.new("Frame")
nameInputBg.Size = UDim2.new(1,0,0,24)
nameInputBg.BackgroundColor3 = Color3.fromRGB(38,38,40)
nameInputBg.BorderSizePixel = 0
nameInputBg.Parent = CreateSec.Parent
Instance.new("UICorner",nameInputBg).CornerRadius = UDim.new(0,2)

local nameInput = Instance.new("TextBox")
nameInput.Size = UDim2.new(1,-8,1,0)
nameInput.Position = UDim2.new(0,4,0,0)
nameInput.BackgroundTransparency = 1
nameInput.BorderSizePixel = 0
nameInput.Text = "Config Name"
nameInput.TextColor3 = Color3.fromRGB(150,150,150)
nameInput.Font = Enum.Font.Code
nameInput.TextSize = 11
nameInput.Parent = nameInputBg

CreateSec:Button("Create New Config", function()
	if nameInput.Text and nameInput.Text ~= "" and nameInput.Text ~= "Config Name" then
		SaveConfig(nameInput.Text, CreateDefaultConfig())
		nameInput.Text = "Config Name"
	end
end)

-- Activate Main Tab
task.wait(0.1)
for _,child in pairs(TabContents:GetChildren()) do
	if child:IsA("ScrollingFrame") then child.Visible = false end
end
local mainTabContent = TabContents:FindFirstChild("Main")
if mainTabContent then mainTabContent.Visible = true end
for _,btn in pairs(TabBar:GetChildren()) do
	if btn:IsA("TextButton") then
		if btn.Text == "Main" then
			btn.TextColor3 = Accent
			btn.BackgroundColor3 = Color3.fromRGB(35,35,37)
		else
			btn.TextColor3 = Color3.fromRGB(150,150,150)
			btn.BackgroundColor3 = Color3.fromRGB(28,28,30)
		end
	end
end

-----------------------------------------------------------
-- ESP Loop
-----------------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not ESPEnabled then return end
	for _,player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			if not ESPLines[player] then CreateESPLine(player) end
			UpdateESP(player)
		end
	end
end)

Players.PlayerAdded:Connect(function(player) if ESPEnabled then CreateESPLine(player) end end)
Players.PlayerRemoving:Connect(RemoveESPLine)
for _,player in ipairs(Players:GetPlayers()) do
	if player ~= LocalPlayer then CreateESPLine(player) end
end

-- Auto Load
if Config.AutoLoad and Config.AutoLoadConfig then
	task.wait(0.5)
	local loaded = LoadConfig(Config.AutoLoadConfig)
	if loaded then
		Config = loaded
		AutoEquipCategory = Config.AutoEquipCategory or "gun"
		setRage(Config.RageBotEnabled)
		setVoidSpam(Config.VoidSpamEnabled)
		applyWalkSpeed(Config.WalkSpeed)
		applyJumpPower(Config.JumpPower)
		InfiniteJumpEnabled = Config.InfiniteJump
		setNoClip(Config.NoClip)
		if Config.EmoteEnabled then EmoteEnabled = true playEmote(LocalPlayer.Character) end
		ESPEnabled = Config.ESPEnabled
	end
end

print("[UconfigE] All systems loaded!")
print("[UconfigE] RightShift to toggle menu")
