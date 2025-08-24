-- lua/plugins/barbar.lua
return {
  'romgrk/barbar.nvim',
  dependencies = {
    'lewis6991/gitsigns.nvim', -- OPTIONAL: for git status
    'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
  },
  init = function() 
    vim.g.barbar_auto_setup = true
  end,
  opts = {
    -- ANIMATION
    animation = true, -- true | false - Enable/disable animations
    
    -- AUTO HIDE
    auto_hide = false, -- false | number - Automatically hide tabline when there are this many buffers left (set to >=0 to enable)
    
    -- TABPAGES INDICATOR  
    tabpages = true, -- true | false - Enable/disable current/total tabpages indicator (top right corner)
    
    -- CLICKABLE TABS
    clickable = true, -- true | false - left-click: go to buffer, middle-click: delete buffer
    
    -- FOCUS ON CLOSE
    focus_on_close = 'left', -- 'left' | 'previous' | 'right' - Direction to focus when closing current buffer
    
    -- HIDE OPTIONS
    hide = {
      extensions = true, -- true | false - Hide file extensions
      inactive = true, -- true | false - Hide inactive buffers (other options: 'alternate', 'current', 'visible')
    },
    
    -- HIGHLIGHTING
    highlight_alternate = false, -- true | false - Disable highlighting alternate buffers
    highlight_inactive_file_icons = false, -- true | false - Disable highlighting file icons in inactive buffers
    highlight_visible = true, -- true | false - Enable highlighting visible buffers
    
    -- ICONS CONFIGURATION
    icons = {
      -- BASE ICONS
      buffer_index = false, -- false | true | 'superscript' | 'subscript' - Display buffer index
      buffer_number = false, -- false | true | 'superscript' | 'subscript' - Display buffer number
      button = '', -- string - Close button character
      
      -- DIAGNOSTICS
      diagnostics = {
        [vim.diagnostic.severity.ERROR] = {enabled = true, icon = 'ﬀ'},
        [vim.diagnostic.severity.WARN] = {enabled = false, icon = '⚠'}, 
        [vim.diagnostic.severity.INFO] = {enabled = false, icon = 'ℹ'},
        [vim.diagnostic.severity.HINT] = {enabled = true, icon = '💡'},
      },
      
      -- GIT SIGNS
      gitsigns = {
        added = {enabled = true, icon = '+'},
        changed = {enabled = true, icon = '~'},
        deleted = {enabled = true, icon = '-'},
      },
      
      -- FILETYPE
      filetype = {
        custom_colors = false, -- true | false - Use custom colors or nvim-web-devicons colors
        enabled = true, -- true | false - Requires nvim-web-devicons
      },
      
      -- SEPARATORS
      separator = {left = '▎', right = ''}, -- {left: string, right: string} - Buffer separators
      separator_at_end = true, -- true | false - Add separator at end of buffer list
      
      -- MODIFIED/PINNED
      modified = {button = '●'}, -- Modified buffer indicator
      pinned = {button = '', filename = true}, -- Pinned buffer indicator
      
      -- PRESET STYLES
      preset = 'default', -- 'default' | 'powerline' | 'slanted' - Preconfigured appearance
      
      -- VISIBILITY-BASED ICONS
      alternate = {filetype = {enabled = false}}, -- Icons for alternate buffers
      current = {buffer_index = true}, -- Icons for current buffer  
      inactive = {button = '×'}, -- Icons for inactive buffers
      visible = {modified = {buffer_number = false}}, -- Icons for visible buffers
    },
    
    -- INSERTION POSITION
    insert_at_end = false, -- true | false - Insert new buffers at end
    insert_at_start = false, -- true | false - Insert new buffers at start (default: after current)
    
    -- PADDING
    maximum_padding = 1, -- number - Maximum padding width around each tab
    minimum_padding = 1, -- number - Minimum padding width around each tab
    
    -- BUFFER NAME LENGTH
    maximum_length = 30, -- number - Maximum buffer name length
    minimum_length = 0, -- number - Minimum buffer name length
    
    -- SEMANTIC LETTERS
    semantic_letters = true, -- true | false - Assign letters based on buffer name vs usability order
    
    -- SIDEBAR INTEGRATION
    sidebar_filetypes = {
      -- Simple enable
      NvimTree = false,
      
      -- Custom text
      undotree = {
        text = 'undotree',
        align = 'center', -- 'left' | 'center' | 'right'
      },
      
      -- Custom event
      ['neo-tree'] = {event = 'BufWipeout'},
      
      -- All options
      Outline = {
        event = 'BufWinLeave', 
        text = 'symbols-outline', 
        align = 'right'
      },
    },
    
    -- JUMP-TO-BUFFER LETTERS
    letters = 'asdfjkl;ghnmxcvbziowerutyqpASDFJKLGHNMXCVBZIOWERUTYQP', -- string - Letter assignment order
    
    -- UNNAMED BUFFERS
    no_name_title = nil, -- string | nil - Name for unnamed buffers (default: "[Buffer X]")
    
    -- SORTING
    sort = {
      ignore_case = true, -- true | false - Ignore case when sorting buffers
    },
  },
  
  -- KEYMAPS (recommended)
  keys = {
    -- Navigation
    { '<A-,>', '<Cmd>BufferPrevious<CR>', desc = 'Previous buffer' },
    { '<A-.>', '<Cmd>BufferNext<CR>', desc = 'Next buffer' },
    
    -- Reordering  
    { '<A-<>', '<Cmd>BufferMovePrevious<CR>', desc = 'Move buffer left' },
    { '<A->>', '<Cmd>BufferMoveNext<CR>', desc = 'Move buffer right' },
    
    -- Go to buffer by position
    { '<A-1>', '<Cmd>BufferGoto 1<CR>', desc = 'Go to buffer 1' },
    { '<A-2>', '<Cmd>BufferGoto 2<CR>', desc = 'Go to buffer 2' },
    { '<A-3>', '<Cmd>BufferGoto 3<CR>', desc = 'Go to buffer 3' },
    { '<A-4>', '<Cmd>BufferGoto 4<CR>', desc = 'Go to buffer 4' },
    { '<A-5>', '<Cmd>BufferGoto 5<CR>', desc = 'Go to buffer 5' },
    { '<A-6>', '<Cmd>BufferGoto 6<CR>', desc = 'Go to buffer 6' },
    { '<A-7>', '<Cmd>BufferGoto 7<CR>', desc = 'Go to buffer 7' },
    { '<A-8>', '<Cmd>BufferGoto 8<CR>', desc = 'Go to buffer 8' },
    { '<A-9>', '<Cmd>BufferGoto 9<CR>', desc = 'Go to buffer 9' },
    { '<A-0>', '<Cmd>BufferLast<CR>', desc = 'Go to last buffer' },
    
    -- Pin/unpin
    { '<A-p>', '<Cmd>BufferPin<CR>', desc = 'Pin/unpin buffer' },
    
    -- Close/restore
    { '<A-c>', '<Cmd>BufferClose<CR>', desc = 'Close buffer' },
    { '<A-S-c>', '<Cmd>BufferRestore<CR>', desc = 'Restore buffer' },
    
    -- Buffer picking
    { '<C-p>', '<Cmd>BufferPick<CR>', desc = 'Pick buffer' },
    { '<C-S-p>', '<Cmd>BufferPickDelete<CR>', desc = 'Pick buffer to delete' },
    
    -- Sorting
    { '<leader>bb', '<Cmd>BufferOrderByBufferNumber<CR>', desc = 'Sort by buffer number' },
    { '<leader>bn', '<Cmd>BufferOrderByName<CR>', desc = 'Sort by name' },
    { '<leader>bd', '<Cmd>BufferOrderByDirectory<CR>', desc = 'Sort by directory' },
    { '<leader>bl', '<Cmd>BufferOrderByLanguage<CR>', desc = 'Sort by language' },
    { '<leader>bw', '<Cmd>BufferOrderByWindowNumber<CR>', desc = 'Sort by window number' },
  },
}
