local colors = require("colors")

-- Equivalent to the --bar domain
sbar.bar({
	topmost = "window",
	height = 40,
	color = colors.bar.bg,
	border_color = colors.bar.border,
	border_width = 2,
	padding_right = 8,
	padding_left = 8,
	corner_radius = 90,
	y_offset = 6,
	margin = 12,
	blur_radius = 20,
})
