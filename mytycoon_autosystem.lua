-- =====================================================
-- N-HUB | My Tycoon Farm (STABLE FIXED)
-- =====================================================

-- ===== KEY =====
local VALID_KEY = "NONON123"
if _G.KEY ~= VALID_KEY then return end

-- ===== SAFE START =====
repeat task.wait() until game:IsLoaded()
task.wait(1)

-- ===== SERVICES =====
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local Char = LP.Character or LP.CharacterAdded:Wait()
local HRP = Char:WaitForChild("HumanoidRootPart")

-- ===== STATE =====
local AutoBuy = false
local AutoCollect = false
local MinPrice = 250
local COLLECT_DELAY = 60

pcall(function() PlayerGui.NHubUI:Destroy() end)

-- =====================================================
-- UI ROOT
-- =====================================================
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "NHubUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false

-- Open Button
local openBtn = Instance.new("TextButton", gui)
openBtn.Size = UDim2.fromOffset(90,30)
openBtn.Position = UDim2.fromOffset(20,120)
openBtn.Text = "OPEN HUB"
openBtn.Visible = false
openBtn.BackgroundColor3 = Color3.fromRGB(20,20,20)
openBtn.TextColor3 = Color3.new(1,1,1)

-- Main Frame
local frame = Instance.new("Frame", gui)
frame.Position = UDim2.fromOffset(20,200)
frame.Size = UDim2.fromOffset(320,260)
frame.BackgroundColor3 = Color3.fromRGB(15,15,15)
frame.BorderSizePixel = 0

-- Top Bar
local top = Instance.new("Frame", frame)
top.Size = UDim2.new(1,0,0,30)
top.BackgroundColor3 = Color3.fromRGB(25,25,25)

local title = Instance.new("TextLabel", top)
title.Size = UDim2.new(1,-70,1,0)
title.Position = UDim2.fromOffset(10,0)
title.Text = "N-HUB | MY TYCOON FARM"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.TextXAlignment = Left

local minBtn = Instance.new("TextButton", top)
minBtn.Size = UDim2.fromOffset(25,25)
minBtn.Position = UDim2.new(1,-55,0,2)
minBtn.Text = "-"

local closeBtn = Instance.new("TextButton", top)
closeBtn.Size = UDim2.fromOffset(25,25)
closeBtn.Position = UDim2.new(1,-28,0,2)
closeBtn.Text = "X"

-- Content
local content = Instance.new("Frame", frame)
content.Position = UDim2.fromOffset(0,30)
content.Size = UDim2.new(1,0,1,-30)
content.BackgroundTransparency = 1

-- Resize Handle
local resize = Instance.new("Frame", frame)
resize.Size = UDim2.fromOffset(14,14)
resize.Position = UDim2.new(1,-14,1,-14)
resize.BackgroundColor3 = Color3.fromRGB(90,90,90)

-- =====================================================
-- DRAG (FIXED)
-- =====================================================
do
	local dragging, startPos, startFrame
	top.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			startPos = i.Position
			startFrame = frame.Position
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - startPos
			frame.Position = UDim2.fromOffset(
				startFrame.X.Offset + d.X,
				startFrame.Y.Offset + d.Y
			)
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
end

-- =====================================================
-- RESIZE (FIXED)
-- =====================================================
do
	local resizing, startSize, startPos
	resize.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = true
			startSize = frame.Size
			startPos = i.Position
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if resizing and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - startPos
			frame.Size = UDim2.fromOffset(
				math.clamp(startSize.X.Offset + d.X, 260, 520),
				math.clamp(startSize.Y.Offset + d.Y, 180, 520)
			)
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = false
		end
	end)
end

-- =====================================================
-- BUTTONS
-- =====================================================
local minimized = false
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	content.Visible = not minimized
	frame.Size = minimized
		and UDim2.fromOffset(frame.Size.X.Offset, 30)
		or UDim2.fromOffset(frame.Size.X.Offset, 260)
end)

closeBtn.MouseButton1Click:Connect(function()
	frame.Visible = false
	openBtn.Visible = true
end)

openBtn.MouseButton1Click:Connect(function()
	frame.Visible = true
	openBtn.Visible = false
end)

-- =====================================================
-- UI CONTENT
-- =====================================================
local function Label(text,y)
	local l = Instance.new("TextLabel", content)
	l.Size = UDim2.new(1,-20,0,25)
	l.Position = UDim2.fromOffset(10,y)
	l.Text = text
	l.TextColor3 = Color3.new(1,1,1)
	l.BackgroundTransparency = 1
	return l
end

local function Button(text,y)
	local b = Instance.new("TextButton", content)
	b.Size = UDim2.new(1,-40,0,30)
	b.Position = UDim2.fromOffset(20,y)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(35,35,35)
	b.TextColor3 = Color3.new(1,1,1)
	return b
end

local buyStatus = Label("AutoBuy : OFF",10)
local collectStatus = Label("AutoCollect : OFF",40)

local priceBox = Instance.new("TextBox", content)
priceBox.Size = UDim2.new(1,-40,0,30)
priceBox.Position = UDim2.fromOffset(20,70)
priceBox.Text = tostring(MinPrice)
priceBox.BackgroundColor3 = Color3.fromRGB(35,35,35)
priceBox.TextColor3 = Color3.new(1,1,1)

local buyBtn = Button("TOGGLE AUTO BUY",110)
local collectBtn = Button("TOGGLE AUTO COLLECT",150)

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
end
