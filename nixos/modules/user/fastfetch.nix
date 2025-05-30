{ pkgs, lib, ... }:

{
  programs.fastfetch.enable = true;
  programs.zsh.shellAliases = {
      fastfetch = "fastfetch --logo-color-1 yellow";
    };

  home.file.".config/fastfetch/config.jsonc".text = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
      "logo": {
        "source": "~/.config/fastfetch/butterfly.txt",
        "padding": {
          "top": 3,
          "left": 4,
          "right": 5
        }
      },
      "display": {
        "separator": " "
      },
      "modules": [
        "break",
        "break",
        {
          "type": "custom",
          "format": "\u001b[90m  \u001b[31m  \u001b[32m  \u001b[33m  \u001b[34m  \u001b[35m  \u001b[36m  \u001b[37m"
        },
        "break",
        {
          "type": "os",
          "key": " ",
          "format": "\u001b[32m{2}\u001b[0m {8}"
        },
        "break",
        {
          "type": "cpu",
          "key": "󰍹 ",
          "format": "{1} ({6})"
        },
        {
          "type": "gpu",
          "key": "  ",
          "format": "{1} {2}"
        },
        {
          "type": "memory",
          "key": "  ",
          "format": "{1~0,-4} / {2} ({3})"
        },
        "break",
        {
          "type": "users",
          "key": " ",
          "format": "\u001b[32muser\u001b[0m             {1}"
        },
        {
          "type": "terminal",
          "key": "  ",
          "format": "\u001b[32mterminal\u001b[0m         {5}"
        },
        {
          "type": "LM",
          "key": "  ",
          "format": "\u001b[32mdm\u001b[0m               {1}"
        },
        {
          "type": "wm",
          "key": "  ",
          "format": "\u001b[32mwm\u001b[0m               {2}"
        },
        "break",
        {
          "type": "uptime",
          "key": "󰋼 ",
          "format": ""
        },
        {
          "type": "media",
          "key": "  ",
          "format": ""
        }
      ]
    }
  '';

  home.file.".config/fastfetch/butterfly.txt".text = ''
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣴⡦
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡴⠏⠄⣺⠃
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⡋⢚⠄⠊⣿
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⢏⣔⣤⢲⣋⣿⡀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠏⠁⡔⠻⣿⢡⠼⢧
⣾⣷⠶⣤⣀⠀⠀⠀⠀⠀⠀⠀⡜⠀⡰⠋⠀⣙⣀⣰⣽⡀
⠙⠻⣤⠐⢺⡗⠤⡀⠀⠀⠀⠀⠇⢀⢃⣴⡿⢋⠤⠾⠯⢽⣄
⠀⠀⠀⠙⠢⢄⠀⠐⠴⣄⠀⠀⣰⣻⡿⢛⡉⠉⠀⠀⠐⠀⢿⡀
⠀⠀⠀⠀⠀⠀⠙⢴⠁⣠⣵⢶⣿⣾⢭⡭⠤⣀⠀⠄⢀⠁⠀⢧
⠀⠀⠀⠀⠀⠀⠀⠀⠁⠿⠁⠈⠫⠻⣷⣝⡢⢄⠀⠀⠀⠈⠱⣾⠁
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢦⣄⠀⠈⠻⢿⣶⣤⣄⣀⣀⣴⠉
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢦⡘⡄⠹⣦⠈⠉⠉⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠒⠢⠽
  '';
}
