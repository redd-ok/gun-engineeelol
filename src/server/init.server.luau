local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Deploy = require(ReplicatedStorage.Events.deploy):Server()
local InitWeps = require(ReplicatedStorage.Events.initweps):Server()

local SpawnLocations = {
	{Vector3.new(-50, 14, -25), Vector3.new(50, 14, 25)}
}

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(chr)
		chr.PrimaryPart = chr.HumanoidRootPart
		chr.PrimaryPart.Anchored = true
	end)
end)

Deploy:On(function(plr: Player, prim, sec)
	assert(plr.Character, "Character model is nil")
	assert(plr.Character.PrimaryPart, "Character has no PrimaryPart")
	local spawnLoc = SpawnLocations[math.random(1, #SpawnLocations)]
	local pos = CFrame.new(Vector3.new(math.random(spawnLoc[1].X, spawnLoc[2].X), math.random(spawnLoc[1].Y, spawnLoc[2].Y), math.random(spawnLoc[1].Z, spawnLoc[2].Z)))

	plr.Character:PivotTo(pos)

	local Inv = plr:FindFirstChild("Inv")
	if Inv then
		Inv:Destroy()
	end
	Inv = Instance.new("Folder")
	Inv.Parent = plr
	Inv.Name = "Inv"
	local primModule = ReplicatedStorage.WeaponConfigs[prim]:Clone()
	local secondModule = ReplicatedStorage.WeaponConfigs[sec]:Clone()

	primModule.Parent = Inv
	secondModule.Parent = Inv

	InitWeps:Fire(plr, {primModule, secondModule})
	
	plr.Character.PrimaryPart.Anchored = false
end)