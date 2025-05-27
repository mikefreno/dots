local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Execute both event providers
sbar.exec("killall cpu_load >/dev/null; $CONFIG_DIR/helpers/event_providers/cpu_load/bin/cpu_load cpu_update 2.0")
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
	icon = { string = icons.cpu },
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
	padding_left = 0
})

local cpu = sbar.add("graph", "widgets.cpu", 42, {
	position = "right",
	graph = { color = colors.blue },
	background = {
		height = 22,
		color = { alpha = 0 },
		border_color = { alpha = 0 },
		drawing = true,
	},
	icon = { drawing = false },
	label = {
		string = "cpu ??%",
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
	padding_left = settings.paddings + 6,
	padding_right = 0
})



-- Background around the combined widget
sbar.add("bracket", "widgets.hw_stats.bracket", {
	gpu.name,
	cpu.name
}, {
	background = { color = colors.bg1 },
})

sbar.add("item", "widgets.hw_stats.padding", {
	position = "right",
	width = settings.group_paddings,
})

-- CPU updates
cpu:subscribe("cpu_update", function(env)
	local load = tonumber(env.total_load)
	cpu:push({ load / 100. })

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

	cpu:set({
		graph = { color = color },
		label = "cpu " .. env.total_load .. "%",
	})
end)

-- GPU updates
gpu:subscribe("gpu_update", function(env)
	local load = tonumber(env.gpu_total_util)
	gpu:push({ load / 100. })

	local color = colors.purple
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

cpu:subscribe("mouse.clicked", function(env)
	sbar.exec("open -a 'Activity Monitor'")
end)

gpu:subscribe("mouse.clicked", function(env)
	sbar.exec("open -a 'Activity Monitor' || open -a 'Xcode' --args GPUReport")
end)
