{ config, pkgs, inputs, lib, ... }:

{
  programs.tmux = {
    enable = true;
    mouse = true;
    keyMode = "vi";
    plugins = with pkgs.tmuxPlugins; [
      better-mouse-mode
      vim-tmux-navigator
      resurrect
      continuum
      sensible
      {
        plugin = inputs.minimal-tmux.packages.${pkgs.system}.default;
        extraConfig = ''
          set -g @minimal-tmux-bg "${config.lib.stylix.colors.withHashtag.base0A}"
        '';
      }
    ];

    extraConfig = ''
      set -as terminal-overrides ',*:Tc'
      set -g default-terminal "tmux-256color"
      set -g history-limit 5000
      set -g base-index 1
      set -g renumber-windows on
      set -g prefix C-s

      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux config reloaded"

      bind-key h select-pane -L
      bind-key j select-pane -D
      bind-key k select-pane -U
      bind-key l select-pane -R
    '';
  };
}
