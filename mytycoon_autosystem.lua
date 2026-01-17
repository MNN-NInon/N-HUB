-- =====================================================
-- N-HUB | My Tycoon Farm
-- AutoCollect + AutoBuy (WARP MODE)
-- Version : V.1.3.2 (UNIVERSAL TYCOON)
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

-- ===== BASE POSITION (สำคัญมาก) =====
local BASE_POSITION = HRP.Position

-- ===== VARIABLES =====
local AutoCollect = true
local AutoBuy = false
local UI_VISIBLE = true

local COLLECT_DELAY = 60
local BASE_RADIUS = 80 -- ระยะบ้าน (ถ้าบ้านกว้าง ปรับเป็น 120 ได้)
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
frame.Size = UDim2.fromOffset(230,190)
frame.Position = UDim2.fromOffset(20,220)
frame.BackgroundColor3 = Color3.fromRGB(15,15,15)
frame.BackgroundTransparency = 0.15
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,28)
title.BackgroundTransparency = 1
title.Text = "N-HUB | TYCOON"
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)

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

local collectBtn = makeBtn("AUTO COLLECT : ON",40)
local buyBtn = makeBtn("AUTO BUY : OFF",72)

local priceBox = Instance.new("TextBox", frame)
priceBox.Position = UDim2.fromOffset(20,104)
priceBox.Size = UDim2.fromOffset(190,26)
priceBox.Text = tostring(MinPrice)
priceBox.TextScaled = true
priceBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
priceBox.TextColor3 = Color3.new(1,1,1)

local hideBtn = makeBtn("HIDE / SHOW (G)",140)

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
			if (BASE_POSITION - z.Position).Magnitude <= BASE_RADIUS then
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
local HOLD_AFTER_BUY = 1.0 -- ⏸️ ยืนคาหลังซื้อ
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
	while task.wait(0.25) do
		if not AutoBuy then continue end
		if tick() - LAST_BUY < BUY_DELAY then continue end

		for _,p in pairs(workspace:GetDescendants()) do
			if not AutoBuy then break end
			if not p:IsA("ProximityPrompt") then continue end
			if p.ActionText ~= "Buy!" and p.ActionText ~= "Purchase" then continue end

			local part =
				p.Parent:IsA("BasePart") and p.Parent
				or p.Parent:FindFirstChildWhichIsA("BasePart")
			if not part then continue end

			if (part.Position - BASE_POSITION).Magnitude > BASE_RADIUS then
				continue
			end

			local price = GetPrice(p.Parent)
			if not price or price < MinPrice then continue end

			local oldCF = HRP.CFrame

			-- 🌀 วาปไปหน้ากล่อง
			HRP.CFrame = part.CFrame * CFrame.new(0, 0, -3)

			-- 🛒 ซื้อทันที
			fireproximityprompt(p)

			-- ⏸️ ยืนคาให้ดูเนียน
			task.wait(HOLD_AFTER_BUY)

			-- 🔙 วาปกลับ
			HRP.CFrame = oldCF

			LAST_BUY = tick()
			break
		end
	end
end)
