local icons = require("icons")
local colors = require("colors")

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

local media = sbar.add("item", {
  position = "right",
  icon = {
    string = icons.media.play_pause,
    color = colors.white,
    padding_left = 8,
    padding_right = 6,
  },
  label = {
    drawing = false,
    width = 140,
    max_chars = 26,
    color = colors.white,
    padding_left = 0,
    padding_right = 8,
  },
  background = {
    color = colors.bg2,
    border_width = 1,
    border_color = colors.grey,
  },
  click_script = "media-control toggle-play-pause",
})

local cover = sbar.add("item", {
  position = "popup." .. media.name,
  drawing = false,
  icon = { drawing = false },
  label = { drawing = false },
  background = {
    drawing = true,
    color = colors.bg1,
    height = 64,
    image = { scale = 0.35, corner_radius = 6 },
  },
  width = 64,
})

local title = sbar.add("item", {
  position = "popup." .. media.name,
  drawing = false,
  icon = { drawing = false },
  label = {
    drawing = true,
    max_chars = 36,
    color = colors.white,
    y_offset = -8,
  },
  width = 200,
})

local artist = sbar.add("item", {
  position = "popup." .. media.name,
  drawing = false,
  icon = { drawing = false },
  label = {
    drawing = true,
    max_chars = 36,
    color = colors.with_alpha(colors.white, 0.7),
    y_offset = 8,
  },
  width = 200,
})

local progress_bg = sbar.add("item", {
  position = "popup." .. media.name,
  drawing = false,
  icon = { drawing = false },
  label = { drawing = false },
  background = { drawing = true, color = colors.bg1, height = 4, corner_radius = 2 },
  width = 200,
})

local progress_fg = sbar.add("item", {
  position = "popup." .. media.name,
  drawing = false,
  icon = { drawing = false },
  label = { drawing = false },
  background = { drawing = true, color = colors.blue, height = 4, corner_radius = 2 },
  width = 0,
})

local time = sbar.add("item", {
  position = "popup." .. media.name,
  drawing = false,
  icon = { drawing = false },
  label = {
    drawing = true,
    color = colors.with_alpha(colors.white, 0.7),
  },
  width = 200,
})

sbar.add("item", {
  position = "popup." .. media.name,
  icon = { string = icons.media.back },
  label = { drawing = false },
  click_script = "media-control previous-track",
})

sbar.add("item", {
  position = "popup." .. media.name,
  icon = { string = icons.media.play_pause },
  label = { drawing = false },
  click_script = "media-control toggle-play-pause",
})

sbar.add("item", {
  position = "popup." .. media.name,
  icon = { string = icons.media.forward },
  label = { drawing = false },
  click_script = "media-control next-track",
})

local function refresh()
  sbar.exec(state_script, function(raw)
    local fields = parse_kv(raw or "")
    local is_playing = fields.playing == "true"
    local elapsed = tonumber(fields.elapsed or "0") or 0
    local duration = tonumber(fields.duration or "1") or 1
    local track = fields.title or ""
    local performer = fields.artist or ""
    local artwork_path = fields.cover or ""

    media:set({
      label = { drawing = is_playing and track ~= "", string = track },
    })

    title:set({ label = { string = track ~= "" and track or "Nothing playing" } })
    artist:set({ label = { string = performer } })
    time:set({ label = { string = format_time(elapsed) .. " / " .. format_time(duration) } })

    local pct = 0
    if duration > 0 then
      pct = math.floor(math.max(0, math.min(1, elapsed / duration)) * 200)
    end
    progress_fg:set({ width = pct })

    if artwork_path ~= "" then
      cover:set({
        drawing = true,
        background = { image = { string = artwork_path } },
      })
    else
      cover:set({ drawing = false })
    end
  end)
end

local function popup(show)
  media:set({ popup = { drawing = show } })
  cover:set({ drawing = show })
  title:set({ drawing = show })
  artist:set({ drawing = show })
  progress_bg:set({ drawing = show })
  progress_fg:set({ drawing = show })
  time:set({ drawing = show })
end

refresh()

media:subscribe("mouse.entered", function()
  refresh()
  popup(true)
end)

media:subscribe("mouse.exited", function()
  popup(false)
end)

media:subscribe("mouse.clicked", function()
  sbar.delay(0.2, refresh)
end)
