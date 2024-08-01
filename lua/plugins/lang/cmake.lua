return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = { ensure_installed = { "cmake" } },
	},
	{
		"mason.nvim",
		opts = { ensure_installed = { "cmakelang", "cmakelint" } },
	},
	-- {
	-- 	"williamboman/mason-lspconfig.nvim",
	-- 	opts = function(_, opts)
	-- 		opts.ensure_installed = YukiVim.list_insert_unique(opts.ensure_installed, "neocmake")
	-- 	end,
	-- },
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
		lazy = true,
		ft = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
		init = function()
			local loaded = false
			local function check()
				local cwd = vim.uv.cwd()
				if vim.fn.filereadable(cwd .. "/CMakeLists.txt") == 1 then
					require("lazy").load({ plugins = { "cmake-tools.nvim" } })
					loaded = true
				end
			end
			check()
			vim.api.nvim_create_autocmd("DirChanged", {
				callback = function()
					if not loaded then
						check()
					end
				end,
			})
		end,
		opts = {},
	},
	{
		"nvimtools/none-ls.nvim",
		optional = true,
		opts = function(_, opts)
			local nls = require("null-ls")
			opts.sources = vim.list_extend(opts.sources or {}, { nls.builtins.diagnostics.cmake_lint })
		end,
	},
	{
		"mfussenegger/nvim-lint",
		optional = true,
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
