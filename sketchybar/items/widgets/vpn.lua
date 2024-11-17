local colors = require("colors")
local settings = require("settings")

sbar.exec("$CONFIG_DIR/helpers/event_providers/vpn_load/bin/vpn_load vpn_update 5 &")

local vpn_icon = sbar.add("item", "widgets.vpn.icon", {
	position = "left",
	width = 6,
	icon = {
		font = {
			style = settings.font.style_map["Bold"],
			size = 16.0,
		},
		string = "􁣡",
		color = colors.red,
	},
	padding_right = 0,
	padding_left = 6,
	y_offset = 0,
})

local vpn_status = sbar.add("item", "widgets.vpn.status", {
	position = "left",
	padding_left = 20,
	padding_right = -8,
	label = {
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 9.0,
		},
		color = colors.white,
		string = "Disconnected",
	},
	y_offset = 0,
})

local vpn = sbar.add("item", "widgets.vpn.padding", {
	position = "left",
	label = { drawing = false },
})

-- Background around the item
sbar.add("bracket", "widgets.vpn.bracket", {
	vpn.name,
	vpn_icon.name,
	vpn_status.name,
}, {
	background = { color = colors.bg1 },
	popup = { align = "center", height = 30 },
})

sbar.add("item", { position = "left", width = settings.group_paddings })

vpn_icon:subscribe("vpn_update", function(env)
	local vpn_name = env.vpn

	if vpn_name == "Connected" then
		vpn_icon:set({
			icon = {
				string = "􁅏",
				color = colors.green,
			},
		})
		vpn_status:set({
			label = {
				string = vpn_name,
				color = colors.white,
			},
		})
	else
		vpn_icon:set({
			icon = {
				string = "􁣡",
				color = colors.red,
			},
		})
		vpn_status:set({
			label = {
				string = "Disconnected",
				color = colors.white,
			},
		})
	end
end)

vpn_icon:subscribe("mouse.clicked", function(env)
	-- Open network preferences or perform desired action
	sbar.exec("open -a 'System Preferences' /System/Library/PreferencePanes/Network.prefPane")
end)
vpn_status:subscribe("mouse.clicked", function(env)
	-- Open network preferences or perform desired action
	sbar.exec("open -a 'ProtonVPN'")
end)
vpn:subscribe("mouse.clicked", function(env)
	-- Open network preferences or perform desired action
	sbar.exec("open -a 'System Preferences' /System/Library/PreferencePanes/Network.prefPane")
end)
