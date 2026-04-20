return {
	-- ─── Gitsigns (inline git info) ──────────────────────
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "│" },
				change = { text = "│" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
				untracked = { text = "┆" },
			},
			signcolumn = true,
			numhl = false,
			linehl = false,
			word_diff = false,
			watch_gitdir = { follow_files = true },
			current_line_blame = false, -- toggle with <leader>gb
			current_line_blame_opts = {
				virt_text = true,
				virt_text_pos = "eol",
				delay = 500,
			},
			current_line_blame_formatter = "<author>, <author_time:%R> • <summary>",
			sign_priority = 6,
			update_debounce = 100,
			preview_config = {
				border = "rounded",
				style = "minimal",
				relative = "cursor",
				row = 0,
				col = 1,
			},

			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns
				local map = function(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
				end

				-- Navigation between hunks
				map("n", "]h", function()
					if vim.wo.diff then
						return "]h"
					end
					vim.schedule(function()
						gs.nav_hunk("next")
					end)
					return "<Ignore>"
				end, "Next hunk")

				map("n", "[h", function()
					if vim.wo.diff then
						return "[h"
					end
					vim.schedule(function()
						gs.nav_hunk("prev")
					end)
					return "<Ignore>"
				end, "Previous hunk")

				-- Hunk actions (under <leader>h = "hunk")
				map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
				map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
				map("v", "<leader>hs", function()
					gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, "Stage selection")
				map("v", "<leader>hr", function()
					gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, "Reset selection")
				map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
				map("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage hunk")
				map("n", "<leader>hR", gs.reset_buffer, "Reset buffer")
				map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
				map("n", "<leader>hb", function()
					gs.blame_line({ full = true })
				end, "Blame line")
				map("n", "<leader>hd", gs.diffthis, "Diff against index")
				map("n", "<leader>hD", function()
					gs.diffthis("~")
				end, "Diff against last commit")

				-- Toggles
				map("n", "<leader>gb", gs.toggle_current_line_blame, "Toggle line blame")
				map("n", "<leader>gd", gs.toggle_deleted, "Toggle deleted lines")

				-- Text object: inner hunk
				map({ "o", "x" }, "ih", "<cmd>Gitsigns select_hunk<CR>", "Select hunk")
			end,
		},
	},

	-- ─── Fugitive (full git wrapper) ─────────────────────
	{
		"tpope/vim-fugitive",
		cmd = { "G", "Git", "Gdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GRename", "GDelete", "GBrowse" },
		keys = {
			{ "<leader>gg", "<cmd>Git<cr>", desc = "Git status (fugitive)" },
			{ "<leader>gc", "<cmd>Git commit<cr>", desc = "Git commit" },
			{ "<leader>gP", "<cmd>Git push<cr>", desc = "Git push" },
			{ "<leader>gp", "<cmd>Git pull<cr>", desc = "Git pull" },
			{ "<leader>gl", "<cmd>Git log --oneline --graph --all<cr>", desc = "Git log" },
			{ "<leader>gB", "<cmd>Git blame<cr>", desc = "Git blame (full)" },
		},
	},
}
