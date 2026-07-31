-- Understory: dark wood, forest shade, and botanical greens.
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "mocha",
      color_overrides = {
        mocha = {
          rosewater = "#D8D2C4",
          flamingo = "#B5C99A",
          pink = "#A18DA8",
          mauve = "#88768F",
          red = "#B8645B",
          maroon = "#D27A70",
          peach = "#A47B50",
          yellow = "#C59B58",
          green = "#8EAD73",
          teal = "#6E9B85",
          sky = "#82A9AC",
          sapphire = "#668F92",
          blue = "#759A9D",
          lavender = "#9CA58D",
          text = "#D8D2C4",
          subtext1 = "#BDB7AA",
          subtext0 = "#A6A093",
          overlay2 = "#8F9487",
          overlay1 = "#73786C",
          overlay0 = "#5C6257",
          surface2 = "#454A40",
          surface1 = "#363B32",
          surface0 = "#20251D",
          base = "#181B16",
          mantle = "#151712",
          crust = "#11130F",
        },
      },
      custom_highlights = function(colors)
        return {
          CursorLine = { bg = colors.surface0 },
          FloatBorder = { fg = colors.green, bg = colors.mantle },
          Visual = { bg = "#3F5B3A" },
          WinSeparator = { fg = colors.surface2 },
        }
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha",
    },
  },
}
