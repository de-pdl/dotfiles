return {
  -- ─── Autopairs ───────────────────────────────────────
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = true,           -- use treesitter to avoid pairing in strings/comments
      ts_config = {
        lua = { "string" },
        c   = { "string" },
        cpp = { "string" },
      },
      fast_wrap = {},            -- <M-e> to wrap next object in pair
    },
  },

  -- ─── Comment.nvim ────────────────────────────────────
  {
    "numToStr/Comment.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
    -- Default mappings:
    --   gcc   toggle line comment
    --   gbc   toggle block comment
    --   gc    (visual) toggle selection
    --   gc{motion}  e.g. gcap = comment paragraph
  },

  -- ─── nvim-surround ───────────────────────────────────
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
    -- Default mappings:
    --   ys{motion}{char}   add surround, e.g. ysiw"  → "word"
    --   cs{old}{new}       change surround, e.g. cs"'  → swap " to '
    --   ds{char}           delete surround, e.g. ds"  → remove quotes
    --   S{char} (visual)   wrap selection
  },
}
