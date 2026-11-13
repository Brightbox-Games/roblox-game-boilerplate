--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local project = require("./Project")
local run = require("./Run")

if not fs.isFile("rokit.toml") then
	print("Run this from the project root: lune run write")
	process.exit(1)
end

for _, path in project.Write() do
	print(`Generated {path}`)
end
run("rogen", { "write", "--quiet" })
