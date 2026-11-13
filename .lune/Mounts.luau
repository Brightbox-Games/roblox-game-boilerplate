--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local function mountPath(node: { [string]: any }): string?
	local path = node["$path"]
	if type(path) == "table" then
		return path.optional
	end
	return path
end

local function collect(node: { [string]: any }, path: string, mounts: { string })
	local keys = {}
	for key, child in node do
		if string.sub(key, 1, 1) ~= "$" and type(child) == "table" then
			table.insert(keys, key)
		end
	end
	table.sort(keys)
	for _, key in keys do
		local child = node[key]
		local childPath = if path == "" then key else `{path}/{key}`
		local diskPath = mountPath(child)
		if diskPath and (fs.isFile(diskPath) or fs.isDir(diskPath)) then
			table.insert(mounts, "--mount")
			table.insert(mounts, `{childPath}={diskPath}`)
		end
		collect(child, childPath, mounts)
	end
end

local function mounts(place: string): { string }
	local project = serde.decode("json", fs.readFile(`{place}.test.project.json`))
	local result = {}
	collect(project.tree, "", result)
	return result
end

return mounts
