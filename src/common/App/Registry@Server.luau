--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Lifecycle = require(ReplicatedStorage.Base.Lifecycle)

local services: { Lifecycle.System } = {
	require(ServerScriptService.Core.Data.DataService),
	require(ServerScriptService.Features.Game.GameService),
	require(ServerScriptService.Features.Admin.AdminService),
	require(script.Parent.ComponentService),
}

return services
