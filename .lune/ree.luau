--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local mounts = require("./Mounts")
local project = require("./Project")
local Checkouts = require("./Checkouts")
local run = require("./Run")

if not fs.isFile("rokit.toml") then
	print("Run this from the project root: lune run ree <ree arguments>")
	process.exit(1)
end

local args = table.clone(process.args)
if #args == 0 then
	print("Usage: lune run ree run --harness tests/Server/Boot.luau --run-context server")
	process.exit(1)
end

if args[1] == "profile" and (args[2] == "view" or args[2] == "render") then
	local checkout = Checkouts.Require("ree")
	table.remove(args, 1)
	run(`{checkout}/target/release/ree-profile-view`, args, Checkouts.Env())
	process.exit(0)
end

if args[1] == "run" or args[1] == "record" or (args[1] == "profile" and args[2] == "try") then
	local place = project.Selected()
	project.Sync(place)
	for _, arg in mounts(place) do
		table.insert(args, arg)
	end
end

run("ree", args)
