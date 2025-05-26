{ pkgs, ... }: {
  programs.nixvim = {
    plugins.obsidian = {
      enable   = true;
      autoLoad = true;

      settings = {
        workspaces = [
          {
            name = "Regular";
            path = "~/Documents/Obsidian/Regular";
          }
        ];
      };
    };
  };
}
