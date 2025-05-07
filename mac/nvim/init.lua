--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.opt.shortmess = vim.opt.shortmess + { I = true }

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.wo.relativenumber = true
vim.o.updatetime = 50
vim.o.redrawtime = 100
-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

vim.cmd("set spell spelllang=en_us")
require("colors").setup()

require("lazy").setup({
	-- NOTE: First, some plugins that don't require any configuration
	-- Git related plugins
	"tpope/vim-fugitive",
	"tpope/vim-rhubarb",
	"tpope/vim-dotenv",
	-- Detect tabstop and shiftwidth automatically
	"tpope/vim-sleuth",
	"preservim/nerdcommenter",
	"wakatime/vim-wakatime",
	"sbdchd/neoformat",
	"tpope/vim-surround",
	"keith/swift.vim",
	"mbbill/undotree",
	"mattn/emmet-vim",
	"rhysd/vim-clang-format",
	"evanleck/vim-svelte",
	"OmniSharp/omnisharp-vim",
	"ionide/Ionide-vim",
	"tikhomirov/vim-glsl",
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
	},
	{
		"S1M0N38/love2d.nvim",
		cmd = "LoveRun",
		opts = {},
		keys = {
			{ "<leader>v", ft = "lua", desc = "LÖVE" },
			{ "<leader>vv", "<cmd>LoveRun<cr>", ft = "lua", desc = "Run LÖVE" },
			{ "<leader>vs", "<cmd>LoveStop<cr>", ft = "lua", desc = "Stop LÖVE" },
		},
	},
	{
		"chrisgrieser/nvim-spider",
		opts = {
			skipInsignificantPunctuation = false,
			consistentOperatorPending = false,
			subwordMovement = true,
			customPatterns = {},
		},
		keys = {
			{ "w", "<cmd>lua require('spider').motion('w')<CR>", mode = { "n", "o", "x" } },
			{ "e", "<cmd>lua require('spider').motion('e')<CR>", mode = { "n", "o", "x" } },
			{ "b", "<cmd>lua require('spider').motion('b')<CR>", mode = { "n", "o", "x" } },
			{ "ge", "<cmd>lua require('spider').motion('ge')<CR>", mode = { "n", "o", "x" } },
		},
	},
	{ "tpope/vim-repeat", lazy = false },
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "williamboman/mason.nvim", config = true },
			"williamboman/mason-lspconfig.nvim",
			-- Useful status updates for LSP
			{ "j-hui/fidget.nvim", tag = "legacy", opts = {} },
			"folke/neodev.nvim",
		},
	},
	{
		"luckasRanarison/tailwind-tools.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		opts = {},
	},
	--Debugger
	--{
	--"rcarriga/nvim-dap-ui",
	--dependencies = {
	--"mfussenegger/nvim-dap",
	--},
	--},
	--"theHamsta/nvim-dap-virtual-text",
	--"mfussenegger/nvim-dap-python",
	--"leoluz/nvim-dap-go",
	--"mxsdev/nvim-dap-vscode-js",
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-nvim-lsp",
			"rafamadriz/friendly-snippets",
		},
	},
	{
		"rcarriga/nvim-notify",
		lazy = false,
		config = function()
			require("notify").setup({})
		end,
	},
	{ "folke/which-key.nvim", opts = {} },
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
			on_attach = function(bufnr)
				vim.keymap.set(
					"n",
					"<leader>gp",
					require("gitsigns").prev_hunk,
					{ buffer = bufnr, desc = "[G]o to [P]revious Hunk" }
				)
				vim.keymap.set(
					"n",
					"<leader>gn",
					require("gitsigns").next_hunk,
					{ buffer = bufnr, desc = "[G]o to [N]ext Hunk" }
				)
				vim.keymap.set(
					"n",
					"<leader>ph",
					require("gitsigns").preview_hunk,
					{ buffer = bufnr, desc = "[P]review [H]unk" }
				)
			end,
		},
	},
	{ "neoclide/coc.nvim", branch = "release" },
	{
		"romgrk/barbar.nvim",
		dependencies = {
			"lewis6991/gitsigns.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		init = function()
			vim.g.barbar_auto_setup = false
		end,
		opts = {},
		version = "^1.0.0",
	},
	{
		"nvim-tree/nvim-tree.lua",
		version = "*",
		lazy = false,
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("nvim-tree").setup({})
		end,
	},

	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			local current_theme = vim.g.current_theme or "latte"
			local transparency = vim.g.transparency or false

			require("catppuccin").setup({
				lazy = false,
				flavour = current_theme,
				background = {
					light = "latte",
					dark = "mocha",
				},
				color_overrides = require("colors").colors,
				transparent_background = transparency,
				show_end_of_buffer = false,
				custom_highlights = {},
			})

			vim.cmd.colorscheme("catppuccin")
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		opts = {
			options = {
				icons_enabled = false,
				theme = "catppuccin",
				component_separators = "|",
				section_separators = "",
			},
			sections = {
				lualine_c = { "%f" },
			},
		},
	},
	{ "windwp/nvim-ts-autotag" },
	--{
	--"windwp/nvim-autopairs",
	--event = "InsertEnter",
	--config = true,
	--opts = { map_cr = false },
	---- use opts = {} for passing setup options
	--},
	{
		"folke/zen-mode.nvim",
		config = function()
			local colors = require("colors")

			local function kitty_switch_config()
				local config_dir = os.getenv("HOME") .. "/.config/kitty"
				local kitty_file = config_dir .. "/kitty.conf"
				local kitty_dark_file = config_dir .. "/kitty_dark.conf"

				vim.fn.system(string.format("cp %s %s/kitty_previous.conf", kitty_file, config_dir))
				vim.fn.system(string.format("cp %s %s", kitty_dark_file, kitty_file))
				vim.fn.system("/Applications/kitty.app/Contents/MacOS/kitty @ load-config")
			end

			local function kitty_restore_config()
				local config_dir = os.getenv("HOME") .. "/.config/kitty"
				local kitty_file = config_dir .. "/kitty.conf"
				local previous_config = config_dir .. "/kitty_previous.conf"

				vim.fn.system(string.format("cp %s %s", previous_config, kitty_file))
				vim.fn.system("/Applications/kitty.app/Contents/MacOS/kitty @ load-config")
			end

			local function toggle_fullscreen()
				local script = [[
        tell application "System Events"
            keystroke "f" using {command down, control down}
        end tell
    ]]
				vim.fn.system(string.format("osascript -e '%s'", script))
			end

			require("zen-mode").setup({
				window = {
					backdrop = 0.95,
					width = 120,
					height = 1,
					options = {
						signcolumn = "no",
						number = false,
						relativenumber = false,
						cursorline = false,
						cursorcolumn = false,
						foldcolumn = "0",
						list = false,
					},
				},
				plugins = {
					options = {
						enabled = true,
						ruler = false,
						showcmd = false,
					},
					twilight = { enabled = false },
					gitsigns = { enabled = false },
					tmux = { enabled = true },
				},
				on_open = function()
					vim.g.pre_zen_theme = vim.g.current_theme

					colors.change_theme("mocha", true)

					toggle_fullscreen()

					kitty_switch_config()

					-- Safely handle notify
					local ok, notify = pcall(require, "notify")
					if ok then
						notify.setup({
							enabled = false,
							merge_duplicates = true,
						})
					end
				end,
				on_close = function()
					toggle_fullscreen()
					colors.change_theme(vim.g.pre_zen_theme or colors.get_system_theme(), false)

					kitty_restore_config()

					local ok, notify = pcall(require, "notify")
					if ok then
						notify.setup({
							enabled = true,
							merge_duplicates = true,
						})
					end
				end,
			})

			vim.keymap.set("n", "<leader>z", ":ZenMode<CR>", { silent = true })
		end,
	},
	{ "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
	{
		"folke/twilight.nvim",
		config = function()
			require("twilight").setup({
				dimming = {
					alpha = 0.4,
					inactive = false,
				},
				context = 14,
				treesitter = true,
				expand = {
					"function",
					"method",
					"table",
					"if_statement",
				},
				exclude = {
					"NvimTree",
					"TelescopePrompt",
					"help",
					"lazy",
					"Mason",
				},
			})

			-- Auto-enable Twilight for specific file types
			--vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
			--pattern = { "*.lua", "*.ts", "*.tsx", "*.jsx", "*.js", "*.md" },
			--callback = function()
			--vim.cmd("TwilightEnable")
			--end,
			--})
		end,
	},
	{ "numToStr/Comment.nvim", opts = {} },
	-- Fuzzy Finder (files, lsp, etc)
	{
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
		},
	},
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			"sindrets/diffview.nvim",
			"ibhagwan/fzf-lua",
		},
		config = true,
	},
	{
		"folke/trouble.nvim",
		opts = {},
		cmd = "Trouble",
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
			{
				"<leader>xX",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Buffer Diagnostics (Trouble)",
			},
			{
				"<leader>cs",
				"<cmd>Trouble symbols toggle focus=false<cr>",
				desc = "Symbols (Trouble)",
			},
			{
				"<leader>cl",
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				desc = "LSP Definitions / references / ... (Trouble)",
			},
			{
				"<leader>xL",
				"<cmd>Trouble loclist toggle<cr>",
				desc = "Location List (Trouble)",
			},
			{
				"<leader>xQ",
				"<cmd>Trouble qflist toggle<cr>",
				desc = "Quickfix List (Trouble)",
			},
		},
	},
	--{
	--"lervag/vimtex",
	--lazy = false, -- we don't want to lazy load VimTeX
	---- tag = "v2.15", -- uncomment to pin to a specific release
	--init = function()
	---- VimTeX configuration goes here, e.g.
	--vim.g.vimtex_view_method = "zathura"
	--vim.g.vimtex_compiler_method = "latexmk"
	--end,
	--},
	{
		-- Highlight, edit, and navigate code
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		build = ":TSUpdate",
	},
	{
		"jake-stewart/multicursor.nvim",
		branch = "1.0",
		config = function()
			local mc = require("multicursor-nvim")

			mc.setup()

			local set = vim.keymap.set

			set({ "n", "v" }, "<up>", function()
				mc.lineAddCursor(-1)
			end)
			set({ "n", "v" }, "<down>", function()
				mc.lineAddCursor(1)
			end)
			set({ "n", "v" }, "<c-up>", function()
				mc.lineSkipCursor(-1)
			end)
			set({ "n", "v" }, "<c-down>", function()
				mc.lineSkipCursor(1)
			end)

			set({ "n", "v" }, "<leader>n", function()
				mc.matchAddCursor(1)
			end)
			set({ "n", "v" }, "<leader>s", function()
				mc.matchSkipCursor(1)
			end)
			set({ "n", "v" }, "<leader>N", function()
				mc.matchAddCursor(-1)
			end)
			set({ "n", "v" }, "<leader>S", function()
				mc.matchSkipCursor(-1)
			end)

			set({ "n", "v" }, "<leader>A", mc.matchAllAddCursors)

			-- You can also add cursors with any motion you prefer:
			-- set("n", "<right>", function()
			--     mc.addCursor("w")
			-- end)
			-- set("n", "<leader><right>", function()
			--     mc.skipCursor("w")
			-- end)

			set({ "n", "v" }, "<left>", mc.nextCursor)
			set({ "n", "v" }, "<right>", mc.prevCursor)

			set({ "n", "v" }, "<leader>x", mc.deleteCursor)

			set("n", "<c-leftmouse>", mc.handleMouse)

			set({ "n", "v" }, "<c-q>", mc.toggleCursor)

			set({ "n", "v" }, "<leader><c-q>", mc.duplicateCursors)

			set("n", "<esc>", function()
				if not mc.cursorsEnabled() then
					mc.enableCursors()
				elseif mc.hasCursors() then
					mc.clearCursors()
				else
				end
			end)
			set("n", "<leader>gv", mc.restoreCursors)
			set("n", "<leader>a", mc.alignCursors)

			set("v", "S", mc.splitCursors)
			set("v", "I", mc.insertVisual)
			set("v", "A", mc.appendVisual)
			set("v", "M", mc.matchCursors)
			set("v", "<leader>t", function()
				mc.transposeCursors(1)
			end)
			set("v", "<leader>T", function()
				mc.transposeCursors(-1)
			end)
			set({ "v", "n" }, "<c-i>", mc.jumpForward)
			set({ "v", "n" }, "<c-o>", mc.jumpBackward)
			local hl = vim.api.nvim_set_hl
			hl(0, "MultiCursorCursor", { link = "Cursor" })
			hl(0, "MultiCursorVisual", { link = "Visual" })
			hl(0, "MultiCursorSign", { link = "SignColumn" })
			hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
			hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
			hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
		end,
	},
	{
		"chrishrb/gx.nvim",
		keys = { { "gx", "<cmd>Browse<cr>", mode = { "n", "x" } } },
		cmd = { "Browse" },
		init = function()
			vim.g.netrw_nogx = 1
		end,
		config = true,
	},
}, {})

-- LSP's not supported by Mason
require("lspconfig").sourcekit.setup({
	cmd = { "sourcekit-lsp" },
	filetypes = { "swift", "objective-c", "objective-cpp" },
})
require("lspconfig").ocamllsp.setup({
	cmd = { "ocamllsp" },
	filetypes = { "ocaml", "menhir", "ocamlinterface", "ocamllex", "reason", "dune" },
})

require("colors").setup_highlights()

vim.o.hlsearch = false

vim.wo.number = true

vim.o.mouse = "a"
vim.o.clipboard = "unnamedplus"

vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true

vim.wo.signcolumn = "yes"

vim.o.updatetime = 250
vim.o.timeoutlen = 300

vim.o.completeopt = "menuone,noselect"

vim.o.termguicolors = true

vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
local harpoon = require("harpoon")
harpoon:setup()

vim.keymap.set("n", "<leader>a", function()
	harpoon:list():add()
end)
vim.keymap.set("n", "<leader>h", function()
	harpoon.ui:toggle_quick_menu(harpoon:list())
end)

vim.keymap.set("n", "<leader>1", function()
	harpoon:list():select(1)
end)
vim.keymap.set("n", "<leader>2", function()
	harpoon:list():select(2)
end)
vim.keymap.set("n", "<leader>3", function()
	harpoon:list():select(3)
end)
vim.keymap.set("n", "<leader>4", function()
	harpoon:list():select(4)
end)

vim.keymap.set("n", "<leader>z", ":ZenMode<CR>", { silent = true })

vim.api.nvim_set_keymap("n", "<leader>ng", ":Neogit<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

vim.api.nvim_command("source ~/.config/nvim/move_line.vim")
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})
require("nvim-tree").setup({
	sort_by = "case_sensitive",
	view = {
		relativenumber = true,
		width = 30,
	},
	auto_reload_on_write = true,
	renderer = {
		group_empty = false,
	},
	filters = {
		dotfiles = false,
		git_ignored = false,
	},
	diagnostics = {
		enable = false,
		show_on_dirs = false,
		show_on_open_dirs = true,
		debounce_delay = 50,
		severity = {
			min = vim.diagnostic.severity.HINT,
			max = vim.diagnostic.severity.ERROR,
		},
		icons = {
			hint = "",
			info = "",
			warning = "",
			error = "",
		},
	},
})
vim.api.nvim_set_keymap("n", "<leader>t", ":NvimTreeToggle<CR>", { noremap = true, silent = true })

require("telescope").setup({
	defaults = {
		file_ignore_patterns = { "node_modules", "env", "ios", "android", "macos", "linux", "build", "windows" },
		mappings = {
			i = {
				["<C-u>"] = false,
				["<C-d>"] = false,
			},
		},
	},
})

pcall(require("telescope").load_extension, "fzf")
vim.keymap.set("n", "<leader>?", require("telescope.builtin").oldfiles, { desc = "[?] Find recently opened files" })
vim.keymap.set("n", "<leader><space>", require("telescope.builtin").buffers, { desc = "[ ] Find existing buffers" })
vim.keymap.set("n", "<leader>/", function()
	require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
		winblend = 10,
		previewer = false,
	}))
end, { desc = "[/] Fuzzily search in current buffer" })

vim.keymap.set("n", "<leader>gf", require("telescope.builtin").git_files, { desc = "Search [G]it [F]iles" })
vim.keymap.set("n", "<leader>sf", require("telescope.builtin").find_files, { desc = "[S]earch [F]iles" })
vim.keymap.set("n", "<leader>sh", require("telescope.builtin").help_tags, { desc = "[S]earch [H]elp" })
vim.keymap.set("n", "<leader>sw", require("telescope.builtin").grep_string, { desc = "[S]earch current [W]ord" })
vim.keymap.set("n", "<leader>sg", require("telescope.builtin").live_grep, { desc = "[S]earch by [G]rep" })
vim.keymap.set("n", "<leader>sd", require("telescope.builtin").diagnostics, { desc = "[S]earch [D]iagnostics" })

vim.api.nvim_set_keymap("i", "<Tab>", 'pumvisible() ? "\\<C-y>" : "\\<Tab>"', { expr = true, noremap = true })
require("nvim-treesitter.configs").setup({
	ensure_installed = { "c", "cpp", "go", "lua", "python", "rust", "tsx", "javascript", "typescript", "vimdoc", "vim" },
	auto_install = false,

	highlight = { enable = true },
	indent = { enable = true },
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "<c-space>",
			node_incremental = "<c-space>",
			scope_incremental = "<c-s>",
			node_decremental = "<M-space>",
		},
	},
	textobjects = {
		select = {
			enable = true,
			lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
			keymaps = {
				-- You can use the capture groups defined in textobjects.scm
				["aa"] = "@parameter.outer",
				["ia"] = "@parameter.inner",
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				["ic"] = "@class.inner",
			},
		},
		move = {
			enable = true,
			set_jumps = true, -- whether to set jumps in the jumplist
			goto_next_start = {
				["]m"] = "@function.outer",
				["]]"] = "@class.outer",
			},
			goto_next_end = {
				["]M"] = "@function.outer",
				["]["] = "@class.outer",
			},
			goto_previous_start = {
				["[m"] = "@function.outer",
				["[["] = "@class.outer",
			},
			goto_previous_end = {
				["[M"] = "@function.outer",
				["[]"] = "@class.outer",
			},
		},
		--swap = {
		--enable = true,
		--swap_next = {
		--["<leader>a"] = "@parameter.inner",
		--},
		--swap_previous = {
		--["<leader>A"] = "@parameter.inner",
		--},
		--},
	},
})

vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

local on_attach = function(_, bufnr)
	local nmap = function(keys, func, desc)
		if desc then
			desc = "LSP: " .. desc
		end

		vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
	end
	--Debugger Keybinds
	--nmap("<leader>dt", require("dap").continue(), "[D]ebugger [T]oggle")
	--nmap("<leader>dso", require("dap").step_over(), "[D]ebugger [S]tep [O]ver")
	--nmap("<leader>dsi", require("dap").step_into(), "[D]ebugger [S]tep [I]nto")
	--nmap("<leader>dsb", require("dap").set_breakpoint(), "[D]ebugger [S]et [B]reakpoint")

	nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
	nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

	nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
	nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
	nmap("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
	nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
	nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
	nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

	nmap("K", vim.lsp.buf.hover, "Hover Documentation")
	nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")

	nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
	nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
	nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
	nmap("<leader>wl", function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, "[W]orkspace [L]ist Folders")

	vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
		vim.lsp.buf.format()
	end, { desc = "Format current buffer with LSP" })
end

local servers = {
	basedpyright = { basedpyright = { typeCheckingMode = "standard" } },
	clangd = { hint = { enable = true } },
	gopls = { hint = { enable = true } },
	rust_analyzer = { hint = { enable = true } },
	tsserver = { hint = { enable = true } },
	lua_ls = {
		Lua = {
			workspace = { checkThirdParty = false },
			telemetry = { enable = false },
			hint = { enable = true },
		},
	},
}

local sourcekit = {
	cmd = {
		"/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
	},
	filetypes = { "swift" },
}

local ocamllsp = {
	cmd = { "/Users/mike/.opam/default/bin/ocamllsp" },
	filetypes = { "ocaml", "menhir", "ocamlinterface", "ocamllex", "reason", "dune" },
}
require("neodev").setup()

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

local mason_lspconfig = require("mason-lspconfig")

mason_lspconfig.setup({
	ensure_installed = vim.tbl_keys(servers),
})

mason_lspconfig.setup_handlers({
	function(server_name)
		require("lspconfig")[server_name].setup({
			capabilities = capabilities,
			on_attach = on_attach,
			settings = servers[server_name],
			filetypes = (servers[server_name] or {}).filetypes,
		})
	end,
})

require("lspconfig")["sourcekit"].setup(sourcekit)
require("lspconfig")["ocamllsp"].setup(ocamllsp)

local cmp = require("cmp")
local luasnip = require("luasnip")
require("luasnip.loaders.from_vscode").lazy_load()
luasnip.config.setup({})

cmp.setup({
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-n>"] = cmp.mapping.select_next_item(),
		["<C-p>"] = cmp.mapping.select_prev_item(),
		["<C-d>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete({}),
		["<CR>"] = cmp.mapping.confirm({
			behavior = cmp.ConfirmBehavior.Replace,
			select = true,
		}),
		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif luasnip.expand_or_locally_jumpable() then
				luasnip.expand_or_jump()
			else
				fallback()
			end
		end, { "i", "s" }),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.locally_jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, { "i", "s" }),
	}),
	sources = {
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
	},
})

vim.keymap.set("n", "<leader>ut", vim.cmd.UndotreeToggle)
--for go :)
vim.keymap.set("n", "<leader>ee", "oif err != nil {<CR>} <Esc>Oreturn err<Esc>")

--tailwind sort
vim.api.nvim_set_keymap("n", "<leader>st", ":TailwindSort<CR>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "<leader>[", ":bp<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>]", ":bn<CR>", { noremap = true, silent = true })

vim.cmd([[runtime macros/matchit.vim]])

vim.cmd([[
  autocmd FileType * setlocal ts=4 sts=4 sw=4 expandtab
]])

vim.cmd([[
    autocmd BufWritePre *.js,*.jsx,*.ts,*.tsx,*.html,*.css,*.lua,*.ml,*.mli,*.go,*.c,*.cpp Neoformat
]])

vim.g.neoformat_enabled_ocaml = { "ocamlformat" }
vim.g.neoformat_enabled_html = { "prettier" }
vim.g.neoformat_enabled_css = { "prettier" }
vim.g.neoformat_enabled_javascript = { "prettier" }
vim.g.neoformat_enabled_typescript = { "prettier" }
vim.g.neoformat_enabled_typescriptreact = { "prettier" }
vim.g.neoformat_enabled_javascriptreact = { "prettier" }
vim.g.neoformat_enabled_lua = { "stylua" }
vim.g.neoformat_enabled_go = { "gofmt" }
vim.g.neoformat_options_c = {
	command = "clang-format -style=Google",
}

vim.g.neoformat_options_cpp = {
	command = "clang-format -style=Google",
}
vim.cmd([[
  autocmd BufWritePost * silent! :Sleuth
]])

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*.glsl",
	command = "Format",
})

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*.json",
	callback = function()
		local bufnr = vim.api.nvim_get_current_buf()
		local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
		local result = vim.system({
			"jq",
			".",
		}, {
			stdin = content,
		}):wait()
		if result.code == 0 then
			local formatted = vim.split(result.stdout, "\n")
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
		end
	end,
})

--make save case insensitive
vim.cmd("command! W w")
vim.cmd("command! Wq wq")

vim.cmd("autocmd FileType ocaml nnoremap <leader>t :NvimTreeToggle<CR>")

vim.api.nvim_set_keymap(
	"n",
	"<leader>sx",
	":lua vim.api.nvim_del_line(vim.api.nvim_get_current_line()); vim.api.nvim_put_line(vim.api.nvim_get_current_line() - 1, vim.api.nvim_get_line(vim.api.nvim_get_current_line()))<CR>",
	{ noremap = true, silent = true }
)

if vim.lsp.inlay_hint then
	vim.keymap.set("n", "<Leader>nh", function()
		vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
	end, { desc = "toggle inlay [h]ints" })
end

vim.cmd([[
  inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
  inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
  inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<CR>"
]])

-- vim: ts=2 sts=2 sw=2 et
