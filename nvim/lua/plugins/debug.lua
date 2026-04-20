return {
	-- ─── Core DAP + UI ───────────────────────────────────
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
			"theHamsta/nvim-dap-virtual-text",
			"jay-babu/mason-nvim-dap.nvim",
			"williamboman/mason.nvim",
		},
		keys = {
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Toggle breakpoint",
			},
			{
				"<leader>dB",
				function()
					require("dap").set_breakpoint(vim.fn.input("Condition: "))
				end,
				desc = "Conditional breakpoint",
			},
			{
				"<leader>dc",
				function()
					require("dap").continue()
				end,
				desc = "Continue / start",
			},
			{
				"<leader>dC",
				function()
					require("dap").run_to_cursor()
				end,
				desc = "Run to cursor",
			},
			{
				"<leader>ds",
				function()
					require("dap").step_over()
				end,
				desc = "Step over",
			},
			{
				"<leader>di",
				function()
					require("dap").step_into()
				end,
				desc = "Step into",
			},
			{
				"<leader>do",
				function()
					require("dap").step_out()
				end,
				desc = "Step out",
			},
			{
				"<leader>dr",
				function()
					require("dap").repl.toggle()
				end,
				desc = "Toggle REPL",
			},
			{
				"<leader>dl",
				function()
					require("dap").run_last()
				end,
				desc = "Run last config",
			},
			{
				"<leader>dt",
				function()
					require("dap").terminate()
				end,
				desc = "Terminate",
			},
			{
				"<leader>du",
				function()
					require("dapui").toggle()
				end,
				desc = "Toggle DAP UI",
			},
			{
				"<leader>dw",
				function()
					require("dap.ui.widgets").hover()
				end,
				desc = "Hover variable",
			},
			{
				"<leader>dp",
				function()
					require("dap.ui.widgets").preview()
				end,
				desc = "Preview variable",
			},
			{
				"<leader>df",
				function()
					local widgets = require("dap.ui.widgets")
					widgets.centered_float(widgets.frames)
				end,
				desc = "Frames",
			},
			{
				"<leader>dS",
				function()
					local widgets = require("dap.ui.widgets")
					widgets.centered_float(widgets.scopes)
				end,
				desc = "Scopes",
			},
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			-- ─── Mason-DAP: auto-install adapters ─────────────
			require("mason-nvim-dap").setup({
				ensure_installed = { "codelldb", "cppdbg" },
				automatic_installation = true,
				handlers = {}, -- use default handler → wires each adapter up automatically
			})

			-- ─── UI setup ─────────────────────────────────────
			dapui.setup({
				icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
				layouts = {
					{
						elements = {
							{ id = "scopes", size = 0.35 },
							{ id = "breakpoints", size = 0.15 },
							{ id = "stacks", size = 0.25 },
							{ id = "watches", size = 0.25 },
						},
						size = 40,
						position = "left",
					},
					{
						elements = {
							{ id = "repl", size = 0.5 },
							{ id = "console", size = 0.5 },
						},
						size = 10,
						position = "bottom",
					},
				},
				controls = {
					enabled = true,
					element = "repl",
				},
				floating = {
					border = "rounded",
					mappings = { close = { "q", "<Esc>" } },
				},
			})

			-- ─── Virtual text ─────────────────────────────────
			require("nvim-dap-virtual-text").setup({
				commented = true,
				virt_text_pos = "eol",
				all_frames = false,
			})

			-- ─── Auto-open/close UI ───────────────────────────
			dap.listeners.before.attach.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.launch.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				dapui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				dapui.close()
			end

			-- ─── Breakpoint appearance ────────────────────────
			vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError", linehl = "", numhl = "" })
			vim.fn.sign_define(
				"DapBreakpointCondition",
				{ text = "◆", texthl = "DiagnosticWarn", linehl = "", numhl = "" }
			)
			vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
			vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticWarn", linehl = "Visual", numhl = "" })
			vim.fn.sign_define(
				"DapBreakpointRejected",
				{ text = "", texthl = "DiagnosticError", linehl = "", numhl = "" }
			)

			-- ─── C / C++ desktop launch configurations ────────
			for _, lang in ipairs({ "c", "cpp" }) do
				dap.configurations[lang] = {
					{
						name = "Launch (desktop binary)",
						type = "codelldb",
						request = "launch",
						program = function()
							return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
						end,
						cwd = "${workspaceFolder}",
						stopOnEntry = false,
						args = function()
							local raw = vim.fn.input("Args (space-separated): ")
							if raw == "" then
								return {}
							end
							return vim.split(raw, " ")
						end,
						runInTerminal = false,
					},
					{
						name = "Attach to running process",
						type = "codelldb",
						request = "attach",
						pid = require("dap.utils").pick_process,
						cwd = "${workspaceFolder}",
					},
					-- ── Embedded: attach to remote gdbserver ──
					-- Use this with: arm-none-eabi-gdb via gdbserver, openocd, avarice, etc.
					-- Prerequisite: adapter must be running BEFORE you continue.
					{
						name = "Attach remote gdbserver (default :3333)",
						type = "cppdbg",
						request = "launch",
						MIMode = "gdb",
						miDebuggerPath = "/usr/bin/gdb",
						miDebuggerServerAddress = "localhost:3333",
						program = function()
							return vim.fn.input("Path to ELF: ", vim.fn.getcwd() .. "/", "file")
						end,
						cwd = "${workspaceFolder}",
						stopOnEntry = true,
						setupCommands = {
							{
								text = "-enable-pretty-printing",
								description = "enable pretty printing",
								ignoreFailures = false,
							},
						},
					},
				}
			end
		end,
	},
}
