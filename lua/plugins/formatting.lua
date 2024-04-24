local M = {}

---@param opts ConformOpts
function M.setup(_, opts)
	for name, formatter in pairs(opts.formatters or {}) do
		if type(formatter) == "table" then
			---@diagnostic disable-next-line: undefined-field
			if formatter.extra_args then
				---@diagnostic disable-next-line: undefined-field
				formatter.prepend_args = formatter.extra_args
				YukiVim.deprecate(
					("opts.formatters.%s.extra_args"):format(name),
					("opts.formatters.%s.prepend_args"):format(name)
				)
			end
		end
	end

	for _, key in ipairs({ "format_on_save", "format_after_save" }) do
		if opts[key] then
			YukiVim.warn(
				("Don't set `opts.%s` for `conform.nvim`.\n**YukiVim** will use the conform formatter automatically"):format(
					key
				)
			)
			---@diagnostic disable-next-line: no-unknown
			opts[key] = nil
		end
	end
	require("conform").setup(opts)
end
return {

	{
		"williamboman/mason.nvim",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			table.insert(opts.ensure_installed, "black")
		end,
	},

	{
		"nvimtools/none-ls.nvim",
		opts = function(_, opts)
			local nls = require("null-ls")
			opts.sources = opts.sources or {}
			table.insert(opts.sources, nls.builtins.formatting.black)
		end,
	},
	{
		"stevearc/conform.nvim",
		dependencies = { "mason.nvim" },
		lazy = true,
		cmd = "ConformInfo",
		keys = {
			{
				"<leader>cF",
				function()
					require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
				end,
				mode = { "n", "v" },
				desc = "Format Injected Langs",
			},
		},
		init = function()
			YukiVim.on_very_lazy(function()
				YukiVim.format.register({
					name = "conform.nvim",
					priority = 100,
					primary = true,
					format = function(buf)
						local plugin = require("lazy.core.config").plugins["conform.nvim"]
						local Plugin = require("lazy.core.plugin")
						local opts = Plugin.values(plugin, "opts", false)
						require("conform").format(YukiVim.merge({}, opts.format, { bufnr = buf }))
					end,
					sources = function(buf)
						local ret = require("conform").list_formatters(buf)
						---@param v conform.FormatterInfo
						return vim.tbl_map(function(v)
							return v.name
						end, ret)
					end,
				})
			end)
		end,
		opts = function()
			local plugin = require("lazy.core.config").plugins["conform.nvim"]
			if plugin.config ~= M.setup then
				YukiVim.error({
					"Don't set `plugin.config` for `conform.nvim`.\n",
				}, { title = "YukiVim" })
			end
			---@class ConformOpts
			local opts = {
				format = {
					timeout_ms = 3000,
					async = false,
					quiet = false,
					lsp_fallback = true,
				},
				---@type table<string, conform.FormatterUnit[]>
				formatters_by_ft = {
					lua = { "stylua" },
					fish = { "fish_indent" },
					sh = { "shfmt" },
					cs = { "csharpier" },
					python = { "black" },
				},
				---@type table<string, conform.FormatterConfigOverride|fun(bufnr: integer): nil|conform.FormatterConfigOverride>
				formatters = {
					csharpier = {
						command = "dotnet-csharpier",
						args = { "--write-stdout" },
					},
					injected = { options = { ignore_errors = true } },
				},
			}
			return opts
		end,
		config = M.setup,
	},
	{
		"williamboman/mason.nvim",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			table.insert(opts.ensure_installed, "prettier")
		end,
	},
	{
		"nvimtools/none-ls.nvim",
		optional = true,
		opts = function(_, opts)
			local nls = require("null-ls")
			opts.sources = opts.sources or {}
			table.insert(opts.sources, nls.builtins.formatting.prettier)
		end,
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				["javascript"] = { "prettier" },
				["javascriptreact"] = { "prettier" },
				["typescript"] = { "prettier" },
				["typescriptreact"] = { "prettier" },
				["vue"] = { "prettier" },
				["css"] = { "prettier" },
				["scss"] = { "prettier" },
				["less"] = { "prettier" },
				["html"] = { "prettier" },
				["json"] = { "prettier" },
				["jsonc"] = { "prettier" },
				["yaml"] = { "prettier" },
				["markdown"] = { "prettier" },
				["markdown.mdx"] = { "prettier" },
				["graphql"] = { "prettier" },
				["handlebars"] = { "prettier" },
			},
		},
	},
}
