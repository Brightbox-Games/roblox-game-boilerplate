--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local run = require("./Run")

if not fs.isFile("globalTypes.d.luau") or not fs.isDir("Packages") then
	print("Project is not installed. Run rokit install, then lune run install.")
	process.exit(1)
end

run("stylua", { "src", ".lune", "tests" })
run("rojo", { "sourcemap", "test.project.json", "--output", "sourcemap.json" })
run("luau-lsp", {
	"analyze",
	"--settings=.vscode/settings.json",
	"--definitions=globalTypes.d.luau",
	"--sourcemap=sourcemap.json",
	"./src",
	"./tests",
})
if not fs.isDir("build") then
	fs.writeDir("build")
end
run("rojo", { "build", "default.project.json", "--output", "build/code.rbxlx" })
