--[[
	Effects (server)
	Simple transformation visuals: a flash of light and a burst of steam.
]]

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Effects = {}

function Effects.burst(position: Vector3, scale: number, color: Color3?)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = position

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(color or Color3.fromRGB(235, 235, 235))
	emitter.Size = NumberSequence.new(scale * 0.5, scale * 1.8)
	emitter.Lifetime = NumberRange.new(1, 2.2)
	emitter.Speed = NumberRange.new(scale * 0.5, scale * 2)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.LightEmission = 0.5
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = anchor

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 120)
	light.Range = scale * 4
	light.Brightness = 8
	light.Parent = anchor

	anchor.Parent = Workspace
	emitter:Emit(60)
	TweenService:Create(light, TweenInfo.new(0.6), { Brightness = 0 }):Play()
	Debris:AddItem(anchor, 4)
end

-- Big flash + steam when a shifter transforms
function Effects.shift(position: Vector3, heightStuds: number)
	Effects.burst(position, heightStuds * 0.5, Color3.fromRGB(255, 240, 200))
end

-- Steam when a Titan evaporates
function Effects.evaporate(position: Vector3, heightStuds: number)
	Effects.burst(position, heightStuds * 0.6, Color3.fromRGB(240, 240, 240))
end

return Effects
