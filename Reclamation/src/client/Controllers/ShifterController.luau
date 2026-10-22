--[[
	ShifterController (client)
	  P            shift / turn back
	  Left click   Titan melee combo (server decides the combo step + damage)
	  Ability keys (e.g. Q = Harden) come from the Titan's config
	Also: locks movement during the transformation, plays the bite animation,
	plays swing animations, and applies knockback.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerState = require(Shared.PlayerState)
local Remotes = require(Shared.Remotes)
local TitanConfigs = require(Shared.Configs.TitanConfigs)

local CharacterController = require(script.Parent.CharacterController)

local player = Players.LocalPlayer

local ShifterController = {}

local swingConnection: RBXScriptConnection? = nil

local function isShifted(): boolean
	return PlayerState.get(player, "Shifted") == true
end

local function onInput(input: InputObject, processed: boolean)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.P then
		if not PlayerState.get(player, "Transforming") then
			Remotes.ShiftToggle:FireServer()
		end
		return
	end

	if not isShifted() or PlayerState.get(player, "Transforming") then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Remotes.TitanM1:FireServer()
		return
	end

	-- Titan abilities
	local character = CharacterController.getCharacter()
	local config = character and TitanConfigs[character:GetAttribute("TitanName")]
	if config and config.Abilities then
		for abilityName, ability in config.Abilities do
			if ability.Key == input.KeyCode then
				Remotes.TitanAbility:FireServer(abilityName)
			end
		end
	end
end

-- Play the right swing animation whenever the server advances the combo
local function watchTitan(character: Model)
	if swingConnection then
		swingConnection:Disconnect()
		swingConnection = nil
	end
	if not character:GetAttribute("IsTitan") then
		return
	end

	local config = TitanConfigs[character:GetAttribute("TitanName")]
	swingConnection = character:GetAttributeChangedSignal("AttackSerial"):Connect(function()
		local combo = character:GetAttribute("AttackCombo")
		local id = config and config.Animations and config.Animations.M1 and config.Animations.M1[combo]
		local track = id and CharacterController.loadAnimation(id, Enum.AnimationPriority.Action3)
		if track then
			track.Looped = false
			track:Play(0.05)
		end
	end)
end

function ShifterController.start()
	UserInputService.InputBegan:Connect(onInput)

	-- Mid-transformation: freeze and play the bite animation
	PlayerState.observe(player, "Transforming", function(transforming)
		if transforming then
			CharacterController.setLock("Transforming", {
				WalkSpeed = 0,
				NoJump = true,
				NoSprint = true,
				NoCrouch = true,
				NoAutoRotate = true,
			})
			if not isShifted() then
				CharacterController.playAction("bitehand")
			end
		else
			CharacterController.clearLock("Transforming")
		end
	end)

	CharacterController.onCharacterChanged(watchTitan)

	-- Hit by a Titan
	Remotes.Knockback.OnClientEvent:Connect(function(velocity)
		local root = CharacterController.getRoot()
		if root and typeof(velocity) == "Vector3" then
			root.AssemblyLinearVelocity = velocity
		end
	end)
end

return ShifterController
