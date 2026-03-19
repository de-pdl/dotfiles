local config = require("config")

-- 1. Load your custom keymaps FIRST
require("keymaps")

if config.is_remote then
    vim.cmd.colorscheme("gruvbox")  -- Change to your preferred fallback
else
    vim.cmd.colorscheme("matugen")
end

-- 2. Basic Editor Settings
vim.opt.number = true           -- Show line numbers
vim.opt.relativenumber = true   -- Relative line numbers
vim.opt.shiftwidth = 2          -- 2 spaces for indent
vim.opt.tabstop = 2
vim.opt.expandtab = true        -- Use spaces instead of tabs
vim.opt.clipboard = "unnamedplus" -- Syncs Neovim clipboard with your OS automatically

-- 3. Bootstrap Lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

-- 4. Load all files inside the `lua/plugins/` folder
require("lazy").setup("plugins")
