
local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- Set a consistent width for all popup items
local popup_item_width = 120

-- Padding item required because of bracket
local gear = sbar.add("item", {
	icon = {
		font = { size = 20.0 },
		string = icons.gear,
		padding_right = 6,
		padding_left = 6,
	},
	label = { drawing = false },
	background = {
		color = colors.bg2,
		border_color = colors.black,
		border_width = 1,
	},
	padding_left = 1,
	padding_right = 1,
	position = "right",
})

-- Double border for apple using a single item bracket
local gear_bracket = sbar.add("bracket", { gear.name }, {
	background = {
		color = colors.transparent,
		height = 30,
		border_color = colors.grey,
	},
	popup = { align = "right" },
})

-- Popup menu items
local lock_item = sbar.add("item", {
	position = "popup." .. gear_bracket.name,
	width = popup_item_width,
	icon = {
		string = "􀎠",
		font = { size = 14.0 },
		padding_left = 8,
		padding_right = 8,
	},
	label = {
		string = "Lock Screen",
		font = {
			style = settings.font.style_map["Bold"],
			size = 12.0,
		},
		padding_right = 12,
	},
	background = {
		color = colors.bg1,
		height = 25,
	},
})

local logout_item = sbar.add("item", {
	position = "popup." .. gear_bracket.name,
	width = popup_item_width,
	icon = {
		string = "􀱍",
		font = { size = 14.0 },
		padding_left = 8,
		padding_right = 8,
	},
	label = {
		string = "Log Out",
		font = {
			style = settings.font.style_map["Bold"],
			size = 12.0,
		},
		padding_right = 12,
	},
	background = {
		color = colors.bg1,
		height = 25,
	},
})

local sleep_item = sbar.add("item", {
	position = "popup." .. gear_bracket.name,
	width = popup_item_width,
	icon = {
		string = "􀥦",
		font = { size = 14.0 },
		padding_left = 8,
		padding_right = 8,
	},
	label = {
		string = "Sleep",
		font = {
			style = settings.font.style_map["Bold"],
			size = 12.0,
		},
		padding_right = 12,
	},
	background = {
		color = colors.bg1,
		height = 25,
	},
})

local shutdown_item = sbar.add("item", {
	position = "popup." .. gear_bracket.name,
	width = popup_item_width,
	icon = {
		string = "􀆨",
		font = { size = 14.0 },
		padding_left = 8,
		padding_right = 8,
	},
	label = {
		string = "Shutdown",
		font = {
			style = settings.font.style_map["Bold"],
			size = 12.0,
		},
		padding_right = 12,
	},
	background = {
		color = colors.bg1,
		height = 25,
	},
})

local reboot_item = sbar.add("item", {
	position = "popup." .. gear_bracket.name,
	width = popup_item_width,
	icon = {
		string = "􀎀",
		font = { size = 14.0 },
		padding_left = 8,
		padding_right = 8,
	},
	label = {
		string = "Restart",
		font = {
			style = settings.font.style_map["Bold"],
			size = 12.0,
		},
		padding_right = 12,
	},
	background = {
		color = colors.bg1,
		height = 25,
	},
})

-- Popup toggle functions
local function hide_popup()
	gear_bracket:set({ popup = { drawing = false } })
end

local function toggle_popup()
	local should_draw = gear_bracket:query().popup.drawing == "off"
	gear_bracket:set({ popup = { drawing = should_draw } })
end

-- Gear click handler
gear:subscribe("mouse.clicked", toggle_popup)
gear:subscribe("mouse.exited.global", hide_popup)

-- Menu item click handlers
lock_item:subscribe("mouse.clicked", function(env)
	sbar.exec("pmset displaysleepnow")
	hide_popup()
end)

logout_item:subscribe("mouse.clicked", function(env)
	sbar.exec("osascript -e 'tell application \"System Events\" to log out'")
	hide_popup()
end)

sleep_item:subscribe("mouse.clicked", function(env)
	sbar.exec("pmset sleepnow")
	hide_popup()
end)

shutdown_item:subscribe("mouse.clicked", function(env)
	sbar.exec("osascript -e 'tell application \"System Events\" to shut down'")
	hide_popup()
end)

reboot_item:subscribe("mouse.clicked", function(env)
	sbar.exec("osascript -e 'tell application \"System Events\" to restart'")
	hide_popup()
end)

-- Hover effects for menu items
local function add_hover_effect(item)
	item:subscribe("mouse.entered", function(env)
		item:set({ background = { color = colors.bg2 } })
	end)
	
	item:subscribe("mouse.exited", function(env)
		item:set({ background = { color = colors.bg1 } })
	end)
end

add_hover_effect(lock_item)
add_hover_effect(logout_item)
add_hover_effect(sleep_item)
add_hover_effect(shutdown_item)
add_hover_effect(reboot_item)

