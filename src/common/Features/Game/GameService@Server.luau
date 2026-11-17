--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Charm = require(ReplicatedStorage.Packages.Charm)
local GameConfig = require(ReplicatedStorage.Features.Game.GameConfig)
local Packets = require(ReplicatedStorage.Core.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

local GameService = { Name = "GameService" }

local trove = Trove.new()
-- Example synced state: every client's Hud shows it. Replace with the game's own (round phase, timer).
local getPlayerCount, setPlayerCount = Charm.signal(0)

function GameService.Init(_self: any, services: { [string]: any })
	services.SyncService:Add("Game.PlayerCount", getPlayerCount)
end

function GameService.Start(_self: any)
	Packets.Ping.OnServerInvoke = function(_player: Player)
		return workspace:GetServerTimeNow()
	end
	local function count()
		setPlayerCount(#Players:GetPlayers())
	end
	trove:Connect(Players.PlayerAdded, count)
	-- PlayerRemoving fires while the player is still listed
	trove:Connect(Players.PlayerRemoving, function()
		task.defer(count)
	end)
	count()
	print(`[{GameConfig.Name}] Server services ready`)
end

function GameService.Destroy(_self: any)
	Packets.Ping.OnServerInvoke = nil
	trove:Clean()
end

return GameService
