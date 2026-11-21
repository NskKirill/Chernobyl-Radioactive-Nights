-- Night 1 UI. All gameplay decisions stay on the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local guiParent = player:WaitForChild("PlayerGui")
local state = ReplicatedStorage:WaitForChild("CRN_Night1State")
local remote = ReplicatedStorage:WaitForChild("CRN_Night1Action")
local cameraFolder = Workspace:WaitForChild("CRN_Night1"):WaitForChild("Cameras")

local status = state:WaitForChild("Status")
local hour = state:WaitForChild("Hour")
local power = state:WaitForChild("Power")
local leftDoor = state:WaitForChild("LeftDoor")
local rightDoor = state:WaitForChild("RightDoor")
local notice = state:WaitForChild("Notice")

local gui = Instance.new("ScreenGui")
gui.Name = "CRN_Night1HUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 15
gui.Parent = guiParent

local function style(obj, bg)
    obj.BackgroundColor3 = bg
    obj.BorderSizePixel = 0
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = obj
    return obj
end

local function label(parent, name, text, size, position, textSize)
    local item = Instance.new("TextLabel")
    item.Name = name
    item.Size = size
    item.Position = position
    item.BackgroundTransparency = 1
    item.Text = text
    item.TextColor3 = Color3.fromRGB(215, 228, 210)
    item.TextSize = textSize
    item.Font = Enum.Font.GothamBold
    item.TextWrapped = true
    item.Parent = parent
    return item
end

local function button(parent, name, text, size, position)
    local item = Instance.new("TextButton")
    item.Name = name
    item.Size = size
    item.Position = position
    item.Text = text
    item.TextSize = 15
    item.TextWrapped = true
    item.Font = Enum.Font.GothamBold
    item.TextColor3 = Color3.new(1, 1, 1)
    item.AutoButtonColor = true
    style(item, Color3.fromRGB(49, 65, 69))
    item.Parent = parent
    return item
end

local bar = Instance.new("Frame")
bar.Name = "StatusBar"
bar.Size = UDim2.new(0.96, 0, 0, 70)
bar.Position = UDim2.new(0.02, 0, 0.02, 0)
style(bar, Color3.fromRGB(20, 30, 32))
bar.Parent = gui
local title = label(bar, "Title", "CHERNOBYL / NIGHT 1", UDim2.new(0.43, 0, 0.42, 0), UDim2.new(0.02, 0, 0.08, 0), 19)
title.TextXAlignment = Enum.TextXAlignment.Left
local clock = label(bar, "Clock", "00:00", UDim2.new(0.22, 0, 0.45, 0), UDim2.new(0.46, 0, 0.07, 0), 23)
local battery = label(bar, "Battery", "POWER 100%", UDim2.new(0.29, 0, 0.45, 0), UDim2.new(0.69, 0, 0.07, 0), 17)
local info = label(bar, "Notice", "", UDim2.new(0.96, 0, 0.48, 0), UDim2.new(0.02, 0, 0.50, 0), 13)
info.TextXAlignment = Enum.TextXAlignment.Left

local controls = Instance.new("Frame")
controls.Name = "Controls"
controls.BackgroundTransparency = 1
controls.Size = UDim2.new(0.96, 0, 0, 58)
controls.Position = UDim2.new(0.02, 0, 1, -68)
controls.Parent = gui
local start = button(controls, "StartNight", "НАЧАТЬ НОЧЬ", UDim2.new(0.22, -5, 1, 0), UDim2.fromScale(0, 0))
local left = button(controls, "LeftDoor", "ЛЕВАЯ: ОТКРЫТА", UDim2.new(0.25, -5, 1, 0), UDim2.fromScale(0.23, 0))
local right = button(controls, "RightDoor", "ПРАВАЯ: ОТКРЫТА", UDim2.new(0.25, -5, 1, 0), UDim2.fromScale(0.49, 0))
local cameras = button(controls, "Cameras", "КАМЕРЫ", UDim2.new(0.23, -2, 1, 0), UDim2.fromScale(0.76, 0))

local cameraMenu = Instance.new("Frame")
cameraMenu.Name = "CameraMenu"
cameraMenu.Size = UDim2.new(0, 260, 0, 250)
cameraMenu.Position = UDim2.new(1, -278, 0, 105)
style(cameraMenu, Color3.fromRGB(19, 29, 31))
cameraMenu.Visible = false
cameraMenu.Parent = gui
label(cameraMenu, "Heading", "СИСТЕМА НАБЛЮДЕНИЯ", UDim2.new(1, -14, 0, 35), UDim2.new(0, 7, 0, 6), 14)
local camButtons = {}
for index = 1, 4 do
    local cam = button(cameraMenu, "Cam" .. index, "CAM " .. string.format("%02d", index), UDim2.new(0.9, 0, 0, 38), UDim2.new(0.05, 0, 0, 41 + (index - 1) * 44))
    camButtons[index] = cam
end
local closeCam = button(cameraMenu, "Close", "ЗАКРЫТЬ МОНИТОР", UDim2.new(0.9, 0, 0, 27), UDim2.new(0.05, 0, 1, -34))

local cameraActive = false
local currentCameraIndex = 1

local function restoreView()
    cameraActive = false
    cameraMenu.Visible = false
    remote:FireServer("CameraState", false)
    local camera = Workspace.CurrentCamera
    if camera then
        camera.CameraType = Enum.CameraType.Custom
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then camera.CameraSubject = humanoid end
    end
end

local function selectCamera(index)
    local anchor = cameraFolder:FindFirstChild("CAM_" .. string.format("%02d", index))
    if not anchor then return end
    currentCameraIndex = index
    cameraActive = true
    cameraMenu.Visible = true
    local camera = Workspace.CurrentCamera
    if camera then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = anchor.CFrame
    end
end

local function toggleCamera()
    if status.Value ~= "RUNNING" then return end
    if cameraActive then
        restoreView()
    else
        cameraActive = true
        cameraMenu.Visible = true
        remote:FireServer("CameraState", true)
        selectCamera(currentCameraIndex)
    end
end

local function refresh()
    local currentStatus = status.Value
    clock.Text = (currentStatus == "WIN" and "06:00" or string.format("%02d:00", hour.Value))
    battery.Text = string.format("POWER %d%%", math.ceil(power.Value))
    battery.TextColor3 = power.Value < 25 and Color3.fromRGB(248, 116, 94) or Color3.fromRGB(215, 228, 210)
    left.Text = leftDoor.Value and "ЛЕВАЯ: ЗАКРЫТА" or "ЛЕВАЯ: ОТКРЫТА"
    right.Text = rightDoor.Value and "ПРАВАЯ: ЗАКРЫТА" or "ПРАВАЯ: ОТКРЫТА"
    left.BackgroundColor3 = leftDoor.Value and Color3.fromRGB(125, 52, 42) or Color3.fromRGB(49, 65, 69)
    right.BackgroundColor3 = rightDoor.Value and Color3.fromRGB(125, 52, 42) or Color3.fromRGB(49, 65, 69)
    info.Text = notice.Value
    if currentStatus == "READY" then
        start.Text = "НАЧАТЬ НОЧЬ"
        start.Visible = true
    elseif currentStatus == "RUNNING" then
        start.Visible = false
    else
        start.Text = "ПОВТОРИТЬ"
        start.Visible = true
    end
    left.Visible = currentStatus == "RUNNING"
    right.Visible = currentStatus == "RUNNING"
    cameras.Visible = currentStatus == "RUNNING"
    if currentStatus ~= "RUNNING" and cameraActive then restoreView() end
end

start.Activated:Connect(function()
    if status.Value == "READY" then remote:FireServer("StartNight")
    elseif status.Value == "WIN" or status.Value == "LOSE" then remote:FireServer("RestartNight") end
end)
left.Activated:Connect(function() remote:FireServer("ToggleDoor", "Left") end)
right.Activated:Connect(function() remote:FireServer("ToggleDoor", "Right") end)
cameras.Activated:Connect(toggleCamera)
closeCam.Activated:Connect(restoreView)
for index, cam in ipairs(camButtons) do
    cam.Activated:Connect(function() selectCamera(index) end)
end
for _, source in ipairs({status, hour, power, leftDoor, rightDoor, notice}) do
    source.Changed:Connect(refresh)
end
player.CharacterAdded:Connect(function()
    if cameraActive then
        task.wait(0.15)
        selectCamera(currentCameraIndex)
    end
end)
refresh()
