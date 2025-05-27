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
	update_freq = 180,
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

-- Function to check for outdated packages
local function check_brew_outdated()
	sbar.exec("brew outdated --quiet | wc -l | tr -d ' '", function(result)
		local count = tonumber(result) or 0
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
	end)
end

brew:subscribe("brew_outdated", function(env)
	check_brew_outdated()
end)

-- Initial check
brew:subscribe("routine", function(env)
	check_brew_outdated()
end)

brew:subscribe("mouse.clicked", function(env)
	sbar.exec('kitty --title "  Brew Package Updates..." sh -c "brew upgrade && echo \\"\\nUpgrade complete! Press any key to close...\\" && read"')
end)

sbar.trigger("routine")

