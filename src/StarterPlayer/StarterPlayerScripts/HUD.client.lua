-- Expedition HUD: readable on desktop, gamepad and touch; gameplay remains server-authoritative.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local state = ReplicatedStorage:WaitForChild("GameState")
local remotes = ReplicatedStorage:WaitForChild("CRN_Remotes")
local actionRemote = remotes:WaitForChild("Action")
local noticeRemote = remotes:WaitForChild("Notice")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local status = state:WaitForChild("Status")
local stage = state:WaitForChild("Stage")
local objective = state:WaitForChild("Objective")
local relayCount = state:WaitForChild("RelayCount")
local runSeconds = state:WaitForChild("RunSeconds")

local old = playerGui:FindFirstChild("CRN_ExpeditionHUD")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "CRN_ExpeditionHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 20
gui.Parent = playerGui

local function corner(parent, radius)
    local item = Instance.new("UICorner")
    item.CornerRadius = UDim.new(0, radius or 8)
    item.Parent = parent
end

local function stroke(parent, color, thickness)
    local item = Instance.new("UIStroke")
    item.Color = color or Color3.fromRGB(92, 128, 108)
    item.Thickness = thickness or 1
    item.Parent = parent
end

local function label(parent, name, text, size, position, textSize, color, font)
    local item = Instance.new("TextLabel")
    item.Name = name
    item.Size = size
    item.Position = position
    item.BackgroundTransparency = 1
    item.Text = text
    item.TextColor3 = color or Color3.fromRGB(206, 218, 205)
    item.TextSize = textSize or 15
    item.Font = font or Enum.Font.Gotham
    item.TextWrapped = true
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.TextYAlignment = Enum.TextYAlignment.Center
    item.Parent = parent
    return item
end

local function button(parent, name, text, size, position)
    local item = Instance.new("TextButton")
    item.Name = name
    item.Size = size
    item.Position = position
    item.BackgroundColor3 = Color3.fromRGB(34, 49, 44)
    item.BorderSizePixel = 0
    item.Text = text
    item.TextColor3 = Color3.fromRGB(218, 231, 214)
    item.TextSize = 15
    item.Font = Enum.Font.GothamSemibold
    item.AutoButtonColor = true
    item.Parent = parent
    corner(item, 7)
    stroke(item, Color3.fromRGB(91, 128, 106), 1)
    return item
end

local scale = Instance.new("UIScale")
scale.Parent = gui
local function fitScale()
    local camera = Workspace.CurrentCamera
    if camera then
        local width = camera.ViewportSize.X
        scale.Scale = math.clamp(width / 1050, 0.72, 1)
    end
end
fitScale()
if Workspace.CurrentCamera then
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitScale)
end

local top = Instance.new("Frame")
top.Name = "StatusPanel"
top.AnchorPoint = Vector2.new(0, 0)
top.Position = UDim2.fromOffset(12, 8)
top.Size = UDim2.fromOffset(390, 138)
top.BackgroundColor3 = Color3.fromRGB(9, 16, 16)
top.BackgroundTransparency = 0.16
top.BorderSizePixel = 0
top.Parent = gui
corner(top, 10)
stroke(top, Color3.fromRGB(83, 122, 101), 1)

local titleLabel = label(top, "Title", "УБЕЖИЩЕ 04", UDim2.new(1, -28, 0, 18), UDim2.fromOffset(14, 5), 14, Color3.fromRGB(139, 207, 158), Enum.Font.Code)
local statusLabel = label(top, "RunStatus", "ПОДГОТОВКА", UDim2.new(1, -28, 0, 18), UDim2.fromOffset(14, 25), 12, Color3.fromRGB(226, 180, 90), Enum.Font.GothamBold)
local objectiveLabel = label(top, "Objective", "Подготовься у терминала.", UDim2.new(1, -28, 0, 32), UDim2.fromOffset(14, 45), 13, Color3.fromRGB(225, 228, 213))
local zoneLabel = label(top, "Zone", "ЗОНА: УБЕЖИЩЕ  |  РЕТРАНСЛЯТОРЫ 0/3", UDim2.new(1, -28, 0, 16), UDim2.fromOffset(14, 80), 11, Color3.fromRGB(143, 183, 161), Enum.Font.Code)
local resourcesLabel = label(top, "Resources", "ЗДОРОВЬЕ 100  •  RAD 0  •  ЖИЗНИ 3", UDim2.new(1, -28, 0, 16), UDim2.fromOffset(14, 97), 11, Color3.fromRGB(212, 217, 198), Enum.Font.Code)
local suppliesLabel = label(top, "Inventory", "ФИЛЬТР 100с +1  •  АПТЕЧКИ 1  •  ФОНАРЬ 100%", UDim2.new(1, -28, 0, 16), UDim2.fromOffset(14, 115), 10, Color3.fromRGB(168, 193, 173), Enum.Font.Code)

local actionBar = Instance.new("Frame")
actionBar.Name = "TouchActions"
actionBar.AnchorPoint = Vector2.new(1, 1)
actionBar.Position = UDim2.new(1, -12, 1, -155)
actionBar.Size = UDim2.fromOffset(264, 124)
actionBar.BackgroundTransparency = 1
actionBar.Parent = gui
local medkitButton = button(actionBar, "Medkit", "H  Аптечка", UDim2.fromOffset(128, 44), UDim2.fromOffset(0, 0))
local filterButton = button(actionBar, "Filter", "F  Фильтр", UDim2.fromOffset(128, 44), UDim2.fromOffset(136, 0))
local lampButton = button(actionBar, "Lamp", "L  Фонарь", UDim2.fromOffset(128, 44), UDim2.fromOffset(0, 50))
local pauseButton = button(actionBar, "Pause", "⏸  Пауза", UDim2.fromOffset(128, 44), UDim2.fromOffset(136, 50))

local cameraButton = button(top, "Camera", "C  Разведка", UDim2.fromOffset(126, 30), UDim2.new(1, -10, 0, 6))
cameraButton.AnchorPoint = Vector2.new(1, 0)
cameraButton.TextSize = 13

local toast = Instance.new("TextLabel")
toast.Name = "Alert"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 200)
toast.Size = UDim2.new(0.8, 0, 0, 46)
toast.BackgroundColor3 = Color3.fromRGB(21, 24, 20)
toast.BackgroundTransparency = 0.08
toast.BorderSizePixel = 0
toast.Text = ""
toast.TextColor3 = Color3.fromRGB(239, 194, 110)
toast.TextSize = 16
toast.Font = Enum.Font.GothamSemibold
toast.TextWrapped = true
toast.Visible = false
toast.Parent = gui
corner(toast, 8)
stroke(toast, Color3.fromRGB(135, 103, 59), 1)

local function overlay(name, titleText, bodyText)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.Size = UDim2.fromOffset(460, 330)
    frame.BackgroundColor3 = Color3.fromRGB(8, 14, 15)
    frame.BackgroundTransparency = 0.04
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = gui
    corner(frame, 12)
    stroke(frame, Color3.fromRGB(104, 139, 112), 1)
    label(frame, "Heading", titleText, UDim2.new(1, -36, 0, 42), UDim2.fromOffset(18, 14), 24, Color3.fromRGB(176, 221, 176), Enum.Font.GothamBold)
    local body = label(frame, "Body", bodyText, UDim2.new(1, -36, 0, 177), UDim2.fromOffset(18, 62), 15, Color3.fromRGB(219, 225, 211))
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.TextXAlignment = Enum.TextXAlignment.Left
    return frame
end

local briefing = overlay("Briefing", "ВЫЛАЗКА «СЕВЕРНЫЙ СИГНАЛ»",
    "Сними три ретранслятора на станции, в тоннеле и на поверхности. Дойди до маяка и подай сигнал эвакуации.\n\nWASD / левый стик — движение   •   Space / A — прыжок\nE / X — взаимодействие   •   H / RB — аптечка\nF / Y — сменить фильтр   •   L / B — фонарь\nEsc / Start — личная пауза   •   C — камеры разведки в убежище\n\nПодойди к плану маршрута у шлюза и начни вылазку. В кооперативе пауза не останавливает время для команды.")
local startButton = button(briefing, "StartRun", "Начать вылазку", UDim2.new(1, -36, 0, 48), UDim2.new(0, 18, 1, -62))

local resultPanel = overlay("Result", "ВЫЛАЗКА ЗАВЕРШЕНА", "")
local resultBody = resultPanel:FindFirstChild("Body")
local restartButton = button(resultPanel, "RestartRun", "Подготовить новую попытку", UDim2.new(1, -36, 0, 48), UDim2.new(0, 18, 1, -62))
local pausePanel = overlay("PauseMenu", "ЛИЧНАЯ ПАУЗА", "Персонаж заморожен. В кооперативе остальная команда продолжает вылазку.")
local resumeButton = button(pausePanel, "Resume", "Продолжить", UDim2.new(1, -36, 0, 48), UDim2.new(0, 18, 1, -62))

local function applyTouchTargets()
    local camera = Workspace.CurrentCamera
    local viewportWidth = camera and camera.ViewportSize.X or 1050
    local mobile = UserInputService.TouchEnabled or viewportWidth < 900
    local uiScale = math.max(scale.Scale, 0.1)
    local buttonWidth = mobile and 132 or 112
    local buttonGap = 8
    local secondColumnX = buttonWidth + buttonGap
    local targetHeight = mobile and math.ceil(56 / uiScale) or 44
    for _, actionButton in ipairs({medkitButton, filterButton, lampButton, pauseButton}) do
        actionButton.Size = UDim2.fromOffset(buttonWidth, targetHeight)
        actionButton.TextSize = math.ceil((mobile and 13 or 14) / uiScale)
    end
    filterButton.Position = UDim2.fromOffset(secondColumnX, 0)
    lampButton.Position = UDim2.fromOffset(0, targetHeight + buttonGap)
    pauseButton.Position = UDim2.fromOffset(secondColumnX, targetHeight + buttonGap)
    actionBar.Size = UDim2.fromOffset(secondColumnX + buttonWidth, targetHeight * 2 + buttonGap)
    actionBar.Position = mobile
        and UDim2.new(1, -12, 1, -math.ceil(120 / uiScale))
        or UDim2.new(1, -12, 1, -155)

    cameraButton.Size = UDim2.fromOffset(126, targetHeight)
    titleLabel.Size = UDim2.new(1, -28, 0, 18)
    titleLabel.TextSize = math.ceil(14 / uiScale)
    statusLabel.Position = UDim2.fromOffset(14, 25)
    statusLabel.TextSize = math.ceil(12 / uiScale)
    objectiveLabel.Position = UDim2.fromOffset(14, 45)
    objectiveLabel.Size = UDim2.new(1, -28, 0, 32)
    objectiveLabel.TextSize = math.ceil(13 / uiScale)
    zoneLabel.Position = UDim2.fromOffset(14, 80)
    zoneLabel.Size = UDim2.new(1, -28, 0, 16)
    zoneLabel.TextSize = math.ceil(11 / uiScale)
    resourcesLabel.Position = UDim2.fromOffset(14, 97)
    resourcesLabel.Size = UDim2.new(1, -28, 0, 16)
    resourcesLabel.TextSize = math.ceil(11 / uiScale)
    suppliesLabel.Position = UDim2.fromOffset(14, 115)
    suppliesLabel.TextSize = math.ceil(10 / uiScale)
    suppliesLabel.Visible = not mobile
    top.Size = UDim2.fromOffset(390, mobile and 114 or 138)
    top.Position = mobile and UDim2.fromOffset(12, 78) or UDim2.fromOffset(12, 8)
    toast.Position = UDim2.new(0.5, 0, 0, math.ceil((mobile and 140 or 158) / uiScale))
    for _, overlayButton in ipairs({startButton, restartButton, resumeButton}) do
        overlayButton.Size = UDim2.new(1, -36, 0, mobile and math.ceil(56 / uiScale) or 48)
        overlayButton.TextSize = math.ceil((mobile and 15 or 15) / uiScale)
    end
end
applyTouchTargets()
if Workspace.CurrentCamera then
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyTouchTargets)
end

local mobileObjectives = {
    STATION = "Сними ретранслятор 1/3",
    TUNNEL = "Сними ретранслятор 2/3",
    SURFACE = "Сними ретранслятор 3/3",
    EXTRACTION = "Дойди до маяка эвакуации",
}

local function formatClock(seconds)
    local whole = math.max(0, math.floor(seconds))
    return string.format("%02d:%02d", math.floor(whole / 60), whole % 60)
end

local function currentHealth()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return 100, 100 end
    return humanoid.Health, humanoid.MaxHealth
end

local function updateStartAccess()
    if status.Value ~= "READY" then
        startButton.Active = false
        startButton.AutoButtonColor = false
        return
    end

    local map = Workspace:FindFirstChild("CRN_Expedition")
    local shelter = map and map:FindFirstChild("Shelter")
    local console = shelter and shelter:FindFirstChild("StartConsole")
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local canStart = root ~= nil and console ~= nil
        and (root.Position - console.Position).Magnitude <= 18

    startButton.Text = canStart and "Начать вылазку" or "Подойди к плану маршрута"
    startButton.Active = canStart
    startButton.AutoButtonColor = canStart
end

local function refresh()
    updateStartAccess()
    local currentStatus = status.Value
    titleLabel.Text = currentStatus == "READY" and "УБЕЖИЩЕ 04" or "ВЫЛАЗКА 01"
    local currentStage = stage.Value
    local playerZone = player:GetAttribute("Zone") or "Убежище"
    local health, maxHealth = currentHealth()
    local radiation = player:GetAttribute("Radiation") or 0
    local lives = player:GetAttribute("Lives") or Config.Player.StartingLives
    local filterSeconds = player:GetAttribute("FilterSeconds") or 0
    local filters = player:GetAttribute("FilterCartridges") or 0
    local medkits = player:GetAttribute("Medkits") or 0
    local battery = player:GetAttribute("Battery") or 0
    local lampOn = player:GetAttribute("LampOn") == true
    local relayTotal = relayCount.Value

    local camera = Workspace.CurrentCamera
    local mobile = UserInputService.TouchEnabled or (camera and camera.ViewportSize.X < 900)
    if currentStatus == "RUNNING" then
        local left = Config.RunTimeLimitSeconds - runSeconds.Value
        local stageName = Config.StageText[currentStage] or "ВЫЛАЗКА"
        if mobile then
            local shortStages = {STATION = "СТАНЦИЯ", TUNNEL = "ТОННЕЛЬ", SURFACE = "ПОВЕРХНОСТЬ", EXTRACTION = "ЭВАКУАЦИЯ"}
            stageName = shortStages[currentStage] or "ВЫЛАЗКА"
            statusLabel.Text = stageName .. "  •  " .. formatClock(left)
            zoneLabel.Text = string.format("РЕТРАНСЛЯТОРЫ %d/3  •  ФИЛЬТР %dс", relayTotal, math.floor(filterSeconds + 0.5))
            resourcesLabel.Text = string.format("HP %d  •  RAD %d  •  ЖИЗНИ %d", math.floor(health + 0.5), math.floor(radiation + 0.5), lives)
        else
            statusLabel.Text = string.upper(stageName) .. "   •   " .. formatClock(left)
            zoneLabel.Text = "ЗОНА: " .. string.upper(playerZone) .. "   |   РЕТРАНСЛЯТОРЫ " .. tostring(relayTotal) .. "/3"
            resourcesLabel.Text = string.format("ЗДОРОВЬЕ %d/%d  •  RAD %d  •  ЖИЗНИ %d",
                math.floor(health + 0.5), math.floor(maxHealth + 0.5), math.floor(radiation + 0.5), lives)
        end
        statusLabel.TextColor3 = Color3.fromRGB(182, 218, 169)
        objectiveLabel.Text = mobile and (mobileObjectives[currentStage] or objective.Value) or objective.Value
        briefing.Visible = false
        resultPanel.Visible = false
    elseif currentStatus == "WIN" or currentStatus == "LOSE" then
        statusLabel.Text = currentStatus == "WIN" and "ЭВАКУАЦИЯ УСПЕШНА" or "ВЫЛАЗКА СОРВАНА"
        statusLabel.TextColor3 = currentStatus == "WIN" and Color3.fromRGB(139, 226, 151) or Color3.fromRGB(238, 117, 91)
        objectiveLabel.Text = currentStatus == "WIN" and "Команда добралась до безопасного места." or "Вернись в убежище и подготовь новую попытку."
        zoneLabel.Text = "РЕТРАНСЛЯТОРЫ " .. tostring(relayTotal) .. "/3   |   ВРЕМЯ " .. formatClock(runSeconds.Value)
        briefing.Visible = false
        resultPanel.Visible = true
        if resultBody then
            resultBody.Text = currentStatus == "WIN"
                and "Сигнал принят. Выжившие могут осмотреться, затем подготовить новую попытку.\n\nИспользуй кнопку ниже, чтобы сбросить маршрут и вернуться в убежище."
                or "Команда потеряла возможность продолжать или не успела к эвакуации.\n\nСнаряжение, жизни и ретрансляторы сбросятся перед новой попыткой."
        end
    else
        statusLabel.Text = currentStatus == "READY" and "ГОТОВНОСТЬ   •   УБЕЖИЩЕ 04" or currentStatus
        statusLabel.TextColor3 = Color3.fromRGB(226, 180, 90)
        objectiveLabel.Text = objective.Value
        zoneLabel.Text = "ЗОНА: УБЕЖИЩЕ   |   МАРШРУТ: СТАНЦИЯ → ТОННЕЛЬ → ПОВЕРХНОСТЬ"
        briefing.Visible = true
        resultPanel.Visible = false
    end

    cameraButton.Visible = currentStatus == "READY" and not mobile
    if currentStatus ~= "RUNNING" or not mobile then
        resourcesLabel.Text = string.format("ЗДОРОВЬЕ %d/%d  •  RAD %d  •  ЖИЗНИ %d",
            math.floor(health + 0.5), math.floor(maxHealth + 0.5), math.floor(radiation + 0.5), lives)
    end
    suppliesLabel.Text = string.format("ФИЛЬТР %dс +%d  •  АПТЕЧКИ %d  •  ФОНАРЬ %d%% %s",
        math.floor(filterSeconds + 0.5), filters, medkits, math.floor(battery + 0.5), lampOn and "ВКЛ" or "ВЫКЛ")
    if mobile then
        medkitButton.Text = "МЕДКИТ ×" .. tostring(medkits)
        filterButton.Text = "ФИЛЬТР ×" .. tostring(filters)
        lampButton.Text = lampOn and ("ФОНАРЬ " .. tostring(math.floor(battery + 0.5)) .. "%") or "ФОНАРЬ ВЫКЛ"
        pauseButton.Text = player:GetAttribute("Paused") and "ПРОДОЛЖИТЬ" or "ПАУЗА"
    else
        medkitButton.Text = "H  Аптечка (" .. tostring(medkits) .. ")"
        filterButton.Text = "F  Фильтр (" .. tostring(filters) .. ")"
        lampButton.Text = lampOn and "L  Фонарь: ВКЛ" or "L  Фонарь: ВЫКЛ"
    end

    local paused = player:GetAttribute("Paused") == true
    pausePanel.Visible = paused
    if not mobile then pauseButton.Text = paused and "⏵  Продолжить" or "⏸  Пауза" end
    if player:GetAttribute("OutOfRun") == true then
        resourcesLabel.Text = resourcesLabel.Text .. "  •  ВЫБЫЛ"
    end
end

local toastSequence = 0
noticeRemote.OnClientEvent:Connect(function(message, kind)
    toastSequence += 1
    local current = toastSequence
    toast.Text = tostring(message)
    toast.Visible = true
    if kind == "WARN" or kind == "LOSE" then
        toast.TextColor3 = Color3.fromRGB(255, 151, 119)
    elseif kind == "WIN" then
        toast.TextColor3 = Color3.fromRGB(167, 230, 151)
    else
        toast.TextColor3 = Color3.fromRGB(239, 207, 135)
    end
    task.delay(3.8, function()
        if current == toastSequence then toast.Visible = false end
    end)
end)

local function sendAction(name)
    actionRemote:FireServer(name)
end
medkitButton.Activated:Connect(function() sendAction("UseMedkit") end)
filterButton.Activated:Connect(function() sendAction("UseFilter") end)
lampButton.Activated:Connect(function() sendAction("ToggleLamp") end)
startButton.Activated:Connect(function() sendAction("StartRun") end)
restartButton.Activated:Connect(function() sendAction("RestartRun") end)

local function togglePause()
    if player:GetAttribute("Paused") then
        sendAction("Resume")
    elseif status.Value == "RUNNING" then
        sendAction("Pause")
    end
end
pauseButton.Activated:Connect(togglePause)
resumeButton.Activated:Connect(function() sendAction("Resume") end)

local cameraMode = false
local cameraIndex = 0
local previousCameraType
local previousCameraSubject
local function cameraFolder()
    local map = Workspace:FindFirstChild("CRN_Expedition")
    local shelter = map and map:FindFirstChild("Shelter")
    return shelter and shelter:FindFirstChild("CameraAnchors")
end

local function closeCamera()
    cameraMode = false
    cameraIndex = 0
    local camera = Workspace.CurrentCamera
    if camera then
        camera.CameraType = previousCameraType or Enum.CameraType.Custom
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        camera.CameraSubject = humanoid or previousCameraSubject
    end
    cameraButton.Text = "C  Разведка"
end

local function cycleCamera()
    if status.Value ~= "READY" then
        if cameraMode then closeCamera() end
        return
    end
    local anchors = cameraFolder()
    if not anchors then return end
    if cameraMode and cameraIndex >= 3 then
        closeCamera()
        return
    end

    if not cameraMode then
        local console = anchors.Parent:FindFirstChild("StartConsole")
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not root or not console or (root.Position - console.Position).Magnitude > 70 then
            toast.Text = "Камеры доступны у плана маршрута в убежище."
            toast.Visible = true
            task.delay(2.5, function() toast.Visible = false end)
            return
        end
        local camera = Workspace.CurrentCamera
        if not camera then return end
        previousCameraType = camera.CameraType
        previousCameraSubject = camera.CameraSubject
        cameraMode = true
        cameraIndex = 0
    end

    cameraIndex += 1
    local anchor = anchors:FindFirstChild(string.format("CAM_%02d", cameraIndex))
    local camera = Workspace.CurrentCamera
    if anchor and camera then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = anchor.CFrame
        cameraButton.Text = "C  CAM " .. string.format("%02d", cameraIndex) .. " →"
        actionRemote:FireServer("Camera", cameraIndex)
    else
        closeCamera()
    end
end
cameraButton.Activated:Connect(cycleCamera)

ContextActionService:BindAction("CRN_Medkit", function(_, stateType)
    if stateType == Enum.UserInputState.Begin then sendAction("UseMedkit") end
    return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.H, Enum.KeyCode.ButtonR1)
ContextActionService:BindAction("CRN_Filter", function(_, stateType)
    if stateType == Enum.UserInputState.Begin then sendAction("UseFilter") end
    return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.F, Enum.KeyCode.ButtonY)
ContextActionService:BindAction("CRN_Lamp", function(_, stateType)
    if stateType == Enum.UserInputState.Begin then sendAction("ToggleLamp") end
    return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.L, Enum.KeyCode.ButtonB)
ContextActionService:BindAction("CRN_Pause", function(_, stateType)
    if stateType == Enum.UserInputState.Begin then togglePause() end
    return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.Escape, Enum.KeyCode.ButtonStart)
ContextActionService:BindAction("CRN_Camera", function(_, stateType)
    if stateType == Enum.UserInputState.Begin then cycleCamera() end
    return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.C)

for _, value in ipairs({status, stage, objective, relayCount, runSeconds}) do
    value.Changed:Connect(refresh)
end
for _, attribute in ipairs({"Zone", "Lives", "Radiation", "FilterSeconds", "FilterCartridges", "Medkits", "Battery", "LampOn", "Paused", "OutOfRun"}) do
    player:GetAttributeChangedSignal(attribute):Connect(refresh)
end
player.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if humanoid then humanoid.HealthChanged:Connect(refresh) end
    refresh()
end)
if player.Character then
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.HealthChanged:Connect(refresh) end
end

refresh()

local startAccessElapsed = 0
RunService.Heartbeat:Connect(function(dt)
    startAccessElapsed += dt
    if startAccessElapsed >= 0.2 then
        startAccessElapsed = 0
        updateStartAccess()
    end
end)
