--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local mounts = require("./Mounts")
local project = require("./Project")
local Checkouts = require("./Checkouts")
local run = require("./Run")

if not fs.isFile("rokit.toml") then
	print("Run this from the project root: lune run rur <rur-native arguments>")
	process.exit(1)
end

local args = table.clone(process.args)
if #args == 0 then
	print("Usage: lune run rur render --module build/rur/Panel.luau --dir build/rur/Panel")
	process.exit(1)
end

if args[1] == "inspect" or args[1] == "diff" or args[1] == "compare" then
	local checkout = Checkouts.Require("rur-native")
	local script = if args[1] == "inspect" then "cli/inspect.mjs" else "cli/rur.mjs"
	if args[1] == "inspect" then
		table.remove(args, 1)
	end
	table.insert(args, 1, `{checkout}/{script}`)
	run("node", args, Checkouts.Env())
	process.exit(0)
end

if args[1] == "render" or args[1] == "sequence" then
	local place = project.Selected()
	project.Sync(place)
	for _, arg in mounts(place) do
		table.insert(args, arg)
	end
end

run("rur-native", args)
