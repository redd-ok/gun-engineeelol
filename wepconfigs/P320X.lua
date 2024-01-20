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
		Idle = "rbxassetid://16051405068",
		Sprint = "rbxassetid://16051409535"
	},
	Animations = {
		Reload = "rbxassetid://16051407412",
		Equip = "rbxassetid://16051379556",
		Unequip = "rbxassetid://16051412527",
		EmptyReload = "rbxassetid://16051399889",
		Shoot = "rbxassetid://16051402773"
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