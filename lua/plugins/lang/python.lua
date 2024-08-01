local ruff = "ruff"
return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = { ensure_installed = { "ninja", "rst" } },
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				pyright = {
					enabled = true,
				},
				ruff = {
					cmd_env = { RUFF_TRACE = "messages" },
					init_options = {
						settings = {
							logLevel = "error",
						},
					},
					keys = {
						{
							"<leader>co",
							YukiVim.lsp.action["source.organizeImports"],
							desc = "Organize Imports",
						},
					},
					enabled = true,
				},
				ruff_lsp = {
					enabled = false,
					keys = {
						{
							"<leader>co",
							YukiVim.lsp.action["source.organizeImports"],
							desc = "Organize Imports",
						},
					},
				},
			},

			setup = {
				[ruff] = function()
					YukiVim.lsp.on_attach(function(client, _)
						-- Disable hover in favor of Pyright
						client.server_capabilities.hoverProvider = false
					end, ruff)
				end,
			},
		},
	},
	{
		"nvim-neotest/neotest",
		optional = true,
		dependencies = {
			"nvim-neotest/neotest-python",
		},
		opts = {
			adapters = {
				["neotest-python"] = {},
			},
		},
	},
	{
		"mfussenegger/nvim-dap",
		optional = true,
		dependencies = {
			"mfussenegger/nvim-dap-python",
			keys = {
				{
					"<leader>dPt",
					function()
						require("dap-python").test_method()
					end,
					desc = "Debug Method",
					ft = "python",
				},
				{
					"<leader>dPc",
					function()
						require("dap-python").test_class()
					end,
					desc = "Debug Class",
					ft = "python",
				},
			},
			config = function()
				local path = require("mason-registry").get_package("debugpy"):get_install_path()
				require("dap-python").setup(path .. "/venv/bin/python")
			end,
		},
	},
	{
		"linux-cultist/venv-selector.nvim",
		branch = "regexp",
		cmd = "VenvSelect",
		opts = {
			settings = {
				options = {
					notify_user_on_venv_activation = true,
				},
			},
		},
		ft = "python",
		keys = { { "<leader>cv", "<cmd>:VenvSelect<cr>", desc = "Select VirtualEnv" } },
	},
	{
		"hrsh7th/nvim-cmp",
		opts = function(_, opts)
			opts.auto_brackets = opts.auto_brackets or {}
			table.insert(opts.auto_brackets, "python")
		end,
	},
	{
		"jay-babu/mason-nvim-dap.nvim",
		optional = true,
		opts = {
			handlers = {
				python = function() end,
			},
		},
	},
}
