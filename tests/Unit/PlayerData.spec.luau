--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local PlayerData = require(ReplicatedStorage.PlayerData)

local describe, it, expect = JestGlobals.describe, JestGlobals.it, JestGlobals.expect

describe("PlayerData", function()
	it("loads a new player with template defaults and saves writes", function()
		local player = Instance.new("Player")
		player.Name = "SpecPlayer"
		player.Parent = Players
		local data = PlayerData.Server.WaitForData(player, 5)
		expect(data).never.toBeNil()
		expect(PlayerData.Get(player)).never.toBeNil()
		local loaded = PlayerData.Get(player) :: PlayerData.Data
		expect(loaded.Cash.Get()).toBe(0)
		loaded.Cash.Increment(10)
		expect(loaded.Cash.Get()).toBe(10)
		loaded.Cash.Increment(-50)
		expect(loaded.Cash.Get()).toBe(0)
		player.Parent = nil
	end)
end)
