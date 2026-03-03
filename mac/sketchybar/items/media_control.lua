local icons = require("icons")
local colors = require("colors")

local PLAY_ICON = "􀊄"
local PAUSE_ICON = "􀊆"
local DOT_ICON = "􀀀"

local state_script = [[
json="$(media-control get --micros 2>/dev/null)"
if [ -z "$json" ]; then
  printf 'playing=false\nelapsed=0\nduration=1\ntitle=\nartist=\ncover=\n'
  exit 0
fi

playing="$(printf '%s' "$json" | jq -r '.playing // false')"
elapsed="$(printf '%s' "$json" | jq -r '.elapsedTimeMicros // 0')"
duration="$(printf '%s' "$json" | jq -r '.durationMicros // 1')"
title="$(printf '%s' "$json" | jq -r '.title // ""' | tr '\t\n' '  ')"
artist="$(printf '%s' "$json" | jq -r '.artist // ""' | tr '\t\n' '  ')"
artwork_data="$(printf '%s' "$json" | jq -r '.artworkData // ""')"
artwork_mime="$(printf '%s' "$json" | jq -r '.artworkMimeType // ""')"

cover=""
if [ -n "$artwork_data" ]; then
  ext="jpg"
  case "$artwork_mime" in
    image/png) ext="png" ;;
    image/jpeg) ext="jpg" ;;
  esac
  cover="/tmp/sketchybar-media-cover.$ext"
  printf '%s' "$artwork_data" | base64 -d > "$cover" 2>/dev/null || cover=""
fi

printf 'playing=%s\nelapsed=%s\nduration=%s\ntitle=%s\nartist=%s\ncover=%s\n' "$playing" "$elapsed" "$duration" "$title" "$artist" "$cover"
]]

local function parse_kv(s)
  local out = {}
  for line in string.gmatch(s or "", "[^\n]+") do
    local key, value = string.match(line, "^([a-z]+)=(.*)$")
    if key then
      out[key] = value
    end
  end
  return out
end

local function format_time(micros)
  local total_seconds = math.floor((tonumber(micros) or 0) / 1000000)
  local minutes = math.floor(total_seconds / 60)
  local seconds = total_seconds % 60
  return string.format("%d:%02d", minutes, seconds)
end

local cache = {
  track = "",
  artist = "",
  cover = "",
  duration = 1,
  elapsed = 0,
  playing = false,
}

local popup_open = false

local media_toggle = sbar.add("item", "widgets.media.toggle", {
  position = "left",
  background = { color = colors.bg1, border_width = 0 },
  icon = {
    string = PLAY_ICON,
    color = colors.white,
    font = { size = 8 },
    padding_left = 8,
    padding_right = 4,
  },
  label = { drawing = false },
  click_script = "media-control toggle-play-pause",
})

local media_title = sbar.add("item", "widgets.media.title", {
  position = "left",
  width = 148,
  background = { color = colors.bg1, border_width = 0 },
  icon = { drawing = false },
  label = {
    drawing = false,
    max_chars = 28,
    color = colors.white,
    padding_left = 0,
    padding_right = 8,
  },
  popup = {
    align = "center",
  },
})

local cover = sbar.add("item", {
  position = "popup." .. media_title.name,
  drawing = false,
  width = 220,
  icon = { drawing = false },
  label = { drawing = false },
  background = {
    drawing = true,
    color = colors.bg1,
    height = 80,
    image = { scale = 0.44, corner_radius = 6 },
  },
})

local title = sbar.add("item", {
  position = "popup." .. media_title.name,
  drawing = false,
  width = 220,
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
  width = 220,
  icon = { drawing = false },
  label = {
    max_chars = 44,
    color = colors.with_alpha(colors.white, 0.7),
    y_offset = 8,
  },
})

local progress_bg = sbar.add("item", {
  position = "popup." .. media_title.name,
  drawing = false,
  width = 220,
  icon = { drawing = false },
  label = { drawing = false },
  background = { drawing = true, color = colors.bg1, height = 5, corner_radius = 3 },
})

local progress_fg = sbar.add("item", {
  position = "popup." .. media_title.name,
  drawing = false,
  width = 0,
  icon = { drawing = false },
  label = { drawing = false },
  background = { drawing = true, color = colors.blue, height = 5, corner_radius = 3 },
})

local progress_dot = sbar.add("item", {
  position = "popup." .. media_title.name,
  drawing = false,
  width = 220,
  icon = {
    string = DOT_ICON,
    color = colors.yellow,
    font = { size = 10 },
  },
  label = { drawing = false },
})

local time = sbar.add("item", {
  position = "popup." .. media_title.name,
  drawing = false,
  width = 220,
  icon = { drawing = false },
  label = {
    color = colors.with_alpha(colors.white, 0.7),
  },
})

local controls = sbar.add("item", {
  position = "popup." .. media_title.name,
  drawing = false,
  width = 220,
  icon = { drawing = false },
  label = {
    string = "􀊊   􀊄   􀊌",
    color = colors.white,
    align = "center",
  },
})

local function set_popup(show)
  popup_open = show
  media_title:set({ popup = { drawing = show } })
  cover:set({ drawing = show })
  title:set({ drawing = show })
  artist:set({ drawing = show })
  progress_bg:set({ drawing = show })
  progress_fg:set({ drawing = show })
  progress_dot:set({ drawing = show })
  time:set({ drawing = show })
  controls:set({ drawing = show })
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
end

local function refresh()
  sbar.exec(state_script, function(raw)
    local fields = parse_kv(raw or "")
    local is_playing = fields.playing == "true"
    local elapsed = tonumber(fields.elapsed or "0") or 0
    local duration = tonumber(fields.duration or "1") or 1
    local track = fields.title or ""
    local performer = fields.artist or ""
    local artwork_path = fields.cover or ""

    if track ~= "" then cache.track = track end
    if performer ~= "" then cache.artist = performer end
    if artwork_path ~= "" then cache.cover = artwork_path end
    if duration > 1 then cache.duration = duration end
    if is_playing then cache.elapsed = elapsed elseif elapsed == 0 then elapsed = cache.elapsed end
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
    time:set({ label = { string = format_time(elapsed) .. " / " .. format_time(shown_duration) } })
    controls:set({ label = { string = "􀊊   " .. icon .. "   􀊌" } })

    local pct = 0
    if shown_duration > 0 then
      pct = math.floor(math.max(0, math.min(1, elapsed / shown_duration)) * 220)
    end
    progress_fg:set({ width = pct })
    progress_dot:set({ icon = { x_offset = pct - 110 } })

    if shown_cover ~= "" then
      cover:set({ drawing = true, background = { image = { string = shown_cover } } })
    else
      cover:set({ drawing = false })
    end
  end)
end

refresh()

media_toggle:subscribe("mouse.clicked", function()
  sbar.delay(0.2, refresh)
end)

media_title:subscribe("mouse.clicked", function()
  refresh()
  set_popup(not popup_open)
end)

progress_bg:subscribe("mouse.clicked", function(env)
  apply_seek_from_percentage(env.PERCENTAGE)
  sbar.delay(0.05, refresh)
end)

progress_fg:subscribe("mouse.clicked", function(env)
  apply_seek_from_percentage(env.PERCENTAGE)
  sbar.delay(0.05, refresh)
end)

progress_dot:subscribe("mouse.scrolled", function(env)
  local delta = tonumber(env.SCROLL_DELTA or "0") or 0
  if delta == 0 then
    return
  end
  local step = (delta > 0) and -5 or 5
  local target = math.max(0, (cache.elapsed / 1000000) + step)
  sbar.exec("media-control seek " .. string.format("%.3f", target))
  sbar.delay(0.05, refresh)
end)

controls:subscribe("mouse.clicked", function(env)
  local pct = tonumber(env.PERCENTAGE or "0") or 0
  if pct < 33 then
    sbar.exec("media-control previous-track")
  elseif pct < 66 then
    sbar.exec("media-control toggle-play-pause")
  else
    sbar.exec("media-control next-track")
  end
  sbar.delay(0.2, refresh)
end)
