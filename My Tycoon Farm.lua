-- =====================================================
-- N-HUB | My Tycoon Farm
-- AutoCollect + AutoBuy + FLY (WARP MODE)
-- Version : V.1.3.5 (STABLE MERGED)
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
-- ================= CONFIG ============================
-- =====================================================
local CONFIG_FILE = "N-HUB_MyTycoonFarm_Config.json"

local Config = {
	AutoCollect = true,
	AutoBuy = false,
	MinPrice = 250,
	UI_VISIBLE = true,
	MINIMIZED = false,
	FLY = false
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

local AutoCollect = Config.AutoCollect
local AutoBuy = Config.AutoBuy
local UI_VISIBLE = Config.UI_VISIBLE
local MINIMIZED = Config.MINIMIZED
local MinPrice = Config.MinPrice
local FLYING = Config.FLY

-- =====================================================
-- ================= ANTI AFK ==========================
-- =====================================================
task.spawn(function()
	while task.wait(30) do
		if not LP.Character or not LP.Character:FindFirstChild("Humanoid") then continue end
		local hum = LP.Character.Humanoid
		local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then continue end

		hum:Move(Vector3.new(0,0,-1), true)
		task.wait(0.15)
		hum:Move(Vector3.new(0,0,1), true)
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

-- ===== BASE =====
local BASE_POSITION = HRP.Position
local BASE_RADIUS = 80
local COLLECT_DELAY = 60

-- ===== WARP =====
local WARP_IN_DELAY  = 0.35
local WARP_OUT_DELAY = 0.25
local LOCK_TIME      = 0.18

-- ===== CLEAR UI =====
pcall(function()
	PlayerGui.MainAutoUI:Destroy()
end)

-- =====================================================
-- ================= UI ================================
-- =====================================================
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "MainAutoUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(230,240)
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

local priceBox = Instance.new("TextBox", frame)
priceBox.Position = UDim2.fromOffset(20,104)
priceBox.Size = UDim2.fromOffset(190,26)
priceBox.TextScaled = true
priceBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
priceBox.TextColor3 = Color3.new(1,1,1)

local flyBtn = makeBtn("",136)
local hideBtn = makeBtn("HIDE / SHOW (G)",168)

-- ===== UI LOGIC =====
local function updateUI()
	title.Text = MINIMIZED and "N-HUB (MINI)" or "N-HUB | TYCOON"
	minimizeBtn.Text = MINIMIZED and "+" or "-"
	collectBtn.Text = AutoCollect and "AUTO COLLECT : ON" or "AUTO COLLECT : OFF"
	buyBtn.Text = AutoBuy and "AUTO BUY : ON" or "AUTO BUY : OFF"
	flyBtn.Text = FLYING and "FLY : ON" or "FLY : OFF"
	priceBox.Text = tostring(MinPrice)
end

local function SetMini(state)
	MINIMIZED = state
	Config.MINIMIZED = state
	SaveConfig()

	frame.Size = state and MINI_SIZE or FULL_SIZE
	for _,v in pairs(frame:GetChildren()) do
		if v ~= title and v ~= minimizeBtn then
			v.Visible = not state
		end
	end
	updateUI()
end

updateUI()
SetMini(MINIMIZED)

minimizeBtn.MouseButton1Click:Connect(function()
	SetMini(not MINIMIZED)
end)

collectBtn.MouseButton1Click:Connect(function()
	AutoCollect = not AutoCollect
	Config.AutoCollect = AutoCollect
	SaveConfig()
	updateUI()
end)

buyBtn.MouseButton1Click:Connect(function()
	AutoBuy = not AutoBuy
	Config.AutoBuy = AutoBuy
	SaveConfig()
	updateUI()
end)

hideBtn.MouseButton1Click:Connect(function()
	UI_VISIBLE = not UI_VISIBLE
	Config.UI_VISIBLE = UI_VISIBLE
	frame.Visible = UI_VISIBLE
	SaveConfig()
end)

UIS.InputBegan:Connect(function(i,g)
	if not g and i.KeyCode == Enum.KeyCode.G then
		UI_VISIBLE = not UI_VISIBLE
		Config.UI_VISIBLE = UI_VISIBLE
		frame.Visible = UI_VISIBLE
		SaveConfig()
	end
end)

priceBox.FocusLost:Connect(function()
	local n = tonumber(priceBox.Text)
	if n then
		MinPrice = n
		Config.MinPrice = n
		SaveConfig()
	end
	updateUI()
end)

-- =====================================================
-- ================= FLY ===============================
-- =====================================================
local flySpeed = 70
local BV, BG
local ctrl = {f=0,b=0,l=0,r=0,u=0,d=0}

local function startFly()
	if FLYING then return end
	FLYING = true
	Config.FLY = true
	SaveConfig()

	local cam = workspace.CurrentCamera

	BV = Instance.new("BodyVelocity", HRP)
	BV.MaxForce = Vector3.new(9e9,9e9,9e9)

	BG = Instance.new("BodyGyro", HRP)
	BG.MaxTorque = Vector3.new(9e9,9e9,9e9)

	task.spawn(function()
		while FLYING do
			BV.Velocity =
				cam.CFrame.LookVector * (ctrl.f - ctrl.b) +
				cam.CFrame.RightVector * (ctrl.r - ctrl.l) +
				Vector3.new(0,(ctrl.u - ctrl.d),0)
			BV.Velocity *= flySpeed
			BG.CFrame = cam.CFrame
			RunService.RenderStepped:Wait()
		end
	end)
	updateUI()
end

local function stopFly()
	FLYING = false
	Config.FLY = false
	SaveConfig()
	if BV then BV:Destroy() BV=nil end
	if BG then BG:Destroy() BG=nil end
	updateUI()
end

flyBtn.MouseButton1Click:Connect(function()
	if FLYING then stopFly() else startFly() end
end)

UIS.InputBegan:Connect(function(i,g)
	if g then return end
	if i.KeyCode == Enum.KeyCode.W then ctrl.f=1 end
	if i.KeyCode == Enum.KeyCode.S then ctrl.b=1 end
	if i.KeyCode == Enum.KeyCode.A then ctrl.l=1 end
	if i.KeyCode == Enum.KeyCode.D then ctrl.r=1 end
	if i.KeyCode == Enum.KeyCode.Space then ctrl.u=1 end
	if i.KeyCode == Enum.KeyCode.LeftControl then ctrl.d=1 end
end)

UIS.InputEnded:Connect(function(i)
	if i.KeyCode == Enum.KeyCode.W then ctrl.f=0 end
	if i.KeyCode == Enum.KeyCode.S then ctrl.b=0 end
	if i.KeyCode == Enum.KeyCode.A then ctrl.l=0 end
	if i.KeyCode == Enum.KeyCode.D then ctrl.r=0 end
	if i.KeyCode == Enum.KeyCode.Space then ctrl.u=0 end
	if i.KeyCode == Enum.KeyCode.LeftControl then ctrl.d=0 end
end)

if FLYING then startFly() end
