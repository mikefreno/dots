local colors = require("colors")
local settings = require("settings")

sbar.add("item", "mirrors.controlcenter.icon", {
	background = {
		height = 24,
		color = colors.bg1,
		border_color = colors.grey,
		border_width = 1,
		padding_right = 6,
		padding_left = 0,
	},
	icon = {
		string = "􀜊",
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
	click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 'Control Center,BentoBox-0'",
})
-- broken atm due to macos() changes
--sbar.add("item", "mirrors.betterdisplay.icon", {
--background = {
--height = 24,
--color = colors.bg1,
--border_color = colors.grey,
--border_width = 1,
--},
--icon = {
--string = "􀢹",
--width = 20,
--padding_right = 0,
--padding_left = 5,
--align = "center",
--color = colors.white,
--font = {
--style = settings.font.style_map["Regular"],
--size = 14.0,
--},
--},
--position = "right",
--click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s ''",
--})
