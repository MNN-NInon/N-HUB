-- =====================================================
-- N-HUB | My Tycoon Farm
-- AutoCollect + AutoBuy
-- Version : V.1.2
-- Status  : MAIN (STABLE)
-- UI      : DARK + TRANSPARENT
-- =====================================================

local SCRIPT_VERSION = "V.1.2"

-- ===== SAVE CONFIG =====
getgenv().N_HUB_CONFIG = getgenv().N_HUB_CONFIG or {
	MinPrice = 250
}

-- ===== KEY SYSTEM =====
local VALID_KEY = "NONON123"
if not _G.KEY then return warn("❌ NO KEY") end
if _G.KEY ~= VALID_KEY then return warn("❌ INVALID KEY") end

repeat task.wait() until game:IsLoaded()

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
local UI_MINIMIZED = false

local COLLECT_DELAY = 60
local MinPrice = getgenv().N_HUB_CONFIG.MinPrice

-- ===== CLEAR UI =====
pcall(function()
	PlayerGui.MainAutoUI:Destroy()
end)

-- ===== UI =====
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "MainAutoUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(260, 200)
frame.Position = UDim2.fromOffset(20, 180)
frame.BackgroundColor3 = Color3.fromRGB(10,10,10)
frame.BackgroundTransparency = 0.25
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

-- ===== TITLE BAR =====
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,28)
title.BackgroundTransparency = 1
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(220,220,220)
title.Text = "N-HUB | TYCOON | "..SCRIPT_VERSION

local miniBtn = Instance.new("TextButton", frame)
miniBtn.Size = UDim2.fromOffset(28,18)
miniBtn.Position = UDim2.fromOffset(200,5)
miniBtn.Text = "-"
miniBtn.TextScaled = true
miniBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
miniBtn.TextColor3 = Color3.new(1,1,1)

local hideBtn = Instance.new("TextButton", frame)
hideBtn.Size = UDim2.fromOffset(28,18)
hideBtn.Position = UDim2.fromOffset(232,5)
hideBtn.Text = "X"
hideBtn.TextScaled = true
hideBtn.BackgroundColor3 = Color3.fromRGB(80,20,20)
hideBtn.TextColor3 = Color3.new(1,1,1)

-- ===== CONTENT =====
local content = Instance.new("Frame", frame)
content.Position = UDim2.fromOffset(0,28)
content.Size = UDim2.fromOffset(260,172)
content.BackgroundTransparency = 1

local function label(y)
	local l = Instance.new("TextLabel", content)
	l.Position = UDim2.fromOffset(10,y)
	l.Size = UDim2.fromOffset(240,18)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	return l
end

local function button(y,color)
	local b = Instance.new("TextButton", content)
	b.Position = UDim2.fromOffset(15,y)
	b.Size = UDim2.fromOffset(230,22)
	b.TextScaled = true
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.new(1,1,1)
	return b
end

local collectStatus = label(8)
local collectBtn = button(28, Color3.fromRGB(60,60,60))

local buyStatus = label(58)
local priceBox = Instance.new("TextBox", content)
priceBox.Position = UDim2.fromOffset(15,78)
priceBox.Size = UDim2.fromOffset(230,22)
priceBox.TextScaled = true
priceBox.BackgroundColor3 = Color3.fromRGB(35,35,35)
priceBox.TextColor3 = Color3.new(1,1,1)
priceBox.Text = tostring(MinPrice)

local buyBtn = button(108, Color3.fromRGB(90,20,20))

collectBtn.Text = "AUTO COLLECT"
buyBtn.Text = "AUTO BUY"

-- ===== UI UPDATE =====
local function updateUI()
	collectStatus.Text = AutoCollect and "AUTO COLLECT : ON" or "AUTO COLLECT : OFF"
	collectStatus.TextColor3 = AutoCollect and Color3.fromRGB(0,255,120) or Color3.fromRGB(255,80,80)

	buyStatus.Text = AutoBuy and "AUTO BUY : ON" or "AUTO BUY : OFF"
	buyStatus.TextColor3 = AutoBuy and Color3.fromRGB(0,255,120) or Color3.fromRGB(255,80,80)
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
		getgenv().N_HUB_CONFIG.MinPrice = n
	end
	priceBox.Text = tostring(MinPrice)
end)

-- ===== MINIMIZE =====
miniBtn.MouseButton1Click:Connect(function()
	UI_MINIMIZED = not UI_MINIMIZED
	content.Visible = not UI_MINIMIZED
	frame.Size = UI_MINIMIZED and UDim2.fromOffset(260,28) or UDim2.fromOffset(260,200)
	miniBtn.Text = UI_MINIMIZED and "+" or "-"
end)

-- ===== HIDE =====
hideBtn.MouseButton1Click:Connect(function()
	gui.Enabled = false
	UI_VISIBLE = false
end)

UIS.InputBegan:Connect(function(i,gp)
	if gp then return end
	if i.KeyCode == Enum.KeyCode.G then
		UI_VISIBLE = not UI_VISIBLE
		gui.Enabled = UI_VISIBLE
	end
end)
