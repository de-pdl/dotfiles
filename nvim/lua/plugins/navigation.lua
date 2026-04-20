return {
  -- ─── Telescope (fuzzy finder) ────────────────────────
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function() return vim.fn.executable("make") == 1 end,
      },
    },
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>",   desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",    desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",      desc = "Find buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>",    desc = "Help tags" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>",     desc = "Recent files" },
      { "<leader>fd", "<cmd>Telescope diagnostics<cr>",  desc = "Diagnostics" },
      { "<leader>fk", "<cmd>Telescope keymaps<cr>",      desc = "Keymaps" },
      { "<leader>fc", "<cmd>Telescope commands<cr>",     desc = "Commands" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>",           desc = "Document symbols" },
      { "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<cr>",          desc = "Workspace symbols" },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          layout_strategy = "horizontal",
          layout_config = { prompt_position = "top" },
          sorting_strategy = "ascending",
          path_display = { "smart" },
        },
        pickers = {
          find_files = { hidden = true },
        },
      })
      pcall(telescope.load_extension, "fzf")
    end,
  },

  -- ─── Neo-tree (file explorer) ────────────────────────
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>",         desc = "Toggle file tree" },
      { "<leader>E", "<cmd>Neotree focus<cr>",          desc = "Focus file tree" },
      { "<leader>fe", "<cmd>Neotree reveal<cr>",        desc = "Reveal in tree" },
    },
    opts = {
      close_if_last_window = true,
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
      window = {
        width = 32,
        mappings = {
          ["<space>"] = "none",  -- don't steal our leader
        },
      },
    },
  },
}
