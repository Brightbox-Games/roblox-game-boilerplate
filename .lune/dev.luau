--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local task = require("@lune/task")
local project = require("./Project")

if not fs.isFile("rokit.toml") or not fs.isDir("Packages") then
	print("Run this from an installed project root: lune run install, then lune run dev")
	process.exit(1)
end

local place = process.args[1] or project.DefaultPlace
if table.find(project.Places(), place) == nil then
	print(`No place named {place}: expected {place}.rogen.json`)
	process.exit(1)
end
project.Sync(place)

local commands = {
	{
		name = "sourcemap",
		program = "rogen",
		args = { "sourcemap", project.TestName(place), "--watch", "--output", "sourcemap.json" },
	},
	{ name = "serve", program = "rogen", args = { "serve", place, "--address", "127.0.0.1" } },
}

local children: { process.ChildProcess } = {}
local stopped = false

local function pipe(name: string, reader: any)
	task.spawn(function()
		while true do
			local chunk = reader:read()
			if chunk == nil then
				break
			end
			for _, line in string.split(chunk, "\n") do
				if line ~= "" then
					print(`[{name}] {line}`)
				end
			end
		end
	end)
end

for _, command in commands do
	local child = process.create(command.program, command.args)
	table.insert(children, child)
	pipe(command.name, child.stdout)
	pipe(command.name, child.stderr)
	task.spawn(function()
		local status = child:status()
		if not stopped then
			stopped = true
			print(`[{command.name}] exited with code {status.code}; stopping the others`)
			for _, other in children do
				other:kill()
			end
			process.exit(status.code)
		end
	end)
end
