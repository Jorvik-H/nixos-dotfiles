return {
 

  {
    "neanias/everforest-nvim",
    name = "everforest",
    lazy = false,
    priority = 1000,
    config = function()
        --vim.o.background=light
      require("everforest").setup({
        transparent_background_level = 2,
        background = "soft",
      })

      vim.cmd([[colorscheme everforest]])
    end,
  },
}
