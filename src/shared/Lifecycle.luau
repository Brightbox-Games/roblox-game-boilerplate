--!strict

export type System = {
	read Name: string,
	read Init: ((self: any, systems: { [string]: any }) -> ())?,
	read Start: ((self: any) -> ())?,
	read Destroy: ((self: any) -> ())?,
}

local Lifecycle = {}
Lifecycle.__index = Lifecycle

function Lifecycle.new(systems: { System })
	local byName: { [string]: any } = {}
	for _, system in systems do
		assert(type(system.Name) == "string" and #system.Name > 0, "System needs a Name")
		assert(byName[system.Name] == nil, `Duplicate system: {system.Name}`)
		byName[system.Name] = system
	end

	return setmetatable({
		_systems = table.clone(systems),
		_byName = table.freeze(byName),
		_initialized = {} :: { System },
		_state = "Created",
	}, Lifecycle)
end

function Lifecycle.Destroy(self: Lifecycle)
	if self._state == "Destroyed" then
		return
	end
	self._state = "Destroyed"
	for index = #self._initialized, 1, -1 do
		local system = self._initialized[index]
		local destroy = system.Destroy
		if destroy then
			local failure = "unknown error"
			local ok = xpcall(function()
				destroy(system)
			end, function(err: any)
				failure = debug.traceback(tostring(err), 2)
			end)
			if not ok then
				warn(`[{system.Name}.Destroy] {failure}`)
			end
		end
	end
	table.clear(self._initialized)
end

function Lifecycle.Start(self: Lifecycle)
	assert(self._state == "Created", `Cannot start lifecycle in state {self._state}`)
	self._state = "Starting"
	local phase = "Init"
	local activeName = "unknown"
	local failure = "unknown error"
	local ok = xpcall(function()
		for _, system in self._systems do
			activeName = system.Name
			table.insert(self._initialized, system)
			local init = system.Init
			if init then
				init(system, self._byName)
			end
		end
		phase = "Start"
		for _, system in self._systems do
			activeName = system.Name
			local start = system.Start
			if start then
				start(system)
			end
		end
	end, function(err: any)
		failure = debug.traceback(tostring(err), 2)
	end)
	if not ok then
		self:Destroy()
		error(`[{activeName}.{phase}] {failure}`, 0)
	end
	self._state = "Started"
end

export type Lifecycle = typeof(setmetatable({
	_systems = {} :: { System },
	_byName = {} :: { [string]: any },
	_initialized = {} :: { System },
	_state = "Created",
}, Lifecycle))

return Lifecycle
