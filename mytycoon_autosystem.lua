-- ===== SAFE START =====
repeat task.wait() until game:IsLoaded()
task.wait(1)
print("AutoCollect + AutoBuy Loaded")

-- ===== SERVICES =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local Char = LP.Character or LP.CharacterAdded:Wait()
local HRP = Char:WaitForChild("HumanoidRootPart")

-- =================================================
-- ================== VARIABLES ====================
-- =================================================
local AutoCollect = true
local AutoBuy = false

local COLLECT_DELAY = 60
local MinPrice = 250

-- =================================================
-- ================= CLEAR UI ======================
-- =================================================
pcall(function()
	PlayerGui.MainAutoUI:Destroy()
end)

-- =================================================
-- ===================== UI ========================
-- =================================================
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "MainAutoUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(300, 230)
frame.Position = UDim2.fromOffset(20, 200)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,35)
title.BackgroundTransparency = 1
title.Text = "AUTO SYSTEM"
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)

-- ===== AUTO COLLECT UI =====
local collectStatus = Instance.new("TextLabel", frame)
collectStatus.Position = UDim2.fromOffset(10,45)
collectStatus.Size = UDim2.fromOffset(280,25)
collectStatus.BackgroundTransparency = 1
collectStatus.TextScaled = true

local collectBtn = Instance.new("TextButton", frame)
collectBtn.Position = UDim2.fromOffset(20,75)
collectBtn.Size = UDim2.fromOffset(260,30)
collectBtn.TextScaled = true
collectBtn.Text = "TOGGLE AUTO COLLECT"
collectBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
collectBtn.TextColor3 = Color3.new(1,1,1)

-- ===== AUTO BUY UI =====
local buyStatus = Instance.new("TextLabel", frame)
buyStatus.Position = UDim2.fromOffset(10,115)
buyStatus.Size = UDim2.fromOffset(280,25)
buyStatus.BackgroundTransparency = 1
buyStatus.TextScaled = true

local priceBox = Instance.new("TextBox", frame)
priceBox.Position = UDim2.fromOffset(20,145)
priceBox.Size = UDim2.fromOffset(260,30)
priceBox.Text = tostring(MinPrice)
priceBox.PlaceholderText = "Min Price"
priceBox.TextScaled = true
priceBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
priceBox.TextColor3 = Color3.new(1,1,1)

local buyBtn = Instance.new("TextButton", frame)
buyBtn.Position = UDim2.fromOffset(20,185)
buyBtn.Size = UDim2.fromOffset(260,30)
buyBtn.TextScaled = true
buyBtn.Text = "TOGGLE AUTO BUY"
buyBtn.BackgroundColor3 = Color3.fromRGB(80,0,0)
buyBtn.TextColor3 = Color3.new(1,1,1)

-- ===== UI UPDATE =====
local function updateUI()
	collectStatus.Text = AutoCollect and "AUTO COLLECT : ON" or "AUTO COLLECT : OFF"
	collectStatus.TextColor3 = AutoCollect and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)

	buyStatus.Text = AutoBuy and "AUTO BUY : ON" or "AUTO BUY : OFF"
	buyStatus.TextColor3 = AutoBuy and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
end
updateUI()

-- ===== UI ACTIONS =====
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
	if n then MinPrice = n end
	priceBox.Text = tostring(MinPrice)
end)

-- =================================================
-- ================= AUTO COLLECT ==================
-- =================================================
local function GetCollectZones()
	local zones = {}
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") then
			local n = v.Name:lower()
			if n:find("collect") or n:find("zone") or n:find("trigger") then
				table.insert(zones, v)
			end
		end
	end
	return zones
end

local function SlideThroughZone(zone)
	local old = HRP.CFrame
	for _,offset in ipairs({
		Vector3.new(0,0,0),
		Vector3.new(1,0,0),
		Vector3.new(-1,0,0),
		Vector3.new(0,0,1),
		Vector3.new(0,0,-1),
		Vector3.new(0,-2,0),
	}) do
		HRP.CFrame = CFrame.new(zone.Position + offset)
		RunService.Heartbeat:Wait()
	end
	HRP.CFrame = old
end

task.spawn(function()
	while task.wait(COLLECT_DELAY) do
		if not AutoCollect then continue end
		for _,zone in pairs(GetCollectZones()) do
			if (HRP.Position - zone.Position).Magnitude <= 120 then
				SlideThroughZone(zone)
			end
		end
	end
end)

-- =================================================
-- ================== AUTO BUY =====================
-- =================================================
local function GetPrice(obj)
	local best
	for _,v in pairs(obj:GetDescendants()) do
		if v:IsA("TextLabel") or v:IsA("TextButton") then
			local t = v.Text
			if not t or t == "" then continue end
			t = t:gsub(",", "")

			local n
			if t:find("K") then
				n = tonumber(t:match("%d+%.?%d*"))
				if n then n = n * 1000 end
			elseif t:find("M") then
				n = tonumber(t:match("%d+%.?%d*"))
				if n then n = n * 1000000 end
			else
				n = tonumber(t:match("%d+"))
			end

			if n and (not best or n > best) then
				best = n
			end
		end
	end
	return best
end

task.spawn(function()
	while task.wait(0.3) do
		if not AutoBuy then continue end

		for _,p in pairs(workspace:GetDescendants()) do
			if p:IsA("ProximityPrompt")
			and (p.ActionText == "Buy!" or p.ActionText == "Purchase") then

				local part =
					p.Parent:IsA("BasePart") and p.Parent
					or p.Parent:FindFirstChildWhichIsA("BasePart")

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
