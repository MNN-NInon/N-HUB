-- =====================================================
-- N-HUB | My Tycoon Farm
-- AutoCollect + AutoBuy + AntiAFK
-- Version : V.1.3.4b-r4 (FULL SAFE)
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

-- =================================================
-- ================= ANTI AFK =====================
-- =================================================
LP.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

-- ===== BASE POSITION =====
local BASE_POSITION = HRP.Position

-- ===== VARIABLES =====
local AutoCollect = true
local AutoBuy = false
local UI_VISIBLE = true
local MINIMIZED = false

local MinPrice = tonumber(getgenv().MinPrice) or 250
getgenv().MinPrice = MinPrice

-- ===== CLEAR UI =====
pcall(function()
	PlayerGui.MainAutoUI:Destroy()
end)

-- =================================================
-- =================== UI =========================
-- =================================================
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
minimizeBtn.Text = "-"
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

-- ===== MINI UI =====
local function SetMini(state)
	MINIMIZED = state
	if state then
		frame.Size = MINI_SIZE
		title.Text = "N-HUB (MINI)"
		minimizeBtn.Text = "+"
		for _,v in pairs(frame:GetChildren()) do
			if v ~= title and v ~= minimizeBtn then
				v.Visible = false
			end
		end
	else
		frame.Size = FULL_SIZE
		title.Text = "N-HUB | TYCOON"
		minimizeBtn.Text = "-"
		for _,v in pairs(frame:GetChildren()) do
			v.Visible = true
		end
	end
end

minimizeBtn.MouseButton1Click:Connect(function()
	SetMini(not MINIMIZED)
end)

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
	if not g and i.KeyCode == Enum.KeyCode.G then
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
-- ============== AUTO COLLECT (FIXED) ==============
-- =================================================
task.spawn(function()
	while task.wait(1) do
		if not AutoCollect then continue end
		if not HRP then continue end

		for _,p in ipairs(workspace:GetDescendants()) do
			if p:IsA("ProximityPrompt") then
				local text = (p.ActionText or ""):lower()
				if text:find("collect") or text:find("claim") then
					local parent = p.Parent
					if not parent then continue end

					local part =
						parent:IsA("BasePart") and parent
						or parent:FindFirstChildWhichIsA("BasePart")

					if part and (part.Position - HRP.Position).Magnitude <= 20 then
						fireproximityprompt(p)
						task.wait(0.3)
					end
				end
			end
		end
	end
end)

-- =================================================
-- ================= AUTO BUY (SAFE) ================
-- =================================================
local BUY_COOLDOWN = 0.8
local LAST_BUY = 0

local function getPrice(model)
	for _,v in ipairs(model:GetDescendants()) do
		if v:IsA("TextLabel") or v:IsA("TextButton") then
			local n = tonumber(v.Text:gsub(",",""):match("%d+"))
			if n then return n end
		end
	end
end

task.spawn(function()
	while task.wait(0.4) do
		if not AutoBuy then continue end
		if tick() - LAST_BUY < BUY_COOLDOWN then continue end
		if not HRP then continue end

		for _,p in ipairs(workspace:GetDescendants()) do
			if p:IsA("ProximityPrompt") then
				local parent = p.Parent
				if not parent then continue end

				local part =
					parent:IsA("BasePart") and parent
					or parent:FindFirstChildWhichIsA("BasePart")

				if not part then continue end
				if (part.Position - HRP.Position).Magnitude > 120 then continue end

				local price = getPrice(parent)
				if not price or price < MinPrice then continue end

				local old = HRP.CFrame
				HRP.CFrame = part.CFrame * CFrame.new(0,0,-3)
				task.wait(0.2)

				fireproximityprompt(p)
				LAST_BUY = tick()

				task.wait(0.2)
				HRP.CFrame = old
				break
			end
		end
	end
end)
