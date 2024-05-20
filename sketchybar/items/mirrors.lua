local colors = require("colors")
local settings = require("settings")

sbar.add("item", "mirrors.cleanshot.icon", {
	background = {
		height = 22,
		color = colors.bg1,
		border_color = colors.grey,
		border_width = 1,
	},
	icon = {
		string = "􀐩",
		width = 20,
		padding_right = 0,
		padding_left = 5,
		align = "center",
		color = colors.white,
		font = {
			style = settings.font.style_map["Regular"],
			size = 14.0,
		},
	},
	position = "right",
	click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 'CleanShot X,Item-0'",
})

sbar.add("item", "mirrors.cork.icon", {
	background = {
		height = 22,
		color = colors.bg1,
		border_color = colors.grey,
		border_width = 1,
	},
	icon = {
		string = "􀐯",
		width = 20,
		padding_right = 6,
		padding_left = 5,
		color = colors.white,
		font = {
			style = settings.font.style_map["Regular"],
			size = 14.0,
		},
	},
	position = "right",
	click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 'Cork,Item-0'",
})
