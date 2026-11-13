--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local project = require("./Project")
local run = require("./Run")

if not fs.isFile("globalTypes.d.luau") or not fs.isDir("Packages") then
	print("Project is not installed. Run rokit install, then lune run install.")
	process.exit(1)
end

local frozen = table.find(process.args, "--frozen") ~= nil

if frozen then
	run("stylua", { "--check", "src", ".lune", "tests" })
else
	run("stylua", { "src", ".lune", "tests" })
end

local emptyFolders = project.EmptyFolders("src")
if #emptyFolders > 0 then
	for _, path in emptyFolders do
		print(
			`{path} is empty. Delete it: Rogen maps empty folders, so the project files differ between clones.`
		)
	end
	process.exit(1)
end

project.Write()
if not frozen then
	run("rogen", { "write", "--quiet" })
end
local rogenCheck = process.exec("rogen", { "check", "--color", "never" }, { stdio = "forward" })
if not rogenCheck.ok then
	print(
		"rogen check failed. Fix each warning; if a project file is out of date, run lune run write and commit it."
	)
	process.exit(1)
end

if not fs.isDir("build") then
	fs.writeDir("build")
end
for _, place in project.Places() do
	print(`Checking place {place}`)
	project.Sourcemap(place)
	local files = project.SourceFiles("sourcemap.json")
	local analyze = {
		"analyze",
		"--settings=.vscode/settings.json",
		"--definitions=globalTypes.d.luau",
		"--sourcemap=sourcemap.json",
	}
	table.move(files, 1, #files, #analyze + 1, analyze)
	run("luau-lsp", analyze)
	local lint = { "lint", "--no-default-lints" }
	for _, file in files do
		if string.sub(file, 1, 4) == "src/" then
			table.insert(lint, file)
		end
	end
	run("lute", lint)
	run("rojo", { "build", `{place}.project.json`, "--output", `build/{place}.rbxlx` })
end
project.Sourcemap(project.DefaultPlace)
