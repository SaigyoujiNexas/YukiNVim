return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "VeryLazy" },
		init = function(plugin)
			require("lazy.core.loader").add_to_rtp(plugin)
			require("nvim-treesitter.query_predicates")
		end,
		opts_extend = { "ensure_installed" },
		dependencies = {
			{
				"nvim-treesitter/nvim-treesitter-textobjects",
				config = function()
					local move = require("nvim-treesitter.textobjects.move") ---@type table<string,fun(...)>
					local configs = require("nvim-treesitter.configs")
					for name, fn in pairs(move) do
						if name:find("goto") == 1 then
							move[name] = function(q, ...)
								if vim.wo.diff then
									local config = configs.get_module("textobjects.move")[name] ---@type table<string,string>
									for key, query in pairs(config or {}) do
										if q == query and key:find("[%]%[][cC]") then
											vim.cmd("normal! " .. key)
											return
										end
									end
								end
								return fn(q, ...)
							end
						end
					end
				end,
			},
		},
		cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
		opts = function(_, opts)
			local function add(lang)
				if type(opts.ensure_installed) == "table" then
					table.insert(opts.ensure_installed, lang)
				end
			end
			vim.filetype.add({
				extension = { rasi = "rasi" },
				pattern = {
					[".*/waybar/config"] = "jsonc",
					[".*/mako/config"] = "dosini",
					[".*/kitty/*.conf"] = "bash",
					[".*/hypr/.*%.conf"] = "hyprlang",
				},
			})
			add("git_config")

			local other = {
				auto_install = true,
				highlight = { enable = true },
				indent = { enable = true },
				ensure_installed = {
					"bash",
					"c",
					"c_sharp",
					"diff",
					"html",
					"java",
					"javascript",
					"jsdoc",
					"json",
					"jsonc",
					"luadoc",
					"lua",
					"luap",
					"markdown",
					"markdown_inline",
					"printf",
					"python",
					"query",
					"regex",
					"toml",
					"tsx",
					"typescript",
					"vim",
					"vimdoc",
					"xml",
					"yaml",
				},
				textobjects = {
					move = {
						enable = true,
						goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
						goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
						goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
						goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
					},
				},
			}
			return vim.tbl_deep_extend("force", opts, other)
		end,
		config = function(_, opts)
			if type(opts.ensure_installed) == "table" then
				opts.ensure_installed = YukiVim.dedup(opts.ensure_installed)
			end
			require("nvim-treesitter.configs").setup(opts)
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		enabled = true,
		opts = { mode = "cursor", max_lines = 3 },
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		event = "VeryLazy",
		enabled = true,
		config = function()
			local lazy_config = require("lazy.core.config")
			-- If treesitter is already loaded, we need to run config again for textobjects
			if lazy_config.plugins["nvim-treesitter"] and lazy_config.plugins["nvim-treesitter"]._.loaded then
				local opts = YukiVim.opts("nvim-treesitter")
				require("nvim-treesitter.configs").setup({ textobjects = opts.textobjects })
			end

			-- When in diff mode, we want to use the default
			-- vim text objects c & C instead of the treesitter ones.
			local move = require("nvim-treesitter.textobjects.move") ---@type table<string,fun(...)>
			local configs = require("nvim-treesitter.configs")
			for name, fn in pairs(move) do
				if name:find("goto") == 1 then
					move[name] = function(q, ...)
						if vim.wo.diff then
							local config = configs.get_module("textobjects.move")[name] ---@type table<string,string>
							for key, query in pairs(config or {}) do
								if q == query and key:find("[%]%[][cC]") then
									vim.cmd("normal! " .. key)
									return
								end
							end
						end
						return fn(q, ...)
					end
				end
			end
		end,
	},
	{
		"windwp/nvim-ts-autotag",
		opts = {},
	},
}
