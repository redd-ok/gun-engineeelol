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

		Ready = false,
		ShootDelay = false,

		Animator = Canim.Canim.new(),
		Char = Player.Character,

		LastLook = Vector2.new(),
		RecoilCF = CFrame.new(),
		AimCF = CFrame.new(),
		StanceCF = CFrame.new(),

		Stance = 0,

		SwaySpr = Spring.new(15, 85, 2, 5),
		BobSpr = Spring.new(15, 85, 4, 4),
		BobSpr2 = Spring.new(15, 85, 4, 4),
		RecoilSpr = Spring.new(15, 100, 5, 6),
		Recoil2Spr = Spring.new(15, 100, 5, 6),
		OffsetSpr = Spring.new(15, 125, 2, 5),
		AimSpr = Spring.new(15, 75, 5, 8, 0),
		FOVSpr = Spring.new(15, 125, 4, 3, 80),

		Aimming = false,
		Sprinting = false,

		Distance = 0,
		Current = 1,
	}, { __index = gunfw })

	do
		for i, v in self.Weapons do
			self.Configs[i] = require(v)
			self.Configs[i].MaxAmmo = self.Configs[i].Ammo
		end

		for j, v in self do
			if typeof(j) == "string" and j:sub(-3) == "Spr" then
				v.Mass = self.Configs[self.Current].Mass
			end
		end

		for j, v in self do
			if typeof(j) == "string" and j:sub(-3) == "Spr" then
				v.Mass = self.Configs[self.Current].Mass
			end
		end

		for _, v in self.Weapons do
			self.Viewmodels[#self.Viewmodels + 1] = self:GenViewmodel(v)
		end

		-- local rebaseBasis
		-- local rebaseTarget

		for i, v in self.Configs do
			for j, k in v.Poses do
				self.Animator:load_pose((self.Weapons[i].Name .. "_") .. j, v.Priorities[j], k).looped = false
				-- local pose = self.Animator.animations[self.Weapons[i].Name .. "_" .. j]

				-- if j == "RebaseIdle" then
				-- 	rebaseTarget = pose
				-- else
				-- 	if j == "Idle" then
				-- 		rebaseBasis = pose
				-- 	end

				-- 	pose.bone_weights = v.Bones
				-- end
			end
		end
		for i, v in self.Configs do
			for j, k in v.Animations do
				self.Animator:load_animation((self.Weapons[i].Name .. "_") .. j, v.Priorities[j], k) --.rebase_target =
				-- self.Animator.animations[self.Weapons[i].Name .. "_Idle"]
				if j == "Reload" then
					local track = self.Animator.animations[self.Weapons[i].Name .. "_" .. j]
					track.speed = track.length / v.ReloadTime
				elseif j == "EmptyReload" then
					local track = self.Animator.animations[self.Weapons[i].Name .. "_" .. j]
					track.speed = track.length / v.EmptyReloadTime
				end

				-- if j ~= "Equip" and j ~= "Unequip" then
				local track = self.Animator.animations[self.Weapons[i].Name .. "_" .. j]
				track.rebase_target = self.Animator.animations[self.Weapons[i].Name .. "_" .. "Idle"]
				-- track.rebase_basis = rebaseBasis
				-- end
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
		self.Connections.InputChanged = UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
			if not gameProcessedEvent then
				if input.UserInputType == Enum.UserInputType.MouseWheel then
					self.Stance += input.Position.Z
					self.Stance = math.clamp(self.Stance, -1, 1)
				end
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

		self.Animator:play_pose(self.Weapons[self.Current].Name .. "_Idle")
		self.Animator:play_animation(self.Weapons[self.Current].Name .. "_Equip")
		self.Animator.animations[self.Weapons[self.Current].Name .. "_Equip"].finished:Wait()
		self.Ready = true
	end

	return self
end

function gunfw:equip(num)
	self.Ready = false
	self.Animator:play_animation(self.Weapons[self.Current].Name .. "_Unequip")
	task.wait(self.Animator.animations[self.Weapons[self.Current].Name .. "_Unequip"].length)

	self.Current = num

	for j, v in self do
		if typeof(j) == "string" and j:sub(-3) == "Spr" then
			v.Mass = self.Configs[self.Current].Mass
		end
	end

	for _, v in self.Animator.playing_animations do
		self.Animator:stop_animation(v.name)
	end
	for _, v in self.Animator.playing_poses do
		self.Animator:stop_animation(v.name)
	end

	self.Animator:play_pose(self.Weapons[self.Current].Name .. "_Idle")
	self.Animator:play_animation(self.Weapons[self.Current].Name .. "_Equip")
	self.Animator.animations[self.Weapons[self.Current].Name .. "_Equip"].finished:Wait()
	self.Ready = true
end

function gunfw:inputBegan(inp: InputObject)
	if inp.KeyCode.Value > 47 and inp.KeyCode.Value < 58 and self.Ready then
		local i = inp.KeyCode.Value == 48 and 10 or inp.KeyCode.Value - 48
		if self.Viewmodels[i] then
			self:equip(i)
		end
	end
	if inp.UserInputType == Enum.UserInputType.MouseButton1 and self.Ready then
		local cfg = self.Configs[self.Current]
		while cfg.Ammo > 0 and self.Ready and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
			if not self.ShootDelay then
				self.ShootDelay = true

				self:shoot()

				task.wait(60 / cfg.RPM)
				self.ShootDelay = false
			end
			if cfg.Firemode ~= "Auto" then
				break
			end
		end
	elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
		self.Aimming = true
	elseif inp.KeyCode == Enum.KeyCode.LeftShift and self.Ready then
		self.Sprinting = true
		self.Animator:stop_animation(self.Weapons[self.Current].Name .. "_Idle")
		self.Animator:play_pose(self.Weapons[self.Current].Name .. "_Sprint")
	elseif inp.KeyCode == Enum.KeyCode.R and self.Ready and not self.Sprinting then
		self:reload()
	end
end

function gunfw:inputEnded(inp: InputObject)
	if inp.UserInputType == Enum.UserInputType.MouseButton2 then
		self.Aimming = false
	elseif inp.KeyCode == Enum.KeyCode.LeftShift and self.Sprinting then
		self.Sprinting = false
		self.Animator:play_pose(self.Weapons[self.Current].Name .. "_Idle")
		self.Animator:stop_animation(self.Weapons[self.Current].Name .. "_Sprint")
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
	local cfg = self.Configs[self.Current]
	cfg.Ammo -= 1
	local X = math.random(math.floor(cfg.Recoil.X * 0.8), math.floor(cfg.Recoil.X * 1.2)) * A
	local Z = math.random(math.floor(cfg.Recoil.Z * 0.8), math.floor(cfg.Recoil.Z * 1.2)) * A
	self.RecoilSpr:shove(Vector3.new(X, cfg.Recoil.Y, Z))
	self.Recoil2Spr:shove(Vector3.new(-X, -cfg.Recoil.Y * 0.6, 15))
	self.RecoilCF *= CFrame.Angles(math.rad(cfg.Recoil.Y * 1.4), math.rad(X * 0.4), math.rad(Z * 0.4)) * CFrame.new(
		math.rad(-X * 0.4),
		math.rad(-cfg.Recoil.Y * 0.4),
		cfg.Punch
	)
	self.FOVSpr.Velocity += cfg.FOVPunch
	self.Animator:play_animation(self.Weapons[self.Current].Name .. "_Shoot")
end

function gunfw:reload()
	self.Ready = false

	local cfg = self.Configs[self.Current]

	if cfg.Ammo > 0 then
		self.Animator:play_animation(self.Weapons[self.Current].Name .. "_Reload")
		self.Animator.animations[self.Weapons[self.Current].Name .. "_Reload"].finished:Wait()

		cfg.Ammo = cfg.MaxAmmo + 1

		self.Ready = true
	else
		self.Animator:play_animation(self.Weapons[self.Current].Name .. "_EmptyReload")
		self.Animator.animations[self.Weapons[self.Current].Name .. "_EmptyReload"].finished:Wait()

		cfg.Ammo = cfg.MaxAmmo

		self.Ready = true
	end
end

function gunfw:step(dt)
	local vm: Model = self.Viewmodels[self.Current]
	assert(vm.PrimaryPart, "Viewmodel PrimaryPart must be defined.")

	local cfg = self.Configs[self.Current]

	for i, v in self.Viewmodels do
		if i ~= self.Current and v.Parent ~= nil then
			v.Parent = nil
		elseif i == self.Current and v.Parent ~= workspace.CurrentCamera then
			v.Parent = workspace.CurrentCamera
			self.Animator:assign_model(v)
		end
	end

	local md = UserInputService:GetMouseDelta()

	if not self.Aimming or self.Stance ~= 0 then
		self.OffsetSpr.Target -= Vector3.new(md.X, md.Y) / 8
	else
		self.OffsetSpr.Target = Vector3.new()
	end
	if self.OffsetSpr.Target.Magnitude > 6 then
		self.OffsetSpr.Target = self.OffsetSpr.Target.Unit * 6
	end

	local relVel = self.Char.PrimaryPart.CFrame:VectorToObjectSpace(self.Char.PrimaryPart.AssemblyLinearVelocity)
	local vel = self.Char.PrimaryPart.AssemblyLinearVelocity

	if self.Char.Humanoid.MoveDirection.Magnitude > 0 then
		local s = relVel.Magnitude / 2
		self.BobSpr.Target = self.BobSpr.Target:Lerp(
			Vector3.new(
				math.sin(self.Distance * s) * (1 + (s / 4)) + (relVel.X / 6),
				-(math.abs((math.cos(self.Distance * s)) * 3) - (0.5 / (2 / 4))) * (s / 4) - (vel.Y / 2),
				math.cos(self.Distance * s) * (2 + (s / 4)) + (relVel.X / 4)
			),
			0.3
		)
		self.BobSpr2.Target = self.BobSpr2.Target:Lerp(
			Vector3.new(
				-math.sin(self.Distance * s) * (1 + (s / 4)) + (relVel.X / 6),
				(math.abs((math.cos(self.Distance * s)) * 2) - (0.5 / (2 / 4))) * (s / 4) - (vel.Y / 7),
				UserInputService:IsKeyDown(Enum.KeyCode.W) and 0.1
					or (UserInputService:IsKeyDown(Enum.KeyCode.S) and -0.1 or 0)
			),
			0.3
		)
		self.Distance += dt
	else
		self.BobSpr.Target = Vector3.new(0, -(vel.Y / 2), 0)
		self.BobSpr2.Target = Vector3.new(0, -(vel.Y / 7), 0)
		self.Distance = 0
	end

	self.SwaySpr.Target =
		Vector3.new(math.clamp(-md.X, -2, 2) / 2, math.clamp(-md.Y, -2, 2) / 2, math.clamp(-md.X, -4, 4) / 2)

	self.Animator:update(dt)

	local springV = self.SwaySpr:update(dt)
	local bobV = self.BobSpr:update(dt)
	local bob2V = self.BobSpr2:update(dt)
	local recoilV = self.RecoilSpr:update(dt)
	local recoil2V = self.Recoil2Spr:update(dt)
	local offsetV = self.OffsetSpr:update(dt) / 2

	self.RecoilCF = self.RecoilCF:Lerp(CFrame.new(), cfg.Recover)

	local aimOffset = CFrame.new()
	local gun = vm:FindFirstChildWhichIsA("Model")
	if gun:FindFirstChild("Aim1") then
		local Weight = 1
		self.AimCF = self.AimCF:Lerp(
			gun.Aim1.CFrame:ToObjectSpace(vm.PrimaryPart.CFrame * cfg.VMOffset:Inverse()),
			dt / (Weight * 0.1)
		)
		local a = self.AimSpr:update(dt)
		aimOffset = CFrame.new():Lerp(self.AimCF, a) * CFrame.new(0, 0, (a < 0.5 and -a or (a - 1)) * 0.3)
		self.AimSpr.Target = self.Aimming and 1 or 0
	end

	workspace.CurrentCamera.FieldOfView = self.FOVSpr:update(dt)

	local PivotTo = workspace.CurrentCamera.CFrame * cfg.VMOffset
	PivotTo *= CFrame.new(math.rad(springV.X * 1.5), -math.rad(springV.Y * 2.5), 0)
	PivotTo *= CFrame.new(math.rad(offsetV.X) + math.rad(offsetV.Z * 1.5), -math.rad(offsetV.Y * 3), 0)
	PivotTo *= CFrame.new(0, 0, -1)
	PivotTo *= CFrame.Angles(math.rad(offsetV.Y), math.rad(offsetV.X), -math.rad(offsetV.X * 1.5))
	PivotTo *= CFrame.new(0, 0, 1)
	PivotTo *= CFrame.Angles(math.rad(springV.Y), math.rad(springV.X), math.rad(springV.X * 1.5)) * CFrame.new(
		math.rad(springV.X),
		0,
		0
	)
	PivotTo *= CFrame.new(math.rad(bob2V.X) + math.rad(bob2V.Z * 1.5), -math.rad(bob2V.Y), bob2V.Z)
	PivotTo *= CFrame.Angles(math.rad(bobV.Y), math.rad(bobV.X), math.rad(bobV.Z * 1.5))
	PivotTo *= CFrame.new(0, 0, -0.5)
	PivotTo *= CFrame.Angles(math.rad(recoilV.Y), math.rad(recoilV.X), math.rad(recoilV.Z * 1.5))
	PivotTo *= CFrame.new(math.rad(recoil2V.Y), math.rad(recoil2V.X), math.rad(recoil2V.Z))
	PivotTo *= self.RecoilCF
	PivotTo *= CFrame.new(0, 0, 0.5)
	PivotTo *= aimOffset

	local Y = math.sin(math.sin(tick() * 0.7)) * 0.6
	local X = math.cos(math.cos(tick() * 0.5)) * 0.5
	PivotTo *= CFrame.new(X/45, (Y)/45, 0) * CFrame.Angles(0, X/45, -X/45)

	if self.Stance ~= 0 and not self.Sprinting and not self.Aimming then
		self.StanceCF = self.StanceCF:Lerp(cfg.StanceCFrames[self.Stance == 1 and 1 or 2], 0.1)
	else
		self.StanceCF = self.StanceCF:Lerp(CFrame.new(), 0.1)
		self.Stance = 0
	end

	PivotTo *= self.StanceCF

	vm:PivotTo(PivotTo)

	self.Char.Humanoid.WalkSpeed = self.Char.Humanoid.WalkSpeed
		+ ((self.Sprinting and 18 or 12) - self.Char.Humanoid.WalkSpeed) * 0.3
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
