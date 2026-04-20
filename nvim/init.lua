-- ─── Entry Point ───────────────────────────────────────
local config = require("config")

-- ─── Load user settings ────────────────────────────────
require("config.options")
require("config.keymaps")

-- ─── Colorscheme ───────────────────────────────────────
if config.is_remote then
  vim.cmd.colorscheme("gruvbox")
else
  vim.cmd.colorscheme("matugen")
end

-- ─── Bootstrap Lazy.nvim ───────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

-- ─── Load all plugin specs from lua/plugins/ ───────────
require("lazy").setup("plugins")
