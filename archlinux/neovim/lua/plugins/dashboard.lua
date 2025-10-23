return {
  "nvimdev/dashboard-nvim",
  event = "VimEnter",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("dashboard").setup({
      theme = "doom",
      config = {
        vertical_center = true,
        header = {
          "⠠⠀⠀⠀⠰⢀⡀⠀⡤⠏⠀⠸⠈⠐⠀⠊⡸⡀⠈⠗⠈⣠⠍⠀⠀⠡⣀⡄⠀⠠⠀⠁⡁⢂⣪⠀⠄⠀⠀⡀⡂⠄⠲⢀⠀⠀⡂⠀⣠⣄",
          "⠤⠄⠤⠄⢈⠀⢀⠰⠐⠂⡬⠀⠐⠄⠆⠠⡄⠠⠁⠒⡒⠦⠅⠄⠀⠆⡀⠂⡴⣄⠲⣐⣰⣟⣵⣀⠼⡈⢵⠤⠋⠀⡀⠭⣁⠅⠒⠑⠂⠑",
          "⠤⠤⠐⡀⠂⠀⢑⠂⠡⠟⠴⣠⡠⠀⡥⡈⡓⡇⢖⡺⡷⢩⠇⠈⢷⣞⣦⡬⡷⢶⠧⡧⣮⢵⠯⠶⡮⣺⡫⠷⡲⡇⡊⠂⡐⠾⠡⣴⠍⠅",
          "⠀⢦⠸⠓⠆⡫⠀⢰⢆⢆⡓⣃⠗⣷⠅⡨⢄⢘⢯⡥⣶⢽⣯⡿⠿⣿⣿⡏⣿⣽⣿⡝⠛⠕⢵⣻⡷⡱⡖⢓⣾⢭⢩⣡⣶⣽⣣⢄⠄⡴",
          "⠡⠙⠁⢀⢉⠠⢂⣖⠾⡏⢉⣴⠴⠸⠃⣓⠀⢻⠆⣐⣿⣇⢓⡼⡂⠩⢿⠇⠸⣷⣍⢆⠌⡭⠾⡩⣯⠿⠯⢽⣬⢧⣿⠿⢅⢭⢤⠂⢴⠆",
          "⠋⡓⠁⠃⠀⠀⠋⠋⢘⠋⠤⠄⠩⢹⣿⣯⣩⠯⡛⡿⠇⡺⣕⡡⠟⡣⢒⢥⣽⠭⠆⡫⠖⠂⡊⠫⢉⠁⡽⣀⠃⡔⠤⢴⠰⡋⠀⠀⠐⠑",
          "⠈⠁⠈⠀⠂⠀⠁⠰⠂⠂⠇⠔⡱⠫⠌⠌⠷⠠⠡⠁⠐⢆⠀⠗⡹⡇⠀⠄⠂⠅⡥⡠⢀⠑⠂⠁⠀⡂⠄⠈⠀⠀⠀⠂⠀⠀⠐⠀⠀⠈",
          "⠀⠈⠀⠀⠀⠀⠀⠁⠀⠀⠀⠉⠀⠘⠂⠀⠀⣀⡀⣝⠄⢁⠐⠀⠠⠁⠀⠀⠑⠈⠀⠀⠁⠀⠀⠀⠃⠁⠀⠂⠈⠀⠀⠀⠀⠐⠀⠀⠀⠀",
          "⠀⠠⠀⠤⠀⢀⢀⠀⠀⠀⠄⠂⠘⡀⠁⠀⠕⠀⠀⠄⠀⢐⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⢀⠀⠀⠀⠁⠁⠀⠀⠀⠀⠀⠐⠀⡀⠀⠀⠀⠀",
          "⠀⠀⠀⠀⠀⠀⠀⠀⠁⠁⠀⠀⠈⠀⠀⠀⠀⠀⠠⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠁⠀⠀⠀⠀⡀⠀⠂⠀⠀⠀⠄⠀⠀⠀⠀⠀",
          "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠁⠂⠀⠀",
          "⠂⠀⠠⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        },
        center = {
          {
            icon = "",
            icon_hl = "DashboardIcon",
            desc = "Find File",
            desc_hl = "DashboardDesc",
            key = "f",
            key_hl = "DashboardKey",
            key_format = " [%s]",
            action = "Telescope find_files",
          },
          {
            icon = "",
            icon_hl = "DashboardIcon",
            desc = "New File",
            desc_hl = "DashboardDesc",
            key = "n",
            key_hl = "DashboardKey",
            key_format = " [%s]",
            action = "ene | startinsert",
          },
          {
            icon = "",
            icon_hl = "DashboardIcon",
            desc = "Recent Files",
            desc_hl = "DashboardDesc",
            key = "r",
            key_hl = "DashboardKey",
            key_format = " [%s]",
            action = "Telescope oldfiles",
          },
          {
            icon = "",
            icon_hl = "DashboardIcon",
            desc = "Obsidian",
            desc_hl = "DashboardDesc",
            key = "o",
            key_hl = "DashboardKey",
            key_format = " [%s]",
            action = "ObsidianQuickSwitch",
          },
        },
        footer = {
          "",
          "Powered by Neovim",
        },
      },
    })

    local header_color = "#4a4a4a"
    local footer_color = "#262626"

    vim.api.nvim_set_hl(0, "DashboardHeader", {
      fg = header_color,
      bg = "NONE",
    })

    vim.api.nvim_set_hl(0, "DashboardFooter", {
      fg = footer_color,
      bg = "NONE",
    })

    vim.api.nvim_create_autocmd("User", {
      pattern = "DashboardReady",
      callback = function()
        vim.cmd(string.format("highlight DashboardHeader guifg=%s guibg=NONE", header_color))
        vim.cmd(string.format("highlight DashboardFooter guifg=%s guibg=NONE", footer_color))
      end,
    })
  end,
  keys = {
    { "<leader>db", "<cmd>Dashboard<CR>", desc = "[D]ashboard" },
  },
}
