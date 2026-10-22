--[[
	GunStates (shared)
	The legal stance flow for a gun, used by client (prediction) AND server (validation).

	Idle   -> equipped, normal movement
	Ready  -> gun raised (click from Idle), movement still normal
	Aiming -> F while Ready: slow walk only, turns to mouse, can shoot

	Idle -> Aiming directly is NOT allowed: you must ready the gun first.
]]

local GunStates = {}

GunStates.Stance = {
	Idle = "Idle",
	Ready = "Ready",
	Aiming = "Aiming",
}

local allowed: { [string]: { [string]: boolean } } = {
	Idle = { Ready = true },
	Ready = { Aiming = true, Idle = true },
	Aiming = { Ready = true, Idle = true }, -- F again lowers to Ready; Idle = reload/unequip
}

function GunStates.canTransition(from: string, to: string): boolean
	if from == to then
		return true
	end
	local row = allowed[from]
	return row ~= nil and row[to] == true
end

return GunStates
