{ pkgs, inputs, ... }: {

  imports = [
    inputs.nixvim.homeManagerModules.nixvim
    #inputs.nixvim.nixosModules.nixvim
    #inputs.nixvim.nixDarwinModules.nixvim

    # Plugins
    ./plugins/which-key.nix
    ./plugins/telescope.nix
    ./plugins/comment.nix
    ./plugins/treesitter.nix
    ./plugins/nvim-cmp.nix
    ./plugins/lsp.nix
    ./plugins/gitsigns.nix
    ./plugins/toggleterm.nix
    ./plugins/mini.nix
    ./plugins/ccc.nix
    ./plugins/neogit.nix
    ./plugins/tmux-navigator.nix
    ./plugins/neo-tree.nix
    ./plugins/barbar.nix
    ./plugins/dashboard.nix
    ./plugins/lualine.nix
    # ./plugins/conform.nix
    # ./plugins/todo-comments.nix

    # NOTE: Add/Configure additional plugins for Kickstart.nixvim
    #
    #  Here are some example plugins that I've included in the Kickstart repository.
    #  Uncomment any of the lines below to enable them (you will need to restart nvim).
    #
    # ./plugins/kickstart/plugins/debug.nix
    # ./plugins/kickstart/plugins/indent-blankline.nix
    # ./plugins/kickstart/plugins/lint.nix
    # ./plugins/kickstart/plugins/autopairs.nix
    #
    # NOTE: Configure your own plugins `see https://nix-community.github.io/nixvim/`
    # Add your plugins to ./plugins/custom/plugins and import them below
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    # colorschemes = {
    # };

    globals = {
      mapleader = " ";  # Set <space> as the leader key
      maplocalleader = " ";
      have_nerd_font = true;
    };

    clipboard = { #  See `:help 'clipboard'`
      providers = {
        wl-copy.enable = true;
        xsel.enable = true;
      };

      register = "unnamedplus"; # Sync clipboard between OS and Neovim
    };

    opts = {
      number = true;
      termguicolors = true;
      mouse = "a";

      # Don't show the mode, since it's already in the statusline
      showmode = false;

      # Enable break indent
      breakindent = true;

      # Save undo history
      undofile = true;

      # Decrease update time
      updatetime = 250;

      # Decrease mapped sequence wait time
      # Displays which-key popup sooner
      timeoutlen = 200;

      # Configure how new splits should be opened
      splitright = true;
      splitbelow = true;

      # Sets how neovim will display certain whitespace characters in the editor
      #  See `:help 'list'`
      #  and `:help 'listchars'`
      list = true;
      # NOTE: .__raw here means that this field is raw lua code
      listchars.__raw = "{ tab = '» ', trail = '·', nbsp = '␣' }";

      # Preview substitutions live, as you type!
      inccommand = "split";

      # Show which line your cursor is on
      cursorline = false;

      # Minimal number of screen lines to keep above and below the cursor.
      scrolloff = 10;

      # if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
      # instead raise a dialog asking if you wish to save the current file(s)
      # See `:help 'confirm'`
      confirm = true;

      # See `:help hlsearch`
      hlsearch = true;
    };

    keymaps = [
      # Clear highlights on search when pressing <Esc> in normal mode
      {
        mode = "n";
        key = "<Esc>";
        action = "<cmd>nohlsearch<CR>";
      }

      {
        mode   = "n";
        key    = "<leader>rr";
        action = "<cmd>lua vim.wo.relativenumber = not vim.wo.relativenumber; vim.wo.number = true<CR>";
        options = {
          desc = "Toggle relative line numbers";
        };
      }

      # Keybinds to make split navigation easier.
      #  Use CTRL+<hjkl> to switch between windows
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-w><C-h>";
        options = {
          desc = "Move focus to the left window";
        };
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-w><C-l>";
        options = {
          desc = "Move focus to the right window";
        };
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-w><C-j>";
        options = {
          desc = "Move focus to the lower window";
        };
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-w><C-k>";
        options = {
          desc = "Move focus to the upper window";
        };
      }
    ];

    plugins = {
      # Adds icons for plugins to utilize in ui
      web-devicons.enable = true;

      # Detect tabstop and shiftwidth automatically
      sleuth = {
        enable = true;
      };
    };

    extraPlugins = with pkgs.vimPlugins; [
      # Useful for getting pretty icons, but requires a Nerd Font.
      nvim-web-devicons
    ];

    extraConfigLuaPre = ''
      if vim.g.have_nerd_font then
        require('nvim-web-devicons').setup {}
      end
      '';

    # The line beneath this is called `modeline`. See `:help modeline`
    # https://nix-community.github.io/nixvim/NeovimOptions/index.html?highlight=extraplugins#extraconfigluapost
    extraConfigLuaPost = ''
      -- vim: ts=2 sts=2 sw=2 et
      '';
  };

  home.packages = with pkgs; [ ripgrep ];
}
