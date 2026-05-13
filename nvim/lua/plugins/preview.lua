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
	},

	{
		"lervag/vimtex",
		lazy = false,
		init = function()
			vim.g.vimtex_view_method = "zathura"
			vim.g.vimtex_compiler_latexmk = {
				out_dir = "build",
				continuous = 1,
				options = { "-pdf", "-interaction=nonstopmode", "-synctex=1" },
			}
			vim.g.vimtex_doc_enabled = 0
			vim.g.vimtex_complete_enabled = 0
			vim.g.vimtex_syntax_enabled = 0
			vim.g.vimtex_imaps_enabled = 0
			vim.g.vimtex_view_forward_search_on_start = 1
		end,
	},
}
