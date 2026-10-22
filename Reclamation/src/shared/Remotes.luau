--[[
	Remotes (shared)
	Every RemoteEvent in the game is listed here. The server creates them the first
	time this module is required; the client waits for them. Both sides just:
		local Remotes = require(Shared.Remotes)
		Remotes.GunFire:FireServer(...)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	-- Guns
	"GunSetStance", -- client -> server (tool, stance)
	"GunFire", -- client -> server (tool, origin, direction)
	"GunReload", -- client -> server (tool)
	"GunBulletReplicate", -- server -> clients (shooterCharacter, gunId, origin, direction)

	-- Shifters
	"ShiftToggle", -- client -> server: shift / deshift
	"TitanM1", -- client -> server: melee swing
	"TitanAbility", -- client -> server (abilityName)

	-- Combat feedback
	"Knockback", -- server -> client (velocity)
}

local folder
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in NAMES do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("Remotes")
end

local remotes: { [string]: RemoteEvent } = {}
for _, name in NAMES do
	remotes[name] = folder:WaitForChild(name) :: RemoteEvent
end

return remotes
