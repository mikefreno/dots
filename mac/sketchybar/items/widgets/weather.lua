local colors = require("colors")
local settings = require("settings")
local weather_icons_day = {
	["1000"] = "􀆮", -- Sunny/113
	["1003"] = "􀇕", -- Partly cloudy/116
	["1006"] = "􀇃", -- Cloudy/119
	["1009"] = "􀆸", -- Overcast/122
	["1030"] = "􁷍", -- Mist/143
	["1063"] = "􀇅", -- Patchy rain possible/176
	["1066"] = "􀇏", -- Patchy snow possible/179
	["1069"] = "􀇑", -- Patchy sleet possible/182
	["1072"] = "􀇑", -- Patchy freezing drizzle possible/185
	["1087"] = "􀇓", -- Thundery outbreaks possible/200
	["1114"] = "􀇏", -- Blowing snow/227
	["1117"] = "􀇏", -- Blizzard/230
	["1135"] = "􀇋", -- Fog/248
	["1147"] = "􀇋", -- Freezing fog/260
	["1150"] = "􀇅", -- Patchy light drizzle/263
	["1153"] = "􀇑", -- Light drizzle/266
	["1168"] = "􀇑", -- Freezing drizzle/281
	["1171"] = "􀇑", -- Heavy freezing drizzle/284
	["1180"] = "􀇅", -- Patchy light rain/293
	["1183"] = "􀇅", -- Light rain/296
	["1186"] = "􀇇", -- Moderate rain at times/299
	["1189"] = "􀇇", -- Moderate rain/302
	["1192"] = "􀇉", -- Heavy rain at times/305
	["1195"] = "􀇉", -- Heavy rain/308
	["1198"] = "􀇑", -- Light freezing rain/311
	["1201"] = "􀇑", -- Moderate or heavy freezing rain/314
	["1204"] = "􀇑", -- Light sleet/317
	["1207"] = "􀇑", -- Moderate or heavy sleet/320
	["1210"] = "􀇑", -- Patchy light snow/323
	["1213"] = "􀇏", -- Light snow/326
	["1216"] = "􀇏", -- Patchy moderate snow/329
	["1219"] = "􀇏", -- Moderate snow/332
	["1222"] = "􀇏", -- Patchy heavy snow/335
	["1225"] = "􀇏", -- Heavy snow/338
	["1237"] = "􀇏", -- Ice pellets/350
	["1240"] = "􀇇", -- Light rain shower/353
	["1243"] = "􀇉", -- Moderate or heavy rain shower/356
	["1246"] = "􀇉", -- Torrential rain shower/359
	["1249"] = "􀇑", -- Light sleet showers/362
	["1252"] = "􀇑", -- Moderate or heavy sleet showers/365
	["1255"] = "􀇏", -- Light snow showers/368
	["1258"] = "􀇏", -- Moderate or heavy snow showers/371
	["1261"] = "􀇓", -- Light showers of ice pellets/374
	["1264"] = "􀇍", -- Moderate or heavy showers of ice pellets/377
	["1273"] = "􀇟", -- Patchy light rain with thunder/386
	["1276"] = "􀇟", -- Moderate or heavy rain with thunder/389
	["1279"] = "􀇟", -- Patchy light snow with thunder/392
	["1282"] = "􀇟", -- Moderate or heavy snow with thunder/395
}

local weather_icons_night = {
	["1000"] = "􀆺", -- Clear/113
	["1003"] = "􀇛", -- Partly cloudy/116
	["1006"] = "􀇛", -- Cloudy/119
	["1009"] = "􁑰", -- Overcast/122
	["1030"] = "􀇅", -- Mist/143
	["1063"] = "􀇅", -- Patchy rain possible/176
	["1066"] = "􀇏", -- Patchy snow possible/179
	["1069"] = "􀇑", -- Patchy sleet possible/182
	["1072"] = "􀇑", -- Patchy freezing drizzle possible/185
	["1087"] = "􀇡", -- Thundery outbreaks possible/200
	["1114"] = "􀇏", -- Blowing snow/227
	["1117"] = "􀇏", -- Blizzard/230
	["1135"] = "􀇋", -- Fog/248
	["1147"] = "􀇋", -- Freezing fog/260
	["1150"] = "􀇅", -- Patchy light drizzle/263
	["1153"] = "􀇑", -- Light drizzle/266
	["1168"] = "􀇑", -- Freezing drizzle/281
	["1171"] = "􀇑", -- Heavy freezing drizzle/284
	["1180"] = "􀇅", -- Patchy light rain/293
	["1183"] = "􀇝", -- Light rain/296
	["1186"] = "􀇝", -- Moderate rain at times/299
	["1189"] = "􀇝", -- Moderate rain/302
	["1192"] = "􀇉", -- Heavy rain at times/305
	["1195"] = "􀇉", -- Heavy rain/308
	["1198"] = "􀇑", -- Light freezing rain/311
	["1201"] = "􀇑", -- Moderate or heavy freezing rain/314
	["1204"] = "􀇑", -- Light sleet/317
	["1207"] = "􀇑", -- Moderate or heavy sleet/320
	["1210"] = "􀇑", -- Patchy light snow/323
	["1213"] = "􀇏", -- Light snow/326
	["1216"] = "􀇏", -- Patchy moderate snow/329
	["1219"] = "􀇏", -- Moderate snow/332
	["1222"] = "􀇏", -- Patchy heavy snow/335
	["1225"] = "􀇏", -- Heavy snow/338
	["1237"] = "􀇏", -- Ice pellets/350
	["1240"] = "􀇇", -- Light rain shower/353
	["1243"] = "􀇉", -- Moderate or heavy rain shower/356
	["1246"] = "􀇉", -- Torrential rain shower/359
	["1249"] = "􀇑", -- Light sleet showers/362
	["1252"] = "􀇑", -- Moderate or heavy sleet showers/365
	["1255"] = "􀇏", -- Light snow showers/368
	["1258"] = "􀇏", -- Moderate or heavy snow showers/371
	["1261"] = "􀇓", -- Light showers of ice pellets/374
	["1264"] = "􀇍", -- Moderate or heavy showers of ice pellets/377
	["1273"] = "􀇟", -- Patchy light rain with thunder/386
	["1276"] = "􀇟", -- Moderate or heavy rain with thunder/389
	["1279"] = "􀇟", -- Patchy light snow with thunder/392
	["1282"] = "􀇟", -- Moderate or heavy snow with thunder/395
}

-- Execute the event provider binary which provides the event "weather_update" for
-- the weather data, which is fired every 3 minutes (180 seconds).
sbar.exec(
	"killall weather_update >/dev/null; $CONFIG_DIR/helpers/event_providers/weather_provider/bin/weather_provider weather_update 180 &"
)

local weather_temp = sbar.add("item", "widgets.weather.temp", {
	position = "right",
	padding_left = -20,
	label = {
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 9.0,
		},
		color = colors.white,
		string = "??°F", -- Replace with the actual temperature value
	},
	y_offset = 4,
})

local weather_city = sbar.add("item", "widgets.weather.city", {
	position = "right",
	padding_right = -24,
	label = {
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Regular"],
			size = 8.0,
		},
		color = colors.grey,
		string = "loading...",
	},
	y_offset = -6,
})

local weather_icon = sbar.add("item", "widgets.weather.icon", {
	position = "right",
	width = 6,
	icon = {
		font = {
			style = settings.font.style_map["Bold"],
			size = 16.0,
		},
		string = "__",
	},
	padding_right = -16,
	padding_left = 4,
	y_offset = 0,
})

local weather = sbar.add("item", "widgets.weather.padding", {
	position = "right",
	label = { drawing = false },
})

-- Background around the item
sbar.add("bracket", "widgets.weather.bracket", {
	weather.name,
	weather_icon.name,
	weather_temp.name,
	weather_city.name,
}, {
	background = { color = colors.bg1 },
})

sbar.add("item", { position = "right", width = settings.group_paddings })

weather_icon:subscribe("weather_update", function(env)
	local is_day = tonumber(env.is_day)
	local condition = env.condition
	local icon = is_day == 1 and weather_icons_day[condition] or weather_icons_night[condition]

	weather_icon:set({
		icon = {
			string = icon,
			color = colors.white,
		},
	})
	weather_temp:set({
		label = {
			string = env.temp .. "°F",
			color = colors.white,
		},
	})
	weather_city:set({
		label = {
			string = env.city,
			color = colors.white,
		},
	})
end)

weather_icon:subscribe("mouse.clicked", function(env)
	sbar.exec("open -a 'Weather'")
end)
weather_city:subscribe("mouse.clicked", function(env)
	sbar.exec("open -a 'Weather'")
end)
weather_temp:subscribe("mouse.clicked", function(env)
	sbar.exec("open -a 'Weather'")
end)
weather:subscribe("mouse.clicked", function(env)
	sbar.exec("open -a 'Weather'")
end)
