-- ============================================================
-- LnvAutoBlock 核心战斗模块
-- 编写规范：模块化设计 / 动态特征与静态 ID 双轨检测
-- ============================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- UI 库初始化
local repo = "https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
Library.ShowCustomCursor = true

local MainWindow = Library:CreateWindow({
    Title = "LnvAutoBlock",
    Footer = "Pro Edition",
    Icon = "rbxassetid://4483362748",
    Center = true,
    AutoShow = true,
    Resizable = true,
    NotifySide = "Right",
    ToggleKeybind = Enum.KeyCode.RightShift
})

local Tab = MainWindow:AddTab("自动格挡", "shield")
local function notify(t, d) pcall(function() Library:Notify({Title=t, Description=d, Time=2}) end) end

-- ============================================================
-- 1. 配置中心 (Config)
-- ============================================================
local Config = {
    Enabled = false,
    TriggerRadius = 35,
    BlockDelay = 0.05,
    Cooldown = 0.1,
    ShowBox = true,
    BoxWidth = 6,
    BoxLength = 9,
    BoxHeight = 8,
    BoxDuration = 0.4
}

-- ============================================================
-- 2. 静态 ID 数据库 (Static Database)
-- ============================================================
local Database = {
    Animations = {
        -- 核心库及全量 ID
        ["100725497418533"] = true, ["89448354637442"] = true, 
        ["120950360130737"] = true, ["18885909645"] = true, 
        ["130958529065375"] = true, ["125403313786645"] = true, 
        ["138938529389204"] = true, ["121293883585738"] = true,
        ["88451353906104"] = true, ["113281145948084"] = true, 
        ["119021310055322"] = true, ["109725460050273"] = true, 
        ["76052034966793"] = true, ["94165438815708"] = true,
        ["133738204715506"] = true, ["110467441332666"] = true, 
        ["127916769733604"] = true, ["72623347581545"] = true, 
        ["129001498040521"] = true, ["102776026072549"] = true,
        ["95721871543232"] = true, ["116888521321180"] = true, 
        ["128939901497877"] = true, ["78078652940310"] = true, 
        ["128072729691985"] = true, ["121138069766020"] = true,
        ["83274568292003"] = true, ["99865700633726"] = true, 
        ["97208348928006"] = true, ["129919777481535"] = true, 
        ["121982888855786"] = true, ["106334382305365"] = true,
        ["100972794726219"] = true, ["95029865702251"] = true, 
        ["88346839287070"] = true, ["98105697395689"] = true, 
        ["100926346851492"] = true, ["140671644163156"] = true,
        ["72182155407310"] = true, ["72722244508749"] = true, 
        ["95802026624883"] = true,
        ["102228729296384"] = true, ["140242176732868"] = true, ["112809109188560"] = true,
        ["136323728355613"] = true, ["115026634746636"] = true, ["84116622032112"] = true,
        ["108907358619313"] = true, ["127793641088496"] = true, ["86174610237192"] = true,
        ["95079963655241"] = true, ["101199185291628"] = true, ["119942598489800"] = true,
        ["84307400688050"] = true, ["113037804008732"] = true, ["105200830849301"] = true,
        ["75330693422988"] = true, ["82221759983649"] = true, ["81702359653578"] = true,
        ["108610718831698"] = true, ["112395455254818"] = true, ["109431876587852"] = true,
        ["109348678063422"] = true, ["85853080745515"] = true, ["12222216"] = true,
        ["87259391926321"] = true, ["140703210927645"] = true, ["136007065400978"] = true,
        ["129843313690921"] = true, ["86709774283672"] = true, ["108807732150251"] = true,
        ["138040001965654"] = true, ["86096387000557"] = true, ["81905101227053"] = true,
        ["127777649118195"] = true, ["99100240941590"] = true, ["92831180929659"] = true,
        ["112081768119093"] = true, ["117587689359268"] = true, ["91830732867282"] = true,
        ["91730605416216"] = true, ["100184164753080"] = true, ["108911997126897"] = true,
        ["138936949998619"] = true, ["116427323741607"] = true, ["72007882634344"] = true,
        ["91522546229765"] = true, ["111270184603402"] = true, ["82137285150006"] = true,
        ["119850211147676"] = true,
        ["88557287105521"] = true, ["123548100869928"] = true, ["82605295530067"] = true,
        ["120748030255574"] = true, ["88287038085804"] = true, ["96959123077498"] = true,
        ["115706752305794"] = true, ["82036084568393"] = true, ["127040663332045"] = true,
        ["138407964761603"] = true, ["102517104852347"] = true, ["133292581373127"] = true,
        ["113899931890882"] = true, ["90970641235403"] = true,
    },
    MoveKeywords = {
        "idle", "walk", "run", "jump", "fall", "sit", "swim", 
        "climb", "crouch", "tool", "emote", "loop", "movement"
    }
}

-- ============================================================
-- 3. 工具函数 (Utilities)
-- ============================================================
local function isMoveAnimation(animName)
    if not animName or animName == "" then return false end
    local lowerName = string.lower(animName)
    for _, keyword in ipairs(Database.MoveKeywords) do
        if string.find(lowerName, keyword, 1, true) then
            return true
        end
    end
    return false
end

local function getBlockButton()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local mainUI = playerGui and playerGui:FindFirstChild("MainUI")
    local abilityContainer = mainUI and mainUI:FindFirstChild("AbilityContainer", true)
    if abilityContainer then
        return abilityContainer:FindFirstChild("Block") 
            or abilityContainer:FindFirstChild("Guard") 
            or abilityContainer:FindFirstChild("Parry")
    end
    return nil
end

-- ============================================================
-- 4. 战斗模块 (Combat Module)
-- ============================================================
local Combat = {
    LastBlockTime = 0,
    LastAnimTime = {}, 
    ActiveBoxes = {}
}

function Combat:TriggerBlock()
    if not Config.Enabled then return end
    if tick() - self.LastBlockTime < Config.Cooldown then return end
    self.LastBlockTime = tick()
    
    local btn = getBlockButton()
    if not btn then return end
    
    local function ExecuteClick()
        pcall(function() btn:Activate() end)
        pcall(function()
            if firesignal then
                firesignal(btn.MouseButton1Click)
                firesignal(btn.MouseButton1Down)
            end
        end)
        pcall(function()
            if getconnections then
                for _, conn in pairs(getconnections(btn.MouseButton1Click)) do
                    conn:Fire()
                end
            end
        end)
    end

    if Config.BlockDelay > 0 then
        task.delay(Config.BlockDelay, ExecuteClick)
    else
        ExecuteClick()
    end
end

function Combat:SpawnBox(killerModel)
    if not Config.ShowBox or not killerModel then return end
    
    if self.ActiveBoxes[killerModel] then
        self.ActiveBoxes[killerModel].expire = tick() + Config.BoxDuration
        return
    end
    
    local hrp = killerModel:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local box = Instance.new("Part")
    box.Name = "Lnv_Hitbox"
    box.Size = Vector3.new(Config.BoxWidth, Config.BoxHeight, Config.BoxLength)
    box.Anchored = true
    box.CanCollide = false
    box.CanTouch = false
    box.CanQuery = false
    box.CastShadow = false
    box.Material = Enum.Material.ForceField
    box.Color = Color3.fromRGB(255, 0, 50)
    box.Transparency = 0.4
    box.Parent = Workspace
    
    local outline = Instance.new("SelectionBox")
    outline.Adornee = box
    outline.LineThickness = 0.2
    outline.Color3 = Color3.fromRGB(255, 255, 255)
    outline.SurfaceTransparency = 1
    outline.Parent = box
    
    self.ActiveBoxes[killerModel] = { part = box, expire = tick() + Config.BoxDuration }
end

function Combat:UpdateBoxes()
    for killer, data in pairs(self.ActiveBoxes) do
        if tick() > data.expire or not killer.Parent then
            data.part:Destroy()
            self.ActiveBoxes[killer] = nil
        else
            local hrp = killer:FindFirstChild("HumanoidRootPart")
            if hrp then data.part.CFrame = hrp.CFrame end
        end
    end
end

function Combat:IsInRange(killerModel)
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local kRoot = killerModel and killerModel:FindFirstChild("HumanoidRootPart")
    if not myRoot or not kRoot then return false end
    return (kRoot.Position - myRoot.Position).Magnitude <= Config.TriggerRadius
end

-- ============================================================
-- 5. 事件监听模块 (Event Hooker)
-- ============================================================
local HookedKillers = setmetatable({}, { __mode = "k" })

local function OnAnimationPlayed(killerModel, track)
    if not Config.Enabled or not track.Animation then return end
    
    local animId = track.Animation.AnimationId:match("%d+")
    if not animId then return end
    
    local isKnownAttack = Database.Animations[animId] ~= nil
    -- 收紧兜底：只认 Action 级别，且过滤掉移动动作和 2.5 秒以上的长动作（防技能误判）
    local isHighPriorityAction = (track.Priority >= Enum.AnimationPriority.Action) 
        and not isMoveAnimation(track.Animation.Name) 
        and (track.Length < 2.5)
    
    if isKnownAttack or isHighPriorityAction then
        local now = tick()
        if now - (Combat.LastAnimTime[killerModel] or 0) > 0.15 then
            Combat.LastAnimTime[killerModel] = now
            
            if Combat:IsInRange(killerModel) then
                Combat:SpawnBox(killerModel)
                Combat:TriggerBlock()
            end
        end
    end
end

local function HookKiller(killerModel)
    if HookedKillers[killerModel] then return end
    HookedKillers[killerModel] = true
    
    local humanoid = killerModel:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if animator then
        animator.AnimationPlayed:Connect(function(track) 
            task.spawn(OnAnimationPlayed, killerModel, track) 
        end)
    end
end

-- ============================================================
-- 6. 主循环与初始化 (Main Loop)
-- ============================================================
task.spawn(function()
    while task.wait(1) do
        local playersFolder = Workspace:FindFirstChild("Players")
        local killersFolder = playersFolder and playersFolder:FindFirstChild("Killers")
        if killersFolder then
            for _, killer in ipairs(killersFolder:GetChildren()) do
                if killer:IsA("Model") then HookKiller(killer) end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    Combat:UpdateBoxes()
end)

-- ============================================================
-- 7. UI 界面与悬浮窗 (UI)
-- ============================================================
local function CreateUI()
    local Group = Tab:AddLeftGroupbox("Auto Block", "shield")
    
    Group:AddToggle("AutoBlock", {
        Text = "启用智能格挡", Default = false,
        Callback = function(v)
            Config.Enabled = v
            notify("格挡", v and "已开启" or "已关闭")
            if _G.FloatBtn then
                _G.FloatBtn.BackgroundColor3 = v and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
                _G.FloatBtn.Text = v and "Auto Block\nON" or "Auto Block\nOFF"
            end
        end,
    })
    
    Group:AddSlider("BlockDelay", { Text = "格挡延迟 (秒)", Default = 0.05, Min = 0, Max = 1, Rounding = 2, Callback = function(v) Config.BlockDelay = v end })
    Group:AddSlider("TriggerRadius", { Text = "识别距离", Default = 35, Min = 5, Max = 50, Rounding = 1, Callback = function(v) Config.TriggerRadius = v end })
    
    Group:AddDivider()
    
    Group:AddSlider("BoxWidth", { Text = "框宽度", Default = 6, Min = 2, Max = 20, Rounding = 1, Callback = function(v) Config.BoxWidth = v end })
    Group:AddSlider("BoxLength", { Text = "框长度", Default = 9, Min = 2, Max = 20, Rounding = 1, Callback = function(v) Config.BoxLength = v end })
    Group:AddSlider("BoxHeight", { Text = "框高度", Default = 8, Min = 2, Max = 20, Rounding = 1, Callback = function(v) Config.BoxHeight = v end })

    -- 悬浮窗
    local gui = Instance.new("ScreenGui")
    gui.Name = "Lnv_UI"; gui.ResetOnSpawn = false; gui.DisplayOrder = 999
    gui.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 90, 0, 90)
    btn.Position = UDim2.new(0, 20, 0, 150)
    btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    btn.Text = "Auto Block\nOFF"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBlack
    btn.TextSize = 14
    btn.AutoButtonColor = false
    btn.Parent = gui
    _G.FloatBtn = btn
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Thickness = 3

    -- 实现悬浮窗拖动
    local dragging, dragStart, startPos
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    btn.MouseButton1Click:Connect(function()
        Config.Enabled = not Config.Enabled
        if Library.Options.AutoBlock then Library.Options.AutoBlock:SetValue(Config.Enabled) end
    end)
end

CreateUI()
notify("LnvAutoBlock", "专业版已加载 | 全量 ID 双轨检测启动")

-- ============================================================
-- 8. 性能监控 (FPS & Ping 悬浮窗)
-- ============================================================
local function CreatePerformanceMonitor()
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    -- 创建独立的 ScreenGui
    local statGui = Instance.new("ScreenGui")
    statGui.Name = "Lnv_PerformanceMonitor"
    statGui.ResetOnSpawn = false
    statGui.DisplayOrder = 9999
    statGui.IgnoreGuiInset = true
    statGui.Parent = game:GetService("CoreGui") or PlayerGui
    
    -- 背景板
    local bgFrame = Instance.new("Frame")
    bgFrame.Size = UDim2.new(0, 130, 0, 24)
    bgFrame.Position = UDim2.new(1, -140, 0, 10) -- 右上角
    bgFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    bgFrame.BackgroundTransparency = 0.3
    bgFrame.BorderSizePixel = 0
    bgFrame.Parent = statGui
    _G.PerfFrame = bgFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = bgFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 80, 100)
    stroke.Thickness = 1
    stroke.Parent = bgFrame
    
    -- 文本标签
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 12
    textLabel.TextColor3 = Color3.fromRGB(50, 255, 120)
    textLabel.Text = "FPS: -- | Ping: -- ms"
    textLabel.Parent = bgFrame
    
    -- 数据统计
    local Stats = game:GetService("Stats")
    local Network = Stats:FindFirstChild("Network")
    local ServerStatsItem = Network and Network:FindFirstChild("ServerStatsItem")
    local DataPing = ServerStatsItem and ServerStatsItem:FindFirstChild("Data Ping")
    
    local frames = 0
    local timeElapsed = 0
    local lastUpdate = tick()
    
    RunService.RenderStepped:Connect(function(dt)
        if not bgFrame.Parent or not bgFrame.Visible then return end
        
        frames = frames + 1
        timeElapsed = timeElapsed + dt
        
        if tick() - lastUpdate >= 0.5 then
            local fps = math.floor(frames / timeElapsed + 0.5)
            local ping = "--"
            
            if DataPing then
                pcall(function()
                    ping = math.floor(DataPing:GetValue() + 0.5)
                end)
            else
                Network = Stats:FindFirstChild("Network")
                ServerStatsItem = Network and Network:FindFirstChild("ServerStatsItem")
                DataPing = ServerStatsItem and ServerStatsItem:FindFirstChild("Data Ping")
            end
            
            textLabel.Text = string.format("FPS: %d | Ping: %s ms", fps, tostring(ping))
            
            if fps < 30 then
                textLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            elseif fps < 50 then
                textLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
            else
                textLabel.TextColor3 = Color3.fromRGB(50, 255, 120)
            end
            
            frames = 0
            timeElapsed = 0
            lastUpdate = tick()
        end
    end)
end

CreatePerformanceMonitor()

-- 加一个开关控制性能面板显示
local UI_Func = Tab:AddRightGroupbox("界面", "layout")
UI_Func:AddToggle("ShowFPS", {
    Text = "显示 FPS / Ping 面板", Default = true,
    Callback = function(v)
        if _G.PerfFrame then
            _G.PerfFrame.Visible = v
        end
    end,
})
