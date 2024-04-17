local java_filetypes = { "java" }
---@param config table
---@param custom function | table | nil
local function extend_or_override(config, custom, ...)
	if type(custom) == "function" then
		config = custom(config, ...) or config
	elseif custom then
		config = vim.tbl_deep_extend("force", config, custom) --[[@as table]]
	end
	return config
end

return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			vim.list_extend(opts.ensure_installed, { "java" })
		end,
	},
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			{
				"williamboman/mason.nvim",
				opts = function(_, opts)
					opts.ensure_installed = opts.ensure_installed or {}
					vim.list_extend(opts.ensure_installed, { "java-test", "java-debug-adapter" })
				end,
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			-- make sure mason installs the server
			servers = {
				jdtls = {},
			},
			setup = {
				jdtls = function()
					return true -- avoid duplicate servers
				end,
			},
		},
	},
	{
		"mfussenegger/nvim-jdtls",
		dependencies = { "folke/which-key.nvim" },
		ft = java_filetypes,
		opts = function()
			return {
				root_dir = require("lspconfig.server_configurations.jdtls").default_config.root_dir,
				project_name = function(root_dir)
					return root_dir and vim.fs.basename(root_dir)
				end,
				jdtls_config_dir = function(project_name)
					return vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/config"
				end,
				jdtls_workspace_dir = function(project_name)
					return vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/workspace"
				end,
				cmd = { vim.fn.exepath("jdtls") },
				full_cmd = function(opts)
					local fname = vim.api.nvim_buf_get_name(0)
					local root_dir = opts.root_dir(fname)
					local project_name = opts.project_name(root_dir)
					local cmd = vim.deepcopy(opts.cmd)
					if project_name then
						vim.list_extend(cmd, {
							"-configuration",
							opts.jdtls_config_dir(project_name),
							"-data",
							opts.jdtls_workspace_dir(project_name),
						})
					end
					return cmd
				end,
				dap = { hotcodereplace = "auto", config_overrides = {} },
				dap_main = {},
				test = true,
			}
		end,
		config = function()
			local opts = YukiVim.opts("nvim-jdtls") or {}
			local mason_registry = require("mason-registry")
			local bundles = {} ---@type string[]
			if opts.dap then
				local java_dbg_pkg = mason_registry.get_package("java-debug-adapter")
				local java_dbg_path = java_dbg_pkg:get_install_path()
				local jar_patterns = {
					java_dbg_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar",
				}
				if opts.test then
					local java_test_pkg = mason_registry.get_package("java-test")
					local java_test_path = java_test_pkg:get_install_path()
					vim.list_extend(jar_patterns, {
						java_test_path .. "extension/server/*.jar",
					})
				end
				for _, jar_pattern in ipairs(jar_patterns) do
					for _, bundle in ipairs(vim.split(vim.fn.glob(jar_pattern), "\n")) do
						table.insert(bundles, bundle)
					end
				end
			end

			local function attach_jdtls()
				local fname = vim.api.nvim_buf_get_name(0)

				-- Configuration can be augmented and overridden by opts.jdtls
				local config = extend_or_override({
					cmd = opts.full_cmd(opts),
					root_dir = opts.root_dir(fname),
					init_options = {
						bundles = bundles,
					},
					capabilities = YukiVim.has("cmp-nvim-lsp") and require("cmp_nvim_lsp").default_capabilities()
						or nil,
				}, opts.jdtls)
				-- Existing server will be reused if the root_dir matches.
				require("jdtls").start_or_attach(config)
				-- not need to require("jdtls.setup").add_commands(), start automatically adds commands
			end
			vim.api.nvim_create_autocmd("FileType", {
				pattern = java_filetypes,
				callback = attach_jdtls,
			})
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if client and client.name == "jdtls" then
						local wk = require("which-key")
						wk.register({
							["gs"] = { require("jdtls").super_implementation, "Goto Super" },
							["gS"] = { require("jdtls.tests").goto_subjects, "Goto Subjects" },
						})
						if opts.dap then
							require("jdtls").setup_dap(opts.dap)
							require("jdtls.dap").setup_dap_main_class_configs(opts.dap_main)
							if opts.test and mason_registry.is_installed("java-test") then
								-- custom keymaps for Java test runner (not yet compatible with neotest)
								wk.register({
									["<leader>t"] = { name = "+test" },
									["<leader>tt"] = { require("jdtls.dap").test_class, "Run All Test" },
									["<leader>tr"] = { require("jdtls.dap").test_nearest_method, "Run Nearest Test" },
									["<leader>tT"] = { require("jdtls.dap").pick_test, "Run Test" },
								}, { mode = "n", buffer = args.buf })
							end
						end
						if opts.on_attach then
							opts.on_attach(args)
						end
					end
				end,
			})
			attach_jdtls()
		end,
	},
}
