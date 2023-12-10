local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Weld = require(ReplicatedStorage.Shared.Weld)

local gunhandler = {}

function gunhandler.new(weapons)
	local self = {Connections={}, Weapons = weapons, WeaponCache = {}}
	self.Connections.PreRender = game:GetService("RunService").PreRender:Connect(function(deltaTimeRender)
		self:step(deltaTimeRender)
	end)

	return setmetatable(self, {__index = gunhandler})
end

function gunhandler:GenViewmodel(weapon)
	local vm = ReplicatedStorage.Arms[Players.LocalPlayer.Team and Players.LocalPlayer.Team.Name or "Neutral"]
	local model = ReplicatedStorage.WeaponModels[weapon.Name]

	model.Parent = vm
	model:PivotTo(vm)

	Weld(vm.PrimaryPart, model.PrimaryPart)

	return vm
end

function gunhandler:step()
	
end

function gunhandler:cleanup()
	for _, v in self.Connections do
		v:Disconnect()
	end
	
	for _, v in self.WeaponCache do
		v:Destroy()
	end
end

return gunhandler