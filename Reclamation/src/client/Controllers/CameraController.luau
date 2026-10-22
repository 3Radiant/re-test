--[[
	CameraController (client) - fully custom camera.

	Human mode : third person. Hold RIGHT MOUSE to look (cursor stays free so you can
	             aim at it). Scroll to zoom. Pulls in + shifts to the shoulder while aiming.
	Titan mode : mouse locked to centre, high camera scaled to the Titan's height, and
	             the Titan turns to face wherever the camera points.

	CharacterController switches modes when the character changes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Configs.Config)
local CameraConfig = GameConfig.Camera

local player = Players.LocalPlayer

local CameraController = {}

local mode = "Human"
local titanHeight = 45
local aiming = false
local yaw = 0
local pitch = math.rad(-12)
local zoom = CameraConfig.DefaultZoom
local shownZoom = zoom
local minZoom, maxZoom = CameraConfig.MinZoom, CameraConfig.MaxZoom
local rightMouseHeld = false

local baseFov = GameConfig.FovWalk
local lastTargetFov: number? = nil

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

local function getRoot(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

function CameraController.setMode(newMode: string, height: number?)
	mode = newMode
	if mode == "Titan" then
		titanHeight = height or 45
		minZoom = titanHeight * CameraConfig.TitanZoomMinScale
		maxZoom = titanHeight * CameraConfig.TitanZoomMaxScale
		zoom = (minZoom + maxZoom) / 2
		pitch = math.rad(-30)
	else
		minZoom, maxZoom = CameraConfig.MinZoom, CameraConfig.MaxZoom
		zoom = CameraConfig.DefaultZoom
		pitch = math.rad(-12)
	end
	shownZoom = zoom

	local root = getRoot()
	if root then
		yaw = select(2, root.CFrame:ToOrientation())
	end
end

function CameraController.setAiming(value: boolean)
	aiming = value
end

-- FOV the camera settles on when not aiming (CharacterController: 70 walking, 80 running)
function CameraController.setBaseFov(fov: number)
	baseFov = fov
end

function CameraController.getMode(): string
	return mode
end

----------------------------------------------------------------------
-- Frame update
----------------------------------------------------------------------

local function updateFov(camera: Camera)
	local target = aiming and CameraConfig.Aim.Fov or baseFov
	if target ~= lastTargetFov then
		lastTargetFov = target
		TweenService:Create(camera, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = target }):Play()
	end
end

local function update(dt: number)
	local camera = Workspace.CurrentCamera
	local root = getRoot()
	if not camera or not root then
		return
	end

	if camera.CameraType ~= Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Scriptable
	end

	-- Mouse behaviour
	if mode == "Titan" then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	elseif rightMouseHeld then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	-- Look
	local delta = UserInputService:GetMouseDelta()
	if mode == "Titan" or rightMouseHeld then
		yaw -= delta.X * CameraConfig.Sensitivity
		pitch = math.clamp(pitch - delta.Y * CameraConfig.Sensitivity, -CameraConfig.MaxPitch, CameraConfig.MaxPitch)
	end

	-- Where the camera orbits and how far back it sits
	local focusOffset: Vector3, shoulder: Vector3, targetZoom: number
	if mode == "Titan" then
		focusOffset = Vector3.new(0, titanHeight * CameraConfig.TitanHeadOffsetScale, 0)
		shoulder = Vector3.zero
		targetZoom = zoom
	elseif aiming then
		focusOffset = CameraConfig.HeadOffset
		shoulder = CameraConfig.Aim.Shoulder
		targetZoom = CameraConfig.Aim.Zoom
	else
		focusOffset = CameraConfig.HeadOffset
		shoulder = CameraConfig.Shoulder
		targetZoom = zoom
	end
	shownZoom += (targetZoom - shownZoom) * (1 - math.exp(-10 * dt))

	local focus = root.Position + focusOffset
	local rotation = CFrame.fromOrientation(pitch, yaw, 0)
	local desired = (CFrame.new(focus) * rotation * CFrame.new(shoulder.X, shoulder.Y, shownZoom)).Position

	-- Don't let walls put the camera inside geometry (human mode only)
	if mode == "Human" and player.Character then
		params.FilterDescendantsInstances = { player.Character }
		local toDesired = desired - focus
		local result = Workspace:Raycast(focus, toDesired, params)
		if result then
			desired = result.Position - toDesired.Unit * 0.3
		end
	end

	camera.CFrame = CFrame.new(desired) * rotation
	updateFov(camera)

	-- Titan turns to face where the camera is pointing
	if mode == "Titan" then
		local goal = CFrame.new(root.Position) * CFrame.fromOrientation(0, yaw, 0)
		root.CFrame = root.CFrame:Lerp(goal, 1 - math.exp(-14 * dt))
	end
end

----------------------------------------------------------------------

function CameraController.start()
	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			rightMouseHeld = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			rightMouseHeld = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.MouseWheel then
			return
		end
		local step = mode == "Titan" and titanHeight * 0.1 or 1
		zoom = math.clamp(zoom - input.Position.Z * step, minZoom, maxZoom)
	end)

	RunService:BindToRenderStep("ReclamationCamera", Enum.RenderPriority.Camera.Value, update)
end

return CameraController
