--!strict

local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local run = require("./Run")

local globalTypesUrl =
	"https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau"

if not fs.isFile("rokit.toml") then
	print("Run this from the project root: lune run install")
	process.exit(1)
end

if not fs.isFile("globalTypes.d.luau") then
	local response = net.request(globalTypesUrl)
	if not response.ok then
		print(`Downloading Roblox type definitions failed with status {response.statusCode}`)
		process.exit(1)
	end
	fs.writeFile("globalTypes.d.luau", response.body)
end

run("wally", { "install" })
run("rojo", { "sourcemap", "default.project.json", "--output", "sourcemap.json" })
run("wally-package-types", { "--sourcemap", "sourcemap.json", "Packages/" })
if fs.isDir("ServerPackages") then
	run("wally-package-types", { "--sourcemap", "sourcemap.json", "ServerPackages/" })
end
