local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = script.Parent
local Text = require(UI.Text)
local Background = require(UI.Background)

local SpawnMenu = {}

local Roact = require(ReplicatedStorage.Lib.roact)


function SpawnMenu:render()
	

	return Roact.createElement("ScreenGui", {
		IgnoreGuiInset = true,
	}, {
		Bg = Roact.createElement(Background, {
			size = UDim2.new(1, 0, 1, 0)
		}),

		gameTitle = Roact.createElement(Text, {
			text = "gun testing",
			pos = UDim2.new(0, 0, 0.4, 0),
			size = UDim2.new(1, 0, 0, 48),

			textsize = 24,
		}),

		loadingText = Roact.createElement(Text, {
			text = "loading..",
			pos = UDim2.new(0, 0, 0.5, 24),
			size = UDim2.new(1, 0, 0, 48),

			textsize = 24,
		})
	})
end

function SpawnMenu.new()
	local self = setmetatable({}, { __index = SpawnMenu })
	self.handle = Roact.mount(self:render(), Players.LocalPlayer.PlayerGui, "Loading Menu")

	return self
end

function SpawnMenu:cleanup()
	Roact.unmount(self.handle)
end

return SpawnMenu
