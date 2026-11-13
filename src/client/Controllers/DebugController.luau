--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Iris = require(ReplicatedStorage.Packages.Iris)
local PlayerData = require(ReplicatedStorage.PlayerData)
local isAdmin = require(ReplicatedStorage.Utils.IsAdmin)

local DebugController = { Name = "DebugController" }

local connections: { RBXScriptConnection } = {}
local stopIris: (() -> ())? = nil
local hasStarted = false

function DebugController.Start(_self: any)
	if not isAdmin(Players.LocalPlayer) then
		return
	end
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		warn("[DebugController] PlayerGui not found; debug UI disabled")
		return
	end
	hasStarted = true
	Iris.Init(playerGui, nil, false)

	local isOpen = Iris.State(false)
	local showDemo = Iris.State(false)
	local frameTime = 0

	table.insert(
		connections,
		RunService.RenderStepped:Connect(function(dt: number)
			frameTime = dt
		end)
	)
	table.insert(
		connections,
		UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
			if input.KeyCode == Enum.KeyCode.F3 and not processed then
				isOpen:set(not isOpen:get())
			end
		end)
	)

	stopIris = Iris:Connect(function()
		if isOpen:get() then
			Iris.Window({ "Debug" }, { isOpened = isOpen })
			Iris.Text({ `FPS: {if frameTime > 0 then math.round(1 / frameTime) else 0}` })
			Iris.Text({ `Cash: {PlayerData.Client.Cash.Get()}` })
			Iris.Checkbox({ "Show Iris demo" }, { isChecked = showDemo })
			Iris.End()
		end
		if showDemo:get() then
			Iris.ShowDemoWindow()
		end
	end)
end

function DebugController.Destroy(_self: any)
	if stopIris then
		stopIris()
		stopIris = nil
	end
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if hasStarted then
		Iris.Shutdown()
		hasStarted = false
	end
end

return DebugController
