--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Conch = require(ReplicatedStorage.Packages.Conch)
local isAdmin = require(ReplicatedStorage.Utils.IsAdmin)

local AdminService = { Name = "AdminService" }
local connections: { RBXScriptConnection } = {}

local function grant(player: Player)
	if isAdmin(player) then
		Conch.give_roles(Conch.get_user(player), "super-user")
	end
end

function AdminService.Start(_self: any)
	Conch.initiate_default_lifecycle()
	table.insert(connections, Players.PlayerAdded:Connect(grant))
	for _, player in Players:GetPlayers() do
		grant(player)
	end
end

function AdminService.Destroy(_self: any)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

return AdminService
