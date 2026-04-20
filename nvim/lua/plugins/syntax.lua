local languages = {
	-- General
	"c",
	"cpp",
	"lua",
	"python",
	"bash",
	"markdown",
	"markdown_inline",
	"html",
	"css",
	"json",
	"yaml",
	"toml",
	-- Hardware / HDL
	"vhdl",
	-- Scientific / engineering
	"matlab",
	-- Config / build
	"make",
	"cmake",
	"ninja",
	-- Git + docs
	"gitcommit",
	"gitignore",
	"diff",
	-- Vim
	"vim",
	"vimdoc",
	"query",
}

return {
	-- ─── Treesitter ──────────────────────────────────────
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
		lazy = false,
		config = function()
			local ts = require("nvim-treesitter")
			ts.install(languages)

			vim.api.nvim_create_autocmd("FileType", {
				pattern = languages,
				callback = function()
					vim.treesitter.start()
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})
		end,
	},

	-- ─── Treesitter text objects ─────────────────────────
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		dependencies = {
			{ "nvim-treesitter/nvim-treesitter", branch = "main" },
		},
		event = "VeryLazy",
		config = function()
			require("nvim-treesitter-textobjects").setup({
				select = {
					lookahead = true,
					selection_modes = {
						["@parameter.outer"] = "v",
						["@function.outer"] = "V",
						["@class.outer"] = "V",
					},
					include_surrounding_whitespace = false,
				},
			})

			local select = require("nvim-treesitter-textobjects.select")
			local map = vim.keymap.set

			map({ "x", "o" }, "af", function()
				select.select_textobject("@function.outer", "textobjects")
			end, { desc = "a function" })
			map({ "x", "o" }, "if", function()
				select.select_textobject("@function.inner", "textobjects")
			end, { desc = "inner function" })
			map({ "x", "o" }, "ac", function()
				select.select_textobject("@class.outer", "textobjects")
			end, { desc = "a class" })
			map({ "x", "o" }, "ic", function()
				select.select_textobject("@class.inner", "textobjects")
			end, { desc = "inner class" })
			map({ "x", "o" }, "aa", function()
				select.select_textobject("@parameter.outer", "textobjects")
			end, { desc = "a parameter" })
			map({ "x", "o" }, "ia", function()
				select.select_textobject("@parameter.inner", "textobjects")
			end, { desc = "inner parameter" })
		end,
	},
}
