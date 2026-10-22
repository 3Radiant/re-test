--[[
	CharacterController (client)
	Movement states (Idle / Walking / Running / Crouching), movement animations, and
	a LOCK system so other systems can restrict movement without fighting each other.

	  CharacterController.setLock("GunAiming", { WalkSpeed = 6, NoJump = true,
	      NoSprint = true, NoCrouch = true, NoAutoRotate = true })
	  CharacterController.clearLock("GunAiming")

	Lock fields: WalkSpeed (lowest wins), NoJump, NoSprint, NoCrouch, NoAutoRotate.

	Works for human AND Titan characters: it picks a movement profile from the
	character's "IsTitan" / "TitanName" attributes (set by the server).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AnimationConfigs = require(Shared.Configs.AnimationConfigs)
local GameConfig = require(Shared.Configs.Config)
local TitanConfigs = require(Shared.Configs.TitanConfigs)

local CameraController = require(script.Parent.CameraController)

local player = Players.LocalPlayer

local CharacterController = {}

local character: Model?
local humanoid: Humanoid?
local root: BasePart?
local animator: Animator?
local profile: any = nil
local state = "Idle"
local sprintHeld = false
local crouchHeld = false

local locks: { [string]: any } = {}
local tracks: { [string]: AnimationTrack } = {} -- base + named tracks for the current character
local cache: { [string]: AnimationTrack } = {} -- extra tracks loaded by other systems, keyed by animation id
local currentBase: string? = nil
local characterCallbacks: { (Model) -> () } = {}

----------------------------------------------------------------------
-- Animation helpers
----------------------------------------------------------------------

local function toAssetId(id: any): string?
	if id == nil or id == 0 or id == "" then
		return nil
	end
	local text = tostring(id)
	if text:find("rbxassetid://") then
		return text
	end
	return "rbxassetid://" .. text
end

local function loadTrack(id: any, priority: Enum.AnimationPriority?): AnimationTrack?
	local assetId = toAssetId(id)
	if not assetId or not animator then
		return nil
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = assetId
	local track = animator:LoadAnimation(animation)
	if priority then
		track.Priority = priority
	end
	return track
end

-- For other controllers (guns etc.). Cached per animation id for this character.
function CharacterController.loadAnimation(id: any, priority: Enum.AnimationPriority?): AnimationTrack?
	local assetId = toAssetId(id)
	if not assetId then
		return nil
	end
	if not cache[assetId] then
		local track = loadTrack(id, priority)
		if track then
			cache[assetId] = track
		end
	end
	return cache[assetId]
end

-- Plays one of the character's named tracks (e.g. "bitehand"). Returns the track.
function CharacterController.playAction(key: string): AnimationTrack?
	local track = tracks[key]
	if track then
		track:Play(0.1)
	end
	return track
end

local function playBase(key: string)
	if key == currentBase then
		return
	end
	local old = currentBase and tracks[currentBase]
	if old then
		old:Stop(GameConfig.AnimationFadeTime)
	end
	currentBase = key
	local new = tracks[key]
	if new and not new.IsPlaying then
		new:Play(GameConfig.AnimationFadeTime)
	end
end

local BASE_KEYS = { idle = true, walk = true, run = true, crouch = true, jump = true, fall = true }

local function loadAnimations()
	if not humanoid then
		return
	end
	local rigIds: { [string]: any } = if humanoid.RigType == Enum.HumanoidRigType.R6
		then AnimationConfigs.R6_Animations
		else AnimationConfigs.R15_Animations
	local ids = table.clone(rigIds)
	if profile.Animations then
		for key, id in profile.Animations do
			if type(id) == "number" or type(id) == "string" then
				ids[key] = id
			end
		end
	end

	for key, id in ids do
		local priority = if BASE_KEYS[key] then Enum.AnimationPriority.Movement else Enum.AnimationPriority.Action4
		local track = loadTrack(id, priority)
		if track then
			tracks[key] = track
		end
	end
end

----------------------------------------------------------------------
-- Locks
----------------------------------------------------------------------

function CharacterController.setLock(name: string, lock: any)
	locks[name] = lock
end

function CharacterController.clearLock(name: string)
	locks[name] = nil
end

local function mergeLocks()
	local merged = { NoJump = false, NoSprint = false, NoCrouch = false, NoAutoRotate = false, WalkSpeed = nil :: number? }
	for _, lock in locks do
		merged.NoJump = merged.NoJump or lock.NoJump == true
		merged.NoSprint = merged.NoSprint or lock.NoSprint == true
		merged.NoCrouch = merged.NoCrouch or lock.NoCrouch == true
		merged.NoAutoRotate = merged.NoAutoRotate or lock.NoAutoRotate == true
		if lock.WalkSpeed then
			merged.WalkSpeed = merged.WalkSpeed and math.min(merged.WalkSpeed, lock.WalkSpeed) or lock.WalkSpeed
		end
	end
	return merged
end

----------------------------------------------------------------------
-- Getters
----------------------------------------------------------------------

function CharacterController.getCharacter(): Model?
	return character
end
function CharacterController.getHumanoid(): Humanoid?
	return humanoid
end
function CharacterController.getRoot(): BasePart?
	return root
end
function CharacterController.getState(): string
	return state
end
function CharacterController.isTitan(): boolean
	return profile ~= nil and profile.IsTitan == true
end

-- cb(character) runs now (if a character exists) and on every character swap (incl. shifting)
function CharacterController.onCharacterChanged(callback: (Model) -> ())
	table.insert(characterCallbacks, callback)
	if character then
		task.spawn(callback, character)
	end
end

----------------------------------------------------------------------
-- Per-frame update
----------------------------------------------------------------------

local function update()
	if not humanoid or not humanoid.Parent or humanoid.Health <= 0 or not profile then
		return
	end

	local lock = mergeLocks()
	local moving = humanoid.MoveDirection.Magnitude > 0.05
	local canSprint = not lock.NoSprint
	local canCrouch = profile.CanCrouch and not lock.NoCrouch

	state = "Idle"
	if moving then
		if sprintHeld and canSprint and not (crouchHeld and canCrouch) then
			state = "Running"
		elseif crouchHeld and canCrouch then
			state = "Crouching"
		else
			state = "Walking"
		end
	end

	local speed: number = profile.Walk
	if state == "Running" then
		speed = profile.Run
	elseif state == "Crouching" then
		speed = profile.Crouch
	end
	if lock.WalkSpeed ~= nil then
		speed = lock.WalkSpeed
	end

	humanoid.WalkSpeed = speed
	humanoid.JumpHeight = if lock.NoJump then 0 else profile.JumpHeight
	humanoid.AutoRotate = not (lock.NoAutoRotate or profile.IsTitan)

	CameraController.setBaseFov(if state == "Running" then GameConfig.FovRun else GameConfig.FovWalk)

	-- Pick the animation
	local key = "idle"
	local humanoidState = humanoid:GetState()
	if humanoidState == Enum.HumanoidStateType.Freefall or humanoid.FloorMaterial == Enum.Material.Air then
		key = if humanoidState == Enum.HumanoidStateType.Jumping then "jump" else "fall"
	elseif moving then
		key = if state == "Running" then "run" elseif state == "Crouching" then "crouch" else "walk"
	end
	playBase(key)
end

----------------------------------------------------------------------
-- Character setup
----------------------------------------------------------------------

local function teardown()
	for _, track in tracks do
		track:Stop(0)
		track:Destroy()
	end
	for _, track in cache do
		track:Stop(0)
		track:Destroy()
	end
	table.clear(tracks)
	table.clear(cache)
	table.clear(locks)
	currentBase = nil
	character, humanoid, root, animator, profile = nil, nil, nil, nil, nil
end

local function setupCharacter(newCharacter: Model)
	teardown()

	local newHumanoid = newCharacter:WaitForChild("Humanoid", 10)
	local newRoot = newCharacter:WaitForChild("HumanoidRootPart", 10)
	if not newHumanoid or not newRoot or player.Character ~= newCharacter then
		return -- gone, or swapped again while we waited
	end
	if not newHumanoid:IsA("Humanoid") or not newRoot:IsA("BasePart") then
		return
	end

	character, humanoid, root = newCharacter, newHumanoid, newRoot
	local foundAnimator = newHumanoid:WaitForChild("Animator", 5)
	if foundAnimator and foundAnimator:IsA("Animator") then
		animator = foundAnimator
	else
		local created = Instance.new("Animator")
		created.Parent = newHumanoid
		animator = created
	end
	newHumanoid.UseJumpPower = false

	local isTitan = newCharacter:GetAttribute("IsTitan") == true
	if isTitan then
		local titanConfig = TitanConfigs[newCharacter:GetAttribute("TitanName")]
		profile = {
			IsTitan = true,
			CanCrouch = false,
			Walk = titanConfig.WalkSpeed,
			Run = titanConfig.RunSpeed,
			Crouch = titanConfig.WalkSpeed,
			JumpHeight = titanConfig.JumpHeight,
			Animations = titanConfig.Animations,
		}
	else
		local human = GameConfig.Movement.Human
		profile = {
			IsTitan = false,
			CanCrouch = true,
			Walk = human.Walk,
			Run = human.Run,
			Crouch = human.Crouch,
			JumpHeight = human.JumpHeight,
		}
	end

	loadAnimations()
	CameraController.setMode(if isTitan then "Titan" else "Human", newCharacter:GetAttribute("TitanHeight"))

	for _, callback in characterCallbacks do
		task.spawn(callback, newCharacter)
	end
end

function CharacterController.start()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftShift then
			sprintHeld = true
		elseif input.KeyCode == Enum.KeyCode.LeftControl then
			crouchHeld = true
		end
	end)
	-- No `processed` check on release, or a held key could get stuck
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift then
			sprintHeld = false
		elseif input.KeyCode == Enum.KeyCode.LeftControl then
			crouchHeld = false
		end
	end)

	player.CharacterAdded:Connect(setupCharacter)
	player.CharacterRemoving:Connect(function()
		teardown()
	end)
	if player.Character then
		task.spawn(setupCharacter, player.Character)
	end

	RunService.RenderStepped:Connect(update)
end

return CharacterController
