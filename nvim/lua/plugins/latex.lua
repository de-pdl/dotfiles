-- ~/.dotfiles/nvim/lua/plugins/latex.lua
-- LaTeX editing: VimTeX (compile/preview/SyncTeX) + img-clip (paste images from clipboard)

return {
  -----------------------------------------------------------------------
  -- VimTeX: the canonical LaTeX plugin for vim/nvim
  -- Handles: compilation, forward/reverse SyncTeX, syntax, motions,
  -- text objects (e.g. dse = delete surrounding environment), TOC, etc.
  -----------------------------------------------------------------------
  {
    "lervag/vimtex",
    lazy = false,        -- VimTeX must load on startup, not on filetype
    ft = { "tex" },      -- but we still mark it for tex files
    init = function()
      -- ┌──────────────────────────────────────────────┐
      -- │ Compiler: latexmk (already installed)        │
      -- └──────────────────────────────────────────────┘
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_compiler_latexmk = {
        aux_dir = "build",         -- keep aux/log files out of project root
        out_dir = "build",         -- PDF goes here too
        callback = 1,
        continuous = 1,            -- watch mode: recompile on save
        executable = "latexmk",
        options = {
          "-verbose",
          "-file-line-error",
          "-synctex=1",            -- enable SyncTeX (cursor↔PDF jumps)
          "-interaction=nonstopmode",
        },
      }

      -- ┌──────────────────────────────────────────────┐
      -- │ PDF viewer: zathura                          │
      -- └──────────────────────────────────────────────┘
      vim.g.vimtex_view_method = "zathura_simple"

      -- ┌──────────────────────────────────────────────┐
      -- │ Quickfix: only open on errors, not warnings  │
      -- └──────────────────────────────────────────────┘
      vim.g.vimtex_quickfix_mode = 0  -- 0 = never auto-open; toggle with <leader>lq
      vim.g.vimtex_quickfix_open_on_warning = 0

      -- ┌──────────────────────────────────────────────┐
      -- │ Disable VimTeX's default <localleader> maps  │
      -- │ if you want to define your own. Leaving on.  │
      -- └──────────────────────────────────────────────┘
      -- vim.g.vimtex_mappings_enabled = 0

      -- Conceal: hide \emph{}, $, etc. for readability. 0=off, 2=on.
      vim.g.vimtex_syntax_conceal_disable = 1  -- I prefer to see the source
    end,
  },

  -----------------------------------------------------------------------
  -- img-clip.nvim: paste images from system clipboard into LaTeX/MD
  -- Workflow: screenshot → <leader>p → image saved to figures/, 
  -- \includegraphics{...} inserted at cursor.
  -----------------------------------------------------------------------
  {
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    opts = {
      default = {
        dir_path = "figures",          -- relative to .tex file's directory
        file_name = "%Y%m%d-%H%M%S",   -- timestamp-based filenames
        use_absolute_path = false,
        relative_to_current_file = true,
      },
      filetypes = {
        tex = {
          template = [[
\begin{figure}[htbp]
    \centering
    \includegraphics[width=0.8\linewidth]{$FILE_PATH}
    \caption{$CURSOR}
    \label{fig:$FILE_NAME}
\end{figure}]],
        },
      },
    },
    keys = {
      { "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste image from clipboard" },
    },
  },
}
