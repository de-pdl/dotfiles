return {
  -- ─── Snippets ────────────────────────────────────────
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = (function()
      if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
        return
      end
      return "make install_jsregexp"
    end)(),
    dependencies = {
      "rafamadriz/friendly-snippets",
      config = function()
        require("luasnip.loaders.from_vscode").lazy_load()
      end,
    },
  },

  -- ─── Completion engine ───────────────────────────────
  {
    "saghen/blink.cmp",
    version = "1.*",
    dependencies = { "L3MON4D3/LuaSnip" },
    event = "InsertEnter",
    opts = {
      keymap = {
        preset = "default",
        -- Overrides on top of the preset:
        ["<CR>"]  = { "accept", "fallback" },
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },
      },

      appearance = {
        nerd_font_variant = "mono",
      },

      completion = {
        accept = { auto_brackets = { enabled = true } },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = { border = "rounded" },
        },
        list = {
          selection = { preselect = false, auto_insert = true },
        },
        menu = {
          border = "rounded",
          draw = {
            columns = {
              { "label", "label_description", gap = 1 },
              { "kind_icon", "kind" },
            },
          },
        },
        ghost_text = { enabled = true },
      },

      signature = {
        enabled = true,
        window = { border = "rounded" },
      },

      snippets = { preset = "luasnip" },

      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },

      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
  },
}
