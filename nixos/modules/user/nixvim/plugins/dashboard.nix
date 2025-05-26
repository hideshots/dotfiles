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
  programs.nixvim.plugins.dashboard = {
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
            action      = "Obsidian";
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
  };
}
