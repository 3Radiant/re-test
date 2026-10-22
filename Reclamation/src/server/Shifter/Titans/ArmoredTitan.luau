--[[
	ArmoredTitan (server) - subclass of ShifterBase.
	Adds the Harden ability: for a few seconds the Titan takes a fraction of normal
	damage (DamageService reads the model's "DamageMultiplier" attribute).
]]

local ShifterBase = require(script.Parent.Parent.ShifterBase)

local ArmoredTitan = setmetatable({}, { __index = ShifterBase })
ArmoredTitan.__index = ArmoredTitan

function ArmoredTitan.new(player: Player, titanName: string)
	local self = ShifterBase.new(player, titanName)
	return setmetatable(self, ArmoredTitan)
end

function ArmoredTitan.UseAbility(self: any, abilityName: string): boolean
	if abilityName ~= "Harden" or not self.Shifted or self.Transforming or not self.Model then
		return false
	end

	local def = self.Config.Abilities.Harden
	local now = os.clock()
	if now < (self.AbilityReadyAt.Harden or 0) then
		return false
	end
	self.AbilityReadyAt.Harden = now + def.Cooldown

	local model: Model = self.Model
	model:SetAttribute("DamageMultiplier", def.DamageMultiplier)
	model:SetAttribute("Hardened", true)

	-- Visual: shift to a harder, paler material while active
	local originals = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Name ~= "Nape" then
			originals[part] = { Material = part.Material, Color = part.Color }
			part.Material = Enum.Material.Metal
			part.Color = part.Color:Lerp(Color3.fromRGB(200, 190, 180), 0.45)
		end
	end

	task.delay(def.Duration, function()
		if model.Parent then
			model:SetAttribute("DamageMultiplier", 1)
			model:SetAttribute("Hardened", false)
			for part, original in originals do
				if part.Parent then
					part.Material = original.Material
					part.Color = original.Color
				end
			end
		end
	end)
	return true
end

return ArmoredTitan
