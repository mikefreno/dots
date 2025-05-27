local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

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

-- Function to update display from cache
local function update_brew_display()
	sbar.exec("cat /tmp/brew_outdated_count 2>/dev/null || echo '?'", function(result)
		local count_str = result:gsub("%s+", "")

		if count_str == "?" then
			brew:set({
				icon = { color = colors.white },
				label = {
					string = "?",
					color = colors.white,
				},
			})
		else
			local count = tonumber(count_str) or 0
			if count > 0 then
				brew:set({
					icon = { color = colors.orange },
					label = {
						string = tostring(count),
						color = colors.orange,
					},
				})
			else
				brew:set({
					icon = { color = colors.green },
					label = {
						string = "0",
						color = colors.green,
					},
				})
			end
		end
	end)
end

local function trigger_brew_check()
	sbar.exec("$CONFIG_DIR/helpers/event_providers/brew_check.sh &")
end

-- Subscribe to the custom brew_update event
brew:subscribe("brew_update", function()
	update_brew_display()
end)

-- Trigger background check on routine (but don't wait for it)
brew:subscribe("routine", function()
	trigger_brew_check()
end)


brew:subscribe("mouse.clicked", function()
	sbar.exec('osascript -e \'tell application "Terminal" to do script "brew upgrade && echo \\"\\nUpgrade complete! Press any key to close...\\" && read"\'')
end)

update_brew_display()
trigger_brew_check()
