--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Charm = require(ReplicatedStorage.Packages.Charm)
local Icon = require(ReplicatedStorage.Packages.TopbarPlus) :: any
local Trove = require(ReplicatedStorage.Packages.Trove)
local Vide = require(ReplicatedStorage.Packages.Vide)
local VideCharm = require(ReplicatedStorage.Packages.VideCharm)
local WaitFor = require(ReplicatedStorage.Packages.WaitFor)
local Types = require(script.Types)

local modules: { [string]: Types.Screen } = {
	Hud = require(script.Screens.Hud),
}

type Entry = {
	Screen: Types.Screen,
	IsOpen: Charm.Getter<boolean>,
	SetOpen: Charm.Setter<boolean>,
}

local UIController = { Name = "UIController" }

local entries: { [string]: Entry } = {}
local registry: { [string]: any } = {}
local trove = Trove.new()
local destroyed = false

function UIController.Init(_self: any, controllers: { [string]: any })
	registry = controllers
	for name, screen in modules do
		local isOpen, setOpen = Charm.signal(false)
		entries[name] = { Screen = screen, IsOpen = isOpen, SetOpen = setOpen }
	end
end

function UIController.Open(_self: any, name: string)
	local entry = entries[name]
	if not entry or Charm.untracked(entry.IsOpen) then
		return
	end
	Charm.batch(function()
		if entry.Screen.Modal then
			for otherName, other in entries do
				if other.Screen.Modal and otherName ~= name then
					other.SetOpen(false)
				end
			end
		end
		entry.SetOpen(true)
	end)
end

function UIController.Close(_self: any, name: string)
	local entry = entries[name]
	if entry then
		entry.SetOpen(false)
	end
end

function UIController.IsOpen(_self: any, name: string): boolean
	local entry = entries[name]
	return entry ~= nil and Charm.untracked(entry.IsOpen)
end

-- A Charm getter for a screen's open state, for effects in other systems
function UIController.OpenState(_self: any, name: string): Charm.Getter<boolean>?
	local entry = entries[name]
	return if entry then entry.IsOpen else nil
end

local function addTopbar(name: string, entry: Entry, topbar: Types.Topbar)
	local icon = Icon.new():setName(name):autoDeselect(false)
	if topbar.Label then
		icon:setLabel(topbar.Label)
	end
	if topbar.Image then
		icon:setImage(topbar.Image)
	end
	if topbar.Order then
		icon:setOrder(topbar.Order)
	end
	icon.selected:Connect(function()
		UIController:Open(name)
	end)
	icon.deselected:Connect(function()
		UIController:Close(name)
	end)
	-- Follow the screen when something else opens or closes it (another modal, a system)
	local stop = Charm.listen(entry.IsOpen, function(open: boolean)
		if open then
			icon:select()
		else
			icon:deselect()
		end
	end)
	trove:Add(function()
		stop()
		icon:destroy()
	end)
end

local function mount(name: string, entry: Entry, playerGui: Instance)
	local context: Types.Context = {
		Controllers = registry,
		Open = function(screenName: string)
			UIController:Open(screenName)
		end,
		Close = function(screenName: string)
			UIController:Close(screenName)
		end,
	}
	local gui: Instance? = nil
	local ok, problem = pcall(function()
		local unmount = Vide.mount(function()
			local open = VideCharm.useSignalState(entry.IsOpen)
			gui = Vide.create("ScreenGui")({
				Name = name,
				ResetOnSpawn = false,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
				DisplayOrder = entry.Screen.DisplayOrder or 0,
				Enabled = open,
				entry.Screen.Render(context),
			})
			return gui
		end, playerGui)
		trove:Add(function()
			unmount()
			if gui then
				gui:Destroy()
			end
		end)
	end)
	if not ok then
		warn(`[UIController] {name} screen disabled: {problem}`)
		return
	end
	if entry.Screen.Topbar then
		addTopbar(name, entry, entry.Screen.Topbar)
	end
	if entry.Screen.StartsOpen then
		UIController:Open(name)
	end
end

function UIController.Start(_self: any)
	local promise = (WaitFor.Child(Players.LocalPlayer, "PlayerGui", 15) :: any)
		:andThen(function(playerGui: Instance)
			if destroyed then
				return
			end
			for name, entry in entries do
				mount(name, entry, playerGui)
			end
		end)
		:catch(function(problem: any)
			warn(`[UIController] screens disabled; no PlayerGui: {tostring(problem)}`)
		end)
	trove:Add(function()
		promise:cancel()
	end)
end

function UIController.Destroy(_self: any)
	destroyed = true
	trove:Clean()
	table.clear(entries)
end

return UIController
