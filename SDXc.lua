--!native
-- ============================================================
-- QE V1 - 终极重构版 (全功能稳定版 + 自动背刺)
-- ============================================================

local Players       = game:GetService("Players")
local LP            = Players.LocalPlayer
local RS            = game:GetService("ReplicatedStorage")
local WS            = game:GetService("Workspace")
local RunService    = game:GetService("RunService")
local Lighting      = game:GetService("Lighting")
local VirtualUser   = game:GetService("VirtualInputManager")
local c3rgb         = Color3.fromRGB
local c3n           = Color3.new

-- ====================================================
-- 0. 环境清理
-- ====================================================
if getgenv().QE_CleanupAll then pcall(getgenv().QE_CleanupAll) getgenv().QE_CleanupAll = nil end
local prev = getgenv().QE_Instance
if prev and prev.ScreenGui then pcall(function() prev.ScreenGui:Destroy() end) end

-- ====================================================
-- 1. 加载 UI
-- ====================================================
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
getgenv().QE_Instance = Library
Library.Scheme = { BackgroundColor = c3rgb(5,5,5), MainColor = c3rgb(24,24,28), AccentColor = c3rgb(225,30,30), OutlineColor = c3rgb(30,5,5), FontColor = c3n(1,1,1), Font = Font.fromEnum(Enum.Font.Code) }
local Window = Library:CreateWindow({ Title = "QE V1", Footer = "Ultimate Edition", Icon = "rbxassetid://4483362748", Center = true, AutoShow = true })
local Tabs = {
    Main = Window:AddTab("主页", "home"),
    Block = Window:AddTab("自动格挡", "shield"),
    Backstab = Window:AddTab("自动背刺", "sword"),
    Aimbot = Window:AddTab("自瞄", "crosshair"),
    Visual = Window:AddTab("视觉", "eye"),
    Utility = Window:AddTab("实用", "wrench"),
}

-- ====================================================
-- 2. 核心配置与 ID 库
-- ====================================================
local Config = {
    Block = { Enabled = false, Cooldown = 0.1, FacingCheck = true, WallCheck = true, BoxSize = {X=5, Y=8, Z=5}, BoxOffset = 4, BoxTrans = 0.5, BoxColor = {255,0,0}, BoxLinger = 1.0, Delay = 0.02 },
    Backstab = { Enabled = false, Dist = 8 },
    Aimbot = { Chance = false, Dist = 100 },
    Visual = { ESP = false, Fullbright = false, NoFog = false },
    Utility = { Stamina = false, AntiSlow = false, Noclip = false }
}

local AttackAnimIDs = {
    ["126830014841198"]=true, ["126355327951215"]=true, ["121086746534252"]=true, ["101736016625776"]=true,
    ["18885909645"]=true, ["98456918873918"]=true, ["18885937766"]=true, ["18885940850"]=true,
    ["105458270463374"]=true, ["106538427162796"]=true, ["139835501933932"]=true, ["126896426760253"]=true,
    ["114356208094580"]=true, ["135884061951801"]=true, ["83829782357897"]=true, ["99050723653468"]=true,
    ["119181003138006"]=true, ["122709416391891"]=true, ["87989533095285"]=true, ["133363345661032"]=true,
    ["128414736976503"]=true, ["139309647473555"]=true, ["88451353906104"]=true, ["91628732643385"]=true,
    ["115403107018365"]=true, ["124619925708292"]=true,
}
local AttackSoundIDs = {
    ["112809109188560"]=true, ["102228729296384"]=true, ["80516583309685"]=true, ["111261564982886"]=true,
    ["75467546215199"]=true, ["80919153988550"]=true, ["86451559088289"]=true, ["140242176732868"]=true,
    ["136323728355613"]=true, ["115026634746636"]=true, ["84116622032112"]=true, ["108907358619313"]=true,
    ["127793641088496"]=true, ["86174610237192"]=true, ["95079963655241"]=true, ["101199185291628"]=true,
    ["119942598489800"]=true, ["84307400688050"]=true, ["113037804008732"]=true, ["105200830849301"]=true,
    ["75330693422988"]=true, ["82221759983649"]=true, ["81702359653578"]=true, ["108610718831698"]=true,
    ["112395455254818"]=true, ["109431876587852"]=true, ["109348678063422"]=true, ["85853080745515"]=true,
    ["90819435118493"]=true, ["117173212095661"]=true, ["100321250424257"]=true, ["77100821793542"]=true,
    ["81989261113189"]=true, ["129108619555351"]=true, ["119583605486352"]=true, ["79980897195554"]=true,
    ["110877859670130"]=true, ["104910828105172"]=true, ["110126546193799"]=true, ["104388455240670"]=true,
    ["85544168523099"]=true, ["103736328206432"]=true, ["128307808203038"]=true, ["111104117703814"]=true,
    ["97100466324703"]=true, ["74000375845213"]=true, ["111502315377475"]=true, ["84340345572285"]=true,
    ["120394605928086"]=true, ["134973085112081"]=true, ["79554277951408"]=true, ["115476331903507"]=true,
}

-- ====================================================
-- 3. 核心判定与网络
-- ====================================================
local RemoteEvent
pcall(function() RemoteEvent = RS:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent", 5) end)
local lastBlock = 0
local function FireBlock()
    if not RemoteEvent then return false end
    local now = tick()
    if now - lastBlock < Config.Block.Cooldown then return false end
    lastBlock = now
    pcall(function() RemoteEvent:FireServer("UseActorAbility", {buffer.fromstring("\3\5\0\0\0Block")}) end)
    return true
end

local function myRoot() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getKillersFolder() local pf = WS:FindFirstChild("Players"); return pf and pf:FindFirstChild("Killers") end
local function GetBoxSize() local b = Config.Block.BoxSize return Vector3.new(b.X, b.Y, b.Z) end

-- 高级判定：面向、穿墙、框内
local function IsFacing(root, kRoot) 
    if not Config.Block.FacingCheck then return true end 
    local dir = (root.Position - kRoot.Position) 
    local flat = Vector3.new(dir.X, 0, dir.Z).Unit 
    local look = Vector3.new(kRoot.CFrame.LookVector.X, 0, kRoot.CFrame.LookVector.Z).Unit 
    return math.deg(math.acos(math.clamp(look:Dot(flat), -1, 1))) <= 90 
end
local function HasLOS(targetRoot) 
    if not Config.Block.WallCheck then return true end 
    local root = myRoot(); if not root then return false end 
    local params = RaycastParams.new() 
    params.FilterType = Enum.RaycastFilterType.Exclude; params.IgnoreWater = true; params.FilterDescendantsInstances = {LP.Character} 
    local result = WS:Raycast(root.Position, targetRoot.Position - root.Position, params) 
    return not result or result.Instance:IsDescendantOf(targetRoot.Parent) 
end
local function InBox(root, kRoot) 
    local boxSize = GetBoxSize() 
    local forward = kRoot.CFrame.LookVector 
    local boxPos = kRoot.Position + forward * Config.Block.BoxOffset 
    local boxCFrame = CFrame.lookAt(boxPos, boxPos + forward * 100) 
    local rel = root.Position - boxPos 
    local localSpace = boxCFrame:VectorToObjectSpace(rel) 
    return math.abs(localSpace.X) <= (boxSize.X / 2) and math.abs(localSpace.Y) <= (boxSize.Y / 2) and math.abs(localSpace.Z) <= (boxSize.Z / 2) 
end
local function CanBlock(root, kRoot) return InBox(root, kRoot) and IsFacing(root, kRoot) and HasLOS(kRoot) end

-- ====================================================
-- 4. 高级对象池 (碰撞箱管理)
-- ====================================================
local BoxPool = {}
local function SpawnBox(killer)
    if not killer or not killer:FindFirstChild("HumanoidRootPart") then return end
    if BoxPool[killer] then
        BoxPool[killer].expire = tick() + Config.Block.BoxLinger
        return
    end
    local folder = Instance.new("Folder"); folder.Name = "QE_Box"; folder.Parent = killer.HumanoidRootPart
    local box = Instance.new("Part"); box.Name = "Box"; box.Material = Enum.Material.ForceField
    box.Anchored = true; box.CanCollide = false; box.CanQuery = false; box.CastShadow = false
    box.Transparency = Config.Block.BoxTrans; box.Color = Color3.fromRGB(unpack(Config.Block.BoxColor))
    box.Size = GetBoxSize(); box.Parent = folder
    BoxPool[killer] = {folder = folder, box = box, killer = killer, expire = tick() + Config.Block.BoxLinger}
end

-- 监听器
local function HookSound(snd)
    if not snd:IsA("Sound") or snd:GetAttribute("QE_Hooked") then return end
    snd:SetAttribute("QE_Hooked", true)
    snd.Played:Connect(function()
        if not Config.Block.Enabled then return end
        local id = tostring(snd.SoundId):match("%d+")
        if not id or not AttackSoundIDs[id] then return end
        local parent = snd.Parent
        while parent and not parent:IsA("Model") do parent = parent.Parent end
        if parent then SpawnBox(parent) end
    end)
end
local function HookAnim(animator)
    if not animator:IsA("Animator") or animator:GetAttribute("QE_Hooked") then return end
    animator:SetAttribute("QE_Hooked", true)
    animator.AnimationPlayed:Connect(function(track)
        if not Config.Block.Enabled then return end
        local id = track.Animation and track.Animation.AnimationId:match("%d+")
        if not id or not AttackAnimIDs[id] then return end
        local parent = track.Parent
        while parent and not parent:IsA("Model") do parent = parent.Parent end
        if parent then SpawnBox(parent) end
    end)
end

for _, d in ipairs(WS:GetDescendants()) do
    if d:IsA("Sound") then HookSound(d) end
    if d:IsA("Animator") then HookAnim(d) end
end
WS.DescendantAdded:Connect(function(d)
    if d:IsA("Sound") then HookSound(d) end
    if d:IsA("Animator") then HookAnim(d) end
end)

-- ====================================================
-- 5. 自动背刺逻辑 (带指示线)
-- ====================================================
local Backstab = { LastTime = 0 }
local beamPart1 = Instance.new("Part"); beamPart1.Anchored = true; beamPart1.CanCollide = false; beamPart1.Transparency = 1; beamPart1.Parent = WS
local beamPart2 = Instance.new("Part"); beamPart2.Anchored = true; beamPart2.CanCollide = false; beamPart2.Transparency = 1; beamPart2.Parent = WS
local backstabBeam = Instance.new("Beam"); backstabBeam.FaceCamera = true; backstabBeam.Width0 = 0.1; backstabBeam.Width1 = 0.1; backstabBeam.LightEmission = 1; backstabBeam.LightInfluence = 0; backstabBeam.Enabled = false; backstabBeam.Parent = beamPart1
local att1 = Instance.new("Attachment", beamPart1); local att2 = Instance.new("Attachment", beamPart2); backstabBeam.Attachment0 = att1; backstabBeam.Attachment1 = att2

local function isLocalPlayerTwoTime()
    local char = LP.Character; if not char then return false end
    local surv = WS:FindFirstChild("Players") and WS.Players:FindFirstChild("Survivors")
    if not surv then return false end
    for _, s in ipairs(surv:GetChildren()) do if s == char and s.Name == "TwoTime" then return true end end
    return false
end

-- ====================================================
-- 6. UI 构建
-- ====================================================
local BlockGroup = Tabs.Block:AddGroupbox({ Side = "Left", Name = "🛡️ 自动格挡" })
BlockGroup:AddToggle("AutoBlock", { Text = "启用自动格挡", Callback = function(v) Config.Block.Enabled = v end })
BlockGroup:AddToggle("FacingCheck", { Text = "面向检测", Default = true, Callback = function(v) Config.Block.FacingCheck = v end })
BlockGroup:AddToggle("WallCheck", { Text = "穿墙检测", Default = true, Callback = function(v) Config.Block.WallCheck = v end })
BlockGroup:AddSlider("BlockDelay", { Text = "格挡延迟", Default = 0.02, Min = 0, Max = 0.5, Rounding = 2, Callback = function(v) Config.Block.Delay = v end })

local BoxGroup = Tabs.Block:AddGroupbox({ Side = "Right", Name = "📦 碰撞盒" })
BoxGroup:AddSlider("BoxWidth", { Text = "宽度", Default = 5, Min = 1, Max = 20, Rounding = 1, Callback = function(v) Config.Block.BoxSize.X = v end })
BoxGroup:AddSlider("BoxHeight", { Text = "高度", Default = 8, Min = 1, Max = 20, Rounding = 1, Callback = function(v) Config.Block.BoxSize.Y = v end })
BoxGroup:AddSlider("BoxLength", { Text = "长度", Default = 5, Min = 1, Max = 20, Rounding = 1, Callback = function(v) Config.Block.BoxSize.Z = v end })
BoxGroup:AddSlider("BoxOffset", { Text = "前后偏移", Default = 4, Min = -10, Max = 10, Rounding = 1, Callback = function(v) Config.Block.BoxOffset = v end })
BoxGroup:AddSlider("BoxTrans", { Text = "透明度", Default = 0.5, Min = 0, Max = 1, Rounding = 2, Callback = function(v) Config.Block.BoxTrans = v end })
BoxGroup:AddSlider("BoxLinger", { Text = "滞留时间", Default = 1.0, Min = 0.2, Max = 3.0, Rounding = 2, Callback = function(v) Config.Block.BoxLinger = v end })
BoxGroup:AddDropdown("BoxColor", { Text = "颜色", Values = {"红色", "绿色", "蓝色", "白色"}, Default = "红色", Callback = function(v)
    local c = { ["红色"]={255,0,0}, ["绿色"]={0,255,0}, ["蓝色"]={0,0,255}, ["白色"]={255,255,255} }
    Config.Block.BoxColor = c[v]
end })

-- 背刺 UI
local BackstabGroup = Tabs.Backstab:AddGroupbox({ Side = "Left", Name = "🗡️ 两次背刺" })
BackstabGroup:AddToggle("TwoTimeBackstab", { Text = "启用自动背刺", Callback = function(v) Config.Backstab.Enabled = v end })
BackstabGroup:AddSlider("BackDist", { Text = "触发距离", Default = 8, Min = 2, Max = 20, Rounding = 1, Callback = function(v) Config.Backstab.Dist = v end })

-- 自瞄 UI
local AimbotGroup = Tabs.Aimbot:AddGroupbox({ Side = "Left", Name = "🎯 角色自瞄" })
local chanceAimbotEnabled = false
AimbotGroup:AddToggle("ChanceAimbot", { Text = "机会自瞄", Callback = function(v) chanceAimbotEnabled = v end })
AimbotGroup:AddSlider("AimDist", { Text = "距离", Default = 100, Min = 20, Max = 300, Rounding = 0, Callback = function(v) Config.Aimbot.Dist = v end })

-- 实用 & 视觉
local UtilGroup = Tabs.Utility:AddGroupbox({ Side = "Left", Name = "🔧 实用" })
UtilGroup:AddToggle("InfStamina", { Text = "无限体力", Callback = function(v) Config.Utility.Stamina = v end })
UtilGroup:AddToggle("AntiSlow", { Text = "无减速", Callback = function(v) Config.Utility.AntiSlow = v end })
UtilGroup:AddToggle("Noclip", { Text = "穿墙", Callback = function(v) Config.Utility.Noclip = v end })
local VisGroup = Tabs.Visual:AddGroupbox({ Side = "Left", Name = "👁️ 视觉" })
VisGroup:AddToggle("Fullbright", { Text = "全亮", Callback = function(v) Config.Visual.Fullbright = v end })
VisGroup:AddToggle("NoFog", { Text = "去雾", Callback = function(v) Config.Visual.NoFog = v end })

-- ====================================================
-- 7. 核心主循环
-- ====================================================
local boxUpdateCounter = 0
local boxUpdateInterval = 2

RunService.Heartbeat:Connect(function()
    local char = LP.Character
    local root = myRoot()
    if not char or not root then return end

    -- 1. 碰撞箱生命周期与更新
    boxUpdateCounter = boxUpdateCounter + 1
    for killer, data in pairs(BoxPool) do
        if tick() > data.expire or not killer.Parent or not data.box.Parent then
            if data.folder then data.folder:Destroy() end
            BoxPool[killer] = nil
        else
            if boxUpdateCounter >= boxUpdateInterval then
                local kRoot = killer:FindFirstChild("HumanoidRootPart")
                if kRoot then
                    local forward = kRoot.CFrame.LookVector
                    local pos = kRoot.Position + forward * Config.Block.BoxOffset
                    data.box.Size = GetBoxSize()
                    data.box.CFrame = CFrame.lookAt(pos, pos + forward * 100)
                end
            end
        end
    end
    if boxUpdateCounter >= boxUpdateInterval then boxUpdateCounter = 0 end

    -- 2. 自动格挡执行
    if Config.Block.Enabled then
        for killer, data in pairs(BoxPool) do
            local kRoot = killer:FindFirstChild("HumanoidRootPart")
            if kRoot and CanBlock(root, kRoot) then
                task.delay(Config.Block.Delay, function() FireBlock() end)
            end
        end
    end

    -- 3. 背刺执行
    backstabBeam.Enabled = false
    if Config.Backstab.Enabled and isLocalPlayerTwoTime() and tick() - Backstab.LastTime >= 1 then
        local kf = getKillersFolder()
        if kf then
            local nearest, minDist = nil, math.huge
            for _, k in ipairs(kf:GetChildren()) do
                local kRoot = k:FindFirstChild("HumanoidRootPart")
                if kRoot then
                    local dist = (kRoot.Position - root.Position).Magnitude
                    if dist < nearest then nearest = k; minDist = dist end
                    local dot = kRoot.CFrame.LookVector:Dot((root.Position - kRoot.Position).Unit)
                    local isBehind = dot < -0.2
                    local inDistance = dist <= Config.Backstab.Dist
                    if k == nearest then
                        beamPart1.Position = root.Position
                        beamPart2.Position = kRoot.Position
                        backstabBeam.Enabled = true
                        backstabBeam.Color = (inDistance and isBehind) and ColorSequence.new(c3rgb(0,255,0)) or ColorSequence.new(c3rgb(255,0,0))
                    end
                    if inDistance and isBehind and tick() - Backstab.LastTime >= 1 then
                        pcall(function() VirtualUser:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game) end)
                        task.wait(0.1)
                        pcall(function() VirtualUser:SendKeyEvent(true, Enum.KeyCode.E, false, game); task.wait(0.05); VirtualUser:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
                        pcall(function() VirtualUser:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game) end)
                        Backstab.LastTime = tick(); break
                    end
                end
            end
        end
    end

    -- 4. 机会自瞄
    if chanceAimbotEnabled and char.Name == "Chance" then
        local kf = getKillersFolder()
        if kf then
            local nearest, minDist = nil, Config.Aimbot.Dist
            for _, k in ipairs(kf:GetChildren()) do
                local hrp = k:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = (hrp.Position - root.Position).Magnitude
                    if d < minDist then nearest = hrp; minDist = d end
                end
            end
            if nearest then root.CFrame = CFrame.lookAt(root.Position, Vector3.new(nearest.Position.X, root.Position.Y, nearest.Position.Z)) end
        end
    end

    -- 5. 实用功能
    if Config.Utility.Stamina then
        pcall(function()
            local systems = RS:FindFirstChild("Systems")
            local sprinting = systems and systems:FindFirstChild("Character") and systems.Character:FindFirstChild("Game") and systems.Character.Game:FindFirstChild("Sprinting")
            if sprinting then local m = require(sprinting); m.Stamina = m.MaxStamina; m.StaminaLoss = 0 end
        end)
    end
    if Config.Utility.AntiSlow then
        local sm = char:FindFirstChild("SpeedMultipliers")
        if sm then for _, v in ipairs(sm:GetChildren()) do if v:IsA("NumberValue") and v.Value < 1 then v.Value = 1 end end end
    end
    if Config.Utility.Noclip then for _, v in ipairs(char:GetChildren()) do if v:IsA("BasePart") then v.CanCollide = false end end end

    -- 6. 视觉功能
    if Config.Visual.Fullbright then Lighting.Ambient = c3rgb(255,255,255); Lighting.OutdoorAmbient = c3rgb(255,255,255); Lighting.GlobalShadows = false end
    if Config.Visual.NoFog then Lighting.FogEnd = math.huge; Lighting.FogStart = 0 end
end)

Library:Notify({Title = "QE V1", Description = "终极重构版已加载 | 全功能可用", Time = 5})
