-- Collects every gun config in this folder: GunConfigs.Kar98k, GunConfigs.Whatever
local configs: { [string]: any } = {}
for _, module in script:GetChildren() do
	if module:IsA("ModuleScript") then
		configs[module.Name] = require(module)
	end
end
return configs
