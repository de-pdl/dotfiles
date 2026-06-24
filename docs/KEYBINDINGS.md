# Neovim Keybindings

This file documents the keybindings defined in nvim/.config/nvim/lua/keymaps.lua

## Leader
- <Leader>: Space

## Clipboard
- <leader>y (n, v): Yank to system clipboard
- <leader>Y (n): Yank line to system clipboard
- <leader>p (n, v): Paste from system clipboard
- <leader>P (n, v): Paste before from system clipboard

## Save / Quit
- <leader>w (n): Save file (:w)
- <leader>W (n): Save all files (:wa)
- <leader>q (n): Quit (:q)
- <leader>Q (n): Quit all (:qall)

## Window navigation
- Ctrl-h / Ctrl-j / Ctrl-k / Ctrl-l (n): Move to left / bottom / top / right window

## Resize windows
- Alt + Up / Down (n): Increase / decrease window height
- Alt + Left / Right (n): Decrease / increase window width

## Buffer navigation
- <leader>bn (n): Next buffer (:bnext)
- <leader>bp (n): Previous buffer (:bprevious)
- <leader>bd (n): Delete/close buffer (:bd)

## Telescope (requires Telescope plugin)
- <leader>ff (n): Find files
- <leader>fg (n): Live grep
- <leader>fb (n): List buffers
- <leader>fh (n): Help tags

## File explorer
- <leader>e (n): Open file explorer (netrw / :Ex)

## Terminal
- <leader>t (n): Open terminal (:terminal)

## Insert mode
- jk (i): Exit insert mode (Esc)

## Visual mode helpers
- J / K (v): Move selection down / up
- < / > (v): Indent left / right and keep selection
- p (v): Paste over selection without yanking the selection (uses blackhole register)

## LSP (requires lspconfig)
- gd (n): LSP go to definition
- gD (n): LSP go to declaration
- gr (n): LSP references
- K (n): LSP hover
- <leader>rn (n): LSP rename
- <leader>ca (n): LSP code action
- <leader>f (n): Format file (async)

## Diagnostics
- [d (n): Go to previous diagnostic
- ]d (n): Go to next diagnostic
- <leader>e (n): Open diagnostic float
- <leader>qf (n): Send diagnostics to location list

## Misc / QoL
- <leader>sf (n): Toggle spell checking
- <leader>y (n): Yank to system clipboard (shortcut)
- <leader>p (n): Paste from system clipboard (shortcut)

---
File: nvim/.config/nvim/lua/keymaps.lua
Generated: This file summarizes the mappings currently defined in the repo.

