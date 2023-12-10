local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = script.Parent.UI
local Text = require(UI.Text)
local Button = require(UI.Button)

local SpawnMenu = {}

local Roact = require(ReplicatedStorage.Lib.roact)

local Deploy = require(ReplicatedStorage.Events.deploy):Client()

function SpawnMenu:getUI()
	local Primaries = {}
	local PrimaryStartPos = UDim2.new(0, 5, 0, 80)
	local PrimarySize = UDim2.new(0, 350, 0, 40)
	local PrimarySpacing = 5

	for i, v in {"KE Arms KP-15", "XD!!"} do
		if self.Primary == nil then
			self.Primary = v
		end
		Primaries[v] = Roact.createElement(Button, {
			text = v,
			pos = PrimaryStartPos + UDim2.fromOffset(0, i*(PrimarySize.Y.Offset + PrimarySpacing)),
			size = PrimarySize,

			highlight = v == self.Primary,

			onClick = function()
				self.Primary = v
				Roact.update(self.handle, self:getUI())
			end,

			textsize = 18,
		})
	end

	local Secondaries = {}
	local SecondaryStartPos = UDim2.new(1, -355, 0, 80)
	local SecondarySize = UDim2.new(0, 350, 0, 40)
	local SecondarySpacing = 5

	for i, v in {"P320X"} do
		if self.Secondary == nil then
			self.Secondary = v
		end
		Secondaries[v] = Roact.createElement(Button, {
			text = v,
			pos = SecondaryStartPos + UDim2.fromOffset(0, i*(SecondarySize.Y.Offset + SecondarySpacing)),
			size = SecondarySize,

			highlight = v == self.Secondary,

			onClick = function()
				self.Secondary = v
				Roact.update(self.handle, self:getUI())
			end,

			textsize = 18,
		})
	end


	return Roact.createElement("ScreenGui", {}, {
		Title = Roact.createElement(Text, {
			text = "gun testing",
			pos = UDim2.new(0, 0, 0, 5),
			size = UDim2.new(1, 0, 0, 48),

			textsize = 24,
		}),

		Primary = Roact.createElement(Text, {
			text = "Primaries",
			pos = PrimaryStartPos - UDim2.fromOffset(0, 15),
			size = PrimarySize,

			textsize = 24,
		}),

		Primaries = Roact.createFragment(Primaries),

		Secondary = Roact.createElement(Text, {
			text = "Secondaries",
			pos = SecondaryStartPos - UDim2.fromOffset(0, 15),
			size = SecondarySize,

			textsize = 24,
		}),

		Secondaries = Roact.createFragment(Secondaries),

		SpawnButton = Roact.createElement(Button, {
			text = "deploy",
			pos = UDim2.new(0.5, -250/2, 0.8, 0),
			size = UDim2.new(0, 250, 0, 50),

			textsize = 24,
			
			onClick = function()
				print("Deploying..")
				Deploy:Fire(self.Primary, self.Secondary)
				self:Unmount()
			end
		}),
	})
end

function SpawnMenu.new()
	local self = setmetatable({
		Primary = nil,
		Secondary = nil,
	}, {__index=SpawnMenu})
	self.handle = Roact.mount(self:getUI(), Players.LocalPlayer.PlayerGui, "Spawn Menu")

	return self
end

function SpawnMenu:Unmount()
	Roact.unmount(self.handle)
end

return SpawnMenu