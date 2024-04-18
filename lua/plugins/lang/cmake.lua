return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			opts.ensure_installed = YukiVim.list_insert_unique(opts.ensure_installed, "cmake")
		end,
	},
	{
		"mason.nvim",
		opts = function(_, opts)
			opts.ensure_installed = YukiVim.list_insert_unique(opts.ensure_installed, { "cmakelang", "cmakelint" })
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		opts = function(_, opts)
			opts.ensure_installed = YukiVim.list_insert_unique(opts.ensure_installed, "neocmake")
		end,
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				neocmake = {},
			},
		},
	},
	{
		"Civitasv/cmake-tools.nvim",
		ft = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
		opts = {},
	},
	{
		"nvimtools/none-ls.nvim",
		opts = function(_, opts)
			local nls = require("null-ls")
			opts.sources = YukiVim.list_insert_unique(opts.sources, nls.builtins.diagnostics.cmake_lint)
		end,
	},
	{
		"mfussenegger/nvim-lint",
		opts = {
			linters_by_ft = {
				cmake = { "cmakelint" },
			},
		},
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		optional = true,
		opts = function(_, opts)
			opts.ensure_installed = YukiVim.list_insert_unique(opts.ensure_installed, { "neocmakelsp" })
		end,
	},
}
