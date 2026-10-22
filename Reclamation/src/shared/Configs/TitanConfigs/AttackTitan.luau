--[[
	Attack Titan. Canon: 15 m, wielded by Eren Yeager. Fast and aggressive, no armor.
]]

return {
	DisplayName = "Attack Titan",
	Wielder = "Eren Yeager",

	HeightMeters = 15,
	MaxHealth = 3000,
	Regen = { PerSecond = 22, Delay = 5 },
	DamageTakenMultiplier = 1,

	WalkSpeed = 26,
	RunSpeed = 52,
	JumpHeight = 14,

	SkinColor = Color3.fromRGB(120, 78, 62),
	Material = Enum.Material.SmoothPlastic,

	Abilities = {},

	Combat = {
		M1 = {
			Cooldown = 0.4,
			ComboReset = 1.2,
			Hits = {
				{ Windup = 0.12, DamageHuman = 40, DamageTitan = 55, Size = Vector3.new(0.6, 0.6, 0.6), Forward = 0.5, Knockback = 45 },
				{ Windup = 0.12, DamageHuman = 40, DamageTitan = 55, Size = Vector3.new(0.6, 0.6, 0.6), Forward = 0.5, Knockback = 45 },
				{ Windup = 0.12, DamageHuman = 40, DamageTitan = 55, Size = Vector3.new(0.6, 0.6, 0.6), Forward = 0.5, Knockback = 45 },
				{ Windup = 0.30, Cooldown = 0.8, DamageHuman = 80, DamageTitan = 120, Size = Vector3.new(0.9, 0.8, 0.8), Forward = 0.6, Knockback = 120 },
			},
		},
	},

	Animations = { M1 = {} },
}
