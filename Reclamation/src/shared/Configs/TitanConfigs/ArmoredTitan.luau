--[[
	Armored Titan. Canon: 15 m, wielded by Reiner Braun, hardened plating.
	All combat numbers are gameplay placeholders - tune freely.

	Hit boxes are in UNITS OF THE TITAN'S HEIGHT, so they scale with any model:
	Size = box size, Forward = how far in front of the root the box is centred.
]]

return {
	DisplayName = "Armored Titan",
	Wielder = "Reiner Braun",

	HeightMeters = 15,
	MaxHealth = 4000,
	Regen = { PerSecond = 15, Delay = 6 }, -- heal after 6s without taking damage
	DamageTakenMultiplier = 1,

	WalkSpeed = 24,
	RunSpeed = 44,
	JumpHeight = 12,

	-- Used by the placeholder model (ignored if you drop a real model in assets/titans)
	SkinColor = Color3.fromRGB(92, 66, 58),
	Material = Enum.Material.Slate,

	Abilities = {
		Harden = { Key = Enum.KeyCode.Q, Duration = 6, Cooldown = 18, DamageMultiplier = 0.2 },
	},

	Combat = {
		M1 = {
			Cooldown = 0.55,
			ComboReset = 1.4,
			Hits = {
				{ Windup = 0.20, DamageHuman = 45, DamageTitan = 60, Size = Vector3.new(0.7, 0.6, 0.6), Forward = 0.50, Knockback = 55 },
				{ Windup = 0.20, DamageHuman = 45, DamageTitan = 60, Size = Vector3.new(0.7, 0.6, 0.6), Forward = 0.50, Knockback = 55 },
				{ Windup = 0.25, DamageHuman = 55, DamageTitan = 80, Size = Vector3.new(0.8, 0.6, 0.7), Forward = 0.55, Knockback = 70 },
				{ Windup = 0.40, Cooldown = 1.0, DamageHuman = 90, DamageTitan = 140, Size = Vector3.new(1.0, 0.8, 0.9), Forward = 0.65, Knockback = 140 },
			},
		},
	},

	-- Animation IDs (numbers). Anything missing falls back to the human set.
	Animations = {
		-- idle = 0, walk = 0, run = 0,
		M1 = {
			-- [1] = 0, [2] = 0, [3] = 0, [4] = 0,
		},
	},
}
