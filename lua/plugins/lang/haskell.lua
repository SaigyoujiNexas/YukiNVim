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
			{ "mfussenegger/nvim-dap", optional = true },
		},
		version = "^3",
		init = function() end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		optional = true,
		opts = function(_, opts)
			opts.ensure_installed = YukiVim.list_insert_unique(opts.ensure_installed, { "hls" })
		end,
	},
	{
		"jay-babu/mason-nvim-dap.nvim",
		optional = true,
		opts = function(_, opts)
			opts.ensure_installed = YukiVim.list_insert_unique(opts.ensure_installed, { "haskell" })
		end,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		optional = true,
		opts = function(_, opts)
			opts.ensure_installed = YukiVim.list_insert_unique(
				opts.ensure_installed,
				{ "haskell-debug-adapter", "haskell-language-server" }
			)
		end,
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
		optional = true,
		dependencies = { "mrcjkb/neotest-haskell" },
		opts = function(_, opts)
			if not opts.adapters then
				opts.adapters = {}
			end
			table.insert(opts.adapters, (require("neotest-haskell")))
		end,
	},
}
