-- Hardware / embedded development layer
-- Targets: ESP32/ESP8266, AVR (Arduino), FPGA (Verilog/VHDL)
-- Language: C/C++ primary, with HDL support

return {
	-- ─── Additional LSP servers for HDL ──────────────────
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			-- We don't override the main LSP config; we just add new servers
			-- using vim.lsp.config/enable. This runs after lsp.lua has loaded.
			return opts
		end,
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			-- ─── Verible (Verilog / SystemVerilog) ───────────
			if vim.fn.executable("verible-verilog-ls") == 1 then
				vim.lsp.config("verible", {
					cmd = { "verible-verilog-ls", "--rules_config_search" },
					filetypes = { "verilog", "systemverilog" },
					root_markers = { ".git", ".verible.filelist" },
					capabilities = capabilities,
				})
				vim.lsp.enable("verible")
			end

			-- ─── GHDL (VHDL) ─────────────────────────────────
			-- Lightweight — only enable if ghdl-ls exists
			if vim.fn.executable("ghdl-ls") == 1 then
				vim.lsp.config("ghdl_ls", {
					cmd = { "ghdl-ls" },
					filetypes = { "vhdl" },
					root_markers = { ".git", "hdl-prj.json" },
					capabilities = capabilities,
				})
				vim.lsp.enable("ghdl_ls")
			end
		end,
	},

	-- ─── Filetype detection for hardware files ───────────
	{
		"LazyVim/LazyVim", -- placeholder so lazy has something to load; we use init
		name = "hardware-filetypes",
		event = "VeryLazy",
		dir = vim.fn.stdpath("config"), -- treat as local plugin (no download)
		config = function()
			vim.filetype.add({
				extension = {
					-- Arduino sketches — treat as C++ for clangd
					ino = "cpp",
					pde = "cpp",

					-- Verilog / SystemVerilog
					v = "verilog",
					vh = "verilog",
					sv = "systemverilog",
					svh = "systemverilog",

					-- VHDL
					vhd = "vhdl",
					vhdl = "vhdl",

					-- Linker / memory map scripts
					ld = "ld",

					-- ESP-IDF Kconfig files
					["Kconfig.projbuild"] = "kconfig",
				},

				filename = {
					-- Common embedded build files
					["platformio.ini"] = "dosini",
					["sdkconfig"] = "config",
					["sdkconfig.defaults"] = "config",
				},
			})
		end,
	},
}
