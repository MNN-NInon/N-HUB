-- =====================================================
-- N-HUB | My Tycoon Farm
-- AutoCollect + AutoBuy (WARP MODE)
-- Version : V.1.3.1 (STABLE | TYCOON SAFE)
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

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local Char = LP.Character or LP.CharacterAdded:Wait()
local HRP = Char:WaitForChild("HumanoidRootPart")

-- ===== VARIABLES =====
local AutoCollect = true
local AutoBuy = false
local UI_VISIBLE = true

local COLLECT_DELAY = 60
local MinPrice = tonumber(getgenv().MinPrice) or 250
getgenv().MinPrice = MinPrice

-- ===== CLEAR UI =====
pcall(function()
	PlayerGui.MainAutoUI:Destroy()
end)

-- ===== UI =====
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "MainAutoUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(240,200)
frame.Position = UDim2.fromOffset(20,220)
frame.BackgroundColor3 = Color3.fromRGB(15,15,15)
frame.BackgroundTransparency = 0.15
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.BackgroundTransparency = 1
title.Text = "N-HUB | TYCOON"
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)

local function makeBtn(txt,y)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.fromOffset(200,28)
	b.Position = UDim2.fromOffset(20,y)
	b.Text = txt
	b.TextScaled = true
	b.BackgroundColor3 = Color3.fromRGB(40,40,40)
	b.TextColor3 = Color3.new(1,1,1)
	return b
end

local collectBtn = makeBtn("AUTO COLLECT : ON",40)
local buyBtn = makeBtn("AUTO BUY : OFF",75)

local priceBox = Instance.new("TextBox", frame)
priceBox.Position = UDim2.fromOffset(20,110)
priceBox.Size = UDim2.fromOffset(200,28)
priceBox.Text = tostring(MinPrice)
priceBox.TextScaled = true
priceBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
priceBox.TextColor3 = Color3.new(1,1,1)

local hideBtn = makeBtn("HIDE / SHOW (G)",150)

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

hideBtn.MouseButton1Click:Connect(function()
	UI_VISIBLE = not UI_VISIBLE
	frame.Visible = UI_VISIBLE
end)

UIS.InputBegan:Connect(function(i,g)
	if g then return end
	if i.KeyCode == Enum.KeyCode.G then
		UI_VISIBLE = not UI_VISIBLE
		frame.Visible = UI_VISIBLE
	end
end)

priceBox.FocusLost:Connect(function()
	local n = tonumber(priceBox.Text)
	if n then
		MinPrice = n
		getgenv().MinPrice = n
	end
	priceBox.Text = tostring(MinPrice)
end)

-- =================================================
-- ================= TYCOON CHECK ==================
-- =================================================
local function IsMyTycoon(obj)
	local current = obj
	while current and current ~= workspace do
		if current:FindFirstChild("Owner") then
			local o = current.Owner.Value
			if o == LP or o == LP.UserId or o == LP.Name then
				return true
			end
		end
		if current:FindFirstChild("Player") then
			if current.Player.Value == LP then
				return true
			end
		end
		current = current.Parent
	end
	return false
end

-- =================================================
-- ================= AUTO COLLECT ==================
-- =================================================
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

		local originalCF = HRP.CFrame
		local wasBuy = AutoBuy
		AutoBuy = false

		for _,z in pairs(GetCollectZones()) do
			if not AutoCollect then break end
			if (originalCF.Position - z.Position).Magnitude <= 120 then
				HRP.CFrame = CFrame.new(z.Position)
				RunService.Heartbeat:Wait()
				RunService.Heartbeat:Wait()
			end
		end

		HRP.CFrame = originalCF
		AutoBuy = wasBuy
	end
end)

-- =================================================
-- ================= AUTO BUY (WARP) ================
-- =================================================
local BUY_DELAY = 1.2
local LAST_BUY = 0

local function GetPrice(obj)
	local best
	for _,v in pairs(obj:GetDescendants()) do
		if v:IsA("TextLabel") or v:IsA("TextButton") then
			local t = v.Text:gsub(",","")
			local n = tonumber(t:match("%d+"))
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
		if tick() - LAST_BUY < BUY_DELAY then continue end

		for _,p in pairs(workspace:GetDescendants()) do
			if not AutoBuy then break end
			if not p:IsA("ProximityPrompt") then continue end
			if p.ActionText ~= "Buy!" and p.ActionText ~= "Purchase" then continue end
			if not IsMyTycoon(p) then continue end

			local part =
				p.Parent:IsA("BasePart") and p.Parent
				or p.Parent:FindFirstChildWhichIsA("BasePart")
			if not part then continue end

			local price = GetPrice(p.Parent)
			if not price or price < MinPrice then continue end

			local old = HRP.CFrame
			HRP.CFrame = part.CFrame * CFrame.new(0,0,-3)
			RunService.Heartbeat:Wait()
			fireproximityprompt(p)
			RunService.Heartbeat:Wait()
			HRP.CFrame = old

			LAST_BUY = tick()
			break
		end
	end
end)
