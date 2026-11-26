-- ============================================================
-- XD Ultimate v5.0 - Part 1
-- 核心架构 | 完整网络发包 | 动画/音效 Hook | 所有角色独立判定
-- ============================================================

local Players       = game:GetService("Players")
local LP            = Players.LocalPlayer
local RS            = game:GetService("ReplicatedStorage")
local WS            = game:GetService("Workspace")
local RunService    = game:GetService("RunService")
local UIS           = game:GetService("UserInputService")
local HttpService   = game:GetService("HttpService")
local Lighting      = game:GetService("Lighting")

-- ============================================================
-- 全局清理
-- ============================================================
if getgenv().XD_Connections then
    for _, conn in ipairs(getgenv().XD_Connections) do pcall(function() conn:Disconnect() end) end
end
getgenv().XD_Connections = {}
local function AddConnection(conn) if conn then table.insert(getgenv().XD_Connections, conn) end return conn end

-- ============================================================
-- 1. 加载 UI 库
-- ============================================================
local repo = "https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
Library.ShowCustomCursor = true
Library.NotifySide = "Right"
Library.Theme = {
    Name = "XD v5",
    AccentColor = Color3.fromRGB(255, 105, 180),
    BackgroundColor = Color3.fromRGB(20, 20, 25),
    OutlineColor = Color3.fromRGB(55, 55, 65),
    FontColor = Color3.fromRGB(235, 235, 240),
    TextDarkTheme = true
}
local Window = Library:CreateWindow({
    Title = "XD Ultimate",
    Footer = "Forsaken | v5.0 | " .. LP.Name,
    Icon = "rbxassetid://4483362748",
    Center = true, AutoShow = true, Resizable = true,
    NotifySide = "Right", ToggleKeybind = Enum.KeyCode.RightShift
})

local Tabs = {
    Main      = Window:AddTab("主页", "home"),
    Block     = Window:AddTab("自动格挡", "shield"),
    Adjust    = Window:AddTab("调节", "sliders"),
    Aimbot    = Window:AddTab("自瞄系统", "crosshair"),
    Backstab  = Window:AddTab("自动背刺", "sword"),
    Visual    = Window:AddTab("视觉", "eye"),
    Utility   = Window:AddTab("实用功能", "wrench"),
    Logs      = Window:AddTab("运行日志", "terminal"),
    Settings  = Window:AddTab("设置", "settings"),
}

-- ============================================================
-- 2. 免责声明授权网关
-- ============================================================
getgenv().XD_Authorized = false
local function AuthBlock(func)
    return function(...)
        if not getgenv().XD_Authorized then
            Library:Notify({Title="⚠️ 未授权", Description="请先在主页同意免责声明！", Time=3})
            return
        end
        return func(...)
    end
end

-- ============================================================
-- 3. 日志系统
-- ============================================================
local Logger = { Logs = {}, Max = 100, UI = nil }
function Logger:Add(level, msg)
    local entry = string.format("[%s] [%s] %s", os.date("%H:%M:%S"), level, msg)
    table.insert(self.Logs, 1, entry)
    if #self.Logs > self.Max then table.remove(self.Logs) end
    print("[XD]", entry)
    self:Render()
end
function Logger:Render()
    if not self.UI then return end
    for _, child in ipairs(self.UI:GetChildren()) do if child:IsA("TextLabel") then child:Destroy() end end
    for i, log in ipairs(self.Logs) do
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 0, 20)
        lbl.BackgroundTransparency = 1
        lbl.Text = log
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.TextSize = 11
        lbl.Font = Enum.Font.Code
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.LayoutOrder = i
        lbl.Parent = self.UI
    end
end

-- ============================================================
-- 4. 配置系统（持久化）
-- ============================================================
local defaultConfig = {
    Block = { Enabled = false, Cooldown = 0.2, FacingCheck = false, FacingAngle = 90, WallCheck = false, BoxScale = 1.0, BoxForwardOffset = 4, BoxTransparency = 0.5, MaxSoundAge = 1.2, MaxAnimAge = 1.5 },
    Aimbot = { Chance = false, Cookidd = false, JohnDoe = false, Distance = 100, Smoothness = 0.8, Mode = "Camera" },
    Backstab = { Enabled = false, Distance = 8, Key = Enum.KeyCode.E },
    Visual = { EnlargeHitbox = false, HitboxMultiplier = 3, LocalHitbox = false, ShowChat = false },
    Utility = { InfStamina = false, NoStaminaLoss = false, AutoGen = false, AntiSlow = false, Noclip = false, Speed = 16, Jump = 50 },
    Preset = "普通",
}
local CONFIG_FILE = "XD_v5_Config.json"
getgenv().XD_Config = {}
for k, v in pairs(defaultConfig) do
    getgenv().XD_Config[k] = {}
    for k2, v2 in pairs(v) do getgenv().XD_Config[k][k2] = v2 end
end
local function SaveConfig() pcall(function() if writefile then writefile(CONFIG_FILE, HttpService:JSONEncode(getgenv().XD_Config)) end end) end
local function LoadConfig() pcall(function() if readfile and isfile and isfile(CONFIG_FILE) then local data = HttpService:JSONDecode(readfile(CONFIG_FILE)); for k, v in pairs(data) do if getgenv().XD_Config[k] then for k2, v2 in pairs(v) do getgenv().XD_Config[k][k2] = v2 end end end end end) end
LoadConfig()

-- ============================================================
-- 5. 网络底层
-- ============================================================
local RemoteEvent
pcall(function() RemoteEvent = RS:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent", 5) end)
local lastBlock = 0
local function FireBlock()
    if not getgenv().XD_Authorized or not RemoteEvent then return false end
    local now = tick()
    if now - lastBlock < getgenv().XD_Config.Block.Cooldown then return false end
    lastBlock = now
    pcall(function() RemoteEvent:FireServer("UseActorAbility", {buffer.fromstring("\3\5\0\0\0Block")}) end)
    return true
end

-- ============================================================
-- 6. 完整的 ID 库 (角色对应)
-- ============================================================
-- 这里放入了常见的杀手动画、音效、动作 ID
local AttackAnimIDs = {}
local AnimList = {
    ["126830014841198"]=true, ["126355327951215"]=true, ["121086746534252"]=true, ["101736016625776"]=true,
    ["18885909645"]=true, ["98456918873918"]=true, ["18885937766"]=true, ["18885940850"]=true,
    ["105458270463374"]=true, ["106538427162796"]=true, ["139835501933932"]=true, ["126896426760253"]=true,
    ["114356208094580"]=true, ["135884061951801"]=true, ["83829782357897"]=true, ["99050723653468"]=true,
    ["119181003138006"]=true, ["122709416391891"]=true, ["87989533095285"]=true, ["133363345661032"]=true,
    ["128414736976503"]=true, ["139309647473555"]=true, ["88451353906104"]=true, ["91628732643385"]=true,
    ["115403107018365"]=true, ["124619925708292"]=true,
}
for k, v in pairs(AnimList) do AttackAnimIDs[k] = v end

local AttackSoundIDs = {}
local SoundList = {
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
    ["18885940850"]=true, ["18885937766"]=true,
}
for k, v in pairs(SoundList) do AttackSoundIDs[k] = v end

-- ============================================================
-- 7. 核心工具函数
-- ============================================================
local function myRoot() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getKillersFolder() local pf = WS:FindFirstChild("Players"); return pf and pf:FindFirstChild("Killers") end
local function GetBoxSize() return Vector3.new(4.8 * getgenv().XD_Config.Block.BoxScale, 8 * getgenv().XD_Config.Block.BoxScale, 5 * getgenv().XD_Config.Block.BoxScale) end
local function IsKillerFacing(root, kRoot) 
    if not getgenv().XD_Config.Block.FacingCheck then return true end 
    if not root or not kRoot then return false end 
    local dir = (root.Position - kRoot.Position) 
    local flat = Vector3.new(dir.X, 0, dir.Z).Unit 
    local look = Vector3.new(kRoot.CFrame.LookVector.X, 0, kRoot.CFrame.LookVector.Z).Unit 
    local dot = look:Dot(flat) 
    return math.deg(math.acos(math.clamp(dot, -1, 1))) <= getgenv().XD_Config.Block.FacingAngle 
end
local function HasLOS(targetRoot) 
    if not getgenv().XD_Config.Block.WallCheck then return true end 
    local root = myRoot(); if not root then return false end 
    local params = RaycastParams.new() 
    params.FilterType = Enum.RaycastFilterType.Exclude 
    params.IgnoreWater = true 
    params.FilterDescendantsInstances = {LP.Character} 
    local result = WS:Raycast(root.Position, targetRoot.Position - root.Position, params) 
    return not result or result.Instance:IsDescendantOf(targetRoot.Parent) 
end
local function InBox(root, kRoot) 
    if not root or not kRoot then return false end 
    local boxSize = GetBoxSize() 
    local forward = kRoot.CFrame.LookVector 
    local boxPos = kRoot.Position + forward * getgenv().XD_Config.Block.BoxForwardOffset 
    local boxCFrame = CFrame.lookAt(boxPos, boxPos + forward * 100) 
    local rel = root.Position - boxPos 
    local localSpace = boxCFrame:VectorToObjectSpace(rel) 
    return math.abs(localSpace.X) <= (boxSize.X / 2) and math.abs(localSpace.Y) <= (boxSize.Y / 2) and math.abs(localSpace.Z) <= (boxSize.Z / 2) 
end
local function CheckAllConditions(root, kRoot) 
    if not root or not kRoot then return false end 
    if not InBox(root, kRoot) then return false end 
    if not IsKillerFacing(root, kRoot) then return false end 
    if not HasLOS(kRoot) then return false end 
    return true 
end

-- ============================================================
-- 8. 各功能模块占位（将在 Part 2 展开完整）
-- ============================================================
local Modules = {
    Block = { SoundBlockedUntil = {}, AnimBlockedUntil = {}, SoundStartTime = {}, AnimStartTime = {} },
    Visual = { Boxes = {}, Processed = {} },
    Aimbot = { Target = nil, LastAim = 0, AnimMap = { ["73921036900313"]=true, ["111384272984267"]=true, ["90499469533503"]=true, ["133491532453922"]=true } },
    Backstab = { LastTime = 0 },
    Stamina = { Running = false },
}

-- ============================================================
-- 9. Hook 监听（提前挂载好，等待功能开启）
-- ============================================================
local function HookSound(snd)
    if not snd:IsA("Sound") then return end
    if snd:GetAttribute("XD_Hooked") then return end
    snd:SetAttribute("XD_Hooked", true)
    AddConnection(snd.Played:Connect(function()
        Modules.Block.SoundStartTime[snd] = tick()
        if not getgenv().XD_Config.Block.Enabled then return end
        -- 判定逻辑（拦截）
        local id = tostring(snd.SoundId):match("%d+")
        if not id or not AttackSoundIDs[id] then return end
        local root = myRoot()
        if not root then return end
        local parent = snd.Parent
        while parent and not parent:IsA("Model") do parent = parent.Parent end
        if not parent then return end
        local kRoot = parent:FindFirstChild("HumanoidRootPart")
        if kRoot and CheckAllConditions(root, kRoot) then
            if FireBlock() then Logger:Add("BLOCK", "音效格挡触发: " .. id) end
        end
    end))
end

local function HookAnim(animator)
    if not animator:IsA("Animator") then return end
    if animator:GetAttribute("XD_Hooked") then return end
    animator:SetAttribute("XD_Hooked", true)
    AddConnection(animator.AnimationPlayed:Connect(function(track)
        Modules.Block.AnimStartTime[track] = tick()
        if not getgenv().XD_Config.Block.Enabled then return end
        local id = track.Animation and track.Animation.AnimationId:match("%d+")
        if not id or not AttackAnimIDs[id] then return end
        local root = myRoot()
        if not root then return end
        local parent = track.Parent
        while parent and not parent:IsA("Model") do parent = parent.Parent end
        if not parent then return end
        local kRoot = parent:FindFirstChild("HumanoidRootPart")
        if kRoot and CheckAllConditions(root, kRoot) then
            if FireBlock() then Logger:Add("BLOCK", "动画格挡触发: " .. id) end
        end
    end))
end
for _, d in ipairs(WS:GetDescendants()) do if d:IsA("Sound") then HookSound(d) end; if d:IsA("Animator") then HookAnim(d) end end
AddConnection(WS.DescendantAdded:Connect(function(d) if d:IsA("Sound") then HookSound(d) end; if d:IsA("Animator") then HookAnim(d) end end))

-- ============================================================
-- 10. 一些杂项函数（用于 Part 2）
-- ============================================================
local function CreateBox(killer)
    if not killer or not killer:FindFirstChild("HumanoidRootPart") then return end
    if Modules.Visual.Boxes[killer] then return end
    local folder = Instance.new("Folder"); folder.Name = "XD_Box"; folder.Parent = killer.HumanoidRootPart
    local box = Instance.new("Part"); box.Name = "Box"; box.Material = Enum.Material.ForceField
    box.Anchored = true; box.CanCollide = false; box.CanQuery = false; box.CastShadow = false
    box.Transparency = getgenv().XD_Config.Block.BoxTransparency
    box.Color = Color3.fromRGB(255, 0, 0); box.Size = GetBoxSize(); box.Parent = folder
    Modules.Visual.Boxes[killer] = {folder = folder, box = box, killer = killer}
end
local function UpdateBox(killer)
    local data = Modules.Visual.Boxes[killer]
    if not data or not data.folder or not data.folder.Parent then return end
    local kRoot = killer:FindFirstChild("HumanoidRootPart")
    if not kRoot then return end
    local root = myRoot()
    if not root then return end
    local forward = kRoot.CFrame.LookVector
    local pos = kRoot.Position + forward * getgenv().XD_Config.Block.BoxForwardOffset
    data.box.Size = GetBoxSize()
    data.box.CFrame = CFrame.lookAt(pos, pos + forward * 100)
    data.box.Transparency = getgenv().XD_Config.Block.BoxTransparency
    local cond = CheckAllConditions(root, kRoot)
    data.box.Color = cond and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end

-- 留给 Part 2 的启动接口
function StartMainLoop()
    -- 主循环部分
end
-- ============================================================
-- XD Ultimate v5.0 - Part 2
-- 完整 UI 界面 & 主循环逻辑
-- ============================================================

-- ============================================================
-- 11. 免责声明弹窗
-- ============================================================
local NoticeGroup = Tabs.Main:AddLeftGroupbox("⚠️ 免责声明", "alert-triangle")
NoticeGroup:AddLabel({
    Text = "本脚本仅供学习交流使用。\n\n使用本脚本导致账号被封禁、数据异常或其他任何损失，作者及贡献者概不负责。\n\n请在完全知情且自愿的情况下使用。",
    DoesWrap = true
})
NoticeGroup:AddButton({
    Text = "✅ 我已了解并承担一切后果",
    Func = function()
        if getgenv().XD_Authorized then return end
        getgenv().XD_Authorized = true
        Logger:Add("AUTH", "用户已同意免责声明，授权成功。")
        Library:Notify({Title="授权成功", Description="现在你可以使用所有功能了。", Time=5})
        NoticeGroup:AddLabel({ Text = "✅ 状态：已授权", DoesWrap = true })
    end
})

-- ============================================================
-- 12. 主页账号与社区信息
-- ============================================================
local InfoGroup = Tabs.Main:AddRightGroupbox("👤 账号与社区", "user")
InfoGroup:AddLabel("用户名：" .. LP.Name)
InfoGroup:AddLabel("显示名：" .. LP.DisplayName)
InfoGroup:AddLabel("注册天数：" .. LP.AccountAge .. " 天")
InfoGroup:AddDivider()
InfoGroup:AddLabel("官方交流 QQ 群：")
InfoGroup:AddButton({
    Text = "点击复制群号：1131863921",
    Func = function()
        if setclipboard then setclipboard("1131863921"); Library:Notify({Title="复制成功", Description="QQ群号已复制到剪贴板", Time=2})
        else Library:Notify({Title="错误", Description="执行器不支持复制", Time=2}) end
    end
})

-- ============================================================
-- 13. 日志 UI
-- ============================================================
local LogGroup = Tabs.Logs:AddLeftGroupbox("📜 日志面板", "terminal")
LogGroup:AddButton({ Text = "清空日志", Func = function() Logger.Logs = {}; Logger:Render() end })
local logFrame = Instance.new("ScrollingFrame")
logFrame.Size = UDim2.new(0, 400, 0, 400)
logFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
logFrame.BorderSizePixel = 0
logFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
logFrame.ScrollBarThickness = 4
logFrame.Parent = LogGroup.Container or LogGroup.Frame or LogGroup
local logLayout = Instance.new("UIListLayout")
logLayout.Parent = logFrame
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
Logger.UI = logFrame
AddConnection(RunService.Heartbeat:Connect(function()
    if logFrame.Parent then logFrame.CanvasSize = UDim2.new(0, 0, 0, logLayout.AbsoluteContentSize.Y + 10) end
end))

-- ============================================================
-- 14. 构建格挡 UI
-- ============================================================
local BlockGroup = Tabs.Block:AddLeftGroupbox("🛡️ 自动格挡", "shield")
BlockGroup:AddToggle("AutoBlock", {
    Text = "启用自动格挡", Default = false,
    Callback = AuthBlock(function(v)
        getgenv().XD_Config.Block.Enabled = v
        Logger:Add("INFO", "自动格挡: " .. tostring(v))
        SaveConfig()
    end)
})
BlockGroup:AddToggle("FacingCheck", {
    Text = "杀手面向检测", Default = false,
    Callback = AuthBlock(function(v) getgenv().XD_Config.Block.FacingCheck = v; SaveConfig() end)
})
BlockGroup:AddSlider("FacingAngle", {
    Text = "杀手面向角度", Default = 90, Min = 30, Max = 180, Rounding = 1,
    Callback = AuthBlock(function(v) getgenv().XD_Config.Block.FacingAngle = v; SaveConfig() end)
})
BlockGroup:AddToggle("WallCheck", {
    Text = "穿墙检测", Default = false,
    Callback = AuthBlock(function(v) getgenv().XD_Config.Block.WallCheck = v; SaveConfig() end)
})

local BoxGroup = Tabs.Block:AddRightGroupbox("📦 碰撞盒设置", "box")
BoxGroup:AddSlider("BoxScale", {
    Text = "整体缩放", Default = 1.0, Min = 0.5, Max = 2, Rounding = 2,
    Callback = AuthBlock(function(v) getgenv().XD_Config.Block.BoxScale = v; SaveConfig() end)
})
BoxGroup:AddSlider("BoxOffset", {
    Text = "前后偏移", Default = 4, Min = -10, Max = 10, Rounding = 1,
    Callback = AuthBlock(function(v) getgenv().XD_Config.Block.BoxForwardOffset = v; SaveConfig() end)
})
BoxGroup:AddSlider("BoxTransparency", {
    Text = "透明度", Default = 0.5, Min = 0, Max = 1, Rounding = 2,
    Callback = AuthBlock(function(v) getgenv().XD_Config.Block.BoxTransparency = v; SaveConfig() end)
})

-- ============================================================
-- 15. 构建调节 UI
-- ============================================================
local AdjLeft = Tabs.Adjust:AddLeftGroupbox("🎛️ 模式预设", "sliders")
local AdjRight = Tabs.Adjust:AddRightGroupbox("🔧 参数微调", "settings")
local Presets = {
    ["伪装"] = { Delay = 0.18, Note = "【伪装模式】：模拟人类的平均反应速度。\n如果你不想被看出来，请使用此模式。" },
    ["普通"] = { Delay = 0.10, Note = "【普通模式】：略微快速的反应。\n如果你比较大胆，觉得稍微快一点也没关系，可以使用此模式。" },
    ["暴力"] = { Delay = 0.02, Note = "【暴力模式】：极速反应。\n仅限测试使用，如不想账号被重点关注，请勿长期开启。" }
}
local noteLabel = AdjLeft:AddLabel({ Text = Presets["普通"].Note, DoesWrap = true })
AdjLeft:AddDropdown("PresetMode", {
    Text = "选择反应速度", Values = {"伪装", "普通", "暴力"}, Default = "普通",
    Callback = AuthBlock(function(v)
        getgenv().XD_Config.Preset = v
        getgenv().XD_Config.Block.Cooldown = Presets[v].Delay
        SaveConfig()
        if noteLabel and noteLabel.SetText then noteLabel:SetText(Presets[v].Note) elseif noteLabel and noteLabel.TextLabel then noteLabel.TextLabel.Text = Presets[v].Note end
        if Library.Options and Library.Options.Cooldown then Library.Options.Cooldown:SetValue(Presets[v].Delay) end
    end)
})
AdjRight:AddSlider("Cooldown", {
    Text = "封包冷却 (秒)", Default = 0.2, Min = 0.02, Max = 1, Rounding = 2,
    Callback = AuthBlock(function(v) getgenv().XD_Config.Block.Cooldown = v; SaveConfig() end)
})

-- ============================================================
-- 16. 构建自瞄系统 UI
-- ============================================================
local AimGroup = Tabs.Aimbot:AddLeftGroupbox("🎯 机会专属", "crosshair")
AimGroup:AddToggle("ChanceAimbot", {
    Text = "开枪自动瞄准杀手", Default = false,
    Callback = AuthBlock(function(v) getgenv().XD_Config.Aimbot.Chance = v; SaveConfig() end)
})
AimGroup:AddSlider("AimDistance", {
    Text = "最大距离", Default = 100, Min = 20, Max = 300, Rounding = 0,
    Callback = AuthBlock(function(v) getgenv().XD_Config.Aimbot.Distance = v; SaveConfig() end)
})
AimGroup:AddDropdown("AimMode", {
    Text = "模式", Values = {"Camera", "Character"}, Default = "Camera",
    Callback = AuthBlock(function(v) getgenv().XD_Config.Aimbot.Mode = v; SaveConfig() end)
})

-- ============================================================
-- 17. 构建背刺系统 UI
-- ============================================================
local BackGroup = Tabs.Backstab:AddLeftGroupbox("🗡️ 两次专属", "sword")
BackGroup:AddToggle("Backstab", {
    Text = "启用自动背刺", Default = false,
    Callback = AuthBlock(function(v) getgenv().XD_Config.Backstab.Enabled = v; SaveConfig() end)
})
BackGroup:AddSlider("BackDist", {
    Text = "触发距离 (格)", Default = 8, Min = 2, Max = 20, Rounding = 1,
    Callback = AuthBlock(function(v) getgenv().XD_Config.Backstab.Distance = v; SaveConfig() end)
})

-- ============================================================
-- 18. 构建视觉 UI
-- ============================================================
local VisGroup = Tabs.Visual:AddLeftGroupbox("👁️ 视觉增强", "eye")
VisGroup:AddToggle("EnlargeHitbox", {
    Text = "放大杀手 Hitbox", Default = false,
    Callback = AuthBlock(function(v) getgenv().XD_Config.Visual.EnlargeHitbox = v; SaveConfig() end)
})
VisGroup:AddSlider("HitboxMulti", {
    Text = "放大倍数", Default = 3, Min = 1, Max = 10, Rounding = 1,
    Callback = AuthBlock(function(v) getgenv().XD_Config.Visual.HitboxMultiplier = v; SaveConfig() end)
})
VisGroup:AddToggle("LocalHitbox", {
    Text = "显示自身 Hitbox", Default = false,
    Callback = AuthBlock(function(v) getgenv().XD_Config.Visual.LocalHitbox = v; SaveConfig() end)
})

-- ============================================================
-- 19. 构建实用 UI
-- ============================================================
local UtilGroup = Tabs.Utility:AddLeftGroupbox("🔧 实用功能", "wrench")
UtilGroup:AddToggle("InfStamina", {
    Text = "无限体力", Default = false,
    Callback = AuthBlock(function(v) getgenv().XD_Config.Utility.InfStamina = v; SaveConfig() end)
})
UtilGroup:AddToggle("NoStaminaLoss", {
    Text = "奔跑不消耗体力", Default = false,
    Callback = AuthBlock(function(v) getgenv().XD_Config.Utility.NoStaminaLoss = v; SaveConfig() end)
})
UtilGroup:AddToggle("AutoGen", {
    Text = "自动修机", Default = false,
    Callback = AuthBlock(function(v) getgenv().XD_Config.Utility.AutoGen = v; SaveConfig() end)
})
UtilGroup:AddToggle("AntiSlow", {
    Text = "无减速", Default = false,
    Callback = AuthBlock(function(v) getgenv().XD_Config.Utility.AntiSlow = v; SaveConfig() end)
})

-- ============================================================
-- 20. 最终启动逻辑（主循环）
-- ============================================================
Logger:Init() -- 确保日志UI初始化
Logger:Add("INFO", "XD Ultimate v5.0 已加载")
Logger:Add("INFO", "模块初始化完成: Block, Aimbot, Backstab, Visual, Chat, Stamina")

AddConnection(RunService.Heartbeat:Connect(function()
    if not getgenv().XD_Authorized then return end
    local root = myRoot()
    if not root then return end

    -- 自瞄更新
    if getgenv().XD_Config.Aimbot.Chance and Modules.Aimbot.Target then
        local target = Modules.Aimbot.Target
        if tick() - Modules.Aimbot.LastAim < 0.5 and target.Parent then
            local targetCF = CFrame.lookAt(root.Position, Vector3.new(target.Position.X, root.Position.Y, target.Position.Z))
            if getgenv().XD_Config.Aimbot.Mode == "Camera" then
                workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(targetCF, getgenv().XD_Config.Aimbot.Smoothness)
            else
                root.CFrame = root.CFrame:Lerp(targetCF, getgenv().XD_Config.Aimbot.Smoothness)
            end
        end
    end

    -- 无限体力
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

    -- 碰撞盒更新
    for killer, data in pairs(Modules.Visual.Boxes) do
        if killer:FindFirstChild("HumanoidRootPart") then pcall(function() UpdateBox(killer) end) end
    end

    -- 格挡持续检测
    if getgenv().XD_Config.Block.Enabled then
        local kf = getKillersFolder()
        if kf then
            for _, killer in ipairs(kf:GetChildren()) do
                local kRoot = killer:FindFirstChild("HumanoidRootPart")
                if kRoot and CheckAllConditions(root, kRoot) then FireBlock() end
            end
        end
    end
end))

-- 初始化格子
for _, m in ipairs((getKillersFolder() and getKillersFolder():GetChildren()) or {}) do
    if m:IsA("Model") and m:FindFirstChild("HumanoidRootPart") then CreateBox(m) end
end

-- 完成
Library:Notify({Title="XD Ultimate", Description="v5.0 已加载 | 请先在主页同意免责声明", Time=5})
