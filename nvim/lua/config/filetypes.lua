-- lua/config/filetypes.lua
-- Consolidated filetype detection for non-standard files.
-- Loaded from init.lua, applied globally before plugins.

vim.filetype.add({
	extension = {
		-- ─── Arduino / embedded C++ ──────────────────────────
		ino = "cpp",
		pde = "cpp",

		-- ─── Verilog / SystemVerilog ─────────────────────────
		v = "verilog",
		vh = "verilog",
		sv = "systemverilog",
		svh = "systemverilog",

		-- ─── VHDL ────────────────────────────────────────────
		vhd = "vhdl",
		vhdl = "vhdl",

		-- ─── Linker / memory scripts ─────────────────────────
		ld = "ld",

		-- ─── MATLAB ──────────────────────────────────────────
		-- Vim's default maps .m → objc. Force matlab.
		m = "matlab",
		mat = "matlab",
		mlx = "matlab", -- Live Script (best-effort; .mlx is XML under the hood)
	},

	filename = {
		-- ─── Embedded build files ────────────────────────────
		["platformio.ini"] = "dosini",
		["sdkconfig"] = "config",
		["sdkconfig.defaults"] = "config",
		["Kconfig.projbuild"] = "kconfig",

		-- ─── MATLAB ──────────────────────────────────────────
		[".matlabrc"] = "matlab",
	},
})
