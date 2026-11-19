--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local mounts = require("./Mounts")
local project = require("./Project")

type Line = { kind: string, message: string }

local contexts = { Server = "server", Client = "client", Loopback = "loopback" }

-- extra ree flags for one harness
local harnessFlags: { [string]: { string } } = {
	["tests/Server/Jest.luau"] = { "--load-module" },
}

-- what the place's own scripts print once the server and client have booted and talked
local bootLines = { "Server services ready", "Client controllers ready", "Packet round trip" }

local function isKnownGap(output: { Line }, index: number): boolean
	local message = output[index].message
	local nextLine = output[index + 1]
	if message == "Scribe SUBSYSTEM_HOOK_ERROR" then
		return nextLine ~= nil and string.find(nextLine.message, "HasRobloxSubscription", 1, true) ~= nil
	end
	return string.find(message, "conch-ui.src.components.ui.executor:257", 1, true) ~= nil
end

local function runRee(place: string, label: string, args: { string }): ({ Line }?, string?)
	for _, arg in mounts(place) do
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
		print(`FAIL {place} {label}: ree printed no report\n{result.stdout}{result.stderr}`)
		return nil, nil
	end
	return report.output or {}, report.status
end

-- false when a line is a FAIL or an error the emulator does not explain
local function checkLines(output: { Line }): boolean
	local passed = true
	for index, line in output do
		if string.sub(line.message, 1, 5) == "FAIL " then
			passed = false
			print(`  {line.message}`)
		elseif line.kind == "error" and not isKnownGap(output, index) then
			passed = false
			print(`  error: {line.message}`)
		end
	end
	return passed
end

local function runHarness(place: string, path: string, context: string): boolean
	local args = { "run", "--harness", path, "--run-context", context, "--seconds", "30" }
	for _, flag in harnessFlags[path] or {} do
		table.insert(args, flag)
	end
	local output, status = runRee(place, path, args)
	if not output then
		return false
	end
	local passed = status == "ok" and checkLines(output)
	local done = false
	for _, line in output do
		done = done or line.message == "@done"
	end
	if not done then
		passed = false
		print(`  {path} did not reach @done (status {status})`)
	end
	print(`{if passed then "PASS" else "FAIL"} {place} {path}`)
	return passed
end

-- The place's own Bootstrap scripts on a server and its client (no harness)
local function runPlaceScripts(place: string): boolean
	local label = "place scripts (loopback)"
	local output, status = runRee(place, label, { "run", "--run-context", "loopback", "--seconds", "5" })
	if not output then
		return false
	end
	local passed = status == "ok" and checkLines(output)
	for _, expected in bootLines do
		local seen = false
		for _, line in output do
			seen = seen or string.find(line.message, expected, 1, true) ~= nil
		end
		if not seen then
			passed = false
			print(`  never printed "{expected}"`)
		end
	end
	print(`{if passed then "PASS" else "FAIL"} {place} {label}`)
	return passed
end

if not fs.isDir("tests") then
	print("Run this from the project root: lune run test")
	process.exit(1)
end

project.Sync()

local failures = 0
for _, place in project.Places() do
	if not runPlaceScripts(place) then
		failures += 1
	end
	for folder, context in contexts do
		local directory = `tests/{folder}`
		if fs.isDir(directory) then
			local names = fs.readDir(directory)
			table.sort(names)
			for _, name in names do
				if
					string.sub(name, -5) == ".luau" and not runHarness(place, `{directory}/{name}`, context)
				then
					failures += 1
				end
			end
		end
	end
end

if failures > 0 then
	print(`{failures} harness(es) failed`)
	process.exit(1)
end
print("All harnesses passed")
