{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh.enable = true;
    oh-my-zsh.theme = "bureau";
    initContent = ''
      autoload -Uz add-zsh-hook
      unsetopt beep

      # Yazi wrapper function
      y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }
    '';
  };

  programs.kitty = {
    enable = true;
    settings = {
      font_family = "FiraCode Nerd Font";
      font_size = 14.0;

      cursor_trail = 1;
      cursor_trail_start_threshold = 0;
      cursor_trail_decay = "0.01 0.25";
      cursor_shape = "block";
      cursor_blink = true;

      confirm_os_window_close = 0;
      scrollback_lines = 10000;
      hide_window_decorations = 1;

      enable_audio_bell = false;
      bell_on_tab = "none";
    };
  };

  programs.foot = {
    enable = true;
    # settings = { main = { font = "Hack Nerd Font:size=14"; }; };
  };
}
