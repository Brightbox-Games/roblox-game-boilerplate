--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local packetsStandIn = [[
local Signal = require(game:GetService("ReplicatedStorage").Packages.Signal)
return setmetatable({}, {
	__index = function(packets, name)
		local packet = {
			Name = name,
			Fire = function() return nil end,
			OnClientEvent = Signal.new(),
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

	local started, problem = pcall(runtime.Start, runtime)
	check("client lifecycle starts", started)
	if not started then
		print(`  {problem}`)
	end
	task.wait(0.5)
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	check("debug UI starts for admins", playerGui ~= nil and playerGui:FindFirstChild("Iris_Root") ~= nil)
	local hud = playerGui and playerGui:FindFirstChild("Hud")
	check("Hud screen mounts open", hud ~= nil and hud:IsA("ScreenGui") and hud.Enabled)
	local cashLine = hud and hud:FindFirstChild("Line1", true)
	local playersLine = hud and hud:FindFirstChild("Line2", true)
	check("Hud shows cash", cashLine ~= nil and cashLine:IsA("TextLabel") and cashLine.Text == "Cash: 0")
	check(
		"Hud shows player count",
		playersLine ~= nil and playersLine:IsA("TextLabel") and playersLine.Text == "Players: 0"
	)
	local registry: { [string]: any } = {}
	for _, controller in controllers do
		registry[controller.Name] = controller
	end
	registry.UIController:Close("Hud")
	check("UIController closes Hud", hud ~= nil and (hud :: ScreenGui).Enabled == false)
	check("client lifecycle destroys", pcall(runtime.Destroy, runtime))
	check("Hud is removed on destroy", hud ~= nil and hud.Parent == nil)
	print("@done")
end
