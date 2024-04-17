return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			vim.list_extend(opts.ensure_installed, { "kotlin" })
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			opts.ensure_installed = vim.list_extend(opts.ensure_installed, { "kotlin_language_server" })
		end,
	},

	{
		"jay-babu/mason-null-ls.nvim",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			opts.ensure_installed = vim.list_extend(opts.ensure_installed, { "ktlint" })
		end,
	},

	{
		"jay-babu/mason-nvim-dap.nvim",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			opts.ensure_installed = vim.list_extend(opts.ensure_installed, { "kotlin" })
		end,
	},
}
