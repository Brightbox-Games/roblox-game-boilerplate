--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local EditorOnly = require(ServerScriptService.Platform.EditorOnly)

EditorOnly.Strip()

local Lifecycle = require(ReplicatedStorage:WaitForChild("Base"):WaitForChild("Lifecycle"))
local services = require(script.Parent.Registry)
local runtime = Lifecycle.new(services)

game:BindToClose(function()
	runtime:Destroy()
end)

runtime:Start()
script:SetAttribute("Ready", true)
