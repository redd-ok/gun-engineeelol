local gunhandler = {}

function gunhandler.new(weapons)
	local self = {Connections={}, Weapons = weapons, WeaponCache = {}}
	self.Connections.PreRender = game:GetService("RunService").PreRender:Connect(function(deltaTimeRender)
		self:step(deltaTimeRender)
	end)

	return setmetatable(self, {__index = gunhandler})
end

function gunhandler:GenViewmodel()
	
end

function gunhandler:step()
	
end

function gunhandler:cleanup()
	for _, v in self.Connections do
		v:Disconnect()
	end
	
	for _, v in self.WeaponCache do
		v:Destroy()
	end
end

return gunhandler