local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- Padding item required because of bracket

local gear = sbar.add("item", {
	icon = {
		font = { size = 16.0 },
		string = icons.gear,
		padding_right = 6,
		padding_left = 5,
	},
	label = { drawing = false },
	background = {
		color = colors.bg2,
		border_color = colors.black,
		border_width = 1,
	},
	padding_left = 1,
	padding_right = 1,
	position = "right",

	click_script = "open -a 'System Settings'",
})

-- Double border for apple using a single item bracket
sbar.add("bracket", { gear.name }, {
	background = {
		color = colors.transparent,
		height = 30,
		border_color = colors.grey,
	},
})

-- Padding item required because of bracket
