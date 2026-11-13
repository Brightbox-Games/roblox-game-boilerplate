--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Conch = require(ReplicatedStorage.Packages.Conch)
local Trove = require(ReplicatedStorage.Packages.Trove)
local isAdmin = require(ReplicatedStorage.Utils.IsAdmin)

local AdminService = { Name = "AdminService" }
local trove = Trove.new()

local function grant(player: Player)
	if isAdmin(player) then
		Conch.give_roles(Conch.get_user(player), "super-user")
	end
end

function AdminService.Start(_self: any)
	Conch.initiate_default_lifecycle()
	trove:Connect(Players.PlayerAdded, grant)
	for _, player in Players:GetPlayers() do
		grant(player)
	end
end

function AdminService.Destroy(_self: any)
	trove:Clean()
end

return AdminService
