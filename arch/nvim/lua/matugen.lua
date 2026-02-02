local M = {}

function M.setup()
	require("base16-colorscheme").setup({
		-- Background tones
		base00 = "#282828", -- Default Background
		base01 = "#3c3836", -- Lighter Background (status bars)
		base02 = "#474240", -- Selection Background
		base03 = "#786f6b", -- Comments, Invisibles
		-- Foreground tones
		base04 = "#ebdbb2", -- Dark Foreground (status bars)
		base05 = "#fbf1c7", -- Default Foreground
		base06 = "#fbf1c7", -- Light Foreground
		base07 = "#fbf1c7", -- Lightest Foreground
		-- Accent colors
		base08 = "#fb4934", -- Variables, XML Tags, Errors
		base09 = "#83a598", -- Integers, Constants
		base0A = "#8ec07c", -- Classes, Search Background
		base0B = "#ebdbb2", -- Strings, Diff Inserted
		base0C = "#96e9c9", -- Regex, Escape Chars
		base0D = "#e9d196", -- Functions, Methods
		base0E = "#ace996", -- Keywords, Storage
		base0F = "#7d0d00", -- Deprecated, Embedded Tags
	})
	vim.o.background = "dark"
end

-- Register a signal handler for SIGUSR1 (matugen updates)
if vim and vim.uv then
	local signal = vim.uv.new_signal()
	signal:start(
		"sigusr1",
		vim.schedule_wrap(function()
			package.loaded["matugen"] = nil
			require("matugen").setup()
		end)
	)
end

return M
