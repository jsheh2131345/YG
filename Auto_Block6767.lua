-- ========================================
-- Inv 鉴权拦截系统
-- ========================================

local Players      = game:GetService("Players")
local LP           = Players.LocalPlayer
local PlayerGui    = LP:WaitForChild("PlayerGui")

local repo    = "https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
Library.ShowCustomCursor = true

local AuthWindow = Library:CreateWindow({
    Title = "Inv 登录",
    Footer = "请验证卡密解锁",
    Icon = "rbxassetid://4483362748",
    Center = true,
    AutoShow = true,
    Resizable = false,
    NotifySide = "Right",
    ToggleKeybind = Enum.KeyCode.RightShift
})

local AuthTab = AuthWindow:AddTab("验证", "lock")

-- 全局持久化存储
_G.InvAuth = _G.InvAuth or { NormalKey = nil, ExpireTime = 0 }

-- 永久卡密列表
local PermanentKeys = {
    ["LNV_7b3a80daa6a87f7a0385aa4485894526"] = true, -- 作者卡密
    ["LNV_9f2c4e1a7b3d8056c9e2f4a1b7d36085"] = true, -- 普通永久卡密
}

local isAuthorized = false

-- 50 个随机普通卡密池
local NormalKeyPool = {
    "ARSD_4a1b2c3d4e5f6g7h8i9j", "ARSD_9x8y7z6w5v4u3t2s1r0q", "ARSD_m1n2b3v4c5x6z7l8k9j",
    "ARSD_q1w2e3r4t5y6u7i8o9p", "ARSD_z1x2c3v4b5n6m7a8s9d", "ARSD_p0o9i8u7y6t5r4e3w2q",
    "ARSD_a1s2d3f4g5h6j7k8l9z", "ARSD_l9k8j7h6g5f4d3s2a1q", "ARSD_m9n8b7v6c5x4z3l2k1j",
    "ARSD_q9w8e7r6t5y4u3i2o1p", "ARSD_1a2b3c4d5e6f7g8h9i0j", "ARSD_9z8x7c6v5b4n3m2a1s",
    "ARSD_1q2w3e4r5t6y7u8i9o0", "ARSD_0p9o8i7u6y5t4r3e2w1", "ARSD_1a2s3d4f5g6h7j8k9l",
    "ARSD_9l8k7j6h5g4f3d2s1a", "ARSD_1m2n3b4v5c6x7z8l9k", "ARSD_9k8l7z6x5c4v3b2n1m",
    "ARSD_1q2w3e4r5t6y7u8i9o", "ARSD_9o8i7u6y5t4r3e2w1q", "ARSD_1z2x3c4v5b6n7m8a9s",
    "ARSD_9s8a7m6n5b4v3c2x1z", "ARSD_1p2o3i4u5y6t7r8e9w", "ARSD_9w8e7r6t5y4u3i2o1p",
    "ARSD_1a2b3c4d5e6f7g8h9i", "ARSD_9i8h7g6f5e4d3c2b1a", "ARSD_1x2y3z4a5b6c7d8e9f",
    "ARSD_9f8e7d6c5b4a3z2y1x", "ARSD_1m2n3o4p5q6r7s8t9u", "ARSD_9u8t7s6r5q4p3o2n1m",
    "ARSD_1v2w3x4y5z6a7b8c9d", "ARSD_9d8c7b6a5z4y3x2w1v", "ARSD_1e2f3g4h5i6j7k8l9m",
    "ARSD_9m8l7k6j5i4h3g2f1e", "ARSD_1n2o3p4q5r6s7t8u9v", "ARSD_9v8u7t6s5r4q3p2o1n",
    "ARSD_1w2x3y4z5a6b7c8d9e", "ARSD_9e8d7c6b5a4z3y2x1w", "ARSD_1f2g3h4i5j6k7l8m9n",
    "ARSD_9n8m7l6k5j4i3h2g1f", "ARSD_1o2p3q4r5s6t7u8v9w", "ARSD_9w8v7u6t5s4r3q2p1o",
    "ARSD_1x2y3z4a5b6c7d8e9f", "ARSD_9f8e7d6c5b4a3z2y1x", "ARSD_1g2h3i4j5k6l7m8n9o",
    "ARSD_9o8n7m6l5k4j3i2h1g", "ARSD_1p2q3r4s5t6u7v8w9x", "ARSD_9x8w7v6u5t4s3r2q1p",
    "ARSD_1y2z3a4b5c6d7e8f9g", "ARSD_9g8f7e6d5c4b3a2z1y"
}

local function generateNormalKey()
    local randIndex = math.random(1, #NormalKeyPool)
    return NormalKeyPool[randIndex]
end

local function validateKey(input)
    if type(input) == "string" then
        input = input:gsub("^%s*(.-)%s*$", "%1")
    else
        return false, "Invalid"
    end

    if PermanentKeys[input] then
        return true, "Permanent"
    end

    if _G.InvAuth.NormalKey and input == _G.InvAuth.NormalKey then
        if os.time() < _G.InvAuth.ExpireTime then
            return true, "Normal"
        else
            return false, "Expired"
        end
    end

    return false, "Invalid"
end

local function unlockScript()
    isAuthorized = true
    Library:Notify({Title = "授权成功", Description = "欢迎使用 Inv！", Time = 3})
    AuthWindow:Destroy()
    if _G.LoadMainScript then
        task.spawn(_G.LoadMainScript)
    end
end

-- UI 构建
local AuthGroup = AuthTab:AddLeftGroupbox("卡密验证", "key")
AuthGroup:AddInput("KeyInput", {
    Text = "输入卡密", Default = "", Placeholder = "在此粘贴卡密...", ClearTextOnFocus = false, Finished = true,
})
AuthGroup:AddButton("确认并解锁", function()
    local isValid, keyType = validateKey(Library.Options.KeyInput.Value)
    if isValid then unlockScript() else
        if keyType == "Expired" then
            Library:Notify({Title = "卡密过期", Description = "普通卡密已过期，请前往右侧答题获取新卡密！", Time = 4})
        else
            Library:Notify({Title = "授权失败", Description = "卡密错误！", Time = 3})
        end
    end
end)

AuthGroup:AddDivider()
AuthGroup:AddButton("不想答题？复制官方 QQ 群获取卡密", function()
    if setclipboard then setclipboard("1136413909") Library:Notify({Title = "已复制", Description = "QQ群号: 1136413909", Time = 3})
    else Library:Notify({Title = "复制失败", Description = "执行器不支持 setclipboard", Time = 3}) end
end)

-- 答题区
local QuizGroup = AuthTab:AddRightGroupbox("答题续命 (普通卡密)", "help-circle")
QuizGroup:AddLabel("提示：前 5 题简单加减法，后 5 题解方程，全对才能拿卡密", true)

local quizState = { progress = 0, qText = "", answer = 0, questions = {} }
local ProgressLabel = QuizGroup:AddLabel("进度: 0 / 10", true)
local MathLabel = QuizGroup:AddLabel("题目: 点击下方按钮开始", true)
local AnswerInput = QuizGroup:AddInput("MathInput", { Text = "答案", Default = "", Placeholder = "输入数字...", Finished = false })

local CopyBtn = QuizGroup:AddButton("已生成卡密，点此复制", function()
    if _G.InvAuth.NormalKey then
        if setclipboard then setclipboard(_G.InvAuth.NormalKey) end
        Library:Notify({Title = "已复制", Description = _G.InvAuth.NormalKey, Time = 3})
    end
end)
CopyBtn:SetVisible(false)

local function generateQuiz()
    quizState.questions = {}
    for i = 1, 5 do
        local a, b = math.random(10, 50), math.random(10, 50)
        table.insert(quizState.questions, { type = "add", text = a .. " + " .. b .. " = ?", answer = a + b })
    end
    for i = 1, 5 do
        local x = math.random(1, 20)
        local mult = math.random(2, 9)
        local constant = math.random(1, 20)
        local result = x * mult + constant
        table.insert(quizState.questions, { type = "eq", text = "解方程: " .. mult .. "x + " .. constant .. " = " .. result .. " (x=?)", answer = x })
    end
    for i = #quizState.questions, 2, -1 do
        local j = math.random(1, i)
        quizState.questions[i], quizState.questions[j] = quizState.questions[j], quizState.questions[i]
    end
end

local SubmitBtn = QuizGroup:AddButton("提交答案", function()
    if quizState.progress >= 10 or MathLabel.Text == "题目: 点击下方按钮开始" then return end
    local userAns = tonumber(AnswerInput.Value)
    local currentQuestion = quizState.questions[quizState.progress + 1]
    if userAns and currentQuestion and userAns == currentQuestion.answer then
        quizState.progress = quizState.progress + 1
        ProgressLabel:SetText("进度: " .. quizState.progress .. " / 10")
        Library:Notify({Title = "回答正确", Description = "继续下一题！", Time = 1})
        if quizState.progress >= 10 then
            local newKey = generateNormalKey()
            _G.InvAuth.NormalKey = newKey
            _G.InvAuth.ExpireTime = os.time() + 86400
            MathLabel:SetText("题目: 答题完成！卡密已生成")
            AnswerInput:SetVisible(false)
            CopyBtn:SetVisible(true)
            if setclipboard then setclipboard(newKey) end
            Library:Notify({Title = "生成成功", Description = "新卡密已复制，有效期24小时！", Time = 5})
        else
            MathLabel:SetText("题目: " .. quizState.questions[quizState.progress + 1].text)
            AnswerInput:SetValue("")
        end
    else
        Library:Notify({Title = "回答错误", Description = "重新思考一下吧！", Time = 2})
    end
end)

local StartQuizBtn = QuizGroup:AddButton("获取普通卡密 (答题)", function()
    quizState.progress = 0
    ProgressLabel:SetText("进度: 0 / 10")
    generateQuiz()
    MathLabel:SetText("题目: " .. quizState.questions[1].text)
    AnswerInput:SetVisible(true)
    CopyBtn:SetVisible(false)
    Library:Notify({Title = "开始答题", Description = "答对10道题即可获得卡密！", Time = 3})
end)

if _G.InvAuth.NormalKey and os.time() < _G.InvAuth.ExpireTime then
    local remainingHours = math.floor((_G.InvAuth.ExpireTime - os.time()) / 3600)
    Library:Notify({Title = "检测到有效卡密", Description = "你的普通卡密还剩 " .. remainingHours .. " 小时", Time = 5})
    AuthGroup:AddLabel("当前可用普通卡密: " .. _G.InvAuth.NormalKey, true)
else
    if _G.InvAuth.NormalKey then
        Library:Notify({Title = "卡密已过期", Description = "请重新答题获取新卡密", Time = 5})
    end
end
-- ============================================
-- 主功能加载器（由卡密验证成功后触发）
-- ============================================
_G.LoadMainScript = function()
    -- 清理之前的验证界面
    pcall(function() Library:Unload() end)
    
    -- 重新加载全新的库
    local NewLibrary = loadstring(game:HttpGet(repo .. "Library.lua"))()
    local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
    local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

    NewLibrary.ShowToggleFrameInKeybinds = true
    NewLibrary.ShowCustomCursor = true
    NewLibrary.NotifySide = "Right"

    local MainWindow = NewLibrary:CreateWindow({
        Title = "Inv",
        Footer = "Forsaken Edition",
        Icon = "rbxassetid://4483362748",
        Center = true,
        AutoShow = true,
        Resizable = true,
        NotifySide = "Right",
        ToggleKeybind = Enum.KeyCode.RightShift
    })

    local Tabs = {
        ["自动格挡"] = MainWindow:AddTab("自动格挡", "shield"),
        ["设置"]     = MainWindow:AddTab("设置",     "settings"),
    }

    local function notify(t, d) pcall(function() NewLibrary:Notify({Title=t, Description=d, Time=2}) end) end

    local Settings = {
        Enabled = false,
        ShowBox = true,
        BoxWidth = 5, BoxLength = 8, BoxHeight = 7, 
        BoxLingerTime = 0.4, 
        TriggerRadius = 20, 
        BlockDelay = 0.1,   
        KillerPause = true,
    }

    -- 全量动画 ID
    local ATTACK_ANIM_IDS = {
        ["100725497418533"] = true, ["89448354637442"] = true, 
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
        ["100972794726219"] = true, ["95029865702251"] = true, ["88346839287070"] = true,
    }

    -- 全量音效 ID
    local ATTACK_SOUND_IDS = {
        ["92869747208256"] = true, ["95166423060976"] = true,
        ["81177941300998"] = true, ["124759000002143"] = true, ["100454448660396"] = true,
        ["80378074560573"] = true, ["71581509593817"] = true, ["137608690172310"] = true,
        ["111156341720353"] = true, ["103770659190361"] = true, ["120096209419889"] = true,
        ["138470027130522"] = true, ["126187132064750"] = true, ["114123828853081"] = true,
        ["113947388190071"] = true, ["135441171877786"] = true, ["97208348928006"] = true,
    }

    local function myRoot() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
    local function getKillers() local pf = game:GetService("Workspace"):FindFirstChild("Players") return pf and pf:FindFirstChild("Killers") end
    local function getBlockButton()
        local pg = LP:FindFirstChild("PlayerGui")
        local main = pg and pg:FindFirstChild("MainUI")
        local container = main and main:FindFirstChild("AbilityContainer", true)
        return container and (container:FindFirstChild("Block") or container:FindFirstChild("Guard") or container:FindFirstChild("Parry"))
    end

    local function executeBlock()
        local btn = getBlockButton()
        if not btn then return end
        local cd = btn:FindFirstChild("CooldownTime", true)
        if cd and cd:IsA("TextLabel") and tostring(cd.Text) ~= "" and tostring(cd.Text) ~= "0" then return end
        pcall(function() btn:Activate() end)
    end

    local function amKiller()
        local c = LP.Character; local kf = getKillers(); return c and kf and c:IsDescendantOf(kf)
    end

    local activeBoxes = {} 
    local function spawnHitboxOnKiller(killer)
        if not Settings.ShowBox or not killer then return end
        for _, boxData in ipairs(activeBoxes) do
            if boxData.killer == killer then
                boxData.expire = tick() + Settings.BoxLingerTime
                return
            end
        end

        local box = Instance.new("Part")
        box.Name = "Inv_Hitbox"
        box.Size = Vector3.new(Settings.BoxWidth, Settings.BoxHeight, Settings.BoxLength)
        box.Anchored = true
        box.CanCollide = false; box.CanTouch = false; box.CanQuery = false; box.CastShadow = false
        box.Material = Enum.Material.ForceField
        box.Color = Color3.fromRGB(200, 30, 30) 
        box.Transparency = 0.5
        box.Parent = workspace
        
        local boxOutline = Instance.new("SelectionBox")
        boxOutline.Adornee = box
        boxOutline.LineThickness = 0.1
        boxOutline.Color3 = Color3.fromRGB(255, 0, 0)
        boxOutline.SurfaceTransparency = 0.8
        boxOutline.Parent = box
        
        table.insert(activeBoxes, {killer = killer, part = box, expire = tick() + Settings.BoxLingerTime})
    end

    game:GetService("RunService").RenderStepped:Connect(function()
        for i = #activeBoxes, 1, -1 do
            local data = activeBoxes[i]
            if tick() > data.expire or not data.killer.Parent then
                data.part:Destroy()
                table.remove(activeBoxes, i)
            else
                local hrp = data.killer:FindFirstChild("HumanoidRootPart")
                if hrp then data.part.CFrame = hrp.CFrame end
            end
        end
    end)

    local lastBlockAt = 0
    local function tryBlock()
        if not Settings.Enabled then return end
        if Settings.KillerPause and amKiller() then return end
        if tick() - lastBlockAt < 0.1 then return end
        lastBlockAt = tick()
        local d = math.clamp(Settings.BlockDelay, 0, 3)
        if d <= 0.01 then executeBlock() else task.delay(d, executeBlock) end
    end

    local hookedKillers = setmetatable({}, {__mode="k"})
    local lastAnimAt = setmetatable({}, {__mode="k"})
    local function hookKillerAnims(model)
        if hookedKillers[model] then return end
        hookedKillers[model] = true
        local hum = model:FindFirstChildOfClass("Humanoid")
        local animator = hum and hum:FindFirstChildOfClass("Animator")
        if not animator then return end
        
        animator.AnimationPlayed:Connect(function(track)
            if not Settings.Enabled then return end
            local id = track.Animation and track.Animation.AnimationId:match("%d+")
            local isAttack = false
            if id and ATTACK_ANIM_IDS[id] then isAttack = true
            else
                local name = track.Animation and track.Animation.Name:lower() or ""
                if not track.Looped and track.Length < 3.0 and not name:find("idle") and not name:find("walk") and not name:find("run") then isAttack = true end
            end
            
            if isAttack then
                local root = myRoot()
                local hrp = model:FindFirstChild("HumanoidRootPart")
                if hrp and root and (hrp.Position - root.Position).Magnitude <= Settings.TriggerRadius then
                    if tick() - (lastAnimAt[model] or 0) > 0.1 then
                        lastAnimAt[model] = tick()
                        spawnHitboxOnKiller(model)
                        tryBlock()
                    end
                end
            end
        end)
    end

    local hookedSounds = setmetatable({}, {__mode="k"})
    local lastSoundAt = {}
    local function onAnySound(s)
        if not Settings.Enabled or not s.IsPlaying then return end
        local id = tostring(s.SoundId):match("%d+")
        if not id or not ATTACK_SOUND_IDS[id] then return end
        if tick() - (lastSoundAt[id] or 0) < 0.1 then return end
        lastSoundAt[id] = tick()
        
        local root = myRoot(); if not root then return end
        local kf = getKillers(); if not kf then return end
        for _, k in ipairs(kf:GetChildren()) do
            if k:IsA("Model") then
                local hrp = k:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - root.Position).Magnitude <= Settings.TriggerRadius then
                    spawnHitboxOnKiller(k)
                    tryBlock()
                    break
                end
            end
        end
    end

    task.spawn(function()
        for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("Sound") then onAnySound(d) end end
        workspace.DescendantAdded:Connect(function(d) if d:IsA("Sound") then onAnySound(d) end end)
        while task.wait(1) do
            local kf = getKillers()
            if kf then for _, m in ipairs(kf:GetChildren()) do if m:IsA("Model") then hookKillerAnims(m) end end end
        end
    end)

    -- UI 部分
    local AutoBlockGroup = Tabs["自动格挡"]:AddLeftGroupbox("Auto Block", "shield")
    AutoBlockGroup:AddToggle("AutoBlock", {
        Text = "自动格挡（原版专用）", Default = false,
        Callback = function(v)
            Settings.Enabled = v
            notify("自动格挡", v and "已开启" or "已关闭")
            if _G.InvFloatBtn then
                if v then
                    _G.InvFloatBtn.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
                    _G.InvFloatBtn.Text = "Auto Block\nON"
                else
                    _G.InvFloatBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                    _G.InvFloatBtn.Text = "Auto Block\nOFF"
                end
            end
        end,
    })

    AutoBlockGroup:AddSlider("TriggerRadius", { Text = "触发距离", Default = 20, Min = 5, Max = 50, Rounding = 1, Callback = function(v) Settings.TriggerRadius = v end })
    AutoBlockGroup:AddDivider()
    AutoBlockGroup:AddSlider("BoxWidth", { Text = "框宽度", Default = 5, Min = 2, Max = 20, Rounding = 1, Callback = function(v) Settings.BoxWidth = v end })
    AutoBlockGroup:AddSlider("BoxLength", { Text = "框长度", Default = 8, Min = 2, Max = 20, Rounding = 1, Callback = function(v) Settings.BoxLength = v end })
    AutoBlockGroup:AddSlider("BoxHeight", { Text = "框高度", Default = 7, Min = 2, Max = 20, Rounding = 1, Callback = function(v) Settings.BoxHeight = v end })

    local SettingsGroup = Tabs["设置"]:AddLeftGroupbox("菜单", "settings")
    SettingsGroup:AddLabel("菜单快捷键"):AddKeyPicker("MenuKey", { Default = "RightShift", NoUI = true, Text = "菜单快捷键" })
    NewLibrary.ToggleKeybind = NewLibrary.Options.MenuKey
    SettingsGroup:AddButton("卸载脚本", function() NewLibrary:Unload() end)

    ThemeManager:SetLibrary(NewLibrary)
    ThemeManager:SetDefaultTheme({ BackgroundColor = Color3.fromRGB(26, 26, 46), AccentColor = Color3.fromRGB(137, 180, 250), OutlineColor = Color3.fromRGB(49, 50, 68), FontColor = Color3.fromRGB(205, 214, 244), FontFace = Enum.Font.Jura })
    SaveManager:SetLibrary(NewLibrary)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ "MenuKey" })
    SaveManager:SetFolder("InvHub")
    SaveManager:BuildConfigSection(Tabs["设置"])
    ThemeManager:ApplyToTab(Tabs["设置"])

    -- 悬浮按钮（绿开红关）
    local invGui = Instance.new("ScreenGui")
    invGui.Name = "Inv_UI"; invGui.ResetOnSpawn = false; invGui.DisplayOrder = 999; invGui.Parent = PlayerGui
    _G.InvGui = invGui

    local floatBtn = Instance.new("TextButton")
    floatBtn.Size = UDim2.new(0, 90, 0, 90) 
    floatBtn.Position = UDim2.new(0, 20, 0, 150)
    floatBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50) 
    floatBtn.Text = "Auto Block\nOFF"
    floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    floatBtn.Font = Enum.Font.GothamBlack
    floatBtn.TextSize = 14
    floatBtn.AutoButtonColor = false
    floatBtn.Parent = invGui
    _G.InvFloatBtn = floatBtn

    local fCorner = Instance.new("UICorner"); fCorner.CornerRadius = UDim.new(1, 0); fCorner.Parent = floatBtn
    local fStroke = Instance.new("UIStroke"); fStroke.Color = Color3.fromRGB(255, 255, 255); fStroke.Thickness = 3; fStroke.Parent = floatBtn

    local dragging, dragStart, startPos, wasDragged = false, nil, nil, false
    floatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; wasDragged = false; dragStart = input.Position; startPos = floatBtn.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
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
            floatBtn.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
            floatBtn.Text = "Auto Block\nON"
        else
            floatBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            floatBtn.Text = "Auto Block\nOFF"
        end
        if NewLibrary.Options.AutoBlock then
            pcall(function() NewLibrary.Options.AutoBlock:SetValue(Settings.Enabled) end)
        end
    end)

    notify("Inv", "已解锁 | 按 RightShift 打开菜单")
end
