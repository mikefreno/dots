-- setup color scheme --
require("colors").setup()
require("colors").setup_highlights()
-- spellcheck --
vim.cmd("set spell spelllang=en_us")
-- basic options --
vim.opt.shortmess = vim.opt.shortmess + { I = true }
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.o.number = true
vim.o.relativenumber = true
vim.o.updatetime = 50
vim.o.showmode = false
vim.o.redrawtime = 100
vim.o.hlsearch = false

vim.o.textwidth = 0
vim.o.wrapmargin = 10
vim.o.wrap = true

vim.o.linebreak = true

vim.o.mouse = "a"
vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

vim.o.breakindent = true
vim.o.undofile = true

-- Indentation settings
vim.o.tabstop = 4 -- Number of spaces a tab counts for
vim.o.shiftwidth = 4 -- Number of spaces for each step of autoindent
vim.o.softtabstop = 4 -- Number of spaces a tab counts for while editing
vim.o.expandtab = true -- Use spaces instead of tabs
vim.o.autoindent = true -- Copy indent from current line when starting new line
vim.o.smartindent = true -- Smart autoindenting when starting new line
vim.o.cindent = true -- Stricter rules for C programs (also works well for other languages)
vim.o.shiftround = true -- Round indent to multiple of shiftwidth

vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.signcolumn = "yes"

vim.o.updatetime = 250
vim.o.timeoutlen = 300

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.list = true
vim.opt.listchars = { tab = "▏ ", trail = "·", nbsp = "␣", eol = "↵" }

vim.o.inccommand = "split"

vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

vim.o.confirm = true

vim.o.completeopt = "menuone,noselect"
vim.o.termguicolors = true

--make save case insensitive
vim.cmd("command! W w")
vim.cmd("command! Wq wq")

-- basic autocommands --
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

vim.api.nvim_create_autocmd("VimResized", {
	group = vim.api.nvim_create_augroup("autoresize_windows", { clear = true }),
	command = "wincmd =",
})

-- Filetype-specific indentation
vim.api.nvim_create_autocmd("FileType", {
	desc = "Set indentation for specific file types",
	group = vim.api.nvim_create_augroup("indentation-settings", { clear = true }),
	callback = function()
		local ft = vim.bo.filetype
		local indent_settings = {
			lua = { tabstop = 2, shiftwidth = 2, softtabstop = 2, expandtab = true },
			javascript = { tabstop = 2, shiftwidth = 2, softtabstop = 2, expandtab = true },
			typescript = { tabstop = 2, shiftwidth = 2, softtabstop = 2, expandtab = true },
			html = { tabstop = 2, shiftwidth = 2, softtabstop = 2, expandtab = true },
			css = { tabstop = 2, shiftwidth = 2, softtabstop = 2, expandtab = true },
			json = { tabstop = 2, shiftwidth = 2, softtabstop = 2, expandtab = true },
			yaml = { tabstop = 2, shiftwidth = 2, softtabstop = 2, expandtab = true },
			go = { tabstop = 4, shiftwidth = 4, softtabstop = 4, expandtab = false }, -- Go uses tabs
			python = { tabstop = 4, shiftwidth = 4, softtabstop = 4, expandtab = true },
			c = { tabstop = 4, shiftwidth = 4, softtabstop = 4, expandtab = true },
			cpp = { tabstop = 4, shiftwidth = 4, softtabstop = 4, expandtab = true },
			rust = { tabstop = 4, shiftwidth = 4, softtabstop = 4, expandtab = true },
		}

		local settings = indent_settings[ft]
		if settings then
			for option, value in pairs(settings) do
				vim.bo[option] = value
			end
		end
	end,
})

-- keybinds --

-- wrap file
vim.keymap.set("", "k", function()
	return vim.api.nvim_win_get_cursor(0)[1] == 1 and "G" or "k"
end, { expr = true, silent = true })

vim.keymap.set("", "j", function()
	local last_line = vim.api.nvim_buf_line_count(0)
	return vim.api.nvim_win_get_cursor(0)[1] == last_line and "gg" or "j"
end, { expr = true, silent = true })

vim.api.nvim_command("source ~/.config/nvim/move_line.vim")

vim.api.nvim_set_keymap("n", "<leader>[", ":bp<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>]", ":bn<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>ee", "oif err != nil {<CR>} <Esc>Oreturn err<Esc>")
vim.keymap.set("n", "<leader>gi", ":GuessIndent<CR>", { desc = "[G]uess [I]ndent" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

-- package manager setup --
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

-- package install/configuration --
require("lazy").setup({
	-- NOTE: First, some plugins that don't require any configuration
	{ "tpope/vim-repeat", lazy = false },
	{
		"NMAC427/guess-indent.nvim", -- Detect tabstop and shiftwidth automatically
		config = function()
			require("guess-indent").setup({
				auto_cmd = true, -- Set to false to disable automatic execution
				override_editorconfig = false, -- Set to true to override settings set by .editorconfig
				filetype_exclude = { -- A list of filetypes for which the auto command gets disabled
					"netrw",
					"tutor",
				},
				buftype_exclude = { -- A list of buffer types for which the auto command gets disabled
					"help",
					"nofile",
					"terminal",
					"prompt",
				},
			})
		end,
	},
	"wakatime/vim-wakatime",
	"mattn/emmet-vim",
	"preservim/nerdcommenter",
	"mbbill/undotree",
	"luckasRanarison/tailwind-tools.nvim",
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = true,
		-- use opts = {} for passing setup options
		-- this is equivalent to setup({}) function
	},
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
	},
	{
		"ThePrimeagen/refactoring.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		lazy = false,
		opts = {},
	},
	{
		"ggml-org/llama.vim",
		init = function()
			local keyFile = io.open("/Users/mike/.config/opencode/my.key", "r")
			local api_key = "_"
			if keyFile then
				api_key = keyFile:read("*l")
			end
			vim.g.llama_config = {
				--endpoint = "http://localhost:8123/infill",
				endpoint = "https://infill.freno.me/infill",
				api_key = api_key,
				keymap_trigger = "<M-Enter>",
				keymap_accept_line = "<A-Tab>",
				keymap_accept_full = "<S-Tab>",
				keymap_accept_word = "<Right>",
				stop_strings = {},
				n_prefix = 512,
				n_suffix = 512,
				show_info = 0,
			}
		end,
	},
	-- language specific plugins
	"keith/swift.vim",
	"rhysd/vim-clang-format",
	"evanleck/vim-svelte",
	"OmniSharp/omnisharp-vim",
	"ionide/Ionide-vim",
	"tikhomirov/vim-glsl",
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" }, -- if you use the mini.nvim suite
		-- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' }, -- if you use standalone mini plugins
		-- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
		---@module 'render-markdown'
		---@type render.md.UserConfig
		opts = {},
		keys = {
			{
				"<leader>rm",
				function()
					require("render-markdown").toggle()
				end,
				mode = { "n" },
				desc = "[R]ender [M]arkdown",
			},
		},
	},
	{
		"lervag/vimtex",
		lazy = false, -- we don't want to lazy load VimTeX
		-- tag = "v2.15", -- uncomment to pin to a specific release
		init = function()
			-- VimTeX configuration goes here, e.g.
			vim.g.vimtex_view_method = "zathura"
			vim.g.vimtex_compiler_method = "latexmk"
		end,
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
	-- more complex, non specifics
	{
		"chrisgrieser/nvim-spider",
		opts = {
			skipInsignificantPunctuation = false,
			consistentOperatorPending = false,
			subwordMovement = true,
			customPatterns = {},
		},
		keys = {
			{
				"w",
				function()
					require("spider").motion("w")
				end,
				mode = { "n", "o", "x" },
				desc = "Spider motion: w",
			},
			{
				"e",
				function()
					require("spider").motion("e")
				end,
				mode = { "n", "o", "x" },
				desc = "Spider motion: e",
			},
			{
				"b",
				function()
					require("spider").motion("b")
				end,
				mode = { "n", "o", "x" },
				desc = "Spider motion: b",
			},
			{
				"ge",
				function()
					require("spider").motion("ge")
				end,
				mode = { "n", "o", "x" },
				desc = "Spider motion: ge",
			},
		},
	},
	{
		-- Main LSP Configuration
		"neovim/nvim-lspconfig",
		dependencies = {
			-- Automatically install LSPs and related tools to stdpath for Neovim
			-- Mason must be loaded before its dependents so we need to set it up here.
			-- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
			{ "mason-org/mason.nvim", opts = {} },
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",

			-- Useful status updates for LSP.
			{ "j-hui/fidget.nvim", opts = {} },

			-- Allows extra capabilities provided by blink.cmp
			"saghen/blink.cmp",
		},
		config = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc, mode)
						mode = mode or "n"
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end
					map("grn", vim.lsp.buf.rename, "[R]e[n]ame")
					map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
					map("grr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
					map("gri", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
					map("grd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
					map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
					map("gO", require("telescope.builtin").lsp_document_symbols, "Open Document Symbols")
					map("gW", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Open Workspace Symbols")

					map("grt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype Definition")
					-- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
					---@param client vim.lsp.Client
					---@param method vim.lsp.protocol.Method
					---@param bufnr? integer some lsp support methods only in specific files
					---@return boolean
					local function client_supports_method(client, method, bufnr)
						return client:supports_method(method, bufnr)
					end

					-- The following two autocommands are used to highlight references of the
					-- word under your cursor when your cursor rests there for a little while.
					--    See `:help CursorHold` for information about when this is executed
					--
					-- When you move your cursor, the highlights will be cleared (the second autocommand).
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if
						client
						and client_supports_method(
							client,
							vim.lsp.protocol.Methods.textDocument_documentHighlight,
							event.buf
						)
					then
						local highlight_augroup =
							vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight,
						})

						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})

						vim.api.nvim_create_autocmd("LspDetach", {
							group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
							callback = function(event2)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
							end,
						})
					end

					-- The following code creates a keymap to toggle inlay hints in your
					-- code, if the language server you are using supports them
					--
					-- This may be unwanted, since they displace some of your code
					if
						client
						and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf)
					then
						map("<leader>ih", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
						end, "Toggle [I]nlay [H]ints")
					end
				end,
			})
			-- Diagnostic Config
			-- See :help vim.diagnostic.Opts
			vim.diagnostic.config({
				severity_sort = true,
				float = { border = "rounded", source = "if_many" },
				underline = { severity = vim.diagnostic.severity.ERROR },
				signs = vim.g.have_nerd_font and {
					text = {
						[vim.diagnostic.severity.ERROR] = "󰅚 ",
						[vim.diagnostic.severity.WARN] = "󰀪 ",
						[vim.diagnostic.severity.INFO] = "󰋽 ",
						[vim.diagnostic.severity.HINT] = "󰌶 ",
					},
				} or {},
				virtual_text = {
					source = "if_many",
					spacing = 2,
					format = function(diagnostic)
						local diagnostic_message = {
							[vim.diagnostic.severity.ERROR] = diagnostic.message,
							[vim.diagnostic.severity.WARN] = diagnostic.message,
							[vim.diagnostic.severity.INFO] = diagnostic.message,
							[vim.diagnostic.severity.HINT] = diagnostic.message,
						}
						return diagnostic_message[diagnostic.severity]
					end,
				},
			})

			local capabilities = require("blink.cmp").get_lsp_capabilities()
			local servers = {
				basedpyright = { basedpyright = { typeCheckingMode = "standard" } },
				clangd = { hint = { enable = true } },
				gopls = { hint = { enable = true } },
				rust_analyzer = { hint = { enable = true } },
				ts_ls = { hint = { enable = true } },
				lua_ls = {
					settings = {
						Lua = {
							workspace = { checkThirdParty = false },
							telemetry = { enable = false },
							hint = {
								enable = true,
							},
							runtime = {
								version = "LuaJIT",
							},
						},
					},
				},
			}

			-- Ensure the servers and tools above are installed
			--
			-- To check the current status of installed tools and/or manually install
			-- other tools, you can run
			--    :Mason
			--
			-- You can press `g?` for help in this menu.
			--
			-- `mason` had to be setup earlier: to configure its options see the
			-- `dependencies` table for `nvim-lspconfig` above.
			--
			-- You can add other tools here that you want Mason to install
			-- for you, so that they are available from within Neovim.
			local ensure_installed = vim.tbl_keys(servers or {})
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			require("mason-lspconfig").setup({
				ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
				automatic_installation = false,
				handlers = {
					function(server_name)
						local server = servers[server_name] or {}
						-- This handles overriding only values explicitly passed
						-- by the server configuration above. Useful when disabling
						-- certain features of an LSP (for example, turning off formatting for ts_ls)
						server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
						require("lspconfig")[server_name].setup(server)
					end,
				},
			})
		end,
	},
	{ -- Autoformat
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		opts = {
			notify_on_error = false,
			format_on_save = function(bufnr)
				-- Disable "format_on_save lsp_fallback" for languages that don't
				-- have a well standardized coding style. You can add additional
				-- languages here or re-enable it for the disabled ones.
				local disable_filetypes = {}
				if disable_filetypes[vim.bo[bufnr].filetype] then
					return nil
				else
					return {
						timeout_ms = 500,
						lsp_format = "fallback",
					}
				end
			end,
			formatters_by_ft = {
				lua = { "stylua" },
				ocaml = { "ocamlformat" },
				html = { "prettier" },
				css = { "prettier" },
				-- Conform can also run multiple formatters sequentially
				python = { "isort", "black" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
				javascriptreact = { "prettier" },
				go = { "gofmt" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				json = { "jq" },
				--json = {
				--{
				--command = "jq",
				--args = { "." }, -- `jq .` pretty‑prints
				--stdin = true, -- send the buffer to stdin
				---- Optional, but you can specify which exit codes count as success
				--exit_codes = { 0, 1 }, -- jq returns 1 for already‑formatted files
				--},
				--},
				-- You can use option 'stop_after_first = true' to run the first available formatter from the list
			},
		},
	},
	{ -- Autocompletion
		"saghen/blink.cmp",
		event = "VimEnter",
		version = "1.*",
		dependencies = {
			-- Snippet Engine
			{
				"L3MON4D3/LuaSnip",
				version = "2.*",
				build = (function()
					-- Build Step is needed for regex support in snippets.
					-- This step is not supported in many windows environments.
					-- Remove the below condition to re-enable on windows.
					if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
						return
					end
					return "make install_jsregexp"
				end)(),
				dependencies = {
					-- `friendly-snippets` contains a variety of premade snippets.
					--    See the README about individual language/framework/plugin snippets:
					--    https://github.com/rafamadriz/friendly-snippets
					{
						"rafamadriz/friendly-snippets",
						config = function()
							require("luasnip.loaders.from_vscode").lazy_load()
						end,
					},
				},
				opts = {},
			},
			"folke/lazydev.nvim",
		},
		--- @module 'blink.cmp'
		--- @type blink.cmp.Config
		opts = {
			keymap = {
				preset = "super-tab",
			},

			appearance = {
				nerd_font_variant = "mono",
			},

			completion = {
				documentation = { auto_show = true, auto_show_delay_ms = 500 },
				keyword = {
					range = "full",
				},
			},

			sources = {
				default = { "lsp", "path", "snippets", "lazydev", "buffer" },
				providers = {
					lazydev = { module = "lazydev.integrations.blink", score_offset = 100 },
				},
			},

			snippets = { preset = "luasnip" },

			-- Blink.cmp includes an optional, recommended rust fuzzy matcher,
			-- which automatically downloads a prebuilt binary when enabled.
			--
			-- By default, we use the Lua implementation instead, but you may enable
			-- the rust implementation via `'prefer_rust_with_warning'`
			--
			-- See :h blink-cmp-config-fuzzy for more information
			fuzzy = { implementation = "prefer_rust_with_warning" },

			-- Shows a signature help window while you type arguments for a function
			signature = { enabled = true },
		},
	},
	{
		"folke/which-key.nvim",
		event = "VimEnter", -- Sets the loading event to 'VimEnter'
		opts = {
			-- delay between pressing a key and opening which-key (milliseconds)
			-- this setting is independent of vim.o.timeoutlen
			delay = 0,
			icons = {
				-- set icon mappings to true if you have a Nerd Font
				mappings = vim.g.have_nerd_font,
				-- If you are using a Nerd Font: set icons.keys to an empty table which will use the
				-- default which-key.nvim defined Nerd Font icons, otherwise define a string table
				keys = vim.g.have_nerd_font and {} or {
					Up = "<Up> ",
					Down = "<Down> ",
					Left = "<Left> ",
					Right = "<Right> ",
					C = "<C-…> ",
					M = "<M-…> ",
					D = "<D-…> ",
					S = "<S-…> ",
					CR = "<CR> ",
					Esc = "<Esc> ",
					ScrollWheelDown = "<ScrollWheelDown> ",
					ScrollWheelUp = "<ScrollWheelUp> ",
					NL = "<NL> ",
					BS = "<BS> ",
					Space = "<Space> ",
					Tab = "<Tab> ",
					F1 = "<F1>",
					F2 = "<F2>",
					F3 = "<F3>",
					F4 = "<F4>",
					F5 = "<F5>",
					F6 = "<F6>",
					F7 = "<F7>",
					F8 = "<F8>",
					F9 = "<F9>",
					F10 = "<F10>",
					F11 = "<F11>",
					F12 = "<F12>",
				},
			},

			-- Document existing key chains
			spec = {
				{ "<leader>s", group = "[S]earch" },
				{ "<leader>t", group = "[T]oggle" },
				{ "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
			},
		},
	},
	{ -- used for completion, annotations and signatures of Neovim apis
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				-- Load luvit types when the `vim.uv` word is found
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},
	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},
	{ -- Adds git related signs to the gutter, as well as utilities for managing changes
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
		},
	},
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
		keys = { "<leader>t", ":NvimTreeToggle<CR>", mode = "n", desc = "[U]ndo[T]ree" },
		config = function()
			require("nvim-tree").setup({
				sort_by = "name",
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
		end,
	},
	{ -- Collection of various small independent plugins/modules
		"echasnovski/mini.nvim",
		config = function()
			-- Better Around/Inside textobjects
			--
			-- Examples:
			--  - va)  - [V]isually select [A]round [)]paren
			--  - yinq - [Y]ank [I]nside [N]ext [Q]uote
			--  - ci'  - [C]hange [I]nside [']quote
			require("mini.ai").setup({ n_lines = 500 })

			-- Add/delete/replace surroundings (brackets, quotes, etc.)
			--
			-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
			-- - sd'   - [S]urround [D]elete [']quotes
			-- - sr)'  - [S]urround [R]eplace [)] [']
			require("mini.surround").setup()

			-- Simple and easy statusline.
			--  You could remove this setup call if you don't like it,
			--  and try some other statusline plugin
			local statusline = require("mini.statusline")
			-- set use_icons to true if you have a Nerd Font
			statusline.setup({ use_icons = vim.g.have_nerd_font })

			-- You can configure sections in the statusline by overriding their
			-- default behavior. For example, here we set the section for
			-- cursor location to LINE:COLUMN
			---@diagnostic disable-next-line: duplicate-set-field
			statusline.section_location = function()
				return "%2l:%-2v"
			end

			-- ... and there is more!
			--  Check out: https://github.com/echasnovski/mini.nvim
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
	{ -- Fuzzy Finder (files, lsp, etc)
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ -- If encountering errors, see telescope-fzf-native README for installation instructions
				"nvim-telescope/telescope-fzf-native.nvim",

				-- `build` is used to run some command when the plugin is installed/updated.
				-- This is only run then, not every time Neovim starts up.
				build = "make",

				-- `cond` is a condition used to determine whether this plugin should be
				-- installed and loaded.
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			{ "nvim-telescope/telescope-ui-select.nvim" },

			-- Useful for getting pretty icons, but requires a Nerd Font.
			{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
		},
		config = function()
			-- [[ Configure Telescope ]]
			-- See `:help telescope` and `:help telescope.setup()`
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
				},
			})
			-- Enable Telescope extensions if they are installed
			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")

			-- See `:help telescope.builtin`
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
			vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
			vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
			vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
			vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
			vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
			vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
			vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
			vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
			vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })

			-- Slightly advanced example of overriding default behavior and theme
			vim.keymap.set("n", "<leader>/", function()
				-- You can pass additional configuration to Telescope to change the theme, layout, etc.
				builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "[/] Fuzzily search in current buffer" })

			-- It's also possible to pass additional configuration options.
			--  See `:help telescope.builtin.live_grep()` for information about particular keys
			vim.keymap.set("n", "<leader>s/", function()
				builtin.live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end, { desc = "[S]earch [/] in Open Files" })

			-- Shortcut for searching your Neovim configuration files
			vim.keymap.set("n", "<leader>sn", function()
				builtin.find_files({ cwd = vim.fn.stdpath("config") })
			end, { desc = "[S]earch [N]eovim files" })
		end,
	},
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			"sindrets/diffview.nvim",
			"ibhagwan/fzf-lua",
		},
		keys = {
			{
				"<leader>ng",
				":Neogit<CR>",
				mode = "n",
				desc = "[N]eo[g]it",
			},
		},
		config = true,
	},
	{ -- Highlight, edit, and navigate code
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		main = "nvim-treesitter.configs", -- Sets main module to use for opts
		-- [[ Configure Treesitter ]] See `:help nvim-treesitter`
		opts = {
			ensure_installed = {
				"bash",
				"c",
				"cpp",
				"go",
				"python",
				"rust",
				"tsx",
				"javascript",
				"typescript",
				"diff",
				"html",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"query",
				"vim",
				"vimdoc",
			},
			-- Autoinstall languages that are not installed
			auto_install = true,
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = { "ruby" },
			},
			indent = { enable = true, disable = { "ruby" } },
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
		},
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
		"folke/zen-mode.nvim",
		config = function()
			local colors = require("colors")

			local function run_applescript(script)
				-- Escape the script so osascript sees it correctly
				local escaped = vim.fn.shellescape(script)
				-- Either use vim.fn.system() or os.execute()
				os.execute("osascript -e " .. escaped)
			end

			-- Toggle fullscreen (⌘‑⌃‑F)
			local function toggle_fullscreen()
				local script = [[
    tell application "System Events"
        keystroke "f" using {command down, control down}
    end tell
  ]]
				run_applescript(script)
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
					toggle_fullscreen()

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
	{

		"chrishrb/gx.nvim",
		keys = { { "gx", "<cmd>Browse<cr>", mode = { "n", "x" } } },
		cmd = { "Browse" },
		init = function()
			vim.g.netrw_nogx = 1
		end,
		config = true,
	},
	{
		"NickvanDyke/opencode.nvim",
		dependencies = {
			-- Recommended for better prompt input, and required to use `opencode.nvim`'s embedded terminal — otherwise optional
			{ "folke/snacks.nvim", opts = { input = { enabled = true } } },
		},
		config = function()
			vim.g.opencode_opts = {
				-- Your configuration, if any — see `lua/opencode/config.lua`
			}

			-- Required for `opts.auto_reload`
			vim.opt.autoread = true

			-- Recommended keymaps
			vim.keymap.set("n", "<leader>ot", function()
				require("opencode").toggle()
			end, { desc = "[O]pencode [t]oggle" })

			vim.keymap.set("n", "<leader>oA", function()
				require("opencode").ask()
			end, { desc = "[O]pencode [A]sk" })

			vim.keymap.set("n", "<leader>oa", function()
				require("opencode").ask("@cursor: ")
			end, { desc = "[O]pencode [a]sk about cursor" })

			vim.keymap.set("v", "<leader>oa", function()
				require("opencode").ask("@selection: ")
			end, { desc = "[O]pencode [a]sk about selection" })

			vim.keymap.set("n", "<leader>oab", function()
				require("opencode").ask("@buffer: ")
			end, { desc = "[O]pencode [a]sk about current [b]uffer" })

			vim.keymap.set("n", "<leader>oaB", function()
				require("opencode").ask("@buffers: ")
			end, { desc = "[O]pencode [a]sk about all [B]uffers" })

			vim.keymap.set("n", "<leader>on", function()
				require("opencode").command("session_new")
			end, { desc = "[O]pencode [n]ew session" })

			vim.keymap.set("n", "<leader>oy", function()
				require("opencode").command("messages_copy")
			end, { desc = "[O]pencode [y]ank response" })

			vim.keymap.set("n", "<S-C-u>", function()
				require("opencode").command("messages_half_page_up")
			end, { desc = "Messages half page up" })
			vim.keymap.set("n", "<S-C-d>", function()
				require("opencode").command("messages_half_page_down")
			end, { desc = "Messages half page down" })

			vim.keymap.set({ "n", "v" }, "<leader>os", function()
				require("opencode").select()
			end, { desc = "[O]pencode [s]elect prompt" })
		end,
	},
}, {
	ui = {
		-- If you are using a Nerd Font: set icons to an empty table which will use the
		-- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
		icons = vim.g.have_nerd_font and {} or {
			cmd = "⌘",
			config = "🛠",
			event = "📅",
			ft = "📂",
			init = "⚙",
			keys = "🗝",
			plugin = "🔌",
			runtime = "💻",
			require = "🌙",
			source = "📄",
			start = "🚀",
			task = "📌",
			lazy = "💤 ",
		},
	},
})

--- package keymaps (don't support `keys`)
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

vim.keymap.set("x", "<leader>re", ":Refactor extract ")
vim.keymap.set("x", "<leader>rf", ":Refactor extract_to_file ")

vim.keymap.set("x", "<leader>rv", ":Refactor extract_var ")

vim.keymap.set({ "n", "x" }, "<leader>ri", ":Refactor inline_var")

vim.keymap.set("n", "<leader>rI", ":Refactor inline_func")

vim.keymap.set("n", "<leader>rb", ":Refactor extract_block")
vim.keymap.set("n", "<leader>rbf", ":Refactor extract_block_to_file")

vim.api.nvim_set_keymap("n", "<leader>it", ":LlamaToggle<CR>", { noremap = true, desc = "[i]nfill [t]oggle" })
vim.api.nvim_set_keymap("n", "<leader>ie", ":LlamaEnable<CR>", { noremap = true, desc = "[i]nfill [e]nable" })
vim.api.nvim_set_keymap("n", "<leader>id", ":LlamaDisable<CR>", { noremap = true, desc = "[i]nfill [d]isable" })

vim.api.nvim_set_keymap("n", "<leader>t", ":NvimTreeToggle<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>ut", ":UndotreeToggle<CR>", { noremap = true, silent = true })

-- Additional lsp servers --
--require("lspconfig").sourcekit.setup({
--cmd = {
--"/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
--},
--filetypes = { "swift" },
--})
--require("lspconfig").ocamllsp.setup({
--cmd = { "/Users/mike/.opam/default/bin/ocamllsp" },
--filetypes = { "ocaml", "menhir", "ocamlinterface", "ocamllex", "reason", "dune" },
--})

--tailwind sort
vim.api.nvim_set_keymap("n", "<leader>st", ":TailwindSort<CR>", { noremap = true, silent = true })
vim.cmd([[runtime macros/matchit.vim]])
-- ocaml fix, so i can still use nvimtree
vim.cmd("autocmd FileType ocaml nnoremap <leader>t :NvimTreeToggle<CR>")
-- vim: ts=2 sts=2 sw=2 et
