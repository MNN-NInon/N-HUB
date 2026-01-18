-- =====================================================
-- N-HUB | My Tycoon Farm
-- AutoCollect + AutoBuy (WARP FAST)
-- Version : V.1.3.4c (UI FIX)
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

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local Char = LP.Character or LP.CharacterAdded:Wait()
local HRP = Char:WaitForChild("HumanoidRootPart")

-- ===== BASE POSITION =====
local BASE_POSITION = HRP.Position

-- ===== VARIABLES =====
local AutoCollect = true
local AutoBuy = false
local MINI_MODE = false

local COLLECT_DELAY = 60
local BASE_RADIUS = 80
local MinPrice = tonumber(getgenv().MinPrice) or 250
getgenv().MinPrice = MinPrice

-- ===== WARP FAST CONFIG =====
local WARP_IN_DELAY  = 0.35
local WARP_OUT_DELAY = 0.25
local LOCK_TIME      = 0.18
local BUY_DELAY      = 0.9
local LAST_BUY = 0

-- ===== ANTI AFK (SAFE) =====
LP.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
	task.wait(1)
	VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- ===== CLEAR UI =====
pcall(function()
	PlayerGui.MainAutoUI:Destroy()
end)

-- =====================================================
-- ======================= UI ==========================
-- =====================================================
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "MainAutoUI"
gui.ResetOnSpawn = false

-- ===== MAIN FRAME =====
local MainFrame = Instance.new("Frame", gui)
MainFrame.Size = UDim2.fromOffset(230,200)
MainFrame.Position = UDim2.fromOffset(20,220)
MainFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
MainFrame.BackgroundTransparency = 0.1
MainFrame.Active = true
MainFrame.Draggable = true

local title = Instance.new("TextLabel", MainFrame)
title.Size = UDim2.new(1,0,0,28)
title.BackgroundTransparency = 1
title.Text = "N-HUB | TYCOON"
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)

local function makeBtn(txt,y)
	local b = Instance.new("TextButton", MainFrame)
	b.Size = UDim2.fromOffset(190,26)
	b.Position = UDim2.fromOffset(20,y)
	b.Text = txt
	b.TextScaled = true
	b.BackgroundColor3 = Color3.fromRGB(40,40,40)
	b.TextColor3 = Color3.new(1,1,1)
	return b
end

local collectBtn = makeBtn("AUTO COLLECT : ON",40)
local buyBtn = makeBtn("AUTO BUY : OFF",72)

local priceBox = Instance.new("TextBox", MainFrame)
priceBox.Position = UDim2.fromOffset(20,104)
priceBox.Size = UDim2.fromOffset(190,26)
priceBox.Text = tostring(MinPrice)
priceBox.TextScaled = true
priceBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
priceBox.TextColor3 = Color3.new(1,1,1)

local miniBtn = makeBtn("MINI UI",136)

-- ===== MINI FRAME =====
local MiniFrame = Instance.new("Frame", gui)
MiniFrame.Size = UDim2.fromOffset(120,36)
MiniFrame.Position = MainFrame.Position
MiniFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
MiniFrame.BackgroundTransparency = 0.1
MiniFrame.Visible = false
MiniFrame.Active = true
MiniFrame.Draggable = true

local miniTitle = Instance.new("TextButton", MiniFrame)
miniTitle.Size = UDim2.fromScale(1,1)
miniTitle.Text = "N-HUB"
miniTitle.TextScaled = true
miniTitle.TextColor3 = Color3.new(1,1,1)
miniTitle.BackgroundTransparency = 1

-- ===== UI LOGIC =====
local function updateUI()
	collectBtn.Text = AutoCollect and "AUTO COLLECT : ON" or "AUTO COLLECT : OFF"
	buyBtn.Text = AutoBuy and "AUTO BUY : ON" or "AUTO BUY : OFF"
end
updateUI()

collectBtn.MouseButton1Click:Connect(function()
	AutoCollect = not AutoCollect
	updateUI()
end)

buyBtn.MouseButton1Click:Connect(function()
	AutoBuy = not AutoBuy
	updateUI()
end)

priceBox.FocusLost:Connect(function()
	local n = tonumber(priceBox.Text)
	if n then
		MinPrice = n
		getgenv().MinPrice = n
	end
	priceBox.Text = tostring(MinPrice)
end)

miniBtn.MouseButton1Click:Connect(function()
	MINI_MODE = true
	MainFrame.Visible = false
	MiniFrame.Visible = true
end)

miniTitle.MouseButton1Click:Connect(function()
	MINI_MODE = false
	MainFrame.Visible = true
	MiniFrame.Visible = false
end)

-- =====================================================
-- ================= AUTO COLLECT ======================
-- =====================================================
local function GetCollectZones()
	local t = {}
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") then
			local n = v.Name:lower()
			if n:find("collect") or n:find("zone") or n:find("trigger") then
				table.insert(t,v)
			end
		end
	end
	return t
end

task.spawn(function()
	while task.wait(COLLECT_DELAY) do
		if not AutoCollect then continue end

		local oldCF = HRP.CFrame
		local wasBuy = AutoBuy
		AutoBuy = false

		for _,z in pairs(GetCollectZones()) do
			if (BASE_POSITION - z.Position).Magnitude <= BASE_RADIUS then
				HRP.CFrame = CFrame.new(z.Position)
				RunService.Heartbeat:Wait()
				RunService.Heartbeat:Wait()
			end
		end

		HRP.CFrame = oldCF
		AutoBuy = wasBuy
	end
end)

-- =====================================================
-- ================= AUTO BUY ==========================
-- =====================================================
local function GetPrice(obj)
	local best
	for _,v in pairs(obj:GetDescendants()) do
		if v:IsA("TextLabel") or v:IsA("TextButton") then
			local n = tonumber(v.Text:gsub(",",""):match("%d+"))
			if n and (not best or n > best) then
				best = n
			end
		end
	end
	return best
end

task.spawn(function()
	while task.wait(0.25) do
		if not AutoBuy then continue end
		if tick() - LAST_BUY < BUY_DELAY then continue end

		for _,p in pairs(workspace:GetDescendants()) do
			if not p:IsA("ProximityPrompt") then continue end
			if p.ActionText ~= "Buy!" and p.ActionText ~= "Purchase" then continue end

			local part = p.Parent:IsA("BasePart") and p.Parent
				or p.Parent:FindFirstChildWhichIsA("BasePart")
			if not part then continue end
			if (part.Position - BASE_POSITION).Magnitude > BASE_RADIUS then continue end

			local price = GetPrice(p.Parent)
			if not price or price < MinPrice then continue end

			local old = HRP.CFrame
			HRP.CFrame = part.CFrame * CFrame.new(0,0,-3)
			task.wait(WARP_IN_DELAY)

			local t0 = tick()
			while tick() - t0 < LOCK_TIME do
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
