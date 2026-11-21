-- Chernobyl: Radioactive Nights / Night 1 prototype
-- Solo stationary survival: two security doors, three cameras, power, Subject 06, survive until 06:00.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local HOUR_SECONDS = 60 -- Six game-hours = six real minutes; adjust after playtests.
local ENEMY_STEP_SECONDS = 13
local rng = Random.new()

local function ensure(parent, className, name)
    local old = parent:FindFirstChild(name)
    if old and not old:IsA(className) then
        old:Destroy()
        old = nil
    end
    if not old then
        old = Instance.new(className)
        old.Name = name
        old.Parent = parent
    end
    return old
end

local remotes = ensure(ReplicatedStorage, "Folder", "CRN_Night1")
local action = ensure(remotes, "RemoteEvent", "Action")
local function value(className, name, initial)
    local item = ensure(remotes, className, name)
    item.Value = initial
    return item
end
local status = value("StringValue", "Status", "READY")
local hour = value("IntValue", "Hour", 0)
local energy = value("NumberValue", "Energy", 100)
local leftDoorClosed = value("BoolValue", "LeftDoorClosed", false)
local rightDoorClosed = value("BoolValue", "RightDoorClosed", false)
local cameraIndex = value("IntValue", "CameraIndex", 0)
local enemySide = value("StringValue", "EnemySide", "LEFT")
local enemyStage = value("IntValue", "EnemyStage", 0)
local message = value("StringValue", "Message", "Нажми «Начать ночь». Продержись до 06:00.")

-- Reuse the project's free ProSoundEffects Creator Store selection.
-- Published experience permissions still need validation in the target experience.
local audio = ensure(SoundService, "Folder", "CRN_Night1_Audio")
local function sound(name, assetId, volume, looped)
    local item = ensure(audio, "Sound", name)
    item.SoundId = "rbxassetid://" .. assetId
    item.Volume = volume
    item.Looped = looped or false
    return item
end
local ambience = sound("BunkerHum", "9112775375", 0.12, true)
sound("Door", "9116728376", 0.35)
sound("Alarm", "9118805558", 0.24)
sound("Win", "9113867249", 0.35)
sound("Lose", "9113085764", 0.35)
local cueGenerations = {}
local function playCue(name, duration)
    local cue = audio:FindFirstChild(name)
    cueGenerations[name] = (cueGenerations[name] or 0) + 1
    local generation = cueGenerations[name]
    cue:Stop()
    cue:Play()
    task.delay(duration, function()
        if cueGenerations[name] == generation then cue:Stop() end
    end)
end

-- Build a self-contained bunker so Night 1 runs in a blank Roblox place.
local previous = workspace:FindFirstChild("CRN_Night1_World")
if previous then previous:Destroy() end
local map = Instance.new("Folder")
map.Name = "CRN_Night1_World"
map.Parent = workspace

local function block(name, pos, size, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.Size = size
    p.Position = pos
    p.Color = color
    p.Material = material or Enum.Material.Concrete
    p.Parent = map
    return p
end

block("OfficeFloor", Vector3.new(0, 0, 0), Vector3.new(46, 1, 32), Color3.fromRGB(43, 48, 46))
block("LeftCorridor", Vector3.new(-18, 0, -35), Vector3.new(11, 1, 50), Color3.fromRGB(34, 38, 36))
block("RightCorridor", Vector3.new(18, 0, -35), Vector3.new(11, 1, 50), Color3.fromRGB(34, 38, 36))
block("RearWall", Vector3.new(0, 7, 15), Vector3.new(46, 14, 2), Color3.fromRGB(48, 53, 52))
block("LeftWall", Vector3.new(-23, 7, 0), Vector3.new(2, 14, 32), Color3.fromRGB(47, 53, 50))
block("RightWall", Vector3.new(23, 7, 0), Vector3.new(2, 14, 32), Color3.fromRGB(47, 53, 50))
block("FrontWallCenter", Vector3.new(0, 7, -16), Vector3.new(13, 14, 2), Color3.fromRGB(47, 53, 50))
block("SecurityDesk", Vector3.new(0, 2, 5), Vector3.new(12, 3, 3), Color3.fromRGB(56, 61, 55), Enum.Material.Metal)

local leftDoor = block("LeftSecurityDoor", Vector3.new(-11, 5, -16), Vector3.new(6, 10, 1.5), Color3.fromRGB(130, 42, 38), Enum.Material.Metal)
local rightDoor = block("RightSecurityDoor", Vector3.new(11, 5, -16), Vector3.new(6, 10, 1.5), Color3.fromRGB(130, 42, 38), Enum.Material.Metal)
local function updateDoors()
    for _, pair in ipairs({{leftDoor, leftDoorClosed.Value}, {rightDoor, rightDoorClosed.Value}}) do
        local door, closed = pair[1], pair[2]
        door.Transparency = closed and 0 or 0.75
        door.CanCollide = closed
        door.Color = closed and Color3.fromRGB(170, 48, 43) or Color3.fromRGB(62, 122, 77)
    end
end
leftDoorClosed.Changed:Connect(function()
    updateDoors()
    playCue("Door", 1.4)
end)
rightDoorClosed.Changed:Connect(function()
    updateDoors()
    playCue("Door", 1.4)
end)
updateDoors()

local anchors = Instance.new("Folder")
anchors.Name = "CameraAnchors"
anchors.Parent = map
local function cameraAnchor(name, pos, lookAt)
    local p = block(name, pos, Vector3.new(1, 1, 1), Color3.new(1, 1, 1))
    p.Transparency = 1
    p.CanCollide = false
    p.CFrame = CFrame.lookAt(pos, lookAt)
    p.Parent = anchors
end
cameraAnchor("Camera1", Vector3.new(-22, 10, -14), Vector3.new(-18, 3, -35))
cameraAnchor("Camera2", Vector3.new(22, 10, -14), Vector3.new(18, 3, -35))
cameraAnchor("Camera3", Vector3.new(0, 13, -10), Vector3.new(0, 4, 0))
cameraAnchor("OfficeView", Vector3.new(0, 6, 6), Vector3.new(0, 5, -16))

local enemy = block("Subject06", Vector3.new(0, 3.5, -64), Vector3.new(3, 7, 2), Color3.fromRGB(77, 104, 72), Enum.Material.Metal)
enemy.CanCollide = false
enemy.Transparency = 1
local function enemyPart(name, size, offset, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = enemy.CFrame * CFrame.new(offset)
    part.Color = color
    part.Material = material or Enum.Material.Slate
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.Parent = enemy
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = enemy
    weld.Part1 = part
    weld.Parent = part
    return part
end
local skin = Color3.fromRGB(64, 69, 66)
local darkSkin = Color3.fromRGB(29, 33, 32)
enemyPart("Torso", Vector3.new(2.4, 2.9, 1.25), Vector3.new(0, 0.8, 0), skin)
enemyPart("HunchedBack", Vector3.new(2.2, 1.5, 0.8), Vector3.new(0, 1.6, 0.5), darkSkin)
enemyPart("Head", Vector3.new(1.35, 1.5, 1.15), Vector3.new(0, 3, -0.2), skin)
enemyPart("Jaw", Vector3.new(1, 0.5, 0.8), Vector3.new(0, 2.5, -0.6), darkSkin)
for _, side in ipairs({-1, 1}) do
    enemyPart("Arm", Vector3.new(0.7, 4, 0.7), Vector3.new(side * 1.6, -0.1, 0), skin)
    enemyPart("Leg", Vector3.new(0.7, 2.7, 0.8), Vector3.new(side * 0.6, -2, 0), darkSkin)
    local eye = enemyPart("Eye", Vector3.new(0.22, 0.2, 0.15), Vector3.new(side * 0.3, 3.15, -0.82), Color3.fromRGB(255, 20, 20), Enum.Material.Neon)
    local glow = Instance.new("PointLight")
    glow.Brightness = 0.6
    glow.Range = 5
    glow.Color = eye.Color
    glow.Parent = eye
end

local function positionEnemy()
    if enemyStage.Value == 0 then
        enemy.CFrame = CFrame.lookAt(Vector3.new(0, 4, -65), Vector3.new(0, 4, 9))
        return
    end
    local x = enemySide.Value == "LEFT" and -18 or 18
    local z = ({-45, -30, -19})[enemyStage.Value] or -45
    if enemyStage.Value == 3 then
        x = enemySide.Value == "LEFT" and -11 or 11
    end
    enemy.CFrame = CFrame.lookAt(Vector3.new(x, 4, z), Vector3.new(0, 4, 9))
end

Lighting.ClockTime = 1
Lighting.Brightness = 0.8
Lighting.FogEnd = 95
Lighting.FogColor = Color3.fromRGB(28, 35, 30)
local light = Instance.new("PointLight")
light.Range = 22
light.Brightness = 1.5
light.Color = Color3.fromRGB(203, 226, 191)
light.Parent = block("OfficeLamp", Vector3.new(0, 11, 0), Vector3.new(2, 0.4, 2), Color3.fromRGB(206, 230, 188), Enum.Material.Neon)

local owner = nil
local startedAt = 0
local lastTick = os.clock()
local enemyTimer = 0
local actionTimes = {}

local function seatInOffice(player, character)
    local root = character:WaitForChild("HumanoidRootPart", 10)
    if not root then return end
    root.CFrame = CFrame.lookAt(Vector3.new(0, 4, 9), Vector3.new(0, 4, -16))
    root.Anchored = true
end

local function startNight(player)
    if status.Value == "RUNNING" then return end
    if owner and owner.Parent == Players and owner ~= player then return end
    owner = player
    status.Value = "RUNNING"
    hour.Value = 0
    energy.Value = 100
    leftDoorClosed.Value = false
    rightDoorClosed.Value = false
    cameraIndex.Value = 0
    enemyStage.Value = 0
    enemySide.Value = "LEFT"
    message.Value = "00:00. Электричество ограничено. Следи за коридорами."
    startedAt = os.clock()
    lastTick = startedAt
    enemyTimer = 0
    light.Enabled = true
    ambience:Stop()
    ambience:Play()
    positionEnemy()
    if player.Character then seatInOffice(player, player.Character) end
end

local function finishNight(result, reason)
    if status.Value ~= "RUNNING" then return end
    status.Value = result
    cameraIndex.Value = 0
    message.Value = reason
    ambience:Stop()
    playCue(result == "WIN" and "Win" or "Lose", 2)
end

local validActions = {
    StartNight = true, LeftDoor = true, RightDoor = true,
    Camera1 = true, Camera2 = true, Camera3 = true, CloseCamera = true
}
action.OnServerEvent:Connect(function(player, command, ...)
    if select("#", ...) ~= 0 then return end
    if typeof(command) ~= "string" or not validActions[command] then return end
    local now = os.clock()
    if now - (actionTimes[player] or 0) < 0.12 then return end
    actionTimes[player] = now
    if command == "StartNight" then
        startNight(player)
        return
    end
    if player ~= owner or status.Value ~= "RUNNING" or energy.Value <= 0 then return end
    if command == "LeftDoor" then
        leftDoorClosed.Value = not leftDoorClosed.Value
    elseif command == "RightDoor" then
        rightDoorClosed.Value = not rightDoorClosed.Value
    elseif command == "CloseCamera" then
        cameraIndex.Value = 0
    else
        cameraIndex.Value = tonumber(command:sub(-1)) or 0
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        seatInOffice(player, character)
    end)
    if player.Character then task.spawn(seatInOffice, player, player.Character) end
end)
for _, player in ipairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function(character) seatInOffice(player, character) end)
    if player.Character then task.spawn(seatInOffice, player, player.Character) end
end
Players.PlayerRemoving:Connect(function(player)
    actionTimes[player] = nil
    if owner == player then
        owner = nil
        status.Value = "READY"
        cameraIndex.Value = 0
        message.Value = "Нажми «Начать ночь»."
    end
end)

while true do
    task.wait(0.2)
    local now = os.clock()
    local dt = math.clamp(now - lastTick, 0, 1)
    lastTick = now
    if status.Value == "RUNNING" then
        local elapsed = now - startedAt
        hour.Value = math.min(6, math.floor(elapsed / HOUR_SECONDS))
        if elapsed >= 6 * HOUR_SECONDS then
            hour.Value = 6
            finishNight("WIN", "06:00. Рассвет! Ты пережил первую ночь.")
        else
            local drain = 0.045
            if leftDoorClosed.Value then drain += 0.19 end
            if rightDoorClosed.Value then drain += 0.19 end
            if cameraIndex.Value > 0 then drain += 0.10 end
            energy.Value = math.max(0, energy.Value - drain * dt)
            light.Enabled = energy.Value > 0
            light.Color = enemyStage.Value == 2 and Color3.fromRGB(255, 110, 80) or Color3.fromRGB(203, 226, 191)
            if energy.Value <= 0 then
                leftDoorClosed.Value = false
                rightDoorClosed.Value = false
                cameraIndex.Value = 0
                message.Value = "Энергия закончилась! Обе двери открыты."
            end

            enemyTimer += dt
            if enemyTimer >= ENEMY_STEP_SECONDS then
                enemyTimer -= ENEMY_STEP_SECONDS
                if enemyStage.Value == 0 then
                    enemySide.Value = rng:NextInteger(1, 2) == 1 and "LEFT" or "RIGHT"
                end
                enemyStage.Value += 1
                positionEnemy()
                if enemyStage.Value == 2 then
                    message.Value = "Шорох в коридорах. Проверь камеры и закрой нужную дверь."
                    playCue("Alarm", 1.6)
                elseif enemyStage.Value >= 3 then
                    local blocked
                    if enemySide.Value == "LEFT" then
                        blocked = leftDoorClosed.Value
                    else
                        blocked = rightDoorClosed.Value
                    end
                    if blocked then
                        message.Value = "Удар по закрытой двери! Subject 06 отступил."
                        enemyStage.Value = 0
                        positionEnemy()
                    else
                        finishNight("LOSE", "Subject 06 проник через открытую дверь.")
                    end
                end
            end
        end
    end
end
