-- User commands wrapping hardware toolchains in toggleterm.
-- Keeps CLI tools (arduino-cli, esptool, avrdude, iverilog) one keystroke away
-- without leaving nvim.

return {
	{
		"akinsho/toggleterm.nvim", -- we're extending toggleterm with commands
		optional = true,
		init = function()
			-- Helper: run a command in a named toggleterm terminal
			local function term_exec(cmd, name)
				vim.cmd(string.format("TermExec cmd=%q name=%s direction=horizontal", cmd, name or "hw"))
			end

			-- ──────────────────────────────────────────────────
			-- Arduino / AVR
			-- ──────────────────────────────────────────────────
			vim.api.nvim_create_user_command("ArduinoCompile", function(opts)
				local fqbn = opts.args ~= "" and opts.args or "arduino:avr:uno"
				term_exec("arduino-cli compile --fqbn " .. fqbn .. " " .. vim.fn.expand("%:p:h"), "arduino")
			end, { nargs = "?", desc = "Compile Arduino sketch (default: arduino:avr:uno)" })

			vim.api.nvim_create_user_command("ArduinoUpload", function(opts)
				local args = opts.args
				if args == "" then
					vim.notify(
						"Usage: :ArduinoUpload <fqbn> <port>\nExample: :ArduinoUpload arduino:avr:uno /dev/ttyUSB0",
						vim.log.levels.ERROR
					)
					return
				end
				local fqbn, port = args:match("(%S+)%s+(%S+)")
				if not fqbn or not port then
					vim.notify("Need both FQBN and port", vim.log.levels.ERROR)
					return
				end
				term_exec(
					string.format(
						"arduino-cli compile --fqbn %s %s && arduino-cli upload -p %s --fqbn %s %s",
						fqbn,
						vim.fn.expand("%:p:h"),
						port,
						fqbn,
						vim.fn.expand("%:p:h")
					),
					"arduino"
				)
			end, { nargs = "+", desc = "Compile + upload Arduino sketch" })

			vim.api.nvim_create_user_command("ArduinoBoards", function()
				term_exec("arduino-cli board list", "arduino")
			end, { desc = "List connected Arduino boards" })

			-- ──────────────────────────────────────────────────
			-- ESP32 / ESP8266 (esptool)
			-- ──────────────────────────────────────────────────
			vim.api.nvim_create_user_command("EspChipId", function(opts)
				local port = opts.args ~= "" and opts.args or "/dev/ttyUSB0"
				term_exec("esptool.py --port " .. port .. " chip_id", "esp")
			end, { nargs = "?", desc = "Read ESP chip ID (default port: /dev/ttyUSB0)" })

			vim.api.nvim_create_user_command("EspFlash", function(opts)
				local args = opts.args
				if args == "" then
					vim.notify(
						"Usage: :EspFlash <port> <offset> <file.bin>\n"
							.. "Example: :EspFlash /dev/ttyUSB0 0x1000 build/firmware.bin",
						vim.log.levels.ERROR
					)
					return
				end
				term_exec("esptool.py --port " .. args .. " write_flash " .. args, "esp")
			end, { nargs = "+", desc = "Flash firmware to ESP chip" })

			vim.api.nvim_create_user_command("EspErase", function(opts)
				local port = opts.args ~= "" and opts.args or "/dev/ttyUSB0"
				term_exec("esptool.py --port " .. port .. " erase_flash", "esp")
			end, { nargs = "?", desc = "Erase ESP flash" })

			vim.api.nvim_create_user_command("EspMonitor", function(opts)
				local args = opts.args
				local port, baud = args:match("(%S+)%s+(%S+)")
				port = port or "/dev/ttyUSB0"
				baud = baud or "115200"
				term_exec("screen " .. port .. " " .. baud, "monitor")
			end, { nargs = "*", desc = "Serial monitor via screen (default /dev/ttyUSB0 115200)" })

			-- ──────────────────────────────────────────────────
			-- AVR direct (avrdude)
			-- ──────────────────────────────────────────────────
			vim.api.nvim_create_user_command("AvrFlash", function(opts)
				local args = opts.args
				if args == "" then
					vim.notify(
						"Usage: :AvrFlash <programmer> <part> <hexfile>\n"
							.. "Example: :AvrFlash arduino m328p firmware.hex",
						vim.log.levels.ERROR
					)
					return
				end
				local prog, part, hex = args:match("(%S+)%s+(%S+)%s+(%S+)")
				if not (prog and part and hex) then
					vim.notify("Need programmer, part, and hexfile", vim.log.levels.ERROR)
					return
				end
				term_exec(string.format("avrdude -c %s -p %s -U flash:w:%s:i", prog, part, hex), "avr")
			end, { nargs = "+", desc = "Flash AVR chip via avrdude" })

			-- ──────────────────────────────────────────────────
			-- FPGA / Verilog simulation
			-- ──────────────────────────────────────────────────
			vim.api.nvim_create_user_command("VerilogSim", function()
				local file = vim.fn.expand("%:p")
				local out = vim.fn.expand("%:p:r") .. ".vvp"
				term_exec(string.format("iverilog -o %s %s && vvp %s", out, file, out), "verilog")
			end, { desc = "Compile and run current Verilog file with iverilog" })

			vim.api.nvim_create_user_command("VerilogLint", function()
				term_exec("verilator --lint-only -Wall " .. vim.fn.expand("%:p"), "verilog")
			end, { desc = "Lint current Verilog file with Verilator" })

			vim.api.nvim_create_user_command("VerilogFormat", function()
				local file = vim.fn.expand("%:p")
				term_exec("verible-verilog-format --inplace " .. file, "verilog")
				vim.cmd("checktime") -- reload the file in nvim
			end, { desc = "Format Verilog file with verible" })

			vim.api.nvim_create_user_command("WaveView", function(opts)
				local wave = opts.args ~= "" and opts.args or vim.fn.expand("%:p:r") .. ".vcd"
				term_exec("gtkwave " .. wave .. " &", "wave")
			end, { nargs = "?", desc = "Open .vcd waveform in gtkwave" })
		end,
	},
}
