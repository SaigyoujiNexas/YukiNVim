return {
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		opts = function(_, _)
			return {
				ensure_installed = {
					"stylua",
					"shfmt",
				},
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			}
		end,
		---@param opts MasonSettings | {ensure_installed: string[]}
		config = function(_, opts)
			require("mason").setup(opts)
			local mr = require("mason-registry")
			mr:on("package:install:success", function()
				vim.defer_fn(function()
					-- trigger FileType event to possibly load this newly installed LSP server
					require("lazy.core.handler.event").trigger({
						event = "FileType",
						buf = vim.api.nvim_get_current_buf(),
					})
				end, 100)
			end)
			local function ensure_installed()
				for _, tool in ipairs(opts.ensure_installed) do
					local p = mr.get_package(tool)
					if not p:is_installed() then
						p:install()
					end
				end
			end
			if mr.refresh then
				mr.refresh(ensure_installed)
			else
				ensure_installed()
			end
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
	},
	{
		"nvimtools/none-ls.nvim",
		dependencies = { "mason.nvim" },
		init = function()
			YukiVim.on_very_lazy(function()
				-- register the formatter with LazyVim
				YukiVim.format.register({
					name = "none-ls.nvim",
					priority = 200, -- set higher than conform, the builtin formatter
					primary = true,
					format = function(buf)
						return YukiVim.lsp.format({
							bufnr = buf,
							filter = function(client)
								return client.name == "null-ls"
							end,
						})
					end,
					sources = function(buf)
						local ret = require("null-ls.sources").get_available(vim.bo[buf].filetype, "NULL_LS_FORMATTING")
							or {}
						return vim.tbl_map(function(source)
							return source.name
						end, ret)
					end,
				})
			end)
		end,
		opts = function(_, opts)
			local nls = require("null-ls")
			opts.root_dir = opts.root_dir
				or require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", "Makefile", ".git")
			opts.sources = vim.list_extend(opts.sources or {}, {
				nls.builtins.formatting.fish_indent,
				nls.builtins.diagnostics.fish,
				nls.builtins.formatting.stylua,
				nls.builtins.formatting.shfmt,
			})
		end,
	},

	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{
				"folke/neoconf.nvim",
				cmd = "Neoconf",
				config = false,
				dependencies = { "nvim-lspconfig" },
			},
			{
				"folke/neodev.nvim",
				opts = {},
			},
			"mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		opts = {
			diagnostics = {
				underline = true,
				update_in_insert = false,
				virtual_text = {
					spacing = 4,
					source = "if_many",
					prefix = "",
				},
				severity_sort = true,
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = require("config").icons.diagnostics.Error,
						[vim.diagnostic.severity.WARN] = require("config").icons.diagnostics.Warn,
						[vim.diagnostic.severity.HINT] = require("config").icons.diagnostics.Hint,
						[vim.diagnostic.severity.INFO] = require("config").icons.diagnostics.Info,
					},
				},
			},
			inlay_hints = {
				enabled = false,
			},
			codelens = {
				enabled = false,
			},
			capabilities = {},
			format = {
				formatting_options = nil,
				timeout_ms = nil,
			},
			servers = {
				lua_ls = {
					settings = {
						Lua = {
							workspace = {
								checkThirdParty = false,
							},
							codeLens = {
								enable = true,
							},
							completion = {
								callSnippet = "Replace",
							},
						},
					},
				},
			},
			setup = {},
		},
		config = function(_, opts)
			if YukiVim.has("neoconf.nvim") then
				local plugin = require("lazy.core.config").spec.plugins["neoconf.nvim"]
				require("neoconf").setup(require("lazy.core.plugin").values(plugin, "opts", false))
			end
			-- setup autoformat
			YukiVim.format.register(YukiVim.lsp.formatter())

			require("lspconfig").sourcekit.setup({
				cmd = {
					"/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
				},
			})
			if opts.autoformat ~= nil then
				vim.g.autoformat = opts.autoformat
				YukiVim.deprecate("nvim-lspconfig.opts.autoformat", "vim.g.autoformat")
			end

			local register_capability = vim.lsp.handlers["client/registerCapability"]
			vim.lsp.handlers["client/registerCapability"] = function(err, res, ctx)
				local ret = register_capability(err, res, ctx)
				return ret
			end

			if vim.fn.has("nvim-0.10.0") == 0 then
				for severity, icon in pairs(opts.diagnostics.signs.text) do
					local name = vim.diagnostic.severity[severity]:lower():gsub("^%l", string.upper)
					name = "DiagnosticSign" .. name
					vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
				end
			end

			if opts.inlay_hints.enabled then
				YukiVim.lsp.on_attach(function(client, buffer)
					if client.supports_method("textDocument/inlayHint") then
						YukiVim.toggle.inlay_hints(buffer, true)
					end
				end)
			end

			if opts.codelens.enabled and vim.lsp.codelens then
				YukiVim.lsp.on_attach(function(client, buffer)
					if client.supports_method("textDocument/codeLens") then
						vim.lsp.codelens.refresh()
						--- autocmd BufEnter,CursorHold,InsertLeave <buffer> lua vim.lsp.codelens.refresh()
						vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
							buffer = buffer,
							callback = vim.lsp.codelens.refresh,
						})
					end
				end)
			end

			if type(opts.diagnostics.virtual_text) == "table" and opts.diagnostics.virtual_text.prefix == "icons" then
				opts.diagnostics.virtual_text.prefix = vim.fn.has("nvim-0.10.0") == 0 and "●"
					or function(diagnostic)
						local icons = require("config").icons.diagnostics
						for d, icon in pairs(icons) do
							if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
								return icon
							end
						end
					end
			end

			vim.diagnostic.config(vim.deepcopy(opts.diagnostics))
			local servers = opts.servers
			local cmp_nvim_lsp = require("cmp_nvim_lsp")
			local capabilities = vim.tbl_deep_extend(
				"force",
				{},
				vim.lsp.protocol.make_client_capabilities(),
				cmp_nvim_lsp.default_capabilities() or {},
				opts.capabilities or {}
			)
			local function setup(server)
				local server_opts = vim.tbl_deep_extend("force", {
					capabilities = vim.deepcopy(capabilities),
				}, servers[server] or {})
				if opts.setup[server] then
					if opts.setup[server](server, server_opts) then
						return
					end
				elseif opts.setup["*"] then
					if opts.setup["*"](server, server_opts) then
						return
					end
				end
				require("lspconfig")[server].setup(server_opts)
			end
			local mlsp = require("mason-lspconfig")
			local all_mslp_servers = vim.tbl_keys(require("mason-lspconfig.mappings.server").lspconfig_to_package)
			local ensure_installed = {}
			for server, server_opts in pairs(servers) do
				if server_opts then
					server_opts = server_opts == true and {} or server_opts
					if server_opts.mason == false or vim.tbl_contains(all_mslp_servers, server) then
						setup(server)
					else
						ensure_installed[#ensure_installed + 1] = server
					end
				end
			end
			if YukiVim.lsp.get_config("denols") and YukiVim.lsp.get_config("tsserver") then
				local is_deno = require("lspconfig.util").root_pattern("deno.json", "deno.jsonc")
				YukiVim.lsp.disable("tsserver", is_deno)
				YukiVim.lsp.disable("denols", function(root_dir)
					return not is_deno(root_dir)
				end)
			end

			mlsp.setup({ ensure_installed = ensure_installed, handlers = { setup } })
			-- local k = vim.keymap
			-- vim.api.nvim_create_autocmd("LspAttach", {
			-- 	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			-- 	callback = function(ev)
			-- 		-- Enable completion triggered by <c-x><c-o>
			-- 		vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
			-- 		local opt = { buffer = ev.buf }
			-- 		k.set("n", "gd", vim.lsp.buf.definition, opt)
			-- 		k.set("n", "gt", vim.lsp.buf.type_definition, opt)
			-- 		k.set("n", "gi", vim.lsp.buf.implementation, opt)
			-- 		k.set("n", "gr", vim.lsp.buf.references, opt)
			-- 		--show documents
			-- 		k.set("n", "sd", vim.lsp.buf.hover, opt)
			-- 		k.set("n", "rn", vim.lsp.buf.rename, opt)
			-- 		k.set("n", "<leader>ca", vim.lsp.buf.code_action, opt)
			-- 		k.set("x", "<leader>ca", vim.lsp.buf.code_action, opt)
			-- 		--quick fix
			-- 		--remap keys for applying refactor code actions.
			-- 		k.set("n", "<leader>re", function()
			-- 			vim.lsp.buf.code_action({ only = { "refactor" } })
			-- 		end, opt)
			-- 		k.set("x", "<leader>r", function()
			-- 			vim.lsp.buf.code_action({ only = { "refactor" } })
			-- 		end, opt)
			-- 		k.set("n", "<leader>r", function()
			-- 			vim.lsp.buf.code_action({ only = { "refactor" } })
			-- 		end, opt)
			-- 		--code len actions
			-- 		k.set("n", "<leader>cl", vim.lsp.codelens.run, opt)
			-- 		-- use ctrl-s for selection ranges
			-- 		k.set("n", "<leader>qf", function()
			-- 			vim.lsp.buf.code_action({
			-- 				only = { "quickfix" },
			-- 			})
			-- 		end, opt)
			-- 	end,
			-- })
		end,
		keys = {},
	},
}
