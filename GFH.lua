-- ========================================
-- GFH Delta优化版
-- 作者：石头
-- 适配：Forsaken（被遗弃）
-- ========================================

local repo = 'https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor = true
Library.NotifySide = "Right"

local Window = Library:CreateWindow({
    Title = 'GFH',
    Footer = "石头",
    Icon = "rbxassetid://4483362748",
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = true,
    NotifySide = "Right",
    TabPadding = 8,
    MenuFadeTime = 0
})

local Tabs = {
    Main = Window:AddTab('功能', 'house'),
    Info = Window:AddTab('信息', 'info'),
    ["UI设置"] = Window:AddTab('UI设置', 'settings')
}

local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")
local ws = game:GetService("Workspace")
local uis = game:GetService("UserInputService")
local rs = game:GetService("ReplicatedStorage")
local lighting = game:GetService("Lighting")
local cam = ws.CurrentCamera

local features = {
    noStun = {enabled = false},
    speedBoost = {enabled = false, value = 1},
    speed = {enabled = true},
    noclip = {enabled = true, running = nil},
    nightVision = {enabled = true},
    infiniteHealth = {enabled = true, running = nil},
    stepFly = {enabled = false, running = nil},
    newFly = {enabled = false, running = nil},
    jumpUnlock = {enabled = false},
    autoFlyUp = {enabled = false, running = nil},
    infiniteStamina = {enabled = false, running = nil},
    speedMultiplier = {enabled = false, value = 1},
    aimbot = {enabled = false, running = nil},
    fullbright = {enabled = false},
    noFog = {enabled = false},
    globalShadows = {enabled = false},
    fov = {enabled = false, value = 70}
}

-- ============================================
-- 夜视
-- ============================================
local function applyNightVision()
    if features.nightVision.enabled then
        lighting.Ambient = Color3.fromRGB(255, 255, 255)
        lighting.Brightness = 2
        lighting.ClockTime = 12
        lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        lighting.GlobalShadows = false
        lighting.FogEnd = 1000
        for _, s in ipairs(lighting:GetDescendants()) do
            if s:IsA("Shadow") or s:IsA("BlurEffect") or s:IsA("BloomEffect") then
                s.Enabled = false
            end
        end
    else
        lighting.Ambient = Color3.fromRGB(0, 0, 0)
        lighting.Brightness = 1
        lighting.ClockTime = 0
        lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
        lighting.GlobalShadows = true
        lighting.FogEnd = 10000
        for _, s in ipairs(lighting:GetDescendants()) do
            if s:IsA("Shadow") or s:IsA("BlurEffect") or s:IsA("BloomEffect") then
                s.Enabled = true
            end
        end
    end
end

-- ============================================
-- 全亮
-- ============================================
local function applyFullbright()
    if features.fullbright.enabled then
        lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        lighting.Brightness = 2
        lighting.GlobalShadows = not features.globalShadows.enabled
        if features.noFog.enabled then
            lighting.FogStart = 0
            lighting.FogEnd = math.huge
            local fog = lighting:FindFirstChildOfClass("Atmosphere")
            if fog then fog.Density = 0 end
        end
    else
        lighting.OutdoorAmbient = Color3.fromRGB(55, 55, 55)
        lighting.Brightness = 0
        lighting.GlobalShadows = true
    end
end

-- ============================================
-- 超级速度
-- ============================================
local function applySpeed()
    if features.speed.enabled then
        hum.WalkSpeed = 80
        hum.JumpPower = 150
    else
        hum.WalkSpeed = 16
        hum.JumpPower = 50
    end
end

-- ============================================
-- 穿墙
-- ============================================
local function applyNoclip()
    if not features.noclip.enabled then
        if features.noclip.running then
            task.cancel(features.noclip.running)
            features.noclip.running = nil
        end
        if root then root.CanCollide = true end
        return
    end
    if features.noclip.running then return end
    features.noclip.running = task.spawn(function()
        while features.noclip.enabled do
            if char and root then
                root.CanCollide = false
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
            task.wait(0.15)
        end
    end)
end

-- ============================================
-- 无限血量
-- ============================================
local function applyInfiniteHealth()
    if not features.infiniteHealth.enabled then
        if features.infiniteHealth.running then
            task.cancel(features.infiniteHealth.running)
            features.infiniteHealth.running = nil
        end
        return
    end
    if features.infiniteHealth.running then return end
    features.infiniteHealth.running = task.spawn(function()
        while features.infiniteHealth.enabled do
            pcall(function()
                if hum then
                    hum.Health = hum.MaxHealth
                    hum.BreakJointsOnDeath = false
                end
            end)
            task.wait(0.05)
        end
    end)
end

-- ============================================
-- 无限体力
-- ============================================
local function applyInfiniteStamina()
    if not features.infiniteStamina.enabled then
        if features.infiniteStamina.running then
            task.cancel(features.infiniteStamina.running)
            features.infiniteStamina.running = nil
        end
        return
    end
    if features.infiniteStamina.running then return end
    features.infiniteStamina.running = task.spawn(function()
        while features.infiniteStamina.enabled do
            pcall(function()
                local st = char:FindFirstChild("体力值") or char:FindFirstChild("体力") or char:FindFirstChild("耐力值")
                if st and (st:IsA("NumberValue") or st:IsA("IntValue")) then st.Value = 100 end
            end)
            task.wait(0.05)
        end
    end)
end

-- ============================================
-- 速度倍率
-- ============================================
local function applySpeedMultiplier()
    if not features.speedMultiplier.enabled then
        hum.WalkSpeed = 16
        return
    end
    local mult = features.speedMultiplier.value or 1
    hum.WalkSpeed = 16 * mult
    if hum.WalkSpeed > 800 then hum.WalkSpeed = 800 end
end

-- ============================================
-- 自瞄
-- ============================================
local function applyAimbot()
    if not features.aimbot.enabled then
        if features.aimbot.running then
            task.cancel(features.aimbot.running)
            features.aimbot.running = nil
        end
        return
    end
    if features.aimbot.running then return end
    features.aimbot.running = task.spawn(function()
        while features.aimbot.enabled do
            pcall(function()
                local near = nil
                local nearDist = math.huge
                local killers = ws:FindFirstChild("Players") and ws.Players:FindFirstChild("Killers")
                if killers then
                    for _, k in ipairs(killers:GetChildren()) do
                        local hrp = k:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local d = (root.Position - hrp.Position).Magnitude
                            if d < nearDist then
                                nearDist = d
                                near = hrp
                            end
                        end
                    end
                end
                if near and nearDist < 50 then
                    cam.CFrame = CFrame.new(cam.CFrame.Position, near.Position - Vector3.new(0, 0.5, 0))
                end
            end)
            task.wait()
        end
    end)
end

-- ============================================
-- 踏空而行
-- ============================================
local function applyStepFly()
    if not features.stepFly.enabled then
        if features.stepFly.running then
            task.cancel(features.stepFly.running)
            features.stepFly.running = nil
        end
        return
    end
    if features.stepFly.running then return end
    features.stepFly.running = task.spawn(function()
        while features.stepFly.enabled do
            pcall(function()
                if root then
                    local v = root.Velocity
                    if v.Y < 0 then root.Velocity = Vector3.new(v.X, 0, v.Z) end
                end
            end)
            task.wait()
        end
    end)
end

-- ============================================
-- 自动飞升
-- ============================================
local function applyAutoFlyUp()
    if not features.autoFlyUp.enabled then
        if features.autoFlyUp.running then
            task.cancel(features.autoFlyUp.running)
            features.autoFlyUp.running = nil
        end
        return
    end
    if features.autoFlyUp.running then return end
    features.autoFlyUp.running = task.spawn(function()
        while features.autoFlyUp.enabled do
            pcall(function()
                if root and cam then
                    local look = cam.CFrame.LookVector
                    if look.Y > 0.5 then
                        root.Velocity = Vector3.new(root.Velocity.X, look.Y * 30, root.Velocity.Z)
                    end
                end
            end)
            task.wait()
        end
    end)
end

-- ============================================
-- 新飞天
-- ============================================
local function applyNewFly()
    if not features.newFly.enabled then
        if features.newFly.running then
            task.cancel(features.newFly.running)
            features.newFly.running = nil
        end
        if hum then hum.PlatformStand = false end
        return
    end
    if features.newFly.running then return end
    if not char then return end
    local r = root
    if not r then return end

    hum.PlatformStand = true
    local bv = Instance.new("BodyVelocity")
    bv.Parent = r
    bv.MaxForce = Vector3.new(4000, 4000, 4000)
    bv.Velocity = Vector3.new(0, 0, 0)

    features.newFly.running = task.spawn(function()
        while features.newFly.enabled and r do
            local fwd = cam.CFrame.LookVector
            local right = cam.CFrame.RightVector
            local up = cam.CFrame.UpVector
            local vel = Vector3.new(0, 0, 0)

            if uis:IsKeyDown(Enum.KeyCode.W) then vel = vel + fwd * 50 end
            if uis:IsKeyDown(Enum.KeyCode.S) then vel = vel - fwd * 50 end
            if uis:IsKeyDown(Enum.KeyCode.A) then vel = vel - right * 50 end
            if uis:IsKeyDown(Enum.KeyCode.D) then vel = vel + right * 50 end
            if uis:IsKeyDown(Enum.KeyCode.Space) then vel = vel + up * 50 end
            if uis:IsKeyDown(Enum.KeyCode.LeftShift) then vel = vel - up * 50 end

            bv.Velocity = vel
            task.wait()
        end
    end)
end

-- ============================================
-- 解锁跳跃
-- ============================================
local function applyJumpUnlock()
    if features.jumpUnlock.enabled then
        hum.JumpPower = 150
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
    else
        hum.JumpPower = 50
    end
end

-- ============================================
-- 视野
-- ============================================
local function applyFOV()
    if features.fov.enabled then
        workspace.Camera.FieldOfView = features.fov.value
    else
        workspace.Camera.FieldOfView = 70
    end
end

-- ============================================
-- 去除减速
-- ============================================
local function applyNoStun()
    if features.noStun.enabled then
        hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if hum.WalkSpeed < 16 then
                hum.WalkSpeed = 16
            end
        end)
    end
end

-- ============================================
-- 激活速度
-- ============================================
local function applySpeedBoost()
    if features.speedBoost.enabled then
        local boost = features.speedBoost.value or 1
        root.CFrame = root.CFrame + hum.MoveDirection * boost
        root.CanCollide = true
    end
end

-- ============================================
-- 应用全部
-- ============================================
local function applyAll()
    pcall(applySpeed)
    pcall(applyNoclip)
    pcall(applyNightVision)
    pcall(applyInfiniteHealth)
    pcall(applyInfiniteStamina)
    pcall(applySpeedMultiplier)
    pcall(applyAimbot)
    pcall(applyStepFly)
    pcall(applyAutoFlyUp)
    pcall(applyNewFly)
    pcall(applyJumpUnlock)
    pcall(applyFullbright)
    pcall(applyFOV)
    pcall(applyNoStun)
end

player.CharacterAdded:Connect(function(newChar)
    char = newChar
    root = char:WaitForChild("HumanoidRootPart")
    hum = char:WaitForChild("Humanoid")
    task.wait(0.5)
    applyAll()
end)

applyAll()

-- ============================================
-- UI
-- ============================================
local Main = Tabs.Main:AddLeftGroupbox("核心功能")

Main:AddToggle("NoStunToggle", {
    Text = "去除减速",
    Default = false,
    Callback = function(v)
        features.noStun.enabled = v
        pcall(applyNoStun)
    end
})

Main:AddSlider("SpeedBoostSlider", {
    Text = "速度调节",
    Min = 0,
    Max = 3,
    Default = 1,
    Compact = true,
    Rounding = 1,
    Callback = function(v)
        features.speedBoost.value = v
    end
})

Main:AddToggle("SpeedBoostToggle", {
    Text = "激活速度",
    Default = false,
    Callback = function(v)
        features.speedBoost.enabled = v
        if v then
            task.spawn(function()
                while features.speedBoost.enabled do
                    pcall(applySpeedBoost)
                    task.wait()
                end
            end)
        end
    end
})

Main:AddToggle("SpeedToggle", {
    Text = "超级速度",
    Default = true,
    Callback = function(v)
        features.speed.enabled = v
        pcall(applySpeed)
    end
})

Main:AddToggle("NoclipToggle", {
    Text = "穿墙",
    Default = true,
    Callback = function(v)
        features.noclip.enabled = v
        pcall(applyNoclip)
    end
})

Main:AddToggle("NightVisionToggle", {
    Text = "夜视",
    Default = true,
    Callback = function(v)
        features.nightVision.enabled = v
        pcall(applyNightVision)
    end
})

Main:AddToggle("HealthToggle", {
    Text = "无限血量",
    Default = true,
    Callback = function(v)
        features.infiniteHealth.enabled = v
        pcall(applyInfiniteHealth)
    end
})

Main:AddToggle("StaminaToggle", {
    Text = "无限体力",
    Default = false,
    Callback = function(v)
        features.infiniteStamina.enabled = v
        pcall(applyInfiniteStamina)
    end
})

Main:AddToggle("StepFlyToggle", {
    Text = "踏空而行",
    Default = false,
    Callback = function(v)
        features.stepFly.enabled = v
        pcall(applyStepFly)
    end
})

Main:AddToggle("AutoFlyUpToggle", {
    Text = "自动飞升",
    Default = false,
    Callback = function(v)
        features.autoFlyUp.enabled = v
        pcall(applyAutoFlyUp)
    end
})

Main:AddToggle("NewFlyToggle", {
    Text = "新飞天",
    Default = false,
    Callback = function(v)
        features.newFly.enabled = v
        pcall(applyNewFly)
    end
})

Main:AddToggle("JumpUnlockToggle", {
    Text = "解锁跳跃",
    Default = false,
    Callback = function(v)
        features.jumpUnlock.enabled = v
        pcall(applyJumpUnlock)
    end
})

Main:AddSlider("SpeedMultiplierSlider", {
    Text = "速度倍率",
    Min = 1,
    Max = 50,
    Default = 1,
    Compact = true,
    Rounding = 1,
    Callback = function(v)
        features.speedMultiplier.value = v
        features.speedMultiplier.enabled = true
        pcall(applySpeedMultiplier)
    end
})

Main:AddToggle("AimbotToggle", {
    Text = "自瞄",
    Default = false,
    Callback = function(v)
        features.aimbot.enabled = v
        pcall(applyAimbot)
    end
})

-- ============================================
-- 音乐功能
-- ============================================
local MusicIds = {
    "109842476936999",
    "76280794937714",
}

local CurrentMusic = nil

local function PlayRandomMusic()
    if CurrentMusic then
        pcall(function() CurrentMusic:Destroy() end)
        CurrentMusic = nil
    end

    local id = MusicIds[math.random(1, #MusicIds)]
    local fullId = "rbxassetid://" .. id

    local sound = Instance.new("Sound")
    sound.Name = "GFH_Music"
    sound.SoundId = fullId
    sound.Volume = 1
    sound.Looped = false
    sound.Parent = workspace

    pcall(function() sound:Play() end)
    CurrentMusic = sound

    Library:Notify({
        Title = "GFH 音乐",
        Content = "正在播放: " .. id,
        Time = 3,
    })

    sound.Ended:Connect(function()
        if CurrentMusic == sound then
            sound:Destroy()
            CurrentMusic = nil
        end
    end)
end

Main:AddButton({
    Text = "播放音乐",
    Callback = function()
        pcall(PlayRandomMusic)
    end,
})

Main:AddButton({
    Text = "停止音乐",
    Callback = function()
        if CurrentMusic then
            pcall(function() CurrentMusic:Destroy() end)
            CurrentMusic = nil
            Library:Notify({
                Title = "GFH 音乐",
                Content = "已停止",
                Time = 2,
            })
        end
    end,
})

-- ============================================
-- 环境
-- ============================================
local Env = Tabs.Main:AddRightGroupbox("环境")

Env:AddSlider("BrightnessSlider", {
    Text = "亮度",
    Min = 0,
    Max = 3,
    Default = 0,
    Rounding = 1,
    Compact = true,
    Callback = function(v)
        features.brightness = v
        if features.fullbright.enabled then
            pcall(applyFullbright)
        end
    end
})

Env:AddToggle("GlobalShadowsToggle", {
    Text = "无阴影",
    Default = false,
    Callback = function(v)
        features.globalShadows.enabled = v
        if features.fullbright.enabled then
            pcall(applyFullbright)
        end
    end
})

Env:AddToggle("NoFogToggle", {
    Text = "除雾",
    Default = false,
    Callback = function(v)
        features.noFog.enabled = v
        if features.fullbright.enabled then
            pcall(applyFullbright)
        end
    end
})

Env:AddToggle("FullbrightToggle", {
    Text = "启用全亮",
    Default = false,
    Callback = function(v)
        features.fullbright.enabled = v
        pcall(applyFullbright)
    end
})

-- ============================================
-- 视野
-- ============================================
local Fov = Tabs.Main:AddRightGroupbox("视野")

Fov:AddSlider("FOVSlider", {
    Text = "视野范围",
    Min = 70,
    Max = 120,
    Default = 70,
    Rounding = 1,
    Compact = true,
    Callback = function(v)
        features.fov.value = v
        if features.fov.enabled then
            pcall(applyFOV)
        end
    end
})

Fov:AddToggle("FOVToggle", {
    Text = "启用视野",
    Default = false,
    Callback = function(v)
        features.fov.enabled = v
        pcall(applyFOV)
    end
})

-- ============================================
-- 信息
-- ============================================
local Info = Tabs.Info:AddLeftGroupbox("版本信息")
Info:AddLabel("版本: GFH Delta优化版")
Info:AddLabel("作者: 石头")
Info:AddLabel("适配: Forsaken (被遗弃)")
Info:AddLabel("状态: ✅ 稳定")

-- ============================================
-- UI 设置
-- ============================================
local UI = Tabs["UI设置"]:AddLeftGroupbox("UI设置")
UI:AddButton({
    Text = "切换UI",
    Callback = function()
        Window:Close()
    end
})

ThemeManager:SetTheme("Dark")
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
ThemeManager:SetLibrary(Library)
SaveManager:Load()
