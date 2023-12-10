local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Lib.roact)

local Button = Roact.Component:extend("Button")

function Button:init()
end

function Button:render()
	-- print(self.state.highlight)
	return Roact.createElement("TextButton", {
		Text = self.props.text,
		Position = self.props.pos,
		Size = self.props.size,

		[Roact.Event.MouseButton1Click] = self.props.onClick,

		BackgroundTransparency = 0.35,
		BackgroundColor3 = self.props.highlight and Color3.fromRGB(173, 173, 173) or Color3.fromRGB(36, 36, 36),
		TextColor3 = Color3.fromRGB(224, 224, 224),
		FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
		TextSize = self.props.textsize,
		BorderSizePixel = 0,
	})
end

return Button