return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        config = function()
        end
      },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          border = {
            prompt = { 1, 1, 1, 1 },
            results = { 1, 1, 1, 1 },
            preview = { 1, 1, 1, 1 },
          },
          borderchars = {
            prompt = { " ", " ", "─", "│", "│", " ", "─", "└" },
            results = { "─", " ", " ", "│", "┌", "─", " ", "│" },
            preview = { "─", "│", "─", "│", "┬", "┐", "┘", "┴" },
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
        pickers = {
          colorscheme = {
            enable_preview = true,
          },
          find_files = {
            hidden = true,
            find_command = {
              "rg",
              "--files",
              "--glob",
              "!{.git/*,.next/*,.svelte-kit/*,target/*,node_modules/*}",
              "--path-separator",
              "/",
            },
          },
        },
      })

      require("telescope").load_extension("zoxide")
    end,

    keys = {
      {
        "<leader>jk",
        function()
          require("telescope.builtin").find_files({
            find_command = { "rg", "--files", "--hidden", "-g", "!.git" }
          })
        end,
        desc = "Find Files"
      },
      { "<leader>ff", "<cmd>Telescope find_files<cr>",            desc = "Find Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",             desc = "Live Grep" },
      { "<leader>fd", "<cmd>Telescope diagnostics<cr>",           desc = "Diagnostics" },
      { "<leader>ds", "<cmd>Telescope lsp_document_symbols<cr>",  desc = "Document Symbols" },
      { "<leader>ws", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "Workspace Symbols" },
      { "<leader>fv", "<cmd>Telescope help_tags<cr>",             desc = "Help Tags" },
    },
  },
  {
    "jvgrootveld/telescope-zoxide",
    config = function() end,
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
    config = function()
      require("telescope").setup({
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({
            }),
          },
        },
      })
      require("telescope").load_extension("ui-select")
    end,
  },
}
