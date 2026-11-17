--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Scribe = require(ReplicatedStorage.Packages.Scribe)

-- Each board is an OrderedDataStore named LB_<board> (LB_Studio_<board> in Studio, so play-tests
-- never rank on live boards). Renaming a board starts it empty.
-- Read on the server with PlayerData.Server.GetLeaderboard(name, count) and GetMyRank(player, name).
local Leaderboards: { [string]: Scribe.LeaderboardConfig } = {
	-- All-time wins
	TopWins = { Stat = "Wins", Limit = 100 },
	-- Wins earned today (UTC day); a periodic board writes one new store per day
	WinsDaily = { Stat = "Wins", Period = "Daily", Limit = 100 },
}

if RunService:IsStudio() then
	for name, board in Leaderboards do
		board.StoreName = `LB_Studio_{name}`
	end
end

return Leaderboards
