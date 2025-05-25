{ ... }:

{
  programs.nixvim = {
    plugins.lualine = {
      enable   = true;
      autoLoad = true;

      settings = {
        options = {
          icons_enabled        = true;
          component_separators = { left  = ""; right = ""; };
          section_separators   = { left  = ""; right = ""; };
          disabled_filetypes   = {
            statusline = [ "alpha" "dashboard" ];
            winbar     = [ ];
          };
          always_divide_middle = true;
          globalstatus         = false;
        };

        sections = {
          # left side
          lualine_a = [ "" ];
          lualine_b = [ "" ];
          lualine_c = [ "mode" "diagnostics" "diff" "filetype" ];

          # right side
          lualine_x = [ "filename" "datetime" ];
          lualine_y = [ "" ];
          lualine_z = [ "" ];
        };

        inactive_sections = {
          lualine_a = [ "" ];
          lualine_b = [ "" ];
          lualine_c = [ "filename" ];
          lualine_x = [ "filetype" ];
          lualine_y = [ "" ];
          lualine_z = [ "" ];
        };

        tabline         = { };
        winbar          = { };
        inactive_winbar = { };
        extensions      = [ "neo-tree" "quickfix" ];
      };
    };
  };
}
