return {
	-- ─── Statusline ──────────────────────────────────────
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		event = "VeryLazy",
		opts = {
			options = {
				theme = "auto",
				globalstatus = true,
				section_separators = { left = "", right = "" },
				component_separators = { left = "│", right = "│" },
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff", "diagnostics" },
				lualine_c = { { "filename", path = 1 } },
				lualine_x = { "encoding", "fileformat", "filetype" },
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
		},
	},

	-- ─── Which-key (leader key discovery) ────────────────
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "modern",
			delay = 300,
			spec = {
				-- Leader groups
				{ "<leader>b", group = "buffers" },
				{ "<leader>c", group = "code" },
				{ "<leader>d", group = "debug / diagnostics" },
				{ "<leader>f", group = "find" },
				{ "<leader>g", group = "git" },
				{ "<leader>h", group = "hunk" },
				{ "<leader>l", group = "lsp / lint / format" },
				{ "<leader>t", group = "terminal" },

				-- Non-leader groups (plugin defaults)
				{ "gc", group = "comment" },
				{ "ys", group = "surround add", mode = { "n" } },
				{ "cs", group = "surround change", mode = { "n" } },
				{ "ds", group = "surround delete", mode = { "n" } },
			},
		},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer local keymaps (which-key)",
			},
		},
	},
}
