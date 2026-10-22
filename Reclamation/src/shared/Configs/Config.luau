--[[
	Config (shared) - global tuning values. Units: studs and seconds.
]]

local Config = {
	StudsPerMeter = 3, -- used to turn canon Titan heights (metres) into studs
	DebugHitboxes = false, -- draw melee hitboxes in red

	Movement = {
		Human = { Walk = 12, Crouch = 9, Run = 26, JumpHeight = 7.2 },
	},
	FovWalk = 70,
	FovRun = 80,
	AnimationFadeTime = 0.3,

	Camera = {
		Sensitivity = 0.0035, -- radians per pixel of mouse movement
		MaxPitch = math.rad(80),

		-- Human (third person, hold RIGHT MOUSE to look, cursor stays free for aiming)
		MinZoom = 3,
		MaxZoom = 30,
		DefaultZoom = 8,
		HeadOffset = Vector3.new(0, 2, 0),
		Shoulder = Vector3.new(1.2, 0.4, 0),
		Aim = { Zoom = 5, Shoulder = Vector3.new(2.2, 0.8, 0), Fov = 58 },

		-- Titan (mouse locked, high camera). All scaled by the Titan's height so
		-- it works for any size. 1.44 / 2.2 reproduce the original 65 / 100 stud
		-- values on a 45 stud Titan.
		TitanHeadOffsetScale = 1.44,
		TitanZoomMinScale = 1.44,
		TitanZoomMaxScale = 2.2,
	},

	Shifting = {
		DefaultTitan = "ArmoredTitan",
		MaxShifts = 3, -- per player per session. Raise while testing!
		BiteTime = 1.6, -- seconds; set to the length of your "bitehand" animation
		Cooldown = 20, -- seconds after turning back before shifting again
	},

	Damage = {
		-- Rifles barely scratch a Titan (as in the anime). Nape shots hurt more.
		TitanGunMultiplier = 0.05,
		NapeMultiplier = 2,
		HumanHealthAfterDefeat = 0.5, -- fraction of max health when forced out of Titan form
	},
}

return Config
