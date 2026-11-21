-- Night 1 local interface and static bunker cameras.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local remoteFolder = ReplicatedStorage:WaitForChild("CRN_Night1")
local world = workspace:WaitForChild("CRN_Night1_World")
local anchors = world:WaitForChild("CameraAnchors")
local action = remoteFolder:WaitForChild("Action")
local status = remoteFolder:WaitForChild("Status")
local hour = remoteFolder:WaitForChild("Hour")
local energy = remoteFolder:WaitForChild("Energy")
local left = remoteFolder:WaitForChild("LeftDoorClosed")
local right = remoteFolder:WaitForChild("RightDoorClosed")
local cameraIndex = remoteFolder:WaitForChild("CameraIndex")
local enemySide = remoteFolder:WaitForChild("EnemySide")
local enemyStage = remoteFolder:WaitForChild("EnemyStage")
local message = remoteFolder:WaitForChild("Message")

local gui = Instance.new("ScreenGui")
gui.Name = "CRN_Night1_HUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function panel(name, size, position, anchor)
    local f = Instance.new("Frame")
    f.Name = name
    f.AnchorPoint = anchor
    f.Position = position
    f.Size = size
    f.BackgroundColor3 = Color3.fromRGB(12, 20, 19)
    f.BackgroundTransparency = 0.14
    f.BorderSizePixel = 0
    f.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = f
    return f
end
local info = panel("SecurityMonitor", UDim2.new(0.94, 0, 0, 144), UDim2.new(0.03, 0, 0.025, 0), Vector2.new(0, 0))
local cap = Instance.new("UISizeConstraint")
cap.MaxSize = Vector2.new(480, 144)
cap.Parent = info
local function label(parent, text, pos, size, fontSize, color)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = true
    l.Font = Enum.Font.GothamBold
    l.TextSize = fontSize
    l.TextColor3 = color or Color3.fromRGB(217, 231, 221)
    l.Size = size
    l.Position = pos
    l.Text = text
    l.Parent = parent
    return l
end
local title = label(info, "CHERNOBYL / NIGHT 1", UDim2.fromOffset(12, 9), UDim2.new(1, -20, 0, 25), 19)
local clock = label(info, "00:00 • Энергия 100%", UDim2.fromOffset(12, 38), UDim2.new(1, -20, 0, 23), 17)
local threat = label(info, "SUBJECT 06: неизвестно", UDim2.fromOffset(12, 65), UDim2.new(1, -20, 0, 22), 15, Color3.fromRGB(255, 161, 133))
local notice = label(info, "", UDim2.fromOffset(12, 89), UDim2.new(1, -24, 0, 49), 13)

local controls = panel("Controls", UDim2.new(0.94, 0, 0, 159), UDim2.new(0.03, 0, 0.975, 0), Vector2.new(0, 1))
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(480, 159)
limit.Parent = controls
local layout = Instance.new("UIGridLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.CellSize = UDim2.new(0.315, 0, 0, 46)
layout.CellPadding = UDim2.new(0.013, 0, 0, 5)
layout.Parent = controls

local function button(text, command, order)
    local b = Instance.new("TextButton")
    b.Name = command
    b.Text = text
    b.LayoutOrder = order
    b.TextScaled = true
    b.TextWrapped = true
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = Color3.fromRGB(234, 242, 231)
    b.BackgroundColor3 = Color3.fromRGB(44, 61, 54)
    b.BorderSizePixel = 0
    b.Parent = controls
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = b
    b.Activated:Connect(function() action:FireServer(command) end)
    return b
end
local leftButton = button("Левая дверь", "LeftDoor", 1)
local rightButton = button("Правая дверь", "RightDoor", 2)
local startButton = button("Начать ночь", "StartNight", 3)
button("Камера 1 / Л", "Camera1", 4)
button("Камера 2 / П", "Camera2", 5)
button("Камера 3 / Офис", "Camera3", 6)
button("Закрыть камеры", "CloseCamera", 7)

local function refresh()
    local result = status.Value
    clock.Text = string.format("%02d:00  •  Энергия: %d%%", hour.Value, math.floor(energy.Value + 0.5))
    leftButton.Text = left.Value and "ЛЕВАЯ: ЗАКРЫТА" or "ЛЕВАЯ: ОТКРЫТА"
    rightButton.Text = right.Value and "ПРАВАЯ: ЗАКРЫТА" or "ПРАВАЯ: ОТКРЫТА"
    startButton.Text = result == "READY" and "НАЧАТЬ НОЧЬ" or (result == "RUNNING" and "ИДЁТ НОЧЬ" or "ЗАНОВО")
    startButton.BackgroundColor3 = result == "RUNNING" and Color3.fromRGB(62, 69, 65) or Color3.fromRGB(36, 110, 75)
    if cameraIndex.Value == 0 then
        threat.Text = "КАМЕРЫ ОТКЛЮЧЕНЫ — проверь коридоры"
    elseif cameraIndex.Value == 3 then
        threat.Text = "КАМЕРА 3: офис под наблюдением"
    else
        local selectedSide = cameraIndex.Value == 1 and "LEFT" or "RIGHT"
        if enemyStage.Value > 0 and enemySide.Value == selectedSide then
            threat.Text = "SUBJECT 06: ОБНАРУЖЕН • этап " .. enemyStage.Value .. "/3"
        else
            threat.Text = "КАМЕРА " .. cameraIndex.Value .. ": цель не обнаружена"
        end
    end
    notice.Text = message.Value
    if result == "WIN" then
        title.Text = "06:00 — ПОБЕДА"
    elseif result == "LOSE" then
        title.Text = "НОЧЬ ПРОИГРАНА"
    else
        title.Text = "CHERNOBYL / NIGHT 1" .. (cameraIndex.Value > 0 and (" • CAM " .. cameraIndex.Value) or "")
    end
end

for _, item in ipairs({status, hour, energy, left, right, cameraIndex, enemySide, enemyStage, message}) do
    item.Changed:Connect(refresh)
end
refresh()

local cameraWasActive = false
RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    if not cam then return end
    if status.Value == "RUNNING" and cameraIndex.Value > 0 then
        local anchor = anchors:FindFirstChild("Camera" .. cameraIndex.Value)
        if anchor then
            cam.CameraType = Enum.CameraType.Scriptable
            cam.CFrame = anchor.CFrame
            cameraWasActive = true
        end
    elseif cameraWasActive then
        cam.CameraType = Enum.CameraType.Custom
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then cam.CameraSubject = humanoid end
        cameraWasActive = false
    end
end)

local keyActions = {
    [Enum.KeyCode.Q] = "LeftDoor",
    [Enum.KeyCode.E] = "RightDoor",
    [Enum.KeyCode.One] = "Camera1",
    [Enum.KeyCode.Two] = "Camera2",
    [Enum.KeyCode.Three] = "Camera3",
    [Enum.KeyCode.C] = "CloseCamera",
    [Enum.KeyCode.N] = "StartNight",
}
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local command = keyActions[input.KeyCode]
    if command then action:FireServer(command) end
end)
