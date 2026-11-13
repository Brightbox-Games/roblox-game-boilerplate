--!strict

local process = require("@lune/process")

local function run(program: string, args: { string }, env: { [string]: string }?)
	local result = process.exec(program, args, { stdio = "forward", env = env })
	if not result.ok then
		print(`{program} {table.concat(args, " ")} failed with exit code {result.code}`)
		process.exit(1)
	end
end

return run
