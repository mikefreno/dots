local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Execute the brew event provider
sbar.exec(
	"killall brew_update >/dev/null; sleep 30; $CONFIG_DIR/helpers/event_providers/brew_check/bin/brew_check brew_update 30 &"
)

local brew = sbar.add("item", "widgets.brew", {
	position = "right",
	icon = {
		padding_left = 6,
		string = icons.package,
		color = colors.white,
	},
	label = {
		font = { family = settings.font.numbers },
		string = "?",
		padding_left = 4,
		color = colors.white,
	},
	padding_right = settings.paddings + 6,
})

-- Background around the brew item
sbar.add("bracket", "widgets.brew.bracket", { brew.name }, {
	background = { color = colors.bg1 },
})

sbar.add("item", "widgets.brew.padding", {
	position = "right",
	width = settings.group_paddings,
})

-- Subscribe to brew updates
brew:subscribe("brew_update", function(env)
	local count = tonumber(env.outdated_count)
	local status = tonumber(env.status)

	-- Handle error states
	if status ~= 0 then
		brew:set({
			icon = { color = colors.red },
			label = {
				string = "!",
				color = colors.red,
			},
		})
		return
	end

	local color = count > 0 and colors.orange or colors.green
	brew:set({
		icon = { color = color },
		label = {
			string = env.outdated_count,
			color = color,
		},
	})
end)

brew:subscribe("mouse.clicked", function()
	sbar.exec('osascript -e \'tell application "Terminal" to do script "brew upgrade"\'')
	-- Trigger immediate check after potential upgrade
	sbar.exec("killall brew_update; $CONFIG_DIR/helpers/event_providers/brew_check/bin/brew_check brew_update 30 &")
end)
