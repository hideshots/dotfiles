{ config, pkgs, inputs, lib, ... }:

{
  programs.tmux = {
    enable = true;
    mouse = true;
    keyMode = "vi";
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = inputs.minimal-tmux.packages.${pkgs.system}.default;
        extraConfig = ''
          # this will now be applied before the plugin loads
          set -g @minimal-tmux-bg "${config.lib.stylix.colors.withHashtag.base0A}"
        '';
      }
      better-mouse-mode
      vim-tmux-navigator
      resurrect         # doesn't work in unstable for some reason
      continuum
      sensible
    ];

    extraConfig = ''
      set -g default-terminal "tmux-256color"
      set -ga terminal-overrides ",xterm-256color:Tc"

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
