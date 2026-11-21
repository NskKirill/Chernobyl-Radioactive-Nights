-- Night 1 balance. One real-time minute per game hour by default.
local Config = {}
Config.NightLengthSeconds = 360
Config.MaxPower = 100
Config.BasePowerDrainPerSecond = 0.08
Config.DoorDrainPerSecond = 0.13
Config.CameraDrainPerSecond = 0.04
Config.EnemyAdvanceMinSeconds = 15
Config.EnemyAdvanceMaxSeconds = 24
Config.EnemyAttackDelaySeconds = 6
Config.EnemyRepelSeconds = 5
Config.OfficeSpawn = Vector3.new(0, 3, 2)
Config.CameraNames = {"CAM 01 / Corridor", "CAM 02 / Junction", "CAM 03 / Left Door", "CAM 04 / Right Door"}
return Config
