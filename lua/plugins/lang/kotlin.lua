return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			opts.ensure_installed = YukiVim.list_insert_unique(opts.ensure_installed, { "kotlin" })
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		opts = function(_, opts)
			opts.ensure_installed = YukiVim.list_insert_unique(opts.ensure_installed, { "kotlin_language_server" })
		end,
	},

	{
		"jay-babu/mason-null-ls.nvim",
		opts = function(_, opts)
			opts.ensure_installed = YukiVim.list_insert_unique(opts.ensure_installed, { "ktlint" })
		end,
	},

	{
		"jay-babu/mason-nvim-dap.nvim",
		opts = function(_, opts)
			opts.ensure_installed = YukiVim.list_insert_unique(opts.ensure_installed, { "kotlin" })
		end,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		optional = true,
		opts = function(_, opts)
			opts.ensure_installed = YukiVim.list_insert_unique(opts.ensure_installed, {
				"kotlin-language-server",
				"ktlint",
				"kotlin-debug-adapter",
			})
		end,
	},
	{
		"mfussenegger/nvim-lint",
		optional = true,
		opts = {
			linters_by_ft = {
				kotlin = { "ktlint" },
			},
		},
	},
}
