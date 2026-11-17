--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Scribe = require(ReplicatedStorage.Packages.Scribe)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Leaderboards = require(script.Leaderboards)
local Products = require(script.Products)

local leaving = Signal.new() :: Signal.Signal<(Player, any)>

local bundle = Scribe({
	Template = {
		Cash = Scribe.Int(0, { Min = 0 }),
		Wins = Scribe.Int(0, { Min = 0 }),
	},
	ProfileStoreIndex = if RunService:IsStudio() then "PlayerData_Studio" else "PlayerData",
	ProfileKeyPrefix = "Player_",
	Products = Products,
	Leaderboards = Leaderboards,
	OnPlayerLeaving = function(player: Player, data: any)
		leaving:Fire(player, data)
	end,
})

export type Data = typeof(bundle.Server.Get((nil :: any) :: Player))

local function get(player: Player): Data?
	if bundle.Server.GetState(player) ~= "Ready" then
		return nil
	end
	return bundle.Server.Get(player)
end

return {
	Server = bundle.Server,
	Client = bundle.Client,
	Get = get,
	Leaving = leaving,
}
