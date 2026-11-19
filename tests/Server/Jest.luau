--!strict

-- Runs every Jest spec under ReplicatedStorage.Tests. Jest needs debug.loadmodule, which ree enables
-- with --load-module (lune run test passes it for this harness).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function(_context: any)
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
