return {
	Ammo = 17,

	Type = "Secondary",

	Mass = 15,

	VMOffset = CFrame.new(0, -0, 0);

	Recoil = Vector3.new(9, 25, 9),
	Punch = 1.2,
	FOVPunch = 24,
	Recover = 0.25,

	Poses = {
		Idle = "rbxassetid://15624615256",
		Sprint = "rbxassetid://15946193728"
	},
	Animations = {
		Reload = "rbxassetid://15945535805",
		Equip = "rbxassetid://16051379556",
		Unequip = "rbxassetid://15946073154",
		EmptyReload = "rbxassetid://15946188230",
		Shoot = "rbxassetid://15946191467"
	},
	Priorities = {
		Idle = 1,
		Reload = 2,
		Equip = 2,
		Unequip = 2,
		EmptyReload = 2,
		Shoot = 2,
		Sprint = 1,
	},
}