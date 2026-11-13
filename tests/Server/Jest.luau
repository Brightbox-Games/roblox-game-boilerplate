--!strict
--!nolint DeprecatedApi

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local dataModelServiceStandIn = [[
return function(service)
	if service == "CoreScriptSyncService" then
		return nil
	end
	local success, result = pcall(function()
		local instance = game:GetService(service)
		local _ = instance.Name
		return instance
	end)
	return success and result or nil
end
]]

local function loadModule(module: ModuleScript): (any, string?, (() -> ())?)
	local source = (module :: any).Source :: string
	source = string.gsub(source, "^export%s+type", "type")
	source = string.gsub(source, "\n(%s*)export%s+type", "\n%1type")
	local copy = Instance.new("ModuleScript")
	copy.Name = module.Name;
	(copy :: any).Source = "return function(...) " .. source .. "\nend"
	local ok, result = pcall(require, copy)
	if not ok then
		return nil, tostring(result), nil
	end
	setfenv(result, setmetatable({ script = module }, { __index = getfenv(result) }))
	return result, nil, function()
		copy:Destroy()
	end
end

return function(context: any)
	(debug :: any).loadmodule = loadModule
	local threadGlobals = getfenv(0) :: any
	if threadGlobals.warn == nil then
		threadGlobals.warn = warn
	end
	local shared = ReplicatedStorage.DevPackages._Index["roblox_roblox-shared@3.21.0"]["roblox-shared"]
	context.StandIn(shared.getDataModelService, dataModelServiceStandIn)

	local Jest = require(ReplicatedStorage.DevPackages.Jest) :: any
	local status, result = Jest.runCLI(ReplicatedStorage.Tests, {
		ci = true,
		runInBand = true,
		verbose = true,
	}, { ReplicatedStorage.Tests }):awaitStatus()

	if status ~= "Resolved" or type(result) ~= "table" then
		print(`FAIL Jest did not finish: {tostring(result)}`)
	else
		for _, suite in result.results.testResults do
			if suite.failureMessage and #suite.testResults == 0 then
				print(`FAIL {suite.testFilePath}: suite failed to run`)
			end
			for _, test in suite.testResults do
				print(`{if test.status == "passed" then "PASS" else "FAIL"} {test.fullName}`)
			end
		end
	end
	print("@done")
end
