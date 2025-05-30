{ pkgs, lib, config, ... }:

# "⠠⠀⠀⠀⠰⢀⡀⠀⡤⠏⠀⠸⠈⠐⠀⠊⡸⡀⠈⠗⠈⣠⠍⠀⠀⠡⣀⡄⠀⠠⠀⠁⡁⢂⣪⠀⠄⠀⠀⡀⡂⠄⠲⢀⠀⠀⡂⠀⣠⣄"
# "⠤⠄⠤⠄⢈⠀⢀⠰⠐⠂⡬⠀⠐⠄⠆⠠⡄⠠⠁⠒⡒⠦⠅⠄⠀⠆⡀⠂⡴⣄⠲⣐⣰⣟⣵⣀⠼⡈⢵⠤⠋⠀⡀⠭⣁⠅⠒⠑⠂⠑"
# "⠤⠤⠐⡀⠂⠀⢑⠂⠡⠟⠴⣠⡠⠀⡥⡈⡓⡇⢖⡺⡷⢩⠇⠈⢷⣞⣦⡬⡷⢶⠧⡧⣮⢵⠯⠶⡮⣺⡫⠷⡲⡇⡊⠂⡐⠾⠡⣴⠍⠅"
# "⠀⢦⠸⠓⠆⡫⠀⢰⢆⢆⡓⣃⠗⣷⠅⡨⢄⢘⢯⡥⣶⢽⣯⡿⠿⣿⣿⡏⣿⣽⣿⡝⠛⠕⢵⣻⡷⡱⡖⢓⣾⢭⢩⣡⣶⣽⣣⢄⠄⡴"
# "⠡⠙⠁⢀⢉⠠⢂⣖⠾⡏⢉⣴⠴⠸⠃⣓⠀⢻⠆⣐⣿⣇⢓⡼⡂⠩⢿⠇⠸⣷⣍⢆⠌⡭⠾⡩⣯⠿⠯⢽⣬⢧⣿⠿⢅⢭⢤⠂⢴⠆"
# "⠋⡓⠁⠃⠀⠀⠋⠋⢘⠋⠤⠄⠩⢹⣿⣯⣩⠯⡛⡿⠇⡺⣕⡡⠟⡣⢒⢥⣽⠭⠆⡫⠖⠂⡊⠫⢉⠁⡽⣀⠃⡔⠤⢴⠰⡋⠀⠀⠐⠑"
# "⠈⠁⠈⠀⠂⠀⠁⠰⠂⠂⠇⠔⡱⠫⠌⠌⠷⠠⠡⠁⠐⢆⠀⠗⡹⡇⠀⠄⠂⠅⡥⡠⢀⠑⠂⠁⠀⡂⠄⠈⠀⠀⠀⠂⠀⠀⠐⠀⠀⠈"
# "⠀⠈⠀⠀⠀⠀⠀⠁⠀⠀⠀⠉⠀⠘⠂⠀⠀⣀⡀⣝⠄⢁⠐⠀⠠⠁⠀⠀⠑⠈⠀⠀⠁⠀⠀⠀⠃⠁⠀⠂⠈⠀⠀⠀⠀⠐⠀⠀⠀⠀"
# "⠀⠠⠀⠤⠀⢀⢀⠀⠀⠀⠄⠂⠘⡀⠁⠀⠕⠀⠀⠄⠀⢐⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⢀⠀⠀⠀⠁⠁⠀⠀⠀⠀⠀⠐⠀⡀⠀⠀⠀⠀"
# "⠀⠀⠀⠀⠀⠀⠀⠀⠁⠁⠀⠀⠈⠀⠀⠀⠀⠀⠠⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠁⠀⠀⠀⠀⡀⠀⠂⠀⠀⠀⠄⠀⠀⠀⠀⠀"
# "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠁⠂⠀⠀"
# "⠂⠀⠠⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"

{
  programs.nixvim = {
    plugins.dashboard = {
      enable = true;
      autoLoad = true;

      settings = {
        theme = "doom";
        config = {
          vertical_center = true;

          header = [
            " ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⠀⠀⠀⠀⠀"
            " ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⢤⠤⠤⠞⡎⠀⠀⠀⠀⠀"
            " ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⡥⠀⠀⠓⠦⢄⡀⠀⠀"
            " ⠀⢸⠦⣄⡠⠞⡇⠀⠀⠀⣞⣠⠤⡀⢰⠋⠁⠀⠀⠀"
            " ⠀⠈⡇⠈⠁⠀⡇⠀⠀⠈⠁⠀⠀⠉⢾⡄⠀⠀⠀⠀"
            " ⣠⣔⣃⣀⠀⠀⠘⣦⡀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀"
            " ⠀⠀⠀⠸⡄⡞⠉⠀⠀⠀⠀⠀⡏⢆⠀⣀⠤⠒⡶⠃"
            " ⠀⠀⠀⠀⠟⠀⠀⠀⠀⠀⠀⢀⡧⠀⠁⠀⢀⠎⠀⠀"
            " ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠳⣄⠀⢀⣀⠈⡇⠀⠀"
            " ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡞⡴⠋⠈⠙⠿⠀⠀"
            " ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⠀⠀⠀⠀⠀⠀⠀"
            ""
            ""
          ];
          center = [
            {
              # icon        = " ";
              icon_hl     = "DashboardIcon";
              desc        = "Find File";
              desc_hl     = "DashboardDesc";
              key         = "f";
              key_hl      = "DashboardKey";
              key_format  = " [%s]";
              action      = "Telescope find_files";
            }

            {
              # icon        = " ";
              icon_hl     = "DashboardIcon";
              desc        = "New File";
              desc_hl     = "DashboardDesc";
              key         = "n";
              key_hl      = "DashboardKey";
              key_format  = " [%s]";
              action      = "ene | startinsert";
            }

            {
              # icon        = " ";
              icon_hl     = "DashboardIcon";
              desc        = "Recent Files";
              desc_hl     = "DashboardDesc";
              key         = "r";
              key_hl      = "DashboardKey";
              key_format  = " [%s]";
              action      = "Telescope oldfiles";
            }

            {
              icon_hl     = "DashboardIcon";
              desc        = "Obsidian";
              desc_hl     = "DashboardDesc";
              key         = "o";
              key_hl      = "DashboardKey";
              key_format  = " [%s]";
              action      = "ObsidianQuickSwitch";
            }

            # {
            #   icon        = " ";
            #   icon_hl     = "DashboardIcon";
            #   desc        = "Quit";
            #   desc_hl     = "DashboardDesc";
            #   key         = "q";
            #   key_hl      = "DashboardKey";
            #   key_format  = " [%s]";
            #   action      = "qa";
            # }
          ];



          footer = [
            # "   __          "
            # "  ( _/_ _ /_// "
            # " __)/(-(/( //) "
            # "               "
            ""
            " stealth © nixvim"
          ];
        };
      };
    luaConfig.post = ''
      vim.api.nvim_set_hl(0, "DashboardHeader", {
        fg = "${config.lib.stylix.colors.withHashtag.base0A}",
        bg = "NONE"
      })
      vim.api.nvim_set_hl(0, "DashboardFooter", {
        fg = "${config.lib.stylix.colors.withHashtag.base0A}",
        bg = "NONE"
      })

      -- Re-apply colors when DashboardReady event fires
      vim.api.nvim_create_autocmd("User", {
        pattern = "DashboardReady",
        callback = function()
          local color = "${config.lib.stylix.colors.withHashtag.base0A}"
          vim.cmd(string.format("highlight DashboardHeader guifg=%s guibg=NONE", color))
          vim.cmd(string.format("highlight DashboardFooter guifg=%s guibg=NONE", color))
        end,
      })
    '';
    };
    keymaps = [
      {
        mode    = "n";
        key     = "<leader>db";
        action  = "<cmd>Dashboard<CR>";
        options = {
          desc = "[D]ashboard";
        };
      }
    ];

  };
}
