local Kar98k = {
	DisplayName = "Kar98k",

	BodyDamage = 42,
	HeadshotDamage = 87,
	LimbDamage = 17,

	Ammo = 5, -- magazine size
	RPM = 55, -- shots per minute -> fire interval = 60 / RPM

	BulletSpeed = 1100, -- studs per second

	AnimationGroup = "Rifle", -- "Rifle" "Pistol"
	Type = "Bolt", -- "SemiAuto" "Auto" "Bolt" (Auto = hold click to keep firing)

	Tracer = "Default", -- see BulletVisuals.TracerStyles

	Recoil = 0, -- not implemented yet

	-- Added for the projectile + stance system
	ReloadTime = 3.5,
	FalloffDistance = 160, -- bullet flies dead straight this far, THEN drops
	GravityScale = 0.5, -- fraction of workspace gravity once it starts dropping
	MaxRange = 1600,
	MaxLifetime = 6,
	AimWalkSpeed = 6, -- the only speed allowed while aiming
	AimTurnSpeed = 18, -- how snappily you turn toward the mouse
}

return Kar98k
