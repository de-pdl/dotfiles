return {
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		cmd = { "ToggleTerm", "TermExec", "ToggleTermToggleAll" },
		keys = {
			-- Quick toggles
			{ "<C-\\>", "<cmd>ToggleTerm<cr>", mode = { "n", "t" }, desc = "Toggle terminal" },
			{ "<leader>tt", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Terminal (horizontal)" },
			{ "<leader>tv", "<cmd>ToggleTerm direction=vertical size=80<cr>", desc = "Terminal (vertical)" },
			{ "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Terminal (floating)" },
			{ "<leader>tT", "<cmd>ToggleTermToggleAll<cr>", desc = "Toggle all terminals" },

			-- Dedicated named terminals (persist independently)
			{ "<leader>t1", "<cmd>1ToggleTerm direction=horizontal<cr>", desc = "Terminal 1 (build)" },
			{ "<leader>t2", "<cmd>2ToggleTerm direction=horizontal<cr>", desc = "Terminal 2 (flash)" },
			{ "<leader>t3", "<cmd>3ToggleTerm direction=horizontal<cr>", desc = "Terminal 3 (monitor)" },

			-- Common tools in floats
			{
				"<leader>tg",
				function()
					_LAZYGIT_TOGGLE()
				end,
				desc = "LazyGit (if installed)",
			},
			{
				"<leader>th",
				function()
					_BTOP_TOGGLE()
				end,
				desc = "Btop (if installed)",
			},
			{
				"<leader>tp",
				function()
					_PYTHON_TOGGLE()
				end,
				desc = "Python REPL",
			},
		},
		opts = {
			size = function(term)
				if term.direction == "horizontal" then
					return 15
				elseif term.direction == "vertical" then
					return math.floor(vim.o.columns * 0.4)
				end
			end,
			open_mapping = nil, -- we use `keys` above instead
			hide_numbers = true,
			shade_terminals = true,
			shading_factor = 2,
			start_in_insert = true,
			insert_mappings = true,
			terminal_mappings = true,
			persist_size = true,
			persist_mode = true,
			direction = "horizontal",
			close_on_exit = true,
			shell = vim.o.shell,
			auto_scroll = true,
			float_opts = {
				border = "rounded",
				width = function()
					return math.floor(vim.o.columns * 0.85)
				end,
				height = function()
					return math.floor(vim.o.lines * 0.8)
				end,
				winblend = 0,
			},
			winbar = {
				enabled = false,
			},
		},
		config = function(_, opts)
			require("toggleterm").setup(opts)

			-- ─── Terminal-mode keymaps ─────────────────────────
			-- Easier escape + window navigation from terminal buffers
			local function set_terminal_keymaps()
				local o = { buffer = 0 }
				vim.keymap.set("t", "<esc><esc>", [[<C-\><C-n>]], o) -- double-esc leaves insert
				vim.keymap.set("t", "jk", [[<C-\><C-n>]], o)
				vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], o)
				vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], o)
				vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], o)
				vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], o)
			end

			vim.api.nvim_create_autocmd("TermOpen", {
				pattern = "term://*toggleterm#*",
				callback = set_terminal_keymaps,
			})

			-- ─── Pre-configured floating terminal helpers ─────
			local Terminal = require("toggleterm.terminal").Terminal

			local lazygit = Terminal:new({
				cmd = "lazygit",
				direction = "float",
				float_opts = { border = "rounded" },
				hidden = true,
				on_open = function(term)
					vim.cmd("startinsert!")
					vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = term.bufnr })
				end,
			})
			function _LAZYGIT_TOGGLE()
				lazygit:toggle()
			end

			local btop = Terminal:new({
				cmd = "btop",
				direction = "float",
				hidden = true,
			})
			function _BTOP_TOGGLE()
				btop:toggle()
			end

			local python = Terminal:new({
				cmd = "python",
				direction = "float",
				hidden = true,
			})
			function _PYTHON_TOGGLE()
				python:toggle()
			end
		end,
	},
}
