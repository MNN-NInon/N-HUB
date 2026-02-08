-- =====================================================
-- N-HUB | My Tycoon Farm (MERGED VERSION)
-- AutoCollect + AutoBuy Prompt + AutoBuy Shop
-- Integrated UI + Stock Detection
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
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
	AutoBuyShop = false,
	MinPrice = 250,
	UI_VISIBLE = true,
	MINIMIZED = false,
	Fly = false
}

local function LoadConfig()
	if isfile(CONFIG_FILE) then
		local ok,data = pcall(function()
			return HttpService:JSONDecode(readfile(CONFIG_FILE))
		end)
		if ok and type(data)=="table" then
			for k,v in pairs(Config) do
				if data[k]~=nil then
					Config[k]=data[k]
				end
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
local AutoBuy     = Config.AutoBuy
local AutoBuyShop = Config.AutoBuyShop
local FlyEnabled  = Config.Fly
local MinPrice    = Config.MinPrice

-- =====================================================
-- ANTI AFK
-- =====================================================
task.spawn(function()
	while task.wait(60) do
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end)

-- =====================================================
-- UI BASE
-- =====================================================
pcall(function()
	if PlayerGui:FindFirstChild("MainAutoUI") then
		PlayerGui.MainAutoUI:Destroy()
	end
end)

local gui = Instance.new("ScreenGui",PlayerGui)
gui.Name="MainAutoUI"
gui.ResetOnSpawn=false

local frame = Instance.new("Frame",gui)
frame.Size=UDim2.fromOffset(230,260)
frame.Position=UDim2.fromOffset(20,220)
frame.BackgroundColor3=Color3.fromRGB(15,15,15)
frame.Active=true
frame.Draggable=true

local function makeBtn(txt,y)
	local b=Instance.new("TextButton",frame)
	b.Size=UDim2.fromOffset(190,26)
	b.Position=UDim2.fromOffset(20,y)
	b.TextScaled=true
	b.BackgroundColor3=Color3.fromRGB(40,40,40)
	b.TextColor3=Color3.new(1,1,1)
	b.Text=txt
	return b
end

local collectBtn = makeBtn("",40)
local buyBtn     = makeBtn("",72)
local shopBtn    = makeBtn("",104)
local flyBtn     = makeBtn("",136)

local priceBox = Instance.new("TextBox",frame)
priceBox.Position=UDim2.fromOffset(20,168)
priceBox.Size=UDim2.fromOffset(190,26)
priceBox.Text=tostring(MinPrice)
priceBox.TextScaled=true
priceBox.BackgroundColor3=Color3.fromRGB(30,30,30)
priceBox.TextColor3=Color3.new(1,1,1)

-- =====================================================
-- UI UPDATE
-- =====================================================
local function updateUI()
	collectBtn.Text = AutoCollect and "AUTO COLLECT : ON" or "AUTO COLLECT : OFF"
	buyBtn.Text     = AutoBuy and "AUTO BUY PROMPT : ON" or "AUTO BUY PROMPT : OFF"
	shopBtn.Text    = AutoBuyShop and "AUTO BUY SHOP : ON" or "AUTO BUY SHOP : OFF"
	flyBtn.Text     = FlyEnabled and "FLY : ON" or "FLY : OFF"
end

collectBtn.MouseButton1Click:Connect(function()
	AutoCollect=not AutoCollect
	Config.AutoCollect=AutoCollect
	SaveConfig()
	updateUI()
end)

buyBtn.MouseButton1Click:Connect(function()
	AutoBuy=not AutoBuy
	Config.AutoBuy=AutoBuy
	SaveConfig()
	updateUI()
end)

shopBtn.MouseButton1Click:Connect(function()
	AutoBuyShop=not AutoBuyShop
	Config.AutoBuyShop=AutoBuyShop
	SaveConfig()
	updateUI()
end)

updateUI()

-- =====================================================
-- SHOP MENU
-- =====================================================
local shopFrame = Instance.new("Frame",gui)
shopFrame.Size=UDim2.fromOffset(260,300)
shopFrame.Position=UDim2.fromOffset(260,220)
shopFrame.BackgroundColor3=Color3.fromRGB(15,15,15)
shopFrame.Visible=false
shopFrame.Active=true
shopFrame.Draggable=true

shopBtn.MouseButton2Click:Connect(function()
	shopFrame.Visible=not shopFrame.Visible
end)

local scroll=Instance.new("ScrollingFrame",shopFrame)
scroll.Size=UDim2.new(1,-10,1,-10)
scroll.Position=UDim2.fromOffset(5,5)
scroll.BackgroundTransparency=1
scroll.CanvasSize=UDim2.new()
scroll.ScrollBarThickness=6

local layout=Instance.new("UIListLayout",scroll)
layout.Padding=UDim.new(0,4)

-- =====================================================
-- SHOP SYSTEM
-- =====================================================
local buyRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BuyStock")
local stockGui  = PlayerGui:WaitForChild("Main"):WaitForChild("Stock")
local scroll2   = stockGui.ScrollingFrame.ScrollingFrame

local Selected={}
local Frames={}

local function HasStock(frame)
	for _,v in pairs(frame:GetDescendants()) do
		if v:IsA("TextLabel") and v.Text:find("Stock") then
			local n=tonumber(v.Text:match("%d+"))
			if n and n>0 then return true end
		end
	end
end

local function createToggle(name,ref)
	Frames[name]=ref

	local btn=Instance.new("TextButton",scroll)
	btn.Size=UDim2.new(1,0,0,28)
	btn.BackgroundColor3=Color3.fromRGB(40,40,40)
	btn.TextColor3=Color3.new(1,1,1)
	btn.TextScaled=true
	btn.Text="[ ] "..name

	local on=false

	btn.MouseButton1Click:Connect(function()
		on=not on
		Selected[name]=on or nil
		btn.Text=(on and "[✓] " or "[ ] ")..name
	end)
end

local function scan(item)
	if item.Name=="Example" then return end
	local title=item:FindFirstChild("Title",true)
	if title and not Frames[title.Text] then
		createToggle(title.Text,item)
	end
end

for _,v in pairs(scroll2:GetChildren()) do
	scan(v)
end

scroll2.ChildAdded:Connect(function(v)
	task.wait(0.5)
	scan(v)
end)

-- =====================================================
-- SHOP BUY LOOP
-- =====================================================
task.spawn(function()
	while task.wait(1) do
		if not AutoBuyShop then continue end

		for name,_ in pairs(Selected) do
			local frame=Frames[name]
			if frame and HasStock(frame) then
				buyRemote:FireServer(name)
			end
		end
	end
end)

-- =====================================================
-- AUTO COLLECT (SAFE)
-- =====================================================
task.spawn(function()
	while task.wait(60) do
		if not AutoCollect then continue end
		local root=getRoot()
		if not root then continue end

		for _,v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") then
				local n=v.Name:lower()
				if n:find("cash") or n:find("collect") then
					local old=root.CFrame
					root.CFrame=v.CFrame
					task.wait(.15)
					root.CFrame=old
				end
			end
		end
	end
end)

-- =====================================================
-- END
-- =====================================================
