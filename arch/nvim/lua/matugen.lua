local M = {}

function M.setup()
	require("base16-colorscheme").setup({
		-- Background tones
		base00 = "#232a2e", -- Default Background
		base01 = "#2d353b", -- Lighter Background (status bars)
		base02 = "#363f47", -- Selection Background
		base03 = "#7a8478", -- Comments, Invisibles
		-- Foreground tones
		base04 = "#d3c6aa", -- Dark Foreground (status bars)
		base05 = "#859289", -- Default Foreground
		base06 = "#859289", -- Light Foreground
		base07 = "#859289", -- Lightest Foreground
		-- Accent colors
		base08 = "#e67e80", -- Variables, XML Tags, Errors
		base09 = "#9da9a0", -- Integers, Constants
		base0A = "#d3c6aa", -- Classes, Search Background
		base0B = "#a7c080", -- Strings, Diff Inserted
		base0C = "#96e9ab", -- Regex, Escape Chars
		base0D = "#c8e996", -- Functions, Methods
		base0E = "#e9ce96", -- Keywords, Storage
		base0F = "#a21012", -- Deprecated, Embedded Tags
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
