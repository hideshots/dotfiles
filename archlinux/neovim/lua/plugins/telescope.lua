-- lua/plugins/telescope.lua
return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.8',
  dependencies = { 
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    -- Optional: for better sorting performance
    -- { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  },
  config = function()
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    
    require('telescope').setup({
      -- DEFAULTS (applied to all pickers)
      defaults = {
        -- PROMPT CONFIGURATION
        prompt_prefix = "  ", -- string - Character(s) to show in front of Telescope's prompt
        selection_caret = "➤ ", -- string - Character(s) to show in front of the current selection
        entry_prefix = "  ", -- string - Prefix in front of each result entry
        multi_icon = "+ ", -- string - Character(s) to show in front of a multi-selected result entry
        
        -- INITIAL SETTINGS
        initial_mode = "insert", -- "insert" | "normal" - Which mode telescope starts in
        default_selection_index = nil, -- number | nil - Which result to select by default
        
        -- SORTING & FILTERING
        sorting_strategy = "descending", -- "descending" | "ascending" - Determines the direction "better" results are sorted
        selection_strategy = "reset", -- "reset" | "follow" | "row" | "closest" - How the cursor acts after each sort iteration
        scroll_strategy = "cycle", -- "cycle" | "limit" - What happens if you try to scroll past view of the picker
        
        -- LAYOUT STRATEGY
        layout_strategy = "vertical", -- "horizontal" | "vertical" | "center" | "cursor" | "bottom_pane" | "flex"
        layout_config = {
          horizontal = {
            height = 0.9, -- number 0-1 (percentage of screen) or >1 (fixed lines)
            preview_cutoff = 120, -- number - When columns are less than this, remove preview
            prompt_position = "top", -- "top" | "bottom"
            width = 0.8, -- number 0-1 (percentage of screen) or >1 (fixed columns)
            preview_width = 0.6, -- number 0-1 (percentage of total width) or >1 (fixed columns)
            results_width = 0.8, -- number 0-1 (percentage of total width)
            mirror = false, -- true | false - Flip the location of the results/prompt and preview windows
          },
        },
        
        -- WINDOW OPTIONS
        winblend = 0, -- number 0-100 - Transparency level for popup windows
        wrap_results = false, -- true | false - Wrap long results
        border = {}, -- table | true | false - Border configuration for popup windows
        borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }, -- table - Border characters [top, right, bottom, left, top-left, top-right, bottom-right, bottom-left]
        get_status_text = function(picker) -- function - Custom status text function
          local total = picker.stats.processed or 0
          local selected = #picker:get_multi_selection()
          if selected > 0 then
            return string.format("%d/%d (%d selected)", picker:get_selection_row(), total, selected)
          else
            return string.format("%d/%d", picker:get_selection_row(), total)
          end
        end,
        results_title = "Results", -- string | false - Title for results window
        prompt_title = "Prompt", -- string | false - Title for prompt window
        preview_title = "Preview", -- string | false - Title for preview window
        dynamic_preview_title = false, -- true | false - Show filename as preview title
        
        -- PREVIEW OPTIONS
        preview = {
          check_mime_type = true, -- true | false - Check if file is binary before preview
          timeout = 250, -- number - Timeout for preview in milliseconds
          treesitter = true, -- true | false - Use treesitter for syntax highlighting in preview
          msg_bg_fillchar = "╱", -- string - Character to fill preview background when no preview
          hide_on_startup = false, -- true | false - Hide preview window on startup
          filetype_hook = function(filepath, bufnr, opts) -- function - Custom filetype detection
            -- You can set custom filetype or buffer options here
            local ft = vim.filetype.match({ filename = filepath, buf = bufnr })
            vim.bo[bufnr].filetype = ft or ""
          end,
        },
        
        -- HISTORY
        history = {
          path = '~/.local/share/nvim/databases/telescope_history.sqlite3', -- string - Path to history database
          limit = 100, -- number - Max number of entries in history per picker
        },
        
        -- FILE HANDLING
        file_ignore_patterns = { -- table - Lua regex patterns to ignore files/directories
          "node_modules",
          ".git/",
          "%.jpg",
          "%.jpeg", 
          "%.png",
          "%.pdf",
          "%.zip",
          "%.tar.gz",
          "__pycache__",
          "%.pyc",
          "%.class",
          "%.o",
          "%.so",
          "%.dylib",
          "%.dll"
        },
        -- Path display options: table | function | "hidden" | "tail" | "absolute" | "smart" | "shorten" | "truncate" | "filename_first"
        path_display = { "truncate" }, -- Can be: { "truncate", 3 } for truncate after 3 dirs, or { shorten = { len = 1, exclude = {1, -1} } }
        hidden = false, -- true | false - Show hidden files and directories
        respect_gitignore = true, -- true | false - Respect .gitignore files when searching
        follow_symlinks = false, -- true | false - Follow symbolic links when searching
        
        -- SEARCH OPTIONS
        case_sensitive = false, -- true | false - Case sensitive search
        use_regex = false, -- true | false - Use regex patterns in search by default
        
        -- CACHING
        cache_picker = {
          num_pickers = -1, -- number - Number of pickers to cache (-1 for unlimited)
          limit_entries = 1000, -- number - Max entries to cache per picker
        },
        
        -- RESULT BUFFER OPTIONS
        buffer_previewer_maker = require'telescope.previewers'.buffer_previewer_maker, -- function - Custom buffer previewer function
        
        -- GREP OPTIONS
        vimgrep_arguments = { -- table - Arguments passed to grep command
          "rg", -- ripgrep executable
          "--color=never", -- Don't colorize output
          "--no-heading", -- Don't group matches by each file
          "--with-filename", -- Print the file path with the matched lines
          "--line-number", -- Show line numbers
          "--column", -- Show column numbers
          "--smart-case" -- Smart case matching
        },
        
        -- GENERIC SORTER
        generic_sorter = require'telescope.sorters'.get_generic_fuzzy_sorter, -- function - Default sorter for non-files
        file_sorter = require'telescope.sorters'.get_fuzzy_file, -- function - Default file sorter
        
        -- PREVIEWERS
        grep_previewer = require'telescope.previewers'.vim_buffer_vimgrep.new, -- function - Grep result previewer
        qflist_previewer = require'telescope.previewers'.vim_buffer_qflist.new, -- function - Quickfix list previewer  
        file_previewer = require'telescope.previewers'.vim_buffer_cat.new, -- function - File content previewer
        
        -- MAPPINGS
        mappings = {
          i = { -- Insert mode mappings
            ["<C-n>"] = actions.move_selection_next, -- Move to next result
            ["<C-p>"] = actions.move_selection_previous, -- Move to previous result
            ["<C-j>"] = actions.move_selection_next, -- Move to next result
            ["<C-k>"] = actions.move_selection_previous, -- Move to previous result
            ["<C-c>"] = actions.close, -- Close telescope
            ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist, -- Send to quickfix and open
            ["<C-s>"] = actions.select_horizontal, -- Open in horizontal split
            ["<C-v>"] = actions.select_vertical, -- Open in vertical split
            ["<C-t>"] = actions.select_tab, -- Open in new tab
            ["<C-u>"] = actions.preview_scrolling_up, -- Scroll preview up
            ["<C-d>"] = actions.preview_scrolling_down, -- Scroll preview down
            ["<C-f>"] = actions.preview_scrolling_down, -- Scroll preview down
            ["<C-b>"] = actions.preview_scrolling_up, -- Scroll preview up
            ["<C-l>"] = actions.complete_tag, -- Complete tag under cursor
            ["<C-_>"] = actions.which_key, -- Show which_key help (<C-/> in terminal)
            ["<C-w>"] = { "<c-s-w>", type = "command" }, -- Delete word backward
            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse, -- Toggle selection and move
            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better, -- Toggle selection and move
            ["<CR>"] = actions.select_default, -- Select entry
            ["<A-q>"] = actions.send_selected_to_qflist + actions.open_qflist, -- Send selected to quickfix
            ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist, -- Send selected to quickfix
            ["<C-/>"] = actions.which_key, -- Show help
            
            -- Custom actions can be defined like this:
            -- ["<C-e>"] = function(prompt_bufnr)
            --   local selection = action_state.get_selected_entry()
            --   actions.close(prompt_bufnr)
            --   vim.cmd("edit " .. selection.path)
            -- end,
          },
          n = { -- Normal mode mappings  
            ["<esc>"] = actions.close, -- Close telescope
            ["<CR>"] = actions.select_default, -- Select entry
            ["<C-x>"] = actions.select_horizontal, -- Open in horizontal split
            ["<C-v>"] = actions.select_vertical, -- Open in vertical split
            ["<C-t>"] = actions.select_tab, -- Open in new tab
            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse, -- Toggle selection and move
            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better, -- Toggle selection and move
            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist, -- Send all to quickfix and open
            ["j"] = actions.move_selection_next, -- Move to next result
            ["k"] = actions.move_selection_previous, -- Move to previous result
            ["H"] = actions.move_to_top, -- Move to first result
            ["M"] = actions.move_to_middle, -- Move to middle result
            ["L"] = actions.move_to_bottom, -- Move to last result
            ["<Down>"] = actions.move_selection_next, -- Move to next result
            ["<Up>"] = actions.move_selection_previous, -- Move to previous result
            ["gg"] = actions.move_to_top, -- Move to first result
            ["G"] = actions.move_to_bottom, -- Move to last result
            ["<C-u>"] = actions.preview_scrolling_up, -- Scroll preview up
            ["<C-d>"] = actions.preview_scrolling_down, -- Scroll preview down
            ["<C-f>"] = actions.preview_scrolling_down, -- Scroll preview down
            ["<C-b>"] = actions.preview_scrolling_up, -- Scroll preview up
            ["?"] = actions.which_key, -- Show help
            ["<A-q>"] = actions.send_selected_to_qflist + actions.open_qflist, -- Send selected to quickfix
            ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist, -- Send selected to quickfix
            ["<C-a>"] = actions.toggle_all, -- Toggle all selections
          }
        },
        
        -- TRANSFORM OPTIONS
        transform_mod = "", -- string - Transform module (rarely used)
        
        -- COLOR OPTIONS
        color_devicons = true, -- true | false - Use colored devicons in results
        
        -- PERFORMANCE OPTIONS
        get_selection_window = function() -- function - Window to return to after selection
          local wins = vim.api.nvim_list_wins()
          table.insert(wins, 1, vim.api.nvim_get_current_win())
          for _, win in ipairs(wins) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].buftype == "" then
              return win
            end
          end
          return 0
        end,
        
        -- ENVIRONMENT VARIABLES
        set_env = { ['COLORTERM'] = 'truecolor' }, -- table - Environment variables to set
        
        -- PICKER SPECIFIC DEFAULTS (can be overridden in pickers section)
        show_line = true, -- true | false - Show line numbers in preview
        trim_text = false, -- true | false - Trim whitespace from results
        results_width = 0.8, -- number - Width of results window (0-1 for percentage)
        preview_width = 0.6, -- number - Width of preview window (0-1 for percentage)
        results_height = 0.8, -- number - Height of results window (0-1 for percentage) 
        preview_height = 0.5, -- number - Height of preview window (0-1 for percentage)
        
        -- TIEBREAK FUNCTION
        tiebreak = function(current_entry, existing_entry, prompt) -- function - Custom tiebreak function
          return false -- Return true if current_entry should be preferred over existing_entry
        end,
        
        -- ON_COMPLETE CALLBACK
        on_complete = { -- table - Functions to call when picker is complete
          function(picker)
            -- Custom completion logic here
          end
        }
      },
      
      -- PICKERS (individual builtin picker configurations)
      pickers = {
        -- FILE PICKERS
        find_files = {
          theme = "dropdown", -- "dropdown" | "cursor" | "ivy" - Predefined theme
          previewer = false, -- true | false - Show preview window
          hidden = true, -- true | false - Show hidden files
          no_ignore = false, -- true | false - Don't respect .gitignore/.ignore files
          no_ignore_parent = false, -- true | false - Don't respect parent .gitignore/.ignore files
          follow = false, -- true | false - Follow symbolic links
          find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" }, -- table - Custom find command
          search_dirs = {}, -- table - Directories to search in (empty = current working directory)
          search_file = "", -- string - Specific file to search for
          cwd = nil, -- string - Change working directory for this picker
          attach_mappings = function(prompt_bufnr, map) -- function - Custom key mappings for this picker
            -- Custom mappings here
            return true -- Return false to replace default mappings, true to extend them
          end,
        },
        
        git_files = {
          theme = "dropdown", -- "dropdown" | "cursor" | "ivy"
          previewer = false, -- true | false - Show preview window
          show_untracked = true, -- true | false - Show untracked files
          recurse_submodules = false, -- true | false - Include submodules
          git_command = { "git", "ls-files", "--exclude-standard", "--cached", "--others" }, -- table - Custom git command
          cwd = nil, -- string - Git repository directory
        },
        
        grep_string = {
          only_sort_text = true, -- true | false - Only sort the text part, ignore file paths
          word_match = "-w", -- string - Word match option for rg
          short_path = true, -- true | false - Show short file paths
          search_dirs = {}, -- table - Directories to search in
          use_regex = true, -- true | false - Use regex in search
          case_sensitive = false, -- true | false - Case sensitive search
          additional_args = function() return {} end, -- function - Additional arguments to pass to rg
          max_results = 1000, -- number - Maximum number of results
          search = "", -- string - Initial search string
          prompt_title = "Grep String", -- string - Title for the prompt window
        },
        
        live_grep = {
          only_sort_text = true, -- true | false - Only sort the text part, ignore file paths
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
          search_dirs = {}, -- table - Directories to search in
          glob_pattern = {}, -- table - Glob patterns to include/exclude files
          type_filter = nil, -- string - File type filter (e.g., "py", "js")
          max_results = 1000, -- number - Maximum number of results
          disable_devicons = false, -- true | false - Disable file icons
          additional_args = function() return {} end, -- function - Additional arguments to pass to rg
          -- Custom grep command (overrides vimgrep_arguments from defaults)
          -- grep_command = "rg", -- string - Grep executable
          -- grep_arguments = { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case" },
        },
        
        -- LSP PICKERS
        lsp_references = { 
          theme = "cursor", -- "dropdown" | "cursor" | "ivy"
          initial_mode = "normal", -- "insert" | "normal"
          include_declaration = true, -- true | false - Include declaration in results
          include_current_line = false, -- true | false - Include current line in results
          show_line = true, -- true | false - Show line content in results
          trim_text = true, -- true | false - Trim whitespace from results
          fname_width = 50, -- number - Width of filename column
          reuse_win = false, -- true | false - Reuse existing window for results
        },
        
        lsp_definitions = {
          theme = "cursor", -- "dropdown" | "cursor" | "ivy"
          initial_mode = "normal", -- "insert" | "normal"
          reuse_win = false, -- true | false - Reuse existing window for results
          show_line = true, -- true | false - Show line content in results
        },
        
        lsp_type_definitions = {
          theme = "cursor", -- "dropdown" | "cursor" | "ivy"
          initial_mode = "normal", -- "insert" | "normal"
          reuse_win = false, -- true | false - Reuse existing window for results
        },
        
        lsp_implementations = {
          theme = "cursor", -- "dropdown" | "cursor" | "ivy"
          initial_mode = "normal", -- "insert" | "normal"
          reuse_win = false, -- true | false - Reuse existing window for results
        },
        
        lsp_document_symbols = {
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
          symbol_width = 40, -- number - Width of symbol name column
          symbol_type_width = 12, -- number - Width of symbol type column
          fname_width = 50, -- number - Width of filename column (for workspace symbols)
          show_line = true, -- true | false - Show line numbers
        },
        
        lsp_workspace_symbols = {
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
          symbol_width = 40, -- number - Width of symbol name column  
          symbol_type_width = 12, -- number - Width of symbol type column
          fname_width = 50, -- number - Width of filename column
          query = "", -- string - Initial query (empty = prompt user)
        },
        
        lsp_dynamic_workspace_symbols = {
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
          symbol_width = 40, -- number - Width of symbol name column
          symbol_type_width = 12, -- number - Width of symbol type column
          fname_width = 50, -- number - Width of filename column
        },
        
        diagnostics = {
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
          bufnr = 0, -- number | nil - Buffer number (0 for current buffer, nil for all buffers)
          line_width = "full", -- "full" | number - Width of line column
          root_dir = nil, -- string | nil - Root directory for workspace diagnostics
          wrap_results = true, -- true | false - Wrap long diagnostic messages
          severity_limit = nil, -- number | nil - Only show diagnostics of this severity or higher
          severity_bound = nil, -- number | nil - Only show diagnostics below this severity
          disable_coordinates = false, -- true | false - Don't show line:col coordinates
        },
        
        -- BUFFER PICKERS
        buffers = {
          theme = "dropdown", -- "dropdown" | "cursor" | "ivy"
          previewer = false, -- true | false - Show preview window
          initial_mode = "normal", -- "insert" | "normal"
          mappings = {
            i = {
              ["<C-d>"] = actions.delete_buffer, -- Delete buffer in insert mode
            },
            n = {
              ["dd"] = actions.delete_buffer, -- Delete buffer in normal mode
            }
          },
          sort_lastused = true, -- true | false - Sort by last used time
          sort_mru = true, -- true | false - Sort by most recently used
          show_all_buffers = true, -- true | false - Show all buffers including unlisted ones
          ignore_current_buffer = false, -- true | false - Ignore current buffer in results
          only_cwd = false, -- true | false - Only show buffers from current working directory
          cwd_only = false, -- true | false - Alias for only_cwd
          attach_mappings = function(prompt_bufnr, map) -- function - Custom mappings
            local delete_buf = function()
              local selection = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              vim.api.nvim_buf_delete(selection.bufnr, { force = false })
            end
            map("i", "<c-d>", delete_buf)
            map("n", "dd", delete_buf)
            return true
          end,
        },
        
        -- VIM PICKERS
        oldfiles = {
          theme = "dropdown", -- "dropdown" | "cursor" | "ivy"
          previewer = false, -- true | false - Show preview window
          only_cwd = false, -- true | false - Only show files from current working directory
          include_current_session = false, -- true | false - Include files from current session
          cwd_only = false, -- true | false - Alias for only_cwd
          tiebreak = function(entry1, entry2) -- function - Custom tiebreak function
            return entry1.index < entry2.index
          end,
        },
        
        command_history = {
          theme = "dropdown", -- "dropdown" | "cursor" | "ivy"
          previewer = false, -- true | false - Show preview window
        },
        
        search_history = {
          theme = "dropdown", -- "dropdown" | "cursor" | "ivy"
          previewer = false, -- true | false - Show preview window
        },
        
        help_tags = {
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
          previewer = true, -- true | false - Show preview window
          lang = "en", -- string - Language for help tags
          fallback = true, -- true | false - Fallback to default language
        },
        
        man_pages = {
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
          sections = {"ALL"}, -- table - Manual sections to show (e.g., {"1", "8"})
        },
        
        marks = {
          theme = "dropdown", -- "dropdown" | "cursor" | "ivy"
          previewer = false, -- true | false - Show preview window
          mark_type = "all", -- "all" | "global" | "local" - Types of marks to show
        },
        
        registers = {
          theme = "cursor", -- "dropdown" | "cursor" | "ivy"
          previewer = false, -- true | false - Show preview window
        },
        
        keymaps = {
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
          lhs_filter = function(lhs) -- function - Filter for left-hand side of mappings
            return not string.find(lhs, "Þ") 
          end,
          layout_config = {
            width = 0.6, -- number - Width of picker
            height = 0.6, -- number - Height of picker
          },
          modes = {"n", "i", "c"}, -- table - Which modes to show mappings for
          show_plug = true, -- true | false - Show <Plug> mappings
          only_buf = false, -- true | false - Only show buffer-local mappings
        },
        
        filetypes = {
          theme = "dropdown", -- "dropdown" | "cursor" | "ivy"
          previewer = false, -- true | false - Show preview window
        },
        
        highlights = {
          theme = "dropdown", -- "dropdown" | "cursor" | "ivy"
          previewer = false, -- true | false - Show preview window
        },
        
        autocommands = {
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
        },
        
        spell_suggest = {
          theme = "cursor", -- "dropdown" | "cursor" | "ivy"
          previewer = false, -- true | false - Show preview window
        },
        
        tags = {
          only_sort_tags = true, -- true | false - Only sort tags, not files
          only_current_buffer = false, -- true | false - Only show tags from current buffer
          fname_width = 100, -- number - Width of filename column
        },
        
        current_buffer_tags = {
          only_sort_tags = true, -- true | false - Only sort tags, not files
          fname_width = 100, -- number - Width of filename column
        },
        
        -- GIT PICKERS
        git_commits = {
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
          git_command = { "git", "log", "--pretty=oneline", "--abbrev-commit", "--", "." }, -- table - Custom git command
        },
        
        git_bcommits = {
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
          git_command = { "git", "log", "--pretty=oneline", "--abbrev-commit" }, -- table - Custom git command
        },
        
        git_bcommits_range = {
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
          git_command = { "git", "log", "--pretty=oneline", "--abbrev-commit" }, -- table - Custom git command
        },
        
        git_branches = {
          theme = "dropdown", -- "dropdown" | "cursor" | "ivy"
          previewer = false, -- true | false - Show preview window
          show_remote_tracking_branches = true, -- true | false - Show remote tracking branches
          pattern = "", -- string - Pattern to filter branches
        },
        
        git_status = {
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
          git_icons = { -- table - Git status icons
            added     = " ", -- string - Added files icon
            changed   = " ", -- string - Changed files icon
            copied    = " ", -- string - Copied files icon
            deleted   = " ", -- string - Deleted files icon
            renamed   = "➡ ", -- string - Renamed files icon
            unmerged  = " ", -- string - Unmerged files icon
            untracked = " ", -- string - Untracked files icon
          },
          expand_dir = true, -- true | false - Expand directories to show individual files
          git_command = { "git", "status", "--porcelain", "--untracked-files" }, -- table - Custom git command
        },
        
        git_stash = {
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
          git_command = { "git", "stash", "list" }, -- table - Custom git command
        },
        
        -- TREESITTER PICKER
        treesitter = {
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
          show_line = true, -- true | false - Show line numbers
          symbol_width = 25, -- number - Width of symbol column
          symbol_type_width = 8, -- number - Width of symbol type column
        },
        
        -- BUILTIN PICKERS LIST
        builtin = {
          theme = "dropdown", -- "dropdown" | "cursor" | "ivy"
          previewer = false, -- true | false - Show preview window
          include_extensions = true, -- true | false - Include extensions in builtin list  
        },
        
        planets = {
          show_pluto = true, -- true | false - Show Pluto (Easter egg)
          show_moon = true, -- true | false - Show Moon (Easter egg)
        },
        
        reloader = {
          theme = "dropdown", -- "dropdown" | "cursor" | "ivy"
          previewer = false, -- true | false - Show preview window
        },
        
        resume = {
          theme = "dropdown", -- "dropdown" | "cursor" | "ivy"
          previewer = false, -- true | false - Show preview window
        },
        
        pickers = {
          theme = "dropdown", -- "dropdown" | "cursor" | "ivy"
          previewer = false, -- true | false - Show preview window
        },
        
        -- QUICKFIX / LOCATION LIST
        quickfix = {
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
          trim_text = true, -- true | false - Trim whitespace from entries
          show_line = true, -- true | false - Show line numbers
        },
        
        quickfixhistory = {
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
          trim_text = true, -- true | false - Trim whitespace from entries
        },
        
        loclist = {
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
          trim_text = true, -- true | false - Trim whitespace from entries
          show_line = true, -- true | false - Show line numbers
        },
        
        jumplist = {
          theme = "dropdown", -- "dropdown" | "cursor" | "ivy"
          previewer = false, -- true | false - Show preview window
        },
        
        vim_options = {
          theme = "dropdown", -- "dropdown" | "cursor" | "ivy"
          previewer = false, -- true | false - Show preview window
        },
        
        colorscheme = {
          theme = "dropdown", -- "dropdown" | "cursor" | "ivy"
          previewer = false, -- true | false - Show preview window
          enable_preview = true, -- true | false - Show colorscheme preview
        },
        
        commands = {
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
        },
        
        current_buffer_fuzzy_find = {
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
          previewer = false, -- true | false - Show preview window
          skip_empty_lines = false, -- true | false - Skip empty lines in results
        },
      },
      
      -- EXTENSIONS
      extensions = {
        -- FZF extension configuration (if using telescope-fzf-native.nvim)
        fzf = {
          fuzzy = true, -- true | false - Enable fuzzy matching
          override_generic_sorter = true, -- true | false - Override generic sorter with fzf
          override_file_sorter = true, -- true | false - Override file sorter with fzf  
          case_mode = "smart_case", -- "smart_case" | "ignore_case" | "respect_case" - Case sensitivity
        },
        
        -- UI-Select extension configuration (if using telescope-ui-select.nvim)
        ['ui-select'] = {
          theme = "dropdown", -- "dropdown" | "cursor" | "ivy"
          specific_opts = {
            codeactions = false, -- true | false - Use telescope for LSP code actions
            lsp_definitions = false, -- true | false - Use telescope for LSP definitions
            lsp_references = false, -- true | false - Use telescope for LSP references
            lsp_implementations = false, -- true | false - Use telescope for LSP implementations
          }
        },
        
        -- File browser extension configuration (if using telescope-file-browser.nvim)
        file_browser = {
          theme = "ivy", -- "dropdown" | "cursor" | "ivy"
          hijack_netrw = true, -- true | false - Replace netrw with telescope file browser
          mappings = {
            ["i"] = {
              ["<A-c>"] = false, -- Disable default create file/folder mapping
              ["<S-CR>"] = false, -- Disable default create file mapping
            },
            ["n"] = {
              ["c"] = false, -- Disable default create file/folder mapping
              ["%"] = false, -- Disable default create file mapping
              ["d"] = false, -- Disable default delete mapping
            },
          },
          grouped = true, -- true | false - Group directories before files
          files = true, -- true | false - Show files
          add_dirs = true, -- true | false - Show directories
          depth = 1, -- number | false - Depth to show subdirectories (false for unlimited)
          auto_depth = false, -- true | false - Automatically adjust depth
          select_buffer = false, -- true | false - Select buffer instead of file
          hidden = { file_browser = false, folder_browser = false }, -- table - Show hidden files/folders
          respect_gitignore = vim.fn.executable "fd" == 1, -- true | false - Respect .gitignore files
          no_ignore = false, -- true | false - Don't use .ignore files
          follow_symlinks = false, -- true | false - Follow symbolic links
          hide_parent_dir = false, -- true | false - Hide parent directory (..)
          collapse_dirs = false, -- true | false - Collapse single-child directories
          prompt_path = false, -- true | false - Show path in prompt
          quiet = false, -- true | false - Suppress error messages
          dir_icon = "", -- string - Directory icon
          dir_icon_hl = "Default", -- string - Directory icon highlight group
          display_stat = { date = true, size = true, mode = true }, -- table - Show file statistics
          use_fd = true, -- true | false - Use fd command if available
          git_status = true, -- true | false - Show git status
          path = vim.loop.cwd(), -- string - Starting path
          cwd = vim.fn.expand('%:p:h'), -- string - Current working directory
        },
      }
    })
    
    -- Load extensions (uncomment as needed)
    -- require('telescope').load_extension('fzf')
    -- require('telescope').load_extension('file_browser')
    -- require('telescope').load_extension('ui-select')
  end,
  
  keys = {
    -- File pickers
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
    { "<leader>fo", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
    { "<leader>fc", "<cmd>Telescope command_history<cr>", desc = "Command history" },
    { "<leader>fs", "<cmd>Telescope search_history<cr>", desc = "Search history" },
    
    -- Git pickers
    { "<leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Git commits" },
    { "<leader>gb", "<cmd>Telescope git_branches<cr>", desc = "Git branches" },
    { "<leader>gs", "<cmd>Telescope git_status<cr>", desc = "Git status" },
    
    -- LSP pickers  
    { "gr", "<cmd>Telescope lsp_references<cr>", desc = "LSP references" },
    { "gd", "<cmd>Telescope lsp_definitions<cr>", desc = "LSP definitions" },
    { "gi", "<cmd>Telescope lsp_implementations<cr>", desc = "LSP implementations" },
    { "<leader>ds", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document symbols" },
    { "<leader>ws", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "Workspace symbols" },
    
    -- Other pickers
    { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
    { "<leader>ft", "<cmd>Telescope filetypes<cr>", desc = "Filetypes" },
    { "<leader>fr", "<cmd>Telescope registers<cr>", desc = "Registers" },
    { "<leader>fm", "<cmd>Telescope marks<cr>", desc = "Marks" },
    { "<leader>fp", "<cmd>Telescope builtin<cr>", desc = "Telescope builtin" },
    { "<leader>fR", "<cmd>Telescope resume<cr>", desc = "Resume last picker" },
  },
}
