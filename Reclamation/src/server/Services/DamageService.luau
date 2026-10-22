--[[
	DamageService (server)
	The ONE place damage is applied. Knows the difference between humans and Titans:
	  * Titans resist guns, take extra on the Nape, honour DamageMultiplier (hardening)
	  * Titan health is managed here so a defeated Titan returns the shifter to human
	    form instead of killing (and respawning) the player.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Configs.Config)

local DamageService = {}

-- ShifterService sets this: function(ownerPlayer, attackerPlayer)
DamageService.onTitanDefeated = nil :: ((Player?, Player?) -> ())?

-- info = { Source = "Gun" | "TitanMelee", HitPart = BasePart? }
-- Returns the damage actually dealt.
function DamageService.damage(attacker: Player?, targetModel: Model, amount: number, info: any?): number
	info = info or {}

	local humanoid = targetModel:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return 0
	end

	-- Humans: plain damage
	if not targetModel:GetAttribute("IsTitan") then
		humanoid:TakeDamage(amount)
		return amount
	end

	-- Titans
	local multiplier: number = targetModel:GetAttribute("DamageMultiplier") or 1
	if info.Source == "Gun" then
		multiplier *= GameConfig.Damage.TitanGunMultiplier
	end
	if info.HitPart and info.HitPart.Name == "Nape" then
		multiplier *= GameConfig.Damage.NapeMultiplier
	end

	local final = amount * multiplier
	targetModel:SetAttribute("LastDamaged", Workspace:GetServerTimeNow())

	if humanoid.Health - final <= 0 then
		humanoid.Health = 1 -- never let the Titan humanoid actually die
		local owner = Players:GetPlayerByUserId(targetModel:GetAttribute("OwnerUserId") or 0)
		if DamageService.onTitanDefeated then
			DamageService.onTitanDefeated(owner, attacker)
		end
		return final
	end

	humanoid.Health -= final
	return final
end

return DamageService
