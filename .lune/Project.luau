--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local run = require("./Run")

local defaultPlace = "game"
local testSuffix = ".test"

local testTree = {
	DevPackages = { ["$path"] = "DevPackages" },
	Tests = { ["$path"] = "tests" },
}

local function deepClone(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in value do
		copy[key] = deepClone(child)
	end
	return copy
end

local function withTests(config: { [string]: any }): { [string]: any }
	local result = deepClone(config)
	result.name = `{config.name} (tests)`
	result.servePort = nil
	result.servePlaceIds = nil
	result.tree.ReplicatedStorage = result.tree.ReplicatedStorage or {}
	for name, node in testTree do
		result.tree.ReplicatedStorage[name] = deepClone(node)
	end
	return result
end

local function places(): { string }
	local result = {}
	for _, name in fs.readDir(".") do
		local place = string.match(name, "^(.+)%.rogen%.json$")
		if place and string.sub(place, -#testSuffix) ~= testSuffix then
			table.insert(result, place)
		end
	end
	table.sort(result)
	return result
end

local function testName(place: string): string
	return `{place}{testSuffix}`
end

local function selected(): string
	local place = process.env.PLACE or defaultPlace
	if table.find(places(), place) == nil then
		print(`No place named {place}: expected {place}.rogen.json. Places: {table.concat(places(), ", ")}`)
		process.exit(1)
	end
	return place
end

local function write(): { string }
	local changed = {}
	for _, place in places() do
		local config = serde.decode("json", fs.readFile(`{place}.rogen.json`))
		local path = `{testName(place)}.rogen.json`
		local contents = serde.encode("json", withTests(config), true) .. "\n"
		if not fs.isFile(path) or fs.readFile(path) ~= contents then
			fs.writeFile(path, contents)
			table.insert(changed, path)
		end
	end
	table.sort(changed)
	return changed
end

local function emptyFolders(root: string): { string }
	local result = {}
	local function visit(path: string)
		local names = fs.readDir(path)
		if #names == 0 then
			table.insert(result, path)
			return
		end
		table.sort(names)
		for _, name in names do
			local child = `{path}/{name}`
			if fs.isDir(child) then
				visit(child)
			end
		end
	end
	visit(root)
	return result
end

local function sourcemap(place: string, output: string?)
	run("rojo", { "sourcemap", `{testName(place)}.project.json`, "--output", output or "sourcemap.json" })
end

local function sourceFiles(sourcemapPath: string): { string }
	local result = {}
	local function walk(node: { [string]: any })
		for _, path in node.filePaths or {} do
			local isLuau = string.sub(path, -5) == ".luau" or string.sub(path, -4) == ".lua"
			if isLuau and (string.sub(path, 1, 4) == "src/" or string.sub(path, 1, 6) == "tests/") then
				table.insert(result, path)
			end
		end
		for _, child in node.children or {} do
			walk(child)
		end
	end
	walk(serde.decode("json", fs.readFile(sourcemapPath)))
	table.sort(result)
	return result
end

local function sync(place: string?)
	write()
	run("rogen", { "write", "--quiet" })
	sourcemap(place or defaultPlace)
end

return {
	DefaultPlace = defaultPlace,
	Places = places,
	Selected = selected,
	TestName = testName,
	Write = write,
	EmptyFolders = emptyFolders,
	Sourcemap = sourcemap,
	SourceFiles = sourceFiles,
	Sync = sync,
}
