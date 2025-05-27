local colors = require("colors")

-- Equivalent to the --bar domain
sbar.bar({
	topmost = "window",
	height = 36,
	color = colors.bar.bg,
	border_color = colors.bar.border,
	--border_width = 2,
	padding_right = 10,
	padding_left = 10,
	--corner_radius = 12,
	y_offset = 4,
	--margin = 10,
	--blur_radius = 20,
	--shadow = true,
	notch_width = 200
})
