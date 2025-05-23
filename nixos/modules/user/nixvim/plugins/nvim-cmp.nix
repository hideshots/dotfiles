{
  programs.nixvim = {
    # `friendly-snippets` contains a variety of premade snippets
    #    See the README about individual language/framework/plugin snippets:
    #    https://github.com/rafamadriz/friendly-snippets
    # https://nix-community.github.io/nixvim/plugins/friendly-snippets.html
    # plugins.friendly-snippets = {
    #   enable = true;
    # };

    plugins.lazydev.enable = true; # autoEnableSources not enough
    plugins.luasnip.enable = true; # autoEnableSources not enough

    # Autocompletion
    # See `:help cmp`
    # https://nix-community.github.io/nixvim/plugins/cmp/index.html
    plugins.cmp = {
      enable = true;

      settings = {
        snippet = {
          expand = ''
          function(args)
            require('luasnip').lsp_expand(args.body)
          end
          '';
        };

        completion = {
          completeopt = "menu,menuone,noinsert";
        };

        mapping = {
          # Cycle through items with Tab / Shift-Tab
          "<Tab>" = ''
          cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
            else
              fallback()
            end
          end, { "i", "s" })
          '';
          "<S-Tab>" = ''
          cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
            else
              fallback()
            end
          end, { "i", "s" })
          '';

          # Confirm selection with Enter
          "<CR>" = "cmp.mapping.confirm { select = true }";

          # Your existing mappings…
          "<C-n>" = "cmp.mapping.select_next_item()";
          "<C-p>" = "cmp.mapping.select_prev_item()";
          "<C-b>" = "cmp.mapping.scroll_docs(-4)";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";
          "<C-y>" = "cmp.mapping.confirm { select = true }";
          "<C-Space>" = "cmp.mapping.complete {}";
          "<C-l>" = ''
          cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            end
          end, { "i", "s" })
          '';
          "<C-h>" = ''
          cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { "i", "s" })
          '';
        };

        sources = [
          { name = "lazydev";   group_index = 0; }
          { name = "nvim_lsp";  }
          { name = "luasnip";   }
          { name = "path";      }
          { name = "nvim_lsp_signature_help"; }
        ];
      };
    };
  };
}
