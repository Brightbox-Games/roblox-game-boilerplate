--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local run = require("./Run")

if not fs.isFile("asphalt.toml") then
	print("Run this from the project root: lune run assets")
	process.exit(1)
end

if string.match(fs.readFile("asphalt.toml"), "\nid%s*=%s*0%s*\n") then
	print("Set [creator] id in asphalt.toml to this game's Roblox group ID before syncing assets.")
	process.exit(1)
end

run("asphalt", { "sync", table.unpack(process.args) })
