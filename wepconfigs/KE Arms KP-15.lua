return {
	Ammo = 30,

	Type = "Primary",

	Mass = 25,

	VMOffset = CFrame.new(0, -0.5, 0);

	Recoil = Vector3.new(1, 1.5, 1.5),
	Punch = 0.5,
	FOVPunch = 10,
	Recover = 0.2,

	ReloadTime = 3,

	Poses = {
		Idle = "rbxassetid://15624615256"
	},
	Animations = {
		Reload = "rbxassetid://15945535805",
		Equip = "rbxassetid://15946075946",
		Unequip = "rbxassetid://15946073154",
		-- EmptyReload = "",

	},
	Priorities = {
		Idle = 1,
		Reload = 2,
		Equip = 2,
		Unequip = 2,
	},
}