--[[
	AnimationConfigs (shared) - ALL animation IDs in one place.
	IDs are numbers. Missing/nil entries are simply skipped.
]]

local AnimationConfigs = {
	R15_Animations = {
		idle = 123506257787693,
		sit = 93510718700299,
		climb = 84928247225712,
		walk = 131456776016673,
		run = 88471524924881,
		crouch = 109873741442289,
		prone = 128012679440087,
		jump = 120806074075745,
		land = 84175020371276,
		fall = 126531083236156,
		swim = 74337086098657,
		swimidle = 129889153930676,
		cuffed = 121778511803588,
		nvg_down = 139405372108608,
		nvg_up = 129593908367110,
		bitehand = 104186481295205,
	} :: { [string]: number },

	R6_Animations = {
		idle = 94895920597129,
		walk = 83288770616418,
		run = 81566505013607,
		crouch = 75151469676980,
		jump = 119109059338672,
		fall = 119109059338672,
		bitehand = 104186481295205,
	} :: { [string]: number },

	-- Gun animations by AnimationGroup (see GunConfigs). Author these ARM/TORSO ONLY
	-- so the legs keep doing walk/run/crouch underneath.
	--   idle   = gun equipped, carried       ready = gun raised
	--   aim    = aiming stance               fire / reload = one-shots
	Guns = {
		Rifle = {
			-- idle = 0,
			-- ready = 0,
			-- aim = 0,
			-- fire = 0,
			-- reload = 0,
		} :: { [string]: number },
		Pistol = {} :: { [string]: number },
	} :: { [string]: { [string]: number } },
}

return AnimationConfigs
