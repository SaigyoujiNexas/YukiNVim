vim.uv = vim.uv or vim.loop
-- require("config.options")
local lazyvim = require("lazyvim")

-- first, install lazyvim
-- second, the init method to setup bootstrap environment
-- third, load all plugins
-- forth, setup all plugin config.
lazyvim.installLazy()
local config = require("config")
config.init()
lazyvim.startLoadPlugins()
config.setup()
