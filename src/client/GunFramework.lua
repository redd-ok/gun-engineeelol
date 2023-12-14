local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

local Weld = require(ReplicatedStorage.Shared.Weld)
local Spring = require(ReplicatedStorage.Shared.Spring)
local Canim = require(script.Parent.canim) -- thank you blackshibe!!!

local gunfw = {
	Canim = Canim,
}

function gunfw.new(weapons)
	local self = setmetatable({
		Connections = {},
		Weapons = weapons,
		Configs = {},
		Viewmodels = {},

		Animator = Canim.Canim.new(),
		Char = Player.Character,

		LastLook = Vector2.new(),
		RecoilCF = CFrame.new(),
		AimCF = CFrame.new(),

		SwaySpr = Spring.new(15, 50, 2, 4),
		BobSpr = Spring.new(15, 75, 4, 2),
		BobSpr2 = Spring.new(15, 75, 4, 2),
		RecoilSpr = Spring.new(15, 100, 5, 6),
		Recoil2Spr = Spring.new(15, 100, 5, 6),
		OffsetSpr = Spring.new(15, 75, 4, 2),
		AimSpr = Spring.new(15, 45, 5, 5, 0),

		Aimming = false,

		Distance = 0,
		Current = 1,
	}, { __index = gunfw })

	do
		for i, v in self.Weapons do
			self.Configs[i] = require(v)
		end

		for _, v in self.Weapons do
			self.Viewmodels[#self.Viewmodels + 1] = self:GenViewmodel(v)
		end

		for i, v in self.Configs do
			for j, k in v.Poses do
				self.Animator:load_pose((self.Weapons[i].Name .. "_") .. j, v.Priorities[j], k).looped = false
				-- self.Animator.animations[(self.Weapons[i].Name.."_")..j]
			end
		end
		for i, v in self.Configs do
			for j, k in v.Animations do
				self.Animator:load_animation((self.Weapons[i].Name .. "_") .. j, v.Priorities[j], k)
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
		self.Connections.InputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
			if not gameProcessedEvent then
				self:inputEnded(input)
			end
		end)
		-- self.Connections.StateChanged = self.Char.Humanoid.StateChanged:Connect(function(_, new)
		-- 	if new == Enum.HumanoidStateType.Landed then
		-- 		self.BobSpr:shove(Vector3.new(0, math.rad(-50), 0))
		-- 		self.BobSpr2:shove(Vector3.new(0, math.rad(-50), 0))
		-- 	end
		-- end)

		if self.Animator.animations[self.Weapons[self.Current].Name .. "_Idle"] then
			self.Animator:play_pose(self.Weapons[self.Current].Name .. "_Idle")
		end
	end

	return self
end

function gunfw:inputBegan(inp: InputObject)
	if inp.KeyCode.Value > 47 and inp.KeyCode.Value < 58 then
		local i = inp.KeyCode.Value == 48 and 10 or inp.KeyCode.Value - 48
		if self.Viewmodels[i] then
			self.Current = i

			for _, v in self.Animator.playing_animations do
				self.Animator:stop_animation(v.name)
			end
			for _, v in self.Animator.playing_poses do
				self.Animator:stop_animation(v.name)
			end

			if self.Animator.animations[self.Weapons[i].Name .. "_Idle"] then
				self.Animator:play_pose(self.Weapons[i].Name .. "_Idle")
			end
		end
	end
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then
		self:shoot()
	elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
		self.Aimming = true
	end
end

function gunfw:inputEnded(inp: InputObject)
	if inp.UserInputType == Enum.UserInputType.MouseButton2 then
		self.Aimming = false
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

function gunfw:shoot()
	local A = math.random(-1, 1)
	local X = math.random(4, 6) * A
	self.RecoilSpr:shove(Vector3.new(X, 5, X))
	self.Recoil2Spr:shove(Vector3.new(-X, -4, 15))
	self.RecoilCF *= CFrame.Angles(math.rad(6), 0, 0) * CFrame.new(0, math.rad(-5), 0.25)
end

function gunfw:step(dt)
	local vm: Model = self.Viewmodels[self.Current]

	for i, v in self.Viewmodels do
		if i ~= self.Current and v.Parent ~= nil then
			v.Parent = nil
		elseif i == self.Current and v.Parent ~= workspace.CurrentCamera then
			v.Parent = workspace.CurrentCamera
			self.Animator:assign_model(v)
		end
	end

	local md = UserInputService:GetMouseDelta()

	self.OffsetSpr.Target -= Vector3.new(md.X, md.Y) / 8
	if self.OffsetSpr.Target.Magnitude > 6 then
		self.OffsetSpr.Target = self.OffsetSpr.Target.Unit * 6
	end

	local relVel = self.Char.PrimaryPart.CFrame:VectorToObjectSpace(self.Char.PrimaryPart.AssemblyLinearVelocity)
	local vel = self.Char.PrimaryPart.AssemblyLinearVelocity

	if self.Char.Humanoid.MoveDirection.Magnitude > 0 then
		local s = relVel.Magnitude / 4
		self.BobSpr.Target = Vector3.new(
			math.cos(self.Distance * s) * 3 + (relVel.X / 2),
			-math.abs(math.sin(self.Distance * s) * 3) - (vel.Y / 2),
			math.cos(self.Distance * s) * 3 + (relVel.X / 4)
		)
		self.BobSpr2.Target = Vector3.new(
			-math.cos(self.Distance * s) * 2 + (relVel.X / 2),
			-math.abs(math.sin(self.Distance * s) * 2) - (vel.Y / 7),
			UserInputService:IsKeyDown(Enum.KeyCode.W) and 0.1
				or (UserInputService:IsKeyDown(Enum.KeyCode.S) and -0.1 or 0)
		)
		self.Distance += dt
	else
		self.BobSpr.Target = Vector3.new(0, -(vel.Y / 2), 0)
		self.BobSpr2.Target = Vector3.new(0, -(vel.Y / 7), 0)
		self.Distance = 0
	end

	self.SwaySpr.Target = Vector3.new(math.clamp(-md.X, -5, 5), math.clamp(-md.Y, -5, 5), math.clamp(-md.X, -5, 5))

	self.Animator:update(dt)

	local springV = self.SwaySpr:update(dt)
	local bobV = self.BobSpr:update(dt)
	local bob2V = self.BobSpr2:update(dt)
	local recoilV = self.RecoilSpr:update(dt)
	local recoil2V = self.Recoil2Spr:update(dt)
	local offsetV = self.OffsetSpr:update(dt)

	self.RecoilCF = self.RecoilCF:Lerp(CFrame.new(), 0.25)

	local aimOffset = CFrame.new()
	local gun = vm:FindFirstChildWhichIsA("Model")
	if gun:FindFirstChild("Aim1") then
		local Weight = 1
		self.AimCF = self.AimCF:Lerp(gun.Aim1.CFrame:ToObjectSpace(vm.PrimaryPart.CFrame), dt / (Weight * 0.1))
		local a = self.AimSpr:update(dt)
		aimOffset *= aimOffset:Lerp(self.AimCF, a)
		self.AimSpr.Target = self.Aimming and 1 or 0
	end

	vm:PivotTo(
		workspace.CurrentCamera.CFrame
			* CFrame.new(math.rad(springV.X) + math.rad(springV.Z * 1.5), -math.rad(springV.Y), 0)
			* CFrame.Angles(math.rad(offsetV.Y), math.rad(offsetV.X), -math.rad(offsetV.X * 1.5))
			* CFrame.Angles(math.rad(springV.Y), math.rad(springV.X), -math.rad(springV.Z * 1.5))
			* CFrame.new(math.rad(bob2V.X) + math.rad(bob2V.Z * 1.5), -math.rad(bob2V.Y), bob2V.Z)
			* CFrame.Angles(math.rad(bobV.Y), math.rad(bobV.X), math.rad(bobV.Z * 1.5))
			* CFrame.Angles(math.rad(recoilV.Y), math.rad(recoilV.X), math.rad(recoilV.Z * 1.5))
			* CFrame.new(math.rad(recoil2V.Y), math.rad(recoil2V.X), math.rad(recoil2V.Z))
			* self.RecoilCF
			* aimOffset
	)

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
