--!strict

-- Replicates global (not per-player) Charm state to every client through charm-sync.
-- Features register a getter in Init: services.SyncService:Add("Game.PlayerCount", getPlayerCount).
-- Per-player state belongs in Scribe (Core/Data), not here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharmSync = require(ReplicatedStorage.Packages.CharmSync)
local Packets = require(ReplicatedStorage.Core.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

local SyncService = { Name = "SyncService" }

-- charm-sync types its map as exactly `(() -> any) | {}`, which a typed getter table does not satisfy
local getters: { [string]: any } = {}
local ready: { [Player]: boolean } = {}
local trove = Trove.new()

function SyncService.Add(_self: any, key: string, getter: () -> any)
	assert(getters[key] == nil, `[SyncService] {key} is already registered`)
	getters[key] = getter
	for player in ready do
		CharmSync.server.addSignalsToClient(player, { [key] = getter })
	end
end

function SyncService.Init(_self: any, _services: { [string]: any }) end

function SyncService.Start(_self: any)
	-- Packet serializes tables key by key, so charm-sync's sparse-array workaround is not needed.
	CharmSync.config.fixArrays = false
	trove:Connect(Packets.SyncReady.OnServerEvent, function(player: Player)
		if ready[player] or player.Parent ~= Players then
			return
		end
		ready[player] = true
		CharmSync.server.addSignalsToClient(player, table.clone(getters))
	end)
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		if ready[player] then
			ready[player] = nil
			CharmSync.server.removeClient(player)
		end
	end)
	CharmSync.server.connect(function(player: Player, payloads: { CharmSync.SyncPayload })
		if ready[player] then
			Packets.Sync:FireClient(player, payloads)
		end
	end)
end

function SyncService.Destroy(_self: any)
	trove:Clean()
	CharmSync.server.reset()
	table.clear(ready)
	table.clear(getters)
end

return SyncService
