--[[
	PlayerService (server)
	Joins, spawns and loadouts.

	Studio only: type  /titan AttackTitan  (or ArmoredTitan / FemaleTitan) in chat
	to change which Titan you wield (only while in human form).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Configs.Config)

local GunService = require(script.Parent.GunService)
local ShifterService = require(script.Parent.ShifterService)

local PlayerService = {}

local function onCharacterAdded(player: Player, character: Model)
	-- Shifting reassigns Player.Character (to the Titan, then back to the ORIGINAL
	-- human). Only give a loadout to a fresh human body, never to those.
	if character:GetAttribute("IsTitan") or character:GetAttribute("LoadoutGiven") then
		return
	end
	character:SetAttribute("LoadoutGiven", true)
	GunService.giveGun(player, "Kar98k")
end

local function onPlayerAdded(player: Player)
	ShifterService.assign(player, GameConfig.Shifting.DefaultTitan)

	player.CharacterAdded:Connect(function(character)
		task.spawn(onCharacterAdded, player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end

	if RunService:IsStudio() then
		player.Chatted:Connect(function(message)
			local name = message:match("^/titan%s+(%w+)")
			if name then
				ShifterService.assign(player, name)
			end
		end)
	end
end

function PlayerService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		ShifterService.remove(player)
	end)
end

return PlayerService
