--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.wo.relativenumber = true
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
	"vrischmann/tree-sitter-templ",
	"sbdchd/neoformat",
	"tpope/vim-dadbod",
	"tpope/vim-surround",
	"mattn/emmet-vim",
	"keith/swift.vim",
	"ThePrimeagen/vim-be-good",
	"ThePrimeagen/harpoon",
	"ThePrimeagen/vim-apm",
	"prisma/vim-prisma",
	"mbbill/undotree",
	"mattn/emmet-vim",
	"rhysd/vim-clang-format",
	"evanleck/vim-svelte",
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = {
			{ "tpope/vim-dadbod", lazy = true },
			{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
		},
		cmd = {
			"DBUI",
			"DBUIToggle",
			"DBUIAddConnection",
			"DBUIFindBuffer",
		},
		init = function()
			-- Your DBUI configuration
			vim.g.db_ui_use_nerd_fonts = 1
		end,
	},
	{ "tpope/vim-repeat", lazy = false },
	{
		-- LSP Configuration & Plugins
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
		opts = {}, -- your configuration
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
		"NvChad/nvterm",
		config = function()
			require("nvterm").setup()
		end,
	},
	{
		-- Autocompletion
		"hrsh7th/nvim-cmp",
		dependencies = {
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-nvim-lsp",
			"rafamadriz/friendly-snippets",
		},
	},
	--Useful plugin to show you pending keybinds.
	{ "folke/which-key.nvim", opts = {} },
	{
		-- Adds git related signs to the gutter, as well as utilities for managing changes
		"lewis6991/gitsigns.nvim",
		opts = {
			-- See `:help gitsigns.txt`
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
	--{
	--"windwp/nvim-autopairs",
	--event = "InsertEnter",
	--opts = {}, -- this is equalent to setup({}) functions
	--},
	{ "neoclide/coc.nvim", branch = "release" },
	{
		"romgrk/barbar.nvim",
		dependencies = {
			"lewis6991/gitsigns.nvim", -- OPTIONAL: for git status
			"nvim-tree/nvim-web-devicons", -- OPTIONAL: for file icons
		},
		init = function()
			vim.g.barbar_auto_setup = false
		end,
		opts = {},
		version = "^1.0.0", -- optional: only update when a new 1.x version is released
	},
	{ "christoomey/vim-tmux-navigator", lazy = false },
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
		lazy = false,
	},
	{
		-- Set lualine as statusline
		"nvim-lualine/lualine.nvim",
		-- See `:help lualine.txt`
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
	{ "windwp/nvim-autopairs" },
	{ "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
	-- "gc" to comment visual regions/lines
	{ "numToStr/Comment.nvim", opts = {} },
	-- Fuzzy Finder (files, lsp, etc)
	{
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			-- Fuzzy Finder Algorithm which requires local dependencies to be built.
			-- Only load if `make` is available. Make sure you have the system
			-- requirements installed.
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
			"nvim-lua/plenary.nvim", -- required
			"nvim-telescope/telescope.nvim", -- optional
			"sindrets/diffview.nvim", -- optional
			"ibhagwan/fzf-lua", -- optional
		},
		config = true,
	},
	{
		-- Highlight, edit, and navigate code
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		build = ":TSUpdate",
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

-- [[ Setting options ]]
-- See `:help vim.o`
-- Set highlight on search
vim.o.hlsearch = false

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = "a"
-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = "unnamedplus"

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = "yes"

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = "menuone,noselect"

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
--terminal
vim.api.nvim_set_keymap(
	"n",
	"<leader>t",
	'<cmd>lua require("nvterm.terminal").toggle("horizontal")<CR>',
	{ noremap = true, silent = true, desc = "[H]orizontal Terminal" }
)
vim.api.nvim_set_keymap(
	"n",
	"<leader>f",
	'<cmd>lua require("nvterm.terminal").toggle("float")<CR>',
	{ noremap = true, silent = true, desc = "[F]loating Terminal" }
)
--harpoon keymaps
vim.api.nvim_set_keymap(
	"n",
	"<leader>hm",
	'<cmd>lua require("harpoon.mark").add_file()<CR>',
	{ noremap = true, silent = true, desc = "[H]arpoon [M]ark" }
)
vim.api.nvim_set_keymap(
	"n",
	"<leader>hq",
	'<cmd>lua require("harpoon.ui").toggle_quick_menu()<CR>',
	{ noremap = true, silent = true, desc = "[H]arpoon [Q]uick Menu" }
)

local apm = require("vim-apm")

apm:setup({})
vim.keymap.set("n", "<leader>apm", function()
	apm:toggle_monitor()
end)
--git integration

vim.api.nvim_set_keymap("n", "<leader>ng", ":Neogit<CR>", { noremap = true, silent = true })
-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

vim.api.nvim_command("source ~/.config/nvim/move_line.vim")
-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})
--file explorer - nvim tree
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
vim.api.nvim_set_keymap("n", "<leader>T", ":NvimTreeToggle<CR>", { noremap = true, silent = true })
--time dependant color theme set-up
local handle =
	io.popen("osascript -e 'tell application \"System Events\" to tell appearance preferences to return dark mode'")
local flavor
local transparency = false
if handle then
	local result = handle:read("*a")
	handle:close()

	local is_dark_mode = (result:find("true") ~= nil)
	if is_dark_mode then
		flavor = "mocha"
	else
		flavor = "latte"
	end
else
	flavor = "mocha"
end
if flavor == "mocha" then
	transparency = true
end
require("catppuccin").setup({
	lazy = false,
	flavour = flavor,
	background = {
		light = "latte",
		dark = "mocha",
	},
	color_overrides = {
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
	},
	transparent_background = transparency,
	show_end_of_buffer = false,
	custom_highlights = {},
})

vim.cmd.colorscheme("catppuccin")

function LineNumberColors()
	vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#8abcb5" })
	vim.api.nvim_set_hl(0, "LineNr", { fg = "#b5c1f1", bold = true })
	vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#dfbad5" })
end
LineNumberColors()

-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
require("telescope").setup({
	defaults = {
		file_ignore_patterns = { "node_modules", "env", "ios", "android" },
		mappings = {
			i = {
				["<C-u>"] = false,
				["<C-d>"] = false,
			},
		},
	},
})

-- Enable telescope fzf native, if installed
pcall(require("telescope").load_extension, "fzf")
-- See `:help telescope.builtin`
vim.keymap.set("n", "<leader>?", require("telescope.builtin").oldfiles, { desc = "[?] Find recently opened files" })
vim.keymap.set("n", "<leader><space>", require("telescope.builtin").buffers, { desc = "[ ] Find existing buffers" })
vim.keymap.set("n", "<leader>/", function()
	-- You can pass additional configuration to telescope to change theme, layout, etc.
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

--nvim autocomplete tab
vim.api.nvim_set_keymap("i", "<Tab>", 'pumvisible() ? "\\<C-y>" : "\\<Tab>"', { expr = true, noremap = true })
-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`
require("nvim-treesitter.configs").setup({
	-- Add languages to be installed here that you want installed for treesitter
	ensure_installed = { "c", "cpp", "go", "lua", "python", "rust", "tsx", "javascript", "typescript", "vimdoc", "vim" },

	-- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
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
		swap = {
			enable = true,
			swap_next = {
				["<leader>a"] = "@parameter.inner",
			},
			swap_previous = {
				["<leader>A"] = "@parameter.inner",
			},
		},
	},
})

--select next/prev occurance
--vim.api.nvim_set_keymap('v', '*', [[y/\V<C-R>=escape(@", '/')<CR>]], {noremap = true})
--vim.api.nvim_set_keymap('v', '#', [[y?\V<C-R>=escape(@", '/')<CR>]], {noremap = true})

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })
-- [[ Configure LSP ]]
--  This function gets run when an LSP connects to a particular buffer.
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

	-- See `:help K` for why this keymap
	nmap("K", vim.lsp.buf.hover, "Hover Documentation")
	nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")

	-- Lesser used LSP functionality
	nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
	nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
	nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
	nmap("<leader>wl", function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, "[W]orkspace [L]ist Folders")

	-- Create a command `:Format` local to the LSP buffer
	vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
		vim.lsp.buf.format()
	end, { desc = "Format current buffer with LSP" })
end

local servers = {
	clangd = { hint = { enable = true } },
	gopls = { hint = { enable = true } },
	rust_analyzer = { hint = { enable = true } },
	tsserver = { hint = { enable = true } },
	-- html = { filetypes = { 'html', 'twig', 'hbs'} },
	lua_ls = {
		Lua = {
			workspace = { checkThirdParty = false },
			telemetry = { enable = false },
			hint = { enable = true },
		},
	},
}

local sourcekit = {
	cmd = { "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp" },
	filetypes = { "swift" },
}

local ocamllsp = {
	cmd = { "/Users/mike/.opam/default/bin/ocamllsp" },
	filetypes = { "ocaml", "menhir", "ocamlinterface", "ocamllex", "reason", "dune" },
}

local test_c = {
	cmd = { "./c_lsp" },
	filetypes = { "c" },
}

-- Setup neovim lua configuration
require("neodev").setup()

-- Setup tailwind-sorter configuration
-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

-- Ensure the servers above are installed
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

--require("lspconfig")["clangd"].setup(test_c)

-- [[ Configure nvim-cmp ]]
-- See `:help cmp`
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
--buffers
vim.api.nvim_set_keymap("n", "<leader>[", ":bp<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>]", ":bn<CR>", { noremap = true, silent = true })

vim.cmd([[runtime macros/matchit.vim]])

-- change vim-sleuth fallback to 4
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
-- key maps --

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

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
