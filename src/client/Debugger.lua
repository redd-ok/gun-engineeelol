local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local roact = require(ReplicatedStorage.Lib.roact)

local debugger = {}

local Logs

local function getTime()
	local temp = os.date("*t", os.time())
	return tostring(temp.hour)..":"..tostring(temp.min)..":"..tostring(temp.sec)
end

do
	local config = {
		font = Enum.Font.Code,
		textSize = 14,
		textStrokeColor = Color3.fromRGB(29, 29, 29),
		textStrokeTransparency = 0.3,
		backgroundColor = Color3.fromRGB(43, 43, 43),
		backgroundTransparency = 0.5,
	}

	function Logs(logs)
		local logUIs = {}
		local y = 0

		for i = #logs, 1, -1 do
			local log = logs[i]
			local textsize = TextService:GetTextSize(log[1], config.textSize, config.font, Vector2.new(999, 999))
			y += textsize.Y+16
			logUIs[i] = roact.createElement("TextLabel", {
				Text = log[1],
				Font = config.font,
				TextSize = config.textSize,
				TextColor3 = log[2],
				TextStrokeColor3 = config.textStrokeColor,
				TextStrokeTransparency = config.textStrokeTransparency,
				BackgroundColor3 = config.backgroundColor,
				BackgroundTransparency = config.backgroundTransparency,

				Size = UDim2.new(0, textsize.X + 6, 0, textsize.Y + 6),
				Position = UDim2.new(0, 5, 1, -y)
			})
		end

		return roact.createElement("ScreenGui", {ResetOnSpawn = false},  logUIs)
	end
end

function debugger.new()
	local self = {
		handle = roact.mount(roact.createElement(Logs, {}), Players.LocalPlayer.PlayerGui, "Debugger UI"),
		logs = {}
	}

	return setmetatable(self, {__index = debugger})
end

function debugger:log(text)
	local timeStamp = getTime()

	local log = {string.format("%s [%s] ", timeStamp, "LOG")..text, Color3.fromRGB(253, 253, 253)}

	table.insert(self.logs, log)
	roact.update(self.handle, roact.createElement(Logs, self.logs))

	task.delay(10, function()
		local idx = 1
		for i, v in self.logs do
			if v == log then
				idx = i
			end
		end
		table.remove(self.logs, idx)
		roact.update(self.handle, roact.createElement(Logs, self.logs))
	end)
end

function debugger:warn(text)
	local timeStamp = getTime()

	local log = {string.format("%s [%s] ", timeStamp, "WARN")..text, Color3.fromRGB(239, 119, 0)}

	table.insert(self.logs, log)
	roact.update(self.handle, roact.createElement(Logs, self.logs))

	task.delay(15, function()
		local idx = 1
		for i, v in self.logs do
			if v == log then
				idx = i
			end
		end
		table.remove(self.logs, idx)
		roact.update(self.handle, roact.createElement(Logs, self.logs))
	end)
end

function debugger:error(text)
	local timeStamp = getTime()

	local log = {string.format("%s [%s] ", timeStamp, "ERROR")..text, Color3.fromRGB(238, 78, 78)}

	table.insert(self.logs, log)
	roact.update(self.handle, roact.createElement(Logs, self.logs))

	task.delay(25, function()
		local idx = 1
		for i, v in self.logs do
			if v == log then
				idx = i
			end
		end
		table.remove(self.logs, idx)
		roact.update(self.handle, roact.createElement(Logs, self.logs))
	end)
end

return debugger
