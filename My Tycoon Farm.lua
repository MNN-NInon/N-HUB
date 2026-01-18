-- =====================================================
-- N-HUB | My Tycoon Farm
-- AutoCollect + AutoBuy (WARP MODE)
-- Version : V.1.3.4a + FLY
-- =====================================================

-- ===== KEY SYSTEM =====
local VALID_KEY = "NONON123"
if not _G.KEY or _G.KEY ~= VALID_KEY then
	warn("❌ INVALID KEY")
	return
end

repeat task.wait() until game:IsLoaded()
task.wait(1)

-- ===== SERVICES =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local Char = LP.Character or LP.CharacterAdded:Wait()
local HRP = Char:WaitForChild("HumanoidRootPart")

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

-- =====================================================
-- ================= ANTI AFK ==========================
-- =====================================================
task.spawn(function()
	while task.wait(30) do
		if not LP.Character or not LP.Character:FindFirstChild("Humanoid") then continue end
		local hum = LP.Character.Humanoid
		hum:Move(Vector3.new(0,0,-1), true)
		task.wait(0.15)
		hum:Move(Vector3.new(0,0,1), true)
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

-- ===== BASE POSITION =====
local BASE_POSITION = HRP.Position

-- ===== VARIABLES =====
local COLLECT_DELAY = 60
local BASE_RADIUS = 80

-- ===== WARP STABILIZER =====
local WARP_IN_DELAY  = 0.35
local WARP_OUT_DELAY = 0.25
local LOCK_TIME      = 0.18

-- ===== CLEAR UI =====
pcall(function()
	PlayerGui.MainAutoUI:Destroy()
end)

-- =====================================================
-- ===================== UI ============================
-- =====================================================
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "MainAutoUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(230,216)
frame.Position = UDim2.fromOffset(20,220)
frame.BackgroundColor3 = Color3.fromRGB(15,15,15)
frame.BackgroundTransparency = 0.15
frame.Active = true
frame.Draggable = true
frame.Visible = UI_VISIBLE

local FULL_SIZE = frame.Size
local MINI_SIZE = UDim2.fromOffset(230,36)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,-30,0,28)
title.Position = UDim2.fromOffset(5,4)
title.BackgroundTransparency = 1
title.Text = "N-HUB | TYCOON"
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)

local minimizeBtn = Instance.new("TextButton", frame)
minimizeBtn.Size = UDim2.fromOffset(26,26)
minimizeBtn.Position = UDim2.fromOffset(198,4)
minimizeBtn.TextScaled = true
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
minimizeBtn.TextColor3 = Color3.new(1,1,1)

local function makeBtn(txt,y)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.fromOffset(190,26)
	b.Position = UDim2.fromOffset(20,y)
	b.Text = txt
	b.TextScaled = true
	b.BackgroundColor3 = Color3.fromRGB(40,40,40)
	b.TextColor3 = Color3.new(1,1,1)
	return b
end

local collectBtn = makeBtn("",40)
local buyBtn = makeBtn("",72)
local flyBtn = makeBtn("",104)

local priceBox = Instance.new("TextBox", frame)
priceBox.Position = UDim2.fromOffset(20,136)
priceBox.Size = UDim2.fromOffset(190,26)
priceBox.Text = tostring(MinPrice)
priceBox.TextScaled = true
priceBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
priceBox.TextColor3 = Color3.new(1,1,1)

local hideBtn = makeBtn("HIDE / SHOW (G)",170)

local function updateUI()
	collectBtn.Text = AutoCollect and "AUTO COLLECT : ON" or "AUTO COLLECT : OFF"
	buyBtn.Text = AutoBuy and "AUTO BUY : ON" or "AUTO BUY : OFF"
	flyBtn.Text = FlyEnabled and "FLY : ON (F)" or "FLY : OFF (F)"
end

-- ===== FLY SYSTEM =====
local FlyBV, FlyBG
local FlySpeed = 60

local function StartFly()
	if FlyBV then return end
	local hum = Char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	FlyEnabled = true
	Config.Fly = true
	SaveConfig()

	FlyBV = Instance.new("BodyVelocity", HRP)
	FlyBV.MaxForce = Vector3.new(9e9,9e9,9e9)

	FlyBG = Instance.new("BodyGyro", HRP)
	FlyBG.MaxTorque = Vector3.new(9e9,9e9,9e9)
	FlyBG.P = 9e4

	hum.PlatformStand = true

	task.spawn(function()
		while FlyEnabled and FlyBV do
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
	end)
end

local function StopFly()
	FlyEnabled = false
	Config.Fly = false
	SaveConfig()

	if FlyBV then FlyBV:Destroy(); FlyBV = nil end
	if FlyBG then FlyBG:Destroy(); FlyBG = nil end

	local hum = Char:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = false end
end

-- ===== UI EVENTS =====
minimizeBtn.MouseButton1Click:Connect(function()
	MINIMIZED = not MINIMIZED
	Config.MINIMIZED = MINIMIZED
	SaveConfig()

	if MINIMIZED then
		frame.Size = MINI_SIZE
		title.Text = "N-HUB (MINI)"
		minimizeBtn.Text = "+"
		for _,v in pairs(frame:GetChildren()) do
			if v ~= title and v ~= minimizeBtn then v.Visible = false end
		end
	else
		frame.Size = FULL_SIZE
		title.Text = "N-HUB | TYCOON"
		minimizeBtn.Text = "-"
		for _,v in pairs(frame:GetChildren()) do v.Visible = true end
	end
end)

collectBtn.MouseButton1Click:Connect(function()
	AutoCollect = not AutoCollect
	Config.AutoCollect = AutoCollect
	updateUI()
	SaveConfig()
end)

buyBtn.MouseButton1Click:Connect(function()
	AutoBuy = not AutoBuy
	Config.AutoBuy = AutoBuy
	updateUI()
	SaveConfig()
end)

flyBtn.MouseButton1Click:Connect(function()
	if FlyEnabled then StopFly() else StartFly() end
	updateUI()
end)

hideBtn.MouseButton1Click:Connect(function()
	UI_VISIBLE = not UI_VISIBLE
	Config.UI_VISIBLE = UI_VISIBLE
	frame.Visible = UI_VISIBLE
	SaveConfig()
end)

UIS.InputBegan:Connect(function(i,g)
	if g then return end
	if i.KeyCode == Enum.KeyCode.G then
		UI_VISIBLE = not UI_VISIBLE
		Config.UI_VISIBLE = UI_VISIBLE
		frame.Visible = UI_VISIBLE
		SaveConfig()
	elseif i.KeyCode == Enum.KeyCode.F then
		if FlyEnabled then StopFly() else StartFly() end
		updateUI()
	end
end)

priceBox.FocusLost:Connect(function()
	local n = tonumber(priceBox.Text)
	if n then
		MinPrice = n
		Config.MinPrice = n
		getgenv().MinPrice = n
		SaveConfig()
	end
	priceBox.Text = tostring(MinPrice)
end)

updateUI()

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
			local n = tonumber(v.Text:gsub(",",""):match("%d+"))
			if n and (not best or n > best) then best = n end
		end
	end
	return best
end

local function RefreshPrompts()
	CachedPrompts = {}
	for _,p in pairs(workspace:GetDescendants()) do
		if p:IsA("ProximityPrompt") and (p.ActionText=="Buy!" or p.ActionText=="Purchase") then
			local part = p.Parent:IsA("BasePart") and p.Parent or p.Parent:FindFirstChildWhichIsA("BasePart")
			if part and (part.Position-BASE_POSITION).Magnitude<=BASE_RADIUS then
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
		if not AutoBuy or tick()-LAST_BUY<BUY_DELAY then continue end
		for _,p in pairs(CachedPrompts) do
			local part = p.Parent and (p.Parent:IsA("BasePart") and p.Parent or p.Parent:FindFirstChildWhichIsA("BasePart"))
			if not part then continue end

			local price = GetPrice(p.Parent)
			if not price or price < MinPrice then continue end

			local old = HRP.CFrame
			HRP.CFrame = part.CFrame * CFrame.new(0,0,-3)
			task.wait(WARP_IN_DELAY)

			local t0 = tick()
			while tick()-t0 < LOCK_TIME do
				HRP.CFrame = part.CFrame * CFrame.new(0,0,-3)
				RunService.Heartbeat:Wait()
			end

			fireproximityprompt(p)
			task.wait(WARP_OUT_DELAY)
			HRP.CFrame = old

			LAST_BUY = tick()
			break
		end
	end
end)

-- =====================================================
-- ============== AUTO COLLECT =========================
-- =====================================================
task.spawn(function()
	while task.wait(COLLECT_DELAY) do
		if not AutoCollect then continue end
		for _,v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") then
				local name = v.Name:lower()
				if name:find("collect") or name:find("money") or name:find("cash") then
					if (v.Position - BASE_POSITION).Magnitude <= BASE_RADIUS then
						local old = HRP.CFrame
						HRP.CFrame = v.CFrame + Vector3.new(0,3,0)
						task.wait(0.15)
						firetouchinterest(HRP, v, 0)
						firetouchinterest(HRP, v, 1)
						task.wait(0.15)
						HRP.CFrame = old
					end
				end
			end
		end
	end
end)
