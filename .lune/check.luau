--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local run = require("./Run")

if not fs.isFile("globalTypes.d.luau") or not fs.isDir("Packages") then
	print("Project is not installed. Run rokit install, then lune run install.")
	process.exit(1)
end

run("stylua", { "src", ".lune" })
run("rojo", { "sourcemap", "default.project.json", "--output", "sourcemap.json" })
run("luau-lsp", {
	"analyze",
	"--settings=.vscode/settings.json",
	"--definitions=globalTypes.d.luau",
	"--sourcemap=sourcemap.json",
	"./src",
})
if not fs.isDir("build") then
	fs.writeDir("build")
end
run("rojo", { "build", "default.project.json", "--output", "build/code.rbxlx" })
