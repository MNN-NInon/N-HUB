-- =====================================================
-- N-HUB | My Tycoon Farm
-- AutoCollect + AutoBuy (WARP) + Fly
-- Version : V.1.3.8b (FULL MERGED FINAL)
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
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local Char = LP.Character or LP.CharacterAdded:Wait()
local HRP = Char:WaitForChild("HumanoidRootPart")

-- =====================================================
-- ================= CONFIG SYSTEM =====================
-- =====================================================
local CFG_FOLDER = "NHUB"
local CFG_FILE = CFG_FOLDER.."/mytycoonfarm.json"
if not isfolder(CFG_FOLDER) then makefolder(CFG_FOLDER) end

local Config = {
	AutoCollect = true,
	AutoBuy = false,
	MinPrice = 250,
	Fly = false
}

local function LoadConfig()
	if isfile(CFG_FILE) then
		local ok,data = pcall(function()
			return HttpService:JSONDecode(readfile(CFG_FILE))
		end)
		if ok and type(data)=="table" then
			for k,v in pairs(data) do Config[k]=v end
		end
	end
end

local function SaveConfig()
	pcall(function()
		writefile(CFG_FILE,HttpService:JSONEncode(Config))
	end)
end

LoadConfig()

-- =====================================================
-- ================= STATES ============================
-- =====================================================
local AutoCollect = Config.AutoCollect
local AutoBuy = Config.AutoBuy
local MinPrice = Config.MinPrice
local FLYING = Config.Fly

local UI_VISIBLE = true
local MINIMIZED = false

local BASE_POSITION = HRP.Position
local BASE_RADIUS = 80
local COLLECT_DELAY = 60

-- ===== WARP =====
local WARP_IN_DELAY  = 0.35
local WARP_OUT_DELAY = 0.25
local LOCK_TIME      = 0.18

-- =====================================================
-- ================= ANTI AFK ==========================
-- =====================================================
task.spawn(function()
	while task.wait(30) do
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end
end)

-- =====================================================
-- ================= UI ================================
-- =====================================================
pcall(function() PlayerGui.MainAutoUI:Destroy() end)

local gui = Instance.new("ScreenGui",PlayerGui)
gui.Name = "MainAutoUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame",gui)
frame.Size = UDim2.fromOffset(230,220)
frame.Position = UDim2.fromOffset(20,220)
frame.BackgroundColor3 = Color3.fromRGB(15,15,15)
frame.BackgroundTransparency = 0.15
frame.Active = true
frame.Draggable = true

local FULL_SIZE = frame.Size
local MINI_SIZE = UDim2.fromOffset(230,36)

local title = Instance.new("TextLabel",frame)
title.Size = UDim2.new(1,-30,0,28)
title.Position = UDim2.fromOffset(5,4)
title.BackgroundTransparency = 1
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)

local minimizeBtn = Instance.new("TextButton",frame)
minimizeBtn.Size = UDim2.fromOffset(26,26)
minimizeBtn.Position = UDim2.fromOffset(198,4)
minimizeBtn.TextScaled = true
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
minimizeBtn.TextColor3 = Color3.new(1,1,1)

local function makeBtn(y)
	local b = Instance.new("TextButton",frame)
	b.Size = UDim2.fromOffset(190,26)
	b.Position = UDim2.fromOffset(20,y)
	b.TextScaled = true
	b.BackgroundColor3 = Color3.fromRGB(40,40,40)
	b.TextColor3 = Color3.new(1,1,1)
	return b
end

local collectBtn = makeBtn(40)
local buyBtn     = makeBtn(72)

local priceBox = Instance.new("TextBox",frame)
priceBox.Position = UDim2.fromOffset(20,104)
priceBox.Size = UDim2.fromOffset(190,26)
priceBox.TextScaled = true
priceBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
priceBox.TextColor3 = Color3.new(1,1,1)

local flyBtn  = makeBtn(136)
local hideBtn = makeBtn(168)

local function updateUI()
	title.Text = MINIMIZED and "N-HUB (MINI)" or "N-HUB | TYCOON"
	minimizeBtn.Text = MINIMIZED and "+" or "-"
	collectBtn.Text = AutoCollect and "AUTO COLLECT : ON" or "AUTO COLLECT : OFF"
	buyBtn.Text = AutoBuy and "AUTO BUY : ON" or "AUTO BUY : OFF"
	flyBtn.Text = FLYING and "FLY : ON (F)" or "FLY : OFF (F)"
	priceBox.Text = tostring(MinPrice)
end
updateUI()

-- ===== UI EVENTS =====
minimizeBtn.MouseButton1Click:Connect(function()
	MINIMIZED = not MINIMIZED
	frame.Size = MINIMIZED and MINI_SIZE or FULL_SIZE
	for _,v in pairs(frame:GetChildren()) do
		if v~=title and v~=minimizeBtn then v.Visible = not MINIMIZED end
	end
	updateUI()
end)

collectBtn.MouseButton1Click:Connect(function()
	AutoCollect = not AutoCollect
	Config.AutoCollect = AutoCollect
	SaveConfig(); updateUI()
end)

buyBtn.MouseButton1Click:Connect(function()
	AutoBuy = not AutoBuy
	Config.AutoBuy = AutoBuy
	SaveConfig(); updateUI()
end)

flyBtn.MouseButton1Click:Connect(function()
	FLYING = not FLYING
	Config.Fly = FLYING
	SaveConfig(); updateUI()
end)

hideBtn.MouseButton1Click:Connect(function()
	UI_VISIBLE = not UI_VISIBLE
	frame.Visible = UI_VISIBLE
end)

UIS.InputBegan:Connect(function(i,g)
	if g then return end
	if i.KeyCode==Enum.KeyCode.G then
		UI_VISIBLE = not UI_VISIBLE
		frame.Visible = UI_VISIBLE
	elseif i.KeyCode==Enum.KeyCode.F then
		FLYING = not FLYING
		Config.Fly = FLYING
		SaveConfig(); updateUI()
	end
end)

priceBox.FocusLost:Connect(function()
	local n=tonumber(priceBox.Text)
	if n then
		MinPrice=n
		Config.MinPrice=n
		SaveConfig()
	end
	updateUI()
end)

-- =====================================================
-- ================= FLY CORE ==========================
-- =====================================================
local flySpeed = 70
local BV, BG
local ctrl = {f=0,b=0,l=0,r=0,u=0,d=0}

task.spawn(function()
	while task.wait() do
		if FLYING and not BV then
			BV = Instance.new("BodyVelocity",HRP)
			BV.MaxForce = Vector3.new(9e9,9e9,9e9)
			BG = Instance.new("BodyGyro",HRP)
			BG.MaxTorque = Vector3.new(9e9,9e9,9e9)
		end

		if not FLYING and BV then
			BV:Destroy() BV=nil
			BG:Destroy() BG=nil
		end

		if FLYING and BV then
			local cam = workspace.CurrentCamera
			BV.Velocity =
				cam.CFrame.LookVector * (ctrl.f - ctrl.b) +
				cam.CFrame.RightVector * (ctrl.r - ctrl.l) +
				Vector3.new(0, ctrl.u - ctrl.d, 0) * flySpeed
			BG.CFrame = cam.CFrame
		end
	end
end)

UIS.InputBegan:Connect(function(i,g)
	if g or not FLYING then return end
	if i.KeyCode==Enum.KeyCode.W then ctrl.f=1 end
	if i.KeyCode==Enum.KeyCode.S then ctrl.b=1 end
	if i.KeyCode==Enum.KeyCode.A then ctrl.l=1 end
	if i.KeyCode==Enum.KeyCode.D then ctrl.r=1 end
	if i.KeyCode==Enum.KeyCode.Space then ctrl.u=1 end
	if i.KeyCode==Enum.KeyCode.LeftControl then ctrl.d=1 end
end)

UIS.InputEnded:Connect(function(i)
	if i.KeyCode==Enum.KeyCode.W then ctrl.f=0 end
	if i.KeyCode==Enum.KeyCode.S then ctrl.b=0 end
	if i.KeyCode==Enum.KeyCode.A then ctrl.l=0 end
	if i.KeyCode==Enum.KeyCode.D then ctrl.r=0 end
	if i.KeyCode==Enum.KeyCode.Space then ctrl.u=0 end
	if i.KeyCode==Enum.KeyCode.LeftControl then ctrl.d=0 end
end)

-- =====================================================
-- ================= AUTO BUY (WARP) ===================
-- =====================================================
local BUY_DELAY = 0.7
local LAST_BUY = 0
local CachedPrompts = {}

local function GetPrice(obj)
	local best
	for _,v in pairs(obj:GetDescendants()) do
		if v:IsA("TextLabel") or v:IsA("TextButton") then
			local n = tonumber(v.Text:gsub(",",""):match("%d+"))
			if n and (not best or n>best) then best=n end
		end
	end
	return best
end

local function RefreshPrompts()
	CachedPrompts = {}
	for _,p in pairs(workspace:GetDescendants()) do
		if p:IsA("ProximityPrompt")
		and (p.ActionText=="Buy!" or p.ActionText=="Purchase") then
			local part = p.Parent:IsA("BasePart") and p.Parent
				or p.Parent:FindFirstChildWhichIsA("BasePart")
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
			local part = p.Parent:IsA("BasePart") and p.Parent
				or p.Parent:FindFirstChildWhichIsA("BasePart")
			if not part then continue end

			local price = GetPrice(p.Parent)
			if not price or price < MinPrice then continue end

			local old = HRP.CFrame
			HRP.CFrame = part.CFrame * CFrame.new(0,0,-3)

			task.wait(WARP_IN_DELAY)
			local t0=tick()
			while tick()-t0<LOCK_TIME do
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
-- ================= AUTO COLLECT ======================
-- =====================================================
task.spawn(function()
	while task.wait(COLLECT_DELAY) do
		if not AutoCollect then continue end
		for _,v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") then
				local n=v.Name:lower()
				if n:find("collect") or n:find("cash")
				or n:find("money") or n:find("drop") then
					if (v.Position-BASE_POSITION).Magnitude<=BASE_RADIUS then
						local old=HRP.CFrame
						HRP.CFrame=v.CFrame+Vector3.new(0,3,0)
						task.wait(0.15)
						firetouchinterest(HRP,v,0)
						firetouchinterest(HRP,v,1)
						task.wait(0.15)
						HRP.CFrame=old
					end
				end
			end
		end
	end
end)
