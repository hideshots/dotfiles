{ pkgs, lib, ... }: 

{
  programs.nixvim.plugins.tmux-navigator = {
    enable = true;
    autoLoad = true;
  };
}
