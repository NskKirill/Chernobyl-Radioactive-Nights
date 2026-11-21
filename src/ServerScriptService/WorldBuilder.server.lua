-- Deterministic, asset-free greybox for the first playable security-room night.
local Workspace = game:GetService("Workspace")
local existing = Workspace:FindFirstChild("CRN_Night1")
if existing then existing:Destroy() end
local map = Instance.new("Folder")
map.Name = "CRN_Night1"
map.Parent = Workspace

local function part(parent, name, position, size, color, material, collide)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = CFrame.new(position)
    p.Anchored = true
    p.Color = color
    p.Material = material or Enum.Material.Concrete
    p.CanCollide = collide ~= false
    p.Parent = parent
    return p
end

local concrete = Color3.fromRGB(55, 64, 64)
local metal = Color3.fromRGB(78, 89, 92)
local lights = Color3.fromRGB(180, 215, 194)
local office = Instance.new("Folder")
office.Name = "Office"
office.Parent = map
part(office, "Floor", Vector3.new(0, -0.8, 0), Vector3.new(33, 1.4, 24), concrete)
part(office, "Ceiling", Vector3.new(0, 12, 0), Vector3.new(33, 1, 24), concrete)
part(office, "BackWall", Vector3.new(0, 5.5, 11.5), Vector3.new(33, 12, 1), concrete)
part(office, "FrontWall", Vector3.new(0, 5.5, -11.5), Vector3.new(33, 12, 1), concrete)
for _, side in ipairs({-1, 1}) do
    local x = side * 16
    part(office, (side < 0 and "Left" or "Right") .. "SideTop", Vector3.new(x, 9, 0), Vector3.new(1, 6, 24), metal)
    part(office, (side < 0 and "Left" or "Right") .. "SideFront", Vector3.new(x, 3, -8.5), Vector3.new(1, 6, 6), metal)
    part(office, (side < 0 and "Left" or "Right") .. "SideBack", Vector3.new(x, 3, 8.5), Vector3.new(1, 6, 6), metal)
end
part(office, "SecurityDesk", Vector3.new(0, 1.3, -3), Vector3.new(12, 2.6, 3.4), metal)
local panel = part(office, "SecurityPanel", Vector3.new(0, 3, -4), Vector3.new(8, 1, 0.4), lights, Enum.Material.Neon)
panel.CanCollide = false
local ceilingLight = part(office, "OverheadLight", Vector3.new(0, 11.2, 0), Vector3.new(8, 0.2, 2), lights, Enum.Material.Neon, false)
local pointLight = Instance.new("PointLight")
pointLight.Range = 28
pointLight.Brightness = 0.9
pointLight.Color = lights
pointLight.Parent = ceilingLight

local doors = Instance.new("Folder")
doors.Name = "Doors"
doors.Parent = map
for _, side in ipairs({"Left", "Right"}) do
    local x = side == "Left" and -16 or 16
    local p = part(doors, side, Vector3.new(x, 11, 0), Vector3.new(1.3, 10, 9), Color3.fromRGB(141, 161, 159), Enum.Material.Metal)
    p:SetAttribute("ClosedCFrame", CFrame.new(x, 5, 0))
    p:SetAttribute("OpenCFrame", CFrame.new(x, 11, 0))
    p:SetAttribute("Closed", false)
    p.CanCollide = false
end

local corridors = Instance.new("Folder")
corridors.Name = "Corridors"
corridors.Parent = map
part(corridors, "LeftFloor", Vector3.new(-34, -0.8, -12), Vector3.new(38, 1, 43), concrete)
part(corridors, "RightFloor", Vector3.new(34, -0.8, -12), Vector3.new(38, 1, 43), concrete)
for _, side in ipairs({-1, 1}) do
    local x = side * 37
    part(corridors, "HallLight" .. tostring(side), Vector3.new(x, 8, -16), Vector3.new(4, 0.3, 2), Color3.fromRGB(138, 50, 43), Enum.Material.Neon, false)
end

local cameras = Instance.new("Folder")
cameras.Name = "Cameras"
cameras.Parent = map
local specs = {
    {Vector3.new(-42, 9, -29), Vector3.new(-24, 2, -12)},
    {Vector3.new(42, 9, -26), Vector3.new(24, 2, -10)},
    {Vector3.new(-23, 8, 8), Vector3.new(-16, 4, 0)},
    {Vector3.new(23, 8, 8), Vector3.new(16, 4, 0)},
}
for index, spec in ipairs(specs) do
    local anchor = part(cameras, "CAM_" .. string.format("%02d", index), spec[1], Vector3.new(1, 1, 1), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, false)
    anchor.Transparency = 1
    anchor.CFrame = CFrame.lookAt(spec[1], spec[2])
end

local enemyFolder = Instance.new("Folder")
enemyFolder.Name = "Enemies"
enemyFolder.Parent = map
local enemy = part(enemyFolder, "Subject06", Vector3.new(-43, 3, -28), Vector3.new(3, 6, 2), Color3.fromRGB(79, 21, 22), Enum.Material.Metal, false)
enemy:SetAttribute("Stage", 0)
local glow = Instance.new("PointLight")
glow.Color = Color3.fromRGB(229, 43, 33)
glow.Range = 12
glow.Brightness = 0.7
glow.Parent = enemy

local spawn = Instance.new("SpawnLocation")
spawn.Name = "OfficeSpawn"
spawn.Size = Vector3.new(5, 1, 5)
spawn.CFrame = CFrame.new(0, 0.5, 5)
spawn.Anchored = true
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Neutral = true
spawn.Parent = office

local Lighting = game:GetService("Lighting")
Lighting.ClockTime = 0
Lighting.Brightness = 0.6
Lighting.FogEnd = 90
Lighting.Ambient = Color3.fromRGB(35, 43, 45)
print("[CRN Night1] Greybox world created.")
