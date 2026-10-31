-- Local cinematic ambience: subtle distortion near the Echo Bloom and radiation fields.
-- It never changes damage, inventory, objectives or other authoritative game state.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local color = Lighting:FindFirstChild("CRN_LocalColor") or Instance.new("ColorCorrectionEffect")
color.Name = "CRN_LocalColor"
color.Enabled = true
color.Parent = Lighting

local blur = Lighting:FindFirstChild("CRN_LocalBlur") or Instance.new("BlurEffect")
blur.Name = "CRN_LocalBlur"
blur.Enabled = true
blur.Size = 0
blur.Parent = Lighting

local function contains(box, position)
    local localPoint = box.CFrame:PointToObjectSpace(position)
    return math.abs(localPoint.X) <= box.Size.X * 0.5
        and math.abs(localPoint.Y) <= box.Size.Y * 0.5
        and math.abs(localPoint.Z) <= box.Size.Z * 0.5
end

local elapsed = 0
local colorMix = 0
local blurMix = 0
RunService.RenderStepped:Connect(function(dt)
    elapsed += dt
    if elapsed < 0.12 then return end
    dt = elapsed
    elapsed = 0

    local targetColor = 0
    local targetBlur = 0
    local map = Workspace:FindFirstChild("CRN_Expedition")
    local fields = map and map:FindFirstChild("Hazards")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if fields and root then
        for _, field in ipairs(fields:GetChildren()) do
            if field:IsA("BasePart") then
                local kind = field:GetAttribute("HazardType")
                if contains(field, root.Position) then
                    if kind == "ANOMALY" then
                        targetColor = math.max(targetColor, 1)
                        targetBlur = math.max(targetBlur, 1)
                    elseif kind == "RADIATION" then
                        targetColor = math.max(targetColor, 0.42)
                    end
                end
            end
        end
    end

    colorMix += (targetColor - colorMix) * math.clamp(dt * 2.5, 0, 1)
    blurMix += (targetBlur - blurMix) * math.clamp(dt * 3, 0, 1)
    color.Saturation = -0.16 * colorMix
    color.Contrast = 0.08 * colorMix
    color.TintColor = Color3.new(1, 1 - 0.06 * colorMix, 1 - 0.12 * colorMix)
    blur.Size = 4 * blurMix
end)
