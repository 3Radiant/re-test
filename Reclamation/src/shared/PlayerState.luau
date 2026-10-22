--[[
	PlayerState (shared) - the "global state table".
	Server-owned facts about a player live as attributes on the Player, so they
	replicate to everyone automatically. The server writes, anyone reads/observes.

	Keys
	  Shifted       bool    currently in Titan form
	  Transforming  bool    mid-transformation (biting hand); movement is locked
	  ShifterName   string  which Titan this player wields ("" = none)
	  ShiftReadyAt  number  workspace:GetServerTimeNow() when they can shift again
	  ShiftsLeft    number  transformations remaining
]]

local PlayerState = {}

PlayerState.Defaults = {
	Shifted = false,
	Transforming = false,
	ShifterName = "",
	ShiftReadyAt = 0,
	ShiftsLeft = 0,
}

function PlayerState.get(player: Player, key: string): any
	local value = player:GetAttribute(key)
	if value == nil then
		return PlayerState.Defaults[key]
	end
	return value
end

-- Server only (client-side attributes don't replicate)
function PlayerState.set(player: Player, key: string, value: any)
	player:SetAttribute(key, value)
end

-- Calls callback now and whenever the key changes. Returns the connection.
function PlayerState.observe(player: Player, key: string, callback: (any) -> ())
	task.spawn(callback, PlayerState.get(player, key))
	return player:GetAttributeChangedSignal(key):Connect(function()
		callback(PlayerState.get(player, key))
	end)
end

return PlayerState
