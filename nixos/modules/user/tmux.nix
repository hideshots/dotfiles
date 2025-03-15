{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    mouse = true;
    keyMode = "vi";
    extraConfig = ''
      set -g @tmux_power_theme 'everforest'
      set -g default-terminal "tmux-256color"
      set -ga terminal-overrides ",xterm-256color:Tc"
      set -g history-limit 5000
      set -g base-index 1
      set -g renumber-windows on
      set -g prefix C-s
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux config reloaded"
      set -g @continuum-boot 'on'
      bind-key h select-pane -L
      bind-key j select-pane -D
      bind-key k select-pane -U
      bind-key l select-pane -R
    '';

    plugins = with pkgs.tmuxPlugins; [
      sensible
      better-mouse-mode
      vim-tmux-navigator
      # resurrect         # doesn't work in unstable for some reason
      continuum
      power-theme
    ];
  };
}
