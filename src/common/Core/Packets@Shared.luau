--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packet = require(ReplicatedStorage.Platform.Packet)

local Packets = {
	Ping = Packet("Ping"):Response(Packet.NumberF64):RateLimit(5, 1),
	-- Core/Sync: charm-sync patches, server to client only (no RateLimit, so clients cannot send it)
	Sync = Packet("Sync", Packet.Any),
	SyncReady = Packet("SyncReady"):RateLimit(1, 5),
}

return Packets
