--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lifecycle = require(ReplicatedStorage.Lifecycle)

local controllers: { Lifecycle.System } = {
	require(script.Parent.Controllers.AppController),
	require(script.Parent.Controllers.AdminController),
	require(script.Parent.Controllers.DebugController),
	require(script.Parent.Controllers.UIController),
	require(script.Parent.Controllers.ComponentController),
}

return controllers
