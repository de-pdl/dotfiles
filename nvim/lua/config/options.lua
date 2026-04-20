-- lua/config/options.lua
-- Editor options (extracted from init.lua)

local opt = vim.opt

-- ─── Line Numbers ──────────────────────────────────────
opt.number = true
opt.relativenumber = true

-- ─── Indentation ───────────────────────────────────────
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.expandtab = true
opt.smartindent = true

-- ─── Clipboard ─────────────────────────────────────────
opt.clipboard = "unnamedplus"

-- ─── Search ────────────────────────────────────────────
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

-- ─── UI ────────────────────────────────────────────────
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false

-- ─── Files ─────────────────────────────────────────────
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undodir = vim.fn.stdpath("data") .. "/undodir"

-- ─── Splits ────────────────────────────────────────────
opt.splitright = true
opt.splitbelow = true

-- ─── Misc ──────────────────────────────────────────────
opt.updatetime = 250       -- Faster diagnostic/hover popups
opt.timeoutlen = 300       -- Faster which-key (Phase 2)
opt.mouse = "a"
