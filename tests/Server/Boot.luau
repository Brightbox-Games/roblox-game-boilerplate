--!strict

local DataStoreService = game:GetService("DataStoreService")
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
	local Packets = require(ReplicatedStorage.Core.Packets)
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
	player.UserId = 4242
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

	local leaderstats = player:FindFirstChild("leaderstats")
	local wins = leaderstats and leaderstats:FindFirstChild("Wins")
	check("player list shows Wins", wins ~= nil and wins:IsA("NumberValue") and wins.Value == 0)
	if data then
		data.Wins.Increment(1)
	end
	check(
		"player list follows Wins",
		waitUntil(function()
			return wins ~= nil and (wins :: NumberValue).Value == 1
		end, 2)
	)

	check(
		"TopWins board writes the score",
		waitUntil(function()
			local status = PlayerData.Server.GetLeaderboardStatus("TopWins")
			return status ~= nil and status.LastWriteAt ~= nil
		end, 10)
	)
	-- Studio (and ree) use LB_Studio_<board>, never the live LB_<board>
	local board = DataStoreService:GetOrderedDataStore("LB_Studio_TopWins")
	check("TopWins score is in the Studio store", board:GetAsync("4242") == 1)
	check(
		"live TopWins store is untouched",
		DataStoreService:GetOrderedDataStore("LB_TopWins"):GetAsync("4242") == nil
	)

	player.Parent = nil
	check("PlayerReleasing fires with final data", waitUntil(function()
		return releasedCash ~= nil
	end, 5) and releasedCash == 25)
	check("PlayerData.Get is nil after leaving", PlayerData.Get(player) == nil)

	check("server lifecycle destroys", pcall(runtime.Destroy, runtime))
	print("@done")
end
