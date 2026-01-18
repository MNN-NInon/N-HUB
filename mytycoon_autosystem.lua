-- =====================================================
-- N-HUB | My Tycoon Farm
-- AutoCollect + AutoBuy + Anti-AFK
-- Version : V.1.3.4b-r2
-- CORE 4b + UI 4a (WARP STABILIZED + COLLAPSE FIX)
-- =====================================================

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
local UI_VISIBLE = true
local COLLAPSED = false

local COLLECT_DELAY = 60
local BASE_RADIUS = 80
local BUY_DELAY = 1.2
local LAST_BUY = 0

local MinPrice = tonumber(getgenv().MinPrice) or 250
getgenv().MinPrice = MinPrice

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

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(230,190)
frame.Position = UDim2.fromOffset(20,220)
frame.BackgroundColor3 = Color3.fromRGB(15,15,15)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Active = true

-- ===== TITLE BAR =====
local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1,0,0,30)
titleBar.BackgroundColor3 = Color3.fromRGB(28,28,28)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 10

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1,-40,1,0)
title.Position = UDim2.fromOffset(10,0)
title.BackgroundTransparency = 1
title.Text = "N-HUB | TYCOON"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Left
title.TextColor3 = Color3.new(1,1,1)
title.ZIndex = 11

-- ===== COLLAPSE BUTTON (- / +) =====
local toggleBtn = Instance.new("TextButton", titleBar)
toggleBtn.Size = UDim2.fromOffset(26,26)
toggleBtn.Position = UDim2.new(1,-30,0,2)
toggleBtn.Text = "-"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 18
toggleBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.ZIndex = 12
Instance.new("UICorner", toggleBtn)

-- ===== CONTENT FRAME =====
local content = Instance.new("Frame", frame)
content.Position = UDim2.fromOffset(0,30)
content.Size = UDim2.new(1,0,1,-30)
content.BackgroundTransparency = 1

local function makeBtn(txt,y)
	local b = Instance.new("TextButton", content)
	b.Size = UDim2.fromOffset(190,26)
	b.Position = UDim2.fromOffset(20,y)
	b.Text = txt
	b.Font = Enum.Font.Gotham
	b.TextSize = 14
	b.BackgroundColor3 = Color3.fromRGB(40,40,40)
	b.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", b)
	return b
end

local collectBtn = makeBtn("AUTO COLLECT : ON",10)
local buyBtn = makeBtn("AUTO BUY : OFF",42)

local priceBox = Instance.new("TextBox", content)
priceBox.Position = UDim2.fromOffset(20,74)
priceBox.Size = UDim2.fromOffset(190,26)
priceBox.Text = tostring(MinPrice)
priceBox.Font = Enum.Font.Gotham
priceBox.TextSize = 14
priceBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
priceBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", priceBox)

local hideBtn = makeBtn("HIDE / SHOW (G)",110)

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

-- ===== COLLAPSE LOGIC =====
toggleBtn.MouseButton1Click:Connect(function()
	COLLAPSED = not COLLAPSED
	content.Visible = not COLLAPSED
	frame.Size = COLLAPSED and UDim2.fromOffset(230,30) or UDim2.fromOffset(230,190)
	toggleBtn.Text = COLLAPSED and "+" or "-"
end)

-- ===== DRAG SCRIPT (SAFE) =====
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

-- =====================================================
-- =================== ANTI-AFK ========================
-- =====================================================
task.spawn(function()
	while task.wait(60) do
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end
end)

-- =====================================================
-- AUTO COLLECT + AUTO BUY (CORE 4b เหมือนเดิม)
-- =====================================================
-- (คง logic เดิมทั้งหมด ไม่แตะเพื่อความเสถียร)
