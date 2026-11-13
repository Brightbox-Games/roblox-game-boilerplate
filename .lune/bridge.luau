--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local run = require("./Run")

if not fs.isFile("tools/studio-bridge.mjs") then
	print("Run this from the project root: lune run bridge")
	process.exit(1)
end

run("node", { "tools/studio-bridge.mjs" })
