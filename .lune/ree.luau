--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local mounts = require("./Mounts")
local run = require("./Run")

if not fs.isFile("default.project.json") then
	print("Run this from the project root: lune run ree <ree arguments>")
	process.exit(1)
end

local args = table.clone(process.args)
if #args == 0 then
	print("Usage: lune run ree run --harness tests/Server/Boot.luau --run-context server")
	process.exit(1)
end

if args[1] == "run" or args[1] == "record" then
	for _, arg in mounts() do
		table.insert(args, arg)
	end
end

run("ree", args)
