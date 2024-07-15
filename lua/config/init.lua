_G.YukiVim = require("util")

---@class YukiVimConfig: YukiVimOptions
local M = {}
YukiVim.config = M
---@class YukiVimOptions
local defaults = {
	---@type string|fun()
	colorscheme = function()
		if not vim.g.vscode then
			require("catppuccin").load()
		end
	end,
	defaults = {
		autocmds = true,
		keymaps = true,
		-- options = true,
	},
	icons = {
		misc = {
			dots = "󰇘",
		},
		dap = {
			Stopped = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
			Breakpoint = " ",
			BreakpointCondition = " ",
			BreakpointRejected = { " ", "DiagnosticError" },
			LogPoint = ".>",
		},
		diagnostics = {
			Error = " ",
			Warn = " ",
			Hint = " ",
			Info = " ",
		},
		git = {
			added = " ",
			modified = " ",
			removed = " ",
		},
		kinds = {
			Array = " ",
			Boolean = "󰨙 ",
			Class = " ",
			Codeium = "󰘦 ",
			Color = " ",
			Control = " ",
			Collapsed = " ",
			Constant = "󰏿 ",
			Constructor = " ",
			Copilot = " ",
			Enum = " ",
			EnumMember = " ",
			Event = " ",
			Field = " ",
			File = " ",
			Folder = " ",
			Function = "󰊕 ",
			Interface = " ",
			Key = " ",
			Keyword = " ",
			Method = "󰊕 ",
			Module = " ",
			Namespace = "󰦮 ",
			Null = " ",
			Number = "󰎠 ",
			Object = " ",
			Operator = " ",
			Package = " ",
			Property = " ",
			Reference = " ",
			Snippet = " ",
			String = " ",
			Struct = "󰆼 ",
			TabNine = "󰏚 ",
			Text = " ",
			TypeParameter = " ",
			Unit = " ",
			Value = " ",
			Variable = "󰀫 ",
		},
	},
	---@type table<string, string[]|boolean>?
	kind_filter = {
		default = {
			"Class",
			"Constructor",
			"Enum",
			"Field",
			"Function",
			"Interface",
			"Method",
			"Module",
			"Namespace",
			"Package",
			"Property",
			"Struct",
			"Trait",
		},
		markdown = false,
		help = false,
		-- you can specify a different filter for each filetype
		lua = {
			"Class",
			"Constructor",
			"Enum",
			"Field",
			"Function",
			"Interface",
			"Method",
			"Module",
			"Namespace",
			-- "Package", -- remove package since luals uses it for control flow structures
			"Property",
			"Struct",
			"Trait",
		},
	},
}
---@type YukiVimOptions
local options

---@param opts? YukiVimOptions
function M.setup(opts)
	options = vim.tbl_deep_extend("force", defaults, opts or {}) or {}

	local autocmds = vim.fn.argc(-1) == 0
	if not autocmds then
		M.load("autocmds")
	end
	local group = vim.api.nvim_create_augroup("YukiVim", { clear = true })
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "VeryLazy",
		callback = function()
			if autocmds then
				M.load("autocmds")
			end
			M.load("keymaps")
			M.load("options")

			YukiVim.format.setup()
			YukiVim.root.setup()
		end,
	})
	YukiVim.try(function()
		if type(M.colorscheme) == "function" then
			M.colorscheme()
		else
			vim.cmd.colorscheme(M.colorscheme)
		end
	end, {
		msg = "Could not load your colorscheme",
		on_error = function(msg)
			YukiVim.error(msg)
		end,
	})
end

---@param buf? number
---@return string[]?
function M.get_kind_filter(buf)
	buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
	local ft = vim.bo[buf].filetype
	if M.kind_filter == false then
		return
	end
	if M.kind_filter[ft] == false then
		return
	end
	---@diagnostic disable-next-line: return-type-mismatch
	return type(M.kind_filter) == "table" and type(M.kind_filter.default) == "table" and M.kind_filter.default or nil
end

---@param name "autocmds" | "options" | "keymaps"
function M.load(name)
	local function _load(mod)
		if require("lazy.core.cache").find(mod)[1] then
			require(mod)
		end
	end
	_load("config." .. name)
	local pattern = "YukiVim" .. name:sub(1, 1):upper() .. name:sub(2)
	vim.api.nvim_exec_autocmds("User", { pattern = pattern, modeline = false })
end
M.initialized = false
function M.init()
	if M.initialized then
		return
	end
	M.initialized = true
	M.load("options")
end

setmetatable(M, {
	__index = function(_, key)
		if options == nil then
			return vim.deepcopy(defaults)[key]
		end
		---@cast options YukiVimConfig
		return options[key]
	end,
})

return M
