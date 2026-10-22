--[[
	BulletVisuals (client)
	Cosmetic bullets only - the server decides what actually hits. Uses the same
	Ballistics module so the visual path matches the real one.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GunConfigs = require(Shared.Configs.GunConfigs)
local Remotes = require(Shared.Remotes)
local Ballistics = require(Shared.Gun.Ballistics)

local BulletVisuals = {}

-- GunConfig.Tracer picks one of these
BulletVisuals.TracerStyles = {
	Default = { Color = Color3.fromRGB(255, 220, 130), Size = Vector3.new(0.15, 0.15, 2) },
}

local folder = Instance.new("Folder")
folder.Name = "GunBullets"
folder.Parent = Workspace

function BulletVisuals.spawnBullet(origin: Vector3, direction: Vector3, config: any, shooterCharacter: Instance?)
	local style = BulletVisuals.TracerStyles[config.Tracer] or BulletVisuals.TracerStyles.Default

	local part = Instance.new("Part")
	part.Size = style.Size
	part.Color = style.Color
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false -- bullets never block raycasts
	part.CanTouch = false
	part.CastShadow = false
	part.CFrame = CFrame.lookAt(origin, origin + direction)
	part.Parent = folder

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = if shooterCharacter then { shooterCharacter } else {}

	local bullet = Ballistics.new(origin, direction, config, params)

	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(dt)
		Ballistics.Step(bullet, dt)
		part.CFrame = CFrame.lookAt(bullet.Position, bullet.Position + bullet.Velocity)
		if bullet.Finished then
			connection:Disconnect()
			part:Destroy()
		end
	end)
end

function BulletVisuals.start()
	-- Other players' shots (the server skips the shooter, who predicts locally)
	Remotes.GunBulletReplicate.OnClientEvent:Connect(function(shooterCharacter, gunId, origin, direction)
		local config = GunConfigs[gunId]
		if config and typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
			BulletVisuals.spawnBullet(origin, direction, config, shooterCharacter)
		end
	end)
end

return BulletVisuals
