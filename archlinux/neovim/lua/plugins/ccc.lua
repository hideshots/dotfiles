return {
  "uga-rosa/ccc.nvim",
  event = "BufRead",
  config = function()
    local ccc = require("ccc")
    
    ccc.setup({
      win_opts = {
        border = "none",
      },
      
      inputs = {
        ccc.input.rgb,
        ccc.input.hsl,
      },
      
      outputs = {
        ccc.output.hex,
        ccc.output.css_rgb,
        ccc.output.css_rgba,
        ccc.output.float,
        ccc.output.hex_short,
      },
      
      virtual_symbol = "  ",
      
      highlighter = {
        auto_enable = true,
      },
      
      convert = {
        { ccc.picker.hex, ccc.output.css_rgb },
        { ccc.picker.css_rgb, ccc.output.css_hsl },
        { ccc.picker.css_hsl, ccc.output.hex },
      },
      
      recognize = {
        input = false,
        output = false,
        pattern = {
          [ccc.picker.css_rgb] = { ccc.input.rgb, ccc.output.css_rgb },
          [ccc.picker.css_name] = { ccc.input.rgb, ccc.output.hex },
          [ccc.picker.hex] = { ccc.input.rgb, ccc.output.hex },
          [ccc.picker.css_hsl] = { ccc.input.hsl, ccc.output.css_hsl },
          [ccc.picker.css_hwb] = { ccc.input.hwb, ccc.output.css_hwb },
          [ccc.picker.css_lab] = { ccc.input.lab, ccc.output.css_lab },
          [ccc.picker.css_lch] = { ccc.input.lch, ccc.output.css_lch },
          [ccc.picker.css_oklab] = { ccc.input.oklab, ccc.output.css_oklab },
          [ccc.picker.css_oklch] = { ccc.input.oklch, ccc.output.css_oklch },
        },
      },
    })
    
    ccc.output.hex.setup({ uppercase = false })
    ccc.output.hex_short.setup({ uppercase = false })
  end,
  
  keys = {
    { "<leader>cp", "<cmd>CccPick<cr>", desc = "Color picker" },
    { "<leader>ch", "<cmd>CccHighlighterToggle<cr>", desc = "Hide Color picker" },
  },
}
