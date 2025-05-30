{ pkgs, ... }: {
  programs.nixvim = {
    plugins.markdown-preview = {
      enable   = true;
      autoLoad = true;

      settings = {
      theme = "dark";
        # markdown_css = "/home/nixos/.dotfiles/nixos/modules/user/nixvim/plugins/obsidian.css";
        # highlight_css = {
        #   __raw = "vim.fn.expand('/home/nixos/.dotfiles/nixos/modules/user/nixvim/plugins/obsidian-mark.css')";
        # };

        preview_options = {
          disable_filename    = 1;
          # hide_yaml_meta      = 1;
          sync_scroll_type    = "middle";
          # maid                = [ "--theme dark" ];
        };
      };
    };
  };
}
