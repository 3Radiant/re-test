--[[
	Female Titan. Canon: 14 m, wielded by Annie Leonhart. Agile and quick.
]]

return {
	DisplayName = "Female Titan",
	Wielder = "Annie Leonhart",

	HeightMeters = 14,
	MaxHealth = 2800,
	Regen = { PerSecond = 20, Delay = 5 },
	DamageTakenMultiplier = 1,

	WalkSpeed = 28,
	RunSpeed = 56,
	JumpHeight = 16,

	SkinColor = Color3.fromRGB(150, 110, 95),
	Material = Enum.Material.SmoothPlastic,

	Abilities = {},

	Combat = {
		M1 = {
			Cooldown = 0.35,
			ComboReset = 1.1,
			Hits = {
				{ Windup = 0.10, DamageHuman = 35, DamageTitan = 50, Size = Vector3.new(0.6, 0.6, 0.6), Forward = 0.5, Knockback = 40 },
				{ Windup = 0.10, DamageHuman = 35, DamageTitan = 50, Size = Vector3.new(0.6, 0.6, 0.6), Forward = 0.5, Knockback = 40 },
				{ Windup = 0.20, Cooldown = 0.7, DamageHuman = 70, DamageTitan = 100, Size = Vector3.new(0.8, 0.9, 0.9), Forward = 0.6, Knockback = 110 },
			},
		},
	},

	Animations = { M1 = {} },
}
