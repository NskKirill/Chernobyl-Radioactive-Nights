-- Server-authoritative co-op expedition: objectives, hazards, resources, checkpoints and replay.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local function folder(parent, name)
    local item = parent:FindFirstChild(name)
    if not item then
        item = Instance.new("Folder")
        item.Name = name
        item.Parent = parent
    end
    return item
end

local function remote(parent, name)
    local item = parent:FindFirstChild(name)
    if item and not item:IsA("RemoteEvent") then
        warn("[CRN] " .. name .. " exists but is not a RemoteEvent; gameplay input disabled.")
        return nil
    end
    if not item then
        item = Instance.new("RemoteEvent")
        item.Name = name
        item.Parent = parent
    end
    return item
end

local function stateValue(className, name, defaultValue)
    local state = folder(ReplicatedStorage, "GameState")
    local item = state:FindFirstChild(name)
    if item and not item:IsA(className) then
        warn("[CRN] GameState." .. name .. " has the wrong type; keeping the existing object.")
        return nil
    end
    if not item then
        item = Instance.new(className)
        item.Name = name
        item.Parent = state
    end
    item.Value = defaultValue
    return item
end

local remotes = folder(ReplicatedStorage, "CRN_Remotes")
local actionRemote = remote(remotes, "Action")
local noticeRemote = remote(remotes, "Notice")
if not actionRemote or not noticeRemote then
    error("[CRN] Required RemoteEvents are unavailable.")
end

local status = stateValue("StringValue", "Status", "READY")
local stage = stateValue("StringValue", "Stage", "READY")
local objective = stateValue("StringValue", "Objective", "Подготовься у терминала и выйди через шлюз.")
local relayCount = stateValue("IntValue", "RelayCount", 0)
local runSeconds = stateValue("NumberValue", "RunSeconds", 0)
local nightActive = ReplicatedStorage:FindFirstChild("GameState") and ReplicatedStorage.GameState:FindFirstChild("NightActive")
if nightActive and nightActive:IsA("BoolValue") then
    nightActive.Value = false
end

local map = Workspace:WaitForChild("CRN_Expedition", 45)
if not map then
    error("[CRN] CRN_Expedition was not built.")
end
local shelter = map:WaitForChild("Shelter")
local supplies = map:WaitForChild("Supplies")
local objectives = map:WaitForChild("Objectives")
local hazards = map:WaitForChild("Hazards")
local checkpoints = map:WaitForChild("Checkpoints")
local startConsole = shelter:WaitForChild("StartConsole")
local startPrompt = startConsole:WaitForChild("Interact")
local airlockGate = shelter:WaitForChild("AirlockGate")
local extractionBeacon = objectives:WaitForChild("ExtractionBeacon")
local extractionPrompt = extractionBeacon:WaitForChild("Interact")
local checkpointParts = checkpoints:GetChildren()
local hazardParts = hazards:GetChildren()

Players.RespawnTime = Config.Survival.RespawnDelay

local playerData = {}
local boundPrompts = {}
local actionTimes = {}
local promptTimes = {}
local lampNoticeSent = {}
local startedAt = 0
local lastWorldTick = os.clock()

local function notifyPlayer(player, message, kind)
    noticeRemote:FireClient(player, message, kind or "INFO")
end

local function notifyTeam(message, kind)
    noticeRemote:FireAllClients(message, kind or "INFO")
end

local function rootOf(player)
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function humanoidOf(player)
    local character = player.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function near(player, target, maxDistance)
    local root = rootOf(player)
    return root ~= nil and target ~= nil and target:IsA("BasePart")
        and (root.Position - target.Position).Magnitude <= maxDistance
end

local function pointInside(box, position, margin)
    local p = box.CFrame:PointToObjectSpace(position)
    local extra = margin or 0
    return math.abs(p.X) <= box.Size.X * 0.5 + extra
        and math.abs(p.Y) <= box.Size.Y * 0.5 + extra
        and math.abs(p.Z) <= box.Size.Z * 0.5 + extra
end

local function setPlayerAttribute(player, name, value)
    if player:GetAttribute(name) ~= value then
        player:SetAttribute(name, value)
    end
end

local function syncPlayer(player, data)
    setPlayerAttribute(player, "InRun", data.inRun)
    setPlayerAttribute(player, "OutOfRun", data.out)
    setPlayerAttribute(player, "Zone", data.zone)
    setPlayerAttribute(player, "Checkpoint", data.checkpoint)
    setPlayerAttribute(player, "Lives", data.lives)
    setPlayerAttribute(player, "Radiation", math.floor(data.radiation + 0.5))
    setPlayerAttribute(player, "FilterSeconds", math.floor(data.filterSeconds + 0.5))
    setPlayerAttribute(player, "FilterCartridges", data.filterCartridges)
    setPlayerAttribute(player, "Medkits", data.medkits)
    setPlayerAttribute(player, "Battery", math.floor(data.battery + 0.5))
    setPlayerAttribute(player, "LampOn", data.lampOn)
    setPlayerAttribute(player, "Paused", data.paused)
end

local function createData()
    return {
        inRun = false,
        out = false,
        paused = false,
        lives = Config.Player.StartingLives,
        radiation = Config.Player.StartingRadiation,
        filterSeconds = Config.Player.StartingFilterSeconds,
        filterCartridges = Config.Player.StartingFilterCartridges,
        medkits = Config.Player.StartingMedkits,
        battery = Config.Player.StartingBattery,
        lampOn = false,
        zone = "Убежище",
        checkpoint = "CP_Shelter",
        checkpointIndex = 0,
        hazardState = {},
        nextDamageAt = {},
        fallRecoverAt = 0,
        savedWalkSpeed = 16,
        savedJumpPower = 50,
    }
end

local function setLamp(player, data, enabled)
    data.lampOn = enabled and data.battery > 0
    local character = player.Character
    local head = character and character:FindFirstChild("Head")
    if head then
        local lamp = head:FindFirstChild("CRN_Flashlight")
        if lamp and lamp:IsA("SpotLight") then
            lamp.Enabled = data.lampOn
        end
    end
    if enabled and not data.lampOn then
        notifyPlayer(player, "Батарея фонаря разряжена.", "WARN")
    end
end

local function checkpointFor(data)
    local found
    for _, item in ipairs(checkpointParts) do
        if item:IsA("BasePart") and item.Name == data.checkpoint then
            found = item
            break
        end
    end
    return found or shelter:FindFirstChild("ShelterSpawn")
end

local function moveToCheckpoint(player, data)
    local root = rootOf(player)
    local target = checkpointFor(data)
    if root and target and target:IsA("BasePart") then
        root.CFrame = target.CFrame + Vector3.new(0, Config.World.CheckpointRespawnHeight, 0)
        root.AssemblyLinearVelocity = Vector3.zero
    end
end

local function restorePause(player, data)
    data.paused = false
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if root then root.Anchored = false end
    if humanoid then
        humanoid.WalkSpeed = data.savedWalkSpeed or 16
        humanoid.JumpPower = data.savedJumpPower or 50
        humanoid.AutoRotate = true
    end
    syncPlayer(player, data)
end

local function setupCharacter(player, character)
    local data = playerData[player]
    if not data then return end
    local humanoid = character:WaitForChild("Humanoid", 10)
    local root = character:WaitForChild("HumanoidRootPart", 10)
    if not humanoid or not root then return end

    humanoid.MaxHealth = Config.Player.MaxHealth
    humanoid.Health = Config.Player.MaxHealth
    data.paused = false
    setLamp(player, data, false)
    local head = character:FindFirstChild("Head")
    if head and not head:FindFirstChild("CRN_Flashlight") then
        local lamp = Instance.new("SpotLight")
        lamp.Name = "CRN_Flashlight"
        lamp.Face = Enum.NormalId.Front
        lamp.Angle = 74
        lamp.Brightness = 1.5
        lamp.Range = 30
        lamp.Color = Color3.fromRGB(203, 225, 191)
        lamp.Enabled = false
        lamp.Parent = head
    end

    task.wait(0.1)
    if status.Value == "RUNNING" and data.inRun and not data.out then
        moveToCheckpoint(player, data)
    else
        local spawn = shelter:FindFirstChild("ShelterSpawn")
        if spawn and spawn:IsA("BasePart") then
            root.CFrame = spawn.CFrame + Vector3.new(0, 4, 0)
        end
    end
    syncPlayer(player, data)

    humanoid.HealthChanged:Connect(function(health)
        setPlayerAttribute(player, "Health", math.floor(health + 0.5))
    end)
    setPlayerAttribute(player, "Health", math.floor(humanoid.Health + 0.5))

    humanoid.Died:Connect(function()
        if status.Value ~= "RUNNING" or not data.inRun or data.out then return end
        if data.paused then restorePause(player, data) end
        data.lives = math.max(0, data.lives - 1)
        data.lampOn = false
        notifyTeam(player.DisplayName .. " выбыл на маршруте. Осталось жизней: " .. tostring(data.lives) .. ".", "WARN")
        if data.lives <= 0 then
            data.out = true
            setPlayerAttribute(player, "OutOfRun", true)
        end
        syncPlayer(player, data)
        task.delay(Config.Survival.RespawnDelay + 0.5, function()
            if player.Parent ~= Players then return end
            local newCharacter = player.Character
            local newRoot = newCharacter and newCharacter:FindFirstChild("HumanoidRootPart")
            local newHumanoid = newCharacter and newCharacter:FindFirstChildOfClass("Humanoid")
            if not newRoot or not newHumanoid then return end
            if data.out then
                local spawn = shelter:FindFirstChild("ShelterSpawn")
                if spawn then newRoot.CFrame = spawn.CFrame + Vector3.new(0, 4, 0) end
                newRoot.Anchored = true
                newHumanoid.WalkSpeed = 0
                newHumanoid.JumpPower = 0
                notifyPlayer(player, "Запас жизней исчерпан. Дождись конца вылазки.", "WARN")
            else
                moveToCheckpoint(player, data)
                notifyPlayer(player, "Возрождение на последней безопасной точке.", "INFO")
            end
            local runners = 0
            for _, otherData in pairs(playerData) do
                if otherData.inRun and not otherData.out then runners += 1 end
            end
            if runners == 0 and status.Value == "RUNNING" then
                status.Value = "LOSE"
                stage.Value = "LOSE"
                objective.Value = Config.StageText.LOSE
                if nightActive and nightActive:IsA("BoolValue") then nightActive.Value = false end
                notifyTeam("Вся команда выбыла. Вылазка сорвана.", "LOSE")
            end
        end)
    end)
end

local function latestTeamCheckpoint()
    local best = 0
    local name = "CP_Shelter"
    for _, data in pairs(playerData) do
        if data.inRun and data.checkpointIndex > best then
            best = data.checkpointIndex
            name = data.checkpoint
        end
    end
    return name, best
end

local function setMissionStage()
    if relayCount.Value == 0 then
        stage.Value = "STATION"
        objective.Value = "Сними ретранслятор 1/3 на платформе станции."
    elseif relayCount.Value == 1 then
        stage.Value = "TUNNEL"
        objective.Value = "Пройди сервисный тоннель и сними ретранслятор 2/3."
    elseif relayCount.Value == 2 then
        stage.Value = "SURFACE"
        objective.Value = "Пересечь заражённую поверхность и забрать ретранслятор 3/3."
    else
        stage.Value = "EXTRACTION"
        objective.Value = "Все ретрансляторы собраны. Активируй маяк на северной гряде."
    end
end

local function activeRunnerCount()
    local n = 0
    for _, data in pairs(playerData) do
        if data.inRun and not data.out then n += 1 end
    end
    return n
end

local function startRun(player)
    if status.Value ~= "READY" then return end
    if not near(player, startConsole, 18) then
        notifyPlayer(player, "Подойди к плану вылазки в убежище.", "WARN")
        return
    end
    local accepted = 0
    for _, participant in ipairs(Players:GetPlayers()) do
        local data = playerData[participant]
        if data and accepted < Config.MaxPartySize then
            data.inRun = true
            data.out = false
            data.paused = false
            data.lives = Config.Player.StartingLives
            data.radiation = Config.Player.StartingRadiation
            data.filterSeconds = Config.Player.StartingFilterSeconds
            data.filterCartridges = Config.Player.StartingFilterCartridges
            data.medkits = Config.Player.StartingMedkits
            data.battery = Config.Player.StartingBattery
            data.lampOn = data.battery > 0
            data.zone = "Убежище"
            data.checkpoint = "CP_Shelter"
            data.checkpointIndex = 0
            data.hazardState = {}
            data.nextDamageAt = {}
            setLamp(participant, data, data.lampOn)
            syncPlayer(participant, data)
            accepted += 1
        elseif data then
            data.inRun = false
            syncPlayer(participant, data)
            notifyPlayer(participant, "Вылазка рассчитана максимум на четырёх участников.", "WARN")
        end
    end
    if accepted == 0 then return end

    relayCount.Value = 0
    runSeconds.Value = 0
    startedAt = os.clock()
    startPrompt.Enabled = false
    status.Value = "RUNNING"
    setMissionStage()
    if nightActive and nightActive:IsA("BoolValue") then nightActive.Value = true end
    airlockGate.CanCollide = false
    airlockGate:SetAttribute("Closed", false)
    TweenService:Create(airlockGate, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = airlockGate:GetAttribute("OpenCFrame")
    }):Play()
    notifyTeam("Вылазка началась. Цель: снять три ретранслятора и подать сигнал эвакуации.", "INFO")
    print("[CRN] Expedition started.")
end

local function grantSupply(player, supplyType)
    local data = playerData[player]
    if not data or data.out or not data.inRun then return end
    if supplyType == "FILTER" then
        if data.filterSeconds < Config.Player.MaxFilterSeconds then
            data.filterSeconds = math.min(Config.Player.MaxFilterSeconds, data.filterSeconds + 60)
        else
            data.filterCartridges = math.min(Config.Player.MaxFilterCartridges, data.filterCartridges + 1)
        end
    elseif supplyType == "MEDKIT" then
        data.medkits = math.min(Config.Player.MaxMedkits, data.medkits + 1)
    elseif supplyType == "BATTERY" then
        data.battery = math.min(100, data.battery + 45)
    end
    syncPlayer(player, data)
end

local function collectSupply(player, target)
    local data = playerData[player]
    if status.Value ~= "RUNNING" or not data or not data.inRun or data.out then return end
    if not target:IsDescendantOf(supplies) or target:GetAttribute("Collected") then return end
    if not near(player, target, 14) then return end
    local supplyType = target:GetAttribute("SupplyType")
    if supplyType ~= "FILTER" and supplyType ~= "MEDKIT" and supplyType ~= "BATTERY" then return end

    target:SetAttribute("Collected", true)
    target.Transparency = 1
    target.CanCollide = false
    for _, child in ipairs(target:GetDescendants()) do
        if child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight") then child.Enabled = false end
    end
    local promptObject = target:FindFirstChild("Interact")
    if promptObject and promptObject:IsA("ProximityPrompt") then promptObject.Enabled = false end
    for participant, participantData in pairs(playerData) do
        if participantData.inRun and not participantData.out then
            grantSupply(participant, supplyType)
        end
    end
    local names = {FILTER = "фильтр", MEDKIT = "аптечка", BATTERY = "батарея"}
    notifyTeam("Команда забрала: " .. names[supplyType] .. ".", "INFO")
end

local function collectRelay(player, target)
    local data = playerData[player]
    if status.Value ~= "RUNNING" or not data or not data.inRun or data.out then return end
    if not target:IsDescendantOf(objectives) or target:GetAttribute("Collected") then return end
    if not near(player, target, 14) then return end
    local stepNumber = target:GetAttribute("RelayStep")
    if typeof(stepNumber) ~= "number" or stepNumber ~= relayCount.Value + 1 then
        notifyPlayer(player, "Сначала выполни цель текущего этапа.", "WARN")
        return
    end

    target:SetAttribute("Collected", true)
    target.Transparency = 1
    target.CanCollide = false
    for _, child in ipairs(target:GetDescendants()) do
        if child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight") then child.Enabled = false end
    end
    local promptObject = target:FindFirstChild("Interact")
    if promptObject and promptObject:IsA("ProximityPrompt") then promptObject.Enabled = false end
    relayCount.Value = stepNumber
    setMissionStage()
    notifyTeam("Ретранслятор " .. tostring(stepNumber) .. "/3 получен.", "WIN")
    if stepNumber == 3 then
        extractionBeacon:SetAttribute("Active", true)
        extractionPrompt.Enabled = true
    end
end

local function finishRun(result, message)
    if status.Value ~= "RUNNING" then return end
    status.Value = result
    stage.Value = result
    objective.Value = Config.StageText[result] or result
    if nightActive and nightActive:IsA("BoolValue") then nightActive.Value = false end
    extractionBeacon:SetAttribute("Active", false)
    extractionPrompt.Enabled = false
    for player, data in pairs(playerData) do
        if data.paused then restorePause(player, data) end
        setLamp(player, data, false)
    end
    notifyTeam(message or (result == "WIN" and "Сигнал принят. Вылазка завершена!" or "Вылазка сорвана."), result)
    print("[CRN] Expedition ended: " .. result)
end

local function extract(player)
    local data = playerData[player]
    if status.Value ~= "RUNNING" or relayCount.Value < 3 or not data or not data.inRun or data.out then return end
    if not extractionBeacon:GetAttribute("Active") or not near(player, extractionBeacon, 14) then return end
    extractionBeacon:SetAttribute("Active", false)
    extractionPrompt.Enabled = false
    finishRun("WIN", "Сигнал принят. Команда эвакуирована!")
end

local function bindPrompt(promptObject)
    if boundPrompts[promptObject] or not promptObject:IsA("ProximityPrompt") then return end
    boundPrompts[promptObject] = true
    local target = promptObject.Parent
    if not target or not target:IsA("BasePart") then return end
    promptObject.Triggered:Connect(function(player)
        if not playerData[player] then return end
        local now = os.clock()
        local last = promptTimes[player] or 0
        if now - last < 0.45 then return end
        promptTimes[player] = now
        if target == startConsole then
            -- Route both HUD and world-prompt requests through the same server
            -- validation so an out-of-range prompt interaction gets feedback.
            startRun(player)
        elseif target == extractionBeacon then
            extract(player)
        elseif target:GetAttribute("RelayStep") then
            collectRelay(player, target)
        elseif target:GetAttribute("SupplyType") then
            collectSupply(player, target)
        end
    end)
end

for _, item in ipairs(map:GetDescendants()) do
    if item:IsA("ProximityPrompt") then bindPrompt(item) end
end
map.DescendantAdded:Connect(function(item)
    if item:IsA("ProximityPrompt") then bindPrompt(item) end
end)
extractionPrompt.Enabled = false

local function resetRun(player)
    if status.Value ~= "WIN" and status.Value ~= "LOSE" then
        notifyPlayer(player, "Новая попытка доступна после завершения вылазки.", "WARN")
        return
    end
    status.Value = "READY"
    stage.Value = "READY"
    startPrompt.Enabled = true
    objective.Value = "Проверь снаряжение у стола и нажми «Начать вылазку»."
    relayCount.Value = 0
    runSeconds.Value = 0
    startedAt = 0
    if nightActive and nightActive:IsA("BoolValue") then nightActive.Value = false end

    for _, item in ipairs(supplies:GetChildren()) do
        if item:IsA("BasePart") then
            item:SetAttribute("Collected", false)
            item.Transparency = 0
            item.CanCollide = true
            for _, child in ipairs(item:GetDescendants()) do
                if child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight") then child.Enabled = true end
            end
            local pp = item:FindFirstChild("Interact")
            if pp and pp:IsA("ProximityPrompt") then pp.Enabled = true end
        end
    end
    for _, item in ipairs(objectives:GetChildren()) do
        if item:IsA("BasePart") and item:GetAttribute("RelayStep") then
            item:SetAttribute("Collected", false)
            item.Transparency = 0
            item.CanCollide = true
            for _, child in ipairs(item:GetDescendants()) do
                if child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight") then child.Enabled = true end
            end
            local pp = item:FindFirstChild("Interact")
            if pp and pp:IsA("ProximityPrompt") then pp.Enabled = true end
        end
    end
    extractionBeacon:SetAttribute("Active", false)
    extractionPrompt.Enabled = false
    airlockGate.CFrame = airlockGate:GetAttribute("ClosedCFrame")
    airlockGate.CanCollide = true
    airlockGate:SetAttribute("Closed", true)

    for participant, data in pairs(playerData) do
        data.inRun = false
        data.out = false
        data.paused = false
        data.lives = Config.Player.StartingLives
        data.radiation = Config.Player.StartingRadiation
        data.filterSeconds = Config.Player.StartingFilterSeconds
        data.filterCartridges = Config.Player.StartingFilterCartridges
        data.medkits = Config.Player.StartingMedkits
        data.battery = Config.Player.StartingBattery
        data.lampOn = false
        data.zone = "Убежище"
        data.checkpoint = "CP_Shelter"
        data.checkpointIndex = 0
        data.hazardState = {}
        data.nextDamageAt = {}
        lampNoticeSent[participant] = nil
        syncPlayer(participant, data)
        task.spawn(function()
            if participant.Parent == Players then
                pcall(function() participant:LoadCharacter() end)
            end
        end)
    end
    notifyTeam("Снаряжение и маршрут сброшены. Новая попытка готова.", "INFO")
    print("[CRN] Expedition reset.")
end

local function canUseRemote(player, actionName)
    local now = os.clock()
    local last = actionTimes[player] or {}
    actionTimes[player] = last
    local previous = last[actionName] or 0
    if now - previous < 0.35 then return false end
    last[actionName] = now
    return true
end

local allowedActions = {
    StartRun = true,
    RestartRun = true,
    UseMedkit = true,
    UseFilter = true,
    ToggleLamp = true,
    Pause = true,
    Resume = true,
    Camera = true,
}

actionRemote.OnServerEvent:Connect(function(player, actionName, payload)
    if typeof(actionName) ~= "string" or not allowedActions[actionName] or not canUseRemote(player, actionName) then return end
    if actionName == "Camera" then
        if typeof(payload) ~= "number" or payload % 1 ~= 0 or payload < 1 or payload > 3 then return end
        if status.Value ~= "READY" or not near(player, startConsole, 70) then
            notifyPlayer(player, "Камеры доступны только у плана в убежище.", "WARN")
            return
        end
        notifyPlayer(player, "Камера разведки " .. string.format("%02d", payload) .. ".", "INFO")
        return
    elseif payload ~= nil then
        return
    end

    local data = playerData[player]
    if actionName == "StartRun" then
        startRun(player)
        return
    elseif actionName == "RestartRun" then
        resetRun(player)
        return
    end
    if status.Value ~= "RUNNING" or not data or not data.inRun or data.out then return end

    if actionName == "Pause" then
        if data.paused then return end
        data.paused = true
        local root = rootOf(player)
        local humanoid = humanoidOf(player)
        if root then root.Anchored = true end
        if humanoid then
            data.savedWalkSpeed = humanoid.WalkSpeed
            data.savedJumpPower = humanoid.JumpPower
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
            humanoid.AutoRotate = false
        end
        syncPlayer(player, data)
        notifyPlayer(player, "Личная пауза. В кооперативе время продолжает идти для команды.", "INFO")
    elseif actionName == "Resume" then
        if data.paused then restorePause(player, data) end
    elseif data.paused then
        return
    elseif actionName == "UseMedkit" then
        local humanoid = humanoidOf(player)
        if data.medkits <= 0 or not humanoid or humanoid.Health >= humanoid.MaxHealth - 2 then
            notifyPlayer(player, "Аптечка недоступна или здоровье уже полное.", "WARN")
            return
        end
        data.medkits -= 1
        humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 40)
        syncPlayer(player, data)
        notifyPlayer(player, "Аптечка использована: +40 здоровья.", "INFO")
    elseif actionName == "UseFilter" then
        if data.filterCartridges <= 0 or data.filterSeconds >= Config.Player.MaxFilterSeconds - 10 then
            notifyPlayer(player, "Новый фильтр не требуется или запас исчерпан.", "WARN")
            return
        end
        data.filterCartridges -= 1
        data.filterSeconds = math.min(Config.Player.MaxFilterSeconds, data.filterSeconds + 90)
        syncPlayer(player, data)
        notifyPlayer(player, "Картридж заменён.", "INFO")
    elseif actionName == "ToggleLamp" then
        setLamp(player, data, not data.lampOn)
        syncPlayer(player, data)
    end
end)

local function initializePlayer(player)
    if playerData[player] then return end
    local data = createData()
    playerData[player] = data

    if status.Value == "RUNNING" then
        if activeRunnerCount() < Config.MaxPartySize then
            local latestName, latestIndex = latestTeamCheckpoint()
            data.inRun = true
            data.checkpoint = latestName
            data.checkpointIndex = latestIndex
            data.zone = "Маршрут"
            notifyPlayer(player, "Ты присоединился к текущей вылазке у последней безопасной точки.", "INFO")
        else
            notifyPlayer(player, "Команда заполнена. Ты останешься вне текущей вылазки.", "WARN")
        end
    end

    syncPlayer(player, data)
    player.CharacterAdded:Connect(function(character)
        setupCharacter(player, character)
    end)
    if player.Character then
        task.spawn(setupCharacter, player, player.Character)
    end
end

Players.PlayerAdded:Connect(initializePlayer)
Players.PlayerRemoving:Connect(function(player)
    playerData[player] = nil
    actionTimes[player] = nil
    promptTimes[player] = nil
    lampNoticeSent[player] = nil
    if status.Value == "RUNNING" and activeRunnerCount() == 0 then
        status.Value = "LOSE"
        stage.Value = "LOSE"
        objective.Value = Config.StageText.LOSE
        if nightActive and nightActive:IsA("BoolValue") then nightActive.Value = false end
        notifyTeam("Команда покинула сервер. Вылазка сорвана.", "LOSE")
    end
end)
for _, player in ipairs(Players:GetPlayers()) do initializePlayer(player) end

local function updateCheckpointsAndHazards(player, data, now, dt)
    if data.paused or data.out then return end
    local root = rootOf(player)
    local humanoid = humanoidOf(player)
    if not root or not humanoid or humanoid.Health <= 0 then return end

    local z = root.Position.Z
    if z < 40 then data.zone = "Убежище"
    elseif z < 160 then data.zone = "Станция Каскад"
    elseif z < 330 then data.zone = "Сервисный тоннель"
    elseif z < 610 then data.zone = "Поверхность"
    else data.zone = "Северная гряда" end

    for _, marker in ipairs(checkpointParts) do
        if marker:IsA("BasePart") and pointInside(marker, root.Position, 1) then
            local index = marker:GetAttribute("Index")
            if typeof(index) == "number" and index > data.checkpointIndex then
                data.checkpoint = marker.Name
                data.checkpointIndex = index
                data.zone = marker:GetAttribute("Zone") or data.zone
                notifyPlayer(player, "Безопасная точка: " .. data.zone .. ".", "INFO")
            end
        end
    end

    if root.Position.Y < -18 and now >= data.fallRecoverAt then
        data.fallRecoverAt = now + 2
        humanoid:TakeDamage(Config.Survival.FallDamage)
        moveToCheckpoint(player, data)
        notifyPlayer(player, "Падение! Ты возвращён к последней безопасной точке.", "WARN")
    end

    local activeHazards = {}
    for _, field in ipairs(hazardParts) do
        if field:IsA("BasePart") and pointInside(field, root.Position) then
            local kind = field:GetAttribute("HazardType")
            local key = field.Name
            activeHazards[key] = true
            local h = data.hazardState[key]
            if not h then
                h = {enteredAt = now, nextDamageAt = now + (field:GetAttribute("Warning") or 1)}
                data.hazardState[key] = h
                local warnings = {
                    RADIATION = "Дозиметр трещит: радиация. Фильтр расходуется.",
                    ELECTRIC = "Искрит кабель! Отойди или пережди предупреждение.",
                    ANOMALY = "Эхо-цветок пульсирует. Не задерживайся в поле.",
                }
                notifyPlayer(player, warnings[kind] or "Опасная зона.", "WARN")
            end

            if kind == "RADIATION" then
                if data.filterSeconds > 0 then
                    data.filterSeconds = math.max(0, data.filterSeconds - Config.Survival.FilterDrainPerSecond * dt)
                    data.radiation = math.max(0, data.radiation - 0.2 * dt)
                else
                    data.radiation = math.min(100, data.radiation + Config.Survival.RadiationPerSecond * dt)
                    if data.radiation >= 60 then
                        humanoid:TakeDamage(Config.Survival.UnfilteredHealthPerSecond * dt)
                    end
                end
            elseif now >= h.nextDamageAt then
                local damage = field:GetAttribute("Damage") or 0
                if damage > 0 then humanoid:TakeDamage(damage) end
                h.nextDamageAt = now + (kind == "ELECTRIC" and 1.3 or 1)
            end
        end
    end
    for key in pairs(data.hazardState) do
        if not activeHazards[key] then data.hazardState[key] = nil end
    end

    if data.lampOn then
        data.battery = math.max(0, data.battery - Config.Lamp.DrainPerSecond * dt)
        if data.battery <= 0 then
            setLamp(player, data, false)
            if not lampNoticeSent[player] then
                lampNoticeSent[player] = true
                notifyPlayer(player, "Фонарь погас: батарея разряжена.", "WARN")
            end
        elseif data.battery <= Config.Lamp.LowBatteryNotice and not lampNoticeSent[player] then
            lampNoticeSent[player] = true
            notifyPlayer(player, "Батарея фонаря почти разряжена.", "WARN")
        end
    end
    syncPlayer(player, data)
end

while true do
    task.wait(Config.Survival.HazardTickSeconds)
    local now = os.clock()
    local dt = math.clamp(now - lastWorldTick, 0, 1)
    lastWorldTick = now
    if status.Value == "RUNNING" then
        runSeconds.Value = math.max(0, now - startedAt)
        for player, data in pairs(playerData) do
            if data.inRun then
                updateCheckpointsAndHazards(player, data, now, dt)
            end
        end
        if runSeconds.Value >= Config.RunTimeLimitSeconds then
            finishRun("LOSE", "Время на эвакуацию истекло. Вылазка сорвана.")
        elseif activeRunnerCount() == 0 then
            finishRun("LOSE", "Вся команда выбыла. Вылазка сорвана.")
        end
    end
end
