-- =====================================================
-- N-HUB | My Tycoon Farm
-- AutoCollect + AutoBuy
-- Version : MAIN
-- =====================================================

-- ===== KEY SYSTEM =====
local VALID_KEY = "NONON123" -- 🔑 เปลี่ยนคีย์ตรงนี้

if not _G.KEY then
	warn("❌ NO KEY")
	return
end

if _G.KEY ~= VALID_KEY then
	warn("❌ INVALID KEY")
	return
end

print("✅ KEY OK - LOADING N-HUB")

-- ===== SAFE START =====
repeat task.wait() until game:IsLoaded()
task.wait(1)

-- ===== SERVICES =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local Char = LP.Character or LP.CharacterAdded:Wait()
local HRP = Char:WaitForChild("HumanoidRootPart")

-- ===== SETTINGS =====
local AutoBuy = false
local AutoCollect = false
local MinPrice = 250
local COLLECT_DELAY = 60 -- ⏱ 60 วิ

-- ===== CLEAR OLD UI =====
pcall(function()
	PlayerGui.NHubUI:Destroy()
end)

-- =====================================================
-- ======================= UI ==========================
-- =====================================================
local gui = Instance.new("ScreenGui")
gui.Name = "NHubUI"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(300, 220)
frame.Position = UDim2.fromOffset(20, 200)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local function MakeLabel(text, y)
	local l = Instance.new("TextLabel", frame)
	l.Size = UDim2.new(1, -20, 0, 25)
	l.Position = UDim2.fromOffset(10, y)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = Color3.new(1,1,1)
	l.TextScaled = true
	return l
end

local function MakeButton(text, y)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(1, -40, 0, 30)
	b.Position = UDim2.fromOffset(20, y)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(35,35,35)
	b.TextColor3 = Color3.new(1,1,1)
	b.TextScaled = true
	return b
end

MakeLabel("N-HUB | MY TYCOON FARM", 5)

local buyStatus = MakeLabel("AutoBuy : OFF", 35)
local collectStatus = MakeLabel("AutoCollect : OFF", 60)

local priceBox = Instance.new("TextBox", frame)
priceBox.Size = UDim2.new(1, -40, 0, 30)
priceBox.Position = UDim2.fromOffset(20, 90)
priceBox.Text = tostring(MinPrice)
priceBox.PlaceholderText = "Min Price"
priceBox.BackgroundColor3 = Color3.fromRGB(35,35,35)
priceBox.TextColor3 = Color3.new(1,1,1)
priceBox.TextScaled = true

local buyBtn = MakeButton("TOGGLE AUTO BUY", 130)
local collectBtn = MakeButton("TOGGLE AUTO COLLECT", 170)

-- ===== UI ACTIONS =====
buyBtn.MouseButton1Click:Connect(function()
	AutoBuy = not AutoBuy
	buyStatus.Text = AutoBuy and "AutoBuy : ON" or "AutoBuy : OFF"
end)

collectBtn.MouseButton1Click:Connect(function()
	AutoCollect = not AutoCollect
	collectStatus.Text = AutoCollect and "AutoCollect : ON" or "AutoCollect : OFF"
end)

priceBox.FocusLost:Connect(function()
	local n = tonumber(priceBox.Text)
	if n then MinPrice = n end
	priceBox.Text = tostring(MinPrice)
end)

-- =====================================================
-- ================== AUTO BUY =========================
-- =====================================================
local function GetPrice(obj)
	for _,v in pairs(obj:GetDescendants()) do
		if v:IsA("TextLabel") or v:IsA("TextButton") then
			local t = v.Text
			if t and t ~= "" then
				t = t:gsub(",", "")
				local n = tonumber(t:match("%d+"))
				if n then return n end
			end
		end
	end
end

task.spawn(function()
	while task.wait(0.3) do
		if not AutoBuy then continue end

		for _,p in pairs(workspace:GetDescendants()) do
			if p:IsA("ProximityPrompt")
			and (p.ActionText == "Buy!" or p.ActionText == "Purchase") then

				local part = p.Parent:FindFirstChildWhichIsA("BasePart")
				if part and (HRP.Position - part.Position).Magnitude <= 8 then
					local price = GetPrice(p.Parent)
					if price and price >= MinPrice then
						pcall(function()
							fireproximityprompt(p)
						end)
					end
				end
			end
		end
	end
end)

-- =====================================================
-- ================= AUTO COLLECT ======================
-- =====================================================
local function GetCollectZones()
	local zones = {}
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") then
			local n = v.Name:lower()
			if n:find("collect") or n:find("zone") then
				table.insert(zones, v)
			end
		end
	end
	return zones
end

local function TouchZone(zone)
	local old = HRP.CFrame
	HRP.CFrame = CFrame.new(zone.Position)
	RunService.Heartbeat:Wait()
	HRP.CFrame = old
end

task.spawn(function()
	while task.wait(COLLECT_DELAY) do
		if not AutoCollect then continue end
		for _,z in pairs(GetCollectZones()) do
			TouchZone(z)
		end
	end
end)
