local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")

local Debugger = require(script.Debugger).new()

local InitWeapons = require(ReplicatedStorage.Events.initweps):Client()

LogService.MessageOut:Connect(function(message, messageType)
	if messageType == Enum.MessageType.MessageError then
		Debugger:error(message)
	elseif messageType == Enum.MessageType.MessageWarning then
		Debugger:warn(message)
	elseif messageType == Enum.MessageType.MessageOutput then
		Debugger:log(message)
	end
end)

local Menu = require(script.SpawnMenu)
local handle = nil

if Players.LocalPlayer.Character then
	handle = Menu.new()
end

Players.LocalPlayer.CharacterAdded:Connect(function()
	if handle then
		handle = handle:Unmount()
	end

	handle = Menu.new()
end)

InitWeapons:On(function()
	-- to be do
end)