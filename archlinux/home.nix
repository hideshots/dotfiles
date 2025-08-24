{ config, pkgs, inputs, system, lib, ... }:

let
  link = path: config.lib.file.mkOutOfStoreSymlink path;
  home = config.home.homeDirectory;
in {
  xdg.configFile."wal/templates".source = link "${home}/.dotfiles/archlinux/pywal";
 	xdg.configFile."MangoHud/MangoHud.conf".source = link "${home}/.cache/wal/MangoHud.conf";
 	home.file.".tmux.conf".source = link "${home}/.cache/wal/.tmux.conf";

  xdg.configFile."kitty".source = link "${home}/.dotfiles/archlinux/kitty";
 	home.file.".zshrc".source     = link "${home}/.dotfiles/archlinux/shell/.zshrc";
 	# home.file.".tmux.conf".source = link "${home}/.dotfiles/archlinux/tmux/.tmux.conf";
  xdg.configFile."yazi".source  = link "${home}/.dotfiles/archlinux/yazi";
  xdg.configFile."nvim".source  = link "${home}/.dotfiles/archlinux/neovim";
  xdg.configFile."rofi".source  = link "${home}/.dotfiles/archlinux/rofi";
  xdg.configFile."fastfetch".source  = link "${home}/.dotfiles/archlinux/fastfetch";

  xdg.configFile."wofi".source = link "${home}/.dotfiles/archlinux/wofi";

  xdg.configFile."i3status".source = link "${home}/.dotfiles/archlinux/i3status";
  xdg.configFile."sway".source     = link "${home}/.dotfiles/archlinux/sway";
  xdg.configFile."mako".source     = link "${home}/.dotfiles/archlinux/mako";

  xdg.configFile."hypr".source     = link "${home}/.dotfiles/archlinux/hyprland";

  home.packages = with pkgs; [
    inputs.appleEmoji.packages.${system}.apple-emoji-linux
    inputs.home-manager.packages.${system}.home-manager
    inputs.apple-fonts.packages.${system}.sf-mono-nerd
    inputs.apple-fonts.packages.${system}.sf-pro
    nerd-fonts.iosevka
    terminus_font
    nix
  ];

  home = {
    username = "drama";
    homeDirectory = "/home/drama";
    stateVersion = "25.05";
  };
}
