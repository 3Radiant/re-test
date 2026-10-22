--[[
	GunController (client)
	Input + stance state machine for guns.

	  Idle --click--> Ready --F--> Aiming --F--> Ready
	  Aiming + click = FIRE        click with 0 ammo (or R) = reload -> back to Idle

	Aiming is a movement LOCK (slow walk, no jump/sprint/crouch) and turns the
	character toward the mouse every frame. Stance is predicted locally and validated
	by the server, which is the authority on ammo and firing.

	Disabled automatically while you are a Titan.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AnimationConfigs = require(Shared.Configs.AnimationConfigs)
local GunConfigs = require(Shared.Configs.GunConfigs)
local GunStates = require(Shared.Gun.GunStates)
local Remotes = require(Shared.Remotes)

local CameraController = require(script.Parent.CameraController)
local CharacterController = require(script.Parent.CharacterController)
local Aim = require(script.Parent.Parent.Gun.Aim)
local BulletVisuals = require(script.Parent.Parent.Gun.BulletVisuals)

local player = Players.LocalPlayer
local Stance = GunStates.Stance

local GunController = {}

local active: any = nil -- { Tool, Config, Stance, Tracks, LastFire, Connections }
local mouseHeld = false
local bound = setmetatable({}, { __mode = "k" }) :: { [Instance]: boolean }

local STANCE_TRACKS = {
	[Stance.Idle] = "idle",
	[Stance.Ready] = "ready",
	[Stance.Aiming] = "aim",
}

function GunController.getActive(): any
	return active
end

----------------------------------------------------------------------
-- Aiming stance
----------------------------------------------------------------------

local function beginAiming()
	local gun = active
	if not gun then
		return
	end

	CharacterController.setLock("GunAiming", {
		WalkSpeed = gun.Config.AimWalkSpeed,
		NoJump = true,
		NoSprint = true,
		NoCrouch = true,
		NoAutoRotate = true,
	})
	CameraController.setAiming(true)

	-- Runs just after the character updates each frame
	RunService:BindToRenderStep("GunAimFace", Enum.RenderPriority.Character.Value + 2, function(dt)
		local character = CharacterController.getCharacter()
		local root = CharacterController.getRoot()
		if character and root then
			Aim.faceTarget(root, Aim.getMouseWorldPosition({ character }), dt, gun.Config.AimTurnSpeed)
		end
	end)
end

local function endAiming()
	RunService:UnbindFromRenderStep("GunAimFace")
	CharacterController.clearLock("GunAiming")
	CameraController.setAiming(false)
end

----------------------------------------------------------------------
-- Stance handling
----------------------------------------------------------------------

local function applyStance(newStance: string)
	local gun = active
	if not gun or gun.Stance == newStance then
		return
	end

	local old: string = gun.Stance
	gun.Stance = newStance

	local oldTrack = gun.Tracks[STANCE_TRACKS[old]]
	if oldTrack then
		oldTrack:Stop(0.15)
	end
	local newTrack = gun.Tracks[STANCE_TRACKS[newStance]]
	if newTrack then
		newTrack:Play(0.15)
	end

	if newStance == Stance.Aiming then
		beginAiming()
	elseif old == Stance.Aiming then
		endAiming()
	end
end

local function requestStance(newStance: string)
	local gun = active
	if not gun or gun.Tool:GetAttribute("Reloading") then
		return
	end
	if not GunStates.canTransition(gun.Stance, newStance) then
		return
	end
	applyStance(newStance)
	Remotes.GunSetStance:FireServer(gun.Tool, newStance)
end

local function requestReload()
	local gun = active
	if not gun or gun.Tool:GetAttribute("Reloading") then
		return
	end
	if (gun.Tool:GetAttribute("Ammo") or 0) >= gun.Config.Ammo then
		return
	end
	applyStance(Stance.Idle) -- reloading returns you to the normal stance
	Remotes.GunReload:FireServer(gun.Tool)
end

----------------------------------------------------------------------
-- Firing
----------------------------------------------------------------------

local function getMuzzlePosition(tool: Tool, root: BasePart): Vector3
	local handle = tool:FindFirstChild("Handle")
	local muzzle = handle and handle:FindFirstChild("Muzzle")
	if muzzle and muzzle:IsA("Attachment") then
		return muzzle.WorldPosition
	end
	return (root.CFrame * CFrame.new(0.5, 1.2, -2.5)).Position
end

local function fire()
	local gun = active
	local character = CharacterController.getCharacter()
	local root = CharacterController.getRoot()
	if not gun or not character or not root then
		return
	end
	if gun.Stance ~= Stance.Aiming or gun.Tool:GetAttribute("Reloading") then
		return
	end
	if (gun.Tool:GetAttribute("Ammo") or 0) <= 0 then
		requestReload()
		return
	end

	local now = os.clock()
	if now - gun.LastFire < 60 / gun.Config.RPM then
		return
	end
	gun.LastFire = now

	local origin = getMuzzlePosition(gun.Tool, root)
	local target = Aim.getMouseWorldPosition({ character })
	local direction = target - origin
	if direction.Magnitude < 1 then
		direction = root.CFrame.LookVector
	end
	direction = direction.Unit

	Remotes.GunFire:FireServer(gun.Tool, origin, direction)
	BulletVisuals.spawnBullet(origin, direction, gun.Config, character) -- instant local feedback

	if gun.Tracks.fire then
		gun.Tracks.fire:Play()
	end
	-- gun.Config.Recoil hook goes here
end

----------------------------------------------------------------------
-- Input
----------------------------------------------------------------------

local function onClick()
	local gun = active
	if not gun or gun.Tool:GetAttribute("Reloading") then
		return
	end

	if (gun.Tool:GetAttribute("Ammo") or 0) <= 0 then
		requestReload() -- clicking an empty gun reloads
		return
	end

	if gun.Stance == Stance.Idle then
		requestStance(Stance.Ready)
	elseif gun.Stance == Stance.Aiming then
		fire()
	end
	-- merely Ready: nothing, press F to aim
end

local function onToggleAim()
	local gun = active
	if not gun then
		return
	end
	if gun.Stance == Stance.Ready then
		requestStance(Stance.Aiming)
	elseif gun.Stance == Stance.Aiming then
		requestStance(Stance.Ready)
	end
	-- F while Idle does nothing: you must ready the gun first
end

----------------------------------------------------------------------
-- Equip / unequip
----------------------------------------------------------------------

local function teardownActive()
	local gun = active
	if not gun then
		return
	end
	if gun.Stance == Stance.Aiming then
		endAiming()
	end
	for _, track in gun.Tracks do
		track:Stop(0.1)
	end
	for _, connection in gun.Connections do
		connection:Disconnect()
	end
	active = nil
	mouseHeld = false
end

local function onEquipped(tool: Tool)
	local config = GunConfigs[tool:GetAttribute("GunId")]
	if not config or CharacterController.isTitan() or not CharacterController.getHumanoid() then
		return
	end

	-- Load this gun's animations (skipped silently if you haven't made them yet)
	local group = AnimationConfigs.Guns[config.AnimationGroup] or {}
	local tracks: { [string]: AnimationTrack } = {}
	for key, id in group do
		local oneShot = key == "fire" or key == "reload"
		local priority = if oneShot then Enum.AnimationPriority.Action2 else Enum.AnimationPriority.Action
		local track = CharacterController.loadAnimation(id, priority)
		if track then
			track.Looped = not oneShot
			tracks[key] = track
		end
	end

	local gun = {
		Tool = tool,
		Config = config,
		Stance = Stance.Idle,
		Tracks = tracks,
		LastFire = 0,
		Connections = {} :: { RBXScriptConnection },
	}
	active = gun

	if tracks.idle then
		tracks.idle:Play(0.15)
	end

	table.insert(
		gun.Connections,
		tool:GetAttributeChangedSignal("Reloading"):Connect(function()
			if tool:GetAttribute("Reloading") and tracks.reload then
				tracks.reload:Play()
			end
		end)
	)

	-- If the server forces us back to Idle (reload / reset), follow it. Other server
	-- values are ignored on purpose to avoid flicker from network lag.
	table.insert(
		gun.Connections,
		tool:GetAttributeChangedSignal("Stance"):Connect(function()
			if tool:GetAttribute("Stance") == Stance.Idle and gun.Stance ~= Stance.Idle then
				applyStance(Stance.Idle)
			end
		end)
	)
end

local function onUnequipped(tool: Tool)
	if active and active.Tool == tool then
		teardownActive()
	end
end

local function bindTool(tool: Instance)
	if not tool:IsA("Tool") or bound[tool] or tool:GetAttribute("GunId") == nil then
		return
	end
	bound[tool] = true

	tool.Equipped:Connect(function()
		onEquipped(tool)
	end)
	tool.Unequipped:Connect(function()
		onUnequipped(tool)
	end)

	if tool.Parent == player.Character then
		onEquipped(tool)
	end
end

local function watchCharacter(character: Model)
	teardownActive()
	if character:GetAttribute("IsTitan") then
		return -- Titans don't use guns
	end

	local backpack = player:WaitForChild("Backpack")
	for _, child in backpack:GetChildren() do
		bindTool(child)
	end
	backpack.ChildAdded:Connect(bindTool)

	for _, child in character:GetChildren() do
		bindTool(child)
	end
	character.ChildAdded:Connect(bindTool)
end

function GunController.start()
	BulletVisuals.start()

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not active then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			mouseHeld = true
			onClick()
		elseif input.KeyCode == Enum.KeyCode.F then
			onToggleAim()
		elseif input.KeyCode == Enum.KeyCode.R then
			requestReload()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			mouseHeld = false
		end
	end)

	-- "Auto" guns keep firing while you hold click in the aiming stance
	RunService.Heartbeat:Connect(function()
		if mouseHeld and active and active.Config.Type == "Auto" and active.Stance == Stance.Aiming then
			fire()
		end
	end)

	CharacterController.onCharacterChanged(watchCharacter)
end

return GunController
