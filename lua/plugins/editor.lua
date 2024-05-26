return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"3rd/image.nvim",
		},
		cmd = "Neotree",
		keys = {
			{
				"<C-t>",
				function()
					require("neo-tree.command").execute({
						toggle = true,
						dir = YukiVim.root(),
					})
				end,
				desc = "Explorer NeoTree (root dir)",
			},
			{
				"<C-w>",
				function()
					require("neo-tree.command").execute({
						toggle = true,
						dir = vim.uv.cwd(),
					})
				end,
				desc = "Explorer NeoTree (cwd)",
			},
			{
				"<C-g>",
				function()
					require("neo-tree.command").execute({
						source = "git_status",
						toggle = true,
					})
				end,
				desc = "Git explorer",
			},
			{
				"<C-b>",
				function()
					require("neo-tree.command").execute({
						source = "buffers",
						toggle = true,
					})
				end,
				desc = "Buffer explorer",
			},
		},
		deactivate = function()
			vim.cmd([[Neotree close]])
		end,
		init = function()
			if vim.fn.argc(-1) == 1 then
				local stat = vim.loop.fs_stat(vim.fn.argv(0))
				if stat and stat.type == "directory" then
					require("neo-tree")
				end
			end
		end,
		opts = {
			sources = { "filesystem", "buffers", "git_status", "document_symbols" },
			open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
			filesystem = {
				bind_to_cwd = false,
				follow_current_file = { enable = true },
				use_libuv_file_watcher = true,
				filtered_items = {
					visible = true,
					hide_dotfiles = false,
					hide_gitignored = false,
				},
			},
			window = {
				mappings = {
					["<space>"] = "none",
					["Y"] = {
						function(state)
							local node = state.tree:get_node()
							local path = node:get_id()
							vim.fn.setreg("+", path, "c")
						end,
						desc = "copy path to clipboard",
					},
				},
			},
			default_component_configs = {
				indent = {
					with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
					expander_collapsed = "",
					expander_expanded = "",
					expander_highlight = "NeoTreeExpander",
				},
			},
		},
		config = function(_, opts)
			local function on_move(data)
				YukiVim.lsp.on_rename(data.source, data.destination)
			end

			local events = require("neo-tree.events")
			opts.event_handlers = opts.event_handlers or {}
			vim.list_extend(opts.event_handlers, {
				{ event = events.FILE_MOVED, handler = on_move },
				{ event = events.FILE_RENAMED, handler = on_move },
			})
			require("neo-tree").setup(opts)
			vim.api.nvim_create_autocmd("TermClose", {
				pattern = "*lazygit",
				callback = function()
					if package.loaded["neo-tree.sources.git_status"] then
						require("neo-tree.sources.git_status").refresh()
					end
				end,
			})
		end,
	},
	{
		"nvim-pack/nvim-spectre",
		build = false,
		cmd = "Spectre",
		opts = { open_cmd = "noswapfile vnew" },
		keys = {
			{
				"<leader>sr",
				function()
					require("spectre").open()
				end,
				desc = "Replace in Files (Spectre)",
			},
		},
	},

	{
		"echasnovski/mini.bufremove",

		keys = {
			{
				"<leader>bd",
				function()
					local bd = require("mini.bufremove").delete
					if vim.bo.modified then
						local choice =
							vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname()), "&Yes\n&No\n&Cancel")
						if choice == 1 then -- Yes
							vim.cmd.write()
							bd(0)
						elseif choice == 2 then -- No
							bd(0, true)
						end
					else
						bd(0)
					end
				end,
				desc = "Delete Buffer",
			},
    -- stylua: ignore
    { "<leader>bD", function() require("mini.bufremove").delete(0, true) end, desc = "Delete Buffer (Force)" },
		},
	},
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		vscode = true,
		opts = {},
        -- stylua: ignore
        keys = {
            { "s",     mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash" },
            { "S",     mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },
            { "r",     mode = "o",               function() require("flash").remote() end,            desc = "Remote Flash" },
            { "R",     mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
            { "<c-s>", mode = { "c" },           function() require("flash").toggle() end,            desc = "Toggle Flash Search" },
        },
	},

	{
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "" },
				topdelete = { text = "" },
				changedelete = { text = "▎" },
				untracked = { text = "▎" },
			},
			on_attach = function(buffer)
				local gs = package.loaded.gitsigns

				local function map(mode, l, r, desc)
					vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
				end
				map("n", "]h", gs.next_hunk, "Next Hunk")
				map("n", "[h", gs.prev_hunk, "Prev Hunk")
				map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
				map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
				map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
				map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
				map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
				map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
				map("n", "<leader>ghb", function()
					gs.blame_line({ full = true })
				end, "Blame Line")
				map("n", "<leader>ghd", gs.diffthis, "Diff This")
				map("n", "<leader>ghD", function()
					gs.diffthis("~")
				end, "Diff This ~")
			end,
		},
	},
	{
		"rrethy/vim-illuminate",
		opts = {
			delay = 200,
			large_file_cutoff = 2000,
			large_file_overrides = {
				providers = { "lsp" },
			},
		},
		config = function(_, opts)
			require("illuminate").configure(opts)
			local function map(key, dir, buffer)
				vim.keymap.set("n", key, function()
					require("illuminate")["goto_" .. dir .. "_reference"](false)
				end, { desc = dir:sub(1, 1):upper() .. dir:sub(2) .. " Reference", buffer = buffer })
			end

			map("]]", "next")
			map("[[", "prev")

			-- also set it after loading ftplugins, since a lot overwrite [[ and ]]
			vim.api.nvim_create_autocmd("FileType", {
				callback = function()
					local buffer = vim.api.nvim_get_current_buf()
					map("]]", "next", buffer)
					map("[[", "prev", buffer)
				end,
			})
		end,
		keys = {
			{ "]]", desc = "Next Reference" },
			{ "[[", desc = "Prev Reference" },
		},
	},
	{
		"nvim-pack/nvim-spectre",
		build = false,
		cmd = "Spectre",
		opts = { open_cmd = "noswapfile vnew" },
		keys = {
			{
				"<leader>sr",
				function()
					require("spectre").open()
				end,
				desc = "Replace in files (Spectre)",
			},
		},
	},

	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		version = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = vim.fn.executable("make") == 1 and "make"
					or "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
				enabled = vim.fn.executable("make") == 1 or vim.fn.executable("cmake") == 1,
				config = function()
					YukiVim.on_load("telescope.nvim", function()
						require("telescope").load_extension("fzf")
					end)
				end,
			},
		},
		keys = {
			{
				"<leader>gc",
				"<cmd>Telescope git_commits<CR>",
				desc = "commits",
			},
			{
				"<leader>gs",
				"<cmd>Telescope git_status<CR>",
				desc = "status",
			},
			{
				"<leader>ff",
				"<cmd>Telescope find_files<CR>",
				desc = "find files",
			},
			{
				"<leader>fg",
				"<cmd>Telescope live_grep<CR>",
				desc = "live grep",
			},
			{
				"<leader>fb",
				"<cmd>Telescope buffers<CR>",
				desc = "buffers",
			},
			{
				"<leader>fh",
				"<cmd>Telescope help_tags<CR>",
				desc = "help tags",
			},
			{
				"<leader>ss",
				function()
					require("telescope.builtin").lsp_document_symbols({
						symbols = require("config").get_kind_filter(),
					})
				end,
				desc = "Goto Symbol",
			},
		},
		opts = function()
			YukiVim.on_load("telescope.nvim", function()
				require("telescope").load_extension("aerial")
			end)
			return {
				defaults = {
					prompt_prefix = " ",
					selection_caret = " ",
				},
				get_selection_window = function()
					local wins = vim.api.nvim_list_wins()
					table.insert(wins, 1, vim.api.nvim_get_current_win())
					for _, win in ipairs(wins) do
						local buf = vim.api.nvim_win_get_buf(win)
						if vim.bo[buf].buftype == "" then
							return win
						end
					end
					return 0
				end,
				extensions = {
					fzf = {
						fuzzy = true,
						override_generic_sorter = true,
						override_file_sorter = true,
						case_mode = "smart_case",
					},
				},
			}
		end,
		config = function(_, opts)
			local function flash(prompt_bufnr)
				require("flash").jump({
					pattern = "^",
					label = { after = { 0, 0 } },
					search = {
						mode = "search",
						exclude = {
							function(win)
								return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "TelescopeResults"
							end,
						},
					},
					action = function(match)
						local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
						picker:set_selection(match.pos[1] - 1)
					end,
				})
			end
			opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
				mappings = { n = { s = flash }, i = { ["<c-s>"] = flash } },
			})
			local telescope = require("telescope")
			telescope.setup(opts)
		end,
	},
	{
		"folke/todo-comments.nvim",
		cmd = { "TodoTrouble", "TodoTelescope" },
		config = true,
		keys = {
			{
				"]t",
				function()
					require("todo-comments").jump_next()
				end,
				desc = "Next todo comment",
			},
			{
				"[t",
				function()
					require("todo-comments").jump_prev()
				end,
				desc = "Previous todo comment",
			},
			{ "<leader>xt", "<cmd>TodoTrouble<cr>", desc = "Todo (Trouble)" },
			{ "<leader>st", "<cnd>TodoTelescope<cr>", desc = "Todo" },
		},
	},
	{
		"folke/trouble.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		cmd = { "TroubleToggle", "Trouble" },
		opts = { use_diagnostic_signs = true },
		keys = {
			{
				"[q",
				function()
					if require("trouble").is_open() then
						require("trouble").previous({ skip_groups = true, jump = true })
					else
						local ok, err = pcall(vim.diagnostic.goto_prev)
						if not ok then
							vim.notify(err, vim.log.levels.ERROR)
						end
					end
				end,
				desc = "Previous trouble/quickfix item",
			},
			{
				"]q",
				function()
					if require("trouble").is_open() then
						require("trouble").next({ skip_groups = true, jump = true })
					else
						local ok, err = pcall(vim.diagnostic.goto_next)
						if not ok then
							vim.notify(err, vim.log.levels.ERROR)
						end
					end
				end,
				desc = "Next trouble/quickfix item",
			},
			{
				"<leader>xw",
				"<cmd>TroubleToggle workspace_diagnistics<cr>",
				desc = "Workspace Diagnostics (Trouble)",
			},
			{
				"<leader>xl",
				"<cmd>TroubleToggle loclist<cr>",
				desc = "Location List (Trouble)",
			},
			{
				"<leader>xq",
				"<cmd>TroubleToggle quickfix<cr>",
				desc = "Quickfix List (Trouble)",
			},
		},
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			plugins = { spelling = true },
			defaults = {
				mode = { "n", "v" },
				["g"] = { name = "+goto" },
				["gd"] = { name = "definition/declaration" },
				["gs"] = { name = "+surround" },
				["z"] = { name = "+fold" },
				["<leader>b"] = { name = "+buffer" },
				["<leader>c"] = { name = "+code" },
				["<leader>g"] = { name = "+git" },
				["<leader>gh"] = { name = "+hunk" },
				["<leader>f"] = { name = "+file/find" },
				["<leader>s"] = { name = "+search" },
				["<leader>x"] = { name = "+diagnositics/quickfix" },
				["]"] = { name = "+next" },
				["["] = { name = "+prev" },
			},
		},
		config = function(_, opts)
			local wk = require("which-key")
			wk.setup(opts)
			wk.register(opts.defaults)
		end,
	},
	{
		"stevearc/aerial.nvim",
		opts = function()
			local Config = require("config")
			local icons = vim.deepcopy(Config.icons.kinds)

			-- HACK: fix lua's weird choice for `Package` for control
			-- structures like if/else/for/etc.
			icons.lua = { Package = icons.Control }

			---@type table<string, string[]>|false
			local filter_kind = false
			if Config.kind_filter then
				filter_kind = assert(vim.deepcopy(Config.kind_filter))
				filter_kind._ = filter_kind.default
				filter_kind.default = nil
			end

			local opts = {
				attach_mode = "global",
				backends = { "lsp", "treesitter", "markdown", "man" },
				show_guides = true,
				layout = {
					resize_to_content = false,
					win_opts = {
						winhl = "Normal:NormalFloat,FloatBorder:NormalFloat,SignColumn:SignColumnSB",
						signcolumn = "yes",
						statuscolumn = " ",
					},
				},
				icons = icons,
				filter_kind = filter_kind,
				guides = {
					mid_item = "├╴",
					last_item = "└╴",
					nested_top = "│ ",
					whitespace = "  ",
				},
			}
			return opts
		end,
		keys = {
			{ "<leader>sf", "<cmd>AerialToggle<cr>", desc = "Aerial (Symbols)" },
		},
	},
	{
		"folke/edgy.nvim",
		optional = true,
		opts = function(_, opts)
			-- local edgy_idx = YukiVim.plugin.extra_idx("ui.edgy")
			-- local aerial_idx = YukiVim.plugin.extra_idx("editor.aerial")
			--
			-- if edgy_idx and edgy_idx > aerial_idx then
			-- 	YukiVim.warn(
			-- 		"The `edgy.nvim` extra must be **imported** before the `aerial.nvim` extra to work properly.",
			-- 		{
			-- 			title = "LazyVim",
			-- 		}
			-- 	)
			-- end

			opts.right = opts.right or {}
			table.insert(opts.right, {
				title = "Aerial",
				ft = "aerial",
				pinned = true,
				open = "AerialOpen",
			})
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		optional = true,
		opts = function(_, opts)
			opts.sections = opts.sections or {}
			opts.sections.lualine_c = opts.sections.lualine_c or {}
			table.insert(opts.sections.lualine_c, {
				"aerial",
				sep = " ", -- separator between symbols
				sep_icon = "", -- separator between icon and symbol

				-- The number of symbols to render top-down. In order to render only 'N' last
				-- symbols, negative numbers may be supplied. For instance, 'depth = -1' can
				-- be used in order to render only current symbol.
				depth = 5,

				-- When 'dense' mode is on, icons are not rendered near their symbols. Only
				-- a single icon that represents the kind of current symbol is rendered at
				-- the beginning of status line.
				dense = false,

				-- The separator to be used to separate symbols in dense mode.
				dense_sep = ".",

				-- Color the symbol icons.
				colored = true,
			})
		end,
	},
	{
		"nvim-telescope/telescope.nvim",
		optional = true,
		opts = function()
			YukiVim.on_load("telescope.nvim", function()
				require("telescope").load_extension("aerial")
			end)
		end,
		keys = {
			{
				"<leader>sa",
				"<cmd>Telescope aerial<cr>",
				desc = "Goto Symbol (Aerial)",
			},
		},
	},
	{
		"akinsho/toggleterm.nvim",
		versions = "*",
		config = true,
		-- opts = {
		-- 	open_mapping = [[C-/]],
		-- },
	},
}
