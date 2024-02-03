local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Red = require(ReplicatedStorage.Lib.Red)
local Guard = require(ReplicatedStorage.Lib.guard)

local Check = Guard.List(Guard.Instance)

return Red.Event("InitWeps", function(weps)
	return Check(weps)
end)