return {
  {
    "brianhuster/live-preview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "LivePreview" },
    keys = {
      { "<leader>lp", ":LivePreview<CR>", desc = "Toggle Live Preview" },
    },
    opts = {
      -- Opens in your default browser
      port = 8080,
      browser = "default", 
    },
  }
}
