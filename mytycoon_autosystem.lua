--// ===============================
--// N-HUB | MY TYCOON FARM
--// V.1.3.4b-r2 (Classic UI + Collapse)
--// ===============================

-- SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- FLAGS
local AUTO_BUY = false
local AUTO_COLLECT = false
local COLLAPSED = false

--// ===============================
--// UI SETUP
--// ===============================
local gui = Instance.new("ScreenGui")
gui.Name = "N_HUB_GUI"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(230,190)
frame.Position = UDim2.new(0,40,0,120)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

-- CORNER
local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0,10)

--// ===============================
--// TITLE BAR
--// ===============================
local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1,0,0,28)
titleBar.BackgroundTransparency = 1

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1,-30,1,0)
title.Position = UDim2.new(0,8,0,0)
title.BackgroundTransparency = 1
title.Text = "N-HUB | TYCOON"
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Left

local toggleBtn = Instance.new("TextButton", titleBar)
toggleBtn.Size = UDim2.fromOffset(22,22)
toggleBtn.Position = UDim2.new(1,-26,0,3)
toggleBtn.Text = "-"
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
toggleBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", toggleBtn)

--// ===============================
--// CONTENT FRAME
--// ===============================
local content = Instance.new("Frame", frame)
content.Position = UDim2.new(0,0,0,30)
content.Size = UDim2.new(1,0,1,-30)
content.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", content)
layout.Padding = UDim.new(0,8)

--// ===============================
--// BUTTON MAKER
--// ===============================
local function createButton(text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1,-20,0,32)
	btn.Position = UDim2.new(0,10,0,0)
	btn.Text = text
	btn.TextScaled = true
	btn.Font = Enum.Font.Gotham
	btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
	btn.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", btn)
	btn.Parent = content
	return btn
end

-- BUTTONS
local autoBuyBtn = createButton("AUTO BUY : OFF")
local autoCollectBtn = createButton("AUTO COLLECT : OFF")
local warpBtn = createButton("WARP FAST")

--// ===============================
--// COLLAPSE LOGIC
--// ===============================
local function setCollapsed(state)
	COLLAPSED = state
	toggleBtn.Text = state and "+" or "-"

	content.Visible = not state

	frame.Size = state
		and UDim2.fromOffset(230,36)
		or UDim2.fromOffset(230,190)
end

toggleBtn.MouseButton1Click:Connect(function()
	setCollapsed(not COLLAPSED)
end)

--// ===============================
--// CORE LOGIC (SAFE – ไม่แตะระบบเดิม)
--// ===============================
autoBuyBtn.MouseButton1Click:Connect(function()
	AUTO_BUY = not AUTO_BUY
	autoBuyBtn.Text = "AUTO BUY : " .. (AUTO_BUY and "ON" or "OFF")
end)

autoCollectBtn.MouseButton1Click:Connect(function()
	AUTO_COLLECT = not AUTO_COLLECT
	autoCollectBtn.Text = "AUTO COLLECT : " .. (AUTO_COLLECT and "ON" or "OFF")
end)

warpBtn.MouseButton1Click:Connect(function()
	-- วางโค้ด WARP FAST ของ V.1.3.4b-r1 ตรงนี้
	-- (ไม่โดน UI แน่นอน)
end)

--// ===============================
--// END
--// ===============================
