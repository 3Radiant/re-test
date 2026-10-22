--[[
	ShifterService (server)
	One shifter object PER PLAYER (no shared singleton), plus the remotes that drive
	them: ShiftToggle, TitanM1, TitanAbility. Also runs Titan regeneration.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerState = require(Shared.PlayerState)
local Remotes = require(Shared.Remotes)
local TitanConfigs = require(Shared.Configs.TitanConfigs)

local ShifterFolder = script.Parent.Parent:WaitForChild("Shifter")
local ShifterBase = require(ShifterFolder.ShifterBase)
local DamageService = require(script.Parent.DamageService)

-- Titan-specific subclasses (Shifter/Titans/<TitanName>). Titans without one use ShifterBase.
local TitanClasses: { [string]: any } = {}
for _, module in ShifterFolder.Titans:GetChildren() do
	if module:IsA("ModuleScript") then
		TitanClasses[module.Name] = require(module)
	end
end

local ShifterService = {}

local shifters: { [Player]: any } = {}

function ShifterService.get(player: Player): any
	return shifters[player]
end

-- Choose which Titan a player wields. Not allowed mid-transformation / while shifted.
function ShifterService.assign(player: Player, titanName: string): boolean
	if not TitanConfigs[titanName] then
		warn("[ShifterService] Unknown Titan:", titanName)
		return false
	end
	local existing = shifters[player]
	if existing and (existing.Shifted or existing.Transforming) then
		return false
	end

	local class = TitanClasses[titanName] or ShifterBase
	shifters[player] = class.new(player, titanName)
	PlayerState.set(player, "ShifterName", titanName)
	PlayerState.set(player, "ShiftsLeft", shifters[player].MaxShifts)
	return true
end

function ShifterService.remove(player: Player)
	local shifter = shifters[player]
	if shifter then
		shifter:Destroy()
		shifters[player] = nil
	end
end

function ShifterService.start()
	local stored = ServerStorage:FindFirstChild("StoredCharacters")
	if not stored then
		stored = Instance.new("Folder")
		stored.Name = "StoredCharacters"
		stored.Parent = ServerStorage
	end

	-- A defeated Titan sends its wielder back to human form
	DamageService.onTitanDefeated = function(owner: Player?)
		local shifter = owner and shifters[owner]
		if shifter then
			shifter:Deshift("Defeated")
		end
	end

	Remotes.ShiftToggle.OnServerEvent:Connect(function(player)
		local shifter = shifters[player]
		if not shifter then
			return
		end
		if shifter.Shifted then
			shifter:Deshift("Manual")
		else
			task.spawn(shifter.Shift, shifter) -- yields (bite animation), so don't block
		end
	end)

	Remotes.TitanM1.OnServerEvent:Connect(function(player)
		local shifter = shifters[player]
		if shifter then
			shifter:M1()
		end
	end)

	Remotes.TitanAbility.OnServerEvent:Connect(function(player, abilityName)
		local shifter = shifters[player]
		if shifter and typeof(abilityName) == "string" then
			shifter:UseAbility(abilityName)
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		for _, shifter in shifters do
			if shifter.Shifted then
				shifter:Tick(dt)
			end
		end
	end)
end

return ShifterService
