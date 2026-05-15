local M = {}

function M.setup()
	require("base16-colorscheme").setup({
		-- Background tones
		base00 = "#e3ebe0", -- Default Background
		base01 = "#d8e3d3", -- Lighter Background (status bars)
		base02 = "#d2dfcd", -- Selection Background
		base03 = "#679056", -- Comments, Invisibles
		-- Foreground tones
		base04 = "#535a52", -- Dark Foreground (status bars)
		base05 = "#191b18", -- Default Foreground
		base06 = "#191b18", -- Light Foreground
		base07 = "#191b18", -- Lightest Foreground
		-- Accent colors
		base08 = "#fd4663", -- Variables, XML Tags, Errors
		base09 = "#194d3e", -- Integers, Constants
		base0A = "#165a25", -- Classes, Search Background
		base0B = "#2c6c13", -- Strings, Diff Inserted
		base0C = "#1b7e62", -- Regex, Escape Chars
		base0D = "#358217", -- Functions, Methods
		base0E = "#1b7e31", -- Keywords, Storage
		base0F = "#f7bbc4", -- Deprecated, Embedded Tags
	})
end

-- Register a signal handler for SIGUSR1 (matugen updates)
local signal = vim.uv.new_signal()
signal:start(
	"sigusr1",
	vim.schedule_wrap(function()
		package.loaded["matugen"] = nil
		require("matugen").setup()
	end)
)

return M
