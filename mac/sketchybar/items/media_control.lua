local icons = require("icons")
local colors = require("colors")

sbar.exec("killall media >/dev/null; $CONFIG_DIR/helpers/event_providers/media_provider/bin/media media_provider &")

local media_item = sbar.add("item", {
	position = "right",
	background = {
		color = colors.bg2,
		height = 28,
		corner_radius = 6,
		border_width = 1,
		border_color = colors.grey,
	},
	icon = {
		string = icons.media.play_pause,
		color = colors.white,
		font = { size = 10 },
		padding_left = 8,
		padding_right = 8,
	},
	label = {
		drawing = false,
		font = { size = 11 },
		color = colors.white,
		padding_left = 6,
		padding_right = 6,
		max_chars = 15,
		scrolling = true,
	},
	click_script = "media-control toggle-play-pause",
})

local media_popup = sbar.add("item", {
	position = "popup." .. media_item.name,
	align = "center",
	horizontal = true,
	drawing = false,
	background = {
		color = colors.popup.bg,
		border_width = 2,
		corner_radius = 10,
		border_color = colors.popup.border,
		shadow = { drawing = true },
	},
	blur_radius = 40,
})

local media_popup_artwork = sbar.add("item", {
	position = "popup." .. media_item.name,
	drawing = false,
	background = {
		drawing = false,
		color = colors.black,
		image = {
			scale = 0.9,
			corner_radius = 6,
		},
		height = 120,
		width = 120,
		margin_left = 8,
		padding = 4,
	},
})

local media_popup_info = sbar.add("item", {
	position = "popup." .. media_item.name,
	drawing = false,
	background = { drawing = false },
	icon = { drawing = false },
	label = {
		drawing = false,
		font = { size = 10 },
		color = colors.with_alpha(colors.white, 0.7),
		padding_left = 8,
		padding_right = 8,
		vertical_align = "middle",
		width = 200,
		max_width = 200,
	},
})

local media_popup_title = sbar.add("item", {
	position = "popup." .. media_item.name,
	drawing = false,
	background = { drawing = false },
	icon = { drawing = false },
	label = {
		drawing = false,
		font = { size = 13, style = "Semibold" },
		color = colors.white,
		padding_left = 8,
		padding_right = 8,
		max_chars = 30,
		y_offset = -8,
		width = 200,
		max_width = 200,
	},
})

local media_popup_artist = sbar.add("item", {
	position = "popup." .. media_item.name,
	drawing = false,
	background = { drawing = false },
	icon = { drawing = false },
	label = {
		drawing = false,
		font = { size = 11 },
		color = colors.white,
		padding_left = 8,
		padding_right = 8,
		max_chars = 30,
		y_offset = -20,
		width = 200,
		max_width = 200,
	},
})

local media_popup_progress_bg = sbar.add("item", {
	position = "popup." .. media_item.name,
	drawing = false,
	background = {
		drawing = true,
		color = colors.bg1,
		height = 4,
		corner_radius = 2,
	},
	label = { drawing = false },
	icon = { drawing = false },
	padding_left = 8,
	padding_right = 8,
	y_offset = -36,
	width = 200,
})

local media_popup_progress_fg = sbar.add("item", {
	position = "popup." .. media_item.name,
	drawing = false,
	background = {
		drawing = true,
		color = colors.blue,
		height = 4,
		corner_radius = 2,
	},
	label = { drawing = false },
	icon = { drawing = false },
	padding_left = 8,
	padding_right = 8,
	y_offset = -36,
	width = 0,
	max_width = 200,
})

	local media_popup_prev = sbar.add("item", {
	position = "popup." .. media_item.name,
	background = {
		drawing = true,
		color = colors.bg1,
		height = 32,
		width = 32,
		corner_radius = 6,
	},
	icon = {
		string = icons.media.back,
		color = colors.white,
		font = { size = 12 },
		padding_left = 0,
		padding_right = 0,
	},
	label = { drawing = false },
	click_script = "media-control previous-track",
})

local media_popup_play_pause = sbar.add("item", {
	position = "popup." .. media_item.name,
	background = {
		drawing = true,
		color = colors.blue,
		height = 40,
		width = 40,
		corner_radius = 8,
	},
	icon = {
		string = icons.media.play_pause,
		color = colors.white,
		font = { size = 16 },
		padding_left = 0,
		padding_right = 0,
	},
	label = { drawing = false },
	click_script = "media-control toggle-play-pause",
})

local media_popup_next = sbar.add("item", {
	position = "popup." .. media_item.name,
	background = {
		drawing = true,
		color = colors.bg1,
		height = 32,
		width = 32,
		corner_radius = 6,
	},
	icon = {
		string = icons.media.forward,
		color = colors.white,
		font = { size = 12 },
		padding_left = 0,
		padding_right = 0,
	},
	label = { drawing = false },
	click_script = "media-control next-track",
})

local interrupt = 0

local function format_time(micros)
	local total_seconds = math.floor(micros / 1000000)
	local minutes = math.floor(total_seconds / 60)
	local seconds = total_seconds % 60
	return string.format("%d:%02d", minutes, seconds)
end

	local function animate_popup(show)
		if show then
			interrupt = interrupt + 1
		else
			interrupt = interrupt - 1
		end
		
		sbar.animate("tanh", 200, function()
			media_item:set({ label = { drawing = show } })
			media_popup:set({ drawing = show })
			media_popup_artwork:set({ drawing = show })
			media_popup_info:set({ drawing = show })
			media_popup_title:set({ drawing = show })
			media_popup_artist:set({ drawing = show })
			media_popup_progress_bg:set({ drawing = show })
			media_popup_progress_fg:set({ drawing = show })
			media_popup_prev:set({ drawing = show })
			media_popup_play_pause:set({ drawing = show })
			media_popup_next:set({ drawing = show })
		end)
	end

	media_item:subscribe("media_change", function(env)
	local state = env.INFO.state or (env.INFO.playing and "playing") or "stopped"
	
	if state == "paused" or state == "stopped" or state == false then
		media_item:set({
			icon = { string = "􀊈" },
			label = { drawing = false },
		})
		media_popup:set({ drawing = false })
		return
	end
	
	local title = env.INFO.title or "?"
	local artist = env.INFO.artist or "?"
	local elapsed = tonumber(env.INFO.elapsedTimeMicros) or 0
	local duration = tonumber(env.INFO.durationMicros) or 1
	
	media_item:set({
		icon = { string = icons.media.play_pause },
		label = { drawing = true, string = title },
	})
	
	media_popup_info:set({ label = { string = format_time(elapsed) .. " / " .. format_time(duration) } })
	media_popup_title:set({ label = { string = title } })
	media_popup_artist:set({ label = { string = artist } })
	
	if duration > 0 then
		local percentage = math.min(100, (elapsed / duration) * 100)
		media_popup_progress_fg:set({ background = { width = (percentage / 100) * 200 } })
	end
	
	local artwork = env.INFO.artworkData or ""
	if artwork and #artwork > 0 then
		media_popup_artwork:set({
			drawing = true,
			background = { drawing = true, image = { string = artwork } },
		})
	else
		media_popup_artwork:set({ drawing = false })
	end
	
	animate_popup(true)
	interrupt = interrupt + 1
	sbar.delay(5, function() animate_popup(false) end)
end)

media_item:subscribe("mouse.entered", function(env)
	interrupt = interrupt + 1
	animate_popup(true)
end)

media_item:subscribe("mouse.exited", function(env)
	animate_popup(false)
end)

media_item:subscribe("mouse.clicked", function(env)
	animate_popup("toggle")
end)