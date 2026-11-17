--!strict

-- Receives global Charm state from SyncService. Features register a setter in Init, with the
-- same key the server uses: controllers.SyncController:Add("Game.PlayerCount", setPlayerCount).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharmSync = require(ReplicatedStorage.Packages.CharmSync)
local Packets = require(ReplicatedStorage.Core.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

local SyncController = { Name = "SyncController" }

local keys: { [string]: boolean } = {}
local trove = Trove.new()

function SyncController.Add(_self: any, key: string, setter: (value: any) -> any)
	assert(not keys[key], `[SyncController] {key} is already registered`)
	keys[key] = true
	CharmSync.client.addSignals({ [key] = setter })
end

function SyncController.Init(_self: any, _controllers: { [string]: any }) end

function SyncController.Start(_self: any)
	trove:Connect(Packets.Sync.OnClientEvent, function(payloads: any)
		CharmSync.client.patch(payloads)
	end)
	-- Every controller's Init has run, so every key is registered before the first patch.
	Packets.SyncReady:Fire()
end

function SyncController.Destroy(_self: any)
	trove:Clean()
	CharmSync.client.removeAllSignals()
	table.clear(keys)
end

return SyncController
