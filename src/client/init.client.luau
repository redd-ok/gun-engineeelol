local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local LoadingUi = require(script.UI.LoadingUI):new()
local Debugger = require(script.Debugger).new()

Players.LocalPlayer.CharacterAdded:Wait()

local InitWeapons = require(ReplicatedStorage.Events.initweps):Client()
local GunFramework = require(script.GunFramework)

LogService.MessageOut:Connect(function(message, messageType)
	if messageType == Enum.MessageType.MessageError then
		Debugger:error(message)
	elseif messageType == Enum.MessageType.MessageWarning then
		Debugger:warn(message)
	elseif messageType == Enum.MessageType.MessageOutput then
		Debugger:log(message)
	end
end)

local Primaries, Secondaries = {}, {}
for _, v in ReplicatedStorage.WeaponConfigs:GetChildren() do
	local cfg = require(v)
	if cfg.Poses then
		for _, k in cfg.Poses do
			GunFramework.Canim.cache_get_keyframe_sequence(k)
		end
	else
		warn(v.Name.." has no poses table!")
	end
	if cfg.Animations then
		for _, k in cfg.Animations do
			GunFramework.Canim.cache_get_keyframe_sequence(k)
		end
	else
		warn(v.Name.." has no animations table!")
	end
	if cfg.Type == "Primary" then
		Primaries[#Primaries+1] = v.Name
	elseif cfg.Type == "Secondary" then
		Secondaries[#Secondaries+1] = v.Name
	else
		warn(v.Name.." has invalid type!")
	end
end
print("Loaded!")

LoadingUi:cleanup()

local Menu = require(script.UI.SpawnMenu)
local handle = nil
local gunfw = nil

handle = Menu.new(Primaries, Secondaries)

Players.LocalPlayer.CharacterAdded:Connect(function()
	if handle then
		handle = handle:cleanup()
	end
	if gunfw then
		gunfw:cleanup()
		Players.LocalPlayer.CameraMode = Enum.CameraMode.Classic
	end

	handle = Menu.new(Primaries, Secondaries)
end)

InitWeapons:On(function(weps)
	gunfw = GunFramework.new(weps)
end)