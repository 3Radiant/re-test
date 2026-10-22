--[[
	Aim (client)
	Mouse -> world position, and turning the character toward it.
]]

local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local Aim = {}

local MAX_DISTANCE = 2000

-- Where in the world the mouse points (3D, so vertical aim works too)
function Aim.getMouseWorldPosition(ignore: { Instance }): Vector3
	local camera = Workspace.CurrentCamera :: Camera
	local mouse = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore

	local result = Workspace:Raycast(ray.Origin, ray.Direction * MAX_DISTANCE, params)
	if result then
		return result.Position
	end
	return ray.Origin + ray.Direction * MAX_DISTANCE
end

-- Smoothly yaw the root toward the target (horizontal only)
function Aim.faceTarget(root: BasePart, target: Vector3, dt: number, speed: number)
	local position = root.Position
	local flat = Vector3.new(target.X, position.Y, target.Z)
	if (flat - position).Magnitude < 1 then
		return
	end
	local goal = CFrame.lookAt(position, flat)
	root.CFrame = root.CFrame:Lerp(goal, 1 - math.exp(-speed * dt))
end

return Aim
