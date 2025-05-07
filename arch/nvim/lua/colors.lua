-- colors.lua
local M = {}

M.colors = {
	mocha = {
		rosewater = "#efc9c2",
		flamingo = "#ebb2b2",
		pink = "#f2a7de",
		mauve = "#b889f4",
		red = "#ea7183",
		maroon = "#ea838c",
		peach = "#f39967",
		yellow = "#eaca89",
		green = "#96d382",
		teal = "#78cec1",
		sky = "#91d7e3",
		sapphire = "#68bae0",
		blue = "#739df2",
		lavender = "#a0a8f6",
		text = "#b5c1f1",
		subtext1 = "#a6b0d8",
		subtext0 = "#959ec2",
		overlay2 = "#848cad",
		overlay1 = "#717997",
		overlay0 = "#63677f",
		surface2 = "#505469",
		surface1 = "#3e4255",
		surface0 = "#2c2f40",
		base = "#1a1c2a",
		mantle = "#141620",
		crust = "#0e0f16",
	},
	latte = {
		rosewater = "#c14a4a",
		flamingo = "#c14a4a",
		pink = "#945e80",
		mauve = "#945e80",
		red = "#c14a4a",
		maroon = "#c14a4a",
		peach = "#c35e0a",
		yellow = "#a96b2c",
		green = "#6c782e",
		teal = "#4c7a5d",
		sky = "#4c7a5d",
		sapphire = "#4c7a5d",
		blue = "#45707a",
		lavender = "#45707a",
		text = "#654735",
		subtext1 = "#7b5d44",
		subtext0 = "#8f6f56",
		overlay2 = "#a28368",
		overlay1 = "#b6977a",
		overlay0 = "#c9aa8c",
		surface2 = "#A79C86",
		surface1 = "#C9C19F",
		surface0 = "#DFD6B1",
		base = "#fbf1c7",
		mantle = "#F3EAC1",
		crust = "#E7DEB7",
	},
}

--keeping for compatability
function M.get_system_theme()
	return "mocha" -- only using darkmode
end

M.setup_highlights = function()
	-- Line numbers with your specific colors
	vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#8abcb5" })
	vim.api.nvim_set_hl(0, "LineNr", { fg = "#b5c1f1", bold = true })
	vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#dfbad5" })

	-- Rainbow delimiters
	local colors = vim.g.current_colors
	if colors then
		vim.api.nvim_set_hl(0, "RainbowRed", { fg = colors.red })
		vim.api.nvim_set_hl(0, "RainbowYellow", { fg = colors.yellow })
		vim.api.nvim_set_hl(0, "RainbowBlue", { fg = colors.blue })
		vim.api.nvim_set_hl(0, "RainbowOrange", { fg = colors.peach })
		vim.api.nvim_set_hl(0, "RainbowGreen", { fg = colors.green })
		vim.api.nvim_set_hl(0, "RainbowViolet", { fg = colors.mauve })
		vim.api.nvim_set_hl(0, "RainbowCyan", { fg = colors.teal })
	end
end

function M.setup()
	-- Store colors globally
	vim.g.colors = M.colors

	-- Add zen mode state tracking
	vim.g.zen_mode_active = false

	-- Set current theme based on system
	local current_theme = M.get_system_theme()
	vim.g.current_theme = current_theme
	vim.g.current_colors = M.colors[current_theme]
	vim.g.transparency = current_theme == "mocha"

	-- Set up theme change detection
	vim.api.nvim_create_autocmd({ "FocusGained" }, {
		callback = function()
			-- Only check system theme if not in zen mode
			if not vim.g.zen_mode_active then
				local new_theme = M.get_system_theme()
				if new_theme ~= vim.g.current_theme then
					M.change_theme(new_theme)
				end
			end
		end,
	})
end

function M.change_theme(new_theme, is_zen_mode)
	-- Update zen mode state
	if is_zen_mode ~= nil then
		vim.g.zen_mode_active = is_zen_mode
	end

	vim.g.current_theme = new_theme
	vim.g.current_colors = M.colors[new_theme]
	vim.g.transparency = new_theme == "mocha"

	local ok, catppuccin = pcall(require, "catppuccin")
	if ok then
		catppuccin.setup({
			flavour = new_theme,
			color_overrides = M.colors,
			transparent_background = vim.g.transparency,
		})
		vim.cmd.colorscheme("catppuccin")
	end
end

return M
