-- thank you blackshibe x2
-- (editted a bit to make selene and roblox lsp shut the hell up)

-- Constants

local ITERATIONS	= 8

-- Module

local SPRING	= {}

-- Functions 

function SPRING.new(mass, force, damping, speed, default)
	local spring	= setmetatable({
		Target		= default or Vector3.new();
		Position	= default or Vector3.new();
		Velocity	= default or Vector3.new();
		
		Mass		= mass or 5;
		Force		= force or 50;
		Damping		= damping or 4;
		Speed		= speed  or 4;
	}, {__index 	= SPRING})
	
	return spring
end

function SPRING:shove(force)
	local x, y, z	= force.X, force.Y, force.Z
	if x ~= x or x == math.huge or x == -math.huge then
		x	= 0
	end
	if y ~= y or y == math.huge or y == -math.huge then
		y	= 0
	end
	if z ~= z or z == math.huge or z == -math.huge then
		z	= 0
	end
	self.Velocity	= self.Velocity + Vector3.new(x, y, z)
end

function SPRING:update( dt)
	local scaledDeltaTime = math.min(dt,1) * self.Speed / ITERATIONS
	
	for _ = 1, ITERATIONS do
		local iterationForce= self.Target - self.Position
		local acceleration	= (iterationForce * self.Force) / self.Mass
		
		acceleration		= acceleration - self.Velocity * self.Damping
		
		self.Velocity	= self.Velocity + acceleration * scaledDeltaTime
		self.Position	= self.Position + self.Velocity * scaledDeltaTime
	end
	
	return self.Position
end

-- Return

return SPRING