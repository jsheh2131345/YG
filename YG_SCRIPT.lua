-- ============================================
-- PG SCRIPT - 综合版
-- 自动格挡（v8.0.0 核心）+ 基础作弊 + 修机 + 可视化
-- ============================================

-- ============================================
-- 库加载
-- ============================================
local repo = "https://raw.githubusercontent.com/SyndromeXph/Obsidian/refs/heads/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

-- ============================================
-- 服务
-- ============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- 清理旧连接
-- ============================================
if getgenv().ExistingConnections then
    for _, conn in ipairs(getgenv().ExistingConnections) do
        pcall(function() conn:Disconnect() end)
    end
end
getgenv().ExistingConnections = {}

-- ============================================
-- 全局变量
-- ============================================
getgenv().buffer = buffer or require(ReplicatedStorage.Buffer)
getgenv().RemoteEvent = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent")

-- ============================================
-- 音效 / 动画 ID 表
-- ============================================
local AutoBlockSounds = {
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

local AutoBlockAnims = {
    ["18885909645"] = true, ["70371667919898"] = true, ["70447634862911"] = true,
    ["99135633258223"] = true, ["74707328554358"] = true, ["81299297965542"] = true,
    ["81639435858902"] = true, ["82113744478546"] = true, ["83251433279852"] = true,
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

local PunchAnims = {
    ["108911997126897"] = true, ["82137285150006"] = true, ["129843313690921"] = true,
    ["140703210927645"] = true, ["136007065400978"] = true, ["86096387000557"] = true,
    ["87259391926321"] = true, ["86709774283672"] = true, ["108807732150251"] = true,
    ["138040001965654"] = true,
}

-- ============================================
-- 全局配置（自动格挡核心）
-- ============================================
getgenv().AutoBlockEnabled = false
getgenv().LooseFacingCheck = false
getgenv().SenseRange = 18
getgenv().PlayerFacingAngle = 90
getgenv().KillerFacingAngle = 90
getgenv().KillerFacingCheckEnabled = false
getgenv().SenseRangeSq = getgenv().SenseRange * getgenv().SenseRange
getgenv().FacingCheckEnabled = false
getgenv().InnerCircleVisible = false
getgenv().OuterCircleVisible = false
getgenv().KillerCircles = {}
getgenv().SoundHooks = {}
getgenv().AnimHooks = {}
getgenv().SoundBlockedUntil = {}
getgenv().AnimBlockedUntil = {}
getgenv().SoundStartTime = {}
getgenv().AnimStartTime = {}
getgenv().MaxSoundAge = 1.2
getgenv().MaxAnimAge = 1.5
getgenv().autoPunchOn = false
getgenv().aimbotPunchOn = false
getgenv().punchRange = 50
getgenv().aimbotDelay = 0.1
getgenv().lastAimbotTime = 0
getgenv().KnownKillers = {"c00lkidd","Jason","JohnDoe","1x1x1x1","Noli","Slasher","Sixer","Nosferatu"}
getgenv().HDPullEnabled = false
getgenv().HDSpeed = 12
getgenv().pulling = false
getgenv().wallCheckEnabled = false
getgenv().VisualizationMode = "指南针"
getgenv().BoxLength = 15
getgenv().BoxWidth = 6
getgenv().BoxColor = Color3.fromRGB(255, 0, 255)
getgenv().BoxTransparency = 0.7
getgenv().BoxSafeColor = Color3.fromRGB(0, 255, 0)
getgenv().BoxDangerColor = Color3.fromRGB(255, 0, 0)
getgenv().lastBlockTime = 0
getgenv().blockCooldown = 0.2
getgenv().faceKillerUntil = 0
getgenv().currentTargetKiller = nil
getgenv().faceKillerDuration = 3

-- ============================================
-- 核心函数
-- ============================================
getgenv().FireBlockRemote = function()
    local now = tick()
    if now - getgenv().lastBlockTime < getgenv().blockCooldown then return end
    getgenv().lastBlockTime = now
    pcall(function()
        getgenv().RemoteEvent:FireServer("UseActorAbility", {
            buffer.fromstring("\3\5\0\0\0Block")
        })
    end)
end

getgenv().fireRemotePunch = function()
    pcall(function()
        getgenv().RemoteEvent:FireServer("UseActorAbility", {
            buffer.fromstring("\3\5\0\0\0Punch")
        })
    end)
    local closest = getgenv().getClosestKiller()
    if closest then
        getgenv().currentTargetKiller = closest
        getgenv().faceKillerUntil = tick() + getgenv().faceKillerDuration
    end
end

getgenv().IsPlayerFacingKiller = function(myRoot, killerRoot)
    if not getgenv().FacingCheckEnabled then return true end
    if not myRoot or not killerRoot then return false end
    local dirToKiller = (killerRoot.Position - myRoot.Position)
    local flatDir = Vector3.new(dirToKiller.X, 0, dirToKiller.Z).Unit
    local playerLookDir = Vector3.new(myRoot.CFrame.LookVector.X, 0, myRoot.CFrame.LookVector.Z).Unit
    local dot = playerLookDir:Dot(flatDir)
    local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
    return angle <= getgenv().PlayerFacingAngle
end

getgenv().IsKillerFacingPlayer = function(myRoot, killerRoot)
    if not getgenv().KillerFacingCheckEnabled then return true end
    if not myRoot or not killerRoot then return false end
    local dirToPlayer = (myRoot.Position - killerRoot.Position)
    local flatDir = Vector3.new(dirToPlayer.X, 0, dirToPlayer.Z).Unit
    local killerLookDir = Vector3.new(killerRoot.CFrame.LookVector.X, 0, killerRoot.CFrame.LookVector.Z).Unit
    local dot = killerLookDir:Dot(flatDir)
    local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
    return angle <= getgenv().KillerFacingAngle
end

getgenv().HasLineOfSight = function(targetRoot)
    if not getgenv().wallCheckEnabled then return true end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return false end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local origin = myRoot.Position
    local direction = targetRoot.Position - origin
    local result = workspace:Raycast(origin, direction, rayParams)
    return not result or result.Instance:IsDescendantOf(targetRoot.Parent)
end

getgenv().IsPlayerInBox = function(myRoot, killerRoot)
    if not myRoot or not killerRoot then return false end
    local forward = killerRoot.CFrame.LookVector
    local forwardOffset = forward * (getgenv().BoxLength / 2)
    local boxPos = killerRoot.Position + forwardOffset
    local boxCFrame = CFrame.lookAt(boxPos, boxPos + forward * 100)
    local relative = myRoot.Position - boxPos
    local localSpace = boxCFrame:VectorToObjectSpace(relative)
    local halfX = getgenv().BoxWidth / 2
    local halfY = 4
    local halfZ = getgenv().BoxLength / 2
    return math.abs(localSpace.X) <= halfX and math.abs(localSpace.Y) <= halfY and math.abs(localSpace.Z) <= halfZ
end

getgenv().CheckAllBlockConditions = function(myRoot, killerRoot)
    if not myRoot or not killerRoot then return false end
    local dvec = killerRoot.Position - myRoot.Position
    local distSq = dvec.X^2 + dvec.Y^2 + dvec.Z^2

    if getgenv().VisualizationMode == "Box" then
        if not getgenv().IsPlayerInBox(myRoot, killerRoot) then return false end
    else
        if distSq > getgenv().SenseRangeSq then return false end
    end

    if not getgenv().IsKillerFacingPlayer(myRoot, killerRoot) then return false end
    if not getgenv().HasLineOfSight(killerRoot) then return false end
    if not getgenv().IsPlayerFacingKiller(myRoot, killerRoot) then return false end
    return true
end

getgenv().GetSoundIdNumeric = function(snd)
    if not snd or not snd.SoundId then return nil end
    return tostring(snd.SoundId):match("%d+")
end

getgenv().GetAnimIdNumeric = function(anim)
    if not anim or not anim.AnimationId then return nil end
    return tostring(anim.AnimationId):match("%d+")
end

getgenv().GetSoundPosition = function(snd)
    if not snd then return nil end
    if snd.Parent and snd.Parent:IsA("BasePart") then
        return snd.Parent.Position, snd.Parent
    end
    if snd.Parent and snd.Parent:IsA("Attachment") and snd.Parent.Parent and snd.Parent.Parent:IsA("BasePart") then
        return snd.Parent.Parent.Position, snd.Parent.Parent
    end
    local found = snd.Parent and snd.Parent:FindFirstChildWhichIsA("BasePart", true)
    return found and found.Position, found or nil
end

getgenv().GetCharFromDescendant = function(inst)
    if not inst then return nil end
    local mdl = inst:FindFirstAncestorOfClass("Model")
    return mdl and mdl:FindFirstChildOfClass("Humanoid") and mdl or nil
end

getgenv().CanUseBlock = function()
    local cooldown = LocalPlayer:FindFirstChild("PlayerGui")
    if cooldown then
        local mainUI = cooldown:FindFirstChild("MainUI")
        if mainUI then
            local abilityContainer = mainUI:FindFirstChild("AbilityContainer")
            if abilityContainer then
                local blockBtn = abilityContainer:FindFirstChild("Block")
                if blockBtn then
                    local cd = blockBtn:FindFirstChild("CooldownTime")
                    if cd and cd.Text ~= "" then return false end
                end
            end
        end
    end
    return true
end

getgenv().DoHDPull = function(targetPos)
    if getgenv().pulling or not getgenv().CanUseBlock() then return end
    getgenv().pulling = true
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then getgenv().pulling = false return end
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(50000, 0, 50000)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    local startTime = tick()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not bv.Parent or tick() - startTime > 0.4 then
            if bv.Parent then bv:Destroy() end
            conn:Disconnect()
            getgenv().pulling = false
            return
        end
        local vec = targetPos - hrp.Position
        if vec.Magnitude < 3 then
            bv:Destroy()
            conn:Disconnect()
            getgenv().pulling = false
            return
        end
        bv.Velocity = vec.Unit * (getgenv().HDSpeed * 25)
    end)
end

-- ============================================
-- 格挡触发
-- ============================================
getgenv().AttemptBlockSound = function(snd)
    if not getgenv().AutoBlockEnabled then return end
    if not snd or not snd:IsA("Sound") then return end
    if not snd.IsPlaying then return end
    local id = getgenv().GetSoundIdNumeric(snd)
    if not id or not AutoBlockSounds[id] then return end

    local now = tick()
    if not getgenv().SoundStartTime[snd] then getgenv().SoundStartTime[snd] = now end
    if now - getgenv().SoundStartTime[snd] > getgenv().MaxSoundAge then return end
    if getgenv().SoundBlockedUntil[snd] and now < getgenv().SoundBlockedUntil[snd] then return end

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local pos, part = getgenv().GetSoundPosition(snd)
    if not pos or not part then return end
    local char = getgenv().GetCharFromDescendant(part)
    local plr = char and Players:GetPlayerFromCharacter(char)
    if not plr or plr == LocalPlayer then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if not getgenv().CheckAllBlockConditions(myRoot, hrp) then return end
    getgenv().FireBlockRemote()
    if getgenv().HDPullEnabled then
        task.spawn(function() getgenv().DoHDPull(hrp.Position) end)
    end
    getgenv().SoundBlockedUntil[snd] = now + 0.8
end

getgenv().AttemptBlockAnim = function(animTrack)
    if not getgenv().AutoBlockEnabled then return end
    if not animTrack or not animTrack.Animation then return end
    if not animTrack.IsPlaying then return end
    local id = getgenv().GetAnimIdNumeric(animTrack.Animation)
    if not id or not AutoBlockAnims[id] then return end

    local now = tick()
    if not getgenv().AnimStartTime[animTrack] then getgenv().AnimStartTime[animTrack] = now end
    if now - getgenv().AnimStartTime[animTrack] > getgenv().MaxAnimAge then return end
    if getgenv().AnimBlockedUntil[animTrack] and now < getgenv().AnimBlockedUntil[animTrack] then return end

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local animator = animTrack.Parent
    if not animator or not animator:IsA("Animator") then return end
    local char = getgenv().GetCharFromDescendant(animator)
    if not char then return end
    local plr = Players:GetPlayerFromCharacter(char)
    if not plr or plr == LocalPlayer then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if not getgenv().CheckAllBlockConditions(myRoot, hrp) then return end
    getgenv().FireBlockRemote()
    if getgenv().HDPullEnabled then
        task.spawn(function() getgenv().DoHDPull(hrp.Position) end)
    end
    getgenv().AnimBlockedUntil[animTrack] = now + 0.8
end

-- ============================================
-- Hook 系统
-- ============================================
getgenv().HookSound = function(snd)
    if not snd or not snd:IsA("Sound") then return end
    if getgenv().SoundHooks[snd] then return end

    local playConn = snd.Played:Connect(function()
        getgenv().SoundStartTime[snd] = tick()
        task.defer(getgenv().AttemptBlockSound, snd)
    end)

    local propConn = snd:GetPropertyChangedSignal("IsPlaying"):Connect(function()
        if snd.IsPlaying then
            if not getgenv().SoundStartTime[snd] then getgenv().SoundStartTime[snd] = tick() end
            task.defer(getgenv().AttemptBlockSound, snd)
        else
            getgenv().SoundStartTime[snd] = nil
        end
    end)

    local destroyConn
    destroyConn = snd.Destroying:Connect(function()
        if playConn.Connected then playConn:Disconnect() end
        if propConn.Connected then propConn:Disconnect() end
        if destroyConn.Connected then destroyConn:Disconnect() end
        getgenv().SoundHooks[snd] = nil
        getgenv().SoundBlockedUntil[snd] = nil
        getgenv().SoundStartTime[snd] = nil
    end)

    getgenv().SoundHooks[snd] = {playConn, propConn, destroyConn}

    if snd.IsPlaying then
        getgenv().SoundStartTime[snd] = tick()
        task.defer(getgenv().AttemptBlockSound, snd)
    end
end

getgenv().HookAnimator = function(animator)
    if not animator or not animator:IsA("Animator") then return end
    animator.AnimationPlayed:Connect(function(animTrack)
        pcall(function()
            getgenv().AnimStartTime[animTrack] = tick()

            local playConn = animTrack:GetPropertyChangedSignal("IsPlaying"):Connect(function()
                if animTrack.IsPlaying then
                    if not getgenv().AnimStartTime[animTrack] then
                        getgenv().AnimStartTime[animTrack] = tick()
                    end
                    task.defer(getgenv().AttemptBlockAnim, animTrack)
                else
                    getgenv().AnimStartTime[animTrack] = nil
                end
            end)

            animTrack.Stopped:Connect(function()
                if playConn.Connected then playConn:Disconnect() end
                getgenv().AnimBlockedUntil[animTrack] = nil
                getgenv().AnimStartTime[animTrack] = nil
            end)

            if animTrack.IsPlaying then
                task.defer(getgenv().AttemptBlockAnim, animTrack)
            end
        end)
    end)
end

for _, d in ipairs(game:GetDescendants()) do
    if d:IsA("Sound") then pcall(getgenv().HookSound, d) end
    if d:IsA("Animator") then pcall(getgenv().HookAnimator, d) end
end

game.DescendantAdded:Connect(function(d)
    if d:IsA("Sound") then task.defer(getgenv().HookSound, d) end
    if d:IsA("Animator") then task.defer(getgenv().HookAnimator, d) end
end)

-- ============================================
-- 获取最近的杀手
-- ============================================
getgenv().getClosestKiller = function()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, closestDist = nil, math.huge
    local killersFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
    if killersFolder then
        for _, name in ipairs(getgenv().KnownKillers) do
            local killer = killersFolder:FindFirstChild(name)
            if killer and killer:FindFirstChild("HumanoidRootPart") then
                local root = killer.HumanoidRootPart
                local dvec = root.Position - myRoot.Position
                local dist = math.sqrt(dvec.X^2 + dvec.Y^2 + dvec.Z^2)
                if dist < closestDist and dist <= getgenv().punchRange then
                    closest = killer
                    closestDist = dist
                end
            end
        end
    end
    return closest
end

-- ============================================
-- 自动拳击 / 自瞄拳击 / 面向杀手
-- ============================================
RunService.RenderStepped:Connect(function()
    if not getgenv().autoPunchOn and not getgenv().aimbotPunchOn then return end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local gui = LocalPlayer.PlayerGui:FindFirstChild("MainUI")
    local punchBtn = gui and gui:FindFirstChild("AbilityContainer") and gui.AbilityContainer:FindFirstChild("Punch")
    local charges = punchBtn and punchBtn:FindFirstChild("Charges")
    if punchBtn and charges then
        local chargeCount = tonumber(charges.Text) or 0
        if chargeCount >= 1 then
            local killer = getgenv().getClosestKiller()
            if killer and killer:FindFirstChild("HumanoidRootPart") then
                if getgenv().aimbotPunchOn then
                    local currentTime = tick()
                    if currentTime - getgenv().lastAimbotTime >= getgenv().aimbotDelay then
                        getgenv().fireRemotePunch()
                        getgenv().lastAimbotTime = currentTime
                    end
                elseif getgenv().autoPunchOn then
                    getgenv().fireRemotePunch()
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if getgenv().faceKillerUntil > tick() and getgenv().currentTargetKiller then
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myRoot and getgenv().currentTargetKiller:FindFirstChild("HumanoidRootPart") then
            local killerRoot = getgenv().currentTargetKiller.HumanoidRootPart
            local direction = (killerRoot.Position - myRoot.Position)
            local flatDir = Vector3.new(direction.X, 0, direction.Z)
            if flatDir.Magnitude > 0.1 then
                myRoot.CFrame = CFrame.new(myRoot.Position, myRoot.Position + flatDir)
            end
        end
    else
        getgenv().currentTargetKiller = nil
    end
end)

-- ============================================
-- 可视化（指南针 / 固定 / Box / 球体）
-- ============================================
getgenv().KillersFolder = workspace:WaitForChild("Players"):WaitForChild("Killers")
getgenv().KillerCircles = {}

getgenv().CreateCompassVisualization = function(killer, myRoot)
    if not killer or not killer:FindFirstChild("HumanoidRootPart") or not myRoot then return nil end
    local killerRoot = killer.HumanoidRootPart
    local folder = Instance.new("Folder")
    folder.Name = "CompassVisualization"
    folder.Parent = killerRoot
    local segments = 32
    local parts = {}
    local centerPart = Instance.new("Part")
    centerPart.Name = "Center"
    centerPart.Size = Vector3.new(0.6, 0.1, 0.6)
    centerPart.Anchored = true
    centerPart.CanCollide = false
    centerPart.Transparency = 0.7
    centerPart.Material = Enum.Material.Neon
    centerPart.Color = Color3.fromRGB(255, 255, 0)
    centerPart.CFrame = CFrame.new(killerRoot.Position + Vector3.new(0, 0.1, 0))
    centerPart.Parent = folder
    table.insert(parts, centerPart)
    for i = 1, segments do
        local part = Instance.new("Part")
        part.Name = "ArcPoint" .. i
        part.Size = Vector3.new(0.4, 0.15, 0.4)
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 0.5
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(255, 100, 100)
        part.Parent = folder
        table.insert(parts, part)
    end
    return {folder = folder, parts = parts, killer = killer, mode = "指南针"}
end

getgenv().CreateFixedVisualization = function(killer)
    if not killer or not killer:FindFirstChild("HumanoidRootPart") then return nil end
    local killerRoot = killer.HumanoidRootPart
    local folder = Instance.new("Folder")
    folder.Name = "FixedVisualization"
    folder.Parent = killerRoot
    local segments = 32
    local parts = {}
    local centerPart = Instance.new("Part")
    centerPart.Name = "Center"
    centerPart.Size = Vector3.new(0.6, 0.1, 0.6)
    centerPart.Anchored = true
    centerPart.CanCollide = false
    centerPart.Transparency = 0.7
    centerPart.Material = Enum.Material.Neon
    centerPart.Color = Color3.fromRGB(255, 255, 0)
    centerPart.CFrame = CFrame.new(killerRoot.Position + Vector3.new(0, 0.1, 0))
    centerPart.Parent = folder
    table.insert(parts, centerPart)
    for i = 1, segments do
        local part = Instance.new("Part")
        part.Name = "ArcPoint" .. i
        part.Size = Vector3.new(0.4, 0.15, 0.4)
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 0.5
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(100, 100, 255)
        part.Parent = folder
        table.insert(parts, part)
    end
    return {folder = folder, parts = parts, killer = killer, mode = "固定"}
end

getgenv().CreateBoxVisualization = function(killer)
    if not killer or not killer:FindFirstChild("HumanoidRootPart") then return nil end
    local killerRoot = killer.HumanoidRootPart
    local folder = Instance.new("Folder")
    folder.Name = "BoxVisualization"
    folder.Parent = killerRoot
    local box = Instance.new("Part")
    box.Name = "DetectionBox"
    box.Material = Enum.Material.ForceField
    box.Anchored = true
    box.CanCollide = false
    box.Transparency = getgenv().BoxTransparency
    box.Color = getgenv().BoxColor
    box.Size = Vector3.new(getgenv().BoxWidth, 8, getgenv().BoxLength)
    box.Parent = folder
    return {folder = folder, box = box, killer = killer, mode = "Box"}
end

getgenv().CreateSphereVisualization = function(killer)
    if not killer or not killer:FindFirstChild("HumanoidRootPart") then return nil end
    local killerRoot = killer.HumanoidRootPart
    local folder = Instance.new("Folder")
    folder.Name = "SphereVisualization"
    folder.Parent = killerRoot
    local sphere = Instance.new("Part")
    sphere.Name = "DetectionSphere"
    sphere.Shape = Enum.PartType.Ball
    sphere.Material = Enum.Material.ForceField
    sphere.Anchored = true
    sphere.CanCollide = false
    sphere.Transparency = 0.8
    sphere.Color = Color3.fromRGB(255, 0, 0)
    sphere.Size = Vector3.new(getgenv().SenseRange * 2, getgenv().SenseRange * 2, getgenv().SenseRange * 2)
    sphere.Parent = folder
    return {folder = folder, sphere = sphere, killer = killer, mode = "球体"}
end

getgenv().UpdateCompassVisualization = function(visData, myRoot)
    if not visData or not visData.folder or not visData.folder.Parent then return end
    if not myRoot or not visData.killer or not visData.killer:FindFirstChild("HumanoidRootPart") then return end
    local killerRoot = visData.killer.HumanoidRootPart
    local dirToPlayer = (myRoot.Position - killerRoot.Position)
    local forward = Vector3.new(dirToPlayer.X, 0, dirToPlayer.Z).Unit
    local right = Vector3.new(-forward.Z, 0, forward.X)
    local angle = getgenv().KillerFacingCheckEnabled and getgenv().KillerFacingAngle or 360
    local angleRad = math.rad(angle)
    local distance = getgenv().SenseRange
    local segments = #visData.parts - 1
    visData.parts[1].Position = killerRoot.Position + Vector3.new(0, 0.1, 0)
    for i = 2, #visData.parts do
        local t = (i - 2) / math.max(1, segments - 1)
        local currentAngle = -angleRad / 2 + angleRad * t
        local direction = forward * math.cos(currentAngle) + right * math.sin(currentAngle)
        visData.parts[i].Position = killerRoot.Position + Vector3.new(0, 0.1, 0) + direction * distance
    end
    local shouldBlock = getgenv().CheckAllBlockConditions(myRoot, killerRoot)
    local color = shouldBlock and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    for _, part in ipairs(visData.parts) do part.Color = color end
end

getgenv().UpdateFixedVisualization = function(visData, myRoot)
    if not visData or not visData.folder or not visData.folder.Parent then return end
    if not myRoot or not visData.killer or not visData.killer:FindFirstChild("HumanoidRootPart") then return end
    local killerRoot = visData.killer.HumanoidRootPart
    local forward = Vector3.new(killerRoot.CFrame.LookVector.X, 0, killerRoot.CFrame.LookVector.Z).Unit
    local right = Vector3.new(-forward.Z, 0, forward.X)
    local angle = getgenv().KillerFacingCheckEnabled and getgenv().KillerFacingAngle or 360
    local angleRad = math.rad(angle)
    local distance = getgenv().SenseRange
    local segments = #visData.parts - 1
    visData.parts[1].Position = killerRoot.Position + Vector3.new(0, 0.1, 0)
    for i = 2, #visData.parts do
        local t = (i - 2) / math.max(1, segments - 1)
        local currentAngle = -angleRad / 2 + angleRad * t
        local direction = forward * math.cos(currentAngle) + right * math.sin(currentAngle)
        visData.parts[i].Position = killerRoot.Position + Vector3.new(0, 0.1, 0) + direction * distance
    end
    local shouldBlock = getgenv().CheckAllBlockConditions(myRoot, killerRoot)
    local color = shouldBlock and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(100, 100, 255)
    for _, part in ipairs(visData.parts) do part.Color = color end
end

getgenv().UpdateBoxVisualization = function(visData, myRoot)
    if not visData or not visData.folder or not visData.folder.Parent then return end
    if not myRoot or not visData.killer or not visData.killer:FindFirstChild("HumanoidRootPart") then return end
    local killerRoot = visData.killer.HumanoidRootPart
    local forward = killerRoot.CFrame.LookVector
    local forwardOffset = forward * (getgenv().BoxLength / 2)
    local boxPos = killerRoot.Position + forwardOffset
    visData.box.Size = Vector3.new(getgenv().BoxWidth, 8, getgenv().BoxLength)
    visData.box.CFrame = CFrame.lookAt(boxPos, boxPos + forward * 100)
    visData.box.Transparency = getgenv().BoxTransparency
    local shouldBlock = getgenv().IsPlayerInBox(myRoot, killerRoot) and getgenv().CheckAllBlockConditions(myRoot, killerRoot)
    visData.box.Color = shouldBlock and getgenv().BoxSafeColor or getgenv().BoxDangerColor
end

getgenv().UpdateSphereVisualization = function(visData, myRoot)
    if not visData or not visData.folder or not visData.folder.Parent then return end
    if not myRoot or not visData.killer or not visData.killer:FindFirstChild("HumanoidRootPart") then return end
    local killerRoot = visData.killer.HumanoidRootPart
    visData.sphere.Size = Vector3.new(getgenv().SenseRange * 2, getgenv().SenseRange * 2, getgenv().SenseRange * 2)
    visData.sphere.CFrame = killerRoot.CFrame
    local dvec = myRoot.Position - killerRoot.Position
    local distSq = dvec.X^2 + dvec.Y^2 + dvec.Z^2
    local shouldBlock = distSq <= getgenv().SenseRangeSq and getgenv().CheckAllBlockConditions(myRoot, killerRoot)
    visData.sphere.Color = shouldBlock and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end

getgenv().CreateVisualizationForKiller = function(killer)
    if not killer or not killer:FindFirstChild("HumanoidRootPart") then return nil end
    if getgenv().VisualizationMode == "指南针" then
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        return getgenv().CreateCompassVisualization(killer, myRoot)
    elseif getgenv().VisualizationMode == "固定" then
        return getgenv().CreateFixedVisualization(killer)
    elseif getgenv().VisualizationMode == "Box" then
        return getgenv().CreateBoxVisualization(killer)
    elseif getgenv().VisualizationMode == "球体" then
        return getgenv().CreateSphereVisualization(killer)
    end
    return nil
end

getgenv().UpdateVisualization = function(visData, myRoot)
    if not visData then return end
    if visData.mode == "指南针" then getgenv().UpdateCompassVisualization(visData, myRoot)
    elseif visData.mode == "固定" then getgenv().UpdateFixedVisualization(visData, myRoot)
    elseif visData.mode == "Box" then getgenv().UpdateBoxVisualization(visData, myRoot)
    elseif visData.mode == "球体" then getgenv().UpdateSphereVisualization(visData, myRoot)
    end
end

getgenv().AddKillerCircle = function(killer)
    if not killer:FindFirstChild("HumanoidRootPart") then return end
    if getgenv().KillerCircles[killer] then return end
    local innerCirc, outerCirc
    if getgenv().InnerCircleVisible then
        innerCirc = Instance.new("CylinderHandleAdornment")
        innerCirc.Name = "KillerInnerCircle"
        innerCirc.Adornee = killer.HumanoidRootPart
        innerCirc.Color3 = Color3.fromRGB(255, 0, 0)
        innerCirc.AlwaysOnTop = true
        innerCirc.ZIndex = 1
        innerCirc.Transparency = 0.6
        innerCirc.Radius = getgenv().SenseRange
        innerCirc.Height = 0.1
        innerCirc.CFrame = CFrame.Angles(math.rad(90), 0, 0)
        innerCirc.Parent = killer.HumanoidRootPart
    end
    if getgenv().OuterCircleVisible then
        outerCirc = Instance.new("CylinderHandleAdornment")
        outerCirc.Name = "KillerOuterCircle"
        outerCirc.Adornee = killer.HumanoidRootPart
        outerCirc.Color3 = Color3.fromRGB(0, 255, 255)
        outerCirc.AlwaysOnTop = true
        outerCirc.ZIndex = 0
        outerCirc.Transparency = 0.3
        outerCirc.Radius = getgenv().punchRange
        outerCirc.Height = 0.1
        outerCirc.CFrame = CFrame.Angles(math.rad(90), 0, 0)
        outerCirc.Parent = killer.HumanoidRootPart
    end
    local visData = getgenv().CreateVisualizationForKiller(killer)
    getgenv().KillerCircles[killer] = {innerCircle = innerCirc, outerCircle = outerCirc, visualization = visData}
end

getgenv().RemoveKillerCircle = function(killer)
    if getgenv().KillerCircles[killer] then
        local data = getgenv().KillerCircles[killer]
        if data.innerCircle then data.innerCircle:Destroy() end
        if data.outerCircle then data.outerCircle:Destroy() end
        if data.visualization and data.visualization.folder then data.visualization.folder:Destroy() end
        getgenv().KillerCircles[killer] = nil
    end
end

getgenv().RefreshKillerCircles = function()
    for _, killer in ipairs(getgenv().KillersFolder:GetChildren()) do
        if getgenv().InnerCircleVisible or getgenv().OuterCircleVisible then
            getgenv().AddKillerCircle(killer)
        else
            getgenv().RemoveKillerCircle(killer)
        end
    end
end

getgenv().UpdateVisualizationMode = function(newMode)
    getgenv().VisualizationMode = newMode
    for killer, data in pairs(getgenv().KillerCircles) do
        if data.visualization and data.visualization.folder then
            data.visualization.folder:Destroy()
        end
        local newVisData = getgenv().CreateVisualizationForKiller(killer)
        data.visualization = newVisData
    end
end

getgenv().UpdateBoxColors = function()
    for killer, data in pairs(getgenv().KillerCircles) do
        if data.visualization and data.visualization.mode == "Box" and data.visualization.box then
            data.visualization.box.Transparency = getgenv().BoxTransparency
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not (getgenv().InnerCircleVisible or getgenv().OuterCircleVisible) then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    for killer, data in pairs(getgenv().KillerCircles) do
        if killer:FindFirstChild("HumanoidRootPart") then
            local killerRoot = killer.HumanoidRootPart
            if data.innerCircle and data.innerCircle.Parent then
                data.innerCircle.Radius = getgenv().SenseRange
                local shouldBlock = getgenv().CheckAllBlockConditions(myRoot, killerRoot)
                data.innerCircle.Color3 = shouldBlock and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
            end
            if data.outerCircle and data.outerCircle.Parent then
                data.outerCircle.Radius = getgenv().punchRange
                local dvec = killerRoot.Position - myRoot.Position
                local dist = math.sqrt(dvec.X^2 + dvec.Y^2 + dvec.Z^2)
                data.outerCircle.Color3 = dist <= getgenv().punchRange and Color3.fromRGB(0, 150, 150) or Color3.fromRGB(0, 100, 100)
            end
            if data.visualization then
                pcall(getgenv().UpdateVisualization, data.visualization, myRoot)
            end
        end
    end
end)

getgenv().KillersFolder.ChildAdded:Connect(function(killer)
    if getgenv().InnerCircleVisible or getgenv().OuterCircleVisible then
        task.spawn(function()
            local hrp = killer:WaitForChild("HumanoidRootPart", 5)
            if hrp then getgenv().AddKillerCircle(killer) end
        end)
    end
end)

getgenv().KillersFolder.ChildRemoved:Connect(function(killer)
    getgenv().RemoveKillerCircle(killer)
end)

-- ============================================
-- 基础作弊功能
-- ============================================
local function TestSpeedHack()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:WaitForChild("Humanoid")
    local original = humanoid.WalkSpeed
    humanoid.WalkSpeed = 100
    task.delay(5, function()
        if humanoid and humanoid.Parent then humanoid.WalkSpeed = original end
    end)
end

local function TestJumpHack()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:WaitForChild("Humanoid")
    local original = humanoid.JumpPower
    humanoid.JumpPower = 200
    humanoid.UseJumpPower = true
    task.delay(5, function()
        if humanoid and humanoid.Parent then humanoid.JumpPower = original end
    end)
end

local function TestTeleport()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    root.CFrame = CFrame.new(math.random(-100, 100), 50, math.random(-100, 100))
end

local noclipConn, flyConn
local function StartNoclip()
    if noclipConn then return end
    noclipConn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end)
end
local function StopNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    local char = LocalPlayer.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
end

local function StartFly()
    if flyConn then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then humanoid.PlatformStand = true end
    flyConn = RunService.RenderStepped:Connect(function()
        if not root or not root.Parent then return end
        local cam = workspace.CurrentCamera
        local moveDir = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
        if moveDir.Magnitude > 0 then root.CFrame = root.CFrame + moveDir.Unit * 2 end
    end)
end
local function StopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
    end
end

-- ============================================
-- 修机 / 连接 / 体力
-- ============================================
local repairConn, connectConn, staminaConn
local function FindGenerators()
    local gens = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("generator") or obj.Name:lower():find("gen")) then
            table.insert(gens, obj)
        end
    end
    return gens
end

local function StartQuickRepair()
    if repairConn then return end
    repairConn = task.spawn(function()
        while repairConn do
            for _, gen in ipairs(FindGenerators()) do
                for _, d in ipairs(gen:GetDescendants()) do
                    if d:IsA("ProximityPrompt") then
                        pcall(function()
                            d:InputHoldBegin()
                            task.wait(1.25)
                            d:InputHoldEnd()
                        end)
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end
local function StopQuickRepair()
    if repairConn then task.cancel(repairConn); repairConn = nil end
end

local function StartAutoConnect()
    if connectConn then return end
    connectConn = task.spawn(function()
        while connectConn do
            for _, obj in ipairs(game:GetDescendants()) do
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    local n = obj.Name:lower()
                    if n:find("connect") or n:find("node") or n:find("wire") then
                        pcall(function() obj.MouseButton1Click:Fire() end)
                        task.wait(0.09)
                    end
                end
            end
            task.wait(0.05)
        end
    end)
end
local function StopAutoConnect()
    if connectConn then task.cancel(connectConn); connectConn = nil end
end

local function StartInfiniteStamina()
    if staminaConn then return end
    staminaConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("NumberValue") then
                local n = obj.Name:lower()
                if n:find("stamina") or n:find("energy") then obj.Value = 100 end
            end
        end
    end)
end
local function StopInfiniteStamina()
    if staminaConn then staminaConn:Disconnect(); staminaConn = nil end
end

-- ============================================
-- 假无敌陷阱
-- ============================================
local function FakeGodMode()
    local char = LocalPlayer.Character
    if char then
        pcall(function()
            char:SetAttribute("Invincible", true)
            char:SetAttribute("GodMode", true)
            char:SetAttribute("Immortal", true)
        end)
    end
    task.wait(0.8)
    local kicked = false
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local n = obj.Name:lower()
            if n:find("kick") or n:find("ban") then
                pcall(function()
                    obj:FireServer(LocalPlayer, "就你还想开无敌😂")
                    kicked = true
                end)
                if kicked then break end
            end
        end
    end
    if not kicked then
        task.wait(0.3)
        pcall(function()
            LocalPlayer:Kick("就你还想开无敌😂")
        end)
    end
end

-- ============================================
-- 窗口
-- ============================================
local Window = Library:CreateWindow({
    Title = "PG SCRIPT | V1",
    Footer = "PG SCRIPT",
    Icon = "rbxassetid://79732464885756",
    CornerElements = false,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Info = Window:AddTab("公告", "megaphone", "欢迎"),
    Main = Window:AddTab("主要的", "layers", "基础作弊"),
    AutoBlock = Window:AddTab("自动格挡", "shield", "Guest 1337 削弱版"),
    Ability = Window:AddTab("能力", "user-round-pen", "修机 / 连接 / 体力"),
    Settings = Window:AddTab("设置", "settings", "配置"),
}

-- ============================================
-- 公告 Tab
-- ============================================
local InfoGroup = Tabs.Info:AddLeftGroupbox("公告", "megaphone")
InfoGroup:AddLabel("欢迎使用 PG SCRIPT")
InfoGroup:AddLabel("目前为 V1")
InfoGroup:AddDivider()
InfoGroup:AddLabel("作者：灰白")

-- ============================================
-- 主要的 Tab
-- ============================================
local MainGroup = Tabs.Main:AddLeftGroupbox("基础作弊", "zap")
MainGroup:AddButton({ Text = "测试速度修改", Func = TestSpeedHack })
MainGroup:AddButton({ Text = "测试跳跃修改", Func = TestJumpHack })
MainGroup:AddButton({ Text = "测试瞬移", Func = TestTeleport })
MainGroup:AddToggle("NoclipToggle", {
    Text = "穿墙", Default = false,
    Callback = function(v) if v then StartNoclip() else StopNoclip() end end,
})
MainGroup:AddToggle("FlyToggle", {
    Text = "飞行", Default = false,
    Callback = function(v) if v then StartFly() else StopFly() end end,
})

-- ============================================
-- 自动格挡 Tab
-- ============================================
local BlockTabBox = Tabs.AutoBlock:AddLeftTabbox()
local BlockMain = BlockTabBox:AddTab("Block")
local BlockPunch = BlockTabBox:AddTab("Punch")
local BlockBox = BlockTabBox:AddTab("Box")
local BlockMisc = BlockTabBox:AddTab("Misc")

-- Block
BlockMain:AddToggle("AutoBlockToggle", {
    Text = "自动格挡", Default = false,
    Callback = function(v) getgenv().AutoBlockEnabled = v end,
})
BlockMain:AddToggle("InnerCircleToggle", {
    Text = "可视化", Default = false,
    Callback = function(v)
        getgenv().InnerCircleVisible = v
        getgenv().RefreshKillerCircles()
    end,
})
BlockMain:AddDropdown("VisualizationModeDropdown", {
    Values = {"指南针", "固定", "Box", "球体"}, Default = 1, Multi = false,
    Text = "可视化模式",
    Callback = function(v) getgenv().UpdateVisualizationMode(v) end,
})
BlockMain:AddToggle("FacingCheck", {
    Text = "玩家面向检测", Default = false,
    Callback = function(v) getgenv().FacingCheckEnabled = v end,
})
BlockMain:AddToggle("KillerFacingCheck", {
    Text = "杀手面向检测", Default = false,
    Callback = function(v) getgenv().KillerFacingCheckEnabled = v end,
})
BlockMain:AddToggle("WallCheck", {
    Text = "Wallcheck", Default = false,
    Callback = function(v) getgenv().wallCheckEnabled = v end,
})
BlockMain:AddSlider("SenseRange", {
    Text = "格挡范围", Default = 18, Min = 5, Max = 50, Rounding = 1,
    Callback = function(v)
        getgenv().SenseRange = v
        getgenv().SenseRangeSq = v * v
    end,
})
BlockMain:AddSlider("PlayerFacingAngle", {
    Text = "玩家面向角度", Default = 90, Min = 30, Max = 180, Rounding = 1,
    Callback = function(v) getgenv().PlayerFacingAngle = v end,
})
BlockMain:AddSlider("KillerFacingAngle", {
    Text = "杀手面向角度", Default = 90, Min = 30, Max = 180, Rounding = 1,
    Callback = function(v) getgenv().KillerFacingAngle = v end,
})
BlockMain:AddSlider("MaxSoundAge", {
    Text = "最大声音检测时长(秒)", Default = 1.5, Min = 0.5, Max = 5, Rounding = 1,
    Callback = function(v) getgenv().MaxSoundAge = v end,
})
BlockMain:AddSlider("MaxAnimAge", {
    Text = "最大动画检测时长(秒)", Default = 1.5, Min = 0.5, Max = 5, Rounding = 1,
    Callback = function(v) getgenv().MaxAnimAge = v end,
})

-- Punch
BlockPunch:AddToggle("AutoPunch", {
    Text = "自动拳击", Default = false,
    Callback = function(v) getgenv().autoPunchOn = v end,
})
BlockPunch:AddToggle("AimbotPunch", {
    Text = "自瞄拳击", Default = false,
    Callback = function(v) getgenv().aimbotPunchOn = v end,
})
BlockPunch:AddToggle("OuterCircleToggle", {
    Text = "可视化", Default = false,
    Callback = function(v)
        getgenv().OuterCircleVisible = v
        getgenv().RefreshKillerCircles()
    end,
})
BlockPunch:AddSlider("PunchRange", {
    Text = "拳击范围", Default = 50, Min = 10, Max = 100, Rounding = 1,
    Callback = function(v) getgenv().punchRange = v end,
})
BlockPunch:AddSlider("AimbotDelay", {
    Text = "自瞄拳击间隔", Default = 0.1, Min = 0.01, Max = 1, Rounding = 2,
    Callback = function(v) getgenv().aimbotDelay = v end,
})
BlockPunch:AddSlider("FaceKillerDuration", {
    Text = "持续时间", Default = 3, Min = 1, Max = 10, Rounding = 1,
    Callback = function(v) getgenv().faceKillerDuration = v end,
})

-- Box
BlockBox:AddSlider("BoxLength", {
    Text = "Box长度", Default = 15, Min = 5, Max = 50, Rounding = 1,
    Callback = function(v) getgenv().BoxLength = v end,
})
BlockBox:AddSlider("BoxWidth", {
    Text = "Box宽度", Default = 6, Min = 2, Max = 30, Rounding = 1,
    Callback = function(v) getgenv().BoxWidth = v end,
})
BlockBox:AddSlider("BoxTransparency", {
    Text = "Box透明度", Default = 0.7, Min = 0, Max = 1, Rounding = 2,
    Callback = function(v)
        getgenv().BoxTransparency = v
        getgenv().UpdateBoxColors()
    end,
})

-- Misc
BlockMisc:AddToggle("HDPullToggle", {
    Text = "格挡拉近 (HDPull)", Default = false,
    Callback = function(v) getgenv().HDPullEnabled = v end,
})
BlockMisc:AddSlider("HDSpeed", {
    Text = "拉近速度", Default = 12, Min = 5, Max = 50, Rounding = 1,
    Callback = function(v) getgenv().HDSpeed = v end,
})

-- ============================================
-- 能力 Tab
-- ============================================
local AbilityGroup = Tabs.Ability:AddLeftGroupbox("修机 / 连接 / 体力", "user-round-pen")
AbilityGroup:AddToggle("QuickRepairToggle", {
    Text = "快速修机", Default = false,
    Callback = function(v) if v then StartQuickRepair() else StopQuickRepair() end end,
})
AbilityGroup:AddToggle("AutoConnectToggle", {
    Text = "自动连接", Default = false,
    Callback = function(v) if v then StartAutoConnect() else StopAutoConnect() end end,
})
AbilityGroup:AddToggle("InfiniteStaminaToggle", {
    Text = "无限体力", Default = false,
    Callback = function(v) if v then StartInfiniteStamina() else StopInfiniteStamina() end end,
})
AbilityGroup:AddDivider()
AbilityGroup:AddButton({ Text = "无敌模式", Func = FakeGodMode })

-- ============================================
-- 设置 Tab
-- ============================================
local SettingsGroup = Tabs.Settings:AddLeftGroupbox("Menu")
SettingsGroup:AddButton("卸载", function()
    StopNoclip(); StopFly()
    StopQuickRepair(); StopAutoConnect(); StopInfiniteStamina()
    getgenv().AutoBlockEnabled = false
    for _, data in pairs(getgenv().KillerCircles) do
        if data.innerCircle then data.innerCircle:Destroy() end
        if data.outerCircle then data.outerCircle:Destroy() end
        if data.visualization and data.visualization.folder then data.visualization.folder:Destroy() end
    end
    Library:Unload()
end)
SettingsGroup:AddLabel("Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift", NoUI = true, Text = "Menu keybind",
})
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("PGSCRIPT")
SaveManager:SetFolder("PGSCRIPT/Configs")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

print("[PG SCRIPT] 已加载")
