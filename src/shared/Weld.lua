return function(p0, p1, c0, c1)
	local Weld = Instance.new("Motor6D")
	Weld.Parent = p0
	Weld.Name = p1.Name
	if not c0 and not c1 then
		Weld.C0 = p1.CFrame:ToObjectSpace(p0.CFrame)
	else
		Weld.C0 = c0 or CFrame.new()
		Weld.C1 = c1 or CFrame.new()
	end
	Weld.Part0 = p0
	Weld.Part1 = p1
	return Weld
end