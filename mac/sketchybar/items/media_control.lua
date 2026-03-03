local icons = require("icons")
local colors = require("colors")

local config_dir = os.getenv("HOME") .. "/.config/sketchybar"
local tick_script = config_dir .. "/helpers/event_providers/media_provider/bin/media_tick.sh"
sbar.exec("sketchybar --add event media_tick_update")
sbar.exec("pkill -f media_tick.sh >/dev/null 2>&1; " .. tick_script .. " >/dev/null 2>&1 &")

local PLAY_ICON = "􀊄"
local PAUSE_ICON = "􀊆"
local BAR_WIDTH = 220
local CTRL_WIDTH = 40

local cache = {
	track = "",
	artist = "",
	cover = "",
	duration = 1,
	elapsed = 0,
	playing = false,
}

local popup_open = false
local progress_clock_active = false

local function format_time(micros)
	local total_seconds = math.floor((tonumber(micros) or 0) / 1000000)
	local minutes = math.floor(total_seconds / 60)
	local seconds = total_seconds % 60
	return string.format("%d:%02d", minutes, seconds)
end

local media_toggle = sbar.add("item", "widgets.media.toggle", {
	position = "left",
	background = { drawing = false },
	icon = {
		string = PLAY_ICON,
		color = colors.white,
		font = { size = 12 },
		padding_left = 4,
		padding_right = 4,
	},
	label = { drawing = false },
	click_script = "media-control toggle-play-pause",
})

local media_title = sbar.add("item", "widgets.media.title", {
	position = "left",
	width = 148,
	background = { drawing = false },
	icon = { drawing = false },
	label = {
		drawing = false,
		max_chars = 28,
		color = colors.white,
		padding_right = 4,
	},
	popup = {
		align = "center",
	},
})

sbar.add("bracket", "widgets.media.bracket", {
	media_toggle.name,
	media_title.name,
}, {
	background = {
		color = colors.bg1,
		border_width = 0,
	},
})

local cover = sbar.add("item", {
	position = "popup." .. media_title.name,
	drawing = false,
	width = 64,
	icon = { drawing = false },
	label = { drawing = false },
	background = {
		drawing = true,
		color = colors.bg2,
		height = 64,
		image = { scale = 0.6, corner_radius = 6 },
	},
})

local title = sbar.add("item", {
	position = "popup." .. media_title.name,
	drawing = false,
	width = BAR_WIDTH,
	icon = { drawing = false },
	label = {
		max_chars = 44,
		color = colors.white,
		y_offset = -8,
	},
})

local artist = sbar.add("item", {
	position = "popup." .. media_title.name,
	drawing = false,
	width = BAR_WIDTH,
	icon = { drawing = false },
	label = {
		max_chars = 44,
		color = colors.with_alpha(colors.white, 0.7),
		y_offset = 8,
	},
})

local progress_slider = sbar.add("slider", BAR_WIDTH, {
	position = "popup." .. media_title.name,
	drawing = false,
	slider = {
		highlight_color = colors.blue,
		percentage = 0,
		background = {
			height = 6,
			corner_radius = 3,
			color = colors.bg1,
		},
		knob = {
			string = "􀀁",
			drawing = true,
			color = colors.white,
			font = { size = 10.0 },
		},
	},
	background = { color = colors.transparent, height = 2, y_offset = -20 },
	icon = { drawing = false },
	label = { drawing = false },
})

local time_display = sbar.add("item", {
	position = "popup." .. media_title.name,
	drawing = false,
	width = BAR_WIDTH,
	icon = { drawing = false },
	label = {
		color = colors.with_alpha(colors.white, 0.7),
		align = "center",
		font = { size = 11.0 },
	},
})

--local ctrl_prev = sbar.add("item", {
--position = "popup." .. media_title.name,
--drawing = false,
--width = CTRL_WIDTH,
--icon = {
--string = icons.media.back,
--color = colors.white,
--font = { size = 12.0 },
--align = "center",
--padding_left = 0,
--padding_right = 0,
--},
--label = { drawing = false },
--})

--local ctrl_play = sbar.add("item", {
--position = "popup." .. media_title.name,
--drawing = false,
--width = CTRL_WIDTH,
--icon = {
--string = PLAY_ICON,
--color = colors.white,
--font = { size = 12.0 },
--align = "center",
--padding_left = 0,
--padding_right = 0,
--},
--label = { drawing = false },
--})

--local ctrl_next = sbar.add("item", {
--position = "popup." .. media_title.name,
--drawing = false,
--width = CTRL_WIDTH,
--icon = {
--string = icons.media.forward,
--color = colors.white,
--font = { size = 12.0 },
--align = "center",
--padding_left = 0,
--padding_right = 0,
--},
--label = { drawing = false },
--})

local popup_items = { cover, title, artist, progress_slider, time_display }

local function render_progress()
	local shown_duration = cache.duration > 1 and cache.duration or 1
	local shown_elapsed = math.max(0, math.min(cache.elapsed, shown_duration))
	local pct = math.floor(math.max(0, math.min(1, shown_elapsed / shown_duration)) * 100)
	progress_slider:set({ slider = { percentage = pct } })
	time_display:set({ label = { string = format_time(shown_elapsed) .. " / " .. format_time(shown_duration) } })
end

local function stop_progress_clock()
	progress_clock_active = false
end

local function start_progress_clock()
	if progress_clock_active then
		return
	end
	progress_clock_active = true
	local function tick()
		if not progress_clock_active or not popup_open or not cache.playing then
			progress_clock_active = false
			return
		end
		cache.elapsed = math.min(cache.elapsed + 1000000, cache.duration)
		render_progress()
		sbar.delay(1, tick)
	end
	sbar.delay(1, tick)
end

local function set_popup(show)
	popup_open = show
	media_title:set({ popup = { drawing = show } })
	for _, item in ipairs(popup_items) do
		item:set({ drawing = show })
	end
	--ctrl_prev:set({ drawing = show })
	--ctrl_play:set({ drawing = show })
	--ctrl_next:set({ drawing = show })
	if show and cache.playing then
		start_progress_clock()
	else
		stop_progress_clock()
	end
end

local function apply_seek_from_percentage(percentage)
	local pct = tonumber(percentage)
	if not pct or cache.duration <= 0 then
		return
	end
	local target_micros = math.floor(math.max(0, math.min(100, pct)) / 100 * cache.duration)
	local target_seconds = target_micros / 1000000
	sbar.exec("media-control seek " .. string.format("%.3f", target_seconds))
	cache.elapsed = target_micros
	render_progress()
end

local function update_from_event(env)
	local is_playing = env.playing == "true"
	local elapsed = tonumber(env.elapsed or "0") or 0
	local duration = tonumber(env.duration or "1") or 1
	local track = env.title or ""
	local performer = env.artist or ""
	local artwork_path = env.cover or ""

	if track ~= "" then
		cache.track = track
	end
	if performer ~= "" then
		cache.artist = performer
	end
	if artwork_path ~= "" then
		cache.cover = artwork_path
	end
	if duration > 1 then
		cache.duration = duration
	end
	if is_playing then
		if math.abs(elapsed - cache.elapsed) > 1500000 or not cache.playing then
			cache.elapsed = elapsed
		end
	else
		elapsed = cache.elapsed
	end
	cache.playing = is_playing

	local shown_track = track ~= "" and track or cache.track
	local shown_artist = performer ~= "" and performer or cache.artist
	local shown_cover = artwork_path ~= "" and artwork_path or cache.cover
	local shown_duration = duration > 1 and duration or cache.duration

	local icon = is_playing and PAUSE_ICON or PLAY_ICON
	media_toggle:set({ icon = { string = icon } })
	media_title:set({ label = { drawing = shown_track ~= "", string = shown_track } })

	title:set({ label = { string = shown_track ~= "" and shown_track or "Nothing played yet" } })
	artist:set({ label = { string = shown_artist } })
	--ctrl_play:set({ icon = { string = icon } })

	render_progress()

	if shown_cover ~= "" then
		cover:set({
			drawing = popup_open,
			background = {
				image = { string = shown_cover, scale = 0.66, corner_radius = 6 },
			},
		})
	else
		cover:set({ drawing = false })
	end

	if popup_open and cache.playing then
		start_progress_clock()
	else
		stop_progress_clock()
	end
end

media_title:subscribe("media_tick_update", function(env)
	update_from_event(env)
end)

media_toggle:subscribe("mouse.clicked", function()
	sbar.delay(0.2, function()
		sbar.exec("sketchybar --trigger media_tick_update")
	end)
end)

media_title:subscribe("mouse.clicked", function()
	set_popup(not popup_open)
end)

progress_slider:subscribe("mouse.clicked", function(env)
	apply_seek_from_percentage(env.PERCENTAGE)
end)

--ctrl_prev:subscribe("mouse.clicked", function()
--sbar.exec("media-control previous-track")
--end)

--ctrl_play:subscribe("mouse.clicked", function()
--sbar.exec("media-control toggle-play-pause")
--end)

--ctrl_next:subscribe("mouse.clicked", function()
--sbar.exec("media-control next-track")
--end)
