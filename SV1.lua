-- ========================================
-- LnvAutoBlock 鉴权网关 (古诗答题版)
-- ========================================

local Players      = game:GetService("Players")
local LP           = Players.LocalPlayer

local repo    = "https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
Library.ShowCustomCursor = true

local AuthWindow = Library:CreateWindow({
    Title = "LnvAutoBlock 登录",
    Footer = "请完成验证",
    Icon = "rbxassetid://4483362748",
    Center = true,
    AutoShow = true,
    Resizable = false,
    NotifySide = "Right",
    ToggleKeybind = Enum.KeyCode.RightShift
})

local AuthTab = AuthWindow:AddTab("验证", "lock")

local isAuthorized = false
_G.InvAuth = _G.InvAuth or { NormalKey = nil, ExpireTime = 0 }

-- 永久与VIP卡密
local PermanentKeys = {
    ["LNV_7b3a80daa6a87f7a0385aa4485894526"] = true, -- 作者卡密
    ["LNV_9f2c4e1a7b3d8056c9e2f4a1b7d36085"] = true, -- 普通永久卡密
    ["VIP_c4e8a2f6b1d39075e2a4c6f8b1d30579"] = true, -- 新增VIP卡密
}

-- 50 个普通卡密池（保持原来的）
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

local function validateKey(input)
    if type(input) == "string" then input = input:gsub("^%s*(.-)%s*$", "%1") else return false, "Invalid" end
    if PermanentKeys[input] then return true, "Permanent" end
    if _G.InvAuth.NormalKey and input == _G.InvAuth.NormalKey then
        if os.time() < _G.InvAuth.ExpireTime then return true, "Normal" else return false, "Expired" end
    end
    return false, "Invalid"
end

local AuthGroup = AuthTab:AddLeftGroupbox("卡密验证", "key")
AuthGroup:AddInput("KeyInput", { Text = "输入卡密", Default = "", Placeholder = "在此粘贴卡密...", ClearTextOnFocus = false, Finished = true })

AuthGroup:AddButton("确认并解锁", function()
    local isValid, keyType = validateKey(Library.Options.KeyInput.Value)
    if isValid then
        isAuthorized = true
        Library:Notify({Title = "授权成功", Description = "正在加载主功能...", Time = 3})
        
        task.spawn(function()
            local ok, err = pcall(function()
                -- 这里加载你的主脚本
                loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/jsheh2131345/YG@main/LnvAutoBlock_SCRIRT_67.lua"))()
            end)
            
            if ok then
                task.wait(0.2)
                pcall(function() Library:Unload() end)
            else
                Library:Notify({Title = "加载失败", Description = tostring(err), Time = 5})
            end
        end)
    else
        if keyType == "Expired" then
            Library:Notify({Title = "卡密过期", Description = "普通卡密已过期，请答题获取新卡密！", Time = 4})
        else
            Library:Notify({Title = "授权失败", Description = "卡密错误！", Time = 3})
        end
    end
end)

AuthGroup:AddDivider()
AuthGroup:AddButton("不想答题？复制官方 QQ 群", function()
    if setclipboard then setclipboard("1136413909") Library:Notify({Title = "已复制", Description = "QQ群号: 1136413909", Time = 3})
    else Library:Notify({Title = "复制失败", Description = "执行器不支持", Time = 3}) end
end)

-- ============================================
-- 答题区：唐诗三百首
-- ============================================
local QuizGroup = AuthTab:AddRightGroupbox("答题续命 (普通卡密)", "help-circle")
QuizGroup:AddLabel("提示：答对 10 道唐诗填空题即可获取普通卡密", true)

local quizState = { progress = 0, questions = {} }
local ProgressLabel = QuizGroup:AddLabel("进度: 0 / 10", true)
local MathLabel = QuizGroup:AddLabel("题目: 点击下方按钮开始", true)
local AnswerInput = QuizGroup:AddInput("MathInput", { Text = "答案", Default = "", Placeholder = "输入汉字或诗句...", Finished = false })

-- 题库池
local poemBank = {
    { q = "举头望明月，下一句是？", a = "低头思故乡" },
    { q = "春眠不觉晓，下一句是？", a = "处处闻啼鸟" },
    { q = "白日依山尽，下一句是？", a = "黄河入海流" },
    { q = "欲穷千里目，下一句是？", a = "更上一层楼" },
    { q = "锄禾日当午，下一句是？", a = "汗滴禾下土" },
    { q = "谁知盘中餐，下一句是？", a = "粒粒皆辛苦" },
    { q = "离离原上草，下一句是？", a = "一岁一枯荣" },
    { q = "野火烧不尽，下一句是？", a = "春风吹又生" },
    { q = "千山鸟飞绝，下一句是？", a = "万径人踪灭" },
    { q = "孤舟蓑笠翁，下一句是？", a = "独钓寒江雪" },
    { q = "空山不见人，下一句是？", a = "但闻人语响" },
    { q = "红豆生南国，下一句是？", a = "春来发几枝" },
    { q = "松下问童子，下一句是？", a = "言师采药去" },
    { q = "只在此山中，下一句是？", a = "云深不知处" },
    { q = "向晚意不适，下一句是？", a = "驱车登古原" },
    { q = "夕阳无限好，下一句是？", a = "只是近黄昏" },
    { q = "独坐幽篁里，下一句是？", a = "弹琴复长啸" },
    { q = "深林人不知，下一句是？", a = "明月来相照" },
    { q = "好雨知时节，下一句是？", a = "当春乃发生" },
    { q = "随风潜入夜，下一句是？", a = "润物细无声" }
}

local function generateQuiz()
    quizState.questions = {}
    local pool = {}
    for i = 1, #poemBank do pool[i] = poemBank[i] end
    -- 打乱题库
    for i = #pool, 2, -1 do
        local j = math.random(1, i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    -- 取前 10 个
    for i = 1, 10 do
        table.insert(quizState.questions, pool[i])
    end
end

local CopyBtn = QuizGroup:AddButton("已生成卡密，点此复制", function()
    if _G.InvAuth.NormalKey then
        if setclipboard then setclipboard(_G.InvAuth.NormalKey) end
        Library:Notify({Title = "已复制", Description = _G.InvAuth.NormalKey, Time = 3})
    end
end)
CopyBtn:SetVisible(false)

QuizGroup:AddButton("提交答案", function()
    if quizState.progress >= 10 or MathLabel.Text == "题目: 点击下方按钮开始" then return end
    local userAns = tostring(AnswerInput.Value):gsub("%s+", "") -- 去除所有空格
    local currentQuestion = quizState.questions[quizState.progress + 1]
    
    if userAns == currentQuestion.a then
        quizState.progress = quizState.progress + 1
        ProgressLabel:SetText("进度: " .. quizState.progress .. " / 10")
        Library:Notify({Title = "回答正确", Description = "继续下一题！", Time = 1})
        if quizState.progress >= 10 then
            local newKey = NormalKeyPool[math.random(1, #NormalKeyPool)]
            _G.InvAuth.NormalKey = newKey
            _G.InvAuth.ExpireTime = os.time() + 86400
            MathLabel:SetText("题目: 答题完成！卡密已生成")
            AnswerInput:SetVisible(false)
            CopyBtn:SetVisible(true)
            if setclipboard then setclipboard(newKey) end
            Library:Notify({Title = "生成成功", Description = "新卡密已复制，有效期24小时！", Time = 5})
        else
            MathLabel:SetText("题目: " .. quizState.questions[quizState.progress + 1].q)
            AnswerInput:SetValue("")
        end
    else
        Library:Notify({Title = "回答错误", Description = "重新思考一下吧！", Time = 2})
    end
end)

QuizGroup:AddButton("获取普通卡密 (答题)", function()
    quizState.progress = 0
    ProgressLabel:SetText("进度: 0 / 10")
    generateQuiz()
    MathLabel:SetText("题目: " .. quizState.questions[1].q)
    AnswerInput:SetVisible(true)
    CopyBtn:SetVisible(false)
    Library:Notify({Title = "开始答题", Description = "答对10道古诗题即可获得卡密！", Time = 3})
end)

if _G.InvAuth.NormalKey and os.time() < _G.InvAuth.ExpireTime then
    local remainingHours = math.floor((_G.InvAuth.ExpireTime - os.time()) / 3600)
    Library:Notify({Title = "检测到有效卡密", Description = "你的普通卡密还剩 " .. remainingHours .. " 小时", Time = 5})
    AuthGroup:AddLabel("当前可用普通卡密: " .. _G.InvAuth.NormalKey, true)
end
