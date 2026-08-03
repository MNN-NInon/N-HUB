-- =============================================================
--  WALLHACK FEATURE (ยิงทะลุกำแพง)
--  เพิ่มเข้าไปใน N-HUB | UNIVERSAL V3
-- =============================================================

-- เพิ่มตัวแปรใน defaultConfig (หาส่วน defaultConfig = {...})
-- wallhackEnabled = false,
-- wallTransparency = 0.4,

-- ตัวแปร Wallhack (เพิ่มหลัง COMBAT VARIABLES)
local wallhackEnabled   = config.wallhackEnabled or false
local wallTransparency  = config.wallTransparency or 0.4
local ignoredWalls      = {}

-- =============================================================
--  WALLHACK UI (เพิ่มใน AIMBOT UI SECTION)
--  ใส่ Code นี้ลงไปหลัง HitboxSec ที่มี Hitbox Size Slider
-- =============================================================

local WallhackSec = AimbotTab:NewSection("ทะลุกำแพง")

local wallhackTogObj = WallhackSec:NewToggle("เปิด Wallhack", "ยิงทะลุกำแพงและสิ่งกีดขวาง", function(state)
    wallhackEnabled = state
    config.wallhackEnabled = state
    SaveConfig()
    
    if state then
        pcall(function() Library:Notify("Wallhack", "เปิดแล้ว ✓", 2) end)
    else
        -- คืนค่าปกติเมื่อปิด
        for part, _ in pairs(ignoredWalls) do
            if part and part.Parent then
                pcall(function()
                    part.CanCollide = true
                    part.Transparency = part.Transparency - 0.3
                end)
            end
        end
        ignoredWalls = {}
    end
end)

local wallTransSlider = WallhackSec:NewSlider("ความโปร่งใส", "ปรับโปร่งใสของกำแพง", 1, 0.1, function(s)
    wallTransparency = math.floor(s * 10) / 10
    config.wallTransparency = wallTransparency
    SaveConfig()
end)

-- =============================================================
--  WALLHACK LOGIC
-- =============================================================

local function ApplyWallhack()
    if not wallhackEnabled then return end
    
    local myChar = LocalPlayer.Character
    if not myChar then return end
    
    -- หา Raycast Direction จากกล้อง
    local camera = workspace.CurrentCamera
    local rayOrigin = camera.CFrame.Position
    local rayDirection = (camera.Focus.Position - rayOrigin).Unit
    
    -- Raycast เพื่อหาว่ากำแพงอยู่ที่ไหน
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = { myChar }
    rayParams.IgnoreWater = true
    
    local rayResult = workspace:Raycast(rayOrigin, rayDirection * 10000, rayParams)
    
    if rayResult then
        local hitPart = rayResult.Instance
        if hitPart and hitPart.Parent then
            -- ตรวจสอบว่าเป็นกำแพง ประตู หรือสิ่งกีดขวาง
            local objName = string.lower(hitPart.Name)
            local isWall = string.find(objName, "wall") 
                        or string.find(objName, "door")
                        or string.find(objName, "fence")
                        or string.find(objName, "barrier")
                        or string.find(objName, "part")
                        or hitPart.Name == "Baseplate"
            
            -- ถ้าเป็นกำแพง ให้ทะลุได้
            if isWall and hitPart:IsA("BasePart") then
                pcall(function()
                    -- เก็บค่าเดิมไว้เพื่อคืนค่าหลังปิด
                    if not ignoredWalls[hitPart] then
                        ignoredWalls[hitPart] = {
                            canCollide = hitPart.CanCollide,
                            transparency = hitPart.Transparency
                        }
                    end
                    
                    -- ปิด Collision และทำให้โปร่งใส
                    hitPart.CanCollide = false
                    hitPart.Transparency = wallTransparency
                end)
            end
        end
    end
end

-- RunService Loop สำหรับ Wallhack
RunService.RenderStepped:Connect(function()
    if wallhackEnabled then
        ApplyWallhack()
    end
end)

-- ทำให้ Wallhack ทำงานอัตโนมัติเวลา Aimbot ยิง
local originalAimbotLoop = RunService.RenderStepped:Connect(function()
    if wallhackEnabled and aimbotEnabled and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        ApplyWallhack()
    end
end)

-- =============================================================
--  SYNC WALLHACK CONFIG (เพิ่มใน SYNC UI กับ CONFIG)
-- =============================================================
-- task.defer(function()
--     if config.wallhackEnabled and wallhackTogObj then
--         pcall(function() wallhackTogObj:UpdateToggle(nil, true) end)
--     end
--     
--     if config.wallTransparency and wallTransSlider then
--         pcall(function() wallTransSlider:Set(config.wallTransparency) end)
--     end
-- end)
