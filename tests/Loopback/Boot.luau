--!strict

-- A server and its client in one ree run (--run-context loopback): Packet, Scribe and Sync cross real
-- remotes. The server's checks print before the player joins; the client's after.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function check(label: string, passed: boolean)
	print(if passed then `PASS {label}` else `FAIL {label}`)
end

local function waitUntil(condition: () -> boolean, timeout: number): boolean
	local deadline = os.clock() + timeout
	while not condition() and os.clock() < deadline do
		task.wait(0.05)
	end
	return condition()
end

local function text(root: Instance?, name: string): string?
	local label = root and root:FindFirstChild(name, true)
	return if label and label:IsA("TextLabel") then label.Text else nil
end

local function server(context: any)
	local ServerScriptService = game:GetService("ServerScriptService")
	require(ServerScriptService.Platform.EditorOnly).Strip()
	local Lifecycle = require(ReplicatedStorage.Base.Lifecycle)
	local services = require(ServerScriptService.App.Registry)
	local runtime = Lifecycle.new(services)

	-- the player joins once the services have started, as on a live server
	context.HoldJoin()
	check("server lifecycle starts", pcall(runtime.Start, runtime))
	local registry: { [string]: any } = {}
	for _, system in services do
		registry[system.Name] = system
	end
	-- changes the client must see arrive through Scribe and the player list
	registry.DataService.PlayerLoaded:Connect(function(_player: Player, data: any)
		data.Cash.Increment(25)
		data.Wins.Increment(1)
	end)
	context.Join()
end

local function client(_context: any)
	local StarterPlayer = game:GetService("StarterPlayer")
	local PlayerData = require(ReplicatedStorage.Core.Data.PlayerData)
	local Packets = require(ReplicatedStorage.Core.Packets)
	local Lifecycle = require(ReplicatedStorage.Base.Lifecycle)
	local controllers = require(StarterPlayer.StarterPlayerScripts.App.Registry)
	local runtime = Lifecycle.new(controllers)

	local started, problem = pcall(runtime.Start, runtime)
	check("client lifecycle starts", started)
	if not started then
		print(`  {problem}`)
	end
	local registry: { [string]: any } = {}
	for _, controller in controllers do
		registry[controller.Name] = controller
	end

	local serverTime = Packets.Ping:Fire()
	check("Ping answers through Packet", type(serverTime) == "number")
	check(
		"Scribe sends the player's data",
		waitUntil(function()
			return PlayerData.Client.IsReady()
		end, 5)
	)
	check(
		"Sync sends the player count",
		waitUntil(function()
			return registry.AppController.PlayerCount() == 1
		end, 2)
	)

	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	check("debug UI starts for admins", playerGui ~= nil and playerGui:FindFirstChild("Iris_Root") ~= nil)
	local hud = playerGui and playerGui:FindFirstChild("Hud")
	check("Hud screen mounts open", hud ~= nil and hud:IsA("ScreenGui") and hud.Enabled)
	check(
		"Hud follows the server's cash",
		waitUntil(function()
			return text(hud, "Line1") == "Cash: 25"
		end, 2)
	)
	check("Hud shows the player count", text(hud, "Line2") == "Players: 1")
	check(
		"player list replicates Wins",
		waitUntil(function()
			local leaderstats = Players.LocalPlayer:FindFirstChild("leaderstats")
			local wins = leaderstats and leaderstats:FindFirstChild("Wins")
			return wins ~= nil and wins:IsA("NumberValue") and wins.Value == 1
		end, 2)
	)

	registry.UIController:Close("Hud")
	check("UIController closes Hud", hud ~= nil and (hud :: ScreenGui).Enabled == false)
	check("client lifecycle destroys", pcall(runtime.Destroy, runtime))
	check("Hud is removed on destroy", hud ~= nil and hud.Parent == nil)
	print("@done")
end

return {
	Server = server,
	Client = client,
}
