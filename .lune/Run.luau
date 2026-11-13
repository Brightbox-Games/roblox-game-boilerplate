--!strict

local process = require("@lune/process")

local function run(program: string, args: { string })
	local result = process.exec(program, args, { stdio = "forward" })
	if not result.ok then
		print(`{program} {table.concat(args, " ")} failed with exit code {result.code}`)
		process.exit(1)
	end
end

return run
