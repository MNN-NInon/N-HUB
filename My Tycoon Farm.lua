-- =====================================================
-- N-HUB | My Tycoon Farm (FIXED VERSION)
-- AutoCollect + AutoBuy (WARP MODE)
-- Fixed: Character Respawn Bug
-- =====================================================

-- ===== KEY SYSTEM =====
local VALID_KEY = "NONON123"
if not _G.KEY or _G.KEY ~= VALID_KEY then
	warn("❌ INVALID KEY : กรุณาใส่ _G.KEY = 'NONON123' ก่อนรัน")
	-- return -- เปิดบรรทัดนี้ถ้าต้องการบังคับใช้คีย์
end

repeat task.wait() until game:IsLoaded()
task.wait(1)

-- ===== SERVICES =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

-- ฟังก์ชันช่วยดึง Character ปัจจุบัน (แก้ปัญหาตายแล้วสคริปต์พัง)
local function getRoot()
	local char = LP.Character
	if char then
		return char:FindFirstChild("HumanoidRootPart")
	end
	return nil
end

local function getHum()
	local char = LP.Character
	if char then
		return char:FindFirstChildWhichIsA("Humanoid")
	end
	return nil
end

-- =====================================================
-- =============== CONFIG SYSTEM =======================
-- =====================================================
local CONFIG_FILE = "N-HUB_MyTycoonFarm_Config.json"

local Config = {
	AutoCollect = true,
	AutoBuy = false,
	MinPrice = 250,
	UI_VISIBLE = true,
	MINIMIZED = false,
	Fly = false
}

local function LoadConfig()
	if isfile(CONFIG_FILE) then
		local ok, data = pcall(function()
			return HttpService:JSONDecode(readfile(CONFIG_FILE))
		end)
		if ok and type(data) == "table" then
			for k,v in pairs(Config) do
				if data[k] ~= nil then
					Config[k] = data[k]
				end
			end
		end
	end
end

local function SaveConfig()
	pcall(function()
		writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
	end)
end

LoadConfig()

-- ===== APPLY CONFIG =====
local AutoCollect = Config.AutoCollect
local AutoBuy     = Config.AutoBuy
local UI_VISIBLE  = Config.UI_VISIBLE
local MINIMIZED   = Config.MINIMIZED
local MinPrice    = Config.MinPrice
local FlyEnabled  = Config.Fly

getgenv().MinPrice = MinPrice

-- ================== ANTI AFK ==================
task.spawn(function()
	while task.wait(60) do
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new(0,0))
		end)
	end
end)

-- ===== BASE POSITION (Updated to be safer) =====
-- แนะนำให้ผู้เล่นยืนที่ Tycoon ก่อนรัน
local initialRoot = getRoot()
local BASE_POSITION = initialRoot and initialRoot.Position or Vector3.new(0,0,0)

-- ===== VARIABLES =====
local COLLECT_DELAY = 60
local BASE_RADIUS = 100 -- เพิ่มระยะเล็กน้อย

-- ===== WARP STABILIZER =====
local WARP_IN_DELAY  = 0.35
local WARP_OUT_DELAY = 0.25
local LOCK_TIME      = 0.18

-- ===== CLEAR UI =====
pcall(function()
	if PlayerGui:FindFirstChild("MainAutoUI") then
		PlayerGui.MainAutoUI:Destroy()
	end
end)

-- ===== FLY SYSTEM (FIXED) =====
local FlyBV, FlyBG
local FlySpeed = 60

local function StopFly()
	FlyEnabled = false
	Config.Fly = false
	SaveConfig()
	
	if FlyBV then FlyBV:Destroy(); FlyBV = nil end
	if FlyBG then FlyBG:Destroy(); FlyBG = nil end
	
	local hum = getHum()
	if hum then hum.PlatformStand = false end
end

local function StartFly()
	if FlyBV then StopFly() end -- Reset if exists
	local hum = getHum()
	local root = getRoot()
	if not hum or not root then return end

	FlyEnabled = true
	Config.Fly = true
	SaveConfig()

	FlyBV = Instance.new("BodyVelocity")
	FlyBV.MaxForce = Vector3.new(9e9,9e9,9e9)
	FlyBV.Parent = root

	FlyBG = Instance.new("BodyGyro")
	FlyBG.MaxTorque = Vector3.new(9e9,9e9,9e9)
	FlyBG.P = 9e4
	FlyBG.Parent = root

	hum.PlatformStand = true

	task.spawn(function()
		while FlyEnabled and FlyBV and FlyBV.Parent do
			local root = getRoot()
			if not root then break end
			
			local cam = workspace.CurrentCamera
			local move = Vector3.zero

			if UIS:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then move += cam.CFrame.UpVector end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= cam.CFrame.UpVector end

			FlyBV.Velocity = move.Magnitude > 0 and move.Unit * FlySpeed or Vector3.zero
			FlyBG.CFrame = cam.CFrame
			RunService.RenderStepped:Wait()
		end
		-- ถ้าลูปหลุดให้เคลียร์ค่า
		StopFly()
	end)
end

-- =====================================================
-- ================= RAYFIELD UI =======================
-- =====================================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "N-HUB | My Tycoon Farm",
	LoadingTitle = "N-HUB",
	LoadingSubtitle = "Rayfield Edition",
	ConfigurationSaving = {
		Enabled = false -- ใช้ Config เดิมของสคริปต์มึงอยู่แล้ว
	},
	KeySystem = false
})

local MainTab = Window:CreateTab("Main", 4483362458)

-- ================= TOGGLES =================

MainTab:CreateToggle({
	Name = "Auto Collect",
	CurrentValue = AutoCollect,
	Callback = function(v)
		AutoCollect = v
		Config.AutoCollect = v
		SaveConfig()
	end
})

MainTab:CreateToggle({
	Name = "Auto Buy",
	CurrentValue = AutoBuy,
	Callback = function(v)
		AutoBuy = v
		Config.AutoBuy = v
		SaveConfig()
	end
})

-- ================= MIN PRICE =================

MainTab:CreateInput({
	Name = "Min Price",
	PlaceholderText = tostring(MinPrice),
	RemoveTextAfterFocusLost = false,
	Callback = function(txt)
		local n = tonumber(txt)
		if n then
			MinPrice = n
			Config.MinPrice = n
			getgenv().MinPrice = n
			SaveConfig()
		end
	end
})

-- ================= FLY =================

MainTab:CreateToggle({
	Name = "Fly (F)",
	CurrentValue = FlyEnabled,
	Callback = function(v)
		if v then
			StartFly()
		else
			StopFly()
		end
	end
})

-- ================= NOTIFY =================

Rayfield:Notify({
	Title = "N-HUB",
	Content = "Loaded Successfully",
	Duration = 4
})

-- =====================================================
-- ============ AUTO BUY (STABILIZED) ==================
-- =====================================================
local BUY_DELAY = 0.7
local LAST_BUY = 0
local CachedPrompts = {}

local function GetPrice(obj)
	local best
	for _,v in pairs(obj:GetDescendants()) do
		if v:IsA("TextLabel") or v:IsA("TextButton") then
			local cleanText = v.Text:gsub(",",""):gsub("%$","") -- ลบ $ ออกด้วย
			local n = tonumber(cleanText:match("%d+"))
			if n and (not best or n > best) then best = n end
		end
	end
	return best
end

local function RefreshPrompts()
	CachedPrompts = {}
	for _,p in pairs(workspace:GetDescendants()) do
		if p:IsA("ProximityPrompt") and (p.ActionText:match("Buy") or p.ActionText:match("Purchase")) then
			local part = p.Parent:IsA("BasePart") and p.Parent or p.Parent:FindFirstChildWhichIsA("BasePart")
			if part and (part.Position-BASE_POSITION).Magnitude <= BASE_RADIUS then
				table.insert(CachedPrompts,p)
			end
		end
	end
end

task.spawn(function()
	while task.wait(8) do
		if AutoBuy then RefreshPrompts() end
	end
end)

task.spawn(function()
	while task.wait(0.4) do
		if not AutoBuy or tick()-LAST_BUY < BUY_DELAY then continue end
		
		-- FIX: เช็ค HRP ในลูป
		local root = getRoot()
		if not root then continue end

		for _,p in pairs(CachedPrompts) do
			if not p.Parent then continue end
			local part = p.Parent:IsA("BasePart") and p.Parent or p.Parent:FindFirstChildWhichIsA("BasePart")
			if not part then continue end

			local price = GetPrice(p.Parent)
			if not price or price < MinPrice then continue end
			
			-- Logic การซื้อ
			local old = root.CFrame
			root.CFrame = part.CFrame * CFrame.new(0,0,-3)
			task.wait(WARP_IN_DELAY)

			local t0 = tick()
			while tick()-t0 < LOCK_TIME do
				if root then
					root.CFrame = part.CFrame * CFrame.new(0,0,-3)
				end
				RunService.Heartbeat:Wait()
			end

			if p and p.Parent then
				fireproximityprompt(p)
			end
			
			task.wait(WARP_OUT_DELAY)
			
			if root then
				root.CFrame = old
			end

			LAST_BUY = tick()
			break -- ซื้อทีละชิ้นแล้ววนใหม่
		end
	end
end)

-- =====================================================
-- ============== AUTO COLLECT =========================
-- =====================================================
task.spawn(function()
	while task.wait(COLLECT_DELAY) do
		if not AutoCollect then continue end
		
		-- FIX: เช็ค HRP ในลูป
		local root = getRoot()
		if not root then continue end

		for _,v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") then
				local name = v.Name:lower()
				-- เพิ่มเงื่อนไขการหาชื่อให้กว้างขึ้น
				if name:find("collect") or name:find("money") or name:find("cash") or name:find("drop") then
					if (v.Position - BASE_POSITION).Magnitude <= BASE_RADIUS then
						local old = root.CFrame
						
						-- Teleport ไปเก็บ
						root.CFrame = v.CFrame + Vector3.new(0,3,0)
						task.wait(0.15)
						
						firetouchinterest(root, v, 0)
						firetouchinterest(root, v, 1)
						
						task.wait(0.15)
						if root then
							root.CFrame = old
						end
					end
				end
			end
		end
	end
end)
