_G.YukiVim = require("util")
---@class YukiVimOptions

local defaults = {
	---@type string|fun()
	colorscheme = function()
		-- if not vim.g.vscode then
		require("catppuccin").load()
		-- end
	end,
	defaults = {
		autocmds = true,
		keymaps = true,
		options = true,
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
	},
}
---@type YukiVimOptions
local options

---@param opts? YukiVimOptions
function M.setup(opts)
	options = vim.tbl_deep_extend("force", defaults, opts or P({})) or {}

	local autocmds = vim.fn.argc(-1) == 0
	if not autocmds then
		M.load("autocmds")
	end
end

---@param name "autocmds" | "options" | "keymaps"
function M.load(name)
	local function _load(mod)
		if require("lazy.core.cache").find(mod)[1] then
			YukiVim.try(function()
				require(mod)
			end, { msg = "Failed loading " .. mod })
		end
	end

	if M.defaults[name] or name == "options" then
		_load("config." .. name)
	end
	if vim.bo.filetype == "lazy" then
		vim.cmd([[do VimResized]])
	end
	local pattern = "Yuki"
end
