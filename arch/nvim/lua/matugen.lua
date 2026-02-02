local M = {}

function M.setup()
		require("base16-colorscheme").setup({
		-- Background tones
		base00 = "#fbf1c7", -- Default Background
		base01 = "#ebdbb2", -- Lighter Background (status bars)
		base02 = "#e7d3a2", -- Selection Background
		base03 = "#9e8861", -- Comments, Invisibles
		-- Foreground tones
		base04 = "#7c6f64", -- Dark Foreground (status bars)
		base05 = "#3c3836", -- Default Foreground
		base06 = "#3c3836", -- Light Foreground
		base07 = "#3c3836", -- Lightest Foreground
		-- Accent colors
		base08 = "#cc241d", -- Variables, XML Tags, Errors
		base09 = "#458588", -- Integers, Constants
		base0A = "#d79921", -- Classes, Search Background
		base0B = "#98971a", -- Strings, Diff Inserted
		base0C = "#1b7a7e", -- Regex, Escape Chars
		base0D = "#838216", -- Functions, Methods
		base0E = "#855e14", -- Keywords, Storage
			base0F = "#e9b5b3", -- Deprecated, Embedded Tags
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
