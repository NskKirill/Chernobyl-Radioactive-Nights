-- Builds the chapter from Roblox primitives. The generated map is versioned so
-- repeated starts replace only this project's old expedition model.
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local existing = Workspace:FindFirstChild("CRN_Expedition")
if existing and existing:GetAttribute("BuildVersion") == Config.BuildVersion then
    print("[CRN] Expedition map already built; reusing it.")
    return
end
if existing then
    existing:Destroy()
end

local map = Instance.new("Model")
map.Name = "CRN_Expedition"
map:SetAttribute("BuildVersion", Config.BuildVersion)
map.Parent = Workspace

local folders = {}
for _, name in ipairs({"Shelter", "Station", "Tunnel", "Surface", "Hazards", "Supplies", "Objectives", "Checkpoints", "Lights"}) do
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = map
    folders[name] = folder
end

local C = {
    concrete = Color3.fromRGB(77, 82, 79),
    dark = Color3.fromRGB(33, 39, 39),
    metal = Color3.fromRGB(87, 91, 84),
    rust = Color3.fromRGB(118, 65, 42),
    warning = Color3.fromRGB(227, 167, 46),
    pale = Color3.fromRGB(161, 181, 165),
    green = Color3.fromRGB(99, 225, 143),
    red = Color3.fromRGB(224, 73, 54),
    blue = Color3.fromRGB(92, 163, 177),
    violet = Color3.fromRGB(169, 110, 206),
    soil = Color3.fromRGB(63, 70, 61),
}

local function part(parent, name, size, cf, color, material, transparency, collide)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Anchored = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Color = color or C.concrete
    p.Material = material or Enum.Material.Concrete
    p.Transparency = transparency or 0
    p.CanCollide = collide ~= false
    p.CanTouch = collide ~= false
    p.Parent = parent
    return p
end

local function light(parent, name, position, color, brightness, range, size)
    local bulb = part(parent, name, size or Vector3.new(1.5, 0.35, 1.5), CFrame.new(position), color, Enum.Material.Neon, 0, false)
    local glow = Instance.new("PointLight")
    glow.Name = "Glow"
    glow.Color = color
    glow.Brightness = brightness or 1
    glow.Range = range or 20
    glow.Parent = bulb
    return bulb
end

local function sign(parent, name, text, position, color, rotation)
    local board = part(parent, name, Vector3.new(12, 4, 0.45), CFrame.new(position) * (rotation or CFrame.new()), C.dark, Enum.Material.Metal)
    for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
        local surface = Instance.new("SurfaceGui")
        surface.Name = "Sign_" .. face.Name
        surface.Face = face
        surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        surface.PixelsPerStud = 30
        surface.Parent = board
        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = color or C.pale
        label.TextScaled = true
        label.Font = Enum.Font.Code
        label.Parent = surface
    end
    return board
end

local function checkpoint(name, zone, position, index)
    local width = 16
    if zone == "Станция Каскад" then width = 82
    elseif zone == "Сервисный тоннель" then width = 26
    elseif zone == "Поверхность" or zone == "Северная гряда" then width = 76
    elseif zone == "Убежище" then width = 86 end
    local depth = (index == 0) and 20 or 18
    local forward = position + Vector3.new(0, 0, 1)
    local p = part(folders.Checkpoints, name, Vector3.new(width, 8, depth), CFrame.lookAt(position, forward), C.green, Enum.Material.ForceField, 1, false)
    p:SetAttribute("Zone", zone)
    p:SetAttribute("Index", index)
    return p
end

local function hazard(name, kind, position, size, damage)
    local p = part(folders.Hazards, name, size, CFrame.new(position), C.red, Enum.Material.ForceField, 1, false)
    p:SetAttribute("HazardType", kind)
    p:SetAttribute("Damage", damage or 0)
    p:SetAttribute("Warning", kind == "ANOMALY" and 2.5 or 1.2)
    return p
end

local function prompt(target, actionText, objectText, holdDuration)
    local pp = Instance.new("ProximityPrompt")
    pp.Name = "Interact"
    pp.ActionText = actionText
    pp.ObjectText = objectText
    pp.HoldDuration = holdDuration or 0.45
    pp.MaxActivationDistance = 10
    pp.RequiresLineOfSight = false
    pp.Parent = target
    return pp
end

local function pickup(name, kind, position, color, label)
    local p = part(folders.Supplies, name, Vector3.new(2.2, 2.2, 2.2), CFrame.new(position), color, Enum.Material.Neon, 0, true)
    p.Shape = Enum.PartType.Ball
    p:SetAttribute("SupplyType", kind)
    p:SetAttribute("Collected", false)
    local glow = Instance.new("PointLight")
    glow.Color = color
    glow.Brightness = 0.75
    glow.Range = 12
    glow.Parent = p
    prompt(p, "Забрать", label, 0.35)
    return p
end

local function relay(name, position, step)
    local p = part(folders.Objectives, name, Vector3.new(2.8, 3.4, 2.8), CFrame.new(position), C.violet, Enum.Material.Neon, 0, true)
    p.Shape = Enum.PartType.Ball
    p:SetAttribute("RelayStep", step)
    p:SetAttribute("Collected", false)
    local glow = Instance.new("PointLight")
    glow.Color = C.violet
    glow.Brightness = 1.2
    glow.Range = 16
    glow.Parent = p
    prompt(p, "Снять блок", "Ретранслятор " .. tostring(step), 1.2)
    return p
end

-- Lighting is deterministic and all visual resources are built-in.
Lighting.ClockTime = Config.Lighting.ClockTime
Lighting.Brightness = Config.Lighting.Brightness
Lighting.Ambient = Config.Lighting.Ambient
Lighting.OutdoorAmbient = Config.Lighting.OutdoorAmbient
Lighting.FogColor = Config.Lighting.FogColor
Lighting.FogStart = Config.Lighting.FogStart
Lighting.FogEnd = Config.Lighting.FogEnd
Lighting.GlobalShadows = true
Lighting.EnvironmentDiffuseScale = 0.32
Lighting.EnvironmentSpecularScale = 0.12
local atmosphere = Lighting:FindFirstChild("CRN_Atmosphere") or Instance.new("Atmosphere")
atmosphere.Name = "CRN_Atmosphere"
atmosphere.Density = 0.19
atmosphere.Offset = 0.08
atmosphere.Color = Color3.fromRGB(171, 184, 175)
atmosphere.Decay = Color3.fromRGB(79, 91, 86)
atmosphere.Glare = 0.04
atmosphere.Haze = 0.9
atmosphere.Parent = Lighting

-- Shelter: the old generator and blast-door idea becomes an airlock and kit station.
part(folders.Shelter, "ShelterFloor", Vector3.new(86, 2, 76), CFrame.new(0, -1, 0), C.dark)
part(folders.Shelter, "ShelterRoof", Vector3.new(86, 2, 76), CFrame.new(0, 23, 0), Color3.fromRGB(47, 53, 51))
part(folders.Shelter, "ShelterBackWall", Vector3.new(86, 24, 2), CFrame.new(0, 11, -38), C.concrete)
part(folders.Shelter, "ShelterLeftWall", Vector3.new(2, 24, 76), CFrame.new(-43, 11, 0), C.concrete)
part(folders.Shelter, "ShelterRightWall", Vector3.new(2, 24, 76), CFrame.new(43, 11, 0), C.concrete)
part(folders.Shelter, "ShelterFrontLeft", Vector3.new(27, 24, 2), CFrame.new(-29.5, 11, 38), C.concrete)
part(folders.Shelter, "ShelterFrontRight", Vector3.new(27, 24, 2), CFrame.new(29.5, 11, 38), C.concrete)
part(folders.Shelter, "GeneratorBody", Vector3.new(12, 8, 10), CFrame.new(-29, 4, -20), Color3.fromRGB(51, 61, 57), Enum.Material.Metal)
part(folders.Shelter, "GeneratorCap", Vector3.new(13, 0.6, 11), CFrame.new(-29, 8.3, -20), C.rust, Enum.Material.CorrodedMetal)
for x = -33, -25, 2 do
    part(folders.Shelter, "GeneratorRib", Vector3.new(0.45, 5, 8), CFrame.new(x, 4.5, -20), C.metal, Enum.Material.Metal)
end
part(folders.Shelter, "SupplyBench", Vector3.new(18, 3, 6), CFrame.new(23, 1.5, -24), C.metal, Enum.Material.Metal)
part(folders.Shelter, "StartConsole", Vector3.new(7, 5, 3), CFrame.new(Config.World.StartConsole), C.metal, Enum.Material.Metal, 0, false)
local startPrompt = prompt(folders.Shelter:FindFirstChild("StartConsole"), "Начать вылазку", "План маршрута", 1)
-- Hint at the terminal before the interaction becomes available.
startPrompt.MaxActivationDistance = 18
startPrompt.MaxIndicatorDistance = 18
light(folders.Lights, "ConsoleLamp", Config.World.StartConsole + Vector3.new(0, 2.9, -1), C.green, 1.15, 22)
sign(folders.Shelter, "ShelterBoard", "УБЕЖИЩЕ 04  |  ВЫЛАЗКА 01", Vector3.new(0, 14, -35), C.green)
sign(folders.Shelter, "AirlockSign", "ШЛЮЗ  →  СТАНЦИЯ КАСКАД  |  ПРЫГАЙ", Vector3.new(0, 12, 34), C.warning)
local cameraFolder = Instance.new("Folder")
cameraFolder.Name = "CameraAnchors"
cameraFolder.Parent = folders.Shelter
for _, spec in ipairs({
    {name = "CAM_01", pos = Vector3.new(-27, 11, -20), look = Vector3.new(0, 2, 25)},
    {name = "CAM_02", pos = Vector3.new(0, 13, 30), look = Vector3.new(0, 2, 90)},
    {name = "CAM_03", pos = Vector3.new(22, 12, 155), look = Vector3.new(0, 2, 250)},
}) do
    local anchor = part(cameraFolder, spec.name, Vector3.new(0.4, 0.4, 0.4), CFrame.lookAt(spec.pos, spec.look), C.pale, Enum.Material.SmoothPlastic, 1, false)
    anchor.CanQuery = false
end
local gate = part(folders.Shelter, "AirlockGate", Vector3.new(22, 18, 2), CFrame.new(0, 8, 37), C.rust, Enum.Material.CorrodedMetal)
gate:SetAttribute("ClosedCFrame", gate.CFrame)
gate:SetAttribute("OpenCFrame", gate.CFrame + Config.World.AirlockOpenOffset)
local spawn = Instance.new("SpawnLocation")
spawn.Name = "ShelterSpawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.CFrame = CFrame.lookAt(Config.World.ShelterSpawn, Config.World.ShelterSpawn + Vector3.new(0, 0, 1))
spawn.Anchored = true
spawn.Neutral = true
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Parent = folders.Shelter
for x = -28, 28, 14 do
    light(folders.Lights, "ShelterStrip", Vector3.new(x, 20, 4), Color3.fromRGB(160, 190, 164), 0.9, 30, Vector3.new(6, 0.25, 1))
end
pickup("Kit_Filter_Shelter", "FILTER", Vector3.new(22, 4, -24), C.blue, "Фильтр")
pickup("Kit_Medkit_Shelter", "MEDKIT", Vector3.new(29, 4, -24), C.red, "Аптечка")
checkpoint("CP_Shelter", "Убежище", Vector3.new(0, 2, -10), 0)

-- Cascade station, with a broken track crossing and a safer side ledge.
part(folders.Station, "StationFloorSouth", Vector3.new(82, 2, 56), CFrame.new(0, -1, 72), C.concrete)
part(folders.Station, "StationFloorNorth", Vector3.new(82, 2, 44), CFrame.new(0, -1, 151), C.concrete)
part(folders.Station, "StationWallLeft", Vector3.new(2, 20, 132), CFrame.new(-42, 9, 107), C.dark)
part(folders.Station, "StationWallRight", Vector3.new(2, 20, 132), CFrame.new(42, 9, 107), C.dark)
part(folders.Station, "PlatformLeft", Vector3.new(18, 1, 38), CFrame.new(-31, 0, 119), C.metal, Enum.Material.Metal)
part(folders.Station, "PlatformRight", Vector3.new(18, 1, 38), CFrame.new(31, 0, 119), C.metal, Enum.Material.Metal)
for i = 0, 4 do
    local x = -22 + i * 11
    local z = (i % 2 == 0) and 105 or 129
    part(folders.Station, "TrackJumper", Vector3.new(8, 1.2, 7), CFrame.new(x, 1 + (i % 2), z), C.rust, Enum.Material.CorrodedMetal)
end
for x = -34, 34, 17 do
    part(folders.Station, "StationColumn", Vector3.new(2.4, 18, 2.4), CFrame.new(x, 8, 79), C.metal, Enum.Material.Metal)
    part(folders.Station, "StationColumn", Vector3.new(2.4, 18, 2.4), CFrame.new(x, 8, 150), C.metal, Enum.Material.Metal)
end
sign(folders.Station, "StationName", "СТАНЦИЯ КАСКАД", Vector3.new(0, 15, 54), C.pale)
sign(folders.Station, "RadiationWarning", "РАДИАЦИЯ  |  ФИЛЬТР", Vector3.new(-26, 9, 88), C.warning)
light(folders.Lights, "StationLampA", Vector3.new(-25, 16, 72), C.blue, 1, 26)
light(folders.Lights, "StationLampB", Vector3.new(25, 16, 145), C.warning, 0.8, 24)
hazard("Rad_Station_Platform", "RADIATION", Vector3.new(-27, 3, 104), Vector3.new(18, 12, 24))
pickup("Cache_Filter_Station", "FILTER", Vector3.new(32, 3, 145), C.blue, "Картридж")
pickup("Cache_Battery_Station", "BATTERY", Vector3.new(-32, 3, 83), C.green, "Батарея")
relay("Relay_01_Station", Vector3.new(28, 3, 146), 1)
checkpoint("CP_Station", "Станция Каскад", Vector3.new(0, 2, 77), 1)

-- Service tunnel: a broken walkway, a live cable, then an original "Echo Bloom" anomaly.
part(folders.Tunnel, "TunnelFloorEntry", Vector3.new(26, 2, 48), CFrame.new(0, -1, 186), C.dark)
part(folders.Tunnel, "TunnelFloorWest", Vector3.new(26, 2, 44), CFrame.new(-3, -1, 264), C.dark)
part(folders.Tunnel, "TunnelFloorExit", Vector3.new(30, 2, 32), CFrame.new(0, -1, 311), C.dark)
part(folders.Tunnel, "TunnelServiceLedge", Vector3.new(4, 1, 170), CFrame.new(-10, 0, 245), C.metal, Enum.Material.Metal)
part(folders.Tunnel, "TunnelWallLeft", Vector3.new(2, 18, 148), CFrame.new(-14, 8, 246), C.concrete)
part(folders.Tunnel, "TunnelWallRight", Vector3.new(2, 18, 148), CFrame.new(14, 8, 246), C.concrete)
part(folders.Tunnel, "TunnelRoof", Vector3.new(30, 2, 154), CFrame.new(0, 18, 246), C.dark)
for i = 0, 5 do
    local z = 188 + i * 22
    part(folders.Tunnel, "TunnelRib", Vector3.new(1, 17, 1), CFrame.new(-12, 8, z), C.rust, Enum.Material.CorrodedMetal)
    part(folders.Tunnel, "TunnelRib", Vector3.new(1, 17, 1), CFrame.new(12, 8, z), C.rust, Enum.Material.CorrodedMetal)
    part(folders.Tunnel, "TunnelRibTop", Vector3.new(25, 1, 1), CFrame.new(0, 16, z), C.rust, Enum.Material.CorrodedMetal)
end
for i = 0, 8 do
    local x = -8 + (i % 5) * 4
    local z = 212 + i * 3.7
    part(folders.Tunnel, "BrokenWalkway", Vector3.new(6, 1, 5), CFrame.new(x, 1 + (i % 2), z), C.metal, Enum.Material.Metal)
end
local ladder = Instance.new("TrussPart")
ladder.Name = "MaintenanceLadder"
ladder.Size = Vector3.new(1.2, 10, 1.2)
ladder.CFrame = CFrame.new(12, 5, 278)
ladder.Anchored = true
ladder.Color = C.metal
ladder.Material = Enum.Material.Metal
ladder.Parent = folders.Tunnel
part(folders.Tunnel, "MaintenanceLedge", Vector3.new(3, 1, 26), CFrame.new(12, 10, 278), C.metal, Enum.Material.Metal)
part(folders.Tunnel, "LiveCable", Vector3.new(18, 0.45, 0.45), CFrame.new(0, 4, 235) * CFrame.Angles(0, 0, math.rad(90)), C.warning, Enum.Material.Neon, 0, false)
light(folders.Lights, "CableArcLamp", Vector3.new(0, 4, 235), C.warning, 1.4, 20)
for i = 1, 3 do
    local orb = part(folders.Tunnel, "EchoBloomShard", Vector3.new(1.8 + i, 1.8 + i, 1.8 + i), CFrame.new(-3 + i * 3, 5 + (i % 2) * 2, 276), C.violet, Enum.Material.Neon, 0.22, false)
    orb.Shape = Enum.PartType.Ball
    local glow = Instance.new("PointLight")
    glow.Color = C.violet
    glow.Brightness = 0.7
    glow.Range = 18
    glow.Parent = orb
end
sign(folders.Tunnel, "TunnelWarning", "КАБЕЛЬ ПОД НАПРЯЖЕНИЕМ", Vector3.new(0, 12, 226), C.warning)
sign(folders.Tunnel, "AnomalyWarning", "НЕ СМОТРИ НА ОТБЛЕСК", Vector3.new(0, 12, 265), C.violet)
light(folders.Lights, "TunnelLampA", Vector3.new(0, 14, 190), C.blue, 0.65, 24)
light(folders.Lights, "TunnelLampB", Vector3.new(0, 14, 250), C.red, 0.6, 22)
hazard("Electric_Cable_Field", "ELECTRIC", Vector3.new(0, 4, 235), Vector3.new(16, 8, 12), Config.Survival.ElectricDamage)
hazard("Echo_Bloom_Field", "ANOMALY", Vector3.new(0, 6, 276), Vector3.new(20, 14, 20), Config.Survival.AnomalyDamagePerSecond)
pickup("Cache_Medkit_Tunnel", "MEDKIT", Vector3.new(-9, 3, 293), C.red, "Аптечка")
pickup("Cache_Filter_Tunnel", "FILTER", Vector3.new(9, 3, 296), C.blue, "Фильтр")
relay("Relay_02_Tunnel", Vector3.new(0, 3, 308), 2)
checkpoint("CP_Tunnel", "Сервисный тоннель", Vector3.new(0, 2, 190), 2)

-- Surface: ruined avenue, service rooftops and an exposed gap to the extraction ridge.
part(folders.Surface, "SurfaceRoad", Vector3.new(76, 2, 234), CFrame.new(0, -1, 435), Color3.fromRGB(55, 61, 56), Enum.Material.Asphalt)
part(folders.Surface, "SurfaceGroundLeft", Vector3.new(42, 2, 330), CFrame.new(-59, -1.2, 484), C.soil, Enum.Material.Ground)
part(folders.Surface, "SurfaceGroundRight", Vector3.new(42, 2, 330), CFrame.new(59, -1.2, 484), C.soil, Enum.Material.Ground)
for z = 345, 620, 55 do
    part(folders.Surface, "BrokenStreetLine", Vector3.new(1, 0.15, 12), CFrame.new(0, 0.1, z), C.warning, Enum.Material.Neon, 0.2, false)
end
-- Distinctive derelict buildings frame the route without blocking the parkour lane.
for _, spec in ipairs({
    {x=-47,z=380,w=22,d=40,h=28},
    {x=47,z=420,w=22,d=54,h=36},
    {x=-48,z=500,w=24,d=54,h=31},
    {x=48,z=560,w=22,d=42,h=25},
}) do
    part(folders.Surface, "RuinedBlock", Vector3.new(spec.w, spec.h, spec.d), CFrame.new(spec.x, spec.h/2, spec.z), C.dark, Enum.Material.Concrete)
    part(folders.Surface, "RuinedRoofRim", Vector3.new(spec.w + 2, 1, spec.d + 2), CFrame.new(spec.x, spec.h, spec.z), C.rust, Enum.Material.CorrodedMetal)
end
-- A fractured avenue is crossed on two wide, readable slabs.
part(folders.Surface, "RoadBeforeGap", Vector3.new(76, 2, 52), CFrame.new(0, -1, 555), Color3.fromRGB(55, 61, 56), Enum.Material.Asphalt)
part(folders.Surface, "RoadAfterGap", Vector3.new(76, 2, 46), CFrame.new(0, -1, 631), Color3.fromRGB(55, 61, 56), Enum.Material.Asphalt)
for i = 0, 3 do
    part(folders.Surface, "ConcreteBridgeSlab", Vector3.new(12, 1.2, 14), CFrame.new(-18 + i * 12, 1.5 + (i % 2), 592 + (i % 2) * 3), C.concrete, Enum.Material.Concrete)
end
sign(folders.Surface, "BridgeWarningSign", "ОБВАЛ  |  ПРЫГАЙ ПО ПЛИТАМ", Vector3.new(0, 10, 573), C.warning)
light(folders.Lights, "BridgeWarningWest", Vector3.new(-31, 2.2, 578), C.warning, 1, 26, Vector3.new(1.2, 0.35, 1.2))
light(folders.Lights, "BridgeWarningEast", Vector3.new(31, 2.2, 578), C.warning, 1, 26, Vector3.new(1.2, 0.35, 1.2))
light(folders.Lights, "BridgeLandingWest", Vector3.new(-31, 2.2, 606), C.warning, 1, 26, Vector3.new(1.2, 0.35, 1.2))
light(folders.Lights, "BridgeLandingEast", Vector3.new(31, 2.2, 606), C.warning, 1, 26, Vector3.new(1.2, 0.35, 1.2))
sign(folders.Surface, "SurfaceSign", "ПОВЕРХНОСТЬ  |  НЕ СНИМАЙ МАСКУ", Vector3.new(0, 13, 337), C.warning)
sign(folders.Surface, "ExtractionSign", "МАЯК  →  СЕВЕРНАЯ ГРЯДА", Vector3.new(0, 11, 623), C.green)
light(folders.Lights, "SurfaceBeacon", Vector3.new(0, 12, 648), C.green, 1.3, 36, Vector3.new(2, 8, 2))
hazard("Rad_Surface_Avenue", "RADIATION", Vector3.new(-22, 4, 470), Vector3.new(22, 12, 34))
pickup("Cache_Filter_Surface", "FILTER", Vector3.new(31, 3, 395), C.blue, "Фильтр")
pickup("Cache_Battery_Surface", "BATTERY", Vector3.new(31, 3, 522), C.green, "Батарея")
pickup("Cache_Medkit_Surface", "MEDKIT", Vector3.new(-31, 3, 603), C.red, "Аптечка")
relay("Relay_03_Surface", Vector3.new(29, 3, 548), 3)
checkpoint("CP_Surface", "Поверхность", Vector3.new(0, 2, 365), 3)
checkpoint("CP_Ridge", "Северная гряда", Vector3.new(0, 2, 626), 4)

local evac = part(folders.Objectives, "ExtractionBeacon", Vector3.new(8, 1, 8), CFrame.new(0, 0.2, 650), C.green, Enum.Material.Neon, 0.08, true)
evac:SetAttribute("ObjectiveType", "EXTRACTION")
evac:SetAttribute("Active", false)
local evacLight = Instance.new("PointLight")
evacLight.Color = C.green
evacLight.Brightness = 1
evacLight.Range = 32
evacLight.Parent = evac
prompt(evac, "Подать сигнал", "Маяк эвакуации", 2.5)

print("[CRN] Expedition world ready: shelter, Cascade station, service tunnel, contaminated avenue and extraction ridge.")
