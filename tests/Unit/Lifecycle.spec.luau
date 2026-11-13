--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local Lifecycle = require(ReplicatedStorage.Lifecycle)

local describe, it, expect, jest = JestGlobals.describe, JestGlobals.it, JestGlobals.expect, JestGlobals.jest

local function system(name: string, calls: { string }): any
	return {
		Name = name,
		Init = function()
			table.insert(calls, `{name}.Init`)
		end,
		Start = function()
			table.insert(calls, `{name}.Start`)
		end,
		Destroy = function()
			table.insert(calls, `{name}.Destroy`)
		end,
	}
end

describe("Lifecycle", function()
	it("runs every Init, then every Start, and destroys in reverse", function()
		local calls = {}
		local runtime = Lifecycle.new({ system("A", calls), system("B", calls) })
		runtime:Start()
		runtime:Destroy()
		expect(calls).toEqual({ "A.Init", "B.Init", "A.Start", "B.Start", "B.Destroy", "A.Destroy" })
	end)

	it("names the failing system and phase, and destroys what started", function()
		local destroyA = jest.fn()
		local runtime = Lifecycle.new({
			{
				Name = "A",
				Destroy = function()
					destroyA()
				end,
			},
			{
				Name = "B",
				Init = function()
					error("boom")
				end,
			},
		} :: { any })
		local ok, message = pcall(function()
			runtime:Start()
		end)
		expect(ok).toBe(false)
		expect(string.sub(tostring(message), 1, 8)).toBe("[B.Init]")
		expect(destroyA).toHaveBeenCalledTimes(1)
	end)

	it("rejects duplicate system names", function()
		expect(function()
			Lifecycle.new({ { Name = "A" }, { Name = "A" } } :: { any })
		end).toThrow("Duplicate system: A")
	end)
end)
