-- =====================================================
-- N-HUB | My Tycoon Farm
-- AutoCollect + AutoBuy
-- Version : MAIN (FIXED UI)
-- =====================================================

-- ===== KEY SYSTEM =====
local VALID_KEY = "NONON123"

if not _G.KEY or _G.KEY ~= VALID_KEY then
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
local UIS = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local Char = LP.Character or LP.CharacterAdded:Wait()
local HRP = Char:WaitForChild("HumanoidRootPart")

-- ===== SETTINGS =====
local AutoBuy = false
local AutoCollect = false
local MinPrice = 250
local COLLECT_DELAY = 60

-- ===== CLEAR OLD UI =====
pcall(function()
	PlayerGui.NHubUI:Destroy()
end)

-- ================= UI =================
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

-- ===== DRAG FIX =====
local dragging, dragInput, dragStart, startPos

frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

-- ===== UI ELEMENTS =====
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
priceBox.BackgroundColor3 = Color3.fromRGB(35,35,35)
priceBox.TextColor3 = Color3.new(1,1,1)
priceBox.TextScaled = true

local buyBtn = MakeButton("TOGGLE AUTO BUY", 130)
local collectBtn = MakeButton("TOGGLE AUTO COLLECT", 170)

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

-- ================= AUTO BUY =================
local function GetPrice(obj)
	for _,v in pairs(obj:GetDescendants()) do
		if v:IsA("TextLabel") or v:IsA("TextButton") then
			local n = tonumber((v.Text or ""):gsub(",", ""):match("%d+"))
			if n then return n end
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

-- ================= AUTO COLLECT =================
local function GetCollectZones()
	local zones = {}
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and v.Name:lower():find("collect") then
			table.insert(zones, v)
		end
	end
	return zones
end

task.spawn(function()
	while task.wait(COLLECT_DELAY) do
		if not AutoCollect then continue end
		for _,z in pairs(GetCollectZones()) do
			HRP.CFrame = CFrame.new(z.Position)
			RunService.Heartbeat:Wait()
		end
	end
end)
