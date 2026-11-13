--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local Checkouts = require("./Checkouts")
local run = require("./Run")

local env = Checkouts.Env()

local function has(program: string): boolean
	return process.exec("sh", { "-c", `command -v {program}` }, { env = env }).ok
end

if not fs.isFile("rokit.toml") then
	print("Run this from the project root: lune run sourcetools")
	process.exit(1)
end
if not has("cargo") then
	print(
		"cargo not found. Install Rust 1.90 or later (macOS: brew install rustup && rustup default stable)."
	)
	process.exit(1)
end
if not has("node") then
	print("node not found. Install Node 18 or later.")
	process.exit(1)
end

local home = Checkouts.Home()
if not fs.isDir(home) then
	fs.writeDir(home)
end

for _, tool in { "ree", "ror", "rur-native" } do
	local repo = Checkouts.Repos[tool]
	local tag = `v{Checkouts.PinnedVersion(tool)}`
	local path = `{home}/{repo}`
	if not fs.isDir(path) then
		run("git", {
			"clone",
			"--quiet",
			"--depth",
			"1",
			"--branch",
			tag,
			`https://github.com/Anime-Vanguards/{repo}.git`,
			path,
		})
	else
		run("git", { "-C", path, "fetch", "--quiet", "--depth", "1", "origin", "tag", tag })
		run("git", { "-C", path, "checkout", "--quiet", tag })
	end
	print(`{repo} at {tag}`)
end

run(
	Checkouts.Program("cargo"),
	{ "build", "--release", "--workspace", "--manifest-path", `{home}/roblox-engine-emulator/Cargo.toml` },
	env
)
run(
	Checkouts.Program("cargo"),
	{ "build", "--release", "--manifest-path", `{home}/roblox-object-renderer/Cargo.toml` },
	env
)
local npm = process.exec(
	"npm",
	{ "install", "--no-audit", "--no-fund" },
	{ cwd = `{home}/roblox-ui-renderer`, stdio = "forward", env = env }
)
if not npm.ok then
	print("npm install failed in roblox-ui-renderer")
	process.exit(1)
end
local native = process.exec(
	"node",
	{ "tools/native-app/build.mjs" },
	{ cwd = `{home}/roblox-ui-renderer`, stdio = "forward", env = env }
)
if not native.ok then
	print("Building rur's native engine failed")
	process.exit(1)
end
print(`Source tools ready in {home}`)
