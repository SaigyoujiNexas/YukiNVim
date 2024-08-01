local M = {}

---@param opts conform.setupOpts
function M.setup(_, opts)
	require("conform").setup(opts)
end

local supported = {
	"css",
	"graphql",
	"handlebars",
	"html",
	"javascript",
	"javascriptreact",
	"json",
	"jsonc",
	"less",
	"markdown",
	"markdown.mdx",
	"scss",
	"typescript",
	"typescriptreact",
	"vue",
	"yaml",
}

---@alias ConformCtx {buf: number, filename: string, dirname: string}

---@param ctx ConformCtx
function M.has_prettier_config(ctx)
	vim.fn.system({ "prettier", "--find-config-path", ctx.filename })
	return vim.v.shell_error == 0
end

--- Checks if a parser can be inferred for the given context:
--- * If the filetype is in the supported list, return true
--- * Otherwise, check if a parser can be inferred
---@param ctx ConformCtx
function M.has_prettier_parser(ctx)
	local ft = vim.bo[ctx.buf].filetype --[[@as string]]
	-- default filetypes are always supported
	if vim.tbl_contains(supported, ft) then
		return true
	end
	-- otherwise, check if a parser can be inferred
	local ret = vim.fn.system({ "prettier", "--file-info", ctx.filename })
	---@type boolean, string?
	local ok, parser = pcall(function()
		return vim.fn.json_decode(ret).inferredParser
	end)
	return ok and parser and parser ~= vim.NIL
end

M.has_prettier_config = YukiVim.memorize(M.has_prettier_config)
M.has_prettier_parser = YukiVim.memorize(M.has_prettier_parser)

return {

	{
		"williamboman/mason.nvim",
		opts = function(_, opts)
			opts.ensure_installed = YukiVim.list_insert_unique(opts.ensure_installed, { "black", "prettier" })
		end,
	},

	{
		"nvimtools/none-ls.nvim",
		opts = function(_, opts)
			local nls = require("null-ls")
			opts.sources = YukiVim.list_insert_unique(
				opts.sources,
				{ nls.builtins.formatting.black, nls.builtins.formatting.prettier }
			)
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
						require("conform").format({ bufnr = buf })
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
			---@type conform.setupOpts
			local opts = {
				format = {
					timeout_ms = 3000,
					async = false,
					quiet = false,
					lsp_format = "fallback",
				},
				formatters_by_ft = {
					lua = { "stylua" },
					fish = { "fish_indent" },
					sh = { "shfmt" },
					cs = { "csharpier" },
					["python"] = { "black" },
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
				---@type table<string, conform.FormatterConfigOverride|fun(bufnr: integer): nil|conform.FormatterConfigOverride>
				formatters = {
					injected = { options = { ignore_errors = true } },
					prettier = {
						condition = function(_, ctx)
							return M.has_prettier_parser(ctx) and M.has_prettier_config(ctx)
						end,
					},
				},
			}
			return opts
		end,
		config = M.setup,
	},
}
