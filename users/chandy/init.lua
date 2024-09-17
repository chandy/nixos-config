local fn = vim.fn
local opt = vim.opt
local map = vim.api.nvim_set_keymap

vim.bo.expandtab = true
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2
opt.scrolloff = 999

vim.g.mapleader = ","

map("n", "<Leader>w", ":write<CR>", { noremap = true })
map("n", "<Leader>q", ":q<CR>", { noremap = true })
-- map('n', '<Esc>', "<C-\><C-n>", {tnoremap = true})

--  Relative line numbers
opt.relativenumber = true
opt.number = true

local install_path = fn.stdpath("data") .. "/site/pack/paqs/start/paq-nvim"

if fn.empty(fn.glob(install_path)) > 0 then
	fn.system({ "git", "clone", "--depth=1", "https://github.com/savq/paq-nvim.git", install_path })
end

-- Package Management
require("paq")({
	"savq/paq-nvim", -- Let Paq manage itself

	-- Telescope https://github.com/nvim-telescope/telescope.nvim
	"BurntSushi/ripgrep",

	-- Adding since telescope needs the plenary modules which are not in Lua5.1
	"nvim-lua/plenary.nvim",
	"nvim-lua/popup.nvim",
	"nvim-telescope/telescope.nvim",

	{ "nvim-telescope/telescope-fzf-native.nvim", hook = "make" },
	"nvim-telescope/telescope-file-browser.nvim",

	-- LSP
	"neovim/nvim-lspconfig", -- Mind the semi-colons
	"williamboman/nvim-lsp-installer",
	"nvim-lua/lsp-status.nvim",
	"jose-elias-alvarez/null-ls.nvim",
	"folke/trouble.nvim",

	"hrsh7th/cmp-nvim-lsp",
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-path",
	"hrsh7th/cmp-cmdline",
	"hrsh7th/nvim-cmp",

	-- Luasnipa
	"L3MON4D3/LuaSnip",
	"saadparwaiz1/cmp_luasnip",

	"folke/which-key.nvim",

	{ "lervag/vimtex", opt = true }, -- Use braces when passing options
	"nvim-treesitter/nvim-treesitter",
	"nvim-treesitter/playground",

	"mhinz/vim-startify",

	"kyazdani42/nvim-web-devicons",
	"sbdchd/neoformat",

	"nvim-lualine/lualine.nvim",

	"EdenEast/nightfox.nvim",
	"rebelot/kanagawa.nvim",

	"akinsho/toggleterm.nvim",
})

-- require('chandy')

-- TELESCOPE
-- You dont need to set any of these options. These are the default ones. Only
-- the loading is important
local action_layout = require("telescope.actions.layout")
require("telescope").setup({
	defaults = {
		prompt_prefix = "$ ",
		mappings = {
			i = {
				["<C-r>"] = "which_key",
				["<C-p>"] = action_layout.toggle_preview,
			},
		},
	},
	pickers = {
		find_files = {
			hidden = false,
		},
		mappings = {
			i = {
				["<C-e>"] = function()
					print("bb is cool")
				end,
			},
		},
	},
	extensions = {
		fzf = {
			fuzzy = true, -- false will only do exact matching
			override_generic_sorter = true, -- override the generic sorter
			override_file_sorter = true, -- override the file sorter
			case_mode = "smart_case", -- or "ignore_case" or "respect_case"
			-- the default case_mode is "smart_case"
		},
	},
})
-- To get fzf loaded and working with telescope, you need to call
-- load_extension, somewhere after setup function:
require("telescope").load_extension("fzf")
require("telescope").load_extension("file_browser")

map("n", "<Leader>ff", ":Telescope find_files<CR>", { noremap = true })
map("n", "<Leader>fi", ":Telescope git_files<CR>", { noremap = true })
map("n", "<Leader>fg", ":Telescope live_grep<CR>", { noremap = true })
map("n", "<Leader>fb", ":Telescope buffers<CR>", { noremap = true })
map("n", "<Leader>fh", ":Telescope help_tags<CR>", { noremap = true })
map("n", "<Leader>fo", ":Telescope oldfiles<CR>", { noremap = true })
map("n", "<Leader>fl", ":Telescope file_browser<CR>", { noremap = true })

require("nvim-treesitter.configs").setup({
	ensure_installed = "maintained",
	highlight = {
		enable = true, -- false will disable the whole extension
	},
	indent = {
		enable = true,
	},
})
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"

-- Setup nvim-cmp.
local cmp = require("cmp")

cmp.setup({
	snippet = {
		-- REQUIRED - you must specify a snippet engine
		expand = function(args)
			-- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
			require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
			-- require('snippy').expand_snippet(args.body) -- For `snippy` users.
			-- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
		end,
	},
	mapping = {
		["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
		["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
		["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
		["<C-y>"] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
		["<C-e>"] = cmp.mapping({
			i = cmp.mapping.abort(),
			c = cmp.mapping.close(),
		}),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
		-- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
	},
	sources = cmp.config.sources({
		-- { name = 'nvim_lsp' },
		-- { name = 'vsnip' }, -- For vsnip users.
		{ name = "luasnip" }, -- For luasnip users.
		-- { name = 'ultisnips' }, -- For ultisnips users.
		-- { name = 'snippy' }, -- For snippy users.
	}, {
		{ name = "buffer" },
	}),
})

-- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline("/", {
	sources = {
		{ name = "buffer" },
	},
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(":", {
	sources = cmp.config.sources({
		{ name = "path" },
	}, {
		{ name = "cmdline" },
	}),
})

local lsp_installer = require("nvim-lsp-installer")
lsp_installer.on_server_ready(function(server)
	local opts = {}
	if server.name == "sumneko_lua" then
		opts = {
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim", "use" },
					},
					--workspace = {
					-- Make the server aware of Neovim runtime files
					--library = {[vim.fn.expand('$VIMRUNTIME/lua')] = true, [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true}
					--}
				},
			},
		}
	end
	server:setup(opts)
end)

local nvim_lsp = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())
local servers = {
	"puppet",
	"cmake",
	"rust_analyzer",
	"tsserver",
	"rust_analyzer",
	"dockerls",
	"ansiblels",
	"bashls",
	"html",
	"yamlls",
}
for _, lsp in ipairs(servers) do
	nvim_lsp[lsp].setup({
		-- on_attach = on_attach,
		flags = {
			debounce_text_changes = 150,
		},
		capabilities = capabilities,
	})
end
nvim_lsp.sumneko_lua.setup({
	flags = {
		debounce_text_changes = 150,
	},
	capabilities = capabilities,
	settings = {
		Lua = {
			runtime = {
				-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
				version = "LuaJIT",
				-- Setup your lua path
				--path = runtime_path,
			},
			diagnostics = {
				-- Get the language server to recognize the `vim` global
				globals = { "vim", "use" },
			},
			workspace = {
				-- Make the server aware of Neovim runtime files
				library = vim.api.nvim_get_runtime_file("", true),
			},
			-- Do not send telemetry data containing a randomized but unique identifier
			telemetry = {
				enable = false,
			},
		},
	},
})
map("n", "gk", ":lua vim.lsp.buf.definition()<cr>", { noremap = true })
map("n", "gD", ":lua vim.lsp.buf.declaration()<cr>", { noremap = true })
map("n", "gi", ":lua vim.lsp.buf.implementation()<cr>", { noremap = true })
map("n", "gw", ":lua vim.lsp.buf.document_symbol()<cr>", { noremap = true })
map("n", "gw", ":lua vim.lsp.buf.workspace_symbol()<cr>", { noremap = true })
map("n", "gr", ":lua vim.lsp.buf.references()<cr>", { noremap = true })
map("n", "gt", ":lua vim.lsp.buf.type_definition()<cr>", { noremap = true })
map("n", "K", ":lua vim.lsp.buf.hover()<cr>", { noremap = true })
map("n", "<c-k>", ":lua vim.lsp.buf.signature_help()<cr>", { noremap = true })
map("n", "<leader>af", ":lua vim.lsp.buf.code_action()<cr>", { noremap = true })

local wk = require("which-key")
wk.setup({})

require("lualine").setup()

-- require('nightfox').load("nightfox")

require("lualine").setup({
	options = {
		-- ... your lualine config
		-- theme = "kanagawa",
	},
})
require("kanagawa").setup({
	overrides = {},
})

-- setup must be called before loading
vim.cmd("colorscheme kanagawa")

require("trouble").setup({
	-- your configuration comes here
	-- or leave it empty to use the default settings
	-- refer to the configuration section below
})
map("n", "<leader>xx", "<cmd>Trouble<cr>", { silent = true, noremap = true })
map("n", "<leader>xw", "<cmd>Trouble workspace_diagnostics<cr>", { silent = true, noremap = true })
map("n", "<leader>xd", "<cmd>Trouble document_diagnostics<cr>", { silent = true, noremap = true })
map("n", "<leader>xl", "<cmd>Trouble loclist<cr>", { silent = true, noremap = true })
map("n", "<leader>xq", "<cmd>Trouble quickfix<cr>", { silent = true, noremap = true })
map("n", "gR", "<cmd>Trouble lsp_references<cr>", { silent = true, noremap = true })

-- null-ls
local null_ls = require("null-ls")
null_ls.setup({
	sources = {
		null_ls.builtins.formatting.stylua,
		-- causing issues, can be confifgured to ignore globals somewhere
		-- null_ls.builtins.diagnostics.luacheck,
		null_ls.builtins.formatting.eslint,
		null_ls.builtins.diagnostics.eslint,
		null_ls.builtins.code_actions.eslint,
		null_ls.builtins.formatting.prettier,
		null_ls.builtins.completion.spell,
		null_ls.builtins.formatting.nixfmt,
		null_ls.builtins.diagnostics.statix,
		null_ls.builtins.code_actions.statix,
		null_ls.builtins.formatting.rustfmt,
	},
})
