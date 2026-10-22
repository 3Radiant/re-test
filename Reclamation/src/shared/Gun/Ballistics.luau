--[[
	Ballistics (shared)
	One projectile simulation used by BOTH the server (real, damaging) and the client
	(cosmetic) so they follow the same path.

	  * Flies dead straight for config.FalloffDistance studs.
	  * After that, gravity pulls it down -> projectile arc.
	  * Each step raycasts old -> new position, so fast bullets never tunnel.
]]

local Workspace = game:GetService("Workspace")

local Ballistics = {}
Ballistics.__index = Ballistics

function Ballistics.new(origin: Vector3, direction: Vector3, config: any, params: RaycastParams)
	return setmetatable({
		Position = origin,
		Velocity = direction.Unit * config.BulletSpeed,
		Travelled = 0,
		Age = 0,
		Finished = false,
		Config = config,
		Params = params,
	}, Ballistics)
end

-- Returns a RaycastResult if the bullet hit something this step.
function Ballistics.Step(self: any, dt: number): RaycastResult?
	if self.Finished then
		return nil
	end

	local config = self.Config

	if self.Travelled >= config.FalloffDistance then
		self.Velocity += Vector3.new(0, -Workspace.Gravity * config.GravityScale * dt, 0)
	end

	local displacement: Vector3 = self.Velocity * dt
	local result = Workspace:Raycast(self.Position, displacement, self.Params)
	if result then
		self.Position = result.Position
		self.Finished = true
		return result
	end

	self.Position += displacement
	self.Travelled += displacement.Magnitude
	self.Age += dt

	if self.Age >= config.MaxLifetime or self.Travelled >= config.MaxRange then
		self.Finished = true
	end
	return nil
end

return Ballistics
