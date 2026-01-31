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

-- Get theme based on system time (daytime = latte, nighttime = mocha)
function M.get_system_theme()
	local hour = tonumber(os.date("%H"))
	local minute = tonumber(os.date("%M"))
	if hour >= 7 and (hour < 17 or (hour == 17 and minute < 30)) then
		return "latte"
	else
		return "mocha"
	end
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

	-- Detect SSH session
	local is_ssh = os.getenv("SSH_CONNECTION") ~= nil or os.getenv("SSH_CLIENT") ~= nil or os.getenv("SSH_TTY") ~= nil
	vim.g.is_ssh = is_ssh

	-- Set current theme based on system
	local current_theme = M.get_system_theme()
	vim.g.current_theme = current_theme
	vim.g.current_colors = M.colors[current_theme]
	-- Disable transparency over SSH for better visibility
	vim.g.transparency = current_theme == "mocha" and not is_ssh

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
	-- Disable transparency over SSH for better visibility
	local is_ssh = vim.g.is_ssh or false
	vim.g.transparency = new_theme == "mocha" and not is_ssh

	local ok, catppuccin = pcall(require, "catppuccin")
	if ok then
		catppuccin.setup({
			flavour = new_theme,
			color_overrides = M.colors,
			transparent_background = vim.g.transparency,
		})
		vim.cmd.colorscheme("catppuccin")
		M.setup_highlights()
		print("Theme changed to: " .. new_theme)
	end
end

-- Toggle between mocha and latte
function M.toggle_theme()
	local new_theme = vim.g.current_theme == "mocha" and "latte" or "mocha"
	M.change_theme(new_theme)
end

-- Manually set to dark theme
function M.set_dark()
	M.change_theme("mocha")
end

-- Manually set to light theme
function M.set_light()
	M.change_theme("latte")
end

return M
