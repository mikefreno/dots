local colors = require("colors")

sbar.add("alias", "CleanShot X", {
	background = {
		height = 22,
		color = colors.bg1,
		border_color = colors.grey,
		drawing = true,
		border_width = 1,
	},
	icon = {
		padding_right = -4,
		padding_left = 0,
	},
	label = {
		padding_right = 2,
	},
	padding_right = -12,
	width = 34,
	position = "right",
	click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 'CleanShot X,Item-0'",
})

sbar.add("alias", "Cork", {
	background = {
		height = 22,
		color = colors.bg1,
		border_color = colors.grey,
		drawing = true,
		border_width = 1,
	},
	icon = {
		padding_right = -4,
		padding_left = 0,
	},
	label = {
		padding_right = 0,
	},
	padding_right = -8,
	width = 30,
	position = "right",
	click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 'Cork,Item-0'",
})

sbar.add("alias", "Control Center,Sound", {
	background = {
		height = 22,
		color = colors.bg1,
		border_color = colors.grey,
		drawing = true,
		border_width = 1,
	},
	position = "right",
	click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 'Control Center,Sound'",
})

sbar.exec(string.format("sketchybar --set 'Cork' alias.color=%s", colors.white))
sbar.exec(string.format("sketchybar --set 'CleanShot X' alias.color=%s", colors.white))
sbar.exec(string.format("sketchybar --set 'Control Center,Sound' alias.color=%s", colors.white))
