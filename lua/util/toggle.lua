---@class YukiUtil.toggle
local M = {}

---@class yukivim.Toggle
---@field name string
---@field get fun():boolean
---@field set fun(state:boolean)

---@class yukivim.Toggle.wrap: yukivim.Toggle
---@operator call:boolean

---@param toggle yukivim.Toggle
function M.wrap(toggle)
	return setmetatable(toggle, {
		__call = function()
			toggle.set(not toggle.get())
			local state = toggle.get()
			if state then
				YukiVim.info("Enabled " .. toggle.name, { title = toggle.name })
			else
				YukiVim.warn("Disabled " .. toggle.name, { title = toggle.name })
			end
			return state
		end,
	}) --[[@as yukivim.Toggle.wrap]]
end

---@param opts? {values?: {[1]:any, [2]:any}, name?:string}
function M.option(option, opts)
	opts = opts or {}
	local name = opts.name or option
	local on = opts.values and opts.values[2] or true
	local off = opts.values and opts.values[1] or false
	return M.wrap({
		name = name,
		get = function()
			return vim.opt_local[option]:get() == on
		end,
		set = function(state)
			vim.opt_local[option] = state and on or off
		end,
	})
end

local nu = { number = true, relativenumber = true }

M.number = M.wrap({
	name = "Line Numbers",
	get = function()
		return vim.opt_local.number:get() or vim.opt_local.relativenumber:get()
	end,
	set = function(state)
		if state then
			vim.opt_local.number = nu.number
			vim.opt_local.relativenumber = nu.relativenumber
		else
			nu = { number = vim.opt_local.number:get(), relativenumber = vim.opt_local.relativenumber:get() }
			vim.opt_local.number = false
			vim.opt_local.relativenumber = false
		end
	end,
})
M.diagnostics = M.wrap({
	name = "Diagnostics",
	get = function()
		return vim.diagnostic.is_enabled and vim.diagnostic.is_enabled()
	end,
	set = vim.diagnostic.enable,
})

M.inlay_hints = M.wrap({
	name = "Inlay Hints",
	get = function()
		return vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
	end,
	set = function(state)
		vim.lsp.inlay_hint.enable(state, { bufnr = 0 })
	end,
})

setmetatable(M, {
	__call = function(m, ...)
		return m.option(...)
	end,
})

return M
