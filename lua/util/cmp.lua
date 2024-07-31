---@class YukiUtil.cmp
local M = {}

---@alias PlaceHolder {n: number, text: string}

---@param snippet string
---@param fn fun(placeholder: PlaceHolder):string
---@return string
function M.snippet_replace(snippet, fn)
	return snippet:gsub("%$%b{}", function(m)
		local n, name = m:match("^%${(%d+):(.+)$}")
		return n and fn({ n = n, text = name }) or m
	end) or snippet
end

-- This function resolves nested placeholder in a snippets
---@param snippet string
---@return string
function M.snippet_preview(snippet)
	local ok, parsed = pcall(function()
		return vim.lsp._snippet_grammar.parse(snippet)
	end)
	return ok and tostring(parsed)
		or M.snippet_replace(snippet, function(placeholder)
			return M.snippet_preview(placeholder.text)
		end):gsub("%$0", "")
end
-- This function replaces nested placeholders in a snippet with LSP placeholders.
function M.snippet_fix(snippet)
	local texts = {} ---@type table<number, string>
	return M.snippet_replace(snippet, function(placeholder)
		texts[placeholder.n] = texts[placeholder.n] or M.snippet_preview(placeholder.text)
		return "${" .. placeholder.n .. ":" .. texts[placeholder.n] .. "}"
	end)
end

function M.expand(snippet)
	local session = vim.snippet.active() and vim.snippet._session or nil
	local ok, err = pcall(vim.snippet.expand, snippet)
	if not ok then
		local fixed = M.snippet_fix(snippet)
		ok = pcall(vim.snippet.expand, fixed)
	end
	local msg = ok and "Failed to parse snippet, \nbut was able to fix it automatically."
		or ("Failed to parse snippet.\n" .. err)
	YukiVim[ok and "warn" or "error"](
		([[%s
```%s
%s
```]]):format(msg, vim.bo.filetype, snippet),
		{ title = "vim.snippet" }
	)

	if session then
		vim.snippet._session = session
	end
end

return M
