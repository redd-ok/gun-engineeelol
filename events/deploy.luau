local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Red = require(ReplicatedStorage.Lib.Red)
local Guard = require(ReplicatedStorage.Lib.guard)

local Check = Guard.Check(Guard.String)

return Red.Event("Deploy", function(primary, secondary)
	return Check(primary), Check(secondary)
end)