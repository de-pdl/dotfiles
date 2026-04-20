return {
  -- ─── Mason tool installer (formatters + linters) ─────
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    cmd = { "MasonToolsInstall", "MasonToolsUpdate", "MasonToolsClean" },
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          -- Formatters
          "stylua",
          "clang-format",
          "black",
          "isort",
          "shfmt",
          "prettier",

          -- Linters
          "shellcheck",
          "cppcheck",
          "markdownlint",
        },
        auto_update = false,
        run_on_start = false, -- we trigger manually after registry is ready
      })

      -- Run install after Mason is fully loaded and registry is refreshed.
      vim.api.nvim_create_autocmd("User", {
        pattern = "MasonToolsStartingInstall",
        callback = function()
          vim.schedule(function()
            vim.notify("mason-tool-installer: starting install", vim.log.levels.INFO)
          end)
        end,
      })

      -- Trigger on VimEnter (after all plugins loaded), but only when
      -- the registry is actually ready.
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          require("mason-registry").refresh(function()
            vim.cmd("MasonToolsInstall")
          end)
        end,
      })
    end,
  },

  -- ─── Conform (formatter) ─────────────────────────────
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>lf",
        function() require("conform").format({ async = true, lsp_fallback = true }) end,
        mode = { "n", "v" },
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        lua      = { "stylua" },
        c        = { "clang-format" },
        cpp      = { "clang-format" },
        python   = { "isort", "black" },
        sh       = { "shfmt" },
        bash     = { "shfmt" },
        zsh      = { "shfmt" },
        html     = { "prettier" },
        css      = { "prettier" },
        json     = { "prettier" },
        yaml     = { "prettier" },
        markdown = { "prettier" },
        ["_"]    = { "trim_whitespace" },   -- fallback for any filetype
      },

      format_on_save = function(bufnr)
        -- Global off-switch: :FormatDisable / :FormatEnable
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 1000, lsp_fallback = true }
      end,

      formatters = {
        shfmt = {
          prepend_args = { "-i", "2", "-ci" }, -- 2-space indent, indent switch cases
        },
      },
    },
    init = function()
      -- Toggle commands for format-on-save
      vim.api.nvim_create_user_command("FormatDisable", function(args)
        if args.bang then
          vim.b.disable_autoformat = true -- buffer-local
        else
          vim.g.disable_autoformat = true -- global
        end
      end, {
        desc = "Disable autoformat-on-save",
        bang = true,
      })

      vim.api.nvim_create_user_command("FormatEnable", function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
      end, { desc = "Re-enable autoformat-on-save" })
    end,
  },

  -- ─── nvim-lint (linter runner) ───────────────────────
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile", "BufWritePost" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        c        = { "cppcheck" },
        cpp      = { "cppcheck" },
        sh       = { "shellcheck" },
        bash     = { "shellcheck" },
        markdown = { "markdownlint" },
      }

      -- Run linters on the events below
      local group = vim.api.nvim_create_augroup("nvim-lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = group,
        callback = function()
          -- Only run in modifiable files
          if vim.bo.modifiable then
            lint.try_lint()
          end
        end,
      })

      vim.keymap.set("n", "<leader>ll", function()
        lint.try_lint()
      end, { desc = "Lint: trigger manually" })
    end,
  },
}
