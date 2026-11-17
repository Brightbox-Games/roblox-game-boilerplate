--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Charm = require(ReplicatedStorage.Packages.Charm)
local GameConfig = require(ReplicatedStorage.Features.Game.GameConfig)
local Packets = require(ReplicatedStorage.Core.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

local getPlayerCount, setPlayerCount = Charm.signal(0)

local AppController = {
	Name = "AppController",
	-- Synced from GameService ("Game.PlayerCount"); read it in an effect or a Vide screen.
	PlayerCount = getPlayerCount :: Charm.Getter<number>,
}

local trove = Trove.new()

function AppController.Init(_self: any, controllers: { [string]: any })
	controllers.SyncController:Add("Game.PlayerCount", setPlayerCount)
end

function AppController.Start(_self: any)
	print(`[{GameConfig.Name}] Client controllers ready`)
	trove:Add(task.spawn(function()
		local sentAt = os.clock()
		local serverTime = Packets.Ping:Fire()
		if serverTime then
			print(`[{GameConfig.Name}] Packet round trip {math.round((os.clock() - sentAt) * 1000)} ms`)
		end
	end))
end

function AppController.Destroy(_self: any)
	trove:Clean()
end

return AppController
