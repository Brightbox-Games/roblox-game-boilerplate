--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lifecycle = require(ReplicatedStorage.Base.Lifecycle)

local controllers: { Lifecycle.System } = {
	require(script.Parent.Parent.Core.Sync.SyncController),
	require(script.Parent.Parent.Features.Game.AppController),
	require(script.Parent.Parent.Features.Admin.AdminController),
	require(script.Parent.Parent.Features.Debug.DebugController),
	require(script.Parent.Parent.Features.UI.UIController),
	require(script.Parent.ComponentController),
}

return controllers
