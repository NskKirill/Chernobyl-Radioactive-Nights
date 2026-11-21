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
gui.IgnoreGuiInset = false
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
cap.MaxSize = Vector2.new(480, 210)
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
title.Name = "Title"
clock.Name = "Clock"
threat.Name = "Threat"
notice.Name = "Notice"
notice.TextYAlignment = Enum.TextYAlignment.Top

local controls = panel("Controls", UDim2.new(0.94, 0, 0, 86), UDim2.new(0.03, 0, 0.975, 0), Vector2.new(0, 1))
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(420, 86)
limit.Parent = controls

local function controlRow(name, y, columns)
    local row = Instance.new("Frame")
    row.Name = name
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, -16, 0, 32)
    row.Position = UDim2.fromOffset(8, y)
    row.Parent = controls
    local layout = Instance.new("UIGridLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.FillDirectionMaxCells = columns
    -- Leave one pixel per cell for layout rounding at fractional viewport scales.
    layout.CellSize = UDim2.new(1 / columns, -6 * (columns - 1) / columns - 1, 0, 32)
    layout.CellPadding = UDim2.fromOffset(6, 0)
    layout.Parent = row
    return row
end
local doors = controlRow("Doors", 8, 2)
local cameras = controlRow("Cameras", 46, 4)

local function button(parent, text, command, order)
    local b = Instance.new("TextButton")
    b.Name = command
    b.Text = text
    b.LayoutOrder = order
    b.TextSize = 14
    b.TextScaled = false
    b.TextWrapped = false
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = Color3.fromRGB(234, 242, 231)
    b.BackgroundColor3 = Color3.fromRGB(44, 61, 54)
    b.BorderSizePixel = 0
    b.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = b
    b.Activated:Connect(function() action:FireServer(command) end)
    return b
end
local leftButton = button(doors, "Левая дверь", "LeftDoor", 1)
local rightButton = button(doors, "Правая дверь", "RightDoor", 2)
local startButton = button(controls, "N · Начать ночь", "StartNight", 1)
startButton.Position = UDim2.fromOffset(8, 8)
startButton.Size = UDim2.new(1, -16, 0, 32)
local cameraButtons = {
    button(cameras, "1 · Левый", "Camera1", 1),
    button(cameras, "2 · Правый", "Camera2", 2),
    button(cameras, "3 · Обзор", "Camera3", 3),
}
local closeCameraButton = button(cameras, "C · В офис", "CloseCamera", 4)

local function refresh()
    local result = status.Value
    clock.Text = string.format("%02d:00  •  Энергия: %d%%", hour.Value, math.floor(energy.Value + 0.5))
    local running = result == "RUNNING"
    doors.Visible = running
    cameras.Visible = running
    startButton.Visible = not running
    controls.Size = UDim2.new(0.94, 0, 0, running and 86 or 48)
    limit.MaxSize = running and Vector2.new(420, 86) or Vector2.new(240, 48)
    leftButton.Text = "Q · Левая: " .. (left.Value and "закрыта" or "открыта")
    rightButton.Text = "E · Правая: " .. (right.Value and "закрыта" or "открыта")
    startButton.Text = result == "READY" and "N · Начать ночь" or "N · Повторить"
    startButton.BackgroundColor3 = Color3.fromRGB(36, 110, 75)
    local idleColor = Color3.fromRGB(44, 61, 54)
    local selectedColor = Color3.fromRGB(36, 110, 75)
    for index, cameraButton in ipairs(cameraButtons) do
        cameraButton.BackgroundColor3 = cameraIndex.Value == index and selectedColor or idleColor
    end
    closeCameraButton.BackgroundColor3 = cameraIndex.Value == 0 and selectedColor or idleColor
    if result == "READY" then
        threat.Text = "ЦЕЛЬ: ДОЖИВИ ДО 06:00"
    elseif result == "WIN" then
        threat.Text = "СМЕНА ОКОНЧЕНА"
    elseif result == "LOSE" then
        threat.Text = "N — НОВАЯ ПОПЫТКА"
    elseif cameraIndex.Value == 0 then
        threat.Text = "1 / 2 — ПРОВЕРЬ КОРИДОРЫ"
    elseif cameraIndex.Value == 3 then
        threat.Text = "КАМЕРА 3: офис под наблюдением"
    else
        local selectedSide = cameraIndex.Value == 1 and "LEFT" or "RIGHT"
        if enemyStage.Value > 0 and enemySide.Value == selectedSide then
            local sideName = selectedSide == "LEFT" and "СЛЕВА" or "СПРАВА"
            if enemyStage.Value >= 2 then
                local doorKey = selectedSide == "LEFT" and "Q" or "E"
                threat.Text = "ОБНАРУЖЕН " .. sideName .. " — ЗАКРОЙ " .. doorKey
            else
                threat.Text = "ДВИЖЕНИЕ " .. sideName .. " — ЖДИ ШОРОХА"
            end
        else
            threat.Text = "КАМЕРА " .. cameraIndex.Value .. ": цель не обнаружена"
        end
    end
    notice.Text = message.Value
    if result == "READY" then
        info.Size = UDim2.new(0.94, 0, 0, 210)
        notice.Size = UDim2.new(1, -24, 0, 114)
        notice.Text = "Ночь длится 6 минут.\nПосле шороха: 1 / 2 — найди сторону угрозы.\nQ / E — закрой нужную дверь; C — убери камеры.\nПосле удара открой дверь: энергия ограничена.\nN или кнопка ниже — начать."
    else
        info.Size = UDim2.new(0.94, 0, 0, 144)
        notice.Size = UDim2.new(1, -24, 0, 49)
    end
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

RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local anchorName = status.Value == "RUNNING" and cameraIndex.Value > 0
        and ("Camera" .. cameraIndex.Value) or "OfficeView"
    local anchor = anchors:FindFirstChild(anchorName)
    if anchor then
        cam.CameraType = Enum.CameraType.Scriptable
        cam.CFrame = anchor.CFrame
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
