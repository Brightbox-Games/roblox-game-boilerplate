--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerData = require(ReplicatedStorage.PlayerData)
local Signal = require(ReplicatedStorage.Packages.Signal)

local DataService = {
	Name = "DataService",
	PlayerLoaded = Signal.new() :: Signal.Signal<(Player, PlayerData.Data)>,
	PlayerReleasing = PlayerData.Leaving :: Signal.Signal<(Player, PlayerData.Data)>,
}

local connections: { RBXScriptConnection } = {}
local stopped = false

local function load(player: Player)
	local data, reason = PlayerData.Server.WaitForData(player)
	if not data then
		if reason ~= "player-left" and reason ~= "shutdown" then
			warn(`[DataService] No data for {player.Name}: {reason}`)
		end
		return
	end
	task.defer(function()
		if not stopped and player.Parent == Players then
			DataService.PlayerLoaded:Fire(player, data)
		end
	end)
end

function DataService.Init(_self: any, _services: { [string]: any }) end

function DataService.Start(_self: any)
	table.insert(connections, Players.PlayerAdded:Connect(load))
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end
end

function DataService.Destroy(_self: any)
	stopped = true
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

return DataService
