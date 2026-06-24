-- Servers to ensure installed via Mason.
-- Hardware-focused additions: clangd (C/C++), and we'll add HDL servers in Phase 9.
local lsp_servers = {
  "clangd",       -- C / C++
  "lua_ls",       -- Lua (your config itself)
  "bashls",       -- Bash
  "pyright",      -- Python
  "html",
  "cssls",
  "jsonls",
  "yamlls",
  "taplo",        -- TOML
  "marksman",     -- Markdown
}

return {
  -- ─── LSP progress spinner ────────────────────────────
  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    opts = {
      progress = {
        display = {
          render_limit = 8,
          done_ttl = 2,
        },
      },
      notification = {
        window = { winblend = 0 },
      },
    },
  },

  -- ─── LSP ─────────────────────────────────────────────
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",   -- provides completion capabilities
    },
    config = function()
      require("mason").setup({
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })

      require("mason-lspconfig").setup({
        ensure_installed = lsp_servers,
      })

      -- Completion capabilities from blink.cmp
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      -- Per-server configuration
      local server_config = {
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
          },
          init_options = {
            usePlaceholders = true,
            completeUnimported = true,
            clangdFileStatus = true,
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              runtime = { version = "LuaJIT" },
              diagnostics = { globals = { "vim" } },
              workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
              },
              telemetry = { enable = false },
            },
          },
        },
      }

      -- Apply config + enable each server
      for _, lsp in ipairs(lsp_servers) do
        local config = vim.tbl_deep_extend("force",
          { capabilities = capabilities },
          server_config[lsp] or {}
        )
        vim.lsp.config(lsp, config)
        vim.lsp.enable(lsp)
      end

      -- Diagnostic UI
      vim.diagnostic.config({
        virtual_text = { prefix = "●", spacing = 2 },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = true,
        },
      })

      -- Rounded borders for hover and signature help
      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
        vim.lsp.handlers.hover, { border = "rounded" }
      )
      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
        vim.lsp.handlers.signature_help, { border = "rounded" }
      )

      -- LSP keymaps (buffer-local, on attach)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local opts = { buffer = args.buf }
          local map = vim.keymap.set
          map('n', 'gd', vim.lsp.buf.definition,
            vim.tbl_extend('force', opts, { desc = "LSP: goto definition" }))
          map('n', 'gD', vim.lsp.buf.declaration,
            vim.tbl_extend('force', opts, { desc = "LSP: goto declaration" }))
          map('n', 'gi', vim.lsp.buf.implementation,
            vim.tbl_extend('force', opts, { desc = "LSP: goto implementation" }))
          map('n', 'gt', vim.lsp.buf.type_definition,
            vim.tbl_extend('force', opts, { desc = "LSP: goto type definition" }))
          map('n', 'gr', vim.lsp.buf.references,
            vim.tbl_extend('force', opts, { desc = "LSP: references" }))
          map('n', 'K', vim.lsp.buf.hover,
            vim.tbl_extend('force', opts, { desc = "LSP: hover" }))
          map('n', '<C-k>', vim.lsp.buf.signature_help,
            vim.tbl_extend('force', opts, { desc = "LSP: signature help" }))
          map({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action,
            vim.tbl_extend('force', opts, { desc = "LSP: code action" }))
          map('n', '<leader>rn', vim.lsp.buf.rename,
            vim.tbl_extend('force', opts, { desc = "LSP: rename" }))
          map('n', '<leader>lf', function() vim.lsp.buf.format({ async = true }) end,
            vim.tbl_extend('force', opts, { desc = "LSP: format file" }))
          map('n', '<leader>ls', vim.lsp.buf.document_symbol,
            vim.tbl_extend('force', opts, { desc = "LSP: document symbols" }))
        end,
      })
    end,
  },
}
