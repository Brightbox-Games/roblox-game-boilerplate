--!strict

-- Example screen: player data from Scribe, synced global state from Charm, and a topbar toggle.
-- Delete it (and its line in init.luau) when the game has its own HUD.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerData = require(ReplicatedStorage.Core.Data.PlayerData)
local Vide = require(ReplicatedStorage.Packages.Vide)
local VideCharm = require(ReplicatedStorage.Packages.VideCharm)
local ScribeVide = require(script.Parent.Parent.ScribeVide)
local Types = require(script.Parent.Parent.Types)

local create = Vide.create
-- Vide types create only for common classes; cast for others (UIPadding, UIStroke, UIScale, ...)
local createAny = Vide.create :: any
local useScribe = ScribeVide(Vide)

local function line(order: number, text: () -> string): Instance
	return create("TextLabel")({
		Name = `Line{order}`,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSansBold),
		TextSize = 20,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
	})
end

local Hud: Types.Screen = {
	Modal = false,
	StartsOpen = true,
	Topbar = { Label = "HUD" },
	Render = function(context: Types.Context): Instance
		local cash, stopCash = useScribe(PlayerData.Client.Cash)
		Vide.cleanup(function()
			stopCash()
		end)
		local playerCount =
			VideCharm.useSignalState(context.Controllers.AppController.PlayerCount :: () -> number)

		return create("Frame")({
			Name = "Hud",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 16, 1, -16),
			Size = UDim2.fromOffset(200, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Color3.fromRGB(20, 20, 24),
			BackgroundTransparency = 0.25,
			create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
			createAny("UIPadding")({
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
			}),
			create("UIListLayout")({ Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
			line(1, function()
				return `Cash: {cash()}`
			end),
			line(2, function()
				return `Players: {playerCount()}`
			end),
		})
	end,
}

return Hud
