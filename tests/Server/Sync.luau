--!strict

-- charm-sync through Packet.Any, both halves in one VM. A harness rather than a Jest spec:
-- Jest's runtime cannot resolve Charm's `@self/...` requires.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function check(label: string, passed: boolean)
	print(if passed then `PASS {label}` else `FAIL {label}`)
end

-- Writes a value with Packet.Any and reads it back, as the Sync packet carries it
local function overPacket(PacketTypes: any, value: any): any
	local cursor = {
		Buffer = buffer.create(128),
		BufferLength = 128,
		BufferOffset = 0,
		Instances = {},
		InstancesOffset = 0,
	}
	PacketTypes.Import(cursor)
	PacketTypes.Writes.Any(value)
	PacketTypes.Export()
	PacketTypes.Import({
		Buffer = cursor.Buffer,
		BufferLength = cursor.BufferOffset,
		BufferOffset = 0,
		Instances = cursor.Instances,
		InstancesOffset = 0,
	})
	return PacketTypes.Reads.Any()
end

return function(_context: any)
	local Charm = require(ReplicatedStorage.Packages.Charm)
	local CharmSync = require(ReplicatedStorage.Packages.CharmSync)
	local PacketTypes = require(ReplicatedStorage.Platform.Packet.Types) :: any

	CharmSync.config.fixArrays = false
	local getServer, setServer =
		Charm.signal({ Phase = "Lobby", Slots = { "a", "b", "c" }, Winner = "x" } :: any)
	local getClient, setClient = Charm.signal(nil :: any)
	CharmSync.client.addSignals({ ["Spec.State"] = setClient })

	local sent: { any } = {}
	CharmSync.server.connect(function(_client: any, payloads: any)
		table.insert(sent, overPacket(PacketTypes, payloads))
	end)
	CharmSync.server.disconnect()
	CharmSync.server.addSignalsToClient("client", { ["Spec.State"] = getServer :: any })

	local function deliver()
		CharmSync.server.flush()
		for _, payloads in sent do
			CharmSync.client.patch(payloads)
		end
		table.clear(sent)
	end

	deliver()
	local state = getClient()
	check(
		"client receives the initial state",
		state ~= nil and state.Phase == "Lobby" and state.Winner == "x"
	)
	check("initial array arrives whole", state ~= nil and state.Slots[1] == "a" and state.Slots[3] == "c")

	local slots = { "a", "b", "c" }
	slots[2] = nil
	setServer({ Phase = "Round", Slots = slots })
	deliver()
	state = getClient()
	check("changed key is patched", state.Phase == "Round")
	check("removed key arrives as nil", state.Winner == nil)
	check(
		"sparse array keeps its hole",
		state.Slots[1] == "a" and state.Slots[2] == nil and state.Slots[3] == "c"
	)

	CharmSync.server.reset()
	CharmSync.client.removeAllSignals()
	print("@done")
end
