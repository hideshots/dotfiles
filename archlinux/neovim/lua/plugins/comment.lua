return {
  'numToStr/Comment.nvim',
  lazy = false,
  config = function()
    require('Comment').setup({
      padding = true,
      sticky = true,
      ignore = nil,
      mappings = {
        basic = false,
        extra = false,
      },
    })
    local api = require('Comment.api')
    
    vim.keymap.set('n', '<leader>/', api.toggle.linewise.current, { 
      desc = 'Toggle comment on current line',
      silent = true 
    })
    
    vim.keymap.set('x', '<leader>/', function()
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes('<ESC>', true, false, true), 
        'nx', 
        false
      )
      api.toggle.linewise(vim.fn.visualmode())
    end, { 
      desc = 'Toggle line comment on selected lines',
      silent = true 
    })
  end
}
