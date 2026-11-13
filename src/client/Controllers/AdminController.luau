--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Conch = require(ReplicatedStorage.Packages.Conch)
local ConchUi = require(ReplicatedStorage.Packages.ConchUi)
local isAdmin = require(ReplicatedStorage.Utils.IsAdmin)

local AdminController = { Name = "AdminController" }

function AdminController.Start(_self: any)
	task.spawn(function()
		Conch.initiate_default_lifecycle()
		if isAdmin(Players.LocalPlayer) then
			ConchUi.bind_to(Enum.KeyCode.F4)
		end
	end)
end

return AdminController
