return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local config = require("nvim-treesitter.configs")
    config.setup({
      ignore_install = {},
      ensure_installed = {
        "javascript",
        "typescript",
        "markdown",
        "python",
        "vimdoc",
        "html",
        "rust",
        "lua",
        "css",
        "sql",
        "c",
      },
      highlight = {
        enable = true,
      },
      indent = { enable = true },
      modules = {},
      sync_install = true,
      auto_install = true,
    })
  end
}
