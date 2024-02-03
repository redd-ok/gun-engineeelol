local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Lib.roact)

local Text = Roact.Component:extend("Text")

function Text:init(props)
	self:setState({
		pos = props.pos,
		size = props.size,

		highlight = props.highlight,
	})
end

function Text:render()
	return Roact.createElement("Frame", {
		Position = self.state.pos,
		Size = self.state.size,

		BackgroundTransparency = 0,
		BackgroundColor3 = self.state.highlight and Color3.fromRGB(173, 173, 173) or Color3.fromRGB(36, 36, 36),
		BorderSizePixel = 0,
	})
end

return Text