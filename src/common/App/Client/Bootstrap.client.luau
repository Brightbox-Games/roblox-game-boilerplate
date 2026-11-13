--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packages = ReplicatedStorage:WaitForChild("Packages")
packages:WaitForChild("Trove")
require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("Data"):WaitForChild("PlayerData"))

local Lifecycle = require(ReplicatedStorage:WaitForChild("Base"):WaitForChild("Lifecycle"))
local controllers = require(script.Parent.Registry)
local runtime = Lifecycle.new(controllers)

script.Destroying:Connect(function()
	runtime:Destroy()
end)

runtime:Start()
script:SetAttribute("Ready", true)
