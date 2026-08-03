-- =============================================================
--  N-HUB | UNIVERSAL V3
--  UI : Kavo UI  |  Auto Save Config
-- =============================================================

pcall(function()
    for _, v in pairs(game:GetService("CoreGui"):GetChildren()) do
        if v.Name == "KavoContainer" then v:Destroy() end
    end
end)

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"
))()
local Window = Library.CreateLib("The Walking Dead Online 3 | N-HUB", "Midnight")

-- =============================================================
--  SERVICES
-- =============================================================
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UIS             = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- =============================================================
--  CONFIG SYSTEM
-- =============================================================
local CONFIG_FILE = "nhub_config.json"

local defaultConfig = {
    jumpPower         = 50,
    infJump           = false,
    ctrlClickTP       = false,
    aimbotEnabled     = false,
    showFOV           = false,
    aimbotFOV         = 120,
    aimbotSmoothness  = 5,
    aimbotPart        = "Head",
    hitboxEnabled     = false,
    hitboxSize        = 10,
    espEnabled        = false,
    maxESPDistance    = 5000,
    tpOffsetDistance  = 5,
    -- Map coords (layer 1 = user saved, layer 2 = scanned) เก็บเป็น {x,y,z}
    userSavedCoords   = {},
    scannedCoords     = {},
}

local config = {}

local function LoadConfig()
    if not (isfile and writefile and readfile) then
        for k, v in pairs(defaultConfig) do config[k] = v end
        return
    end
    if isfile(CONFIG_FILE) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end)
        if ok and type(data) == "table" then
            config = data
            for k, v in pairs(defaultConfig) do
                if config[k] == nil then config[k] = v end
            end
        else
            for k, v in pairs(defaultConfig) do config[k] = v end
        end
    else
        for k, v in pairs(defaultConfig) do config[k] = v end
    end
end

local function SaveConfig()
    if not writefile then return end
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(config))
    end)
end

LoadConfig()

-- =============================================================
--  COMBAT VARIABLES
-- =============================================================
local aimbotEnabled    = config.aimbotEnabled
local aimbotFOV        = config.aimbotFOV
local aimbotPart       = config.aimbotPart
local aimbotSmoothness = config.aimbotSmoothness / 10
local showFOV          = config.showFOV
local lockedTarget     = nil

local hitboxEnabled = config.hitboxEnabled
local hitboxSize    = config.hitboxSize

-- =============================================================
--  TP PLAYER VARIABLES
-- =============================================================
local selectedPlayerName = nil
local foundPlayersData   = {}
local playerDropdown     = nil
local tpOffsetDistance   = config.tpOffsetDistance

-- =============================================================
--  MAP TELEPORT VARIABLES
-- =============================================================
-- layer 1: user saved (ถาวร, save ลง config)
-- layer 2: scanned   (save ลง config เช่นกัน แต่ scan ใหม่ได้)
local userSavedCoords = {}
local scannedCoords   = {}

-- ชื่อที่ user พิมพ์ใน TextBox
local customLocationName = ""

-- โหลดจาก config → แปลง {x,y,z} กลับเป็น Vector3
for k, t in pairs(config.userSavedCoords or {}) do
    if type(t) == "table" and t.x then
        userSavedCoords[k] = Vector3.new(t.x, t.y, t.z)
    end
end
for k, t in pairs(config.scannedCoords or {}) do
    if type(t) == "table" and t.x then
        scannedCoords[k] = Vector3.new(t.x, t.y, t.z)
    end
end

-- dropdown references (สร้างหลัง UI)
local savedLocDropdown   = nil
local scannedLocDropdown = nil
local selectedSavedLoc   = nil
local selectedScannedLoc = nil

local function Vec3ToTable(v) return { x = v.X, y = v.Y, z = v.Z } end

local function RefreshSavedDropdown()
    if not savedLocDropdown then return end
    local list = {}
    for k in pairs(userSavedCoords) do table.insert(list, k) end
    table.sort(list)
    if #list == 0 then list = { "ยังไม่มีตำแหน่งที่บันทึก" } end
    pcall(function() savedLocDropdown:Refresh(list) end)
end

local function RefreshScannedDropdown()
    if not scannedLocDropdown then return end
    local list = {}
    for k in pairs(scannedCoords) do table.insert(list, k) end
    table.sort(list)
    if #list == 0 then list = { "กด Auto Scan ก่อน" } end
    pcall(function() scannedLocDropdown:Refresh(list) end)
end

-- =============================================================
--  TP LOOT VARIABLES
-- =============================================================
local selectedBoxName = nil
local foundBoxesData  = {}
local boxDropdown     = nil

-- =============================================================
--  ESP VARIABLES
-- =============================================================
local ESPEnabled     = config.espEnabled
local ESPObjects     = {}
local maxESPDistance = config.maxESPDistance

local TEAM_COLOR  = Color3.fromRGB(0, 170, 255)
local ENEMY_COLOR = Color3.fromRGB(255, 60, 60)

-- =============================================================
--  FOV CIRCLE
-- =============================================================
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness    = 1.5
fovCircle.Color        = Color3.fromRGB(255, 0, 80)
fovCircle.Filled       = false
fovCircle.Visible      = false
fovCircle.Transparency = 1

-- =============================================================
--  ESP LOGIC
-- =============================================================
local function IsEnemy(player)
    if not player or player == LocalPlayer then return false end
    if LocalPlayer.Team and player.Team then
        return player.Team ~= LocalPlayer.Team
    end
    if LocalPlayer.TeamColor and player.TeamColor then
        local neutral = BrickColor.new("Medium stone grey")
        if LocalPlayer.TeamColor == neutral then return true end
        return player.TeamColor ~= LocalPlayer.TeamColor
    end
    return true
end

local function CreateESP(player)
    if ESPObjects[player] and ESPObjects[player].cleanup then
        pcall(function() ESPObjects[player].cleanup() end)
    end
    ESPObjects[player] = nil

    local function SetupCharacter(char)
        if ESPObjects[player] and ESPObjects[player].cleanup then
            pcall(function() ESPObjects[player].cleanup() end)
        end
        ESPObjects[player] = { cleanup = function() end }

        task.spawn(function()
            local hum  = char:WaitForChild("Humanoid", 10)
            local root = char:WaitForChild("HumanoidRootPart", 10)
            if not hum or not root then ESPObjects[player] = nil; return end
            if not player or not player.Parent then return end

            local highlight = Instance.new("Highlight")
            highlight.Adornee             = char
            highlight.FillColor           = ENEMY_COLOR
            highlight.OutlineColor        = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency    = 0.3
            highlight.OutlineTransparency = 0
            highlight.Enabled             = false
            highlight.Parent              = char

            local label   = Drawing.new("Text")
            label.Size    = 13
            label.Center  = true
            label.Outline = true
            label.Visible = false

            local conn
            conn = RunService.RenderStepped:Connect(function()
                if not char or not char.Parent then
                    highlight.Enabled = false; label.Visible = false; return
                end
                local alive = hum and hum.Health > 0
                if not ESPEnabled or not alive then
                    highlight.Enabled = false; label.Visible = false; return
                end
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if not myRoot then
                    highlight.Enabled = false; label.Visible = false; return
                end
                local dist = math.floor((myRoot.Position - root.Position).Magnitude)
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen and dist <= maxESPDistance then
                    local color = IsEnemy(player) and ENEMY_COLOR or TEAM_COLOR
                    highlight.FillColor = color
                    highlight.Enabled   = true
                    local head    = char:FindFirstChild("Head")
                    local textPos = head
                        and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
                        or  screenPos
                    label.Text     = player.Name .. " [" .. dist .. "m]"
                    label.Position = Vector2.new(textPos.X, textPos.Y - 15)
                    label.Color    = color
                    label.Visible  = true
                else
                    highlight.Enabled = false; label.Visible = false
                end
            end)

            local function cleanup()
                pcall(function() conn:Disconnect() end)
                pcall(function() highlight:Destroy() end)
                pcall(function() label:Remove() end)
            end

            if ESPObjects[player] then
                ESPObjects[player] = {
                    highlight = highlight, name = label,
                    connection = conn, cleanup = cleanup,
                }
            else
                cleanup()
            end
        end)
    end

    player.CharacterAdded:Connect(SetupCharacter)
    if player.Character then SetupCharacter(player.Character) end
end

Players.PlayerAdded:Connect(function(plr)
    if plr ~= LocalPlayer then CreateESP(plr) end
end)
Players.PlayerRemoving:Connect(function(plr)
    if ESPObjects[plr] and ESPObjects[plr].cleanup then
        pcall(function() ESPObjects[plr].cleanup() end)
        ESPObjects[plr] = nil
    end
end)
for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then CreateESP(plr) end
end

-- =============================================================
--  TABS & SECTIONS
-- =============================================================
local PlayerTab    = Window:NewTab("Player")
local PlayerSec    = PlayerTab:NewSection("การเคลื่อนที่")

local AimbotTab    = Window:NewTab("Aimbot")
local AimbotSec    = AimbotTab:NewSection("เล็งอัตโนมัติ")
local HitboxSec    = AimbotTab:NewSection("ขยาย Hitbox")

local ESPTab       = Window:NewTab("ESP")
local ESPSec       = ESPTab:NewSection("แสดงผู้เล่น")

local TPPlrTab     = Window:NewTab("TP Player")
local TPPlrSec     = TPPlrTab:NewSection("วาร์ปหาผู้เล่น")

local TPMapTab     = Window:NewTab("TP Map")
local TPMapSavedSec   = TPMapTab:NewSection("📌 ตำแหน่งที่บันทึกเอง")
local TPMapScannedSec = TPMapTab:NewSection("🔍 ตำแหน่งจาก Auto Scan")

local TPLootTab    = Window:NewTab("TP Loot")
local TPLootSec    = TPLootTab:NewSection("สแกนของในแมพ")

local UtilTab      = Window:NewTab("Utility")
local UtilSec      = UtilTab:NewSection("เครื่องมือทั่วไป")
local ConfigSec    = UtilTab:NewSection("จัดการ Config")

-- =============================================================
--  JUMP FEATURES
-- =============================================================
local jumpPower      = config.jumpPower
local infJumpEnabled = config.infJump
local _infJumpConn   = nil

local function applyJumpPower(hum, val)
    if not hum then return end
    pcall(function()
        if hum:IsA("Humanoid") then
            pcall(function() hum.UseJumpPower = true end)
            hum.JumpPower = val
        end
    end)
end

local function applyJumpNow()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then applyJumpPower(hum, jumpPower) end
end

function SetJumpPower(v)
    if type(v) ~= "number" then return end
    jumpPower = v; applyJumpNow()
end

local function connectInfJump()
    if _infJumpConn then return end
    _infJumpConn = UIS.JumpRequest:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end
    end)
end

local function disconnectInfJump()
    if _infJumpConn then
        pcall(function() _infJumpConn:Disconnect() end)
        _infJumpConn = nil
    end
end

function EnableInfiniteJump(state)
    infJumpEnabled = not not state
    if infJumpEnabled then connectInfJump() else disconnectInfJump() end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then applyJumpPower(hum, jumpPower) end
    if infJumpEnabled then disconnectInfJump(); connectInfJump() end
end)

applyJumpNow()
if infJumpEnabled then connectInfJump() end

-- ── Player UI ────────────────────────────────────────────────
local jumpSliderObj = PlayerSec:NewSlider("Jump Power", "ความสูงกระโดด", 350, 50, function(s)
    SetJumpPower(s); config.jumpPower = s; SaveConfig()
end)

local infJumpTogObj = PlayerSec:NewToggle("Infinite Jump", "กระโดดได้ไม่จำกัด", function(state)
    EnableInfiniteJump(state); config.infJump = state; SaveConfig()
end)

local ctrlClickTPEnabled = config.ctrlClickTP
local ctrlTPTogObj = PlayerSec:NewToggle("Ctrl+Click TP", "กด Ctrl+คลิกซ้ายเพื่อวาร์ป", function(state)
    ctrlClickTPEnabled = state; config.ctrlClickTP = state; SaveConfig()
end)

local _tpRayParams = RaycastParams.new()
_tpRayParams.FilterType  = Enum.RaycastFilterType.Blacklist
_tpRayParams.IgnoreWater = true

local function doCtrlClickTP()
    if not ctrlClickTPEnabled then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    _tpRayParams.FilterDescendantsInstances = { char }
    local mp  = UIS:GetMouseLocation()
    local ray = Camera:ScreenPointToRay(mp.X, mp.Y)
    local res = workspace:Raycast(ray.Origin, ray.Direction * 5000, _tpRayParams)
    local pos = res and (res.Position + Vector3.new(0, 3, 0)) or (ray.Origin + ray.Direction * 100)
    pcall(function()
        root.CFrame = CFrame.new(pos)
        Library:Notify("TP", "วาร์ปสำเร็จ", 2)
    end)
end

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl) then
            doCtrlClickTP()
        end
    end
end)

-- =============================================================
--  AIMBOT UI
-- =============================================================
local aimbotTogObj = AimbotSec:NewToggle("เปิด Aimbot", "เล็งศัตรูอัตโนมัติ", function(state)
    aimbotEnabled = state
    if not state then lockedTarget = nil end
    config.aimbotEnabled = state; SaveConfig()
end)

local showFOVTogObj = AimbotSec:NewToggle("แสดง FOV Circle", "วงกลมขอบเขตการล็อก", function(state)
    showFOV = state; fovCircle.Visible = state
    config.showFOV = state; SaveConfig()
end)

local fovSliderObj = AimbotSec:NewSlider("FOV Size", "ขนาดวงกลม FOV", 500, 30, function(s)
    aimbotFOV = s; fovCircle.Radius = s
    config.aimbotFOV = s; SaveConfig()
end)

local smoothSliderObj = AimbotSec:NewSlider("Smoothness", "ความนุ่มนวลในการล็อก", 10, 1, function(s)
    aimbotSmoothness = s / 10; config.aimbotSmoothness = s; SaveConfig()
end)

AimbotSec:NewDropdown("จุดเล็ง", "เลือกส่วนที่จะล็อก", { "Head", "HumanoidRootPart" }, function(sel)
    aimbotPart = sel; config.aimbotPart = sel; SaveConfig()
end)

-- =============================================================
--  HITBOX UI
-- =============================================================
local hitboxTogObj = HitboxSec:NewToggle("เปิด Hitbox Expander", "ขยาย Hitbox ศัตรู", function(state)
    hitboxEnabled = state; config.hitboxEnabled = state; SaveConfig()
    if not state then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Size = Vector3.new(2, 2, 1); hrp.Transparency = 1 end
            end
        end
    end
end)

local hitboxSliderObj = HitboxSec:NewSlider("Hitbox Size", "ขนาด Hitbox", 50, 2, function(s)
    hitboxSize = s; config.hitboxSize = s; SaveConfig()
end)

-- =============================================================
--  ESP UI
-- =============================================================
local espTogObj = ESPSec:NewToggle("เปิด ESP", "แสดงชื่อและระยะของผู้เล่น", function(state)
    ESPEnabled = state; config.espEnabled = state; SaveConfig()
end)

local espDistSliderObj = ESPSec:NewSlider("ระยะ ESP", "ระยะสูงสุดที่แสดง ESP", 5000, 50, function(s)
    maxESPDistance = s; config.maxESPDistance = s; SaveConfig()
end)

-- =============================================================
--  KILL AURA (REMOVED) -- ปรับโค้ดแล้ว: ไม่มีส่วนของ Kill Aura
-- =============================================================

-- =============================================================
--  TAB: TP PLAYER
-- =============================================================
local function TeleportToSelectedPlayer()
    if not selectedPlayerName or not foundPlayersData[selectedPlayerName] then
        pcall(function() Library:Notify("Error", "เลือกผู้เล่นก่อน", 3) end)
        return
    end
    local target     = foundPlayersData[selectedPlayerName]
    local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    local myRoot     = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myRoot and targetRoot then
        local behind = -targetRoot.CFrame.LookVector
        myRoot.CFrame = CFrame.new(targetRoot.Position + behind * tpOffsetDistance, targetRoot.Position)
        pcall(function() Library:Notify("TP Player", "วาร์ปสำเร็จ", 2) end)
    else
        pcall(function() Library:Notify("Error", "ไม่พบตัวละครเป้าหมาย", 3) end)
    end
end

playerDropdown = TPPlrSec:NewDropdown("ผู้เล่น", "เลือกผู้เล่น", { "กด Scan ก่อน" }, function(sel)
    selectedPlayerName = sel
end)

TPPlrSec:NewButton("Scan ผู้เล่น (2000m)", "สแกนผู้เล่นในรัศมี 2000m", function()
    foundPlayersData = {}
    local list   = {}
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local nearby = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (myRoot.Position - root.Position).Magnitude
                if dist <= 2000 then table.insert(nearby, { player = plr, dist = dist }) end
            end
        end
    end
    table.sort(nearby, function(a, b) return a.dist < b.dist end)
    for _, item in ipairs(nearby) do
        local label = item.player.Name .. " [" .. math.floor(item.dist) .. "m]"
        foundPlayersData[label] = item.player
        table.insert(list, label)
    end
    if #list == 0 then table.insert(list, "ไม่พบผู้เล่นในรัศมี") end
    pcall(function() playerDropdown:Refresh(list) end)
end)

-- เปลี่ยน max slider จาก 50 → 300
local tpOffsetSliderObj = TPPlrSec:NewSlider("ระยะห่าง", "วาร์ปห่างจากเป้าหมาย", 300, 1, function(s)
    tpOffsetDistance = s; config.tpOffsetDistance = s; SaveConfig()
end)

TPPlrSec:NewButton("วาร์ปหาผู้เล่น", "ไปด้านหลังผู้เล่นที่เลือก", function()
    TeleportToSelectedPlayer()
end)
TPPlrSec:NewKeybind("Hotkey วาร์ปผู้เล่น", "กดเพื่อวาร์ปทันที", Enum.KeyCode.E, function()
    TeleportToSelectedPlayer()
end)

-- =============================================================
--  TAB: TP MAP — SECTION 1: ตำแหน่งที่บันทึกเอง
-- =============================================================
TPMapSavedSec:NewTextBox("ชื่อตำแหน่ง", "พิมพ์ชื่อก่อนกด Save", function(text)
    customLocationName = text
end)

local initSavedList = {}
for k in pairs(userSavedCoords) do table.insert(initSavedList, k) end
table.sort(initSavedList)
if #initSavedList == 0 then initSavedList = { "ยังไม่มีตำแหน่งที่บันทึก" } end

savedLocDropdown = TPMapSavedSec:NewDropdown("ตำแหน่งที่บันทึก", "เลือกตำแหน่ง", initSavedList, function(sel)
    selectedSavedLoc = sel
end)

TPMapSavedSec:NewButton("💾 Save ตำแหน่งปัจจุบัน", "บันทึกพิกัดที่ยืนอยู่ด้วยชื่อที่พิมพ์", function()
    local name = customLocationName ~= "" and customLocationName or nil
    if not name then
        pcall(function() Library:Notify("Error", "พิมพ์ชื่อตำแหน่งก่อน", 3) end)
        return
    end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        pcall(function() Library:Notify("Error", "ไม่พบตัวละคร", 3) end)
        return
    end
    local pos = myRoot.Position
    userSavedCoords[name]          = pos
    config.userSavedCoords[name]   = Vec3ToTable(pos)
    SaveConfig()
    RefreshSavedDropdown()
    pcall(function() Library:Notify("Saved ✓", "บันทึก [" .. name .. "] แล้ว", 3) end)
end)

TPMapSavedSec:NewButton("🗑 ลบตำแหน่งที่เลือก", "ลบออกจากลิส", function()
    if not selectedSavedLoc or userSavedCoords[selectedSavedLoc] == nil then
        pcall(function() Library:Notify("Error", "เลือกตำแหน่งก่อน", 3) end)
        return
    end
    local name = selectedSavedLoc
    userSavedCoords[name]        = nil
    config.userSavedCoords[name] = nil
    selectedSavedLoc             = nil
    SaveConfig()
    RefreshSavedDropdown()
    pcall(function() Library:Notify("Deleted", "ลบ [" .. name .. "] แล้ว", 3) end)
end)

TPMapSavedSec:NewButton("🚀 วาร์ปไปตำแหน่งที่บันทึก", "วาร์ปไปตำแหน่งที่เลือกในลิสนี้", function()
    if not selectedSavedLoc or not userSavedCoords[selectedSavedLoc] then
        pcall(function() Library:Notify("Error", "เลือกตำแหน่งก่อน", 3) end)
        return
    end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myRoot then
        myRoot.CFrame = CFrame.new(userSavedCoords[selectedSavedLoc] + Vector3.new(0, 5, 0))
        pcall(function() Library:Notify("TP ✓", "วาร์ปไป [" .. selectedSavedLoc .. "]", 3) end)
    end
end)

-- =============================================================
--  TAB: TP MAP — SECTION 2: ตำแหน่งจาก Auto Scan
-- =============================================================
local searchKeywords = {
    ["Prison"]     = "prison",
    ["Woodbury"]   = "woodbury",
    ["Farmland"]   = "farm",
    ["Hospital"]   = { "hospital", "king county" },
    ["Quarry"]     = "quarry",
    ["Terminus"]   = "terminus",
    ["Big Spot"]   = "big spot",
    ["Outpost"]    = "outpost",
    ["Hilltop"]    = "hilltop",
    ["Police Dept"]= "pd",
    ["Motel"]      = "motel",
    ["Alexandria"] = "alexandria",
    ["Sanctuary"]  = "sanctuary",
}

local initScannedList = {}
for k in pairs(scannedCoords) do table.insert(initScannedList, k) end
table.sort(initScannedList)
if #initScannedList == 0 then initScannedList = { "กด Auto Scan ก่อน" } end

scannedLocDropdown = TPMapScannedSec:NewDropdown("ตำแหน่ง Scan", "เลือกตำแหน่ง", initScannedList, function(sel)
    selectedScannedLoc = sel
end)

TPMapScannedSec:NewButton("🔍 Auto Scan แมพ", "สแกนหาตำแหน่งในแมพอัตโนมัติ (บันทึกไว้ใช้ครั้งต่อไป)", function()
    local found = 0
    for locName, kwData in pairs(searchKeywords) do
        local positions = {}
        for _, obj in pairs(workspace:GetDescendants()) do
            local nameLow = string.lower(obj.Name)
            local matched = false
            if type(kwData) == "table" then
                for _, kw in ipairs(kwData) do
                    if string.find(nameLow, kw) then matched = true; break end
                end
            else
                matched = string.find(nameLow, kwData) ~= nil
            end
            if matched then
                local pos
                if obj:IsA("BasePart") then pos = obj.Position
                elseif obj:IsA("Model") then pcall(function() pos = obj:GetPivot().Position end) end
                if pos then table.insert(positions, pos) end
            end
        end
        if #positions > 0 then
            local sx, sy, sz = 0, 0, 0
            for _, p in ipairs(positions) do sx = sx + p.X; sy = sy + p.Y; sz = sz + p.Z end
            local n = #positions
            local centroid = Vector3.new(sx/n, sy/n, sz/n)
            scannedCoords[locName]        = centroid
            config.scannedCoords[locName] = Vec3ToTable(centroid)
            found = found + 1
        end
    end
    SaveConfig()
    RefreshScannedDropdown()
    pcall(function() Library:Notify("Auto Scan ✓", "พบ " .. found .. " ตำแหน่ง (บันทึกแล้ว)", 4) end)
end)

TPMapScannedSec:NewButton("🚀 วาร์ปไปตำแหน่ง Scan", "วาร์ปไปตำแหน่งที่เลือกในลิสนี้", function()
    if not selectedScannedLoc or not scannedCoords[selectedScannedLoc] then
        pcall(function() Library:Notify("Error", "เลือกตำแหน่งหรือ Scan ก่อน", 3) end)
        return
    end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myRoot then
        myRoot.CFrame = CFrame.new(scannedCoords[selectedScannedLoc] + Vector3.new(0, 5, 0))
        pcall(function() Library:Notify("TP ✓", "วาร์ปไป [" .. selectedScannedLoc .. "]", 3) end)
    end
end)

TPMapScannedSec:NewButton("🗑 ล้างข้อมูล Scan", "ลบตำแหน่ง Scan ทั้งหมด", function()
    for k in pairs(scannedCoords) do scannedCoords[k] = nil end
    config.scannedCoords = {}
    selectedScannedLoc   = nil
    SaveConfig()
    RefreshScannedDropdown()
    pcall(function() Library:Notify("Cleared", "ล้างข้อมูล Scan แล้ว", 3) end)
end)

-- =============================================================
--  TAB: TP LOOT
-- =============================================================
boxDropdown = TPLootSec:NewDropdown("ของที่พบ", "เลือก Loot", { "กด Scan ก่อน" }, function(sel)
    selectedBoxName = sel
end)

TPLootSec:NewButton("Scan Loot (1000m)", "สแกนหา Loot ในรัศมี 1000m", function()
    foundBoxesData = {}
    local list   = {}
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local nearby    = {}
    local seenParts = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            if string.find(string.lower(obj.Name), "loot_") then
                local displayName = obj.Name
                if string.sub(string.lower(displayName), 1, 5) == "loot_" then
                    displayName = string.sub(displayName, 6)
                end
                local part = obj:IsA("BasePart") and obj
                          or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")))
                if part and not seenParts[part] then
                    local dist = (myRoot.Position - part.Position).Magnitude
                    if dist <= 1000 then
                        seenParts[part] = true
                        table.insert(nearby, { part = part, name = displayName, dist = dist })
                    end
                end
            end
        end
    end
    table.sort(nearby, function(a, b) return a.dist < b.dist end)
    for _, item in ipairs(nearby) do
        local label = item.name .. " [" .. math.floor(item.dist) .. "m]"
        if foundBoxesData[label] then
            label = item.name .. " (" .. math.floor(item.part.Position.X) .. ") [" .. math.floor(item.dist) .. "m]"
        end
        foundBoxesData[label] = { part = item.part }
        table.insert(list, label)
    end
    if #list == 0 then table.insert(list, "ไม่พบ Loot ในรัศมี") end
    pcall(function() boxDropdown:Refresh(list) end)
end)

TPLootSec:NewButton("วาร์ปไปหา Loot", "วาร์ปไปด้านหน้า Loot ที่เลือก", function()
    if not selectedBoxName or not foundBoxesData[selectedBoxName] then return end
    local myRoot  = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local boxPart = foundBoxesData[selectedBoxName].part
    if myRoot and boxPart then
        local look     = boxPart.CFrame.LookVector
        local flatLook = Vector3.new(look.X, 0, look.Z)
        if flatLook.Magnitude < 0.1 then flatLook = Vector3.new(1, 0, 0) else flatLook = flatLook.Unit end
        myRoot.CFrame = CFrame.new(boxPart.Position + flatLook * 3 + Vector3.new(0, 1, 0), boxPart.Position)
    end
end)

-- =============================================================
--  TAB: UTILITY
-- =============================================================
UtilSec:NewButton("Rejoin", "เข้าเซิร์ฟเวอร์เดิมใหม่", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)
UtilSec:NewKeybind("เปิด/ปิด UI", "Toggle หน้าต่าง", Enum.KeyCode.RightControl, function()
    Library:ToggleUI()
end)

ConfigSec:NewButton("Save Config", "บันทึกการตั้งค่าทั้งหมด", function()
    SaveConfig()
    pcall(function() Library:Notify("Config", "บันทึกแล้ว ✓", 2) end)
end)
ConfigSec:NewButton("Reset Config", "รีเซ็ตทุกอย่างเป็นค่าเริ่มต้น", function()
    if writefile then
        pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(defaultConfig)) end)
    end
    for k in pairs(userSavedCoords) do userSavedCoords[k] = nil end
    for k in pairs(scannedCoords)   do scannedCoords[k]   = nil end
    pcall(function() Library:Notify("Reset", "รีเซ็ตแล้ว กรุณา Re-execute", 4) end)
end)

-- =============================================================
--  SYNC UI กับ CONFIG ที่โหลดมา
-- =============================================================
task.defer(function()
    if config.infJump        and infJumpTogObj      then pcall(function() infJumpTogObj:UpdateToggle(nil, true) end) end
    if config.ctrlClickTP    and ctrlTPTogObj        then pcall(function() ctrlTPTogObj:UpdateToggle(nil, true) end) end
    if config.aimbotEnabled  and aimbotTogObj        then pcall(function() aimbotTogObj:UpdateToggle(nil, true) end) end
    if config.showFOV        and showFOVTogObj       then pcall(function() showFOVTogObj:UpdateToggle(nil, true) end) end
    if config.hitboxEnabled  and hitboxTogObj        then pcall(function() hitboxTogObj:UpdateToggle(nil, true) end) end
    if config.espEnabled     and espTogObj           then pcall(function() espTogObj:UpdateToggle(nil, true) end) end

    task.wait(0.1)

    -- ปรับ sync ให้ทนทานกับโครงสร้าง UI ที่ต่างกัน และเพิ่ม delay สั้น ๆ
local function syncSliderByLabel(labelText, value, minV, maxV)
    local function setSliderVisual(sliderBtn)
        local drag = sliderBtn:FindFirstChild("sliderBtn") and sliderBtn.sliderBtn:FindFirstChild("sliderDrag")
                 or sliderBtn:FindFirstChild("sliderDrag")
        if drag and drag:IsA("GuiObject") then
            drag.Size = UDim2.new(0, math.floor(math.clamp((value - minV) / (maxV - minV), 0, 1) * 149), 0, 6)
        end
        local val = sliderBtn:FindFirstChild("val")
        if val and val:IsA("TextLabel") then val.Text = tostring(value) end
    end

    local core = game:GetService("CoreGui")
    for _, sg in pairs(core:GetChildren()) do
        -- หา TextLabel ที่ตรงกับป้ายชื่อ
        for _, lbl in pairs(sg:GetDescendants()) do
            if lbl:IsA("TextLabel") and lbl.Text == labelText then
                -- ไต่ ancestor ขึ้นไปหลายระดับเพื่อตามหา container ที่มี slider
                local anc = lbl
                for i = 1, 6 do
                    anc = anc.Parent
                    if not anc then break end
                    -- หา descendant ที่เป็นปุ่ม slider (TextButton) ภายใน ancestor นี้
                    for _, cand in pairs(anc:GetDescendants()) do
                        if cand:IsA("TextButton") then
                            if (cand:FindFirstChild("sliderBtn") and cand.sliderBtn:FindFirstChild("sliderDrag"))
                            or cand:FindFirstChild("sliderDrag")
                            or cand:FindFirstChild("val") then
                                pcall(function() setSliderVisual(cand) end)
                                return
                            end
                        end
                    end
                end
            end
        end
    end
end

-- รอให้ UI สร้างเสร็จก่อน (เพิ่มเล็กน้อย)
task.wait(0.5)

-- เรียก sync ตามป้ายชื่อที่ใช้ตอนสร้าง slider (แก้ชื่อ label ถ้าต่าง)
syncSliderByLabel("Jump Power",        config.jumpPower,        50,  350)
syncSliderByLabel("FOV Size",         config.aimbotFOV,        30,  500)
syncSliderByLabel("Smoothness",       config.aimbotSmoothness, 1,   10)
syncSliderByLabel("Hitbox Size",      config.hitboxSize,       2,   50)
syncSliderByLabel("ระยะ ESP",         config.maxESPDistance,   50,  5000)
syncSliderByLabel("ระยะห่าง",         config.tpOffsetDistance, 1,   300)

    -- refresh dropdown ของ map หลัง UI พร้อม
    RefreshSavedDropdown()
    RefreshScannedDropdown()

    pcall(function() Library:Notify("N-HUB", "โหลด Config สำเร็จ ✓", 2) end)
end)

-- =============================================================
--  AIMBOT LOGIC
-- =============================================================
local function GetClosestInFOV()
    local closest = nil
    local minDist = aimbotFOV
    local mousePos = UIS:GetMouseLocation()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local part = plr.Character:FindFirstChild(aimbotPart)
            local hum  = plr.Character:FindFirstChildOfClass("Humanoid")
            if part and hum and hum.Health > 0 then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local d = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                    if d < minDist then minDist = d; closest = part end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    fovCircle.Position = UIS:GetMouseLocation()
    fovCircle.Radius   = aimbotFOV
    fovCircle.Visible  = showFOV

    if aimbotEnabled and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if not lockedTarget
        or not lockedTarget.Parent
        or not lockedTarget.Parent:FindFirstChildOfClass("Humanoid")
        or lockedTarget.Parent.Humanoid.Health <= 0 then
            lockedTarget = GetClosestInFOV()
        end
        if lockedTarget then
            local tp = lockedTarget.Position
            if aimbotSmoothness >= 0.95 then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, tp)
            else
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, tp), aimbotSmoothness)
            end
        end
    else
        lockedTarget = nil
    end
end)

-- =============================================================
--  HITBOX LOOP
-- =============================================================
RunService.Stepped:Connect(function()
    if hitboxEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Size         = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                    hrp.Transparency = 0.7
                    hrp.BrickColor   = BrickColor.new("Really red")
                    hrp.Material     = Enum.Material.ForceField
                    hrp.CanCollide   = false
                end
            end
        end
    end
end)
