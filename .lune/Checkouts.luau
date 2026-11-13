--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")

local Checkouts = {}

Checkouts.Repos = {
	ree = "roblox-engine-emulator",
	ror = "roblox-object-renderer",
	["rur-native"] = "roblox-ui-renderer",
}

local rustupBin = "/opt/homebrew/opt/rustup/bin"
local studioContent = "/Applications/RobloxStudio.app/Contents/Resources/content"

function Checkouts.Home(): string
	return process.env.ANIME_VANGUARDS_HOME or `{process.env.HOME}/.local/share/anime-vanguards`
end

function Checkouts.Path(tool: string): string?
	local path = `{Checkouts.Home()}/{Checkouts.Repos[tool]}`
	return if fs.isDir(path) then path else nil
end

function Checkouts.Require(tool: string): string
	local path = Checkouts.Path(tool)
	if not path then
		print(`This needs the {Checkouts.Repos[tool]} source checkout. Run lune run sourcetools first.`)
		process.exit(1)
	end
	return path :: string
end

function Checkouts.PinnedVersion(tool: string): string
	local toml = fs.readFile("rokit.toml")
	local escaped = string.gsub(tool, "%p", "%%%0")
	local version = string.match(toml, `\n{escaped} = "[^@"]+@([^"]+)"`)
	assert(version, `{tool} is not pinned in rokit.toml`)
	return version
end

function Checkouts.Program(name: string): string
	local candidate = `{rustupBin}/{name}`
	return if fs.isFile(candidate) then candidate else name
end

function Checkouts.Env(): { [string]: string }
	local env: { [string]: string } = {}
	for key, value in process.env do
		env[key] = value
	end
	if fs.isDir(rustupBin) then
		env.PATH = `{rustupBin}:{process.env.PATH or ""}`
	end
	if not process.env.RUR_ROBLOX_CONTENT and fs.isDir(studioContent) then
		env.RUR_ROBLOX_CONTENT = studioContent
	end
	local ree = Checkouts.Path("ree")
	local rur = Checkouts.Path("rur-native")
	if ree then
		env.ROR_REE = ree
	end
	if rur then
		env.ROR_RUR = rur
	end
	env.ROR_STUDIO_MCP = process.env.ROR_STUDIO_MCP or `127.0.0.1:{process.env.STUDIO_BRIDGE_PORT or "58790"}`
	return env
end

return Checkouts
