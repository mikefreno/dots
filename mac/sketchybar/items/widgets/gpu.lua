local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Execute the GPU event provider (using the C code we created earlier)
sbar.exec("killall gpu_load >/dev/null; $CONFIG_DIR/helpers/event_providers/gpu_load/bin/gpu_load gpu_update 2.0")

local gpu = sbar.add("graph", "widgets.gpu", 42, {
	position = "right",
	graph = { color = colors.purple },
	background = {
		height = 22,
		color = { alpha = 0 },
		border_color = { alpha = 0 },
		drawing = true,
	},
	icon = { string = icons.cpu }, -- Make sure you have a GPU icon defined
	label = {
		string = "gpu ??%",
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 9.0,
		},
		align = "right",
		padding_right = 0,
		width = 0,
		y_offset = 4,
	},
	padding_right = settings.paddings + 6,
})

gpu:subscribe("gpu_update", function(env)
	local load = tonumber(env.gpu_total_util)
	gpu:push({ load / 100. })

	local color = colors.blue
	if load > 30 then
		if load < 60 then
			color = colors.yellow
		elseif load < 80 then
			color = colors.orange
		else
			color = colors.red
		end
	end

	gpu:set({
		graph = { color = color },
		label = "gpu " .. load .. "%",
	})
end)

gpu:subscribe("mouse.clicked", function(env)
	-- Open Activity Monitor or GPU-specific tool
	sbar.exec("open -a 'Activity Monitor' || open -a 'Xcode' --args GPUReport")
end)

-- Background around the gpu item
sbar.add("bracket", "widgets.gpu.bracket", { gpu.name }, {
	background = { color = colors.bg1 },
})

sbar.add("item", "widgets.gpu.padding", {
	position = "right",
	width = settings.group_paddings,
})
