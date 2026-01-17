-- =====================================================
-- N-HUB | My Tycoon Farm
-- AutoCollect + AutoBuy
-- Version : V.1.3.3 (STABLE / PERSIST CONFIG)
-- =====================================================

-- ================= KEY SYSTEM =================
local VALID_KEY = "NONON123"
if not _G.KEY or _G.KEY ~= VALID_KEY then
	warn("❌ INVALID KEY")
	return
end

-- ================= SAFE LOAD =================
repeat task.wait() until game:IsLoaded()
task.wait(1)

-- ================= SERVICES =================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local Char = LP.Character or LP.CharacterAdded:Wait()
local HRP = Char:WaitForChild("HumanoidRootPart")

-- ================= CONFIG SAVE =================
local CONFIG_FILE = "NHub_MyTycoon_Config.json"

local Config = {
	CollectDelay = 60,
	MinPrice = 250
}

if isfile(CONFIG_FILE) then
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(CONFIG_FILE))
	end)
	if ok and type(data) == "table" then
		for k,v in pairs(data) do
			Config[k] = v
		end
	end
else
	writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
end

local function SaveConfig()
	writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
end

-- ================= VARIABLES =================
local AutoCollect = true
local AutoBuy = false
local COLLECT_DELAY = Config.CollectDelay
local MinPrice = Config.MinPrice

-- ================= CLEAR UI =================
pcall(function()
	PlayerGui.MainAutoUI:Destroy()
end)

-- ================= UI =================
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "MainAutoUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(260, 220)
frame.Position = UDim2.fromOffset(20, 200)
frame.BackgroundColor3 = Color3.fromRGB(15,15,15)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.BackgroundTransparency = 1
title.Text = "N-HUB | TYCOON FARM"
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)

-- ===== STATUS =====
local collectStatus = Instance.new("TextLabel", frame)
collectStatus.Position = UDim2.fromOffset(10,35)
collectStatus.Size = UDim2.fromOffset(240,20)
collectStatus.BackgroundTransparency = 1
collectStatus.TextScaled = true

local buyStatus = Instance.new("TextLabel", frame)
buyStatus.Position = UDim2.fromOffset(10,55)
buyStatus.Size = UDim2.fromOffset(240,20)
buyStatus.BackgroundTransparency = 1
buyStatus.TextScaled = true

-- ===== BUTTONS =====
local collectBtn = Instance.new("TextButton", frame)
collectBtn.Position = UDim2.fromOffset(20,80)
collectBtn.Size = UDim2.fromOffset(220,26)
collectBtn.Text = "TOGGLE AUTO COLLECT"
collectBtn.TextScaled = true
collectBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
collectBtn.TextColor3 = Color3.new(1,1,1)

local delayBox = Instance.new("TextBox", frame)
delayBox.Position = UDim2.fromOffset(20,112)
delayBox.Size = UDim2.fromOffset(220,26)
delayBox.Text = tostring(COLLECT_DELAY)
delayBox.PlaceholderText = "Collect Delay (sec)"
delayBox.TextScaled = true
delayBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
delayBox.TextColor3 = Color3.new(1,1,1)

local priceBox = Instance.new("TextBox", frame)
priceBox.Position = UDim2.fromOffset(20,144)
priceBox.Size = UDim2.fromOffset(220,26)
priceBox.Text = tostring(MinPrice)
priceBox.PlaceholderText = "Min Buy Price"
priceBox.TextScaled = true
priceBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
priceBox.TextColor3 = Color3.new(1,1,1)

local buyBtn = Instance.new("TextButton", frame)
buyBtn.Position = UDim2.fromOffset(20,176)
buyBtn.Size = UDim2.fromOffset(220,26)
buyBtn.Text = "TOGGLE AUTO BUY"
buyBtn.TextScaled = true
buyBtn.BackgroundColor3 = Color3.fromRGB(80,0,0)
buyBtn.TextColor3 = Color3.new(1,1,1)

-- ================= UI UPDATE =================
local function updateUI()
	collectStatus.Text = AutoCollect and "AUTO COLLECT : ON" or "AUTO COLLECT : OFF"
	collectStatus.TextColor3 = AutoCollect and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)

	buyStatus.Text = AutoBuy and "AUTO BUY : ON" or "AUTO BUY : OFF"
	buyStatus.TextColor3 = AutoBuy and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
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

delayBox.FocusLost:Connect(function()
	local n = tonumber(delayBox.Text)
	if n and n >= 5 then
		COLLECT_DELAY = n
		Config.CollectDelay = n
		SaveConfig()
	end
	delayBox.Text = tostring(COLLECT_DELAY)
end)

priceBox.FocusLost:Connect(function()
	local n = tonumber(priceBox.Text)
	if n then
		MinPrice = n
		Config.MinPrice = n
		SaveConfig()
	end
	priceBox.Text = tostring(MinPrice)
end)

-- ================= HOTKEY G =================
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.G then
		gui.Enabled = not gui.Enabled
	end
end)

-- ================= AUTO COLLECT =================
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

task.spawn(function()
	while true do
		task.wait(COLLECT_DELAY)
		if not AutoCollect then continue end
		local oldCF = HRP.CFrame
		for _,zone in pairs(GetCollectZones()) do
			if (HRP.Position - zone.Position).Magnitude <= 120 then
				HRP.CFrame = zone.CFrame + Vector3.new(0,2,0)
				RunService.Heartbeat:Wait()
			end
		end
		HRP.CFrame = oldCF
	end
end)

-- ================= AUTO BUY (WARP) =================
task.spawn(function()
	while task.wait(0.4) do
		if not AutoBuy then continue end
		for _,p in pairs(workspace:GetDescendants()) do
			if p:IsA("ProximityPrompt")
			and (p.ActionText == "Buy!" or p.ActionText == "Purchase") then
				local part = p.Parent:IsA("BasePart") and p.Parent or p.Parent:FindFirstChildWhichIsA("BasePart")
				if part then
					local old = HRP.CFrame
					HRP.CFrame = part.CFrame + Vector3.new(0,2,0)
					task.wait(0.15)
					pcall(function()
						fireproximityprompt(p)
					end)
					task.wait(0.1)
					HRP.CFrame = old
				end
			end
		end
	end
end)

print("✅ N-HUB V.1.3.3 LOADED")
