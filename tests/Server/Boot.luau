--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local function check(label: string, passed: boolean)
	print(if passed then `PASS {label}` else `FAIL {label}`)
end

local function waitUntil(condition: () -> boolean, timeout: number): boolean
	local deadline = os.clock() + timeout
	while not condition() and os.clock() < deadline do
		task.wait(0.05)
	end
	return condition()
end

return function(_context: any)
	require(ServerScriptService.Platform.EditorOnly).Strip()
	local Lifecycle = require(ReplicatedStorage.Base.Lifecycle)
	local PlayerData = require(ReplicatedStorage.Core.Data.PlayerData)
	local Packets = require(ReplicatedStorage.Core.Net.Packets)
	local services = require(ServerScriptService.App.Registry)
	local runtime = Lifecycle.new(services)

	check("server lifecycle starts", pcall(runtime.Start, runtime))

	local registry: { [string]: any } = {}
	for _, system in services do
		registry[system.Name] = system
	end
	check("Ping is bound", Packets.Ping.OnServerInvoke ~= nil)
	check("admin console networking exists", ReplicatedStorage:FindFirstChild("conch_networking") ~= nil)

	local loadedCash: number? = nil
	local releasedCash: number? = nil
	registry.DataService.PlayerLoaded:Connect(function(_player: Player, data: PlayerData.Data)
		loadedCash = data.Cash.Get()
		data.Cash.Increment(25)
	end)
	registry.DataService.PlayerReleasing:Connect(function(_player: Player, data: PlayerData.Data)
		releasedCash = data.Cash.Get()
	end)

	local player = Instance.new("Player")
	player.Name = "Tester"
	player.Parent = Players

	check(
		"PlayerLoaded fires",
		waitUntil(function()
			return loadedCash ~= nil
		end, 5)
	)
	check("new player starts with 0 cash", loadedCash == 0)
	local data = PlayerData.Get(player)
	check("PlayerData.Get sees the write", data ~= nil and data.Cash.Get() == 25)

	player.Parent = nil
	check("PlayerReleasing fires with final data", waitUntil(function()
		return releasedCash ~= nil
	end, 5) and releasedCash == 25)
	check("PlayerData.Get is nil after leaving", PlayerData.Get(player) == nil)

	check("server lifecycle destroys", pcall(runtime.Destroy, runtime))
	print("@done")
end
