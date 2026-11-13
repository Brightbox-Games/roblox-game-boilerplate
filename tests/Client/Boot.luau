--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local packetsStandIn = [[
return setmetatable({}, {
	__index = function(packets, name)
		local packet = {
			Name = name,
			Fire = function() return nil end,
			OnClientEvent = { Connect = function() return { Disconnect = function() end } end },
		}
		rawset(packets, name, packet)
		return packet
	end,
})
]]

local function check(label: string, passed: boolean)
	print(if passed then `PASS {label}` else `FAIL {label}`)
end

local function remotes(name: string, remoteNames: { string })
	local folder = Instance.new("Folder")
	folder.Name = name
	for _, remoteName in remoteNames do
		local remote = Instance.new("RemoteEvent")
		remote.Name = remoteName
		remote.Parent = folder
	end
	folder.Parent = ReplicatedStorage
end

return function(context: any)
	context.StandIn(ReplicatedStorage.Core.Packets, packetsStandIn)
	remotes("ScribeTransport", { "Down", "Up" })
	remotes("conch_networking", {
		"invoke_server_command",
		"create_user",
		"update_user_roles",
		"update_role_permissions",
		"register_command",
		"log",
		"log_command",
		"ready",
	})

	require(ReplicatedStorage.Core.Data.PlayerData)
	local Lifecycle = require(ReplicatedStorage.Base.Lifecycle)
	local controllers = require(StarterPlayer.StarterPlayerScripts.App.Registry)
	local runtime = Lifecycle.new(controllers)

	check("client lifecycle starts", pcall(runtime.Start, runtime))
	task.wait(0.5)
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	check("debug UI starts for admins", playerGui ~= nil and playerGui:FindFirstChild("Iris_Root") ~= nil)
	check("client lifecycle destroys", pcall(runtime.Destroy, runtime))
	print("@done")
end
