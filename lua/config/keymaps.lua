local map = YukiVim.safe_keymap_set

map({ "n", "v", "i", "t" }, "：", ":")
map({ "n", "v", "i", "t" }, "；", ";")
map({ "n", "v", "i", "t" }, "‘", "'")
map({ "n", "v", "i", "t" }, "“", '"')
map({ "n", "v", "i", "t" }, "？", "?")
map({ "n", "v", "i", "t" }, "，", ",")
map({ "n", "v", "i", "t" }, "。", ".")
map({ "n", "v", "i", "t" }, "（", "(")
map({ "n", "v", "i", "t" }, "）", ")")
map({ "n", "v", "i", "t" }, "【", "[")
map({ "n", "v", "i", "t" }, "】", "]")
map({ "n", "v", "i", "t" }, "｜", "|")

map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

map({ "n", "v" }, "<leader>cf", function()
	YukiVim.format({ force = true })
end, { desc = "Format" })

local diagnostic_goto = function(next, severity)
	local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
	severity = severity and vim.diagnostic.severity[severity] or nil
	return function()
		go({ severity = severity })
	end
end

map("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Enter Normal Mode" })

map("n", "[q", vim.cmd.cprev, { desc = "Previous quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next quickfix" })

-- diagnostic
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

-- floating terminal
local yukiterm = function()
	require("util").terminal(nil, { cmd = YukiVim.root() })
end
map("n", "<leader>ft", yukiterm, { desc = "Terminal (root dir)" })
map("n", "<leader>fT", function()
	YukiVim.terminal()
end, { desc = "Terminal (cwd)" })
map("n", "<c-/>", yukiterm, { desc = "Terminal (root dir)" })
map("n", "<c-_>", yukiterm, { desc = "which_key_ignore" })

-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window", remap = true })
map("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "Go to left window" })
map("t", "<C-j>", "<cmd>wincmd j<cr>", { desc = "Go to lower window" })
map("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "Go to upper window" })
map("t", "<C-l>", "<cmd>wincmd l<cr>", { desc = "Go to right window" })

map("n", "<leader>-", "<C-W>s", { desc = "Split window below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split window right", remap = true })

------------------ LSP Keymap start --------------

---@type LazyKeysSpec[]|nil
local lsp_keys = {
	{
		"gdf",
		function()
			require("telescope.builtin").lsp_definitions({ reuse_win = true })
		end,
		desc = "Goto Definition",
		has = "definition",
	},
	{ "gr", "<cmd>Telescope lsp_references<cr>", desc = "Goto References" },
	{ "gdc", vim.lsp.buf.declaration, desc = "Goto Declaration" },
	{
		"gi",
		function()
			require("telescope.builtin").lsp_implementations({ reuse_win = true })
		end,
		desc = "Goto Implementation",
	},
	{
		"gt",
		function()
			require("telescope.builtin").lsp_type_definitions({ reuse_win = true })
		end,
		desc = "Goto Type Definition",
	},
	{ "K", vim.lsp.buf.hover, desc = "Hover" },
	{ "gK", vim.lsp.buf.signature_help, desc = "Signature Help", has = "signatureHelp" },
	{ "<c-k>", vim.lsp.buf.signature_help, mode = "i", desc = "Signature Help", has = "signatureHelp" },
	{ "<leader>ca", vim.lsp.buf.code_action, desc = "Code Action", mode = { "n", "v" }, has = "codeAction" },
	{ "<leader>cl", vim.lsp.codelens.run, desc = "Run Codelens", mode = { "n", "v" }, has = "codeLens" },
	{ "<leader>cc", vim.lsp.codelens.refresh, desc = "Refresh Codelens", mode = { "n", "v" }, has = "codeLens" },
	{
		"<leader>csa",
		function()
			vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } })
		end,
		desc = "Code Source Action",
		has = "codeAction",
	},
}

if YukiVim.has("inc-rename.nvim") then
	lsp_keys[#lsp_keys + 1] = {
		"<leader>cr",
		function()
			local inc_rename = require("inc_rename")
			return ":" .. inc_rename.config.cmd_name .. " " .. vim.fn.expand("<cword>")
		end,
		expr = true,
		desc = "Code Rename",
		has = "rename",
	}
else
	lsp_keys[#lsp_keys + 1] = { "<leader>cr", vim.lsp.buf.rename, desc = "Code Rename", has = "rename" }
end

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		local buffer = ev.buf

		---@param method string
		local has_usable = function(buf, method)
			method = method:find("/") and method or "textDocument/" .. method
			local clients = YukiVim.lsp.get_clients({ bufnr = buf })
			for _, client in ipairs(clients) do
				if client.supports_method(method) then
					return true
				end
			end
			return false
		end

		vim.bo[buffer].omnifunc = "v:lua.vim.lsp.omnifunc"
		local Keys = require("lazy.core.handler.keys")
		local keymaps = YukiVim.lsp.lspKeyResolve(buffer, lsp_keys)

		for _, keys in pairs(keymaps) do
			if not keys.has or has_usable(buffer, keys.has) then
				local opts = Keys.opts(keys)
				opts.has = nil
				opts.silent = opts.silent ~= false
				opts.buffer = buffer
				vim.keymap.set(keys.mode or "n", keys.lhs, keys.rhs, opts)
			end

			vim.keymap.set("n", "<leader>re", function()
				vim.lsp.buf.code_action({ only = { "refactor" } })
			end)
			vim.keymap.set("n", "<leader>qf", function()
				vim.lsp.buf.code_action({
					only = { "quickfix" },
				})
			end)
		end
	end,
})
