-- Shared tuning for the first expedition. Gameplay rules live on the server.
local Config = {}

Config.BuildVersion = 11
Config.MaxPartySize = 4
Config.TargetChapterMinutes = 20
Config.RunTimeLimitSeconds = 25 * 60

Config.Player = {
    MaxHealth = 100,
    StartingLives = 3,
    StartingRadiation = 0,
    StartingFilterSeconds = 100,
    StartingFilterCartridges = 1,
    StartingMedkits = 1,
    StartingBattery = 100,
    MaxFilterSeconds = 240,
    MaxFilterCartridges = 4,
    MaxMedkits = 3,
}

Config.Survival = {
    RadiationPerSecond = 2.5,
    FilterDrainPerSecond = 1,
    UnfilteredHealthPerSecond = 5,
    HazardTickSeconds = 0.5,
    ElectricDamage = 18,
    AnomalyDamagePerSecond = 12,
    FallDamage = 25,
    RespawnDelay = 3,
}

Config.Lamp = {
    DrainPerSecond = 0.85,
    LowBatteryNotice = 20,
}

Config.World = {
    ShelterSpawn = Vector3.new(0, 3, 4),
    CheckpointRespawnHeight = 4,
    StartConsole = Vector3.new(-7, 2.5, 18),
    AirlockOpenOffset = Vector3.new(0, 20, 0),
}

Config.Lighting = {
    ClockTime = 5.4,
    Brightness = 1.45,
    Ambient = Color3.fromRGB(68, 74, 70),
    OutdoorAmbient = Color3.fromRGB(43, 50, 47),
    FogColor = Color3.fromRGB(88, 104, 100),
    FogStart = 48,
    FogEnd = 620,
}

Config.StageText = {
    READY = "Подготовка в убежище",
    STATION = "Найти ретранслятор на станции",
    TUNNEL = "Пройти тоннель и забрать ретранслятор",
    SURFACE = "Пересечь поверхность и найти ретранслятор",
    EXTRACTION = "Активировать маяк эвакуации",
    WIN = "Вылазка завершена",
    LOSE = "Вылазка сорвана",
}

return Config
