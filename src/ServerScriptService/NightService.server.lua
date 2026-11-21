-- Night 1 server-owned state. Playable prototype; Studio QA is still required.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local map = workspace:WaitForChild("CRN_Night1")
local doors = map:WaitForChild("Doors")
local enemy = map:WaitForChild("Enemies"):WaitForChild("Subject06")

local function container(parent, className, name)
    local v = parent:FindFirstChild(name)
    if v and not v:IsA(className) then v:Destroy(); v = nil end
    if not v then
        v = Instance.new(className)
        v.Name = name
        v.Parent = parent
    end
    return v
end

local remote = container(ReplicatedStorage, "RemoteEvent", "CRN_Night1Action")
local state = container(ReplicatedStorage, "Folder", "CRN_Night1State")
local function value(className, name, initial)
    local v = container(state, className, name)
    v.Value = initial
    return v
end
local status = value("StringValue", "Status", "READY")
local hour = value("IntValue", "Hour", 0)
local power = value("NumberValue", "Power", Config.MaxPower)
local leftDoor = value("BoolValue", "LeftDoor", false)
local rightDoor = value("BoolValue", "RightDoor", false)
local enemySide = value("StringValue", "EnemySide", "Left")
local enemyStage = value("IntValue", "EnemyStage", 0)
local notice = value("StringValue", "Notice", "Начни первую смену. Продержись до 06:00.")

local stagePositions = {
    Left = {
        Vector3.new(-43, 3, -28),
        Vector3.new(-35, 3, -16),
        Vector3.new(-24, 3, -6),
        Vector3.new(-18, 3, 0),
    },
    Right = {
        Vector3.new(43, 3, -28),
        Vector3.new(35, 3, -16),
        Vector3.new(24, 3, -6),
        Vector3.new(18, 3, 0),
    },
}
local elapsed = 0
local lastTick = os.clock()
local nextAdvance = 0
local approachTime = 0
local repelledAt = 0
local cameraUsers = {}
local actionCooldowns = {}

local function teleportOffice(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame = CFrame.new(Config.OfficeSpawn) end
end

local function doorsOpen()
    return not leftDoor.Value and not rightDoor.Value
end

local function setDoor(which, closed)
    local v = which == "Left" and leftDoor or rightDoor
    local object = doors:FindFirstChild(which)
    if not object then return end
    v.Value = closed
    object:SetAttribute("Closed", closed)
    object.CanCollide = closed
    local target = object:GetAttribute(closed and "ClosedCFrame" or "OpenCFrame")
    if typeof(target) == "CFrame" then
        TweenService:Create(object, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {CFrame = target}):Play()
    end
end

local function placeEnemy()
    local positions = stagePositions[enemySide.Value]
    enemy.CFrame = CFrame.new(positions[enemyStage.Value + 1])
    enemy:SetAttribute("Stage", enemyStage.Value)
    enemy:SetAttribute("Side", enemySide.Value)
end

local function nextEnemyStep(now)
    nextAdvance = now + math.random(Config.EnemyAdvanceMinSeconds, Config.EnemyAdvanceMaxSeconds)
end

local function resetEnemy(now)
    enemyStage.Value = 0
    enemySide.Value = (enemySide.Value == "Left") and "Right" or "Left"
    approachTime = 0
    repelledAt = 0
    placeEnemy()
    nextEnemyStep(now)
end

local function finish(result, message)
    if status.Value ~= "RUNNING" then return end
    status.Value = result
    notice.Value = message
    for player in pairs(cameraUsers) do cameraUsers[player] = nil end
    setDoor("Left", false)
    setDoor("Right", false)
    print("[CRN Night1] " .. result .. ": " .. message)
end

local function reset()
    status.Value = "READY"
    hour.Value = 0
    power.Value = Config.MaxPower
    elapsed = 0
    notice.Value = "Новая попытка. Запусти первую ночь."
    enemySide.Value = "Left"
    enemyStage.Value = 0
    placeEnemy()
    for player in pairs(cameraUsers) do cameraUsers[player] = nil end
    setDoor("Left", false)
    setDoor("Right", false)
end

local function begin(player)
    if status.Value ~= "READY" then return end
    status.Value = "RUNNING"
    hour.Value = 0
    power.Value = Config.MaxPower
    elapsed = 0
    enemySide.Value = "Left"
    enemyStage.Value = 0
    placeEnemy()
    nextEnemyStep(os.clock())
    notice.Value = "00:00. Следи за камерами. Закрывай двери при угрозе."
    for _, participant in ipairs(Players:GetPlayers()) do teleportOffice(participant) end
    print("[CRN Night1] Night started by " .. player.Name)
end

local allowed = {StartNight = true, RestartNight = true, ToggleDoor = true, CameraState = true}
remote.OnServerEvent:Connect(function(player, action, arg)
    if typeof(action) ~= "string" or not allowed[action] then return end
    local now = os.clock()
    local recent = actionCooldowns[player] or {}
    actionCooldowns[player] = recent
    if now - (recent[action] or -1000) < 0.2 then return end
    recent[action] = now
    if action == "StartNight" then
        if arg == nil then begin(player) end
        return
    end
    if action == "RestartNight" then
        if arg == nil and (status.Value == "WIN" or status.Value == "LOSE") then reset() end
        return
    end
    if status.Value ~= "RUNNING" then return end
    if action == "ToggleDoor" then
        if arg ~= "Left" and arg ~= "Right" then return end
        if power.Value <= 0 then return end
        if arg == "Left" then setDoor("Left", not leftDoor.Value)
        else setDoor("Right", not rightDoor.Value) end
    elseif action == "CameraState" then
        if typeof(arg) ~= "boolean" then return end
        cameraUsers[player] = arg or nil
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        local root = character:WaitForChild("HumanoidRootPart", 10)
        if root then
            task.wait(0.1)
            teleportOffice(player)
        end
    end)
end)
Players.PlayerRemoving:Connect(function(player)
    cameraUsers[player] = nil
    actionCooldowns[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do teleportOffice(player) end
placeEnemy()

while true do
    task.wait(0.2)
    local now = os.clock()
    local dt = math.min(now - lastTick, 0.5)
    lastTick = now
    if status.Value == "RUNNING" then
        elapsed += dt
        hour.Value = math.min(6, math.floor(elapsed / (Config.NightLengthSeconds / 6)))
        if elapsed >= Config.NightLengthSeconds then
            hour.Value = 6
            finish("WIN", "06:00. Ты пережил первую ночь!")
        else
            local cameraActive = false
            for player, watching in pairs(cameraUsers) do
                if watching and player.Parent == Players then cameraActive = true; break end
            end
            local drain = Config.BasePowerDrainPerSecond
            if leftDoor.Value then drain += Config.DoorDrainPerSecond end
            if rightDoor.Value then drain += Config.DoorDrainPerSecond end
            if cameraActive then drain += Config.CameraDrainPerSecond end
            power.Value = math.max(0, power.Value - drain * dt)
            if power.Value <= 0 then
                setDoor("Left", false)
                setDoor("Right", false)
                finish("LOSE", "Энергия закончилась. Двери открыты.")
            elseif enemyStage.Value == 3 then
                local closed = (enemySide.Value == "Left") and leftDoor.Value or rightDoor.Value
                if closed then
                    if repelledAt == 0 then
                        repelledAt = now
                        notice.Value = "Существо за дверью! Не открывай."
                    elseif now - repelledAt >= Config.EnemyRepelSeconds then
                        resetEnemy(now)
                        notice.Value = "Шаги удаляются."
                    end
                elseif now - approachTime >= Config.EnemyAttackDelaySeconds then
                    finish("LOSE", "Subject 06 проник в комнату охраны.")
                else
                    repelledAt = 0
                end
            elseif now >= nextAdvance then
                enemyStage.Value += 1
                placeEnemy()
                nextEnemyStep(now)
                if enemyStage.Value == 3 then
                    approachTime = now
                    repelledAt = 0
                    notice.Value = "Шаги рядом с " .. (enemySide.Value == "Left" and "левой" or "правой") .. " дверью!"
                else
                    notice.Value = "Помехи в коридоре. Проверь камеры."
                end
            end
        end
    end
end
