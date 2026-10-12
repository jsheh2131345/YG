-- ========================================
-- CN SCRIRT
-- 作者：我已经绷住了
-- 适配：被遗弃
-- 版本：1.8
-- 功能：自动格挡1.0/2.0/3.0 + 出拳 + Anti + 透视 + 无限体力
-- ========================================

local repo = 'https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor = true
Library.NotifySide = "Right"

local Window = Library:CreateWindow({
    Title = 'CN SCRIRT',
    Footer = "我已经绷住了",
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
    Main = Window:AddTab('主功能', 'house'),
    Block2 = Window:AddTab('自动格挡2.0', 'shield-check'),
    Block3 = Window:AddTab('自动格挡3.0', 'shield-plus'),
    Punch = Window:AddTab('出拳', 'hand'),
    Anti = Window:AddTab('免疫', 'shield'),
    Info = Window:AddTab('信息', 'info'),
    ["UI设置"] = Window:AddTab('UI设置', 'settings')
}

local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ============================================
-- 通用工具
-- ============================================
local function getBlockButton()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local main = pg:FindFirstChild("MainUI")
    if not main then return nil end
    local container = main:FindFirstChild("AbilityContainer")
    if not container then return nil end
    return container:FindFirstChild("Block") or container:FindFirstChild("Guard")
end

local function executeBlock()
    local btn = getBlockButton()
    if not btn then return false end
    local cd = btn:FindFirstChild("CooldownTime")
    if cd and cd.Text ~= "" then return false end
    pcall(function() btn:Activate() end)
    pcall(function()
        for _, conn in ipairs(getconnections(btn.MouseButton1Click) or {}) do
            conn:Fire()
        end
    end)
    return true
end

-- ============================================
-- 关键词表
-- ============================================
local NormalAttackHitboxKeywords = {
    "QueryHitbox", "AttackHitbox", "M1Hitbox", "PunchHitbox",
    "BasicAttack", "NormalAttack", "MeleeHitbox", "SlashHitbox",
    "Hitbox", "MeleeZone", "AttackZone", "DamageZone"
}

local ExcludeHitboxKeywords = {
    "Skill", "Ult", "Ultimate", "AOE", "Circle", "Trap",
    "Zone", "Projectile", "Range", "Ranged", "Dash",
    "Charge", "Special", "Ability", "Aura", "Shockwave",
    "Wave", "Explosion", "Fire", "Ice", "Magic", "Spell"
}

local function isNormalAttackHitbox(obj)
    if not obj then return false end
    if not (obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation")) then
        return false
    end
    local lowerName = obj.Name:lower()
    for _, kw in ipairs(ExcludeHitboxKeywords) do
        if lowerName:find(kw:lower()) then return false end
    end
    for _, kw in ipairs(NormalAttackHitboxKeywords) do
        if lowerName:find(kw:lower()) then return true end
    end
    return false
end

-- ============================================
-- 音效/动画 ID 表
-- ============================================
local AttackSoundIDs = {
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

local AttackAnimIDs = {
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
-- 自动格挡 1.0
-- ============================================
local BlockSettings = {
    Enabled = false,
    HitboxMode = true,
    SoundAnimMode = false,
    TriggerDistance = 20,
    HitboxDistance = 10,
    ShowRangeVisual = false,
    FacingCheck = true,
    WallCheck = true,
    BlockDelay = 0.02,
    RandomDelay = false,
    RandomRange = 0.05,
}

local function getBlockDelay()
    if BlockSettings.RandomDelay then
        local offset = (math.random() * 2 - 1) * BlockSettings.RandomRange
        return math.clamp(BlockSettings.BlockDelay + offset, 0, 1.0)
    end
    return math.clamp(BlockSettings.BlockDelay, 0, 1.0)
end

local pendingBlock = nil
local function pressBlock()
    if pendingBlock then
        task.cancel(pendingBlock)
        pendingBlock = nil
    end
    local d = getBlockDelay()
    if d <= 0.01 then
        executeBlock()
    else
        pendingBlock = task.delay(d, function()
            executeBlock()
            pendingBlock = nil
        end)
    end
end

local function isKillerFacingPlayer(killerRoot)
    if not BlockSettings.FacingCheck then return true end
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not killerRoot then return false end
    local toPlayer = (myRoot.Position - killerRoot.Position).Unit
    local killerLook = killerRoot.CFrame.LookVector
    local dot = killerLook:Dot(toPlayer)
    local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
    return angle <= 85
end

local function hasLineOfSight(targetRoot)
    if not BlockSettings.WallCheck then return true end
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not targetRoot then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    params.FilterDescendantsInstances = {player.Character}
    local result = ws:Raycast(myRoot.Position, targetRoot.Position - myRoot.Position, params)
    return not result or result.Instance:IsDescendantOf(targetRoot.Parent)
end

local hitboxConns = {}
local hitboxBlockedUntil = {}

local function attemptBlockFromHitbox(hitbox)
    if not BlockSettings.Enabled then return end
    if not BlockSettings.HitboxMode then return end
    if not hitbox or not hitbox.Parent then return end
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local dist = (hitbox.Position - myRoot.Position).Magnitude
    if dist > BlockSettings.HitboxDistance then return end
    local t = tick()
    if hitboxBlockedUntil[hitbox] and t < hitboxBlockedUntil[hitbox] then return end
    local killerModel = hitbox:FindFirstAncestorOfClass("Model")
    local killerRoot = killerModel and killerModel:FindFirstChild("HumanoidRootPart")
    if killerRoot then
        if not isKillerFacingPlayer(killerRoot) then return end
        if not hasLineOfSight(killerRoot) then return end
    end
    pressBlock()
    hitboxBlockedUntil[hitbox] = t + 0.1
end

local function watchHitbox(hitbox)
    if hitboxConns[hitbox] then return end
    local conn = hitbox:GetPropertyChangedSignal("Position"):Connect(function()
        pcall(attemptBlockFromHitbox, hitbox)
    end)
    hitboxConns[hitbox] = conn
    hitbox.Destroying:Connect(function()
        if hitboxConns[hitbox] then
            hitboxConns[hitbox]:Disconnect()
            hitboxConns[hitbox] = nil
        end
        hitboxBlockedUntil[hitbox] = nil
    end)
end

local function scanAllHitboxes()
    for _, obj in ipairs(ws:GetDescendants()) do
        if isNormalAttackHitbox(obj) then
            watchHitbox(obj)
        end
    end
end

local soundHooks = {}
local soundBlockedUntil = {}
local animConns = {}
local animBlockedUntil = {}

local function getSoundIdNumber(sound)
    return tostring(sound.SoundId):match("%d+")
end

local function getKillerRootFromSound(sound)
    local soundModel = sound.Parent
    while soundModel and not soundModel:IsA("Model") do
        soundModel = soundModel.Parent
    end
    if soundModel then
        return soundModel:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function attemptBlockFromSound(sound)
    if not BlockSettings.Enabled then return end
    if not BlockSettings.SoundAnimMode then return end
    if not sound or not sound:IsA("Sound") or not sound.IsPlaying then return end
    local id = getSoundIdNumber(sound)
    if not id or not AttackSoundIDs[id] then return end
    local t = tick()
    if soundBlockedUntil[sound] and t < soundBlockedUntil[sound] then return end
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local killerRoot = getKillerRootFromSound(sound)
    if killerRoot then
        if (killerRoot.Position - myRoot.Position).Magnitude > BlockSettings.TriggerDistance then return end
        if not isKillerFacingPlayer(killerRoot) then return end
        if not hasLineOfSight(killerRoot) then return end
    end
    pressBlock()
    soundBlockedUntil[sound] = t + 0.05
end

local function hookSound(sound)
    if not sound:IsA("Sound") or soundHooks[sound] then return end
    local playedConn = sound.Played:Connect(function()
        pcall(attemptBlockFromSound, sound)
    end)
    local propConn = sound:GetPropertyChangedSignal("IsPlaying"):Connect(function()
        if sound.IsPlaying then pcall(attemptBlockFromSound, sound) end
    end)
    local destroyConn = sound.Destroying:Connect(function()
        playedConn:Disconnect()
        propConn:Disconnect()
        destroyConn:Disconnect()
        soundHooks[sound] = nil
        soundBlockedUntil[sound] = nil
    end)
    soundHooks[sound] = {playedConn, propConn, destroyConn}
    if sound.IsPlaying then
        task.spawn(function() pcall(attemptBlockFromSound, sound) end)
    end
end

local function watchKillerAnimations(killerModel)
    if animConns[killerModel] then return end
    local h = killerModel:FindFirstChildOfClass("Humanoid")
    if not h then return end
    local animator = h:FindFirstChildOfClass("Animator")
    if not animator then return end
    local conn = animator.AnimationPlayed:Connect(function(track)
        if not BlockSettings.Enabled then return end
        if not BlockSettings.SoundAnimMode then return end
        local animId = track.Animation.AnimationId:match("%d+")
        if not animId or not AttackAnimIDs[animId] then return end
        local t = tick()
        if animBlockedUntil[killerModel] and t < animBlockedUntil[killerModel] then return end
        local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        local killerRoot = killerModel:FindFirstChild("HumanoidRootPart")
        if killerRoot then
            if (killerRoot.Position - myRoot.Position).Magnitude > BlockSettings.TriggerDistance then return end
            if not isKillerFacingPlayer(killerRoot) then return end
            if not hasLineOfSight(killerRoot) then return end
        end
        pressBlock()
        animBlockedUntil[killerModel] = t + 0.05
    end)
    animConns[killerModel] = conn
    killerModel.AncestryChanged:Connect(function()
        if not killerModel.Parent then
            if animConns[killerModel] then
                animConns[killerModel]:Disconnect()
                animConns[killerModel] = nil
            end
            animBlockedUntil[killerModel] = nil
        end
    end)
end

local function bindExistingKillers()
    local killersFolder = ws:FindFirstChild("Players") and ws.Players:FindFirstChild("Killers")
    if not killersFolder then return end
    for _, model in ipairs(killersFolder:GetChildren()) do
        if model:IsA("Model") then watchKillerAnimations(model) end
    end
end

-- ============================================
-- 自动格挡 2.0（普攻白色碰撞箱 + 玩家在框内即格挡）
-- ============================================
local Block2Settings = {
    Enabled = false,
    BoxLength = 8,
    BoxWidth = 6,
    BoxHeight = 8,
    BoxTransparency = 0.5,
    BoxColor = Color3.fromRGB(255, 255, 255),
    HitboxDistance = 30,
    BlockDelay = 0.02,
    RandomDelay = false,
    RandomRange = 0.05,
    ShowVisual = true,
}

local Block2Visuals = {}

local function isBlock2Hitbox(obj)
    return isNormalAttackHitbox(obj)
end

local function isPlayerInsideBox(boxPart)
    if not boxPart or not boxPart.Parent then return false end
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return false end
    local relative = boxPart.CFrame:PointToObjectSpace(myRoot.Position)
    local halfX = boxPart.Size.X / 2
    local halfY = boxPart.Size.Y / 2
    local halfZ = boxPart.Size.Z / 2
    return math.abs(relative.X) <= halfX
        and math.abs(relative.Y) <= halfY
        and math.abs(relative.Z) <= halfZ
end

local function block2PressBlock()
    if Block2Settings.RandomDelay then
        local offset = (math.random() * 2 - 1) * Block2Settings.RandomRange
        local d = math.clamp(Block2Settings.BlockDelay + offset, 0, 1.0)
        task.delay(d, executeBlock)
    else
        task.delay(Block2Settings.BlockDelay, executeBlock)
    end
end

local function checkAndBlock2(hitbox, box)
    if not Block2Settings.Enabled then return end
    if not hitbox or not hitbox.Parent then return end
    if not box or not box.Parent then return end
    if isPlayerInsideBox(box) then
        local killerModel = hitbox:FindFirstAncestorOfClass("Model")
        local killerRoot = killerModel and killerModel:FindFirstChild("HumanoidRootPart")
        if killerRoot then
            local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if myRoot and (killerRoot.Position - myRoot.Position).Magnitude <= Block2Settings.HitboxDistance then
                block2PressBlock()
            end
        end
    end
end

local function createBlock2Visual(hitbox)
    if Block2Visuals[hitbox] then return end
    local box = Instance.new("Part")
    box.Name = "CN_Block2Box"
    box.Size = Vector3.new(Block2Settings.BoxWidth, Block2Settings.BoxHeight, Block2Settings.BoxLength)
    box.Color = Block2Settings.BoxColor
    box.Material = Enum.Material.ForceField
    box.Transparency = Block2Settings.BoxTransparency
    box.Anchored = true
    box.CanCollide = false
    box.CastShadow = false
    box.CFrame = hitbox.CFrame
    box.Parent = ws

    local visConn = RunService.Heartbeat:Connect(function()
        if not Block2Settings.Enabled then
            if box.Parent then box.Transparency = 1 end
            return
        end
        if not hitbox or not hitbox.Parent then
            box:Destroy()
            if visConn then visConn:Disconnect() end
            Block2Visuals[hitbox] = nil
            return
        end
        box.Size = Vector3.new(Block2Settings.BoxWidth, Block2Settings.BoxHeight, Block2Settings.BoxLength)
        box.CFrame = hitbox.CFrame
        box.Color = Block2Settings.BoxColor
        box.Transparency = Block2Settings.ShowVisual and Block2Settings.BoxTransparency or 0.95
        checkAndBlock2(hitbox, box)
    end)

    local attachConn = hitbox:GetPropertyChangedSignal("CFrame"):Connect(function()
        if not Block2Settings.Enabled then return end
        if not box.Parent then return end
        box.CFrame = hitbox.CFrame
        checkAndBlock2(hitbox, box)
    end)

    task.defer(function() checkAndBlock2(hitbox, box) end)

    Block2Visuals[hitbox] = {box = box, visConn = visConn, attachConn = attachConn}
end

local function scanBlock2Hitboxes()
    for _, obj in ipairs(ws:GetDescendants()) do
        if isBlock2Hitbox(obj) then createBlock2Visual(obj) end
    end
end

-- ============================================
-- 自动格挡 3.0（Nolsaken 同款）
-- ============================================
local Block3Settings = {
    Enabled = false,
    TriggerDistance = 20,
    FacingAngle = 85,
    WallCheck = true,
    BlockDelay = 0.02,
    RandomDelay = false,
    RandomRange = 0.05,
    ShowRangeVisual = false,
    AuraRange = 15,
}

local Block3_pendingBlock = nil
local function block3_pressBlock()
    if Block3_pendingBlock then
        task.cancel(Block3_pendingBlock)
        Block3_pendingBlock = nil
    end
    local d = Block3Settings.BlockDelay
    if Block3Settings.RandomDelay then
        local offset = (math.random() * 2 - 1) * Block3Settings.RandomRange
        d = math.clamp(d + offset, 0, 1.0)
    end
    if d <= 0.01 then
        executeBlock()
    else
        Block3_pendingBlock = task.delay(d, function()
            executeBlock()
            Block3_pendingBlock = nil
        end)
    end
end

local function block3_isKillerFacing(killerRoot)
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not killerRoot then return false end
    local toPlayer = (myRoot.Position - killerRoot.Position).Unit
    local killerLook = killerRoot.CFrame.LookVector
    local dot = killerLook:Dot(toPlayer)
    local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
    return angle <= Block3Settings.FacingAngle
end

local function block3_hasLineOfSight(killerRoot)
    if not Block3Settings.WallCheck then return true end
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not killerRoot then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    params.FilterDescendantsInstances = {player.Character}
    local result = ws:Raycast(myRoot.Position, killerRoot.Position - myRoot.Position, params)
    return not result or result.Instance:IsDescendantOf(killerRoot.Parent)
end

-- Block3 用音效 + 动画检测（Nolsaken 同款）
local block3_soundHooks = {}
local block3_soundBlockedUntil = {}
local block3_animConns = {}
local block3_animBlockedUntil = {}

local function block3_attemptFromSound(sound)
    if not Block3Settings.Enabled then return end
    if not sound or not sound:IsA("Sound") or not sound.IsPlaying then return end
    local id = getSoundIdNumber(sound)
    if not id or not AttackSoundIDs[id] then return end
    local t = tick()
    if block3_soundBlockedUntil[sound] and t < block3_soundBlockedUntil[sound] then return end
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local killerRoot = getKillerRootFromSound(sound)
    if killerRoot then
        if (killerRoot.Position - myRoot.Position).Magnitude > Block3Settings.TriggerDistance then return end
        if not block3_isKillerFacing(killerRoot) then return end
        if not block3_hasLineOfSight(killerRoot) then return end
    end
    block3_pressBlock()
    block3_soundBlockedUntil[sound] = t + 0.05
end

local function block3_hookSound(sound)
    if not sound:IsA("Sound") or block3_soundHooks[sound] then return end
    local c1 = sound.Played:Connect(function()
        pcall(block3_attemptFromSound, sound)
    end)
    local c2 = sound:GetPropertyChangedSignal("IsPlaying"):Connect(function()
        if sound.IsPlaying then pcall(block3_attemptFromSound, sound) end
    end)
    local c3 = sound.Destroying:Connect(function()
        c1:Disconnect()
        c2:Disconnect()
        c3:Disconnect()
        block3_soundHooks[sound] = nil
        block3_soundBlockedUntil[sound] = nil
    end)
    block3_soundHooks[sound] = {c1, c2, c3}
    if sound.IsPlaying then
        task.spawn(function() pcall(block3_attemptFromSound, sound) end)
    end
end

local function block3_watchKiller(killerModel)
    if block3_animConns[killerModel] then return end
    local h = killerModel:FindFirstChildOfClass("Humanoid")
    if not h then return end
    local animator = h:FindFirstChildOfClass("Animator")
    if not animator then return end
    local conn = animator.AnimationPlayed:Connect(function(track)
        if not Block3Settings.Enabled then return end
        local animId = track.Animation.AnimationId:match("%d+")
        if not animId or not AttackAnimIDs[animId] then return end
        local t = tick()
        if block3_animBlockedUntil[killerModel] and t < block3_animBlockedUntil[killerModel] then return end
        local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        local killerRoot = killerModel:FindFirstChild("HumanoidRootPart")
        if killerRoot then
            if (killerRoot.Position - myRoot.Position).Magnitude > Block3Settings.TriggerDistance then return end
            if not block3_isKillerFacing(killerRoot) then return end
            if not block3_hasLineOfSight(killerRoot) then return end
        end
        block3_pressBlock()
        block3_animBlockedUntil[killerModel] = t + 0.05
    end)
    block3_animConns[killerModel] = conn
    killerModel.AncestryChanged:Connect(function()
        if not killerModel.Parent then
            if block3_animConns[killerModel] then
                block3_animConns[killerModel]:Disconnect()
                block3_animConns[killerModel] = nil
            end
            block3_animBlockedUntil[killerModel] = nil
        end
    end)
end

local function block3_bindExisting()
    local killersFolder = ws:FindFirstChild("Players") and ws.Players:FindFirstChild("Killers")
    if not killersFolder then return end
    for _, model in ipairs(killersFolder:GetChildren()) do
        if model:IsA("Model") then block3_watchKiller(model) end
    end
end

-- Block3 可视化圈
local block3_aura = nil
local function block3_updateAura()
    if not Block3Settings.Enabled or not Block3Settings.ShowRangeVisual then
        if block3_aura then block3_aura:Destroy() block3_aura = nil end
        return
    end
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    if not block3_aura or not block3_aura.Parent then
        block3_aura = Instance.new("Part")
        block3_aura.Name = "CN_Block3Aura"
        block3_aura.Shape = Enum.PartType.Ball
        block3_aura.Material = Enum.Material.ForceField
        block3_aura.Color = Color3.fromRGB(0, 200, 255)
        block3_aura.Transparency = 0.85
        block3_aura.Anchored = true
        block3_aura.CanCollide = false
        block3_aura.Parent = ws
    end
    block3_aura.Size = Vector3.new(Block3Settings.AuraRange * 2, Block3Settings.AuraRange * 2, Block3Settings.AuraRange * 2)
    block3_aura.CFrame = myRoot.CFrame
end

RunService.Heartbeat:Connect(function()
    block3_updateAura()
end)

local function block3_enable()
    for _, sound in ipairs(ws:GetDescendants()) do
        if sound:IsA("Sound") then pcall(block3_hookSound, sound) end
    end
    block3_bindExisting()
end

-- ============================================
-- 初始化
-- ============================================
if BlockSettings.Enabled then scanAllHitboxes() end
if Block2Settings.Enabled then scanBlock2Hitboxes() end

local killersFolder = ws:FindFirstChild("Players") and ws.Players:FindFirstChild("Killers")
if killersFolder then
    killersFolder.ChildAdded:Connect(function(model)
        if model:IsA("Model") then
            task.wait(0.5)
            watchKillerAnimations(model)
            block3_watchKiller(model)
        end
    end)
    bindExistingKillers()
end

player.CharacterAdded:Connect(function()
    task.wait(1)
    bindExistingKillers()
    block3_bindExisting()
    if BlockSettings.Enabled then scanAllHitboxes() end
    if Block2Settings.Enabled then scanBlock2Hitboxes() end
end)

for _, sound in ipairs(ws:GetDescendants()) do
    if sound:IsA("Sound") then
        if BlockSettings.SoundAnimMode then pcall(hookSound, sound) end
        if Block3Settings.Enabled then pcall(block3_hookSound, sound) end
    end
end

ws.DescendantAdded:Connect(function(obj)
    -- 自动格挡 1.0
    if BlockSettings.Enabled and BlockSettings.HitboxMode then
        if isNormalAttackHitbox(obj) then
            task.spawn(function()
                task.wait(0.1)
                watchHitbox(obj)
            end)
        end
    end
    -- 自动格挡 2.0
    if Block2Settings.Enabled then
        if isBlock2Hitbox(obj) then
            task.spawn(function()
                task.wait(0.1)
                createBlock2Visual(obj)
            end)
        end
    end
    -- 3.0 音效监听
    if obj:IsA("Sound") then
        if BlockSettings.SoundAnimMode then pcall(hookSound, obj) end
        if Block3Settings.Enabled then pcall(block3_hookSound, obj) end
    end
end)
-- ============================================
-- 出拳自瞄（Guest 1337）
-- ============================================
local PunchSettings = {
    AutoPunch = false,
    AutoAim = true,
    AimMode = "Character",
    AimSpeed = 0.5,
    Range = 15,
    Visible = false,
}

local punchAura = nil
local punchRunning = false
local punchConn = nil

local function getPunchButton()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local main = pg:FindFirstChild("MainUI")
    if not main then return nil end
    local container = main:FindFirstChild("AbilityContainer")
    if not container then return nil end
    return container:FindFirstChild("Punch") or container:FindFirstChild("Attack")
end

local function doPunch()
    local btn = getPunchButton()
    if not btn then return false end
    local charges = btn:FindFirstChild("Charges")
    if charges then
        local c = tonumber(charges.Text) or 0
        if c < 1 then return false end
    end
    pcall(function() btn:Activate() end)
    pcall(function()
        for _, conn in ipairs(getconnections(btn.MouseButton1Click) or {}) do
            conn:Fire()
        end
    end)
    return true
end

local function getNearestKiller()
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local killersFolder = ws:FindFirstChild("Players") and ws.Players:FindFirstChild("Killers")
    if not killersFolder then return nil end
    local best, bestDist = nil, math.huge
    for _, k in ipairs(killersFolder:GetChildren()) do
        local hrp = k:FindFirstChild("HumanoidRootPart")
        local h = k:FindFirstChildOfClass("Humanoid")
        if hrp and h and h.Health > 0 then
            local d = (hrp.Position - myRoot.Position).Magnitude
            if d < bestDist and d <= PunchSettings.Range then
                bestDist = d
                best = hrp
            end
        end
    end
    return best
end

local function createPunchAura()
    if punchAura then punchAura:Destroy() end
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local part = Instance.new("Part")
    part.Name = "CN_PunchAura"
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(PunchSettings.Range * 2, PunchSettings.Range * 2, PunchSettings.Range * 2)
    part.Color = Color3.fromRGB(255, 100, 255)
    part.Material = Enum.Material.ForceField
    part.Transparency = 0.85
    part.Anchored = true
    part.CanCollide = false
    part.Parent = ws
    punchAura = part
end

local function updatePunchAura()
    if not punchAura or not punchAura.Parent then return end
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if myRoot then
        punchAura.CFrame = myRoot.CFrame
        punchAura.Size = Vector3.new(PunchSettings.Range * 2, PunchSettings.Range * 2, PunchSettings.Range * 2)
    end
end

local function startPunch()
    if punchRunning then return end
    punchRunning = true
    punchConn = RunService.RenderStepped:Connect(function()
        if not PunchSettings.AutoPunch then return end
        local target = getNearestKiller()
        if target and PunchSettings.AutoAim then
            local myChar = player.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myRoot then
                local cam = ws.CurrentCamera
                if PunchSettings.AimMode == "Character" then
                    local lerpCF = CFrame.lookAt(myRoot.Position, Vector3.new(target.Position.X, myRoot.Position.Y, target.Position.Z))
                    myRoot.CFrame = myRoot.CFrame:Lerp(lerpCF, PunchSettings.AimSpeed)
                elseif PunchSettings.AimMode == "Camera" and cam then
                    local camLook = CFrame.lookAt(cam.CFrame.Position, target.Position)
                    cam.CFrame = cam.CFrame:Lerp(camLook, PunchSettings.AimSpeed)
                else
                    local lerpCF = CFrame.lookAt(myRoot.Position, Vector3.new(target.Position.X, myRoot.Position.Y, target.Position.Z))
                    myRoot.CFrame = myRoot.CFrame:Lerp(lerpCF, PunchSettings.AimSpeed)
                    if cam then
                        local camLook = CFrame.lookAt(cam.CFrame.Position, target.Position)
                        cam.CFrame = cam.CFrame:Lerp(camLook, PunchSettings.AimSpeed)
                    end
                end
            end
        end
        if target then doPunch() end
    end)
    if PunchSettings.Visible then createPunchAura() end
end

local function stopPunch()
    punchRunning = false
    if punchConn then punchConn:Disconnect() punchConn = nil end
    if punchAura then punchAura:Destroy() punchAura = nil end
end

-- ============================================
-- 无限体力（Feng-Yu 同款）
-- ============================================
local StaminaModule = nil
local StaminaDefaults = nil

local function GetStaminaModule()
    if StaminaModule then return StaminaModule end
    local ok, module = pcall(function()
        return require(rs:WaitForChild("Systems")
            :WaitForChild("Character")
            :WaitForChild("Game")
            :WaitForChild("Sprinting"))
    end)
    if ok and module then
        StaminaModule = module
        if not StaminaDefaults then
            StaminaDefaults = {
                MaxStamina = module.MaxStamina,
                StaminaGain = module.StaminaGain,
                StaminaLoss = module.StaminaLoss,
                SprintSpeed = module.SprintSpeed,
            }
        end
        return module
    end
    return nil
end

local StaminaEnabled = false
local StaminaRunning = nil

local function applyInfiniteStamina()
    if not StaminaEnabled then
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
        while StaminaEnabled do
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
-- Anti 系列
-- ============================================
local AntiSettings = {
    AntiSlow = false,
    AntiStun = false,
    AntiAcid = false,
    AntiJohnDoeTrap = false,
    AntiJohnDoeTrail = false,
}

local antiConns = {}

local function startAntiSlow()
    if antiConns.AntiSlow then return end
    antiConns.AntiSlow = RunService.Heartbeat:Connect(function()
        if not AntiSettings.AntiSlow then return end
        local c = player.Character
        if not c then return end
        local sm = c:FindFirstChild("SpeedMultipliers")
        if sm then
            for _, v in ipairs(sm:GetChildren()) do
                if v:IsA("NumberValue") and v.Value < 1 then v.Value = 1 end
            end
        end
    end)
end

local function stopAntiSlow()
    if antiConns.AntiSlow then
        antiConns.AntiSlow:Disconnect()
        antiConns.AntiSlow = nil
    end
end

local function startAntiStun()
    if antiConns.AntiStun then return end
    antiConns.AntiStun = RunService.Heartbeat:Connect(function()
        if not AntiSettings.AntiStun then return end
        local c = player.Character
        if not c then return end
        local sm = c:FindFirstChild("SpeedMultipliers")
        if sm then
            local stun = sm:FindFirstChild("Stunned")
            if stun then stun.Value = 1 end
        end
    end)
end

local function stopAntiStun()
    if antiConns.AntiStun then
        antiConns.AntiStun:Disconnect()
        antiConns.AntiStun = nil
    end
end

local function startAntiAcid()
    if antiConns.AntiAcid then return end
    antiConns.AntiAcid = task.spawn(function()
        while AntiSettings.AntiAcid do
            pcall(function()
                local map = ws:FindFirstChild("Map")
                local ingame = map and map:FindFirstChild("Ingame")
                local innerMap = ingame and ingame:FindFirstChild("Map")
                if innerMap then
                    for _, v in ipairs(innerMap:GetChildren()) do
                        if v.Name == "AcidContainer" then
                            for _, acid in ipairs(v:GetChildren()) do
                                if acid:IsA("BasePart") then acid.CanTouch = false end
                            end
                        end
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
end

local function stopAntiAcid()
    if antiConns.AntiAcid then
        task.cancel(antiConns.AntiAcid)
        antiConns.AntiAcid = nil
    end
end

local function startAntiJohnDoeTrap()
    if antiConns.AntiJohnDoeTrap then return end
    antiConns.AntiJohnDoeTrap = task.spawn(function()
        while AntiSettings.AntiJohnDoeTrap do
            pcall(function()
                local map = ws:FindFirstChild("Map")
                local ingame = map and map:FindFirstChild("Ingame")
                if ingame then
                    for _, obj in ipairs(ingame:GetChildren()) do
                        if obj:IsA("Model") and obj.Name:lower():find("trap") then
                            for _, p in ipairs(obj:GetDescendants()) do
                                if p:IsA("BasePart") then p.CanTouch = false end
                            end
                        end
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
end

local function stopAntiJohnDoeTrap()
    if antiConns.AntiJohnDoeTrap then
        task.cancel(antiConns.AntiJohnDoeTrap)
        antiConns.AntiJohnDoeTrap = nil
    end
end

local function startAntiJohnDoeTrail()
    if antiConns.AntiJohnDoeTrail then return end
    antiConns.AntiJohnDoeTrail = task.spawn(function()
        while AntiSettings.AntiJohnDoeTrail do
            pcall(function()
                local map = ws:FindFirstChild("Map")
                local ingame = map and map:FindFirstChild("Ingame")
                if ingame then
                    for _, obj in ipairs(ingame:GetChildren()) do
                        if obj:IsA("Folder") and obj.Name:find("JohnDoeTrail") then
                            for _, p in ipairs(obj:GetChildren()) do
                                if p:IsA("BasePart") then p.CanTouch = false end
                            end
                        end
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
end

local function stopAntiJohnDoeTrail()
    if antiConns.AntiJohnDoeTrail then
        task.cancel(antiConns.AntiJohnDoeTrail)
        antiConns.AntiJohnDoeTrail = nil
    end
end

-- ============================================
-- 透视 ESP
-- ============================================
local espHighlights = {}
local espEnabled = false

local function createESP(plr)
    if plr == player then return end
    if espHighlights[plr] then return end
    local c = plr.Character
    if not c then return end
    local h = Instance.new("Highlight")
    h.Name = "CN_ESP"
    h.FillColor = Color3.fromRGB(255, 100, 100)
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = 0.5
    h.OutlineTransparency = 0
    h.Adornee = c
    h.Parent = c
    espHighlights[plr] = h
end

local function removeESP(plr)
    if espHighlights[plr] then
        espHighlights[plr]:Destroy()
        espHighlights[plr] = nil
    end
end

local function startESP()
    espEnabled = true
    for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
end

local function stopESP()
    espEnabled = false
    for _, h in pairs(espHighlights) do h:Destroy() end
    espHighlights = {}
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if espEnabled then createESP(p) end
    end)
    if espEnabled then createESP(p) end
end)
Players.PlayerRemoving:Connect(removeESP)

-- ============================================
-- 可视化（1.0 触发范围）
-- ============================================
local RangeVisual = nil
local function UpdateRangeVisual()
    if RangeVisual then RangeVisual:Destroy(); RangeVisual = nil end
    if not BlockSettings.ShowRangeVisual or not player.Character then return end
    local r = player.Character:FindFirstChild("HumanoidRootPart")
    if not r then return end
    local part = Instance.new("Part")
    part.Name = "BlockRangeVisual"
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(BlockSettings.TriggerDistance * 2, 1, BlockSettings.TriggerDistance * 2)
    part.Color = Color3.fromRGB(255, 50, 50)
    part.Material = Enum.Material.ForceField
    part.Transparency = 0.7
    part.Anchored = false
    part.CanCollide = false
    part.CFrame = r.CFrame
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = r
    weld.Part1 = part
    weld.Parent = part
    part.Parent = r
    RangeVisual = part
end

RunService.RenderStepped:Connect(function()
    if RangeVisual and RangeVisual.Parent then
        local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if r then RangeVisual.CFrame = r.CFrame end
    end
    updatePunchAura()
end)

-- ============================================
-- UI - 主功能（自动格挡 1.0）
-- ============================================
local BlockGroup = Tabs.Main:AddLeftGroupbox("自动格挡 1.0 [Auto Block]")

BlockGroup:AddToggle("AutoBlockToggle", {
    Text = "启用自动格挡 1.0（总开关）",
    Default = false,
    Callback = function(s)
        BlockSettings.Enabled = s
        Library:Notify({Title="Auto Block 1.0", Description = s and "已开启" or "已关闭", Time=1})
    end,
})

BlockGroup:AddToggle("HitboxModeToggle", {
    Text = "碰撞箱检测",
    Default = true,
    Callback = function(s)
        BlockSettings.HitboxMode = s
        if s then scanAllHitboxes() end
    end,
})

BlockGroup:AddToggle("SoundAnimModeToggle", {
    Text = "音效/动画检测",
    Default = false,
    Callback = function(s) BlockSettings.SoundAnimMode = s end,
})

BlockGroup:AddSlider("HitboxDistanceSlider", {
    Text = "碰撞箱检测距离",
    Default = 10, Min = 2, Max = 30, Rounding = 0,
    Callback = function(v) BlockSettings.HitboxDistance = v end,
})

BlockGroup:AddSlider("TriggerDistanceSlider", {
    Text = "音效/动画触发距离",
    Default = 20, Min = 5, Max = 50, Rounding = 0,
    Callback = function(v)
        BlockSettings.TriggerDistance = v
        UpdateRangeVisual()
    end,
})

BlockGroup:AddSlider("BlockDelaySlider", {
    Text = "格挡延迟 (秒)",
    Default = 0.02, Min = 0, Max = 0.5, Rounding = 2,
    Callback = function(v) BlockSettings.BlockDelay = v end,
})

BlockGroup:AddToggle("RandomDelayToggle", {
    Text = "随机延迟",
    Default = false,
    Callback = function(s) BlockSettings.RandomDelay = s end,
})

BlockGroup:AddSlider("RandomRangeSlider", {
    Text = "随机波动 (秒)",
    Default = 0.05, Min = 0, Max = 0.2, Rounding = 2,
    Callback = function(v) BlockSettings.RandomRange = v end,
})

BlockGroup:AddToggle("FacingCheck", {
    Text = "杀手面向检测 (85°)",
    Default = true,
    Callback = function(s) BlockSettings.FacingCheck = s end,
})

BlockGroup:AddToggle("WallCheck", {
    Text = "穿墙检测",
    Default = true,
    Callback = function(s) BlockSettings.WallCheck = s end,
})

BlockGroup:AddToggle("ShowRangeVisual", {
    Text = "显示触发范围",
    Default = false,
    Callback = function(s)
        BlockSettings.ShowRangeVisual = s
        UpdateRangeVisual()
    end,
})

local MiscGroup = Tabs.Main:AddRightGroupbox("其他功能")

MiscGroup:AddToggle("StaminaToggle", {
    Text = "无限体力",
    Default = false,
    Callback = function(v)
        StaminaEnabled = v
        pcall(applyInfiniteStamina)
    end,
})

MiscGroup:AddToggle("ESPToggle", {
    Text = "透视（高亮所有玩家）",
    Default = false,
    Callback = function(v)
        if v then startESP() else stopESP() end
    end,
})

-- ============================================
-- UI - 自动格挡 2.0
-- ============================================
local Block2Group = Tabs.Block2:AddLeftGroupbox("自动格挡 2.0 [白色碰撞箱]")

Block2Group:AddToggle("Block2Toggle", {
    Text = "启用自动格挡 2.0",
    Default = false,
    Callback = function(s)
        Block2Settings.Enabled = s
        if s then scanBlock2Hitboxes() end
        Library:Notify({Title="Auto Block 2.0", Description = s and "已开启" or "已关闭", Time=1})
    end,
})

Block2Group:AddDivider()

Block2Group:AddSlider("Block2LengthSlider", {
    Text = "碰撞箱长度 (长)",
    Default = 8, Min = 2, Max = 30, Rounding = 1,
    Callback = function(v) Block2Settings.BoxLength = v end,
})

Block2Group:AddSlider("Block2WidthSlider", {
    Text = "碰撞箱宽度 (宽)",
    Default = 6, Min = 2, Max = 30, Rounding = 1,
    Callback = function(v) Block2Settings.BoxWidth = v end,
})

Block2Group:AddSlider("Block2HeightSlider", {
    Text = "碰撞箱高度 (高)",
    Default = 8, Min = 2, Max = 30, Rounding = 1,
    Callback = function(v) Block2Settings.BoxHeight = v end,
})

Block2Group:AddSlider("Block2TransparencySlider", {
    Text = "碰撞箱透明度",
    Default = 0.5, Min = 0, Max = 1, Rounding = 2,
    Callback = function(v) Block2Settings.BoxTransparency = v end,
})

Block2Group:AddToggle("Block2ShowVisualToggle", {
    Text = "显示白色碰撞箱",
    Default = true,
    Callback = function(s) Block2Settings.ShowVisual = s end,
})

Block2Group:AddDivider()

Block2Group:AddSlider("Block2DistanceSlider", {
    Text = "杀手距离检测",
    Default = 30, Min = 5, Max = 100, Rounding = 0,
    Callback = function(v) Block2Settings.HitboxDistance = v end,
})

Block2Group:AddSlider("Block2DelaySlider", {
    Text = "格挡延迟 (秒)",
    Default = 0.02, Min = 0, Max = 0.5, Rounding = 2,
    Callback = function(v) Block2Settings.BlockDelay = v end,
})

Block2Group:AddToggle("Block2RandomDelayToggle", {
    Text = "随机延迟",
    Default = false,
    Callback = function(s) Block2Settings.RandomDelay = s end,
})

-- ============================================
-- UI - 自动格挡 3.0
-- ============================================
local Block3Group = Tabs.Block3:AddLeftGroupbox("自动格挡 3.0 [Nolsaken]")

Block3Group:AddToggle("Block3Toggle", {
    Text = "启用自动格挡 3.0",
    Default = false,
    Callback = function(s)
        Block3Settings.Enabled = s
        if s then block3_enable() end
        Library:Notify({Title="Auto Block 3.0", Description = s and "已开启" or "已关闭", Time=1})
    end,
})

Block3Group:AddDivider()

Block3Group:AddSlider("Block3DistanceSlider", {
    Text = "触发距离",
    Default = 20, Min = 5, Max = 50, Rounding = 0,
    Callback = function(v) Block3Settings.TriggerDistance = v end,
})

Block3Group:AddSlider("Block3FacingSlider", {
    Text = "杀手面向角度 (°)",
    Default = 85, Min = 30, Max = 180, Rounding = 0,
    Callback = function(v) Block3Settings.FacingAngle = v end,
})

Block3Group:AddToggle("Block3WallCheck", {
    Text = "穿墙检测",
    Default = true,
    Callback = function(s) Block3Settings.WallCheck = s end,
})

Block3Group:AddSlider("Block3DelaySlider", {
    Text = "格挡延迟 (秒)",
    Default = 0.02, Min = 0, Max = 0.5, Rounding = 2,
    Callback = function(v) Block3Settings.BlockDelay = v end,
})

Block3Group:AddToggle("Block3RandomDelayToggle", {
    Text = "随机延迟",
    Default = false,
    Callback = function(s) Block3Settings.RandomDelay = s end,
})

Block3Group:AddSlider("Block3RandomRangeSlider", {
    Text = "随机波动 (秒)",
    Default = 0.05, Min = 0, Max = 0.2, Rounding = 2,
    Callback = function(v) Block3Settings.RandomRange = v end,
})

Block3Group:AddDivider()

Block3Group:AddToggle("Block3ShowRangeVisual", {
    Text = "显示范围可视化",
    Default = false,
    Callback = function(s) Block3Settings.ShowRangeVisual = s end,
})

Block3Group:AddSlider("Block3AuraRangeSlider", {
    Text = "可视化范围",
    Default = 15, Min = 5, Max = 50, Rounding = 1,
    Callback = function(v) Block3Settings.AuraRange = v end,
})

-- ============================================
-- UI - 出拳
-- ============================================
local PunchGroup = Tabs.Punch:AddLeftGroupbox("出拳自瞄 [Guest 1337 Punch]")

PunchGroup:AddToggle("AutoPunchToggle", {
    Text = "自动出拳",
    Default = false,
    Callback = function(v)
        PunchSettings.AutoPunch = v
        if v then startPunch() else stopPunch() end
    end,
})

PunchGroup:AddToggle("AutoAimToggle", {
    Text = "出拳自瞄",
    Default = true,
    Callback = function(v) PunchSettings.AutoAim = v end,
})

PunchGroup:AddToggle("PunchVisibleToggle", {
    Text = "出拳范围可视化",
    Default = false,
    Callback = function(v)
        PunchSettings.Visible = v
        if v and PunchSettings.AutoPunch then
            createPunchAura()
        elseif punchAura then
            punchAura:Destroy()
            punchAura = nil
        end
    end,
})

PunchGroup:AddSlider("PunchRangeSlider", {
    Text = "出拳范围",
    Default = 15, Min = 1, Max = 50, Rounding = 1,
    Callback = function(v) PunchSettings.Range = v end,
})

PunchGroup:AddDropdown("AimModeDropdown", {
    Text = "自瞄模式",
    Values = {"角色", "相机", "角色+相机"},
    Default = "角色",
    Multi = false,
    Callback = function(v)
        if v == "角色" then PunchSettings.AimMode = "Character"
        elseif v == "相机" then PunchSettings.AimMode = "Camera"
        else PunchSettings.AimMode = "Both" end
    end,
})

PunchGroup:AddSlider("AimSpeedSlider", {
    Text = "自瞄平滑度",
    Default = 0.5, Min = 0.1, Max = 1, Rounding = 2,
    Callback = function(v) PunchSettings.AimSpeed = v end,
})

-- ============================================
-- UI - Anti 系列
-- ============================================
local AntiGroup = Tabs.Anti:AddLeftGroupbox("免疫功能 [Anti Effects]")

AntiGroup:AddToggle("AntiSlowToggle", {
    Text = "防减速 (Anti-Slow)",
    Default = false,
    Callback = function(v)
        AntiSettings.AntiSlow = v
        if v then startAntiSlow() else stopAntiSlow() end
    end,
})

AntiGroup:AddToggle("AntiStunToggle", {
    Text = "防眩晕 (Anti-Stun)",
    Default = false,
    Callback = function(v)
        AntiSettings.AntiStun = v
        if v then startAntiStun() else stopAntiStun() end
    end,
})

AntiGroup:AddToggle("AntiAcidToggle", {
    Text = "防酸液 (Anti-Acid)",
    Default = false,
    Callback = function(v)
        AntiSettings.AntiAcid = v
        if v then startAntiAcid() else stopAntiAcid() end
    end,
})

AntiGroup:AddDivider()

AntiGroup:AddToggle("AntiJohnDoeTrapToggle", {
    Text = "防约翰多陷阱",
    Default = false,
    Callback = function(v)
        AntiSettings.AntiJohnDoeTrap = v
        if v then startAntiJohnDoeTrap() else stopAntiJohnDoeTrap() end
    end,
})

AntiGroup:AddToggle("AntiJohnDoeTrailToggle", {
    Text = "防约翰多脚气",
    Default = false,
    Callback = function(v)
        AntiSettings.AntiJohnDoeTrail = v
        if v then startAntiJohnDoeTrail() else stopAntiJohnDoeTrail() end
    end,
})

-- ============================================
-- 信息
-- ============================================
local Info = Tabs.Info:AddLeftGroupbox("版本信息")
Info:AddLabel("版本: 1.8")
Info:AddLabel("作者: 我已经绷住了")
Info:AddLabel("适配: 被遗弃")
Info:AddLabel("状态: 💚 稳定")

local UIGroup = Tabs["UI设置"]:AddLeftGroupbox("UI设置")
UIGroup:AddButton({
    Text = "关闭窗口",
    Callback = function() Window:Close() end,
})

ThemeManager:SetTheme("Dark")
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
ThemeManager:SetLibrary(Library)
SaveManager:Load()
