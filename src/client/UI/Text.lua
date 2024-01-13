local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Lib.roact)

local Text = Roact.Component:extend("Text")

function Text:init(props)
	self:setState({
		text = props.text,
		pos = props.pos,
		size = props.size,

		textsize = props.textsize or 16,

		highlight= props.highlight,
	})
end

function Text:render()
	return Roact.createElement("TextLabel", {
		Text = self.state.text,
		Position = self.state.pos,
		Size = self.state.size,

		BackgroundTransparency = 0.35,
		BackgroundColor3 = self.state.highlight and Color3.fromRGB(173, 173, 173) or Color3.fromRGB(36, 36, 36),
		TextColor3 = Color3.fromRGB(224, 224, 224),
		FontFace = Font.new("rbxassetid://12187365364"),
		TextSize = self.state.textsize,
		BorderSizePixel = 0,
	}, {
		Roact.createElement("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.fromRGB(102, 102, 102),
			Thickness = 2,
		})
	})
end

return Text