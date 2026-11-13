--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lifecycle = require(ReplicatedStorage.Lifecycle)

local services: { Lifecycle.System } = {
	require(script.Parent.Services.DataService),
	require(script.Parent.Services.GameService),
	require(script.Parent.Services.AdminService),
	require(script.Parent.Services.ComponentService),
}

return services
