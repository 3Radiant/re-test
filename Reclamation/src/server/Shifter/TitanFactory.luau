--[[
	TitanFactory (server)
	Builds the Titan model for a shifter.

	1. If ServerStorage/Titans/<TitanName> exists (put real models in assets/titans/),
	   it's cloned and used as-is.
	2. Otherwise a PLACEHOLDER is built: an R15 rig from a HumanoidDescription,
	   recoloured and scaled to the canon height (config.HeightMeters * StudsPerMeter),
	   plus an invisible "Nape" weak-point part welded behind the neck.

	Custom models need: a Humanoid, a HumanoidRootPart (set as PrimaryPart) and
	ideally a part named "Nape". An Animator is added if missing.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Configs.Config)
local TitanConfigs = require(Shared.Configs.TitanConfigs)

local TitanFactory = {}

-- Very crude model used only if the R15 builder fails (no animations)
local function buildFallback(name: string): Model
	local model = Instance.new("Model")
	model.Name = name

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.Parent = model

	local body = Instance.new("Part")
	body.Name = "UpperTorso"
	body.Size = Vector3.new(2, 3, 1)
	body.CFrame = root.CFrame * CFrame.new(0, 1, 0)
	body.Parent = model
	local weld = Instance.new("Weld")
	weld.Part0, weld.Part1, weld.C0 = root, body, CFrame.new(0, 1, 0)
	weld.Parent = body

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.5, 1.5, 1.5)
	head.CFrame = root.CFrame * CFrame.new(0, 3, 0)
	head.Parent = model
	local headWeld = Instance.new("Weld")
	headWeld.Part0, headWeld.Part1, headWeld.C0 = root, head, CFrame.new(0, 3, 0)
	headWeld.Parent = head

	local humanoid = Instance.new("Humanoid")
	humanoid.HipHeight = 2
	humanoid.Parent = model
	model.PrimaryPart = root
	return model
end

local function buildPlaceholder(config: any, name: string): Model
	local description = Instance.new("HumanoidDescription")
	description.Face = 0
	description.HeadColor = config.SkinColor
	description.TorsoColor = config.SkinColor
	description.LeftArmColor = config.SkinColor
	description.RightArmColor = config.SkinColor
	description.LeftLegColor = config.SkinColor
	description.RightLegColor = config.SkinColor

	local ok, built = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	local model: Model
	if ok and built then
		model = built
	else
		warn("[TitanFactory] R15 builder failed, using crude fallback:", built)
		model = buildFallback(name)
	end

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			if descendant.Name ~= "HumanoidRootPart" then
				descendant.Color = config.SkinColor
				descendant.Material = config.Material
			end
		elseif descendant:IsA("Decal") or descendant:IsA("BaseScript") then
			descendant:Destroy() -- face decal / any default scripts
		end
	end

	-- Nape weak point, welded behind the neck (model faces -Z, so back is +Z)
	local anchor = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or model.PrimaryPart
	assert(anchor and anchor:IsA("BasePart"), "Titan placeholder has no torso")
	local nape = Instance.new("Part")
	nape.Name = "Nape"
	nape.Size = Vector3.new(1.4, 1.1, 0.8)
	nape.Transparency = 1
	nape.CanCollide = false
	nape.Massless = true
	nape.CFrame = anchor.CFrame * CFrame.new(0, 0.7, 0.5)
	local weld = Instance.new("Weld") -- Weld (not WeldConstraint) so ScaleTo scales the offset
	weld.Part0 = anchor
	weld.Part1 = nape
	weld.C0 = CFrame.new(0, 0.7, 0.5)
	weld.Parent = nape
	nape.Parent = model

	return model
end

-- Returns a Titan Model (not parented). Yields.
function TitanFactory.create(titanName: string, player: Player): Model
	local config = TitanConfigs[titanName]
	assert(config, "Unknown Titan: " .. tostring(titanName))

	local titansFolder = ServerStorage:FindFirstChild("Titans")
	local template = titansFolder and titansFolder:FindFirstChild(titanName)
	local model: Model
	if template and template:IsA("Model") then
		model = template:Clone()
	else
		model = buildPlaceholder(config, player.Name)
		local placeholderHumanoid = model:FindFirstChildOfClass("Humanoid")
		if placeholderHumanoid then
			placeholderHumanoid.AutomaticScalingEnabled = false
		end
		local targetHeight = config.HeightMeters * GameConfig.StudsPerMeter
		model:ScaleTo(targetHeight / model:GetExtentsSize().Y)
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	assert(humanoid and model.PrimaryPart, "Titan model needs a Humanoid and a PrimaryPart (HumanoidRootPart)")

	if not humanoid:FindFirstChildOfClass("Animator") then
		Instance.new("Animator").Parent = humanoid -- created on the server so animations replicate
	end
	humanoid.MaxHealth = config.MaxHealth
	humanoid.Health = config.MaxHealth
	humanoid.WalkSpeed = config.WalkSpeed
	humanoid.UseJumpPower = false
	humanoid.JumpHeight = config.JumpHeight
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.BreakJointsOnDeath = false

	if not model:FindFirstChild("Nape", true) then
		warn("[TitanFactory] " .. titanName .. " has no part named 'Nape' - nape hits won't register")
	end

	model.Name = player.Name
	model:SetAttribute("IsTitan", true)
	model:SetAttribute("TitanName", titanName)
	model:SetAttribute("TitanHeight", model:GetExtentsSize().Y)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("LastDamaged", 0)
	model:SetAttribute("DamageMultiplier", 1)
	return model
end

return TitanFactory
