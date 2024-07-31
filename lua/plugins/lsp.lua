return {
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		opts_extend = { "ensure_installed" },
		opts = {
			ensure_installed = {
				"stylua",
				"shfmt",
			},
		},
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
			mr.refresh(function()
				for _, tool in ipairs(opts.ensure_installed) do
					local p = mr.get_package(tool)
					if not p:is_installed() then
						p:install()
					end
				end
			end)
		end,
	},
	-- {
	-- 	"williamboman/mason-lspconfig.nvim",
	-- },
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
				opts = {},
			},
			"mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		---@class PluginLspOpts
		opts = function()
			return {
				---@type vim.diagnostic.Opts
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
							[vim.diagnostic.severity.ERROR] = YukiVim.config.icons.diagnostics.Error,
							[vim.diagnostic.severity.WARN] = YukiVim.config.icons.diagnostics.Warn,
							[vim.diagnostic.severity.HINT] = YukiVim.config.icons.diagnostics.Hint,
							[vim.diagnostic.severity.INFO] = YukiVim.config.icons.diagnostics.Info,
						},
					},
				},
				inlay_hints = {
					enabled = false,
					exclude = { "vue" },
				},
				codelens = {
					enabled = false,
				},
				document_highlight = {
					enabled = false,
				},
				capabilities = {
					workspace = {
						fileOperations = {
							didRename = true,
							willRename = true,
						},
					},
				},
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
								doc = {
									privateName = { "^_" },
								},
								hint = {
									enable = true,
									setType = false,
									paramType = true,
									semicolon = "Disable",
									paramName = "Disable",
									arrayIndex = "Disable",
								},
							},
						},
					},
				},
				---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
				setup = {},
			}
		end,
		---@param opts PluginLspOpts
		config = function(_, opts)
			-- setup autoformat
			YukiVim.format.register(YukiVim.lsp.formatter())
			if YukiVim.is_mac() then
				require("lspconfig").sourcekit.setup({
					cmd = {
						"/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
					},
				})
			end

			YukiVim.lsp.on_attach(function(client, buffer)
				YukiVim.lsp.keymap.on_attach(client, buffer)
			end)
			YukiVim.lsp.setup()
			YukiVim.lsp.on_dynamic_capability(YukiVim.lsp.keymap.on_attach)
			YukiVim.lsp.words.setup(opts.document_highlight)

			if vim.fn.has("nvim-0.10.0") == 0 then
				if type(opts.diagnostics.signs) ~= "boolean" then
					for severity, icon in pairs(opts.diagnostics.signs.text) do
						local name = vim.diagnostic.severity[severity]:lower():gsub("^%l", string.upper)
						name = "DiagnosticSign" .. name
						vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
					end
				end
			end

			if vim.fn.has("nvim-0.10.0") == 1 then
				if opts.inlay_hints.enabled then
					YukiVim.lsp.on_supports_method("textDocument/inlayHint", function(client, buffer)
						if
							vim.api.nvim_buf_is_valid(buffer)
							and vim.bo[buffer].buftype == ""
							and not vim.tbl_contains(opts.inlay_hints.exclude, vim.bo[buffer].filetype)
						then
							YukiVim.toggle.inlay_hints(buffer, true)
						end
					end)
				end
			end

			if opts.codelens.enabled and vim.lsp.codelens then
				YukiVim.lsp.on_supports_method("textDocument/codeLens", function(client, buffer)
					vim.lsp.codelens.refresh()
					vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
						buffer = buffer,
						callback = vim.lsp.codelens.refresh,
					})
				end)
			end

			if type(opts.diagnostics.virtual_text) == "table" and opts.diagnostics.virtual_text.prefix == "icons" then
				opts.diagnostics.virtual_text.prefix = vim.fn.has("nvim-0.10.0") == 0 and "●"
					or function(diagnostic)
						local icons = YukiVim.config.icons.diagnostics
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
			local ensure_installed = {} ---@type string[]
			for server, server_opts in pairs(servers) do
				if server_opts then
					server_opts = server_opts == true and {} or server_opts
					if server_opts.enabled ~= false then
						if server_opts.mason == false or not vim.tbl_contains(all_mslp_servers, server) then
							setup(server)
						else
							ensure_installed[#ensure_installed + 1] = server
						end
					end
				end
			end
			mlsp.setup({
				ensure_installed = vim.tbl_deep_extend(
					"force",
					ensure_installed,
					YukiVim.opts("mason-lspconfig.nvim").ensure_installed or {}
				),
				handlers = { setup },
			})
			if YukiVim.lsp.get_config("denols") and YukiVim.lsp.is_enabled("vtsls") then
				local is_deno = require("lspconfig.util").root_pattern("deno.json", "deno.jsonc")
				YukiVim.lsp.disable("vtsls", is_deno)
				YukiVim.lsp.disable("denols", function(root_dir, config)
					if not is_deno(root_dir) then
						config.setttings.deno.enabled = false
					end
					return false
				end)
			end
		end,
	},
}
