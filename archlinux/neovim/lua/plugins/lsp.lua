return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({
        PATH = "prepend",
      })
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "nil_ls",
          "bashls",
          "omnisharp",
          "cmake",
          "lua_ls",
          "pylsp",
          "clangd",
          "yamlls",
          "jsonls",
          "marksman",
          "sqlls",
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
    config = function()
      local capabilities = require('blink.cmp').get_lsp_capabilities()

      -- Configure servers with custom settings
      vim.lsp.config('cmake', {
        capabilities = capabilities,
      })

      vim.lsp.config('nil_ls', {
        capabilities = capabilities,
      })

      vim.lsp.config('sqlls', {
        capabilities = capabilities,
      })

      vim.lsp.config('bashls', {
        capabilities = capabilities,
      })

      vim.lsp.config('lua_ls', {
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              library = {
                vim.api.nvim_get_runtime_file("", true),
              },
            },
            telemetry = {
              enable = false,
            },
          },
        },
      })

      vim.lsp.config('jsonls', {
        capabilities = capabilities,
      })

      vim.lsp.config('yamlls', {
        capabilities = capabilities,
      })

      vim.lsp.config('clangd', {
        cmd = {
          "clangd",
          "--background-index",
          "--pch-storage=memory",
          "--all-scopes-completion",
          "--pretty",
          "--header-insertion=never",
          "-j=4",
          "--inlay-hints",
          "--header-insertion-decorators",
          "--function-arg-placeholders",
          "--completion-style=detailed",
        },
        filetypes = { "c", "cpp", "objc", "objcpp" },
        root_dir = vim.fs.root(0, { "src" }),
        capabilities = capabilities,
      })

      function get_python_path()
        local venv_path = os.getenv("VIRTUAL_ENV")
        if venv_path then
          return venv_path .. "/bin/python3"
        else
          local os_name = require("utils").get_os()
          if os_name == "windows" then
            return "C:/python312"
          elseif os_name == "linux" then
            return "/usr/bin/python3"
          else
            return "/Library/Frameworks/Python.framework/Versions/3.11/bin/python3"
          end
        end
      end

      vim.lsp.config('pylsp', {
        capabilities = capabilities,
        settings = {
          python = {
            pythonPath = get_python_path(),
          },
        },
      })

      vim.lsp.config('marksman', {
        capabilities = capabilities,
      })

      vim.lsp.config('omnisharp', {
        capabilities = capabilities,
        cmd = { "OmniSharp" },
      })

      -- Enable all configured servers
      vim.lsp.enable({
        'cmake',
        'nil_ls',
        'sqlls',
        'bashls',
        'lua_ls',
        'jsonls',
        'yamlls',
        'clangd',
        'pylsp',
        'marksman',
        'omnisharp',
      })
    end,
  },
}
