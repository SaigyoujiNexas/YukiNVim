local haskell_ft = { "haskell", "lhaskell", "cabal", "cabalproject" }

return {
	{
		"nvim-treesitter/nvim-treesitter",
		optional = true,
		opts = function(_, opts)
			if opts.ensure_installed ~= "all" then
				opts.ensure_installed = YukiVim.list_insert_unique(opts.ensure_installed, { "haskell" })
			end
		end,
	},
	{
		"mrcjkb/haskell-tools.nvim",
		ft = haskell_ft,
		dependencies = {
			{ "nvim-telescope/telescope.nvim", optional = true },
		},
		version = "^3",
		config = function()
			local ok, telescope = pcall(require, "telescope")
			if ok then
				telescope.load_extension("ht")
			end
		end,
	},
	{
		"williamboman/mason.nvim",
		opts = { ensure_installed = { "haskell-language-server" } },
	},
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			{
				"williamboman/mason.nvim",
				opts = { ensure_installed = { "haskell-debug-adapter" } },
			},
		},
	},
	{
		"mrcjkb/haskell-snippets.nvim",
		ft = haskell_ft,
		dependencies = { "L3MON4D3/LuaSnip" },
		config = function()
			local haskell_snippets = require("haskell-snippets").all
			require("luasnip").add_snippets("haskell", haskell_snippets, { key = "haskell" })
		end,
	},
	{
		"luc-tielen/telescope_hoogle",
		ft = haskell_ft,
		dependencies = {
			{ "nvim-telescope/telescope.nvim" },
		},
		config = function()
			require("telescope").load_extension("hoogle")
		end,
	},
	{
		"nvim-neotest/neotest",
		dependencies = { "mrcjkb/neotest-haskell" },
		opts = {
			adapters = {
				["neotest-haskell"] = {},
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			setup = {
				hls = function()
					return true
				end,
			},
		},
	},
}
