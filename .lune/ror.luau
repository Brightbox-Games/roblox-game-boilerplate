--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local Checkouts = require("./Checkouts")
local mounts = require("./Mounts")
local project = require("./Project")
local run = require("./Run")

if not fs.isFile("rokit.toml") then
	print("Run this from the project root: lune run ror <ror arguments>")
	process.exit(1)
end

local args = table.clone(process.args)
if #args == 0 then
	print("Usage: lune run ror render build/ror/Build.luau --views iso --out build/ror/Build")
	process.exit(1)
end

local scriptInput = false
for _, arg in args do
	if string.sub(arg, -5) == ".luau" then
		scriptInput = true
	end
end
if scriptInput and (args[1] == "render" or args[1] == "video" or args[1] == "cost") then
	local place = project.Selected()
	project.Sync(place)
	for _, arg in mounts(place) do
		table.insert(args, arg)
	end
end

run(Checkouts.Binary("ror"), args, Checkouts.Env())
