local haskell_ft = { "haskell", "lhaskell", "cabal", "cabalproject" }

return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = { ensure_installed = { "haskell" } },
	},
	{
		"mrcjkb/haskell-tools.nvim",
		ft = haskell_ft,
		dependencies = {
			{ "nvim-telescope/telescope.nvim", optional = true },
		},
		version = "^3",
		config = function()
			local ok, telescope = pcall(require, "telescope")
			if ok then
				telescope.load_extension("ht")
			end
		end,
	},
	{
		"williamboman/mason.nvim",
		opts = { ensure_installed = { "haskell-language-server" } },
	},
	{
		"mfussenegger/nvim-dap",
		optional = true,
		dependencies = {
			{
				"williamboman/mason.nvim",
				opts = { ensure_installed = { "haskell-debug-adapter" } },
			},
		},
	},
	{
		"luc-tielen/telescope_hoogle",
		ft = haskell_ft,
		dependencies = {
			{ "nvim-telescope/telescope.nvim" },
		},
		config = function()
			require("telescope").load_extension("hoogle")
		end,
	},
	{
		"nvim-neotest/neotest",
		optional = true,
		dependencies = { "mrcjkb/neotest-haskell" },
		opts = {
			adapters = {
				["neotest-haskell"] = {},
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			setup = {
				hls = function()
					return true
				end,
			},
		},
	},
}
