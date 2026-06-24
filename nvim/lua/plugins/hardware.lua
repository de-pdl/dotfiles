-- Hardware / embedded development layer
-- Targets: ESP32/ESP8266, AVR (Arduino), FPGA (Verilog/VHDL)
-- Filetype detection lives in lua/config/filetypes.lua

return {
	-- ─── Additional LSP servers for HDL ──────────────────
	{
		"neovim/nvim-lspconfig",
		optional = true,
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
}
