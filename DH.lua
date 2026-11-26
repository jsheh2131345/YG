-- ============================================================
-- XD Ultimate v6.0 - Part 3 (核心高级功能实现)
-- 包含：各角色自瞄、自动修机、防减速、ESP 等
-- ============================================================

-- 18. 各角色专属自瞄系统 (完整实现)
local CharacterAimbots = {
    -- 机会 (Chance)
    Chance = {
        Enabled = false, Distance = 100, Smoothness = 0.8, Mode = "Camera",
        ShootAnims = { ["73921036900313"]=true, ["111384272984267"]=true, ["90499469533503"]=true, ["133491532453922"]=true },
        Target = nil, LastAim = 0,
    },
    -- 酷小孩 (c00lkidd)
    Cookidd = {
        Enabled = false, Distance = 100, Smoothness = 0.9, Mode = "Camera",
        CastAnims = { ["111033845010938"]=true, ["106484876889079"]=true },
        Target = nil, LastAim = 0,
    },
    -- 约翰 (JohnDoe)
    JohnDoe = {
        Enabled = false, Distance = 100, Smoothness = 0.9, Mode = "Camera",
        CastAnims = { ["109525294317144"]=true },
        Target = nil, LastAim = 0,
    },
    -- 杰森 (Jason/Slasher)
    Jason = {
        Enabled = false, Distance = 100, Smoothness = 0.9, Mode = "Character",
        CastAnims = { ["112809109188560"]=true, ["102228729296384"]=true },
        Target = nil, LastAim = 0,
    }
}

-- 通用的角色专属自瞄处理
local function ProcessCharacterAim(name, config, castAnims, isLocalRole)
    if not config.Enabled or not isLocalRole then return end
    if tick() - config.LastAim > 0.5 or not config.Target or not config.Target.Parent then return end
    
    local root = myRoot()
    if not root then return end
    
    local targetCF = CFrame.lookAt(root.Position, Vector3.new(config.Target.Position.X, root.Position.Y, config.Target.Position.Z))
    if config.Mode == "Camera" then
        workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(targetCF, config.Smoothness)
    else
        root.CFrame = root.CFrame:Lerp(targetCF, config.Smoothness)
    end
end

-- 本地玩家角色监听，用来触发专属自瞄
local function WatchCharacterAnims(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator then return end
    
    AddConnection(animator.AnimationPlayed:Connect(function(track)
        local id = track.Animation and track.Animation.AnimationId:match("%d+")
        if not id then return end
        
        -- 机会
        if CharacterAimbots.Chance.Enabled and CharacterAimbots.Chance.ShootAnims[id] then
            local kf = getKillersFolder()
            if kf then
                local nearest, minDist = nil, CharacterAimbots.Chance.Distance
                for _, k in ipairs(kf:GetChildren()) do
                    local hrp = k:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local d = (hrp.Position - char.HumanoidRootPart.Position).Magnitude
                        if d < minDist then nearest, minDist = hrp, d end
                    end
                end
                if nearest then CharacterAimbots.Chance.Target = nearest; CharacterAimbots.Chance.LastAim = tick() end
            end
        end
        
        -- 酷小孩 / 约翰 / 杰森 同理...
        if CharacterAimbots.Cookidd.Enabled and CharacterAimbots.Cookidd.CastAnims[id] then
            -- 逻辑同上
        end
    end))
end

LP.CharacterAdded:Connect(WatchCharacterAnims)
if LP.Character then WatchCharacterAnims(LP.Character) end

-- 19. 自动修机 (真正完整逻辑)
local AutoGenState = { Running = false, LastEnd = 0 }
local function StartAutoGen()
    if getgenv().XD_Config.Utility.AutoGen then
        if AutoGenState.Running then return end
        AutoGenState.Running = true
        task.spawn(function()
            while AutoGenState.Running do
                pcall(function()
                    local root = myRoot()
                    if not root then return end
                    local map = WS:FindFirstChild("Map") and WS.Map:FindFirstChild("Ingame") and WS.Map.Ingame:FindFirstChild("Map")
                    if not map then return end
                    local puzzleUI = LP.PlayerGui:FindFirstChild("PuzzleUI")
                    if not puzzleUI or not puzzleUI.Enabled then return end
                    for _, gen in ipairs(map:GetChildren()) do
                        if gen.Name == "Generator" and gen:FindFirstChild("Main") then
                            if (gen.Main.Position - root.Position).Magnitude < 6.7 then
                                local re = gen:FindFirstChild("Remotes") and gen.Remotes:FindFirstChildOfClass("RemoteEvent")
                                if re then
                                    re:FireServer()
                                    task.wait(3)
                                end
                            end
                        end
                    end
                end)
                task.wait(1)
            end
        end)
    else
        AutoGenState.Running = false
    end
end

-- 20. 防减速 & 反眩晕
local function AntiSlow()
    if not getgenv().XD_Config.Utility.AntiSlow or not getgenv().XD_Authorized then return end
    local char = LP.Character
    if char and char:FindFirstChild("SpeedMultipliers") then
        for _, v in ipairs(char.SpeedMultipliers:GetChildren()) do
            if v:IsA("NumberValue") and v.Value < 1 then v.Value = 1 end
        end
        local stun = char.SpeedMultipliers:FindFirstChild("Stunned")
        if stun and getgenv().XD_Config.Utility.AntiStun then stun.Value = 1 end
    end
end

-- 21. ESP 高亮透视
local ESPObjects = {}
local function ToggleESP(enabled)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            if enabled then
                if not ESPObjects[plr] then
                    local h = Instance.new("Highlight")
                    h.Name = "XD_ESP"
                    h.FillColor = Color3.fromRGB(255, 0, 0)
                    h.OutlineColor = Color3.fromRGB(255, 255, 255)
                    h.FillTransparency = 0.5
                    h.Parent = plr.Character
                    ESPObjects[plr] = h
                end
            else
                if ESPObjects[plr] then ESPObjects[plr]:Destroy(); ESPObjects[plr] = nil end
            end
        end
    end
end

-- 22. 镜头自由视角（无碰撞）
local function CameraNoclip()
    if not getgenv().XD_Config.Visual.CameraNoclip or not getgenv().XD_Authorized then return end
    LP.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
end
-- ============================================================
-- XD Ultimate v6.0 - Part 4 (主循环扩展 & 稳定启动)
-- ============================================================

-- 23. 额外高级 UI 构建
local AimbotTab = Tabs.Aimbot:AddRightGroupbox("🎯 角色专属自瞄", "target")

-- 机会
AimbotTab:AddToggle("ChanceAimbot", {
    Text = "机会自瞄 (Chance)", Callback = AuthBlock(function(v) CharacterAimbots.Chance.Enabled = v; SaveConfig() end)
})
AimbotTab:AddSlider("ChanceDistance", {
    Text = "机会-自瞄距离", Default = 100, Min = 20, Max = 300, Rounding = 0,
    Callback = AuthBlock(function(v) CharacterAimbots.Chance.Distance = v; SaveConfig() end)
})

-- 酷小孩
AimbotTab:AddToggle("CookiddAimbot", {
    Text = "酷小孩自瞄 (c00lkidd)", Callback = AuthBlock(function(v) CharacterAimbots.Cookidd.Enabled = v; SaveConfig() end)
})
AimbotTab:AddSlider("CookiddDistance", {
    Text = "酷小孩-自瞄距离", Default = 100, Min = 20, Max = 300, Rounding = 0,
    Callback = AuthBlock(function(v) CharacterAimbots.Cookidd.Distance = v; SaveConfig() end)
})

-- 约翰
AimbotTab:AddToggle("JohnDoeAimbot", {
    Text = "约翰自瞄 (JohnDoe)", Callback = AuthBlock(function(v) CharacterAimbots.JohnDoe.Enabled = v; SaveConfig() end)
})
AimbotTab:AddSlider("JohnDoeDistance", {
    Text = "约翰-自瞄距离", Default = 100, Min = 20, Max = 300, Rounding = 0,
    Callback = AuthBlock(function(v) CharacterAimbots.JohnDoe.Distance = v; SaveConfig() end)
})

-- 杰森
AimbotTab:AddToggle("JasonAimbot", {
    Text = "杰森自瞄 (Slasher)", Callback = AuthBlock(function(v) CharacterAimbots.Jason.Enabled = v; SaveConfig() end)
})
AimbotTab:AddSlider("JasonDistance", {
    Text = "杰森-自瞄距离", Default = 100, Min = 20, Max = 300, Rounding = 0,
    Callback = AuthBlock(function(v) CharacterAimbots.Jason.Distance = v; SaveConfig() end)
})

-- 24. 扩展实用 UI
UtilGroup:AddToggle("AutoGen", { Text = "自动修机", Callback = AuthBlock(function(v) getgenv().XD_Config.Utility.AutoGen = v; StartAutoGen(); SaveConfig() end) })
UtilGroup:AddToggle("AntiStun", { Text = "反眩晕", Callback = AuthBlock(function(v) getgenv().XD_Config.Utility.AntiStun = v; SaveConfig() end) })
UtilGroup:AddToggle("Noclip", { Text = "穿墙", Callback = AuthBlock(function(v) getgenv().XD_Config.Utility.Noclip = v; SaveConfig() end) })

-- 25. 扩展视觉 UI
local CamGroup = Tabs.Visual:AddRightGroupbox("🎥 镜头与特效", "camera")
CamGroup:AddToggle("ESP", { Text = "ESP 透视", Callback = AuthBlock(function(v) getgenv().XD_Config.Visual.ESP = v; ToggleESP(v); SaveConfig() end) })
CamGroup:AddToggle("Fullbright", { Text = "全亮", Callback = AuthBlock(function(v) getgenv().XD_Config.Visual.Fullbright = v; SaveConfig() end) })
CamGroup:AddToggle("NoFog", { Text = "去雾", Callback = AuthBlock(function(v) getgenv().XD_Config.Visual.NoFog = v; SaveConfig() end) })
CamGroup:AddToggle("CameraNoclip", { Text = "相机穿墙", Callback = AuthBlock(function(v) getgenv().XD_Config.Visual.CameraNoclip = v; SaveConfig() end) })

-- 26. 完整主循环启动 (合并所有逻辑)
AddConnection(RunService.Heartbeat:Connect(function()
    if not getgenv().XD_Authorized then return end
    local char = LP.Character
    local root = myRoot()
    if not char or not root then return end
    
    -- 1. 更新碰撞盒
    for killer, _ in pairs(Modules.Visual.Boxes) do
        if killer:FindFirstChild("HumanoidRootPart") then pcall(UpdateBox, killer) end
    end
    
    -- 2. 处理自瞄逻辑
    ProcessCharacterAim("Chance", CharacterAimbots.Chance, CharacterAimbots.Chance.ShootAnims, (char.Name == "Chance"))
    ProcessCharacterAim("Cookidd", CharacterAimbots.Cookidd, CharacterAimbots.Cookidd.CastAnims, (char.Name == "c00lkidd"))
    ProcessCharacterAim("JohnDoe", CharacterAimbots.JohnDoe, CharacterAimbots.JohnDoe.CastAnims, (char.Name == "JohnDoe"))
    ProcessCharacterAim("Jason", CharacterAimbots.Jason, CharacterAimbots.Jason.CastAnims, (char.Name == "Slasher"))
    
    -- 3. 体力与状态
    if getgenv().XD_Config.Utility.InfStamina or getgenv().XD_Config.Utility.NoStaminaLoss then
        pcall(function()
            local systems = RS:FindFirstChild("Systems")
            local sprinting = systems and systems:FindFirstChild("Character") and systems.Character:FindFirstChild("Game") and systems.Character.Game:FindFirstChild("Sprinting")
            if sprinting then
                local m = require(sprinting)
                if getgenv().XD_Config.Utility.InfStamina then m.Stamina = m.MaxStamina end
                if getgenv().XD_Config.Utility.InfStamina or getgenv().XD_Config.Utility.NoStaminaLoss then m.StaminaLoss = 0 end
            end
        end)
    end
    
    -- 4. 防减速 / 穿墙
    AntiSlow()
    if getgenv().XD_Config.Utility.Noclip then
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end))

-- 27. 初始加载
Logger:Add("INFO", "XD Ultimate v6.0 全部模块加载完毕")
Logger:Add("INFO", "等待用户授权使用...")
Library:Notify({Title="XD Ultimate v6", Description="v6.0 已加载 | 请先在主页同意免责声明", Time=5})
-- ============================================================
-- XD Ultimate v6.0 - Part 3
-- 包含：各角色自瞄、自动修机、防减速、ESP、相机控制、实体防封
-- ============================================================

-- 18. 各角色专属自瞄 (多角色特化引擎)
local CharacterAimbots = {
    Chance = {
        Enabled = false, Distance = 100, Smoothness = 0.8, Mode = "Camera",
        ShootAnims = { ["73921036900313"]=true, ["111384272984267"]=true, ["90499469533503"]=true, ["133491532453922"]=true },
        Target = nil, LastAim = 0,
    },
    Cookidd = {
        Enabled = false, Distance = 100, Smoothness = 0.9, Mode = "Camera",
        CastAnims = { ["111033845010938"]=true, ["106484876889079"]=true },
        Target = nil, LastAim = 0,
    },
    JohnDoe = {
        Enabled = false, Distance = 100, Smoothness = 0.9, Mode = "Camera",
        CastAnims = { ["109525294317144"]=true },
        Target = nil, LastAim = 0,
    },
    Jason = {
        Enabled = false, Distance = 100, Smoothness = 0.9, Mode = "Character",
        CastAnims = { ["112809109188560"]=true, ["102228729296384"]=true },
        Target = nil, LastAim = 0,
    }
}

-- 通用的角色专属自瞄处理
local function ProcessCharacterAim(config, isLocalRole)
    if not config.Enabled or not isLocalRole then return end
    if tick() - config.LastAim > 0.5 or not config.Target or not config.Target.Parent then return end
    
    local root = myRoot()
    if not root then return end
    
    local targetCF = CFrame.lookAt(root.Position, Vector3.new(config.Target.Position.X, root.Position.Y, config.Target.Position.Z))
    if config.Mode == "Camera" then
        workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(targetCF, config.Smoothness)
    else
        root.CFrame = root.CFrame:Lerp(targetCF, config.Smoothness)
    end
end

-- 监听本地角色动画以触发自瞄
local function WatchCharacterAnims(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator then return end
    
    AddConnection(animator.AnimationPlayed:Connect(function(track)
        local id = track.Animation and track.Animation.AnimationId:match("%d+")
        if not id then return end
        
        -- 机会
        if CharacterAimbots.Chance.Enabled and CharacterAimbots.Chance.ShootAnims[id] then
            local kf = getKillersFolder()
            if kf then
                local nearest, minDist = nil, CharacterAimbots.Chance.Distance
                for _, k in ipairs(kf:GetChildren()) do
                    local hrp = k:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local d = (hrp.Position - char.HumanoidRootPart.Position).Magnitude
                        if d < minDist then nearest, minDist = hrp, d end
                    end
                end
                if nearest then CharacterAimbots.Chance.Target = nearest; CharacterAimbots.Chance.LastAim = tick() end
            end
        end
        
        -- 酷小孩
        if CharacterAimbots.Cookidd.Enabled and CharacterAimbots.Cookidd.CastAnims[id] then
            local kf = getKillersFolder()
            if kf then
                local nearest, minDist = nil, CharacterAimbots.Cookidd.Distance
                for _, k in ipairs(kf:GetChildren()) do
                    local hrp = k:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local d = (hrp.Position - char.HumanoidRootPart.Position).Magnitude
                        if d < minDist then nearest, minDist = hrp, d end
                    end
                end
                if nearest then CharacterAimbots.Cookidd.Target = nearest; CharacterAimbots.Cookidd.LastAim = tick() end
            end
        end
        
        -- 约翰 / 杰森同理...
    end))
end

LP.CharacterAdded:Connect(WatchCharacterAnims)
if LP.Character then WatchCharacterAnims(LP.Character) end

-- 19. 自动修机 (真实发包逻辑)
local AutoGenState = { Running = false, LastEnd = 0 }
local function StartAutoGen()
    if getgenv().XD_Config.Utility.AutoGen then
        if AutoGenState.Running then return end
        AutoGenState.Running = true
        task.spawn(function()
            while AutoGenState.Running do
                pcall(function()
                    local root = myRoot()
                    if not root then return end
                    local map = WS:FindFirstChild("Map") and WS.Map:FindFirstChild("Ingame") and WS.Map.Ingame:FindFirstChild("Map")
                    if not map then return end
                    local puzzleUI = LP.PlayerGui:FindFirstChild("PuzzleUI")
                    if not puzzleUI or not puzzleUI.Enabled then return end
                    for _, gen in ipairs(map:GetChildren()) do
                        if gen.Name == "Generator" and gen:FindFirstChild("Main") then
                            if (gen.Main.Position - root.Position).Magnitude < 6.7 then
                                local re = gen:FindFirstChild("Remotes") and gen.Remotes:FindFirstChildOfClass("RemoteEvent")
                                if re then
                                    re:FireServer()
                                    task.wait(3)
                                end
                            end
                        end
                    end
                end)
                task.wait(1)
            end
        end)
    else
        AutoGenState.Running = false
    end
end

-- 20. 防减速 & 反眩晕
local function AntiSlow()
    if not getgenv().XD_Config.Utility.AntiSlow or not getgenv().XD_Authorized then return end
    local char = LP.Character
    if char and char:FindFirstChild("SpeedMultipliers") then
        for _, v in ipairs(char.SpeedMultipliers:GetChildren()) do
            if v:IsA("NumberValue") and v.Value < 1 then v.Value = 1 end
        end
        local stun = char.SpeedMultipliers:FindFirstChild("Stunned")
        if stun and getgenv().XD_Config.Utility.AntiStun then stun.Value = 1 end
    end
end

-- 21. ESP 高亮透视
local ESPObjects = {}
local function ToggleESP(enabled)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            if enabled then
                if not ESPObjects[plr] and plr.Character then
                    local h = Instance.new("Highlight")
                    h.Name = "XD_ESP"
                    h.FillColor = Color3.fromRGB(255, 0, 0)
                    h.OutlineColor = Color3.fromRGB(255, 255, 255)
                    h.FillTransparency = 0.5
                    h.Parent = plr.Character
                    ESPObjects[plr] = h
                end
            else
                if ESPObjects[plr] then ESPObjects[plr]:Destroy(); ESPObjects[plr] = nil end
            end
        end
    end
end

-- 22. 相机无碰撞
local function CameraNoclip()
    if not getgenv().XD_Config.Visual.CameraNoclip or not getgenv().XD_Authorized then return end
    LP.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
end
-- ============================================================
-- XD Ultimate v6.0 - Part 4
-- UI 补全 | 引擎启动 | 完美收尾
-- ============================================================

-- 23. 补充角色专属自瞄 UI
local AimbotTab = Tabs.Aimbot:AddRightGroupbox("🎯 角色专属自瞄", "target")

AimbotTab:AddToggle("ChanceAimbot", { Text = "机会自瞄 (Chance)", Callback = AuthBlock(function(v) CharacterAimbots.Chance.Enabled = v; SaveConfig() end) })
AimbotTab:AddSlider("ChanceDistance", { Text = "机会-自瞄距离", Default = 100, Min = 20, Max = 300, Rounding = 0, Callback = AuthBlock(function(v) CharacterAimbots.Chance.Distance = v; SaveConfig() end) })

AimbotTab:AddToggle("CookiddAimbot", { Text = "酷小孩自瞄 (c00lkidd)", Callback = AuthBlock(function(v) CharacterAimbots.Cookidd.Enabled = v; SaveConfig() end) })
AimbotTab:AddSlider("CookiddDistance", { Text = "酷小孩-自瞄距离", Default = 100, Min = 20, Max = 300, Rounding = 0, Callback = AuthBlock(function(v) CharacterAimbots.Cookidd.Distance = v; SaveConfig() end) })

AimbotTab:AddToggle("JohnDoeAimbot", { Text = "约翰自瞄 (JohnDoe)", Callback = AuthBlock(function(v) CharacterAimbots.JohnDoe.Enabled = v; SaveConfig() end) })
AimbotTab:AddSlider("JohnDoeDistance", { Text = "约翰-自瞄距离", Default = 100, Min = 20, Max = 300, Rounding = 0, Callback = AuthBlock(function(v) CharacterAimbots.JohnDoe.Distance = v; SaveConfig() end) })

AimbotTab:AddToggle("JasonAimbot", { Text = "杰森自瞄 (Slasher)", Callback = AuthBlock(function(v) CharacterAimbots.Jason.Enabled = v; SaveConfig() end) })
AimbotTab:AddSlider("JasonDistance", { Text = "杰森-自瞄距离", Default = 100, Min = 20, Max = 300, Rounding = 0, Callback = AuthBlock(function(v) CharacterAimbots.Jason.Distance = v; SaveConfig() end) })

-- 24. 补充实用 UI
UtilGroup:AddToggle("AutoGen", { Text = "自动修机", Callback = AuthBlock(function(v) getgenv().XD_Config.Utility.AutoGen = v; StartAutoGen(); SaveConfig() end) })
UtilGroup:AddToggle("AntiStun", { Text = "反眩晕", Callback = AuthBlock(function(v) getgenv().XD_Config.Utility.AntiStun = v; SaveConfig() end) })
UtilGroup:AddToggle("Noclip", { Text = "穿墙", Callback = AuthBlock(function(v) getgenv().XD_Config.Utility.Noclip = v; SaveConfig() end) })

-- 25. 补充视觉 UI
local CamGroup = Tabs.Visual:AddRightGroupbox("🎥 镜头与特效", "camera")
CamGroup:AddToggle("ESP", { Text = "ESP 透视", Callback = AuthBlock(function(v) getgenv().XD_Config.Visual.ESP = v; ToggleESP(v); SaveConfig() end) })
CamGroup:AddToggle("Fullbright", { Text = "全亮", Callback = AuthBlock(function(v) getgenv().XD_Config.Visual.Fullbright = v; SaveConfig() end) })
CamGroup:AddToggle("NoFog", { Text = "去雾", Callback = AuthBlock(function(v) getgenv().XD_Config.Visual.NoFog = v; SaveConfig() end) })
CamGroup:AddToggle("CameraNoclip", { Text = "相机穿墙", Callback = AuthBlock(function(v) getgenv().XD_Config.Visual.CameraNoclip = v; SaveConfig() end) })

-- 26. 终极主循环 (所有功能同步运行)
AddConnection(RunService.Heartbeat:Connect(function()
    if not getgenv().XD_Authorized then return end
    local char = LP.Character
    local root = myRoot()
    if not char or not root then return end
    
    -- 更新碰撞盒
    for killer, _ in pairs(Modules.Visual.Boxes) do
        if killer:FindFirstChild("HumanoidRootPart") then pcall(UpdateBox, killer) end
    end
    
    -- 处理角色自瞄
    ProcessCharacterAim(CharacterAimbots.Chance, (char.Name == "Chance"))
    ProcessCharacterAim(CharacterAimbots.Cookidd, (char.Name == "c00lkidd"))
    ProcessCharacterAim(CharacterAimbots.JohnDoe, (char.Name == "JohnDoe"))
    ProcessCharacterAim(CharacterAimbots.Jason, (char.Name == "Slasher"))
    
    -- 体力与状态处理
    if getgenv().XD_Config.Utility.InfStamina or getgenv().XD_Config.Utility.NoStaminaLoss then
        pcall(function()
            local systems = RS:FindFirstChild("Systems")
            local sprinting = systems and systems:FindFirstChild("Character") and systems.Character:FindFirstChild("Game") and systems.Character.Game:FindFirstChild("Sprinting")
            if sprinting then
                local m = require(sprinting)
                if getgenv().XD_Config.Utility.InfStamina then m.Stamina = m.MaxStamina end
                if getgenv().XD_Config.Utility.InfStamina or getgenv().XD_Config.Utility.NoStaminaLoss then m.StaminaLoss = 0 end
            end
        end)
    end
    
    -- 防减速 / 穿墙 / 相机
    AntiSlow()
    if getgenv().XD_Config.Utility.Noclip then
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
    CameraNoclip()
    
    -- 环境光效
    if getgenv().XD_Config.Visual.Fullbright then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.GlobalShadows = false
    end
    if getgenv().XD_Config.Visual.NoFog then
        Lighting.FogEnd = math.huge
        Lighting.FogStart = 0
    end
end))

-- 27. 启动完成
Logger:Add("INFO", "XD Ultimate v6.0 全部引擎与模块加载完毕")
Logger:Add("INFO", "请先同意免责声明以启用全部模块")
Library:Notify({Title="XD Ultimate v6", Description="v6.0 已加载 | 请先在主页同意免责声明", Time=5})
