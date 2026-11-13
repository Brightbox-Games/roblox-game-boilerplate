--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local RateLimit = require(ReplicatedStorage.Base.RateLimit)

local describe, it, expect = JestGlobals.describe, JestGlobals.it, JestGlobals.expect

describe("RateLimit", function()
	it("allows up to its count, then refuses", function()
		local limiter = RateLimit.new(2, 10)
		local player = Instance.new("Player")
		expect(limiter:Allow(player)).toBe(true)
		expect(limiter:Allow(player)).toBe(true)
		expect(limiter:Allow(player)).toBe(false)
	end)

	it("tracks each key separately", function()
		local limiter = RateLimit.new(1, 10)
		expect(limiter:Allow("a")).toBe(true)
		expect(limiter:Allow("b")).toBe(true)
		expect(limiter:Allow("a")).toBe(false)
	end)

	it("forgets a removed key", function()
		local limiter = RateLimit.new(1, 10)
		expect(limiter:Allow("a")).toBe(true)
		limiter:Remove("a")
		expect(limiter:Allow("a")).toBe(true)
	end)
end)
