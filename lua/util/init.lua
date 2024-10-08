local LazyUtil = require("lazy.core.util")

---@class YukiUtil: LazyUtilCore
---@field config YukiVimConfig
---@field format YukiUtil.format
---@field lsp YukiUtil.lsp
---@field root YukiUtil.root
---@field toggle YukiUtil.toggle
---@field ui YukiUtil.ui
---@field lualine YukiUtil.lualine
---@field cmp YukiUtil.cmp
local M = {}

setmetatable(M, {
	__index = function(t, k)
		if LazyUtil[k] then
			return LazyUtil[k]
		end
		---@diagnostic disable-next-line: no-unknown
		t[k] = require("util." .. k)
		return t[k]
	end,
})

function M.is_win()
	return vim.uv.os_uname().sysname:find("Windows") ~= nil
end

function M.is_mac()
	return vim.uv.os_uname().sysname:find("Darwin") ~= nil
end

---@param plugin string
function M.has(plugin)
	return require("lazy.core.config").spec.plugins[plugin] ~= nil
end

---@param fn fun()
function M.on_very_lazy(fn)
	vim.api.nvim_create_autocmd("User", {
		pattern = "VeryLazy",
		callback = function()
			fn()
		end,
	})
end

---@param name string
function M.opts(name)
	local plugin = require("lazy.core.config").plugins[name]
	if not plugin then
		return {}
	end
	local Plugin = require("lazy.core.plugin")
	return Plugin.values(plugin, "opts", false)
end

function M.deprecate(old, new)
	M.warn(("`%s` is deprecated. Please use `%s` instead"):format(old, new), {
		title = "YukiVim",
		once = true,
		stacktrace = true,
		stacklevel = 6,
	})
end

--- Insert one or more values into a list like table and maintain that you do not insert non-unique values (THIS MODIFIES `lst`)
---@param lst any[]|nil The list like table that you want to insert into
---@param vals any|any[] Either a list like table of values to be inserted or a single value to be inserted
---@return any[] # The modified list like table
function M.list_insert_unique(lst, vals)
	if not lst then
		lst = {}
	end
	assert(vim.tbl_islist(lst), "Provided table is not a list like table")
	if not vim.tbl_islist(vals) then
		vals = { vals }
	end
	local added = {}
	vim.tbl_map(function(v)
		added[v] = true
	end, lst)
	for _, val in ipairs(vals) do
		if not added[val] then
			table.insert(lst, val)
			added[val] = true
		end
	end
	return lst
end

function M.is_loaded(name)
	local Config = require("lazy.core.config")
	return Config.plugins[name] and Config.plugins[name]._.loaded
end

---@param name string
---@param fn fun(name:string)
function M.on_load(name, fn)
	if M.is_loaded(name) then
		fn(name)
	else
		vim.api.nvim_create_autocmd("User", {
			pattern = "LazyLoad",
			callback = function(event)
				if event.data == name then
					fn(name)
					return true
				end
			end,
		})
	end
end

-- Wrapper around vim.keymap.set that will
-- not create a keymap if a lazy key handler exists.
-- It will also set `silent` to true by default.
function M.safe_keymap_set(mode, lhs, rhs, opts)
	local keys = require("lazy.core.handler").handlers.keys
	---@cast keys LazyKeysHandler
	local modes = type(mode) == "string" and { mode } or mode

	---@param m string
	modes = vim.tbl_filter(function(m)
		return not (keys.have and keys:have(lhs, m))
	end, modes)

	-- do not create the keymap if a lazy keys handler exists
	if #modes > 0 then
		opts = opts or {}
		opts.silent = opts.silent ~= false
		if opts.remap and not vim.g.vscode then
			---@diagnostic disable-next-line: no-unknown
			opts.remap = nil
		end
		vim.keymap.set(modes, lhs, rhs, opts)
	end
end

---@generic T
---@param list T[]
---@return T[]
function M.dedup(list)
	local ret = {}
	local seen = {}
	for _, v in ipairs(list) do
		if not seen[v] then
			table.insert(ret, v)
			seen[v] = true
		end
	end
	return ret
end

local cache = {} ---@type table<(fun()), table<string, any>>
---@generic T: fun()
---@param fn T
---@return T
function M.memorize(fn)
	return function(...)
		local key = vim.inspect({ ... })
		cache[fn] = cache[fn] or {}
		if cache[fn][key] == nil then
			cache[fn][key] = fn(...)
		end
		return cache[fn][key]
	end
end
return M
