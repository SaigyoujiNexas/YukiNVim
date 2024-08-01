return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = { ensure_installed = { "kotlin" } },
	},
	{
		"williamboman/mason.nvim",
		opts = { ensure_installed = { "ktlint" } },
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				kotlin_language_server = {},
			},
		},
	},
	{
		"stevearc/conform.nvim",
		optional = true,
		opts = {
			formatters_by_ft = { kotlin = { "ktlint" } },
		},
	},
	{
		"nvimtools/none-ls.nvim",
		optional = true,
		opts = function(_, opts)
			local nls = require("null-ls")
			opts.sources = vim.list_extend(opts.sources or {}, {
				nls.builtins.formatting.ktlint,
				nls.builtins.diagnostics.ktlint,
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
	{
		"mfussenegger/nvim-dap",
		optinal = true,
		dependencies = "williamboman/mason.nvim",
		opts = function()
			local dap = require("dap")
			if not dap.adapters.kotlin then
				dap.adapter.kotlin = {
					type = "executable",
					command = "kotlin-debug-adapter",
					options = { auto_continue_if_many_stopped = false },
				}
			end
		end,
	},
}
