return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			if opts.ensure_installed ~= "all" then
				opts.ensure_installed =
					YukiVim.list_insert_unique(opts.ensure_installed, { "c", "cpp", "objc", "cuda", "proto" })
			end
		end,
	},
	{
		"p00f/clangd_extensions.nvim",
		lazy = true,
		config = function() end,
		opts = {
			inlay_hints = {
				inline = false,
			},
			ast = {
				--These require codicons (https://github.com/microsoft/vscode-codicons)
				role_icons = {
					type = "",
					declaration = "",
					expression = "",
					specifier = "",
					statement = "",
					["template argument"] = "",
				},
				kind_icons = {
					Compound = "",
					Recovery = "",
					TranslationUnit = "",
					PackExpansion = "",
					TemplateTypeParm = "",
					TemplateTemplateParm = "",
					TemplateParamObject = "",
				},
			},
		},
		init = function()
			local augroup = vim.api.nvim_create_augroup("clangd_extensions", { clear = true })
			vim.api.nvim_create_autocmd("LspAttach", {
				group = augroup,
				desc = "Load clangd_extensions with clangd",
				callback = function(args)
					if assert(vim.lsp.get_client_by_id(args.data.client_id)).name == "clangd" then
						require("clangd_extensions")
						vim.api.nvim_del_augroup_by_id(augroup)
					end
				end,
			})
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		opts = function(_, opts)
			opts.ensure_installed = YukiVim.list_insert_unique(opts.ensure_installed, "clangd")
		end,
	},
	{
		"williamboman/mason.nvim",
		opts = function(_, opts)
			opts.ensure_installed = YukiVim.list_insert_unique(opts.ensure_installed, { "codelldb" })
		end,
	},
	{

		"WhoIsSethDaniel/mason-tool-installer.nvim",
		optional = true,
		opts = function(_, opts)
			opts.ensure_installed = YukiVim.list_insert_unique(opts.ensure_installed, { "clangd", "codelldb" })
		end,
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				-- Ensure mason installs the server
				clangd = {
					keys = {
						{ "<leader>cR", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header (C/C++)" },
					},
					root_dir = function(fname)
						return require("lspconfig.util").root_pattern(
							"Makefile",
							"configure.ac",
							"configure.in",
							"config.h.in",
							"meson.build",
							"meson_options.txt",
							"build.ninja"
						)(fname) or require("lspconfig.util").root_pattern(
							"compile_commands.json",
							"compile_flags.txt"
						)(fname) or require("lspconfig.util").find_git_ancestor(fname)
					end,
					capabilities = {
						offsetEncoding = { "utf-8" },
					},
					cmd = {
						"clangd",
						"--fallback-style=LLVM",
						"--background-index",
						"--clang-tidy",
						"--header-insertion=iwyu",
						"--completion-style=detailed",
						"--function-arg-placeholders",
					},
					init_options = {
						usePlaceholders = true,
						completeUnimported = true,
						clangdFileStatus = true,
					},
				},
			},
			setup = {
				clangd = function(_, opts)
					local clangd_ext_opts = YukiVim.opts("clangd_extensions.nvim")
					require("clangd_extensions").setup(
						vim.tbl_deep_extend("force", clangd_ext_opts or {}, { server = opts })
					)
					return false
				end,
			},
		},
	},
	{
		"nvim-cmp",
		opts = function(_, opts)
			table.insert(opts.sorting.comparators, 1, require("clangd_extensions.cmp_scores"))
		end,
	},
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			-- Ensure C/C++ debugger is installed
			"williamboman/mason.nvim",
			optional = true,
			opts = function(_, opts)
				opts.ensure_installed = YukiVim.list_insert_unique(opts.ensure_installed, { "codelldb" })
			end,
		},
		opts = function()
			local dap = require("dap")
			if not dap.adapters["codelldb"] then
				require("dap").adapters["codelldb"] = {
					type = "server",
					host = "localhost",
					port = "${port}",
					executable = {
						command = "codelldb",
						args = {
							"--port",
							"${port}",
						},
					},
				}
			end
			for _, lang in ipairs({ "c", "cpp" }) do
				dap.configurations[lang] = {
					{
						type = "codelldb",
						request = "launch",
						name = "Launch file",
						program = function()
							return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
						end,
						cwd = "${workspaceFolder}",
					},
					{
						type = "codelldb",
						request = "attach",
						name = "Attach to process",
						processId = require("dap.utils").pick_process,
						cwd = "${workspaceFolder}",
					},
				}
			end
		end,
	},
}
