-- ========================================
-- Inv
-- 适配：遗落：沙盒
-- 功能：音效/动画触发格挡 + 杀手攻击判定框 + 自动修机 + 体力控制
-- UI：Obsidian
-- ========================================

local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local WS           = game:GetService("Workspace")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local Debris       = game:GetService("Debris")
local LP           = Players.LocalPlayer
local PlayerGui    = LP:WaitForChild("PlayerGui")

local repo    = "https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor = true
Library.NotifySide = "Right"

local Window = Library:CreateWindow({
    Title = "Inv",
    Footer = "适配：遗落：沙盒",
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
    ["自动格挡"] = Window:AddTab("自动格挡", "shield"),
    ["功能"]     = Window:AddTab("功能",     "zap"),
    ["信息"]     = Window:AddTab("信息",     "info"),
    ["设置"]     = Window:AddTab("设置",     "settings"),
}

local function notify(t, d)
    pcall(function() Library:Notify({Title=t, Description=d, Time=2}) end)
end

-- ============================================
-- 配置
-- ============================================
local Settings = {
    Enabled = false,
    ShowBox = true,
    
    BoxWidth = 8,       
    BoxLength = 12,     
    BoxHeight = 8,      
    BoxLingerTime = 0.5,
    
    TriggerRadius = 35, 
    BlockDelay = 0.15,
    KillerPause = true,
    AnimBlock = true,
    AutoGen = false,
    GenCooldown = 3,
    
    InfiniteStamina = false,
    LockStamina = false,
    TargetStamina = 50,
}

-- ============================================
-- 音效和动画 ID 表（你的 32 个 + 之前的所有全量）
-- ============================================
local ATTACK_SOUND_IDS = {
    -- 之前你发的 15 个
    ["81177941300998"] = true, ["124759000002143"] = true, ["100454448660396"] = true,
    ["80378074560573"] = true, ["71581509593817"] = true, ["137608690172310"] = true,
    ["111156341720353"] = true, ["103770659190361"] = true, ["120096209419889"] = true,
    ["138470027130522"] = true, ["126187132064750"] = true, ["114123828853081"] = true,
    ["113947388190071"] = true, ["135441171877786"] = true, ["97208348928006"] = true,
    -- 你刚发的 32 个（音效部分）
    ["120950360130737"] = true, ["18885909645"] = true, ["130958529065375"] = true,
    ["125403313786645"] = true, ["138938529389204"] = true, ["121293883585738"] = true,
    ["88451353906104"] = true, ["113281145948084"] = true, ["119021310055322"] = true,
    ["109725460050273"] = true, ["76052034966793"] = true, ["94165438815708"] = true,
    ["133738204715506"] = true, ["110467441332666"] = true, ["127916769733604"] = true,
    ["72623347581545"] = true, ["129001498040521"] = true, ["102776026072549"] = true,
    ["95721871543232"] = true, ["116888521321180"] = true, ["128939901497877"] = true,
    ["78078652940310"] = true, ["128072729691985"] = true, ["121138069766020"] = true,
    ["83274568292003"] = true, ["99865700633726"] = true, ["129919777481535"] = true,
    ["121982888855786"] = true, ["106334382305365"] = true, ["100972794726219"] = true,
    ["95029865702251"] = true,
    -- 最后记忆(TURN)的通用音效
    ["12222216"] = true, ["71805956520207"] = true, ["71834552297085"] = true,
    ["72425554233832"] = true, ["75330693422988"] = true, ["76467993976301"] = true,
    ["76959687420003"] = true, ["77245770579014"] = true, ["78298577002481"] = true,
    ["79391273191671"] = true, ["79980897195554"] = true, ["80516583309685"] = true,
    ["81702359653578"] = true, ["82221759983649"] = true, ["84116622032112"] = true,
    ["84307400688050"] = true, ["85810983952228"] = true, ["85853080745515"] = true,
    ["86174610237192"] = true, ["86494585504534"] = true, ["86833981571073"] = true,
    ["89004992452376"] = true, ["89315669689903"] = true, ["90878551190839"] = true,
    ["94043596324983"] = true, ["95079963655241"] = true, ["97894923442490"] = true,
    ["98675142200448"] = true, ["99829427721752"] = true, ["101199185291628"] = true,
    ["101553872555606"] = true, ["101698569375359"] = true, ["102228729296384"] = true,
    ["103684883268194"] = true, ["104910828105172"] = true, ["105200830849301"] = true,
    ["105840448036441"] = true, ["106300477136129"] = true, ["107444859834748"] = true,
    ["108610718831698"] = true, ["108907358619313"] = true, ["109348678063422"] = true,
    ["109431876587852"] = true, ["110115912768379"] = true, ["110372418055226"] = true,
    ["112395455254818"] = true, ["112809109188560"] = true, ["113037804008732"] = true,
    ["114742322778642"] = true, ["115026634746636"] = true, ["116581754553533"] = true,
    ["117173212095661"] = true, ["117231507259853"] = true, ["119089145505438"] = true,
    ["119583605486352"] = true, ["119942598489800"] = true, ["121954639447247"] = true,
    ["124330645976935"] = true, ["124397369810639"] = true, ["124903763333174"] = true,
    ["125213046326879"] = true, ["127793641088496"] = true, ["128856426573270"] = true,
    ["131123355704017"] = true, ["131406927389838"] = true, ["135448067174226"] = true,
    ["136323728355613"] = true, ["136841625231863"] = true, ["140242176732868"] = true,
    ["128367348686124"] = true, ["116527305931161"] = true,
}

local ATTACK_ANIM_IDS = {
    -- 你刚发的 32 个（动画部分）
    ["120950360130737"] = true, ["18885909645"] = true, ["130958529065375"] = true,
    ["125403313786645"] = true, ["138938529389204"] = true, ["121293883585738"] = true,
    ["88451353906104"] = true, ["113281145948084"] = true, ["119021310055322"] = true,
    ["109725460050273"] = true, ["76052034966793"] = true, ["94165438815708"] = true,
    ["133738204715506"] = true, ["110467441332666"] = true, ["127916769733604"] = true,
    ["72623347581545"] = true, ["129001498040521"] = true, ["102776026072549"] = true,
    ["95721871543232"] = true, ["116888521321180"] = true, ["128939901497877"] = true,
    ["78078652940310"] = true, ["128072729691985"] = true, ["121138069766020"] = true,
    ["83274568292003"] = true, ["99865700633726"] = true, ["97208348928006"] = true,
    ["129919777481535"] = true, ["121982888855786"] = true, ["106334382305365"] = true,
    ["100972794726219"] = true, ["95029865702251"] = true,
    -- 最后记忆(TURN)的通用动画
    ["70371667919898"] = true, ["70447634862911"] = true,
    ["99135633258223"] = true, ["74707328554358"] = true, ["81299297965542"] = true,
    ["81635858902"] = true, ["82113744478546"] = true, ["83251433279852"] = true,
    ["83685305553364"] = true, ["83829782357897"] = true, ["86204001129974"] = true,
    ["87989533095285"] = true, ["88970503168421"] = true,
    ["92173139187970"] = true, ["93069721274110"] = true, ["94162446513587"] = true,
    ["96571077893813"] = true, ["97167027849946"] = true, ["97433060861952"] = true,
    ["98456918873918"] = true, ["99829427721752"] = true, ["100592913030351"] = true,
    ["105458270463374"] = true, ["106538427162796"] = true, ["106776364623742"] = true,
    ["106847695270773"] = true, ["109230267448394"] = true, ["109667959938617"] = true,
    ["114356208094580"] = true, ["114506382930939"] = true, ["118298475669935"] = true,
    ["120112897026015"] = true, ["121086746534252"] = true,
    ["122709416391891"] = true, ["124705663396411"] = true,
    ["126171487400618"] = true, ["126355327951215"] = true, ["126681776859538"] = true,
    ["126830014841198"] = true, ["126896426760253"] = true, ["128414736976503"] = true,
    ["129976080405072"] = true, ["131430497821198"] = true, ["131543461321709"] = true,
    ["133336594357903"] = true, ["133363345661032"] = true, ["137314737492715"] = true,
    ["139309647473555"] = true, ["139835501033932"] = true,
    ["109700476007435"] = true, ["93366464803829"] = true, ["98590570796574"] = true,
}

-- ============================================
-- 工具与基础判定
-- ============================================
local function myChar() return LP.Character end
local function myRoot()
    local c = myChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getKillers()
    local pf = WS:FindFirstChild("Players")
    return pf and pf:FindFirstChild("Killers")
end
local function getBlockButton()
    local pg = LP:FindFirstChild("PlayerGui")
    local main = pg and pg:FindFirstChild("MainUI")
    local container = main and main:FindFirstChild("AbilityContainer", true)
    if not container then return nil end
    return container:FindFirstChild("Block") or container:FindFirstChild("Guard") or container:FindFirstChild("Parry")
end

local function executeBlock()
    local btn = getBlockButton()
    if not btn then return false end
    local cd = btn:FindFirstChild("CooldownTime", true)
    if cd and cd:IsA("TextLabel") then
        local t = tostring(cd.Text)
        if t ~= "" and t ~= "0" and t ~= "0.0" and (tonumber(t) or 0) ~= 0 then
            return false
        end
    end
    pcall(function() btn:Activate() end)
    return true
end

local function amKiller()
    local c = myChar()
    if not c then return false end
    local kf = getKillers()
    return kf ~= nil and c:IsDescendantOf(kf)
end

local function isKillerInRange(killer)
    local root = myRoot()
    if not root or not killer then return false end
    local hrp = killer:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    return (hrp.Position - root.Position).Magnitude <= Settings.TriggerRadius
end

local function nearestKillerNear(pos)
    local kf = getKillers()
    if not kf then return nil end
    local best, bestD = nil, math.huge
    for _, k in ipairs(kf:GetChildren()) do
        if k:IsA("Model") then
            local hum = k:FindFirstChildOfClass("Humanoid")
            local hrp = k:FindFirstChild("HumanoidRootPart")
            if hrp and (not hum or hum.Health > 0) then
                local d = (hrp.Position - pos).Magnitude
                if d < bestD then best, bestD = k, d end
            end
        end
    end
    return best
end

local function soundWorldPos(s)
    local p = s.Parent
    while p and p ~= WS do
        if p:IsA("BasePart") then return p.Position end
        if p:IsA("Model") then
            local hrp = p:FindFirstChild("HumanoidRootPart") or p.PrimaryPart
            if hrp then return hrp.Position end
        end
        p = p.Parent
    end
    return nil
end

local function spawnHitboxOnKiller(killer)
    if not Settings.ShowBox or not killer then return end
    local hrp = killer:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local box = Instance.new("Part")
    box.Name = "Inv_KillerHitbox"
    box.Size = Vector3.new(Settings.BoxWidth, Settings.BoxHeight, Settings.BoxLength)
    box.CFrame = hrp.CFrame
    box.Anchored = true
    box.CanCollide = false
    box.CanTouch = false
    box.CanQuery = false
    box.CastShadow = false
    box.Material = Enum.Material.ForceField
    box.Color = Color3.fromRGB(255, 50, 50)
    box.Transparency = 0.4
    box.Parent = WS
    
    Debris:AddItem(box, Settings.BoxLingerTime)
end

local lastBlockAt = 0
local function tryBlock(delay)
    if not Settings.Enabled then return end
    if Settings.KillerPause and amKiller() then return end
    local now = tick()
    if now - lastBlockAt < 0.12 then return end
    lastBlockAt = now
    local d = math.clamp(delay or Settings.BlockDelay, 0, 3)
    if d <= 0.01 then executeBlock() else task.delay(d, executeBlock) end
end

-- ============================================
-- 音效检测
-- ============================================
local hookedSounds = setmetatable({}, {__mode="k"})
local lastSoundAt = {}

local function onAnySound(s)
    if not Settings.Enabled or not s.IsPlaying then return end
    local id = tostring(s.SoundId):match("%d+")
    if not id or not ATTACK_SOUND_IDS[id] then return end
    
    local now = tick()
    if now - (lastSoundAt[id] or 0) < 0.12 then return end
    lastSoundAt[id] = now
    
    local root = myRoot()
    if not root then return end
    
    local pos = soundWorldPos(s)
    local killer
    if pos then killer = nearestKillerNear(pos) end
    if not killer then killer = nearestKillerNear(root.Position) end
    
    if killer then
        if isKillerInRange(killer) then
            spawnHitboxOnKiller(killer)
            tryBlock()
        end
    end
end

local function hookAnySound(s)
    if not s:IsA("Sound") or hookedSounds[s] then return end
    hookedSounds[s] = true
    s.Played:Connect(function() pcall(onAnySound, s) end)
    s:GetPropertyChangedSignal("IsPlaying"):Connect(function()
        if s.IsPlaying then pcall(onAnySound, s) end
    end)
end

task.spawn(function()
    for _, d in ipairs(WS:GetDescendants()) do
        if d:IsA("Sound") then hookAnySound(d) end
    end
    for _, d in ipairs(game:GetService("SoundService"):GetDescendants()) do
        if d:IsA("Sound") then hookAnySound(d) end
    end
end)
WS.DescendantAdded:Connect(function(d) if d:IsA("Sound") then hookAnySound(d) end end)
game:GetService("SoundService").DescendantAdded:Connect(function(d) if d:IsA("Sound") then hookAnySound(d) end end)

-- ============================================
-- 动画检测
-- ============================================
local hookedKillers = setmetatable({}, {__mode="k"})
local lastAnimAt = setmetatable({}, {__mode="k"})

local function hookKillerAnims(model)
    if hookedKillers[model] then return end
    hookedKillers[model] = true
    local hum = model:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator then return end
    
    animator.AnimationPlayed:Connect(function(track)
        if not Settings.Enabled or not Settings.AnimBlock then return end
        local id = track.Animation and track.Animation.AnimationId:match("%d+")
        if not id or not ATTACK_ANIM_IDS[id] then return end
        if track.Looped then return end
        if track.Length and track.Length > 2.5 then return end
        
        if isKillerInRange(model) then
            local now = tick()
            if now - (lastAnimAt[model] or 0) > 0.12 then
                lastAnimAt[model] = now
                spawnHitboxOnKiller(model)
                tryBlock()
            end
        end
    end)
    model.AncestryChanged:Connect(function()
        if not model.Parent then hookedKillers[model] = nil end
    end)
end

task.spawn(function()
    while task.wait(1) do
        local kf = getKillers()
        if kf then
            for _, m in ipairs(kf:GetChildren()) do
                if m:IsA("Model") then hookKillerAnims(m) end
            end
        end
    end
end)
-- ============================================
-- 自动修机逻辑
-- ============================================
local GenState = { Solving = false, LastEnd = -math.huge }
local function puzzleOpen() return PlayerGui:FindFirstChild("PuzzleUI") ~= nil end
local function getGameMap()
    local map = WS:FindFirstChild("Map")
    local ingame = map and map:FindFirstChild("Ingame")
    return ingame and ingame:FindFirstChild("Map")
end

task.spawn(function()
    while task.wait(0.25) do
        pcall(function()
            if not Settings.AutoGen or GenState.Solving then return end
            if tick() - GenState.LastEnd < 2 then return end
            if not puzzleOpen() then return end
            local root = myRoot()
            local map = getGameMap()
            if not (root and map) then return end
            for _, gen in ipairs(map:GetChildren()) do
                if gen:IsA("Model") and gen.Name:find("Generator") and gen:FindFirstChild("Main") then
                    if (gen.Main.Position - root.Position).Magnitude < 6.7 then
                        GenState.Solving = true
                        task.spawn(function()
                            pcall(function()
                                local remotes = gen:FindFirstChild("Remotes")
                                local progress = gen:FindFirstChild("Progress")
                                local re = remotes and remotes:FindFirstChildOfClass("RemoteEvent")
                                if not re then return end
                                local lastProgress = progress and progress.Value or 0
                                local stalled = 0
                                while Settings.AutoGen and gen.Parent and puzzleOpen() do
                                    if progress and progress.Value >= 100 then break end
                                    task.wait(Settings.GenCooldown + math.random() * 0.2 - 0.1)
                                    if not Settings.AutoGen or not gen.Parent or not puzzleOpen() then break end
                                    pcall(function() re:FireServer() end)
                                    if progress then
                                        if progress.Value > lastProgress then
                                            lastProgress = progress.Value; stalled = 0
                                        else
                                            stalled = stalled + 1
                                            if stalled >= 8 then break end
                                        end
                                    end
                                end
                            end)
                            GenState.LastEnd = tick(); GenState.Solving = false
                        end)
                        break
                    end
                end
            end
        end)
    end
end)

-- ============================================
-- 体力控制逻辑
-- ============================================
local StaminaModule = nil
local StaminaDefaults = nil
local StaminaRunning = nil

local function GetStaminaModule()
    if StaminaModule then return StaminaModule end
    local ok, module = pcall(function()
        return require(RS:WaitForChild("Systems", 3):WaitForChild("Character", 3):WaitForChild("Game", 3):WaitForChild("Sprinting", 3))
    end)
    if ok and module then
        StaminaModule = module
        if not StaminaDefaults then
            StaminaDefaults = { MaxStamina = module.MaxStamina, StaminaGain = module.StaminaGain, StaminaLoss = module.StaminaLoss }
        end
        return module
    end
    return nil
end

local function applyInfiniteStamina()
    if not Settings.InfiniteStamina and not Settings.LockStamina then
        if StaminaRunning then task.cancel(StaminaRunning); StaminaRunning = nil end
        local m = GetStaminaModule()
        if m and StaminaDefaults then
            pcall(function() m.StaminaLoss = StaminaDefaults.StaminaLoss; m.StaminaGain = StaminaDefaults.StaminaGain end)
        end
        return
    end
    if StaminaRunning then return end
    StaminaRunning = task.spawn(function()
        while Settings.InfiniteStamina or Settings.LockStamina do
            pcall(function()
                local m = GetStaminaModule()
                if m then
                    if Settings.InfiniteStamina then
                        m.StaminaLoss = 0; m.StaminaGain = 9999
                    elseif Settings.LockStamina then
                        local cur = rawget(m, "Stamina") or 0
                        if cur < Settings.TargetStamina then
                            rawset(m, "Stamina", Settings.TargetStamina)
                        end
                        m.StaminaLoss = 1; m.StaminaGain = 25
                    end
                end
            end)
            task.wait(0.1)
        end
    end)
end

-- ============================================
-- UI - 自动格挡
-- ============================================
local AutoBlockGroup = Tabs["自动格挡"]:AddLeftGroupbox("Auto Block", "shield")
local AutoBlockToggle

AutoBlockToggle = AutoBlockGroup:AddToggle("AutoBlock", {
    Text = "自动格挡（音效/动画触发）",
    Default = false,
    Callback = function(v)
        Settings.Enabled = v
        if _G.InvFloatBtn then
            if v then
                _G.InvFloatBtn.BackgroundColor3 = Color3.fromRGB(50, 255, 50); _G.InvFloatBtn.Text = "已开启"
            else
                _G.InvFloatBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50); _G.InvFloatBtn.Text = "格挡"
            end
        end
        notify("自动格挡", v and "已开启" or "已关闭")
    end,
})

AutoBlockGroup:AddSlider("BlockDelay", {
    Text = "格挡延迟（秒）",
    Default = 0.15, Min = 0, Max = 3, Rounding = 2,
    Callback = function(v) Settings.BlockDelay = v end,
})

AutoBlockGroup:AddSlider("TriggerRadius", {
    Text = "触发距离 / 检测圈半径 (格)",
    Default = 35, Min = 5, Max = 100, Rounding = 1,
    Callback = function(v) Settings.TriggerRadius = v end,
})

AutoBlockGroup:AddDivider()

AutoBlockGroup:AddSlider("BoxWidth", {
    Text = "框宽度 (左右)",
    Default = 8, Min = 2, Max = 30, Rounding = 1,
    Callback = function(v) Settings.BoxWidth = v end,
})

AutoBlockGroup:AddSlider("BoxLength", {
    Text = "框长度 (前后)",
    Default = 12, Min = 2, Max = 30, Rounding = 1,
    Callback = function(v) Settings.BoxLength = v end,
})

AutoBlockGroup:AddSlider("BoxHeight", {
    Text = "框高度 (上下)",
    Default = 8, Min = 2, Max = 30, Rounding = 1,
    Callback = function(v) Settings.BoxHeight = v end,
})

AutoBlockGroup:AddSlider("BoxLinger", {
    Text = "框滞留时间 (秒)",
    Default = 0.5, Min = 0.1, Max = 3, Rounding = 2,
    Callback = function(v) Settings.BoxLingerTime = v end,
})

AutoBlockGroup:AddDivider()

AutoBlockGroup:AddToggle("AnimBlock", {
    Text = "动画检测（音效未命中时兜底）",
    Default = true,
    Callback = function(v) Settings.AnimBlock = v end,
})

AutoBlockGroup:AddToggle("ShowBox", {
    Text = "显示杀手攻击判定框",
    Default = true,
    Callback = function(v) Settings.ShowBox = v end,
})

AutoBlockGroup:AddToggle("KillerPause", {
    Text = "我是杀手时暂停格挡",
    Default = true,
    Callback = function(v) Settings.KillerPause = v end,
})

-- ============================================
-- UI - 功能
-- ============================================
local GenGroup = Tabs["功能"]:AddLeftGroupbox("自动修机", "zap")
GenGroup:AddToggle("AutoGen", {
    Text = "自动修机", Default = false,
    Callback = function(v) Settings.AutoGen = v; if _G.InvMiniGenBtn then _G.InvMiniGenBtn.BackgroundColor3 = v and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(80, 80, 80) end end,
})
GenGroup:AddSlider("GenCooldown", { Text = "修机间隔（秒）", Default = 3, Min = 1, Max = 8, Rounding = 1, Callback = function(v) Settings.GenCooldown = v end })

local StaminaGroup = Tabs["功能"]:AddRightGroupbox("体力控制", "heart")
StaminaGroup:AddToggle("InfiniteStamina", {
    Text = "无限体力", Default = false,
    Callback = function(v) 
        Settings.InfiniteStamina = v
        if v then Settings.LockStamina = false end
        applyInfiniteStamina()
        if _G.InvMiniStaminaBtn then _G.InvMiniStaminaBtn.BackgroundColor3 = v and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(80, 80, 80) end
    end,
})
StaminaGroup:AddToggle("LockStamina", {
    Text = "锁定指定体力值", Default = false,
    Callback = function(v) 
        Settings.LockStamina = v
        if v then Settings.InfiniteStamina = false end
        applyInfiniteStamina()
    end,
})
StaminaGroup:AddSlider("TargetStamina", {
    Text = "目标体力值", Default = 50, Min = 1, Max = 200, Rounding = 0,
    Callback = function(v) Settings.TargetStamina = v end,
})

-- ============================================
-- UI - 信息
-- ============================================
local InfoGroup = Tabs["信息"]:AddLeftGroupbox("功能状态", "info")
local statusLabels = {}
local function makeStatusRow(name) local lbl = InfoGroup:AddLabel(name .. ": 检测中...", true); statusLabels[name] = lbl end
makeStatusRow("音效自动格挡"); makeStatusRow("动画自动格挡"); makeStatusRow("判定框显示"); makeStatusRow("自动修机"); makeStatusRow("无限体力")

local function setStatus(name, status)
    local lbl = statusLabels[name]; if not lbl then return end
    local color = (status == "可用" or status == "已启用") and "50ff8c" or (status == "失效" and "ff5050" or (status == "未启用" and "c8c864" or "a0a0b4"))
    pcall(function() lbl:SetText(name .. ': <font color="#' .. color .. '">' .. status .. "</font>") end)
end

local function refreshStatus()
    setStatus("音效自动格挡", not getBlockButton() and "失效" or (Settings.Enabled and "已启用" or "未启用"))
    setStatus("动画自动格挡", Settings.AnimBlock and "可用" or "未启用")
    setStatus("判定框显示", Settings.ShowBox and "可用" or "未启用")
    setStatus("自动修机", getGameMap() and (Settings.AutoGen and "已启用" or "未启用") or "失效")
    setStatus("无限体力", GetStaminaModule() and ((Settings.InfiniteStamina or Settings.LockStamina) and "已启用" or "未启用") or "失效")
end
refreshStatus()
task.spawn(function() while task.wait(1) do pcall(refreshStatus) end end)

-- ============================================
-- UI - 设置
-- ============================================
local SettingsGroup = Tabs["设置"]:AddLeftGroupbox("菜单", "settings")
SettingsGroup:AddLabel("菜单快捷键"):AddKeyPicker("MenuKey", { Default = "RightShift", NoUI = true, Text = "菜单快捷键" })
SettingsGroup:AddButton("卸载脚本", function() Library:Unload() end)
Library.ToggleKeybind = Library.Options.MenuKey
SettingsGroup:AddToggle("ShowFloatBtn", { Text = "显示悬浮按钮", Default = true, Callback = function(v) if _G.InvGui then _G.InvGui.Enabled = v end end })

ThemeManager:SetLibrary(Library)
ThemeManager:SetDefaultTheme({ BackgroundColor = Color3.fromRGB(26, 26, 46), AccentColor = Color3.fromRGB(137, 180, 250), OutlineColor = Color3.fromRGB(49, 50, 68), FontColor = Color3.fromRGB(205, 214, 244), FontFace = Enum.Font.Jura })
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKey" })
SaveManager:SetFolder("InvHub")
SaveManager:BuildConfigSection(Tabs["设置"])
ThemeManager:ApplyToTab(Tabs["设置"])
SaveManager:LoadAutoloadConfig()

-- ============================================
-- 悬浮按钮与快捷开关
-- ============================================
local invGui = Instance.new("ScreenGui")
invGui.Name = "Inv_UI"; invGui.ResetOnSpawn = false; invGui.DisplayOrder = 999; invGui.Parent = PlayerGui
_G.InvGui = invGui

local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0, 50, 0, 50); floatBtn.Position = UDim2.new(0, 20, 0, 200)
floatBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50); floatBtn.Text = "格挡"; floatBtn.TextColor3 = Color3.new(1, 1, 1)
floatBtn.Font = Enum.Font.GothamBold; floatBtn.TextSize = 13; floatBtn.AutoButtonColor = false; floatBtn.Parent = invGui
_G.InvFloatBtn = floatBtn

local fCorner = Instance.new("UICorner"); fCorner.CornerRadius = UDim.new(1, 0); fCorner.Parent = floatBtn
local fStroke = Instance.new("UIStroke"); fStroke.Color = Color3.new(1, 1, 1); fStroke.Thickness = 2; fStroke.Parent = floatBtn

local dragging, dragStart, startPos, wasDragged = false, nil, nil, false
floatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; wasDragged = false; dragStart = input.Position; startPos = floatBtn.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then wasDragged = true end
            floatBtn.Position = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
        end
    end
end)

floatBtn.MouseButton1Click:Connect(function()
    if wasDragged then return end
    Settings.Enabled = not Settings.Enabled
    if Settings.Enabled then
        floatBtn.BackgroundColor3 = Color3.fromRGB(50, 255, 50); floatBtn.Text = "已开启"
    else
        floatBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50); floatBtn.Text = "格挡"
    end
    if AutoBlockToggle and AutoBlockToggle.SetValue then pcall(function() AutoBlockToggle:SetValue(Settings.Enabled) end) end
end)

local function makeMiniButton(text, y, getState, onToggle)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 50, 0, 40); b.Position = UDim2.new(0, 20, 0, y)
    b.BackgroundColor3 = getState() and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(80, 80, 80)
    b.Text = text; b.TextColor3 = Color3.new(1, 1, 1); b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.AutoButtonColor = false; b.Parent = invGui
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = b
    b.MouseButton1Click:Connect(function()
        local newState = not getState(); onToggle(newState)
        b.BackgroundColor3 = newState and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(80, 80, 80)
    end)
    return b
end

_G.InvMiniGenBtn = makeMiniButton("修机", 260, function() return Settings.AutoGen end, function(v) Settings.AutoGen = v end)
_G.InvMiniStaminaBtn = makeMiniButton("体力", 310, function() return Settings.InfiniteStamina end, function(v) Settings.InfiniteStamina = v; applyInfiniteStamina() end)

task.wait(0.5)
notify("Inv", "已加载 | 攻击判定框已就绪")
