return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
      {"<C-/>"}, {"<C-_>"}
    },
    opts = function(_, opts)
      opts.open_mapping = { [[<C-/>]], [[<C-_>]] }
      opts.insert_mappings = true
      opts.terminal_mappings = true
      opts.direction = "float"
    end,
  },
}
