local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Weld = require(ReplicatedStorage.Shared.Weld)

local gunhandler = {}

function gunhandler.new(weapons)
	local self = setmetatable({
		Connections={}, 
		Weapons = weapons, 
		Viewmodels = {},

		Current = 1,
	}, {__index = gunhandler})

	for i, v in self.Weapons do
		self.Viewmodels[i] = self:GenViewmodel(v)
	end

	self.Connections.PreRender = game:GetService("RunService").PreRender:Connect(function(deltaTimeRender)
		self:step(deltaTimeRender)
	end)

	return self
end

function gunhandler:GenViewmodel(weapon)
	local vm = ReplicatedStorage.Arms[Players.LocalPlayer.Team and Players.LocalPlayer.Team.Name or "Neutral"]
	local model = ReplicatedStorage.WeaponModels[weapon.Name]:Clone()

	model.Parent = vm
	model:PivotTo(vm.PrimaryPart.CFrame)

	Weld(vm.PrimaryPart, model.PrimaryPart)

	return vm
end

function gunhandler:step()
	local vm = self.Viewmodels[self.Current]

	for i, v in self.Viewmodels do
		if i ~= self.Current and v.Parent ~= nil then
			v.Parent = nil
		elseif i == self.Current and v.Parent ~= workspace.CurrentCamera then
			v.Parent = workspace.CurrentCamera
		end
	end

	vm:PivotTo(workspace.CurrentCamera.CFrame)
end

function gunhandler:cleanup()
	for _, v in self.Connections do
		v:Disconnect()
	end
	
	for _, v in self.Viewmodels do
		v:Destroy()
	end
end

return gunhandler