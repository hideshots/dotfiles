{ pkgs, ... }: {
  programs.nixvim = {
    plugins.noice = {
      enable = true;
      autoLoad = true;

      settings = {
        presets = {
          bottom_search = true;
          command_palette = true;
          long_message_to_split = true;
          lsp_doc_border = true;
        };

        cmdline = {
          enabled = true;
          view = "cmdline_popup";
        };

        messages = {
          enabled = true;
          view = "notify";
          view_error = "notify";
          view_warn = "notify";
          view_history = "messages";
          view_search = "virtualtext";
        };

        notify = {
          enabled = true;
          view = "notify";
        };

        popupmenu = {
          enabled = true;
          backend = "nui";
        };

        smart_move = {
          enabled = true;
          excluded_filetypes = [ "cmp_menu" "cmp_docs" "notify" ];
        };

        health = {
          checker = true;
        };

        lsp = {
          override = {
            "vim.lsp.util.convert_input_to_markdown_lines" = true;
            "vim.lsp.util.stylize_markdown" = true;
            "cmp.entry.get_documentation" = true;
          };
        };

        status = {
          ruler = {};
          message = {};
          command = {};
          mode = {};
          search = {};
        };
      };
    };
  };
}
