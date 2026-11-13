--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local mounts = require("./Mounts")

type Line = { kind: string, message: string }

local contexts = { Server = "server", Client = "client" }

local function isKnownGap(output: { Line }, index: number): boolean
	local message = output[index].message
	local nextLine = output[index + 1]
	if message == "Scribe SUBSYSTEM_HOOK_ERROR" then
		return nextLine ~= nil and string.find(nextLine.message, "HasRobloxSubscription", 1, true) ~= nil
	end
	return string.find(message, "conch-ui.src.components.ui.executor:257", 1, true) ~= nil
end

local function runHarness(path: string, context: string): boolean
	local args = { "run", "--harness", path, "--run-context", context, "--seconds", "30" }
	for _, arg in mounts() do
		table.insert(args, arg)
	end
	local result = process.exec("ree", args)
	local reportLine = nil
	for _, line in string.split(result.stdout, "\n") do
		if string.sub(line, 1, 1) == "{" then
			reportLine = line
		end
	end
	local ok, report = pcall(serde.decode, "json" :: "json", reportLine or "")
	if not ok or type(report) ~= "table" then
		print(`FAIL {path}: ree printed no report\n{result.stdout}{result.stderr}`)
		return false
	end
	local passed = report.status == "ok"
	local done = false
	local output: { Line } = report.output or {}
	for index, line in output do
		if line.message == "@done" then
			done = true
		elseif string.sub(line.message, 1, 5) == "FAIL " then
			passed = false
			print(`  {line.message}`)
		elseif line.kind == "error" and not isKnownGap(output, index) then
			passed = false
			print(`  error: {line.message}`)
		end
	end
	if not done then
		passed = false
		print(`  {path} did not reach @done (status {report.status})`)
	end
	print(`{if passed then "PASS" else "FAIL"} {path}`)
	return passed
end

if not fs.isDir("tests") then
	print("Run this from the project root: lune run test")
	process.exit(1)
end

local failures = 0
for folder, context in contexts do
	local directory = `tests/{folder}`
	if fs.isDir(directory) then
		local names = fs.readDir(directory)
		table.sort(names)
		for _, name in names do
			if string.sub(name, -5) == ".luau" and not runHarness(`{directory}/{name}`, context) then
				failures += 1
			end
		end
	end
end

if failures > 0 then
	print(`{failures} harness(es) failed`)
	process.exit(1)
end
print("All harnesses passed")
