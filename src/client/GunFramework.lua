local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Weld = require(ReplicatedStorage.Shared.Weld)
local Canim = require(ReplicatedStorage.Lib.canim) -- thank you blackshibe!!!

local gunfw = {
	Canim = Canim
}

function gunfw.new(weapons)
	local self = setmetatable({
		Connections={}, 
		Weapons = weapons, 
		Configs = {},
		Viewmodels = {},

		Animator = Canim.Animator.new(),

		Current = 1,
	}, {__index = gunfw})

	for i, v in self.Weapons do
		self.Configs[i] = require(v)
	end

	for _, v in self.Weapons do
		self.Viewmodels[#self.Viewmodels+1] = self:GenViewmodel(v)
	end

	for _, v in self.Configs do
		for j, k in v.Poses do
			self.Animator:load_pose(j, v.Priorities[j], k)
		end
	end
	for _, v in self.Configs do
		for j, k in v.Animations do
			self.Animator:load_animation(j, v.Priorities[j], k)
		end
	end

	self.Connections.PreRender = RunService.PreRender:Connect(function(deltaTimeRender)
		self:step(deltaTimeRender)
	end)
	self.Connections.InputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if not gameProcessedEvent then
			self:inputBegan(input)
		end
	end)

	return self
end

function gunfw:inputBegan(inp: InputObject)
	if inp.KeyCode.Value > 47 and inp.KeyCode.Value < 58 then
		local i = inp.KeyCode.Value == 48 and 10 or inp.KeyCode.Value-48
		if self.Viewmodels[i] then
			self.Current = i
		end
	end
end

function gunfw:GenViewmodel(weapon)
	local vm = ReplicatedStorage.Arms[Players.LocalPlayer.Team and Players.LocalPlayer.Team.Name or "Neutral"]:Clone()
	local model = ReplicatedStorage.WeaponModels[weapon.Name]:Clone()

	model.Parent = vm
	model:PivotTo(vm.PrimaryPart.CFrame)

	Weld(vm.PrimaryPart, model.PrimaryPart)

	return vm
end

function gunfw:step(dt)
	local vm = self.Viewmodels[self.Current]

	for i, v in self.Viewmodels do
		if i ~= self.Current and v.Parent ~= nil then
			v.Parent = nil
		elseif i == self.Current and v.Parent ~= workspace.CurrentCamera then
			v.Parent = workspace.CurrentCamera
			self.Animator:assign_model(v)
		end
	end

	self.Animator:update(dt)
	vm:PivotTo(workspace.CurrentCamera.CFrame)

	Players.LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
end

function gunfw:cleanup()
	for _, v in self.Connections do
		v:Disconnect()
	end
	
	for _, v in self.Viewmodels do
		v:Destroy()
	end
end

return gunfw