return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- In 2026, 'main' is the default branch and uses a new API
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")

      -- 1. Install your preferred parsers
      ts.install({ "c", "html", "css", "bash", "markdown", "lua" })

      -- 2. Modern way to enable Highlighting & Indent (Nvim 0.11+ style)
      vim.api.nvim_create_autocmd("FileType", {
        -- Enable for the languages you specifically want
        pattern = { "c", "html", "css", "bash", "markdown", "lua" },
        callback = function()
          vim.treesitter.start() -- Native Nvim highlighting
        end,
      })

      -- Optional: Enable Treesitter-based indentation
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "c", "html", "css", "bash", "markdown", "lua" },
        callback = function()
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  -- LSP CONFIG (Updated for Nvim 0.11+)
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "clangd", "html", "cssls", "bashls" },
      })

      local servers = { "clangd", "html", "cssls", "bashls" }
      for _, lsp in ipairs(servers) do
        vim.lsp.config(lsp, {}) 
        vim.lsp.enable(lsp)
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local opts = { buffer = args.buf }
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        end,
      })
    end,
  }
}
