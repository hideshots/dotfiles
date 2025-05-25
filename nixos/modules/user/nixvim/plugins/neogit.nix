{ pkgs, ... }: {
  programs.nixvim = {
    plugins.neogit = {
      enable = true;
      autoLoad = true;
    };
  };
}
