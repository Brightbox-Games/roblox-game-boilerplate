--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AdminConfig = require(ReplicatedStorage.Config.AdminConfig)

local function isAdmin(player: Player): boolean
	if AdminConfig.AdminsInStudio and RunService:IsStudio() then
		return true
	end
	return table.find(AdminConfig.UserIds, player.UserId) ~= nil
end

return isAdmin
