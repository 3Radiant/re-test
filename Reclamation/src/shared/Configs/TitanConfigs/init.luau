-- Collects every Titan config in this folder: TitanConfigs.ArmoredTitan, ...
local configs: { [string]: any } = {}
for _, module in script:GetChildren() do
	if module:IsA("ModuleScript") then
		configs[module.Name] = require(module)
	end
end
return configs
