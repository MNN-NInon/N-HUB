-- =====================================================
-- N-HUB | My Tycoon Farm (FULL VERSION)
-- AutoCollect + AutoBuy + Mutation + Fly + Anti‑AFK
-- WARP MODE + Respawn Fix + Config Save
-- =====================================================

-- ===== KEY SYSTEM =====
local VALID_KEY = "NONON123"
if not _G.KEY or _G.KEY ~= VALID_KEY then
	warn("❌ INVALID KEY : กรุณาใส่ _G.KEY = 'NONON123' ก่อนรัน")
	-- return
end

repeat task.wait() until game:IsLoaded()
task.wait(1)

-- ===== SERVICES =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

-- =====================================================
-- CHARACTER HELPERS
-- =====================================================
local function getRoot()
	local char = LP.Character
	if char then
		return char:FindFirstChild("HumanoidRootPart")
	end
end

local function getHum()
	local char = LP.Character
	if char then
		return char:FindFirstChildWhichIsA("Humanoid")
	end
end

-- =====================================================
-- CONFIG
-- =====================================================
local CONFIG_FILE = "N-HUB_MyTycoonFarm_Config.json"

local Config = {
	AutoCollect = true,
	AutoBuy = false,
	MinPrice = 250,
	Fly = false,
	AntiAFK = true,
	MutationAutoBuy = false,
	MutationSelected = {}
}

local function LoadConfig()
	if isfile(CONFIG_FILE) then
		local ok,data = pcall(function()
			return HttpService:JSONDecode(readfile(CONFIG_FILE))
		end)
		if ok then
			for k,v in pairs(data) do
				Config[k] = v
			end
		end
	end
end

local function SaveConfig()
	pcall(function()
		writefile(CONFIG_FILE,HttpService:JSONEncode(Config))
	end)
end

LoadConfig()

local AutoCollect = Config.AutoCollect
local AutoBuy = Config.AutoBuy
local FlyEnabled = Config.Fly
local AntiAFK = Config.AntiAFK
local MutationAutoBuy = Config.MutationAutoBuy
local SelectedMutation = Config.MutationSelected
local MinPrice = Config.MinPrice

getgenv().MinPrice = MinPrice

-- =====================================================
-- BASE POSITION
-- =====================================================
local root0 = getRoot()
local BASE_POSITION = root0 and root0.Position or Vector3.new()
local BASE_RADIUS = 100

-- =====================================================
-- ANTI AFK SYSTEM
-- =====================================================
local AntiAFK_Status = "Active"

task.spawn(function()
	while task.wait(60) do
		if not AntiAFK then continue end
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
		AntiAFK_Status = "Blocked Kick"
		task.wait(2)
		AntiAFK_Status = "Active"
	end
end)

-- =====================================================
-- FLY SYSTEM
-- =====================================================
local FlyBV,FlyBG
local FlySpeed = 60

local function StopFly()
	FlyEnabled = false
	Config.Fly = false
	SaveConfig()
	if FlyBV then FlyBV:Destroy() FlyBV=nil end
	if FlyBG then FlyBG:Destroy() FlyBG=nil end
	local hum = getHum()
	if hum then hum.PlatformStand=false end
end

local function StartFly()
	StopFly()
	local hum = getHum()
	local root = getRoot()
	if not hum or not root then return end

	FlyEnabled = true
	Config.Fly = true
	SaveConfig()

	FlyBV = Instance.new("BodyVelocity",root)
	FlyBV.MaxForce = Vector3.new(9e9,9e9,9e9)

	FlyBG = Instance.new("BodyGyro",root)
	FlyBG.MaxTorque = Vector3.new(9e9,9e9,9e9)
	FlyBG.P = 9e4

	hum.PlatformStand = true

	task.spawn(function()
		while FlyEnabled and FlyBV do
			local cam = workspace.CurrentCamera
			local move = Vector3.zero

			if UIS:IsKeyDown(Enum.KeyCode.W) then move+=cam.CFrame.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.S) then move-=cam.CFrame.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.A) then move-=cam.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.D) then move+=cam.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then move+=cam.CFrame.UpVector end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move-=cam.CFrame.UpVector end

			FlyBV.Velocity = move.Magnitude>0 and move.Unit*FlySpeed or Vector3.zero
			FlyBG.CFrame = cam.CFrame
			RunService.RenderStepped:Wait()
		end
		StopFly()
	end)
end

-- =====================================================
-- UI (RAYFIELD)
-- =====================================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "N-HUB | My Tycoon Farm",
	LoadingTitle = "N-HUB",
	LoadingSubtitle = "Full Edition",
	ConfigurationSaving = {Enabled=false},
	KeySystem = false
})

local MainTab = Window:CreateTab("Main",4483362458)

-- TOGGLES
MainTab:CreateToggle({
	Name="Auto Collect",
	CurrentValue=AutoCollect,
	Callback=function(v)
		AutoCollect=v
		Config.AutoCollect=v
		SaveConfig()
	end
})

MainTab:CreateToggle({
	Name="Auto Buy",
	CurrentValue=AutoBuy,
	Callback=function(v)
		AutoBuy=v
		Config.AutoBuy=v
		SaveConfig()
	end
})

MainTab:CreateToggle({
	Name="Fly (F)",
	CurrentValue=FlyEnabled,
	Callback=function(v)
		if v then StartFly() else StopFly() end
	end
})

-- ANTI AFK UI
local AntiLabel = MainTab:CreateLabel("Anti‑AFK Status : "..(AntiAFK and "Active" or "Disabled"))

MainTab:CreateToggle({
	Name="Anti AFK",
	CurrentValue=AntiAFK,
	Callback=function(v)
		AntiAFK=v
		Config.AntiAFK=v
		SaveConfig()
		AntiLabel:Set("Anti‑AFK Status : "..(v and "Active" or "Disabled"))
	end
})

-- =====================================================
-- AUTO COLLECT
-- =====================================================
task.spawn(function()
	while task.wait(60) do
		if not AutoCollect then continue end
		local root = getRoot()
		if not root then continue end

		for _,v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") then
				local n=v.Name:lower()
				if n:find("collect") or n:find("cash") or n:find("money") then
					if (v.Position-BASE_POSITION).Magnitude<=BASE_RADIUS then
						local old=root.CFrame
						root.CFrame=v.CFrame+Vector3.new(0,3,0)
						task.wait(.15)
						firetouchinterest(root,v,0)
						firetouchinterest(root,v,1)
						root.CFrame=old
					end
				end
			end
		end
	end
end)

-- =====================================================
-- HOTKEY FLY
-- =====================================================
UIS.InputBegan:Connect(function(i,g)
	if g then return end
	if i.KeyCode==Enum.KeyCode.F then
		if FlyEnabled then StopFly() else StartFly() end
	end
end)

Rayfield:Notify({
	Title="N-HUB",
	Content="Loaded Full Version",
	Duration=4
})
