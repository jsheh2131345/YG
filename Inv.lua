-- ========================================
-- Inv
-- 适配：遗落：沙盒
-- 功能：音效/动画自动格挡 + 范围圈 + 自动修机 + 无限体力 + 状态信息
-- ========================================

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

-- ============================================
-- 配置
-- ============================================
local Settings = {
    Enabled = false,
    Radius = 20,
    BlockDelay = 0.15,
    ShowCircle = true,
    KillerPause = true,
    AnimBlock = true,
    AutoGen = false,
    GenCooldown = 3,
    InfiniteStamina = false,
}

local ATTACK_SOUND_IDS = {
    ["81177941300998"] = true, ["124759000002143"] = true, ["100454448660396"] = true,
    ["80378074560573"] = true, ["71581509593817"] = true, ["137608690172310"] = true,
    ["111156341720353"] = true, ["103770659190361"] = true, ["120096209419889"] = true,
    ["138470027130522"] = true, ["126187132064750"] = true, ["114123828853081"] = true,
    ["113947388190071"] = true, ["135441171877786"] = true, ["97208348928006"] = true,
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
    ["18885909645"] = true, ["70371667919898"] = true, ["70447634862911"] = true,
    ["99135633258223"] = true, ["74707328554358"] = true, ["81299297965542"] = true,
    ["81635858902"] = true, ["82113744478546"] = true, ["83251433279852"] = true,
    ["83685305553364"] = true, ["83829782357897"] = true, ["86204001129974"] = true,
    ["87989533095285"] = true, ["88451353906104"] = true, ["88970503168421"] = true,
    ["92173139187970"] = true, ["93069721274110"] = true, ["94162446513587"] = true,
    ["96571077893813"] = true, ["97167027849946"] = true, ["97433060861952"] = true,
    ["98456918873918"] = true, ["99829427721752"] = true, ["100592913030351"] = true,
    ["105458270463374"] = true, ["106538427162796"] = true, ["106776364623742"] = true,
    ["106847695270773"] = true, ["109230267448394"] = true, ["109667959938617"] = true,
    ["114356208094580"] = true, ["114506382930939"] = true, ["118298475669935"] = true,
    ["120112897026015"] = true, ["121086746534252"] = true, ["121293883585738"] = true,
    ["122709416391891"] = true, ["124705663396411"] = true, ["125403313786645"] = true,
    ["126171487400618"] = true, ["126355327951215"] = true, ["126681776859538"] = true,
    ["126830014841198"] = true, ["126896426760253"] = true, ["128414736976503"] = true,
    ["129976080405072"] = true, ["131430497821198"] = true, ["131543461321709"] = true,
    ["133336594357903"] = true, ["133363345661032"] = true, ["137314737492715"] = true,
    ["138938529389204"] = true, ["139309647473555"] = true, ["139835501033932"] = true,
    ["109700476007435"] = true, ["93366464803829"] = true, ["98590570796574"] = true,
}

-- ============================================
-- 工具
-- ============================================
local function myChar() return LP.Character end
local function myRoot()
    local c = myChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function myHumanoid()
    local c = myChar()
    return c and c:FindFirstChildOfClass("Humanoid")
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
    return container:FindFirstChild("Block") or container:FindFirstChild("Guard")
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

local function killerInRange()
    local root = myRoot()
    if not root then return false end
    local kf = getKillers()
    if not kf then return false end
    for _, k in ipairs(kf:GetChildren()) do
        if k:IsA("Model") then
            local hrp = k:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - root.Position).Magnitude <= Settings.Radius then
                return true
            end
        end
    end
    return false
end

local function modelInRange(model)
    local root = myRoot()
    if not root or not model then return false end
    local hrp = model:FindFirstChild("HumanoidRootPart")
    return hrp ~= nil and (hrp.Position - root.Position).Magnitude <= Settings.Radius
end

local function killerFromSound(s)
    local p = s.Parent
    while p and p ~= WS do
        if p:IsA("Model") and p:FindFirstChild("HumanoidRootPart") then
            return p
        end
        p = p.Parent
    end
    return nil
end

local lastBlockAt = 0
local function tryBlock(delay)
    if not Settings.Enabled then return end
    if Settings.KillerPause and amKiller() then return end
    local now = tick()
    if now - lastBlockAt < 0.12 then return end
    lastBlockAt = now
    local d = math.clamp(delay or Settings.BlockDelay, 0, 3)
    if d <= 0.01 then
        executeBlock()
    else
        task.delay(d, executeBlock)
    end
end

-- ============================================
-- 脚底圆圈
-- ============================================
local circle = Instance.new("Part")
circle.Name = "Inv_Circle"
circle.Shape = Enum.PartType.Cylinder
circle.Anchored = true
circle.CanCollide = false
circle.CanTouch = false
circle.CanQuery = false
circle.CastShadow = false
circle.Material = Enum.Material.Neon
circle.Color = Color3.fromRGB(255, 0, 0)
circle.Transparency = 1
circle.Size = Vector3.new(0.1, Settings.Radius * 2, Settings.Radius * 2)
circle.Parent = nil

local inRangeCached = false

RunService.RenderStepped:Connect(function()
    if not Settings.Enabled or not Settings.ShowCircle then
        if circle.Parent then circle.Transparency = 1 end
        inRangeCached = false
        return
    end
    local root = myRoot()
    if not root then
        circle.Transparency = 1
        inRangeCached = false
        return
    end
    if not circle.Parent then circle.Parent = WS end
    circle.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
    circle.Size = Vector3.new(0.1, Settings.Radius * 2, Settings.Radius * 2)
    circle.Transparency = 0.6
    inRangeCached = killerInRange()
    circle.Color = inRangeCached and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end)

-- ============================================
-- 音效钩子
-- ============================================
local hookedSounds = {}

local function onSoundPlayed(s)
    if not Settings.Enabled then return end
    local id = tostring(s.SoundId):match("%d+")
    if not id or not ATTACK_SOUND_IDS[id] then return end
    local killer = killerFromSound(s)
    if killer then
        local hum = killer:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then return end
        if not modelInRange(killer) then return end
    end
    tryBlock()
end

local function hookSound(s)
    if not s:IsA("Sound") or hookedSounds[s] then return end
    hookedSounds[s] = true
    s.Played:Connect(function() pcall(onSoundPlayed, s) end)
    s.Destroying:Connect(function() hookedSounds[s] = nil end)
end

task.spawn(function()
    for _, d in ipairs(WS:GetDescendants()) do
        if d:IsA("Sound") then hookSound(d) end
    end
end)
WS.DescendantAdded:Connect(function(d)
    if d:IsA("Sound") then hookSound(d) end
end)

-- ============================================
-- 动画钩子
-- ============================================
local hookedKillers = {}

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
        if not modelInRange(model) then return end
        tryBlock()
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
-- 自动修机
-- ============================================
local GenState = { Solving = false, LastEnd = -math.huge }

local function puzzleOpen()
    return PlayerGui:FindFirstChild("PuzzleUI") ~= nil
end

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
                                            lastProgress = progress.Value
                                            stalled = 0
                                        else
                                            stalled = stalled + 1
                                            if stalled >= 8 then break end
                                        end
                                    end
                                end
                            end)
                            GenState.LastEnd = tick()
                            GenState.Solving = false
                        end)
                        break
                    end
                end
            end
        end)
    end
end)
-- ============================================
-- 无限体力
-- ============================================
local StaminaModule = nil
local StaminaDefaults = nil

local function GetStaminaModule()
    if StaminaModule then return StaminaModule end
    local ok, module = pcall(function()
        return require(RS:WaitForChild("Systems", 3)
            :WaitForChild("Character", 3)
            :WaitForChild("Game", 3)
            :WaitForChild("Sprinting", 3))
    end)
    if ok and module then
        StaminaModule = module
        if not StaminaDefaults then
            StaminaDefaults = {
                MaxStamina = module.MaxStamina,
                StaminaGain = module.StaminaGain,
                StaminaLoss = module.StaminaLoss,
            }
        end
        return module
    end
    return nil
end

local StaminaRunning = nil

local function applyInfiniteStamina()
    if not Settings.InfiniteStamina then
        if StaminaRunning then
            task.cancel(StaminaRunning)
            StaminaRunning = nil
        end
        local m = GetStaminaModule()
        if m and StaminaDefaults then
            pcall(function()
                m.StaminaLoss = StaminaDefaults.StaminaLoss
                m.StaminaGain = StaminaDefaults.StaminaGain
            end)
        end
        return
    end
    if StaminaRunning then return end
    StaminaRunning = task.spawn(function()
        while Settings.InfiniteStamina do
            pcall(function()
                local m = GetStaminaModule()
                if m then
                    m.StaminaLoss = 0
                    m.StaminaGain = 9999
                end
            end)
            task.wait(0.1)
        end
    end)
end

-- ============================================
-- 悬浮开关
-- ============================================
local gui = Instance.new("ScreenGui")
gui.Name = "Inv_UI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.Parent = PlayerGui

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 50, 0, 50)
btn.Position = UDim2.new(0, 20, 0, 200)
btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
btn.Text = "格挡"
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 13
btn.AutoButtonColor = false
btn.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = btn

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.new(1, 1, 1)
stroke.Thickness = 2
stroke.Parent = btn

local dragging, dragStart, startPos
local wasDragged = false

btn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        wasDragged = false
        dragStart = input.Position
        startPos = btn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
                wasDragged = true
            end
            btn.Position = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
        end
    end
end)

btn.MouseButton1Click:Connect(function()
    if wasDragged then return end
    Settings.Enabled = not Settings.Enabled
    if Settings.Enabled then
        btn.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        btn.Text = "已开启"
    else
        btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        btn.Text = "格挡"
        if circle.Parent then circle.Transparency = 1 end
    end
end)

-- ============================================
-- 修机 / 体力快捷按钮
-- ============================================
local function makeMiniButton(text, y, getState, onToggle)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 50, 0, 40)
    b.Position = UDim2.new(0, 20, 0, y)
    b.BackgroundColor3 = getState() and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(80, 80, 80)
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.AutoButtonColor = false
    b.Parent = gui
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = b
    b.MouseButton1Click:Connect(function()
        local newState = not getState()
        onToggle(newState)
        b.BackgroundColor3 = newState and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(80, 80, 80)
    end)
    return b
end

makeMiniButton("修机", 260,
    function() return Settings.AutoGen end,
    function(v) Settings.AutoGen = v end
)

makeMiniButton("体力", 310,
    function() return Settings.InfiniteStamina end,
    function(v)
        Settings.InfiniteStamina = v
        applyInfiniteStamina()
    end
)

-- ============================================
-- 信息面板
-- ============================================
local statusGui = Instance.new("ScreenGui")
statusGui.Name = "Inv_Status"
statusGui.ResetOnSpawn = false
statusGui.DisplayOrder = 998
statusGui.Parent = PlayerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -10, 0, 80)
panel.Size = UDim2.fromOffset(280, 340)
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
panel.Parent = statusGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 8)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(60, 60, 80)
panelStroke.Thickness = 1
panelStroke.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
title.BorderSizePixel = 0
title.Text = "Inv · 状态信息"
title.TextColor3 = Color3.fromRGB(80, 255, 140)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = panel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

local note = Instance.new("TextLabel")
note.Position = UDim2.new(0, 10, 0, 36)
note.Size = UDim2.new(1, -20, 0, 24)
note.BackgroundTransparency = 1
note.Text = "如后续删除某些功能，对应行会显示「已移除」"
note.TextColor3 = Color3.fromRGB(160, 160, 180)
note.Font = Enum.Font.Gotham
note.TextSize = 11
note.TextXAlignment = Enum.TextXAlignment.Left
note.Parent = panel

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.new(0, 6, 0, 64)
scroll.Size = UDim2.new(1, -12, 1, -70)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 4)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = scroll

local STATUS_COLORS = {
    ["可用"]   = Color3.fromRGB(80, 255, 140),
    ["已启用"] = Color3.fromRGB(80, 255, 140),
    ["失效"]   = Color3.fromRGB(255, 80, 80),
    ["已移除"] = Color3.fromRGB(160, 160, 180),
    ["未启用"] = Color3.fromRGB(200, 200, 100),
}

local function addRow(name, status)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 20)
    row.BackgroundTransparency = 1
    row.Parent = scroll

    local dot = Instance.new("Frame")
    dot.AnchorPoint = Vector2.new(0, 0.5)
    dot.Position = UDim2.new(0, 6, 0.5, 0)
    dot.Size = UDim2.fromOffset(8, 8)
    dot.BackgroundColor3 = STATUS_COLORS[status] or Color3.fromRGB(120, 120, 120)
    dot.BorderSizePixel = 0
    dot.Parent = row
    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot

    local n = Instance.new("TextLabel")
    n.Position = UDim2.new(0, 20, 0, 0)
    n.Size = UDim2.new(0.6, 0, 1, 0)
    n.BackgroundTransparency = 1
    n.Text = name
    n.TextColor3 = Color3.fromRGB(220, 220, 230)
    n.Font = Enum.Font.Gotham
    n.TextSize = 12
    n.TextXAlignment = Enum.TextXAlignment.Left
    n.Parent = row

    local s = Instance.new("TextLabel")
    s.Position = UDim2.new(0.6, 0, 0, 0)
    s.Size = UDim2.new(0.4, -6, 1, 0)
    s.BackgroundTransparency = 1
    s.Text = status
    s.TextColor3 = STATUS_COLORS[status] or Color3.fromRGB(160, 160, 160)
    s.Font = Enum.Font.GothamBold
    s.TextSize = 11
    s.TextXAlignment = Enum.TextXAlignment.Right
    s.Parent = row
end

local function checkAutoBlock()
    if not getBlockButton() then return "失效" end
    if ATTACK_SOUND_IDS == nil or next(ATTACK_SOUND_IDS) == nil then return "已移除" end
    return Settings.Enabled and "已启用" or "未启用"
end

local function checkAnimBlock()
    if ATTACK_ANIM_IDS == nil or next(ATTACK_ANIM_IDS) == nil then return "已移除" end
    return Settings.AnimBlock and "可用" or "未启用"
end

local function checkCircle()
    return Settings.ShowCircle and "可用" or "未启用"
end

local function checkKillerPause()
    return Settings.KillerPause and "可用" or "未启用"
end

local function checkAutoGen()
    local map = getGameMap()
    if not map then return "失效" end
    return Settings.AutoGen and "已启用" or "未启用"
end

local function checkStamina()
    local m = GetStaminaModule()
    if not m then return "失效" end
    return Settings.InfiniteStamina and "已启用" or "未启用"
end

local function checkHUD()
    if btn and btn.Parent then return "可用" else return "已移除" end
end

local function checkMiniButtons()
    return "可用"
end

local function checkSoundLib()
    if not ATTACK_SOUND_IDS then return "已移除" end
    local c = 0
    for _ in pairs(ATTACK_SOUND_IDS) do c = c + 1 end
    return c .. " 条"
end

local function checkAnimLib()
    if not ATTACK_ANIM_IDS then return "已移除" end
    local c = 0
    for _ in pairs(ATTACK_ANIM_IDS) do c = c + 1 end
    return c .. " 条"
end

local function refreshInfo()
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    addRow("音效自动格挡", checkAutoBlock())
    addRow("动画自动格挡", checkAnimBlock())
    addRow("范围圈可视化", checkCircle())
    addRow("杀手暂停", checkKillerPause())
    addRow("自动修机", checkAutoGen())
    addRow("无限体力", checkStamina())
    addRow("悬浮按钮", checkHUD())
    addRow("修机/体力快捷按钮", checkMiniButtons())
    addRow("音效 ID 库", checkSoundLib())
    addRow("动画 ID 库", checkAnimLib())
end

refreshInfo()

task.spawn(function()
    while task.wait(1) do
        pcall(refreshInfo)
    end
end)
