-- Set the leader key to Space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- Clipboard: copy / paste to system clipboard
map({"n", "v"}, "<leader>y", '\"+y', { desc = "Yank to system clipboard" })
map("n", "<leader>Y", '\"+Y', { desc = "Yank line to system clipboard" })
map({"n", "v"}, "<leader>p", '\"+p', { desc = "Paste from system clipboard" })
map({"n", "v"}, "<leader>P", '\"+P', { desc = "Paste before from system clipboard" })

-- Quick save and quit
map("n", "<leader>w", ":w<CR>", { desc = "Save file" })
map("n", "<leader>W", ":wa<CR>", { desc = "Save all files" })
map("n", "<leader>q", ":q<CR>", { desc = "Quit" })

-- Better window navigation (Ctrl-h/j/k/l)
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Resize windows with Alt + arrow keys
map("n", "<A-Up>", ":resize +2<CR>", { desc = "Increase window height" })
map("n", "<A-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
map("n", "<A-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<A-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

-- Buffer navigation
map("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bd", ":bd<CR>", { desc = "Delete/close buffer" })

-- Telescope-ish mappings (will work if telescope or similar is installed)
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files (Telescope)" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep (Telescope)" })
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "List buffers (Telescope)" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Help tags (Telescope)" })

-- File explorer (falls back to :Ex if no plugin)
map("n", "<leader>e", "<cmd>Ex<cr>", { desc = "Open file explorer (netrw/Ex)" })

-- Terminal toggle
map("n", "<leader>t", ":terminal<CR>", { desc = "Open terminal" })

-- Easier escape from insert mode
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Move selected lines up/down in visual mode
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep visual selection when indenting
map("v", "<", "<gv", { desc = "Indent left and keep selection" })
map("v", ">", ">gv", { desc = "Indent right and keep selection" })

-- Paste over visual selection without yanking selection
map("v", "p", '\"_dP', { desc = "Paste over selection without yanking" })

-- LSP mappings (works if lspconfig is set up)
map("n", "gd", vim.lsp.buf.definition, { desc = "LSP: goto definition" })
map("n", "gD", vim.lsp.buf.declaration, { desc = "LSP: goto declaration" })
map("n", "gr", vim.lsp.buf.references, { desc = "LSP: references" })
map("n", "K", vim.lsp.buf.hover, { desc = "LSP: hover" })
map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "LSP: rename" })
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP: code action" })
map("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, { desc = "LSP: format file" })

-- Diagnostics
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open diagnostic float" })
map("n", "<leader>qf", vim.diagnostic.setloclist, { desc = "Send diagnostics to location list" })

-- Misc quality of life
map("n", "<leader>y", '\"+y', { desc = "Yank to system clipboard (shortcut)" })
map("n", "<leader>p", '\"+p', { desc = "Paste from system clipboard (shortcut)" })
map("v", "<leader>y", '\"+y', { desc = "Yank visual to system clipboard" })
map("n", "<leader>sf", ":setlocal spell!<CR>", { desc = "Toggle spell checking" })

-- Keep common defaults: allow easily quitting and saving
map("n", "<leader>Q", ":qall<CR>", { desc = "Quit all" })
