-- Set the leader key to Space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- ─── Clipboard ─────────────────────────────────────────
map({"n", "v"}, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
map("n", "<leader>Y", '"+Y', { desc = "Yank line to system clipboard" })
map({"n", "v"}, "<leader>p", '"+p', { desc = "Paste from system clipboard" })
map({"n", "v"}, "<leader>P", '"+P', { desc = "Paste before from system clipboard" })

-- ─── Save / Quit ───────────────────────────────────────
map("n", "<leader>w", ":w<CR>", { desc = "Save file" })
map("n", "<leader>W", ":wa<CR>", { desc = "Save all files" })
map("n", "<leader>q", ":q<CR>", { desc = "Quit" })
map("n", "<leader>Q", ":qall<CR>", { desc = "Quit all" })

-- ─── Window Navigation ─────────────────────────────────
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- ─── Window Resize ─────────────────────────────────────
map("n", "<A-Up>", ":resize +2<CR>", { desc = "Increase window height" })
map("n", "<A-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
map("n", "<A-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<A-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

-- ─── Buffers ───────────────────────────────────────────
map("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bd", ":bd<CR>", { desc = "Delete/close buffer" })

-- ─── Terminal ──────────────────────────────────────────
map("n", "<leader>t", ":terminal<CR>", { desc = "Open terminal" })

-- ─── Insert Mode ───────────────────────────────────────
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- ─── Visual Mode ───────────────────────────────────────
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
map("v", "<", "<gv", { desc = "Indent left and keep selection" })
map("v", ">", ">gv", { desc = "Indent right and keep selection" })
map("v", "p", '"_dP', { desc = "Paste over selection without yanking" })

-- ─── Diagnostics ───────────────────────────────────────
map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Previous diagnostic" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "Next diagnostic" })
map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Show diagnostic float" })
map("n", "<leader>dq", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })

-- ─── Misc ──────────────────────────────────────────────
map("n", "<leader>sf", ":setlocal spell!<CR>", { desc = "Toggle spell checking" })

-- Note: LSP keymaps live in LspAttach autocmd (see plugins/syntax.lua)
-- Note: Telescope keymaps will be added in Phase 2 with the plugin
