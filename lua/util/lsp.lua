---@class YukiUtil.lsp
local M = {}

---@alias lsp.Client.filter {id?:number, bufnr?:number, name?:string, method?:string, filter?:fun(client: lsp.Client):boolean}

---@param opts? lsp.Client.filter
function M.get_clients(opts)
	local ret = {} ---@type vim.lsp.Client[]
	if vim.lsp.get_clients then
		ret = vim.lsp.get_clients(opts)
	else
		---@diagnostic disable-next-line: deprecated
		ret = vim.lsp.get_active_clients(opts)
		if opts and opts.method then
			---@param client vim.lsp.Client
			ret = vim.tbl_filter(function(client)
				return client.supports_method(opts.method, { bufnr = opts.bufnr })
			end, ret)
		end
	end
	return opts and opts.filter and vim.tbl_filter(opts.filter, ret) or ret
end

---@param on_attach fun(client:vim.lsp.Client, buffer)
---@param name? string
function M.on_attach(on_attach, name)
	return vim.api.nvim_create_autocmd("LspAttach", {
		callback = function(args)
			local buffer = args.buf ---@type number
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			if client and (not name or client.name == name) then
				return on_attach(client, buffer)
			end
		end,
	})
end

---@type table<string, table<vim.lsp.Client, table<number, boolean>>>
M._supports_method = {}

function M.setup()
	local register_capability = vim.lsp.handlers["client/registerCapability"]
	vim.lsp.handlers["client/registerCapability"] = function(err, res, ctx)
		---@diagnostic disable-next-line: no-unknown
		local ret = register_capability(err, res, ctx)
		local client = vim.lsp.get_client_by_id(ctx.client_id)
		if client then
			for buffer in pairs(client.attached_buffers) do
				vim.api.nvim_exec_autocmds("User", {
					pattern = "LspDynamicCapability",
					data = { client_id = client.id, buffer = buffer },
				})
			end
		end
		return ret
	end
	M.on_attach(M._check_methods)
	M.on_dynamic_capability(M._check_methods)
end

---@param client vim.lsp.Client
function M._check_methods(client, buffer)
	if not vim.api.nvim_buf_is_valid(buffer) then
		return
	end

	if not vim.bo[buffer].buflisted then
		return
	end

	if vim.bo[buffer].buftype == "nofile" then
		return
	end

	for method, clients in pairs(M._supports_method) do
		clients[client] = clients[client] or {}
		if not clients[client][buffer] then
			if client.supports_method and client.supports_method(method, { bufnr = buffer }) then
				clients[client][buffer] = true
				vim.api.nvim_exec_autocmds("User", {
					pattern = "LspSupportsMethod",
					data = { client_id = client.id, buffer = buffer, method = method },
				})
			end
		end
	end
end

---@param fn fun(client: vim.lsp.Client, buffer):boolean?
---@param opts? {group?: integer}
function M.on_dynamic_capability(fn, opts)
	return vim.api.nvim_create_autocmd("User", {
		pattern = "LspDynamicCapability",
		group = opts and opts.group or nil,
		callback = function(args)
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			local buffer = args.data.buffer ---@type number
			if client then
				return fn(client, buffer)
			end
		end,
	})
end

---@param method string
---@param fn fun(client: vim.lsp.Client, buffer)
function M.on_supports_method(method, fn)
	M._supports_method[method] = M._supports_method[method] or setmetatable({}, { __mode = "k" })
	return vim.api.nvim_create_autocmd("User", {
		pattern = "LspSupportsMethod",
		callback = function(args)
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			local buffer = args.data.buffer ---@type number
			if client and method == args.data.method then
				return fn(client, buffer)
			end
		end,
	})
end

function M.rename_file()
	local buf = vim.api.nvim_get_current_buf()
	local old = assert(YukiVim.root.realpath(vim.api.nvim_buf_get_name(buf)))
	local root = assert(YukiVim.root.realpath(YukiVim.root.get({ normalize = true })))
	assert(old:find(root, 1, true) == 1, "File not in project root")

	local extra = old:sub(#root + 2)

	vim.ui.input({
		prompt = "New File Name: ",
		default = extra,
		completion = "file",
	}, function(new)
		if not new or new == "" or new == extra then
			return
		end
		new = YukiVim.norm(root .. "/" .. new)
		vim.fn.mkdir(vim.fs.dirname(new), "p")
		M.on_rename(old, new, function()
			vim.fn.rename(old, new)
			vim.cmd.edit(new)
			vim.api.nvim_buf_delete(buf, { force = true })
			vim.fn.delete(old)
		end)
	end)
end

---@param from string
---@param to string
---@param rename? fun()
function M.on_rename(from, to, rename)
	local changes = { files = { {
		oldUri = vim.uri_from_fname(from),
		newUri = vim.uri_from_fname(to),
	} } }
	local clients = M.get_clients()
	for _, client in ipairs(clients) do
		if client.supports_method("workspace/willRenameFiles") then
			local resp = client.request_sync("workspace/willRenameFiles", changes, 1000, 0)
			if resp and resp.result ~= nil then
				vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
			end
		end
	end

	if rename then
		rename()
	end

	for _, client in ipairs(clients) do
		if client.supports_method("workspace/didRenameFiles") then
			client.notify("workspace/didRenameFiles", changes)
		end
	end
end

---@return _.lspconfig.options
function M.get_config(server)
	local configs = require("lspconfig.configs")
	return rawget(configs, server)
end

function M.is_enabled(server)
	local c = M.get_config(server)
	return c and c.enabled ~= false
end

---@param server string
---@param cond fun(root_dir, config): boolean
function M.disable(server, cond)
	local util = require("lspconfig.util")
	local def = M.get_config(server)
	---@diagnostic disable-next-line: undefined-field
	def.document_config.on_new_config = util.add_hook_before(
		def.document_config.on_new_config,
		function(config, root_dir)
			if cond(root_dir, config) then
				config.enabled = false
			end
		end
	)
end

---@param opts? YukiFormatter| {filter?: (string|lsp.Client.filter)}
function M.formatter(opts)
	opts = opts or {}
	local filter = opts.filter or {}
	filter = type(filter) == "string" and { name = filter } or filter
	---@cast filter lsp.Client.filter
	---@type YukiFormatter
	local ret = {
		name = "LSP",
		primary = true,
		priority = 1,
		format = function(buf)
			M.format(YukiVim.merge({}, filter, { bufnr = buf }))
		end,
		sources = function(buf)
			local clients = M.get_clients(YukiVim.merge({}, filter, { bufnr = buf }))
			---@param client vim.lsp.Client
			local ret = vim.tbl_filter(function(client)
				return client.supports_method("textDocument/formatting")
					or client.supports_method("textDocument/rangeFormatting")
			end, clients)
			---@param client vim.lsp.Client
			return vim.tbl_map(function(client)
				return client.name
			end, ret)
		end,
	}
	return YukiVim.merge(ret, opts) --[[@as YukiFormatter]]
end

---@alias lsp.Client.format {timeout_ms?: number, format_options?: table} | lsp.Client.filter

---@param opts? lsp.Client.format
function M.format(opts)
	opts = vim.tbl_deep_extend(
		"force",
		{},
		opts or {},
		YukiVim.opts("nvim-lspconfig").format or {},
		YukiVim.opts("conform.nvim").format or {}
	)
	local ok, conform = pcall(require, "conform")
	if ok then
		opts.formatter = {}
		conform.format(opts)
	else
		vim.lsp.buf.format(opts)
	end
end

---@alias LspWord {from:{[1]:number, [2]:number}, to:{[1]:number, [2]:number}} 1-0 indexed
M.words = {}
M.words.enabled = false
M.words.ns = vim.api.nvim_create_namespace("vim_lsp_references")

---@param opts? {enabled?: boolean}
function M.words.setup(opts)
	opts = opts or {}
	if not opts.enabled then
		return
	end
	M.words.enabled = true
	local handler = vim.lsp.handlers["textDocument/documentHighlight"]
	vim.lsp.handlers["textDocument/documentHighlight"] = function(err, result, ctx, config)
		if not vim.api.nvim_buf_is_loaded(ctx.bufnr) then
			return
		end
		vim.lsp.buf.clear_references()
		return handler(err, result, ctx, config)
	end

	M.on_supports_method("textDocument/documentHighlight", function(_, buf)
		vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI", "CursorMoved", "CursorMovedI" }, {
			group = vim.api.nvim_create_augroup("lsp_word_" .. buf, { clear = true }),
			buffer = buf,
			callback = function(ev)
				if not M.keymap.has(buf, "documentHighlight") then
					return false
				end
				if not ({ M.words.get() })[2] then
					if ev.event:find("CursorMoved") then
						vim.lsp.buf.clear_references()
					else
						vim.lsp.buf.document_highlight()
					end
				end
			end,
		})
	end)
end

---@return LspWord[] words, number? current
function M.words.get()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local current, ret = nil, {} ---@type number?, LspWord[]
	for _, extmark in ipairs(vim.api.nvim_buf_get_extmarks(0, M.words.ns, 0, -1, { details = true })) do
		local w = {
			from = { extmark[2] + 1, extmark[3] },
			to = { extmark[4].end_row + 1, extmark[4].end_col },
		}
		ret[#ret + 1] = w
		if cursor[1] >= w.from[1] and cursor[1] <= w.to[1] and cursor[2] >= w.from[2] and cursor[2] <= w.to[2] then
			current = #ret
		end
	end
	return ret, current
end

---@param count number
---@param cycle? boolean
function M.words.jump(count, cycle)
	local words, idx = M.words.get()
	if not idx then
		return
	end
	idx = idx + count
	if cycle then
		idx = (idx - 1) % #words + 1
	end
	local target = words[idx]
	if target then
		vim.api.nvim_win_set_cursor(0, target.from)
	end
end

M.action = setmetatable({}, {
	__index = function(_, action)
		return function()
			vim.lsp.buf.code_action({
				apply = true,
				context = {
					only = { action },
					diagnostics = {},
				},
			})
		end
	end,
})

---@class LspCommand: lsp.ExecuteCommandParams
---@field open? boolean
---@field handler? lsp.Handler

---@param opts LspCommand
function M.execute(opts)
	local params = {
		command = opts.command,
		arguments = opts.arguments,
	}
	if opts.open then
		require("trouble").open({
			mode = "lsp_command",
			params = params,
		})
	else
		return vim.lsp.buf_request(0, "workspace/executeCommand", params, opts.handler)
	end
end

-- ---@return (LazyKeys|{has?:string})[]
-- function M.lspKeyResolve(buffer, spec)
-- 	local Keys = require("lazy.core.handler.keys")
-- 	if not Keys.resolve then
-- 		return {}
-- 	end
-- 	local opts = YukiVim.opts("nvim-lspconfig")
-- 	local clients = YukiVim.lsp.get_clients({ bufnr = buffer })
-- 	for _, client in ipairs(clients) do
-- 		local maps = opts.servers[client.name] and opts.servers[client.name].keys or {}
-- 		vim.list_extend(spec, maps)
-- 	end
-- 	return Keys.resolve(spec)
-- end

---@type LazyKeysLspSpec[]|nil
M._keys = nil
M.keymap = {}
---@alias LazyKeysLspSpec LazyKeysSpec|{has?:string|string[], cond?:fun():boolean}
---@alias LazyKeysLsp LazyKeys|{has?:string|string[], cond?:fun():boolean}

---@return LazyKeysLspSpec[]
function M.keymap.get()
	if M._keys then
		return M._keys
	end
    -- stylua: ignore
    M._keys =  {
      { "<leader>cl", "<cmd>LspInfo<cr>", desc = "Lsp Info" },
      { "gd", function() require("telescope.builtin").lsp_definitions({reuse_win = true}) end, desc = "Goto Definition", has = "definition" },
      { "gr", function() require("telescope.builtin").lsp_references() end, desc = "References", nowait = true },
      { "gI", function() require("telescope.builtin").lsp_implementations({reuse_win = true}) end, desc = "Goto Implementation" },
      { "gy", function()  require("telescope.builtin").lsp_type_definitions({reuse_win = true}) end, desc = "Goto T[y]pe Definition" },
      { "gD", vim.lsp.buf.declaration, desc = "Goto Declaration" },
      { "K", vim.lsp.buf.hover, desc = "Hover" },
      { "gK", vim.lsp.buf.signature_help, desc = "Signature Help", has = "signatureHelp" },
      { "<c-k>", vim.lsp.buf.signature_help, mode = "i", desc = "Signature Help", has = "signatureHelp" },
      { "<leader>ca", vim.lsp.buf.code_action, desc = "Code Action", mode = { "n", "v" }, has = "codeAction" },
      { "<leader>cc", vim.lsp.codelens.run, desc = "Run Codelens", mode = { "n", "v" }, has = "codeLens" },
      { "<leader>cC", vim.lsp.codelens.refresh, desc = "Refresh & Display Codelens", mode = { "n" }, has = "codeLens" },
      { "<leader>cR", YukiVim.lsp.rename_file, desc = "Rename File", mode ={"n"}, has = { "workspace/didRenameFiles", "workspace/willRenameFiles" } },
      { "<leader>cr", function() 
            local inc_rename = require("inc_rename")
            return ":" .. inc_rename.config.cmd_name .. " " .. vim.fn.expand("<cword>")
        end, expr = true, desc = "Rename (inc-rename.nvim)", has = "rename" },
      { "<leader>cA", YukiVim.lsp.action.source, desc = "Source Action", has = "codeAction" },
      { "]]", function() YukiVim.lsp.words.jump(vim.v.count1) end, has = "documentHighlight",
        desc = "Next Reference", cond = function() return YukiVim.lsp.words.enabled end },
      { "[[", function() YukiVim.lsp.words.jump(-vim.v.count1) end, has = "documentHighlight",
        desc = "Prev Reference", cond = function() return YukiVim.lsp.words.enabled end },
      { "<a-n>", function() YukiVim.lsp.words.jump(vim.v.count1, true) end, has = "documentHighlight",
        desc = "Next Reference", cond = function() return YukiVim.lsp.words.enabled end },
      { "<a-p>", function() YukiVim.lsp.words.jump(-vim.v.count1, true) end, has = "documentHighlight",
        desc = "Prev Reference", cond = function() return YukiVim.lsp.words.enabled end },
    }

	return M._keys
end

---@param method string|string[]
function M.keymap.has(buffer, method)
	if type(method) == "table" then
		for _, m in ipairs(method) do
			if M.keymap.has(buffer, m) then
				return true
			end
		end
		return false
	end
	method = method:find("/") and method or "textDocument/" .. method
	local clients = YukiVim.lsp.get_clients({ bufnr = buffer })
	for _, client in ipairs(clients) do
		if client.supports_method(method) then
			return true
		end
	end
	return false
end

---@return LazyKeysLsp[]
function M.keymap.resolve(buffer)
	local Keys = require("lazy.core.handler.keys")
	if not Keys.resolve then
		return {}
	end
	local spec = M.keymap.get()
	local opts = YukiVim.opts("nvim-lspconfig")
	local clients = YukiVim.lsp.get_clients({ bufnr = buffer })
	for _, client in ipairs(clients) do
		local maps = opts.servers[client.name] and opts.servers[client.name].keys or {}
		vim.list_extend(spec, maps)
	end
	return Keys.resolve(spec)
end

function M.keymap.on_attach(_, buffer)
	local Keys = require("lazy.core.handler.keys")
	local keymaps = M.keymap.resolve(buffer)

	for _, keys in pairs(keymaps) do
		local has = not keys.has or M.keymap.has(buffer, keys.has)
		local cond = not (keys.cond == false or ((type(keys.cond) == "function") and not keys.cond()))

		if has and cond then
			local opts = Keys.opts(keys)
			opts.cond = nil
			opts.has = nil
			opts.silent = opts.silent ~= false
			opts.buffer = buffer
			vim.keymap.set(keys.mode or "n", keys.lhs, keys.rhs, opts)
		end
	end
end

return M
