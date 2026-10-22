--[[
	HudController (client)
	A small debug-style HUD: ammo / stance for guns, Titan health bar, shift status.
	Replace with your real UI later.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerState = require(Shared.PlayerState)
local TitanConfigs = require(Shared.Configs.TitanConfigs)

local CharacterController = require(script.Parent.CharacterController)
local GunController = require(script.Parent.GunController)

local player = Players.LocalPlayer

local HudController = {}

function HudController.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ReclamationHud"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(1, 1)
	label.Position = UDim2.new(1, -20, 1, -20)
	label.Size = UDim2.fromOffset(340, 80)
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.BackgroundTransparency = 0.5
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Right
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 16
	label.Parent = gui

	local barBack = Instance.new("Frame")
	barBack.AnchorPoint = Vector2.new(0.5, 1)
	barBack.Position = UDim2.new(0.5, 0, 1, -24)
	barBack.Size = UDim2.fromOffset(420, 18)
	barBack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	barBack.Visible = false
	barBack.Parent = gui

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.fromScale(1, 1)
	barFill.BackgroundColor3 = Color3.fromRGB(190, 50, 50)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBack

	RunService.RenderStepped:Connect(function()
		local character = CharacterController.getCharacter()
		local humanoid = CharacterController.getHumanoid()
		if not character or not humanoid then
			return
		end

		if character:GetAttribute("IsTitan") then
			local config = TitanConfigs[character:GetAttribute("TitanName")]
			barBack.Visible = true
			barFill.Size = UDim2.fromScale(math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1), 1)

			local text = ("%s  |  P: turn back  |  LMB: attack"):format(config and config.DisplayName or "Titan")
			if config and config.Abilities then
				for name, ability in config.Abilities do
					text ..= ("  |  %s: %s"):format(ability.Key.Name, name)
				end
			end
			label.Text = text
			return
		end

		barBack.Visible = false
		local lines = {}

		local gun = GunController.getActive()
		if gun then
			local reloading = gun.Tool:GetAttribute("Reloading")
			table.insert(
				lines,
				("%s   %d / %d   %s"):format(
					gun.Config.DisplayName,
					gun.Tool:GetAttribute("Ammo") or 0,
					gun.Config.Ammo,
					if reloading then "RELOADING" else gun.Stance
				)
			)
		end

		local shifterName = PlayerState.get(player, "ShifterName")
		local config = TitanConfigs[shifterName]
		if config then
			local wait = math.max(0, PlayerState.get(player, "ShiftReadyAt") - Workspace:GetServerTimeNow())
			local status = if PlayerState.get(player, "Transforming")
				then "transforming..."
				elseif wait > 0 then ("ready in %ds"):format(math.ceil(wait))
				else "press P"
			table.insert(
				lines,
				("%s  |  shifts left: %d  |  %s"):format(config.DisplayName, PlayerState.get(player, "ShiftsLeft"), status)
			)
		end

		label.Text = table.concat(lines, "\n")
	end)
end

return HudController
