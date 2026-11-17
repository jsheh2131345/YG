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
    Cooldown = 0.1,       -- 防止连续发包的硬直
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
    -- 收录已知的核心挥刀、出拳、技能动画 ID
    Animations = {
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
    },
    -- 移动类动画黑名单，防止 Action 优先级误判
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
    
    -- 支持自定义延迟 (秒)
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
    
    -- 防止同一杀手重叠生成
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
    local isHighPriorityAction = (track.Priority >= Enum.AnimationPriority.Action) and not isMoveAnimation(track.Animation.Name)
    
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
notify("LnvAutoBlock", "专业版已加载 | 双轨检测启动")
